import { readFileSync } from "node:fs";
import { join } from "node:path";
import { extractSymbol } from "./source";

/** The website's own component sources that the docs may quote. Only these prefixes are readable. */
const ALLOWED = ["src/components/app/", "content/flutter/"];

function read(path: string): string {
  if (!ALLOWED.some((prefix) => path.startsWith(prefix)) || path.includes(".."))
    throw new Error(`${path} is not a quotable website source`);
  return readFileSync(join(process.cwd(), path), "utf8");
}

/** Declarations from a TypeScript file, by name. A missing name fails the build. */
export const readTsSymbol = (path: string, symbol: string): string => extractSymbol(read(path), symbol, "javascript");

/** Declarations from a Dart file under content/flutter, by name. */
export const readDartSymbol = (path: string, symbol: string): string => extractSymbol(read(path), symbol, "dart");

/** Whole rule blocks from a stylesheet, each starting at a line that begins with one of the selectors. */
export function readCssRules(path: string, selectors: string[]): string {
  const lines = read(path).split("\n");
  const out: string[] = [];
  for (const selector of selectors) {
    const start = lines.findIndex((l) => l.startsWith(`${selector} {`) || l.startsWith(`${selector},`));
    if (start === -1) throw new Error(`${selector} not found in ${path}`);
    let end = start;
    if (!lines[start].trimEnd().endsWith("}")) while (!lines[end].startsWith("}")) end++;
    out.push(lines.slice(start, end + 1).join("\n"));
  }
  return out.join("\n\n");
}
