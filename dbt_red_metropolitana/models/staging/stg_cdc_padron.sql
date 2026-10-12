select
    seq::bigint as secuencia,
    commit_ts::timestamp as fecha_cambio,
    upper(trim(op)) as operacion,
    trim(tarjeta) as tarjeta,
    nullif(trim(perfil), '') as perfil,
    nullif(trim(zona_residencia), '') as zona_residencia,
    nullif(trim(estado), '') as estado,

    case
        when trim(tarjeta) ~ '^TC-[0-9]{8}$'
            then 'TRANSMETRO'
        when trim(tarjeta) ~ '^[0-9]{10}$'
            then 'TRANSURBANO'
        when trim(tarjeta) ~ '^MR[0-9]{7}$'
            then 'METRORIEL'
        else 'INVALIDA'
    end as tipo_llave,

    "_source_file" as archivo_origen,
    "_ingestion_ts"::timestamptz as fecha_ingesta

from {{ source('staging', 'cdc_padron_usuarios') }}