select distinct
    trim(user_hash) as usuario_origen_id

from {{ source('staging', 'aerometro_boardings') }}

where nullif(trim(user_hash), '') is not null