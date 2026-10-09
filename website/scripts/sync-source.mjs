#!/usr/bin/env node
// Copies the files listed in content/source/manifest.json from the repository into content/source,
// byte for byte, so the documentation site builds without the rest of the repository.
//   node scripts/sync-source.mjs           copy
//   node scripts/sync-source.mjs --check   fail if a copy differs from its original (skips when the original is absent)
import { copyFileSync, existsSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const REPO = join(ROOT, "..");
const DEST = join(ROOT, "content/source");

export function manifest() {
  return JSON.parse(readFileSync(join(DEST, "manifest.json"), "utf8")).files;
}

/** Returns { missing, differing, checked } without writing anything. */
export function verify() {
  const out = { missing: [], differing: [], checked: 0, skipped: 0 };
  for (const file of manifest()) {
    const copy = join(DEST, file);
    const original = join(REPO, file);
    if (!existsSync(copy)) out.missing.push(file);
    else if (!existsSync(original)) out.skipped++;
    else {
      out.checked++;
      if (Buffer.compare(readFileSync(copy), readFileSync(original)) !== 0) out.differing.push(file);
    }
  }
  return out;
}

function sync() {
  for (const file of manifest()) {
    const original = join(REPO, file);
    if (!existsSync(original)) throw new Error(`manifest lists ${file} but the repository has no such file`);
    mkdirSync(dirname(join(DEST, file)), { recursive: true });
    copyFileSync(original, join(DEST, file));
  }
  console.log(`copied ${manifest().length} files into content/source`);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--check")) {
    const r = verify();
    if (r.missing.length || r.differing.length) {
      console.error(`FAIL: missing ${r.missing.join(", ") || "none"}; differing ${r.differing.join(", ") || "none"}. Run npm run sync.`);
      process.exit(1);
    }
    console.log(`ok   ${r.checked} source copies match the repository (${r.skipped} originals not present)`);
  } else sync();
}
