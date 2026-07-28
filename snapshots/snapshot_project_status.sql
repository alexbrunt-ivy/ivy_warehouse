-- snapshot_project_status.sql
-- SCD type 2 snapshot van projecten.
-- Houdt bij wanneer de status, goedkeuring, accountmanager of projectmanager wijzigt.
-- Gebruik: dbt snapshot
-- Dit is puur een historisch archief (optie 1 uit het plan).
-- De actuele versie (dbt_valid_to is null) is dezelfde als dim_project.

{% snapshot snapshot_project_status %}

{{
    config(
        target_schema='snapshots',
        unique_key='project_nummer',
        strategy='check',
        check_cols=['status', 'goedkeuring', 'accountmanager', 'project_managers'],
        invalidate_hard_deletes=True
    )
}}

select
    project_nummer,
    project_id,
    projectnaam,
    opdrachtgever,
    bedrijfsentiteit,
    status,
    goedkeuring,
    accountmanager,
    project_managers,
    start_datum
from {{ ref('stg_huds_projecten') }}

{% endsnapshot %}