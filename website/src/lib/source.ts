import { readFileSync } from "node:fs";
import { join } from "node:path";

/** Source files are copied verbatim into content/source by scripts/sync-source.mjs. */
const SOURCE_DIR = join(process.cwd(), "content/source");

const manifest = (): string[] =>
  (JSON.parse(readFileSync(join(SOURCE_DIR, "manifest.json"), "utf8")) as { files: string[] }).files;

export type SourceLang = "python" | "javascript" | "dart" | "json";

export function languageOf(path: string): SourceLang {
  if (path.endsWith(".py")) return "python";
  if (path.endsWith(".js")) return "javascript";
  if (path.endsWith(".dart")) return "dart";
  if (path.endsWith(".json")) return "json";
  throw new Error(`No language for ${path}`);
}

/** Reads a manifest file. Only paths listed in the manifest are readable, so authors cannot reach other files. */
export function readSource(path: string): string {
  if (!manifest().includes(path)) throw new Error(`${path} is not listed in content/source/manifest.json`);
  return readFileSync(join(SOURCE_DIR, path), "utf8");
}

const indentOf = (line: string): number => line.length - line.trimStart().length;
const isBlank = (line: string): boolean => line.trim() === "";
const isDocLine = (line: string, lang: SourceLang): boolean => {
  const t = line.trim();
  if (/[=\-]{5,}/.test(t)) return false; // section banners are not documentation
  if (lang === "python") return t.startsWith("#") || t.startsWith("@");
  return t.startsWith("///") || t.startsWith("//") || t.startsWith("/**") || t.startsWith("*") || t.startsWith("@");
};

function declarationPattern(symbol: string, lang: SourceLang): RegExp {
  const s = symbol.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  if (lang === "python")
    return new RegExp(`^\\s*(?:async\\s+)?(?:def|class)\\s+${s}\\b|^${s}\\s*(?::[^=]+)?=`);
  if (lang === "javascript") return new RegExp(`^\\s*(?:export\\s+)?(?:async\\s+)?function\\s+${s}\\b|^\\s*(?:export\\s+)?(?:const|let)\\s+${s}\\b`);
  // Dart: a class, or a member at class level (two spaces of indent at most).
  return new RegExp(`^ {0,2}(?:[\\w<>?,$ ()]*\\s)?${s}\\s*(?:\\(|=|\\{)|^\\s*(?:abstract\\s+|final\\s+|base\\s+)*class\\s+${s}\\b`);
}

/**
 * Index of the line where the declaration that starts on `start` ends. A declaration ends at the closing brace
 * of its body (a brace outside any parentheses or brackets) or at a semicolon outside all brackets. Braces inside
 * parentheses, such as Dart named parameters, do not count as a body. String literals and // comments are skipped.
 */
function endOfBraceDeclaration(lines: string[], start: number): number {
  let depth = 0;
  let parens = 0;
  let body = false;
  let quote: string | null = null;
  let inBlockComment = false;
  for (let i = start; i < lines.length; i++) {
    const line = lines[i];
    for (let c = 0; c < line.length; c++) {
      const ch = line[c];
      if (inBlockComment) {
        if (ch === "*" && line[c + 1] === "/") {
          inBlockComment = false;
          c++;
        }
        continue;
      }
      if (quote) {
        if (ch === "\\") c++;
        else if (ch === quote) quote = null;
        continue;
      }
      if (ch === "/" && line[c + 1] === "/") break;
      if (ch === "/" && line[c + 1] === "*") {
        inBlockComment = true;
        c++;
        continue;
      }
      if (ch === "'" || ch === '"' || ch === "`") quote = ch;
      else if (ch === "(" || ch === "[") {
        parens++;
        depth++;
      } else if (ch === ")" || ch === "]") {
        parens--;
        depth--;
      } else if (ch === "{") {
        if (parens === 0) body = true;
        depth++;
      } else if (ch === "}") {
        depth--;
        if (body && depth === 0) return i;
      } else if (ch === ";" && depth === 0 && !body) return i;
    }
    quote = null; // single-line string literals only
  }
  return lines.length - 1;
}

/** Cuts one declaration, with its doc comment, out of a source file. Throws when the symbol is missing. */
export function extractSymbol(code: string, symbol: string, lang: SourceLang): string {
  const lines = code.split("\n");
  const pattern = declarationPattern(symbol, lang);
  const start = lines.findIndex((l) => pattern.test(l));
  if (start === -1) throw new Error(`Symbol "${symbol}" not found`);

  let first = start;
  while (first > 0 && isDocLine(lines[first - 1], lang)) first--;

  let end = start;
  if (lang === "python" && !/^\s*(?:async\s+)?(?:def|class)\s/.test(lines[start])) {
    // A module-level constant: runs until its brackets close.
    let depth = 0;
    for (let i = start; i < lines.length; i++) {
      for (const ch of lines[i].split("#")[0]) {
        if ("([{".includes(ch)) depth++;
        else if (")]}".includes(ch)) depth--;
      }
      end = i;
      if (depth <= 0) break;
    }
  } else if (lang === "python") {
    const base = indentOf(lines[start]);
    end = start;
    for (let i = start + 1; i < lines.length; i++) {
      if (isBlank(lines[i])) continue;
      if (indentOf(lines[i]) <= base) break;
      end = i;
    }
  } else {
    end = endOfBraceDeclaration(lines, start);
  }

  const slice = lines.slice(first, end + 1);
  const margin = Math.min(...slice.filter((l) => !isBlank(l)).map(indentOf));
  return slice.map((l) => l.slice(Math.min(margin, l.length))).join("\n");
}

/** Reads a numeric module-level constant (`NAME = 1.5` or `NAME = 1.5  # note`) from a Python source file. */
export function pythonNumber(path: string, name: string): number {
  const m = new RegExp(`^${name}\\s*(?::[^=]+)?=\\s*(-?[\\d.]+(?:e-?\\d+)?)`, "m").exec(readSource(path));
  if (!m) throw new Error(`${name} not found as a number in ${path}`);
  return parseFloat(m[1]);
}
