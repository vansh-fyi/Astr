"use client";

import type { Palette, PaletteStop } from "@/lib/tokens";

export function findStop(
  palettes: Palette[],
  value: string,
): { id: string; stop: PaletteStop } {
  for (const palette of palettes) {
    for (const stop of palette.stops) {
      if (`${palette.id}-${stop.step}` === value) return { id: palette.id, stop };
    }
  }
  const first = palettes[0];
  return { id: first.id, stop: first.stops[0] };
}

export function StopSelect({
  palettes,
  value,
  onChange,
  label = "Colour stop",
}: {
  palettes: Palette[];
  value: string;
  onChange: (value: string) => void;
  label?: string;
}) {
  return (
    <label>
      {label}
      <select
        className="docs-select"
        value={value}
        onChange={(event) => onChange(event.target.value)}
      >
        {palettes.map((palette) => (
          <optgroup key={palette.id} label={palette.name}>
            {palette.stops.map((stop) => (
              <option key={stop.token} value={`${palette.id}-${stop.step}`}>
                {`${palette.id}-${stop.step}  ${stop.hex}`}
              </option>
            ))}
          </optgroup>
        ))}
      </select>
    </label>
  );
}
