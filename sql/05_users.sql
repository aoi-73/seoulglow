-- ============================================================================
--  Seoul Glow — 05_users.sql
--  Usuarios de MariaDB y permisos. Ejecutar al final, como root.
--
--  ⚠ Ajustar la red de la VM (192.168.56.% por defecto) a la que uses:
--     VirtualBox Host-only  → 192.168.56.%
--     VMware Host-only      → 192.168.xxx.%
--     Red puente (bridged)  → los tres primeros octetos de tu LAN
--
--  Nunca conectarse desde Windows con root.
-- ============================================================================

SET NAMES utf8mb4;
USE seoulglow_db;

-- ---------------------------------------------------------------------------
-- 1) Web (Next.js): SOLO lectura, y solo entra por localhost
-- ---------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'web_skincare'@'localhost' IDENTIFIED BY 'WebSkincare2026!';
ALTER  USER 'web_skincare'@'localhost' IDENTIFIED BY 'WebSkincare2026!';

GRANT SELECT ON seoulglow_db.v_catalogo_web       TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.producto_imagenes    TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.producto_ingredientes TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.ingredientes         TO 'web_skincare'@'localhost';

-- ---------------------------------------------------------------------------
-- 2) Aplicación de escritorio (NetBeans) y DBeaver: CRUD completo
--    Cambiar 192.168.56.% por la red real de la VM si hace falta.
-- ---------------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'admin_skincare'@'192.168.56.%' IDENTIFIED BY 'AdminSkincare2026!';
ALTER  USER 'admin_skincare'@'192.168.56.%' IDENTIFIED BY 'AdminSkincare2026!';

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE
  ON seoulglow_db.* TO 'admin_skincare'@'192.168.56.%';

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
SHOW GRANTS FOR 'admin_skincare'@'192.168.56.%';

-- ============================================================================
--  Fin de 05_users.sql
-- ============================================================================
