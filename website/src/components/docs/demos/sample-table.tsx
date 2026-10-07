import { crossCheckedRows } from "@/lib/gradients";
import { formatPercent } from "@/lib/ladder";

function stepLabel(step: number | null): string {
  return step === null ? "transparent" : `--mag-${step}`;
}

export function SampleTable({ kind }: { kind: "extinction" | "moffat" }) {
  const rows = crossCheckedRows(kind);
  const extinction = kind === "extinction";
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          Alpha snaps to the nearest --mag step; a stop below the 10.5 half-step
          floor becomes transparent. Every row is verified against globals.css
          at build time.
        </caption>
        <thead>
          <tr>
            {extinction ? (
              <>
                <th>z (deg)</th>
                <th>Airmass X</th>
                <th>Position</th>
                <th>Raw alpha</th>
              </>
            ) : (
              <>
                <th>Position p</th>
                <th>r / a</th>
                <th>I(r)</th>
              </>
            )}
            <th>Snapped step</th>
            <th>Snapped alpha</th>
            <th>CSS stop</th>
            <th>Match</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.input}>
              {extinction ? (
                <>
                  <td>{row.input}</td>
                  <td>{row.airmass?.toFixed(3)}</td>
                  <td>{row.position}%</td>
                  <td>{row.raw.toFixed(4)}</td>
                </>
              ) : (
                <>
                  <td>{row.position}%</td>
                  <td>{row.rOverA?.toFixed(2)}</td>
                  <td>{row.raw.toFixed(4)}</td>
                </>
              )}
              <td>
                <code>{stepLabel(row.step)}</code>
              </td>
              <td>{formatPercent(row.snapped)}</td>
              <td>
                <code>
                  {row.css ? `${stepLabel(row.css.step)} @ ${row.css.pos}%` : "none"}
                </code>
              </td>
              <td>
                <span className={row.match ? "docs-ok" : "docs-bad"}>
                  {row.match ? "✓" : "✗"}
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
