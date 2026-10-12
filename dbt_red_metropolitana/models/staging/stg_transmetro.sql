with base as (

    select
        validacion_id::bigint as validacion_id,
        trim(tarjeta) as usuario_origen_id,
        trim(estacion_id) as estacion_id,
        trim(linea) as linea,
        fecha_hora::timestamp as fecha_hora_local,
        tarifa::numeric(10, 2) as monto_gtq,
        trim(tipo) as tipo_validacion,
        "_source_file" as archivo_origen,
        "_ingestion_ts"::timestamptz as fecha_ingesta,
        "_kafka_offset"::bigint as kafka_offset

    from {{ source('staging', 'transmetro_validaciones') }}

),

con_zona as (

    select
        base.*,
        trim(estacion.zona) as zona,

        row_number() over (
            partition by base.validacion_id
            order by base.kafka_offset
        ) as numero_duplicado

    from base

    left join {{ source('staging', 'tm_estaciones') }} estacion
        on base.estacion_id = trim(estacion.estacion_id)

)

select
    *,
    numero_duplicado = 1 as es_registro_valido

from con_zona