with bron as (

    select * from {{ source('huds', 'raw_huds_facturatie_overzicht') }}

),

opgeschoond as (

    select
        -- === Attributen ===
        trim(Project)                           as project,
        trim(Account)                           as account,
        trim(Goedkeuring)                       as goedkeuring,
        trim(Bedrijfsentiteit)                  as bedrijfsentiteit,
        trim(Uren_Status)                       as uren_status,
        trim(Status)                            as status,
        trim(`Procedure`)                       as procedure_type,
        trim(Beschrijving)                      as beschrijving,

        -- === Datums ===
        Periode                                 as periode,

        -- === Financieel ===
        cast(Totaal_uren as FLOAT64)            as totaal_uren,
        cast(Totaal_omzet as FLOAT64)           as totaal_omzet,
        cast(Niet_gefactureerd as FLOAT64)      as niet_gefactureerd,

        -- === Uren per Rol ===
        cast(Uren_projectmanager as FLOAT64)    as uren_projectmanager,
        cast(Uren_projectleider as FLOAT64)     as uren_projectleider,
        cast(Uren_projectengineer as FLOAT64)   as uren_projectengineer,
        cast(Uren_medewerker as FLOAT64)        as uren_medewerker

    from bron
    where Project is not null

)

select * from opgeschoond
