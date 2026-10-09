"use client";

import { useState, type PointerEvent } from "react";
import "./app-ui.css";
import { useElementWidth } from "../docs/viz/use-width";
import { CLOUD_HOURLY, LATITUDE, MOON_RISE_MINUTES, NIGHT_END, NIGHT_START, OBJECTS, moonAltitude, objectAltitude } from "@/lib/viz-data";

const NOW = 20 * 60 + 15;
const SPAN = NIGHT_END - NIGHT_START;
const STEP = 15;
const TIMES = Array.from({ length: SPAN / STEP + 1 }, (_, i) => NIGHT_START + i * STEP);
const NOW_TOP = 80;

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

export const OBJECT_COLORS: Record<string, string> = { blue: "#3b82f6", orange: "#f97316", emerald: "#10b981", pink: "#ec4899" };

/** Where the object is on the horizon: altitude above the line, azimuth along it, east to west. */
function HorizonView({ objectId, minutes, color }: { objectId: string; minutes: number; color: string }) {
  const [ref, w] = useElementWidth<HTMLDivElement>(560);
  const o = OBJECTS.find((x) => x.id === objectId) ?? OBJECTS[0];
  const alt = objectAltitude(o, minutes);
  const az = azimuth(o.dec, minutes, o.transit);
  const H = 110;
  const gy = H - 24;
  const x = ((Math.min(300, Math.max(60, az)) - 60) / 240) * (w - 32) + 16;
  const y = gy - (Math.max(0, alt) / 90) * (gy - 14);
  return (
    <div ref={ref} className="app-og-horizon">
      <svg viewBox={`0 0 ${w} ${H}`} height={H} role="img" aria-label={`${o.name} at ${Math.round(alt)} degrees altitude, ${compass(az)}`}>
        <defs>
          <linearGradient id="og-ground" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0" stopColor="#fff" stopOpacity="0.08" />
            <stop offset="1" stopColor="#fff" stopOpacity="0" />
          </linearGradient>
          <filter id="og-glow"><feGaussianBlur stdDeviation="4" /></filter>
        </defs>
        <rect x={0} y={gy} width={w} height={H - gy} fill="url(#og-ground)" />
        <line x1={0} x2={w} y1={gy} y2={gy} stroke="#fff" strokeOpacity={0.25} />
        {[30, 60].map((a) => (
          <line key={a} x1={0} x2={w} y1={gy - (a / 90) * (gy - 14)} y2={gy - (a / 90) * (gy - 14)} stroke="#fff" strokeOpacity={0.06} strokeDasharray="3 5" />
        ))}
        {[["E", 90], ["S", 180], ["W", 270]].map(([l, a]) => (
          <text key={l} x={((Number(a) - 60) / 240) * (w - 32) + 16} y={H - 6} fontSize={10} fill="#fff" fillOpacity={0.4} textAnchor="middle">{l}</text>
        ))}
        {alt > 0 && <line x1={x} x2={x} y1={y} y2={gy} stroke={color} strokeOpacity={0.4} strokeDasharray="2 3" />}
        {alt > 0 ? (
          <g>
            <circle cx={x} cy={y} r={11} fill={color} fillOpacity={0.45} filter="url(#og-glow)" />
            <circle cx={x} cy={y} r={5} fill="#fff" stroke={color} strokeWidth={3} />
          </g>
        ) : (
          <text x={w / 2} y={gy - 12} fontSize={11} fill="#fff" fillOpacity={0.5} textAnchor="middle">Below the horizon</text>
        )}
        <text x={16} y={14} fontSize={10} fill="#fff" fillOpacity={0.5} letterSpacing={0.6}>{clock(minutes)} · {alt > 0 ? `${alt.toFixed(0)}° ${compass(az)}` : "set"}</text>
      </svg>
    </div>
  );
}

/**
 * The app's two object graphs. "visibility" is VisibilityGraphWidget: cloud area, the moon area, the object curve
 * with glow, the current position dot, NOW, moon rise, the peak dot and a scrubber with a tooltip. "altitude" is
 * the simpler AltitudeGraph: one curve over the night with a faint cloud backdrop, NOW dot and scrubber.
 * `horizon` adds a strip that shows where the object sits above the horizon line at the scrubbed time.
 */
export function AppObjectGraph({
  variant = "visibility",
  objectId = "high",
  color = "#3b82f6",
  horizon = false,
}: {
  variant?: "visibility" | "altitude";
  objectId?: string;
  color?: string;
  horizon?: boolean;
}) {
  const [ref, w] = useElementWidth<HTMLDivElement>(560);
  const [scrub, setScrub] = useState<number | null>(null);
  const o = OBJECTS.find((x) => x.id === objectId) ?? OBJECTS[0];
  const full = variant === "visibility";
  const H = 200;
  const plotH = full ? H : H - 30;
  const x = (m: number): number => ((m - NIGHT_START) / SPAN) * w;
  const objY = (a: number): number => plotH - (Math.max(0, a) / 90) * plotH * 0.7;
  const alt = (m: number): number => (full ? objectAltitude(o, m) : Math.sin(((m - NIGHT_START) / SPAN) * Math.PI) * 80);
  const altY = (m: number): number => (full ? objY(alt(m)) : plotH - (Math.sin(((m - NIGHT_START) / SPAN) * Math.PI)) * plotH * 0.8);

  const cloudPts: Pt[] = CLOUD_HOURLY.map((c, i) => [x(NIGHT_START + i * 60), plotH - (c / 100) * plotH] as const);
  const cloudArea = `M${cloudPts[0][0]} ${plotH} L${cloudPts[0][0]} ${cloudPts[0][1]}${smooth(cloudPts).replace(/^M\S+ \S+/, "")} L${cloudPts.at(-1)![0]} ${plotH} L${w} ${plotH} Z`;
  const objLine = "M" + TIMES.map((m) => `${x(m)} ${altY(m)}`).join(" L");
  const moonLine = "M" + TIMES.map((m) => `${x(m)} ${objY(moonAltitude(m))}`).join(" L");
  const peak = TIMES.reduce((best, m) => (alt(m) > alt(best) ? m : best), TIMES[0]);
  const nowX = x(NOW);
  const riseX = x(MOON_RISE_MINUTES);
  const mm = scrub === null ? NOW : NIGHT_START + scrub * SPAN;

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
            <span><i style={{ background: color }} />OBJECT</span>
            <span><i style={{ background: "#4f46e5" }} />MOON</span>
            <span><i style={{ background: "rgb(255 255 255 / 0.24)" }} />CLOUD</span>
          </span>
        </div>
      )}
      <div ref={ref} className="app-og-plot" style={{ height: H, background: full ? `linear-gradient(to bottom, ${color}1a, transparent)` : undefined }}>
        <svg viewBox={`0 0 ${w} ${H}`} height={H} role="img" aria-label={`${o.name} visibility over the night`} onPointerMove={move} onPointerDown={move} onPointerLeave={() => setScrub(null)}>
          <defs>
            <filter id="og-curve-glow" x="-10%" y="-30%" width="120%" height="160%"><feGaussianBlur stdDeviation="3" /></filter>
            <filter id="og-now-glow" x="-200%" y="-10%" width="500%" height="120%"><feGaussianBlur stdDeviation="3" /></filter>
            <linearGradient id="og-cloud" x1="0" x2="0" y1="0" y2="1">
              <stop offset="0" stopColor="#fff" stopOpacity="0.25" />
              <stop offset="1" stopColor="#fff" stopOpacity="0.05" />
            </linearGradient>
            <linearGradient id="og-now" gradientUnits="userSpaceOnUse" x1="0" x2="0" y1={NOW_TOP} y2={plotH}>
              <stop offset="0" stopColor="#f97316" stopOpacity="0.9" />
              <stop offset="1" stopColor="#f97316" stopOpacity="0" />
            </linearGradient>
          </defs>
          {full ? (
            <>
              <path d={cloudArea} fill="url(#og-cloud)" />
              <path d={smooth(cloudPts)} fill="none" stroke="#fff" strokeOpacity={0.3} strokeWidth={1.5} />
              <path d={`M0 ${plotH} L${moonLine.slice(1)} L${w} ${plotH} Z`} fill="#1e1b4b" fillOpacity={0.5} />
              <path d={moonLine} fill="none" stroke="#6366f1" strokeOpacity={0.5} strokeWidth={1.5} />
              <path d={objLine} fill="none" stroke={color} strokeOpacity={0.4} strokeWidth={6} filter="url(#og-curve-glow)" />
              <path d={objLine} fill="none" stroke={color} strokeWidth={3} strokeLinecap="round" strokeLinejoin="round" />
              <g>
                <circle cx={nowX} cy={objY(alt(NOW))} r={9} fill={color} fillOpacity={0.3} filter="url(#og-curve-glow)" />
                <circle cx={nowX} cy={objY(alt(NOW))} r={5} fill="#fff" stroke={color} strokeWidth={3} />
              </g>
              <line x1={riseX} x2={riseX} y1={plotH} y2={plotH * 0.75 + 10} stroke="#6366f1" strokeOpacity={0.5} />
              <circle cx={riseX} cy={plotH * 0.75 + 5} r={6} fill="#a855f7" fillOpacity={0.3} />
              <circle cx={riseX} cy={plotH * 0.75 + 5} r={3} fill="#a855f7" />
              <rect x={riseX + 8} y={plotH * 0.75} width={74} height={17} rx={4} fill="#312e81" fillOpacity={0.5} stroke="#6366f1" strokeOpacity={0.3} />
              <text x={riseX + 12} y={plotH * 0.75 + 12} fontSize={9} fontWeight={600} letterSpacing={1.5} fill="#a5b4fc">MOON RISE</text>
              <rect x={nowX - 2} y={NOW_TOP} width={4} height={plotH - NOW_TOP} fill="url(#og-now)" fillOpacity={0.6} filter="url(#og-curve-glow)" />
              <rect x={nowX - 0.75} y={NOW_TOP} width={1.5} height={plotH - NOW_TOP} fill="url(#og-now)" />
              <circle className="app-pulse" cx={nowX} cy={NOW_TOP} r={8} fill="#f97316" fillOpacity={0.4} />
              <circle cx={nowX} cy={NOW_TOP} r={3} fill="#fb923c" />
              <rect x={nowX + 8} y={NOW_TOP - 7} width={30} height={15} rx={4} fill="#f97316" fillOpacity={0.1} stroke="#f97316" strokeOpacity={0.2} />
              <text x={nowX + 12} y={NOW_TOP + 4} fontSize={9} fontWeight={700} fill="#fb923c">NOW</text>
              {alt(peak) > 0 && <circle cx={x(peak)} cy={altY(peak)} r={5} fill={color} />}
            </>
          ) : (
            <>
              <path d={`M0 ${plotH} L0 ${plotH * 0.2} C${w * 0.125} ${plotH * 0.2} ${w * 0.125} ${plotH * 0.7} ${w * 0.25} ${plotH * 0.7} C${w * 0.375} ${plotH * 0.7} ${w * 0.375} ${plotH * 0.9} ${w * 0.5} ${plotH * 0.9} C${w * 0.625} ${plotH * 0.9} ${w * 0.625} ${plotH * 0.4} ${w * 0.75} ${plotH * 0.4} C${w * 0.875} ${plotH * 0.4} ${w * 0.875} ${plotH * 0.1} ${w} ${plotH * 0.1} L${w} ${plotH} Z`} fill="#fff" fillOpacity={0.05} />
              <path d={objLine} fill="none" stroke={color} strokeWidth={3} strokeLinecap="round" />
              <circle cx={w / 2} cy={plotH - plotH * 0.8} r={5} fill={color} />
              <circle cx={w * 0.2} cy={plotH - Math.sin(0.2 * Math.PI) * plotH * 0.8} r={4} fill="#fff" />
              <circle cx={w * 0.2} cy={plotH - Math.sin(0.2 * Math.PI) * plotH * 0.8} r={2} fill={color} />
              {[0, 1, 2, 3, 4].map((i) => (
                <text key={i} x={(w * i) / 4} y={H - 10} fontSize={10} fontWeight={i === 2 ? 700 : 400} fill={i === 2 ? "#fff" : "#9e9e9e"} textAnchor={i === 0 ? "start" : i === 4 ? "end" : "middle"}>{clock(NIGHT_START + (SPAN * i) / 4)}</text>
              ))}
            </>
          )}
          {scrub !== null && (
            <g>
              <line x1={scrub * w} x2={scrub * w} y1={0} y2={plotH} stroke={full ? color : "#fff"} strokeOpacity={0.8} />
              {!full && (
                <>
                  <circle cx={scrub * w} cy={altY(mm)} r={6} fill="#fff" />
                  <circle cx={scrub * w} cy={altY(mm)} r={4} fill={color} />
                </>
              )}
            </g>
          )}
        </svg>
        {scrub !== null && (
          <div className="app-og-tip" style={{ left: Math.max(0, Math.min(w - 100, scrub * w)) }}>
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
