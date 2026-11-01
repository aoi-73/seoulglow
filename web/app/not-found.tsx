import Link from "next/link";

export default function NotFound() {
  return (
    <div className="contenedor flex min-h-[60vh] flex-col items-center justify-center py-24 text-center">
      <p className="eyebrow">404</p>
      <h1 className="mt-4 font-display text-4xl tracking-tight md:text-6xl">
        Esta página no existe
      </h1>
      <p className="mt-4 max-w-sm text-sm leading-relaxed text-muted">
        Puede que el producto se haya retirado del catálogo o que el enlace
        esté mal escrito.
      </p>
      <Link
        href="/productos"
        className="mt-8 inline-flex items-center gap-3 border border-ink px-6 py-3 text-[11px] uppercase tracking-[0.2em] transition-colors hover:bg-ink hover:text-paper"
      >
        Volver al catálogo
      </Link>
    </div>
  );
}
