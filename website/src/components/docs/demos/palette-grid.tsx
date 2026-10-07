import { BENTO_IMAGES, IMAGE_BASE } from "@/lib/images";
import { getPalettes } from "@/lib/tokens";
import { ColorChip } from "../color-chip";

export function PaletteGrid() {
  return (
    <>
      {getPalettes().map((palette) => (
        <div className="docs-ramp" key={palette.id}>
          <div className="docs-ramp-head">
            <h3>{palette.name}</h3>
            <code>{`--color-${palette.id}-{step}`}</code>
          </div>
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

/**
 * Photographs that inspired each palette, with the palette's eleven stops as a
 * strip on the caption. Images are pre-optimised webp served from the CDN, so a
 * plain img element is used instead of the Next.js image optimiser.
 */
export function PaletteBento() {
  const palettes = new Map(getPalettes().map((p) => [p.id, p]));
  return (
    <div className="docs-bento">
      {BENTO_IMAGES.map((image) => {
        const palette = palettes.get(image.palette);
        if (!palette) throw new Error(`PaletteBento: unknown palette ${image.palette}`);
        return (
          <figure className="docs-bento-tile" data-palette={palette.id} key={palette.id}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={`${IMAGE_BASE}/${image.file}`}
              alt={image.alt}
              width={image.width}
              height={image.height}
              loading="lazy"
              decoding="async"
            />
            <figcaption>
              <span>{palette.name}</span>
              <span className="docs-bento-strip" aria-hidden="true">
                {palette.stops.map((stop) => (
                  <i key={stop.token} style={{ backgroundColor: stop.hex }} />
                ))}
              </span>
            </figcaption>
          </figure>
        );
      })}
    </div>
  );
}
