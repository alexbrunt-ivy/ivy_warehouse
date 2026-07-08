-- Data quality profiel voor HUDS staging (project-velden, nulls, match rates)
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
        safe_cast(regexp_extract(project_raw, r'^(\d+)') as int64) as project_nummer,
        trim(regexp_replace(project_raw, r'^(\d+)\s*[-:]*\s*', '')) as projectnaam_uit_veld,
        regexp_contains(project_raw, r'^\d+') as starts_with_number
    from project_sources
),
match as (
    select
        p.*,
        proj.project_id,
        proj.projectnaam as projectnaam_master
    from parsed p
    left join {{ ref('stg_huds_projecten') }} proj
        on p.project_nummer = proj.project_nummer
)
select
    model,
    count(*) as row_count,
    countif(not starts_with_number) as zonder_leading_nummer,
    countif(project_nummer is null) as geen_parseerbaar_nummer,
    countif(project_id is not null) as match_op_nummer,
    countif(project_id is null) as geen_match_op_nummer,
    round(100 * safe_divide(countif(project_id is null), count(*)), 1) as pct_unmatched
from match
group by 1
order by 1
