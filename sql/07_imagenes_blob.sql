-- ============================================================================
--  Seoul Glow — 07_imagenes_blob.sql
--  Guarda el binario de las imágenes dentro de MariaDB.
--
--  Ejecutar como root (o admin_skincare) DESPUÉS de 03_views.sql:
--    sudo mariadb < sql/07_imagenes_blob.sql
--
--  Es idempotente: se puede volver a ejecutar sin error.
--
--  Por qué BLOB y no solo una ruta:
--    - La app de escritorio (Windows) puede subir la foto por JDBC sin SMB,
--      SFTP ni un servidor HTTP aparte.
--    - La imagen se elimina junto con la fila (ON DELETE CASCADE del producto).
--    - La web la sirve en /api/imagenes/<id_imagen>.
--
--  `url` queda opcional porque una fila puede existir solo como BLOB
--  (url = NULL). Si tiene ambos, la web prefiere el BLOB.
-- ============================================================================

SET NAMES utf8mb4;
USE seoulglow_db;

-- ---------------------------------------------------------------------------
-- 1. Columnas nuevas
-- ---------------------------------------------------------------------------
ALTER TABLE producto_imagenes
  ADD COLUMN IF NOT EXISTS imagen MEDIUMBLOB NULL AFTER url,
  ADD COLUMN IF NOT EXISTS mime_type VARCHAR(80) NULL AFTER imagen,
  ADD COLUMN IF NOT EXISTS actualizado_en DATETIME NOT NULL
    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- Una imagen puede vivir solo en la base: la ruta local deja de ser obligatoria.
ALTER TABLE producto_imagenes
  MODIFY COLUMN url VARCHAR(500) NULL;

-- ---------------------------------------------------------------------------
-- 2. Vista del catálogo: además de la ruta, expone el id y si hay BLOB
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_catalogo_web AS
SELECT
    p.id_producto,
    p.sku,
    p.nombre,
    p.slug,
    p.descripcion_corta,
    p.id_marca,
    m.nombre  AS marca,
    p.id_categoria,
    c.nombre  AS categoria,
    c.slug    AS categoria_slug,
    COALESCE(p.precio_oferta, p.precio) AS precio_efectivo,
    p.precio,
    p.precio_oferta,
    p.moneda,
    p.stock,
    p.volumen_ml,
    p.tipo_piel,
    p.destacado,
    (SELECT i.url
       FROM producto_imagenes i
      WHERE i.id_producto = p.id_producto
      ORDER BY i.es_principal DESC, i.orden ASC
      LIMIT 1) AS imagen_principal,
    (SELECT i.id_imagen
       FROM producto_imagenes i
      WHERE i.id_producto = p.id_producto
      ORDER BY i.es_principal DESC, i.orden ASC
      LIMIT 1) AS id_imagen_principal,
    (SELECT (i.imagen IS NOT NULL AND OCTET_LENGTH(i.imagen) > 0)
       FROM producto_imagenes i
      WHERE i.id_producto = p.id_producto
      ORDER BY i.es_principal DESC, i.orden ASC
      LIMIT 1) AS tiene_imagen,
    (SELECT UNIX_TIMESTAMP(i.actualizado_en)
       FROM producto_imagenes i
      WHERE i.id_producto = p.id_producto
      ORDER BY i.es_principal DESC, i.orden ASC
      LIMIT 1) AS imagen_version
FROM productos p
JOIN marcas m     ON m.id_marca = p.id_marca
JOIN categorias c ON c.id_categoria = p.id_categoria
WHERE p.activo = 1
  AND m.activa = 1
  AND c.activa = 1;

-- ---------------------------------------------------------------------------
-- 3. Verificación rápida
-- ---------------------------------------------------------------------------
SELECT
    COUNT(*)                                AS filas,
    SUM(imagen IS NOT NULL)                 AS con_blob,
    SUM(url IS NOT NULL)                    AS con_ruta,
    SUM(mime_type IS NOT NULL)              AS con_mime
FROM producto_imagenes;
