import { FLUID_MAX, FLUID_MIN, PANES, SIZE_ROWS, fluidFactor, readMeasure } from "@/lib/scale";

/** Panes drawn at their real proportions. */
export function PaneDiagram() {
  const total = PANES.reduce((a, p) => a + p.px, 0);
  return (
    <figure className="docs-panes">
      <div style={{ display: "grid", gridTemplateColumns: PANES.map((p) => `${p.px}fr`).join(" ") }}>
        {PANES.map((p) => (
          <div key={p.name}>
            <strong>{p.name}</strong>
            <span>{Math.round((p.px / total) * 100)}%</span>
          </div>
        ))}
      </div>
      <figcaption>
        Proportions {PANES.map((p) => p.px).join(" : ")}, shared out as fr tracks of whatever width the screen has. 233 + 377 = 610, and 377 / 233 and 610 / 377 are both phi to three decimals.
      </figcaption>
    </figure>
  );
}

/** A golden rectangle split into its square and the smaller golden rectangle. */
export function GoldenSplit() {
  return (
    <figure className="docs-golden">
      <div>
        <span>1</span>
        <span>1 / phi</span>
      </div>
      <figcaption>
        Remove the largest square from a golden rectangle and what is left is a smaller golden rectangle. Cut a 1000 px tall sheet at 618 and 382.
      </figcaption>
    </figure>
  );
}

export function SizeTable() {
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <thead>
          <tr>
            <th>Element</th>
            <th>px at base</th>
            <th>Token</th>
            <th>Rule</th>
          </tr>
        </thead>
        <tbody>
          {SIZE_ROWS.map((r) => (
            <tr key={r.element}>
              <td>{r.element}</td>
              <td>{r.px}</td>
              <td>
                <code>f{r.px}</code>
              </td>
              <td>{r.note}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

/** The liquid unit at a range of container widths, computed from the formula. */
export function FluidTable() {
  const widths = [320, FLUID_MIN, 610, 987, 1440, FLUID_MAX, 2560];
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          Computed from the formula and checked against scale.css at build time. Body is step 0, the card padding is f21, the measure is {readMeasure()}.
        </caption>
        <thead>
          <tr>
            <th>Container</th>
            <th>Factor</th>
            <th>Unit u</th>
            <th>Body</th>
            <th>f21</th>
            <th>Heading 2 (s4)</th>
          </tr>
        </thead>
        <tbody>
          {widths.map((w) => {
            const f = fluidFactor(w);
            return (
              <tr key={w}>
                <td>{w}px</td>
                <td>{f.toFixed(3)}</td>
                <td>{(16 * f).toFixed(2)}px</td>
                <td>{(16 * f).toFixed(1)}px</td>
                <td>{(21 * f).toFixed(1)}px</td>
                <td>{(42 * f).toFixed(1)}px</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
