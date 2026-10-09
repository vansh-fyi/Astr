import Image from "next/image";

/** The Astr app icon, rendered from the same source as the iOS/Android launcher icon. */
export function AstrMark({ size = 34 }: { size?: number }) {
  return (
    <Image
      src="/astr-icon.png"
      alt=""
      width={size}
      height={size}
      priority
      className="docs-logo-image"
    />
  );
}

export function Wordmark() {
  return <span>Astr</span>;
}
