"""
HUDS data ingestion: Google Drive → BigQuery.

Architectuur:
  - HudsDataSource (Protocol): de interface voor elke databron
  - DriveHudsSource:           huidige implementatie via Google Drive API
  - ingest_huds(source):       orchestratie-logica, bron-agnostisch

Wanneer de HUDS API beschikbaar is:
  1. Maak een klasse `ApiHudsSource` die het HudsDataSource Protocol implementeert.
  2. Pas `flows/huds_flow.py` aan om `ApiHudsSource` mee te geven.
  3. Geen andere code hoeft te veranderen.
"""

from __future__ import annotations

import io
import logging
import os
from typing import Protocol, runtime_checkable

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

load_dotenv()

logger = logging.getLogger("huds_ingest")

BQ_PROJECT = os.getenv("BQ_PROJECT_ID", "ivy-warehouse")
BQ_DATASET = "raw_huds"
SERVICE_ACCOUNT_FILE = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")

# Tabellen die dbt staging-modellen nodig hebben; moeten native BQ-tabellen zijn (geen Sheets).
REQUIRED_RAW_TABLES = (
    "raw_huds_bedrijven",
    "raw_huds_projecten",
    "raw_huds_facturen",
    "raw_huds_facturatie_overzicht",
    "raw_huds_uren",
    "raw_huds_uren_omzet_planning",
    "raw_huds_uren_omzet_realisatie",
    "raw_huds_uurtarieven",
    "raw_data_werknemers_intern",
)

# Drive API heeft alleen leesrechten nodig
_DRIVE_SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]

# MIME-types die worden ondersteund; andere bestanden in de map worden overgeslagen
_SUPPORTED_MIME_TYPES = {
    "application/vnd.google-apps.spreadsheet",                           # Google Sheet  → export als CSV
    "text/csv",                                                           # CSV upload
    "application/octet-stream",                                           # CSV zonder expliciete MIME
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", # XLSX
}


# ─────────────────────────────────────────────────────────────────────────────
# Source Protocol
# Vervang DriveHudsSource door een nieuwe implementatie van dit Protocol
# als de HUDS API beschikbaar komt.
# ─────────────────────────────────────────────────────────────────────────────

@runtime_checkable
class HudsDataSource(Protocol):
    """
    Interface voor een HUDS-databron.

    Elke implementatie moet twee methoden bieden:
      - list_files()              → lijst van bestanden (elk als dict met minimaal 'name')
      - get_dataframe(file_info)  → pandas DataFrame voor dat bestand

    Voorbeeld toekomstige API-implementatie:
        class ApiHudsSource:
            def list_files(self) -> list[dict]:
                # GET /api/huds/exports → [{"name": "Uren", "endpoint": "/uren"}, ...]
                ...
            def get_dataframe(self, file_info: dict) -> pd.DataFrame:
                # GET file_info["endpoint"] → DataFrame
                ...
    """

    def list_files(self) -> list[dict]:
        """Geeft een lijst van beschikbare bestanden terug (elk als dict met minimaal 'name')."""
        ...

    def get_dataframe(self, file_info: dict) -> pd.DataFrame:
        """Geeft een DataFrame terug voor het gegeven bestand."""
        ...


# ─────────────────────────────────────────────────────────────────────────────
# Google Drive implementatie
# ─────────────────────────────────────────────────────────────────────────────

class DriveHudsSource:
    """
    Leest HUDS-exportbestanden vanuit een Google Drive-map.

    Ondersteunt:
      - Google Sheets (worden automatisch als CSV geëxporteerd)
      - CSV-bestanden (direct gedownload)
      - XLSX-bestanden (ingelezen via openpyxl)

    De map wordt geïdentificeerd op basis van de folder_id (het deel
    na '/folders/' in de Drive URL).

    Authenticatie gaat via het service account in GOOGLE_APPLICATION_CREDENTIALS.
    Zorg dat de Drive-map gedeeld is met het e-mailadres van dit service account
    (minimaal Viewer-rechten op de map, niet de losse bestanden).
    """

    def __init__(
        self,
        folder_id: str,
        service_account_file: str | None = None,
    ) -> None:
        self.folder_id = folder_id

        if not self.folder_id:
            raise ValueError(
                "HUDS Drive folder ID ontbreekt. Stel HUDS_DRIVE_FOLDER_ID in of geef folder_id mee."
            )

        sa_file = service_account_file or SERVICE_ACCOUNT_FILE

        if not sa_file or not os.path.exists(sa_file):
            raise FileNotFoundError(
                f"Service account-bestand niet gevonden: '{sa_file}'. "
                "Controleer GOOGLE_APPLICATION_CREDENTIALS in .env"
            )

        credentials = service_account.Credentials.from_service_account_file(
            sa_file,
            scopes=_DRIVE_SCOPES,
        )
        self._drive = build("drive", "v3", credentials=credentials, cache_discovery=False)

    def list_files(self) -> list[dict]:
        """
        Geeft alle ondersteunde bestanden in de Drive-map terug.

        Bestanden met een niet-ondersteund MIME-type (bv. Google Docs,
        afbeeldingen) worden automatisch overgeslagen.
        """
        query = f"'{self.folder_id}' in parents and trashed = false"
        response = (
            self._drive.files()
            .list(
                q=query,
                fields="*",
                pageSize=200,
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            )
            .execute()
        )

        all_files = response.get("files", [])
        supported = [f for f in all_files if f["mimeType"] in _SUPPORTED_MIME_TYPES]
        skipped = len(all_files) - len(supported)

        logger.info(
            f"Drive-map bevat {len(all_files)} bestanden, "
            f"{len(supported)} worden ingekomen ({skipped} overgeslagen)."
        )
        return supported

    def get_dataframe(self, file_info: dict) -> pd.DataFrame:
        """
        Download een bestand uit Drive en geeft het terug als DataFrame.

        Google Sheets worden via de export-API als CSV opgehaald —
        de gebruiker hoeft niets extra's te doen.
        """
        file_id = file_info["id"]
        name = file_info["name"]
        mime_type = file_info["mimeType"]

        buffer = io.BytesIO()

        if mime_type == "application/vnd.google-apps.spreadsheet":
            logger.info(f"  Exporteer Google Sheet '{name}' als CSV...")
            request = self._drive.files().export_media(
                fileId=file_id,
                mimeType="text/csv",
            )
        else:
            logger.info(f"  Download '{name}'...")
            request = self._drive.files().get_media(fileId=file_id)

        downloader = MediaIoBaseDownload(buffer, request)
        done = False
        while not done:
            _, done = downloader.next_chunk()

        buffer.seek(0)

        if mime_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
            return pd.read_excel(buffer, engine="openpyxl")
        else:
            return pd.read_csv(buffer)


# ─────────────────────────────────────────────────────────────────────────────
# Hulpfuncties (bron-agnostisch)
# ─────────────────────────────────────────────────────────────────────────────

def _file_name_to_table(file_name: str) -> str:
    """
    Zet een Drive-bestandsnaam om naar een BigQuery-tabelnaam.

    Voorbeelden:
      'Werknemers'              → 'raw_huds_werknemers'
      'Uren_omzet_realisatie'   → 'raw_huds_uren_omzet_realisatie'
      'Facturen.csv'            → 'raw_huds_facturen'
      'Project voortgang'       → 'raw_huds_project_voortgang'
    """
    base = os.path.splitext(file_name)[0]   # extensie eraf
    sanitized = (
        base
        .lower()
        .strip()
        .replace(" ", "_")
        .replace("-", "_")
    )
    if sanitized in {"data_werknemers_intern", "werknemers_intern"}:
        return "raw_data_werknemers_intern"
    return f"raw_huds_{sanitized}"


def _load_to_bigquery(df: pd.DataFrame, table_name: str) -> None:
    """
    Laad een DataFrame naar BigQuery via een staging-tabel.

    De productietabel blijft intact als ophalen of laden naar staging mislukt.
    Alleen na een geslaagde staging-load wordt de doeltabel vervangen.
    """
    client = bigquery.Client(project=BQ_PROJECT)
    table_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{table_name}"
    staging_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{table_name}__staging"

    df = df.copy().astype(str).replace("nan", None).replace("None", None)
    df["_loaded_at"] = str(pd.Timestamp.utcnow())

    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        autodetect=True,
    )

    client.delete_table(staging_ref, not_found_ok=True)

    logger.info(f"  → Laden naar staging {staging_ref} ({len(df)} rijen)...")
    try:
        job = client.load_table_from_dataframe(df, staging_ref, job_config=job_config)
        job.result()
    except Exception:
        client.delete_table(staging_ref, not_found_ok=True)
        raise

    try:
        client.delete_table(table_ref, not_found_ok=True)
        copy_job = client.copy_table(staging_ref, table_ref)
        copy_job.result()
        logger.info(f"  ✓ {table_ref} geladen.")
        client.delete_table(staging_ref, not_found_ok=True)
    except Exception:
        logger.error(
            f"  Vervangen van {table_ref} mislukt; "
            f"staging blijft beschikbaar op {staging_ref} voor herstel."
        )
        raise


# ─────────────────────────────────────────────────────────────────────────────
# Hoofd-ingestie (bron-agnostisch)
# ─────────────────────────────────────────────────────────────────────────────

def ingest_huds(source: HudsDataSource) -> dict[str, str]:
    """
    Ingesteer alle HUDS-bestanden van de gegeven bron naar BigQuery.

    Geeft een dict terug met de status per bestand:
      {"Werknemers": "ok", "Facturen": "error: ...", ...}

    Deze functie is volledig bron-agnostisch: geef een DriveHudsSource mee
    voor de huidige situatie, of een ApiHudsSource zodra de API beschikbaar is.
    Nieuwe bestanden in de Drive-map worden automatisch opgepikt — er is
    geen configuratie nodig.
    """
    files = source.list_files()
    results: dict[str, str] = {}

    if not files:
        logger.warning("Geen bestanden gevonden in de bron. Niets te doen.")
        return results

    for file_info in files:
        name = file_info["name"]
        table_name = _file_name_to_table(name)
        logger.info(f"Verwerken: '{name}' → {BQ_DATASET}.{table_name}")

        try:
            df = source.get_dataframe(file_info)

            if df.empty:
                logger.warning(f"  '{name}' levert een lege DataFrame op, wordt overgeslagen.")
                results[name] = "skipped: leeg"
                continue

            _load_to_bigquery(df, table_name)
            results[name] = "ok"

        except Exception as exc:
            logger.error(f"  Fout bij verwerken van '{name}': {exc}", exc_info=True)
            results[name] = f"error: {exc}"
            # Ga door met de overige bestanden

    return results


def verify_huds_raw_tables() -> None:
    """Controleer dat vereiste raw-tabellen bestaan en geen externe Sheets meer zijn."""
    client = bigquery.Client(project=BQ_PROJECT)
    external_tables: list[str] = []
    missing_tables: list[str] = []

    for table_name in REQUIRED_RAW_TABLES:
        table_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{table_name}"
        try:
            table = client.get_table(table_ref)
        except Exception:
            missing_tables.append(table_name)
            continue

        if table.table_type == "EXTERNAL":
            external_tables.append(table_name)

    if missing_tables or external_tables:
        details: list[str] = []
        if missing_tables:
            details.append(f"ontbrekend: {missing_tables}")
        if external_tables:
            details.append(
                f"nog extern (Google Sheet): {external_tables}. "
                "Deel de Drive-map met het service account en draai ingestie opnieuw."
            )
        raise RuntimeError("HUDS raw-tabellen niet klaar voor dbt — " + "; ".join(details))
