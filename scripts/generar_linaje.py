"""Genera el grafo de linaje del proyecto (sección 3.1).

Lee el manifest de dbt (dbt_red_metropolitana/target/manifest.json) y dibuja
la cadena completa:

    archivo crudo -> Bronze -> staging -> Silver / Cuarentena -> Gold -> tablero

Salidas:
    docs/linaje/linaje_dbt.dot
    docs/linaje/linaje_dbt.svg   (y .png si Graphviz está instalado)

Uso:
    cd dbt_red_metropolitana && dbt docs generate --profiles-dir . && cd ..
    python scripts/generar_linaje.py

El linaje interactivo completo también se ve con:
    dbt docs serve --profiles-dir dbt_red_metropolitana --project-dir dbt_red_metropolitana
"""
from pathlib import Path
import json
import shutil
import subprocess

BASE_DIR = Path(__file__).resolve().parent.parent
MANIFEST = BASE_DIR / "dbt_red_metropolitana" / "target" / "manifest.json"
SALIDA = BASE_DIR / "docs" / "linaje"

COLORES = {
    "crudo": "#F2F2F2",
    "bronze": "#E3C9A8",
    "staging": "#D9D9D9",
    "silver": "#C9D7E8",
    "quarantine": "#F4C7C3",
    "gold": "#F7E3A1",
    "features": "#CDE8C9",
    "exposure": "#E2D4F0",
}


def nodo(dot, nombre, etiqueta, capa, forma="box"):
    dot.append(
        f'  "{nombre}" [label="{etiqueta}", shape={forma}, '
        f'style="filled,rounded", fillcolor="{COLORES[capa]}"];'
    )


def capa_modelo(nodo_dbt):
    ruta = nodo_dbt["fqn"]
    if "features" in ruta:
        return "features"
    if "quarantine" in ruta:
        return "quarantine"
    if "staging" in ruta:
        return "staging"
    if "gold" in ruta:
        return "gold"
    return "silver"


def main():
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    dot = [
        "digraph linaje {",
        "  rankdir=LR; splines=true; nodesep=0.15; ranksep=1.1;",
        '  node [fontname="Helvetica", fontsize=10];',
        '  edge [color="#7F7F7F", arrowsize=0.6];',
    ]

    # Archivo crudo -> Bronze -> source de staging
    for id_fuente, fuente in manifest["sources"].items():
        meta = fuente.get("meta", {})
        tabla = f"staging.{fuente['name']}"
        nodo(dot, id_fuente, tabla, "staging", "cylinder")
        if meta.get("archivo_crudo"):
            crudo = meta["archivo_crudo"]
            bronze = meta.get("ruta_bronze", "lake/bronze")
            via = meta.get("via_ingesta", "").split(" ")[0]
            nodo(dot, crudo, crudo, "crudo", "note")
            nodo(dot, bronze, f"{bronze}\\n(Parquet, {via})", "bronze", "folder")
            dot.append(f'  "{crudo}" -> "{bronze}";')
            dot.append(f'  "{bronze}" -> "{id_fuente}";')

    # Modelos dbt
    for id_nodo, n in manifest["nodes"].items():
        if n["resource_type"] != "model":
            continue
        capa = capa_modelo(n)
        nodo(dot, id_nodo, f"{n['schema']}.{n['name']}", capa)
        for dep in n["depends_on"]["nodes"]:
            dot.append(f'  "{dep}" -> "{id_nodo}";')

    # Consumidores (tablero y ciencia de datos)
    for id_exp, e in manifest.get("exposures", {}).items():
        nodo(dot, id_exp, e.get("label") or e["name"], "exposure", "doubleoctagon")
        for dep in e["depends_on"]["nodes"]:
            dot.append(f'  "{dep}" -> "{id_exp}";')

    # Leyenda
    dot.append('  subgraph cluster_leyenda { label="Capas"; fontsize=10;')
    for capa in COLORES:
        dot.append(
            f'    "ley_{capa}" [label="{capa}", shape=box, style=filled, '
            f'fillcolor="{COLORES[capa]}", fontsize=9];'
        )
    dot.append("  }")
    dot.append("}")

    SALIDA.mkdir(parents=True, exist_ok=True)
    archivo_dot = SALIDA / "linaje_dbt.dot"
    archivo_dot.write_text("\n".join(dot), encoding="utf-8")
    print(f"Grafo escrito en {archivo_dot}")

    if shutil.which("dot"):
        for formato in ("svg", "png"):
            destino = SALIDA / f"linaje_dbt.{formato}"
            subprocess.run(
                ["dot", f"-T{formato}", "-Gdpi=110", str(archivo_dot), "-o", str(destino)],
                check=True,
            )
            print(f"Imagen generada: {destino}")
    else:
        print("Graphviz no está instalado: abra el .dot en https://dreampuf.github.io/GraphvizOnline")


if __name__ == "__main__":
    main()
