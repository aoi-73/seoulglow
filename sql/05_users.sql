-- ============================================================================
--  Seoul Glow — 05_users.sql
--  Usuarios de MariaDB y permisos.
--
--  ⚠ IMPORTANTE: ejecutar con un usuario que tenga GRANT OPTION.
--    El root de MariaDB por defecto es root@localhost (autenticación por socket),
--    así que hay que ejecutarlo EN LA VM:
--
--        sudo mariadb < sql/05_users.sql
--
--    Si lo ejecutás desde DBeaver conectado como root remoto y aparece
--    "SQL Error [1142] GRANT command denied", ese root no tiene GRANT OPTION.
--    No le des más permisos al root remoto: corré este script en la VM.
--
--  ⚠ Red: por defecto 192.168.1.% (red detectada: el cliente Windows es
--    192.168.1.71). Si cambia, ajustá las apariciones de '192.168.1.%'.
--
--  Nunca conectarse desde Windows con root.
--
--  ℹ El script comprueba GRANT OPTION antes de crear nada. Si falta, aborta
--    con "Falta GRANT OPTION: ejecuta en la VM -> sudo mariadb < ..." en vez
--    de dejar usuarios creados a medias (era lo que pasaba desde DBeaver).
--    Es idempotente: si se corta, volver a ejecutarlo en la VM lo completa.
-- ============================================================================

SET NAMES utf8mb4;
USE seoulglow_db;

-- ---------------------------------------------------------------------------
-- 0) Comprobación previa: sin GRANT OPTION el script se corta en el primer
--    GRANT y deja usuarios creados pero sin permisos. Mejor fallar antes.
-- ---------------------------------------------------------------------------
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_verificar_grant_option$$
CREATE PROCEDURE sp_verificar_grant_option()
BEGIN
  DECLARE v_grant_priv CHAR(1);

  SELECT Grant_priv INTO v_grant_priv
  FROM mysql.user
  WHERE User = SUBSTRING_INDEX(CURRENT_USER(), '@', 1)
    AND Host = SUBSTRING_INDEX(CURRENT_USER(), '@', -1);

  IF v_grant_priv IS NULL OR v_grant_priv <> 'Y' THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Falta GRANT OPTION: ejecuta en la VM -> sudo mariadb < sql/05_users.sql';
  END IF;
END$$
DELIMITER ;

CALL sp_verificar_grant_option();
DROP PROCEDURE sp_verificar_grant_option;

-- ---------------------------------------------------------------------------
-- 1) Web (Next.js): SOLO lectura, y solo entra por localhost
--    Next.js corre en la misma VM, así que este usuario no necesita acceso remoto.
-- ---------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'web_skincare'@'localhost' IDENTIFIED BY 'WebSkincare2026!';
ALTER  USER 'web_skincare'@'localhost' IDENTIFIED BY 'WebSkincare2026!';

GRANT SELECT ON seoulglow_db.v_catalogo_web        TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.producto_imagenes     TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.producto_ingredientes TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.ingredientes          TO 'web_skincare'@'localhost';

-- ---------------------------------------------------------------------------
-- 2) Aplicación de escritorio (NetBeans) y DBeaver: CRUD completo
-- ---------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'admin_skincare'@'192.168.1.%' IDENTIFIED BY 'AdminSkincare2026!';
ALTER  USER 'admin_skincare'@'192.168.1.%' IDENTIFIED BY 'AdminSkincare2026!';

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE
  ON seoulglow_db.* TO 'admin_skincare'@'192.168.1.%';

-- ---------------------------------------------------------------------------
-- 3) Respaldo (opcional, solo desde la propia VM)
-- ---------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'backup_skincare'@'localhost' IDENTIFIED BY 'BackupSkincare2026!';
ALTER  USER 'backup_skincare'@'localhost' IDENTIFIED BY 'BackupSkincare2026!';

GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER
  ON seoulglow_db.* TO 'backup_skincare'@'localhost';

FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------------
-- Verificación
-- ---------------------------------------------------------------------------
SELECT user, host FROM mysql.user WHERE user LIKE '%skincare%';
SHOW GRANTS FOR 'web_skincare'@'localhost';
SHOW GRANTS FOR 'admin_skincare'@'192.168.1.%';

-- ============================================================================
--  Fin de 05_users.sql
--  Siguiente (opcional): 06_verify.sql
-- ============================================================================
