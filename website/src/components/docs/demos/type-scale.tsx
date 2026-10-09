import { TYPE_ROLES, readTypeScale } from "@/lib/scale";

export function TypeScale() {
  const steps = readTypeScale();
  return (
    <div className="docs-typescale">
      {[...steps].reverse().map((s) => {
        const meta = TYPE_ROLES[s.n];
        return (
          <div className="docs-typerow" key={s.n}>
            <div className="docs-typemeta">
              <code>text-s{s.n}</code>
              <span>
                {s.px}px · {s.lineHeight} · {s.tracking.toFixed(4)}em
              </span>
              <small>
                {meta.role} · {meta.family}
              </small>
            </div>
            <p
              style={{
                fontFamily: meta.family === "Satoshi" ? "var(--docs-font-heading)" : "var(--docs-font)",
                fontSize: `var(${s.token})`,
                lineHeight: `var(${s.token}--line-height)`,
                letterSpacing: `var(${s.token}--letter-spacing)`,
                fontWeight: meta.family === "Satoshi" ? 700 : 400,
              }}
            >
              Stars at 21 lux
            </p>
          </div>
        );
      })}
    </div>
  );
}

export function TypeTable() {
  const steps = readTypeScale();
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          Raw is 16 x phi^(n/2). Size is the nearest whole pixel and is what scale.css holds; the build compares the two.
        </caption>
        <thead>
          <tr>
            <th>n</th>
            <th>Raw</th>
            <th>Size</th>
            <th>Leading</th>
            <th>Line box</th>
            <th>Tracking</th>
          </tr>
        </thead>
        <tbody>
          {steps.map((s) => (
            <tr key={s.n}>
              <td>{s.n}</td>
              <td>{(16 * ((1 + Math.sqrt(5)) / 2) ** (s.n / 2)).toFixed(3)}</td>
              <td>{s.px}</td>
              <td>{s.lineHeight}</td>
              <td>{(s.px * s.lineHeight).toFixed(1)}</td>
              <td>{s.tracking.toFixed(4)}em</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
