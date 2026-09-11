# Matriz del bus - Red Metropolitana

## Grano principal

La tabla de hechos principal tendrá una fila por cada abordaje válido
realizado por un usuario, en un modo de transporte, ubicación y
fecha-hora determinada.

Para MetroRiel, cada viaje completo generará un abordaje correspondiente
a su estación de entrada. La información del destino y la duración se
conservará en una segunda tabla de hechos de viajes de MetroRiel.

## Matriz del bus

| Proceso | Fecha | Hora | Usuario | Modo | Estación o parada | Zona | Línea o ruta | Destino |
|---|---|---|---|---|---|---|---|---|
| Abordajes integrados | X | X | X | X | X | X | X | |
| Viajes completos de MetroRiel | X | X | X | X | X | X | | X |
| Estado diario del padrón de Transmetro | X | | X | X | | X | | |

## Tablas de hechos

### gold.fct_abordajes

Una fila representa un abordaje válido realizado por un usuario.

Medidas:

- cantidad_abordajes
- monto_gtq

### gold.fct_viajes_metroriel

Una fila representa un viaje completo de MetroRiel desde la estación
de entrada hasta la estación de salida.

Medidas:

- cantidad_viajes
- monto_gtq
- duracion_segundos

### gold.fct_padron_diario

Una fila representa el estado diario de las tarjetas de Transmetro,
agrupado por fecha, estado y zona de residencia.

Medida:

- tarjetas_activas_fin_dia

## Dimensiones conformadas

- gold.dim_fecha
- gold.dim_hora
- gold.dim_usuario
- gold.dim_modo
- gold.dim_estacion
- gold.dim_zona
- gold.dim_linea_ruta

## Clasificación de medidas

| Medida | Clasificación | Justificación |
|---|---|---|
| cantidad_abordajes | Aditiva | Puede sumarse por fecha, modo, zona y estación |
| monto_gtq | Aditiva | Puede sumarse para calcular los ingresos |
| cantidad_viajes | Aditiva | Puede sumarse entre periodos y estaciones |
| duracion_segundos | Aditiva | Puede sumarse entre viajes individuales |
| tarjetas_activas_fin_dia | Semi-aditiva | Puede sumarse entre zonas, pero no entre diferentes fechas |
| promedio_monto_viaje | No aditiva | Debe recalcularse a partir del monto y los viajes |
| usuarios_distintos | No aditiva | Un usuario puede aparecer en varias zonas o modos |

## Decisiones de diseño

1. El grano principal será un abordaje y no un viaje puerta a puerta,
porque Transmetro, Transurbano y Aerómetro registran abordajes individuales.

2. MetroRiel conservará su información adicional en una tabla de hechos
separada, ya que registra origen, destino y duración.

3. Todas las tablas Gold se construirán exclusivamente desde Silver.

4. Los registros inválidos serán enviados a cuarentena con el motivo
de rechazo. No se eliminarán silenciosamente.

5. La llave del usuario será seudonimizada antes de llegar a Gold.