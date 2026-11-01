import { pool } from "./db";
import type {
  Categoria,
  Estadisticas,
  Ingrediente,
  Marca,
  Producto,
  ProductoDetalle,
} from "./types";

/**
 * Todas las consultas usan placeholders (`?`). Nunca se concatena
 * entrada del usuario en el SQL.
 */

export async function getDestacados(limit = 4): Promise<Producto[]> {
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

  if (filtros.categoria) {
    where.push("categoria_slug = ?");
    params.push(filtros.categoria);
  }
  if (filtros.marca) {
    where.push("marca = ?");
    params.push(filtros.marca);
  }
  if (filtros.piel) {
    where.push("FIND_IN_SET(?, tipo_piel)");
    params.push(filtros.piel);
  }
  if (filtros.q) {
    where.push("(nombre LIKE ? OR descripcion_corta LIKE ? OR marca LIKE ?)");
    const patron = `%${filtros.q}%`;
    params.push(patron, patron, patron);
  }

  const sql = `SELECT * FROM v_catalogo_web
               ${where.length ? "WHERE " + where.join(" AND ") : ""}
               ORDER BY destacado DESC, nombre`;

  const [rows] = await pool.query(sql, params);
  return rows as Producto[];
}

export async function getProductoPorSlug(
  slug: string,
): Promise<ProductoDetalle | null> {
  const [rows] = await pool.query(
    `SELECT * FROM v_catalogo_web WHERE slug = ? LIMIT 1`,
    [slug],
  );

  const filas = rows as Producto[];
  if (filas.length === 0) return null;

  const producto = filas[0];

  const [ingredientes] = await pool.query(
    `SELECT i.nombre, i.beneficio, pi.porcentaje, pi.es_clave
       FROM producto_ingredientes pi
       JOIN ingredientes i USING (id_ingrediente)
      WHERE pi.id_producto = ?
      ORDER BY pi.es_clave DESC, i.nombre`,
    [producto.id_producto],
  );

  return {
    ...producto,
    ingredientes: ingredientes as Ingrediente[],
  };
}

export async function getCategorias(): Promise<Categoria[]> {
  const [rows] = await pool.query(
    `SELECT MIN(id_categoria) AS id_categoria,
            categoria        AS nombre,
            categoria_slug   AS slug,
            COUNT(*)         AS total
       FROM v_catalogo_web
      GROUP BY categoria, categoria_slug
      ORDER BY total DESC, nombre`,
  );
  return rows as Categoria[];
}

export async function getMarcas(): Promise<Marca[]> {
  const [rows] = await pool.query(
    `SELECT marca AS nombre, COUNT(*) AS total
       FROM v_catalogo_web
      GROUP BY marca
      ORDER BY marca`,
  );
  return rows as Marca[];
}

export async function getEstadisticas(): Promise<Estadisticas> {
  const [rows] = await pool.query(
    `SELECT COUNT(*)                            AS productos,
            COUNT(DISTINCT marca)               AS marcas,
            COUNT(DISTINCT categoria_slug)      AS categorias
       FROM v_catalogo_web`,
  );
  return (rows as Estadisticas[])[0];
}
