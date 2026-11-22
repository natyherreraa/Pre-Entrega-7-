from pathlib import Path

import duckdb


archivo_sql = Path(__file__).with_name("feature_engineering_churn.sql")
consulta = archivo_sql.read_text(encoding="utf-8")

with duckdb.connect() as conexion:
    conexion.execute("CREATE TEMP TABLE features AS " + consulta)

    cantidad_polizas, sin_tendencia = conexion.execute("""
        SELECT
            COUNT(*) AS cantidad_polizas,
            COUNT(*) - COUNT(trend_premio) AS sin_tendencia
        FROM features
    """).fetchone()

    print(f"Cantidad de pólizas: {cantidad_polizas}")
    print(f"Pólizas sin historial previo: {sin_tendencia}")

    conexion.sql("""
        SELECT *
        FROM features
        ORDER BY insured_id
        LIMIT 5
    """).show()