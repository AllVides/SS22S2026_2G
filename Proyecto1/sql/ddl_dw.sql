-- ============================================================================
-- SG-Food · DDL del Data Warehouse (base de datos: sgfood)
-- FASE 1: esquemas raw/staging/marts + tablas raw + DDL de REFERENCIA de marts
--
-- Uso:
--   docker compose exec -T postgres psql -U airflow -d sgfood -f /seed-data/sql/ddl_dw.sql
--   (o montando ./sql en el contenedor; ver docs/diseno_dw.md)
--
-- Decisiones (justificación para la documentación):
-- 1. Las tablas `raw` son espejo 1:1 de cada fuente SIN PK/FK/CHECK. raw debe
--    aceptar los datos tal como vienen (incluso sucios); la calidad se valida
--    con tests dbt en staging (Fase 3). Si raw rechazara filas, perderíamos
--    trazabilidad de los errores de origen.
-- 2. Columnas de trazabilidad `_loaded_at` / `_source` en TODA tabla raw
--    (regla del enunciado): permiten saber cuándo y desde dónde se cargó
--    cada lote, base de la comparación source-vs-raw de la Fase 2.
-- 3. La PARTE B (marts) es DDL de REFERENCIA: el dueño real es dbt (Fase 3),
--    que recrea dims/facts con `dbt build`. Se incluye aquí como contrato del
--    modelo estrella y usa IF NOT EXISTS para que este archivo sea
--    re-ejecutable sin errores (idempotencia, regla 4).
-- ============================================================================

-- ============================ PARTE A (real) ================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts;

-- ---- raw desde la BD transaccional (espejo de oltp_sgfood, sin constraints) ----

CREATE TABLE IF NOT EXISTS raw.sucursal (
    id_sucursal  INTEGER,
    nombre       VARCHAR(100),
    ciudad       VARCHAR(100),
    departamento VARCHAR(100),
    _loaded_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source      TEXT        NOT NULL DEFAULT 'oltp_sgfood.sucursal'
);

CREATE TABLE IF NOT EXISTS raw.categoria (
    id_categoria INTEGER,
    nombre       VARCHAR(100),
    _loaded_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source      TEXT        NOT NULL DEFAULT 'oltp_sgfood.categoria'
);

CREATE TABLE IF NOT EXISTS raw.marca (
    id_marca   INTEGER,
    nombre     VARCHAR(100),
    _loaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source    TEXT        NOT NULL DEFAULT 'oltp_sgfood.marca'
);

CREATE TABLE IF NOT EXISTS raw.producto (
    id_producto    INTEGER,
    sku            VARCHAR(20),
    nombre         VARCHAR(150),
    id_categoria   INTEGER,
    id_marca       INTEGER,
    unidad_medida  VARCHAR(30),
    costo_base     NUMERIC(12,2),
    precio_lista   NUMERIC(12,2),
    activo         BOOLEAN,
    _loaded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source        TEXT        NOT NULL DEFAULT 'oltp_sgfood.producto'
);

CREATE TABLE IF NOT EXISTS raw.cliente (
    id_cliente   INTEGER,
    nit          VARCHAR(20),
    nombre       VARCHAR(150),
    tipo_cliente VARCHAR(40),
    municipio    VARCHAR(100),
    departamento VARCHAR(100),
    fecha_alta   DATE,
    _loaded_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source      TEXT        NOT NULL DEFAULT 'oltp_sgfood.cliente'
);

CREATE TABLE IF NOT EXISTS raw.venta (
    id_venta    BIGINT,
    fecha       DATE,
    id_cliente  INTEGER,
    id_sucursal INTEGER,
    canal       VARCHAR(30),
    metodo_pago VARCHAR(30),
    estado      VARCHAR(20),
    _loaded_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source     TEXT        NOT NULL DEFAULT 'oltp_sgfood.venta'
);

CREATE TABLE IF NOT EXISTS raw.venta_detalle (
    id_detalle      BIGINT,
    id_venta        BIGINT,
    id_producto     INTEGER,
    cantidad        INTEGER,
    precio_unitario NUMERIC(12,2),
    descuento       NUMERIC(5,4),
    subtotal        NUMERIC(14,2),
    _loaded_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source         TEXT        NOT NULL DEFAULT 'oltp_sgfood.venta_detalle'
);

-- ---- raw desde CSV (tipos permisivos: la validación va en staging) ----

CREATE TABLE IF NOT EXISTS raw.inventario_bodega (
    fecha_corte       DATE,
    id_sucursal       INTEGER,
    id_producto       INTEGER,
    stock_disponible  INTEGER,
    stock_minimo      INTEGER,
    stock_maximo      INTEGER,
    lote              TEXT,
    fecha_vencimiento DATE,
    _loaded_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source           TEXT        NOT NULL DEFAULT 'inventario_bodega.csv'
);

CREATE TABLE IF NOT EXISTS raw.devoluciones (
    id_devolucion BIGINT,
    fecha         DATE,
    id_venta      BIGINT,
    id_producto   INTEGER,
    cantidad      INTEGER,
    motivo        TEXT,
    _loaded_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source       TEXT        NOT NULL DEFAULT 'devoluciones.csv'
);

CREATE TABLE IF NOT EXISTS raw.metas_ventas (
    periodo       TEXT,          -- formato fuente 'YYYY-MM'; se normaliza en staging
    id_sucursal   INTEGER,
    meta_ventas   NUMERIC(14,2),
    meta_unidades INTEGER,
    _loaded_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source       TEXT        NOT NULL DEFAULT 'metas_ventas.csv'
);

CREATE TABLE IF NOT EXISTS raw.promociones (
    id_promocion         INTEGER,
    nombre               TEXT,
    fecha_inicio         DATE,
    fecha_fin            DATE,
    id_categoria         INTEGER,
    porcentaje_descuento NUMERIC(5,4),
    _loaded_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source              TEXT        NOT NULL DEFAULT 'promociones.csv'
);

CREATE TABLE IF NOT EXISTS raw.proveedores_precios (
    id_proveedor     INTEGER,
    proveedor        TEXT,
    id_producto      INTEGER,
    costo_proveedor  NUMERIC(12,2),
    plazo_dias       INTEGER,
    fecha_vigencia   DATE,
    _loaded_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    _source          TEXT        NOT NULL DEFAULT 'proveedores_precios.csv'
);

-- ====================== PARTE B (REFERENCIA — dueño: dbt) ====================
-- Las crea dbt en Fase 3 (`staging` = views, `marts` = tables).
-- Granos, surrogates y relaciones: ver docs/diseno_dw.md.

-- ---- dimensiones ----
CREATE TABLE IF NOT EXISTS marts.dim_fecha (
    fecha          DATE PRIMARY KEY,  -- PK natural (calendario, 1 fila por día)
    anio           INTEGER NOT NULL,
    mes            INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    nombre_mes     TEXT    NOT NULL,
    trimestre      INTEGER NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    dia_semana     INTEGER NOT NULL CHECK (dia_semana BETWEEN 1 AND 7),
    es_fin_semana  BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS marts.dim_producto (
    producto_sk    SERIAL PRIMARY KEY,          -- surrogate, SCD tipo 1
    id_producto    INTEGER NOT NULL UNIQUE,     -- clave natural del OLTP
    sku            VARCHAR(20) NOT NULL,
    nombre         VARCHAR(150) NOT NULL,
    categoria      VARCHAR(100) NOT NULL,       -- desnormalizada desde categoria
    marca          VARCHAR(100) NOT NULL,       -- desnormalizada desde marca
    unidad_medida  VARCHAR(30) NOT NULL,
    costo_base     NUMERIC(12,2) NOT NULL,
    precio_lista   NUMERIC(12,2) NOT NULL,
    activo         BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS marts.dim_cliente (
    cliente_sk     SERIAL PRIMARY KEY,          -- surrogate, SCD tipo 1
    id_cliente     INTEGER NOT NULL UNIQUE,     -- clave natural del OLTP
    nit            VARCHAR(20) NOT NULL,
    nombre         VARCHAR(150) NOT NULL,
    tipo_cliente   VARCHAR(40) NOT NULL,
    municipio      VARCHAR(100),
    departamento   VARCHAR(100),
    fecha_alta     DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS marts.dim_sucursal (
    sucursal_sk    SERIAL PRIMARY KEY,          -- surrogate, SCD tipo 1
    id_sucursal    INTEGER NOT NULL UNIQUE,     -- clave natural del OLTP
    nombre         VARCHAR(100) NOT NULL,
    ciudad         VARCHAR(100) NOT NULL,
    departamento   VARCHAR(100) NOT NULL
);

-- ---- hechos ----
-- fact_ventas · grano: una fila por línea de venta (venta_detalle).
CREATE TABLE IF NOT EXISTS marts.fact_ventas (
    id_detalle      BIGINT PRIMARY KEY,        -- grano = línea; PK natural
    id_venta        BIGINT NOT NULL,           -- degenerada (agrupa líneas)
    fecha_fk        DATE NOT NULL REFERENCES marts.dim_fecha (fecha),
    producto_sk     INTEGER NOT NULL REFERENCES marts.dim_producto (producto_sk),
    cliente_sk      INTEGER NOT NULL REFERENCES marts.dim_cliente (cliente_sk),
    sucursal_sk     INTEGER NOT NULL REFERENCES marts.dim_sucursal (sucursal_sk),
    canal           VARCHAR(30) NOT NULL,
    metodo_pago     VARCHAR(30) NOT NULL,
    estado          VARCHAR(20) NOT NULL,
    cantidad        INTEGER NOT NULL,
    precio_unitario NUMERIC(12,2) NOT NULL,
    descuento       NUMERIC(5,4) NOT NULL,
    subtotal        NUMERIC(14,2) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_fact_ventas_fecha ON marts.fact_ventas (fecha_fk);
CREATE INDEX IF NOT EXISTS idx_fact_ventas_producto ON marts.fact_ventas (producto_sk);

-- fact_inventario · grano: una fila por corte × sucursal × producto (foto periódica).
CREATE TABLE IF NOT EXISTS marts.fact_inventario (
    fecha_corte       DATE NOT NULL REFERENCES marts.dim_fecha (fecha),
    sucursal_sk       INTEGER NOT NULL REFERENCES marts.dim_sucursal (sucursal_sk),
    producto_sk       INTEGER NOT NULL REFERENCES marts.dim_producto (producto_sk),
    stock_disponible  INTEGER NOT NULL,
    stock_minimo      INTEGER NOT NULL,
    stock_maximo      INTEGER NOT NULL,
    lote              TEXT,
    fecha_vencimiento DATE,
    flag_stock_bajo   BOOLEAN NOT NULL,        -- stock_disponible < stock_minimo
    flag_vencido      BOOLEAN NOT NULL,        -- fecha_vencimiento < fecha_corte
    PRIMARY KEY (fecha_corte, sucursal_sk, producto_sk)
);

-- fact_devoluciones · grano: una fila por devolución (sucursal vía venta).
CREATE TABLE IF NOT EXISTS marts.fact_devoluciones (
    id_devolucion BIGINT PRIMARY KEY,
    fecha_fk      DATE NOT NULL REFERENCES marts.dim_fecha (fecha),
    id_venta      BIGINT NOT NULL,             -- une a fact_ventas.id_venta
    producto_sk   INTEGER NOT NULL REFERENCES marts.dim_producto (producto_sk),
    cantidad      INTEGER NOT NULL,
    motivo        TEXT NOT NULL
);

-- fact_metas · grano: una fila por mes × sucursal (periodo = día 1 del mes).
CREATE TABLE IF NOT EXISTS marts.fact_metas (
    periodo       DATE NOT NULL REFERENCES marts.dim_fecha (fecha),
    sucursal_sk   INTEGER NOT NULL REFERENCES marts.dim_sucursal (sucursal_sk),
    meta_ventas   NUMERIC(14,2) NOT NULL,
    meta_unidades INTEGER NOT NULL,
    PRIMARY KEY (periodo, sucursal_sk)
);
