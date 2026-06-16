-- stg_huds_uren.sql
-- Staging laag: opschonen en type-casting van de ruwe HUDS uren-export.

with bron as (

    select * from {{ source('huds', 'raw_huds_uren') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(Nummer as INT64)               as uren_nummer,

        -- === Timestamps ===
        Created_at                          as created_at,
        Start                               as start_tijdstip,
        Einde                               as einde_tijdstip,

        -- === Medewerker ===
        trim(Naam)                          as medewerker_naam,
        trim(Werknemer_Type)                as werknemer_type,
        trim(Functie)                       as functie,
        trim(Rol)                           as rol,

        -- === Organisatie ===
        trim(Bedrijfs_Entiteit)             as bedrijfsentiteit,
        trim(Kostenplaats)                  as kostenplaats,
        trim(Afdeling)                      as afdeling,
        trim(Business_entity)              as business_entity,
        trim(Regio)                         as regio,

        -- === Project ===
        trim(Project)                       as project,
        trim(Opdrachtgever)                 as opdrachtgever,
        trim(Type_dienst)                   as type_dienst,
        trim(Projectmanagers)               as project_managers,
        trim(Accountmanager)                as accountmanager,

        -- === Uren & Tijd ===
        cast(Tijd_gewerkt as INT64)         as tijd_gewerkt_minuten,
        cast(Pauze_in_minuten as INT64)     as pauze_minuten,
        cast(Uren as FLOAT64)              as uren,

        -- === Status & Locatie ===
        trim(Status)                        as status,
        trim(Locatie)                       as locatie,

        -- === Financieel ===
        trim(Tarief)                        as tarief

    from bron
    where Nummer is not null

)

select * from opgeschoond
