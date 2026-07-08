import os

from prefect import flow, task, get_run_logger

from flows.ingestion.huds import DriveHudsSource, ingest_huds

# Folder ID van de Drive-map met HUDS-exports.
# Staat ook in .env als HUDS_DRIVE_FOLDER_ID zodat je het per omgeving kunt overschrijven.
DRIVE_FOLDER_ID = os.getenv(
    "HUDS_DRIVE_FOLDER_ID",
    "11G124iUsexfoXE9i9D5dVKhdnQcSyjTW",
)


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
    logger = get_run_logger()
    logger.info(f"HUDS-ingestie gestart (Drive-map: {DRIVE_FOLDER_ID})")

    source = DriveHudsSource(folder_id=DRIVE_FOLDER_ID)
    results = ingest_huds(source)

    # Samenvatting loggen
    ok = [name for name, status in results.items() if status == "ok"]
    errors = {name: status for name, status in results.items() if status.startswith("error")}
    skipped = [name for name, status in results.items() if status.startswith("skipped")]

    logger.info(f"Klaar: {len(ok)} geladen, {len(skipped)} overgeslagen, {len(errors)} fouten.")

    if errors:
        for name, msg in errors.items():
            logger.error(f"  ✗ {name}: {msg}")
        raise RuntimeError(
            f"HUDS-ingestie afgerond met {len(errors)} fout(en): {list(errors.keys())}"
        )


@flow(name="ingest-huds", log_prints=True)
def ingest_huds_flow() -> None:
    """
    Prefect-flow: vernieuwt alle HUDS raw-tabellen in BigQuery vanuit Google Drive.

    Vervang of verwijder dit bestand niet: vervang alleen de source
    in ingest_huds_task() als de API beschikbaar is.
    """
    ingest_huds_task()


if __name__ == "__main__":
    ingest_huds_flow()
