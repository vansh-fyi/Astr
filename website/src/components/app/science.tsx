"use client";

import { useState, type PointerEvent, type ReactNode } from "react";
import "./app-ui.css";
import { EDGES, LEGACY_THRESHOLDS, legacyRatioFromRadiance, nelmFromSqm, sqmFromRatio } from "@/lib/astr-zone";
import * as sky from "@/lib/astr-sky";
import { clock } from "@/lib/viz";
import { CLOUD_HOURLY, NIGHT_START, moonRatioAt } from "@/lib/viz-data";
import { useElementWidth } from "../docs/viz/use-width";
import { F, GRAPH, T, stop } from "./tokens";

const SITES: { zone: number; r: number }[] = [
  { zone: 1, r: 0.1 },
  { zone: 3, r: 0.9 },
  { zone: 5, r: 3 },
  { zone: 7, r: 12 },
  { zone: 9, r: 60 },
];

const LINE_DASH = { solid: undefined, dash: `${F.f8} ${F.f5}`, dot: `${F.f2} ${F.f5}` } as const;
type LineForm = keyof typeof LINE_DASH;

const pct = (value: number): string => String(Math.round(value));

function Chips<V extends string | number>({ label, options, value, onChange }: { label: string; options: { value: V; label: string }[]; value: V; onChange: (v: V) => void }) {
  return (
    <div className="docs-chip-row" role="group" aria-label={label}>
      {options.map((o) => (
        <button key={String(o.value)} type="button" className="app-ui app-button is-glass is-sm" aria-pressed={o.value === value} onClick={() => onChange(o.value)}>
          {o.label}
        </button>
      ))}
    </div>
  );
}

function Readout({ items }: { items: { label: string; value: ReactNode }[] }) {
  return (
    <dl className="app-ui app-readout">
      {items.map((i) => (
        <div key={i.label}>
          <dt className="app-label-sm">{i.label}</dt>
          <dd className="app-label-md">{i.value}</dd>
        </div>
      ))}
    </dl>
  );
}

// ---------------------------------------------------------------------------------------------------------------

const SHORT: Record<sky.SkyStateName, string> = {
  milkyWayVisible: "Milky Way",
  starrySkies: "Starry",
  planetsVisible: "Planets",
  fewStars: "Few stars",
  cloudy: "Cloudy",
  tooMuchLight: "Too much light",
};
/** Rank 5 is the best state. The bar fill rises with rank on the Pogson steps, and the state is always named too. */
const RANK: Record<sky.SkyStateName, number> = { milkyWayVisible: 5, starrySkies: 4, planetsVisible: 3, fewStars: 2, cloudy: 1, tooMuchLight: 0 };
const RANK_MAG = [8, 6, 5, 4, 3, 2];
const isDark = (hour: number): boolean => hour >= 21 && hour <= 28;

function mean(hours: sky.SkyHour[], key: "cloud" | "bMoon", window: [number, number] | null): number {
  const span = window ? hours.slice(window[0], window[1]) : hours.filter((h) => h.dark);
  return span.reduce((a, h) => a + h[key], 0) / span.length;
}

/** A night of hourly sky states for a chosen site and moon. Choose an hour to set the right-now chip. */
export function AppNightStrip() {
  const [siteZone, setSiteZone] = useState(3);
  const [illum, setIllum] = useState(0.78);
  const [nowHour, setNowHour] = useState(23);
  const r = SITES.find((s) => s.zone === siteZone)?.r ?? 0.9;
  const hours = Array.from({ length: 12 }, (_, i) => sky.hourQuality(isDark(18 + i), CLOUD_HOURLY[i] / 100, r, moonRatioAt(NIGHT_START + i * 60, illum)));
  const night = sky.nightState(hours);
  const instant = sky.instantState(hours[nowHour - 18]);
  const why = night ? sky.why(mean(hours, "cloud", night.window), r, r + mean(hours, "bMoon", night.window)) : null;
  const CAUSE = { cloud: "cloud", moon: "the moon", light: "light pollution", none: "nothing significant" } as const;
  const hh = (h: number): string => String(h % 24).padStart(2, "0");

  return (
    <div className="app-ui app-stage is-column app-sci">
      <div className="app-sci-controls">
        <Chips label="Site zone" value={siteZone} onChange={setSiteZone} options={SITES.map((s) => ({ value: s.zone, label: `Zone ${s.zone}` }))} />
        <label className="app-pg-range">
          <span className="app-label-sm">Moon lit</span>
          <input type="range" min={0} max={100} step={1} value={Math.round(illum * 100)} onChange={(e) => setIllum(Number(e.target.value) / 100)} />
          <output className="app-label-md">{pct(illum * 100)}%</output>
        </label>
      </div>
      <Readout
        items={[
          { label: "Best window tonight", value: night ? `${sky.STATE_LABELS[night.state]}${night.window ? `, ${clock(NIGHT_START + night.window[0] * 60)} to ${clock(NIGHT_START + night.window[1] * 60)}` : ""}` : "No astronomical night" },
          { label: `Right now, ${hh(nowHour)}:00`, value: instant ? sky.STATE_LABELS[instant] : "Twilight or day" },
          { label: "Limiting factor", value: why ? CAUSE[why.primary] : "none" },
        ]}
      />
      <ol className="app-hours">
        {hours.map((h, i) => {
          const hour = 18 + i;
          const state = h.dark ? sky.skyState(h.cloud, h.rArt, h.rArt + h.bMoon) : null;
          const inWindow = Boolean(night?.window && i >= night.window[0] && i < night.window[1]);
          return (
            <li key={hour}>
              <button type="button" className="app-hour" aria-pressed={hour === nowHour} data-window={inWindow || undefined} onClick={() => setNowHour(hour)} aria-label={`${hh(hour)}:00`}>
                <span className="app-label-sm">{hh(hour)}</span>
                <i style={{ opacity: state ? `var(--mag-${RANK_MAG[RANK[state]]})` : "var(--mag-10)" }} />
                <span className="app-label-sm">{state ? SHORT[state] : "twilight"}</span>
                <b className="app-label-md">{h.dark ? h.nelm.toFixed(1) : "–"}</b>
              </button>
            </li>
          );
        })}
      </ol>
      <p className="app-chart-key">
        An example night: the moon rises at 21:30 and the cloud forecast clears before dawn. Dark hours run 21:00 to 04:00. The
        bottom figure is the effective limiting magnitude, and the outlined hours are the best window.
      </p>
    </div>
  );
}

// ---------------------------------------------------------------------------------------------------------------

interface Series {
  name: string;
  form: LineForm;
  points: (readonly [number, number])[];
}

/** The chart frame shared by the moon-cost and kernel charts: grid, axes, series told apart by line form. */
function LineChart({
  w,
  h,
  pad,
  yTicks,
  xTicks,
  series,
  guides = [],
  scrub,
  label,
  onMove,
}: {
  w: number;
  h: number;
  pad: { l: number; r: number; t: number; b: number };
  yTicks: { y: number; label: string }[];
  xTicks: { x: number; label: string }[];
  series: Series[];
  guides?: { y?: number; x?: number; label: string }[];
  scrub?: number;
  label: string;
  onMove?: (e: PointerEvent<SVGSVGElement>) => void;
}) {
  return (
    <svg viewBox={`0 0 ${w} ${h}`} height={h} role="img" aria-label={label} onPointerMove={onMove}>
      {yTicks.map((t) => (
        <g key={t.label}>
          <line x1={pad.l} x2={w - pad.r} y1={t.y} y2={t.y} stroke={stop(GRAPH.ink, 6)} />
          <text x={pad.l - F.f8} y={t.y + F.f3} fontSize={T.s2n} fill={stop("space-grey-300")} textAnchor="end">{t.label}</text>
        </g>
      ))}
      {xTicks.map((t) => (
        <text key={t.label} x={t.x} y={h - F.f13} fontSize={T.s2n} fill={stop("space-grey-300")} textAnchor="middle">{t.label}</text>
      ))}
      {guides.map((g) => (
        <g key={g.label}>
          {g.y !== undefined && <line x1={pad.l} x2={w - pad.r} y1={g.y} y2={g.y} stroke={stop("deep-space-200", 3)} strokeDasharray={`${F.f3} ${F.f5}`} />}
          {g.y !== undefined && <text x={w - pad.r - F.f5} y={g.y - F.f5} fontSize={T.s2n} fill={stop("deep-space-50")} textAnchor="end">{g.label}</text>}
          {g.x !== undefined && <line x1={g.x} x2={g.x} y1={pad.t} y2={h - pad.b} stroke={stop("deep-space-200", 3)} strokeDasharray={`${F.f3} ${F.f5}`} />}
          {g.x !== undefined && <text x={g.x - F.f5} y={pad.t + F.f13} fontSize={T.s2n} fill={stop("deep-space-50")} textAnchor="end">{g.label}</text>}
        </g>
      ))}
      {scrub !== undefined && <line x1={scrub} x2={scrub} y1={pad.t} y2={h - pad.b} stroke={stop(GRAPH.ink, 3)} />}
      {series.map((s) => (
        <path key={s.name} d={s.points.map(([px, py], i) => `${i === 0 ? "M" : "L"}${px} ${py}`).join(" ")} fill="none" stroke={stop("deep-space-200")} strokeWidth={F.f3} strokeLinecap="round" strokeLinejoin="round" strokeDasharray={LINE_DASH[s.form]} />
      ))}
    </svg>
  );
}

const lin = (d0: number, d1: number, r0: number, r1: number) => (v: number): number => r0 + ((v - d0) / (d1 - d0)) * (r1 - r0);
const CHART_PAD = { l: F.f34 + F.f13, r: F.f13, t: F.f13, b: F.f34 };
const CHART_H = F.f144 + F.f89;

/** How far the moon pulls down the sky brightness as it climbs, for three phases, over the state bands. */
export function AppMoonCostChart() {
  const [ref, w] = useElementWidth<HTMLDivElement>(560);
  const [site, setSite] = useState(SITES[0]);
  const [at, setAt] = useState(45);
  const pad = CHART_PAD;
  const x = lin(0, 90, pad.l, w - pad.r);
  const y = lin(22.2, 16.6, pad.t, CHART_H - pad.b);
  const curves: { name: string; illum: number; form: LineForm }[] = [
    { name: "Full moon", illum: 1, form: "solid" },
    { name: "Half moon", illum: 0.5, form: "dash" },
    { name: "10% crescent", illum: 0.1, form: "dot" },
  ];
  const sqmAt = (illum: number, alt: number): number => {
    const b = alt > 0 ? sky.moonRatio({ obsZenithDeg: 0, moonZenithDeg: 90 - alt, separationDeg: 90 - alt, phaseAngleDeg: sky.phaseAngleFromIllumination(illum), kV: 0.15 }) : 0;
    return sky.sqmEffective(site.r, b);
  };
  const alts = [0.5, ...Array.from({ length: 45 }, (_, i) => (i + 1) * 2)];
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
    <div className="app-ui app-stage is-column app-sci">
      <Chips label="Site zone" value={site.zone} onChange={(z) => setSite(SITES.find((s) => s.zone === z) ?? SITES[0])} options={SITES.slice(0, 4).map((s) => ({ value: s.zone, label: `Zone ${s.zone}` }))} />
      <div ref={ref} className="app-chart">
        <LineChart
          w={w}
          h={CHART_H}
          pad={pad}
          label="Sky brightness against moon altitude"
          onMove={move}
          scrub={x(at)}
          yTicks={[22, 21, 20, 19, 18, 17].map((v) => ({ y: y(v), label: String(v) }))}
          xTicks={[0, 30, 60, 90].map((a) => ({ x: x(a), label: `${a}°` }))}
          guides={bands.map((b) => ({ y: y(sqmFromRatio(b.edge)), label: `${sqmFromRatio(b.edge).toFixed(1)} · ${b.name}` }))}
          series={curves.map((c) => ({ name: c.name, form: c.form, points: alts.map((a) => [x(a), y(sqmAt(c.illum, a))] as const) }))}
        />
      </div>
      <Readout items={[{ label: "Moon altitude", value: `${at}°` }, ...curves.map((c) => ({ label: `${c.name} (${c.form})`, value: `${sqmAt(c.illum, at).toFixed(1)} · NELM ${nelmFromSqm(sqmAt(c.illum, at)).toFixed(1)}` }))]} />
      <p className="app-chart-key">
        Effective sky brightness at the zenith as the moon climbs, with extinction k = 0.15, for a site in zone {site.zone} that starts at {sky.sqmEffective(site.r).toFixed(1)} mag/arcsec² with no moon. Dashed lines mark where the state changes. The model has the moon at nearly full strength as soon as it clears the horizon, so the curves start low. Move over the chart to read the values.
      </p>
    </div>
  );
}

/** The skyglow kernel: contribution of one lit pixel against distance, on log axes, for two scatter fractions. */
export function AppKernelChart({
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
  const [ref, w] = useElementWidth<HTMLDivElement>(560);
  const pad = { l: F.f55, r: F.f13, t: F.f13, b: F.f34 };
  const x = lin(0, 2, pad.l, w - pad.r);
  const y = lin(1, -6, pad.t, CHART_H - pad.b);
  const k = (f: number, d: number): number => (f * Math.exp(-d / scaleKm)) / (1 + (d / refKm) ** power);
  const ds = Array.from({ length: 81 }, (_, i) => 10 ** (i / 40)).filter((d) => d <= maxKm);
  return (
    <div className="app-ui app-stage is-column app-sci">
      <div ref={ref} className="app-chart">
        <LineChart
          w={w}
          h={CHART_H}
          pad={pad}
          label="Skyglow contribution against distance"
          yTicks={[1, 0, -1, -2, -3, -4, -5, -6].map((e) => ({ y: y(e), label: e === 0 ? "1" : `1e${e}` }))}
          xTicks={[1, 2, 5, 10, 20, 50, 100].map((d) => ({ x: x(Math.log10(d)), label: String(d) }))}
          guides={[{ x: x(Math.log10(maxKm)), label: `kernel stops at ${maxKm} km` }]}
          series={fractions.map((f) => ({ name: f.label, form: f.dash ? "dash" : "solid", points: ds.map((d) => [x(Math.log10(d)), y(Math.log10(radiance * k(f.value, d)))] as const) }))}
        />
      </div>
      <p className="app-chart-key">
        Contribution to the sky of one lit pixel of {radiance} nW/cm²/sr (vertical, nW/cm²/sr, log scale) against distance in
        kilometres (horizontal, log scale). {fractions.map((f) => `${f.dash ? "Dashed" : "Solid"}: ${f.label}`).join(". ")}.
      </p>
    </div>
  );
}

// ---------------------------------------------------------------------------------------------------------------

/** A log axis of the artificial/natural ratio r with the zone edges, and optionally a second row of edges to compare. */
export function AppLadderAxis({ legacy = false }: { legacy?: boolean }) {
  const compare = legacy ? [...LEGACY_THRESHOLDS].reverse().map(([radiance]) => legacyRatioFromRadiance(radiance)) : undefined;
  const lo = Math.log10(0.1);
  const hi = Math.log10(100);
  const at = (r: number): string => `${((Math.log10(r) - lo) / (hi - lo)) * 100}%`;
  const bands = [0.1, ...EDGES, 100];
  return (
    <div className="app-ui app-stage is-column app-sci">
      <div className="app-ladder" role="img" aria-label="Zone bands on a logarithmic axis of the ratio r">
        {bands.slice(0, -1).map((from, i) => (
          <div key={i} className="app-ladder-band" style={{ left: at(from), width: `calc(${at(bands[i + 1])} - ${at(from)})`, ["--band" as string]: `var(--mag-${9 - i})` }}>
            <span className="app-label-md">{i + 1}</span>
          </div>
        ))}
      </div>
      <div className="app-ladder-ticks">
        {EDGES.map((e) => (
          <div key={e} className="app-ladder-tick" style={{ left: at(e) }}>
            <i />
            <span className="app-label-md">{e}</span>
            <small className="app-label-sm">{sqmFromRatio(e).toFixed(2)}</small>
          </div>
        ))}
        {compare?.map((e) => (
          <div key={`c${e}`} className="app-ladder-tick is-compare" style={{ left: at(e) }}>
            <i />
            <span className="app-label-md">{Number(e.toPrecision(3))}</span>
          </div>
        ))}
      </div>
      <p className="app-chart-key">
        Ratio r on a logarithmic axis. The bands are the nine zones, and the numbers on the ladder are the zone edges with the sky
        brightness in mag/arcsec² under each.{compare && " The lower row marks where the legacy thresholds fall, in the same units."}
      </p>
    </div>
  );
}
