select distinct
    trim(num_tarjeta) as usuario_origen_id

from {{ source('staging', 'transurbano_transacciones') }}

where nullif(trim(num_tarjeta), '') is not null