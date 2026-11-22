-- =====================================================
-- Granda Panda - Data Warehouse (MySQL 8.0+)
-- Esquema estrella: 1 tabla de hechos + 6 dimensiones
-- Granularidad: una fila por transacción de venta
-- =====================================================
CREATE DATABASE IF NOT EXISTS dw
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE dw;

-- =====================================================
-- DIM_TIEMPO
-- =====================================================
CREATE TABLE dim_tiempo (
    sk_tiempo         INT PRIMARY KEY,              -- formato AAAAMMDD
    fecha             DATE NOT NULL UNIQUE,
    anio              SMALLINT NOT NULL,
    trimestre         TINYINT NOT NULL,
    nombre_trimestre  VARCHAR(10) NOT NULL,
    mes               TINYINT NOT NULL,
    nombre_mes        VARCHAR(15) NOT NULL,
    anio_mes          CHAR(7) NOT NULL,             -- AAAA-MM
    semana_anio       TINYINT NOT NULL,
    dia_mes           TINYINT NOT NULL,
    dia_semana        TINYINT NOT NULL,             -- 1=Lunes ... 7=Domingo
    nombre_dia        VARCHAR(12) NOT NULL,
    es_fin_semana     BOOLEAN NOT NULL
) ENGINE=InnoDB;

-- =====================================================
-- DIM_PRODUCTO (SCD Tipo 2: precio y costo)
-- =====================================================
CREATE TABLE dim_producto (
    sk_producto            INT AUTO_INCREMENT PRIMARY KEY,
    codigo_producto        INT NOT NULL,
    nombre_producto        VARCHAR(100) NOT NULL,
    categoria              VARCHAR(30) NOT NULL,
    precio_unitario        DECIMAL(12,2) NOT NULL,
    costo_unitario         DECIMAL(12,2) NOT NULL,
    codigo_proveedor       INT NOT NULL,
    fecha_inicio_vigencia  DATE NOT NULL,
    fecha_fin_vigencia     DATE NOT NULL,
    es_actual              BOOLEAN NOT NULL,
    UNIQUE KEY uq_producto_version (codigo_producto, fecha_inicio_vigencia),
    CONSTRAINT ck_producto_precio CHECK (precio_unitario >= 0),
    CONSTRAINT ck_producto_costo  CHECK (costo_unitario >= 0)
) ENGINE=InnoDB;

-- =====================================================
-- DIM_TIENDA (SCD Tipo 1)
-- =====================================================
CREATE TABLE dim_tienda (
    sk_tienda      INT AUTO_INCREMENT PRIMARY KEY,
    id_tienda      VARCHAR(10) NOT NULL UNIQUE,
    nombre_tienda  VARCHAR(100) NOT NULL,
    cadena         VARCHAR(40) NOT NULL
) ENGINE=InnoDB;

-- =====================================================
-- DIM_UBICACION (SCD Tipo 1)
-- =====================================================
CREATE TABLE dim_ubicacion (
    sk_ubicacion  INT AUTO_INCREMENT PRIMARY KEY,
    pais          CHAR(2) NOT NULL,
    provincia     VARCHAR(30) NOT NULL,
    canton        VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_ubicacion (provincia, canton)
) ENGINE=InnoDB;

-- =====================================================
-- DIM_CANAL (SCD Tipo 1)
-- =====================================================
CREATE TABLE dim_canal (
    sk_canal  INT AUTO_INCREMENT PRIMARY KEY,
    canal     VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- =====================================================
-- DIM_PUBLICO_META (SCD Tipo 1)
-- =====================================================
CREATE TABLE dim_publico_meta (
    sk_publico_meta           INT AUTO_INCREMENT PRIMARY KEY,
    id_publico_meta           VARCHAR(10) NOT NULL UNIQUE,
    rango_edad                VARCHAR(20) NOT NULL,
    genero                    VARCHAR(20) NOT NULL,
    frecuencia_compra         VARCHAR(20) NOT NULL,
    preferencia_presentacion  VARCHAR(30) NOT NULL
) ENGINE=InnoDB;

-- =====================================================
-- FACT_VENTAS
-- =====================================================
CREATE TABLE fact_ventas (
    sk_venta            BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_transaccion      VARCHAR(20) NOT NULL UNIQUE,   -- dimensión degenerada
    sk_tiempo           INT NOT NULL,
    sk_producto         INT NOT NULL,
    sk_tienda           INT NOT NULL,
    sk_ubicacion        INT NOT NULL,
    sk_canal            INT NOT NULL,
    sk_publico_meta     INT NOT NULL,
    cantidad_unidades   INT NOT NULL,                  -- aditiva
    precio_unitario     DECIMAL(12,2) NOT NULL,        -- no aditiva
    monto_bruto         DECIMAL(14,2) NOT NULL,        -- aditiva
    descuento           DECIMAL(14,2) NOT NULL,        -- aditiva
    monto_neto          DECIMAL(14,2) NOT NULL,        -- aditiva
    costo_total         DECIMAL(14,2) NOT NULL,        -- aditiva
    margen_bruto        DECIMAL(14,2) NOT NULL,        -- aditiva
    fecha_carga         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ventas_tiempo       FOREIGN KEY (sk_tiempo)       REFERENCES dim_tiempo(sk_tiempo),
    CONSTRAINT fk_ventas_producto     FOREIGN KEY (sk_producto)     REFERENCES dim_producto(sk_producto),
    CONSTRAINT fk_ventas_tienda       FOREIGN KEY (sk_tienda)       REFERENCES dim_tienda(sk_tienda),
    CONSTRAINT fk_ventas_ubicacion    FOREIGN KEY (sk_ubicacion)    REFERENCES dim_ubicacion(sk_ubicacion),
    CONSTRAINT fk_ventas_canal        FOREIGN KEY (sk_canal)        REFERENCES dim_canal(sk_canal),
    CONSTRAINT fk_ventas_publico_meta FOREIGN KEY (sk_publico_meta) REFERENCES dim_publico_meta(sk_publico_meta),
    CONSTRAINT ck_ventas_cantidad CHECK (cantidad_unidades >= 0),
    CONSTRAINT ck_ventas_precio   CHECK (precio_unitario >= 0),
    CONSTRAINT ck_ventas_bruto    CHECK (monto_bruto >= 0),
    CONSTRAINT ck_ventas_descuento CHECK (descuento >= 0),
    CONSTRAINT ck_ventas_neto     CHECK (monto_neto >= 0),
    CONSTRAINT ck_ventas_costo    CHECK (costo_total >= 0)
) ENGINE=InnoDB;
-- MySQL crea automáticamente un índice por cada llave foránea.