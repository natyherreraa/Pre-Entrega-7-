-- Preentrega 7: ingeniería de features para pólizas de automotor.


WITH historial AS (
    SELECT
        insured_id,
        year AS anio,
        total_premium AS premio
    FROM read_csv_auto('data/dataset.csv')
    WHERE year BETWEEN 2022 AND 2024
),

-- Una fila por póliza con los años transcurridos desde su
-- último registro y la cantidad de años en que fue observada.
resumen AS (
    SELECT
        insured_id,
        2024 - MAX(anio) AS recency_anios,
        COUNT(DISTINCT anio) AS frequency_anios
    FROM historial
    GROUP BY insured_id
),

-- Cada póliza tiene un registro por año en el archivo de origen.
-- El promedio histórico solo considera años anteriores a 2024.
premios AS (
    SELECT
        insured_id,
        SUM(premio) OVER (
            PARTITION BY insured_id
        ) AS premio_acumulado,

        AVG(premio) FILTER (WHERE anio < 2024) OVER (
            PARTITION BY insured_id
        ) AS promedio_previo,

        CASE
            WHEN anio = 2024 THEN premio
            ELSE 0
        END AS premio_2024,

        ROW_NUMBER() OVER (
            PARTITION BY insured_id
            ORDER BY anio DESC
        ) AS orden
    FROM historial
)

SELECT
    r.insured_id,
    r.recency_anios,
    r.frequency_anios,
    ROUND(p.premio_acumulado, 2) AS monetary_premio,
    ROUND(p.premio_2024 - p.promedio_previo, 2) AS trend_premio,
    CASE
        WHEN p.promedio_previo IS NULL THEN 1
        ELSE 0
    END AS sin_historial_previo
FROM resumen AS r
JOIN premios AS p
    ON r.insured_id = p.insured_id
WHERE p.orden = 1
ORDER BY r.insured_id;