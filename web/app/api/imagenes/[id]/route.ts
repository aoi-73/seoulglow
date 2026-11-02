import { pool } from "@/lib/db";

/**
 * Sirve el binario de una imagen guardada en `producto_imagenes.imagen`.
 *
 * La app de escritorio (Java/JDBC) escribe el BLOB y aquí se devuelve tal cual.
 * La URL incluye `?v=<unix>`, así que se puede cachear de forma agresiva: si la
 * imagen cambia, `actualizado_en` cambia y también la URL.
 */

export const dynamic = "force-dynamic";

type FilaImagen = {
  imagen: Buffer;
  mime_type: string | null;
};

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;

  if (!/^\d+$/.test(id)) {
    return new Response("Imagen no encontrada", { status: 404 });
  }

  const [filas] = await pool.query(
    `SELECT imagen, mime_type
       FROM producto_imagenes
      WHERE id_imagen = ?
        AND imagen IS NOT NULL
      LIMIT 1`,
    [Number(id)],
  );

  const fila = (filas as FilaImagen[])[0];

  if (!fila?.imagen || fila.imagen.length === 0) {
    return new Response("Imagen no encontrada", { status: 404 });
  }

  const cuerpo = new Uint8Array(fila.imagen);

  return new Response(cuerpo, {
    status: 200,
    headers: {
      "Content-Type": fila.mime_type ?? "image/webp",
      "Content-Length": String(cuerpo.byteLength),
      "Cache-Control": "public, max-age=31536000, immutable",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
