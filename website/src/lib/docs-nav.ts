export const DOCS_GROUPS = [
  {
    name: "Colour system",
    links: [
      { href: "/", label: "Introduction" },
      { href: "/colour-stops", label: "Colour stops" },
      { href: "/opacity-ladder", label: "Opacity ladder" },
      { href: "/gradients", label: "Gradients" },
    ],
  },
  {
    name: "Proportion system",
    links: [
      { href: "/spacing", label: "Spacing" },
      { href: "/typography", label: "Typography" },
      { href: "/layout", label: "Layout and size" },
    ],
  },
  {
    name: "Components",
    links: [{ href: "/components", label: "Overview" }],
  },
  {
    name: "Actions",
    links: [
      { href: "/components/icon-tile", label: "Icon tile" },
      { href: "/components/button", label: "Button" },
    ],
  },
  {
    name: "Indicators",
    links: [{ href: "/components/cloud-bar", label: "Cloud bar" }],
  },
  {
    name: "Cards",
    links: [
      { href: "/components/visibility-card", label: "Visibility card" },
      { href: "/components/moon-card", label: "Moon card" },
      { href: "/components/conditions-card", label: "Conditions card" },
      { href: "/components/sky-state", label: "Sky state background" },
    ],
  },
  {
    name: "Graphs",
    links: [
      { href: "/components/conditions-graph", label: "Conditions graph" },
      { href: "/components/cloud-cover-graph", label: "Cloud cover graph" },
      { href: "/components/object-graph", label: "Object visibility graph" },
    ],
  },
  {
    name: "Sky science",
    links: [
      { href: "/sky-science", label: "Overview" },
      { href: "/zone-scale", label: "Zone scale" },
      { href: "/light-pollution", label: "Light pollution data" },
      { href: "/sky-brightness", label: "Moonlight and sky brightness" },
      { href: "/sky-states", label: "Sky states" },
      { href: "/weather-clouds", label: "Weather and clouds" },
      { href: "/planets-sky", label: "Planets and the sky" },
      { href: "/graphs", label: "Graphs" },
      { href: "/offline", label: "Offline and sync" },
    ],
  },
] as const;

/** Flat list with each link's group, for search. */
export const DOCS_LINKS = DOCS_GROUPS.flatMap((group) =>
  group.links.map((link) => ({ ...link, group: group.name })),
);
