with facturen as (

    select * from {{ ref('stg_huds_facturen') }}

),

projecten as (

    select * from {{ ref('stg_huds_projecten') }}

),

bedrijven as (

    select * from {{ ref('int_bedrijven_samengevoegd') }}

),

verrijkt as (

    select
        -- === Keys ===
        facturen.factuur_nummer,
        bedrijven.bedrijf_id as huds_bedrijf_id,
        projecten.project_id,
        safe_cast(regexp_extract(facturen.project, r'^(\d+)') as INT64) as project_nummer,

        -- === Attributen ===
        facturen.opdrachtgever as originele_opdrachtgever_naam,
        REGEXP_REPLACE(
            REGEXP_REPLACE(lower(trim(facturen.bedrijfsentiteit)), r'\b(b\.v\.|bv|n\.v\.|nv|v\.o\.f\.|vof|group|groep)\b', ''),
            r'[^a-z0-9]', 
            ''
        ) as factuur_normalized_name,
        bedrijven.bedrijfsnaam as gekoppelde_bedrijfsnaam,
        trim(regexp_replace(facturen.project, r'^(\d+)\s*[-:]*\s*', '')) as projectnaam_uit_factuur,
        projecten.projectnaam as gekoppelde_projectnaam,
        facturen.procedure_type,
        facturen.periode,
        facturen.bedrijfsentiteit,

        -- === Datums ===
        facturen.factuurdatum,
        facturen.vervaldatum,
        facturen.created_at as factuur_aangemaakt_op,

        -- === Financieel ===
        facturen.bedrag_inc_btw,
        facturen.betalingstermijn_dagen,

        -- === Status en Opvolging ===
        facturen.status as originele_status,
        facturen.is_factuur_voldaan,
        facturen.dagen_overdue,
        facturen.aantal_herinneringen_gestuurd,
        
        -- === Uniforme Status ===
        case 
            when facturen.is_factuur_voldaan then 'Betaald'
            when not facturen.is_factuur_voldaan and facturen.vervaldatum < current_date() then 'Te laat'
            when not facturen.is_factuur_voldaan then 'Open (binnen termijn)'
            else 'Onbekend'
        end as factuur_status_categorie

    from facturen
    -- We matchen de Bedrijfsentiteit uit facturen met de genormaliseerde bedrijfsnaam uit HUDS
    left join bedrijven
        on REGEXP_REPLACE(
            REGEXP_REPLACE(lower(trim(facturen.bedrijfsentiteit)), r'\b(b\.v\.|bv|n\.v\.|nv|v\.o\.f\.|vof|group|groep)\b', ''),
            r'[^a-z0-9]', 
            ''
        ) = bedrijven.normalized_name
    -- We gebruiken regex om het getal aan het begin van de string er altijd veilig uit te vissen
    left join projecten
        on safe_cast(regexp_extract(facturen.project, r'^(\d+)') as INT64) = projecten.project_nummer

)

select * from verrijkt
