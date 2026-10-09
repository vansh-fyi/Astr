import type { Metadata } from "next";
import type { ReactNode } from "react";
import { Inter } from "next/font/google";
import localFont from "next/font/local";
import "katex/dist/katex.min.css";
import "./styles.css";
import { DocsShell } from "@/components/docs/docs-shell";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  display: "swap",
});

const satoshi = localFont({
  variable: "--font-satoshi",
  display: "swap",
  src: [
    { path: "../fonts/Satoshi-Medium.ttf", weight: "500", style: "normal" },
    { path: "../fonts/Satoshi-Bold.ttf", weight: "700", style: "normal" },
  ],
});

export const metadata: Metadata = {
  title: {
    default: "Astr design system",
    template: "%s · Astr design system",
  },
  description:
    "Colour stops, the Pogson opacity ladder and natural-law gradients, plus Fibonacci spacing, golden-ratio type and layout, and the sky science behind the app's verdict, that make up the Astr design system.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={`dark ${inter.variable} ${satoshi.variable}`}>
      <body>
        <DocsShell>{children}</DocsShell>
      </body>
    </html>
  );
}
