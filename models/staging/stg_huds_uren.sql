with bron as (

    select * from {{ source('huds', 'raw_huds_uren') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(Nummer as INT64)               as uren_nummer,

        -- === Timestamps ===
        {{ parse_timestamp('`Created at`') }} as created_at,
        DATETIME({{ parse_timestamp('Start') }}, 'Europe/Amsterdam') as start_tijdstip,
        DATETIME({{ parse_timestamp('Einde') }}, 'Europe/Amsterdam') as einde_tijdstip,

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
        safe_cast(replace(replace(trim(Tarief), '.', ''), ',', '.') as NUMERIC) as tarief

    from bron

)

select * from opgeschoond
