with huds_bedrijven as (

    select * from {{ ref('stg_huds_bedrijven') }}

),

hubspot_bedrijven as (

    select * from {{ ref('stg_hubspot_bedrijven') }}

),

final as (

    select
        -- === Keys ===
        huds.bedrijf_id,
        hubspot.company_id as hubspot_company_id,

        -- === Attributen ===
        huds.bedrijfsnaam,
        hubspot.domain,
        huds.beschrijving as huds_beschrijving,
        hubspot.description as hubspot_description,
        huds.sales_lead,

        -- === Locatie ===
        hubspot.address,
        hubspot.address2,
        hubspot.city,
        hubspot.country,

        -- === Timestamps ===
        huds.aangemaakt_op as huds_aangemaakt_op,
        hubspot.created_at as hubspot_created_at,
        hubspot.updated_at as hubspot_updated_at,
        hubspot.loaded_at as hubspot_loaded_at

    from huds_bedrijven as huds
    full outer join hubspot_bedrijven as hubspot
        on lower(trim(huds.bedrijfsnaam)) = lower(trim(hubspot.domain))

)

select * from final
