with bron as (

    select * from {{ source('huds', 'raw_huds_bedrijven') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(trim(Bedrijf_ID) as STRING)        as bedrijf_id,

        -- === Attributen ===
        trim(Naam)                               as bedrijfsnaam,
        trim(Beschrijving)                       as beschrijving,
        trim(Sales_lead)                         as sales_lead,

        -- === Timestamps ===
        date(safe.parse_timestamp('%Y-%m-%d %H:%M:%S %Ez', trim(Aangemaakt_op))) as aangemaakt_op

    from bron
    where Bedrijf_ID is not null

)

select * from opgeschoond
