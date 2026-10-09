<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# Astr design system: agent rules

This folder is the documentation site for the Astr design system, and the design system itself. Everything the Astr app will look like is defined here first: colour, proportion, type, components, and the sky science behind the verdicts. The Flutter app is being rebuilt to follow this site, not the other way round.

Read this whole file before you change anything, and follow it exactly. These rules are strict on purpose. A rule that seems to get in the way is a reason to stop and ask the owner, never a reason to work around it.

This file contains no hex colours or code listings on purpose. Authoritative values live in the files named in "Single source of truth". Never copy a value from this file into code: read it from its source.

## The prime rules

These are the rules that cannot be broken. Everything below explains them.

1. **Every colour is one of the sixty-six stops.** At full strength or at one of the eleven `--mag-*` opacity steps. No hex, no `rgb()`, no `Colors.something`, no hand-picked alpha, no new colour for any reason.
2. **Every length is on the scale.** Spacing, sizes and radii are the Fibonacci tokens. There is no pixel number, no rem number and no percentage standing in for a size. If something does not fit, change the structure, or ask. Never add a step.
3. **Every font size is a type step.** Size, leading and tracking come together from one step. No other size exists.
4. **Use the component that exists.** Before drawing a button, a card, a field, a toggle, a tab, a bar or a graph, use the documented component. Never build a second version of one.
5. **Every pressable thing has all its states.** Default, hover, pressed, focus, disabled. Pressed squeezes and glows. Reduced motion is respected.
6. **Cards are plain glass. Glow belongs to buttons, tiles and toggles.** Never put a glow on a card, a panel or a graph.
7. **Never express meaning by hue alone.** The app runs under a red night-vision overlay where every hue collapses to one. Pair colour with a label, a shape, a position or a line form.
8. **Tones are named by the colour they are**: `deep-space`, `aurora-green`, `aurora-pink`, `sodium-airglow`, `oxygen-airglow`. Never blue, green, pink, amber or red.
9. **The code on a page is read from the file that draws the example.** Never paste code into a page, never retype a source file.
10. **The check script is a stop sign.** If `npm run check` fails, fix your change. Never edit the check, a hash, a vector or a stop to make it pass.
11. **Report real results.** A step you did not run is reported as not run. Do not say something works because it built.
12. **Never touch what is not yours.** The owner's root `CLAUDE.md`, a running dev server, and the colour stops are off limits.

## Single source of truth

Each thing is defined in exactly one place. Everything else reads it or mirrors it value for value.

| What | Where it is defined | Who reads it |
| --- | --- | --- |
| The sixty-six colour stops, the eleven opacity steps, the two gradient utilities | `src/app/globals.css` | everything |
| Spacing, radii, container widths, type steps, breakpoints, the golden ratios | `src/app/scale.css` | everything |
| Component roles (the glass material, the shared custom properties, every component rule) | `src/components/app/app-ui.css` | the components, the docs chrome |
| Stops and sizes for run-time code (graphs, SVG) | `src/components/app/tokens.ts` | the TypeScript components |
| The docs shell | `src/components/docs/docs.css` | the shell only |
| Flutter mirror of the above | `content/flutter/astr_*.dart` | the app, the pages |
| Real source shown on the sky science pages | the repository, copied to `content/source` | the pages |

The colour stops are absolute. Never edit, round, reorder, reformat, add or remove a stop, and never change an opacity step, even to fix a visual problem. If a stop looks wrong, tell the owner and stop. The check records a hash of `globals.css` and fails if it changes.

## Colour

- Six palettes: Space Grey, Deep Space, Aurora Pink, Aurora Green, Sodium Airglow, Oxygen Airglow. Each has eleven stops: fifty, one hundred to nine hundred, and nine hundred fifty. Lower is lighter.
- Refer to a colour by palette and stop in prose, such as deep space two hundred. Never by an invented name or a raw value.
- Opacity is the Pogson ladder: eleven steps, half a magnitude each, ten steps make a factor of one hundred. They are the only opacities allowed. In CSS write a stop at a step with `color-mix`; in TypeScript use `stop(name, step)` from `tokens.ts`; in Dart use `AstrColors` with `Mag`.
- Roles. The structure of the site and the app is Space Grey and Deep Space: page ground deep space nine hundred fifty; ink and filled surfaces space grey nine hundred fifty; text from space grey fifty (headings) to three hundred (secondary); the accent for focus, selection and the default tone is deep space two hundred.
- The aurora and airglow palettes are expressive. They appear as component tones (a toggle, a tile, a button), as graph layers (the NOW marker is sodium airglow, prime view aurora green, moon rise aurora pink), and as errors (oxygen airglow). They never decorate the documentation chrome: the sidebar, headings, tables, code blocks and notes stay Space Grey and Deep Space.
- Text contrast must hold after the opacity is composited. Never use the accent for small text.
- The site is dark only. Do not add a light theme.

## Proportion

- One unit, sixteen pixels, on every screen. The scale is derived from nature: spacing, radii, sizes and widths are Fibonacci numbers; type steps are half golden-ratio steps.
- Spacing and sizes: 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144 (tokens `--spacing-f1` to `--spacing-f144`; Dart `AstrSpace`).
- Radii: 3, 5, 8, 13, 21, 34 and the full pill (`--radius-f*`, `--radius-full`; Dart `AstrRadius`).
- Type steps (`--text-s-2` to `--text-s6`; Dart `AstrType`): minus two 10, minus one 13, zero 16, one 20, two 26, three 33, four 42, five 53, six 68. Body is zero. Labels are minus one and minus two. Headings are two steps or more above the text they introduce.
- Control heights: compact controls are drawn at 34 and the default control is 55, which is the touch target. A control drawn smaller than 55 must still have a 55 hit area in the app.
- Sizes are fixed and layout is liquid. Never scale a size with the viewport, never use a viewport unit for a size. Panes are Fibonacci fractions of the free width and reading text is capped in characters.
- A compound size built from tokens is fine (a mini card is 144 wide and 144 plus 21 tall; a tile radius is its edge times the golden minor). A literal is never fine.
- Never write a size that is not on the scale. When a design asks for one (a Figma value of 12, 15 or 28), use the nearest step and say so in the commit message. The conversion cheat sheet below is the default.

| Old value | Use | Old value | Use |
| --- | --- | --- | --- |
| 1 | `f1` | 16 | `f13` (or `f21` for roomy) |
| 2 | `f2` | 20, 24 | `f21` |
| 4 | `f3` for hairline gaps, `f5` for padding | 28 to 40 | `f34` |
| 6 | `f5` | 44 | `f34` drawn, `f55` tapped |
| 8 | `f8` | 48 to 64 | `f55` |
| 10 | `f8` | 72 to 100 | `f89` |
| 12, 15 | `f13` | 120 to 170 | `f144` |

| Old font size | Use | Old font size | Use |
| --- | --- | --- | --- |
| 8, 9, 10, 11 | step minus two | 20 | step one |
| 12, 13, 14 | step minus one | 24 | step two |
| 15, 16 | step zero | 28, 32 | step two or three, by role |
| 18 | step one for emphasis, else zero | 36 to 40 | step three or four |

## Components

The components are documented on their own pages under `/components`. They are the only way to build an interface.

| Component | Web | Flutter |
| --- | --- | --- |
| Icon tile | `AppIconTile` | `AstrGlassTile` |
| Button | `AppButton` (filled, glass, outline; medium and small) | `AstrGlassButton` |
| Toggle | `AppToggle` | `AstrGlassToggle` |
| Text field | `AppTextField` | `AstrGlassTextField` |
| Card surface | `.app-card` material | `AstrGlassCard` |
| Cloud bar, visibility card, moon card, conditions card, sky state background | `app-widgets.tsx` | the app widgets, until migrated |
| Nav bar (bottom and top) | `AppNavBar` | the app's `ScaffoldWithNavBar` |
| Conditions graph, cloud cover graph, object visibility graph | `app-graphs.tsx`, `app-object-graph.tsx` | the app's graph painters |
| Science charts | `science.tsx` | none |

Rules for using them:

- **Reuse first.** If a component fits, use it. If it almost fits, extend it with a variant or a prop. Only when nothing fits, build a new one.
- **Material.** The glass card is a sheen over the ink fill, a hairline edge in space grey fifty at magnitude five, an inset top highlight, and nothing else. A button, tile or toggle adds its tone and its glow. A tile's radius is its edge times the golden minor, which lands on the next Fibonacci radius down.
- **States.** Every pressable component has default, hover, pressed, focus-visible and disabled. Hover lifts and glows. Pressed squeezes to ninety-seven percent and glows (a quiet button glows only while held). Disabled is the magnitude-two opacity. Focus is a two-step outline in the tone. Reduced motion removes the lift and the squeeze, and keeps the glow.
- **Sizes.** Buttons are 55 or 34 tall, tiles are 34, 55 or 89, toggles are 55 by 34 or 34 by 21, fields are 55 or 34 tall. Do not invent another size.
- **Naming.** Web components are `App*`, Flutter components are `Astr*`. A tone is a name from the list in the prime rules.
- **Graphs.** Layers are told apart by form (solid, dashed, dotted, filled) as well as tone. Dots are 3, 5 or 8, strokes 2 or 3, labels 10 or 13. Labels sit in a pill sized to its text with 8 of padding on each side.

### Adding or changing a component

Follow every step. Do not skip any.

1. Write the roles in `app-ui.css` using only tokens. No hex, no `rgb()`, no pixel numbers. Put pressed, hover, focus and disabled in the same change.
2. Write the React in `src/components/app/`, using `tokens.ts` for run-time colour and size. A stop picked at run time must also be listed in `src/app/styles.css`, or Tailwind drops it from the build.
3. Write the Flutter in `content/flutter/astr_glass.dart` (or a new `astr_*.dart`), using only `AstrColors`, `Mag`, `AstrSpace`, `AstrRadius`, `AstrSize`, `AstrType`, `AstrLayout`. Keep it analyser-clean. Give every pressable widget a pressed state.
4. Write the page at `content/components/<name>.mdx`: Preview, Variants (the playground), Implementation (the one `CodeTabs`, React and Flutter), API reference, Design tokens. The Design tokens table has four columns: role, CSS token, Dart token, and what the app uses today.
5. Add the playground in `src/components/app/playground.tsx`, with controls for every variant and code generated for both tabs.
6. Register the component in `src/mdx-components.tsx`, the page route under `src/app/components/<name>/page.tsx`, the sidebar entry in `src/lib/docs-nav.ts`, the page and label lists in `scripts/check-docs.mjs`, and a row in the Components overview.
7. Add the manifest entry for any app file the page quotes, then run the sync script.
8. Run the full verification and look at the page.

The component pages are hand-edited MDX. There is no generator. Edit the file.

## The documentation interface

The site's own interface is built from the same components. Do not style chrome separately.

- Controls are the quiet and outline `app-button` classes: variant chips, the code tabs, Copy, the search trigger, dialog Close, the playground controls. The mobile menu is an `app-tile`. A pressed or selected quiet button fills with its tone.
- Cards (notes, examples, code blocks, tables, the tab strip) use the card material through the `--docs-glass*` variables, which are the `--sheen` and `--fill` of the app card.
- The left sidebar has a fixed head (the brand and the search) and a navigation list under it that scrolls on its own. Group titles are type step zero, links step minus one.
- There is no top bar. There are three panes: sidebar, article, on-this-page outline. The article scrolls without a visible scrollbar. Do not add banners, headers, footers or strips.
- The check fails if chrome gets its own button or card styling, or if the removed first-pass chart components return.

## Flutter

The app is being migrated to this system. When you write or change Flutter:

- Use only `AstrColors`, `Mag`, `AstrSpace`, `AstrRadius`, `AstrSize`, `AstrType`, `AstrLayout`. Never `AppColors`, `AppSpacing`, `AppTypography`, `Colors.something`, `Color(0x...)`, a numeric `EdgeInsets`, a numeric `SizedBox` or a numeric `fontSize`.
- Do not edit the token files in `lib/` without changing the site first. The site's `content/flutter/astr_*.dart` is the source; the app's copy mirrors it byte for byte.
- A widget is migrated when it uses the Astr components and tokens only, has every state, has a widget test, and is documented on its component page. Update that page's "app uses today" column in the same change.
- Run `flutter analyze` and the widget tests for every file you change. Report the results.
- The app edits are separate commits at the repository root, never mixed with website commits.
- Follow `docs/next-steps.md` for the order of work. Do not reorder phases without asking.

## Sky science pages

These pages document logic, not design. They read the application's real code and never retype it.

- Code is copied byte for byte into `content/source` by the sync script, from the list in the manifest. The check fails if a copy differs from its original. After changing a manifest file, run the sync. Add a file to the manifest before quoting it.
- A page shows a whole file or excerpts cut out by symbol name. A symbol that no longer exists fails the build.
- Tables and calculators come from the TypeScript ports in `src/lib`. The build checks the ports against the shared test vectors that the Python and Dart implementations also pass. If they disagree, fix the code or the vectors, never the check.
- The second code tab on these pages is named for the page (for example Python and Dart), not Flutter. Each page has exactly one `CodeTabs` with both panels filled.
- Describe equations with the symbols the equation uses, rendered as math, and give each science page a symbol key (symbol, meaning, unit). Tables never explain a formula with code variable names. Real identifiers (files, JSON keys, functions) stay as code.
- Mark every claim not checked against a primary source as unverified, and every design choice that is not a measurement as a proposal, in the visible text.
- State the facts about today's code plainly, including bad ones. Do not use Bortle terms except to say they are not used.
- The markdown pipeline has no table syntax. Use `DocTable` with arrays. Cells accept math, code, bold and links.
- One-off analysis data lives in `content/data` with its provenance, and the check confirms it adds up.

## Product context

- Astr tells you whether tonight's sky, at a place, is worth going outside for, and why not if it is not. Everything serves that question first. After it come astronomical data and, later, a star map and a very large object corpus.
- The product is free, open source and tip-funded. Code is Apache-2.0, published data packs are CC BY-SA, and no third-party copyleft code ships in the app. Check the licence of any dependency or asset before adding it and record it in `NOTICE`.
- The audience stands outside at night with a phone: dark only, legible when dimmed, working under the red overlay.
- Decisions already made, which you must not reopen: the zone scale is a doubling ladder from thirty-two hundredths of natural brightness; the hero state follows the best window tonight with a separate chip for right now; sizes are fixed at sixteen pixels while layout is liquid; the ephemeris moves to free JPL data; the corpus targets parity with the best planetarium apps plus visibility intelligence per object.
- Six sky states, best to worst: Milky Way visible, Starry sky, Planets visible, Few stars, Cloudy, Too much light. Always show why: the limiting factor is cloud, the moon, light pollution or nothing significant. Zones are one to nine with one vocabulary. Offline and stale are normal states, not errors. Say when there is no astronomical night.
- Units: magnitudes per square arcsecond for sky brightness, magnitude for limiting magnitude, percent for cloud, local time for events. Tone: short, factual, no marketing language, British spelling for colour.

## Typography and brand

- Satoshi for headings, labels in components and the wordmark; Inter for body text in the documentation. No other typeface.
- Satoshi's licence forbids redistributing the font files, so they are never committed to this folder. The fonts script fetches them before the dev server and the build. Never commit a Satoshi file, never substitute another typeface.
- The brand mark is the real Astr app icon. Never draw, recolour or replace it.
- Photographs are optimised webp with a long edge of at most sixteen hundred pixels, served through the single image configuration in `src/lib`. Each has alternative text. The app's own artwork for moon phases and sky states lives in `public/app`.

## Writing pages

- Pages are MDX in `content`. Prose and formulas belong in the MDX, not in components. Every number a page shows should be traceable to a formula on the same page.
- Each page declares its title, description and section list, and each declared section exists. The check verifies this.
- Each page has exactly one `CodeTabs` with two filled panels. Never leave a placeholder tab.
- Use the shared documentation components. Do not build one-off equivalents.

## Workflow

- Start edits through the project's quick-task workflow, as the root instructions require.
- Before coding, read the page or component you are changing, and the check script's rules for it.
- Verification, in this order, every time: `npx tsc --noEmit`, `npm run lint`, `npm run build`, `npm run build:turbo`, `npm run check`, then `npm run check -- --http prod`. For Flutter files also `flutter analyze` and the tests. Report each result. The two builds matter: the dev server uses Turbopack and the build script uses webpack, and a stylesheet can pass one and fail the other.
- After changing a file in the source manifest, run `node scripts/sync-source.mjs`. After changing a specification or reference implementation, run its Python and Dart tests before the site's checks.
- Look at the result. For any visual change, take a screenshot and review it at desktop width and at a narrow width. The headless browser's minimum window width is about five hundred pixels. A new graph or component must be seen, not assumed.
- Stop only servers you started. Do not stop a dev server the owner may be running. Do not run a production build into the output folder while a dev server uses it. If the owner reports a stale CSS error, ask them to stop the server, delete `.next` and restart.

## Pitfalls learned the hard way

- **Never delete CSS blocks with a script without checking brace balance afterwards.** A script that removed rules from a grouped selector left dangling selectors and broke the dev server mid-session. After any stylesheet edit, check that braces balance, then run both builds.
- **Tailwind drops theme variables it cannot see used.** A colour stop chosen at run time must be listed in `styles.css`. The check enforces it.
- **An unlayered rule beats a layered one.** `app-ui.css` is not in a layer and `docs.css` is. A docs rule that tries to override a component loses. Give the wrapper the docs rule instead (this is why the mobile menu is a wrapper around a tile).
- **A zero-width SVG line cannot take a bounding-box gradient or filter.** Draw such lines as thin rects with explicit gradient coordinates.
- **Use `fill: none` on stroke icons** inside components that set a fill on every svg.
- **A general `svg` rule inside a component also hits its icons.** Target direct children when sizing a background svg.
- **macOS `sed -i` needs an empty string argument.** Prefer a short Python edit that asserts the text it replaces exists.
- **The documentation folder at the repository root is git-ignored for new files.** Add a new file there with `git add -f`.
- **Satoshi is fetched, never committed**, and the Flutter app needs the fonts script run with its application flag once.
- **Do not describe a feature as working because a screen exists.** The bundled object catalogue is tiny, and some graphs are mock or unused. Read the sky science pages for real status.

## Git

- Stage explicit paths. Never `git add -A`. Inside this folder work, stage only this folder.
- The root `CLAUDE.md` carries the owner's uncommitted edits. Never stage, revert or edit it. `.planning` is not committed.
- Changes outside this folder (specifications, reference implementations, licence files, the Flutter app) are separate commits at the repository root.
- Write a clear message. Do not commit build output or dependency folders. Push only when the owner asks.

## Never do these

- Never change a colour stop or an opacity step.
- Never write a hex value, an `rgb()` call, a `Colors.*` reference, a raw pixel size or a raw font size in a component, a page or Flutter code.
- Never add a colour, opacity, gradient, size or typeface the system does not define.
- Never name a tone by a hue word.
- Never put a glow on a card, a panel or a graph.
- Never build a second version of an existing component.
- Never ship a pressable component without pressed and focus states.
- Never use aurora or airglow colours in the documentation chrome.
- Never express meaning by hue alone.
- Never paste code onto a page, or edit a source copy by hand.
- Never edit the check, a hash or a test vector to make a failure go away.
- Never commit a Satoshi file.
- Never stage the root `CLAUDE.md`.
