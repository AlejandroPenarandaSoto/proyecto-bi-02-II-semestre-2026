-- =====================================================================
-- Grandapanda - ETL (Pentaho Data Integration 9.4) - MySQL 8.0+
-- Validaciones posteriores a la carga del data warehouse (base dw)
--
-- Se ejecuta después de job_carga_dw.kjb. Solo hace SELECT: no modifica
-- datos. Cada consulta indica el resultado esperado con los datos de
-- grandapanda_fuente_operacional_limpia_v4.xlsx. Las capturas de estos
-- resultados forman parte de la evidencia de ejecución del ETL.
-- =====================================================================
USE dw;

-- V1. Conteo de filas por tabla
-- Esperado: 365, 3, 8, 10, 150, 8 y 180
SELECT 'dim_tiempo' AS tabla, COUNT(*) AS filas FROM dim_tiempo
UNION ALL SELECT 'dim_canal',        COUNT(*) FROM dim_canal
UNION ALL SELECT 'dim_ubicacion',    COUNT(*) FROM dim_ubicacion
UNION ALL SELECT 'dim_tienda',       COUNT(*) FROM dim_tienda
UNION ALL SELECT 'dim_publico_meta', COUNT(*) FROM dim_publico_meta
UNION ALL SELECT 'dim_producto',     COUNT(*) FROM dim_producto
UNION ALL SELECT 'fact_ventas',      COUNT(*) FROM fact_ventas;

-- V2. Totales de la tabla de hechos
-- Esperado: 180 | 7504 | 23490530.00 | 1041860.69 | 22448669.31 | 14044900.00 | 8403769.31
-- (el descuento y el neto del Excel suman 1041860.675 y 22448669.325; la
--  diferencia de 0.015 se debe al redondeo a 2 decimales del ETL)
SELECT COUNT(*)                AS filas,
       SUM(cantidad_unidades)  AS cantidad,
       SUM(monto_bruto)        AS bruto,
       SUM(descuento)          AS descuento,
       SUM(monto_neto)         AS neto,
       SUM(costo_total)        AS costo,
       SUM(margen_bruto)       AS margen
FROM fact_ventas;

-- V3. Integridad referencial: hechos sin dimensión correspondiente
-- Esperado: 0 en las seis columnas
SELECT
  SUM(t.sk_tiempo        IS NULL) AS sin_tiempo,
  SUM(p.sk_producto      IS NULL) AS sin_producto,
  SUM(ti.sk_tienda       IS NULL) AS sin_tienda,
  SUM(u.sk_ubicacion     IS NULL) AS sin_ubicacion,
  SUM(c.sk_canal         IS NULL) AS sin_canal,
  SUM(m.sk_publico_meta  IS NULL) AS sin_publico_meta
FROM fact_ventas f
LEFT JOIN dim_tiempo        t  ON t.sk_tiempo        = f.sk_tiempo
LEFT JOIN dim_producto      p  ON p.sk_producto      = f.sk_producto
LEFT JOIN dim_tienda        ti ON ti.sk_tienda       = f.sk_tienda
LEFT JOIN dim_ubicacion     u  ON u.sk_ubicacion     = f.sk_ubicacion
LEFT JOIN dim_canal         c  ON c.sk_canal         = f.sk_canal
LEFT JOIN dim_publico_meta  m  ON m.sk_publico_meta  = f.sk_publico_meta;

-- V4. Transacciones duplicadas en la tabla de hechos
-- Esperado: 0 filas
SELECT id_transaccion, COUNT(*) AS veces
FROM fact_ventas
GROUP BY id_transaccion
HAVING COUNT(*) > 1;

-- V5. Consistencia de las medidas calculadas
-- Esperado: 0 filas en cada columna
SELECT
  SUM(monto_neto   <> monto_bruto - descuento)  AS neto_incorrecto,
  SUM(margen_bruto <> monto_neto - costo_total) AS margen_incorrecto,
  SUM(cantidad_unidades < 0 OR precio_unitario < 0 OR monto_bruto < 0
      OR descuento < 0 OR monto_neto < 0)       AS con_valores_negativos
FROM fact_ventas;

-- V6. Dimensión de producto con variación lenta tipo 2
-- Esperado: cada producto con una sola versión vigente (es_actual = 1)
-- y sin versiones solapadas: ambas consultas deben devolver 0 filas.
SELECT codigo_producto, SUM(es_actual) AS versiones_vigentes
FROM dim_producto
GROUP BY codigo_producto
HAVING SUM(es_actual) <> 1;

SELECT a.codigo_producto, a.fecha_inicio_vigencia, b.fecha_inicio_vigencia AS inicio_otra_version
FROM dim_producto a
JOIN dim_producto b
  ON a.codigo_producto = b.codigo_producto
 AND a.sk_producto < b.sk_producto
 AND a.fecha_inicio_vigencia <= b.fecha_fin_vigencia
 AND b.fecha_inicio_vigencia <= a.fecha_fin_vigencia;

-- V7. Cobertura temporal de las ventas
-- Esperado: 2026-01-02 | 2026-11-15 | 180 fechas distintas
SELECT MIN(t.fecha) AS primera_venta, MAX(t.fecha) AS ultima_venta, COUNT(DISTINCT t.fecha) AS fechas_distintas
FROM fact_ventas f JOIN dim_tiempo t ON t.sk_tiempo = f.sk_tiempo;

-- V8. Inspección de las dimensiones derivadas
-- Tiendas con su cadena (derivada del nombre) y su ubicación (provincia y cantón)
SELECT ti.id_tienda, ti.nombre_tienda, ti.cadena
FROM dim_tienda ti ORDER BY ti.id_tienda;

SELECT sk_ubicacion, pais, provincia, canton
FROM dim_ubicacion ORDER BY sk_ubicacion;
