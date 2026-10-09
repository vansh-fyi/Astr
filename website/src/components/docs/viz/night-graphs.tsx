"use client";

import { useState, type PointerEvent } from "react";
import { clock, chartHeight, scale } from "@/lib/viz";
import {
  CLOUD_HOURLY,
  MOON_ILLUMINATION,
  MOON_RISE_MINUTES,
  NIGHT_END,
  NIGHT_START,
  OBJECTS,
  cloudAt,
  moonAltitude,
  moonValue,
  objectAltitude,
  primeView,
  type ExampleObject,
} from "@/lib/viz-data";
import { DemoFrame } from "../documentation";
import { useElementWidth } from "./use-width";

const LABEL_H = 30;
const NOW = 20 * 60 + 15;
const STEP = 15;
const TICKS = [0, 0.25, 0.5, 0.75, 1];

function Toggle({ on, label, onChange }: { on: boolean; label: string; onChange: (v: boolean) => void }) {
  return (
    <button type="button" className="docs-chip-button" aria-pressed={on} onClick={() => onChange(!on)}>
      {label}
    </button>
  );
}

/** Time axis labels and gridlines shared by both graphs. */
function Axes({ w, plotH }: { w: number; plotH: number }) {
  return (
    <g>
      {[0.25, 0.5, 0.75].map((f) => (
        <line key={f} className="viz-grid" x1={0} x2={w} y1={plotH * f} y2={plotH * f} />
      ))}
      {TICKS.map((f) => (
        <text key={f} className="viz-text" x={f * w} y={plotH + 20} textAnchor={f === 0 ? "start" : f === 1 ? "end" : "middle"}>
          {clock(NIGHT_START + f * (NIGHT_END - NIGHT_START))}
        </text>
      ))}
    </g>
  );
}

const times = Array.from({ length: (NIGHT_END - NIGHT_START) / STEP + 1 }, (_, i) => NIGHT_START + i * STEP);

/** The conditions graph from the atmospherics sheet, on an example night, with each layer switchable. */
export function ConditionsGraphDemo() {
  const [ref, w] = useElementWidth<HTMLDivElement>(610);
  const h = chartHeight(w);
  const plotH = h - LABEL_H;
  const [layers, setLayers] = useState({ cloud: true, moon: true, prime: true });
  const [at, setAt] = useState<number | null>(null);
  const x = scale(NIGHT_START, NIGHT_END, 0, w);
  const prime = primeView();

  const cloudPts = CLOUD_HOURLY.map((c, i) => [x(NIGHT_START + i * 60), plotH - (c / 100) * plotH] as const);
  const cloudPath = `M0 ${plotH} ${cloudPts.map(([px, py]) => `L${px} ${py}`).join(" ")} L${w} ${plotH} Z`;
  const moonPath = `M0 ${plotH} ${times.map((t) => `L${x(t)} ${plotH - (moonAltitude(t) / 90) * plotH}`).join(" ")} L${w} ${plotH} Z`;

  function move(e: PointerEvent<SVGSVGElement>): void {
    const box = e.currentTarget.getBoundingClientRect();
    const f = Math.max(0, Math.min(1, (e.clientX - box.left) / box.width));
    setAt(NIGHT_START + f * (NIGHT_END - NIGHT_START));
  }

  const t = at ?? NOW;
  return (
    <DemoFrame
      controls={
        <div className="docs-chip-row">
          <Toggle on={layers.cloud} label="Cloud cover" onChange={(v) => setLayers({ ...layers, cloud: v })} />
          <Toggle on={layers.moon} label="Moon altitude" onChange={(v) => setLayers({ ...layers, moon: v })} />
          <Toggle on={layers.prime} label="Prime view" onChange={(v) => setLayers({ ...layers, prime: v })} />
        </div>
      }
      caption="An example night: a 78% moon that rises at 21:30, and a cloud forecast with a clear spell before dawn. Move over the graph to read it."
    >
      <div ref={ref} className="viz-chart">
        <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} onPointerMove={move} onPointerLeave={() => setAt(null)} role="img" aria-label="Conditions graph on an example night">
          <Axes w={w} plotH={plotH} />
          {layers.cloud && <path className="viz-cloud-area" d={cloudPath} />}
          {layers.moon && <path className="viz-moon-area" d={moonPath} />}
          {layers.moon && (
            <g>
              <line className="viz-moonrise" x1={x(MOON_RISE_MINUTES)} x2={x(MOON_RISE_MINUTES)} y1={plotH * 0.75 + 10} y2={plotH} />
              <circle className="viz-dot" cx={x(MOON_RISE_MINUTES)} cy={plotH * 0.75 + 5} r={3} />
              <text className="viz-text viz-text-strong" x={x(MOON_RISE_MINUTES) + 8} y={plotH * 0.75 + 9}>
                MOON RISE
              </text>
            </g>
          )}
          {layers.prime && prime && (
            <g>
              <rect className="viz-band" x={x(prime.from)} y={0} width={x(prime.to) - x(prime.from)} height={plotH} />
              <text className="viz-text viz-text-strong" x={(x(prime.from) + x(prime.to)) / 2} y={16} textAnchor="middle">
                PRIME VIEW
              </text>
            </g>
          )}
          <line className={at === null ? "viz-now" : "viz-scrub"} x1={x(t)} x2={x(t)} y1={at === null ? 28 : 0} y2={plotH} />
          {at === null && (
            <text className="viz-text viz-text-strong" x={x(t) + 6} y={22}>
              NOW
            </text>
          )}
        </svg>
      </div>
      <dl className="docs-readoutgrid viz-readout">
        <div><dt>{at === null ? "Now" : "Time"}</dt><dd>{clock(t)}</dd></div>
        <div><dt>Cloud cover</dt><dd>{Math.round(cloudAt(t))}%</dd></div>
        <div><dt>Moon altitude</dt><dd>{moonAltitude(t) > 0 ? `${Math.round(moonAltitude(t))}°` : "below horizon"}</dd></div>
        <div>
          <dt>Prime view</dt>
          <dd>{prime ? `${clock(prime.from)} to ${clock(prime.to)}` : "none"}</dd>
        </div>
      </dl>
    </DemoFrame>
  );
}

/** The object visibility graph on an example night, with the hours the code calls optimal made visible. */
export function ObjectGraphDemo() {
  const [ref, w] = useElementWidth<HTMLDivElement>(610);
  const h = chartHeight(w);
  const plotH = h - LABEL_H;
  const [object, setObject] = useState<ExampleObject>(OBJECTS[0]);
  const [layers, setLayers] = useState({ cloud: true, moon: true, optimal: false });
  const [at, setAt] = useState<number | null>(null);
  const x = scale(NIGHT_START, NIGHT_END, 0, w);
  const yAlt = (deg: number): number => plotH - (Math.max(deg, 0) / 90) * plotH * 0.7;

  const objectPath = times.map((t, i) => `${i === 0 ? "M" : "L"}${x(t)} ${yAlt(objectAltitude(object, t))}`).join(" ");
  const moonPath = `M0 ${plotH} ${times.map((t) => `L${x(t)} ${yAlt(moonValue(t))}`).join(" ")} L${w} ${plotH} Z`;
  const cloudPts = CLOUD_HOURLY.map((c, i) => [x(NIGHT_START + i * 60), plotH - (c / 100) * plotH] as const);
  const cloudPath = `M0 ${plotH} ${cloudPts.map(([px, py]) => `L${px} ${py}`).join(" ")} L${w} ${plotH} Z`;

  const peak = times.reduce((best, t) => (objectAltitude(object, t) > objectAltitude(object, best) ? t : best), times[0]);
  // Hours the code's rule marks optimal: object above 30 degrees and the moon value below 30.
  const optimal: [number, number][] = [];
  let start: number | null = null;
  for (const t of times) {
    const ok = objectAltitude(object, t) > 30 && moonValue(t) < 30;
    if (ok && start === null) start = t;
    if (!ok && start !== null) {
      optimal.push([start, t]);
      start = null;
    }
  }
  if (start !== null) optimal.push([start, NIGHT_END]);

  function move(e: PointerEvent<SVGSVGElement>): void {
    const box = e.currentTarget.getBoundingClientRect();
    const f = Math.max(0, Math.min(1, (e.clientX - box.left) / box.width));
    setAt(Math.round((NIGHT_START + f * (NIGHT_END - NIGHT_START)) / STEP) * STEP);
  }
  const t = at ?? NOW;
  const alt = objectAltitude(object, t);
  return (
    <DemoFrame
      controls={
        <>
          <div className="docs-chip-row">
            {OBJECTS.map((o) => (
              <button key={o.id} type="button" className="docs-chip-button" aria-pressed={o.id === object.id} onClick={() => setObject(o)}>
                {o.name}
              </button>
            ))}
          </div>
          <div className="docs-chip-row">
            <Toggle on={layers.cloud} label="Cloud" onChange={(v) => setLayers({ ...layers, cloud: v })} />
            <Toggle on={layers.moon} label="Moon value" onChange={(v) => setLayers({ ...layers, moon: v })} />
            <Toggle on={layers.optimal} label="Hours the code calls optimal" onChange={(v) => setLayers({ ...layers, optimal: v })} />
          </div>
        </>
      }
      caption={`${object.name}: ${object.note}, seen from latitude 30° N. The object scale reaches 70% of the height at 90°, as in the app.`}
    >
      <div ref={ref} className="viz-chart">
        <svg width={w} height={h} viewBox={`0 0 ${w} ${h}`} onPointerMove={move} onPointerLeave={() => setAt(null)} role="img" aria-label="Object visibility graph on an example night">
          <Axes w={w} plotH={plotH} />
          {layers.cloud && <path className="viz-cloud-area" d={cloudPath} />}
          {layers.moon && <path className="viz-moon-area" d={moonPath} />}
          {layers.optimal &&
            optimal.map(([a, b]) => (
              <rect key={a} className="viz-band viz-band-dashed" x={x(a)} y={0} width={x(b) - x(a)} height={plotH} />
            ))}
          <path className="viz-curve" d={objectPath} />
          <circle className="viz-peak" cx={x(peak)} cy={yAlt(objectAltitude(object, peak))} r={4} />
          <line className={at === null ? "viz-now" : "viz-scrub"} x1={x(t)} x2={x(t)} y1={at === null ? 28 : 0} y2={plotH} />
          <circle className="viz-here" cx={x(t)} cy={yAlt(alt)} r={5} />
          {at === null && (
            <text className="viz-text viz-text-strong" x={x(t) + 6} y={22}>
              NOW
            </text>
          )}
        </svg>
      </div>
      <dl className="docs-readoutgrid viz-readout">
        <div><dt>{at === null ? "Now" : "Time"}</dt><dd>{clock(t)}</dd></div>
        <div><dt>Altitude</dt><dd>{alt > 0 ? `${alt.toFixed(1)}°` : "below horizon"}</dd></div>
        <div><dt>Moon value</dt><dd>{moonValue(t).toFixed(0)}</dd></div>
        <div>
          <dt>Optimal by the code&apos;s rule</dt>
          <dd>{optimal.length ? optimal.map(([a, b]) => `${clock(a)} to ${clock(b)}`).join(", ") : "never tonight"}</dd>
        </div>
      </dl>
      <p className="viz-key" style={{ marginTop: "var(--spacing-f8)" }}>
        Peak altitude {objectAltitude(object, peak).toFixed(0)}° at {clock(peak)}. The moon here is {Math.round(MOON_ILLUMINATION * 100)}% lit.
      </p>
    </DemoFrame>
  );
}
