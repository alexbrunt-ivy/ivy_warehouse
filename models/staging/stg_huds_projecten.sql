with bron as (

    select * from {{ source('huds', 'raw_huds_projecten') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(Project_nummer as INT64)       as project_nummer,
        cast(Id as INT64)                   as project_id,

        -- === Attributen ===
        trim(Projectnaam)                   as projectnaam,
        trim(Opdrachtgever)                 as opdrachtgever,
        trim(Bedrijfs_entiteit)             as bedrijfsentiteit,
        trim(Status)                        as status,
        trim(Goedkeuring)                   as goedkeuring,
        trim(Accountmanager)                as accountmanager,
        trim(Project_managers)              as project_managers,

        -- === Datums ===
        Start_Datum                         as start_datum

    from bron
    where Project_nummer is not null

)

select * from opgeschoond
