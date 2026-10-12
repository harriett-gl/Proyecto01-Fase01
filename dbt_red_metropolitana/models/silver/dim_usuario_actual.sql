select
    usuario_version_sk,
    usuario_natural_id,
    perfil,
    zona_residencia,
    valido_desde,
    activo,
    operacion_origen

from {{ ref('dim_usuario_hist') }}

where es_actual = true