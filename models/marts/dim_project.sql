-- dim_projecten.sql
-- Mart laag: Specifieke selectie voor projectmanagement en accountmanagement rapportages.

with staging_projecten as (

    select * from {{ ref('stg_huds_projecten') }}

),

final as (

    select
        project_nummer,
        projectnaam,
        project_managers as project_manager,  -- hernoemd naar enkelvoud conform je aanvraag
        accountmanager   as account_manager   -- _ toegevoegd voor consistente snake_case

    from staging_projecten

)

select * from final