import Link from "next/link";
import type { ReactNode } from "react";

export interface DocMeta {
  title: string;
  description: string;
  /** Eyebrow above the title. Defaults to the colour system. */
  group?: string;
  sections: { id: string; title: string }[];
}

export function DocPage({
  meta,
  children,
}: {
  meta: DocMeta;
  children: ReactNode;
}) {
  return (
    <div className="docs-page">
      <article className="docs-article" tabIndex={0} aria-label={meta.title}>
        <header className="docs-page-header">
          <p className="docs-eyebrow">{meta.group ?? "Colour system"}</p>
          <h1>{meta.title}</h1>
          <p className="docs-lead">{meta.description}</p>
        </header>
        {children}
      </article>
      <aside className="docs-outline" aria-label="On this page">
        <div>
          <p>On this page</p>
          <nav>
            {meta.sections.map((section) => (
              <a key={section.id} href={`#${section.id}`}>
                {section.title}
              </a>
            ))}
          </nav>
        </div>
      </aside>
    </div>
  );
}

export function DocSection({
  id,
  title,
  description,
  children,
}: {
  id: string;
  title: string;
  description?: string;
  children?: ReactNode;
}) {
  return (
    <section id={id} className="docs-section">
      <h2>
        <a href={`#${id}`}>
          {title}
          <span aria-hidden="true">#</span>
        </a>
      </h2>
      {description && <p className="docs-description">{description}</p>}
      {children}
    </section>
  );
}

export function DocNote({ children }: { children: ReactNode }) {
  return <aside className="docs-note">{children}</aside>;
}

export function DemoFrame({
  controls,
  caption,
  children,
}: {
  controls?: ReactNode;
  caption?: string;
  children: ReactNode;
}) {
  return (
    <div className="docs-example">
      {controls && <div className="docs-example-controls">{controls}</div>}
      <div className="docs-preview">{children}</div>
      {caption && <p className="docs-example-caption">{caption}</p>}
    </div>
  );
}

/** Renders `code`, **bold** and [text](/path) spans inside a table cell. */
function inline(text: string): ReactNode {
  return text.split(/(`[^`]+`|\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\))/g).map((part, i) => {
    if (part.startsWith("`") && part.endsWith("`")) return <code key={i}>{part.slice(1, -1)}</code>;
    if (part.startsWith("**") && part.endsWith("**")) return <strong key={i}>{part.slice(2, -2)}</strong>;
    const link = /^\[([^\]]+)\]\(([^)]+)\)$/.exec(part);
    if (link) {
      return link[2].startsWith("/") ? (
        <Link key={i} href={link[2]}>
          {link[1]}
        </Link>
      ) : (
        <a key={i} href={link[2]}>
          {link[1]}
        </a>
      );
    }
    return part;
  });
}

/** A table from plain arrays, because the markdown pipeline has no table syntax. Cells may use `code` and **bold**. */
export function DocTable({
  head,
  rows,
  caption,
}: {
  head: string[];
  rows: string[][];
  caption?: string;
}) {
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        {caption && <caption>{caption}</caption>}
        <thead>
          <tr>
            {head.map((h) => (
              <th key={h}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, i) => (
            <tr key={i}>
              {row.map((cell, j) => (
                <td key={j}>{inline(cell)}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
