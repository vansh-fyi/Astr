"use client";

import { useState } from "react";
import * as zone from "@/lib/astr-zone";
import * as sky from "@/lib/astr-sky";
import { DemoFrame } from "../documentation";

const f = (x: number, d = 2): string => x.toFixed(d);

function Slider({
  label,
  min,
  max,
  step,
  value,
  onChange,
  display,
}: {
  label: string;
  min: number;
  max: number;
  step: number;
  value: number;
  onChange: (v: number) => void;
  display: string;
}) {
  return (
    <label className="docs-slider">
      <span>{label}</span>
      <input type="range" min={min} max={max} step={step} value={value} onChange={(e) => onChange(Number(e.target.value))} />
      <output>{display}</output>
    </label>
  );
}

/** The zone ladder, live. Runs the same TypeScript port that computes the tables. */
export function ZoneCalculator() {
  const [exp, setExp] = useState(0);
  const r = 10 ** exp;
  const sqm = zone.sqmFromRatio(r);
  return (
    <DemoFrame
      controls={
        <div className="docs-sliders">
          <Slider label="Artificial / natural ratio r" min={-2} max={2} step={0.01} value={exp} onChange={setExp} display={f(r, r < 1 ? 3 : 2)} />
        </div>
      }
      caption="Drag to move along the ladder. Zone edges are 0.32, 0.64, 1.28 ... 40.96."
    >
      <dl className="docs-readoutgrid">
        <div><dt>Zone</dt><dd>{zone.zoneFromRatio(r)}</dd></div>
        <div><dt>Sky brightness</dt><dd>{f(sqm)} mag/arcsec²</dd></div>
        <div><dt>Artificial luminance</dt><dd>{f(zone.artificialUcdFromRatio(r), 0)} µcd/m²</dd></div>
        <div><dt>Limiting magnitude</dt><dd>{f(zone.nelmFromSqm(sqm))}</dd></div>
      </dl>
    </DemoFrame>
  );
}

const CAUSE: Record<sky.SkyCause, string> = {
  cloud: "Cloud",
  moon: "The moon",
  light: "Light pollution",
  none: "Nothing significant",
};

/** One hour of sky, live: place, cloud, moon and air in; moonlight, brightness, limiting magnitude, state and cause out. */
export function SkyCalculator() {
  const [exp, setExp] = useState(-1);
  const [cloud, setCloud] = useState(10);
  const [moonAlt, setMoonAlt] = useState(40);
  const [illum, setIllum] = useState(50);
  const [aod, setAod] = useState(0.05);
  const [elev, setElev] = useState(0);

  const r = 10 ** exp;
  const kV = sky.extinctionKV(aod, elev);
  const up = moonAlt > 0;
  const b = up
    ? sky.moonRatio({
        obsZenithDeg: 0,
        moonZenithDeg: 90 - moonAlt,
        separationDeg: 90 - moonAlt,
        phaseAngleDeg: sky.phaseAngleFromIllumination(illum / 100),
        kV,
      })
    : 0;
  const c = cloud / 100;
  const sqm = sky.sqmEffective(r, b);
  const state = sky.skyState(c, r, r + b);
  const cause = sky.why(c, r, r + b);
  return (
    <DemoFrame
      controls={
        <div className="docs-sliders">
          <Slider label="Artificial ratio r" min={-2} max={2} step={0.01} value={exp} onChange={setExp} display={`${f(r, r < 1 ? 3 : 2)} (zone ${zone.zoneFromRatio(r)})`} />
          <Slider label="Cloud cover" min={0} max={100} step={1} value={cloud} onChange={setCloud} display={`${cloud}%`} />
          <Slider label="Moon altitude" min={-10} max={90} step={1} value={moonAlt} onChange={setMoonAlt} display={up ? `${moonAlt}°` : "below horizon"} />
          <Slider label="Moon illuminated" min={0} max={100} step={1} value={illum} onChange={setIllum} display={`${illum}%`} />
          <Slider label="Aerosol optical depth" min={0} max={0.5} step={0.01} value={aod} onChange={setAod} display={f(aod)} />
          <Slider label="Elevation" min={0} max={4000} step={100} value={elev} onChange={setElev} display={`${elev} m`} />
        </div>
      }
      caption="Zenith sky at astronomical night. The state and the cause come from the same functions the app uses."
    >
      <dl className="docs-readoutgrid">
        <div><dt>State</dt><dd>{sky.STATE_LABELS[state]}</dd></div>
        <div><dt>Limiting factor</dt><dd>{CAUSE[cause.primary]}</dd></div>
        <div><dt>Extinction k_V</dt><dd>{f(kV, 3)}</dd></div>
        <div><dt>Moonlight</dt><dd>{f(b)} × natural</dd></div>
        <div><dt>Sky brightness</dt><dd>{f(sqm)} mag/arcsec²</dd></div>
        <div><dt>Limiting magnitude</dt><dd>{f(zone.nelmFromSqm(sqm))}</dd></div>
        <div><dt>Light pollution cost</dt><dd>{f(cause.lightLoss)} mag</dd></div>
        <div><dt>Moon cost</dt><dd>{f(cause.moonLoss)} mag</dd></div>
      </dl>
    </DemoFrame>
  );
}
