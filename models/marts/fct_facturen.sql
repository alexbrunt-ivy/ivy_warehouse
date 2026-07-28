-- fct_facturen.sql
-- Mart laag: Feitentabel voor facturen.
-- Grain: 1 rij per factuur_nummer (let op: niet uniek, hergebruikt per project)
-- Incremental: alleen nieuwe/gewijzigde facturen worden verwerkt.

{{
    config(
        materialized='incremental',
        unique_key=['factuur_nummer', 'project_nummer', 'factuurdatum'],
        on_schema_change='append_new_columns'
    )
}}

with facturen_verrijkt as (

    select * from {{ ref('int_facturen_verrijkt') }}

),

final as (

    select
        -- === Foreign Keys ===
        {{ dbt_utils.generate_surrogate_key(['factuur_nummer', 'project_nummer', 'coalesce(factuurdatum, current_date())']) }} as factuur_key,
        {{ dbt_utils.generate_surrogate_key(['project_nummer']) }} as project_key,
        {{ dbt_utils.generate_surrogate_key(['huds_bedrijf_id']) }} as bedrijf_key,
        factuur_nummer,
        project_nummer,
        huds_bedrijf_id,

        -- === Datums ===
        factuurdatum,
        vervaldatum,
        factuur_aangemaakt_op,

        -- === Financieel ===
        bedrag_inc_btw,
        betalingstermijn_dagen,

        -- === Status ===
        originele_status,
        is_factuur_voldaan,
        factuur_status_categorie,
        dagen_overdue,
        aantal_herinneringen_gestuurd,

        -- === Context ===
        originele_opdrachtgever_naam,
        gekoppelde_bedrijfsnaam,
        projectnaam_uit_factuur,
        gekoppelde_projectnaam,
        procedure_type,
        periode,
        bedrijfsentiteit

    from facturen_verrijkt

)

select * from final