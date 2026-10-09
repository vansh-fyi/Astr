import { readSource } from "./source";
import * as zone from "./astr-zone";
import * as sky from "./astr-sky";

type J = Record<string, any>; // eslint-disable-line @typescript-eslint/no-explicit-any
const close = (a: number, b: number, tol: number, what: string): void => {
  if (!(Math.abs(a - b) <= tol)) throw new Error(`Vector mismatch in ${what}: got ${a}, expected ${b}`);
};
const eq = (a: unknown, b: unknown, what: string): void => {
  if (a !== b) throw new Error(`Vector mismatch in ${what}: got ${String(a)}, expected ${String(b)}`);
};

let checked = false;

/**
 * Holds the TypeScript ports to the same test vectors that scripts/test_astr_zone.py, scripts/test_astr_sky.py
 * and the Dart tests run. Called while rendering the pages, so a disagreement fails the build.
 */
export function assertAstrVectors(): void {
  if (checked) return;
  const z: J = JSON.parse(readSource("test/fixtures/astr_zone_scale.vectors.json"));
  const s: J = JSON.parse(readSource("test/fixtures/astr_sky_model.vectors.json"));

  zone.EDGES.forEach((e, i) => eq(e, z.edges[i], `zone edge ${i}`));
  for (const c of z.ratio_to_zone) eq(zone.zoneFromRatio(c.r), c.zone, `zone(${c.r})`);
  for (const c of z.ratio_to_sqm.cases) close(zone.sqmFromRatio(c.r), c.sqm, z.ratio_to_sqm.tolerance, "sqm");
  for (const c of z.sqm_to_ratio.cases) close(zone.ratioFromSqm(c.sqm), c.r, z.sqm_to_ratio.tolerance, "ratio");
  for (const c of z.sqm_to_nelm.cases) close(zone.nelmFromSqm(c.sqm), c.nelm, z.sqm_to_nelm.tolerance, "nelm");
  for (const c of z.artificial_ucd.cases) close(zone.artificialUcdFromRatio(c.r), c.ucd, z.artificial_ucd.tolerance, "ucd");
  for (const c of z.legacy.cases) {
    eq(zone.legacyZoneFromRadiance(c.radiance), c.legacy_zone, `legacy zone(${c.radiance})`);
    close(zone.legacyRatioFromRadiance(c.radiance), c.ratio, z.legacy.tolerance, "legacy ratio");
    eq(zone.zoneFromRatio(zone.legacyRatioFromRadiance(c.radiance)), c.ladder_zone, `ladder zone(${c.radiance})`);
  }

  const a = s.anchor;
  close(
    sky.moonBrightnessV({ obsZenithDeg: a.obs_zenith, moonZenithDeg: a.moon_zenith, separationDeg: a.separation, phaseAngleDeg: a.phase_angle, kV: a.k_v }),
    a.v,
    a.tolerance,
    "Krisciunas & Schaefer anchor",
  );
  const geometry = (c: J): sky.MoonGeometry => ({
    obsZenithDeg: c.obs_zenith, moonZenithDeg: c.moon_zenith, separationDeg: c.separation, phaseAngleDeg: c.phase_angle, kV: c.k_v,
  });
  for (const c of s.scattering_airmass.cases) close(sky.scatteringAirmass(c.zenith), c.x, s.scattering_airmass.tolerance, "airmass");
  for (const c of s.phase_angle_from_illumination.cases) close(sky.phaseAngleFromIllumination(c.illumination), c.degrees, s.phase_angle_from_illumination.tolerance, "phase angle");
  for (const c of s.pressure_ratio.cases) close(sky.pressureRatio(c.elevation_m), c.ratio, s.pressure_ratio.tolerance, "pressure");
  for (const c of s.extinction_k_v.cases) close(sky.extinctionKV(c.aod550, c.elevation_m), c.k, s.extinction_k_v.tolerance, "extinction");
  for (const c of s.moon_brightness_v.cases) close(sky.moonBrightnessV(geometry(c)), c.v, s.moon_brightness_v.tolerance, "moon V");
  for (const c of s.moon_ratio.cases) close(sky.moonRatio(geometry(c)), c.ratio, s.moon_ratio.tolerance, "moon ratio");
  for (const c of s.angular_separation.cases) close(sky.angularSeparationDeg(c.alt1, c.az1, c.alt2, c.az2), c.degrees, s.angular_separation.tolerance, "separation");
  for (const c of s.sqm_effective.cases) close(sky.sqmEffective(c.r_art, c.b_moon), c.sqm, s.sqm_effective.tolerance, "sqm_eff");
  for (const c of s.relative_star_count.cases) close(sky.relativeStarCount(c.nelm), c.relative, s.relative_star_count.tolerance, "star count");
  for (const c of s.sky_state) eq(sky.skyState(c.cloud, c.r_art, c.r_eff), c.state, `state(${c.cloud},${c.r_art},${c.r_eff})`);
  for (const c of s.night_state.cases) {
    const hours = c.hours.map((h: [boolean, number, number, number]) => sky.hourQuality(...h));
    const res = sky.nightState(hours);
    eq(res ? res.state : null, c.state, `night: ${c.name}`);
    eq(JSON.stringify(res?.window ?? null), JSON.stringify(c.window), `window: ${c.name}`);
  }
  for (const c of s.instant_state) eq(sky.instantState(sky.hourQuality(...(c.hour as [boolean, number, number, number]))), c.state, "instant");
  for (const c of s.why.cases) {
    const w = sky.why(c.cloud, c.r_art, c.r_eff);
    eq(w.primary, c.primary, "why");
    close(w.lightLoss, c.light_loss, s.why.tolerance, "light loss");
    close(w.moonLoss, c.moon_loss, s.why.tolerance, "moon loss");
  }
  for (const c of s.moon_hours.cases) eq(JSON.stringify(sky.moonHours(c.dark, c.moon_altitude)), JSON.stringify([c.up, c.down]), "moon hours");
  checked = true;
}
