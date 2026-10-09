<!-- BEGIN:nextjs-agent-rules -->

# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

# Astr design system: agent rules

This folder is the documentation site for the Astr design system. It is a Next.js app that will grow into the full design documentation and Flutter reference. Its scope is two systems: colour (the colour stops, the opacity ladder and gradients) and proportion (spacing, typography, layout and element sizes). Read this file before changing anything here, and follow it exactly.

This file contains no code on purpose. Rules are written in plain language. The authoritative values live in the files named below, never in this document.

## Scope

- Colour and proportion only. Do not add component documentation or any other new page until the owner asks for it, one at a time. The owner asked for the three proportion pages together, which is why spacing, typography and layout exist.
- The Flutter application in the repository root is outdated and is used for functionality only. Never read it for design guidance and never edit it from this folder's work. Design rules come from this site, not from the app.
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
- Never write a pixel size, gap, radius or font size that is not on the scale. If something does not fit, change the structure or tell the owner. Do not add a step.
- Never edit, round or reorder a step. Every value must be reproducible from its formula. The verification script recomputes the formulas and compares the stylesheet and the Dart files value for value, and fails on drift. Treat a failure as a stop sign.
- Type: size, leading and tracking always come together from one step. Body is step zero. Headings are two steps or more above the text they introduce.
- Layout: the reading measure is six hundred ten pixels. Panes use consecutive Fibonacci widths. Compact controls are drawn at thirty-four and tapped at fifty-five.
- Media queries cannot read variables, so a breakpoint written in the shell stylesheet is a literal. It must be a Fibonacci breakpoint or a sum of pane widths, and its comment must say which.
- The same page rules apply to the proportion pages: markdown with embedded components, formulas on the page, one code tabs block, and Dart files in the Flutter folder.

## Typography and brand

- Satoshi for headings and the wordmark. Inter for body text. No other typefaces.
- Satoshi comes from the font files already in the application's asset folder. Do not substitute a web font service for it.
- The brand mark is the real Astr app icon taken from the application's icon source. Never draw, recolour or replace it with a placeholder.

## Images

- Photographs live in the images folder as optimised webp only, with a long edge of at most sixteen hundred pixels. Never commit original PNG or JPEG files.
- Pages load them from the jsDelivr CDN, served from this repository, through the single image configuration in the library folder. Never hard-code another host.
- Each image has meaningful alternative text and is tied to the palette it inspired. Keep that mapping in the configuration, not in pages.
- The introduction shows them as a bento with each palette's eleven stops on the caption. New images must be pushed before the CDN can serve them.

## Layout rules

- There is no top bar. The brand and the search field sit at the top of the left sidebar, and a small floating menu button appears on narrow screens.
- Three panes: sidebar, article, and an on-this-page outline. The sidebar holds two groups, the colour system and the proportion system. The article scrolls without a visible scrollbar. Keep it that way.
- Do not add banners, headers, footers, announcement strips or other chrome that was not requested.
- Keep sizing, spacing and radii consistent with the existing shell stylesheet. Reuse its roles instead of introducing new ones. The shell stylesheet carries no raw pixel sizes: every length, font size and radius reads a proportion token, and the verification script fails if a literal appears outside a media query.

## Writing pages

- Pages live as markdown with embedded components in the content folder. Prose and formulas belong in the markdown, not in components.
- Mathematics is written in markdown math and rendered with KaTeX. Every number a page shows should be traceable to a formula on the same page.
- Each page declares its title, description and section list, and each declared section exists on the page. The verification script checks this.
- Each page has exactly one code tabs block with a Tokens and CSS tab and a Flutter tab. Both panels must be filled. Never leave a placeholder tab.
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
- If the verification script's port is busy, find the leftover process from an earlier run and stop only your own.
- A development server may already be running for the owner. Do not stop it.

## Working with git

- Stage explicit paths inside this folder only. Never stage everything.
- The repository-root project instructions file may carry the owner's uncommitted edits. Never stage, revert or edit it.
- Commit with a clear message. Push only when the owner asks.
- Do not commit generated build output or dependency folders.

## Never do these

- Never change a colour stop or an opacity value.
- Never add a colour, opacity, gradient or font that is not defined by the system.
- Never use aurora or airglow colours in the documentation's own design.
- Never add a top bar.
- Never put raw code or hex values into this file.
- Never touch the Flutter application to make the docs work.
