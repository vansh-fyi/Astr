import { F, T } from "./tokens";

/** Width of a pill for an all-caps label: the glyphs, the tracking between them and --spacing-f8 either side. */
export const pillWidth = (text: string, tracking: number): number =>
  Math.round(text.length * (T.s2n * 0.66 + tracking) - tracking + 2 * F.f8);

/**
 * A label pill for graphs. It is --spacing-f21 tall and as wide as its text plus --spacing-f8 of padding on each
 * side, and the text is centred in it, so the padding is even whatever the label says.
 */
export function GraphPill({
  x,
  y,
  text,
  color,
  fill,
  stroke,
  weight = 600,
  tracking = 0.5,
  radius = F.f5,
}: {
  /** Left edge. */
  x: number;
  /** Vertical centre. */
  y: number;
  text: string;
  color: string;
  fill: string;
  stroke: string;
  weight?: number;
  tracking?: number;
  radius?: number;
}) {
  const w = pillWidth(text, tracking);
  return (
    <g>
      <rect x={x} y={y - F.f21 / 2} width={w} height={F.f21} rx={radius} fill={fill} stroke={stroke} />
      <text x={x + w / 2} y={y} fontSize={T.s2n} fontWeight={weight} letterSpacing={tracking} fill={color} textAnchor="middle" dominantBaseline="central">
        {text}
      </text>
    </g>
  );
}
