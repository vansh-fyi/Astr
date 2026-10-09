"use client";

import { useState, type PointerEvent } from "react";
import "./app-ui.css";
import { useElementWidth } from "../docs/viz/use-width";
import { CLOUD_HOURLY, LATITUDE, MOON_RISE_MINUTES, NIGHT_END, NIGHT_START, OBJECTS, moonAltitude, objectAltitude } from "@/lib/viz-data";
import { F, GRAPH, T, TONE_STOP, stop, type Tone } from "./tokens";
import { legendColor } from "./app-graphs";
import { GraphPill } from "./graph-pill";

const NOW = 20 * 60 + 15;
const SPAN = NIGHT_END - NIGHT_START;
const STEP = 15;
const TIMES = Array.from({ length: SPAN / STEP + 1 }, (_, i) => NIGHT_START + i * STEP);
const NOW_TOP = F.f89 - F.f8;
const HEIGHT = 233;

type Pt = readonly [number, number];

/** Cubic segments with tension 0.2, as the app draws every cloud area. */
function smooth(points: Pt[]): string {
  let d = `M${points[0][0]} ${points[0][1]}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[Math.max(0, i - 1)];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[Math.min(points.length - 1, i + 2)];
    d += ` C${p1[0] + (p2[0] - p0[0]) * 0.2} ${p1[1] + (p2[1] - p0[1]) * 0.2} ${p2[0] - (p3[0] - p1[0]) * 0.2} ${p2[1] - (p3[1] - p1[1]) * 0.2} ${p2[0]} ${p2[1]}`;
  }
  return d;
}

const hour12 = (m: number): string => {
  const h = Math.floor(m / 60) % 24;
  return `${h % 12 === 0 ? 12 : h % 12} ${h < 12 ? "AM" : "PM"}`;
};
const clock = (m: number): string => `${String(Math.floor(m / 60) % 24).padStart(2, "0")}:${String(Math.round(m % 60)).padStart(2, "0")}`;

/** Azimuth in degrees from north, through east, from latitude, declination and hour angle. */
function azimuth(dec: number, minutes: number, transit: number): number {
  const phi = (LATITUDE * Math.PI) / 180;
  const d = (dec * Math.PI) / 180;
  const H = (0.25 * (minutes - transit) * Math.PI) / 180;
  const a = Math.atan2(-Math.cos(d) * Math.sin(H), Math.sin(d) * Math.cos(phi) - Math.cos(d) * Math.sin(phi) * Math.cos(H));
  return ((a * 180) / Math.PI + 360) % 360;
}

const COMPASS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
const compass = (az: number): string => COMPASS[Math.round(az / 45) % 8];

/** Where the object is on the horizon: altitude above the line, azimuth along it, east to west. */
function HorizonView({ objectId, minutes, color }: { objectId: string; minutes: number; color: string }) {
  const [ref, w] = useElementWidth<HTMLDivElement>(560);
  const o = OBJECTS.find((x) => x.id === objectId) ?? OBJECTS[0];
  const alt = objectAltitude(o, minutes);
  const az = azimuth(o.dec, minutes, o.transit);
  const H = F.f144;
  const gy = H - F.f21;
  const pad = F.f21;
  const px = (a: number): number => ((Math.min(300, Math.max(60, a)) - 60) / 240) * (w - 2 * pad) + pad;
  const x = px(az);
  const y = gy - (Math.max(0, alt) / 90) * (gy - F.f21);
  return (
    <div ref={ref} className="app-ui app-og-horizon">
      <svg viewBox={`0 0 ${w} ${H}`} height={H} role="img" aria-label={`${o.name} at ${Math.round(alt)} degrees altitude, ${compass(az)}`}>
        <defs>
          <linearGradient id="og-ground" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0" stopColor={stop(GRAPH.ink, 5)} />
            <stop offset="1" stopColor={stop(GRAPH.ink, 10)} />
          </linearGradient>
          <filter id="og-glow"><feGaussianBlur stdDeviation={F.f3 + F.f1} /></filter>
        </defs>
        <rect x={0} y={gy} width={w} height={H - gy} fill="url(#og-ground)" />
        <line x1={0} x2={w} y1={gy} y2={gy} stroke={stop(GRAPH.ink, 3)} />
        {[30, 60].map((a) => (
          <line key={a} x1={0} x2={w} y1={gy - (a / 90) * (gy - F.f21)} y2={gy - (a / 90) * (gy - F.f21)} stroke={stop(GRAPH.ink, 6)} strokeDasharray={`${F.f3} ${F.f5}`} />
        ))}
        {[["E", 90], ["S", 180], ["W", 270]].map(([l, a]) => (
          <text key={l} x={px(Number(a))} y={H - F.f5} fontSize={T.s2n} fill={stop(GRAPH.ink, 2)} textAnchor="middle">{l}</text>
        ))}
        {alt > 0 && <line x1={x} x2={x} y1={y} y2={gy} stroke={color} strokeDasharray={`${F.f2} ${F.f3}`} />}
        {alt > 0 ? (
          <g>
            <circle cx={x} cy={y} r={F.f13} fill={color} filter="url(#og-glow)" />
            <circle cx={x} cy={y} r={F.f5} fill={stop(GRAPH.ink)} stroke={color} strokeWidth={F.f3} />
          </g>
        ) : (
          <text x={w / 2} y={gy - F.f13} fontSize={T.s1n} fill={stop(GRAPH.ink, 2)} textAnchor="middle">Below the horizon</text>
        )}
        <text x={pad} y={F.f21} fontSize={T.s2n} fill={stop(GRAPH.ink, 2)}>{clock(minutes)} · {alt > 0 ? `${alt.toFixed(0)}° ${compass(az)}` : "set"}</text>
      </svg>
    </div>
  );
}

/**
 * The app's two object graphs. "visibility" is VisibilityGraphWidget: cloud area, the moon area, the object curve
 * with glow, the current position dot, NOW, moon rise, the peak dot and a scrubber with a tooltip. "altitude" is
 * the simpler AltitudeGraph: one curve over the night with a faint cloud backdrop, a NOW dot and a scrubber.
 * `horizon` adds a strip showing where the object sits above the horizon line at the scrubbed time.
 */
export function AppObjectGraph({
  variant = "visibility",
  objectId = "high",
  tone = "deep-space",
  horizon = false,
}: {
  variant?: "visibility" | "altitude";
  objectId?: string;
  tone?: Tone;
  horizon?: boolean;
}) {
  const [ref, w] = useElementWidth<HTMLDivElement>(560);
  const [scrub, setScrub] = useState<number | null>(null);
  const o = OBJECTS.find((x) => x.id === objectId) ?? OBJECTS[0];
  const full = variant === "visibility";
  const color = stop(TONE_STOP[tone]);
  const plotH = full ? HEIGHT : HEIGHT - F.f34;
  const x = (m: number): number => ((m - NIGHT_START) / SPAN) * w;
  const objY = (a: number): number => plotH - (Math.max(0, a) / 90) * plotH * 0.7;
  const alt = (m: number): number => (full ? objectAltitude(o, m) : Math.sin(((m - NIGHT_START) / SPAN) * Math.PI) * 80);
  const altY = (m: number): number => (full ? objY(alt(m)) : plotH - Math.sin(((m - NIGHT_START) / SPAN) * Math.PI) * plotH * 0.8);

  const cloudPts: Pt[] = CLOUD_HOURLY.map((c, i) => [x(NIGHT_START + i * 60), plotH - (c / 100) * plotH] as const);
  const cloudArea = `M${cloudPts[0][0]} ${plotH} L${cloudPts[0][0]} ${cloudPts[0][1]}${smooth(cloudPts).replace(/^M\S+ \S+/, "")} L${cloudPts.at(-1)![0]} ${plotH} L${w} ${plotH} Z`;
  const objLine = "M" + TIMES.map((m) => `${x(m)} ${altY(m)}`).join(" L");
  const moonLine = "M" + TIMES.map((m) => `${x(m)} ${objY(moonAltitude(m))}`).join(" L");
  const peak = TIMES.reduce((best, m) => (alt(m) > alt(best) ? m : best), TIMES[0]);
  const nowX = x(NOW);
  const riseX = x(MOON_RISE_MINUTES);
  const mm = scrub === null ? NOW : NIGHT_START + scrub * SPAN;
  const riseY = plotH * 0.75;

  function move(e: PointerEvent<SVGSVGElement>): void {
    const box = e.currentTarget.getBoundingClientRect();
    setScrub(Math.max(0, Math.min(1, (e.clientX - box.left) / box.width)));
  }

  return (
    <div className="app-ui app-og">
      {full && (
        <div className="app-og-head">
          <strong>Visibility</strong>
          <span className="app-legend" style={{ margin: 0 }}>
            <span><i style={{ background: legendColor("object", color) }} />OBJECT</span>
            <span><i style={{ background: legendColor("moon") }} />MOON</span>
            <span><i style={{ background: legendColor("cloud") }} />CLOUD</span>
          </span>
        </div>
      )}
      <div ref={ref} className="app-og-plot" style={{ height: HEIGHT, backgroundImage: full ? `linear-gradient(to bottom, color-mix(in srgb, ${color} var(--mag-5), transparent), transparent)` : undefined }}>
        <svg viewBox={`0 0 ${w} ${HEIGHT}`} height={HEIGHT} role="img" aria-label={`${o.name} visibility over the night`} onPointerMove={move} onPointerDown={move} onPointerLeave={() => setScrub(null)}>
          <defs>
            <filter id="og-curve-glow" x="-10%" y="-30%" width="120%" height="160%"><feGaussianBlur stdDeviation={F.f3} /></filter>
            <linearGradient id="og-cloud" x1="0" x2="0" y1="0" y2="1">
              <stop offset="0" stopColor={stop(GRAPH.cloud, 3)} />
              <stop offset="1" stopColor={stop(GRAPH.cloud, 6)} />
            </linearGradient>
            <linearGradient id="og-now" gradientUnits="userSpaceOnUse" x1="0" x2="0" y1={NOW_TOP} y2={plotH}>
              <stop offset="0" stopColor={stop(GRAPH.now, 1)} />
              <stop offset="1" stopColor={stop(GRAPH.now, 10)} />
            </linearGradient>
          </defs>
          {full ? (
            <>
              <path d={cloudArea} fill="url(#og-cloud)" />
              <path d={smooth(cloudPts)} fill="none" stroke={stop(GRAPH.cloud, 3)} strokeWidth={F.f2} />
              <path d={`M0 ${plotH} L${moonLine.slice(1)} L${w} ${plotH} Z`} fill={stop(GRAPH.moon, 4)} />
              <path d={moonLine} fill="none" stroke={stop(GRAPH.moonLine, 2)} strokeWidth={F.f2} />
              <path d={objLine} fill="none" stroke={color} strokeWidth={F.f5} filter="url(#og-curve-glow)" />
              <path d={objLine} fill="none" stroke={color} strokeWidth={F.f3} strokeLinecap="round" strokeLinejoin="round" />
              <g>
                <circle cx={nowX} cy={objY(alt(NOW))} r={F.f8} fill={color} filter="url(#og-curve-glow)" />
                <circle cx={nowX} cy={objY(alt(NOW))} r={F.f5} fill={stop(GRAPH.ink)} stroke={color} strokeWidth={F.f3} />
              </g>
              <line x1={riseX} x2={riseX} y1={plotH} y2={riseY + F.f8} stroke={stop(GRAPH.moonLine, 2)} />
              <circle cx={riseX} cy={riseY + F.f5} r={F.f8} fill={stop(GRAPH.rise, 3)} />
              <circle cx={riseX} cy={riseY + F.f5} r={F.f3} fill={stop(GRAPH.rise)} />
              <GraphPill x={riseX + F.f13} y={riseY + F.f5} text="MOON RISE" tracking={1} color={stop("deep-space-50")} fill={stop(GRAPH.moon, 4)} stroke={stop(GRAPH.moonLine, 3)} />
              <rect x={nowX - F.f2} y={NOW_TOP} width={F.f3 + F.f1} height={plotH - NOW_TOP} fill="url(#og-now)" filter="url(#og-curve-glow)" />
              <rect x={nowX - F.f1 / 2} y={NOW_TOP} width={F.f1} height={plotH - NOW_TOP} fill="url(#og-now)" />
              <circle className="app-pulse" cx={nowX} cy={NOW_TOP} r={F.f8} fill={stop(GRAPH.now, 2)} />
              <circle cx={nowX} cy={NOW_TOP} r={F.f3} fill={stop(GRAPH.now)} />
              <GraphPill x={nowX + F.f13} y={NOW_TOP} text="NOW" weight={700} color={stop(GRAPH.now)} fill={stop(GRAPH.now, 5)} stroke={stop(GRAPH.now, 3)} />
              {alt(peak) > 0 && <circle cx={x(peak)} cy={altY(peak)} r={F.f5} fill={color} />}
            </>
          ) : (
            <>
              <path d={`M0 ${plotH} L0 ${plotH * 0.2} C${w * 0.125} ${plotH * 0.2} ${w * 0.125} ${plotH * 0.7} ${w * 0.25} ${plotH * 0.7} C${w * 0.375} ${plotH * 0.7} ${w * 0.375} ${plotH * 0.9} ${w * 0.5} ${plotH * 0.9} C${w * 0.625} ${plotH * 0.9} ${w * 0.625} ${plotH * 0.4} ${w * 0.75} ${plotH * 0.4} C${w * 0.875} ${plotH * 0.4} ${w * 0.875} ${plotH * 0.1} ${w} ${plotH * 0.1} L${w} ${plotH} Z`} fill={stop(GRAPH.cloud, 6)} />
              <path d={objLine} fill="none" stroke={color} strokeWidth={F.f3} strokeLinecap="round" />
              <circle cx={w / 2} cy={plotH - plotH * 0.8} r={F.f5} fill={color} />
              <circle cx={w * 0.2} cy={plotH - Math.sin(0.2 * Math.PI) * plotH * 0.8} r={F.f5} fill={stop(GRAPH.ink)} />
              <circle cx={w * 0.2} cy={plotH - Math.sin(0.2 * Math.PI) * plotH * 0.8} r={F.f2} fill={color} />
              {[0, 1, 2, 3, 4].map((i) => (
                <text key={i} x={(w * i) / 4} y={HEIGHT - F.f13} fontSize={T.s2n} fontWeight={i === 2 ? 700 : 400} fill={i === 2 ? stop(GRAPH.ink) : stop("space-grey-300")} textAnchor={i === 0 ? "start" : i === 4 ? "end" : "middle"}>{clock(NIGHT_START + (SPAN * i) / 4)}</text>
              ))}
            </>
          )}
          {scrub !== null && (
            <g>
              <line x1={scrub * w} x2={scrub * w} y1={0} y2={plotH} stroke={full ? color : stop(GRAPH.ink, 1)} />
              {!full && (
                <>
                  <circle cx={scrub * w} cy={altY(mm)} r={F.f8} fill={stop(GRAPH.ink)} />
                  <circle cx={scrub * w} cy={altY(mm)} r={F.f5} fill={color} />
                </>
              )}
            </g>
          )}
        </svg>
        {scrub !== null && (
          <div className="app-og-tip" style={{ left: Math.max(0, Math.min(w - F.f144, scrub * w)) }}>
            <strong>{clock(mm)}</strong>
            <span style={{ color }}>Alt: {Math.max(0, alt(mm)).toFixed(1)}°</span>
          </div>
        )}
      </div>
      {full && (
        <div className="app-og-axis">
          {[0, 1, 2, 3, 4].map((i) => (
            <span key={i}>{hour12(NIGHT_START + (SPAN * i) / 4)}</span>
          ))}
        </div>
      )}
      {horizon && <HorizonView objectId={objectId} minutes={mm} color={color} />}
    </div>
  );
}
