-- stg_huds_werknemers_intern.sql
-- Staging laag: opschonen en type-casting van de ruwe HUDS werknemers intern-export.

with bron as (

    select * from {{ source('huds', 'raw_huds_werknemers_intern') }}

),

opgeschoond as (

    select
        -- === Sleutels / ID's ===
        -- Nummer casten we naar een STRING (of INT64 als het puur een getal is)
        cast(Nummer as STRING)                  as werknemer_id,

        -- === Attributen ===
        trim(Naam)                              as werknemer_naam,
        trim(Afdeling)                          as afdeling

    from bron
    -- Filter eventuele lege rijen uit de Google Sheet die geen nummer hebben
    where Nummer is not null

)

select * from opgeschoond