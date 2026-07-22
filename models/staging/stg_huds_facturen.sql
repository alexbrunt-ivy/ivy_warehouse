with bron as (

    select * from {{ source('huds', 'raw_huds_facturen') }}

),

opgeschoond as (

    select
        -- === Keys ===
        trim(`Factuur nummer`)                                    as factuur_nummer,

        -- === Datums ===
        safe.parse_date('%Y-%m-%d', trim(`Factuurdatum`)) as factuurdatum,
        safe.parse_date('%Y-%m-%d', trim(`Vervaldatum`))  as vervaldatum,
        date(safe.parse_timestamp('%Y-%m-%d %H:%M:%S %Ez', trim(`Created at`))) as created_at,

        -- === Attributen ===
        trim(`Prodecure`)                                         as procedure_type,
        trim(Status)                                            as status,
        trim(Periode)                                           as periode,
        {{ huds_parse_project('Project') }},
        trim(Opdrachtgever)                                     as opdrachtgever,
        trim(Bedrijfsentiteit)                                  as bedrijfsentiteit,

        -- === Numeriek ===
        safe_cast(trim(`Dagen overdue`) as INT64)                 as dagen_overdue,
        safe_cast(replace(replace(trim(`Bedrag inc BTW`), '.', ''), ',', '.') as FLOAT64)
                                                                as bedrag_inc_btw,
        safe_cast(trim(`Aantal herinneringen gestuurd`) as INT64) as aantal_herinneringen_gestuurd,
        safe_cast(trim(`Betalingstermijn`) as INT64)              as betalingstermijn_dagen,

        -- === Booleans ===
        case
            when lower(trim(`Factuur voldaan`)) in ('ja', 'yes', 'true', '1') then true
            when lower(trim(`Factuur voldaan`)) in ('nee', 'no', 'false', '0') then false
            else null
        end                                                     as is_factuur_voldaan

    from bron
    where `Factuur nummer` is not null

)

select * from opgeschoond
