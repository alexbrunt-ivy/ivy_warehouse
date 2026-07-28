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
        uren.project_nummer,      -- uit de macro, numeriek en eenduidig
        werknemers.werknemer_id,

        -- === Datums en tijd ===
        {{ parse_timestamp('uren.created_at') }} as created_at,
        uren.start_tijdstip,
        uren.einde_tijdstip,
        date(uren.start_tijdstip) as uren_datum,
        date_trunc(date(uren.start_tijdstip), month) as periode,

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
        uren.tarief,           -- nu al NUMERIC in staging
        uren.uren * uren.tarief as omzet_op_basis_van_tarief

    from uren
    left join projecten
        on uren.project_nummer = projecten.project_nummer
    left join werknemers
        on lower(trim(uren.medewerker_naam)) = lower(trim(werknemers.werknemer_naam))

)

select * from verrijkt