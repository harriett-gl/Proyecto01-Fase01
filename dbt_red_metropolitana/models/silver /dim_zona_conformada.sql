with zonas_originales as (

    select zona
    from {{ ref('transmetro_validaciones') }}

    union

    select zona
    from {{ ref('transurbano_transacciones') }}

    union

    select zona_entrada as zona
    from {{ ref('metroriel_viajes') }}

    union

    select zona_salida as zona
    from {{ ref('metroriel_viajes') }}

    union

    select zona
    from {{ ref('aerometro_boardings') }}

),

zonas_normalizadas as (

    select distinct
        case
            when upper(trim(zona)) ~ '^ZONA[ ]*[0-9]+$'
                then 'Zona ' || regexp_replace(
                    upper(trim(zona)),
                    '[^0-9]',
                    '',
                    'g'
                )
            else initcap(lower(trim(zona)))
        end as zona_nombre

    from zonas_originales

    where nullif(trim(zona), '') is not null

)

select
    md5(zona_nombre) as zona_sk,
    zona_nombre

from zonas_normalizadas