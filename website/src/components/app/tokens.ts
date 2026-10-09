/**
 * The design-system tokens, as the app components use them. Colour is always a stop from globals.css at a
 * --mag-* opacity step; sizes are the Fibonacci numbers of scale.css; type is the phi steps. SVG user units are
 * pixels, so the numbers below are the same Fibonacci and type-step values the CSS tokens resolve to.
 */

export type StopName =
  | "space-grey-50" | "space-grey-300" | "space-grey-500" | "space-grey-950"
  | "deep-space-50" | "deep-space-200" | "deep-space-300"
  | "aurora-green-400" | "aurora-pink-400" | "sodium-airglow-400" | "oxygen-airglow-400";

/** A colour stop, optionally at a --mag-* opacity step (1 is 63%, 5 is 10%, 10 is 1%). */
export const stop = (name: StopName, mag = 0): string =>
  mag === 0 ? `var(--color-${name})` : `color-mix(in srgb, var(--color-${name}) var(--mag-${mag}), transparent)`;

/** Fibonacci spacing, size and radius values in pixels (SVG user units). */
export const F = { f1: 1, f2: 2, f3: 3, f5: 5, f8: 8, f13: 13, f21: 21, f34: 34, f55: 55, f89: 89, f144: 144 } as const;

/** Type steps in pixels: s-2 10, s-1 13, s0 16, s1 20. */
export const T = { s2n: 10, s1n: 13, s0: 16, s1: 20 } as const;

/** Colours of the graph layers, by what they mean. */
export const GRAPH = {
  ink: "space-grey-50",
  cloud: "space-grey-50",
  moon: "deep-space-300",
  moonLine: "deep-space-200",
  rise: "aurora-pink-400",
  now: "sodium-airglow-400",
  prime: "aurora-green-400",
} as const satisfies Record<string, StopName>;

/** The accent tones, named by the colour they are: the system's own colour names. */
export type Tone = "deep-space" | "aurora-green" | "aurora-pink" | "sodium-airglow" | "oxygen-airglow";

/** The stop each tone uses. */
export const TONE_STOP: Record<Tone, StopName> = {
  "deep-space": "deep-space-200",
  "aurora-green": "aurora-green-400",
  "aurora-pink": "aurora-pink-400",
  "sodium-airglow": "sodium-airglow-400",
  "oxygen-airglow": "oxygen-airglow-400",
};

export const TONE_LABEL: Record<Tone, string> = {
  "deep-space": "Deep space",
  "aurora-green": "Aurora green",
  "aurora-pink": "Aurora pink",
  "sodium-airglow": "Sodium airglow",
  "oxygen-airglow": "Oxygen airglow",
};

/** The Dart enum member for a tone: `aurora-pink` is `AstrTone.auroraPink`. */
export const dartTone = (tone: Tone): string => tone.replace(/-(\w)/g, (_, c: string) => c.toUpperCase());
