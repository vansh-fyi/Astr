/**
 * Bento images are served from jsDelivr, straight from this repository's
 * website/images folder. NEXT_PUBLIC_ASTR_IMAGE_BASE overrides the base URL,
 * for example to preview the layout before the images are pushed.
 */
export const IMAGE_BASE =
  process.env.NEXT_PUBLIC_ASTR_IMAGE_BASE ??
  "https://cdn.jsdelivr.net/gh/vansh-fyi/Astr@main/website/images";

export interface BentoImage {
  /** Palette id from tokens.ts that the photograph inspired. */
  palette: string;
  file: string;
  width: number;
  height: number;
  alt: string;
}

export const BENTO_IMAGES: BentoImage[] = [
  {
    palette: "space-grey",
    file: "milky-way.webp",
    width: 1200,
    height: 1600,
    alt: "The Milky Way in black and white, a dense band of stars and dark dust lanes.",
  },
  {
    palette: "deep-space",
    file: "campsite.webp",
    width: 900,
    height: 1600,
    alt: "Two glowing tents under a deep blue night sky full of stars.",
  },
  {
    palette: "aurora-pink",
    file: "aurora-pink.webp",
    width: 1065,
    height: 1600,
    alt: "A pink and magenta aurora over a country road and silhouetted trees.",
  },
  {
    palette: "aurora-green",
    file: "aurora-green.webp",
    width: 1600,
    height: 1068,
    alt: "Green aurora curtains over snowy mountains and a still fjord in Norway.",
  },
  {
    palette: "sodium-airglow",
    file: "airglow-orange.webp",
    width: 1600,
    height: 1065,
    alt: "An orange glow along Earth's horizon seen from the space station, beneath a field of stars.",
  },
  {
    palette: "oxygen-airglow",
    file: "airglow-red.webp",
    width: 1600,
    height: 1012,
    alt: "A red airglow band above Earth's limb and the lit cities of the night side.",
  },
];
