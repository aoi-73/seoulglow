import type { Producto } from "./types";

/**
 * Decide de dónde sale la foto principal de un producto:
 *
 *   1. Si la fila tiene BLOB, se sirve desde la base: `/api/imagenes/<id>`.
 *      Se agrega `?v=<actualizado_en>` para invalidar la caché cuando la app
 *      de escritorio cambia la imagen.
 *   2. Si solo hay `url`, se usa la ruta local de `public/`.
 *   3. Si no hay ninguna, `ProductVisual` muestra el panel tipográfico.
 */
export function rutaImagen(
  producto: Pick<
    Producto,
    | "id_imagen_principal"
    | "tiene_imagen"
    | "imagen_principal"
    | "imagen_version"
  >,
): string | null {
  if (producto.tiene_imagen && producto.id_imagen_principal) {
    const version = producto.imagen_version ?? 0;
    return `/api/imagenes/${producto.id_imagen_principal}?v=${version}`;
  }

  return producto.imagen_principal;
}
