-- Duplicaten project_raw + periode in planning en realisatie
with planning_dupes as (
    select
        'planning' as model,
        project_raw,
        periode,
        count(*) as row_count
    from {{ ref('stg_huds_uren_omzet_planning') }}
    where not is_project_leeg
    group by 1, 2, 3
    having count(*) > 1
),

realisatie_dupes as (
    select
        'realisatie' as model,
        project_raw,
        periode,
        count(*) as row_count
    from {{ ref('stg_huds_uren_omzet_realisatie') }}
    where not is_project_leeg
    group by 1, 2, 3
    having count(*) > 1
)

select * from planning_dupes
union all
select * from realisatie_dupes
order by model, row_count desc, project_raw, periode
