-- dim_team.sql
-- Mart laag: Dimensie voor teams, geladen uit seed dim_team.
-- Let op: seed heet ook dim_team, dus we gebruiken source() of ref() met een alias.
-- Omdat dbt de seed en model niet uit elkaar kan houden met dezelfde naam,
-- verwijzen we naar de seed via de seed-paths configuratie.

with team_seed as (

    select * from {{ ref('seed_team') }}

)

select
    team_id,
    team_naam,
    regio_id,
    regio_naam,
    is_actief
from team_seed