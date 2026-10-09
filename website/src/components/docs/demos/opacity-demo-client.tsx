"use client";

import { useState } from "react";
import type { MagStep, Palette } from "@/lib/tokens";
import { CopyButton } from "../code-block";
import { DemoFrame } from "../documentation";
import { StopSelect, findStop } from "./stop-select";

export function OpacityDemoClient({
  palettes,
  mags,
  backdrop,
}: {
  palettes: Palette[];
  mags: MagStep[];
  backdrop: string;
}) {
  const [value, setValue] = useState("deep-space-300");
  const [active, setActive] = useState(3);
  const { stop } = findStop(palettes, value);
  const form = `bg-${value}/(--mag-${active})`;
  return (
    <DemoFrame
      controls={<StopSelect palettes={palettes} value={value} onChange={setValue} />}
      caption="Same result as the Tailwind class form shown below the tiles."
    >
      <div className="docs-tiles" style={{ backgroundColor: backdrop, padding: "var(--spacing-f13)", borderRadius: "var(--radius-f8)" }}>
        {mags.map((m) => (
          <button
            type="button"
            key={m.n}
            className="docs-tile"
            aria-label={`${value} at --mag-${m.n}, ${m.value}`}
            aria-pressed={active === m.n}
            onClick={() => setActive(m.n)}
            onMouseEnter={() => setActive(m.n)}
          >
            <span
              style={{
                backgroundColor: `color-mix(in srgb, ${stop.hex} var(--mag-${m.n}), transparent)`,
              }}
            />
            <small>{`--mag-${m.n}`}</small>
            <small>{m.value}</small>
          </button>
        ))}
      </div>
      <div className="docs-readout" style={{ width: "100%", marginTop: "var(--spacing-f13)", borderRadius: "var(--radius-f8)" }}>
        <code>{form}</code>
        <CopyButton text={form} />
      </div>
    </DemoFrame>
  );
}
