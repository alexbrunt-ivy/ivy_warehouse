from prefect import flow

from flows.hubspot_flow import ingest_hubspot_flow
from flows.huds_flow import ingest_huds_flow
from flows.huds_api_flow import ingest_huds_api_month_flow
from flows.dbt_flow import run_dbt


@flow(
    name="ivy-pipeline",
    log_prints=True,
)
def pipeline():

    print("Starting HubSpot ingestion...")
    ingest_hubspot_flow()

    print("Starting HUDS ingestion from Google Drive...")
    ingest_huds_flow()

    print("Starting HUDS API ingestion (current month)...")
    ingest_huds_api_month_flow()

    print("Starting dbt...")
    run_dbt()

    print("Pipeline complete.")


if __name__ == "__main__":
    pipeline()