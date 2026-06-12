from prefect import flow


from flows.hubspot_flow import ingest_hubspot_flow
from flows.dbt_flow import run_dbt


@flow(
    name="ivy-pipeline",
    log_prints=True,
)
def pipeline():

    print("Starting HubSpot ingestion...")
    ingest_hubspot_flow()

    print("Starting dbt...")
    run_dbt()

    print("Pipeline complete.")


if __name__ == "__main__":
    pipeline()