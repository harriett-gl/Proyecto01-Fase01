with fechas_eventos as (

    select fecha_viaje
    from {{ ref('transmetro_validaciones') }}

    union all

    select fecha_viaje
    from {{ ref('transurbano_transacciones') }}

    union all

    select fecha_viaje
    from {{ ref('metroriel_viajes') }}

    union all

    select fecha_viaje
    from {{ ref('aerometro_boardings') }}

),

limites as (

    select
        min(fecha_viaje) as fecha_minima,
        max(fecha_viaje) as fecha_maxima

    from fechas_eventos

),

calendario as (

    select
        generate_series(
            fecha_minima,
            fecha_maxima,
            interval '1 day'
        )::date as fecha

    from limites

)

select
    to_char(fecha, 'YYYYMMDD')::integer as fecha_sk,
    fecha,
    extract(day from fecha)::integer as dia,
    extract(month from fecha)::integer as mes,
    extract(year from fecha)::integer as anio,
    extract(quarter from fecha)::integer as trimestre,
    extract(isodow from fecha)::integer as dia_semana,

    extract(isodow from fecha) between 1 and 5
        as es_dia_habil,

    extract(isodow from fecha) in (6, 7)
        as es_fin_semana

from calendario