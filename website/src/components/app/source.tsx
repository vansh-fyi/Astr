import { readCssRules, readDartSymbol, readTsSymbol } from "@/lib/web-source";
import { CodeBlock } from "../docs/code-block";

const nameOf = (file: string): string => file.split("/").at(-1) ?? file;

/** Component source from this site, verbatim. The same file renders the preview, so the code cannot drift. */
export function ReactExcerpt({ file, symbols }: { file: string; symbols: string[] }) {
  return (
    <>
      {symbols.map((symbol) => (
        <CodeBlock key={symbol} code={readTsSymbol(file, symbol)} filename={`${nameOf(file)} · ${symbol}`} lang="javascript" />
      ))}
    </>
  );
}

/** The CSS rules that style the component, verbatim from app-ui.css. */
export function CssExcerpt({ file, selectors }: { file: string; selectors: string[] }) {
  return <CodeBlock code={readCssRules(file, selectors)} filename={nameOf(file)} lang="css" />;
}

/** Flutter widgets from content/flutter, verbatim. */
export function DartExcerpt({ file, symbols }: { file: string; symbols: string[] }) {
  return (
    <>
      {symbols.map((symbol) => (
        <CodeBlock key={symbol} code={readDartSymbol(file, symbol)} filename={`${nameOf(file)} · ${symbol}`} lang="dart" />
      ))}
    </>
  );
}
