"use client";

import { useState } from "react";
import "./app-ui.css";
import { useElementWidth } from "../docs/viz/use-width";
import { Glyph, type GlyphName } from "./app-icons";
import { F, stop } from "./tokens";

export type NavTab = "home" | "objects" | "forecast" | "settings";

const TABS: { id: NavTab; label: string; glyph: GlyphName }[] = [
  { id: "home", label: "Home", glyph: "home" },
  { id: "objects", label: "Objects", glyph: "planet" },
  { id: "forecast", label: "Forecast", glyph: "calendar" },
  { id: "settings", label: "Settings", glyph: "settings" },
];

const BAR_H = F.f89;
const NOTCH_DEPTH = F.f34;
const NOTCH_HALF = F.f55;

/** The bar's outline with the notch cut for the centre action, as the app's NavBarClipper draws it. */
function barPath(w: number): string {
  const c = w / 2;
  return `M0 0 H${c - NOTCH_HALF} C${c - F.f34} 0 ${c - F.f34} ${NOTCH_DEPTH} ${c} ${NOTCH_DEPTH} C${c + F.f34} ${NOTCH_DEPTH} ${c + F.f34} 0 ${c + NOTCH_HALF} 0 H${w} V${BAR_H} H0 Z`;
}
const notchPath = (w: number): string => {
  const c = w / 2;
  return `M${c - NOTCH_HALF} 0 C${c - F.f34} 0 ${c - F.f34} ${NOTCH_DEPTH} ${c} ${NOTCH_DEPTH} C${c + F.f34} ${NOTCH_DEPTH} ${c + F.f34} 0 ${c + NOTCH_HALF} 0`;
};

/**
 * The app's two navigation bars. "bottom" is the tab bar with a notch for the centre action: four tabs, the active
 * one lit with a glow under its label, and the map action in the notch. "top" is the header: the location pill, the
 * logo, and the date stepper.
 */
export function AppNavBar({
  variant = "bottom",
  active: initial = "home",
  action = true,
}: {
  variant?: "bottom" | "top";
  active?: NavTab;
  /** Show the centre action in the notch (bottom bar). */
  action?: boolean;
}) {
  const [active, setActive] = useState<NavTab>(initial);
  const [ref, w] = useElementWidth<HTMLDivElement>(377);

  if (variant === "top") {
    return (
      <div className="app-ui app-navbar is-top">
        <button type="button" className="app-ui app-button is-glass is-sm">
          <Glyph name="pin" />
          <span className="app-navbar-loc">Current Location</span>
        </button>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img className="app-navbar-logo" src="/astr-icon.png" alt="Astr" />
        <div className="app-navbar-date">
          <button type="button" className="app-ui app-tile is-sm" aria-label="Previous day"><Glyph name="chevron-left" /></button>
          <button type="button" className="app-ui app-button is-glass is-sm">Oct 10</button>
          <button type="button" className="app-ui app-tile is-sm" aria-label="Next day"><Glyph name="chevron-right" /></button>
        </div>
      </div>
    );
  }

  return (
    <div ref={ref} className="app-ui app-navbar is-bottom" style={{ height: BAR_H }}>
      <svg viewBox={`0 0 ${w} ${BAR_H}`} height={BAR_H} aria-hidden="true">
        <defs>
          <linearGradient id="nav-sheen" x1="0" x2="1" y1="0" y2="1">
            <stop offset="0" stopColor={stop("space-grey-50", 5)} />
            <stop offset="1" stopColor={stop("space-grey-50", 8)} />
          </linearGradient>
          <linearGradient id="nav-shine" gradientUnits="userSpaceOnUse" x1="0" x2="0" y1="0" y2={NOTCH_DEPTH}>
            <stop offset="0" stopColor={stop("deep-space-200", 10)} />
            <stop offset="0.5" stopColor={stop("deep-space-200", 1)} />
            <stop offset="1" stopColor={stop("deep-space-200", 10)} />
          </linearGradient>
        </defs>
        <path d={barPath(w)} fill={stop("space-grey-950", 1)} />
        <path d={barPath(w)} fill="url(#nav-sheen)" stroke={stop("space-grey-50", 5)} />
        <path d={notchPath(w)} fill="none" stroke="url(#nav-shine)" strokeWidth={F.f2} strokeLinecap="round" />
      </svg>
      <nav aria-label="Primary" className="app-navbar-items">
        {TABS.slice(0, 2).map((t) => (
          <NavItem key={t.id} tab={t} active={active === t.id} onSelect={setActive} />
        ))}
        <span className="app-navbar-gap" aria-hidden="true" />
        {TABS.slice(2).map((t) => (
          <NavItem key={t.id} tab={t} active={active === t.id} onSelect={setActive} />
        ))}
      </nav>
      {action && (
        <button type="button" className="app-ui app-tile is-round app-navbar-action" aria-label="Sky map">
          <Glyph name="map" />
        </button>
      )}
    </div>
  );
}

function NavItem({ tab, active, onSelect }: { tab: { id: NavTab; label: string; glyph: GlyphName }; active: boolean; onSelect: (t: NavTab) => void }) {
  return (
    <div className="app-navbar-tab" data-active={active || undefined} onClick={() => onSelect(tab.id)}>
      <button type="button" className="app-ui app-tile is-sm" aria-label={tab.label} aria-current={active ? "page" : undefined} aria-pressed={active}>
        <Glyph name={tab.glyph} />
      </button>
      <span className="app-micro" aria-hidden="true">{tab.label}</span>
    </div>
  );
}
