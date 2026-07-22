with bron as (

    select * from {{ source('huds', 'raw_huds_facturatie_overzicht') }}

),

opgeschoond as (

    select
        -- === Attributen ===
        {{ huds_parse_project('Project') }},
        trim(Account)                           as account,
        trim(Goedkeuring)                       as goedkeuring,
        trim(Bedrijfsentiteit)                  as bedrijfsentiteit,
        trim(`Uren Status`)                       as uren_status,
        trim(Status)                            as status,
        trim(`Procedure`)                       as procedure_type,
        trim(Beschrijving)                      as beschrijving,

        -- === Datums ===
        cast(Periode as DATE)                   as periode,

        -- === Financieel ===
        safe_cast(nullif(trim(`Totaal uren`), '') as FLOAT64)            as totaal_uren,
        safe_cast(nullif(trim(`Totaal omzet`), '') as FLOAT64)           as totaal_omzet,
        safe_cast(nullif(trim(`Niet gefactureerd`), '') as FLOAT64)      as niet_gefactureerd,

        -- === Uren per Rol ===
        safe_cast(nullif(trim(`Uren projectmanager`), '') as FLOAT64)    as uren_projectmanager,
        safe_cast(nullif(trim(`Uren projectleider`), '') as FLOAT64)     as uren_projectleider,
        safe_cast(nullif(trim(`Uren projectengineer`), '') as FLOAT64)   as uren_projectengineer,
        safe_cast(nullif(trim(`Uren medewerker`), '') as FLOAT64)        as uren_medewerker

    from bron

)

select * from opgeschoond
where totaal_uren > 0
