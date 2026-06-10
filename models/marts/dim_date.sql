with dates as (

    {{
        dbt_utils.date_spine(
            datepart='day',
            start_date="'2014-01-01'",
            end_date="'2050-12-31'"
        )
    }}

)

select
    cast(date_day as date) as datum,

    -- YYYYMMDD key
    cast(format_date('%Y%m%d', date_day) as int64) as datum_key,

    extract(year from date_day) as jaar,
    extract(quarter from date_day) as kwartaal,
    extract(month from date_day) as maand,

    format_date('%B', date_day) as maand_naam,

    -- ISO week (maandag start)
    extract(isoweek from date_day) as weeknummer,

    extract(day from date_day) as dag_van_de_maand,

    -- BigQuery weekday (zondag = 1)
    extract(dayofweek from date_day) as bq_dag_van_de_week,

    -- EU weekday (maandag = 1 ... zondag = 7)
    mod(extract(dayofweek from date_day) + 5, 7) + 1 as dag_van_de_week,

    format_date('%A', date_day) as dag_naam,

    case
        when mod(extract(dayofweek from date_day) + 5, 7) + 1 in (6,7)
        then true
        else false
    end as is_weekend,

    -- working day (ma–vr)
    case
        when mod(extract(dayofweek from date_day) + 5, 7) + 1 between 1 and 5
        then true
        else false
    end as is_werkdag,

    -- month boundaries
    date_trunc(date_day, month) as eerste_dag_maand,

    last_day(date_day, month) as laatste_dag_maand

from dates