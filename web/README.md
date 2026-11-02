# Seoul Glow — Web (Next.js)

Catálogo web de la tienda de skincare coreano. Consume `seoulglow_db`
(MariaDB) a través de la vista `v_catalogo_web`.

## Stack

- Next.js 16 (App Router) + TypeScript
- Tailwind CSS 4
- `mysql2` (pool de conexiones)
- Apache como reverse proxy (`127.0.0.1:3000`)
- `systemd` para mantener el proceso vivo

## Desarrollo

```bash
cp .env.example .env.local     # completar credenciales
npm install
npm run dev                    # http://localhost:3000
```

## Producción

```bash
npm run build
npm run start                  # escucha en 127.0.0.1:3000
```

La configuración de Apache y `systemd` está en
[`../PLAN_WEB_NEXTJS.md`](../PLAN_WEB_NEXTJS.md).

## Datos

- Usuario de MariaDB: `web_skincare@localhost` (solo `SELECT`).
- La foto principal sale, en este orden, de:
  1. `producto_imagenes.imagen` (BLOB) → `/api/imagenes/<id>?v=<actualizado_en>`.
  2. `producto_imagenes.url` → archivo en `public/img/productos/`.
  3. Panel tipográfico con el color de la categoría.
- Las fotos las sube la app Java (JDBC). Ver
  [`../GUIA_IMAGENES_JAVA.md`](../GUIA_IMAGENES_JAVA.md).

## Estructura

```
app/                    páginas (home, catálogo, ficha)
app/api/imagenes/[id]/  endpoint que sirve el BLOB
components/             tarjetas, header, footer, filtros
lib/                    pool, consultas, tipos, formato e imágenes
public/img/productos/   fotos locales (alternativa al BLOB)
```
