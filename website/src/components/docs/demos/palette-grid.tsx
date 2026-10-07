import { getPalettes } from "@/lib/tokens";
import { ColorChip } from "../color-chip";

export function PaletteGrid() {
  return (
    <>
      {getPalettes().map((palette) => (
        <div className="docs-ramp" key={palette.id}>
          <h3>{palette.name}</h3>
          <p className="docs-ramp-note">
            <code>{`--color-${palette.id}-{step}`}</code>
          </p>
          <div className="docs-ramp-steps">
            {palette.stops.map((stop) => (
              <ColorChip
                key={stop.token}
                step={stop.step}
                value={stop.hex}
                label={`${palette.id}-${stop.step}`}
              />
            ))}
          </div>
        </div>
      ))}
    </>
  );
}

export function PaletteStrip() {
  return (
    <div className="docs-swatch-strip" role="img" aria-label="All six palettes, steps 50 to 950">
      {getPalettes().map((palette) => (
        <div key={palette.id}>
          {palette.stops.map((stop) => (
            <span key={stop.token} style={{ backgroundColor: stop.hex }} />
          ))}
        </div>
      ))}
    </div>
  );
}
