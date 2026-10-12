with eventos_transmetro as (

    select *

    from {{ ref('stg_cdc_padron') }}

    where tipo_llave = 'TRANSMETRO'

),

atributos_resueltos as (

    select
        evento.*,

        coalesce(
            evento.perfil,
            (
                select anterior.perfil
                from eventos_transmetro anterior
                where anterior.tarjeta = evento.tarjeta
                  and anterior.secuencia < evento.secuencia
                  and anterior.perfil is not null
                order by anterior.secuencia desc
                limit 1
            )
        ) as perfil_resuelto,

        coalesce(
            evento.zona_residencia,
            (
                select anterior.zona_residencia
                from eventos_transmetro anterior
                where anterior.tarjeta = evento.tarjeta
                  and anterior.secuencia < evento.secuencia
                  and anterior.zona_residencia is not null
                order by anterior.secuencia desc
                limit 1
            )
        ) as zona_resuelta

    from eventos_transmetro evento

),

versiones as (

    select
        *,
        lead(fecha_cambio) over (
            partition by tarjeta
            order by secuencia
        ) as siguiente_fecha,

        row_number() over (
            partition by tarjeta
            order by secuencia desc
        ) as orden_actual

    from atributos_resueltos

)

select
    md5(
        tarjeta || '-' || secuencia::text
    ) as usuario_version_sk,

    tarjeta as usuario_natural_id,
    perfil_resuelto as perfil,
    zona_resuelta as zona_residencia,

    fecha_cambio as valido_desde,
    siguiente_fecha as valido_hasta,

    orden_actual = 1 as es_actual,
    operacion <> 'DELETE' as activo,

    operacion as operacion_origen,
    secuencia,
    archivo_origen,
    fecha_ingesta

from versiones