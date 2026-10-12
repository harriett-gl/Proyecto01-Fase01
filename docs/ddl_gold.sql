-- DDL LÓGICO DE LA CAPA GOLD
-- PROYECTO RED METROPOLITANA - FASE 01

-- 1. CREACIÓN DEL ESQUEMA GOLD
CREATE SCHEMA IF NOT EXISTS gold;

-- 2. DIMENSIÓN FECHA
CREATE TABLE IF NOT EXISTS gold.dim_fecha (
    fecha_sk INTEGER PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    dia INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    anio INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    es_dia_habil BOOLEAN NOT NULL,
    es_fin_semana BOOLEAN NOT NULL
);

-- 3. DIMENSIÓN HORA
CREATE TABLE IF NOT EXISTS gold.dim_hora (
    hora_sk INTEGER PRIMARY KEY,
    hora INTEGER NOT NULL UNIQUE,
    franja_horaria TEXT NOT NULL,
    es_hora_pico BOOLEAN NOT NULL
);

-- 4. DIMENSIÓN MODO DE TRANSPORTE
CREATE TABLE IF NOT EXISTS gold.dim_modo (
    modo_sk INTEGER PRIMARY KEY,
    modo_nombre TEXT NOT NULL UNIQUE
);

-- 5. DIMENSIÓN USUARIO CONFORMADO
CREATE TABLE IF NOT EXISTS gold.dim_usuario (
    usuario_sk VARCHAR(32) PRIMARY KEY,
    perfil TEXT,
    zona_residencia TEXT,
    activo_en_transmetro BOOLEAN NOT NULL,
    modos_identificados TEXT NOT NULL,
    cantidad_modos_identificados BIGINT NOT NULL
);

-- 6. DIMENSIÓN ZONA CONFORMADA
CREATE TABLE IF NOT EXISTS gold.dim_zona (
    zona_sk VARCHAR(32) PRIMARY KEY,
    zona_nombre TEXT NOT NULL UNIQUE
);

-- 7. TABLA DE HECHOS DE ABORDAJES
-- Grano: una fila por abordaje válido de Transmetro, Transurbano o Aerómetro.
CREATE TABLE IF NOT EXISTS gold.fct_abordajes (
    abordaje_sk         VARCHAR(32)   PRIMARY KEY,
    evento_origen_id    TEXT          NOT NULL,
    modo_sk             INTEGER       NOT NULL REFERENCES gold.dim_modo (modo_sk),
    modo_nombre         TEXT          NOT NULL,
    usuario_sk          VARCHAR(32)   NOT NULL REFERENCES gold.dim_usuario (usuario_sk),
    zona_sk             VARCHAR(32)   NOT NULL REFERENCES gold.dim_zona (zona_sk),
    zona_nombre         TEXT          NOT NULL,
    fecha_sk            INTEGER       NOT NULL REFERENCES gold.dim_fecha (fecha_sk),
    hora_sk             INTEGER       NOT NULL REFERENCES gold.dim_hora (hora_sk),
    ubicacion_codigo    TEXT,                       -- dimensión degenerada
    servicio            TEXT,                       -- dimensión degenerada (línea / ruta / eje)
    fecha_hora_local    TIMESTAMPTZ   NOT NULL,
    monto_gtq           NUMERIC(10,2) NOT NULL,     -- aditiva
    operacion_exitosa   BOOLEAN       NOT NULL,
    cantidad_abordajes  INTEGER       NOT NULL DEFAULT 1  -- aditiva
);

-- 8. TABLA DE HECHOS DE VIAJES DE METRORIEL
-- Grano: una fila por viaje completo válido de MetroRiel (entrada y salida).
CREATE TABLE IF NOT EXISTS gold.fct_viajes_metroriel (
    viaje_sk            VARCHAR(32)   PRIMARY KEY,
    viaje_id            BIGINT        NOT NULL UNIQUE,
    modo_sk             INTEGER       NOT NULL REFERENCES gold.dim_modo (modo_sk),
    modo_nombre         TEXT          NOT NULL,
    usuario_sk          VARCHAR(32)   NOT NULL REFERENCES gold.dim_usuario (usuario_sk),
    zona_entrada_sk     VARCHAR(32)   NOT NULL REFERENCES gold.dim_zona (zona_sk),
    zona_salida_sk      VARCHAR(32)   NOT NULL REFERENCES gold.dim_zona (zona_sk),
    zona_entrada        TEXT,
    zona_salida         TEXT,
    fecha_sk            INTEGER       NOT NULL REFERENCES gold.dim_fecha (fecha_sk),
    hora_entrada_sk     INTEGER       NOT NULL REFERENCES gold.dim_hora (hora_sk),
    hora_salida_sk      INTEGER       NOT NULL REFERENCES gold.dim_hora (hora_sk),
    estacion_entrada_id INTEGER,
    estacion_entrada    TEXT,
    estacion_salida_id  INTEGER,
    estacion_salida     TEXT,
    fecha_hora_entrada  TIMESTAMP     NOT NULL,
    fecha_hora_salida   TIMESTAMP     NOT NULL,
    duracion_segundos   INTEGER       NOT NULL,     -- aditiva (el promedio se recalcula)
    monto_gtq           NUMERIC(10,2) NOT NULL,     -- aditiva
    cantidad_viajes     INTEGER       NOT NULL DEFAULT 1  -- aditiva
);

-- 9. VISTAS DE CONSUMO PARA EL TABLERO (Fase 02)
-- gold.rpt_cobertura_zona : una fila por zona (incluye zonas sin servicio).
-- gold.rpt_demanda_red    : demanda de los 4 modos por zona, fecha y hora.
-- Se crean con dbt (models/gold/rpt_*.sql); su definición vive en el repositorio.

-- Nota: dbt materializa estas tablas con CREATE TABLE AS. Las llaves y
-- relaciones de este DDL lógico se verifican con pruebas dbt (unique,
-- not_null y relationships en models/gold/*.yml).
