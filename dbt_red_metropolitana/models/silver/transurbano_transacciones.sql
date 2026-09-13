select
    registro_id,
    fecha_hora_local,
    fecha_hora_local::date as fecha_viaje,
    usuario_origen_id,
    cod_parada,
    ruta,
    zona,
    monto_gtq,
    codigo_estado,
    transaccion_aprobada,
    archivo_origen,
    fecha_ingesta

from {{ ref('stg_transurbano') }}

where tiene_parada_nula = false
  and tiene_fecha_futura = false