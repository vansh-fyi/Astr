import type { ReactNode } from "react";
import { CodeTabsClient } from "./code-tabs-client";

/**
 * Two tabs, both rendered on the server; the client wrapper only toggles which one is visible.
 * The colour and proportion pages use "Tokens / CSS" and "Flutter". Other pages name their own tabs with
 * `labels` and pass the second panel as `second` (`flutter` is the older name for the same prop).
 */
export function CodeTabs({
  children,
  flutter,
  second,
  labels,
}: {
  children: ReactNode;
  flutter?: ReactNode;
  second?: ReactNode;
  labels?: [string, string];
}) {
  return (
    <CodeTabsClient
      first={children}
      second={second ?? flutter}
      labels={labels ?? ["Tokens / CSS", "Flutter"]}
    />
  );
}
