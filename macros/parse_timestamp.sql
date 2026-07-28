{% macro parse_timestamp(column) %}
{#-
    Parseert een timestamp kolom die in meerdere formaten kan voorkomen.
    Probes:
      1. directe TIMESTAMP cast
      2. '%Y-%m-%d %H:%M:%E*S%Ez' (bijv. "2024-01-15 14:30:00 +01:00")
      3. '%Y-%m-%dT%H:%M:%E*S%Ez' (ISO 8601, bijv. "2024-01-15T14:30:00+01:00")
      4. timestamp_millis (voor Unix milliseconden als INT64)
    
    Gebruik: {{ parse_timestamp('bron.kolom') }}
-#}
coalesce(
    safe_cast({{ column }} as TIMESTAMP),
    safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(cast({{ column }} as STRING))),
    safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(cast({{ column }} as STRING))),
    timestamp_millis(safe_cast(trim(cast({{ column }} as STRING)) as INT64))
)
{% endmacro %}
