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
    CodeTabs,
    p: ({ children }) => <p className="docs-description">{children}</p>,
    h3: ({ children }) => <h3>{children}</h3>,
    a: MdxLink,
    pre: MdxPre,
  };
}
