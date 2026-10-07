import { assertLadderMatchesCss, magnitudeOf, pogsonAlpha } from "@/lib/ladder";
import { getMagSteps, getStopHex } from "@/lib/tokens";

export function LadderTable() {
  const steps = getMagSteps();
  assertLadderMatchesCss(steps);
  const hex = getStopHex("aurora-green", 400);
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          Computed alpha is rounded to two decimals; CSS values are read from
          globals.css and verified against the formula at build time. The swatch
          shows aurora-green-400 over deep-space-950.
        </caption>
        <thead>
          <tr>
            <th>Step n</th>
            <th>Magnitude</th>
            <th>Alpha (computed)</th>
            <th>Alpha (CSS)</th>
            <th>Token</th>
            <th>Swatch</th>
          </tr>
        </thead>
        <tbody>
          {steps.map((s) => (
            <tr key={s.n}>
              <td>{s.n}</td>
              <td>{magnitudeOf(s.n).toFixed(1)}</td>
              <td>{pogsonAlpha(s.n).toFixed(2)}</td>
              <td>{s.value}</td>
              <td>
                <code>{s.token}</code>
              </td>
              <td>
                <span className="docs-ladder-swatch">
                  <span
                    style={{
                      backgroundColor: `color-mix(in srgb, ${hex} var(${s.token}), transparent)`,
                    }}
                  />
                </span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
