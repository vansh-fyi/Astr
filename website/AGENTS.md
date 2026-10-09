<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# Astr design system: agent rules

This folder is the documentation site for the Astr design system. It is a Next.js app that will grow into the full design documentation and Flutter reference. Its scope is three systems: colour (the colour stops, the opacity ladder and gradients), proportion (spacing, typography, layout and element sizes) and sky science (how the app measures and decides: the zone scale, light pollution data, sky brightness, sky states, weather, planets, graphs and offline behaviour). Read this file before changing anything here, and follow it exactly.

This file contains no code on purpose. Rules are written in plain language. The authoritative values live in the files named below, never in this document.

## Scope

- Colour, proportion and sky science only. Do not add component documentation or any other new page until the owner asks for it, one at a time. The owner asked for the proportion pages together and for the sky science pages together, which is why they all exist.
- The Flutter application in the repository root is outdated and is used for functionality only. Never read it for design guidance and never edit it from this folder's work. Design rules come from this site, not from the app. The sky science pages are the exception: they document the application's logic, so they read its code, but only through the source copies described below.
- The sepcare project, kept next to this repository, is the reference for the documentation shell's design language. Follow its layout, spacing, sizing and tone closely. Do not copy its colours, its content or anything clinical.

## Single source of truth

- The global stylesheet in the app source folder is the only place colour values are defined. Every page, demo, table and Flutter file reads from it or mirrors it value for value.
- The colour stops are absolute. Never edit, round, reorder, reformat, add or remove a stop, and never change an opacity step value, under any circumstances, even to fix a visual problem. If a stop looks wrong, tell the owner and stop.
- The verification script records a hash of that stylesheet and fails if it changes. Treat a failure there as a stop sign, not as something to update.
- Do not invent colours. Every colour on screen is one of the sixty-six stops, optionally at one opacity step.

## The palettes

- There are six palettes: Space Grey, Deep Space, Aurora Pink, Aurora Green, Sodium Airglow and Oxygen Airglow.
- Each palette has eleven stops numbered fifty, one hundred through nine hundred, and nine hundred fifty. Lower numbers are lighter, higher numbers are darker.
- Refer to a colour by palette name and stop number, such as deep space three hundred. Never describe a colour by an invented name or by its raw value in prose.
- Space Grey and Deep Space are the structural palettes. Aurora and airglow palettes are expressive and belong to the application's own design and components.

## Roles inside the documentation site

- Page background is deep space nine hundred fifty, across the whole site, including the sidebar and the outline.
- Code blocks, notes, inline code and readouts are filled with space grey nine hundred fifty, so they sit as black panels on the deep space page.
- Other raised surfaces, such as the search field, active navigation and preview areas, use Deep Space dark stops.
- Highlight and interaction colour is deep space three hundred. Use it for focus rings, the active tab underline, selected chips and other fills and borders.
- Text and text accents use the Space Grey stops, from brightest for headings to muted for secondary information. Do not use the highlight colour for small text, because its contrast on the dark background is too low.
- Aurora and airglow palettes are kept out of the documentation chrome, code highlighting, status marks, demo defaults and example snippets. They appear only where a page documents the palettes themselves. Do not use them to decorate the site.
- The site is dark only. Do not add a light theme or a theme switch unless asked.

## Opacity ladder

- Opacity follows the Pogson magnitude scale from astronomy. Each step is half a magnitude, and ten steps make exactly a factor of one hundred.
- There are eleven steps, magnitude zero through magnitude ten, and they are the only opacities allowed. Never use an ad hoc percentage, a hand-picked alpha or a round number such as ten or fifty percent.
- Any colour stop may be used at any step. Stops and steps are independent, and there is no pairing rule between them.
- Opacity is applied on top of a stop. It never modifies the stop.
- Platform guidance is respected through the ladder. Text hierarchy and state layers must still meet contrast after compositing, so never carry meaning through opacity alone.

## Gradients

- Gradients are derived from natural laws, not drawn by eye. Today there are two: atmospheric extinction from zenith to horizon, using the Kasten-Young airmass, and the Moffat profile for radial glows.
- Every gradient stop alpha is snapped to the nearest ladder step, and stop positions come from the model, not from taste.
- Gradients take any colour stop through the colour variable and any direction through the direction variable. Use the two existing gradient utilities. Do not hand-write new gradient definitions in pages or components.
- Interpolation is always in sRGB so the web and Flutter render the same.
- A new gradient needs all of the following before it ships: a named natural law, its formula written in the page's markdown, the sampled stops with raw and snapped values in a table, a cross-check against the stylesheet that fails the build on drift, and matching Flutter code. If any of these is missing, do not add it.

## Proportion system

- Proportion is derived from nature, like colour. Spacing, radii, element sizes, pane widths and breakpoints are Fibonacci numbers. Type steps are half golden-ratio steps. The base is sixteen pixels, which is one rem on the web and sixteen dp or sp in Flutter.
- The proportion stylesheet in the app source folder is the only place these values are defined, exactly as the global stylesheet is for colour. It defines no colour and no opacity.
- Sizes are fixed and layout is liquid. Every spacing, radius, type size and element size is a multiple of one unit, sixteen pixels on every screen. Never scale it with the viewport or the container, and never use a viewport unit for a size.
- Panes are shared out as Fibonacci fractions of the free width, never as pixel widths, and reading text is capped by characters, never by a pixel width. Breakpoints are the only absolute widths.
- Never write a pixel size, gap, radius or font size that is not on the scale. If something does not fit, change the structure or tell the owner. Do not add a step.
- Never edit, round or reorder a step. Every value must be reproducible from its formula. The verification script recomputes the formulas and compares the stylesheet and the Dart files value for value, and fails on drift. Treat a failure as a stop sign.
- Type: size, leading and tracking always come together from one step. Body is step zero. Headings are two steps or more above the text they introduce.
- Layout: the reading measure is seventy-six characters. Panes use consecutive Fibonacci proportions. Compact controls are drawn at thirty-four and tapped at fifty-five.
- Media queries cannot read variables, so a breakpoint written in the shell stylesheet is a literal. It must be a Fibonacci breakpoint or a sum of pane widths, and its comment must say which.
- The same page rules apply to the proportion pages: markdown with embedded components, formulas on the page, one code tabs block, and Dart files in the Flutter folder.

## Sky science pages

- These pages document logic, not design. They read the application's real code and never retype it.
- Code is copied byte for byte into the content source folder by the sync script, from the list in the manifest. The verification script fails if a copy differs from its original. After changing a file in the manifest, run the sync script. Add a file to the manifest before using it on a page.
- A page shows either a whole file or excerpts cut out by symbol name. A symbol that no longer exists fails the build, so an excerpt cannot go stale. Never paste code into a page.
- Tables and calculators are computed by the TypeScript ports in the library folder. The build checks those ports against the shared test vectors that the Python and Dart implementations also pass. If they disagree, fix the code or the vectors, never the check.
- The second tab on these pages is named for the page (for example Python and Dart), not Flutter. Each page still has exactly one code tabs block with both panels filled.
- The markdown pipeline has no table syntax. Use the shared table component with arrays.
- Mark every claim that was not checked against a primary source as unverified, and every design choice that is not a measurement as a proposal, in the visible text. Never present a proposal as settled.
- State the facts about today's code plainly, including bad ones (for example the size of the bundled catalogue and what the current sky state ignores).
- Data that comes from a one-off analysis lives in the data folder with its provenance in the file, and the verification script checks it adds up.
- Do not use Bortle terms except to say they are not used.

## Project context for front end work

Read this before designing or building any interface here or in the application.

- Astr tells you whether tonight's sky, at a place, is worth going outside for, and why not if it is not. Everything on screen serves that one question first. After that it offers astronomical data and, later, a star map and a very large object corpus.
- The product is free, open source and tip-funded, with tipping through the stores. The code is licensed under Apache-2.0, published data packs under CC BY-SA, and no third-party copyleft code may ship in the application. Do not add a dependency or an asset without checking its licence, and record it in the repository's notice file.
- The documentation site is the design authority. The application's front end will be redesigned screen by screen from Figma exports, and this site sets the precedent that the redesign follows. The application's old interface code is not a reference for design.
- The next phase on this site is a component system. The owner asks for it one component at a time. Until a component is requested, do not add component pages, and do not invent components.
- The audience stands outside at night with a phone. The interface is dark only, must be legible with the screen dimmed, and must keep working under the red night-vision overlay.
- Decisions already made, which you must not reopen: the zone scale is a doubling ladder that starts at thirty-two hundredths of the natural brightness; the hero state follows the best window tonight with a separate chip for right now; sizes are fixed at sixteen pixels while layout is liquid; the ephemeris moves to free JPL data; the corpus targets parity with the best planetarium apps, plus visibility intelligence per object.

## Design language: glass

The site's look was set in two steps, a glass surface language drawn from the owner's portfolio, then rebuilt on the proportion scale. It is the precedent for every component. Its values live in the shell stylesheet as named custom properties and in the global stylesheet. Reuse those, never copy numbers, and when components arrive promote them to a shared component layer instead of repeating them.

- **Surfaces are frosted glass.** A very faint translucent fill from the lightest space grey stop at magnitude eight, a hairline ring from the same stop at magnitude six, a top sheen at magnitude five, and a backdrop blur with raised saturation. Hover moves the fill to magnitude six and the ring to magnitude four. Code blocks, notes and inputs use a darker block fill from the deepest space grey stop at magnitude one so they stay near black. Raised areas use the dark Deep Space stops.
- **Glass needs something behind it.** Blur on a flat background looks flat. The page has two soft ambient glows built from the Moffat gradient utility, and image areas sit behind glass too. Any component placed on a plain surface must be given a backdrop that varies in brightness, or it will not read as glass.
- **Shape.** Cards and panels use radius step twenty-one, tiles step thirteen, inputs and small controls step eight. Controls that are tapped, chips, tabs and the search field are pills with the fully round radius token. Dialogs use the card radius with heavier blur and a dimmed, blurred backdrop.
- **Interaction.** Hover brightens the fill and the ring as described above. Tiles and swatches lift by spacing step three on hover. Pills shrink slightly when pressed. Transitions run about two hundred milliseconds with an ease-out curve that starts fast, and only transform, opacity and colour animate, never layout. Reduced motion collapses every transition to nothing.
- **Focus and selection** use Deep Space three hundred: a two-step outline for focus and the fill for selected chips and the active tab. It is never used for small text.
- **Text.** Satoshi bold for headings from the second type step up, Inter for everything else. Body is the zero step, labels use the minus-one and minus-two steps. Leading and tracking come with the step.
- **Hit targets.** A control may be drawn at the thirty-four step but its tappable area is at least the fifty-five step, which exceeds both platform minimums.
- **Never express meaning by hue alone.** Under the red overlay every colour collapses to one. Pair colour with a label, a shape, a position or an icon, and keep contrast after compositing.

## Building a component system

- Work one component at a time, when asked. Each gets a documentation page in the proportion or a new components group, written to the page rules above.
- A component page states, in this order: what it is for and the data it shows; anatomy; variants; states, which always include default, hover, pressed, focus, disabled, loading, error, empty, stale and offline where the data can be stale or missing; sizes and spacing as scale steps; colour as a stop and a ladder step per role; the glass level; motion; accessibility including the red overlay; behaviour on narrow and wide screens; and do and do not.
- Define the component's roles in the shared stylesheet before writing the page. A page shows the real tokens, a live example built from them, and the Flutter mirror. If a component needs a value that is not on the scale, change the component, not the scale.
- Mirror each component in Flutter as plain Dart constants plus a small reference widget that depends only on the existing mirror files for colour, opacity, gradients, spacing, radius, type and layout. Keep it analyser-clean and test-verified like the other Dart files, and extend the verification script so it fails if a component uses a raw pixel size or a colour outside the stops.
- Components must handle the real data states described in the next section, because the application's hardest screens are about missing, stale and uncertain data.
- Build components from the glass language, the proportion scale and the ladder only. Aurora and airglow colours belong to the application's own expressive moments, such as sky state art and the six illustrated backgrounds. They never appear in the documentation chrome and they never replace a stop.

## What the interface must express

These facts come from the sky science pages, which are the source of truth. Link to them rather than restating formulas.

- **Six sky states**, best to worst: Milky Way visible, Starry sky, Planets visible, Few stars, Cloudy and Too much light. Each has one illustrated background image. The hero shows the state of the best window tonight. A small chip shows the state right now, and is empty in daylight and twilight. Both come from one function, so they never disagree about method.
- **Say why.** The model returns a limiting factor: cloud, the moon, light pollution or nothing significant. Show it. Never present a bad state without its cause.
- **Zones** are one to nine and never use Bortle words. Show the zone number, the sky brightness in magnitudes per square arcsecond and, where space allows, the limiting magnitude. Use one vocabulary for the same zone across the application. Today three label sets exist for it, and the redesign should replace them with one.
- **Honesty about data.** Mark a zone that is only the dark-sky default, weather that is stale, cloud cover that is a forecast, and seeing that is a proxy index and not a measurement. Offline and stale are normal states, not errors. Say when there is no astronomical night at all.
- **Graphs** share a night-window time axis from sunset to the next sunrise, a Now line, a legend, and a best-window band. The moon layer becomes the moon's cost in magnitudes, and an object's good hours are drawn. Colours in today's graphs come from a default palette that the redesign replaces.
- **Units and wording:** magnitudes per square arcsecond for sky brightness, magnitude for limiting magnitude, percent for cloud, local time for events. Keep the tone short and factual, as on this site.
- **Components today**, which the redesign will replace: the hero label and zone badge, the conditions card with cloud bar and sun and moon times, the visibility and moon cards, the highlights feed, the atmospherics sheet with its graph, tiles and hourly list, the object visibility graph, forecast day rows, the location and search sheets, and the navigation shell. The mock altitude graph and the unused cloud painter are dead and must not be rebuilt.

## Working notes and pitfalls

- The markdown pipeline has no table syntax. Use the shared table component. Links inside its cells are supported.
- The documentation folder at the repository root is git-ignored for new files, although old files in it are tracked. A new file there needs a forced add, or the ignore rule needs to change.
- Satoshi is fetched, never committed. A fresh checkout gets it automatically before the dev server and the build. The Flutter application needs the fonts script run with its application flag once.
- Container query units were tried for a fluid size unit and dropped. Sizes are fixed. Media and container queries cannot read variables, so breakpoints are literals that are Fibonacci numbers or sums of pane widths, and are commented as such.
- A new rule that targets an element already styled by a more specific shared rule will lose. The calculator labels were hit by the example controls' label rule, so match or beat that specificity.
- The development server uses Turbopack and the build script uses webpack. A stylesheet that builds under one can still fail under the other, so run both when changing styles. Do not run a production build into the same output folder while a development server is running, because it can corrupt it. Ask the owner to restart the server if a stale error appears.
- The headless browser used for screenshots has a minimum window width of about five hundred pixels. A narrow screenshot is only as narrow as that.
- Stop only servers you started, and check the ports the verification script uses before and after.
- The bundled object catalogue is tiny today, and some graphs are mock or unused. Do not describe a feature as working because a screen exists. Check the sky science pages for its real status.

## Typography and brand

- Satoshi for headings and the wordmark. Inter for body text. No other typefaces.
- Satoshi's licence forbids redistributing the font files, so they are never committed. They are git-ignored and fetched from Fontshare by the fonts script, which runs automatically before the dev server and the build. Never commit a Satoshi file, and never substitute another typeface for it.
- The brand mark is the real Astr app icon taken from the application's icon source. Never draw, recolour or replace it with a placeholder.

## Images

- Photographs live in the images folder as optimised webp only, with a long edge of at most sixteen hundred pixels. Never commit original PNG or JPEG files.
- Pages load them from the jsDelivr CDN, served from this repository, through the single image configuration in the library folder. Never hard-code another host.
- Each image has meaningful alternative text and is tied to the palette it inspired. Keep that mapping in the configuration, not in pages.
- The introduction shows them as a bento with each palette's eleven stops on the caption. New images must be pushed before the CDN can serve them.

## App components

Each component has its own page under `/components/<name>`, grouped in the sidebar as Actions, Indicators, Cards and Graphs, with the same sections every time: Preview, Implementation, Variants, API reference, Design tokens. Implementation is the page's one `CodeTabs`: React (usage, then the component read from `src/components/app/` with `ReactExcerpt`, then its rules from `app-ui.css` with `CssExcerpt`) and Flutter (usage, then the real widget with `SourceExcerpt`, or `DartExcerpt` for widgets that only exist in `content/flutter/`). Because the code is read from the files that draw the preview, it cannot drift.

The web components are built only from design-system tokens, and `check-docs.mjs` fails the build if that slips. Colour is a stop from `globals.css` at a `--mag-*` opacity step (in CSS with `color-mix`, in code with `stop()` from `tokens.ts`); spacing, sizes and radii are the Fibonacci tokens (`--spacing-f*`, `--radius-f*`, `--container-f*`); type is the phi steps (`--text-s*`). There are no hex values, `rgb()` calls or pixel numbers in `app-ui.css`, and no hex or `rgba()` in the component code. SVG graphs use the same Fibonacci numbers as user units (the `F` and `T` tables in `tokens.ts`). Any stop that code picks at run time must also be listed in `styles.css`, or Tailwind drops it from the build, and the check enforces that too. The tile radius is the golden minor of its edge (0.382), which lands on the next Fibonacci radius down.

The app's own widget Dart (`AppColors`, `AppSpacing`, hex and pixel values) does not use these tokens yet. Each component page ends with a Design tokens table naming the CSS token, the Dart token (`AstrColors`, `Mag`, `AstrSpace`, `AstrType`) and what the app widget uses today, so the gap to close is visible. `content/flutter/astr_glass.dart` is built only from Astr tokens and is the target shape: it holds the proposed tile, button and card. A new component adds its CSS, its React, its Dart tokens and its page. New component pages go in `docs-nav.ts` and the page lists in `scripts/check-docs.mjs`.

The documentation interface is made of these components. Its controls (variant chips, the code tabs, Copy, the search trigger, dialog Close, the playground controls) are the glass and outline `app-button` classes, and the mobile menu is an `app-tile`; a pressed or selected quiet button fills with its tone. The docs cards (notes, examples, code blocks, tables) share the card material through the `--docs-glass*` variables, which are the `--sheen` and `--fill` of the app card. Do not give chrome its own button or card styling: `check-docs.mjs` fails if it comes back. The first-pass chart components are gone; the science pages use `science.tsx` (night strip, moon-cost chart, skyglow kernel chart, zone ladder) and the graph components.

Tones are named by the colour they are, never by a hue word: `deep-space`, `aurora-green`, `aurora-pink`, `sodium-airglow`, `oxygen-airglow` (Dart: `AstrTone.deepSpace` and so on). Do not call a tone blue, pink or amber in props, labels or code.

## Visual components for the science pages

Text-heavy sections are shown with components in `src/components/docs/viz/`. Add new ones there, register them in `src/mdx-components.tsx`, and style them in `docs.css` under the `viz-` prefix.

- Compute from the real model. Visuals call the TypeScript ports of the model functions (the same ports the vector checks hold to the Python and Dart references), or read constants from the copied source, so a visual cannot drift from the spec. Never hard-code a number a script owns.
- Share helpers in `src/lib/viz.ts` (seeded random numbers, chart height of width over φ², scales, noise fields) and example data in `src/lib/viz-data.ts`. Charts size from their container with `use-width.ts`, never from the viewport.
- Use the glass recipe and the 66 stops. Distinguish chart series by form (line, dash, fill, dot), not hue, so Red Mode keeps working.
- Provide controls and readouts where they teach: a scrubber, a toggle, a limiting-factor chip.
- Keep each component a mirror candidate for Flutter: the app draws the same pictures, so keep geometry in plain functions.

## Mathematical notation in prose and tables

Describe equations with the symbols the equation uses, rendered as `$...$` math, with a symbol key (symbol, meaning, unit) near the top of each science page. Tables must not explain a formula with code variable names. Real code identifiers (file names, JSON keys, function names, API variables) stay as code, in a separate column when both are useful. `DocTable` cells accept math, code, bold and links.

## Layout rules

- There is no top bar. The brand and the search field sit at the top of the left sidebar, and a small floating menu button appears on narrow screens.
- Three panes: sidebar, article, and an on-this-page outline. The sidebar holds three groups: the colour system, the proportion system and sky science. The article scrolls without a visible scrollbar. Keep it that way.
- Do not add banners, headers, footers, announcement strips or other chrome that was not requested.
- Keep sizing, spacing and radii consistent with the existing shell stylesheet. Reuse its roles instead of introducing new ones. The shell stylesheet carries no raw pixel sizes: every length, font size and radius reads a proportion token, and the verification script fails if a literal appears outside a media query.

## Writing pages

- Pages live as markdown with embedded components in the content folder. Prose and formulas belong in the markdown, not in components.
- Mathematics is written in markdown math and rendered with KaTeX. Every number a page shows should be traceable to a formula on the same page.
- Each page declares its title, description and section list, and each declared section exists on the page. The verification script checks this.
- Each page has exactly one code tabs block with two filled panels. The colour and proportion pages name them Tokens and CSS, and Flutter. Sky science pages name them for the page. Never leave a placeholder tab.
- Use the shared documentation components for sections, notes, code blocks and tabs. Do not build one-off equivalents.
- Tone: short, factual, no marketing language, British spelling for the word colour.

## Flutter code

- Flutter code lives as real Dart files in the content folder's Flutter subfolder and is displayed verbatim in the Flutter tab. Pages show those files; they do not retype them.
- The Dart files mirror the stylesheet value for value, are plain Dart with no dependency on the Astr application, and must stay analyser-clean and test-verified against the stylesheet before they are committed.
- Android and iOS guidelines apply. Opacity is expressed as the ladder's fixed steps, gradients fade to the same colour at zero alpha rather than to transparent black, and the code targets a Flutter version that supports the current colour alpha API.
- Do not change the Dart files without changing the stylesheet's meaning first, and never the other way round.

## Before you say you are done

- Run the type check, the linter, the production build and the documentation verification script, in that order, and report real results. A step you did not run is reported as not run.
- Look at the page. For any visual change, take a screenshot and review it, at desktop and at a narrow width.
- After changing any file listed in the source manifest, run the sync script. After changing a specification or a reference implementation, run its Python and Dart tests before the site's checks. Run the production-server check, not only the static one.
- If the verification script's port is busy, find the leftover process from an earlier run and stop only your own.
- A development server may already be running for the owner. Do not stop it.

## Working with git

- Stage explicit paths inside this folder only. Never stage everything.
- The repository-root project instructions file may carry the owner's uncommitted edits. Never stage, revert or edit it.
- Commit with a clear message. Push only when the owner asks.
- Changes outside this folder, such as the specifications, the reference implementations, the licence files and the application code they live in, are separate commits at the repository root. Planning files are not committed because the project configuration turns that off. The owner's project instructions file is never staged, reverted or edited.
- Start edits through the project's quick-task workflow, as the root instructions require, and keep each task's summary in its folder.
- Do not commit generated build output or dependency folders.

## Never do these

- Never change a colour stop or an opacity value.
- Never add a colour, opacity, gradient or font that is not defined by the system.
- Never use aurora or airglow colours in the documentation's own design.
- Never add a top bar.
- Never put raw code or hex values into this file.
- Never touch the Flutter application to make the docs work.
