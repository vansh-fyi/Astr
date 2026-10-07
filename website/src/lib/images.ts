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
  /** Where the photograph came from. Omitted until a source is confirmed. */
  credit?: { label: string; url: string };
}

export const BENTO_IMAGES: BentoImage[] = [
  {
    palette: "space-grey",
    file: "milky-way.webp",
    width: 1200,
    height: 1600,
    alt: "The Milky Way in black and white, a dense band of stars and dark dust lanes.",
    credit: {
      label: "Pexels",
      url: "https://images.pexels.com/photos/17954395/pexels-photo-17954395.jpeg",
    },
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
    credit: {
      label: "Pexels",
      url: "https://images.pexels.com/photos/24407823/pexels-photo-24407823.jpeg",
    },
  },
  {
    palette: "aurora-green",
    file: "aurora-green.webp",
    width: 1600,
    height: 1068,
    alt: "Green aurora curtains over snowy mountains and a still fjord in Norway.",
    credit: {
      label: "Pixabay, dkphotography",
      url: "https://pixabay.com/images/download/dkphotography-aurora-8346330_1920.jpg",
    },
  },
  {
    palette: "sodium-airglow",
    file: "airglow-orange.webp",
    width: 1600,
    height: 1065,
    alt: "An orange glow along Earth's horizon seen from the space station, beneath a field of stars.",
    credit: {
      label: "NASA Scientific Visualization Studio, ISS airglow and lightning",
      url: "https://svs.gsfc.nasa.gov/vis/a010000/a012900/a012963/Airglow_lightning_iss_20150914HD.webm",
    },
  },
  {
    palette: "oxygen-airglow",
    file: "airglow-red.webp",
    width: 1600,
    height: 1012,
    alt: "A red airglow band above Earth's limb and the lit cities of the night side.",
    credit: {
      label: "NASA Scientific Visualization Studio, ISS airglow over Bangkok and the Pacific",
      url: "https://svs.gsfc.nasa.gov/vis/a010000/a012900/a012963/Airglow_bangkokpacific_iss_20140130HD.mp4",
    },
  },
];
