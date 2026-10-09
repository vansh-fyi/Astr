import { fibonacci } from "./scale";

export interface Square {
  x: number;
  y: number;
  s: number;
}
type Pt = { x: number; y: number };

export interface Spiral {
  squares: Square[];
  /** SVG path through every square, one quarter-circle per square. */
  path: string;
  viewBox: string;
}

const same = (a: Pt, b: Pt): boolean => a.x === b.x && a.y === b.y;
const cross = (a: Pt, b: Pt): number => a.x * b.y - a.y * b.x;
const dot = (a: Pt, b: Pt): number => a.x * b.x + a.y * b.y;
const sub = (a: Pt, b: Pt): Pt => ({ x: a.x - b.x, y: a.y - b.y });

const corners = (q: Square): Pt[] => [
  { x: q.x, y: q.y },
  { x: q.x + q.s, y: q.y },
  { x: q.x + q.s, y: q.y + q.s },
  { x: q.x, y: q.y + q.s },
];

/** Places F(1)..F(count) as squares wound around each other: 1, 1, then top, left, bottom, right. */
function placeSquares(count: number): Square[] {
  const f = fibonacci(count);
  const sq: Square[] = [
    { x: 0, y: 0, s: 1 },
    { x: 1, y: 0, s: 1 },
  ];
  let box = { x0: 0, y0: 0, x1: 2, y1: 1 };
  for (let i = 2; i < count; i++) {
    const s = f[i];
    const side = (i - 2) % 4;
    let q: Square;
    if (side === 0) q = { x: box.x0, y: box.y0 - s, s };
    else if (side === 1) q = { x: box.x0 - s, y: box.y1 - s, s };
    else if (side === 2) q = { x: box.x0, y: box.y1, s };
    else q = { x: box.x1, y: box.y0, s };
    sq.push(q);
    box = {
      x0: Math.min(box.x0, q.x),
      y0: Math.min(box.y0, q.y),
      x1: Math.max(box.x1, q.x + q.s),
      y1: Math.max(box.y1, q.y + q.s),
    };
  }
  return sq;
}

interface Arc {
  from: Pt;
  to: Pt;
  centre: Pt;
  r: number;
  sweep: 0 | 1;
}

/** Finds one smooth chain of quarter-circles, one per square, by depth-first search. */
function chain(squares: Square[]): Arc[] {
  const options = (q: Square): Arc[] => {
    const c = corners(q);
    const out: Arc[] = [];
    for (let ci = 0; ci < 4; ci++) {
      const centre = c[ci];
      const a = c[(ci + 1) % 4];
      const b = c[(ci + 3) % 4];
      for (const [from, to] of [[a, b], [b, a]] as [Pt, Pt][]) {
        const sweep = cross(sub(from, centre), sub(to, centre)) > 0 ? 1 : 0;
        out.push({ from, to, centre, r: q.s, sweep });
      }
    }
    return out;
  };
  const search = (i: number, prev: Arc | null, sweep: 0 | 1): Arc[] | null => {
    if (i === squares.length) return [];
    for (const arc of options(squares[i])) {
      if (arc.sweep !== sweep) continue;
      if (prev) {
        if (!same(prev.to, arc.from)) continue;
        const t0 = sub(prev.to, prev.centre);
        const t1 = sub(arc.from, arc.centre);
        // Smooth join: both centres lie on the same side of the shared point, on one line,
        // so the curve keeps turning the same way with a growing radius.
        if (cross(t0, t1) !== 0 || dot(t0, t1) <= 0) continue;
      }
      const rest = search(i + 1, arc, sweep);
      if (rest) return [arc, ...rest];
    }
    return null;
  };
  for (const sweep of [1, 0] as const) {
    const found = search(0, null, sweep);
    if (found) return found;
  }
  throw new Error("No smooth spiral found for the squares");
}

export function buildSpiral(count: number): Spiral {
  const squares = placeSquares(count);
  const arcs = chain(squares);
  const path = arcs
    .map((a, i) => {
      const move = i === 0 ? `M${a.from.x} ${a.from.y} ` : "";
      return `${move}A${a.r} ${a.r} 0 0 ${a.sweep} ${a.to.x} ${a.to.y}`;
    })
    .join(" ");
  const x0 = Math.min(...squares.map((q) => q.x));
  const y0 = Math.min(...squares.map((q) => q.y));
  const x1 = Math.max(...squares.map((q) => q.x + q.s));
  const y1 = Math.max(...squares.map((q) => q.y + q.s));
  return { squares, path, viewBox: `${x0} ${y0} ${x1 - x0} ${y1 - y0}` };
}
