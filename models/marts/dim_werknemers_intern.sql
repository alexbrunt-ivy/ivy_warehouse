-- dim_werknemers.sql
-- Mart laag: Dimensie-tabel voor interne werknemers (Huidige situatie)

with stg_werknemers as (

    select * from {{ ref('stg_huds_werknemers_intern') }}

),

final as (

    select
        -- === Sleutels ===
        -- Optioneel: Genereer een unieke hash key (Surrogate Key) voor je ster-schema
        {{ dbt_utils.generate_surrogate_key(['werknemer_id']) }} as werknemer_sk,
        werknemer_id,

        -- === Attributen ===
        werknemer_naam,
        afdeling,
        
        -- === Metadata / Handig voor rapportage ===
        -- Hiermee kun je in je BI-tool makkelijk filteren op actieve afdelingen of totalen tellen
        case 
            when afdeling is null then false 
            else true 
        end as is_toegewezen_aan_afdeling,
        
        current_timestamp() as dbt_geldig_vanaf

    from stg_werknemers

)

select * from final