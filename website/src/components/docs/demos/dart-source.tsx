import { readFileSync } from "node:fs";
import { join } from "node:path";
import { CodeBlock } from "../code-block";

const FLUTTER_DIR = join(process.cwd(), "content/flutter");

/** Renders a verbatim Dart file from content/flutter. Only author-supplied literals are passed in. */
export function DartSource({ file }: { file: string }) {
  if (!/^[a-z_]+\.dart$/.test(file))
    throw new Error(`DartSource: invalid file name "${file}"`);
  const code = readFileSync(join(FLUTTER_DIR, file), "utf8");
  return <CodeBlock code={code} filename={file} lang="dart" />;
}
