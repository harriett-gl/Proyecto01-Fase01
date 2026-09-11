select
    validacion_id,
    usuario_origen_id,
    estacion_id,
    linea,
    zona,
    fecha_hora_local,
    monto_gtq,
    tipo_validacion,
    archivo_origen,
    fecha_ingesta,
    kafka_offset,
    'VALIDACION_DUPLICADA' as motivo_rechazo,
    current_timestamp as fecha_cuarentena

from {{ ref('stg_transmetro') }}

where numero_duplicado > 1