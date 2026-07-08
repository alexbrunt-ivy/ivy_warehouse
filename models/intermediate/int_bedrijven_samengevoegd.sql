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
        hubspot.bedrijf_id as hubspot_bedrijf_id,

        -- === Attributen ===
        coalesce(huds.bedrijfsnaam, hubspot.bedrijfsnaam) as bedrijfsnaam,
        huds.bedrijfsnaam as huds_bedrijfsnaam,
        hubspot.bedrijfsnaam as hubspot_bedrijfsnaam,
        huds.normalized_name,
        hubspot.website as website,
        huds.beschrijving as huds_beschrijving,
        hubspot.beschrijving as hubspot_beschrijving,
        huds.sales_lead,

        -- === Locatie ===
        NULLIF(TRIM(CONCAT(COALESCE(hubspot.straat, ''), ' ', COALESCE(hubspot.huisnummer, ''))), '') as adres,
        hubspot.stad as stad,
        hubspot.land as land,

        -- === Timestamps ===
        huds.aangemaakt_op as huds_aangemaakt_op,
        hubspot.created_at as hubspot_aangemaakt_op,
        hubspot.updated_at as hubspot_geupdated_op,
        hubspot.loaded_at as hubspot_loaded_at

    from huds_bedrijven as huds
    full outer join hubspot_bedrijven as hubspot
        on huds.normalized_name = hubspot.normalized_name

)

select * from final
