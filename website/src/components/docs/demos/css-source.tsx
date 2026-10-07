import { readThemeSource, readUtilityBlock } from "@/lib/tokens";
import { CodeBlock } from "../code-block";

/** Renders verbatim CSS from globals.css. Only author-supplied literals are passed in. */
export function CssSource({ theme, utility }: { theme?: string; utility?: string }) {
  const code = theme
    ? readThemeSource(theme)
    : utility
      ? readUtilityBlock(utility)
      : null;
  if (!code) throw new Error("CssSource needs a `theme` prefix or a `utility` name");
  return <CodeBlock code={code} filename="globals.css" lang="css" />;
}
