"use client";

import { useState } from "react";
import type { MagStep, Palette } from "@/lib/tokens";
import { DemoFrame } from "../documentation";

export function StopMatrixClient({
  palettes,
  mags,
  backdrop,
}: {
  palettes: Palette[];
  mags: MagStep[];
  backdrop: string;
}) {
  const [paletteId, setPaletteId] = useState("deep-space");
  const [readout, setReadout] = useState("Select a cell to copy its Tailwind class.");
  const palette = palettes.find((p) => p.id === paletteId) ?? palettes[0];

  async function copy(form: string) {
    try {
      await navigator.clipboard.writeText(form);
      setReadout(`Copied ${form}`);
    } catch {
      setReadout(`Copy failed. Use ${form}`);
    }
  }

  return (
    <DemoFrame
      controls={
        <div className="docs-chip-row" role="group" aria-label="Palette">
          {palettes.map((p) => (
            <button
              type="button"
              key={p.id}
              className="docs-chip-button"
              aria-pressed={p.id === paletteId}
              onClick={() => setPaletteId(p.id)}
            >
              {p.name}
            </button>
          ))}
        </div>
      }
      caption="Rows are stops 50 to 950, columns are --mag-0 to --mag-10, over deep-space-950."
    >
      <div className="docs-matrix" style={{ backgroundColor: backdrop }}>
        <span />
        {mags.map((m) => (
          <span key={m.n} className="docs-matrix-head">
            {m.n}
          </span>
        ))}
        {palette.stops.map((stop) => (
          <MatrixRow
            key={stop.token}
            label={`${palette.id}-${stop.step}`}
            hex={stop.hex}
            mags={mags}
            onPick={copy}
          />
        ))}
      </div>
      <p className="docs-readout" aria-live="polite" style={{ width: "100%", marginTop: "var(--spacing-f13)", borderRadius: "var(--radius-f8)" }}>
        {readout}
      </p>
    </DemoFrame>
  );
}

function MatrixRow({
  label,
  hex,
  mags,
  onPick,
}: {
  label: string;
  hex: string;
  mags: MagStep[];
  onPick: (form: string) => void;
}) {
  return (
    <>
      <span className="docs-matrix-label">{label}</span>
      {mags.map((m) => (
        <button
          type="button"
          key={m.n}
          className="docs-matrix-cell"
          aria-label={`${label} at --mag-${m.n}, ${m.value}`}
          title={`${label} at --mag-${m.n}, ${m.value}`}
          style={{
            backgroundColor: `color-mix(in srgb, ${hex} var(--mag-${m.n}), transparent)`,
          }}
          onClick={() => onPick(`bg-${label}/(--mag-${m.n})`)}
        />
      ))}
    </>
  );
}
