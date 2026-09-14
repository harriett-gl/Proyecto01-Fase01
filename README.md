# Proyecto 01 — Red Metropolitana de Transporte

Pipeline de datos desarrollado para integrar y analizar información de los operadores Transmetro, Transurbano, Aerometro y MetroRiel.

El proyecto implementa ingesta batch, streaming con Kafka, procesamiento CDC, almacenamiento Bronze, transformaciones con dbt, controles de calidad, modelos Silver y un modelo dimensional Gold.

## Arquitectura

El flujo general del proyecto es:

1. Ingesta batch, streaming y CDC.
2. Almacenamiento de archivos Parquet en la capa Bronze.
3. Carga de información al esquema Staging de PostgreSQL.
4. Limpieza, validación y conformación en Silver.
5. Envío de registros inválidos a Cuarentena.
6. Construcción del modelo dimensional Gold.
7. Registro de métricas en el esquema Audit.
8. Orquestación completa mediante Prefect.

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

## Estructura principal

```text
Proyecto01-Fase01/
├── lake/
│   └── bronze/
├── scripts/
│   ├── ingesta_batch.py
│   ├── ingesta_cdc.py
│   ├── stream_producer.py
│   ├── stream_consumer.py
│   └── cargar_staging.py
├── orchestration/
│   └── flow_red_metropolitana.py
├── dbt_red_metropolitana/
│   ├── models/
│   │   ├── staging/
│   │   ├── silver/
│   │   ├── quarantine/
│   │   └── gold/
│   ├── dbt_project.yml
│   └── profiles.yml
├── docs/
│   ├── matriz_bus.md
│   ├── diagrama_modelo.md
│   ├── ddl_gold.sql
│   └── metricas_fase1.md
├── docker-compose.yml
├── .env.example
└── requirements.txt
```

## Fuentes de información

El proyecto integra información de:

- Transmetro.
- Transurbano.
- Aerometro.
- MetroRiel.
- Padrón metropolitano de usuarios.

Los catálogos y archivos históricos se procesan mediante ingesta batch. Los eventos de Transmetro y Aerometro se procesan mediante Kafka. Las modificaciones del padrón de usuarios se procesan como eventos CDC.

Transurbano se implementó mediante una carga batch debido a que la fuente disponible corresponde a un archivo histórico y no a un productor de eventos en tiempo real.

## Capas de datos

### Bronze

#### Justificación del almacenamiento Bronze

Se eligió un lake local basado en carpetas y archivos Parquet porque permite conservar los datos con su estructura original, acumular nuevas ingestas y particionar físicamente la información por fecha.

Esta decisión también permite almacenar el JSON anidado de MetroRiel como contenido crudo sin obligarlo a adoptar inmediatamente un esquema relacional. La interpretación y normalización de esa estructura se realiza posteriormente en Staging y Silver.

El formato Parquet reduce el tamaño en disco mediante compresión, conserva los tipos de datos y permite reprocesar las fuentes sin modificar los archivos originales. El warehouse se utiliza posteriormente para Staging, Silver, Cuarentena y Gold, donde los datos ya poseen una estructura definida.

Cada registro almacenado en Bronze conserva la marca de tiempo y la fecha de ingesta, junto con información del archivo de origen, para garantizar su trazabilidad.

### Staging

Carga temporalmente las fuentes Bronze en PostgreSQL para que puedan ser transformadas mediante dbt.

### Silver

Contiene información limpia, validada, normalizada y conformada. Aquí se procesan fechas, zonas, usuarios, transacciones y reglas de calidad.

### Quarantine

Almacena registros que no cumplen las reglas de calidad, incluyendo duplicados, valores nulos, fechas futuras y viajes incompletos.

### Gold

Implementa el modelo dimensional utilizado para análisis y visualización.

Tablas de hechos:

- `gold.fct_abordajes`
- `gold.fct_viajes_metroriel`

Dimensiones conformadas:

- `gold.dim_fecha`
- `gold.dim_hora`
- `gold.dim_usuario`
- `gold.dim_modo`
- `gold.dim_zona`

## Modelo dimensional

La matriz de procesos y dimensiones está documentada en:

- [`docs/matriz_bus.md`](docs/matriz_bus.md)

El diagrama dimensional está disponible en:

- [`docs/diagrama_modelo.md`](docs/diagrama_modelo.md)

El DDL de las tablas Gold está disponible en:

- [`docs/ddl_gold.sql`](docs/ddl_gold.sql)

## Configuración del proyecto

### 1. Crear el archivo de variables

Copiar el archivo de ejemplo:

```bash
cp .env.example .env
```

Editar `.env` y colocar las credenciales locales de PostgreSQL.

El archivo `.env` contiene información privada y no debe subirse al repositorio.

### 2. Crear el entorno virtual

```bash
python3.12 -m venv .venv
source .venv/bin/activate
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 4. Levantar PostgreSQL y Kafka

```bash
docker compose up -d
docker compose ps
```

PostgreSQL debe aparecer con estado `healthy` y Kafka con estado `Up`.

### 5. Cargar las variables de entorno

```bash
set -a
source .env
set +a
```

### 6. Validar la conexión de dbt

```bash
dbt debug \
  --project-dir dbt_red_metropolitana \
  --profiles-dir dbt_red_metropolitana
```

### 7. Ejecutar el pipeline completo

```bash
python orchestration/flow_red_metropolitana.py
```

El flujo ejecuta las ingestas, carga Staging, construye los modelos dbt, ejecuta las pruebas, registra las métricas y limpia las tablas temporales.

## Ejecución manual de dbt

Cuando Staging contenga datos, se pueden ejecutar las transformaciones manualmente:

```bash
dbt build \
  --project-dir dbt_red_metropolitana \
  --profiles-dir dbt_red_metropolitana
```

## Pruebas de calidad

El proyecto utiliza pruebas dbt para validar:

- Campos obligatorios.
- Llaves únicas.
- Integridad referencial.
- Relaciones entre hechos y dimensiones.
- Catálogos mínimos de usuarios.
- Consistencia del modelo dimensional.

## Idempotencia

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

## Seguridad

- Las credenciales se administran mediante variables de entorno.
- `.env` está excluido del repositorio.
- `.env.example` únicamente contiene valores de referencia.
- Los identificadores originales de los usuarios no se exponen en las tablas Gold.
- Las dimensiones utilizan llaves sustitutas.

## Autoras

Proyecto académico desarrollado para la Fase 1 del Proyecto Red Metropolitana por:

💜 Rochelle Esquivel
🩷 Susana García
💙 Harriett Guzmán