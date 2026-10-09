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
    links: [{ href: "/components", label: "App components" }],
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
