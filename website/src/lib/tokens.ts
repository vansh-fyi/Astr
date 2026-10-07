import { readFileSync } from "node:fs";
import { join } from "node:path";

/** Fixed path: the single source of colour tokens. No caller-supplied paths. */
const GLOBALS_CSS_PATH = join(process.cwd(), "src/app/globals.css");

export const STEPS = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950] as const;

export const PALETTES = [
  { id: "space-grey", name: "Space Grey" },
  { id: "deep-space", name: "Deep Space" },
  { id: "aurora-pink", name: "Aurora Pink" },
  { id: "aurora-green", name: "Aurora Green" },
  { id: "sodium-airglow", name: "Sodium Airglow" },
  { id: "oxygen-airglow", name: "Oxygen Airglow" },
] as const;

export interface PaletteStop {
  step: number;
  token: string;
  hex: string;
}
export interface Palette {
  id: string;
  name: string;
  stops: PaletteStop[];
}
export interface MagStep {
  n: number;
  token: string;
  value: string;
  percent: number;
}
export interface ThemeBlock {
  kind: "default" | "static" | "inline";
  body: string;
}
export interface GradientStop {
  pos: number;
  step: number | null;
}

export function readGlobalsCss(): string {
  return readFileSync(GLOBALS_CSS_PATH, "utf8");
}

/** Removes block comments so comment text is never mistaken for CSS. */
function stripComments(css: string): string {
  return css.replace(/\/\*[\s\S]*?\*\//g, "");
}

/** Returns the index just after the brace that closes the block opened at `open`. */
function matchBrace(css: string, open: number): number {
  let depth = 0;
  for (let i = open; i < css.length; i++) {
    if (css[i] === "{") depth++;
    else if (css[i] === "}") {
      depth--;
      if (depth === 0) return i + 1;
    }
  }
  throw new Error("globals.css: unbalanced braces");
}

/** Reads every `@theme`, `@theme static` and `@theme inline` block. */
export function readThemeBlocks(): ThemeBlock[] {
  const css = stripComments(readGlobalsCss());
  const blocks: ThemeBlock[] = [];
  const re = /@theme(?:\s+(static|inline))?\s*\{/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(css))) {
    const open = m.index + m[0].length - 1;
    const end = matchBrace(css, open);
    blocks.push({
      kind: (m[1] as "static" | "inline" | undefined) ?? "default",
      body: css.slice(open + 1, end - 1),
    });
    re.lastIndex = end;
  }
  if (!blocks.length) throw new Error("globals.css: no @theme block found");
  return blocks;
}

/** All theme bodies joined, so callers see every block. */
export function readThemeBlock(): string {
  return readThemeBlocks()
    .map((b) => b.body)
    .join("\n");
}

export function parseThemeTokens(
  block: string,
  prefix: string,
): { name: string; value: string }[] {
  const out: { name: string; value: string }[] = [];
  const re = /(--[\w-]+)\s*:\s*([^;]+);/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(block))) {
    if (m[1].startsWith(prefix))
      out.push({ name: m[1], value: m[2].replace(/\s+/g, " ").trim() });
  }
  return out;
}

export function getPalettes(): Palette[] {
  const tokens = new Map(
    parseThemeTokens(readThemeBlock(), "--color-").map((t) => [t.name, t.value]),
  );
  return PALETTES.map(({ id, name }) => ({
    id,
    name,
    stops: STEPS.map((step) => {
      const token = `--color-${id}-${step}`;
      const hex = tokens.get(token);
      if (!hex || !/^#[0-9a-f]{6}$/i.test(hex))
        throw new Error(`globals.css: ${token} missing or not a #rrggbb hex (${hex})`);
      return { step, token, hex: hex.toLowerCase() };
    }),
  }));
}

export function getStopHex(id: string, step: number): string {
  const stop = getPalettes()
    .find((p) => p.id === id)
    ?.stops.find((s) => s.step === step);
  if (!stop) throw new Error(`Unknown stop ${id}-${step}`);
  return stop.hex;
}

export function getMagSteps(): MagStep[] {
  const tokens = new Map(
    parseThemeTokens(readThemeBlock(), "--mag-").map((t) => [t.name, t.value]),
  );
  return Array.from({ length: 11 }, (_, n) => {
    const token = `--mag-${n}`;
    const value = tokens.get(token);
    if (!value) throw new Error(`globals.css: ${token} missing`);
    return { n, token, value, percent: parseFloat(value) };
  });
}

/** Display text of the theme declarations whose names start with `prefix`. */
export function readThemeSource(prefix: string): string {
  const parts: string[] = [];
  for (const block of readThemeBlocks()) {
    const lines = block.body
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l.startsWith(prefix));
    if (!lines.length) continue;
    const head = block.kind === "default" ? "@theme {" : `@theme ${block.kind} {`;
    parts.push([head, ...lines.map((l) => `  ${l}`), "}"].join("\n"));
  }
  if (!parts.length) throw new Error(`globals.css: no theme tokens with prefix ${prefix}`);
  return parts.join("\n\n");
}

function utilityBody(name: string): { text: string; body: string } {
  const css = stripComments(readGlobalsCss());
  const head = new RegExp(`@utility\\s+${name.replace(/[^\w-]/g, "")}\\s*\\{`);
  const m = head.exec(css);
  if (!m) throw new Error(`globals.css: @utility ${name} not found`);
  const open = m.index + m[0].length - 1;
  const end = matchBrace(css, open);
  return { text: css.slice(m.index, end), body: css.slice(open + 1, end - 1) };
}

export function readUtilityBlock(name: string): string {
  return utilityBody(name).text;
}

/** Ordered gradient stops: `--mag-N` steps, or null for bare `transparent`. */
export function parseGradientStops(name: string): GradientStop[] {
  const body = utilityBody(name).body.replace(/\s+/g, " ");
  const re =
    /color-mix\(in srgb, var\(--grad-color\) var\(--mag-(\d+)\), transparent\) ([\d.]+)%|transparent ([\d.]+)%/g;
  const stops: GradientStop[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(body))) {
    if (m[1] !== undefined) stops.push({ pos: parseFloat(m[2]), step: Number(m[1]) });
    else stops.push({ pos: parseFloat(m[3]), step: null });
  }
  return stops;
}
