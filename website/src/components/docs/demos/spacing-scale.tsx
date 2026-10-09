import { RADIUS_ROLES, RADII, SPACING, SPACING_ROLES } from "@/lib/scale";

export function SpacingScale() {
  return (
    <div className="docs-table-wrap">
      <table className="docs-table">
        <thead>
          <tr>
            <th>Token</th>
            <th>px</th>
            <th>rem</th>
            <th>Step</th>
            <th>Typical use</th>
          </tr>
        </thead>
        <tbody>
          {SPACING.map((px) => (
            <tr key={px}>
              <td>
                <code>--spacing-f{px}</code>
              </td>
              <td>{px}</td>
              <td>{px / 16}</td>
              <td>
                <span className="docs-bar" style={{ width: `var(--spacing-f${px})` }} />
              </td>
              <td>{SPACING_ROLES[px]}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function RadiusScale() {
  return (
    <div className="docs-radii">
      {RADII.map((px) => (
        <figure key={px}>
          <span style={{ borderRadius: `var(--radius-f${px})` }} />
          <figcaption>
            <strong>f{px}</strong>
            <small>{RADIUS_ROLES[px]}</small>
          </figcaption>
        </figure>
      ))}
      <figure>
        <span style={{ borderRadius: "var(--radius-full)" }} />
        <figcaption>
          <strong>full</strong>
          <small>Pills, chips, segmented controls</small>
        </figcaption>
      </figure>
    </div>
  );
}
