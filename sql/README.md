# Scripts SQL — Seoul Glow

Base de datos MariaDB del proyecto. Diseño completo en `../PLAN_BASE_DATOS.md`.

## Requisitos

- MariaDB **10.6 o superior** (se usa `JSON_TABLE` en `04_routines.sql`).
- Ejecutar como usuario con permisos de administración (`root`), porque los scripts crean la base, tablas, vistas, rutinas y usuarios.

## Orden de ejecución (importante)

En DBeaver: abrir cada archivo y usar **Execute SQL Script** (`Alt+X`). No ejecutar sentencia por sentencia: los procedimientos usan `DELIMITER`.

| # | Archivo | Qué hace |
|---|---|---|
| 1 | `01_schema.sql` | Crea `seoulglow_db`, las 11 tablas, claves foráneas, índices y `CHECK` |
| 2 | `02_seed.sql` | Carga categorías, marcas, 32 productos, ingredientes, clientes, 20 pedidos y el kardex |
| 3 | `03_views.sql` | Crea `v_catalogo_web`, `v_stock_bajo`, `v_ventas_mensuales` |
| 4 | `04_routines.sql` | Triggers de stock y procedimientos `sp_registrar_pedido`, `sp_reponer_stock`, `sp_cancelar_pedido`, `sp_recalcular_total_pedido` |
| 5 | `05_users.sql` | Crea `web_skincare`, `admin_skincare`, `backup_skincare` y sus permisos |

> `01_schema.sql` es idempotente: si lo volvés a ejecutar, **borra** las tablas y vistas de `seoulglow_db`. No borra los usuarios.

## Credenciales

### Usuarios de la aplicación

| Usuario | Contraseña | Rol | Para qué |
|---|---|---|---|
| `admin` | `Admin123!` | admin | Todo |
| `gerente` | `Gerente123!` | gerente | Reportes y pedidos |
| `vendedor` | `Vendedor123!` | vendedor | Ventas |
| `soporte` | `Soporte123!` | soporte | Consultas |

Los hashes están en formato **PBKDF2-HMAC-SHA256, 120.000 iteraciones**, con este formato:

```
pbkdf2_sha256$<iteraciones>$<salt_base64>$<hash_base64>
```

### Usuarios de MariaDB

| Usuario | Host | Contraseña | Permisos |
|---|---|---|---|
| `web_skincare` | `localhost` | `WebSkincare2026!` | `SELECT` sobre la vista y las tablas del catálogo |
| `admin_skincare` | `192.168.56.%` | `AdminSkincare2026!` | `SELECT, INSERT, UPDATE, DELETE, EXECUTE` sobre `seoulglow_db.*` |
| `backup_skincare` | `localhost` | `BackupSkincare2026!` | Lectura + bloqueo para `mysqldump` |

> Si tu VM usa otra red (VMware, bridged), editá el host en `05_users.sql` antes de ejecutarlo.

## Verificación después de cargar

```sql
USE seoulglow_db;

-- 1. Conteo general
SELECT 'productos' AS tabla, COUNT(*) AS filas FROM productos
UNION ALL SELECT 'pedidos', COUNT(*) FROM pedidos
UNION ALL SELECT 'pedido_detalles', COUNT(*) FROM pedido_detalles
UNION ALL SELECT 'movimientos', COUNT(*) FROM movimientos_inventario;

-- 2. El stock debe coincidir con la suma del kardex
SELECT p.id_producto, p.nombre, p.stock,
       SUM(CASE WHEN m.tipo IN ('entrada','devolucion') THEN m.cantidad
                WHEN m.tipo = 'salida' THEN -m.cantidad
                ELSE 0 END) AS segun_kardex
FROM productos p
LEFT JOIN movimientos_inventario m USING (id_producto)
GROUP BY p.id_producto, p.nombre, p.stock
HAVING p.stock <> segun_kardex;   -- no debe devolver filas

-- 3. Totales de pedidos coherentes
SELECT pe.id_pedido, pe.total, SUM(d.subtotal_linea) AS suma_lineas
FROM pedidos pe JOIN pedido_detalles d USING (id_pedido)
GROUP BY pe.id_pedido, pe.total
HAVING pe.total <> SUM(d.subtotal_linea) - pe.descuento + pe.impuesto;

-- 4. Productos por reponer
SELECT * FROM v_stock_bajo;

-- 5. Catálogo que verá la web
SELECT nombre, marca, categoria, precio_efectivo, stock
FROM v_catalogo_web ORDER BY destacado DESC, nombre LIMIT 10;
```

## Pruebas de los procedimientos

```sql
-- Registrar un pedido (cliente 1, vendedor 3)
CALL sp_registrar_pedido(1, 3,
  '[{"id_producto":1,"cantidad":2},{"id_producto":9,"cantidad":1}]', @nuevo_id);
SELECT @nuevo_id;

SELECT * FROM pedidos WHERE id_pedido = @nuevo_id;
SELECT * FROM pedido_detalles WHERE id_pedido = @nuevo_id;
SELECT * FROM movimientos_inventario ORDER BY id_movimiento DESC LIMIT 3;

-- Reponer stock
CALL sp_reponer_stock(1, 20, 1, 'Compra a proveedor');

-- Cancelar un pedido pendiente (devuelve stock)
CALL sp_cancelar_pedido(@nuevo_id, 1);

-- Error esperado: stock insuficiente
CALL sp_registrar_pedido(1, 3, '[{"id_producto":29,"cantidad":999}]', @x);
```

## Verificar una contraseña desde Java (PBKDF2)

```java
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.util.Base64;

public static boolean verificar(String password, String almacenado) throws Exception {
    String[] partes = almacenado.split("\\$");   // pbkdf2_sha256 $ iter $ salt $ hash
    int iteraciones = Integer.parseInt(partes[1]);
    byte[] salt = Base64.getDecoder().decode(partes[2]);
    byte[] esperado = Base64.getDecoder().decode(partes[3]);

    PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, iteraciones, esperado.length * 8);
    byte[] calculado = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                                       .generateSecret(spec).getEncoded();
    return java.security.MessageDigest.isEqual(esperado, calculado);
}
```

## Notas de conexión

- Desde Windows (NetBeans / DBeaver): `jdbc:mariadb://192.168.56.10:3306/seoulglow_db` con `admin_skincare`.
- Desde Next.js en la VM: `127.0.0.1:3306` con `web_skincare`.
- Requiere en Ubuntu: `bind-address = 0.0.0.0` y `ufw allow from 192.168.56.0/24 to any port 3306` (solo por la app de escritorio).

## Reglas que la base ya hace cumplir

- **Stock por ventas:** lo descuenta el trigger `tr_detalle_after_insert`. Por eso, si insertás detalles desde la app de escritorio, usá `INSERT ... VALUES` (no `INSERT ... SELECT` sobre `productos`: MariaDB lanza el error 1442 porque el trigger actualiza esa misma tabla).
- **Pedidos:** se crean con `sp_registrar_pedido` o insertando cabecera + detalles. Nunca borrar un pedido para "anularlo": usar `sp_cancelar_pedido`, que devuelve el stock y deja el historial.
- **Cancelaciones:** no se permite cancelar un pedido `entregado` ni uno ya `cancelado`.
- **Cambiar la cantidad de una línea:** borrar la línea (el trigger devuelve el stock) y volver a insertarla.
- **Precio histórico:** `pedido_detalles.precio_unitario` guarda el precio del momento de la venta; no se actualiza si el producto cambia de precio.

## Problemas frecuentes

| Error | Causa | Solución |
|---|---|---|
| `You have an error in your SQL syntax ... near 'DELIMITER'` | Se ejecutó sentencia por sentencia | Usar `Alt+X` (script completo) |
| `FUNCTION JSON_TABLE does not exist` | MariaDB < 10.6 | Actualizar MariaDB |
| `Cannot add or update a child row` en el seed | Se ejecutó el seed sin el esquema | Ejecutar `01` antes que `02` |
| `Access denied for user 'web_skincare'@'localhost'` | Usuario creado con otro host | Revisar `SELECT user, host FROM mysql.user` |
| `Duplicate entry 'PED-2026-...'` | Se ejecutó el seed dos veces | Volver a correr `01_schema.sql` y luego `02` |
