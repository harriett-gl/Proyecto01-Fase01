with abordajes as (

    select
        'TRANSMETRO' as modo,
        validacion_id::text as evento_origen_id,
        usuario_origen_id,
        estacion_id as ubicacion_codigo,
        linea as servicio,
        zona,
        fecha_hora_local,
        monto_gtq,
        true as operacion_exitosa

    from {{ ref('transmetro_validaciones') }}

    union all

    select
        'TRANSURBANO' as modo,
        registro_id::text as evento_origen_id,
        usuario_origen_id,
        cod_parada as ubicacion_codigo,
        ruta as servicio,
        zona,
        fecha_hora_local,
        monto_gtq,
        transaccion_aprobada as operacion_exitosa

    from {{ ref('transurbano_transacciones') }}

    union all

    select
        'AEROMETRO' as modo,
        boarding_id::text as evento_origen_id,
        usuario_origen_id,
        estacion_codigo as ubicacion_codigo,
        eje as servicio,
        zona,
        fecha_hora_local,
        monto_gtq,
        true as operacion_exitosa

    from {{ ref('aerometro_boardings') }}

),

abordajes_normalizados as (

    select
        *,

        case
            when upper(trim(zona)) ~ '^ZONA[ ]*[0-9]+$'
                then 'Zona ' || regexp_replace(
                    upper(trim(zona)),
                    '[^0-9]',
                    '',
                    'g'
                )
            else initcap(lower(trim(zona)))
        end as zona_normalizada

    from abordajes

)

select
    md5(
        abordaje.modo || '|' ||
        abordaje.evento_origen_id
    ) as abordaje_sk,

    abordaje.evento_origen_id,

    modo.modo_sk,
    abordaje.modo as modo_nombre,

    usuario.usuario_sk,
    abordaje.usuario_origen_id,

    zona.zona_sk,
    abordaje.zona_normalizada as zona_nombre,

    to_char(
        abordaje.fecha_hora_local::date,
        'YYYYMMDD'
    )::integer as fecha_sk,

    extract(
        hour from abordaje.fecha_hora_local
    )::integer as hora_sk,

    abordaje.ubicacion_codigo,
    abordaje.servicio,
    abordaje.fecha_hora_local,
    abordaje.monto_gtq,
    abordaje.operacion_exitosa,

    1 as cantidad_abordajes

from abordajes_normalizados abordaje

left join {{ ref('dim_modo') }} modo
    on abordaje.modo = modo.modo_nombre

left join {{ ref('dim_usuario_conformado') }} usuario
    on abordaje.modo = usuario.modo
   and abordaje.usuario_origen_id =
       usuario.usuario_origen_id

left join {{ ref('dim_zona_conformada') }} zona
    on abordaje.zona_normalizada =
       zona.zona_nombre