/** Utilidades de formato compartidas por servidor y cliente. */

export function formatoPrecio(valor: number): string {
  return `$${valor.toFixed(2)}`;
}

export function tipoPielLista(tipo: string | null | undefined): string[] {
  if (!tipo) return [];
  return tipo
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean);
}

export const TIPO_PIEL_ETIQUETA: Record<string, string> = {
  seca: "Piel seca",
  grasa: "Piel grasa",
  mixta: "Piel mixta",
  sensible: "Piel sensible",
  normal: "Piel normal",
};

export function porcentajeDescuento(
  precio: number,
  oferta: number | null,
): number | null {
  if (!oferta || oferta >= precio) return null;
  return Math.round((1 - oferta / precio) * 100);
}
