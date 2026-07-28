with bron as (

    select * from {{ source('huds', 'raw_huds_uurtarieven') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(Projectnummer as INT64)        as project_nummer,

        -- === Attributen ===
        trim(Rol)                           as rol,
        safe_cast(Uurtarief as NUMERIC)          as uurtarief,

        -- === Datums ===
        safe_cast(`Start datum` as DATE)      as start_datum

    from bron
    where Projectnummer is not null
        and cast(Projectnummer as string) != ''
        and trim(Rol) != ''

),

gededupliceerd as (

    {{ dbt_utils.deduplicate(
        relation='opgeschoond',
        partition_by='project_nummer, rol, start_datum',
        order_by='uurtarief desc'
    ) }}

)

select * from gededupliceerd