# Imágenes de productos desde la app Java

Guía para que la aplicación de escritorio (Windows, NetBeans, JDBC) pueda
**subir, reemplazar y borrar** las fotos de los productos sin SMB, SFTP ni un
servidor HTTP aparte.

La imagen se guarda **dentro de MariaDB** y la web la sirve en:

```
http://192.168.1.232/api/imagenes/<id_imagen>
```

---

## 1. Cómo está modelado

`producto_imagenes` tiene ahora tres columnas nuevas:

| Columna | Tipo | Para qué |
|---|---|---|
| `imagen` | `MEDIUMBLOB` | Bytes de la foto (hasta 16 MB) |
| `mime_type` | `VARCHAR(80)` | `image/webp`, `image/jpeg`, `image/png`… |
| `actualizado_en` | `DATETIME` | Se actualiza solo; la web lo usa para invalidar la caché |

`url` pasó a ser **opcional** (`NULL`): una fila puede existir solo como BLOB.
Si una fila tiene BLOB y `url`, la web **prefiere el BLOB**.

La vista `v_catalogo_web` expone además:

- `id_imagen_principal`: id de la foto principal.
- `tiene_imagen`: `1` si esa fila tiene BLOB.
- `imagen_version`: `UNIX_TIMESTAMP(actualizado_en)`.

Con eso la web construye `/api/imagenes/<id>?v=<version>`. Cuando la app cambia
la imagen, cambia la versión y el navegador descarga la nueva.

> Migración: `sql/07_imagenes_blob.sql` (ya aplicada en la VM).
> En instalaciones nuevas, `01_schema.sql` y `03_views.sql` ya la incluyen.

---

## 2. Conexión desde Windows

| Dato | Valor |
|---|---|
| URL JDBC | `jdbc:mariadb://192.168.1.232:3306/seoulglow_db` |
| Driver | `org.mariadb.jdbc.Driver` (`mariadb-java-client`) |
| Usuario | **`admin_skincare`** |
| Contraseña | `AdminSkincare2026!` |

`web_skincare` es **solo lectura** y `root` **no** debe usarse desde Windows.
`admin_skincare` tiene `INSERT`, `UPDATE` y `DELETE` sobre `seoulglow_db.*`.

```java
Class.forName("org.mariadb.jdbc.Driver");
Connection con = DriverManager.getConnection(
    "jdbc:mariadb://192.168.1.232:3306/seoulglow_db",
    "admin_skincare",
    "AdminSkincare2026!");
```

---

## 3. Código Java listo para adaptar

### 3.1 Reemplazar (o crear) la imagen principal de un producto

```java
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.sql.*;

public class ImagenProductoDAO {

    private final Connection con;

    public ImagenProductoDAO(Connection con) {
        this.con = con;
    }

    /**
     * Guarda el archivo como imagen principal del producto.
     * Si el producto ya tenía una principal, la reemplaza; si no, crea la fila.
     *
     * @return id_imagen guardado
     */
    public long guardarPrincipal(long idProducto, File archivo, String altText)
            throws SQLException, IOException {

        String mime = detectarMime(archivo);
        long idImagen = buscarPrincipal(idProducto);

        if (idImagen > 0) {
            String sql = """
                UPDATE producto_imagenes
                   SET imagen = ?, mime_type = ?, alt_text = ?,
                       es_principal = 1, orden = 0, url = NULL
                 WHERE id_imagen = ?
                """;
            try (PreparedStatement ps = con.prepareStatement(sql);
                 InputStream in = new FileInputStream(archivo)) {
                ps.setBinaryStream(1, in, archivo.length());
                ps.setString(2, mime);
                ps.setString(3, altText);
                ps.setLong(4, idImagen);
                ps.executeUpdate();
            }
            return idImagen;
        }

        String sql = """
            INSERT INTO producto_imagenes
                   (id_producto, url, imagen, mime_type, alt_text,
                    orden, es_principal)
            VALUES (?, NULL, ?, ?, ?, 0, 1)
            """;
        try (PreparedStatement ps = con.prepareStatement(
                 sql, Statement.RETURN_GENERATED_KEYS);
             InputStream in = new FileInputStream(archivo)) {
            ps.setLong(1, idProducto);
            ps.setBinaryStream(2, in, archivo.length());
            ps.setString(3, mime);
            ps.setString(4, altText);
            ps.executeUpdate();

            try (ResultSet rs = ps.getGeneratedKeys()) {
                rs.next();
                return rs.getLong(1);
            }
        }
    }

    /** Id de la foto principal actual (0 si el producto no tiene ninguna). */
    private long buscarPrincipal(long idProducto) throws SQLException {
        String sql = """
            SELECT id_imagen
              FROM producto_imagenes
             WHERE id_producto = ?
             ORDER BY es_principal DESC, orden ASC
             LIMIT 1
            """;
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setLong(1, idProducto);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getLong("id_imagen") : 0L;
            }
        }
    }

    private static String detectarMime(File archivo) throws IOException {
        String mime = Files.probeContentType(archivo.toPath());
        if (mime != null) return mime;

        String n = archivo.getName().toLowerCase();
        if (n.endsWith(".png"))  return "image/png";
        if (n.endsWith(".jpg") || n.endsWith(".jpeg")) return "image/jpeg";
        if (n.endsWith(".webp")) return "image/webp";
        if (n.endsWith(".gif"))  return "image/gif";
        return "application/octet-stream";
    }
}
```

Uso desde el botón «Cambiar foto»:

```java
File foto = selectorDeArchivos.getSelectedFile();

try (Connection con = ConexionBD.abrir()) {
    ImagenProductoDAO dao = new ImagenProductoDAO(con);
    long idImagen = dao.guardarPrincipal(idProducto, foto, nombreProducto);
    JOptionPane.showMessageDialog(this, "Imagen guardada (id " + idImagen + ")");
}
```

### 3.2 Leer la imagen para mostrarla en la app

```java
public byte[] leerImagen(long idImagen) throws SQLException {
    String sql = "SELECT imagen FROM producto_imagenes WHERE id_imagen = ?";
    try (PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setLong(1, idImagen);
        try (ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getBytes("imagen") : null;
        }
    }
}
```

```java
byte[] bytes = dao.leerImagen(idImagen);
if (bytes != null) {
    ImageIcon icono = new ImageIcon(bytes);
    etiquetaFoto.setIcon(new ImageIcon(
        icono.getImage().getScaledInstance(240, 300, java.awt.Image.SCALE_SMOOTH)));
}
```

### 3.3 Borrar una imagen

```java
try (PreparedStatement ps = con.prepareStatement(
        "DELETE FROM producto_imagenes WHERE id_imagen = ?")) {
    ps.setLong(1, idImagen);
    ps.executeUpdate();
}
```

---

## 4. Detalles que evitan problemas

| Tema | Recomendación |
|---|---|
| **Tamaño** | Usar fotos de **≤ 2 MB**. `MEDIUMBLOB` admite 16 MB, pero `max_allowed_packet` de MariaDB también limita el envío |
| **Formato** | `.webp` o `.jpg` de ~1000 px de ancho. La web las muestra con `object-cover` |
| **Una sola principal** | No hay índice único: si la app permite marcar otra, ejecutar `UPDATE producto_imagenes SET es_principal = 0 WHERE id_producto = ?` antes de marcar la nueva, dentro de la misma transacción |
| **`url`** | Al guardar un BLOB, poner `url = NULL`. Si se deja la ruta antigua no molesta, porque la web prefiere el BLOB |
| **Caché** | La URL cambia con `actualizado_en`, así que no hace falta «refrescar» nada. Si se mira una ficha ya abierta, recargar (F5) |
| **Transacciones** | Si se actualiza la principal y se desmarcan las demás, envolver ambas sentencias en `setAutoCommit(false)` / `commit()` |
| **Permisos** | Si aparece `UPDATE command denied`, la app está usando `web_skincare`. Cambiar a `admin_skincare` |

---

## 5. Verificar desde Windows o Ubuntu

```bash
# ¿La fila tiene bytes?
mariadb -h 192.168.1.232 -u admin_skincare -p seoulglow_db \
  -e "SELECT id_imagen, OCTET_LENGTH(imagen) AS bytes, mime_type
        FROM producto_imagenes WHERE id_imagen = 1;"

# ¿La web la sirve?
curl -I "http://192.168.1.232/api/imagenes/1"
# Debe responder 200 con content-type: image/webp (o el que corresponda)
```

En el navegador: `http://192.168.1.232/productos` — la tarjeta del producto
muestra la foto guardada. La home la refleja en ≤ 60 s (ISR); el catálogo y la
ficha la muestran de inmediato porque consultan en cada visita.

---

## 6. Errores frecuentes

| Error | Causa / solución |
|---|---|
| `UPDATE command denied to user 'web_skincare'` | Usar `admin_skincare` |
| `TLS/SSL error: certificate is not yet valid` | El reloj de la VM se desfasó; `sudo systemctl restart mariadb` |
| `Packet too large` | La foto supera `max_allowed_packet`; reducirla o subir el límite en MariaDB |
| La web sigue mostrando el panel tipográfico | `tiene_imagen = 0`; revisar que el `UPDATE` haya escrito `imagen` y `mime_type` |
| La imagen se ve borrosa | La foto original es muy pequeña; subir una de al menos 800 px de ancho |
| `url` no puede ser `NULL` | Falta aplicar `07_imagenes_blob.sql` (hace `MODIFY url ... NULL`) |
