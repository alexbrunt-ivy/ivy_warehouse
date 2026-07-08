-- Specifieke anomalieën in stg_huds_uren
select 'uren_nummer_zero_or_null' as issue, count(*) as row_count
from {{ ref('stg_huds_uren') }}
where uren_nummer is null or uren_nummer <= 0
union all
select 'duplicate_uren_nummer', count(*) from (
    select uren_nummer from {{ ref('stg_huds_uren') }}
    group by 1 having count(*) > 1
)
union all
select 'start_after_einde', count(*)
from {{ ref('stg_huds_uren') }}
where start_tijdstip > einde_tijdstip
union all
select 'project_zonder_nummer_prefix', count(*)
from {{ ref('stg_huds_uren') }}
where not regexp_contains(project, r'^\d+')
union all
select 'tarief_niet_numeriek', count(*)
from {{ ref('stg_huds_uren') }}
where tarief is not null and trim(tarief) != ''
  and safe_cast(replace(replace(trim(tarief), '.', ''), ',', '.') as float64) is null
