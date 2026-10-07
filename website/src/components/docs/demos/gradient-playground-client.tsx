"use client";

import { useState, type CSSProperties } from "react";
import type { Palette } from "@/lib/tokens";
import { CopyButton } from "../code-block";
import { DemoFrame } from "../documentation";
import { StopSelect, findStop } from "./stop-select";

const DIRECTIONS = ["to bottom", "to top", "to right", "to left"] as const;

export function GradientPlaygroundClient({
  kind,
  palettes,
  backdrop,
}: {
  kind: "extinction" | "moffat";
  palettes: Palette[];
  backdrop: string;
}) {
  const [value, setValue] = useState("aurora-green-400");
  const [direction, setDirection] = useState<(typeof DIRECTIONS)[number]>("to bottom");
  const { stop } = findStop(palettes, value);
  const usage = `gradient-${kind} [--grad-color:var(--color-${value})]`;
  const style = {
    "--grad-color": stop.hex,
    "--grad-dir": direction,
  } as CSSProperties;
  // Literal class strings so Tailwind's scanner emits both utilities.
  const fillClass =
    kind === "extinction"
      ? "docs-gradient-fill gradient-extinction"
      : "docs-gradient-fill gradient-moffat";
  return (
    <DemoFrame
      controls={
        <>
          <StopSelect palettes={palettes} value={value} onChange={setValue} />
          {kind === "extinction" && (
            <label>
              Direction
              <select
                className="docs-select"
                value={direction}
                onChange={(event) =>
                  setDirection(event.target.value as (typeof DIRECTIONS)[number])
                }
              >
                {DIRECTIONS.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </select>
            </label>
          )}
        </>
      }
      caption={
        kind === "extinction"
          ? "With the default direction the top edge is the zenith and the bottom edge is the horizon."
          : "The centre is the source; intensity falls off to transparent at 60% of the radius."
      }
    >
      <div
        className="docs-gradient-stage"
        data-kind={kind}
        style={{ backgroundColor: backdrop }}
      >
        <div className={fillClass} style={style} />
      </div>
      <div className="docs-readout" style={{ width: "100%", marginTop: 16, borderRadius: 8 }}>
        <code>{usage}</code>
        <CopyButton text={usage} />
      </div>
    </DemoFrame>
  );
}
