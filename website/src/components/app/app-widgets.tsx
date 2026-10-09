import type { ReactNode } from "react";
import "./app-ui.css";
import { AppButton } from "./app-icons";

/** The dark app surface that every widget sits on. */
export function AppStage({ children, column }: { children: ReactNode; column?: boolean }) {
  return <div className={`app-ui app-stage${column ? " is-column" : ""}`}>{children}</div>;
}

/** CloudBar from cloud_bar.dart: label, percentage, and an 8 dp track with the glowing fill. */
export function AppCloudBar({
  value,
  state = "data",
  message,
}: {
  value: number;
  state?: "data" | "loading" | "error";
  message?: string;
}) {
  return (
    <div className="app-ui app-cloudbar" style={{ maxWidth: 313 }}>
      <div className="app-cloudbar-head">
        <span className="app-label-md">Cloud Cover</span>
        {state === "loading" ? (
          <span className="app-spinner" role="status" aria-label="Loading" />
        ) : state === "error" ? (
          <span aria-label="Error" style={{ color: "#ff5252", fontSize: 16 }}>!</span>
        ) : (
          <span className="app-label-md">{Math.round(value)}%</span>
        )}
      </div>
      {state === "error" ? (
        <p className="app-cloudbar-error">{message ?? "Weather unavailable"}</p>
      ) : (
        <div className="app-cloudbar-track">
          <div className="app-cloudbar-fill" style={{ width: `${state === "loading" ? 0 : Math.min(100, Math.max(0, value))}%` }} />
        </div>
      )}
    </div>
  );
}

/** Sky type label as the visibility card words it. */
export const skyLabel = (zone: number): string =>
  zone <= 2 ? "Dark Sky" : zone <= 4 ? "Rural Sky" : zone <= 6 ? "Suburban Sky" : "Urban Sky";

/** Lit bars on the rating row: zone 1 lights five, zone 9 lights one (visibility_mini_card.dart). */
export const activeBars = (zone: number): number => Math.min(5, Math.max(0, 5 - Math.floor((zone - 1) / 2)));

/** VisibilityMiniCard: a 164 by 154 card with the zone pill, sky label, SQM figure and rating bars. */
export function AppVisibilityCard({ zone, mpsas }: { zone: number; mpsas: number }) {
  const bars = activeBars(zone);
  return (
    <div className="app-ui app-card is-mini app-vis">
      <div className="app-vis-head">
        <span className="app-label-sm">VISIBILITY</span>
        <span className="app-zone-pill">Zone {zone}</span>
      </div>
      <span className="app-title app-vis-label">{skyLabel(zone)}</span>
      <span className="app-label-sm">{mpsas.toFixed(2)} MPSAS</span>
      <div className="app-rating">
        {Array.from({ length: 5 }, (_, i) => (
          <i key={i} className={i < bars ? "on" : undefined} />
        ))}
      </div>
    </div>
  );
}

/** The moon artwork and label for a phase angle, with the app's bands (moon_mini_card.dart). */
export function moonPhase(angle: number): { asset: string; label: string } {
  const a = ((angle % 360) + 360) % 360;
  if (a >= 355 || a <= 5) return { asset: "moon_new", label: "New Moon" };
  if (a < 85) return { asset: "moon_waxing_crescent", label: "Waxing Crescent" };
  if (a <= 95) return { asset: "moon_first_quarter", label: "First Quarter" };
  if (a < 175) return { asset: "moon_waxing_gibbous", label: "Waxing Gibbous" };
  if (a <= 185) return { asset: "moon_full", label: "Full Moon" };
  if (a < 265) return { asset: "moon_waning_gibbous", label: "Waning Gibbous" };
  if (a <= 275) return { asset: "moon_last_quarter", label: "Last Quarter" };
  return { asset: "moon_waning_crescent", label: "Waning Crescent" };
}

/** MoonMiniCard: the painted moon, illumination and phase name. */
export function AppMoonCard({ angle }: { angle: number }) {
  const { asset, label } = moonPhase(angle);
  const lit = Math.round(((1 - Math.cos((angle * Math.PI) / 180)) / 2) * 100);
  return (
    <div className="app-ui app-card is-mini">
      <span className="abs app-label-sm" style={{ top: 15, left: 15 }}>MOON</span>
      <span className="abs app-label-sm" style={{ top: 15, right: 15, color: "var(--app-text)" }}>{lit}%</span>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img className="app-moon-img" src={`/app/${asset}.webp`} alt={label} />
      <span className="abs app-label-md" style={{ bottom: 15, left: 0, right: 0, textAlign: "center" }}>{label}</span>
    </div>
  );
}

/** One of the four rise and set cells of the conditions card. */
export function AppTimeCell({ label, time }: { label: string; time?: string }) {
  return (
    <div className="app-cell">
      <span className="micro app-micro">{label}</span>
      <span className="time app-label-md">{time ?? "--:--"}</span>
    </div>
  );
}

/** ConditionsCard: headline, Explore button, cloud bar and the four time cells. */
export function AppConditionsCard({
  title = "Clear Skies",
  subtitle = "Perfect visibility for observation",
  cloud = 12,
  times = { sunrise: "06:12", sunset: "18:47", moonrise: "21:30", moonset: "08:02" },
}: {
  title?: string;
  subtitle?: string;
  cloud?: number;
  times?: { sunrise?: string; sunset?: string; moonrise?: string; moonset?: string };
}) {
  return (
    <div className="app-ui app-card is-conditions">
      <div className="abs" style={{ top: 16, left: 16, right: 16, display: "flex", justifyContent: "space-between" }}>
        <div style={{ width: 180 }}>
          <div className="app-heading">{title}</div>
          <div className="app-label-sm" style={{ marginTop: 4 }}>{subtitle}</div>
        </div>
        <AppButton size="sm">Explore</AppButton>
      </div>
      <div className="abs" style={{ top: 69, left: 16, right: 16 }}>
        <AppCloudBar value={cloud} />
      </div>
      <div className="abs app-cells" style={{ top: 162, left: 16, right: 16 }}>
        <AppTimeCell label="SUNRISE" time={times.sunrise} />
        <AppTimeCell label="SUNSET" time={times.sunset} />
        <AppTimeCell label="MOONRISE" time={times.moonrise} />
        <AppTimeCell label="MOONSET" time={times.moonset} />
      </div>
    </div>
  );
}

export type SkyStateKey = "milkyWayVisible" | "starrySkies" | "planetsVisible" | "fewStars" | "cloudy" | "tooMuchLight";

export const SKY_STATE_ASSETS: Record<SkyStateKey, { image: string; label: string }> = {
  milkyWayVisible: { image: "milky_way", label: "Milky Way visible" },
  starrySkies: { image: "starry_sky", label: "Starry skies" },
  planetsVisible: { image: "planets", label: "Planets visible" },
  fewStars: { image: "few_stars", label: "Few stars" },
  cloudy: { image: "cloudy", label: "Cloudy" },
  tooMuchLight: { image: "excessive_light_pollution", label: "Too much light" },
};

/** SkyStateBackground: the illustrated sky at half opacity under the blue wash, with its state name. */
export function AppSkyState({ state, note }: { state: SkyStateKey; note?: string }) {
  const { image, label } = SKY_STATE_ASSETS[state];
  return (
    <div className="app-ui app-state">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={`/app/${image}.jpg`} alt="" />
      <div>
        <div className="app-heading">{label}</div>
        {note && <div className="app-label-sm" style={{ marginTop: 2 }}>{note}</div>}
      </div>
    </div>
  );
}
