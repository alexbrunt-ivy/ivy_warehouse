-- Planning-projectnummers die in de projectmaster staan moeten ook in realisatie voorkomen.
with planning as (
    select distinct project_nummer
    from {{ ref('stg_huds_uren_omzet_planning') }}
    where not is_project_leeg
      and project_nummer is not null
),

realisatie as (
    select distinct project_nummer
    from {{ ref('stg_huds_uren_omzet_realisatie') }}
    where not is_project_leeg
      and project_nummer is not null
),

master as (
    select distinct project_nummer
    from {{ ref('stg_huds_projecten') }}
)

select
    planning.project_nummer
from planning
inner join master
    on planning.project_nummer = master.project_nummer
left join realisatie
    on planning.project_nummer = realisatie.project_nummer
where realisatie.project_nummer is null
