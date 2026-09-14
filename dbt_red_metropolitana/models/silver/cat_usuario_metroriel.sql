with viajes as (

    select
        raw_payload::jsonb as viaje_json

    from {{ source('staging', 'metroriel_viajes_raw') }}

)

select distinct
    viaje_json ->> 'card' as usuario_origen_id

from viajes

where nullif(viaje_json ->> 'card', '') is not null