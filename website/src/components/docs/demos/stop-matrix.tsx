import { getMagSteps, getPalettes, getStopHex } from "@/lib/tokens";
import { StopMatrixClient } from "./stop-matrix-client";

export function StopMatrix() {
  return (
    <StopMatrixClient
      palettes={getPalettes()}
      mags={getMagSteps()}
      backdrop={getStopHex("deep-space", 950)}
    />
  );
}
