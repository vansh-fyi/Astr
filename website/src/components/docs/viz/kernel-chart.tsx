import { pythonNumber } from "@/lib/source";
import { AppKernelChart } from "@/components/app/science";

const FILE = "scripts/apply_skyglow.py";

/** Reads the kernel constants from the pipeline source and draws the falloff for the script default and for production. */
export function KernelFalloff() {
  return (
    <AppKernelChart
      fractions={[
        { value: pythonNumber(FILE, "SCATTER_FRACTION"), label: `F = ${pythonNumber(FILE, "SCATTER_FRACTION")} (script default)`, dash: true },
        { value: 0.06, label: "F = 0.06 (production data)", dash: false },
      ]}
      scaleKm={pythonNumber(FILE, "SCATTER_SCALE_KM")}
      refKm={pythonNumber(FILE, "D_REF_KM")}
      power={pythonNumber(FILE, "SCATTER_POWER")}
      maxKm={pythonNumber(FILE, "MAX_RADIUS_KM")}
    />
  );
}
