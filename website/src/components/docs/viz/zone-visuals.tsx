import { EDGES, LEGACY_THRESHOLDS, legacyRatioFromRadiance, nelmFromSqm, sqmFromRatio } from "@/lib/astr-zone";
import { rng } from "@/lib/viz";

const NATURAL_NELM = nelmFromSqm(22);
const SLOPE = 0.48;

/** One fixed set of stars. Magnitudes follow the star-count law, so how many show up at a given limit is physical. */
const STARS = (() => {
  const rand = rng(21);
  return Array.from({ length: 280 }, () => ({
    x: rand() * 100,
    y: rand() * 160,
    mag: NATURAL_NELM + Math.log10(rand()) / SLOPE,
  }));
})();

/** Zone r at the middle of each zone (geometric), used to describe the sky of a zone. */
const zoneMiddle = (zone: number): number => {
  const lo = zone === 1 ? 0.1 : EDGES[zone - 2];
  const hi = zone === 9 ? EDGES[7] * 2 : EDGES[zone - 1];
  return Math.sqrt(lo * hi);
};

/** The lightest stops at the ladder steps used for a zone's sky glow: darker sky for low zones. */
const glowStep = (zone: number): number => [10, 9, 8, 7, 6, 5, 4, 3, 3][zone - 1];

/**
 * Nine illustrated skies, one per zone. The brightness of the glow rises with the zone, and the stars drawn are
 * those brighter than the zone's limiting magnitude, so the count really does fall as light pollution rises.
 * The star positions are random but fixed, so this illustrates the count, not any real part of the sky.
 */
export function ZoneSkies() {
  return (
    <figure className="viz-zones">
      <div className="viz-zones-grid">
        {Array.from({ length: 9 }, (_, i) => i + 1).map((zone) => {
          const r = zoneMiddle(zone);
          const sqm = sqmFromRatio(r);
          const nelm = nelmFromSqm(sqm);
          const stars = STARS.filter((s) => s.mag <= nelm);
          return (
            <div className="viz-zone" key={zone}>
              <div className="viz-zone-sky" style={{ ["--glow" as string]: `var(--mag-${glowStep(zone)})` }}>
                <svg viewBox="0 0 100 160" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
                  {zone <= 4 && (
                    <path
                      className="viz-milkyway"
                      style={{ opacity: zone <= 3 ? "var(--mag-4)" : "var(--mag-7)" }}
                      d="M-10 150 C 20 100, 60 70, 110 -10 L 110 20 C 70 90, 30 130, -10 175 Z"
                    />
                  )}
                  {stars.map((s, i) => (
                    <circle
                      key={i}
                      className="viz-star"
                      cx={s.x}
                      cy={s.y}
                      r={0.55 + Math.max(0, nelm - s.mag) * 0.32}
                    />
                  ))}
                </svg>
                <div className="viz-zone-horizon gradient-extinction [--grad-dir:to_top] [--grad-color:var(--color-space-grey-50)]" />
              </div>
              <figcaption>
                <strong>{zone}</strong>
                <span>{nelm.toFixed(1)}</span>
                <small>{stars.length} stars</small>
              </figcaption>
            </div>
          );
        })}
      </div>
      <p className="viz-key">
        Zone, limiting magnitude and the stars drawn out of {STARS.length}. Milky Way band shown while it can be seen.
        Illustration: star positions are random but fixed.
      </p>
    </figure>
  );
}

/** A log axis of the artificial/natural ratio r with the zone edges, and optionally a second row of edges to compare. */
export function LadderAxis({ legacy = false }: { legacy?: boolean }) {
  const compare = legacy ? [...LEGACY_THRESHOLDS].reverse().map(([radiance]) => legacyRatioFromRadiance(radiance)) : undefined;
  const lo = Math.log10(0.1);
  const hi = Math.log10(100);
  const at = (r: number): string => `${((Math.log10(r) - lo) / (hi - lo)) * 100}%`;
  const bands = [0.1, ...EDGES, 100];
  return (
    <figure className="viz-axis">
      <div className="viz-axis-bands" role="img" aria-label="Zone bands on a logarithmic axis of the ratio r">
        {bands.slice(0, -1).map((from, i) => (
          <div
            key={i}
            className="viz-axis-band"
            style={{ left: at(from), width: `calc(${at(bands[i + 1])} - ${at(from)})` }}
          >
            <span>{i + 1}</span>
          </div>
        ))}
      </div>
      <div className="viz-axis-ticks">
        {EDGES.map((e) => (
          <div key={e} className="viz-axis-tick" style={{ left: at(e) }}>
            <i />
            <span>{e}</span>
            <small>{sqmFromRatio(e).toFixed(2)}</small>
          </div>
        ))}
        {compare &&
          compare.map((e) => (
            <div key={`c${e}`} className="viz-axis-tick viz-axis-compare" style={{ left: at(e) }}>
              <i />
              <span>{e}</span>
            </div>
          ))}
      </div>
      <figcaption className="viz-key">
        Ratio r on a logarithmic axis; the numbers on the ladder are the zone edges, and the small figure under each is
        the sky brightness in mag/arcsec² at that edge.
        {compare && " The lower row marks where the legacy thresholds fall, in the same units."}
      </figcaption>
    </figure>
  );
}
