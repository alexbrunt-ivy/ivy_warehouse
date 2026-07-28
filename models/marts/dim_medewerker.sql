-- dim_medewerker.sql
-- Mart laag: Dimensie voor medewerkers.

with werknemers as (

    select * from {{ ref('stg_huds_werknemers_intern') }}

),

final as (

    select
        -- === Keys ===
        {{ dbt_utils.generate_surrogate_key(['werknemer_id']) }} as medewerker_key,
        werknemer_id,

        -- === Attributen ===
        werknemer_naam as medewerker_naam,
        afdeling

    from werknemers

)

select * from final