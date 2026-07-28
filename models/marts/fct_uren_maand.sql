-- fct_uren_maand.sql
-- Mart laag: Feitentabel voor uren en omzet per project per maand.
-- Grain: 1 rij per project_nummer × periode (maand)
-- Dit is de centrale tabel voor uren vs budget analyse.
-- Incremental: alleen nieuwe/gewijzigde maanden worden verwerkt.

{{
    config(
        materialized='incremental',
        unique_key=['project_nummer', 'periode'],
        on_schema_change='append_new_columns'
    )
}}

with uren_planning_realisatie as (

    select * from {{ ref('int_uren_planning_realisatie') }}

),

projecten as (

    select * from {{ ref('dim_project') }}

),

final as (

    select
        -- === Foreign Keys ===
        {{ dbt_utils.generate_surrogate_key(['project_nummer']) }} as project_key,
        project_nummer,
        periode,

        -- === Planning ===
        geplande_uren,
        geplande_omzet,
        geplande_uren_projectmanager,
        geplande_uren_projectleider,
        geplande_uren_medewerker,
        geplande_uren_projectengineer,
        geplande_uren_consultant,
        geplande_omzet_projectmanager,
        geplande_omzet_projectleider,
        geplande_omzet_medewerker,
        geplande_omzet_projectengineer,
        geplande_omzet_consultant,

        -- === Realisatie ===
        gerealiseerde_uren,
        gerealiseerde_omzet,
        gerealiseerde_uren_projectmanager,
        gerealiseerde_uren_projectleider,
        gerealiseerde_uren_medewerker,
        gerealiseerde_uren_projectengineer,
        gerealiseerde_omzet_projectmanager,
        gerealiseerde_omzet_projectleider,
        gerealiseerde_omzet_medewerker,
        gerealiseerde_omzet_projectengineer,

        -- === Facturatie ===
        gefactureerde_uren,
        gefactureerde_omzet,
        niet_gefactureerd,
        gefactureerde_uren_projectmanager,
        gefactureerde_uren_projectleider,
        gefactureerde_uren_projectengineer,
        gefactureerde_uren_medewerker,

        -- === Afwijkingen (berekend) ===
        afwijking_uren_realisatie_vs_planning,
        afwijking_omzet_realisatie_vs_planning,
        afwijking_uren_facturatie_vs_realisatie,
        afwijking_omzet_facturatie_vs_realisatie,

        -- === Budget restant (voor uren vs budget KPI) ===
        geplande_uren - gerealiseerde_uren as resterend_budget_uren,
        geplande_omzet - gerealiseerde_omzet as resterend_budget_omzet,

        -- === Context ===
        project_raw,
        projectnaam,
        account,
        type_dienst,
        business_entity,
        regio,
        project_managers,
        accountmanager,
        goedkeuring,
        uren_status,
        facturatie_status,
        procedure_type

    from uren_planning_realisatie

)

select * from final