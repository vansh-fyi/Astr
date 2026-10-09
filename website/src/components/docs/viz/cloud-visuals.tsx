import { cloudCells } from "@/lib/viz";

/** The cloud bar from the home screen: a track filled to the percentage, with optional cut marks and their meaning. */
export function CloudBar({
  value,
  cuts = false,
}: {
  value: number;
  /** Mark the 30, 50 and 70 percent cuts that set the sky state. */
  cuts?: boolean;
}) {
  const marks = [
    { at: 30, text: "Milky Way up to here" },
    { at: 50, text: "Starry up to here" },
    { at: 70, text: "Cloudy beyond" },
  ];
  return (
    <figure className="viz-cloudbar">
      <div className="viz-cloudbar-head">
        <span>Cloud cover</span>
        <strong>{value}%</strong>
      </div>
      <div className="viz-cloudbar-track" role="img" aria-label={`Cloud cover ${value} percent`}>
        <div className="viz-cloudbar-fill" style={{ width: `${value}%` }} />
        {cuts &&
          marks.map((m) => (
            <i key={m.at} className="viz-cloudbar-cut" style={{ left: `${m.at}%` }} />
          ))}
      </div>
      {cuts && (
        <div className="viz-cloudbar-marks">
          {marks.map((m) => (
            <span key={m.at} style={{ left: `${m.at}%` }}>
              <b>{m.at}%</b> {m.text}
            </span>
          ))}
        </div>
      )}
    </figure>
  );
}

const W = 36;
const H = 18;

/** A patch of sky covered to a given fraction. The cells are chosen so exactly that share of the sky has cloud. */
export function CloudSky({ percent, seed = 7 }: { percent: number; seed?: number }) {
  const cells = cloudCells(W, H, percent / 100, seed);
  const id = `cloud-blur-${percent}`;
  return (
    <svg className="viz-cloudsky" viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" role="img" aria-label={`${percent} percent of the sky covered`}>
      <defs>
        <filter id={id} x="-10%" y="-10%" width="120%" height="120%">
          <feGaussianBlur stdDeviation="0.45" />
        </filter>
      </defs>
      <g filter={`url(#${id})`}>
        {cells.map((on, i) =>
          on ? <rect key={i} className="viz-cloud" x={i % W} y={Math.floor(i / W)} width="1.02" height="1.02" /> : null,
        )}
      </g>
    </svg>
  );
}

/** Five skies at the cuts the sky state uses, each with the state it allows. */
export function CloudSkyTiles() {
  const tiles = [
    { p: 0, note: "Clear" },
    { p: 30, note: "Milky Way allowed up to here" },
    { p: 50, note: "Starry sky up to here" },
    { p: 70, note: "Anything but Cloudy up to here" },
    { p: 90, note: "Cloudy" },
  ];
  return (
    <figure className="viz-cloudtiles">
      <div className="viz-cloudtiles-grid">
        {tiles.map((t) => (
          <div key={t.p} className="viz-cloudtile">
            <CloudSky percent={t.p} seed={11} />
            <strong>{t.p}%</strong>
            <span>{t.note}</span>
          </div>
        ))}
      </div>
      <figcaption className="viz-key">
        Forecast cloud cover is the share of the sky covered, and exactly that share of each patch is covered here. The
        shapes are illustrative: a forecast does not say which part of the sky is clear.
      </figcaption>
    </figure>
  );
}
