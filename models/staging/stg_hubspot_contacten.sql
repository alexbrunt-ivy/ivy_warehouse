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
        {{ parse_timestamp('created_at') }} as created_at,
        {{ parse_timestamp('updated_at') }} as updated_at,
        {{ parse_timestamp('createdate') }} as hubspot_created_at,
        {{ parse_timestamp('closedate') }} as closed_at,
        {{ parse_timestamp('associatedcompanylastupdated') }} as associated_company_last_updated_at,
        {{ parse_timestamp('datum_toegevoegd_teamleader') }} as datum_toegevoegd_teamleader,
        safe_cast(_loaded_at as TIMESTAMP) as loaded_at,

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
        safe_cast(trim(cstage_submissions) as INT64) as cstage_submissions

    from bron
    where id is not null

)

select * from opgeschoond
