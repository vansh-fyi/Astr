import { pogsonAlpha, snapStep } from "./ladder";
import { parseGradientStops, type GradientStop } from "./tokens";

export const K_EXTINCTION = 0.2;
export const MOFFAT_BETA = 3;
export const MOFFAT_RADIUS_IN_A = 4;
export const EXTINCTION_ZS = [0, 60, 70, 78, 84, 88, 90] as const;
export const MOFFAT_POSITIONS = [0, 10, 20, 30, 40, 50, 60, 100] as const;

/** Kasten-Young relative airmass; z in degrees. */
export function airmass(zDeg: number): number {
  const rad = (zDeg * Math.PI) / 180;
  return 1 / (Math.cos(rad) + 0.50572 * (96.07995 - zDeg) ** -1.6364);
}

export function extinctionAlpha(zDeg: number): number {
  return Math.min(1, 10 ** (-0.4 * K_EXTINCTION * (airmass(zDeg) - 1)));
}

export function moffatIntensity(rOverA: number): number {
  return (1 + rOverA ** 2) ** -MOFFAT_BETA;
}

export interface SampleRow {
  /** z in degrees (extinction) or position percent (Moffat). */
  input: number;
  /** Extinction only. */
  airmass?: number;
  /** Moffat only: r / a. */
  rOverA?: number;
  position: number;
  raw: number;
  step: number | null;
  snapped: number;
  css: GradientStop | undefined;
  match: boolean;
}

function finish(
  input: number,
  position: number,
  raw: number,
  css: GradientStop | undefined,
  extra: Partial<SampleRow>,
): SampleRow {
  const step = snapStep(raw);
  return {
    input,
    position,
    raw,
    step,
    snapped: step === null ? 0 : pogsonAlpha(step),
    css,
    match: !!css && Math.abs(css.pos - position) <= 0.05 && css.step === step,
    ...extra,
  };
}

export function extinctionRows(): SampleRow[] {
  const css = parseGradientStops("gradient-extinction");
  return EXTINCTION_ZS.map((z, i) =>
    finish(z, Math.round((z / 90) * 1000) / 10, extinctionAlpha(z), css[i], {
      airmass: airmass(z),
    }),
  );
}

export function moffatRows(): SampleRow[] {
  const css = parseGradientStops("gradient-moffat");
  return MOFFAT_POSITIONS.map((p, i) => {
    const rOverA = (MOFFAT_RADIUS_IN_A * p) / 100;
    return finish(p, p, moffatIntensity(rOverA), css[i], { rOverA });
  });
}

/** Rows verified against globals.css; throws on any drift so the build fails. */
export function crossCheckedRows(kind: "extinction" | "moffat"): SampleRow[] {
  const rows = kind === "extinction" ? extinctionRows() : moffatRows();
  const css = parseGradientStops(`gradient-${kind}`);
  if (css.length !== rows.length)
    throw new Error(
      `gradient-${kind}: model has ${rows.length} stops but globals.css has ${css.length}`,
    );
  rows.forEach((row, i) => {
    if (!row.match)
      throw new Error(
        `gradient-${kind} stop ${i}: model ${row.position}% step ${row.step} vs CSS ${JSON.stringify(row.css)}`,
      );
  });
  return rows;
}
