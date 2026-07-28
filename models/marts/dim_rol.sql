-- dim_rol.sql
-- Mart laag: Dimensie voor rollen, afgeleid van unieke rollen in uurtarieven.
-- Dit maakt het mogelijk om in feitentabellen te refereren naar een rol_id
-- in plaats van de string 'rol', wat consistenter en efficiënter is.

with rollen as (

    select distinct rol
    from {{ ref('stg_huds_uurtarieven') }}
    where rol is not null and trim(rol) != ''

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['rol']) }} as rol_key,
        row_number() over (order by rol) as rol_id,
        rol as rol_naam
    from rollen

)

select * from final