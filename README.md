# Pre-Entrega-7- Ingeniería de features con SQL para seguros de automotor


## Objetivo

A partir del historial de la cartera se calculan cuatro variables de comportamiento:
Recency, Frequency, Monetary y Trend. Estas variables permiten estudiar la continuidad
de las pólizas y los cambios en su premio como posibles indicadores de una baja futura. 

## Fuente de datos

Se utiliza el dataset *A detailed dataset of motor insurance policies with
coverage-specific financial information*, de Priscila Espinosa, Josep Lledó y
David Atance. El archivo `data/dataset.csv` contiene 354.140 registros
correspondientes a 2022, 2023 y 2024.

[Dataset y diccionario de variables en Mendeley Data](https://data.mendeley.com/datasets/sw4jmdb2sm/1) · Licencia CC BY 4.0.


La unidad de análisis es la **póliza**, identificada mediante `insured_id`.
El identificador se mantiene cuando la misma póliza aparece en distintos años.
En el CSV hay una fila por combinación de póliza y año.

La actividad observable es la presencia de la póliza en la cartera durante un año.
Por ese motivo, Recency se expresa en años, Frequency cuenta períodos anuales
y Trend compara el premio de 2024 con el historial anterior. Se utilizan los tres
años disponibles para conservar también las pólizas cuyo último registro fue en
2022 o 2023.

## Variables generadas


**Recency** (`recency_anios`) : 2024 menos el último año registrado para la póliza. Indica cuánto tiempo pasó desde su última aparición en la cartera. Un valor de 0 significa que tiene registro en 2024.

**Frequency** (`frequency_anios`) : Cantidad de años  en los que aparece la póliza. | Distingue las pólizas observadas en un único período de aquellas con presencia reiterada. 

**Monetary** (`monetary_premio`) : Suma de `total_premium` durante todos los años observados. Cuantifica el premio acumulado a cada póliza y permite comparar su valor económico dentro de la cartera. 

**Trend** (`trend_premio`) : Premio registrado en 2024 menos el promedio de los premios anuales observados en 2022 y 2023. Muestra cuánto aumentó o disminuyó el premio respecto de su propio historial. Permite estudiar si esa variación se relaciona con bajas posteriores.  


## Consulta SQL

La consulta se organiza en tres expresiones: 

1. `historial` selecciona el identificador de póliza, el año y el premio total para el período 2022–2024.
2. `resumen` agrupa por póliza mediante `GROUP BY`. Utiliza `MAX` para obtener el último año registrado y `COUNT(DISTINCT ...)` para contar los años observados.
3. `premios` utiliza `SUM` y `AVG` con `OVER (PARTITION BY insured_id)` para calcular el premio acumulado y el promedio histórico de cada póliza. El filtro `anio < 2024` evita incluir el año evaluado en su propia referencia.

`ROW_NUMBER()` ordena los registros de cada póliza del más reciente
al más antiguo. La consulta selecciona el primero y devuelve una fila por póliza
con las métricas calculadas sobre todo su historial.

## Tratamiento de períodos sin actividad y valores nulos

- **Póliza con historial previo y sin registro en 2024.** Se conserva en el resultado y se considera cero como premio registrado en 2024 para calcular Trend. La ausencia de un registro anual, por sí sola, no confirma una cancelación.

- **Póliza observada por primera vez en 2024.** Trend queda en `NULL` y el indicador auxiliar `sin_historial_previo` toma el valor `1`. Asignar una tendencia de cero en este caso indicaría que el premio se mantuvo estable, cuando en realidad falta un período de comparación.
- **Promedio histórico.** Se utilizan únicamente los años anteriores con registro. Si una póliza aparece en 2023 y 2024, su referencia histórica es el premio de 2023.

## Cómo ejecutar el proyecto

Desde la carpeta principal del repositorio, con el entorno virtual activo:

```bash
python -m pip install duckdb
python sql/run_query.py
```

La consulta principal está en `sql/feature_engineering_churn.sql` y lee
directamente `data/dataset.csv`. El archivo `sql/run_query.py` ejecuta la
consulta y muestra los totales y las primeras cinco filas del resultado.

## Resultado obtenido

La ejecución sobre los 354.140 registros de origen genera **185.678 pólizas únicas**.
De ellas, **62.778** aparecen por primera vez en 2024 y quedan identificadas
como pólizas sin historial previo para calcular Trend.

El resultado contiene el identificador de póliza, las cuatro features y el indicador
auxiliar `sin_historial_previo`. Para un futuro modelo, estas variables
podrían vincularse con una baja observada después del período utilizado para su cálculo.