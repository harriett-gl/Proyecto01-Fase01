from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
from collections import defaultdict
import argparse
import json
import sqlite3
import time

import pandas as pd
from kafka import KafkaConsumer


BASE_DIR = Path(__file__).resolve().parent.parent
BRONZE_DIR = BASE_DIR / "lake" / "bronze"
CONTROL_DIR = BRONZE_DIR / "_control"
STATE_FILE = CONTROL_DIR / "streaming_state.sqlite"

FUENTES = {
    "transmetro": {
        "topico": "transmetro-validaciones"
    },
    "aerometro": {
        "topico": "aerometro-boardings"
    }
}


def crear_base_control():
    CONTROL_DIR.mkdir(parents=True, exist_ok=True)

    conexion = sqlite3.connect(STATE_FILE)

    conexion.execute("""
        CREATE TABLE IF NOT EXISTS processed_occurrences (
            source TEXT NOT NULL,
            event_id TEXT NOT NULL,
            occurrence_number INTEGER NOT NULL,
            PRIMARY KEY (
                source,
                event_id,
                occurrence_number
            )
        )
    """)

    conexion.commit()
    return conexion


def crear_consumidor(nombre_fuente):
    topico = FUENTES[nombre_fuente]["topico"]

    return KafkaConsumer(
        topico,
        bootstrap_servers="localhost:9092",
        group_id=f"bronze-{nombre_fuente}-v1",
        auto_offset_reset="earliest",
        enable_auto_commit=False,
        consumer_timeout_ms=120000,
        value_deserializer=lambda valor: json.loads(
            valor.decode("utf-8")
        )
    )


def consumir_fuente(nombre_fuente):
    inicio = time.perf_counter()
    consumidor = crear_consumidor(nombre_fuente)
    conexion = crear_base_control()
    cursor = conexion.cursor()

    fecha_hora = datetime.now(ZoneInfo("America/Guatemala"))
    ingestion_ts = fecha_hora.isoformat()
    ingestion_date = fecha_hora.date().isoformat()

    ocurrencias = defaultdict(int)
    registros_nuevos = []
    mensajes_leidos = 0
    mensajes_repetidos = 0
    primer_offset = None
    ultimo_offset = None
    encontro_fin = False

    print(f"\nCONSUMIENDO EVENTOS DE {nombre_fuente.upper()}\n")

    try:
        for mensaje in consumidor:
            evento = mensaje.value

            if evento.get("control") == "END":
                encontro_fin = True
                ultimo_offset = mensaje.offset
                print("Se recibió la señal de finalización.")
                break

            mensajes_leidos += 1

            event_id = str(evento["event_id"])
            ocurrencias[event_id] += 1
            numero_ocurrencia = ocurrencias[event_id]

            cursor.execute(
                """
                INSERT OR IGNORE INTO processed_occurrences
                (source, event_id, occurrence_number)
                VALUES (?, ?, ?)
                """,
                (
                    nombre_fuente,
                    event_id,
                    numero_ocurrencia
                )
            )

            if cursor.rowcount == 0:
                mensajes_repetidos += 1
                continue

            payload = dict(evento["payload"])

            payload["_event_id"] = event_id
            payload["_occurrence_number"] = numero_ocurrencia
            payload["_source"] = nombre_fuente
            payload["_source_file"] = evento["source_file"]
            payload["_published_at"] = evento["published_at"]
            payload["_ingestion_ts"] = ingestion_ts
            payload["_ingestion_date"] = ingestion_date
            payload["_kafka_topic"] = mensaje.topic
            payload["_kafka_partition"] = mensaje.partition
            payload["_kafka_offset"] = mensaje.offset

            registros_nuevos.append(payload)

            if primer_offset is None:
                primer_offset = mensaje.offset

            ultimo_offset = mensaje.offset

            if mensajes_leidos % 50000 == 0:
                print(f"Mensajes leídos: {mensajes_leidos:,}")

        if not encontro_fin:
            print("ADVERTENCIA: no se recibió la señal END.")

        if registros_nuevos:
            directorio_salida = (
                BRONZE_DIR
                / "streaming"
                / nombre_fuente
                / f"ingestion_date={ingestion_date}"
            )

            directorio_salida.mkdir(
                parents=True,
                exist_ok=True
            )

            archivo_salida = directorio_salida / (
                f"part-{primer_offset}-{ultimo_offset}.parquet"
            )

            dataframe = pd.DataFrame(registros_nuevos)

            dataframe.to_parquet(
                archivo_salida,
                index=False,
                compression="snappy"
            )

            print(f"Archivo creado: {archivo_salida}")
        else:
            print("No existen eventos nuevos para guardar.")

        conexion.commit()
        consumidor.commit()

    except Exception:
        conexion.rollback()
        raise

    finally:
        consumidor.close()
        conexion.close()

    duracion = round(time.perf_counter() - inicio, 2)

    print("\nCONSUMO FINALIZADO")
    print(f"Fuente: {nombre_fuente}")
    print(f"Mensajes leídos: {mensajes_leidos:,}")
    print(f"Registros nuevos: {len(registros_nuevos):,}")
    print(f"Repeticiones de una carga anterior: {mensajes_repetidos:,}")
    print(f"Duración: {duracion} segundos\n")


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "fuente",
        choices=["transmetro", "aerometro"]
    )

    argumentos = parser.parse_args()
    consumir_fuente(argumentos.fuente)


if __name__ == "__main__":
    main()