# Seoul Glow — Base de datos y web (K-Beauty)

Proyecto académico: **página web para una empresa utilizando Ubuntu 26 como servidor**.

La empresa vende productos coreanos de skincare. La solución tiene tres clientes sobre
una misma base MariaDB:

| Componente | Dónde corre | Estado |
|---|---|---|
| Base de datos `seoulglow_db` | Ubuntu 26 | scripts listos |
| Página web (Next.js + Apache) | Ubuntu 26 | pendiente |
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
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_seed.sql
mysql -u root -p < sql/03_views.sql
mysql -u root -p < sql/04_routines.sql
mysql -u root -p < sql/05_users.sql
```

Requiere **MariaDB 10.6+** (se usa `JSON_TABLE`).

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
