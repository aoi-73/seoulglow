import Link from "next/link";
import { Price } from "./Price";
import { ProductVisual } from "./ProductVisual";
import { porcentajeDescuento } from "@/lib/format";
import type { Producto } from "@/lib/types";

export function ProductCard({
  producto,
  priority = false,
}: {
  producto: Producto;
  priority?: boolean;
}) {
  const descuento = porcentajeDescuento(
    producto.precio,
    producto.precio_oferta,
  );
  const ultimas = producto.stock > 0 && producto.stock <= 5;

  return (
    <Link href={`/productos/${producto.slug}`} className="group block">
      <div className="relative aspect-[4/5] overflow-hidden border border-line bg-paper-deep">
        <ProductVisual
          src={producto.imagen_principal}
          alt={producto.nombre}
          marca={producto.marca}
          categoria={producto.categoria}
          categoriaSlug={producto.categoria_slug}
          sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
          priority={priority}
        />

        <div className="absolute inset-x-0 top-0 flex items-start justify-between p-3">
          {descuento !== null ? (
            <span className="bg-ink px-2 py-1 text-[10px] uppercase tracking-[0.16em] text-paper">
              -{descuento}%
            </span>
          ) : (
            <span />
          )}
          {ultimas && (
            <span className="border border-ink/20 bg-paper/85 px-2 py-1 text-[10px] uppercase tracking-[0.14em] text-ink-soft backdrop-blur">
              Últimas {producto.stock}
            </span>
          )}
        </div>
      </div>

      <div className="mt-4 flex items-start justify-between gap-4">
        <div className="min-w-0">
          <p className="text-[10px] uppercase tracking-[0.2em] text-muted">
            {producto.marca}
          </p>
          <h3 className="mt-1 font-display text-lg leading-snug text-ink decoration-1 underline-offset-4 group-hover:underline">
            {producto.nombre}
          </h3>
          {producto.volumen_ml && (
            <p className="mt-1 text-xs text-muted">{producto.volumen_ml} ml</p>
          )}
        </div>
        <Price precio={producto.precio} oferta={producto.precio_oferta} />
      </div>
    </Link>
  );
}
