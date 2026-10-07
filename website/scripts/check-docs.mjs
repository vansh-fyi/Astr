#!/usr/bin/env node
// Verification for the Astr colour-system docs app.
//   node scripts/check-docs.mjs               static checks
//   node scripts/check-docs.mjs --http prod   serve `next start` (needs a build) and check HTTP
//   node scripts/check-docs.mjs --http dev    serve `next dev` and check HTTP
import { execFileSync, spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const GLOBALS = join(ROOT, "src/app/globals.css");
const EXPECTED_SHA =
  "3e3d60003ee84a7bface6a8ff088f03c592c141c875c80eb0b8cd79e2231ae1c";
const PAGES = ["/", "/colour-stops", "/opacity-ladder", "/gradients"];
const LABELS = ["Introduction", "Colour stops", "Opacity ladder", "Gradients"];

function fail(message) {
  console.error(`FAIL: ${message}`);
  process.exit(1);
}
function ok(message) {
  console.log(`ok   ${message}`);
}
function assert(cond, message) {
  if (!cond) fail(message);
}
const count = (haystack, needle) => haystack.split(needle).length - 1;
const squash = (s) => s.replace(/\\,/g, "").replace(/\s+/g, "");

function walk(dir, skip = new Set(["node_modules", ".next"])) {
  const out = [];
  for (const name of readdirSync(dir)) {
    if (skip.has(name)) continue;
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...walk(full, skip));
    else out.push(full);
  }
  return out;
}

// ---------------------------------------------------------------- static ----
function staticChecks() {
  const css = readFileSync(GLOBALS);
  const sha = createHash("sha256").update(css).digest("hex");
  assert(sha === EXPECTED_SHA, `globals.css sha256 is ${sha}`);
  ok("globals.css sha256 matches the recorded original");
  assert(!existsSync(join(ROOT, "globals.css")), "website/globals.css still exists");
  ok("website/globals.css no longer exists");

  try {
    const gone = execFileSync(
      "git",
      ["rev-list", "-n", "1", "HEAD", "--", ":(top)website/globals.css"],
      { cwd: ROOT, encoding: "utf8" },
    ).trim();
    if (gone) {
      const old = execFileSync("git", ["show", `${gone}^:website/globals.css`], {
        cwd: ROOT,
        maxBuffer: 1 << 24,
      });
      assert(Buffer.compare(old, css) === 0, "globals.css differs from the original in git history");
      ok("globals.css is byte-identical to the original in git history");
    }
  } catch {
    console.log("skip original-in-history comparison (not available)");
  }

  const text = css.toString("utf8");
  const colours = (text.match(/^\s*--color-[\w-]+\s*:/gm) ?? []).length;
  assert(colours === 66, `expected 66 --color- declarations, got ${colours}`);
  const mags = (text.match(/^\s*--mag-\d+\s*:/gm) ?? []).length;
  assert(mags === 11, `expected 11 --mag- declarations, got ${mags}`);
  assert((text.match(/@utility /g) ?? []).length === 2, "expected two @utility blocks");
  assert(text.includes("@theme static"), "missing @theme static");
  ok("globals.css: 66 stops, 11 --mag steps, 2 utilities, @theme static");

  for (const name of ["introduction", "colour-stops", "opacity-ladder", "gradients"]) {
    const src = readFileSync(join(ROOT, `content/${name}.mdx`), "utf8");
    assert(src.includes("export const meta"), `${name}.mdx has no meta export`);
    const metaBlock = src.slice(src.indexOf("export const meta"), src.indexOf("};") + 2);
    const ids = [...metaBlock.matchAll(/id:\s*"([^"]+)"/g)].map((m) => m[1]);
    assert(ids.length > 0, `${name}.mdx meta has no sections`);
    for (const id of ids)
      assert(src.includes(`<DocSection id="${id}"`), `${name}.mdx: no <DocSection id="${id}">`);
    assert(count(src, "<CodeTabs>") === 1, `${name}.mdx must have exactly one <CodeTabs>`);
  }
  ok("content/*.mdx: meta, section ids and one CodeTabs each");

  const ladder = squash(readFileSync(join(ROOT, "content/opacity-ladder.mdx"), "utf8"));
  assert(ladder.includes("10^{-0.4n/2}"), "opacity-ladder.mdx lacks 10^{-0.4n/2}");
  const grad = squash(readFileSync(join(ROOT, "content/gradients.mdx"), "utf8"));
  for (const needle of ["0.50572", "96.07995", "1.6364", "k=0.2", "^{-\\beta}", "\\beta=3", "4a"])
    assert(grad.includes(needle), `gradients.mdx lacks ${needle}`);
  const lib = readFileSync(join(ROOT, "src/lib/gradients.ts"), "utf8");
  for (const needle of ["0.50572", "96.07995", "1.6364"])
    assert(lib.includes(needle), `src/lib/gradients.ts lacks ${needle}`);
  ok("formula needles present in MDX and in code");

  const files = walk(ROOT).filter((f) => !f.endsWith("package-lock.json") && !f.endsWith("check-docs.mjs"));
  assert(!files.some((f) => f.endsWith(".dart")), "found a .dart file under website/");
  for (const f of files) {
    const body = readFileSync(f, "utf8");
    assert(!body.includes("package:flutter"), `package:flutter found in ${relative(ROOT, f)}`);
    assert(!/```dart/i.test(body), `dart code fence in ${relative(ROOT, f)}`);
  }
  for (const f of files.filter((f) => /\/(src|content)\//.test(f))) {
    const hit = readFileSync(f, "utf8").match(/sepcare|clinical|infant|pulse/i);
    assert(!hit, `forbidden residue "${hit?.[0]}" in ${relative(ROOT, f)}`);
  }
  ok("no Dart/Flutter code and no sepcare residue");
}

// ------------------------------------------------------------------ http ----
async function waitFor(base, child, log) {
  const deadline = Date.now() + 90_000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) fail(`server exited early (${child.exitCode})\n${log.join("")}`);
    try {
      const res = await fetch(`${base}/`);
      if (res.status === 200) return;
    } catch {
      /* not up yet */
    }
    await new Promise((r) => setTimeout(r, 500));
  }
  fail(`server did not become ready within 90 s\n${log.join("")}`);
}

function checkPage(path, html) {
  const where = `${path}`;
  for (const needle of ["Skip to content", "Tokens / CSS", "Coming soon", "<dialog", "On this page"])
    assert(html.includes(needle), `${where}: missing "${needle}"`);
  for (const bad of ["Application error", "NEXT_NOT_FOUND", "Unhandled Runtime Error", "Minified React error"])
    assert(!html.includes(bad), `${where}: contains "${bad}"`);

  const sidebar = /<aside class="docs-sidebar">([\s\S]*?)<\/aside>/.exec(html)?.[1] ?? "";
  assert(sidebar, `${where}: no sidebar`);
  assert(count(sidebar, "<a ") === 4, `${where}: sidebar must have exactly 4 links`);
  for (const label of LABELS) assert(sidebar.includes(label), `${where}: sidebar lacks ${label}`);
  for (const old of ["Foundations", "Getting started", "Examples", "Components"])
    assert(!sidebar.includes(old), `${where}: sidebar contains old template label ${old}`);

  if (path === "/colour-stops") {
    assert(count(html, 'class="docs-color-chip"') === 66, `${where}: expected 66 chips`);
    assert(html.includes("#a6ee8e"), `${where}: missing #a6ee8e`);
  }
  if (path === "/opacity-ladder") {
    assert(html.includes('class="katex"'), `${where}: no KaTeX output`);
    assert(html.includes("--mag-10"), `${where}: missing --mag-10`);
  }
  if (path === "/gradients") {
    assert(html.includes('class="katex"'), `${where}: no KaTeX output`);
    assert(html.includes("gradient-extinction") && html.includes("gradient-moffat"), `${where}: gradient utilities missing`);
    assert(count(html, "<option") >= 132, `${where}: expected at least 132 options`);
    assert(html.includes("0.50572"), `${where}: Kasten-Young constant missing from TeX`);
  }
  if (path === "/") assert(html.includes('class="docs-swatch-strip"'), `${where}: no palette strip`);
}

function chromeConsoleCheck(url) {
  const chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
  if (!existsSync(chrome)) return false;
  const res = spawnSync(
    chrome,
    ["--headless=new", "--disable-gpu", "--enable-logging=stderr", "--v=0", "--virtual-time-budget=5000", "--dump-dom", url],
    { encoding: "utf8", timeout: 30_000, maxBuffer: 1 << 26 },
  );
  const bad = (res.stderr ?? "")
    .split("\n")
    .filter((l) => /CONSOLE/.test(l) && /error|hydration/i.test(l));
  assert(bad.length === 0, `browser console errors at ${url}:\n${bad.join("\n")}`);
  return true;
}

async function httpChecks(mode) {
  const port = mode === "prod" ? 3107 : 3108;
  const args = mode === "prod" ? ["start", "-p", String(port)] : ["dev", "-p", String(port)];
  if (mode === "prod") assert(existsSync(join(ROOT, ".next/BUILD_ID")), "run `npm run build` before --http prod");
  const base = `http://127.0.0.1:${port}`;
  const log = [];
  const child = spawn(process.execPath, [join(ROOT, "node_modules/next/dist/bin/next"), ...args], {
    cwd: ROOT,
    detached: true,
    env: { ...process.env, NEXT_TELEMETRY_DISABLED: "1", FORCE_COLOR: "0" },
  });
  child.stdout.on("data", (d) => log.push(d.toString()));
  child.stderr.on("data", (d) => log.push(d.toString()));

  let chromeRan = false;
  try {
    await waitFor(base, child, log);
    for (const path of PAGES) {
      const res = await fetch(base + path);
      assert(res.status === 200, `${path}: status ${res.status}`);
      checkPage(path, await res.text());
    }
    const icon = await fetch(`${base}/icon.svg`);
    assert(icon.status === 200, `/icon.svg: status ${icon.status}`);
    ok(`${mode}: four pages return 200 with the expected content, icon.svg is 200`);

    for (const path of PAGES) chromeRan = chromeConsoleCheck(base + path) || chromeRan;
    if (chromeRan) ok(`${mode}: headless Chrome console is clean`);
    else console.log(`skip ${mode}: Chrome not installed, console check skipped`);

    await new Promise((r) => setTimeout(r, 500));
    const noise = /telemetry|attention: next\.js now collects/i;
    const bad = log
      .join("")
      .split("\n")
      .filter((l) => !noise.test(l) && /error|⨯|failed to compile|module not found|hydration/i.test(l));
    assert(bad.length === 0, `${mode} server log has errors:\n${bad.join("\n")}`);
    ok(`${mode}: server log is clean`);
  } finally {
    try {
      process.kill(-child.pid, "SIGTERM");
    } catch {
      /* already gone */
    }
    await new Promise((r) => setTimeout(r, 1500));
    try {
      process.kill(-child.pid, "SIGKILL");
    } catch {
      /* already gone */
    }
  }
}

const args = process.argv.slice(2);
const httpIdx = args.indexOf("--http");
if (httpIdx === -1) {
  staticChecks();
} else {
  const mode = args[httpIdx + 1];
  assert(mode === "prod" || mode === "dev", "usage: --http prod|dev");
  await httpChecks(mode);
}
process.exit(0);
