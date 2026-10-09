import "./app-ui.css";
import { TONE_STOP, type Tone } from "./tokens";

export type GlyphName = "moon" | "cloud" | "graph" | "search" | "compass" | "layers" | "telescope" | "home" | "planet" | "calendar" | "settings" | "map" | "pin" | "chevron-left" | "chevron-right";

/** Filled glyphs on a 24 grid, solid shapes so the glow reads like the reference. */
const GLYPHS: Record<GlyphName, string> = {
  moon: "M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5Z",
  cloud: "M7 18a4.5 4.5 0 0 1-.6-8.96A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5H7Z",
  graph: "M4 20V4h2v14h14v2H4Zm4-4V10h3v6H8Zm5 0V6h3v10h-3Zm5 0v-4h2v4h-2Z",
  search: "M10.5 3a7.5 7.5 0 0 1 5.9 12.1l4.3 4.3-1.3 1.3-4.3-4.3A7.5 7.5 0 1 1 10.5 3Zm0 2a5.500 5.500 0 1 0 0 11 5.500 5.500 0 0 0 0-11Z",
  compass: "M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20Zm3.8 6.2-5.6 2-2 5.6 5.6-2 2-5.6Z",
  layers: "m12 3 9 5-9 5-9-5 9-5Zm-7.5 9L12 16l7.5-4 1.5.8-9 5-9-5 1.5-.8Zm0 4L12 20l7.5-4 1.5.8-9 5-9-5 1.5-.8Z",
  home: "M12 3 2.500 11.500H5V20h5.500v-5.500h3V20H19v-8.500h2.500L12 3Z",
  planet: "M12 6.500a5.500 5.500 0 1 1 0 11 5.500 5.500 0 0 1 0-11ZM2.500 12c0-1.900 4.200-3.500 9.500-3.500s9.500 1.600 9.500 3.500-4.200 3.500-9.500 3.500S2.500 13.900 2.500 12Zm2 0c0 .6 3.300 1.600 7.500 1.600s7.500-1 7.500-1.600-3.300-1.600-7.500-1.600S4.500 11.400 4.500 12Z",
  calendar: "M7 2.500v2H5.500A2.500 2.500 0 0 0 3 7v11.500A2.500 2.500 0 0 0 5.500 21h13a2.500 2.500 0 0 0 2.500-2.500V7a2.500 2.500 0 0 0-2.500-2.500H17v-2h-2v2H9v-2H7ZM5 10h14v8.500a.5.5 0 0 1-.5.500h-13a.5.5 0 0 1-.5-.5V10Z",
  settings: "M4 6h9v2H4V6Zm11-1h2v4h-2V5Zm2 1h3v2h-3V6ZM4 11h3v2H4v-2Zm5-1h2v4H9v-4Zm2 1h9v2h-9v-2ZM4 16h9v2H4v-2Zm11-1h2v4h-2v-4Zm2 1h3v2h-3v-2Z",
  map: "M9 4 3 6.200V20l6-2.200 6 2.200 6-2.200V4l-6 2.200L9 4Zm1 2.400 4 1.500v9.700l-4-1.500V6.400Z",
  pin: "M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7Zm0 9.500a2.500 2.500 0 1 1 0-5 2.500 2.500 0 0 1 0 5Z",
  "chevron-left": "M14.500 5.500 8 12l6.500 6.500 1.500-1.500L11 12l5-5-1.500-1.500Z",
  "chevron-right": "M9.500 5.500 8 7l5 5-5 5 1.500 1.500L16 12 9.500 5.500Z",
  telescope: "m3 11 12-6 2 4-12 6-2-4Zm13 2 5-2.5V14l-5 2.5V13ZM9 17l-3 4h2l2-3 2 3h2l-3-4H9Z",
};

export const Glyph = ({ name }: { name: GlyphName }) => (
  <svg viewBox="0 0 24 24" aria-hidden="true">
    <path d={GLYPHS[name]} fillRule="evenodd" />
  </svg>
);

export type TileTone = Tone;
const toneVar = (tone: Tone): string => `var(--color-${TONE_STOP[tone]})`;

/** Glass icon tile. Pass `pressed` for a toggle; `label` is the accessible name. */
export function AppIconTile({
  glyph,
  tone = "deep-space",
  size,
  label,
  pressed,
  disabled,
}: {
  glyph: GlyphName;
  tone?: TileTone;
  size?: "sm" | "lg";
  label: string;
  pressed?: boolean;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      className={`app-ui app-tile${size ? ` is-${size}` : ""}`}
      style={{ ["--tone" as string]: toneVar(tone) }}
      aria-label={label}
      aria-pressed={pressed}
      disabled={disabled}
    >
      <Glyph name={glyph} />
    </button>
  );
}

export type ButtonVariant = "filled" | "glass" | "outline";

/** Button. Filled is the default; glass and outline are quieter. */
export function AppButton({
  glyph,
  tone = "deep-space",
  variant = "filled",
  size,
  disabled,
  children,
}: {
  glyph?: GlyphName;
  tone?: TileTone;
  variant?: ButtonVariant;
  size?: "sm";
  disabled?: boolean;
  children: string;
}) {
  const cls = ["app-ui app-button", variant !== "filled" && `is-${variant}`, size && `is-${size}`].filter(Boolean).join(" ");
  return (
    <button type="button" className={cls} style={{ ["--tone" as string]: toneVar(tone) }} disabled={disabled}>
      {glyph && <Glyph name={glyph} />}
      {children}
    </button>
  );
}
