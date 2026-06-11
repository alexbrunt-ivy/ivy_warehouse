from prefect import flow
from flows.dbt_flow import run_dbt

@flow(name="ivy-pipeline", log_prints=True)
def pipeline():
    run_dbt()

if __name__ == "__main__":
    pipeline()