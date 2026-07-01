with bron as (

    select * from {{ source('hubspot', 'raw_hubspot_contacts') }}

),

opgeschoond as (

    select
        -- === Keys ===
        trim(id) as contact_id,
        trim(contact_id_pi) as contact_id_pi,
        trim(associatedcompanyid) as associated_company_id,
        trim(associated_company_id_pi) as associated_company_id_pi,
        trim(company_id) as company_id,

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
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(associatedcompanylastupdated)),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(associatedcompanylastupdated)),
            timestamp_millis(safe_cast(trim(associatedcompanylastupdated) as INT64))
        ) as associated_company_last_updated_at,
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

        -- === Contactgegevens ===
        trim(firstname) as first_name,
        trim(lastname) as last_name,
        trim(email) as email,
        trim(company) as company,
        trim(associated_company) as associated_company,
        trim(company_owner_pi) as company_owner_pi,
        trim(address) as address,
        trim(city) as city,
        trim(country) as country,

        -- === Marketing / bron ===
        trim(apollo_source) as apollo_source,
        trim(admin__form_stage) as admin_form_stage,
        trim(aiquizfase) as ai_quiz_fase,
        trim(blog_profielen_37199062656_subscription) as blog_profielen_subscription,
        case
            when lower(trim(currentlyinworkflow)) in ('true', '1', 'yes', 'ja') then true
            when lower(trim(currentlyinworkflow)) in ('false', '0', 'no', 'nee') then false
            else null
        end as is_currently_in_workflow,

        -- === Downloads ===
        safe_cast(trim(aantal_keer_fmeca_tool_gedownload) as INT64) as aantal_keer_fmeca_tool_gedownload,
        safe_cast(trim(aantal_keer_hazop_gedownload) as INT64) as aantal_keer_hazop_gedownload,
        safe_cast(trim(aantal_keer_wbda_tool_gedownload) as INT64) as aantal_keer_wbda_tool_gedownload,

        -- === Scores ===
        safe_cast(trim(combined_score) as NUMERIC) as combined_score,
        safe_cast(trim(combined_score_engagement) as NUMERIC) as combined_score_engagement,
        safe_cast(trim(combined_score_fit) as NUMERIC) as combined_score_fit,
        safe_cast(trim(combined_score_threshold) as NUMERIC) as combined_score_threshold,

        -- === Stage submissions ===
        safe_cast(trim(astage_submissions) as INT64) as astage_submissions,
        safe_cast(trim(cstage_submissions) as INT64) as cstage_submissions,

        -- === AI scan antwoorden ===
        trim(aiscan1) as aiscan1,
        trim(aiscan2) as aiscan2,
        trim(aiscan3) as aiscan3,
        trim(aiscan4) as aiscan4,
        trim(aiscan5) as aiscan5,
        trim(aiscan6) as aiscan6,
        trim(aiscan7) as aiscan7,
        trim(aiscan8) as aiscan8,
        trim(aiscan9) as aiscan9,
        trim(aiscan10) as aiscan10,
        trim(aiscan11) as aiscan11,
        trim(aiscan12) as aiscan12,
        trim(aiscan13) as aiscan13

    from bron
    where id is not null

)

select * from opgeschoond
