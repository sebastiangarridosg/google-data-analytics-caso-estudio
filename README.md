# Caso de estudio Cyclistic: miembros vs. ciclistas casuales

Proyecto final del **Certificado Profesional de Google Data Analytics** (caso de estudio 1).

**Pregunta:** ¿en qué se diferencia el uso de las bicicletas entre miembros anuales y ciclistas casuales?

**Datos:** 6,1 millones de viajes de Divvy (Chicago), de noviembre de 2025 a octubre de 2026.

**Herramientas:** SQL (DuckDB) y Python (pandas, matplotlib, Jupyter).

## Hallazgos principales

- Los viajes casuales duran en promedio 18,0 minutos, un 49% más que los de miembros (12,1 min), aunque la distancia típica es la misma.
- El 37,6% de los viajes casuales ocurre en fin de semana, frente al 23,7% en miembros. Los miembros tienen un pico a las 8 a. m. que los casuales casi no tienen.
- Entre enero y julio, los viajes casuales se multiplican por 14,5 y los de miembros, por 4,6.
- Las estaciones favoritas de los casuales están en la costa del lago (Navy Pier, Shedd Aquarium, Millennium Park).
- 148.629 viajes casuales salen en la punta de la mañana desde estaciones de oficinas. Es el segmento más fácil de convertir en miembros.

## Gráficos principales

![Viajes por día de la semana](graficos/1_viajes_por_dia.png)

![Viajes por hora en días laborales](graficos/2_viajes_por_hora.png)

![Viajes por mes](graficos/3_viajes_por_mes.png)

![Duración de los viajes](graficos/4_duracion.png)

![Estaciones favoritas de los casuales](graficos/5_estaciones_casuales.png)

## Recomendaciones

1. Convertir primero a los casuales que ya se trasladan al trabajo en horario punta.
2. Lanzar una campaña de primavera y verano en las estaciones de la costa del lago.
3. Mostrar el valor de la membresía en los viajes de más de 30 minutos.

El informe completo está en [informe_cyclistic.pdf](informe_cyclistic.pdf).

## Estructura

```
cyclistic_analisis.ipynb      Notebook completo (Ask → Act), ya ejecutado
sql/01_carga_y_limpieza.sql   Carga de los 12 CSV, limpieza y columnas nuevas
sql/02_analisis.sql           Consultas del análisis descriptivo
graficos/                     Los 5 gráficos en PNG
resumen/                      Tablas resumen exportadas en CSV
```

## Cómo reproducirlo

1. Descarga los archivos `202511-divvy-tripdata.zip` a `202610-divvy-tripdata.zip` desde https://divvy-tripdata.s3.amazonaws.com/index.html.
2. Descomprímelos en una carpeta `datos_originales/`, al lado del notebook. Si el CSV de enero de 2026 viene con el nombre `202501-divvy-tripdata.csv`, renómbralo a `202601-divvy-tripdata.csv`.
3. Instala las librerías: `pip install duckdb pandas matplotlib jupyter`.
4. Abre `cyclistic_analisis.ipynb` y ejecuta todas las celdas.

Datos publicados por Lyft Bikes and Scooters (Divvy) bajo su [licencia de datos](https://www.divvybikes.com/data-license-agreement).
