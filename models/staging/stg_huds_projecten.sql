with bron as (

    select * from {{ source('huds', 'raw_huds_projecten') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(`Project nummer` as INT64)       as project_nummer,
        cast(Id as INT64)                   as project_id,

        -- === Attributen ===
        trim(Projectnaam)                   as projectnaam,
        trim(Opdrachtgever)                 as opdrachtgever,
        trim(`Bedrijfs entiteit`)             as bedrijfsentiteit,
        trim(Status)                        as status,
        trim(Goedkeuring)                   as goedkeuring,
        trim(Accountmanager)                as accountmanager,
        trim(`Project managers`)              as project_managers,

        -- === Datums ===
        `Start datum`                         as start_datum

    from bron
    where `Project nummer` is not null

)

select * from opgeschoond
