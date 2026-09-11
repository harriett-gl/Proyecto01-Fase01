select distinct
    trim(num_tarjeta) as usuario_origen_id,
    'TRANSURBANO' as modo

from {{ source('staging', 'transurbano_transacciones') }}

where nullif(trim(num_tarjeta), '') is not null