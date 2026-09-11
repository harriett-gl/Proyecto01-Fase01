select
    viaje_id,
    usuario_origen_id,
    estacion_entrada_id,
    estacion_entrada,
    zona_entrada,
    fecha_hora_entrada,
    fecha_hora_entrada::date as fecha_viaje,
    estacion_salida_id,
    estacion_salida,
    zona_salida,
    fecha_hora_salida,
    monto_gtq,
    duracion_segundos,
    archivo_origen,
    fecha_ingesta

from {{ ref('stg_metroriel') }}

where viaje_sin_salida = false