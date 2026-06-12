import os
import logging
from typing import List

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery
from hubspot import HubSpot

# Load environment variables
load_dotenv()

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

logger = logging.getLogger("hubspot_ingest")

# Configuration
BQ_PROJECT = os.getenv("BQ_PROJECT_ID", "ivy-warehouse")
BQ_DATASET = "raw_hubspot"

# Google credentials
SERVICE_ACCOUNT_FILE = os.getenv(
    "GOOGLE_APPLICATION_CREDENTIALS"
)

if SERVICE_ACCOUNT_FILE and os.path.exists(
    SERVICE_ACCOUNT_FILE
):
    os.environ[
        "GOOGLE_APPLICATION_CREDENTIALS"
    ] = SERVICE_ACCOUNT_FILE


def load_access_token() -> str:
    """Load HubSpot token from .env"""

    token = os.getenv(
        "HUBSPOT_ACCESS_TOKEN"
    )

    if not token:
        raise ValueError(
            "HUBSPOT_ACCESS_TOKEN not found in .env"
        )

    return token


def get_all_properties(
    client: HubSpot,
    object_type: str,
) -> List[str]:
    """
    Retrieve all available HubSpot properties.
    """

    logger.info(
        f"Getting available properties for {object_type}..."
    )

    try:
        properties = (
            client.crm.properties.core_api.get_all(
                object_type=object_type
            )
        )

        return [
            prop.name
            for prop in properties.results
        ]

    except Exception as e:
        logger.error(
            f"Error retrieving properties: {e}"
        )
        return []


def get_all_records(
    client: HubSpot,
    object_type: str,
    properties: List[str],
) -> pd.DataFrame:
    """
    Retrieve all records from HubSpot using pagination.
    """

    logger.info(
        f"Getting all records for {object_type}..."
    )

    try:

        all_records = []

        api = getattr(
            client.crm,
            object_type,
        ).basic_api

        # IMPORTANT:
        # Limit property count to avoid HubSpot 414 URI errors
        important = [
            "firstname",
            "lastname",
            "email",
            "name",
            "domain",
            "industry",
            "annual_revenue",
        ]

        props_to_request = [
            p
            for p in properties
            if p in important
        ]

        for p in properties:
            if (
                p not in props_to_request
                and len(props_to_request) < 100
            ):
                props_to_request.append(p)

        after = None

        while True:

            response = api.get_page(
                limit=100,
                properties=props_to_request,
                after=after,
            )

            for item in response.results:

                record = {
                    "id": item.id,
                    "created_at": str(
                        item.created_at
                    ),
                    "updated_at": str(
                        item.updated_at
                    ),
                }

                if item.properties:
                    record.update(
                        item.properties
                    )

                all_records.append(
                    record
                )

            if (
                response.paging
                and response.paging.next
            ):
                after = (
                    response.paging.next.after
                )
            else:
                break

        df = pd.DataFrame(
            all_records
        )

        logger.info(
            f"Successfully retrieved {len(df)} records for {object_type}"
        )

        return df

    except Exception as e:

        logger.error(
            f"Error retrieving records: {e}"
        )

        return pd.DataFrame()


def load_to_bigquery(
    df: pd.DataFrame,
    table_name: str,
):
    """
    Load dataframe into BigQuery.
    """

    logger.info(
        f"Loading {len(df)} rows into "
        f"{BQ_PROJECT}.{BQ_DATASET}.{table_name}"
    )

    client = bigquery.Client(
        project=BQ_PROJECT
    )

    table_ref = (
        f"{BQ_PROJECT}."
        f"{BQ_DATASET}."
        f"{table_name}"
    )

    job_config = (
        bigquery.LoadJobConfig(
            write_disposition=
            bigquery.WriteDisposition.WRITE_TRUNCATE,
            autodetect=True,
        )
    )

    job = (
        client.load_table_from_dataframe(
            df,
            table_ref,
            job_config=job_config,
        )
    )

    job.result()

    logger.info(
        f"Successfully loaded {table_ref}"
    )


def ingest_hubspot():
    """
    Main HubSpot ingestion function.
    Used by Prefect flows.
    """

    token = load_access_token()

    client = HubSpot(
        access_token=token
    )

    objects_to_ingest = [
        "contacts",
        "companies",
    #    "deals",
    ]

    for obj in objects_to_ingest:

        logger.info(
            f"Starting ingestion of {obj}"
        )

        properties = (
            get_all_properties(
                client,
                obj,
            )
        )

        if not properties:
            continue

        df = get_all_records(
            client,
            obj,
            properties,
        )

        if df.empty:
            logger.warning(
                f"No data returned for {obj}"
            )
            continue

        # Remove empty columns
        df.dropna(
            axis=1,
            how="all",
            inplace=True,
        )

        # Convert everything to string
        df = df.astype(str)

        # Replace string null values
        df = (
            df.replace(
                "None",
                None,
            )
            .replace(
                "nan",
                None,
            )
        )

        # Warehouse load timestamp
        df["_loaded_at"] = (
            pd.Timestamp.utcnow()
        )

        table_name = (
            f"raw_hubspot_{obj}"
        )

        load_to_bigquery(
            df,
            table_name,
        )

        logger.info(
            f"Finished ingestion of {obj}"
        )


def main():
    ingest_hubspot()


if __name__ == "__main__":
    main()