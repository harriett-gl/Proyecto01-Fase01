select
    md5('METRORIEL|' || viaje.viaje_id::text)
        as viaje_sk,

    viaje.viaje_id,

    modo.modo_sk,
    'METRORIEL' as modo_nombre,

    usuario.usuario_sk,
    zona_entrada.zona_sk as zona_entrada_sk,
    zona_salida.zona_sk as zona_salida_sk,

    viaje.zona_entrada,
    viaje.zona_salida,

    to_char(
        viaje.fecha_hora_entrada::date,
        'YYYYMMDD'
    )::integer as fecha_sk,

    extract(
        hour from viaje.fecha_hora_entrada
    )::integer as hora_entrada_sk,

    extract(
        hour from viaje.fecha_hora_salida
    )::integer as hora_salida_sk,

    viaje.estacion_entrada_id,
    viaje.estacion_entrada,
    viaje.estacion_salida_id,
    viaje.estacion_salida,

    viaje.fecha_hora_entrada,
    viaje.fecha_hora_salida,
    viaje.duracion_segundos,
    viaje.monto_gtq,

    1 as cantidad_viajes

from {{ ref('metroriel_viajes') }} viaje

left join {{ ref('dim_modo') }} modo
    on modo.modo_nombre = 'METRORIEL'

left join {{ ref('dim_usuario_conformado') }} usuario
    on usuario.modo = 'METRORIEL'
   and viaje.usuario_origen_id =
       usuario.usuario_origen_id

left join {{ ref('dim_zona_conformada') }} zona_entrada
    on viaje.zona_entrada = zona_entrada.zona_nombre

left join {{ ref('dim_zona_conformada') }} zona_salida
    on viaje.zona_salida = zona_salida.zona_nombre