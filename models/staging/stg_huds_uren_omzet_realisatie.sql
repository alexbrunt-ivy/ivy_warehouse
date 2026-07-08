with bron as (

    select * from {{ source('huds', 'raw_huds_uren_omzet_realisatie') }}

),

opgeschoond as (

    select
        -- === Attributen ===
        {{ huds_parse_project('Project') }},
        trim(Account)                               as account,
        trim(Type_dienst)                           as type_dienst,
        trim(Business_entity)                       as business_entity,
        trim(Regio)                                 as regio,
        trim(Projectmanagers)                       as project_managers,
        trim(Accountmanager)                        as accountmanager,

        -- === Datums ===
        cast(Periode as Date)                       as periode,

        -- === Totalen ===
        cast(Totaal_uren as FLOAT64)                as totaal_uren,
        cast(Totaal_omzet as FLOAT64)               as totaal_omzet,

        -- === Uren per Rol ===
        cast(Uren_projectmanager as FLOAT64)        as uren_projectmanager,
        cast(Uren_projectleider as FLOAT64)         as uren_projectleider,
        cast(Uren_medewerker as FLOAT64)            as uren_medewerker,
        cast(Uren_projectengineer as FLOAT64)       as uren_projectengineer,

        -- === Omzet per Rol ===
        cast(Omzet_projectmanager as FLOAT64)       as omzet_projectmanager,
        cast(Omzet_projectleider as FLOAT64)        as omzet_projectleider,
        cast(Omzet_medewerker as FLOAT64)           as omzet_medewerker,
        cast(Omzet_projectengineer as FLOAT64)      as omzet_projectengineer

    from bron

)

select * from opgeschoond
where totaal_uren > 0
