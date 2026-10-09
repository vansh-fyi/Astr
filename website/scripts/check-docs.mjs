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
import { verify as verifySource } from "./sync-source.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const GLOBALS = join(ROOT, "src/app/globals.css");
const SCALE = join(ROOT, "src/app/scale.css");
const EXPECTED_SHA =
  "3e3d60003ee84a7bface6a8ff088f03c592c141c875c80eb0b8cd79e2231ae1c";
const PAGES = ["/", "/colour-stops", "/opacity-ladder", "/gradients", "/spacing", "/typography", "/layout", "/components", "/components/icon-tile", "/components/button", "/components/cloud-bar", "/components/visibility-card", "/components/moon-card", "/components/conditions-card", "/components/sky-state", "/components/conditions-graph", "/components/cloud-cover-graph", "/components/object-graph", "/sky-science", "/zone-scale", "/light-pollution", "/sky-brightness", "/sky-states", "/weather-clouds", "/planets-sky", "/graphs", "/offline"];
const LABELS = ["Introduction", "Colour stops", "Opacity ladder", "Gradients", "Spacing", "Typography", "Layout and size", "Overview", "Icon tile", "Button", "Cloud bar", "Visibility card", "Moon card", "Conditions card", "Sky state background", "Conditions graph", "Cloud cover graph", "Object visibility graph", "Overview", "Zone scale", "Light pollution data", "Moonlight and sky brightness", "Sky states", "Weather and clouds", "Planets and the sky", "Graphs", "Offline and sync"];
const PHI = (1 + Math.sqrt(5)) / 2;

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

// ----------------------------------------------------------------- scale ----
const remPx = (v) => {
  const m = /^calc\(var\(--u\) \* (-?[\d.]+)\)$/.exec(v);
  return parseFloat(m ? m[1] : v) * 16;
};
const near = (a, b, eps) => Math.abs(a - b) <= eps;

function scaleChecks() {
  const raw = readFileSync(SCALE, "utf8");
  const text = raw.replace(/\/\*[\s\S]*?\*\//g, "");
  assert(!/--color-|--mag-|#[0-9a-f]{3,8}\b|rgba?\(|hsla?\(/i.test(text), "scale.css must not define or use a colour");
  const tok = new Map();
  for (const m of text.matchAll(/^\s*(--[\w-]+)\s*:\s*([^;]+);/gm)) tok.set(m[1], m[2].trim());

  const fib = [1, 1];
  while (fib.length < 20) fib.push(fib.at(-1) + fib.at(-2));
  const isFib = (n) => fib.includes(n);
  const px = (name) => {
    assert(tok.has(name), `scale.css lacks ${name}`);
    return remPx(tok.get(name));
  };
  const group = (prefix) => [...tok.keys()].filter((k) => k.startsWith(prefix) && /^\d+$/.test(k.slice(prefix.length)));
  for (const prefix of ["--spacing-f", "--radius-f", "--container-f", "--breakpoint-f"]) {
    const keys = group(prefix);
    assert(keys.length > 0, `scale.css has no ${prefix}* tokens`);
    for (const k of keys) {
      const n = Number(k.slice(prefix.length));
      assert(isFib(n), `${k} is not a Fibonacci number`);
      assert(px(k) === n, `${k} is ${tok.get(k)}, expected ${n}px`);
    }
  }
  assert(group("--spacing-f").length === 11, "expected 11 spacing steps");
  assert(near(Number(tok.get("--phi")), PHI, 0.0005), "--phi is not the golden ratio");
  assert(near(Number(tok.get("--phi-inverse")), 1 / PHI, 0.0005), "--phi-inverse is wrong");
  assert(near(Number(tok.get("--phi-inverse-squared")), 1 / PHI ** 2, 0.0005), "--phi-inverse-squared is wrong");
  assert(near(1.618, PHI, 0.0005) && tok.get("--aspect-golden") === "1.618 / 1", "--aspect-golden is not phi to 1");
  for (let n = -2; n <= 6; n++) {
    const k = `--text-s${n}`;
    const size = Math.round(16 * PHI ** (n / 2));
    assert(px(k) === size, `${k} is ${tok.get(k)}, expected ${size}px`);
    const lh = 1 + PHI ** -(1 + n / 2);
    assert(near(Number(tok.get(`${k}--line-height`)), lh, 0.0005), `${k}--line-height drifted from ${lh.toFixed(3)}`);
    const tr = -(PHI ** (n / 2) - 1) / 89;
    assert(near(parseFloat(tok.get(`${k}--letter-spacing`)), tr, 0.00005), `${k}--letter-spacing drifted from ${tr.toFixed(4)}`);
  }
  assert(tok.get("--u") === "1rem", "--u must be 1rem, the 16 px unit on every screen");
  assert(tok.get("--measure") === "76ch", "--measure must be 76ch");
  for (const k of [...tok.keys()].filter((k) => /^--(spacing|text|radius|container)-/.test(k) && !k.includes("--line-height") && !k.includes("--letter-spacing") && k !== "--radius-full"))
    assert(/^calc\(var\(--u\) \* [\d.]+\)$/.test(tok.get(k)), `${k} must be a multiple of --u`);

  // The shell shares its panes by Fibonacci proportions and is the size container.
  const css = readFileSync(join(ROOT, "src/components/docs/docs.css"), "utf8");
  assert(/container-type:\s*inline-size/.test(css), "docs.css: .docs-root must be a size container");
  assert(css.includes("minmax(0, 233fr) minmax(0, 754fr)"), "docs.css: workspace must split 233 : 754 (sidebar : article + outline)");
  assert(css.includes("minmax(0, 610fr) minmax(0, 144fr)"), "docs.css: page must split 610 : 144 (article : outline)");
  assert(233 + 610 + 144 === 987 && 610 + 144 === 754, "pane proportions are not 233 / 610 / 144");
  assert(!/max-width:\s*var\(--(breakpoint|container)-f1597\)/.test(css), "docs.css: the layout must not be capped in pixels");
  // 233 + 377 = 610 keeps the panes golden.
  assert(px("--container-f233") + px("--container-f377") === px("--container-f610"), "panes are not consecutive Fibonacci widths");

  // Dart mirrors must agree with the stylesheet value for value.
  const dart = (f) => readFileSync(join(ROOT, "content/flutter", f), "utf8");
  const consts = (src, cls) => {
    const body = new RegExp(`abstract final class ${cls} \\{([\\s\\S]*?)\\n\\}`).exec(src)?.[1] ?? "";
    return new Map([...body.matchAll(/static const double (\w+) = (-?[\d.]+);/g)].map((m) => [m[1], Number(m[2])]));
  };
  const sp = dart("astr_spacing.dart");
  const space = consts(sp, "AstrSpace");
  for (const k of group("--spacing-f")) assert(space.get(k.slice(10)) === px(k), `AstrSpace.${k.slice(10)} drifted from ${k}`);
  const rad = consts(sp, "AstrRadius");
  for (const k of group("--radius-f")) assert(rad.get(k.slice(9)) === px(k), `AstrRadius.${k.slice(9)} drifted from ${k}`);
  const ty = dart("astr_type.dart");
  const tcs = consts(ty, "AstrType");
  const list = (name) => (new RegExp(`${name} = <double>\\[([^\\]]*)\\]`).exec(ty)?.[1] ?? "").split(",").map((v) => v.replace(/\/\/.*/g, "").trim()).filter(Boolean).map(Number);
  const leadList = list("leading");
  const trackList = list("tracking");
  assert(leadList.length === 9 && trackList.length === 9, "astr_type.dart needs nine leading and tracking values");
  for (let n = -2; n <= 6; n++) {
    const k = `--text-s${n}`;
    const name = n < 0 ? `sNeg${-n}` : `s${n}`;
    assert(tcs.get(name) === px(k), `AstrType.${name} drifted from ${k}`);
    assert(leadList[n + 2] === Number(tok.get(`${k}--line-height`)), `AstrType.leading[${n + 2}] drifted from ${k}--line-height`);
    assert(trackList[n + 2] === parseFloat(tok.get(`${k}--letter-spacing`)), `AstrType.tracking[${n + 2}] drifted from ${k}--letter-spacing`);
  }
  const lay = consts(dart("astr_layout.dart"), "AstrLayout");
  for (const [name, token] of [["w233", "--container-f233"], ["w377", "--container-f377"], ["w610", "--container-f610"], ["w987", "--container-f987"], ["bp377", "--breakpoint-f377"], ["bp610", "--breakpoint-f610"], ["bp987", "--breakpoint-f987"], ["bp1597", "--breakpoint-f1597"]])
    assert(lay.get(name) === px(token), `AstrLayout.${name} drifted from ${token}`);
  assert(lay.get("major") === Number(tok.get("--phi-inverse")) && lay.get("minor") === Number(tok.get("--phi-inverse-squared")) && lay.get("goldenAspect") === 1.618, "AstrLayout golden constants drifted");
  const size = consts(dart("astr_layout.dart"), "AstrSize");
  for (const [name, v] of size) assert(isFib(v), `AstrSize.${name} = ${v} is not a Fibonacci number`);

  // The shell stylesheet may not carry raw pixel sizes: everything is on the scale.
  const shell = readFileSync(join(ROOT, "src/components/docs/docs.css"), "utf8").replace(/\/\*[\s\S]*?\*\//g, "");
  const rawPx = shell
    .split("\n")
    .filter((l) => !/^\s*@(media|container)/.test(l) && /(?<![\w.-])-?\d*\.?\d+px\b/.test(l));
  assert(rawPx.length === 0, `docs.css has raw pixel sizes (use the scale tokens):\n${rawPx.join("\n")}`);
  ok("docs.css: no raw pixel sizes outside media and container queries");
  ok("scale.css: Fibonacci spacing, radii, widths and breakpoints, phi-derived type, no colour; Dart mirrors match");
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

  scaleChecks();

  for (const name of ["introduction", "colour-stops", "opacity-ladder", "gradients", "spacing", "typography", "layout", "components", "sky-science", "zone-scale", "light-pollution", "sky-brightness", "sky-states", "weather-clouds", "planets-sky", "graphs", "offline"]) {
    const src = readFileSync(join(ROOT, `content/${name}.mdx`), "utf8");
    assert(src.includes("export const meta"), `${name}.mdx has no meta export`);
    const metaBlock = src.slice(src.indexOf("export const meta"), src.indexOf("};") + 2);
    const ids = [...metaBlock.matchAll(/id:\s*"([^"]+)"/g)].map((m) => m[1]);
    assert(ids.length > 0, `${name}.mdx meta has no sections`);
    for (const id of ids)
      assert(src.includes(`<DocSection id="${id}"`), `${name}.mdx: no <DocSection id="${id}">`);
    assert(count(src, "<CodeTabs") === 1, `${name}.mdx must have exactly one <CodeTabs>`);
    assert(src.includes("flutter={") || src.includes("second={"), `${name}.mdx <CodeTabs> has no second panel`);
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
  const dartFiles = files.filter((f) => f.endsWith(".dart"));
  assert(
    dartFiles.every((f) => f.includes(`${join(ROOT, "content", "flutter")}/`) || f.includes(`${join(ROOT, "content", "source")}/`)),
    "a .dart file lives outside website/content/flutter and website/content/source",
  );
  for (const name of ["astr_colors.dart", "astr_opacity.dart", "astr_gradients.dart", "astr_spacing.dart", "astr_type.dart", "astr_layout.dart"])
    assert(
      dartFiles.some((f) => f.endsWith(`/${name}`)),
      `content/flutter/${name} is missing`,
    );
  // Source copies must match the repository, so the code shown on the pages cannot drift.
  const src = verifySource();
  assert(src.missing.length === 0, `content/source is missing ${src.missing.join(", ")}. Run npm run sync.`);
  assert(src.differing.length === 0, `content/source differs from the repository: ${src.differing.join(", ")}. Run npm run sync.`);
  // Satoshi may not be redistributed (ITF Free Font License), so no font file may be tracked by git.
  try {
    const tracked = execFileSync("git", ["ls-files", "-z", ":(top)assets/fonts", ":(top)website/src/fonts"], { cwd: ROOT, encoding: "utf8" })
      .split("\0")
      .filter((f) => /satoshi/i.test(f));
    assert(tracked.length === 0, `Satoshi font files are tracked by git (the licence forbids redistribution): ${tracked.join(", ")}`);
    ok("no Satoshi font files are tracked by git");
  } catch (err) {
    if (err?.status === undefined) throw err;
    console.log("skip tracked-font check (git not available)");
  }
  ok(`${src.checked} source copies match the repository (${src.skipped} originals not present)`);

  const impact = JSON.parse(readFileSync(join(ROOT, "content/data/zone-impact.json"), "utf8"));
  const cells = impact.matrix.flat().reduce((a, b) => a + b, 0);
  assert(cells === impact.records && impact.records === 37528537, "zone-impact.json does not sum to 37,528,537 records");
  const unchanged = impact.matrix.reduce((n, row, i) => n + row[i], 0);
  assert(Math.abs((impact.records - unchanged) / impact.records - 0.1363) < 0.0005, "zone-impact.json: the share of cells that change zone drifted from 13.6%");
  const valid = JSON.parse(readFileSync(join(ROOT, "content/data/validation-25.json"), "utf8"));
  assert(valid.rows.length === 25 && valid.rows.filter((r) => r.expected === r.got).length === 22, "validation-25.json must be 25 rows with 22 matches");
  ok("content/data: zone impact sums to its record count, validation set is 25 places with 22 matches");

  const skyVec = JSON.parse(readFileSync(join(ROOT, "content/source/test/fixtures/astr_sky_model.vectors.json"), "utf8"));
  assert(skyVec.anchor.v === 19.855, "the moonlight anchor value must be 19.855");
  const zoneVec = JSON.parse(readFileSync(join(ROOT, "content/source/test/fixtures/astr_zone_scale.vectors.json"), "utf8"));
  assert(JSON.stringify(zoneVec.edges) === JSON.stringify([0.32, 0.64, 1.28, 2.56, 5.12, 10.24, 20.48, 40.96]), "zone vector edges are not the doubling ladder from 0.32");
  const pyConst = (name) => Number(new RegExp(`^${name}\\s*=\\s*([\\d.]+)`, "m").exec(readFileSync(join(ROOT, "content/source/scripts/apply_skyglow.py"), "utf8"))?.[1]);
  assert(pyConst("SCATTER_FRACTION") === 0.12 && pyConst("MAX_RADIUS_KM") === 80, "apply_skyglow.py constants changed: re-check the light-pollution page's prose about the 0.12 default and the 80 km radius");
  ok("vectors: moonlight anchor 19.855, zone ladder edges, skyglow constants the prose depends on");

  for (const f of files.filter((f) => /\/(src|content)\//.test(f) && !f.includes("/content/source/"))) {
    const hit = readFileSync(f, "utf8").match(/sepcare|clinical|infant/i);
    assert(!hit, `forbidden residue "${hit?.[0]}" in ${relative(ROOT, f)}`);
  }
  ok("Dart files confined to content/flutter, no sepcare residue");
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
  for (const needle of ["Skip to content", 'role="tablist"', "<dialog", "On this page"])
    assert(html.includes(needle), `${where}: missing "${needle}"`);
  for (const bad of ["Application error", "NEXT_NOT_FOUND", "Unhandled Runtime Error", "Minified React error"])
    assert(!html.includes(bad), `${where}: contains "${bad}"`);

  const sidebar = /<aside class="docs-sidebar">([\s\S]*?)<\/aside>/.exec(html)?.[1] ?? "";
  assert(sidebar, `${where}: no sidebar`);
  assert(count(sidebar, "<a ") === 1 + LABELS.length, `${where}: sidebar must have the brand link plus ${LABELS.length} page links`);
  assert(!html.includes('class="docs-header'), `${where}: top bar (docs-header) must not exist`);
  assert(html.includes("astr-icon"), `${where}: Astr app icon missing`);
  for (const label of LABELS) assert(sidebar.includes(label), `${where}: sidebar lacks ${label}`);
  for (const old of ["Foundations", "Getting started", "Examples"])
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
  if (path === "/spacing") {
    assert(html.includes('class="katex"'), `${where}: no KaTeX output`);
    assert(html.includes("docs-spiral-curve"), `${where}: spiral missing`);
    assert(count(html, "--spacing-f") >= 11, `${where}: spacing tokens missing`);
  }
  if (path === "/typography") {
    assert(html.includes('class="katex"'), `${where}: no KaTeX output`);
    assert(count(html, 'class="docs-typerow"') === 9, `${where}: expected nine type rows`);
  }
  if (path === "/layout") {
    assert(html.includes('class="katex"'), `${where}: no KaTeX output`);
    assert(html.includes("docs-panes"), `${where}: pane diagram missing`);
  }
  if (path === "/zone-scale") {
    assert(html.includes("docs-vectorstatus"), `${where}: vector status line missing`);
    assert(html.includes("40.96") && html.includes("docs-readoutgrid"), `${where}: ladder table or calculator missing`);
    assert(html.includes("astr_zone.py"), `${where}: the Python source is not shown`);
  }
  if (path === "/light-pollution") {
    assert(html.includes("create_scatter_kernel") && html.includes("handleZoneLookup"), `${where}: source excerpts missing`);
    assert(count(html, "<tr>") >= 40, `${where}: tables look empty`);
  }
  if (path === "/sky-brightness") {
    assert(html.includes("19.855"), `${where}: anchor value missing`);
    assert(html.includes("moon_brightness_v"), `${where}: Python source excerpt missing`);
  }
  if (path === "/sky-states") {
    assert(html.includes("docs-readoutgrid") && html.includes("best_window"), `${where}: calculator or source excerpt missing`);
  }
  if (path === "/") {
    assert(count(html, 'class="docs-bento-tile"') === 6, `${where}: bento must have six tiles`);
    assert(html.includes("cdn.jsdelivr.net") || process.env.NEXT_PUBLIC_ASTR_IMAGE_BASE, `${where}: bento images are not served from jsDelivr`);
  }
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
    const icon = await fetch(`${base}/icon.png`);
    assert(icon.status === 200, `/icon.png: status ${icon.status}`);
    ok(`${mode}: all pages return 200 with the expected content, icon.png is 200`);

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
