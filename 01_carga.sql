-- =====================================================================
-- Caso de estudio Cyclistic (Google Data Analytics)
-- 01 - Carga de los datos en bruto
-- Motor: DuckDB
-- Entrada: los 12 CSV mensuales de Divvy en la carpeta datos_originales/
-- Salida:  tabla viajes_raw (una fila por viaje, sin modificar)
-- =====================================================================

-- union_by_name alinea las columnas por nombre aunque cambie su orden
-- entre archivos. La columna `archivo` guarda el mes de origen (AAAAMM)
-- para poder revisar cada archivo por separado.
CREATE OR REPLACE TABLE viajes_raw AS
SELECT
    * EXCLUDE (filename),
    REGEXP_EXTRACT(filename, '(\d{6})-divvy-tripdata', 1) AS archivo
FROM READ_CSV('datos_originales/*-divvy-tripdata.csv',
              union_by_name = TRUE,
              filename = TRUE);
