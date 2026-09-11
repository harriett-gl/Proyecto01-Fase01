with datos_convertidos as (

    select
        trim(boarding_id) as boarding_id,
        trim(user_hash) as usuario_origen_id,
        trim(station_code) as estacion_codigo,
        trim(axis) as eje,

        timestamp_utc::timestamptz
            as fecha_hora_utc,

        timestamp_utc::timestamptz
            at time zone 'America/Guatemala'
            as fecha_hora_local,

        cabin_number::integer as numero_cabina,
        fare::numeric(10, 2) as monto_gtq,

        "_event_id" as evento_id,
        "_occurrence_number"::integer as numero_ocurrencia,
        "_source_file" as archivo_origen,
        "_ingestion_ts"::timestamptz as fecha_ingesta,
        "_kafka_offset"::bigint as kafka_offset

    from {{ source('staging', 'aerometro_boardings') }}

),

con_estacion as (

    select
        abordaje.*,
        trim(estacion.station_name) as estacion_nombre,
        trim(estacion.district) as zona,

        row_number() over (
            partition by abordaje.boarding_id
            order by abordaje.numero_ocurrencia, abordaje.kafka_offset
        ) as numero_duplicado

    from datos_convertidos abordaje

    left join {{ source('staging', 'am_estaciones') }} estacion
        on abordaje.estacion_codigo = trim(estacion.station_code)

)

select
    *,
    numero_duplicado > 1 as es_duplicado,
    estacion_nombre is null as estacion_desconocida

from con_estacion
