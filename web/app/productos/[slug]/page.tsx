import type { Metadata } from "next";
import Link from "next/link";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { notFound } from "next/navigation";
import { ProductVisual } from "@/components/ProductVisual";
import {
  formatoPrecio,
  porcentajeDescuento,
  TIPO_PIEL_ETIQUETA,
  tipoPielLista,
} from "@/lib/format";
import { getProductoPorSlug } from "@/lib/queries";
import { rutaImagen } from "@/lib/imagenes";

export const revalidate = 60;

type Params = Promise<{ slug: string }>;

export async function generateMetadata({
  params,
}: {
  params: Params;
}): Promise<Metadata> {
  const { slug } = await params;
  const producto = await getProductoPorSlug(slug);

  if (!producto) return { title: "Producto no encontrado" };

  const imagen = rutaImagen(producto);
  // Solo anunciar la imagen si realmente se puede servir: BLOB o archivo local.
  const imagenDisponible = Boolean(
    imagen &&
      (imagen.startsWith("/api/imagenes/") ||
        existsSync(join(process.cwd(), "public", imagen))),
  );

  return {
    title: `${producto.nombre} — ${producto.marca}`,
    description:
      producto.descripcion_corta ??
      `Descubre ${producto.nombre} de ${producto.marca} en Seoul Glow.`,
    openGraph: {
      images: imagenDisponible && imagen ? [imagen] : [],
    },
  };
}

export default async function ProductoPage({ params }: { params: Params }) {
  const { slug } = await params;
  const producto = await getProductoPorSlug(slug);

  if (!producto) notFound();

  const descuento = porcentajeDescuento(
    producto.precio,
    producto.precio_oferta,
  );
  const pieles = tipoPielLista(producto.tipo_piel);

  return (
    <div className="contenedor py-10 md:py-14">
      {/* Migas */}
      <nav className="flex flex-wrap items-center gap-2 text-[11px] uppercase tracking-[0.16em] text-muted">
        <Link href="/" className="hover:text-ink">
          Inicio
        </Link>
        <span aria-hidden>/</span>
        <Link href="/productos" className="hover:text-ink">
          Catálogo
        </Link>
        <span aria-hidden>/</span>
        <Link
          href={`/productos?cat=${producto.categoria_slug}`}
          className="hover:text-ink"
        >
          {producto.categoria}
        </Link>
        <span aria-hidden>/</span>
        <span className="text-ink-soft">{producto.nombre}</span>
      </nav>

      <div className="mt-10 grid gap-10 lg:grid-cols-2 lg:gap-16">
        {/* Visual */}
        <div className="group relative aspect-[4/5] overflow-hidden border border-line bg-paper-deep">
          <ProductVisual
            src={rutaImagen(producto)}
            alt={producto.nombre}
            marca={producto.marca}
            categoria={producto.categoria}
            categoriaSlug={producto.categoria_slug}
            sizes="(max-width: 1024px) 100vw, 50vw"
            priority
          />
          {descuento !== null && (
            <span className="absolute left-4 top-4 bg-ink px-2.5 py-1 text-[10px] uppercase tracking-[0.16em] text-paper">
              -{descuento}%
            </span>
          )}
        </div>

        {/* Información */}
        <div className="flex flex-col">
          <p className="eyebrow">{producto.marca}</p>
          <h1 className="mt-3 font-display text-3xl leading-[1.05] tracking-tight md:text-5xl">
            {producto.nombre}
          </h1>

          {producto.descripcion_corta && (
            <p className="mt-5 max-w-prose text-base leading-relaxed text-ink-soft">
              {producto.descripcion_corta}
            </p>
          )}

          <div className="mt-8 flex flex-wrap items-end gap-4">
            <p className="font-display text-4xl leading-none">
              {formatoPrecio(producto.precio_efectivo)}
            </p>
            {descuento !== null && (
              <p className="text-sm text-muted line-through">
                {formatoPrecio(producto.precio)}
              </p>
            )}
            <span className="text-[10px] uppercase tracking-[0.18em] text-muted">
              {producto.moneda}
            </span>
          </div>

          <dl className="mt-10 divide-y divide-line border-y border-line text-sm">
            <div className="flex items-baseline justify-between gap-6 py-3">
              <dt className="text-muted">Categoría</dt>
              <dd>
                <Link
                  href={`/productos?cat=${producto.categoria_slug}`}
                  className="hover:text-clay"
                >
                  {producto.categoria}
                </Link>
              </dd>
            </div>
            {producto.volumen_ml && (
              <div className="flex items-baseline justify-between gap-6 py-3">
                <dt className="text-muted">Formato</dt>
                <dd>{producto.volumen_ml} ml</dd>
              </div>
            )}
            {pieles.length > 0 && (
              <div className="flex items-baseline justify-between gap-6 py-3">
                <dt className="text-muted">Tipo de piel</dt>
                <dd className="text-right">
                  {pieles
                    .map((p) => TIPO_PIEL_ETIQUETA[p] ?? p)
                    .join(" · ")}
                </dd>
              </div>
            )}
            <div className="flex items-baseline justify-between gap-6 py-3">
              <dt className="text-muted">Disponibilidad</dt>
              <dd>
                {producto.stock === 0
                  ? "Agotado"
                  : producto.stock <= 5
                    ? `Últimas ${producto.stock} unidades`
                    : "En stock"}
              </dd>
            </div>
            <div className="flex items-baseline justify-between gap-6 py-3">
              <dt className="text-muted">SKU</dt>
              <dd className="text-xs tracking-[0.12em] text-ink-soft">
                {producto.sku}
              </dd>
            </div>
          </dl>

          <div className="mt-8 border border-line bg-paper-deep/40 p-5">
            <p className="text-sm">Consulta disponibilidad en tienda</p>
            <p className="mt-1 text-xs leading-relaxed text-muted">
              Proyecto académico: la venta se registra desde la aplicación de
              escritorio conectada a la misma base de datos.
            </p>
          </div>

          <div className="mt-6 flex items-center justify-between gap-4 text-[11px] uppercase tracking-[0.16em] text-muted">
            <Link href="/productos" className="hover:text-ink">
              ← Volver al catálogo
            </Link>
          </div>
        </div>
      </div>

      {/* Ingredientes */}
      {producto.ingredientes.length > 0 && (
        <section className="mt-20 border-t border-line pt-12">
          <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="eyebrow">Fórmula</p>
              <h2 className="mt-3 font-display text-3xl tracking-tight md:text-4xl">
                Ingredientes clave
              </h2>
            </div>
            <p className="max-w-sm text-sm leading-relaxed text-muted">
              Activos que hacen la diferencia en este producto, según su
              concentración y función.
            </p>
          </div>

          <ul className="mt-10 grid gap-x-10 sm:grid-cols-2">
            {producto.ingredientes.map((ing) => (
              <li
                key={ing.nombre}
                className="flex items-baseline justify-between gap-6 border-t border-line py-5"
              >
                <div>
                  <p className="font-display text-xl">{ing.nombre}</p>
                  {ing.beneficio && (
                    <p className="mt-1 text-sm text-muted">{ing.beneficio}</p>
                  )}
                </div>
                {ing.porcentaje !== null && (
                  <span className="shrink-0 text-xs tracking-[0.12em] text-ink-soft">
                    {Number(ing.porcentaje).toFixed(0)}%
                  </span>
                )}
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
