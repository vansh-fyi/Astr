import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Inter, Plus_Jakarta_Sans } from "next/font/google";
import "katex/dist/katex.min.css";
import "./styles.css";
import { DocsShell } from "@/components/docs/docs-shell";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const plusJakartaSans = Plus_Jakarta_Sans({
  variable: "--font-plus-jakarta-sans",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Astr colour system",
    template: "%s · Astr colour system",
  },
  description:
    "Fixed colour stops, the Pogson opacity ladder and natural-law gradients that make up the Astr colour system.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`dark ${inter.variable} ${plusJakartaSans.variable}`}>
      <body>
        <DocsShell>{children}</DocsShell>
      </body>
    </html>
  );
}
