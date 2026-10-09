import { readScaleLines } from "@/lib/scale";
import { CodeBlock } from "../code-block";

/** Renders verbatim declarations from scale.css. Only author-supplied literals are passed in. */
export function ScaleSource({ prefixes }: { prefixes: string[] }) {
  return <CodeBlock code={readScaleLines(prefixes)} filename="scale.css" lang="css" />;
}
