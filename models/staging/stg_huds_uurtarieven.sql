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
        and trim(Rol) != ''

),

gededupliceerd as (

    select *
    from opgeschoond
    qualify row_number() over (
        partition by project_nummer, rol, start_datum
        order by uurtarief desc
    ) = 1

)

select * from gededupliceerd
