with json_convertido as (

    select
        raw_payload::jsonb as viaje_json,
        "_source_file" as archivo_origen,
        "_ingestion_ts"::timestamptz as fecha_ingesta

    from {{ source('staging', 'metroriel_viajes_raw') }}

),

datos_separados as (

    select
        (viaje_json ->> 'trip_id')::bigint
            as viaje_id,

        viaje_json ->> 'card'
            as usuario_origen_id,

        (viaje_json #>> '{entry,station}')::integer
            as estacion_entrada_id,

        (viaje_json #>> '{entry,ts}')::timestamp
            as fecha_hora_entrada,

        nullif(
            viaje_json #>> '{exit,station}',
            ''
        )::integer as estacion_salida_id,

        nullif(
            viaje_json #>> '{exit,ts}',
            ''
        )::timestamp as fecha_hora_salida,

        (viaje_json ->> 'fare_gtq')::numeric(10, 2)
            as monto_gtq,

        nullif(
            viaje_json ->> 'duration_s',
            ''
        )::integer as duracion_segundos,

        archivo_origen,
        fecha_ingesta

    from json_convertido

),

con_estaciones as (

    select
        viaje.*,

        entrada.nombre_estacion
            as estacion_entrada,

        entrada.zona_nombre
            as zona_entrada,

        salida.nombre_estacion
            as estacion_salida,

        salida.zona_nombre
            as zona_salida

    from datos_separados viaje

    left join {{ source('staging', 'mr_estaciones') }} entrada
        on viaje.estacion_entrada_id =
           entrada.id_estacion::integer

    left join {{ source('staging', 'mr_estaciones') }} salida
        on viaje.estacion_salida_id =
           salida.id_estacion::integer

)

select
    *,

    (
        estacion_salida_id is null
        or fecha_hora_salida is null
        or duracion_segundos is null
    ) as viaje_sin_salida

from con_estaciones