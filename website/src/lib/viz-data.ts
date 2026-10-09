import { moonRatio, phaseAngleFromIllumination } from "./astr-sky";

/** An example night used by the graphs. Everything here is illustrative, and the geometry is real trigonometry. */

/** Night window, minutes since midnight of the evening: 18:00 to 06:00. */
export const NIGHT_START = 18 * 60;
export const NIGHT_END = 30 * 60;

/** Hourly cloud forecast, in percent, at 18:00, 19:00 ... 06:00. */
export const CLOUD_HOURLY: readonly number[] = [10, 12, 20, 35, 45, 30, 15, 10, 8, 10, 20, 40, 55];

export const MOON_ILLUMINATION = 0.78;
const MOON_RISE = 21.5 * 60;
const MOON_SET = 33.5 * 60;
const MOON_PEAK = 58;

/** Moon altitude in degrees: a half sine between moonrise and moonset, below the horizon outside it. */
export function moonAltitude(minutes: number): number {
  if (minutes <= MOON_RISE || minutes >= MOON_SET) return 0;
  return MOON_PEAK * Math.sin((Math.PI * (minutes - MOON_RISE)) / (MOON_SET - MOON_RISE));
}
export const MOON_RISE_MINUTES = MOON_RISE;

/** The "moon value" the object graph plots: altitude times illuminated fraction while up. */
export const moonValue = (minutes: number): number => moonAltitude(minutes) * MOON_ILLUMINATION;

export const LATITUDE = 30;

export interface ExampleObject {
  id: string;
  name: string;
  note: string;
  dec: number;
  /** Local time of transit, minutes since the evening's midnight. */
  transit: number;
}

export const OBJECTS: ExampleObject[] = [
  { id: "high", name: "High object", note: "declination +5°, crosses the meridian at 23:00", dec: 5, transit: 23 * 60 },
  { id: "low", name: "Low object", note: "declination −30°, never gets high", dec: -30, transit: 23 * 60 },
  { id: "late", name: "Late riser", note: "declination +20°, crosses at 03:00", dec: 20, transit: 27 * 60 },
];

/** Altitude in degrees from latitude, declination and the hour angle: sin h = sin φ sin δ + cos φ cos δ cos H. */
export function objectAltitude(o: ExampleObject, minutes: number): number {
  const phi = (LATITUDE * Math.PI) / 180;
  const delta = (o.dec * Math.PI) / 180;
  const hourAngle = (0.25 * (minutes - o.transit) * Math.PI) / 180; // 15 degrees an hour
  const s = Math.sin(phi) * Math.sin(delta) + Math.cos(phi) * Math.cos(delta) * Math.cos(hourAngle);
  return (Math.asin(Math.max(-1, Math.min(1, s))) * 180) / Math.PI;
}

/** Cloud cover in percent at a time, by linear interpolation of the hourly values. */
export function cloudAt(minutes: number): number {
  const pos = Math.max(0, Math.min(CLOUD_HOURLY.length - 1, (minutes - NIGHT_START) / 60));
  const i = Math.min(CLOUD_HOURLY.length - 2, Math.floor(pos));
  return CLOUD_HOURLY[i] + (CLOUD_HOURLY[i + 1] - CLOUD_HOURLY[i]) * (pos - i);
}

export interface PrimeWindow {
  from: number;
  to: number;
  score: number;
}

/** The app's prime view: lowest average score over runs of at least 3 hourly samples, dropped above 0.8. */
export function primeView(): PrimeWindow | null {
  const scores = CLOUD_HOURLY.map((c, i) => {
    const t = NIGHT_START + i * 60;
    return 0.7 * (c / 100) + 0.3 * ((MOON_ILLUMINATION * moonAltitude(t)) / 90);
  });
  let best: PrimeWindow | null = null;
  let bestAvg = Infinity;
  for (let size = 3; size <= scores.length; size++) {
    for (let i = 0; i + size <= scores.length; i++) {
      const avg = scores.slice(i, i + size).reduce((a, b) => a + b, 0) / size;
      if (avg < bestAvg) {
        bestAvg = avg;
        best = { from: NIGHT_START + i * 60, to: NIGHT_START + (i + size - 1) * 60, score: avg };
      }
    }
  }
  return best && best.score <= 0.8 ? best : null;
}

/** Scattered moonlight in natural units for a moon at the zenith-referenced sky, for a given illuminated fraction. */
export function moonRatioAt(minutes: number, illumination: number, kV = 0.15): number {
  const alt = moonAltitude(minutes);
  if (alt <= 0) return 0;
  const z = 90 - alt;
  return moonRatio({ obsZenithDeg: 0, moonZenithDeg: z, separationDeg: z, phaseAngleDeg: phaseAngleFromIllumination(illumination), kV });
}
