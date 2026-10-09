import type { ReactNode } from "react";
import { CodeBlock } from "../docs/code-block";
import { AppStage } from "./app-widgets";

export interface VariantItem {
  label: string;
  /** What the variant shows, in a sentence. */
  note?: string;
  preview: ReactNode;
  /** The Dart that builds it, as a developer would write it. */
  dart: string;
}

/**
 * Visual variants of one widget: each is a labelled preview on the app surface and the Dart that builds it.
 * Previews are the web redraws in app-widgets.tsx; the Dart is the real constructor from the app.
 */
export function Variants({ items, column, wide }: { items: VariantItem[]; column?: boolean; wide?: boolean }) {
  return (
    <div className="app-variants" data-wide={wide || undefined}>
      {items.map((item) => (
        <figure key={item.label} className="app-variant">
          <figcaption>
            <strong>{item.label}</strong>
            {item.note && <span>{item.note}</span>}
          </figcaption>
          <AppStage column={column}>{item.preview}</AppStage>
          <CodeBlock code={item.dart} lang="dart" filename="Dart" />
        </figure>
      ))}
    </div>
  );
}

/** Several previews side by side on one app surface, for a complete set (all nine zones, all eight phases). */
export function Gallery({ children, column }: { children: ReactNode; column?: boolean }) {
  return <AppStage column={column}>{children}</AppStage>;
}
