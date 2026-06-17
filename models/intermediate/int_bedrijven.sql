-- models/intermediate/int_bedrijven.sql

{{ config(materialized='table') }}

SELECT
    id,
    name,
    industry,
    employees,
    created_at,
    updated_at
FROM {{ ref('stg_huds_bedrijven') }}
