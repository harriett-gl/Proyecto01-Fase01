# Proyecto 01 — Red Metropolitana de Transporte

Pipeline de datos desarrollado para integrar, transformar, analizar y visualizar información de los operadores **Transmetro, Transurbano, Aerometro y MetroRiel**.

El proyecto integra las **Fases 01 y 02** de la Red Metropolitana. La primera fase implementa la arquitectura de datos, ingestas batch, streaming y CDC, almacenamiento Bronze, transformaciones con dbt y el modelo dimensional Gold. La segunda fase amplía la solución mediante análisis de movilidad, generación de features, identificación de usuarios multimodales y visualizaciones interactivas en Tableau.

---

## Arquitectura

El flujo general del proyecto es:

1. Ingesta batch, streaming y CDC.
2. Almacenamiento de archivos Parquet en la capa Bronze.
3. Carga de información al esquema Staging de PostgreSQL.
4. Limpieza, validación y conformación en Silver.
5. Envío de registros inválidos a Quarantine.
6. Construcción del modelo dimensional Gold.
7. Generación de features de movilidad.
8. Validaciones de calidad mediante dbt.
9. Análisis de demanda y comportamiento multimodal.
10. Visualización de resultados mediante Tableau.
11. Registro de métricas en el esquema Audit.
12. Orquestación mediante Prefect.

---

## Tecnologías utilizadas

- Python 3.12
- PostgreSQL 16
- Docker y Docker Compose
- Apache Kafka
- dbt Core
- dbt-postgres
- Prefect
- PyArrow
- Pandas
- Psycopg
- Parquet
- Tableau Desktop

---

## Estructura principal

```text
Proyecto01-Fase01/
│
├── datos_red/
│   └── fuentes originales del proyecto
│
├── lake/
│   └── bronze/
│       ├── batch/
│       ├── cdc/
│       └── streaming/
│
├── scripts/
│   ├── cargar_staging.py
│   ├── ingesta_batch.py
│   ├── ingesta_cdc.py
│   ├── stream_consumer.py
│   └── stream_producer.py
│
├── orchestration/
│   └── flow_red_metropolitana.py
│
├── dbt_red_metropolitana/
│   ├── analyses/
│   ├── logs/
│   ├── macros/
│   ├── models/
│   │   ├── features/
│   │   │   ├── features.yml
│   │   │   └── features_usuario_movilidad.sql
│   │   ├── gold/
│   │   ├── quarantine/
│   │   ├── silver/
│   │   └── staging/
│   ├── seeds/
│   ├── snapshots/
│   ├── tests/
│   ├── dbt_project.yml
│   └── profiles.yml
│
├── docs/
│   ├── evidencias/
│   │   ├── Proyecto 01 - Fase 01.pdf
│   │   ├── Proyecto 01 - Fase 01.pptx
│   │   ├── Proyecto 01 - Fase 02.pdf
│   │   ├── Proyecto 01 - Fase 02.pptx
│   │   └── Proyecto 01 - Fase 02.twb
│   ├── Fase 02.sql
│   ├── ddl_gold.sql
│   ├── diagrama_modelo.md
│   ├── matriz_bus.md
│   ├── medicion_capas.sql
│   ├── metricas.sql
│   ├── metricas_fase1.md
│   └── validaciones.sql
│
├── logs/
│   └── registros generados durante la ejecución
│
├── docker-compose.yml
├── generar_red_metropolitana.py
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

> **Nota:** Las carpetas `datos_red/`, `lake/bronze/` y `logs/` forman parte de la ejecución local del pipeline, pero algunos de sus archivos pueden no almacenarse directamente en el repositorio debido al volumen de datos y a los archivos generados durante la ejecución.

---

## Descripción de carpetas y archivos

- **datos_red/**: contiene las fuentes de datos originales utilizadas para desarrollar el proyecto.
- **lake/bronze/**: almacena los datos originales en formato Parquet, organizados según su método de ingesta.
- **scripts/**: contiene los programas responsables de las ingestas batch, CDC y streaming, además de la carga hacia Staging.
- **orchestration/**: contiene el flujo de Prefect que coordina las etapas del pipeline.
- **dbt_red_metropolitana/**: contiene los modelos SQL y la configuración de dbt para construir las capas Staging, Silver, Quarantine, Gold y Features.
- **dbt_red_metropolitana/models/features/**: contiene el modelo analítico utilizado para generar características de movilidad de los usuarios.
- **docs/**: reúne la documentación técnica, métricas, modelo dimensional, consultas SQL y validaciones del proyecto.
- **docs/evidencias/**: contiene los informes, presentaciones y archivos de visualización correspondientes a las Fases 01 y 02 del proyecto.
- **logs/**: almacena los registros generados durante las ejecuciones del pipeline.
- **generar_red_metropolitana.py**: genera o prepara los archivos de datos utilizados por el proyecto.
- **docker-compose.yml**: configura los servicios de infraestructura, como PostgreSQL y Kafka.
- **.env.example**: presenta las variables de entorno necesarias sin incluir credenciales reales.
- **.gitignore**: define los archivos locales que no deben subirse al repositorio.
- **requirements.txt**: contiene las dependencias de Python.
- **README.md**: explica la instalación, ejecución, arquitectura y decisiones técnicas del proyecto.

---

## Fuentes de información

El proyecto integra información de:

- Transmetro.
- Transurbano.
- Aerometro.
- MetroRiel.
- Padrón metropolitano de usuarios.

Los catálogos y archivos históricos se procesan mediante ingesta batch. Los eventos de Transmetro y Aerometro se procesan mediante Kafka. Las modificaciones del padrón de usuarios se procesan como eventos CDC.

Transurbano se implementó mediante una carga batch debido a que la fuente disponible corresponde a un archivo histórico y no a un productor de eventos en tiempo real.

---

# Capas de datos

## Bronze

### Justificación del almacenamiento Bronze

Se eligió un lake local basado en carpetas y archivos Parquet porque permite conservar los datos con su estructura original, acumular nuevas ingestas y particionar físicamente la información por fecha.

Esta decisión también permite almacenar el JSON anidado de MetroRiel como contenido crudo sin obligarlo a adoptar inmediatamente un esquema relacional. La interpretación y normalización de esa estructura se realiza posteriormente en Staging y Silver.

El formato Parquet reduce el tamaño en disco mediante compresión, conserva los tipos de datos y permite reprocesar las fuentes sin modificar los archivos originales. El warehouse se utiliza posteriormente para Staging, Silver, Cuarentena y Gold, donde los datos ya poseen una estructura definida.

Cada registro almacenado en Bronze conserva la marca de tiempo y la fecha de ingesta, junto con información del archivo de origen, para garantizar su trazabilidad.

## Staging

Carga temporalmente las fuentes Bronze en PostgreSQL para que puedan ser transformadas mediante dbt.

## Silver

Contiene información limpia, validada, normalizada y conformada. Aquí se procesan fechas, zonas, usuarios, transacciones y reglas de calidad.

## Quarantine

Almacena registros que no cumplen las reglas de calidad, incluyendo duplicados, valores nulos, fechas futuras y viajes incompletos.

## Gold

Implementa el modelo dimensional utilizado para análisis y visualización.

### Tablas de hechos

- `gold.fct_abordajes`
- `gold.fct_viajes_metroriel`

### Dimensiones conformadas

- `gold.dim_fecha`
- `gold.dim_hora`
- `gold.dim_usuario`
- `gold.dim_modo`
- `gold.dim_zona`

## Features

La Fase 02 incorpora una capa analítica de features destinada a generar variables derivadas del comportamiento de movilidad de los usuarios.

Modelo principal:

- `features.features_usuario_movilidad`

---

# Modelo dimensional

La matriz de procesos y dimensiones está documentada en:

- [`docs/matriz_bus.md`](docs/matriz_bus.md)

El diagrama dimensional está disponible en:

- [`docs/diagrama_modelo.md`](docs/diagrama_modelo.md)

El DDL de las tablas Gold está disponible en:

- [`docs/ddl_gold.sql`](docs/ddl_gold.sql)

---

# Configuración del proyecto

## 1. Crear el archivo de variables

Copiar el archivo de ejemplo:

```bash
cp .env.example .env
```

Editar `.env` y colocar las credenciales locales de PostgreSQL.

El archivo `.env` contiene información privada y no debe subirse al repositorio.

## 2. Crear el entorno virtual

```bash
python3.12 -m venv .venv
source .venv/bin/activate
```

## 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

## 4. Levantar PostgreSQL y Kafka

```bash
docker compose up -d
docker compose ps
```

PostgreSQL debe aparecer con estado `healthy` y Kafka con estado `Up`.

## 5. Cargar las variables de entorno

```bash
set -a
source .env
set +a
```

## 6. Validar la conexión de dbt

```bash
dbt debug \
  --project-dir dbt_red_metropolitana \
  --profiles-dir dbt_red_metropolitana
```

## 7. Ejecutar el pipeline completo

```bash
python orchestration/flow_red_metropolitana.py
```

El flujo ejecuta las ingestas, carga Staging, construye los modelos dbt, ejecuta las pruebas, registra las métricas y limpia las tablas temporales.

---

# Ejecución manual de dbt

Cuando Staging contenga datos, se pueden ejecutar las transformaciones manualmente:

```bash
dbt build \
  --project-dir dbt_red_metropolitana \
  --profiles-dir dbt_red_metropolitana
```

---

# Pruebas de calidad

El proyecto utiliza pruebas dbt para validar:

- Campos obligatorios.
- Llaves únicas.
- Integridad referencial.
- Relaciones entre hechos y dimensiones.
- Catálogos mínimos de usuarios.
- Consistencia del modelo dimensional.
- Integridad de las features de movilidad.

---

# Idempotencia

El pipeline fue ejecutado dos veces consecutivas y produjo los mismos resultados:

| Capa | Ejecución 1 | Ejecución 2 |
|---|---:|---:|
| Staging | 1,730,184 | 1,730,184 |
| Silver | 1,919,887 | 1,919,887 |
| Gold | 1,718,037 | 1,718,037 |
| Cuarentena | 18,431 | 18,431 |

Las dos ejecuciones finalizaron con estado `EXITOSA`, demostrando que el pipeline no genera duplicados al reprocesar las mismas fuentes.

La evidencia completa está disponible en:

- [`docs/metricas_fase1.md`](docs/metricas_fase1.md)

---

# Seguridad

- Las credenciales se administran mediante variables de entorno.
- `.env` está excluido del repositorio.
- `.env.example` únicamente contiene valores de referencia.
- Los identificadores originales de los usuarios no se exponen en las tablas Gold.
- Las dimensiones utilizan llaves sustitutas.

---

# Fase 02 — Visualización y Análisis de Movilidad

La **Fase 02** amplía el modelo desarrollado durante la primera fase para transformar los datos consolidados en información útil para el análisis de movilidad de la Red Metropolitana.

## Features de movilidad

Se incorporó una nueva capa dentro del proyecto dbt:

```text
dbt_red_metropolitana/models/features/
├── features.yml
└── features_usuario_movilidad.sql
```

El modelo `features_usuario_movilidad` permite generar características analíticas por usuario, incluyendo:

- Cantidad de modos identificados.
- Identificación de usuarios multimodales.
- Actividad dentro de la red.
- Variables derivadas del comportamiento de movilidad.

Se considera **usuario multimodal** a aquel identificado en **dos o más modos de transporte**.

---

## Usuarios multimodales

El análisis realizado permitió identificar:

> **36,829 usuarios multimodales**

Distribución según la cantidad de modos identificados:

| Cantidad de modos | Usuarios |
|:---:|---:|
| 1 | 33,551 |
| 2 | 26,833 |
| 3 | 9,996 |

---

## Análisis del caso MetroRiel

Para el análisis de demanda se evaluaron las zonas objetivo:

`Zona 12` · `Zona 8` · `Zona 1` · `Zona 6` · `Zona 17`

| Zona | Demanda total |
|:---|---:|
| Zona 17 | 94,799 |
| Zona 12 | 93,933 |
| Zona 1 | 83,367 |
| Zona 8 | 80,157 |
| Zona 6 | 71,840 |

Estos resultados permiten comparar la demanda existente en las zonas objetivo y apoyar el análisis de cobertura y planificación de MetroRiel.

---

## Validación con dbt

El modelo de features fue sometido a pruebas de calidad para verificar:

- Valores no nulos.
- Unicidad de `usuario_sk`.
- Integridad de la cantidad de modos.
- Clasificación de usuarios multimodales.

Resultado final:

```text
PASS=4
WARN=0
ERROR=0
SKIP=0
TOTAL=4
```

**Todas las pruebas finalizaron correctamente.**

---

# Visualización en Tableau

Se desarrolló el dashboard **Red Metropolitana** en Tableau Desktop.

Incluye las siguientes visualizaciones:

- **Abordajes por Modo**
- **Demanda por Zona**
- **Demanda por Hora**
- **Usuarios Multimodales**
- **Viajes por estación de MetroRiel**
- **Cobertura por Zona**

El dashboard incorpora filtros interactivos por modo de transporte y zona para facilitar la exploración y comparación de los resultados.

---

# Archivos de la Fase 02

Los principales archivos incorporados son:

```text
dbt_red_metropolitana/models/features/
├── features.yml
└── features_usuario_movilidad.sql

docs/
├── Fase 02.sql
├── validaciones.sql
└── evidencias/
    ├── Proyecto 01 - Fase 02.pdf
    ├── Proyecto 01 - Fase 02.pptx
    └── Proyecto 01 - Fase 02.twb
```

---

# Resultado de la Fase 02

La Fase 02 permitió extender la arquitectura construida previamente hacia una capa analítica orientada al estudio de la movilidad.

La integración entre **PostgreSQL, dbt y Tableau** permite pasar desde los datos consolidados hasta indicadores y visualizaciones que facilitan el análisis de demanda, multimodalidad y cobertura territorial.

---

# Autoras

Proyecto académico desarrollado para las **Fases 01 y 02 del Proyecto Red Metropolitana** por:

💜 Rochelle Esquivel  
🩷 Susana García  
💙 Harriett Guzmán