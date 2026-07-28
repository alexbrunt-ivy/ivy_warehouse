with bron as (

    select * from {{ source('hubspot', 'raw_hubspot_companies') }}

),

opgeschoond as (

    select
        -- === Keys ===
        trim(id) as bedrijf_id,

        -- === Timestamps ===
        {{ parse_timestamp('created_at') }} as created_at,
        {{ parse_timestamp('updated_at') }} as updated_at,
        {{ parse_timestamp('createdate') }} as hubspot_created_at,
        {{ parse_timestamp('closedate') }} as closed_at,
        {{ parse_timestamp('first_contact_createdate') }} as first_contact_created_at,
        {{ parse_timestamp('first_conversion_date') }} as first_conversion_at,
        {{ parse_timestamp('first_deal_created_date') }} as first_deal_created_at,
        {{ parse_timestamp('datum_toegevoegd_teamleader') }} as datum_toegevoegd_teamleader,
        safe_cast(_loaded_at as TIMESTAMP) as loaded_at,

        -- === Bedrijfsprofiel ===
        trim(name) as bedrijfsnaam,
        {{ normalize_bedrijfsnaam('name') }} as normalized_name,
        trim(domain) as website,
        trim(about_us) as about_us,
        trim(description) as beschrijving,
        trim(address) as straat,
        trim(address2) as huisnummer,
        trim(city) as stad,
        trim(country) as land,
        trim(facebook_company_page) as facebook_pagina,

        -- === Teamleader / sales ===
        safe_cast(trim(aantal_deals_teamleader) as INT64) as aantal_deals_teamleader,
        safe_cast(trim(days_to_close) as INT64) as days_to_close,
        trim(first_conversion_event_name) as first_conversion_event_name,

        -- === Financieel ===
        safe_cast(trim(annualrevenue) as NUMERIC) as jaarlijkse_omzet,
        safe_cast(trim(founded_year) as INT64) as jaar_opgegericht,

        -- === Analytics samenvatting (kernvelden) ===
        trim(hs_analytics_source) as hs_analytics_source,
        trim(hs_analytics_latest_source) as hs_analytics_latest_source,
        safe_cast(trim(hs_analytics_num_page_views) as INT64) as hs_analytics_num_page_views,
        safe_cast(trim(hs_analytics_num_visits) as INT64) as hs_analytics_num_visits,
        {{ parse_timestamp('hs_analytics_first_timestamp') }} as hs_analytics_first_at,
        {{ parse_timestamp('hs_analytics_last_timestamp') }} as hs_analytics_last_at,
        {{ parse_timestamp('hs_analytics_latest_source_timestamp') }} as hs_analytics_latest_source_at,

        -- === Meetings ===
        trim(engagements_last_meeting_booked) as engagements_last_meeting_booked

    from bron
    where id is not null

)

select * from opgeschoond