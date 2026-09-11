select
    hora as hora_sk,
    hora,

    case
        when hora between 0 and 5
            then 'Madrugada'
        when hora between 6 and 11
            then 'Mañana'
        when hora between 12 and 17
            then 'Tarde'
        else 'Noche'
    end as franja_horaria,

    hora in (6, 7, 8, 16, 17, 18)
        as es_hora_pico

from generate_series(0, 23) as horas(hora)