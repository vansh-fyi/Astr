import "./app-ui.css";

export type GlyphName = "moon" | "cloud" | "star" | "graph" | "search" | "compass" | "layers" | "telescope";

/** Filled glyphs on a 24 grid, solid shapes so the glow reads like the reference. */
const GLYPHS: Record<GlyphName, string> = {
  moon: "M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5Z",
  cloud: "M7 18a4.5 4.5 0 0 1-.6-8.96A6 6 0 0 1 18 9.5a4.25 4.25 0 0 1-.5 8.5H7Z",
  star: "m12 2.5 2.9 6.1 6.6.8-4.9 4.6 1.3 6.6L12 17.3 6.1 20.6l1.3-6.6L2.5 9.4l6.6-.8L12 2.5Z",
  graph: "M4 20V4h2v14h14v2H4Zm4-4V10h3v6H8Zm5 0V6h3v10h-3Zm5 0v-4h2v4h-2Z",
  search: "M10.5 3a7.5 7.5 0 0 1 5.9 12.1l4.3 4.3-1.3 1.3-4.3-4.3A7.5 7.5 0 1 1 10.5 3Z",
  compass: "M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20Zm3.8 6.2-5.6 2-2 5.6 5.6-2 2-5.6Z",
  layers: "m12 3 9 5-9 5-9-5 9-5Zm-7.5 9L12 16l7.5-4 1.5.8-9 5-9-5 1.5-.8Zm0 4L12 20l7.5-4 1.5.8-9 5-9-5 1.5-.8Z",
  telescope: "m3 11 12-6 2 4-12 6-2-4Zm13 2 5-2.5V14l-5 2.5V13ZM9 17l-3 4h2l2-3 2 3h2l-3-4H9Z",
};

export const Glyph = ({ name }: { name: GlyphName }) => (
  <svg viewBox="0 0 24 24" aria-hidden="true">
    <path d={GLYPHS[name]} fillRule="evenodd" />
  </svg>
);

export type TileTone = "blue" | "green" | "pink" | "amber" | "red";
const TONES: Record<TileTone, string> = {
  blue: "var(--color-deep-space-200)",
  green: "var(--color-aurora-green-400)",
  pink: "var(--color-aurora-pink-400)",
  amber: "var(--color-sodium-airglow-400)",
  red: "var(--color-oxygen-airglow-400)",
};

/** Glass icon tile. Pass `pressed` for a toggle; `label` is the accessible name. */
export function AppIconTile({
  glyph,
  tone = "blue",
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
      style={{ ["--tile" as string]: TONES[tone] }}
      aria-label={label}
      aria-pressed={pressed}
      disabled={disabled}
    >
      <Glyph name={glyph} />
    </button>
  );
}

/** Pill button on the same glass, for actions that carry a word. */
export function AppButton({
  glyph,
  tone = "blue",
  disabled,
  children,
}: {
  glyph?: GlyphName;
  tone?: TileTone;
  disabled?: boolean;
  children: string;
}) {
  return (
    <button type="button" className="app-ui app-button" style={{ ["--tile" as string]: TONES[tone] }} disabled={disabled}>
      {glyph && <Glyph name={glyph} />}
      {children}
    </button>
  );
}
