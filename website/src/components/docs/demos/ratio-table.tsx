import { PHI, fibonacci } from "@/lib/scale";

export function RatioTable() {
  const f = fibonacci(13);
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <caption>
          The ratio is computed here. phi = {PHI.toFixed(6)}; the error column is F(n) / F(n-1) minus phi.
        </caption>
        <thead>
          <tr>
            <th>n</th>
            <th>F(n)</th>
            <th>F(n) / F(n-1)</th>
            <th>Error</th>
          </tr>
        </thead>
        <tbody>
          {f.map((v, i) => {
            if (i === 0) return null;
            const r = v / f[i - 1];
            return (
              <tr key={i}>
                <td>{i + 1}</td>
                <td>{v}</td>
                <td>{r.toFixed(6)}</td>
                <td>{(r - PHI >= 0 ? "+" : "") + (r - PHI).toFixed(6)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
