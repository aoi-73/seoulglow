-- ============================================================================
--  Seoul Glow — 01_schema.sql
--  Esquema de la base de datos (MariaDB 10.6+ / 11.x)
--  Ejecutar en DBeaver como usuario administrador (root).
--
--  Este script es IDEMPOTENTE: se puede volver a ejecutar.
--  ⚠ Elimina las tablas y vistas de seoulglow_db si ya existen.
-- ============================================================================

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS seoulglow_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE seoulglow_db;

-- ---------------------------------------------------------------------------
-- Limpieza (orden inverso a las dependencias)
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_catalogo_web;
DROP VIEW IF EXISTS v_stock_bajo;
DROP VIEW IF EXISTS v_ventas_mensuales;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS movimientos_inventario;
DROP TABLE IF EXISTS pedido_detalles;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS producto_ingredientes;
DROP TABLE IF EXISTS ingredientes;
DROP TABLE IF EXISTS producto_imagenes;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS marcas;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS usuarios;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------------
-- 1. usuarios — personal que usa la aplicación de escritorio
-- ---------------------------------------------------------------------------
CREATE TABLE usuarios (
  id_usuario      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre_completo VARCHAR(120) NOT NULL,
  usuario         VARCHAR(50)  NOT NULL,
  email           VARCHAR(150) NOT NULL,
  password_hash   VARCHAR(255) NOT NULL,
  rol             ENUM('admin','gerente','vendedor','soporte') NOT NULL DEFAULT 'vendedor',
  activo          TINYINT(1)   NOT NULL DEFAULT 1,
  ultimo_acceso   DATETIME     NULL,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uq_usuarios_usuario (usuario),
  UNIQUE KEY uq_usuarios_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 2. categorias — con subcategorías (auto-referencia)
-- ---------------------------------------------------------------------------
CREATE TABLE categorias (
  id_categoria INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(80)  NOT NULL,
  slug         VARCHAR(100) NOT NULL,
  descripcion  VARCHAR(255) NULL,
  id_padre     INT UNSIGNED NULL,
  activa       TINYINT(1)   NOT NULL DEFAULT 1,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_categoria),
  UNIQUE KEY uq_categorias_nombre (nombre),
  UNIQUE KEY uq_categorias_slug (slug),
  KEY idx_categorias_padre (id_padre),
  CONSTRAINT fk_categorias_padre
    FOREIGN KEY (id_padre) REFERENCES categorias (id_categoria)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 3. marcas
-- ---------------------------------------------------------------------------
CREATE TABLE marcas (
  id_marca     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(80)  NOT NULL,
  pais_origen  VARCHAR(60)  NOT NULL DEFAULT 'Corea del Sur',
  sitio_web    VARCHAR(200) NULL,
  logo_url     VARCHAR(500) NULL,
  descripcion  TEXT         NULL,
  activa       TINYINT(1)   NOT NULL DEFAULT 1,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_marca),
  UNIQUE KEY uq_marcas_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4. productos — tabla central del catálogo
-- ---------------------------------------------------------------------------
CREATE TABLE productos (
  id_producto      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  sku              VARCHAR(40)  NOT NULL,
  nombre           VARCHAR(150) NOT NULL,
  slug             VARCHAR(180) NOT NULL,
  descripcion_corta VARCHAR(255) NULL,
  descripcion      TEXT         NULL,
  id_marca         INT UNSIGNED NOT NULL,
  id_categoria     INT UNSIGNED NOT NULL,
  precio           DECIMAL(12,2) NOT NULL,
  precio_oferta    DECIMAL(12,2) NULL,
  moneda           CHAR(3)      NOT NULL DEFAULT 'USD',
  stock            INT          NOT NULL DEFAULT 0,
  stock_minimo     INT          NOT NULL DEFAULT 5,
  volumen_ml       SMALLINT UNSIGNED NULL,
  tipo_piel        SET('grasa','seca','mixta','sensible','normal') NULL,
  activo           TINYINT(1)   NOT NULL DEFAULT 1,
  destacado        TINYINT(1)   NOT NULL DEFAULT 0,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_producto),
  UNIQUE KEY uq_productos_sku (sku),
  UNIQUE KEY uq_productos_slug (slug),
  KEY idx_productos_categoria (id_categoria, activo),
  KEY idx_productos_marca (id_marca, activo),
  KEY idx_productos_precio (precio),
  FULLTEXT KEY ft_productos (nombre, descripcion_corta),
  CONSTRAINT chk_productos_precio  CHECK (precio >= 0),
  CONSTRAINT chk_productos_oferta  CHECK (precio_oferta IS NULL OR (precio_oferta > 0 AND precio_oferta < precio)),
  CONSTRAINT chk_productos_stock   CHECK (stock >= 0),
  CONSTRAINT fk_productos_marca
    FOREIGN KEY (id_marca) REFERENCES marcas (id_marca)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_productos_categoria
    FOREIGN KEY (id_categoria) REFERENCES categorias (id_categoria)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 5. producto_imagenes
-- ---------------------------------------------------------------------------
CREATE TABLE producto_imagenes (
  id_imagen   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_producto BIGINT UNSIGNED NOT NULL,
  url         VARCHAR(500) NOT NULL,
  alt_text    VARCHAR(150) NULL,
  orden       TINYINT UNSIGNED NOT NULL DEFAULT 0,
  es_principal TINYINT(1)  NOT NULL DEFAULT 0,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_imagen),
  KEY idx_imagenes_producto (id_producto, es_principal, orden),
  CONSTRAINT fk_imagenes_producto
    FOREIGN KEY (id_producto) REFERENCES productos (id_producto)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 6. ingredientes
-- ---------------------------------------------------------------------------
CREATE TABLE ingredientes (
  id_ingrediente INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(100) NOT NULL,
  beneficio      VARCHAR(150) NULL,
  descripcion    TEXT         NULL,
  es_activo      TINYINT(1)   NOT NULL DEFAULT 1,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_ingrediente),
  UNIQUE KEY uq_ingredientes_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 7. producto_ingredientes — puente N:M
-- ---------------------------------------------------------------------------
CREATE TABLE producto_ingredientes (
  id_producto    BIGINT UNSIGNED NOT NULL,
  id_ingrediente INT UNSIGNED    NOT NULL,
  porcentaje     DECIMAL(5,2)    NULL,
  es_clave       TINYINT(1)      NOT NULL DEFAULT 0,
  PRIMARY KEY (id_producto, id_ingrediente),
  KEY idx_pi_ingrediente (id_ingrediente),
  CONSTRAINT chk_pi_porcentaje CHECK (porcentaje IS NULL OR (porcentaje > 0 AND porcentaje <= 100)),
  CONSTRAINT fk_pi_producto
    FOREIGN KEY (id_producto) REFERENCES productos (id_producto)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pi_ingrediente
    FOREIGN KEY (id_ingrediente) REFERENCES ingredientes (id_ingrediente)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 8. clientes
-- ---------------------------------------------------------------------------
CREATE TABLE clientes (
  id_cliente       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre           VARCHAR(80)  NOT NULL,
  apellido         VARCHAR(80)  NOT NULL,
  email            VARCHAR(150) NOT NULL,
  telefono         VARCHAR(30)  NULL,
  direccion        VARCHAR(200) NULL,
  ciudad           VARCHAR(80)  NULL,
  pais             VARCHAR(60)  NOT NULL DEFAULT 'Ecuador',
  fecha_nacimiento DATE         NULL,
  acepta_marketing TINYINT(1)   NOT NULL DEFAULT 0,
  activo           TINYINT(1)   NOT NULL DEFAULT 1,
  created_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_cliente),
  UNIQUE KEY uq_clientes_email (email),
  KEY idx_clientes_nombre (apellido, nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 9. pedidos
-- ---------------------------------------------------------------------------
CREATE TABLE pedidos (
  id_pedido     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero_pedido VARCHAR(30)  NOT NULL,
  id_cliente    BIGINT UNSIGNED NOT NULL,
  id_usuario    INT UNSIGNED NULL,
  fecha_pedido  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado        ENUM('pendiente','pagado','en_preparacion','enviado','entregado','cancelado')
                NOT NULL DEFAULT 'pendiente',
  metodo_pago   ENUM('tarjeta','transferencia','efectivo','paypal') NULL,
  subtotal      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  descuento     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  impuesto      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total         DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  notas         VARCHAR(255) NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_pedido),
  UNIQUE KEY uq_pedidos_numero (numero_pedido),
  KEY idx_pedidos_cliente (id_cliente, fecha_pedido),
  KEY idx_pedidos_estado (estado, fecha_pedido),
  KEY idx_pedidos_fecha (fecha_pedido),
  CONSTRAINT chk_pedidos_totales CHECK (subtotal >= 0 AND descuento >= 0 AND impuesto >= 0 AND total >= 0),
  CONSTRAINT fk_pedidos_cliente
    FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_pedidos_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 10. pedido_detalles
-- ---------------------------------------------------------------------------
CREATE TABLE pedido_detalles (
  id_detalle      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_pedido       BIGINT UNSIGNED NOT NULL,
  id_producto     BIGINT UNSIGNED NOT NULL,
  cantidad        SMALLINT UNSIGNED NOT NULL,
  precio_unitario DECIMAL(12,2) NOT NULL,
  descuento_linea DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  subtotal_linea  DECIMAL(12,2) AS (cantidad * precio_unitario - descuento_linea) STORED,
  PRIMARY KEY (id_detalle),
  UNIQUE KEY uq_detalle_pedido_producto (id_pedido, id_producto),
  KEY idx_detalle_producto (id_producto),
  CONSTRAINT chk_detalle_cantidad CHECK (cantidad > 0),
  CONSTRAINT chk_detalle_precio   CHECK (precio_unitario >= 0),
  CONSTRAINT fk_detalle_pedido
    FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_detalle_producto
    FOREIGN KEY (id_producto) REFERENCES productos (id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 11. movimientos_inventario — kardex
-- ---------------------------------------------------------------------------
CREATE TABLE movimientos_inventario (
  id_movimiento  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_producto    BIGINT UNSIGNED NOT NULL,
  tipo           ENUM('entrada','salida','ajuste','devolucion') NOT NULL,
  cantidad       INT NOT NULL,
  motivo         VARCHAR(150) NULL,
  id_usuario     INT UNSIGNED NULL,
  stock_resultante INT NOT NULL,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_movimiento),
  KEY idx_mov_producto (id_producto, created_at),
  KEY idx_mov_tipo (tipo, created_at),
  CONSTRAINT chk_mov_cantidad CHECK (cantidad > 0),
  CONSTRAINT fk_mov_producto
    FOREIGN KEY (id_producto) REFERENCES productos (id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_mov_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
--  Fin de 01_schema.sql
--  Siguiente: 02_seed.sql
-- ============================================================================
