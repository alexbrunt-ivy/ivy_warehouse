-- int_projecten_verrijkt.sql
-- Intermediate laag: Projecten verrijkt met bedrijfsinformatie.
-- Dit model koppelt projecten aan bedrijven via genormaliseerde bedrijfsentiteit.
-- Doel: dim_project slanker maken en de bedrijfskoppeling centraliseren.

with projecten as (

    select * from {{ ref('stg_huds_projecten') }}

),

bedrijven as (

    select * from {{ ref('int_bedrijven_samengevoegd') }}

),

-- Normaliseer bedrijfsentiteit eenmalig voor de JOIN
projecten_met_normalized as (

    select
        *,
        {{ normalize_bedrijfsnaam('bedrijfsentiteit') }} as project_normalized_name
    from projecten

),

verrijkt as (

    select
        -- === Keys ===
        projecten.project_nummer,
        projecten.project_id,
        bedrijven.bedrijf_id,
        bedrijven.hubspot_bedrijf_id,

        -- === Project attributen ===
        projecten.projectnaam,
        projecten.opdrachtgever,
        projecten.bedrijfsentiteit,
        projecten.status,
        projecten.goedkeuring,
        projecten.accountmanager        as account_manager,
        projecten.project_managers      as project_manager,
        projecten.start_datum,

        -- === Bedrijfsinformatie ===
        bedrijven.bedrijfsnaam as gekoppelde_bedrijfsnaam,
        bedrijven.website,
        bedrijven.adres,
        bedrijven.stad,
        bedrijven.land,
        bedrijven.sales_lead,
        bedrijven.normalized_name

    from projecten_met_normalized as projecten
    left join bedrijven
        on projecten.project_normalized_name = bedrijven.normalized_name

)

select * from verrijkt