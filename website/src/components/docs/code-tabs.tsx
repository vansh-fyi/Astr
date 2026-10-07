import type { ReactNode } from "react";
import { CodeTabsClient } from "./code-tabs-client";

/**
 * Tokens / CSS and Flutter tabs. Both panels render on the server; the client
 * wrapper only toggles which one is visible.
 */
export function CodeTabs({
  children,
  flutter,
}: {
  children: ReactNode;
  flutter?: ReactNode;
}) {
  return <CodeTabsClient css={children} flutter={flutter} />;
}
