/**
 * Astr Zone scale v2.0, TypeScript port. It exists to compute the tables and calculators on these pages.
 * The Python and Dart references are the implementations; all three are held to the same test vectors
 * (see sky-vectors.ts, which fails the build when this port disagrees).
 */

export const NATURAL_UCD_PER_M2 = 174;
export const REFERENCE_SQM = 22;
export const FIRST_EDGE = 0.32;
export const STEP = 2;
export const ZONE_COUNT = 9;
/** The ratio at which zones 2 to 9 begin. */
export const EDGES: readonly number[] = Array.from({ length: ZONE_COUNT - 1 }, (_, k) => FIRST_EDGE * STEP ** k);

/** Legacy radiance thresholds (nW/cm²/sr), highest first, that built the current zones.db. */
export const LEGACY_THRESHOLDS: readonly (readonly [number, number])[] = [
  [125, 9], [50, 8], [20, 7], [9, 6], [3, 5], [1, 4], [0.5, 3], [0.25, 2],
];

export function zoneFromRatio(r: number): number {
  if (Number.isNaN(r)) throw new Error("r must be a number");
  let zone = 1;
  for (const edge of EDGES) {
    if (r >= edge) zone++;
    else break;
  }
  return zone;
}

export const sqmFromRatio = (r: number): number => {
  if (Number.isNaN(r)) throw new Error("r must be a number");
  return REFERENCE_SQM - 2.5 * Math.log10(1 + Math.max(r, 0));
};

export const ratioFromSqm = (sqm: number): number => {
  if (Number.isNaN(sqm)) throw new Error("sqm must be a number");
  return Math.max(10 ** (0.4 * (REFERENCE_SQM - sqm)) - 1, 0);
};

export const artificialUcdFromRatio = (r: number): number => Math.max(r, 0) * NATURAL_UCD_PER_M2;

export const nelmFromSqm = (sqm: number): number => 7.93 - 5 * Math.log10(10 ** (4.316 - sqm / 5) + 1);

export function legacyZoneFromRadiance(radiance: number): number {
  if (radiance <= 0) return 1;
  for (const [threshold, zone] of LEGACY_THRESHOLDS) if (radiance >= threshold) return zone;
  return 1;
}

/** The ratio implied by the legacy SQM fit 22 - 1.7 log10(1 + 2R): (1 + 2R)^0.68 - 1. */
export const legacyRatioFromRadiance = (radiance: number): number =>
  radiance <= 0 ? 0 : (1 + 2 * radiance) ** (0.4 * 1.7) - 1;

/** The radiance at which the legacy chain reaches ratio r. */
export const legacyRadianceFromRatio = (r: number): number => ((1 + r) ** (1 / (0.4 * 1.7)) - 1) / 2;
