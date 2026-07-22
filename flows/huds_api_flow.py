import logging
import datetime
from typing import Optional
from prefect import flow, task, get_run_logger

from flows.ingestion.huds_api import (
    fetch_huds_totalen_from_api,
    transform_huds_totalen,
    load_totalen_to_bigquery,
    get_huds_api_token,
)


@task(name="ingest-huds-month-api", retries=2, retry_delay_seconds=15, log_prints=True)
def ingest_huds_month_task(year: int, month: int, token: Optional[str] = None) -> int:
    """
    Prefect Task: Haalt data op voor 1 specifieke maand, transformeert deze en laadt het naar BigQuery.
    """
    logger = get_run_logger()
    logger.info(f"Start ingestie HUDS totaaldata voor jaar={year}, maand={month}")

    # 1. API Call
    raw_json = fetch_huds_totalen_from_api(year=year, month=month, token=token)

    # 2. Transformeren
    df = transform_huds_totalen(raw_json)
    logger.info(f"Data getransformeerd: {len(df)} rijen voor regio's.")

    # 3. Laden naar BigQuery
    load_totalen_to_bigquery(df)
    
    return len(df)


@flow(name="ingest-huds-api-single-month", log_prints=True)
def ingest_huds_api_month_flow(
    year: Optional[int] = None,
    month: Optional[int] = None,
    token: Optional[str] = None
) -> None:
    """
    Prefect Flow: Ingesteert data voor 1 specifieke maand.
    Als jaar en maand niet worden meegegeven, pakt hij automatisch de huidige maand.
    """
    now = datetime.datetime.now()
    target_year = year or now.year
    target_month = month or now.month

    ingest_huds_month_task(year=target_year, month=target_month, token=token)


@flow(name="ingest-huds-api-backfill", log_prints=True)
def ingest_huds_api_backfill_flow(
    start_year: int,
    end_year: int,
    token: Optional[str] = None
) -> None:
    """
    Prefect Flow: Backfillt historische data voor een reeks jaren.
    Haalt voor elk jaar alle 12 maanden op.
    """
    logger = get_run_logger()
    logger.info(f"Start backfill van {start_year} t/m {end_year}")

    total_rows = 0
    for y in range(start_year, end_year + 1):
        for m in range(1, 13):
            try:
                rows = ingest_huds_month_task(year=y, month=m, token=token)
                total_rows += rows
            except Exception as exc:
                logger.error(f"Fout bij ophalen {y}-{m}: {exc}")

    logger.info(f"✓ Backfill voltooid! Totaal {total_rows} rijen verwerkt.")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    # Voorbeeld lokaal testen voor dec 2025:
    # ingest_huds_api_month_flow(year=2025, month=12)
