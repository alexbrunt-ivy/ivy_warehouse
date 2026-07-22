"""
HUDS Betty Blocks API Ingestion: API → Pandas Transformation → BigQuery.

Architectuur:
  - fetch_huds_totalen_from_api: Haalt maandelijke totaaldata op uit de Betty Blocks API
  - transform_huds_totalen: Zet JSON om naar een platte dataframe met 1 rij per regio/maand
  - load_totalen_to_bigquery: Upsert (delete + append) de rijen in BigQuery voor idempotentie
  - get_huds_api_token: Beheert API sleutels via Prefect Secret Blocks of .env
"""

from __future__ import annotations

import logging
import os
import datetime
import pandas as pd
import requests
from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv()

logger = logging.getLogger("huds_api_ingest")

BQ_PROJECT = os.getenv("BQ_PROJECT_ID", "ivy-warehouse")
BQ_DATASET = "raw_huds"
BASE_URL = os.getenv("HUDS_API_BASE_URL", "https://ivyglobal.bettywebblocks.com/api/data/totalen")


def get_huds_api_token() -> str:
    """
    Haalt het API token op.
    Probeert eerst een Prefect Secret Block genaamd 'huds-api-token',
    en valt anders terug op de HUDS_API_TOKEN omgevingsvariabele (.env).
    """
    # 1. Probeer Prefect Secret Block
    try:
        from prefect.blocks.system import Secret
        secret_block = Secret.load("huds-api-token")
        token = secret_block.get()
        if token:
            return token
    except Exception:
        pass

    # 2. Fallback naar .env
    token = os.getenv("HUDS_API_TOKEN")
    if not token:
        raise ValueError(
            "HUDS API Token ontbreekt. "
            "Maak een Prefect Secret Block aan met de naam 'huds-api-token' "
            "of voeg 'HUDS_API_TOKEN=jouw_token' toe aan je .env bestand."
        )
    return token


def fetch_huds_totalen_from_api(year: int, month: int, token: str | None = None) -> dict:
    """
    Haalt de maandelijkse totaaldata op via de Betty Blocks API.
    """
    api_token = token or get_huds_api_token()
    params = {
        "token": api_token,
        "year": year,
        "month": month
    }
    
    logger.info(f"API data ophalen voor jaar {year}, maand {month}...")
    response = requests.get(BASE_URL, params=params, timeout=30)
    response.raise_for_status()
    
    return response.json()


def transform_huds_totalen(raw_data: dict) -> pd.DataFrame:
    """
    Zet de Geneste JSON data van Betty Blocks om naar een platte tabel (DataFrame).
    Elke regio + maand combinatie wordt precies 1 rij.
    Metadata zoals 'jaar', 'maand', 'periode' wordt per rij toegevoegd.
    """
    metadata_keys = {"jaar", "maand", "periode"}
    jaar = raw_data.get("jaar")
    maand = raw_data.get("maand")
    periode_str = raw_data.get("periode")

    periode_date = None
    if periode_str:
        try:
            periode_date = pd.to_datetime(periode_str, format="%d-%m-%Y").date()
        except Exception:
            logger.warning(f"Kon periode '{periode_str}' niet parsen als datum.")

    rows = []
    for key, value in raw_data.items():
        # Sla metadata en 'totaal' over (totaal berekenen we later in dbt/BigQuery)
        if key in metadata_keys or key == "totaal" or not isinstance(value, dict):
            continue

        row = {
            "jaar": int(jaar) if jaar is not None else None,
            "maand": int(maand) if maand is not None else None,
            "periode": periode_date,
            "regio": str(key).strip(),
            "sum_gerealiseerd_uren": float(value.get("sum_gerealiseerd_uren", 0) or 0),
            "sum_gerealiseerd_omzet": float(value.get("sum_gerealiseerd_omzet", 0) or 0),
            "sum_gepland_uren": float(value.get("sum_gepland_uren", 0) or 0),
            "sum_gepland_omzet": float(value.get("sum_gepland_omzet", 0) or 0),
        }
        rows.append(row)

    df = pd.DataFrame(rows)
    return df


def load_totalen_to_bigquery(df: pd.DataFrame, table_name: str = "raw_huds_maand_totalen") -> None:
    """
    Laadt het DataFrame naar BigQuery.
    Verwijder eerst bestaande rijen voor hetzelfde jaar & maand (idempotent/upsert),
    zodat herhaaldelijk draaien geen dubbele data veroorzaakt.
    """
    if df.empty:
        logger.warning("Geen data om te laden naar BigQuery.")
        return

    client = bigquery.Client(project=BQ_PROJECT)
    table_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{table_name}"

    df_to_load = df.copy()
    df_to_load["_loaded_at"] = pd.Timestamp.utcnow()

    jaar = df_to_load["jaar"].iloc[0]
    maand = df_to_load["maand"].iloc[0]

    # Clean up existing records for this specific month first
    delete_query = f"""
    DELETE FROM `{table_ref}`
    WHERE jaar = {jaar} AND maand = {maand}
    """
    try:
        logger.info(f"Eventuele bestaande records in `{table_ref}` verwijderen voor {jaar}-{maand}...")
        client.query(delete_query).result()
    except Exception:
        # Als de tabel nog niet bestaat, faalt de query. Dat is niet erg; BigQuery maakt de tabel zo aan.
        logger.info(f"Tabel `{table_ref}` bestaat nog niet of delete is overgeslagen.")

    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        autodetect=True,
    )

    logger.info(f"Laden van {len(df_to_load)} rijen naar BigQuery tabel `{table_ref}`...")
    job = client.load_table_from_dataframe(df_to_load, table_ref, job_config=job_config)
    job.result()
    logger.info(f"✓ BigQuery tabel `{table_ref}` succesvol bijgewerkt voor {jaar}-{maand}.")
