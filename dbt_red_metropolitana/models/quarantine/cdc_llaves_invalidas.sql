select
    secuencia,
    fecha_cambio,
    operacion,
    tarjeta,
    perfil,
    zona_residencia,
    estado,
    tipo_llave,
    archivo_origen,
    fecha_ingesta,

    case
        when tarjeta = 'SIN-TARJETA'
            then 'LLAVE_AUSENTE'
        else 'LLAVE_NO_PERTENECE_AL_PADRON_TRANSMETRO'
    end as motivo_rechazo,

    current_timestamp as fecha_cuarentena

from {{ ref('stg_cdc_padron') }}

where tipo_llave <> 'TRANSMETRO'