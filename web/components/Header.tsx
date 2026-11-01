import Link from "next/link";

export function Header() {
  return (
    <header className="sticky top-0 z-40 border-b border-line/80 bg-paper/85 backdrop-blur-md">
      <div className="contenedor flex h-16 items-center justify-between gap-6">
        <Link href="/" className="flex items-baseline gap-2">
          <span className="font-display text-xl tracking-tight">Seoul Glow</span>
          <span className="text-[9px] uppercase tracking-[0.28em] text-muted">
            K-Beauty
          </span>
        </Link>

        <nav className="flex items-center gap-6 text-sm">
          <Link
            href="/productos"
            className="transition-colors hover:text-clay"
          >
            Catálogo
          </Link>
          <Link
            href="/#categorias"
            className="hidden transition-colors hover:text-clay sm:inline"
          >
            Categorías
          </Link>
          <Link
            href="/#marcas"
            className="hidden transition-colors hover:text-clay sm:inline"
          >
            Marcas
          </Link>
        </nav>

        <Link
          href="/productos"
          className="hidden items-center gap-2 border border-ink px-4 py-2 text-[11px] uppercase tracking-[0.18em] transition-colors hover:bg-ink hover:text-paper md:inline-flex"
        >
          Ver catálogo
        </Link>
      </div>
    </header>
  );
}
