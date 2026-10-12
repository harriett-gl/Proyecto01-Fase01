# Diccionario de datos

> Documento generado con `python scripts/generar_diccionario.py` desde los archivos `.yml` de dbt. No editar a mano: se edita el `.yml` y se vuelve a generar.

Para cada campo se indica qué significa, de qué fuente sale y qué transformación se le aplicó. El linaje gráfico está en [`docs/linaje/linaje_dbt.png`](linaje/linaje_dbt.png).

## Capa Gold - dimensiones

### `gold.dim_modo`

Catálogo de los cuatro modos de transporte de la red.

**Dueño:** Gerencia de Operaciones

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `modo_sk` | Llave sustituta del modo de transporte. | Definida en el modelo | Valor fijo 1-4 |
| `modo_nombre` | Nombre oficial del modo: TRANSMETRO, TRANSURBANO, METRORIEL o AEROMETRO. | Definida en el modelo | Catálogo fijo en mayúsculas |

### `gold.dim_hora`

Hora del día (0-23) con franja horaria y bandera de hora pico.

**Dueño:** Equipo de Datos de la Agencia

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `hora_sk` | Llave de la hora del día (igual a la hora, 0-23). | generate_series(0, 23) | Ninguna |
| `hora` | Hora local del día, de 0 a 23. | generate_series(0, 23) | Ninguna |
| `franja_horaria` | Madrugada (0-5), Mañana (6-11), Tarde (12-17) o Noche (18-23). | Regla de negocio | CASE sobre la hora |
| `es_hora_pico` | Verdadero entre 06:00-08:59 y 16:00-18:59 (definición oficial, macro es_hora_pico). | Regla de negocio | Macro es_hora_pico, compartida con features |

### `gold.dim_fecha`

Calendario continuo entre la primera y la última fecha con viajes.

**Dueño:** Equipo de Datos de la Agencia

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `fecha_sk` | Llave de la fecha en formato YYYYMMDD. | Fechas de viaje de las 4 tablas Silver | to_char(fecha, 'YYYYMMDD')::int |
| `fecha` | Fecha calendario en hora local de Guatemala. | Silver: fecha_viaje de los 4 operadores | generate_series entre mínimo y máximo |
| `dia` | Día del mes (1-31). | dim_fecha.fecha | extract(day) |
| `mes` | Mes del año (1-12). | dim_fecha.fecha | extract(month) |
| `anio` | Año calendario. | dim_fecha.fecha | extract(year) |
| `trimestre` | Trimestre del año (1-4). | dim_fecha.fecha | extract(quarter) |
| `dia_semana` | Día de la semana ISO: 1 = lunes ... 7 = domingo. | dim_fecha.fecha | extract(isodow) |
| `es_dia_habil` | Verdadero de lunes a viernes (no considera feriados). | dim_fecha.fecha | isodow entre 1 y 5 |
| `es_fin_semana` | Verdadero sábado y domingo. | dim_fecha.fecha | isodow en (6, 7) |

### `gold.dim_usuario`

Usuario seudonimizado y conformado entre operadores. No contiene ninguna tarjeta original.

**Dueño:** Gobernanza y Seguridad de la Información

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `usuario_sk` | Seudónimo del usuario: md5 de la parte numérica de la tarjeta (10 dígitos) para Transmetro, Transurbano y MetroRiel; md5 de 'AEROMETRO\|hash' para Aerómetro. | silver.dim_usuario_conformado | md5 sobre la llave normalizada; la tarjeta nunca llega a Gold |
| `perfil` | Perfil tarifario vigente según el padrón CDC (solo existe para Transmetro). | cdc_padron_usuarios.csv -> silver.dim_usuario_actual | Último valor no nulo por secuencia (SCD2, versión actual) |
| `zona_residencia` | Zona de residencia vigente según el padrón CDC (solo Transmetro). | cdc_padron_usuarios.csv -> silver.dim_usuario_actual | Último valor no nulo por secuencia |
| `activo_en_transmetro` | Verdadero si la última operación CDC de la tarjeta no es DELETE. | cdc_padron_usuarios.csv | op <> 'DELETE' en la versión actual; falso si no está en el padrón |
| `modos_identificados` | Lista de modos donde aparece el usuario (padrón o viajes), separados por coma. | silver.dim_usuario_conformado | string_agg(distinct modo) |
| `cantidad_modos_identificados` | Cantidad de modos distintos del usuario. 2 o más = usuario multimodal (transbordo). | silver.dim_usuario_conformado | count(distinct modo) |

### `gold.dim_zona`

Zonas con actividad de algún operador, con nombre normalizado.

**Dueño:** Dirección de Planificación Territorial

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `zona_sk` | Llave sustituta de la zona (md5 del nombre normalizado). | silver.dim_zona_conformada | md5(zona_nombre) |
| `zona_nombre` | Nombre oficial: 'Zona N' o municipio con mayúscula inicial. Z10, ZONA 10 y district apuntan a la misma zona. | tm_estaciones.zona, tu_paradas.sector, mr_estaciones.zona_nombre, am_estaciones.district | Normalización de formato (Z10 -> Zona 10, MIXCO -> Mixco) |

## Capa Gold - tablas de hechos

### `gold.fct_abordajes`

Grano: un abordaje válido (acceso exitoso) de Transmetro, Transurbano o Aerómetro por fila. Se construye solo desde Silver.

**Dueño:** Gerencia de Operaciones

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `abordaje_sk` | Llave sustituta del abordaje: md5(modo \|\| '\|' \|\| evento_origen_id). | Silver de cada operador | md5 de modo + id de origen |
| `evento_origen_id` | Id del evento en el sistema del operador: validacion_id, boarding_id o md5 de la fila de Transurbano. | transmetro_validaciones.csv / aerometro_boardings.csv / transurbano_transacciones.csv | Cast a texto; Transurbano no trae id y se genera con md5 de sus columnas |
| `modo_sk` | Llave del modo de transporte. | gold.dim_modo | Join por nombre del modo |
| `modo_nombre` | Nombre del modo (desnormalizado para facilitar el tablero). | Constante por rama del UNION | Ninguna |
| `usuario_sk` | Seudónimo del usuario que abordó. | silver.dim_usuario_conformado | Join por modo + llave original; la llave original no se copia |
| `zona_sk` | Llave de la zona donde ocurrió el abordaje. | gold.dim_zona | Join por nombre de zona normalizado |
| `zona_nombre` | Zona normalizada del abordaje (desnormalizada para el tablero). | tm_estaciones.zona / tu_paradas.sector / am_estaciones.district | Lookup de la estación o parada + normalización de zona |
| `fecha_sk` | Fecha local del abordaje en formato YYYYMMDD. | fecha_hora (TM), fecha+hora (TU), timestamp_utc (AM) | Unificación a hora local de Guatemala; Aerómetro UTC-6 |
| `hora_sk` | Hora local del abordaje (0-23). | Igual que fecha_sk | extract(hour) sobre la hora local |
| `ubicacion_codigo` | Dimensión degenerada: código de estación (TM, AM) o de parada (TU) del operador. | estacion_id / cod_parada / station_code | trim |
| `servicio` | Dimensión degenerada: línea (TM), ruta (TU) o eje (AM). | linea / ruta / axis | trim |
| `fecha_hora_local` | Fecha y hora local del abordaje. | Igual que fecha_sk | Unificación a un solo estándar de timestamp local |
| `monto_gtq` | Tarifa cobrada en quetzales. Medida aditiva. | tarifa (Q), monto_centavos (TU), fare (Q) | Transurbano: centavos / 100 |
| `operacion_exitosa` | Siempre verdadero en esta tabla: las transacciones rechazadas de Transurbano (estado 7 y 9) no son abordajes. | cod_estado (TU) | cod_estado en (1,2,3) |
| `cantidad_abordajes` | Siempre 1. Medida aditiva para sumar abordajes por cualquier dimensión. | Constante | 1 por fila |

### `gold.fct_viajes_metroriel`

Grano: un viaje completo y válido de MetroRiel (con entrada y salida) por fila. Se separa de fct_abordajes porque solo MetroRiel registra origen, destino y duración.

**Dueño:** Gerencia de Operaciones

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `viaje_sk` | Llave sustituta del viaje: md5('METRORIEL\|' \|\| viaje_id). | metroriel_viajes.jsonl -> trip_id | md5 |
| `viaje_id` | trip_id original de MetroRiel. | metroriel_viajes.jsonl -> trip_id | Extraído del JSON y convertido a bigint |
| `modo_sk` | Llave del modo (siempre METRORIEL). | gold.dim_modo | Join fijo a METRORIEL |
| `modo_nombre` | Siempre 'METRORIEL'. | Constante | Ninguna |
| `usuario_sk` | Seudónimo del usuario. | metroriel_viajes.jsonl -> card | Join a silver.dim_usuario_conformado; la tarjeta no se copia |
| `zona_entrada_sk` | Llave de la zona de la estación de entrada. | mr_estaciones.zona_nombre | Lookup por id de estación |
| `zona_salida_sk` | Llave de la zona de la estación de salida. | mr_estaciones.zona_nombre | Lookup por id de estación |
| `zona_entrada` | Nombre de la zona de entrada. | mr_estaciones.zona_nombre | Lookup por entry.station |
| `zona_salida` | Nombre de la zona de salida. | mr_estaciones.zona_nombre | Lookup por exit.station |
| `fecha_sk` | Fecha local de entrada (YYYYMMDD). | metroriel_viajes.jsonl -> entry.ts (ISO 8601) | Cast a timestamp y a fecha |
| `hora_entrada_sk` | Hora local de entrada (0-23). | entry.ts | extract(hour) |
| `hora_salida_sk` | Hora local de salida (0-23). | exit.ts | extract(hour) |
| `estacion_entrada_id` | Id de la estación de entrada (1-22). | entry.station | Extraído del JSON anidado |
| `estacion_entrada` | Nombre de la estación de entrada. | mr_estaciones.nombre_estacion | Lookup |
| `estacion_salida_id` | Id de la estación de salida (1-22). | exit.station | Extraído del JSON anidado |
| `estacion_salida` | Nombre de la estación de salida. | mr_estaciones.nombre_estacion | Lookup |
| `fecha_hora_entrada` | Fecha y hora local de entrada. | entry.ts | Cast ISO 8601 -> timestamp |
| `fecha_hora_salida` | Fecha y hora local de salida. | exit.ts | Cast ISO 8601 -> timestamp |
| `duracion_segundos` | Duración del viaje en segundos. Aditiva para sumar tiempo total; el promedio se recalcula. | duration_s | Cast a entero; viajes sin salida van a cuarentena |
| `monto_gtq` | Tarifa en quetzales. Medida aditiva. | fare_gtq | Cast a numeric(10,2) |
| `cantidad_viajes` | Siempre 1. Medida aditiva. | Constante | 1 por fila |

## Capa Gold - vistas para el tablero

### `gold.rpt_cobertura_zona`

Vista para el tablero (cobertura y caso MetroRiel). Una fila por zona del área metropolitana, incluyendo zonas donde vive gente según el padrón pero ningún modo opera.

**Dueño:** Dirección de Planificación Territorial

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `zona_sk` | md5 del nombre de zona (misma fórmula que dim_zona). | dim_zona + padrón | md5(zona_nombre) |
| `zona_nombre` | Nombre normalizado de la zona. | gold.dim_zona y silver.dim_usuario_actual.zona_residencia | UNION + macro normalizar_zona |
| `residentes_padron` | Tarjetas del padrón vigente con esa zona de residencia. | cdc_padron_usuarios.csv -> silver.dim_usuario_actual | count(*) por zona |
| `residentes_activos` | Tarjetas activas del padrón con esa zona de residencia. | silver.dim_usuario_actual | count(*) filter (activo) |
| `abordajes_transmetro` | Abordajes válidos de Transmetro en la zona. | gold.fct_abordajes | count por zona y modo |
| `abordajes_transurbano` | Abordajes válidos (aprobados) de Transurbano en la zona. | gold.fct_abordajes | count por zona y modo |
| `abordajes_aerometro` | Abordajes de Aerómetro en la zona. | gold.fct_abordajes | count por zona y modo |
| `viajes_metroriel_origen` | Viajes completos de MetroRiel que inician en la zona. | gold.fct_viajes_metroriel | count por zona_entrada |
| `viajes_metroriel_destino` | Viajes completos de MetroRiel que terminan en la zona. | gold.fct_viajes_metroriel | count por zona_salida |
| `modos_con_servicio` | Cantidad de modos (0-4) con actividad en la zona. | Columnas anteriores | Suma de banderas > 0 |
| `sin_servicio` | Verdadero si ningún modo registró actividad en la zona. | Columnas anteriores | total = 0 |
| `en_trazado_metroriel` | Verdadero para las zonas del trazado propuesto: 12, 8, 1, 6 y 17. | Enunciado del proyecto | Macro zonas_trazado_metroriel |
| `demanda_sin_metroriel` | Abordajes de Transmetro + Transurbano + Aerómetro: demanda que existe independientemente de MetroRiel. | gold.fct_abordajes | Suma |
| `demanda_total` | demanda_sin_metroriel + viajes de MetroRiel que inician en la zona. | fct_abordajes + fct_viajes_metroriel | Suma |
| `ranking_demanda_sin_metroriel` | Posición de la zona por demanda_sin_metroriel (1 = mayor). | Columna demanda_sin_metroriel | rank() descendente |

### `gold.rpt_demanda_red`

Vista para el tablero: demanda de los CUATRO modos por zona, fecha y hora. Un viaje de MetroRiel cuenta como un abordaje en su zona y hora de entrada.

**Dueño:** Gerencia de Operaciones

| Campo | Significado | Fuente | Transformación |
|---|---|---|---|
| `modo_sk` | Llave del modo. | fct_abordajes / fct_viajes_metroriel | UNION ALL |
| `modo_nombre` | Nombre del modo (los cuatro). | fct_abordajes / fct_viajes_metroriel | UNION ALL |
| `zona_sk` | Zona del abordaje o de la entrada a MetroRiel. | fct_abordajes.zona_sk / fct_viajes_metroriel.zona_entrada_sk | UNION ALL |
| `zona_nombre` | Nombre normalizado de la zona. | Igual que zona_sk | UNION ALL |
| `fecha_sk` | Fecha local (YYYYMMDD). | Hechos Gold | UNION ALL |
| `hora_sk` | Hora local (0-23); para MetroRiel, hora de entrada. | Hechos Gold | UNION ALL |
| `franja_horaria` | Franja de dim_hora. | gold.dim_hora | Join por hora_sk |
| `es_hora_pico` | Bandera oficial de hora pico. | gold.dim_hora | Join por hora_sk |
| `es_dia_habil` | Lunes a viernes. | gold.dim_fecha | Join por fecha_sk |
| `abordajes` | Abordajes (o entradas a MetroRiel) en el grupo. Aditiva. | cantidad_abordajes / cantidad_viajes | sum |
| `ingreso_gtq` | Tarifa total cobrada en quetzales. Aditiva. | monto_gtq | sum |

## Capa Features (ciencia de datos)

### `features.features_usuario_movilidad`

Tabla de features para ciencia de datos (sección 2.3). Una fila por usuario con al menos un viaje válido hasta la fecha de corte (variable dbt `fecha_corte`, por defecto 2026-07-15). Se calcula desde Silver (detalle atómico), nunca desde Gold. Permite entrenar, por ejemplo, un modelo que prediga qué usuarios dejarán de viajar en los próximos 30 días.

**Dueño:** Equipo de Ciencia de Datos

| Campo | Significado |
|---|---|
| `usuario_sk` | Seudónimo del usuario (misma llave que gold.dim_usuario). |
| `fecha_corte` | Fecha de corte del cálculo. Ningún evento posterior se usa. |
| `perfil_padron` | Perfil tarifario según el padrón (solo usuarios con tarjeta Transmetro). |
| `viajes_ultimos_7d` | Viajes válidos en los 7 días que terminan en la fecha de corte. |
| `viajes_ultimos_30d` | Viajes válidos en los últimos 30 días. |
| `viajes_ultimos_90d` | Viajes válidos en los últimos 90 días (el periodo de datos es de 45 días). |
| `viajes_total` | Viajes válidos de todo el historial hasta la fecha de corte. |
| `dias_activos` | Días distintos con al menos un viaje. |
| `dias_desde_ultimo_viaje` | Días entre el último viaje y la fecha de corte (recencia). |
| `dias_desde_primer_viaje` | Días entre el primer viaje observado y la fecha de corte (antigüedad). |
| `modo_mas_usado` | Modo con más viajes; empate se resuelve alfabéticamente. |
| `cantidad_modos` | Modos distintos con viajes observados (1-4). |
| `es_multimodal` | Verdadero si viajó en 2 o más modos. |
| `viajes_transmetro` | Viajes válidos en Transmetro. |
| `viajes_transurbano` | Viajes válidos (aprobados) en Transurbano. |
| `viajes_metroriel` | Viajes completos en MetroRiel. |
| `viajes_aerometro` | Abordajes en Aerómetro. |
| `proporcion_hora_pico` | Fracción de viajes en hora pico oficial (06-08 y 16-18 h), entre 0 y 1. |
| `proporcion_fin_semana` | Fracción de viajes en sábado o domingo, entre 0 y 1. |
| `zona_origen_mas_frecuente` | Zona donde más aborda (para MetroRiel, zona de entrada). |
| `zonas_distintas` | Cantidad de zonas distintas donde abordó. |
| `gasto_total_gtq` | Gasto acumulado en quetzales. |
| `gasto_promedio_viaje_gtq` | Gasto promedio por viaje en quetzales. |
| `transacciones_rechazadas` | Transacciones rechazadas en Transurbano (saldo insuficiente o tarjeta inválida). |
