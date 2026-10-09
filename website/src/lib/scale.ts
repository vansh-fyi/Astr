import { readFileSync } from "node:fs";
import { join } from "node:path";

/** Fixed path: the single source of proportion tokens. No caller-supplied paths. */
const SCALE_CSS_PATH = join(process.cwd(), "src/app/scale.css");

export const BASE = 16;
export const PHI = (1 + Math.sqrt(5)) / 2;

/** F(1)..F(n) with F(1) = F(2) = 1. */
export function fibonacci(count: number): number[] {
  const out = [1, 1];
  while (out.length < count) out.push(out[out.length - 1] + out[out.length - 2]);
  return out.slice(0, count);
}

export const SPACING = [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144] as const;
export const RADII = [3, 5, 8, 13, 21, 34] as const;
export const WIDTHS = [233, 377, 610, 987] as const;
export const BREAKPOINTS = [377, 610, 987, 1597] as const;
export const TYPE_STEPS = [-2, -1, 0, 1, 2, 3, 4, 5, 6] as const;

export const typeSizeRaw = (n: number): number => BASE * PHI ** (n / 2);
export const typeSize = (n: number): number => Math.round(typeSizeRaw(n));
export const typeLeading = (n: number): number => 1 + PHI ** -(1 + n / 2);
export const typeTracking = (n: number): number => -(PHI ** (n / 2) - 1) / 89;

export interface TypeStep {
  n: number;
  token: string;
  px: number;
  lineHeight: number;
  tracking: number;
}

/** Roles are documentation only; the tokens carry no role. */
export const TYPE_ROLES: Record<number, { role: string; family: "Inter" | "Satoshi" }> = {
  [-2]: { role: "Overline, legal", family: "Inter" },
  [-1]: { role: "Caption, helper text", family: "Inter" },
  0: { role: "Body", family: "Inter" },
  1: { role: "Lead, subtitle", family: "Inter" },
  2: { role: "Heading 4", family: "Satoshi" },
  3: { role: "Heading 3", family: "Satoshi" },
  4: { role: "Heading 2", family: "Satoshi" },
  5: { role: "Heading 1", family: "Satoshi" },
  6: { role: "Display", family: "Satoshi" },
};

const remToPx = (value: string): number => {
  const m = /^(-?[\d.]+)rem$/.exec(value);
  if (!m) throw new Error(`Expected a rem value, got "${value}"`);
  return parseFloat(m[1]) * BASE;
};

function readTokens(): Map<string, string> {
  const css = readFileSync(SCALE_CSS_PATH, "utf8").replace(/\/\*[\s\S]*?\*\//g, "");
  const out = new Map<string, string>();
  for (const m of css.matchAll(/^\s*(--[\w-]+)\s*:\s*([^;]+);/gm)) out.set(m[1], m[2].trim());
  return out;
}

function expectPx(tokens: Map<string, string>, token: string, px: number): void {
  const value = tokens.get(token);
  if (value === undefined) throw new Error(`scale.css is missing ${token}`);
  if (Math.abs(remToPx(value) - px) > 1e-9)
    throw new Error(`${token} is ${value} in scale.css but the formula gives ${px}px`);
}

/** Throws when scale.css drifts from the formulas. Returns the type table. */
export function readTypeScale(): TypeStep[] {
  const tokens = readTokens();
  for (const f of SPACING) expectPx(tokens, `--spacing-f${f}`, f);
  for (const f of RADII) expectPx(tokens, `--radius-f${f}`, f);
  for (const f of WIDTHS) expectPx(tokens, `--container-f${f}`, f);
  for (const f of BREAKPOINTS) expectPx(tokens, `--breakpoint-f${f}`, f);
  return TYPE_STEPS.map((n) => {
    const token = `--text-s${n}`;
    expectPx(tokens, token, typeSize(n));
    const lh = parseFloat(tokens.get(`${token}--line-height`) ?? "NaN");
    const tr = parseFloat(tokens.get(`${token}--letter-spacing`) ?? "NaN");
    if (Math.abs(lh - typeLeading(n)) > 0.0005)
      throw new Error(`${token}--line-height is ${lh} but the formula gives ${typeLeading(n)}`);
    if (Math.abs(tr - typeTracking(n)) > 0.00005)
      throw new Error(`${token}--letter-spacing is ${tr} but the formula gives ${typeTracking(n)}`);
    return { n, token, px: typeSize(n), lineHeight: lh, tracking: tr };
  });
}

/** Class-name suffix for a step: s-2, s-1, s0, s1 ... */
export const stepName = (n: number): string => `s${n}`;

/** Roles are documentation only; the tokens carry no role. */
export const SPACING_ROLES: Record<number, string> = {
  1: "Hairline border",
  2: "Focus ring, divider weight",
  3: "Optical nudge",
  5: "Icon to label gap, chip padding",
  8: "Inline gap, small control padding",
  13: "Stack gap, compact card padding",
  21: "Card padding, group gap",
  34: "Screen gutter, loose padding",
  55: "Section gap",
  89: "Hero gap",
  144: "Page-level gap",
};

export const RADIUS_ROLES: Record<number, string> = {
  3: "Hairline marks, focus ring corners",
  5: "Inline code, tags",
  8: "Inputs, small controls",
  13: "Tiles, small cards",
  21: "Cards, panels",
  34: "Sheets, dialogs",
};

export interface SizeRow {
  element: string;
  px: number;
  token: string;
  note: string;
}

export const SIZE_ROWS: SizeRow[] = [
  { element: "Border", px: 1, token: "f1", note: "Hairline" },
  { element: "Focus ring", px: 2, token: "f2", note: "Outline width" },
  { element: "Icon, small", px: 13, token: "f13", note: "Inline with caption text" },
  { element: "Icon", px: 21, token: "f21", note: "Default" },
  { element: "Icon, large", px: 34, token: "f34", note: "Empty states, feature rows" },
  { element: "Control, compact", px: 34, token: "f34", note: "Drawn height. The hit area is still 55" },
  { element: "Control", px: 55, token: "f55", note: "Drawn height of primary controls" },
  { element: "Touch target", px: 55, token: "f55", note: "Minimum. Platforms ask for 44 (iOS) and 48 (Android)" },
  { element: "Mark, avatar", px: 34, token: "f34", note: "Small. 55 regular, 89 large" },
];

export interface Pane {
  name: string;
  px: number;
  token: string;
}

/** The documentation panes. 233 and 377 sum to 610, so each pair is one golden ratio apart. */
export const PANES: Pane[] = [
  { name: "Sidebar", px: 233, token: "f233" },
  { name: "Article", px: 610, token: "f610" },
  { name: "Outline", px: 144, token: "f144" },
];

/** Verbatim declaration lines from scale.css whose property starts with one of the prefixes. */
export function readScaleLines(prefixes: string[]): string {
  const lines = readFileSync(SCALE_CSS_PATH, "utf8")
    .split("\n")
    .filter((line) => prefixes.some((p) => line.trim().startsWith(p)));
  if (lines.length === 0) throw new Error(`scale.css has no lines for ${prefixes.join(", ")}`);
  return `@theme static {\n${lines.join("\n")}\n}`;
}
