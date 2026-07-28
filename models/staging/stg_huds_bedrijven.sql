with bron as (

    select * from {{ source('huds', 'raw_huds_bedrijven') }}

),

opgeschoond as (

    select
        -- === Keys ===
        cast(trim(`Bedrijf ID`) as STRING)        as bedrijf_id,

        -- === Attributen ===
        trim(Naam)                               as bedrijfsnaam,
        {{ normalize_bedrijfsnaam('Naam') }}     as normalized_name,
        trim(Beschrijving)                       as beschrijving,
        trim(`Sales lead`)                         as sales_lead,

        -- === Timestamps ===
        date(safe.parse_timestamp('%Y-%m-%d %H:%M:%S %Ez', trim(`Aangemaakt op`))) as aangemaakt_op

    from bron
    where `Bedrijf ID` is not null

)

select * from opgeschoond
