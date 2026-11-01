import { formatoPrecio, porcentajeDescuento } from "@/lib/format";

type Props = {
  precio: number;
  oferta: number | null;
  className?: string;
};

export function Price({ precio, oferta, className = "" }: Props) {
  const descuento = porcentajeDescuento(precio, oferta);

  return (
    <div className={`text-right ${className}`}>
      <p className="font-display text-lg leading-none">
        {formatoPrecio(oferta ?? precio)}
      </p>
      {descuento !== null && (
        <p className="mt-1 text-[11px] text-muted line-through">
          {formatoPrecio(precio)}
        </p>
      )}
    </div>
  );
}
