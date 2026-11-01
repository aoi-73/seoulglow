import type { Metadata } from "next";
import { Footer } from "@/components/Footer";
import { Header } from "@/components/Header";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(
    process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost",
  ),
  title: {
    default: "Seoul Glow — Skincare coreano",
    template: "%s · Seoul Glow",
  },
  description:
    "Catálogo de skincare coreano: esencias, tónicos, sérums y protectores solares de las mejores casas de Seúl.",
  openGraph: {
    title: "Seoul Glow — Skincare coreano",
    description:
      "Catálogo de skincare coreano: fórmulas esenciales, ingredientes activos y rituales simples.",
    type: "website",
    locale: "es_ES",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="es" className="h-full">
      <body className="flex min-h-full flex-col">
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
