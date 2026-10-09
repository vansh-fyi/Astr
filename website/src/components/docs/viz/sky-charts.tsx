"use client";

import { useState, type PointerEvent } from "react";
import { EDGES, nelmFromSqm, sqmFromRatio } from "@/lib/astr-zone";
import * as sky from "@/lib/astr-sky";
import { chartHeight, clock, scale } from "@/lib/viz";
import { CLOUD_HOURLY, NIGHT_START, moonRatioAt } from "@/lib/viz-data";
import { DemoFrame } from "../documentation";
import { useElementWidth } from "./use-width";

const SITES: { zone: number; r: number }[] = [
  { zone: 1, r: 0.1 },
  { zone: 3, r: 0.9 },
  { zone: 5, r: 3 },
  { zone: 7, r: 12 },
  { zone: 9, r: 60 },
];

const SHORT: Record<sky.SkyStateName, string> = {
  milkyWayVisible: "Milky Way",
  starrySkies: "Starry",
  planetsVisible: "Planets",
  fewStars: "Few stars",
  cloudy: "Cloudy",
  tooMuchLight: "Too much light",
};
/** Rank 5 is the best state. The cell fill rises with rank, and the state is always named too. */
const RANK: Record<sky.SkyStateName, number> = {
  milkyWayVisible: 5,
  starrySkies: 4,
  planetsVisible: 3,
  fewStars: 2,
  cloudy: 1,
  tooMuchLight: 0,
};
const FILL = ["var(--mag-8)", "var(--mag-6)", "var(--mag-4)", "var(--mag-3)", "var(--mag-2)", "var(--mag-1)"];

/** The hours of the example night with the Sun at or below -18 degrees: 21:00 to 04:00. */
const isDark = (hour: number): boolean => hour >= 21 && hour <= 28;

/** A night of hourly sky states for a chosen site and moon. Click an hour to set the "right now" chip. */
export function NightStrip() {
  const [siteZone, setSiteZone] = useState(3);
  const [illum, setIllum] = useState(0.78);
  const [nowHour, setNowHour] = useState(23);
  const r = SITES.find((s) => s.zone === siteZone)?.r ?? 0.9;
  const hours = Array.from({ length: 12 }, (_, i) => {
    const hour = 18 + i;
    const t = NIGHT_START + i * 60;
    return sky.hourQuality(isDark(hour), CLOUD_HOURLY[i] / 100, r, moonRatioAt(t, illum));
  });
  const night = sky.nightState(hours);
  const instant = sky.instantState(hours[nowHour - 18]);
  const why = night ? sky.why(mean(hours, "cloud", night.window), r, r + mean(hours, "bMoon", night.window)) : null;
  const CAUSE = { cloud: "cloud", moon: "the moon", light: "light pollution", none: "nothing significant" } as const;

  return (
    <DemoFrame
      controls={
        <>
          <div className="docs-chip-row" role="group" aria-label="Site zone">
            {SITES.map((s) => (
              <button key={s.zone} type="button" className="docs-chip-button" aria-pressed={s.zone === siteZone} onClick={() => setSiteZone(s.zone)}>
                Zone {s.zone}
              </button>
            ))}
          </div>
          <label className="docs-slider-inline">
            <span>Moon lit</span>
            <input type="range" min={0} max={100} step={1} value={Math.round(illum * 100)} onChange={(e) => setIllum(Number(e.target.value) / 100)} />
            <output>{Math.round(illum * 100)}%</output>
          </label>
        </>
      }
      caption="An example night: the moon rises at 21:30 and the cloud forecast clears before dawn. Dark hours run 21:00 to 04:00. Choose an hour to set the right-now chip."
    >
      <div className="viz-night">
        <div className="viz-night-chips">
          <div>
            <small>Hero: best window tonight</small>
            <strong>{night ? sky.STATE_LABELS[night.state] : "No astronomical night"}</strong>
            {night?.window && (
              <span>
                {clock(NIGHT_START + night.window[0] * 60)} to {clock(NIGHT_START + night.window[1] * 60)}
              </span>
            )}
          </div>
          <div>
            <small>Chip: right now at {String(nowHour % 24).padStart(2, "0")}:00</small>
            <strong>{instant ? sky.STATE_LABELS[instant] : "Twilight or day"}</strong>
          </div>
          <div>
            <small>Limiting factor</small>
            <strong>{why ? CAUSE[why.primary] : "none"}</strong>
          </div>
        </div>
        <ol className="viz-hours">
          {hours.map((h, i) => {
            const hour = 18 + i;
            const state = h.dark ? sky.skyState(h.cloud, h.rArt, h.rArt + h.bMoon) : null;
            const inWindow = night?.window && i >= night.window[0] && i < night.window[1];
            return (
              <li key={hour} data-window={inWindow || undefined} data-now={hour === nowHour || undefined}>
                <button type="button" onClick={() => setNowHour(hour)} aria-label={`${String(hour % 24).padStart(2, "0")}:00`}>
                  <small>{String(hour % 24).padStart(2, "0")}</small>
                  <span className="viz-hours-bar" style={{ opacity: state ? FILL[RANK[state]] : "var(--mag-10)" }} />
                  <em>{state ? SHORT[state] : "twilight"}</em>
                  <b>{h.dark ? h.nelm.toFixed(1) : "–"}</b>
                </button>
              </li>
            );
          })}
        </ol>
      </div>
      <p className="viz-key">
        Bottom figure: effective limiting magnitude. Outlined hours are the best window. Cloud is the hourly forecast, the moon is
        added with the moonlight model, and the states follow the rules above.
      </p>
    </DemoFrame>
  );
}

function mean(hours: sky.SkyHour[], key: "cloud" | "bMoon", window: [number, number] | null): number {
  const span = window ? hours.slice(window[0], window[1]) : hours.filter((h) => h.dark);
  return span.reduce((a, h) => a + h[key], 0) / span.length;
}

/** How far the moon pulls down the sky brightness as it climbs, for three phases, over the state bands. */
export function MoonCostChart() {
  const [ref, w] = useElementWidth<HTMLDivElement>(610);
  const h = chartHeight(w) + 40;
  const [site, setSite] = useState(SITES[0]);
  const [at, setAt] = useState(45);
  const pad = { l: 36, r: 8, t: 10, b: 28 };
  const x = scale(0, 90, pad.l, w - pad.r);
  const y = scale(22.2, 16.6, pad.t, h - pad.b);
  const curves = [
    { name: "Full moon", illum: 1, dash: "" },
    { name: "Half moon", illum: 0.5, dash: "dash" },
    { name: "10% crescent", illum: 0.1, dash: "dot" },
  ];
  const sqmAt = (illum: number, alt: number): number => {
    const b =
      alt > 0
        ? sky.moonRatio({ obsZenithDeg: 0, moonZenithDeg: 90 - alt, separationDeg: 90 - alt, phaseAngleDeg: sky.phaseAngleFromIllumination(illum), kV: 0.15 })
        : 0;
    return sky.sqmEffective(site.r, b);
  };
  const alts = [0.5, ...Array.from({ length: 45 }, (_, i) => (i + 1) * 2)];
  // State boundaries: the effective ratio crosses zone edges 1.28, 5.12 and 20.48.
  const bands = [
    { edge: EDGES[2], name: "Milky Way above" },
    { edge: EDGES[4], name: "Starry above" },
    { edge: EDGES[6], name: "Planets above, Few stars below" },
  ];
  function move(e: PointerEvent<SVGSVGElement>): void {
    const box = e.currentTarget.getBoundingClientRect();
    const f = (e.clientX - box.left) / box.width;
    setAt(Math.max(0, Math.min(90, Math.round(((f * w - pad.l) / (w - pad.l - pad.r)) * 90))));
  }
  return (
    <DemoFrame
      controls={
        <div className="docs-chip-row" role="group" aria-label="Site zone">
          {SITES.slice(0, 4).map((s) => (
            <button key={s.zone} type="button" className="docs-chip-button" aria-pressed={s.zone === site.zone} onClick={() => setSite(s)}>
              Zone {s.zone}
            </button>
          ))}
        </div>
      }
      caption="Effective sky brightness at the zenith as the moon climbs, with extinction k = 0.15. The horizontal lines are where the state changes. The model has the moon at nearly full strength as soon as it clears the horizon, so the curves start low. Move over the chart to read the values."
    >
      <div ref={ref} className="viz-chart">
        <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} onPointerMove={move} role="img" aria-label="Sky brightness against moon altitude">
          {bands.map((b) => {
            const sqm = sqmFromRatio(b.edge);
            return (
              <g key={b.edge}>
                <line className="viz-grid" x1={pad.l} x2={w - pad.r} y1={y(sqm)} y2={y(sqm)} />
                <text className="viz-text" x={w - pad.r} y={y(sqm) - 4} textAnchor="end">
                  {sqm.toFixed(1)} · {b.name}
                </text>
              </g>
            );
          })}
          {[22, 21, 20, 19, 18, 17].map((v) => (
            <text key={v} className="viz-text" x={pad.l - 6} y={y(v) + 3} textAnchor="end">
              {v}
            </text>
          ))}
          {[0, 30, 60, 90].map((a) => (
            <text key={a} className="viz-text" x={x(a)} y={h - 8} textAnchor="middle">
              {a}°
            </text>
          ))}
          <line className="viz-scrub" x1={x(at)} x2={x(at)} y1={pad.t} y2={h - pad.b} />
          {curves.map((c) => (
            <path
              key={c.name}
              className={`viz-line viz-line-${c.dash || "solid"}`}
              d={alts.map((a, i) => `${i === 0 ? "M" : "L"}${x(a)} ${y(sqmAt(c.illum, a))}`).join(" ")}
            />
          ))}
        </svg>
      </div>
      <dl className="docs-readoutgrid viz-readout">
        <div><dt>Moon altitude</dt><dd>{at}°</dd></div>
        {curves.map((c) => (
          <div key={c.name}>
            <dt>{c.name}</dt>
            <dd>
              {sqmAt(c.illum, at).toFixed(1)} · NELM {nelmFromSqm(sqmAt(c.illum, at)).toFixed(1)}
            </dd>
          </div>
        ))}
      </dl>
      <p className="viz-key">
        Site: zone {site.zone}, so the sky starts at {sky.sqmEffective(site.r).toFixed(1)} mag/arcsec² with no moon. The values
        are the sky brightness in mag/arcsec² and the limiting magnitude. Solid: full moon. Dashed: half. Dotted: 10% crescent.
      </p>
    </DemoFrame>
  );
}

/** The skyglow kernel: contribution of one lit pixel against distance, on log axes, for two scatter fractions. */
export function KernelChart({
  fractions,
  scaleKm,
  refKm,
  power,
  maxKm,
  radiance = 40,
}: {
  fractions: { value: number; label: string; dash: boolean }[];
  scaleKm: number;
  refKm: number;
  power: number;
  maxKm: number;
  radiance?: number;
}) {
  const [ref, w] = useElementWidth<HTMLDivElement>(610);
  const h = chartHeight(w) + 30;
  const pad = { l: 46, r: 10, t: 10, b: 28 };
  const x = scale(Math.log10(1), Math.log10(100), pad.l, w - pad.r);
  const y = scale(1, -6, pad.t, h - pad.b);
  const k = (F: number, d: number): number => (F * Math.exp(-d / scaleKm)) / (1 + (d / refKm) ** power);
  const ds = Array.from({ length: 81 }, (_, i) => 10 ** (i / 40));
  return (
    <figure className="viz-kernel">
      <div ref={ref} className="viz-chart">
        <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} role="img" aria-label="Skyglow contribution against distance">
          {[1, 0, -1, -2, -3, -4, -5, -6].map((e) => (
            <g key={e}>
              <line className="viz-grid" x1={pad.l} x2={w - pad.r} y1={y(e)} y2={y(e)} />
              <text className="viz-text" x={pad.l - 6} y={y(e) + 3} textAnchor="end">
                {e === 0 ? "1" : `1e${e}`}
              </text>
            </g>
          ))}
          {[1, 2, 5, 10, 20, 50, 100].map((d) => (
            <text key={d} className="viz-text" x={x(Math.log10(d))} y={h - 8} textAnchor="middle">
              {d}
            </text>
          ))}
          <line className="viz-moonrise" x1={x(Math.log10(maxKm))} x2={x(Math.log10(maxKm))} y1={pad.t} y2={h - pad.b} />
          <text className="viz-text viz-text-strong" x={x(Math.log10(maxKm)) - 6} y={pad.t + 12} textAnchor="end">
            kernel stops at {maxKm} km
          </text>
          {fractions.map((f) => (
            <path
              key={f.label}
              className={`viz-line viz-line-${f.dash ? "dash" : "solid"}`}
              d={ds
                .filter((d) => d <= maxKm)
                .map((d, i) => `${i === 0 ? "M" : "L"}${x(Math.log10(d))} ${y(Math.log10(radiance * k(f.value, d)))}`)
                .join(" ")}
            />
          ))}
        </svg>
      </div>
      <figcaption className="viz-key">
        Contribution to the sky of one lit pixel of {radiance} nW/cm²/sr (vertical, nW/cm²/sr, log scale) against distance in
        kilometres (horizontal, log scale). {fractions.map((f) => `${f.dash ? "Dashed" : "Solid"}: ${f.label}`).join(". ")}.
      </figcaption>
    </figure>
  );
}
