import os
from prefect import flow
from prefect_dbt import PrefectDbtRunner
from prefect_dbt.core.settings import PrefectDbtSettings

@flow(name="ivy-dbt-run", log_prints=True)
def run_dbt(select: str = ""):
    settings = PrefectDbtSettings(
        project_dir=".",
        profiles_dir=os.path.expanduser("~/.dbt"),
    )
    runner = PrefectDbtRunner(settings=settings)

    # Seeds first - reference data needed by models
    runner.invoke(["seed"])

    # Snapshots - captures SCD history before models run
    # (currently a no-op until you define snapshots, but safe to leave in)
    runner.invoke(["snapshot"])

    run_args = ["run"]
    test_args = ["test"]
    if select:
        run_args += ["--select", select]
        test_args += ["--select", select]

    runner.invoke(run_args)
    runner.invoke(test_args)