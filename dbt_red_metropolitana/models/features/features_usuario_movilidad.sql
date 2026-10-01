{{ config(
    materialized='table',
    schema='features'
) }}

/*
    Feature: movilidad por usuario

    Fuente:
    gold.dim_usuario

    Objetivo:
    Consolidar por usuario la cantidad de modos de transporte
    identificados y determinar si el usuario es multimodal.
*/

SELECT
    usuario_sk,

    perfil,

    zona_residencia,

    modos_identificados,

    cantidad_modos_identificados AS cantidad_modos,

    CASE
        WHEN cantidad_modos_identificados >= 2 THEN TRUE
        ELSE FALSE
    END AS es_multimodal,

    activo_en_transmetro

FROM {{ ref('dim_usuario') }}