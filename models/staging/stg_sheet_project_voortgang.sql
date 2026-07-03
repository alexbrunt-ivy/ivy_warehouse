with bron as (

    select * from {{ source('sheets', 'vw_project_voortgang') }}

),

opgeschoond as (

    select
        *
        -- TODO: voeg hier kolommen toe die je wilt opschonen en casten.
        -- Bijvoorbeeld: trim(Projectnaam) as projectnaam,
        --              cast(Datum as DATE) as periode,
        --              cast(Voortgangspercentage as FLOAT64) as voortgangspercentage,
    from bron

)

select * from opgeschoond
