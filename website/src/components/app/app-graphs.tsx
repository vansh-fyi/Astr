"use client";

import { useId } from "react";
import "./app-ui.css";
import { useElementWidth } from "../docs/viz/use-width";
import { CLOUD_HOURLY, MOON_RISE_MINUTES, NIGHT_END, NIGHT_START, moonAltitude, primeView } from "@/lib/viz-data";
import { clock } from "@/lib/viz";
import { F, GRAPH, T, stop } from "./tokens";
import { GraphPill, pillWidth } from "./graph-pill";

const LABEL_H = F.f34;
const NOW = 20 * 60 + 15;

type Pt = readonly [number, number];

/** Cubic segments with tension 0.2, exactly as _drawCloudCover builds them. */
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

/** The NOW marker: a glowing line, a pulsing dot at its head and a small label. */
function NowMarker({ x, top, bottom }: { x: number; top: number; bottom: number }) {
  const id = useId();
  return (
    <g>
      <defs>
        <linearGradient id={id} gradientUnits="userSpaceOnUse" x1={x} x2={x} y1={top} y2={bottom}>
          <stop offset="0" stopColor={stop(GRAPH.now, 1)} />
          <stop offset="1" stopColor={stop(GRAPH.now, 10)} />
        </linearGradient>
      </defs>
      <rect x={x - F.f2} y={top} width={F.f3 + F.f1} height={bottom - top} fill={`url(#${id})`} filter="url(#g-blur)" />
      <rect x={x - F.f1 / 2} y={top} width={F.f1} height={bottom - top} fill={`url(#${id})`} />
      <circle className="app-pulse" cx={x} cy={top} r={F.f8} fill={stop(GRAPH.now, 2)} />
      <circle cx={x} cy={top} r={F.f3} fill={stop(GRAPH.now)} />
      <GraphPill x={x + F.f13} y={top} text="NOW" weight={700} tracking={0.5} color={stop(GRAPH.now)} fill={stop(GRAPH.now, 5)} stroke={stop(GRAPH.now, 3)} />
    </g>
  );
}

/** Gradients and the blur used by the graphs on this site. */
function GraphDefs() {
  return (
    <defs>
      <filter id="g-blur" x="-50%" y="-10%" width="200%" height="120%">
        <feGaussianBlur stdDeviation={F.f3} />
      </filter>
      <linearGradient id="g-cloud" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0" stopColor={stop(GRAPH.cloud, 3)} />
        <stop offset="1" stopColor={stop(GRAPH.cloud, 6)} />
      </linearGradient>
      <linearGradient id="g-prime" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0" stopColor={stop(GRAPH.prime, 5)} />
        <stop offset="1" stopColor={stop(GRAPH.prime, 8)} />
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
 * ConditionsGraph: grid, a smoothed cloud area, the moon's altitude area, the moon rise marker, the prime view
 * window and the NOW marker. Colours are stops at Pogson opacity steps; sizes are Fibonacci numbers.
 */
export function AppConditionsGraph({ layers = {}, height = 233, cloudData = CLOUD_HOURLY }: { layers?: GraphLayers; height?: number; cloudData?: readonly number[] }) {
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
  const winMid = Math.max(F.f55, Math.min(w - F.f55, (winStart + winEnd) / 2));

  return (
    <div ref={ref} className="app-ui app-graph" style={{ height }}>
      <svg viewBox={`0 0 ${w} ${height}`} height={height} role="img" aria-label="Conditions graph for an example night">
        <GraphDefs />
        {[1, 2, 3].map((i) => <line key={`h${i}`} x1={0} x2={w} y1={(h * i) / 4} y2={(h * i) / 4} stroke={stop(GRAPH.ink, 6)} />)}
        {[1, 2, 3, 4].map((i) => <line key={`v${i}`} y1={0} y2={h} x1={(w * i) / 4} x2={(w * i) / 4} stroke={stop(GRAPH.ink, 6)} />)}
        {cloud && (
          <g>
            <path d={cloudFill} fill="url(#g-cloud)" />
            <path d={smooth(cloudPts)} fill="none" stroke={stop(GRAPH.cloud, 3)} strokeWidth={F.f2} />
          </g>
        )}
        {moon && (
          <g>
            <path d={`M0 ${h} L${moonLine.slice(1)} L${w} ${h} Z`} fill={stop(GRAPH.moon, 4)} />
            <path d={moonLine} fill="none" stroke={stop(GRAPH.moonLine, 2)} strokeWidth={F.f2} />
          </g>
        )}
        {moonRise && (
          <g>
            <line x1={riseX} x2={riseX} y1={h} y2={labelY + F.f8} stroke={stop(GRAPH.moonLine, 2)} />
            <circle cx={riseX} cy={labelY + F.f5} r={F.f8} fill={stop(GRAPH.rise, 3)} />
            <circle cx={riseX} cy={labelY + F.f5} r={F.f3} fill={stop(GRAPH.rise)} />
            <GraphPill x={riseX + F.f13} y={labelY + F.f5} text="MOON RISE" tracking={1} color={stop("deep-space-50")} fill={stop(GRAPH.moon, 4)} stroke={stop(GRAPH.moonLine, 3)} />
          </g>
        )}
        {win && (
          <g>
            <rect x={winStart} y={0} width={winEnd - winStart} height={h} fill="url(#g-prime)" />
            <GraphPill x={winMid - pillWidth("PRIME VIEW", 0.5) / 2} y={F.f8 + F.f21 / 2} text="PRIME VIEW" radius={F.f21} color={stop(GRAPH.prime)} fill={stop(GRAPH.prime, 5)} stroke={stop(GRAPH.prime, 3)} />
          </g>
        )}
        {now && <NowMarker x={nowX} top={nowTop} bottom={h} />}
        {[0, 1, 2, 3, 4].map((i) => {
          const m = NIGHT_START + (span * i) / 4;
          const midnight = Math.round(m) % 1440 === 0;
          return (
            <text key={i} x={(w * i) / 4} y={h + F.f21} fontSize={T.s2n} fontWeight={midnight ? 700 : 400} fill={midnight ? stop(GRAPH.ink) : stop("space-grey-300")} textAnchor={i === 0 ? "start" : i === 4 ? "end" : "middle"}>
              {clock(m)}
            </text>
          );
        })}
      </svg>
    </div>
  );
}

/**
 * The hourly cloud forecast: the smoothed gradient area, grid, hour labels and NOW marker of the conditions graph
 * with only the cloud layer. Data is a percentage at evenly spaced hours across the night.
 */
export function AppCloudCoverGraph({ data = CLOUD_HOURLY, height = 144 + F.f34 }: { data?: readonly number[]; height?: number }) {
  return <AppConditionsGraph cloudData={data} height={height} layers={{ moon: false, moonRise: false, prime: false }} />;
}

export type LegendKind = "cloud" | "moon" | "prime" | "now" | "rise" | "object";

/** The colour each kind of graph layer uses, so a legend can never disagree with the graph. */
export const legendColor = (kind: LegendKind, object: string = stop("deep-space-200")): string =>
  kind === "cloud" ? stop(GRAPH.cloud, 3) : kind === "moon" ? stop(GRAPH.moonLine) : kind === "prime" ? stop(GRAPH.prime) : kind === "now" ? stop(GRAPH.now) : kind === "rise" ? stop(GRAPH.rise) : object;

/** GraphLegendItem: a dot and a label per layer. */
export function AppLegend({ items }: { items: { label: string; kind: LegendKind }[] }) {
  return (
    <div className="app-ui app-legend">
      {items.map((i) => (
        <span key={i.label}>
          <i style={{ background: legendColor(i.kind) }} />
          {i.label}
        </span>
      ))}
    </div>
  );
}
