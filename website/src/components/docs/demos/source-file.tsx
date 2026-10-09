import { extractSymbol, languageOf, readSource } from "@/lib/source";
import { CodeBlock } from "../code-block";

const nameOf = (file: string): string => file.split("/").at(-1) ?? file;

/** A whole file, verbatim from content/source. Only author-supplied literals are passed in. */
export function SourceFile({ file }: { file: string }) {
  return <CodeBlock code={readSource(file)} filename={file} lang={languageOf(file)} />;
}

/**
 * One or more declarations cut out of a file by name, verbatim, with their doc comments. A missing symbol
 * fails the build, so an excerpt cannot silently go stale.
 */
export function SourceExcerpt({ file, symbols }: { file: string; symbols: string[] }) {
  const lang = languageOf(file);
  const code = readSource(file);
  return (
    <>
      {symbols.map((symbol) => (
        <CodeBlock
          key={symbol}
          code={extractSymbol(code, symbol, lang)}
          filename={`${nameOf(file)} · ${symbol}`}
          lang={lang}
        />
      ))}
    </>
  );
}
