"use client";

import { useId, useState, type ReactNode } from "react";
import { CodeBlock } from "../docs/code-block";
import { AppButton, AppIconTile, type GlyphName, type TileTone } from "./app-icons";
import { AppToggle } from "./app-toggle";
import { AppTextField } from "./app-text-field";
import { AppNavBar, type NavTab } from "./app-nav-bar";
import { TONE_LABEL, dartTone, type Tone } from "./tokens";
import { AppCloudCoverGraph, AppConditionsGraph } from "./app-graphs";
import { AppObjectGraph } from "./app-object-graph";
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
const TONES: Opt[] = (Object.keys(TONE_LABEL) as Tone[]).map((value) => ({ value, label: TONE_LABEL[value] }));
const tone = (v: Values) => v.tone as TileTone;
const ZONE_MPSAS = [22.0, 21.85, 21.6, 21.3, 20.9, 20.4, 19.8, 19.0, 18.2];
/** Phase angle in degrees (0 new, 180 full) for an illuminated percentage, on the waxing or the waning side. */
const moonAngle = (v: Values): number => {
  const a = Math.round((Math.acos(1 - 2 * (Number(v.lit) / 100)) * 180) / Math.PI);
  return v.side === "waning" ? (360 - a) % 360 : a;
};
const pascal = (s: string) => s[0].toUpperCase() + s.slice(1);
const ICONS: Record<string, string> = { moon: "Icons.nightlight_round", cloud: "Icons.cloud", graph: "Icons.bar_chart", compass: "Icons.explore", search: "Icons.search" };

/** Props that differ from the defaults, as JSX attributes. */
const attrs = (pairs: [string, unknown, unknown?][]): string =>
  pairs
    .filter(([, value, dflt]) => value !== dflt && value !== false && value !== undefined && value !== "")
    .map(([name, value]) => (value === true ? ` ${name}` : typeof value === "number" ? ` ${name}={${value}}` : ` ${name}="${value}"`))
    .join("");

const textFieldLabel = (v: Values): string => (v.kind === "search" ? "Search objects" : v.kind === "email" ? "Email" : v.kind === "multiline" ? "Notes" : "Location");
const textFieldHint = (v: Values): string => (v.kind === "search" ? "Jupiter, M31, Orion" : v.kind === "email" ? "you@example.com" : v.kind === "multiline" ? "What did you see tonight?" : "Where are you observing from?");
const textFieldProps = (v: Values) => ({
  label: textFieldLabel(v),
  placeholder: textFieldHint(v),
  type: (v.kind === "multiline" ? "text" : v.kind) as "text" | "search" | "email",
  multiline: v.kind === "multiline",
  glyph: v.icon && v.kind !== "multiline" ? (v.kind === "search" ? ("search" as GlyphName) : ("pin" as GlyphName)) : undefined,
  help: v.help && v.state !== "error" ? "Shown under the field" : undefined,
  error: v.state === "error" ? "This value is not valid" : undefined,
  size: v.size === "sm" ? ("sm" as const) : undefined,
  tone: v.tone as Tone,
  disabled: v.state === "disabled",
});
const textFieldAttrs = (v: Values): string => {
  const p = textFieldProps(v);
  return `${attrs([["label", p.label, ""], ["type", p.type, "text"], ["placeholder", p.placeholder, ""], ["glyph", p.glyph ?? "", ""], ["help", p.help ?? "", ""], ["error", p.error ?? "", ""], ["size", p.size ?? "", ""], ["tone", p.tone, "deep-space"]])}${p.multiline ? " multiline" : ""}${p.disabled ? " disabled" : ""}`;
};

const CONFIGS: Record<string, Config> = {
  "icon-tile": {
    controls: [
      { kind: "segment", key: "glyph", label: "Glyph", options: opts("moon", "cloud", "graph", "compass", "search") },
      { kind: "segment", key: "tone", label: "Tone", options: TONES },
      { kind: "segment", key: "size", label: "Size", options: [{ value: "sm", label: "Small" }, { value: "md", label: "Medium" }, { value: "lg", label: "Large" }] },
      { kind: "segment", key: "state", label: "State", options: opts("default", "selected", "disabled") },
    ],
    initial: { glyph: "moon", tone: "deep-space", size: "md", state: "default" },
    preview: (v) => (
      <AppIconTile glyph={v.glyph as GlyphName} tone={tone(v)} size={v.size === "md" ? undefined : (v.size as "sm" | "lg")} label={String(v.glyph)} pressed={v.state === "selected" ? true : undefined} disabled={v.state === "disabled"} />
    ),
    react: (v) => `<AppIconTile glyph="${v.glyph}" label="${pascal(String(v.glyph))}"${attrs([["tone", v.tone, "deep-space"], ["size", v.size, "md"]])}${v.state === "selected" ? " pressed" : v.state === "disabled" ? " disabled" : ""} />`,
    flutter: (v) =>
      `AstrGlassTile(\n  icon: ${ICONS[String(v.glyph)]},\n  label: '${pascal(String(v.glyph))}',\n${v.tone !== "deep-space" ? `  tone: AstrTone.${dartTone(v.tone as Tone)},\n` : ""}${v.size !== "md" ? `  size: AstrTileSize.${v.size},\n` : ""}${v.state === "selected" ? "  selected: true,\n" : ""}  onPressed: ${v.state === "disabled" ? "null" : "() {}"},\n)`,
  },
  button: {
    controls: [
      { kind: "segment", key: "variant", label: "Variant", options: opts("filled", "glass", "outline") },
      { kind: "segment", key: "tone", label: "Tone", options: TONES },
      { kind: "segment", key: "size", label: "Size", options: [{ value: "md", label: "Medium" }, { value: "sm", label: "Small" }] },
      { kind: "toggle", key: "icon", label: "Icon" },
      { kind: "toggle", key: "disabled", label: "Disabled" },
    ],
    initial: { variant: "filled", tone: "deep-space", size: "md", icon: true, disabled: false },
    preview: (v) => (
      <AppButton glyph={v.icon ? "compass" : undefined} tone={tone(v)} variant={v.variant as "filled"} size={v.size === "sm" ? "sm" : undefined} disabled={Boolean(v.disabled)}>
        Explore
      </AppButton>
    ),
    react: (v) => `<AppButton${attrs([["glyph", v.icon ? "compass" : "", ""], ["tone", v.tone, "deep-space"], ["variant", v.variant, "filled"], ["size", v.size, "md"], ["disabled", v.disabled]])}>Explore</AppButton>`,
    flutter: (v) =>
      `AstrGlassButton(\n  label: 'Explore',\n${v.icon ? "  icon: Icons.explore,\n" : ""}${v.tone !== "deep-space" ? `  tone: AstrTone.${dartTone(v.tone as Tone)},\n` : ""}${v.variant !== "filled" ? `  variant: AstrButtonVariant.${v.variant},\n` : ""}${v.size === "sm" ? "  compact: true,\n" : ""}  onPressed: ${v.disabled ? "null" : "() {}"},\n)`,
  },
  "text-field": {
    controls: [
      { kind: "segment", key: "kind", label: "Type", options: [{ value: "text", label: "Text" }, { value: "search", label: "Search" }, { value: "email", label: "Email" }, { value: "multiline", label: "Multiline" }] },
      { kind: "segment", key: "size", label: "Size", options: [{ value: "md", label: "Medium" }, { value: "sm", label: "Small" }] },
      { kind: "segment", key: "state", label: "State", options: opts("default", "error", "disabled") },
      { kind: "segment", key: "tone", label: "Focus tone", options: TONES },
      { kind: "toggle", key: "icon", label: "Icon" },
      { kind: "toggle", key: "help", label: "Help text" },
    ],
    initial: { kind: "text", size: "md", state: "default", tone: "deep-space", icon: true, help: true },
    preview: (v) => <AppTextField key={`${v.kind}`} {...textFieldProps(v)} />,
    react: (v) => `<AppTextField${textFieldAttrs(v)} />`,
    flutter: (v) =>
      `AstrGlassTextField(\n  label: '${textFieldLabel(v)}',\n  hintText: '${textFieldHint(v)}',\n${v.help && v.state !== "error" ? "  helperText: 'Shown under the field',\n" : ""}${v.state === "error" ? "  errorText: 'This value is not valid',\n" : ""}${v.icon && v.kind !== "multiline" ? `  icon: ${v.kind === "search" ? "Icons.search" : "Icons.place"},\n` : ""}${v.tone !== "deep-space" ? `  tone: AstrTone.${dartTone(v.tone as Tone)},\n` : ""}${v.size === "sm" ? "  compact: true,\n" : ""}${v.kind === "multiline" ? "  maxLines: 3,\n" : ""}${v.state === "disabled" ? "  enabled: false,\n" : ""})`,
  },
  "nav-bar": {
    controls: [
      { kind: "segment", key: "variant", label: "Variant", options: [{ value: "bottom", label: "Bottom bar" }, { value: "top", label: "Top bar" }] },
      { kind: "segment", key: "active", label: "Active tab", options: [{ value: "home", label: "Home" }, { value: "objects", label: "Objects" }, { value: "forecast", label: "Forecast" }, { value: "settings", label: "Settings" }] },
      { kind: "toggle", key: "action", label: "Centre action" },
    ],
    initial: { variant: "bottom", active: "home", action: true },
    column: true,
    preview: (v) => <AppNavBar key={`${v.variant}-${v.active}-${v.action}`} variant={v.variant as "bottom"} active={v.active as NavTab} action={Boolean(v.action)} />,
    react: (v) => `<AppNavBar${attrs([["variant", v.variant, "bottom"], ["active", v.active, "home"], ["action", v.action ? "" : "false", ""]]).replace(' action="false"', " action={false}")} />`,
    flutter: (v) =>
      v.variant === "bottom"
        ? `// ScaffoldWithNavBar: the bottom bar and its notch\nbottomNavigationBar: Stack(/* NavBarClipper, _NavBarItem x4 */)\n// active tab: navigationShell.currentIndex == ${["home", "objects", "forecast", "settings"].indexOf(String(v.active))}${v.action ? "\nfloatingActionButton: FloatingActionButton(/* sky map */)" : ""}`
        : "// ScaffoldWithNavBar: the global header\nPositioned(top: 0, child: SafeArea(/* location pill, logo, date stepper */))",
  },
  toggle: {
    controls: [
      { kind: "segment", key: "tone", label: "Tone", options: TONES },
      { kind: "segment", key: "size", label: "Size", options: [{ value: "md", label: "Medium" }, { value: "sm", label: "Small" }] },
      { kind: "toggle", key: "on", label: "On" },
      { kind: "toggle", key: "disabled", label: "Disabled" },
    ],
    initial: { tone: "deep-space", size: "md", on: true, disabled: false },
    preview: (v) => <AppToggle key={`${v.on}`} label="Cloud cover" tone={tone(v)} size={v.size === "sm" ? "sm" : undefined} defaultChecked={Boolean(v.on)} disabled={Boolean(v.disabled)} />,
    react: (v) => `<AppToggle label="Cloud cover"${attrs([["tone", v.tone, "deep-space"], ["size", v.size === "sm" ? "sm" : "", ""], ["defaultChecked", v.on], ["disabled", v.disabled]])} />`,
    flutter: (v) => `AstrGlassToggle(\n  value: ${v.on},\n  onChanged: ${v.disabled ? "null" : "(bool on) {}"},\n  label: 'Cloud cover',\n${v.tone !== "deep-space" ? `  tone: AstrTone.${dartTone(v.tone as Tone)},\n` : ""}${v.size === "sm" ? "  compact: true,\n" : ""})`,
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
      { kind: "segment", key: "side", label: "Cycle", options: [{ value: "waxing", label: "Waxing" }, { value: "waning", label: "Waning" }] },
      { kind: "range", key: "lit", label: "Illuminated", min: 0, max: 100, unit: "%" },
    ],
    initial: { side: "waxing", lit: 85 },
    preview: (v) => <AppMoonCard angle={moonAngle(v)} illumination={Number(v.lit) / 100} />,
    react: (v) => `<AppMoonCard angle={${moonAngle(v)}} illumination={${Number(v.lit) / 100}} />`,
    flutter: (v) => `MoonMiniCard(\n  moonPhaseInfo: MoonPhaseInfo(\n    phaseAngle: ${moonAngle(v)},\n    illumination: ${Number(v.lit) / 100},\n  ), // ${moonPhase(moonAngle(v)).label}\n)`,
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
  "object-graph": {
    controls: [
      { kind: "segment", key: "variant", label: "Variant", options: [{ value: "visibility", label: "Visibility" }, { value: "altitude", label: "Altitude" }] },
      { kind: "segment", key: "object", label: "Object", options: [{ value: "high", label: "High object" }, { value: "low", label: "Low object" }, { value: "late", label: "Late riser" }] },
      { kind: "segment", key: "tone", label: "Highlight", options: TONES },
      { kind: "toggle", key: "horizon", label: "Horizon view" },
    ],
    initial: { variant: "visibility", object: "high", tone: "deep-space", horizon: false },
    column: true,
    preview: (v) => <AppObjectGraph variant={v.variant as "visibility"} objectId={String(v.object)} tone={tone(v)} horizon={Boolean(v.horizon)} />,
    react: (v) => `<AppObjectGraph${attrs([["variant", v.variant, "visibility"], ["objectId", v.object, "high"], ["tone", v.tone, "deep-space"], ["horizon", v.horizon]])} />`,
    flutter: (v) =>
      v.variant === "visibility"
        ? `VisibilityGraphWidget(\n  objectId: '${v.object}',\n${v.tone !== "deep-space" ? `  highlightColor: AstrTone.${dartTone(v.tone as Tone)}.color,\n` : ""})${v.horizon ? "\n// Horizon view: proposed, not in the app yet." : ""}`
        : `AltitudeGraph(\n  themeColor: AstrTone.${dartTone(v.tone as Tone)}.color,\n)`,
  },
  "cloud-cover-graph": {
    controls: [{ kind: "segment", key: "night", label: "Forecast", options: [{ value: "night", label: "Night" }, { value: "overcast", label: "Overcast" }, { value: "clear", label: "Clear" }] }],
    initial: { night: "night" },
    column: true,
    preview: (v) => <AppCloudCoverGraph data={v.night === "overcast" ? [80, 85, 90, 95, 92, 88, 90, 94, 96, 92, 90, 93, 95] : v.night === "clear" ? [3, 2, 0, 0, 1, 2, 4, 2, 1, 0, 0, 2, 5] : undefined} />,
    react: (v) => (v.night === "night" ? "<AppCloudCoverGraph />" : `<AppCloudCoverGraph data={[${v.night === "overcast" ? "80, 85, 90, 95, 92, 88, 90, 94, 96, 92, 90, 93, 95" : "3, 2, 0, 0, 1, 2, 4, 2, 1, 0, 0, 2, 5"}]} />`),
    flutter: (v) => `ConditionsGraph(\n  cloudCoverData: ${v.night === "night" ? "hourly" : v.night + "Hourly"},\n  startTime: start,\n  endTime: end,\n)\n// cloud layer only: no moonCurve, moonRiseTime or primeViewWindow`,
  },
};

function ControlRow({ control, value, onChange }: { control: Control; value: string | number | boolean; onChange: (v: string | number | boolean) => void }) {
  const id = useId();
  if (control.kind === "toggle")
    return (
      <div className="app-pg-row">
        <span>{control.label}</span>
        <div>
          <AppToggle label={control.label} hideLabel checked={Boolean(value)} onChange={onChange} />
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
          <button key={o.value} type="button" className="app-ui app-button is-glass is-sm" aria-pressed={value === o.value} onClick={() => onChange(o.value)}>
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
          <button key={t} type="button" role="tab" className="docs-tab app-ui app-button is-glass is-sm" aria-selected={tab === t} onClick={() => setTab(t)}>
            {t === "react" ? "React" : "Flutter"}
          </button>
        ))}
      </div>
      {tab === "react" ? <CodeBlock lang="javascript" filename="Variant.tsx" code={config.react(values)} /> : <CodeBlock lang="dart" filename="variant.dart" code={config.flutter(values)} />}
    </div>
  );
}
