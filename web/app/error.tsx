"use client";

import Link from "next/link";
import { useEffect } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="contenedor flex min-h-[60vh] flex-col items-center justify-center py-24 text-center">
      <p className="eyebrow">Error</p>
      <h1 className="mt-4 font-display text-4xl tracking-tight md:text-6xl">
        Algo no cargó bien
      </h1>
      <p className="mt-4 max-w-sm text-sm leading-relaxed text-muted">
        No pudimos leer el catálogo. Revisa la conexión con la base de datos e
        inténtalo de nuevo.
      </p>
      <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
        <button
          type="button"
          onClick={reset}
          className="inline-flex items-center gap-3 border border-ink px-6 py-3 text-[11px] uppercase tracking-[0.2em] transition-colors hover:bg-ink hover:text-paper"
        >
          Reintentar
        </button>
        <Link
          href="/"
          className="text-[11px] uppercase tracking-[0.2em] text-muted underline underline-offset-4 hover:text-ink"
        >
          Ir al inicio
        </Link>
      </div>
    </div>
  );
}
