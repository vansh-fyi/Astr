import type { DocMeta } from "@/components/docs/documentation";

/** Reads the named `meta` export from an imported MDX module namespace. */
export function docMeta(mod: unknown): DocMeta {
  const meta = (mod as { meta?: DocMeta } | null)?.meta;
  if (
    !meta ||
    typeof meta.title !== "string" ||
    typeof meta.description !== "string" ||
    !Array.isArray(meta.sections)
  ) {
    throw new Error(
      "MDX module is missing a valid `export const meta = { title, description, sections }`.",
    );
  }
  return meta;
}
