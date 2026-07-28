-- snapshot_factuur_status.sql
-- SCD type 2 snapshot van facturen.
-- Houdt bij wanneer de betaalstatus, vervaldatum of aantal herinneringen wijzigt.
-- Gebruik: dbt snapshot

{% snapshot snapshot_factuur_status %}

{{
    config(
        target_schema='snapshots',
        unique_key='factuur_nummer',
        strategy='check',
        check_cols=['status', 'is_factuur_voldaan', 'dagen_overdue', 'aantal_herinneringen_gestuurd'],
        invalidate_hard_deletes=True
    )
}}

select
    factuur_nummer,
    project_nummer,
    factuurdatum,
    vervaldatum,
    status,
    is_factuur_voldaan,
    bedrag_inc_btw,
    dagen_overdue,
    aantal_herinneringen_gestuurd,
    betalingstermijn_dagen,
    opdrachtgever,
    bedrijfsentiteit
from {{ ref('stg_huds_facturen') }}

{% endsnapshot %}