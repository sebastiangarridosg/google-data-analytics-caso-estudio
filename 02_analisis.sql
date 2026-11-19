-- =====================================================================
-- Caso de estudio Cyclistic (Google Data Analytics)
-- 02 - Análisis descriptivo: miembros vs. casuales
-- Requiere la tabla `viajes` creada por 01_carga_y_limpieza.sql
-- =====================================================================

-- 1) Resumen general por tipo de usuario
SELECT
    member_casual,
    COUNT(*)                                                   AS viajes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)         AS pct_viajes,
    ROUND(AVG(ride_length_min), 1)                             AS duracion_promedio_min,
    ROUND(MEDIAN(ride_length_min), 1)                          AS duracion_mediana_min,
    ROUND(MAX(ride_length_min), 1)                             AS duracion_max_min,
    ROUND(100.0 * AVG((ride_length_min > 30)::INT), 1)         AS pct_mas_30_min,
    ROUND(MEDIAN(distancia_km), 2)                             AS distancia_mediana_km,
    ROUND(100.0 * AVG(ida_y_vuelta::INT), 1)                   AS pct_ida_y_vuelta,
    ROUND(SUM(ride_length_min) / 60)                           AS horas_totales
FROM viajes
GROUP BY member_casual
ORDER BY member_casual;

-- 2) Moda de day_of_week (día con más viajes) por tipo de usuario
SELECT member_casual, MODE(day_of_week) AS dia_moda  -- 1 = domingo ... 7 = sábado
FROM viajes
GROUP BY member_casual;

-- 3) Equivalente a la tabla dinámica del curso:
--    filas = member_casual, columnas = day_of_week,
--    valores = promedio de ride_length y cantidad de viajes
SELECT member_casual, day_of_week,
       COUNT(*)                       AS viajes,
       ROUND(AVG(ride_length_min), 1) AS duracion_promedio_min
FROM viajes
GROUP BY member_casual, day_of_week
ORDER BY member_casual, day_of_week;

-- 4) Días laborales vs. fin de semana
SELECT member_casual, tipo_dia,
       COUNT(*) AS viajes,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 1) AS pct
FROM viajes
GROUP BY member_casual, tipo_dia
ORDER BY member_casual, tipo_dia;

-- 5) Distribución por hora de inicio (solo días laborales), % de los viajes de cada grupo
SELECT hora, member_casual,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) AS pct
FROM viajes
WHERE tipo_dia = 'Día laboral'
GROUP BY hora, member_casual
ORDER BY hora, member_casual;

-- 6) Viajes por mes y participación de casuales
SELECT mes,
       COUNT(*) FILTER (WHERE member_casual = 'casual') AS casuales,
       COUNT(*) FILTER (WHERE member_casual = 'member') AS miembros,
       ROUND(100.0 * COUNT(*) FILTER (WHERE member_casual = 'casual') / COUNT(*), 1) AS pct_casuales
FROM viajes
GROUP BY mes
ORDER BY mes;

-- 7) Tipo de bicicleta
SELECT member_casual, rideable_type,
       COUNT(*) AS viajes,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 1) AS pct
FROM viajes
GROUP BY member_casual, rideable_type
ORDER BY member_casual, rideable_type;

-- 8) Distribución de la duración por rangos
SELECT member_casual,
       CASE WHEN ride_length_min < 10 THEN '1) 0-10'
            WHEN ride_length_min < 20 THEN '2) 10-20'
            WHEN ride_length_min < 30 THEN '3) 20-30'
            WHEN ride_length_min < 45 THEN '4) 30-45'
            WHEN ride_length_min < 60 THEN '5) 45-60'
            ELSE '6) 60+' END AS rango_min,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 1) AS pct
FROM viajes
GROUP BY member_casual, rango_min
ORDER BY member_casual, rango_min;

-- 9) Top 10 estaciones de inicio por tipo de usuario
SELECT member_casual, start_station_name, COUNT(*) AS viajes
FROM viajes
WHERE start_station_name IS NOT NULL
GROUP BY member_casual, start_station_name
QUALIFY ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY COUNT(*) DESC) <= 10
ORDER BY member_casual, viajes DESC;

-- 10) Segmento "casual que se traslada": días laborales, 7-9 h y 16-18 h
SELECT CASE WHEN hora BETWEEN 7 AND 9 THEN 'Mañana (7-9 h)' ELSE 'Tarde (16-18 h)' END AS franja,
       COUNT(*)                          AS viajes,
       ROUND(MEDIAN(ride_length_min), 1) AS duracion_mediana_min
FROM viajes
WHERE member_casual = 'casual'
  AND tipo_dia = 'Día laboral'
  AND (hora BETWEEN 7 AND 9 OR hora BETWEEN 16 AND 18)
GROUP BY franja;
