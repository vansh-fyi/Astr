import type { MagStep } from "./tokens";

/** Pogson ladder: every step is half a magnitude. */
export const pogsonAlpha = (n: number): number => 10 ** (-0.4 * n / 2);

export const magnitudeOf = (n: number): number => n / 2;

/**
 * Snaps an alpha to the nearest --mag-N step. Alpha is clamped to 1 first;
 * at or beyond 10.5 half-steps the stop is fully transparent (null).
 */
export function snapStep(alpha: number): number | null {
  const a = Math.min(1, alpha);
  const nRaw = -5 * Math.log10(a);
  if (nRaw >= 10.5) return null;
  return Math.min(10, Math.max(0, Math.round(nRaw)));
}

export const formatPercent = (alpha: number, digits = 2): string =>
  `${(alpha * 100).toFixed(digits)}%`;

/** Throws when the CSS --mag values drift from the Pogson formula. */
export function assertLadderMatchesCss(steps: MagStep[]): void {
  if (steps.length !== 11) throw new Error(`Expected 11 --mag steps, got ${steps.length}`);
  for (const s of steps) {
    const expected = pogsonAlpha(s.n) * 100;
    if (Math.abs(s.percent - expected) > 0.05)
      throw new Error(
        `${s.token} is ${s.percent}% in globals.css but alpha(${s.n}) = ${expected.toFixed(3)}%`,
      );
  }
}
