-- =====================================================================
-- Grandapanda - ETL (Pentaho Data Integration 9.4) - MySQL 8.0+
-- Consulta de la dimensión de tiempo
--
-- Esta es la consulta que ejecuta el paso "TI calendario" (Table input)
-- de la transformación tr_dim_tiempo.ktr. Genera una fila por cada día
-- del calendario 2026 (365 filas) con los atributos de dim_tiempo. Se
-- conserva aquí como documentación y para poder ejecutarla de forma
-- independiente: solo hace SELECT, no modifica ninguna tabla.
--
-- Resultado esperado: 365 filas, del 2026-01-01 al 2026-12-31.
-- =====================================================================
WITH RECURSIVE d AS (
  SELECT DATE('2026-01-01') AS fecha
  UNION ALL
  SELECT DATE_ADD(fecha, INTERVAL 1 DAY) FROM d WHERE fecha < DATE('2026-12-31')
)
SELECT
  CAST(DATE_FORMAT(fecha,'%Y%m%d') AS SIGNED)        AS sk_tiempo,
  fecha                                               AS fecha,
  YEAR(fecha)                                         AS anio,
  QUARTER(fecha)                                      AS trimestre,
  CONCAT('T', QUARTER(fecha))                         AS nombre_trimestre,
  MONTH(fecha)                                        AS mes,
  ELT(MONTH(fecha),'Enero','Febrero','Marzo','Abril','Mayo','Junio',
      'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre') AS nombre_mes,
  DATE_FORMAT(fecha,'%Y-%m')                          AS anio_mes,
  WEEK(fecha,3)                                       AS semana_anio,
  DAYOFMONTH(fecha)                                   AS dia_mes,
  WEEKDAY(fecha)+1                                    AS dia_semana,
  ELT(WEEKDAY(fecha)+1,'Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo') AS nombre_dia,
  CASE WHEN WEEKDAY(fecha) >= 5 THEN 1 ELSE 0 END     AS es_fin_semana
FROM d;
