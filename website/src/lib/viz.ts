/** Small helpers for the illustrations. Everything here is deterministic so server and client agree. */

/** A seeded random number generator (mulberry32). */
export function rng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const PHI = (1 + Math.sqrt(5)) / 2;

/** Chart height for a width: the plot is a golden rectangle squared, 233 : 610 in Fibonacci terms. */
export const chartHeight = (width: number): number => Math.round(width / (PHI * PHI));

/** Linear scale from a domain to a range. */
export const scale = (d0: number, d1: number, r0: number, r1: number) => (x: number): number =>
  r0 + ((x - d0) / (d1 - d0)) * (r1 - r0);

/** A smooth 2D value-noise field in 0..1 on a w by h grid. Used for cloud shapes. */
export function noiseField(w: number, h: number, seed: number, cell = 5): number[] {
  const rand = rng(seed);
  const gw = Math.ceil(w / cell) + 2;
  const gh = Math.ceil(h / cell) + 2;
  const grid = Array.from({ length: gw * gh }, () => rand());
  const smooth = (t: number): number => t * t * (3 - 2 * t);
  const out: number[] = [];
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const gx = x / cell;
      const gy = y / cell;
      const x0 = Math.floor(gx);
      const y0 = Math.floor(gy);
      const tx = smooth(gx - x0);
      const ty = smooth(gy - y0);
      const v = (i: number, j: number): number => grid[(y0 + j) * gw + (x0 + i)];
      const top = v(0, 0) * (1 - tx) + v(1, 0) * tx;
      const bottom = v(0, 1) * (1 - tx) + v(1, 1) * tx;
      out.push(top * (1 - ty) + bottom * ty);
    }
  }
  return out;
}

/** Cells of a w by h grid that carry cloud, so that exactly `fraction` of the cells are covered. */
export function cloudCells(w: number, h: number, fraction: number, seed: number): boolean[] {
  const field = noiseField(w, h, seed);
  const order = field.map((v, i) => [v, i] as const).sort((a, b) => b[0] - a[0]);
  const covered = new Array<boolean>(w * h).fill(false);
  const n = Math.round(fraction * w * h);
  for (let k = 0; k < n; k++) covered[order[k][1]] = true;
  return covered;
}

/** "18:00" style label for minutes since midnight (may exceed 1440). */
export const clock = (minutes: number): string => {
  const m = ((Math.round(minutes) % 1440) + 1440) % 1440;
  return `${String(Math.floor(m / 60)).padStart(2, "0")}:${String(m % 60).padStart(2, "0")}`;
};
