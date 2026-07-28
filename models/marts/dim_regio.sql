-- dim_regio.sql
-- Mart laag: Dimensie voor regio's, geladen uit seed.

with regio_seed as (

    select * from {{ ref('seed_regio') }}

)

select
    regio_id,
    regio_naam,
    is_actief
from regio_seed
