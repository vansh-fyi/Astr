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
