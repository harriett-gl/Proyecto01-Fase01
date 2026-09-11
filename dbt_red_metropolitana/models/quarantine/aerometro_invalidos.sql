select
    boarding_id,
    usuario_origen_id,
    estacion_codigo,
    estacion_nombre,
    eje,
    zona,
    fecha_hora_utc,
    fecha_hora_local,
    numero_cabina,
    monto_gtq,
    evento_id,
    numero_ocurrencia,
    archivo_origen,
    fecha_ingesta,
    kafka_offset,

    concat_ws(
        ' | ',
        case
            when es_duplicado
                then 'ABORDAJE_DUPLICADO'
        end,
        case
            when estacion_desconocida
                then 'ESTACION_DESCONOCIDA'
        end
    ) as motivo_rechazo,

    current_timestamp as fecha_cuarentena

from {{ ref('stg_aerometro') }}

where es_duplicado
   or estacion_desconocida