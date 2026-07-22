import logging
import os
import sys
from pathlib import Path

# Zorg dat de root map in sys.path staat
root_dir = Path(__file__).resolve().parent.parent
if str(root_dir) not in sys.path:
    sys.path.insert(0, str(root_dir))

from prefect import flow, task, get_run_logger

from flows.ingestion.huds import DriveHudsSource, LocalHudsSource, ingest_huds, verify_huds_raw_tables

# Folder ID of lokale map voor HUDS-exports
DRIVE_FOLDER_ID = os.getenv("HUDS_DRIVE_FOLDER_ID") or "11G124iUsexfoXE9i9D5dVKhdnQcSyjTW"
LOCAL_FOLDER_PATH = os.getenv("HUDS_LOCAL_FOLDER")


def run_huds_ingestion(log: logging.Logger | None = None, local_folder: str | None = None) -> dict[str, str]:
    """
    Haalt alle HUDS-bestanden op uit Google Drive of een lokale map en laadt ze naar BigQuery.
    """
    logger = log or logging.getLogger("huds_flow")
    
    target_local = local_folder or LOCAL_FOLDER_PATH
    if target_local:
        logger.info(f"HUDS-ingestie gestart vanuit LOKALE map: '{target_local}'")
        source = LocalHudsSource(folder_path=target_local)
    else:
        logger.info(f"HUDS-ingestie gestart vanuit GOOGLE DRIVE (map ID: {DRIVE_FOLDER_ID})")
        source = DriveHudsSource(folder_id=DRIVE_FOLDER_ID)

    results = ingest_huds(source)

    ok = [name for name, status in results.items() if status == "ok"]
    errors = {name: status for name, status in results.items() if status.startswith("error")}
    skipped = [name for name, status in results.items() if status.startswith("skipped")]

    logger.info(f"Klaar: {len(ok)} geladen, {len(skipped)} overgeslagen, {len(errors)} fouten.")

    if not ok:
        raise RuntimeError(
            "Geen HUDS-bestanden succesvol geladen. "
            f"Resultaten: {results}. Controleer of de Drive-map gedeeld is met het service account."
        )

    if errors:
        for name, msg in errors.items():
            logger.error(f"  ✗ {name}: {msg}")
        raise RuntimeError(
            f"HUDS-ingestie afgerond met {len(errors)} fout(en): {list(errors.keys())}"
        )

    verify_huds_raw_tables()
    return results


@task(
    name="ingest-huds-from-drive",
    retries=2,
    retry_delay_seconds=30,
    log_prints=True,
)
def ingest_huds_task() -> None:
    """
    Prefect-task: haalt alle HUDS-bestanden op uit Google Drive en laadt ze
    naar BigQuery. Nieuwe bestanden in de map worden automatisch meegenomen.

    Wanneer de HUDS API beschikbaar is:
      - Vervang DriveHudsSource door ApiHudsSource
      - De rest van de logica blijft ongewijzigd
    """
    run_huds_ingestion(get_run_logger())


@flow(name="ingest-huds", log_prints=True)
def ingest_huds_flow() -> None:
    """
    Prefect-flow: vernieuwt alle HUDS raw-tabellen in BigQuery vanuit Google Drive.

    Vervang of verwijder dit bestand niet: vervang alleen de source
    in ingest_huds_task() als de API beschikbaar is.
    """
    ingest_huds_task()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    run_huds_ingestion()
