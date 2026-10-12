select
    usuario_sk,

    max(perfil) as perfil,
    max(zona_residencia) as zona_residencia,

    coalesce(
        bool_or(activo),
        false
    ) as activo_en_transmetro,

    string_agg(
        distinct modo,
        ', ' order by modo
    ) as modos_identificados,

    count(distinct modo)
        as cantidad_modos_identificados

from {{ ref('dim_usuario_conformado') }}

group by usuario_sk