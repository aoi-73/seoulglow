import Link from "next/link";
import { ProductCard } from "@/components/ProductCard";
import {
  getCategorias,
  getDestacados,
  getEstadisticas,
  getMarcas,
} from "@/lib/queries";

export const revalidate = 60;

export default async function Home() {
  const [destacados, categorias, marcas, stats] = await Promise.all([
    getDestacados(4),
    getCategorias(),
    getMarcas(),
    getEstadisticas(),
  ]);

  return (
    <>
      {/* Hero */}
      <section className="border-b border-line">
        <div className="contenedor grid gap-12 py-16 md:py-24 lg:grid-cols-12 lg:items-end">
          <div className="lg:col-span-7">
            <p className="eyebrow">K-Beauty · Curado en Seúl</p>
            <h1 className="mt-6 font-display text-5xl leading-[0.95] tracking-tight md:text-7xl">
              Rituales coreanos,
              <br />
              <span className="text-muted">sin ruido.</span>
            </h1>
            <p className="mt-8 max-w-md text-base leading-relaxed text-ink-soft">
              Una selección de fórmulas esenciales: ingredientes activos,
              texturas ligeras y una rutina que se siente como tu piel.
            </p>
            <div className="mt-10 flex flex-wrap items-center gap-6">
              <Link
                href="/productos"
                className="inline-flex items-center gap-3 bg-ink px-6 py-3 text-[11px] uppercase tracking-[0.2em] text-paper transition-colors hover:bg-ink-soft"
              >
                Explorar catálogo <span aria-hidden>→</span>
              </Link>
              <Link
                href="#destacados"
                className="text-[11px] uppercase tracking-[0.2em] text-muted underline underline-offset-4 transition-colors hover:text-ink"
              >
                Ver destacados
              </Link>
            </div>
          </div>

          <div className="lg:col-span-5">
            <div className="border border-line bg-paper-deep/50 p-8 md:p-10">
              <p className="eyebrow">En catálogo</p>
              <p className="mt-4 font-display text-7xl leading-none">
                {stats.productos}
              </p>
              <p className="mt-2 text-sm text-muted">fórmulas seleccionadas</p>

              <dl className="mt-8 grid grid-cols-2 gap-6 border-t border-line pt-6">
                <div>
                  <dt className="text-[10px] uppercase tracking-[0.2em] text-muted">
                    Casas coreanas
                  </dt>
                  <dd className="mt-2 font-display text-3xl leading-none">
                    {stats.marcas}
                  </dd>
                </div>
                <div>
                  <dt className="text-[10px] uppercase tracking-[0.2em] text-muted">
                    Categorías
                  </dt>
                  <dd className="mt-2 font-display text-3xl leading-none">
                    {stats.categorias}
                  </dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </section>

      {/* Marcas */}
      <section id="marcas" className="border-b border-line">
        <div className="contenedor flex flex-wrap items-center gap-x-8 gap-y-3 py-6">
          <span className="eyebrow">Marcas</span>
          {marcas.map((m) => (
            <Link
              key={m.nombre}
              href={`/productos?marca=${encodeURIComponent(m.nombre)}`}
              className="text-xs uppercase tracking-[0.16em] text-ink-soft transition-colors hover:text-clay"
            >
              {m.nombre}
            </Link>
          ))}
        </div>
      </section>

      {/* Destacados */}
      <section id="destacados" className="contenedor py-16 md:py-24">
        <div className="flex items-end justify-between gap-6">
          <div>
            <p className="eyebrow">Selección</p>
            <h2 className="mt-3 font-display text-4xl tracking-tight md:text-5xl">
              Destacados
            </h2>
          </div>
          <Link
            href="/productos"
            className="text-[11px] uppercase tracking-[0.2em] text-muted underline underline-offset-4 transition-colors hover:text-ink"
          >
            Ver todo
          </Link>
        </div>

        <div className="mt-10 grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-4">
          {destacados.map((producto, i) => (
            <ProductCard
              key={producto.id_producto}
              producto={producto}
              priority={i < 2}
            />
          ))}
        </div>
      </section>

      {/* Categorías */}
      <section id="categorias" className="border-t border-line">
        <div className="contenedor py-16 md:py-24">
          <div className="flex items-end justify-between gap-6">
            <div>
              <p className="eyebrow">Explorar</p>
              <h2 className="mt-3 font-display text-4xl tracking-tight md:text-5xl">
                Por categoría
              </h2>
            </div>
          </div>

          <div className="mt-10 grid gap-x-10 sm:grid-cols-2 lg:grid-cols-3">
            {categorias.map((c, i) => (
              <Link
                key={c.slug}
                href={`/productos?cat=${c.slug}`}
                className="group flex items-baseline gap-4 border-t border-line py-5"
              >
                <span className="w-6 shrink-0 text-[10px] tracking-[0.2em] text-muted">
                  {String(i + 1).padStart(2, "0")}
                </span>
                <span className="flex-1 font-display text-2xl tracking-tight transition-colors group-hover:text-clay">
                  {c.nombre}
                </span>
                <span className="text-xs text-muted">{c.total}</span>
              </Link>
            ))}
          </div>
        </div>
      </section>

      {/* Cierre */}
      <section className="bg-ink text-paper">
        <div className="contenedor flex flex-col items-start justify-between gap-8 py-16 md:flex-row md:items-center">
          <div>
            <p className="text-[11px] uppercase tracking-[0.22em] text-paper/60">
              Rutina simple
            </p>
            <h2 className="mt-3 font-display text-3xl md:text-4xl">
              Encuentra tu próximo esencial.
            </h2>
          </div>
          <Link
            href="/productos"
            className="inline-flex items-center gap-3 border border-paper/40 px-6 py-3 text-[11px] uppercase tracking-[0.2em] transition-colors hover:bg-paper hover:text-ink"
          >
            Ver catálogo completo <span aria-hidden>→</span>
          </Link>
        </div>
      </section>
    </>
  );
}
