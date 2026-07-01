with planning as (

    select * from {{ ref('stg_huds_uren_omzet_planning') }}

),

realisatie as (

    select * from {{ ref('stg_huds_uren_omzet_realisatie') }}

),

facturatie as (

    select * from {{ ref('stg_huds_facturatie_overzicht') }}

),

samengevoegd as (

    select
        -- === Grain ===
        coalesce(planning.project, realisatie.project, facturatie.project) as project,
        coalesce(planning.periode, realisatie.periode, facturatie.periode) as periode,

        -- === Context ===
        coalesce(planning.account, realisatie.account, facturatie.account) as account,
        coalesce(planning.type_dienst, realisatie.type_dienst) as type_dienst,
        coalesce(planning.business_entity, realisatie.business_entity, facturatie.bedrijfsentiteit) as business_entity,
        coalesce(planning.regio, realisatie.regio) as regio,
        coalesce(planning.project_managers, realisatie.project_managers) as project_managers,
        coalesce(planning.accountmanager, realisatie.accountmanager) as accountmanager,
        facturatie.goedkeuring,
        facturatie.uren_status,
        facturatie.status as facturatie_status,
        facturatie.procedure_type,

        -- === Planning ===
        planning.totaal_uren as geplande_uren,
        planning.totaal_omzet as geplande_omzet,
        planning.uren_projectmanager as geplande_uren_projectmanager,
        planning.uren_projectleider as geplande_uren_projectleider,
        planning.uren_medewerker as geplande_uren_medewerker,
        planning.uren_projectengineer as geplande_uren_projectengineer,
        planning.uren_consultant as geplande_uren_consultant,
        planning.omzet_projectmanager as geplande_omzet_projectmanager,
        planning.omzet_projectleider as geplande_omzet_projectleider,
        planning.omzet_medewerker as geplande_omzet_medewerker,
        planning.omzet_projectengineer as geplande_omzet_projectengineer,
        planning.omzet_consultant as geplande_omzet_consultant,

        -- === Realisatie ===
        realisatie.totaal_uren as gerealiseerde_uren,
        realisatie.totaal_omzet as gerealiseerde_omzet,
        realisatie.uren_projectmanager as gerealiseerde_uren_projectmanager,
        realisatie.uren_projectleider as gerealiseerde_uren_projectleider,
        realisatie.uren_medewerker as gerealiseerde_uren_medewerker,
        realisatie.uren_projectengineer as gerealiseerde_uren_projectengineer,
        realisatie.omzet_projectmanager as gerealiseerde_omzet_projectmanager,
        realisatie.omzet_projectleider as gerealiseerde_omzet_projectleider,
        realisatie.omzet_medewerker as gerealiseerde_omzet_medewerker,
        realisatie.omzet_projectengineer as gerealiseerde_omzet_projectengineer,

        -- === Facturatie ===
        facturatie.totaal_uren as gefactureerde_uren,
        facturatie.totaal_omzet as gefactureerde_omzet,
        facturatie.niet_gefactureerd,
        facturatie.uren_projectmanager as gefactureerde_uren_projectmanager,
        facturatie.uren_projectleider as gefactureerde_uren_projectleider,
        facturatie.uren_projectengineer as gefactureerde_uren_projectengineer,
        facturatie.uren_medewerker as gefactureerde_uren_medewerker,

        -- === Afwijkingen ===
        coalesce(realisatie.totaal_uren, 0) - coalesce(planning.totaal_uren, 0) as afwijking_uren_realisatie_vs_planning,
        coalesce(realisatie.totaal_omzet, 0) - coalesce(planning.totaal_omzet, 0) as afwijking_omzet_realisatie_vs_planning,
        coalesce(facturatie.totaal_uren, 0) - coalesce(realisatie.totaal_uren, 0) as afwijking_uren_facturatie_vs_realisatie,
        coalesce(facturatie.totaal_omzet, 0) - coalesce(realisatie.totaal_omzet, 0) as afwijking_omzet_facturatie_vs_realisatie

    from planning
    full outer join realisatie
        on lower(trim(planning.project)) = lower(trim(realisatie.project))
        and planning.periode = realisatie.periode
    full outer join facturatie
        on lower(trim(coalesce(planning.project, realisatie.project))) = lower(trim(facturatie.project))
        and coalesce(planning.periode, realisatie.periode) = facturatie.periode

)

select * from samengevoegd
