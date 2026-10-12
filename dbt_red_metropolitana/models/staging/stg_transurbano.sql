with datos_convertidos as (

    select
        md5(
            concat_ws(
                '|',
                fecha,
                hora,
                num_tarjeta,
                cod_parada,
                ruta,
                monto_centavos,
                cod_estado
            )
        ) as registro_id,

        to_timestamp(
            fecha || ' ' || hora,
            'DD/MM/YYYY HH24:MI:SS'
        ) as fecha_hora_local,

        trim(num_tarjeta) as usuario_origen_id,
        nullif(trim(cod_parada), '') as cod_parada,
        trim(ruta) as ruta,

        monto_centavos::numeric(10, 2) / 100
            as monto_gtq,

        cod_estado::integer as codigo_estado,

        case
            when cod_estado::integer in (1, 2, 3)
                then true
            else false
        end as transaccion_aprobada,

        "_source_file" as archivo_origen,
        "_ingestion_ts"::timestamptz as fecha_ingesta

    from {{ source('staging', 'transurbano_transacciones') }}

),

con_ubicacion as (

    select
        transaccion.*,

        case
            when upper(trim(parada.sector)) ~ '^Z[0-9]+$'
                then 'Zona ' || substring(
                    upper(trim(parada.sector))
                    from 2
                )
            else initcap(lower(trim(parada.sector)))
        end as zona

    from datos_convertidos transaccion

    left join {{ source('staging', 'tu_paradas') }} parada
        on transaccion.cod_parada = trim(parada.cod_parada)

)

select
    *,

    cod_parada is null as tiene_parada_nula,

    fecha_hora_local::date >
        (
            fecha_ingesta
            at time zone 'America/Guatemala'
        )::date
        as tiene_fecha_futura

from con_ubicacion