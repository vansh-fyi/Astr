import { buildSpiral } from "@/lib/spiral";

/** Squares of side F(n) with a quarter-circle in each. Built from the sequence, not drawn. */
export function FibonacciSpiral() {
  const { squares, path, viewBox } = buildSpiral(10);
  return (
    <figure className="docs-spiral">
      <svg viewBox={viewBox} role="img" aria-label="Ten squares with sides 1, 1, 2, 3, 5, 8, 13, 21, 34 and 55, wound into a spiral">
        {squares.map((q, i) => (
          <rect key={i} className="docs-spiral-square" x={q.x} y={q.y} width={q.s} height={q.s} />
        ))}
        <path className="docs-spiral-curve" d={path} />
        {squares
          .filter((q) => q.s >= 5)
          .map((q, i) => (
            <text
              key={i}
              className="docs-spiral-label"
              x={q.x + q.s / 2}
              y={q.y + q.s / 2}
              fontSize={q.s * 0.22}
              textAnchor="middle"
              dominantBaseline="central"
            >
              {q.s}
            </text>
          ))}
      </svg>
      <figcaption>
        Each square is the sum of the two before it. The arc through every square is a golden spiral, the shape of a nautilus shell.
      </figcaption>
    </figure>
  );
}
