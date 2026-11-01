import Link from "next/link";
import type { ReactNode } from "react";
import { TIPO_PIEL_ETIQUETA } from "@/lib/format";
import type { Categoria } from "@/lib/types";

type Parametros = Record<string, string | undefined>;

function hrefCon(base: Parametros, cambios: Parametros): string {
  const params = new URLSearchParams();

  for (const [clave, valor] of Object.entries({ ...base, ...cambios })) {
    if (valor) params.set(clave, valor);
  }

  const qs = params.toString();
  return qs ? `/productos?${qs}` : "/productos";
}

function Chip({
  href,
  activo,
  children,
}: {
  href: string;
  activo: boolean;
  children: ReactNode;
}) {
  return (
    <Link
      href={href}
      className={`inline-flex items-center border px-3 py-1.5 text-xs transition-colors ${
        activo
          ? "border-ink bg-ink text-paper"
          : "border-line text-ink-soft hover:border-ink"
      }`}
    >
      {children}
    </Link>
  );
}

export function FilterBar({
  categorias,
  actuales,
  total,
}: {
  categorias: Categoria[];
  actuales: Parametros;
  total: number;
}) {
  const pieles = Object.entries(TIPO_PIEL_ETIQUETA);

  return (
    <div className="space-y-6">
      <form action="/productos" method="get" className="flex items-center gap-3">
        {actuales.categoria && (
          <input type="hidden" name="cat" value={actuales.categoria} />
        )}
        {actuales.piel && (
          <input type="hidden" name="piel" value={actuales.piel} />
        )}
        <input
          type="search"
          name="q"
          defaultValue={actuales.q ?? ""}
          placeholder="Buscar por producto o marca…"
          className="w-full max-w-sm border-b border-line bg-transparent py-2 text-sm outline-none placeholder:text-muted focus:border-ink"
        />
        <button
          type="submit"
          className="text-[11px] uppercase tracking-[0.18em] text-muted transition-colors hover:text-ink"
        >
          Buscar
        </button>
      </form>

      <div className="space-y-3">
        <div className="flex flex-wrap items-center gap-2">
          <span className="eyebrow mr-2 w-20 shrink-0">Categoría</span>
          <Chip
            href={hrefCon(actuales, { cat: undefined })}
            activo={!actuales.categoria}
          >
            Todas
          </Chip>
          {categorias.map((c) => (
            <Chip
              key={c.slug}
              href={hrefCon(actuales, { cat: c.slug })}
              activo={actuales.categoria === c.slug}
            >
              {c.nombre}
            </Chip>
          ))}
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <span className="eyebrow mr-2 w-20 shrink-0">Tipo de piel</span>
          <Chip
            href={hrefCon(actuales, { piel: undefined })}
            activo={!actuales.piel}
          >
            Cualquiera
          </Chip>
          {pieles.map(([valor, etiqueta]) => (
            <Chip
              key={valor}
              href={hrefCon(actuales, { piel: valor })}
              activo={actuales.piel === valor}
            >
              {etiqueta}
            </Chip>
          ))}
        </div>

        {actuales.marca && (
          <div className="flex flex-wrap items-center gap-2">
            <span className="eyebrow mr-2 w-20 shrink-0">Marca</span>
            <Chip href={hrefCon(actuales, { marca: undefined })} activo>
              {actuales.marca} ×
            </Chip>
          </div>
        )}
      </div>

      <div className="flex items-center justify-between border-t border-line pt-4">
        <p className="text-xs text-muted">
          {total} {total === 1 ? "producto" : "productos"}
        </p>
        {(actuales.categoria || actuales.piel || actuales.marca || actuales.q) && (
          <Link
            href="/productos"
            className="text-[11px] uppercase tracking-[0.18em] text-muted underline underline-offset-4 transition-colors hover:text-ink"
          >
            Limpiar filtros
          </Link>
        )}
      </div>
    </div>
  );
}
