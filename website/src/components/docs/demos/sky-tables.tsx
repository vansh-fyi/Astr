import katex from "katex";
import { readSource } from "@/lib/source";
import { assertAstrVectors } from "@/lib/sky-vectors";
import * as zone from "@/lib/astr-zone";
import * as sky from "@/lib/astr-sky";
import impact from "../../../../content/data/zone-impact.json";

const f = (x: number, d = 2): string => x.toFixed(d);
const fmt = (n: number): string => n.toLocaleString("en-GB");

/** States whose cells are computed. Short names for the grid. */
const SHORT: Record<sky.SkyStateName, string> = {
  milkyWayVisible: "Milky Way",
  starrySkies: "Starry",
  planetsVisible: "Planets",
  fewStars: "Few stars",
  cloudy: "Cloudy",
  tooMuchLight: "Too much light",
};

/** One line saying how many cases the page's numbers were checked against. Fails the build on a mismatch. */
export function VectorStatus() {
  assertAstrVectors();
  const z = JSON.parse(readSource("test/fixtures/astr_zone_scale.vectors.json"));
  const s = JSON.parse(readSource("test/fixtures/astr_sky_model.vectors.json"));
  const count = (o: Record<string, unknown>): number =>
    Object.values(o).reduce<number>((n, v) => {
      if (Array.isArray(v)) return n + v.length;
      if (v && typeof v === "object" && Array.isArray((v as { cases?: unknown[] }).cases)) return n + (v as { cases: unknown[] }).cases.length;
      return n;
    }, 0);
  return (
    <p className="docs-vectorstatus">
      Every number below is computed by a TypeScript port that was checked at build time against {count(z) + count(s)}{" "}
      shared test cases, the same ones the Python and Dart implementations pass.
    </p>
  );
}

export function ZoneLadderTable() {
  assertAstrVectors();
  const rows = [0, ...zone.EDGES].map((lo, i) => ({ zone: i + 1, lo, hi: zone.EDGES[i] ?? null }));
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          SQM and NELM are shown at the lower edge of each zone. Zone 9 has no upper edge.
        </caption>
        <thead>
          <tr>
            <th>Zone</th>
            <th>r from</th>
            <th>r to</th>
            <th>Artificial µcd/m²</th>
            <th>SQM</th>
            <th>NELM</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.zone}>
              <td>{r.zone}</td>
              <td>{r.lo}</td>
              <td>{r.hi ?? "none"}</td>
              <td>{f(zone.artificialUcdFromRatio(r.lo), 0)}</td>
              <td>{f(zone.sqmFromRatio(r.lo))}</td>
              <td>{f(zone.nelmFromSqm(zone.sqmFromRatio(r.lo)))}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function LegacyBridgeTable() {
  assertAstrVectors();
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          The legacy chain converts radiance R to a ratio with r = (1 + 2R)^0.68 - 1. The ladder edge is shown as the
          radiance at which that chain reaches it.
        </caption>
        <thead>
          <tr>
            <th>Zone starts</th>
            <th>Legacy threshold R</th>
            <th>Legacy implied r</th>
            <th>Ladder edge r</th>
            <th>Ladder edge as R</th>
            <th>Legacy / ladder</th>
          </tr>
        </thead>
        <tbody>
          {zone.EDGES.map((edge, i) => {
            const [threshold, z] = [...zone.LEGACY_THRESHOLDS].reverse()[i];
            const implied = zone.legacyRatioFromRadiance(threshold);
            return (
              <tr key={z}>
                <td>{z}</td>
                <td>{threshold}</td>
                <td>{f(implied)}</td>
                <td>{edge}</td>
                <td>{f(zone.legacyRadianceFromRatio(edge), 3)}</td>
                <td>{f(implied / edge)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export function ZoneImpactTable() {
  const m = impact.matrix as number[][];
  const total = impact.records;
  const same = m.reduce((n, row, i) => n + row[i], 0);
  const up = m.reduce((n, row, i) => n + row.reduce((a, v, j) => (j > i ? a + v : a), 0), 0);
  const down = m.reduce((n, row, i) => n + row.reduce((a, v, j) => (j < i ? a + v : a), 0), 0);
  if (m.flat().reduce((a, b) => a + b, 0) !== total) throw new Error("zone-impact.json does not sum to its record count");
  return (
    <>
      <ul>
        <li>
          <strong>{f((same / total) * 100, 1)}%</strong> of {fmt(total)} stored cells keep their zone.
        </li>
        <li>
          <strong>{f(((total - same) / total) * 100, 1)}%</strong> ({fmt(total - same)}) move by exactly one zone:{" "}
          {fmt(up)} up and {fmt(down)} down. None moves by more.
        </li>
      </ul>
      <div className="docs-table-wrap">
        <table className="docs-table">
          <caption>{impact.provenance}</caption>
          <thead>
            <tr>
              <th>Stored zone</th>
              <th>Cells</th>
              <th>Move down one</th>
              <th>Stay</th>
              <th>Move up one</th>
            </tr>
          </thead>
          <tbody>
            {m.map((row, i) => {
              const n = row.reduce((a, b) => a + b, 0);
              if (n === 0) return null;
              return (
                <tr key={i}>
                  <td>{i + 1}</td>
                  <td>{fmt(n)}</td>
                  <td>{fmt(i > 0 ? row[i - 1] : 0)}</td>
                  <td>{fmt(row[i])}</td>
                  <td>{fmt(i < 8 ? row[i + 1] : 0)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </>
  );
}

const SITES: [string, number][] = [
  ["Zone 1 (r = 0.1)", 0.1],
  ["Zone 3 (r = 0.9)", 0.9],
  ["Zone 5 (r = 3)", 3],
  ["Zone 7 (r = 12)", 12],
  ["Zone 8 (r = 30)", 30],
  ["Zone 9 (r = 60)", 60],
];
const MOONS: [string, [number, number] | null][] = [
  ["No moon", null],
  ["10% crescent, 40°", [0.1, 40]],
  ["Half, 40°", [0.5, 40]],
  ["Full, 20°", [1, 20]],
  ["Full, 40°", [1, 40]],
  ["Full, 70°", [1, 70]],
];

export function MoonGrid({ kV = 0.15, cloud = 0.1 }: { kV?: number; cloud?: number }) {
  assertAstrVectors();
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          Cloud {cloud * 100}%, extinction k = {kV}. Each cell is the state, then the effective sky brightness in
          mag/arcsec² and the limiting magnitude. Moon positions are altitudes above the horizon.
        </caption>
        <thead>
          <tr>
            <th>Site</th>
            {MOONS.map(([name]) => (
              <th key={name}>{name}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {SITES.map(([name, r]) => (
            <tr key={name}>
              <td>{name}</td>
              {MOONS.map(([moon, m]) => {
                const b = m
                  ? sky.moonRatio({
                      obsZenithDeg: 0,
                      moonZenithDeg: 90 - m[1],
                      separationDeg: 90 - m[1],
                      phaseAngleDeg: sky.phaseAngleFromIllumination(m[0]),
                      kV,
                    })
                  : 0;
                const sqm = sky.sqmEffective(r, b);
                return (
                  <td key={moon}>
                    {SHORT[sky.skyState(cloud, r, r + b)]} ({f(sqm, 1)}, {f(zone.nelmFromSqm(sqm), 1)})
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function ExtinctionTable() {
  assertAstrVectors();
  const cases: [string, number, number][] = [
    ["Sea level, clean", 0.02, 0],
    ["Sea level, hazy", 0.1, 0],
    ["Sea level, polluted", 0.3, 0],
    ["1000 m, typical", 0.05, 1000],
    ["2400 m, clear (La Palma)", 0.03, 2400],
    ["4000 m, clear", 0.02, 4000],
  ];
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          The measured median V-band extinction at the Roque de los Muchachos observatory (2400 m) on clear nights is
          0.130 mag per airmass (IAC), against 0.127 from this formula.
        </caption>
        <thead>
          <tr>
            <th>Case</th>
            <th>AOD at 550 nm</th>
            <th>Elevation m</th>
            <th>P / P0</th>
            <th>k_V</th>
          </tr>
        </thead>
        <tbody>
          {cases.map(([name, aod, h]) => (
            <tr key={name}>
              <td>{name}</td>
              <td>{aod}</td>
              <td>{h}</td>
              <td>{f(sky.pressureRatio(h), 3)}</td>
              <td>{f(sky.extinctionKV(aod, h), 3)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

import validation from "../../../../content/data/validation-25.json";
import { pythonNumber } from "@/lib/source";

const KERNEL_SOURCE = "scripts/apply_skyglow.py";

/** Parameters of the skyglow kernel, read from the pipeline source so the page cannot disagree with it. */
export function KernelParameters() {
  const names: [string, string, string, string][] = [
    ["F", "SCATTER_FRACTION", "Scatter fraction", "share of upward light that scatters horizontally (the script's default)"],
    ["L", "SCATTER_SCALE_KM", "Scale length, km", "exponential attenuation length"],
    ["d_0", "D_REF_KM", "Reference distance, km", "where the power law takes over"],
    ["\\beta", "SCATTER_POWER", "Power", "power-law falloff"],
    ["d_{\\max}", "MAX_RADIUS_KM", "Maximum radius, km", "scatter beyond this is dropped"],
    ["p", "PIXEL_KM", "Coarse pixel, km", "size of one pixel of the downsampled grid at the equator"],
    ["n", "DOWNSAMPLE", "Downsample factor", "15 arc-second pixels averaged into one coarse pixel"],
    ["h", "H3_RESOLUTION", "H3 resolution", "cell size of the stored zones"],
  ];
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>Values are read from {KERNEL_SOURCE} when the site is built.</caption>
        <thead>
          <tr>
            <th>Symbol</th>
            <th>Meaning</th>
            <th>Value</th>
            <th>Script constant</th>
          </tr>
        </thead>
        <tbody>
          {names.map(([symbol, name, label, note]) => (
            <tr key={name}>
              <td dangerouslySetInnerHTML={{ __html: katex.renderToString(symbol, { throwOnError: true }) }} />
              <td>
                {label}: {note}.
              </td>
              <td>{pythonNumber(KERNEL_SOURCE, name)}</td>
              <td>
                <code>{name}</code>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

/** Contribution of one lit pixel at several distances, from the kernel formula and the script's constants. */
export function KernelTable({ fraction, radiance = 40 }: { fraction?: number; radiance?: number }) {
  const F = fraction ?? pythonNumber(KERNEL_SOURCE, "SCATTER_FRACTION");
  const L = pythonNumber(KERNEL_SOURCE, "SCATTER_SCALE_KM");
  const d0 = pythonNumber(KERNEL_SOURCE, "D_REF_KM");
  const beta = pythonNumber(KERNEL_SOURCE, "SCATTER_POWER");
  const max = pythonNumber(KERNEL_SOURCE, "MAX_RADIUS_KM");
  const k = (d: number): number => (d > max ? 0 : (F * Math.exp(-d / L)) / (1 + (d / d0) ** beta));
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          F = {F}. One lit pixel of {radiance} nW/cm²/sr. A city is many such pixels, so its skyglow is far larger.
        </caption>
        <thead>
          <tr>
            <th>Distance km</th>
            <th>k(d)</th>
            <th>Contribution nW/cm²/sr</th>
          </tr>
        </thead>
        <tbody>
          {[5, 10, 20, 30, 50, 80].map((d) => (
            <tr key={d}>
              <td>{d}</td>
              <td>{k(d).toExponential(2)}</td>
              <td>{(radiance * k(d)).toPrecision(2)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function ValidationTable() {
  const rows = validation.rows;
  const pass = rows.filter((r) => r.expected === r.got).length;
  if (rows.length !== 25) throw new Error("validation-25.json must have 25 rows");
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          {pass} of {rows.length} match. {validation.provenance}
        </caption>
        <thead>
          <tr>
            <th>Place</th>
            <th>Expected</th>
            <th>Stored</th>
            <th>Radiance</th>
            <th>Ladder zone</th>
            <th>Note</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.name}>
              <td>{r.name}</td>
              <td>{r.expected}</td>
              <td>{r.got}</td>
              <td>{r.radiance === null ? "none" : r.radiance}</td>
              <td>{r.radiance === null ? 1 : zone.zoneFromRatio(zone.legacyRatioFromRadiance(r.radiance))}</td>
              <td>{r.expected === r.got ? "" : (r.cause ?? "")}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
