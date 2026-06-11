from prefect import flow
from prefect_dbt import PrefectDbtRunner

@flow(name="ivy-dbt-run", log_prints=True)
def run_dbt(select: str = ""):
    runner = PrefectDbtRunner(
        project_dir=".",
        profiles_dir="~/.dbt",
    )
    args = ["run"]
    if select:
        args += ["--select", select]
    runner.invoke(args)