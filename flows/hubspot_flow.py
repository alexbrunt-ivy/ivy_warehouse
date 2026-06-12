from prefect import flow

from flows.ingestion.hubspot import ingest_hubspot


@flow(
    name="hubspot-ingestion",
    log_prints=True,
)
def ingest_hubspot_flow():

    ingest_hubspot()


if __name__ == "__main__":
    ingest_hubspot_flow()