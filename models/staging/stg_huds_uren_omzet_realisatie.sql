with bron as (

    select * from {{ source('huds', 'raw_huds_uren_omzet_realisatie') }}

),

opgeschoond as (

    select
        -- === Attributen ===
        {{ huds_parse_project('Project') }},
        trim(Account)                               as account,
        trim(`Type dienst`)                           as type_dienst,
        trim(`Business entity`)                       as business_entity,
        trim(Regio)                                 as regio,
        trim(Projectmanagers)                       as project_managers,
        trim(Accountmanager)                        as accountmanager,

        -- === Datums ===
        cast(Periode as Date)                       as periode,

        -- === Totalen ===
        safe_cast(nullif(trim(`Totaal uren`), '') as FLOAT64)                as totaal_uren,
        safe_cast(nullif(trim(`Totaal omzet`), '') as FLOAT64)               as totaal_omzet,

        -- === Uren per Rol ===
        safe_cast(nullif(trim(`Uren projectmanager`), '') as FLOAT64)        as uren_projectmanager,
        safe_cast(nullif(trim(`Uren projectleider`), '') as FLOAT64)         as uren_projectleider,
        safe_cast(nullif(trim(`Uren medewerker`), '') as FLOAT64)            as uren_medewerker,
        safe_cast(nullif(trim(`Uren projectengineer`), '') as FLOAT64)       as uren_projectengineer,

        -- === Omzet per Rol ===
        safe_cast(nullif(trim(`Omzet projectmanager`), '') as FLOAT64)       as omzet_projectmanager,
        safe_cast(nullif(trim(`Omzet projectleider`), '') as FLOAT64)        as omzet_projectleider,
        safe_cast(nullif(trim(`Omzet medewerker`), '') as FLOAT64)           as omzet_medewerker,
        safe_cast(nullif(trim(`Omzet projectengineer`), '') as FLOAT64)      as omzet_projectengineer

    from bron

)

select * from opgeschoond
where totaal_uren > 0
