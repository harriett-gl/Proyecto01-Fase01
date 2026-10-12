select *
from (
    values
        (1, 'TRANSMETRO'),
        (2, 'TRANSURBANO'),
        (3, 'METRORIEL'),
        (4, 'AEROMETRO')
) as modos(modo_sk, modo_nombre)