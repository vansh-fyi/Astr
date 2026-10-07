import type { Metadata } from "next";
import type { ReactNode } from "react";
import "katex/dist/katex.min.css";
import "./styles.css";
import { DocsShell } from "@/components/docs/docs-shell";

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
    <html lang="en" className="dark">
      <body>
        <DocsShell>{children}</DocsShell>
      </body>
    </html>
  );
}
