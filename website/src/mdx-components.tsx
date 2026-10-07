import Link from "next/link";
import type { MDXComponents } from "mdx/types";
import {
  Children,
  isValidElement,
  type AnchorHTMLAttributes,
  type ComponentPropsWithoutRef,
  type ReactElement,
  type ReactNode,
} from "react";
import { CodeBlock } from "@/components/docs/code-block";
import { CodeTabs } from "@/components/docs/code-tabs";
import { DocNote, DocSection } from "@/components/docs/documentation";
import { DartSource } from "@/components/docs/demos/dart-source";
import { CssSource } from "@/components/docs/demos/css-source";
import { GradientPlayground } from "@/components/docs/demos/gradient-playground";
import { LadderTable } from "@/components/docs/demos/ladder-table";
import { OpacityDemo } from "@/components/docs/demos/opacity-demo";
import { PaletteBento, PaletteCredits, PaletteGrid, PaletteStrip } from "@/components/docs/demos/palette-grid";
import { SampleTable } from "@/components/docs/demos/sample-table";
import { StopMatrix } from "@/components/docs/demos/stop-matrix";

function MdxLink({ href = "", children, ...rest }: AnchorHTMLAttributes<HTMLAnchorElement>) {
  if (href.startsWith("/"))
    return <Link href={href}>{children}</Link>;
  return (
    <a href={href} {...rest}>
      {children}
    </a>
  );
}

function MdxPre({ children }: ComponentPropsWithoutRef<"pre">) {
  const child = Children.toArray(children).find(isValidElement) as
    | ReactElement<{ className?: string; children?: ReactNode }>
    | undefined;
  const className = child?.props.className ?? "";
  const lang = /language-([\w-]+)/.exec(className)?.[1];
  const code = Children.toArray(child?.props.children).join("");
  return <CodeBlock code={code} lang={lang} />;
}

export function useMDXComponents(components: MDXComponents): MDXComponents {
  return {
    ...components,
    DocSection,
    DocNote,
    CodeBlock,
    CodeTabs,
    PaletteGrid,
    PaletteStrip,
    PaletteBento,
    PaletteCredits,
    LadderTable,
    SampleTable,
    CssSource,
    DartSource,
    OpacityDemo,
    StopMatrix,
    GradientPlayground,
    p: ({ children }) => <p className="docs-description">{children}</p>,
    h3: ({ children }) => <h3>{children}</h3>,
    a: MdxLink,
    pre: MdxPre,
  };
}
