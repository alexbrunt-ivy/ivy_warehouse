-- Ongekoppelde project-strings per bron
with project_sources as (
    select 'stg_huds_uren' as model, project as project_raw from {{ ref('stg_huds_uren') }}
    union all
    select 'stg_huds_facturen', project from {{ ref('stg_huds_facturen') }}
    union all
    select 'stg_huds_facturatie_overzicht', project from {{ ref('stg_huds_facturatie_overzicht') }}
    union all
    select 'stg_huds_uren_omzet_planning', project from {{ ref('stg_huds_uren_omzet_planning') }}
    union all
    select 'stg_huds_uren_omzet_realisatie', project from {{ ref('stg_huds_uren_omzet_realisatie') }}
),
parsed as (
    select
        model,
        project_raw,
        safe_cast(regexp_extract(project_raw, r'^(\d+)') as int64) as project_nummer
    from project_sources
)
select
    p.model,
    p.project_raw,
    count(*) as row_count
from parsed p
left join {{ ref('stg_huds_projecten') }} proj
    on p.project_nummer = proj.project_nummer
where proj.project_id is null
group by 1, 2
order by row_count desc
