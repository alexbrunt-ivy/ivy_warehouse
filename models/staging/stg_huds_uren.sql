with bron as (

    select * from {{ source('huds', 'raw_huds_uren') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(Nummer as INT64)               as uren_nummer,

        -- === Timestamps ===
        `Created at`                          as created_at,
        DATETIME(SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S %Ez', Start),'Europe/Amsterdam') AS start_tijdstip,
        DATETIME(SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S %Ez', Einde),'Europe/Amsterdam') AS einde_tijdstip,

        -- === Medewerker ===
        trim(Naam)                          as medewerker_naam,
        trim(`Werknemer Type`)                as werknemer_type,
        trim(Functie)                       as functie,
        trim(Rol)                           as rol,

        -- === Organisatie ===
        trim(`Bedrijfs Entiteit`)             as bedrijfsentiteit,
        trim(Kostenplaats)                  as kostenplaats,
        trim(Afdeling)                      as afdeling,
        trim(`Business entity`)               as business_entity,
        trim(Regio)                         as regio,

        -- === Project ===
        {{ huds_parse_project('Project') }},
        trim(Opdrachtgever)                 as opdrachtgever,
        trim(`Type dienst`)                   as type_dienst,
        trim(Projectmanagers)               as project_managers,
        trim(Accountmanager)                as accountmanager,

        -- === Uren & Tijd ===
        cast(`Tijd gewerkt` as INT64)         as tijd_gewerkt_minuten,
        cast(`Pauze in minuten` as INT64)     as pauze_minuten,
        cast(Uren as FLOAT64)               as uren,

        -- === Status & Locatie ===
        trim(Status)                        as status,
        trim(Locatie)                       as locatie,

        -- === Financieel ===
        trim(Tarief)                        as tarief

    from bron

)

select * from opgeschoond
