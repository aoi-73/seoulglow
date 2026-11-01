# Plan de la página web — Next.js sobre Ubuntu 26 + Apache

> **Proyecto:** Seoul Glow (K-Beauty) · **Caso:** página web para una empresa usando Ubuntu 26 como servidor.
> **Decisión del equipo:** frontend/backend con **Next.js (App Router)**, servido detrás de **Apache** como reverse proxy.
> **Base de datos:** MariaDB `seoulglow_db` (ver `PLAN_BASE_DATOS.md`).
> **Complemento:** aplicación de escritorio en Apache NetBeans (Windows) que administra la misma base por JDBC.

---

## 1. Aclaración clave: quién habla con quién

Con Next.js el reparto de responsabilidades cambia respecto a un stack PHP:

```
┌─────────────────────────── Ubuntu 26 (VM) ───────────────────────────┐
│                                                                      │
│  Navegador ──HTTP:80──▶ Apache 2.4 ──proxy──▶ Next.js (Node) :3000  │
│                             │                       │                │
│                             │                       │ PDO/MySQL      │
│                             │                       ▼                │
│                             │                  MariaDB :3306         │
│                             │                  (localhost)           │
│                             └── sirve /public, logs                 │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │ JDBC :3306 (red Host-only)
                     App NetBeans / DBeaver (Windows)
```

**Tres ideas que hay que tener claras para la exposición:**

1. **Apache no consulta la base.** Apache termina HTTP, sirve estáticos y reenvía todo a Node. Si Apache se cae, la web no responde aunque Node esté vivo (y viceversa).
2. **Next.js corre en el servidor**, no en el navegador. Los *Server Components* se ejecutan en Node, así que pueden abrir conexiones a MariaDB sin exponer credenciales. Esto es lo que hace que Next.js sea seguro aquí.
3. **La única conexión remota a MariaDB es la de Windows** (NetBeans/DBeaver). La web entra por `localhost`, por eso su usuario **no** necesita `@'192.168.1.%'`.

> Regla de oro: el código que corre en el navegador (`"use client"`) **nunca** importa el pool de conexiones. Solo los Server Components, Server Actions y Route Handlers tocan la base.

---

## 2. Arquitectura de la aplicación

### 2.1 Stack

| Capa | Tecnología | Versión sugerida |
|---|---|---|
| Runtime | Node.js LTS | 22 o 24 (`node -v`) |
| Framework | Next.js App Router | última estable (`npm view next version`) |
| Lenguaje | TypeScript | 5.x |
| Estilos | Tailwind CSS | 4.x (viene con `create-next-app`) |
| Driver BD | `mysql2` (promise API) | 3.x |
| Proxy | Apache 2.4 + `mod_proxy_http` | el del sistema |
| Proceso | `systemd` | nativo de Ubuntu |
| BD | MariaDB | 10.11 / 11.x |

> `mysql2` funciona sin problemas contra MariaDB y es más simple que el paquete `mariadb` para este caso. Se instala con `npm i mysql2`.

### 2.2 Estructura del proyecto

```
/var/www/seoulglow/
├── app/
│   ├── layout.tsx                 # header, footer, fuentes, metadata global
│   ├── page.tsx                   # home: destacados + categorías
│   ├── globals.css
│   ├── productos/
│   │   ├── page.tsx               # catálogo con filtros (searchParams)
│   │   └── [slug]/
│   │       └── page.tsx           # ficha de producto + generateMetadata
│   ├── categorias/
│   │   └── [slug]/page.tsx        # catálogo filtrado por categoría
│   ├── api/
│   │   └── productos/route.ts     # JSON opcional (buscador en vivo)
│   ├── not-found.tsx
│   └── error.tsx
├── components/
│   ├── ProductoCard.tsx
│   ├── Filtros.tsx                # "use client"
│   ├── Galeria.tsx                # "use client"
│   ├── Header.tsx / Footer.tsx
│   └── Precio.tsx
├── lib/
│   ├── db.ts                      # pool de conexiones (server-only)
│   ├── queries.ts                 # funciones de consulta tipadas
│   └── types.ts                   # interfaces Producto, Categoria, ...
├── public/
│   └── img/productos/             # imágenes locales (recomendado)
├── .env.local                     # secretos (NO se sube a git)
├── .env.example                   # plantilla sin valores
├── next.config.ts
├── package.json
└── tsconfig.json
```

### 2.3 Rutas y qué hace cada una

| Ruta | Tipo | Consulta | Caché |
|---|---|---|---|
| `/` | Server Component | destacados + categorías | `revalidate = 300` |
| `/productos` | Server Component + `searchParams` | catálogo con filtros (`?cat=&marca=&piel=&q=`) | `revalidate = 60` |
| `/productos/[slug]` | Server Component | ficha, ingredientes, imágenes | `revalidate = 60` |
| `/categorias/[slug]` | Server Component | catálogo por categoría | `revalidate = 60` |
| `/api/productos` | Route Handler (GET) | JSON para el buscador en vivo | `dynamic = 'force-dynamic'` |

> **Decisión:** el catálogo se renderiza en el servidor (SEO + rapidez) y los filtros viajan por la URL (`searchParams`). Así el botón "atrás" del navegador funciona y no hace falta estado global. El `route.ts` es opcional, solo para el autocompletado del buscador.

---

## 3. Capa de datos

### 3.1 Pool de conexiones — `lib/db.ts`

```ts
import mysql from 'mysql2/promise';

// Una sola instancia por proceso Node. Next.js reutiliza el módulo entre requests.
export const pool = mysql.createPool({
  host: process.env.DB_HOST ?? '127.0.0.1',
  port: Number(process.env.DB_PORT ?? 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  charset: 'utf8mb4',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  decimalNumbers: true, // DECIMAL(12,2) llega como number, no como string
  dateStrings: true,
  timezone: 'Z',
});
```

Notas técnicas:
- `127.0.0.1` en lugar de `localhost` evita que el driver intente socket Unix cuando no corresponde.
- `connectionLimit: 10` es suficiente; MariaDB por defecto acepta 151 conexiones.
- El pool se crea una vez por proceso. En `next dev` con HMR puede recrearse; no es un problema en producción.

### 3.2 Consultas — `lib/queries.ts`

```ts
import { pool } from './db';
import type { Producto, Categoria } from './types';

export async function getDestacados(limit = 8): Promise<Producto[]> {
  const [rows] = await pool.query(
    `SELECT * FROM v_catalogo_web
      WHERE destacado = 1
      ORDER BY nombre
      LIMIT ?`,
    [limit],
  );
  return rows as Producto[];
}

export async function getCatalogo(filtros: {
  categoria?: string;
  marca?: string;
  piel?: string;
  q?: string;
}): Promise<Producto[]> {
  const where: string[] = [];
  const params: unknown[] = [];

  if (filtros.categoria) { where.push('categoria_slug = ?'); params.push(filtros.categoria); }
  if (filtros.marca)     { where.push('marca = ?');         params.push(filtros.marca); }
  if (filtros.piel)      { where.push('FIND_IN_SET(?, tipo_piel)'); params.push(filtros.piel); }
  if (filtros.q)         { where.push('(nombre LIKE ? OR descripcion_corta LIKE ?)');
                           params.push(`%${filtros.q}%`, `%${filtros.q}%`); }

  const sql = `SELECT * FROM v_catalogo_web
               ${where.length ? 'WHERE ' + where.join(' AND ') : ''}
               ORDER BY destacado DESC, nombre`;
  const [rows] = await pool.query(sql, params);
  return rows as Producto[];
}

export async function getProductoPorSlug(slug: string) {
  const [rows] = await pool.query(
    `SELECT * FROM v_catalogo_web WHERE slug = ? LIMIT 1`, [slug]);
  if (!rows.length) return null;

  const producto = rows[0] as Producto;
  const [ingredientes] = await pool.query(
    `SELECT i.nombre, i.beneficio, pi.porcentaje, pi.es_clave
       FROM producto_ingredientes pi
       JOIN ingredientes i USING (id_ingrediente)
      WHERE pi.id_producto = ?
      ORDER BY pi.es_clave DESC, i.nombre`,
    [producto.id_producto],
  );
  const [imagenes] = await pool.query(
    `SELECT url, alt_text FROM producto_imagenes
      WHERE id_producto = ? ORDER BY es_principal DESC, orden`,
    [producto.id_producto],
  );
  return { ...producto, ingredientes, imagenes };
}
```

**Siempre `?` (placeholders).** Nunca concatenar `searchParams` en el SQL: es la puerta de entrada a inyección SQL, y es una pregunta casi segura en la exposición.

### 3.3 Variables de entorno

`.env.local` (permisos `600`, nunca en git):

```ini
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=seoulglow_db
DB_USER=web_skincare
DB_PASSWORD=WebSkincare2026!
NEXT_PUBLIC_SITE_URL=http://192.168.1.10
```

`.env.example` (sí se sube):

```ini
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=seoulglow_db
DB_USER=web_skincare
DB_PASSWORD=cambiar
NEXT_PUBLIC_SITE_URL=http://localhost
```

> Solo las variables con prefijo `NEXT_PUBLIC_` llegan al navegador. **Las credenciales no llevan ese prefijo**, así que jamás se filtran al cliente.

---

## 4. Páginas y componentes

### 4.1 Ficha de producto con SEO

```tsx
// app/productos/[slug]/page.tsx
import { notFound } from 'next/navigation';
import { getProductoPorSlug } from '@/lib/queries';

export const revalidate = 60;

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const p = await getProductoPorSlug(slug);
  if (!p) return { title: 'Producto no encontrado' };
  return {
    title: `${p.nombre} — ${p.marca} | Seoul Glow`,
    description: p.descripcion_corta ?? `Compra ${p.nombre} de ${p.marca} en Seoul Glow.`,
    openGraph: { images: p.imagen_principal ? [p.imagen_principal] : [] },
  };
}

export default async function ProductoPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const producto = await getProductoPorSlug(slug);
  if (!producto) notFound();
  // ...render
}
```

> En Next.js 15+ `params` es una `Promise`: hay que `await params`. Es el error más común al copiar ejemplos viejos.

### 4.2 Filtros sin recargar la página

`components/Filtros.tsx` con `"use client"` + `useRouter` + `useSearchParams`, actualizando la query string. El servidor vuelve a renderizar el catálogo con los nuevos `searchParams`. No hay que inventar estado ni API para esto.

### 4.3 Imágenes

- **Recomendado:** guardar las fotos en `public/img/productos/` y que `producto_imagenes.url` guarde `/img/productos/cosrx-snail-96.webp`. Cero configuración y cero dependencia externa (importante si la VM no tiene internet en la exposición).
- Si usan URLs externas, declararlas en `next.config.ts`:

```ts
const nextConfig = {
  images: {
    remotePatterns: [{ protocol: 'https', hostname: 'images.unsplash.com' }],
  },
};
export default nextConfig;
```

### 4.4 Caché y stock

| Estrategia | Efecto | Cuándo usarla |
|---|---|---|
| `revalidate = 60` | La página se regenera como máximo cada 60 s | Catálogo y ficha (recomendado) |
| `dynamic = 'force-dynamic'` | Consulta la BD en cada request | Si el stock debe ser exacto al segundo |
| `revalidatePath('/productos')` | Invalida al instante tras un cambio | Si más adelante agregan panel admin |

**Para la demo:** `revalidate = 60` en catálogo y `force-dynamic` en la ficha del producto. Así se ve stock real y el catálogo sigue siendo rápido.

---

## 5. Apache como reverse proxy (Ubuntu)

### 5.1 Módulos necesarios

```bash
sudo a2enmod proxy proxy_http headers rewrite
sudo systemctl restart apache2
```

### 5.2 VirtualHost

`/etc/apache2/sites-available/seoulglow.conf`:

```apache
<VirtualHost *:80>
    ServerName seoulglow.local
    ServerAlias 192.168.1.10

    ProxyPreserveHost On
    ProxyRequests Off

    # Todo va a Next.js, que escucha SOLO en loopback
    ProxyPass        / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/

    # Cabeceras para que Next.js sepa el host/protocolo reales
    RequestHeader set X-Forwarded-Proto "http"

    <Proxy *>
        Require all granted
    </Proxy>

    ErrorLog  ${APACHE_LOG_DIR}/seoulglow_error.log
    CustomLog ${APACHE_LOG_DIR}/seoulglow_access.log combined
</VirtualHost>
```

Activar:

```bash
sudo a2ensite seoulglow.conf
sudo a2dissite 000-default.conf      # opcional, para que la home sea la tienda
sudo apache2ctl configtest
sudo systemctl reload apache2
```

**Detalles que rompen la configuración si se ignoran:**

| Detalle | Por qué importa |
|---|---|
| Barra final en `ProxyPass / http://127.0.0.1:3000/` | Sin ella, las rutas se concatenan mal (`/productos` → `/productos` vs `/productos/`) |
| `ProxyPreserveHost On` | Next.js genera URLs absolutas y redirecciones con el host correcto |
| `ProxyRequests Off` | Evita que Apache quede como proxy abierto |
| Node en `127.0.0.1`, no `0.0.0.0` | Nadie puede saltarse Apache entrando al puerto 3000 |
| `a2enmod proxy_http` | Sin este módulo, `ProxyPass` da 503 |

### 5.3 WebSocket solo para desarrollo (opcional)

El *hot reload* de `next dev` usa WebSocket. Si van a desarrollar contra el Apache de la VM, agregar dentro del VirtualHost:

```apache
RewriteEngine On
RewriteCond %{HTTP:Upgrade} =websocket [NC]
RewriteRule /(.*) ws://127.0.0.1:3000/$1 [P,L]
```

En producción (`next start`) **no hace falta**: no hay HMR.

### 5.4 HTTPS (opcional, suma puntos)

```bash
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d seoulglow.local
```

Certbot reescribe el VirtualHost y agrega el redirect 80 → 443. Con IP y sin dominio real no es imprescindible; mencionarlo en la exposición demuestra criterio.

---

## 6. Ejecutar Next.js como servicio (systemd)

Sin esto, la web muere cuando se cierra la terminal o se reinicia la VM.

`/etc/systemd/system/seoulglow.service`:

```ini
[Unit]
Description=Seoul Glow - Next.js
After=network.target mariadb.service
Wants=mariadb.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/seoulglow
Environment=NODE_ENV=production
Environment=PORT=3000
Environment=HOSTNAME=127.0.0.1
EnvironmentFile=/var/www/seoulglow/.env.local
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now seoulglow
sudo systemctl status seoulglow
journalctl -u seoulglow -f          # logs en vivo
```

`package.json` debe tener:

```json
"scripts": {
  "dev": "next dev",
  "build": "next build",
  "start": "next start -H 127.0.0.1 -p 3000"
}
```

### Alternativa: `output: 'standalone'`

Reduce el tamaño del despliegue (no necesita `node_modules` completo). En `next.config.ts`:

```ts
const nextConfig = { output: 'standalone' };
```

Luego hay que copiar `.next/static` y `public` dentro de `.next/standalone` y ejecutar `node .next/standalone/server.js`. **Para el trabajo no es necesario**; `npm run start` es más simple de explicar y de depurar.

---

## 7. Despliegue paso a paso

### 7.1 Instalar Node.js

```bash
# Opción A: NodeSource (recomendada para servidor)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node -v && npm -v

# Opción B: nvm (mejor si van a manejar varias versiones)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc && nvm install --lts
```

> Si usan nvm, la ruta de `node` en el servicio systemd cambia (queda en `~/.nvm/...`). Para el servidor conviene NodeSource, que instala en `/usr/bin/node`.

### 7.2 Crear el proyecto

```bash
cd /var/www
sudo mkdir seoulglow && sudo chown -R $USER:www-data seoulglow
cd seoulglow
npx create-next-app@latest . --ts --tailwind --eslint --app --src-dir=false --import-alias "@/*"
npm i mysql2
```

### 7.3 Configurar la base y probar la conexión

```bash
nano .env.local     # credenciales de web_skincare
chmod 600 .env.local
```

Prueba aislada antes de tocar Next.js:

```bash
node -e "
const mysql=require('mysql2/promise');
require('dotenv').config();
mysql.createConnection({host:'127.0.0.1',user:'web_skincare',password:'WebSkincare2026!',database:'seoulglow_db'})
 .then(c=>c.query('SELECT COUNT(*) n FROM v_catalogo_web'))
 .then(([r])=>{console.log('Productos:',r[0].n);process.exit(0)})
 .catch(e=>{console.error(e.message);process.exit(1)});
"
```

### 7.4 Build y arranque

```bash
npm run build
npm run start        # prueba manual en http://127.0.0.1:3000
```

Si responde bien, pasar a systemd (§6) y a Apache (§5).

### 7.5 Permisos

```bash
sudo chown -R www-data:www-data /var/www/seoulglow
sudo chmod 600 /var/www/seoulglow/.env.local
```

> Compilar como `www-data` (`sudo -u www-data npm run build`) evita archivos de `.next` con dueño incorrecto. Si compilan como su usuario, ajustar el dueño después.

---

## 8. Ajustes en la base de datos para este stack

### 8.1 Usuario de la web

Como Next.js corre **en la misma máquina**, el usuario es `@'localhost'` (más seguro: no acepta conexiones remotas).

```sql
CREATE USER 'web_skincare'@'localhost' IDENTIFIED BY 'WebSkincare2026!';
GRANT SELECT ON seoulglow_db.v_catalogo_web       TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.producto_imagenes     TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.producto_ingredientes TO 'web_skincare'@'localhost';
GRANT SELECT ON seoulglow_db.ingredientes          TO 'web_skincare'@'localhost';
FLUSH PRIVILEGES;
```

### 8.2 Lo que sigue igual

- `admin_skincare`@`192.168.1.%` → DBeaver y NetBeans desde Windows (CRUD).
- `bind-address = 0.0.0.0` → sigue siendo necesario **solo** por la app de escritorio.
- `ufw allow from 192.168.1.0/24 to any port 3306` → solo para Windows.

### 8.3 Ajuste recomendado en la vista

Para que los filtros sean eficientes, agregar `id_marca` y `id_categoria` a `v_catalogo_web` (hoy devuelve los nombres). Así el filtro por marca usa el id y no un `LIKE` sobre texto:

```sql
CREATE OR REPLACE VIEW v_catalogo_web AS
SELECT p.id_producto, p.sku, p.nombre, p.slug, p.descripcion_corta,
       p.id_marca, m.nombre AS marca,
       p.id_categoria, c.nombre AS categoria, c.slug AS categoria_slug,
       COALESCE(p.precio_oferta, p.precio) AS precio_efectivo,
       p.precio, p.precio_oferta, p.moneda,
       p.stock, p.volumen_ml, p.tipo_piel, p.destacado,
       (SELECT i.url FROM producto_imagenes i
         WHERE i.id_producto = p.id_producto
         ORDER BY i.es_principal DESC, i.orden ASC LIMIT 1) AS imagen_principal
FROM productos p
JOIN marcas m     ON m.id_marca = p.id_marca
JOIN categorias c ON c.id_categoria = p.id_categoria
WHERE p.activo = 1 AND m.activa = 1 AND c.activa = 1;
```

---

## 9. Desarrollo: Windows vs Ubuntu

| Escenario | Cómo | Ventaja / riesgo |
|---|---|---|
| **A. Desarrollar en Ubuntu** (recomendado) | VS Code con *Remote SSH* o editar por SSH | Mismo entorno que producción; sin sorpresas de rutas ni mayúsculas |
| B. Desarrollar en Windows | `next dev` local, `DB_HOST=192.168.1.10`, usuario `admin_skincare` o un `web_dev@192.168.1.%` | Cómodo, pero hay que crear un usuario extra y el build final se hace igual en Ubuntu |
| C. Solo copiar archivos | Editar en Windows y subir con `scp`/FileZilla | Funciona, pero se pierde el HMR |

> **Ojo con Linux:** las rutas distinguen mayúsculas. `ProductoCard.tsx` importado como `productocard` funciona en Windows y falla en Ubuntu. Es el error clásico del día anterior a la entrega.

---

## 10. Pruebas y criterios de aceptación

### 10.1 Pruebas por capa

```bash
# 1. ¿MariaDB responde y el usuario web ve datos?
mysql -u web_skincare -p -h 127.0.0.1 seoulglow_db -e "SELECT COUNT(*) FROM v_catalogo_web;"

# 2. ¿Next.js responde directo?
curl -I http://127.0.0.1:3000/
curl -s http://127.0.0.1:3000/api/productos | head -c 300

# 3. ¿El servicio está activo y sobrevive a un reinicio?
sudo systemctl is-enabled seoulglow && sudo systemctl restart seoulglow
sleep 3 && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000/

# 4. ¿Apache hace el proxy?
curl -I http://192.168.1.10/
sudo tail -f /var/log/apache2/seoulglow_error.log

# 5. ¿Responde desde Windows?
# PowerShell: Invoke-WebRequest http://192.168.1.10/ -UseBasicParsing | Select StatusCode
```

### 10.2 Definition of Done (punto 4 del caso)

- [ ] La home muestra productos que existen en `productos` (verificable cambiando un nombre en DBeaver y recargando).
- [ ] `/productos` filtra por categoría, marca y tipo de piel vía URL.
- [ ] `/productos/[slug]` muestra marca, precio, stock, imágenes e ingredientes clave.
- [ ] El buscador devuelve resultados sin recargar la página.
- [ ] El sitio se ve bien en móvil (Tailwind `sm/md/lg`).
- [ ] `systemctl status seoulglow` → `active (running)` tras reiniciar la VM.
- [ ] `http://<ip-vm>/` funciona desde Windows.
- [ ] El usuario `web_skincare` **no** puede hacer `INSERT/UPDATE/DELETE` (demostrarlo en la exposición).
- [ ] Las credenciales no aparecen en el bundle: `grep -r "WebSkincare2026" .next/static` no devuelve nada.

---

## 11. Problemas comunes (y su causa real)

| Síntoma | Causa | Solución |
|---|---|---|
| Apache devuelve **503** | `mod_proxy_http` no habilitado o Node caído | `a2enmod proxy_http`, `systemctl status seoulglow` |
| **502** | Node no escucha en 3000 | Revisar `PORT`/`HOSTNAME` y `journalctl -u seoulglow` |
| Página carga sin estilos | `ProxyPass` sin barra final | Corregir a `http://127.0.0.1:3000/` |
| `ECONNREFUSED 127.0.0.1:3306` | MariaDB caída o socket mal | `systemctl status mariadb` |
| `Access denied for user 'web_skincare'@'localhost'` | Usuario creado con otro host (`%` vs `localhost`) | `SELECT user,host FROM mysql.user;` y recrear |
| `ER_ACCESS_DENIED` desde Windows pero no desde Ubuntu | `bind-address` o `ufw` | Ver §7 del plan de BD |
| Falla el build solo en Ubuntu | Mayúsculas en imports | Renombrar imports exactos |
| `params` es una Promise | Next.js 15+ | `const { slug } = await params;` |
| Cambios de la app de escritorio no se ven en la web | Caché ISR | Esperar `revalidate` o `revalidatePath` |
| El servicio muere al cerrar SSH | Se lanzó con `npm run dev` | Usar systemd (§6) |

---

## 12. Cronograma sugerido

| # | Tarea | Tiempo |
|---|---|---|
| 1 | `01_schema.sql` + `02_seed.sql` en DBeaver | 1.5 h |
| 2 | Vistas, procedimientos, triggers y usuarios | 1 h |
| 3 | Crear proyecto Next.js, `lib/db.ts`, probar conexión | 1 h |
| 4 | Home + catálogo + tarjeta de producto | 2 h |
| 5 | Ficha de producto + ingredientes + metadata | 1.5 h |
| 6 | Filtros y buscador | 1.5 h |
| 7 | Estilos responsive con Tailwind | 2 h |
| 8 | Apache + systemd + pruebas desde Windows | 1.5 h |
| 9 | App NetBeans (JDBC) | 6–8 h |
| 10 | Ensayo de exposición y capturas | 1 h |

---

## 13. Guion para la exposición (punto 4)

1. Mostrar el diagrama: **navegador → Apache → Next.js → MariaDB**.
2. Abrir DBeaver y cambiar el nombre de un producto; recargar la web y mostrar el cambio (o explicar el `revalidate`).
3. Enseñar `lib/db.ts`: "la conexión vive en el servidor, el navegador nunca ve la contraseña".
4. Intentar un `INSERT` con `web_skincare` y mostrar el error de permisos → demuestra defensa en profundidad.
5. Mostrar `systemctl status seoulglow` y el acceso desde Windows.
6. Cerrar con la app de NetBeans gestionando la misma base: "un solo modelo de datos, dos clientes".

---

## 14. Decisiones pendientes

1. ¿Dominio o solo IP para `ServerName`? (por defecto `seoulglow.local` + IP).
2. ¿Imágenes locales en `public/` o URLs externas? (recomendado: locales, funciona sin internet).
3. ¿La web tendrá carrito y pedidos? Si sí, se agregan Server Actions que llamen a `sp_registrar_pedido`.
4. ¿Se despliega con `npm run start` (simple) o `output: 'standalone'` (optimizado)?
5. ¿HTTPS con Certbot o solo HTTP para la demo?
