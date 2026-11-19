-- =====================================================================
-- Caso de estudio Cyclistic (Google Data Analytics)
-- 01 - Carga y limpieza de datos
-- Motor: DuckDB (SQL estándar con algunas funciones propias de DuckDB)
-- Periodo: 12 meses, noviembre 2025 a octubre 2026
-- =====================================================================

-- 1) CARGA: se unen los 12 archivos mensuales en una sola tabla cruda.
--    union_by_name alinea las columnas por nombre aunque cambie el orden.
CREATE OR REPLACE TABLE viajes_raw AS
SELECT *
FROM read_csv('datos_originales/*.csv', union_by_name = true);

-- 2) LIMPIEZA Y TRANSFORMACIÓN
--    Reglas aplicadas (cada una se cuantifica en el notebook):
--    a) Duplicados: se conserva una sola fila por ride_id
--       (35 viajes aparecían en dos archivos mensuales consecutivos).
--    b) Ventana de análisis: solo viajes iniciados entre el
--       2025-11-01 y el 2026-10-31.
--    c) Duración: se descartan viajes de menos de 60 segundos
--       (falsos inicios o re-anclajes) y de más de 24 horas
--       (bicicletas perdidas o no devueltas). Esto incluye las
--       duraciones cero o negativas.
--    d) Estaciones de prueba / bodega: se excluyen.
--    e) Viajes sin nombre de estación: se CONSERVAN (son casi todos
--       bicicletas eléctricas estacionadas fuera de una estación), pero
--       no se usan en el análisis por estación.
CREATE OR REPLACE TABLE viajes AS
WITH sin_duplicados AS (
    SELECT *
    FROM viajes_raw
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY started_at) = 1
)
SELECT
    ride_id,
    rideable_type,
    member_casual,
    started_at,
    ended_at,
    start_station_name,
    end_station_name,
    start_lat, start_lng, end_lat, end_lng,
    -- Duración del viaje en minutos (equivale a ride_length del enunciado)
    EPOCH(ended_at - started_at) / 60.0                         AS ride_length_min,
    -- Día de la semana con la convención del curso: 1 = domingo ... 7 = sábado
    DAYOFWEEK(started_at) + 1                                   AS day_of_week,
    HOUR(started_at)                                            AS hora,
    DATE_TRUNC('month', started_at)::DATE                       AS mes,
    CASE WHEN DAYOFWEEK(started_at) IN (0, 6) THEN 'Fin de semana'
         ELSE 'Día laboral' END                                 AS tipo_dia,
    CASE WHEN MONTH(started_at) IN (12, 1, 2)  THEN 'Invierno'
         WHEN MONTH(started_at) IN (3, 4, 5)   THEN 'Primavera'
         WHEN MONTH(started_at) IN (6, 7, 8)   THEN 'Verano'
         ELSE 'Otoño' END                                       AS estacion_anio,
    -- Distancia en línea recta (fórmula de haversine), en km
    CASE WHEN end_lat IS NOT NULL THEN
        2 * 6371 * ASIN(SQRT(
            POWER(SIN(RADIANS(end_lat - start_lat) / 2), 2) +
            COS(RADIANS(start_lat)) * COS(RADIANS(end_lat)) *
            POWER(SIN(RADIANS(end_lng - start_lng) / 2), 2)))
    END                                                         AS distancia_km,
    -- Viaje de ida y vuelta: termina en la misma estación donde empezó
    (start_station_name IS NOT NULL
     AND start_station_name = end_station_name)                 AS ida_y_vuelta
FROM sin_duplicados
WHERE started_at >= TIMESTAMP '2025-11-01'
  AND started_at <  TIMESTAMP '2026-11-01'
  AND ended_at - started_at >= INTERVAL 60 SECOND
  AND ended_at - started_at <= INTERVAL 24 HOUR
  AND COALESCE(start_station_name, '') NOT IN
      ('STAFF & VISITORS @ West Chicago Warehouse', 'Hastings Test Station')
  AND COALESCE(end_station_name, '') NOT IN
      ('STAFF & VISITORS @ West Chicago Warehouse', 'Hastings Test Station');

-- 3) VERIFICACIÓN rápida
SELECT COUNT(*) AS viajes_limpios,
       COUNT(DISTINCT ride_id) AS ids_unicos,
       MIN(started_at) AS primer_viaje,
       MAX(started_at) AS ultimo_viaje,
       MIN(ride_length_min) AS dur_min,
       MAX(ride_length_min) AS dur_max
FROM viajes;
