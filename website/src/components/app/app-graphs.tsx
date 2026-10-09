"use client";

import { useId } from "react";
import "./app-ui.css";
import { useElementWidth } from "../docs/viz/use-width";
import { CLOUD_HOURLY, MOON_RISE_MINUTES, NIGHT_END, NIGHT_START, moonAltitude, primeView } from "@/lib/viz-data";
import { clock } from "@/lib/viz";

const LABEL_H = 30;
const NOW = 20 * 60 + 15;

type Pt = readonly [number, number];

/** Catmull-Rom style smoothing with tension 0.2, exactly as _drawCloudCover builds its cubic segments. */
function smooth(points: Pt[]): string {
  let d = `M${points[0][0]} ${points[0][1]}`;
  for (let i = 0; i < points.length - 1; i++) {
    const p0 = points[Math.max(0, i - 1)];
    const p1 = points[i];
    const p2 = points[i + 1];
    const p3 = points[Math.min(points.length - 1, i + 2)];
    const c1 = [p1[0] + (p2[0] - p0[0]) * 0.2, p1[1] + (p2[1] - p0[1]) * 0.2];
    const c2 = [p2[0] - (p3[0] - p1[0]) * 0.2, p2[1] - (p3[1] - p1[1]) * 0.2];
    d += ` C${c1[0]} ${c1[1]} ${c2[0]} ${c2[1]} ${p2[0]} ${p2[1]}`;
  }
  return d;
}

/** The NOW marker: a glowing orange line, a pulsing dot at its head and a small label. */
function NowMarker({ x, top, bottom }: { x: number; top: number; bottom: number }) {
  const id = useId();
  return (
    <g>
      <defs>
        <linearGradient id={id} gradientUnits="userSpaceOnUse" x1={x} x2={x} y1={top} y2={bottom}>
          <stop offset="0" stopColor="#f97316" stopOpacity="0.95" />
          <stop offset="1" stopColor="#f97316" stopOpacity="0" />
        </linearGradient>
      </defs>
      <rect x={x - 2} y={top} width={4} height={bottom - top} fill={`url(#${id})`} fillOpacity={0.6} filter="url(#g-blur)" />
      <rect x={x - 0.75} y={top} width={1.5} height={bottom - top} fill={`url(#${id})`} />
      <circle className="app-pulse" cx={x} cy={top} r={8} fill="#f97316" fillOpacity={0.4} />
      <circle cx={x} cy={top} r={3} fill="#fb923c" />
      <rect x={x + 8} y={top - 7} width={30} height={15} rx={4} fill="#f97316" fillOpacity={0.1} stroke="#f97316" strokeOpacity={0.2} />
      <text x={x + 12} y={top + 4} fontSize={9} fontWeight={700} fill="#fb923c">NOW</text>
    </g>
  );
}

/** Gradients and the blur used by every graph on this site. */
function GraphDefs() {
  return (
    <defs>
      <filter id="g-blur" x="-50%" y="-10%" width="200%" height="120%">
        <feGaussianBlur stdDeviation="3" />
      </filter>
      <linearGradient id="g-cloud" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0" stopColor="#fff" stopOpacity="0.25" />
        <stop offset="1" stopColor="#fff" stopOpacity="0.05" />
      </linearGradient>
      <linearGradient id="g-now" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0" stopColor="#f97316" stopOpacity="0.9" />
        <stop offset="1" stopColor="#f97316" stopOpacity="0" />
      </linearGradient>
      <linearGradient id="g-prime" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0" stopColor="#10b981" stopOpacity="0.1" />
        <stop offset="1" stopColor="#10b981" stopOpacity="0.02" />
      </linearGradient>
    </defs>
  );
}

export interface GraphLayers {
  cloud?: boolean;
  moon?: boolean;
  moonRise?: boolean;
  prime?: boolean;
  now?: boolean;
}

/**
 * ConditionsGraph from conditions_graph.dart: grid, smoothed cloud area, the moon's altitude area, the moon
 * rise marker, the prime view window with its badge and the NOW marker. Colours are GraphTheme and the
 * painter's own literals.
 */
export function AppConditionsGraph({ layers = {}, height = 200, cloudData = CLOUD_HOURLY }: { layers?: GraphLayers; height?: number; cloudData?: readonly number[] }) {
  const { cloud = true, moon = true, moonRise = true, prime = true, now = true } = layers;
  const [ref, w] = useElementWidth<HTMLDivElement>(560);
  const h = height - LABEL_H;
  const span = NIGHT_END - NIGHT_START;
  const x = (m: number): number => ((m - NIGHT_START) / span) * w;

  const cloudPts: Pt[] = cloudData.map((c, i) => [x(NIGHT_START + (i * span) / (cloudData.length - 1)), h - (c / 100) * h] as const);
  const cloudFill = `M${cloudPts[0][0]} ${h} L${cloudPts[0][0]} ${cloudPts[0][1]} ${smooth(cloudPts).replace(/^M\S+ \S+/, "")} L${cloudPts.at(-1)![0]} ${h} L${w} ${h} Z`;
  const moonPts: Pt[] = [];
  for (let m = NIGHT_START; m <= NIGHT_END; m += 15) moonPts.push([x(m), h - (Math.max(0, moonAltitude(m)) / 90) * h]);
  const moonLine = "M" + moonPts.map(([px, py]) => `${px} ${py}`).join(" L");
  const win = prime ? primeView() : null;
  const riseX = x(MOON_RISE_MINUTES);
  const labelY = h * 0.75;
  const nowX = x(NOW);
  const nowTop = h * 0.35;
  const winStart = win ? x(win.from) : 0;
  const winEnd = win ? x(win.to) : 0;
  const winMid = Math.max(44, Math.min(w - 44, (winStart + winEnd) / 2));

  return (
    <div ref={ref} className="app-ui app-graph" style={{ height }}>
      <svg viewBox={`0 0 ${w} ${height}`} height={height} role="img" aria-label="Conditions graph for an example night">
        <GraphDefs />
        {[1, 2, 3].map((i) => <line key={`h${i}`} x1={0} x2={w} y1={(h * i) / 4} y2={(h * i) / 4} stroke="#fff" strokeOpacity={0.05} />)}
        {[1, 2, 3, 4].map((i) => <line key={`v${i}`} y1={0} y2={h} x1={(w * i) / 4} x2={(w * i) / 4} stroke="#fff" strokeOpacity={0.05} />)}
        {cloud && (
          <g>
            <path d={cloudFill} fill="url(#g-cloud)" />
            <path d={smooth(cloudPts)} fill="none" stroke="#fff" strokeOpacity={0.3} strokeWidth={1.5} />
          </g>
        )}
        {moon && (
          <g>
            <path d={`M0 ${h} L${moonLine.slice(1)} L${w} ${h} Z`} fill="#1e1b4b" fillOpacity={0.5} />
            <path d={moonLine} fill="none" stroke="#6366f1" strokeOpacity={0.5} strokeWidth={1.5} />
          </g>
        )}
        {moonRise && (
          <g>
            <line x1={riseX} x2={riseX} y1={h} y2={labelY + 10} stroke="#6366f1" strokeOpacity={0.5} />
            <circle cx={riseX} cy={labelY + 5} r={6} fill="#a855f7" fillOpacity={0.3} />
            <circle cx={riseX} cy={labelY + 5} r={3} fill="#a855f7" />
            <rect x={riseX + 8} y={labelY} width={74} height={17} rx={4} fill="#312e81" fillOpacity={0.5} stroke="#6366f1" strokeOpacity={0.3} />
            <text x={riseX + 12} y={labelY + 12} fontSize={9} fontWeight={600} letterSpacing={1.5} fill="#a5b4fc">MOON RISE</text>
          </g>
        )}
        {win && (
          <g>
            <rect x={winStart} y={0} width={winEnd - winStart} height={h} fill="url(#g-prime)" />
            <rect x={winMid - 40} y={8} width={80} height={20} rx={10} fill="#10b981" fillOpacity={0.12} stroke="#10b981" strokeOpacity={0.25} />
            <text x={winMid} y={22} fontSize={10} fontWeight={600} letterSpacing={0.5} fill="#6ee7b7" textAnchor="middle">PRIME VIEW</text>
          </g>
        )}
        {now && <NowMarker x={nowX} top={nowTop} bottom={h} />}
        {[0, 1, 2, 3, 4].map((i) => {
          const m = NIGHT_START + (span * i) / 4;
          const midnight = Math.round(m) % 1440 === 0;
          return (
            <text key={i} x={(w * i) / 4} y={h + 20} fontSize={10} fontWeight={midnight ? 700 : 400} fill={midnight ? "#fff" : "#9e9e9e"} textAnchor={i === 0 ? "start" : i === 4 ? "end" : "middle"}>
              {clock(m)}
            </text>
          );
        })}
      </svg>
    </div>
  );
}

/**
 * The hourly cloud forecast: the same smoothed gradient area, grid, hour labels and NOW marker as the
 * conditions graph, with only the cloud layer. Data is a percentage per hour across the night.
 */
export function AppCloudCoverGraph({ data = CLOUD_HOURLY, height = 160 }: { data?: readonly number[]; height?: number }) {
  return <AppConditionsGraph cloudData={data} height={height} layers={{ moon: false, moonRise: false, prime: false }} />;
}

/** GraphLegendItem: an 8 dp dot with a label at 70% white. */
export function AppLegend({ items }: { items: { label: string; color: string }[] }) {
  return (
    <div className="app-ui app-legend">
      {items.map((i) => (
        <span key={i.label}>
          <i style={{ background: i.color }} />
          {i.label}
        </span>
      ))}
    </div>
  );
}
