select
    zona_sk,
    zona_nombre

from {{ ref('dim_zona_conformada') }}