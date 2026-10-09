/**
 * Astr sky synthesis v1.0, TypeScript port. It computes the tables and calculators on these pages.
 * The Python and Dart references are the implementations; all three are held to the same test vectors.
 */
import { REFERENCE_SQM, nelmFromSqm, zoneFromRatio } from "./astr-zone";

export const CLOUD_USABLE_MAX = 0.7;
export const CLOUD_MILKY_WAY_MAX = 0.3;
export const CLOUD_STARRY_MAX = 0.5;
export const NELM_USABLE_MIN = 3.5;
export const MIN_WINDOW_HOURS = 2;
export const LOSS_NOTICEABLE_MAG = 0.25;
export const STAR_COUNT_SLOPE = 0.48;
export const SUN_ALTITUDE_DARK = -18;

const RAYLEIGH_K_SEA_LEVEL = 0.1057;
const OZONE_K = 0.016;
const TAU_TO_K = 1.0857;

export type SkyStateName = "milkyWayVisible" | "starrySkies" | "planetsVisible" | "fewStars" | "cloudy" | "tooMuchLight";

export const STATE_LABELS: Record<SkyStateName, string> = {
  milkyWayVisible: "Milky Way visible",
  starrySkies: "Starry sky",
  planetsVisible: "Planets visible",
  fewStars: "Few stars",
  cloudy: "Cloudy",
  tooMuchLight: "Too much light",
};

const rad = (d: number): number => (d * Math.PI) / 180;
const deg = (r: number): number => (r * 180) / Math.PI;

export const pressureRatio = (elevationM: number): number => (1 - 2.25577e-5 * elevationM) ** 5.25588;

export const extinctionKV = (aod550 = 0, elevationM = 0): number =>
  RAYLEIGH_K_SEA_LEVEL * pressureRatio(elevationM) + OZONE_K + TAU_TO_K * Math.max(aod550, 0);

export function scatteringAirmass(zenithDeg: number): number {
  const s = Math.sin(rad(zenithDeg));
  return (1 - 0.96 * s * s) ** -0.5;
}

export const phaseAngleFromIllumination = (illumination: number): number =>
  deg(Math.acos(Math.max(-1, Math.min(1, 2 * illumination - 1))));

export interface MoonGeometry {
  obsZenithDeg: number;
  moonZenithDeg: number;
  separationDeg: number;
  phaseAngleDeg: number;
  kV: number;
}

/** Krisciunas & Schaefer (1991) scattered moonlight in V mag/arcsec². Infinity when the moon is down. */
export function moonBrightnessV(g: MoonGeometry): number {
  if (g.moonZenithDeg >= 90) return Infinity;
  const alpha = Math.abs(g.phaseAngleDeg);
  const m = -12.73 + 0.026 * alpha + 4e-9 * alpha ** 4;
  const iStar = 10 ** (-0.4 * (m + 16.57));
  const f = 10 ** 5.36 * (1.06 + Math.cos(rad(g.separationDeg)) ** 2) + 10 ** (6.15 - g.separationDeg / 40);
  const xObs = scatteringAirmass(g.obsZenithDeg);
  const xMoon = scatteringAirmass(g.moonZenithDeg);
  const bNl = f * iStar * 10 ** (-0.4 * g.kV * xMoon) * (1 - 10 ** (-0.4 * g.kV * xObs));
  return (20.7233 - Math.log(bNl / 34.08)) / 0.92104;
}

export function moonRatio(g: MoonGeometry): number {
  const v = moonBrightnessV(g);
  return Number.isFinite(v) ? 10 ** (0.4 * (REFERENCE_SQM - v)) : 0;
}

export function angularSeparationDeg(alt1: number, az1: number, alt2: number, az2: number): number {
  const a1 = rad(alt1);
  const a2 = rad(alt2);
  const c = Math.sin(a1) * Math.sin(a2) + Math.cos(a1) * Math.cos(a2) * Math.cos(rad(az1 - az2));
  return deg(Math.acos(Math.max(-1, Math.min(1, c))));
}

export const sqmEffective = (rArt: number, bMoon = 0, bTwilight = 0): number =>
  REFERENCE_SQM - 2.5 * Math.log10(1 + Math.max(rArt, 0) + Math.max(bMoon, 0) + Math.max(bTwilight, 0));

export const relativeStarCount = (nelm: number): number =>
  10 ** (STAR_COUNT_SLOPE * (nelm - nelmFromSqm(REFERENCE_SQM)));

export interface SkyHour {
  dark: boolean;
  cloud: number;
  rArt: number;
  bMoon: number;
  sqm: number;
  nelm: number;
  usable: boolean;
  utility: number;
}

export function hourQuality(dark: boolean, cloud: number, rArt: number, bMoon: number): SkyHour {
  const sqm = sqmEffective(rArt, bMoon);
  const nelm = nelmFromSqm(sqm);
  const usable = dark && cloud <= CLOUD_USABLE_MAX && nelm >= NELM_USABLE_MIN;
  return { dark, cloud, rArt, bMoon, sqm, nelm, usable, utility: usable ? (1 - cloud) * relativeStarCount(nelm) : 0 };
}

export function bestWindow(hours: SkyHour[], minHours = MIN_WINDOW_HOURS): [number, number] | null {
  let best: [number, number] | null = null;
  let bestUtility = 0;
  let i = 0;
  while (i < hours.length) {
    if (!hours[i].usable) {
      i++;
      continue;
    }
    let j = i;
    let total = 0;
    while (j < hours.length && hours[j].usable) total += hours[j++].utility;
    if (j - i >= minHours && total > bestUtility) {
      best = [i, j];
      bestUtility = total;
    }
    i = j;
  }
  return best;
}

export function skyState(cloud: number, rArt: number, rEff: number): SkyStateName {
  if (cloud > CLOUD_USABLE_MAX) return "cloudy";
  const baseZone = zoneFromRatio(rArt);
  let z = zoneFromRatio(rEff);
  if (z === 9 && baseZone < 9) z = 8;
  if (z === 9) return "tooMuchLight";
  let state: SkyStateName = z === 8 ? "fewStars" : z >= 6 ? "planetsVisible" : z >= 4 ? "starrySkies" : "milkyWayVisible";
  if (state === "milkyWayVisible" && cloud > CLOUD_MILKY_WAY_MAX) state = "starrySkies";
  if (state === "starrySkies" && cloud > CLOUD_STARRY_MAX) state = "planetsVisible";
  return state;
}

const mean = (xs: number[]): number => xs.reduce((a, b) => a + b, 0) / xs.length;

export function nightState(hours: SkyHour[]): { state: SkyStateName; window: [number, number] | null } | null {
  const window = bestWindow(hours);
  const span = window ? hours.slice(window[0], window[1]) : hours.filter((h) => h.dark);
  if (span.length === 0) return null;
  return {
    state: skyState(
      mean(span.map((h) => h.cloud)),
      mean(span.map((h) => h.rArt)),
      mean(span.map((h) => h.rArt + h.bMoon)),
    ),
    window,
  };
}

export const instantState = (h: SkyHour): SkyStateName | null =>
  h.dark ? skyState(h.cloud, h.rArt, h.rArt + h.bMoon) : null;

export type SkyCause = "cloud" | "moon" | "light" | "none";

export function why(cloud: number, rArt: number, rEff: number): { primary: SkyCause; lightLoss: number; moonLoss: number } {
  const state = skyState(cloud, rArt, rEff);
  const capped = state === "cloudy" || state !== skyState(0, rArt, rEff);
  const nelmNatural = nelmFromSqm(REFERENCE_SQM);
  const nelmArt = nelmFromSqm(sqmEffective(rArt));
  const nelmAll = nelmFromSqm(sqmEffective(rEff));
  const lightLoss = nelmNatural - nelmArt;
  const moonLoss = nelmArt - nelmAll;
  const primary: SkyCause = capped
    ? "cloud"
    : moonLoss >= LOSS_NOTICEABLE_MAG && moonLoss > lightLoss
      ? "moon"
      : lightLoss >= LOSS_NOTICEABLE_MAG
        ? "light"
        : "none";
  return { primary, lightLoss, moonLoss };
}

export function moonHours(dark: boolean[], moonAltitudes: number[]): [number, number] {
  let up = 0;
  let down = 0;
  dark.forEach((d, i) => {
    if (!d) return;
    if (moonAltitudes[i] > 0) up++;
    else down++;
  });
  return [up, down];
}
