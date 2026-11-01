# Contexto del proyecto — Seoul Glow (K-Beauty)

> **Para el agente que trabaja en la VM Ubuntu.**
> Este documento es la fuente de verdad del estado actual: qué hay hecho, qué se validó,
> con qué credenciales se conecta cada componente y qué falta.
> Última actualización: **1 de noviembre de 2026**.

---

## 1. Resumen

Caso académico: *página web para una empresa utilizando Ubuntu 26 como servidor*.

| Componente | Dónde corre | Estado |
|---|---|---|
| Ubuntu 26 (VM) | VirtualBox / VMware | ✅ instalado |
| MariaDB | Ubuntu | ✅ instalado |
| Base de datos `seoulglow_db` | Ubuntu | ✅ cargada y verificada (01→06 ejecutados) |
| Servidor web Apache | Ubuntu | ✅ instalado |
| Página web **Next.js** + Apache como proxy | Ubuntu | ⬜ pendiente |
| App de escritorio **Apache NetBeans** (Java + JDBC) | Windows | ⬜ pendiente |
| DBeaver | Windows | ✅ conexión creada |

**Marca del caso:** *Seoul Glow* (nombre provisional). Tienda de skincare coreano.

**Documentos de diseño:**

- `PLAN_BASE_DATOS.md` — modelo entidad-relación, diccionario de datos, reglas de integridad, permisos.
- `PLAN_WEB_NEXTJS.md` — arquitectura Next.js, Apache como reverse proxy, systemd, despliegue y pruebas.
- `sql/README.md` — orden de ejecución, credenciales, consultas de verificación y errores frecuentes.

---

## 2. Estructura del repositorio

```
.
├── CONTEXTO_UBUNTU.md      ← este documento
├── README.md
├── PLAN_BASE_DATOS.md
├── PLAN_WEB_NEXTJS.md
└── sql/
    ├── README.md
    ├── 01_schema.sql       ← tablas, FKs, índices, CHECK
    ├── 02_seed.sql         ← datos de ejemplo
    ├── 03_views.sql        ← vistas
    ├── 04_routines.sql     ← triggers + procedimientos
    ├── 05_users.sql        ← usuarios de MariaDB y GRANTs
    └── 06_verify.sql       ← comprobaciones posteriores a la carga
```

---

## 3. Base de datos

- **Nombre:** `seoulglow_db`
- **Motor:** InnoDB · **Charset:** `utf8mb4` / `utf8mb4_unicode_ci`
- **MariaDB mínima:** **10.6** (se usa `JSON_TABLE` en `04_routines.sql`)
- **Normalización:** 3FN
- **Dinero:** `DECIMAL(12,2)`, moneda por defecto `USD`

### 3.1 Tablas (11)

| Tabla | Rol |
|---|---|
| `usuarios` | Personal de la app de escritorio (rol: admin/gerente/vendedor/soporte) |
| `categorias` | 9 principales + 3 subcategorías (auto-referencia `id_padre`) |
| `marcas` | 10 marcas coreanas |
| `productos` | Catálogo: SKU, slug, precio, oferta, stock, `tipo_piel` (SET), `destacado` |
| `producto_imagenes` | 2 imágenes por producto |
| `ingredientes` | 14 activos (centella, niacinamida, mucina de caracol…) |
| `producto_ingredientes` | Puente N:M con `porcentaje` y `es_clave` |
| `clientes` | 15 clientes |
| `pedidos` | 20 pedidos con estados y totales |
| `pedido_detalles` | 38 líneas; `subtotal_linea` es columna generada `STORED` |
| `movimientos_inventario` | Kardex (entrada/salida/ajuste/devolución) |

### 3.2 Volumen esperado después del seed

| Tabla | Filas |
|---|---|
| `categorias` | 12 |
| `marcas` | 10 |
| `ingredientes` | 14 |
| `productos` | 32 |
| `producto_imagenes` | 64 |
| `producto_ingredientes` | 67 |
| `clientes` | 15 |
| `pedidos` | 20 |
| `pedido_detalles` | 38 |
| `movimientos_inventario` | 62 (32 entradas + 30 salidas) |
| `usuarios` | 4 |

### 3.3 Vistas

| Vista | Uso |
|---|---|
| `v_catalogo_web` | Catálogo que consume Next.js. Incluye `id_marca`, `id_categoria`, `precio_efectivo`, `imagen_principal` |
| `v_stock_bajo` | Productos con `stock <= stock_minimo` (app de escritorio) |
| `v_ventas_mensuales` | Ingresos y ticket promedio por mes |

### 3.4 Rutinas

| Objeto | Qué hace |
|---|---|
| `tr_detalle_after_insert` | **Único** punto que descuenta stock por ventas + registra salida en kardex |
| `tr_detalle_after_delete` | Devuelve el stock de la línea eliminada |
| `sp_registrar_pedido(cliente, usuario, items_json, OUT id)` | Crea pedido completo en una transacción |
| `sp_reponer_stock(producto, cantidad, usuario, motivo)` | Entrada de inventario |
| `sp_cancelar_pedido(pedido, usuario)` | Cancela y devuelve stock (no permite `entregado` ni repetir) |
| `sp_recalcular_total_pedido(pedido)` | Recalcula subtotal y total |

---

## 4. Usuarios y credenciales

> ⚠ **Credenciales de demostración para un trabajo académico.**
> Si el repositorio es público o el sistema deja de ser una demo, **cambiar todas** antes de usarlo.
> No usar `root` desde Windows.

### 4.1 Usuarios de la aplicación (tabla `usuarios`)

| Usuario | Contraseña | Rol |
|---|---|---|
| `admin` | `Admin123!` | admin |
| `gerente` | `Gerente123!` | gerente |
| `vendedor` | `Vendedor123!` | vendedor |
| `soporte` | `Soporte123!` | soporte |

Formato del hash: **PBKDF2-HMAC-SHA256, 120.000 iteraciones**

```
pbkdf2_sha256$<iteraciones>$<salt_base64>$<hash_base64>
```

Verificación en Java (también está en `sql/README.md`):

```java
String[] p = almacenado.split("\\$");
int iter = Integer.parseInt(p[1]);
byte[] salt = Base64.getDecoder().decode(p[2]);
byte[] esperado = Base64.getDecoder().decode(p[3]);
PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, iter, esperado.length * 8);
byte[] calc = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
                               .generateSecret(spec).getEncoded();
return MessageDigest.isEqual(esperado, calc);
```

### 4.2 Usuarios de MariaDB

| Usuario | Host | Contraseña | Permisos |
|---|---|---|---|
| `web_skincare` | `localhost` | `WebSkincare2026!` | `SELECT` sobre `v_catalogo_web`, `producto_imagenes`, `producto_ingredientes`, `ingredientes` |
| **`admin_skincare`** | `192.168.1.%` | `AdminSkincare2026!` | `SELECT, INSERT, UPDATE, DELETE, EXECUTE` sobre `seoulglow_db.*` |
| `backup_skincare` | `localhost` | `BackupSkincare2026!` | lectura + `LOCK TABLES` para `mysqldump` |

**Importante:** `web_skincare` es `@'localhost'` porque **Next.js corre en la misma VM**.
Si la IP del cliente Windows no está en `192.168.1.0/24`, ajustar `05_users.sql` **antes** de ejecutarlo.

> **Desde Windows se usa SIEMPRE `admin_skincare`, nunca `root`.** Es el único usuario
> habilitado para conexiones remotas y el único con permiso de escritura. Ver §4.4.

### 4.3 Cadenas de conexión

| Cliente | Cadena |
|---|---|
| Next.js (`mysql2`) | `{ host: '127.0.0.1', port: 3306, database: 'seoulglow_db', user: 'web_skincare' }` |
| JDBC (NetBeans) | `jdbc:mariadb://192.168.1.157:3306/seoulglow_db` con `admin_skincare` |
| DBeaver | misma URL JDBC |

### 4.4 Acceso desde Windows (agente de la app `.exe` / NetBeans)

Datos exactos para conectarse desde la máquina Windows (probado el 1/11/2026 desde
`192.168.1.71` contra la VM `192.168.1.157`):

| Dato | Valor |
|---|---|
| Host / IP de la VM | `192.168.1.157` |
| Puerto | `3306` |
| Base de datos | `seoulglow_db` |
| Usuario | **`admin_skincare`** (no `root`, no `web_skincare`) |
| Contraseña | `AdminSkincare2026!` |
| URL JDBC | `jdbc:mariadb://192.168.1.157:3306/seoulglow_db` |
| Driver | `org.mariadb.jdbc.Driver` (`mariadb-java-client`) |

Prueba rápida antes de escribir código Java:

```bash
# Desde Windows (PowerShell), si hay cliente MariaDB/MySQL instalado:
mariadb -h 192.168.1.157 -P 3306 -u admin_skincare -p seoulglow_db -e "SELECT COUNT(*) FROM productos;"
# Debe devolver 32
```

Notas para ese agente:

- **La base ya está cargada y verificada**: no ejecutar `01`–`06` desde Windows.
- `admin_skincare` solo puede entrar desde `192.168.1.%`; si la IP de Windows cambia de red,
  hay que ajustar el host del usuario en la VM (`05_users.sql`).
- El firewall de la VM tiene el **3306 abierto a cualquier origen** (`ufw allow 3306/tcp`,
  decisión del 1/11/2026 para la demo académica). No hay que tocar `ufw` desde Windows.
- No crear usuarios nuevos ni otorgar permisos desde la app: los usuarios de MariaDB se
  administran solo en la VM.
- `subtotal_linea` en `pedido_detalles` es columna generada: no se inserta ni se actualiza.
- Para anular un pedido usar `CALL sp_cancelar_pedido(id, id_usuario)`, no `DELETE`.

---

## 5. Cómo cargar la base

### Opción A — terminal en Ubuntu (recomendada)

```bash
cd <ruta-del-repo>
sudo mariadb < sql/01_schema.sql
sudo mariadb < sql/02_seed.sql
sudo mariadb < sql/03_views.sql
sudo mariadb < sql/04_routines.sql
sudo mariadb < sql/05_users.sql      # requiere GRANT OPTION: root@localhost
sudo mariadb < sql/06_verify.sql     # opcional
```

El cliente `mariadb` interpreta `DELIMITER` de forma nativa. También sirve `mysql`.

> **Error 1142 (`GRANT command denied`)** al ejecutar `05_users.sql` desde DBeaver:
> el `root` remoto no tiene `GRANT OPTION`. No es un error del script.
> Solución: ejecutarlo en la VM con `sudo mariadb < sql/05_users.sql`.
> No otorgues `GRANT OPTION` al root remoto.

### Opción B — DBeaver desde Windows

Abrir cada archivo y usar **Execute SQL Script** (`Alt+X`), en el mismo orden.
**No** ejecutar sentencia por sentencia en `04_routines.sql`.

`01_schema.sql` es idempotente: vuelve a crear la base desde cero (borra tablas y vistas, **no** usuarios de MariaDB).

---

## 6. Validación realizada

La base **ya está cargada en el MariaDB 11.8.6 de la VM** (Ubuntu 26) y validada con
`06_verify.sql`. Resultado del 1 de noviembre de 2026:

| Verificación | Resultado |
|---|---|
| Conteo de filas (11 tablas) | ✅ coincide con la tabla de §3.2 |
| Vistas creadas | ✅ `v_catalogo_web`, `v_stock_bajo`, `v_ventas_mensuales` |
| Rutinas creadas | ✅ 4 procedimientos + 2 triggers |
| Kardex vs stock (`descuadres_kardex`) | ✅ 0 |
| Totales de pedidos (`descuadres_totales`) | ✅ 0 |
| Usuarios de MariaDB | ✅ `web_skincare`, `admin_skincare`, `backup_skincare` |
| Conexión `web_skincare@localhost` | ✅ lee `v_catalogo_web` (32 filas) |
| Conexión `admin_skincare@192.168.1.%` | ✅ CRUD sobre `seoulglow_db` |
| `v_stock_bajo` | ✅ 4 productos (Miracle Starter Kit, Centella Calming Sheet Mask, All Day Mask Pack, Lip Sleeping Mask) |

### 6.1 Resultados esperados tras el seed

- **4 productos con stock bajo** (para demostrar `v_stock_bajo`):
  - Lip Sleeping Mask → 5 (mín. 5)
  - Centella Calming Sheet Mask → 2 (mín. 5)
  - All Day Mask Pack → 6 (mín. 6)
  - Miracle Starter Kit → 7 (mín. 10)
- El pedido `PED-2026-000005` está **cancelado** y no descuenta stock.
- 45 unidades vendidas en total.

### 6.2 Correcciones aplicadas

- `sp_registrar_pedido` materializa los ítems en una **tabla temporal** antes de insertar
  `pedido_detalles`. Motivo: el `INSERT ... SELECT` original leía `productos` y el trigger
  `tr_detalle_after_insert` actualiza esa misma tabla → **MariaDB error 1442**
  (*Can't update table in stored function/trigger because it is already used by statement*).
- `05_users.sql` comprueba `GRANT OPTION` **antes** de crear usuarios. Antes, al ejecutarlo
  desde DBeaver como `root@'%'` (sin `GRANT OPTION`), abortaba en el primer `GRANT` y dejaba
  `web_skincare` creado pero sin permisos y sin `admin_skincare`. Ya se corrigió ejecutándolo
  en la VM con `sudo mariadb < sql/05_users.sql`; ambos usuarios quedaron con sus permisos.
- `06_verify.sql`: el alias `AS real` es palabra reservada en MariaDB 11.8 (error 1064).
  Se renombró a `AS obtenido`.

---

## 7. Trampas conocidas

| Tema | Detalle |
|---|---|
| **Error 1442** | No insertar detalles con `INSERT ... SELECT` sobre `productos`; usar `VALUES` o `sp_registrar_pedido` |
| **Error 1142** (`GRANT command denied`) | El `root` remoto (DBeaver, `root@'%'`) no tiene `GRANT OPTION`; no es un fallo del script. Desde el 1/11/2026 `05_users.sql` lo detecta y aborta antes de crear nada. Solución: `sudo mariadb < sql/05_users.sql` en la VM |
| **DELIMITER** | `04_routines.sql` debe ejecutarse como script completo |
| **Host de `web_skincare`** | Es `@'localhost'`; no crear `@'%'` "para que funcione" |
| **`bind-address`** | Solo necesario para NetBeans/DBeaver desde Windows |
| **Puerto 3306** | **Abierto a cualquier origen** por decisión del 1/11/2026 (demo académica): `ufw allow 3306/tcp`. El acceso lo controla MariaDB con `admin_skincare@'192.168.1.%'`. En un entorno real, restringir a la LAN (`ufw allow from 192.168.1.0/24 to any port 3306`) |
| **Imágenes** | `producto_imagenes.url` apunta a `/img/productos/<SKU>-1.webp`; hay que copiar las fotos a `public/img/productos/` en Next.js |
| **Caché ISR** | Si el stock cambia desde NetBeans, la web puede tardar hasta `revalidate` segundos |
| **Zona horaria** | Guardar en UTC; mostrar en la app |
| **Mayúsculas** | Linux distingue `ProductoCard.tsx` de `productocard.tsx` (rompe builds que en Windows funcionan) |
| **Borrar pedidos** | No borrar para "anular": usar `sp_cancelar_pedido` |

---

## 8. Próximos pasos (para el agente en Ubuntu)

1. ~~Verificar MariaDB ≥ 10.6~~ → ✅ MariaDB 11.8.6.
2. ~~Ejecutar los scripts en orden~~ → ✅ 01→06 ejecutados y verificados.
3. ~~Correr las consultas de verificación~~ → ✅ kardex y totales cuadran, `v_stock_bajo` devuelve 4.
4. Crear el proyecto Next.js según `PLAN_WEB_NEXTJS.md`:
   - `lib/db.ts` con pool `mysql2` usando `web_skincare@localhost`.
   - Home, catálogo (`searchParams`), ficha `[slug]` con `generateMetadata`.
   - Filtros por categoría, marca y `tipo_piel`.
5. Apache como reverse proxy a `127.0.0.1:3000` (`mod_proxy_http`, `ProxyPreserveHost`).
6. Servicio `systemd` para que sobreviva reinicios.
7. Probar desde Windows: `http://<IP_VM>/`.
8. No commitear `.env.local` ni credenciales nuevas.

---

## 9. Reglas para el repositorio

- `.env.local`, `node_modules/`, `.next/` están en `.gitignore`.
- Las contraseñas de este documento son **de demo**; no reutilizarlas.
- Los planes (`PLAN_*.md`) son la referencia de diseño; si el código se desvía, actualizar el plan.
- Antes de cambiar el esquema, revisar las dependencias: vistas → rutinas → permisos → app.
