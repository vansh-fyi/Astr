import { getMagSteps, getPalettes, getStopHex } from "@/lib/tokens";
import { OpacityDemoClient } from "./opacity-demo-client";

export function OpacityDemo() {
  return (
    <OpacityDemoClient
      palettes={getPalettes()}
      mags={getMagSteps()}
      backdrop={getStopHex("deep-space", 950)}
    />
  );
}
