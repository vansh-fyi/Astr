/**
 * The moon, drawn from its phase angle (0 degrees new, 180 degrees full, as the app defines it).
 * The lit part is a half disc on the waxing or waning side, and the terminator is an ellipse whose width is
 * |cos(angle)| of the radius: dark over the lit half for a crescent, lit beyond the half for a gibbous moon.
 */
export function MoonPhaseIcon({ angle, size }: { angle: number; size?: number }) {
  const a = ((angle % 360) + 360) % 360;
  const waxing = a < 180;
  const c = Math.cos((a * Math.PI) / 180); // 1 at new, -1 at full
  const rx = 48 * Math.abs(c);
  const crescent = c > 0;
  const half = waxing ? "M50 2 A48 48 0 0 1 50 98 Z" : "M50 2 A48 48 0 0 0 50 98 Z";
  return (
    <svg className="viz-moon" viewBox="0 0 100 100" width={size} height={size} role="img" aria-label={`Moon at phase angle ${Math.round(a)} degrees`}>
      <circle className="viz-moon-dark" cx="50" cy="50" r="48" />
      <path className="viz-moon-lit" d={half} />
      <ellipse className={crescent ? "viz-moon-dark" : "viz-moon-lit"} cx="50" cy="50" rx={rx} ry="48" />
      <circle className="viz-moon-rim" cx="50" cy="50" r="48" />
    </svg>
  );
}

/** The eight phase names and the bands of phase angle that the app uses for each. */
const PHASES: { name: string; centre: number; band: string }[] = [
  { name: "New Moon", centre: 0, band: "355° to 5°" },
  { name: "Waxing Crescent", centre: 45, band: "5° to 85°" },
  { name: "First Quarter", centre: 90, band: "85° to 95°" },
  { name: "Waxing Gibbous", centre: 135, band: "95° to 175°" },
  { name: "Full Moon", centre: 180, band: "175° to 185°" },
  { name: "Waning Gibbous", centre: 225, band: "185° to 265°" },
  { name: "Last Quarter", centre: 270, band: "265° to 275°" },
  { name: "Waning Crescent", centre: 315, band: "275° to 355°" },
];

/** Eight phases with the angle band that selects each, and the illuminated fraction at the centre of the band. */
export function MoonPhaseStrip() {
  return (
    <figure className="viz-phases">
      <div className="viz-phases-grid">
        {PHASES.map((p) => (
          <div key={p.name} className="viz-phase">
            <MoonPhaseIcon angle={p.centre} />
            <strong>{p.name}</strong>
            <span>{p.band}</span>
            <small>{Math.round(((1 - Math.cos((p.centre * Math.PI) / 180)) / 2) * 100)}% lit at {p.centre}°</small>
          </div>
        ))}
      </div>
      <figcaption className="viz-key">
        The phase angle runs from 0° at new moon to 180° at full moon and on to 360°. The illuminated fraction is
        (1 − cos of the angle) / 2, so it changes slowly near new and full moon and fastest near the quarters.
      </figcaption>
    </figure>
  );
}
