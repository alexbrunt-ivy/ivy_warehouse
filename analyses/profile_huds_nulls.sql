select
    'stg_huds_uren' as model,
    count(*) as row_count,
    countif(uren_nummer is null) as null_uren_nummer,
    countif(start_tijdstip is null) as null_start,
    countif(uren is null) as null_uren,
    countif(uren <= 0 or uren > 24) as weird_uren,
    countif(tarief is null or trim(tarief) = '') as null_tarief,
    countif(medewerker_naam is null or trim(medewerker_naam) = '') as null_medewerker
from {{ ref('stg_huds_uren') }}
union all
select
    'stg_huds_facturen',
    count(*),
    countif(factuur_nummer is null or trim(factuur_nummer) = ''),
    countif(factuurdatum is null),
    countif(bedrag_inc_btw is null),
    countif(bedrag_inc_btw <= 0),
    countif(is_factuur_voldaan is null),
    countif(project is null or trim(project) = '')
from {{ ref('stg_huds_facturen') }}
union all
select
    'stg_huds_projecten',
    count(*),
    countif(project_nummer is null),
    countif(start_datum is null),
    countif(projectnaam is null or trim(projectnaam) = ''),
    0,
    countif(opdrachtgever is null or trim(opdrachtgever) = ''),
    countif(status is null or trim(status) = '')
from {{ ref('stg_huds_projecten') }}
union all
select
    'stg_huds_werknemers_intern',
    count(*),
    countif(werknemer_id is null or trim(werknemer_id) = ''),
    0,
    countif(werknemer_naam is null or trim(werknemer_naam) = ''),
    0,
    countif(afdeling is null or trim(afdeling) = ''),
    0
from {{ ref('stg_huds_werknemers_intern') }}
