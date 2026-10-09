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
] as const;

/** Flat list with each link's group, for search. */
export const DOCS_LINKS = DOCS_GROUPS.flatMap((group) =>
  group.links.map((link) => ({ ...link, group: group.name })),
);
