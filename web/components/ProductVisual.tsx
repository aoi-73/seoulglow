import { existsSync } from "node:fs";
import { join } from "node:path";
import Image from "next/image";

/**
 * Si la fila tiene BLOB, la imagen se sirve desde `/api/imagenes/<id>`.
 * Si solo hay una ruta local en `public/`, se usa esa. Si no hay ninguna,
 * se muestra un panel tipográfico con el color de la categoría.
 *
 * Así la web se ve completa aunque todavía no se haya subido ninguna foto.
 */

const TINTE: Record<string, string> = {
  "esencias-serums": "bg-[#e7e9ee]",
  hidratantes: "bg-[#f1e7e3]",
  tonicos: "bg-[#edeae2]",
  mascarillas: "bg-[#ece7ef]",
  "serums-faciales": "bg-[#e6ebe6]",
  "protectores-solares": "bg-[#f2ecdd]",
  "contorno-ojos": "bg-[#eae7e0]",
  exfoliantes: "bg-[#ece6df]",
  kits: "bg-[#e4e8e2]",
  limpiadores: "bg-[#e8ede8]",
  "limpiadores-gel": "bg-[#e3eae5]",
  "mascarillas-tela": "bg-[#efe6ea]",
};

type Props = {
  src: string | null;
  alt: string;
  marca: string;
  categoria: string;
  categoriaSlug: string;
  sizes: string;
  priority?: boolean;
};

export function ProductVisual({
  src,
  alt,
  marca,
  categoria,
  categoriaSlug,
  sizes,
  priority = false,
}: Props) {
  // Las rutas /api/imagenes/* vienen de un BLOB: no existen en public/.
  const desdeBase = Boolean(src?.startsWith("/api/imagenes/"));
  const existe = Boolean(
    src && (desdeBase || existsSync(join(process.cwd(), "public", src))),
  );

  if (existe && src) {
    return (
      <Image
        src={src}
        alt={alt}
        fill
        sizes={sizes}
        priority={priority}
        // El BLOB ya está comprimido y el endpoint controla su propio caché.
        unoptimized={desdeBase}
        className="object-cover transition-transform duration-700 group-hover:scale-[1.03]"
      />
    );
  }

  return (
    <div
      className={`absolute inset-0 flex flex-col items-center justify-center px-6 text-center ${
        TINTE[categoriaSlug] ?? "bg-paper-deep"
      }`}
    >
      <span className="font-display text-3xl leading-tight text-ink/25 md:text-4xl">
        {marca}
      </span>
      <span className="mt-3 text-[10px] uppercase tracking-[0.24em] text-ink/35">
        {categoria}
      </span>
    </div>
  );
}
