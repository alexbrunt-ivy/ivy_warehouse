-- fct_uren_omzet.sql
-- Mart laag: Samenvoeging van gerealiseerde uren/omzet (verleden) en geplande uren/omzet (toekomst).

with realisatie as (

    select
        project,
        account,
        type_dienst,
        business_entity,
        regio,
        project_managers                     as project_manager,
        accountmanager                       as account_manager,
        periode,
        totaal_uren,
        totaal_omzet,
        
        -- Uren per Rol
        uren_projectmanager,
        uren_projectleider,
        uren_medewerker,
        uren_projectengineer,
        cast(null as float64)                as uren_consultant,
        
        -- Omzet per Rol
        omzet_projectmanager,
        omzet_projectleider,
        omzet_medewerker,
        omzet_projectengineer,
        cast(null as float64)                as omzet_consultant,
        
        'realisatie'                         as type_bron

    from {{ ref('stg_huds_uren_omzet_realisatie') }}
    where periode < date_trunc(current_date(), month)

),

planning as (

    select
        project,
        account,
        type_dienst,
        business_entity,
        regio,
        project_managers                     as project_manager,
        accountmanager                       as account_manager,
        periode,
        totaal_uren,
        totaal_omzet,
        
        -- Uren per Rol
        uren_projectmanager,
        uren_projectleider,
        uren_medewerker,
        uren_projectengineer,
        uren_consultant,
        
        -- Omzet per Rol
        omzet_projectmanager,
        omzet_projectleider,
        omzet_medewerker,
        omzet_projectengineer,
        omzet_consultant,
        
        'planning'                           as type_bron

    from {{ ref('stg_huds_uren_omzet_planning') }}
    where periode >= date_trunc(current_date(), month)

),

samenvoeging as (

    select * from realisatie
    union all
    select * from planning

)

select * from samenvoeging
