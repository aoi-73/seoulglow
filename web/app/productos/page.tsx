import type { Metadata } from "next";
import Link from "next/link";
import { FilterBar } from "@/components/FilterBar";
import { ProductCard } from "@/components/ProductCard";
import { getCatalogo, getCategorias } from "@/lib/queries";

export const metadata: Metadata = {
  title: "Catálogo",
  description:
    "Todos los productos de Seoul Glow: limpiadores, tónicos, esencias, sérums, hidratantes, mascarillas y protectores solares.",
};

type SearchParams = Promise<{
  cat?: string;
  piel?: string;
  marca?: string;
  q?: string;
}>;

export default async function ProductosPage({
  searchParams,
}: {
  searchParams: SearchParams;
}) {
  const filtros = await searchParams;

  const [productos, categorias] = await Promise.all([
    getCatalogo({
      categoria: filtros.cat,
      piel: filtros.piel,
      marca: filtros.marca,
      q: filtros.q,
    }),
    getCategorias(),
  ]);

  return (
    <div className="contenedor py-14 md:py-20">
      <div className="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
        <div>
          <p className="eyebrow">Catálogo</p>
          <h1 className="mt-3 font-display text-4xl tracking-tight md:text-6xl">
            Todos los esenciales
          </h1>
        </div>
        <p className="max-w-xs text-sm leading-relaxed text-muted">
          Filtra por categoría o tipo de piel. Cada producto incluye su marca,
          formato y precio en USD.
        </p>
      </div>

      <div className="mt-12">
        <FilterBar
          categorias={categorias}
          actuales={filtros}
          total={productos.length}
        />
      </div>

      {productos.length === 0 ? (
        <div className="mt-16 border-t border-line py-24 text-center">
          <p className="font-display text-2xl">Sin resultados</p>
          <p className="mt-3 text-sm text-muted">
            Prueba con otra categoría, otro tipo de piel u otro término.
          </p>
          <Link
            href="/productos"
            className="mt-8 inline-block border border-ink px-6 py-3 text-[11px] uppercase tracking-[0.2em] transition-colors hover:bg-ink hover:text-paper"
          >
            Ver todo
          </Link>
        </div>
      ) : (
        <div className="mt-10 grid gap-x-6 gap-y-12 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {productos.map((producto, i) => (
            <ProductCard
              key={producto.id_producto}
              producto={producto}
              priority={i < 4}
            />
          ))}
        </div>
      )}
    </div>
  );
}
