with uren as (

    select * from {{ ref('stg_huds_uren') }}

),

projecten as (

    select * from {{ ref('stg_huds_projecten') }}

),

werknemers as (

    select * from {{ ref('stg_huds_werknemers_intern') }}

),

verrijkt as (

    select
        -- === Grain ===
        uren.uren_nummer,

        -- === Keys ===
        projecten.project_id,
        projecten.project_nummer,
        werknemers.werknemer_id,

        -- === Datums en tijd ===
        coalesce(
            safe_cast(uren.created_at as TIMESTAMP),
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(cast(uren.created_at as STRING))),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(cast(uren.created_at as STRING)))
        ) as created_at,
        coalesce(
            safe_cast(uren.start_tijdstip as TIMESTAMP),
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(cast(uren.start_tijdstip as STRING))),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(cast(uren.start_tijdstip as STRING)))
        ) as start_tijdstip,
        coalesce(
            safe_cast(uren.einde_tijdstip as TIMESTAMP),
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(cast(uren.einde_tijdstip as STRING))),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(cast(uren.einde_tijdstip as STRING)))
        ) as einde_tijdstip,
        date(coalesce(
            safe_cast(uren.start_tijdstip as TIMESTAMP),
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(cast(uren.start_tijdstip as STRING))),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(cast(uren.start_tijdstip as STRING)))
        )) as uren_datum,
        date_trunc(date(coalesce(
            safe_cast(uren.start_tijdstip as TIMESTAMP),
            safe.parse_timestamp('%Y-%m-%d %H:%M:%E*S%Ez', trim(cast(uren.start_tijdstip as STRING))),
            safe.parse_timestamp('%Y-%m-%dT%H:%M:%E*S%Ez', trim(cast(uren.start_tijdstip as STRING)))
        )), month) as periode,

        -- === Medewerker ===
        uren.medewerker_naam,
        uren.werknemer_type,
        uren.functie,
        uren.rol,
        coalesce(werknemers.afdeling, uren.afdeling) as afdeling,

        -- === Organisatie ===
        uren.bedrijfsentiteit,
        uren.kostenplaats,
        uren.business_entity,
        uren.regio,

        -- === Project ===
        uren.project,
        projecten.projectnaam,
        uren.opdrachtgever,
        uren.type_dienst,
        uren.project_managers,
        uren.accountmanager,

        -- === Uren ===
        uren.tijd_gewerkt_minuten,
        uren.pauze_minuten,
        uren.uren,
        safe_divide(uren.tijd_gewerkt_minuten - coalesce(uren.pauze_minuten, 0), 60) as netto_uren_op_basis_van_minuten,

        -- === Status en locatie ===
        uren.status,
        uren.locatie,

        -- === Financieel ===
        safe_cast(replace(replace(trim(uren.tarief), '.', ''), ',', '.') as NUMERIC) as tarief,
        uren.uren * safe_cast(replace(replace(trim(uren.tarief), '.', ''), ',', '.') as NUMERIC) as omzet_op_basis_van_tarief

    from uren
    left join projecten
        on lower(trim(uren.project)) = lower(trim(projecten.projectnaam))
    left join werknemers
        on lower(trim(uren.medewerker_naam)) = lower(trim(werknemers.werknemer_naam))

)

select * from verrijkt
