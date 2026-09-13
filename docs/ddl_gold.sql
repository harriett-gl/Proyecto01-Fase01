-- DDL lógico de la capa Gold
-- Proyecto Red Metropolitana

CREATE SCHEMA IF NOT EXISTS gold;

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

CREATE TABLE IF NOT EXISTS gold.dim_hora (
    hora_sk INTEGER PRIMARY KEY,
    hora INTEGER NOT NULL UNIQUE,
    franja_horaria TEXT NOT NULL,
    es_hora_pico BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS gold.dim_modo (
    modo_sk INTEGER PRIMARY KEY,
    modo_nombre TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS gold.dim_usuario (
    usuario_sk VARCHAR(32) PRIMARY KEY,
    perfil TEXT,
    zona_residencia TEXT,
    activo_en_transmetro BOOLEAN NOT NULL,
    modos_identificados TEXT NOT NULL,
    cantidad_modos_identificados BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS gold.dim_zona (
    zona_sk VARCHAR(32) PRIMARY KEY,
    zona_nombre TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS gold.fct_abordajes (
    abordaje_sk VARCHAR(32) PRIMARY KEY,
    evento_origen_id TEXT NOT NULL,

    modo_sk INTEGER NOT NULL,
    usuario_sk VARCHAR(32) NOT NULL,
    zona_sk VARCHAR(32),
    fecha_sk INTEGER NOT NULL,
    hora_sk INTEGER NOT NULL,

    modo_nombre TEXT NOT NULL,
    zona_nombre TEXT,
    ubicacion_codigo TEXT,
    servicio TEXT,
    fecha_hora_local TIMESTAMP NOT NULL,
    monto_gtq NUMERIC(10, 2) NOT NULL,
    operacion_exitosa BOOLEAN NOT NULL,
    cantidad_abordajes INTEGER NOT NULL,

    CONSTRAINT fk_abordajes_modo
        FOREIGN KEY (modo_sk)
        REFERENCES gold.dim_modo(modo_sk),

    CONSTRAINT fk_abordajes_usuario
        FOREIGN KEY (usuario_sk)
        REFERENCES gold.dim_usuario(usuario_sk),

    CONSTRAINT fk_abordajes_zona
        FOREIGN KEY (zona_sk)
        REFERENCES gold.dim_zona(zona_sk),

    CONSTRAINT fk_abordajes_fecha
        FOREIGN KEY (fecha_sk)
        REFERENCES gold.dim_fecha(fecha_sk),

    CONSTRAINT fk_abordajes_hora
        FOREIGN KEY (hora_sk)
        REFERENCES gold.dim_hora(hora_sk)
);

CREATE TABLE IF NOT EXISTS gold.fct_viajes_metroriel (
    viaje_sk VARCHAR(32) PRIMARY KEY,
    viaje_id BIGINT NOT NULL UNIQUE,

    modo_sk INTEGER NOT NULL,
    usuario_sk VARCHAR(32) NOT NULL,
    zona_entrada_sk VARCHAR(32),
    zona_salida_sk VARCHAR(32),
    fecha_sk INTEGER NOT NULL,
    hora_entrada_sk INTEGER NOT NULL,
    hora_salida_sk INTEGER NOT NULL,

    modo_nombre TEXT NOT NULL,
    zona_entrada TEXT,
    zona_salida TEXT,
    estacion_entrada_id INTEGER NOT NULL,
    estacion_entrada TEXT,
    estacion_salida_id INTEGER NOT NULL,
    estacion_salida TEXT,
    fecha_hora_entrada TIMESTAMP NOT NULL,
    fecha_hora_salida TIMESTAMP NOT NULL,
    duracion_segundos INTEGER NOT NULL,
    monto_gtq NUMERIC(10, 2) NOT NULL,
    cantidad_viajes INTEGER NOT NULL,

    CONSTRAINT fk_viajes_modo
        FOREIGN KEY (modo_sk)
        REFERENCES gold.dim_modo(modo_sk),

    CONSTRAINT fk_viajes_usuario
        FOREIGN KEY (usuario_sk)
        REFERENCES gold.dim_usuario(usuario_sk),

    CONSTRAINT fk_viajes_zona_entrada
        FOREIGN KEY (zona_entrada_sk)
        REFERENCES gold.dim_zona(zona_sk),

    CONSTRAINT fk_viajes_zona_salida
        FOREIGN KEY (zona_salida_sk)
        REFERENCES gold.dim_zona(zona_sk),

    CONSTRAINT fk_viajes_fecha
        FOREIGN KEY (fecha_sk)
        REFERENCES gold.dim_fecha(fecha_sk),

    CONSTRAINT fk_viajes_hora_entrada
        FOREIGN KEY (hora_entrada_sk)
        REFERENCES gold.dim_hora(hora_sk),

    CONSTRAINT fk_viajes_hora_salida
        FOREIGN KEY (hora_salida_sk)
        REFERENCES gold.dim_hora(hora_sk)
);