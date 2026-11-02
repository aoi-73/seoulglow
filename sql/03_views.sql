-- ============================================================================
--  Seoul Glow — 03_views.sql
--  Vistas de lectura. Ejecutar DESPUÉS de 02_seed.sql.
--  Se pueden volver a ejecutar (CREATE OR REPLACE).
-- ============================================================================

SET NAMES utf8mb4;
USE seoulglow_db;

-- ---------------------------------------------------------------------------
-- Catálogo listo para la web (Next.js consulta esta vista)
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
-- Productos por reponer (app de escritorio)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_stock_bajo AS
SELECT
    p.id_producto,
    p.sku,
    p.nombre,
    m.nombre AS marca,
    p.stock,
    p.stock_minimo,
    (p.stock_minimo - p.stock) AS unidades_faltantes
FROM productos p
JOIN marcas m ON m.id_marca = p.id_marca
WHERE p.activo = 1
  AND p.stock <= p.stock_minimo;

-- ---------------------------------------------------------------------------
-- Ventas por mes (reporte de la app de escritorio)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_ventas_mensuales AS
SELECT
    DATE_FORMAT(pe.fecha_pedido, '%Y-%m') AS periodo,
    COUNT(*)                              AS pedidos,
    SUM(pe.total)                         AS ingresos,
    ROUND(AVG(pe.total), 2)               AS ticket_promedio
FROM pedidos pe
WHERE pe.estado NOT IN ('cancelado', 'pendiente')
GROUP BY DATE_FORMAT(pe.fecha_pedido, '%Y-%m');

-- ============================================================================
--  Fin de 03_views.sql
--  Siguiente: 04_routines.sql
-- ============================================================================
