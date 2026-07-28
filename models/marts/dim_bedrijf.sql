-- dim_bedrijf.sql
-- Mart laag: Dimensie voor bedrijven, gecombineerd uit HUDS en HubSpot.

with bedrijven as (

    select * from {{ ref('int_bedrijven_samengevoegd') }}

),

final as (

    select
        -- === Keys ===
        {{ dbt_utils.generate_surrogate_key(['bedrijf_id', 'hubspot_bedrijf_id']) }} as bedrijf_key,
        bedrijf_id,
        hubspot_bedrijf_id,

        -- === Attributen ===
        bedrijfsnaam,
        huds_bedrijfsnaam,
        hubspot_bedrijfsnaam,
        normalized_name,
        website,
        huds_beschrijving,
        hubspot_beschrijving,
        sales_lead,

        -- === Locatie ===
        adres,
        stad,
        land,

        -- === Timestamps ===
        huds_aangemaakt_op,
        hubspot_aangemaakt_op,
        hubspot_geupdated_op

    from bedrijven

)

select * from final