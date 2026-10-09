"use client";

import { useId, useState, type ReactNode } from "react";
import { CodeBlock } from "../docs/code-block";
import { AppButton, AppIconTile, type GlyphName, type TileTone } from "./app-icons";
import { AppCloudCoverGraph, AppConditionsGraph } from "./app-graphs";
import { AppStage, AppCloudBar, AppConditionsCard, AppMoonCard, AppSkyState, AppVisibilityCard, type SkyStateKey, moonPhase } from "./app-widgets";

type Opt = { value: string; label?: string };
type Control =
  | { kind: "segment"; key: string; label: string; options: Opt[] }
  | { kind: "toggle"; key: string; label: string }
  | { kind: "range"; key: string; label: string; min: number; max: number; step?: number; unit?: string };
type Values = Record<string, string | number | boolean>;

interface Config {
  controls: Control[];
  initial: Values;
  preview: (v: Values) => ReactNode;
  react: (v: Values) => string;
  flutter: (v: Values) => string;
  column?: boolean;
}

const opts = (...values: string[]): Opt[] => values.map((value) => ({ value }));
const TONES = opts("blue", "green", "pink", "amber", "red");
const tone = (v: Values) => v.tone as TileTone;
const ZONE_MPSAS = [22.0, 21.85, 21.6, 21.3, 20.9, 20.4, 19.8, 19.0, 18.2];
const pascal = (s: string) => s[0].toUpperCase() + s.slice(1);
const ICONS: Record<string, string> = { moon: "Icons.nightlight_round", cloud: "Icons.cloud", graph: "Icons.bar_chart", compass: "Icons.explore", search: "Icons.search" };

/** Props that differ from the defaults, as JSX attributes. */
const attrs = (pairs: [string, unknown, unknown?][]): string =>
  pairs
    .filter(([, value, dflt]) => value !== dflt && value !== false && value !== undefined && value !== "")
    .map(([name, value]) => (value === true ? ` ${name}` : typeof value === "number" ? ` ${name}={${value}}` : ` ${name}="${value}"`))
    .join("");

const CONFIGS: Record<string, Config> = {
  "icon-tile": {
    controls: [
      { kind: "segment", key: "glyph", label: "Glyph", options: opts("moon", "cloud", "graph", "compass", "search") },
      { kind: "segment", key: "tone", label: "Tone", options: TONES },
      { kind: "segment", key: "size", label: "Size", options: [{ value: "sm", label: "Small" }, { value: "md", label: "Medium" }, { value: "lg", label: "Large" }] },
      { kind: "segment", key: "state", label: "State", options: opts("default", "selected", "disabled") },
    ],
    initial: { glyph: "moon", tone: "blue", size: "md", state: "default" },
    preview: (v) => (
      <AppIconTile glyph={v.glyph as GlyphName} tone={tone(v)} size={v.size === "md" ? undefined : (v.size as "sm" | "lg")} label={String(v.glyph)} pressed={v.state === "selected" ? true : undefined} disabled={v.state === "disabled"} />
    ),
    react: (v) => `<AppIconTile glyph="${v.glyph}" label="${pascal(String(v.glyph))}"${attrs([["tone", v.tone, "blue"], ["size", v.size, "md"]])}${v.state === "selected" ? " pressed" : v.state === "disabled" ? " disabled" : ""} />`,
    flutter: (v) =>
      `AstrGlassTile(\n  icon: ${ICONS[String(v.glyph)]},\n  label: '${pascal(String(v.glyph))}',\n${v.tone !== "blue" ? `  tone: AstrTone.${v.tone},\n` : ""}${v.size !== "md" ? `  size: AstrTileSize.${v.size},\n` : ""}${v.state === "selected" ? "  selected: true,\n" : ""}  onPressed: ${v.state === "disabled" ? "null" : "() {}"},\n)`,
  },
  button: {
    controls: [
      { kind: "segment", key: "variant", label: "Variant", options: opts("filled", "glass", "outline") },
      { kind: "segment", key: "tone", label: "Tone", options: TONES },
      { kind: "segment", key: "size", label: "Size", options: [{ value: "sm", label: "Small" }, { value: "md", label: "Medium" }, { value: "lg", label: "Large" }] },
      { kind: "toggle", key: "icon", label: "Icon" },
      { kind: "toggle", key: "disabled", label: "Disabled" },
    ],
    initial: { variant: "filled", tone: "blue", size: "md", icon: true, disabled: false },
    preview: (v) => (
      <AppButton glyph={v.icon ? "compass" : undefined} tone={tone(v)} variant={v.variant as "filled"} size={v.size === "md" ? undefined : (v.size as "sm" | "lg")} disabled={Boolean(v.disabled)}>
        Explore
      </AppButton>
    ),
    react: (v) => `<AppButton${attrs([["glyph", v.icon ? "compass" : "", ""], ["tone", v.tone, "blue"], ["variant", v.variant, "filled"], ["size", v.size, "md"], ["disabled", v.disabled]])}>Explore</AppButton>`,
    flutter: (v) =>
      `AstrGlassButton(\n  label: 'Explore',\n${v.icon ? "  icon: Icons.explore,\n" : ""}${v.tone !== "blue" ? `  tone: AstrTone.${v.tone},\n` : ""}${v.variant !== "filled" ? `  variant: AstrButtonVariant.${v.variant},\n` : ""}  onPressed: ${v.disabled ? "null" : "() {}"},\n)${v.size !== "md" ? `\n// Height ${v.size === "sm" ? 32 : 54}: wrap in SizedBox(height: ${v.size === "sm" ? 32 : 54}).` : ""}`,
  },
  "cloud-bar": {
    controls: [
      { kind: "segment", key: "state", label: "State", options: opts("data", "loading", "error") },
      { kind: "range", key: "value", label: "Cloud cover", min: 0, max: 100, unit: "%" },
    ],
    initial: { state: "data", value: 45 },
    preview: (v) => <AppCloudBar value={Number(v.value)} state={v.state as "data"} message="Weather unavailable" />,
    react: (v) => (v.state === "data" ? `<AppCloudBar value={${v.value}} />` : v.state === "loading" ? `<AppCloudBar value={0} state="loading" />` : `<AppCloudBar value={0} state="error" message="Weather unavailable" />`),
    flutter: (v) => (v.state === "data" ? `const CloudBar(cloudCoverPercentage: ${v.value})` : v.state === "loading" ? "const CloudBar(cloudCoverPercentage: 0, isLoading: true)" : "const CloudBar(cloudCoverPercentage: 0, errorMessage: 'Weather unavailable')"),
  },
  "visibility-card": {
    controls: [{ kind: "range", key: "zone", label: "Astr zone", min: 1, max: 9 }],
    initial: { zone: 5 },
    preview: (v) => <AppVisibilityCard zone={Number(v.zone)} mpsas={ZONE_MPSAS[Number(v.zone) - 1]} />,
    react: (v) => `<AppVisibilityCard zone={${v.zone}} mpsas={${ZONE_MPSAS[Number(v.zone) - 1]}} />`,
    flutter: (v) => `VisibilityMiniCard(\n  lightPollution: LightPollution(zone: ${v.zone}, mpsas: ${ZONE_MPSAS[Number(v.zone) - 1]}),\n)`,
  },
  "moon-card": {
    controls: [
      { kind: "segment", key: "phase", label: "Phase", options: [{ value: "0", label: "New" }, { value: "45", label: "Waxing crescent" }, { value: "90", label: "First quarter" }, { value: "135", label: "Waxing gibbous" }, { value: "180", label: "Full" }, { value: "225", label: "Waning gibbous" }, { value: "270", label: "Last quarter" }, { value: "315", label: "Waning crescent" }] },
    ],
    initial: { phase: "135" },
    preview: (v) => <AppMoonCard angle={Number(v.phase)} />,
    react: (v) => `<AppMoonCard angle={${v.phase}} />`,
    flutter: (v) => `MoonMiniCard(\n  moonPhaseInfo: MoonPhaseInfo(\n    phaseAngle: ${v.phase},\n    illumination: ${((1 - Math.cos((Number(v.phase) * Math.PI) / 180)) / 2).toFixed(2)},\n  ), // ${moonPhase(Number(v.phase)).label}\n)`,
  },
  "conditions-card": {
    controls: [
      { kind: "segment", key: "night", label: "Night", options: [{ value: "clear", label: "Clear" }, { value: "cloudy", label: "Cloudy" }, { value: "polar", label: "No moon times" }] },
      { kind: "range", key: "cloud", label: "Cloud cover", min: 0, max: 100, unit: "%" },
    ],
    initial: { night: "clear", cloud: 12 },
    preview: (v) => <AppConditionsCard title={v.night === "cloudy" ? "Cloudy" : "Clear Skies"} subtitle={v.night === "cloudy" ? "Cloud cover hides most of the sky" : "Perfect visibility for observation"} cloud={Number(v.cloud)} times={v.night === "polar" ? { sunrise: "03:40", sunset: "22:18" } : undefined} />,
    react: (v) => `<AppConditionsCard\n  title="${v.night === "cloudy" ? "Cloudy" : "Clear Skies"}"\n  subtitle="${v.night === "cloudy" ? "Cloud cover hides most of the sky" : "Perfect visibility for observation"}"\n  cloud={${v.cloud}}${v.night === "polar" ? '\n  times={{ sunrise: "03:40", sunset: "22:18" }}' : ""}\n/>`,
    flutter: (v) => `const ConditionsCard()\n// weather.cloudCover = ${v.cloud}${v.night === "polar" ? "\n// moon rise and set are null, so those cells show --:--" : ""}`,
  },
  "sky-state": {
    controls: [{ kind: "segment", key: "state", label: "State", options: [{ value: "milkyWayVisible", label: "Milky Way" }, { value: "starrySkies", label: "Starry" }, { value: "planetsVisible", label: "Planets" }, { value: "fewStars", label: "Few stars" }, { value: "cloudy", label: "Cloudy" }, { value: "tooMuchLight", label: "Too much light" }] }],
    initial: { state: "starrySkies" },
    preview: (v) => <AppSkyState state={v.state as SkyStateKey} />,
    react: (v) => `<AppSkyState state="${v.state}" />`,
    flutter: (v) => `SkyStateBackground(skyState: SkyState.${v.state})`,
  },
  "conditions-graph": {
    controls: [
      { kind: "toggle", key: "cloud", label: "Cloud cover" },
      { kind: "toggle", key: "moon", label: "Moon altitude" },
      { kind: "toggle", key: "moonRise", label: "Moon rise" },
      { kind: "toggle", key: "prime", label: "Prime view" },
      { kind: "toggle", key: "now", label: "Now" },
    ],
    initial: { cloud: true, moon: true, moonRise: true, prime: true, now: true },
    column: true,
    preview: (v) => <AppConditionsGraph layers={{ cloud: Boolean(v.cloud), moon: Boolean(v.moon), moonRise: Boolean(v.moonRise), prime: Boolean(v.prime), now: Boolean(v.now) }} />,
    react: (v) => {
      const off = ["cloud", "moon", "moonRise", "prime", "now"].filter((k) => !v[k]);
      return off.length ? `<AppConditionsGraph layers={{ ${off.map((k) => `${k}: false`).join(", ")} }} />` : "<AppConditionsGraph />";
    },
    flutter: (v) => {
      const args = [v.cloud && "cloudCoverData: hourly", v.moon && "moonCurve: curve", v.moonRise && v.moon && "moonRiseTime: rise", v.prime && "primeViewWindow: window"].filter(Boolean) as string[];
      return `ConditionsGraph(\n${args.map((a) => `  ${a},`).join("\n")}\n  startTime: start,\n  endTime: end,\n)${v.now ? "" : "\n// the NOW marker draws only when now is inside [start, end]"}`;
    },
  },
  "cloud-cover-graph": {
    controls: [{ kind: "segment", key: "night", label: "Forecast", options: [{ value: "night", label: "Night" }, { value: "overcast", label: "Overcast" }, { value: "clear", label: "Clear" }] }],
    initial: { night: "night" },
    column: true,
    preview: (v) => <AppCloudCoverGraph data={v.night === "overcast" ? [80, 85, 90, 95, 92, 88, 90] : v.night === "clear" ? [3, 2, 0, 0, 1, 2, 4] : undefined} />,
    react: (v) => (v.night === "overcast" ? "<AppCloudCoverGraph data={[80, 85, 90, 95, 92, 88, 90]} />" : v.night === "clear" ? "<AppCloudCoverGraph data={[3, 2, 0, 0, 1, 2, 4]} />" : "<AppCloudCoverGraph />"),
    flutter: (v) => `CustomPaint(\n  painter: CloudCoverGraphPainter(\n    data: ${v.night === "night" ? "hourly" : v.night + "Hourly"},\n    startTime: start,\n    endTime: end,\n    cloudColor: Colors.white24,\n    nowIndicatorColor: GraphTheme.nowIndicatorColor,\n  ),\n)`,
  },
};

function ControlRow({ control, value, onChange }: { control: Control; value: string | number | boolean; onChange: (v: string | number | boolean) => void }) {
  const id = useId();
  if (control.kind === "toggle")
    return (
      <div className="app-pg-row">
        <span>{control.label}</span>
        <div className="docs-chip-row">
          <button type="button" className="docs-chip-button" aria-pressed={Boolean(value)} onClick={() => onChange(!value)}>
            {value ? "On" : "Off"}
          </button>
        </div>
      </div>
    );
  if (control.kind === "range")
    return (
      <div className="app-pg-row">
        <label htmlFor={id}>{control.label}</label>
        <div className="app-pg-range">
          <input id={id} type="range" min={control.min} max={control.max} step={control.step ?? 1} value={Number(value)} onChange={(e) => onChange(Number(e.target.value))} />
          <output htmlFor={id}>{value}{control.unit}</output>
        </div>
      </div>
    );
  return (
    <div className="app-pg-row" role="group" aria-label={control.label}>
      <span>{control.label}</span>
      <div className="docs-chip-row">
        {control.options.map((o) => (
          <button key={o.value} type="button" className="docs-chip-button" aria-pressed={value === o.value} onClick={() => onChange(o.value)}>
            {o.label ?? pascal(o.value)}
          </button>
        ))}
      </div>
    </div>
  );
}

/** Pick a variant with the controls: the preview and both code blocks follow. */
export function Playground({ name }: { name: string }) {
  const config = CONFIGS[name];
  if (!config) throw new Error(`No playground for ${name}`);
  const [values, setValues] = useState<Values>(config.initial);
  const [tab, setTab] = useState<"react" | "flutter">("react");
  const set = (key: string) => (v: string | number | boolean) => setValues((prev) => ({ ...prev, [key]: v }));
  return (
    <div className="app-pg">
      <div className="app-pg-controls">
        {config.controls.map((c) => (
          <ControlRow key={c.key} control={c} value={values[c.key]} onChange={set(c.key)} />
        ))}
      </div>
      <AppStage column={config.column}>{config.preview(values)}</AppStage>
      <div className="docs-tablist" role="tablist" aria-label="Variant code">
        {(["react", "flutter"] as const).map((t) => (
          <button key={t} type="button" role="tab" className="docs-tab" aria-selected={tab === t} onClick={() => setTab(t)}>
            {t === "react" ? "React" : "Flutter"}
          </button>
        ))}
      </div>
      {tab === "react" ? <CodeBlock lang="javascript" filename="Variant.tsx" code={config.react(values)} /> : <CodeBlock lang="dart" filename="variant.dart" code={config.flutter(values)} />}
    </div>
  );
}
