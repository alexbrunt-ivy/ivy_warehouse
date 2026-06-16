-- stg_huds_uurtarieven.sql
-- Staging laag: opschonen en type-casting van de ruwe HUDS uurtarieven-export.

with bron as (

    select * from {{ source('huds', 'raw_huds_uurtarieven') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(Projectnummer as INT64)        as project_nummer,

        -- === Attributen ===
        trim(Rol)                           as rol,
        cast(Uurtarief as FLOAT64)          as uurtarief,

        -- === Datums ===
        Start_datum                         as start_datum

    from bron
    where Projectnummer is not null

)

select * from opgeschoond
