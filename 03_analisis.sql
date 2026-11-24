-- =====================================================================
-- Caso de estudio Cyclistic (Google Data Analytics)
-- 03 - Análisis descriptivo: miembros vs. casuales
-- Entrada: tabla viajes (creada por 02_limpieza.sql)
-- Cada consulta es independiente y se puede ejecutar por separado.
-- =====================================================================

-- 1) Resumen general por tipo de usuario
SELECT
    member_casual,
    COUNT(*)                                                  AS viajes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)        AS pct_viajes,
    ROUND(AVG(ride_length_min), 1)                            AS duracion_promedio_min,
    ROUND(MEDIAN(ride_length_min), 1)                         AS duracion_mediana_min,
    ROUND(MAX(ride_length_min), 1)                            AS duracion_max_min,
    ROUND(100.0 * AVG((ride_length_min > 30)::INT), 1)        AS pct_mas_30_min,
    ROUND(MEDIAN(distancia_km), 2)                            AS distancia_mediana_km,
    -- Sobre viajes con ambas estaciones registradas (ida_y_vuelta es NULL si falta una)
    ROUND(100.0 * AVG(ida_y_vuelta::INT), 1)                  AS pct_ida_y_vuelta,
    ROUND(SUM(ride_length_min) / 60)                          AS horas_totales
FROM viajes
GROUP BY member_casual
ORDER BY member_casual;

-- 2) Moda de day_of_week: el día con más viajes (1 = domingo ... 7 = sábado)
SELECT member_casual, MODE(day_of_week) AS dia_moda
FROM viajes
GROUP BY member_casual
ORDER BY member_casual;

-- 3) Equivalente a la tabla dinámica del curso:
--    filas = member_casual, columnas = day_of_week,
--    valores = cantidad de viajes y promedio de ride_length
SELECT
    member_casual,
    day_of_week,
    COUNT(*)                       AS viajes,
    ROUND(AVG(ride_length_min), 1) AS duracion_promedio_min
FROM viajes
GROUP BY member_casual, day_of_week
ORDER BY member_casual, day_of_week;

-- 4) Días laborales vs. fin de semana (% de los viajes de cada grupo)
SELECT
    member_casual,
    tipo_dia,
    COUNT(*) AS viajes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 1) AS pct
FROM viajes
GROUP BY member_casual, tipo_dia
ORDER BY member_casual, tipo_dia;

-- 5) Hora de inicio en días laborales (% de los viajes de cada grupo)
SELECT
    hora,
    member_casual,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) AS pct
FROM viajes
WHERE tipo_dia = 'Día laboral'
GROUP BY hora, member_casual
ORDER BY hora, member_casual;

-- 6) Viajes por mes y participación de casuales
SELECT
    mes,
    COUNT(*) FILTER (WHERE member_casual = 'casual') AS casuales,
    COUNT(*) FILTER (WHERE member_casual = 'member') AS miembros,
    ROUND(100.0 * COUNT(*) FILTER (WHERE member_casual = 'casual') / COUNT(*), 1)
        AS pct_casuales
FROM viajes
GROUP BY mes
ORDER BY mes;

-- 7) Tipo de bicicleta (% de los viajes de cada grupo)
SELECT
    member_casual,
    rideable_type,
    COUNT(*) AS viajes,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 1) AS pct
FROM viajes
GROUP BY member_casual, rideable_type
ORDER BY member_casual, rideable_type;

-- 8) Distribución de la duración por rangos (% de los viajes de cada grupo)
WITH rangos AS (
    SELECT
        member_casual,
        CASE WHEN ride_length_min < 10 THEN 1
             WHEN ride_length_min < 20 THEN 2
             WHEN ride_length_min < 30 THEN 3
             WHEN ride_length_min < 45 THEN 4
             WHEN ride_length_min < 60 THEN 5
             ELSE 6 END AS orden
    FROM viajes
)
SELECT
    member_casual,
    orden,
    ['0-10', '10-20', '20-30', '30-45', '45-60', '60+'][orden] AS rango_min,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 1) AS pct
FROM rangos
GROUP BY member_casual, orden
ORDER BY member_casual, orden;

-- 9) Top 10 estaciones de inicio por tipo de usuario
SELECT member_casual, start_station_name, COUNT(*) AS viajes
FROM viajes
WHERE start_station_name IS NOT NULL
GROUP BY member_casual, start_station_name
QUALIFY ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY COUNT(*) DESC) <= 10
ORDER BY member_casual ASC, viajes DESC;

-- 10) Segmento "casual que se traslada": horario punta de días laborales
SELECT
    franja_horaria,
    COUNT(*)                          AS viajes_casuales,
    ROUND(MEDIAN(ride_length_min), 1) AS duracion_mediana_min
FROM viajes
WHERE member_casual = 'casual'
  AND franja_horaria <> 'Fuera de punta'
GROUP BY franja_horaria
ORDER BY franja_horaria;
