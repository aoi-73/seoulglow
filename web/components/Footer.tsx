import Link from "next/link";

export function Footer() {
  return (
    <footer className="mt-24 border-t border-line">
      <div className="contenedor grid gap-10 py-14 md:grid-cols-3">
        <div>
          <p className="font-display text-2xl">Seoul Glow</p>
          <p className="mt-3 max-w-xs text-sm leading-relaxed text-muted">
            Skincare coreano seleccionado. Fórmulas esenciales, ingredientes
            activos y rituales simples.
          </p>
        </div>

        <div className="text-sm">
          <p className="eyebrow">Explorar</p>
          <ul className="mt-4 space-y-2">
            <li>
              <Link href="/productos" className="hover:text-clay">
                Catálogo completo
              </Link>
            </li>
            <li>
              <Link href="/#categorias" className="hover:text-clay">
                Categorías
              </Link>
            </li>
            <li>
              <Link href="/#marcas" className="hover:text-clay">
                Marcas coreanas
              </Link>
            </li>
          </ul>
        </div>

        <div className="text-sm text-muted">
          <p className="eyebrow">Tienda</p>
          <p className="mt-4 leading-relaxed">
            Seúl · Corea del Sur
            <br />
            Precios en USD
          </p>
          <p className="mt-6 text-xs leading-relaxed">
            Proyecto académico — página web sobre Ubuntu 26 con Next.js,
            Apache y MariaDB.
          </p>
        </div>
      </div>

      <div className="border-t border-line">
        <div className="contenedor flex flex-col gap-2 py-6 text-[11px] uppercase tracking-[0.18em] text-muted sm:flex-row sm:items-center sm:justify-between">
          <span>© 2026 Seoul Glow</span>
          <span>Hecho en Ubuntu · Next.js + MariaDB</span>
        </div>
      </div>
    </footer>
  );
}
