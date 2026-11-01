-- ============================================================================
--  Seoul Glow — 06_verify.sql  (opcional)
--  Comprobaciones posteriores a la carga. Ejecutar como root o admin_skincare.
--  Todas las consultas deben dar resultados coherentes con la columna "esperado".
-- ============================================================================

USE seoulglow_db;

-- ---------------------------------------------------------------------------
-- 1) Conteo de filas
-- ---------------------------------------------------------------------------
SELECT 'categorias'           AS tabla, 12 AS esperado, COUNT(*) AS real FROM categorias
UNION ALL SELECT 'marcas',              10, COUNT(*) FROM marcas
UNION ALL SELECT 'ingredientes',        14, COUNT(*) FROM ingredientes
UNION ALL SELECT 'productos',           32, COUNT(*) FROM productos
UNION ALL SELECT 'producto_imagenes',   64, COUNT(*) FROM producto_imagenes
UNION ALL SELECT 'producto_ingredientes', 67, COUNT(*) FROM producto_ingredientes
UNION ALL SELECT 'clientes',            15, COUNT(*) FROM clientes
UNION ALL SELECT 'pedidos',             20, COUNT(*) FROM pedidos
UNION ALL SELECT 'pedido_detalles',     38, COUNT(*) FROM pedido_detalles
UNION ALL SELECT 'movimientos_inventario', 62, COUNT(*) FROM movimientos_inventario
UNION ALL SELECT 'usuarios',             4, COUNT(*) FROM usuarios;

-- ---------------------------------------------------------------------------
-- 2) Objetos creados
-- ---------------------------------------------------------------------------
SELECT TABLE_NAME AS vista
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'seoulglow_db'
ORDER BY TABLE_NAME;

SELECT ROUTINE_TYPE, ROUTINE_NAME
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'seoulglow_db'
ORDER BY ROUTINE_TYPE, ROUTINE_NAME;

SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'seoulglow_db';

-- ---------------------------------------------------------------------------
-- 3) Integridad: el stock debe coincidir con el kardex (0 descuadres)
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS descuadres_kardex
FROM (
    SELECT p.id_producto
    FROM productos p
    LEFT JOIN movimientos_inventario m ON m.id_producto = p.id_producto
    GROUP BY p.id_producto, p.stock
    HAVING p.stock <> COALESCE(SUM(CASE
             WHEN m.tipo IN ('entrada','devolucion') THEN m.cantidad
             WHEN m.tipo = 'salida' THEN -m.cantidad
             ELSE 0 END), 0)
) x;

-- ---------------------------------------------------------------------------
-- 4) Integridad: totales de pedidos (0 descuadres)
-- ---------------------------------------------------------------------------
SELECT COUNT(*) AS descuadres_totales
FROM (
    SELECT pe.id_pedido
    FROM pedidos pe
    LEFT JOIN pedido_detalles d ON d.id_pedido = pe.id_pedido
    GROUP BY pe.id_pedido, pe.subtotal, pe.descuento, pe.impuesto, pe.total
    HAVING pe.subtotal <> COALESCE(SUM(d.subtotal_linea), 0)
        OR pe.total    <> COALESCE(SUM(d.subtotal_linea), 0) - pe.descuento + pe.impuesto
) x;

-- ---------------------------------------------------------------------------
-- 5) Usuarios de MariaDB creados
-- ---------------------------------------------------------------------------
SELECT user, host
FROM mysql.user
WHERE user LIKE '%skincare%'
ORDER BY user, host;

-- ---------------------------------------------------------------------------
-- 6) Demostración: 4 productos con stock bajo
-- ---------------------------------------------------------------------------
SELECT * FROM v_stock_bajo ORDER BY unidades_faltantes DESC;

-- ---------------------------------------------------------------------------
-- 7) Vista previa del catálogo web
-- ---------------------------------------------------------------------------
SELECT nombre, marca, categoria, precio_efectivo, stock
FROM v_catalogo_web
ORDER BY destacado DESC, nombre
LIMIT 10;

-- ============================================================================
--  Fin de 06_verify.sql
-- ============================================================================
