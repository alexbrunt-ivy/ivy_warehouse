-- dim_project.sql
-- Mart laag: Dimensie voor projecten, met alle relevante attributen.
-- Gebruikt int_projecten_verrijkt voor verrijking met bedrijfsinformatie.

with projecten_verrijkt as (

    select * from {{ ref('int_projecten_verrijkt') }}

),

gededupliceerd as (

    select *
    from projecten_verrijkt
    qualify row_number() over (
        partition by project_nummer
        order by project_id desc
    ) = 1

),

-- Haal projectnummers op die in uren/planning/facturen voorkomen maar niet in projecten.
-- Dit voorkomt broken relationships in fct_* tabellen.
projectnummers_uit_uren as (

    select distinct project_nummer from {{ ref('stg_huds_uren') }}
    where project_nummer is not null

),

projectnummers_uit_planning as (

    select distinct project_nummer from {{ ref('stg_huds_uren_omzet_planning') }}
    where project_nummer is not null

),

projectnummers_uit_realisatie as (

    select distinct project_nummer from {{ ref('stg_huds_uren_omzet_realisatie') }}
    where project_nummer is not null

),

projectnummers_uit_facturatie as (

    select distinct project_nummer from {{ ref('stg_huds_facturatie_overzicht') }}
    where project_nummer is not null

),

alle_bekende_projectnummers as (

    select project_nummer from projectnummers_uit_uren
    union distinct
    select project_nummer from projectnummers_uit_planning
    union distinct
    select project_nummer from projectnummers_uit_realisatie
    union distinct
    select project_nummer from projectnummers_uit_facturatie

),

ontbrekende_projectnummers as (

    select project_nummer
    from alle_bekende_projectnummers
    where project_nummer not in (select project_nummer from gededupliceerd)

),

fallback as (

    select
        project_nummer,
        -1                      as project_id,
        cast(null as string)    as bedrijf_id,
        cast(null as string)    as hubspot_bedrijf_id,
        'Onbekend project'      as projectnaam,
        cast(null as string)    as opdrachtgever,
        'Onbekend'              as bedrijfsentiteit,
        'Onbekend'              as status,
        cast(null as string)    as goedkeuring,
        cast(null as string)    as account_manager,
        cast(null as string)    as project_manager,
        cast(null as date)      as start_datum,
        cast(null as string)    as gekoppelde_bedrijfsnaam,
        cast(null as string)    as website,
        cast(null as string)    as adres,
        cast(null as string)    as stad,
        cast(null as string)    as land,
        cast(null as string)    as sales_lead,
        cast(null as string)    as normalized_name
    from ontbrekende_projectnummers

),

final as (

    select * from gededupliceerd
    union all
    select * from fallback

)

select * from final