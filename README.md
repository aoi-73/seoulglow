# Seoul Glow — Base de datos y web (K-Beauty)

Proyecto académico: **página web para una empresa utilizando Ubuntu 26 como servidor**.

La empresa vende productos coreanos de skincare. La solución tiene tres clientes sobre
una misma base MariaDB:

| Componente | Dónde corre | Estado |
|---|---|---|
| Base de datos `seoulglow_db` | Ubuntu 26 | cargada y verificada |
| Página web (Next.js + Apache) | Ubuntu 26 | básica publicada |
| App de escritorio (NetBeans + JDBC) | Windows | pendiente |

## Documentación

| Documento | Contenido |
|---|---|
| [`CONTEXTO_UBUNTU.md`](CONTEXTO_UBUNTU.md) | **Empezar aquí**: estado, credenciales, validaciones y próximos pasos |
| [`PLAN_BASE_DATOS.md`](PLAN_BASE_DATOS.md) | Modelo ER, diccionario de datos, integridad y permisos |
| [`PLAN_WEB_NEXTJS.md`](PLAN_WEB_NEXTJS.md) | Arquitectura Next.js, Apache proxy, systemd y despliegue |
| [`sql/README.md`](sql/README.md) | Orden de ejecución, pruebas y errores frecuentes |

## Puesta en marcha

```bash
sudo mariadb < sql/01_schema.sql
sudo mariadb < sql/02_seed.sql
sudo mariadb < sql/03_views.sql
sudo mariadb < sql/04_routines.sql
sudo mariadb < sql/05_users.sql
sudo mariadb < sql/06_verify.sql   # opcional
```

Requiere **MariaDB 10.6+** (se usa `JSON_TABLE`) y ejecutarse **en la VM**:
`05_users.sql` necesita `GRANT OPTION`, que el `root` remoto normalmente no tiene.

## Conexión desde Windows (app de escritorio / NetBeans)

La base ya está cargada. Desde Windows **no** se ejecutan los scripts: solo se conecta la app.

| Dato | Valor |
|---|---|
| URL JDBC | `jdbc:mariadb://192.168.1.157:3306/seoulglow_db` |
| Usuario | **`admin_skincare`** (nunca `root`) |
| Contraseña | `AdminSkincare2026!` |
| Driver | `org.mariadb.jdbc.Driver` (`mariadb-java-client`) |

Detalles y notas para el agente de la app `.exe`: ver **§4.4** en [`CONTEXTO_UBUNTU.md`](CONTEXTO_UBUNTU.md).

## Web (Next.js + Apache)

Publicada en **`http://192.168.1.157/`** (Apache → `127.0.0.1:3000`).

| Ruta | Contenido |
|---|---|
| `/` | Home: destacados, marcas y categorías |
| `/productos` | Catálogo con filtros por categoría, tipo de piel, marca y búsqueda |
| `/productos/<slug>` | Ficha del producto e ingredientes clave |

```bash
cd web
npm install          # primera vez
npm run dev          # desarrollo en http://localhost:3000
npm run build        # producción
systemctl status seoulglow
journalctl -u seoulglow -f
```

Detalles de despliegue en [`CONTEXTO_UBUNTU.md` §8.1](CONTEXTO_UBUNTU.md) y
[`PLAN_WEB_NEXTJS.md`](PLAN_WEB_NEXTJS.md).

## Modelo en una imagen

```
categorias ─┐
marcas ─────┼──▶ productos ──▶ producto_imagenes
            │        │
ingredientes┴──▶ producto_ingredientes
                     │
clientes ──▶ pedidos ──▶ pedido_detalles
                │
usuarios ───────┴──▶ movimientos_inventario ◀── productos
```

> Las credenciales incluidas son de demostración para el trabajo académico.
> No usarlas en un entorno real.
