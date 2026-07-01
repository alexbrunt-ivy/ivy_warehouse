with bron as (

    select * from {{ source('hubspot', 'raw_hubspot_companies') }}

),

opgeschoond as (

    select
        -- === Keys ===
        trim(id) as company_id,

        -- === Timestamps ===
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(created_at)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(created_at))
        ) as created_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(updated_at)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(updated_at))
        ) as updated_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(createdate)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(createdate)),
            timestamp_millis(safe_cast(trim(createdate) as INT64))
        ) as hubspot_created_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(closedate)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(closedate)),
            timestamp_millis(safe_cast(trim(closedate) as INT64))
        ) as closed_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(first_contact_createdate)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(first_contact_createdate)),
            timestamp_millis(safe_cast(trim(first_contact_createdate) as INT64))
        ) as first_contact_created_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(first_conversion_date)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(first_conversion_date)),
            timestamp_millis(safe_cast(trim(first_conversion_date) as INT64))
        ) as first_conversion_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(first_deal_created_date)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(first_deal_created_date)),
            timestamp_millis(safe_cast(trim(first_deal_created_date) as INT64))
        ) as first_deal_created_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(datum_toegevoegd_teamleader)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(datum_toegevoegd_teamleader)),
            timestamp_millis(safe_cast(trim(datum_toegevoegd_teamleader) as INT64))
        ) as datum_toegevoegd_teamleader,
        coalesce(
            safe_cast(_loaded_at as TIMESTAMP),
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(cast(_loaded_at as STRING))),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(cast(_loaded_at as STRING)))
        ) as loaded_at,

        -- === Bedrijfsprofiel ===
        trim(domain) as domain,
        trim(about_us) as about_us,
        trim(description) as description,
        trim(address) as address,
        trim(address2) as address2,
        trim(city) as city,
        trim(country) as country,
        trim(facebook_company_page) as facebook_company_page,

        -- === Teamleader / sales ===
        safe_cast(trim(aantal_deals_teamleader) as INT64) as aantal_deals_teamleader,
        safe_cast(trim(days_to_close) as INT64) as days_to_close,
        trim(first_conversion_event_name) as first_conversion_event_name,

        -- === Financieel ===
        safe_cast(trim(annualrevenue) as NUMERIC) as annual_revenue,
        safe_cast(trim(founded_year) as INT64) as founded_year,

        -- === HubSpot metadata ===
        trim(hs_additional_domains) as hs_additional_domains,
        trim(hs_all_owner_ids) as hs_all_owner_ids,
        trim(hs_all_team_ids) as hs_all_team_ids,
        trim(hs_all_accessible_team_ids) as hs_all_accessible_team_ids,
        trim(hs_all_assigned_business_unit_ids) as hs_all_assigned_business_unit_ids,

        -- === Analytics samenvatting ===
        trim(hs_analytics_source) as hs_analytics_source,
        trim(hs_analytics_source_data_1) as hs_analytics_source_data_1,
        trim(hs_analytics_source_data_2) as hs_analytics_source_data_2,
        trim(hs_analytics_latest_source) as hs_analytics_latest_source,
        trim(hs_analytics_latest_source_data_1) as hs_analytics_latest_source_data_1,
        trim(hs_analytics_latest_source_data_2) as hs_analytics_latest_source_data_2,
        safe_cast(trim(hs_analytics_num_page_views) as INT64) as hs_analytics_num_page_views,
        safe_cast(trim(hs_analytics_num_visits) as INT64) as hs_analytics_num_visits,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(hs_analytics_first_timestamp)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(hs_analytics_first_timestamp)),
            timestamp_millis(safe_cast(trim(hs_analytics_first_timestamp) as INT64))
        ) as hs_analytics_first_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(hs_analytics_last_timestamp)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(hs_analytics_last_timestamp)),
            timestamp_millis(safe_cast(trim(hs_analytics_last_timestamp) as INT64))
        ) as hs_analytics_last_at,
        coalesce(
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(hs_analytics_latest_source_timestamp)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(hs_analytics_latest_source_timestamp)),
            timestamp_millis(safe_cast(trim(hs_analytics_latest_source_timestamp) as INT64))
        ) as hs_analytics_latest_source_at,

        -- === Meetings ===
        trim(engagements_last_meeting_booked) as engagements_last_meeting_booked

    from bron
    where id is not null

)

select * from opgeschoond
