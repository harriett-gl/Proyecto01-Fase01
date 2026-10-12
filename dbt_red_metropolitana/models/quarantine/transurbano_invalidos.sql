select
    registro_id,
    fecha_hora_local,
    usuario_origen_id,
    cod_parada,
    ruta,
    zona,
    monto_gtq,
    codigo_estado,
    transaccion_aprobada,
    tiene_parada_nula,
    tiene_fecha_futura,
    archivo_origen,
    fecha_ingesta,

    concat_ws(
        ' | ',
        case
            when tiene_parada_nula
                then 'CODIGO_PARADA_NULO'
        end,
        case
            when tiene_fecha_futura
                then 'FECHA_FUTURA'
        end
    ) as motivo_rechazo,

    current_timestamp as fecha_cuarentena

from {{ ref('stg_transurbano') }}

where tiene_parada_nula
   or tiene_fecha_futura