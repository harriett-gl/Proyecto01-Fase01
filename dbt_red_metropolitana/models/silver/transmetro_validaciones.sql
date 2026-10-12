select
    validacion_id,
    usuario_origen_id,
    estacion_id,
    linea,
    zona,
    fecha_hora_local,
    fecha_hora_local::date as fecha_viaje,
    monto_gtq,
    tipo_validacion,
    archivo_origen,
    fecha_ingesta

from {{ ref('stg_transmetro') }}

where es_registro_valido = true