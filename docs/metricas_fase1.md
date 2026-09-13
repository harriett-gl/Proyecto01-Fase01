# Métricas y evidencia de idempotencia — Fase 1

## Resumen de resultados

El pipeline de la Red Metropolitana fue ejecutado dos veces consecutivas para comprobar que el proceso es idempotente. Ambas ejecuciones finalizaron correctamente y produjeron la misma cantidad de registros en todas las capas.

| Métrica | Ejecución 1 | Ejecución 2 | Resultado |
|---|---:|---:|---|
| Estado | EXITOSA | EXITOSA | Correcto |
| Registros Staging | 1,730,184 | 1,730,184 | Idénticos |
| Registros Silver | 1,919,887 | 1,919,887 | Idénticos |
| Registros Gold | 1,718,037 | 1,718,037 | Idénticos |
| Registros en cuarentena | 18,431 | 18,431 | Idénticos |
| Duración | 69.18 segundos | 69.86 segundos | Variación normal |

## Validación de idempotencia

La segunda ejecución no generó duplicados ni modificó la cantidad de registros procesados. Los resultados de Staging, Silver, Gold y Cuarentena permanecieron iguales.

Por lo tanto, se confirma que el pipeline es idempotente para el conjunto de datos utilizado.

## Indicadores de calidad

- Registros enviados a cuarentena: **18,431**.
- Registros procesados en Silver: **1,919,887**.
- Registros generados en Gold: **1,718,037**.
- Registros en `fct_abordajes`: **1,352,058**.
- Registros en `fct_viajes_metroriel`: **295,511**.
- Usuarios en `dim_usuario`: **70,380**.
- Ejecuciones exitosas evaluadas: **2**.
- Fallos registrados durante las ejecuciones evaluadas: **0**.

## Rendimiento

El pipeline completo tardó aproximadamente entre **69.18 y 69.86 segundos**. La diferencia de tiempo entre las ejecuciones fue de únicamente 0.68 segundos y no afectó la consistencia de los resultados.

## Consulta utilizada

```sql
SELECT
    fecha_inicio,
    estado,
    registros_staging,
    registros_silver,
    registros_gold,
    registros_cuarentena,
    duracion_segundos
FROM audit.ejecuciones_pipeline
ORDER BY fecha_inicio DESC
LIMIT 2;
```

## Volumen de datos Bronze

La capa Bronze almacenó un total de **1,730,184 registros**, distribuidos entre fuentes batch, streaming y CDC.

| Fuente | Tipo de ingesta | Registros |
|---|---|---:|
| Transmetro — estaciones | Batch | 104 |
| Transurbano — paradas | Batch | 328 |
| MetroRiel — estaciones | Batch | 22 |
| Aerometro — estaciones | Batch | 14 |
| Transurbano — transacciones | Batch | 832,791 |
| MetroRiel — viajes | Batch | 299,100 |
| Transmetro — eventos | Streaming | 363,221 |
| Aerometro — eventos | Streaming | 203,554 |
| Padrón metropolitano | CDC | 31,050 |
| **Total** |  | **1,730,184** |

## Operaciones CDC

Se procesaron **31,050 operaciones CDC** provenientes del padrón metropolitano.

| Operación | Cantidad |
|---|---:|
| INSERT | 10,800 |
| UPDATE | 16,200 |
| DELETE | 4,050 |
| **Total** | **31,050** |

Después de aplicar las operaciones CDC, el estado actual del padrón fue:

| Estado | Cantidad |
|---|---:|
| Activos | 15,096 |
| Inactivos | 2,336 |
| **Total** | **17,432** |

Los eventos `DELETE` no eliminan físicamente al usuario, sino que lo marcan como inactivo para conservar su historial.

## Catálogos mínimos de usuarios

| Operador | Usuarios distintos |
|---|---:|
| Aerometro | 14,496 |
| MetroRiel | 22,885 |
| Transurbano | 36,567 |

## Resultados de las reglas de calidad

| Tabla de cuarentena | Motivo | Cantidad |
|---|---|---:|
| `cdc_llaves_invalidas` | Llave ausente | 2,206 |
| `cdc_llaves_invalidas` | Llave no pertenece al padrón Transmetro | 6,518 |
| `metroriel_sin_salida` | Viaje sin salida | 3,589 |
| `transmetro_duplicados` | Validación duplicada | 1,115 |
| `transurbano_invalidos` | Código de parada nulo | 4,186 |
| `transurbano_invalidos` | Código de parada nulo y fecha futura | 3 |
| `transurbano_invalidos` | Fecha futura | 814 |
| **Total** |  | **18,431** |

