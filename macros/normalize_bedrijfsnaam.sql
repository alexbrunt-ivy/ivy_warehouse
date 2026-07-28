{% macro normalize_bedrijfsnaam(column) %}
{#-
    Normaliseert een bedrijfsnaam voor fuzzy matching.
    Verwijdert rechtsvormen (bv, nv, vof, etc.) en niet-alfanumerieke tekens.
    Normaliseert diakritische tekens (zoals é, ë, ö) naar hun basisvorm.
    
    Gebruik: {{ normalize_bedrijfsnaam('bron.kolom') }}
-#}
REGEXP_REPLACE(
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            lower(trim({{ column }})),
            r'(b\.v\.|bv|n\.v\.|nv|v\.o\.f\.|vof|group|groep|stichting|vereniging|coöperatie|cooporatie|holding|coop|co\xf6peratie)',
            ''
        ),
        r'[éèëê]', 'e'
    ),
    r'[^a-z0-9]', 
    ''
)
{% endmacro %}
