-- =====================================================================
-- Caso de estudio Cyclistic (Google Data Analytics)
-- 02 - Limpieza y transformación
-- Entrada: tabla viajes_raw (creada por 01_carga.sql)
-- Salida:  vista viajes_clasificados (cada viaje con su motivo de exclusión)
--          tabla viajes (solo los viajes válidos, con columnas nuevas)
-- =====================================================================

-- Distancia en línea recta entre dos coordenadas (fórmula de haversine), en km
CREATE OR REPLACE MACRO haversine_km(lat1, lng1, lat2, lng2) AS
    2 * 6371 * ASIN(SQRT(
        POWER(SIN(RADIANS(lat2 - lat1) / 2), 2)
        + COS(RADIANS(lat1)) * COS(RADIANS(lat2))
        * POWER(SIN(RADIANS(lng2 - lng1) / 2), 2)
    ));

-- 1) CLASIFICACIÓN
--    Cada viaje recibe el PRIMER motivo de exclusión que cumple, en este orden.
--    Los viajes con motivo NULL son válidos. Así las reglas existen en un
--    solo lugar y el conteo de filas eliminadas sale de la misma consulta.
CREATE OR REPLACE VIEW viajes_clasificados AS
WITH estaciones_excluidas (nombre) AS (
    VALUES ('STAFF & VISITORS @ West Chicago Warehouse'),
           ('Hastings Test Station')
),
base AS (
    SELECT
        * EXCLUDE (start_station_name, end_station_name),
        -- Algunos nombres traen espacios al final ("Clark St & Eddy St ")
        NULLIF(TRIM(start_station_name), '') AS start_station_name,
        NULLIF(TRIM(end_station_name), '')   AS end_station_name,
        ended_at - started_at                AS duracion,
        -- Desempate determinista si un ride_id aparece en dos archivos
        ROW_NUMBER() OVER (
            PARTITION BY ride_id
            ORDER BY started_at, ended_at, archivo
        ) AS aparicion
    FROM viajes_raw
)
SELECT
    *,
    CASE
        WHEN ride_id IS NULL OR started_at IS NULL OR ended_at IS NULL
             OR member_casual IS NULL                     THEN '1. Datos incompletos'
        WHEN aparicion > 1                                THEN '2. ride_id duplicado'
        WHEN started_at <  TIMESTAMP '2025-11-01'
          OR started_at >= TIMESTAMP '2026-11-01'         THEN '3. Fuera del periodo'
        WHEN duracion < INTERVAL 60 SECOND                THEN '4. Menos de 60 segundos'
        WHEN duracion > INTERVAL 24 HOUR                  THEN '5. Más de 24 horas'
        WHEN start_station_name IN (SELECT nombre FROM estaciones_excluidas)
          OR end_station_name   IN (SELECT nombre FROM estaciones_excluidas)
                                                          THEN '6. Estación de prueba o bodega'
    END AS motivo_exclusion
FROM base;

-- 2) TABLA LIMPIA con las columnas que usa el análisis
CREATE OR REPLACE TABLE viajes AS
SELECT
    ride_id,
    rideable_type,
    member_casual,
    started_at,
    ended_at,
    start_station_name,
    end_station_name,
    start_lat, start_lng, end_lat, end_lng,
    -- Duración en minutos (equivale a ride_length del enunciado)
    EPOCH(duracion) / 60.0                                  AS ride_length_min,
    -- Convención del curso: 1 = domingo ... 7 = sábado
    DAYOFWEEK(started_at) + 1                               AS day_of_week,
    HOUR(started_at)                                        AS hora,
    DATE_TRUNC('month', started_at)::DATE                   AS mes,
    -- ISODOW: 1 = lunes ... 7 = domingo
    CASE WHEN ISODOW(started_at) >= 6 THEN 'Fin de semana'
         ELSE 'Día laboral' END                             AS tipo_dia,
    -- Estaciones del año del hemisferio norte (Chicago)
    CASE WHEN MONTH(started_at) IN (12, 1, 2) THEN 'Invierno'
         WHEN MONTH(started_at) IN (3, 4, 5)  THEN 'Primavera'
         WHEN MONTH(started_at) IN (6, 7, 8)  THEN 'Verano'
         ELSE 'Otoño' END                                   AS estacion_anio,
    -- Horario punta de días laborales (traslado al trabajo)
    CASE WHEN ISODOW(started_at) <= 5 AND HOUR(started_at) BETWEEN 7 AND 9
              THEN 'Punta mañana'
         WHEN ISODOW(started_at) <= 5 AND HOUR(started_at) BETWEEN 16 AND 18
              THEN 'Punta tarde'
         ELSE 'Fuera de punta' END                          AS franja_horaria,
    CASE WHEN start_lat IS NOT NULL AND end_lat IS NOT NULL
         THEN haversine_km(start_lat, start_lng, end_lat, end_lng)
    END                                                     AS distancia_km,
    -- Termina en la misma estación donde empezó. Queda NULL si falta alguna
    -- de las dos estaciones, para que AVG() lo calcule solo sobre viajes
    -- con ambas estaciones registradas.
    CASE WHEN start_station_name IS NOT NULL AND end_station_name IS NOT NULL
         THEN start_station_name = end_station_name
    END                                                     AS ida_y_vuelta
FROM viajes_clasificados
WHERE motivo_exclusion IS NULL;
