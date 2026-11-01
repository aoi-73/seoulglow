-- ============================================================================
--  Seoul Glow — 04_routines.sql
--  Procedimientos y triggers. Ejecutar DESPUÉS de 03_views.sql.
--
--  Requiere MariaDB 10.6 o superior (JSON_TABLE).
--  DBeaver entiende las directivas DELIMITER: ejecutar todo el archivo
--  con "Execute SQL Script" (Alt+X), no sentencia por sentencia.
-- ============================================================================

SET NAMES utf8mb4;
USE seoulglow_db;

DELIMITER $$

-- ---------------------------------------------------------------------------
-- Trigger: al insertar una línea de pedido se descuenta el stock
-- y se registra la salida en el kardex.
-- Es el ÚNICO punto que modifica stock por ventas: evita doble descuento.
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tr_detalle_after_insert$$
CREATE TRIGGER tr_detalle_after_insert
AFTER INSERT ON pedido_detalles
FOR EACH ROW
BEGIN
    DECLARE v_stock    INT;
    DECLARE v_numero   VARCHAR(30);
    DECLARE v_usuario  INT UNSIGNED;

    UPDATE productos
       SET stock = stock - NEW.cantidad
     WHERE id_producto = NEW.id_producto;

    SELECT stock INTO v_stock
      FROM productos
     WHERE id_producto = NEW.id_producto;

    SELECT numero_pedido, id_usuario
      INTO v_numero, v_usuario
      FROM pedidos
     WHERE id_pedido = NEW.id_pedido;

    INSERT INTO movimientos_inventario
        (id_producto, tipo, cantidad, motivo, id_usuario, stock_resultante)
    VALUES
        (NEW.id_producto, 'salida', NEW.cantidad,
         CONCAT('Venta ', v_numero), v_usuario, v_stock);
END$$

-- ---------------------------------------------------------------------------
-- Trigger: si se elimina una línea, se devuelve el stock
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS tr_detalle_after_delete$$
CREATE TRIGGER tr_detalle_after_delete
AFTER DELETE ON pedido_detalles
FOR EACH ROW
BEGIN
    DECLARE v_stock    INT;
    DECLARE v_numero   VARCHAR(30);
    DECLARE v_usuario  INT UNSIGNED;

    UPDATE productos
       SET stock = stock + OLD.cantidad
     WHERE id_producto = OLD.id_producto;

    SELECT stock INTO v_stock
      FROM productos
     WHERE id_producto = OLD.id_producto;

    SELECT numero_pedido, id_usuario
      INTO v_numero, v_usuario
      FROM pedidos
     WHERE id_pedido = OLD.id_pedido;

    INSERT INTO movimientos_inventario
        (id_producto, tipo, cantidad, motivo, id_usuario, stock_resultante)
    VALUES
        (OLD.id_producto, 'devolucion', OLD.cantidad,
         CONCAT('Ajuste ', v_numero), v_usuario, v_stock);
END$$

-- ---------------------------------------------------------------------------
-- sp_registrar_pedido
--   Crea un pedido completo en una transacción.
--   p_items: JSON con la forma [{"id_producto":1,"cantidad":2}, ...]
--   Devuelve en p_id_pedido el id generado.
--
--   Ejemplo:
--     CALL sp_registrar_pedido(1, 3,
--          '[{"id_producto":1,"cantidad":2},{"id_producto":9,"cantidad":1}]', @id);
--     SELECT @id;
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_pedido$$
CREATE PROCEDURE sp_registrar_pedido(
    IN  p_id_cliente BIGINT UNSIGNED,
    IN  p_id_usuario INT UNSIGNED,
    IN  p_items      LONGTEXT,
    OUT p_id_pedido  BIGINT UNSIGNED
)
BEGIN
    DECLARE v_items      INT DEFAULT 0;
    DECLARE v_faltantes  INT DEFAULT 0;
    DECLARE v_numero     VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF (SELECT COUNT(*) FROM clientes
         WHERE id_cliente = p_id_cliente AND activo = 1) = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cliente inexistente o inactivo';
    END IF;

    SELECT COUNT(*) INTO v_items
      FROM JSON_TABLE(p_items, '$[*]' COLUMNS (
             id_producto BIGINT PATH '$.id_producto',
             cantidad    INT    PATH '$.cantidad'
           )) AS jt;

    IF v_items = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido no tiene items';
    END IF;

    SELECT COUNT(*) INTO v_faltantes
      FROM JSON_TABLE(p_items, '$[*]' COLUMNS (
             id_producto BIGINT PATH '$.id_producto',
             cantidad    INT    PATH '$.cantidad'
           )) AS jt
      LEFT JOIN productos p ON p.id_producto = jt.id_producto
     WHERE p.id_producto IS NULL
        OR p.activo = 0
        OR p.stock < jt.cantidad;

    IF v_faltantes > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente o producto inactivo';
    END IF;

    -- Número temporal único para poder obtener el id con LAST_INSERT_ID()
    INSERT INTO pedidos
        (numero_pedido, id_cliente, id_usuario, estado)
    VALUES
        (CONCAT('TMP-', LEFT(REPLACE(UUID(), '-', ''), 20)),
         p_id_cliente, p_id_usuario, 'pendiente');

    SET p_id_pedido = LAST_INSERT_ID();
    SET v_numero = CONCAT('PED-', YEAR(CURDATE()), '-', LPAD(p_id_pedido, 6, '0'));

    UPDATE pedidos
       SET numero_pedido = v_numero
     WHERE id_pedido = p_id_pedido;

    -- Materializamos los ítems en una tabla temporal: el INSERT que dispara el
    -- trigger no puede leer productos (MariaDB error 1442 si el trigger lo actualiza).
    DROP TEMPORARY TABLE IF EXISTS tmp_items_pedido;
    CREATE TEMPORARY TABLE tmp_items_pedido (
        id_producto     BIGINT UNSIGNED NOT NULL,
        cantidad        INT UNSIGNED NOT NULL,
        precio_unitario DECIMAL(12,2) NOT NULL
    ) ENGINE=InnoDB;

    INSERT INTO tmp_items_pedido (id_producto, cantidad, precio_unitario)
    SELECT p.id_producto, jt.cantidad, COALESCE(p.precio_oferta, p.precio)
      FROM JSON_TABLE(p_items, '$[*]' COLUMNS (
             id_producto BIGINT PATH '$.id_producto',
             cantidad    INT    PATH '$.cantidad'
           )) AS jt
      JOIN productos p ON p.id_producto = jt.id_producto;

    -- El trigger tr_detalle_after_insert descuenta el stock y registra el kardex
    INSERT INTO pedido_detalles
        (id_pedido, id_producto, cantidad, precio_unitario, descuento_linea)
    SELECT p_id_pedido, id_producto, cantidad, precio_unitario, 0
      FROM tmp_items_pedido;

    DROP TEMPORARY TABLE tmp_items_pedido;

    UPDATE pedidos pe
      JOIN (SELECT id_pedido, SUM(subtotal_linea) AS s
              FROM pedido_detalles
             WHERE id_pedido = p_id_pedido
             GROUP BY id_pedido) d
        ON d.id_pedido = pe.id_pedido
       SET pe.subtotal = d.s,
           pe.total    = d.s - pe.descuento + pe.impuesto
     WHERE pe.id_pedido = p_id_pedido;

    COMMIT;
END$$

-- ---------------------------------------------------------------------------
-- sp_reponer_stock
--   Entrada de inventario con registro en el kardex.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_reponer_stock$$
CREATE PROCEDURE sp_reponer_stock(
    IN p_id_producto BIGINT UNSIGNED,
    IN p_cantidad    INT,
    IN p_id_usuario  INT UNSIGNED,
    IN p_motivo      VARCHAR(150)
)
BEGIN
    DECLARE v_stock INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La cantidad debe ser mayor que cero';
    END IF;

    START TRANSACTION;

    UPDATE productos
       SET stock = stock + p_cantidad
     WHERE id_producto = p_id_producto;

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Producto inexistente';
    END IF;

    SELECT stock INTO v_stock
      FROM productos
     WHERE id_producto = p_id_producto;

    INSERT INTO movimientos_inventario
        (id_producto, tipo, cantidad, motivo, id_usuario, stock_resultante)
    VALUES
        (p_id_producto, 'entrada', p_cantidad,
         COALESCE(p_motivo, 'Reposición de inventario'), p_id_usuario, v_stock);

    COMMIT;
END$$

-- ---------------------------------------------------------------------------
-- sp_cancelar_pedido
--   Cancela un pedido y devuelve el stock de todas sus líneas.
--   No permite cancelar pedidos entregados ni ya cancelados.
--   Los detalles quedan como historial: no se borran.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_cancelar_pedido$$
CREATE PROCEDURE sp_cancelar_pedido(
    IN p_id_pedido  BIGINT UNSIGNED,
    IN p_id_usuario INT UNSIGNED
)
BEGIN
    DECLARE v_estado VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT estado INTO v_estado
      FROM pedidos
     WHERE id_pedido = p_id_pedido
       FOR UPDATE;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Pedido inexistente';
    END IF;

    IF v_estado = 'cancelado' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido ya está cancelado';
    END IF;

    IF v_estado = 'entregado' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede cancelar un pedido entregado';
    END IF;

    UPDATE pedidos
       SET estado = 'cancelado'
     WHERE id_pedido = p_id_pedido;

    UPDATE productos p
      JOIN (SELECT id_producto, SUM(cantidad) AS c
              FROM pedido_detalles
             WHERE id_pedido = p_id_pedido
             GROUP BY id_producto) d
        ON d.id_producto = p.id_producto
       SET p.stock = p.stock + d.c;

    INSERT INTO movimientos_inventario
        (id_producto, tipo, cantidad, motivo, id_usuario, stock_resultante)
    SELECT p.id_producto, 'devolucion', d.c,
           CONCAT('Cancelación pedido ', p_id_pedido),
           p_id_usuario, p.stock
      FROM productos p
      JOIN (SELECT id_producto, SUM(cantidad) AS c
              FROM pedido_detalles
             WHERE id_pedido = p_id_pedido
             GROUP BY id_producto) d
        ON d.id_producto = p.id_producto;

    COMMIT;
END$$

-- ---------------------------------------------------------------------------
-- sp_recalcular_total_pedido
--   Recalcula subtotal y total a partir de las líneas.
-- ---------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_recalcular_total_pedido$$
CREATE PROCEDURE sp_recalcular_total_pedido(
    IN p_id_pedido BIGINT UNSIGNED
)
BEGIN
    UPDATE pedidos pe
      JOIN (SELECT id_pedido, COALESCE(SUM(subtotal_linea), 0) AS s
              FROM pedido_detalles
             WHERE id_pedido = p_id_pedido
             GROUP BY id_pedido) d
        ON d.id_pedido = pe.id_pedido
       SET pe.subtotal = d.s,
           pe.total    = d.s - pe.descuento + pe.impuesto
     WHERE pe.id_pedido = p_id_pedido;
END$$

DELIMITER ;

-- ============================================================================
--  Fin de 04_routines.sql
--  Siguiente: 05_users.sql
-- ============================================================================
