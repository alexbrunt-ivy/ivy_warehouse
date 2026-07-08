{% macro huds_parse_project(source_column) %}
{#-
    Parseert een gecombineerd HUDS projectveld (bijv. "12345 - Projectnaam") naar:
      - project_raw
      - is_project_leeg
      - project_nummer
      - projectnaam_uit_veld
-#}
trim({{ source_column }}) as project_raw,
trim({{ source_column }}) as project,
(trim({{ source_column }}) is null or trim({{ source_column }}) = '') as is_project_leeg,
safe_cast(regexp_extract(trim({{ source_column }}), r'^(\d+)') as int64) as project_nummer,
nullif(
    trim(regexp_replace(trim({{ source_column }}), r'^(\d+)\s*[-:]*\s*', '')),
    ''
) as projectnaam_uit_veld
{% endmacro %}
