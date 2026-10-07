import { getPalettes, getStopHex } from "@/lib/tokens";
import { GradientPlaygroundClient } from "./gradient-playground-client";

export function GradientPlayground({ kind }: { kind: "extinction" | "moffat" }) {
  return (
    <GradientPlaygroundClient
      kind={kind}
      palettes={getPalettes()}
      backdrop={getStopHex("deep-space", 950)}
    />
  );
}
