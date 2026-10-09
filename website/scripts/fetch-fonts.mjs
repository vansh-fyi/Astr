#!/usr/bin/env node
// Downloads the Satoshi typeface from Fontshare, the source its licence allows, instead of keeping the
// font files in the repository. The ITF Free Font License allows free use but forbids redistributing the
// files, so they are git-ignored and fetched on demand.
//   node scripts/fetch-fonts.mjs               fetch the website fonts (src/fonts)
//   node scripts/fetch-fonts.mjs --app         also fetch the Flutter app fonts (../assets/fonts)
//   node scripts/fetch-fonts.mjs --if-missing  do nothing when every wanted file already exists
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync, copyFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const APP_FONTS = join(ROOT, "..", "assets", "fonts");
const ZIP_URL = "https://api.fontshare.com/v2/fonts/download/satoshi";
const INSIDE = "Satoshi_Complete/Fonts/WEB/fonts";

const args = new Set(process.argv.slice(2));
const targets = [
  ...["Medium", "Bold"].map((w) => ({ weight: w, dir: join(ROOT, "src", "fonts") })),
  ...(args.has("--app") ? ["Light", "Regular", "Medium", "Bold"].map((w) => ({ weight: w, dir: APP_FONTS })) : []),
];
const path = (t) => join(t.dir, `Satoshi-${t.weight}.ttf`);

if (args.has("--if-missing") && targets.every((t) => existsSync(path(t)))) process.exit(0);

const work = mkdtempSync(join(tmpdir(), "satoshi-"));
try {
  console.log("Fetching Satoshi from Fontshare (ITF Free Font License: free to use, do not redistribute the files)...");
  const res = await fetch(ZIP_URL);
  if (!res.ok) throw new Error(`Fontshare answered ${res.status}`);
  const zip = join(work, "satoshi.zip");
  writeFileSync(zip, Buffer.from(await res.arrayBuffer()));
  const weights = [...new Set(targets.map((t) => t.weight))];
  execFileSync("unzip", ["-q", "-j", "-o", zip, ...weights.map((w) => `${INSIDE}/Satoshi-${w}.ttf`), "-d", work]);
  for (const t of targets) {
    mkdirSync(t.dir, { recursive: true });
    copyFileSync(join(work, `Satoshi-${t.weight}.ttf`), path(t));
  }
  console.log(`Wrote ${targets.length} font files.`);
} catch (err) {
  console.error(`Could not fetch Satoshi: ${err.message}\nDownload it from https://www.fontshare.com/fonts/satoshi and place Satoshi-Medium.ttf and Satoshi-Bold.ttf in website/src/fonts.`);
  process.exit(1);
} finally {
  rmSync(work, { recursive: true, force: true });
}
