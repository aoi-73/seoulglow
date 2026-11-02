/**
 * Tipos de la capa de datos.
 *
 * Los nombres de campo coinciden con las columnas de `v_catalogo_web`,
 * así el resultado de `mysql2` se puede usar directamente.
 */

export type Producto = {
  id_producto: number;
  sku: string;
  nombre: string;
  slug: string;
  descripcion_corta: string | null;
  id_marca: number;
  marca: string;
  id_categoria: number;
  categoria: string;
  categoria_slug: string;
  precio_efectivo: number;
  precio: number;
  precio_oferta: number | null;
  moneda: string;
  stock: number;
  volumen_ml: number | null;
  tipo_piel: string | null;
  destacado: number;
  imagen_principal: string | null;
  id_imagen_principal: number | null;
  tiene_imagen: number;
  imagen_version: number | null;
};

export type Categoria = {
  id_categoria: number;
  nombre: string;
  slug: string;
  total: number;
};

export type Marca = {
  nombre: string;
  total: number;
};

export type Ingrediente = {
  nombre: string;
  beneficio: string | null;
  porcentaje: number | null;
  es_clave: number;
};

export type ProductoDetalle = Producto & {
  ingredientes: Ingrediente[];
};

export type Estadisticas = {
  productos: number;
  marcas: number;
  categorias: number;
};
