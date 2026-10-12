select
    boarding_id,
    usuario_origen_id,
    estacion_codigo,
    estacion_nombre,
    eje,
    zona,
    fecha_hora_utc,
    fecha_hora_local,
    fecha_hora_local::date as fecha_viaje,
    numero_cabina,
    monto_gtq,
    archivo_origen,
    fecha_ingesta

from {{ ref('stg_aerometro') }}

where es_duplicado = false
  and estacion_desconocida = false