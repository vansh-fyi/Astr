# Next steps: building the Astr app on the design system

Prepared 2026-10-10. This is the plan for turning the current Flutter app into the finished Astr app, using everything the design system, the specifications and the old app give us.

Read `website/AGENTS.md` first. Its rules apply to every line of Flutter below. The short version: every colour is a stop, every length is a Fibonacci step, every font size is a type step, and every component already has a page under `/components`.

## 1. Where we are

**Done and verified**

- The design system site (`website/`): colour stops, opacity ladder, gradients, spacing, type, layout, and 13 component pages with live playgrounds, React and Flutter code, API tables and token tables. Checked by `npm run check`.
- The sky science, written as specifications with test vectors and three matching implementations (Python, Dart, TypeScript):
  - Zone scale v2.0: `docs/astr_zone_scale.md`, `lib/core/utils/astr_zone_scale.dart`, `scripts/astr_zone.py`.
  - Sky synthesis v1.0 (moonlight, usable hours, best window, six states, the cause): `docs/astr_sky_synthesis.md`, `lib/core/utils/astr_sky_model.dart`, `scripts/astr_sky.py`.
  - Skyglow propagation: `docs/skyglow_propagation.md`.
- Flutter design tokens, mirrored from the site: `website/content/flutter/astr_colors.dart`, `astr_opacity.dart`, `astr_gradients.dart`, `astr_spacing.dart`, `astr_type.dart`, `astr_layout.dart`.
- Proposed Flutter components built only from those tokens, analyser-clean: `website/content/flutter/astr_glass.dart` (`AstrGlassTile`, `AstrGlassButton`, `AstrGlassToggle`, `AstrGlassTextField`, `AstrGlassCard`).
- Apache-2.0 licence and `NOTICE`.

**The app today** (the numbers matter, they are the size of the job)

| Fact | Number |
| --- | --- |
| Dart files in `lib/features` | 150 (dashboard 60, profile 27, catalog 20, astronomy 11, data_layer 11, context 8, splash 7, forecast 6) |
| Test files | 83 |
| Hex colour literals in `lib` | 114 |
| `Colors.*` references in `lib` | 401 |
| Numeric `fontSize` in `lib` | 109 |
| References to `AppColors`, `AppSpacing`, `AppTypography` | 212 |
| Routes | splash, tos, add-location, and a four-tab shell: home, catalog (with object detail), forecast, settings (with locations) |

The planning state (`.planning/STATE.md`) says phase 3 (design system and home screen) was open and not approved, with 2 of 9 phases complete. This plan replaces phases 3 to 7 of the old roadmap. Phases 1 and 2 (archive and zone validation) stand, and phases 8 and 9 (testing, store submission) become the last two phases here.

**Known problems in the old app** (from the sky science pages, which read the real code)

- Three different label sets exist for one zone.
- The sky state ignores moon, aerosols and elevation. It uses the current-hour cloud only.
- `DarknessCalculator`, `QualitativeConditionService`, `BortleMpsasConverter`, `QualityCalculator` and `StargazingLogic` are the old verdict logic. The last three are unused or marked for removal.
- `AltitudeGraph` plots a mock sine curve. `CloudCoverGraphPainter` is unused. The object graph computes optimal windows and never draws them.
- The prime view window is a weighted average that is always three to five hours and is dropped above a fixed score.
- The stored zone data is built from radiance thresholds (the legacy chain), not the ratio ladder.
- Naming debt: the JSON field and the Dart field called `bortle`/`ratio` do not hold what they say (see "Names to fix" on the zone scale page).
- The bundled object catalogue is tiny.

## 2. Principles for this work

1. **In place, not a rewrite.** Keep the logic layers that work. Rebuild the presentation layer on the design system. Do not start a new project.
2. **Tokens first, then widgets, then screens.** Nothing is built on the old tokens again.
3. **Logic follows the specifications.** The zone scale and sky synthesis implementations already pass the shared vectors. Wire the app to them, do not reimplement.
4. **One widget at a time.** A widget is done when it uses only Astr tokens, has all its states, has a widget test, and its component page says so.
5. **The site is the design authority.** Figma gives layout intent. Values come from the scale. When Figma and the scale disagree, use the nearest step and flag it.
6. **Nothing ships on a guess.** Anything unverified stays marked unverified in the app's copy as well.
7. **Small commits, each verified.** `flutter analyze` and the relevant tests pass before every commit.

## 3. Keep, replace, rebuild, delete

| Area | Decision | Notes |
| --- | --- | --- |
| `core/engine` (AstroEngine, isolates, rise/set, coordinate maths) | Keep | Planet and moon positions. Later move the ephemeris to free JPL data (decided). |
| `features/astronomy` | Keep | Swiss Ephemeris init, rise/set/transit. |
| `features/data_layer` (H3, zone repository, remote zone service, Hive cache) | Keep | The zone lookup is correct. The data regeneration is a separate track (phase B3). |
| Weather (`core/services/weather`, Open-Meteo service, cached repository, pruning, background sync) | Keep | Add hourly aerosol and surface pressure when the sky model needs them. |
| `features/context` (selected place and date) | Keep | Restyle `LocationSheet`. |
| `features/profile` locations repository and providers | Keep | Rebuild its screens. |
| `features/splash` init sequence | Keep | Rebuild the screen. |
| `features/catalog` (SQLite catalogue, rise/set, visibility graph data) | Keep | Rebuild the screens and widgets. The catalogue grows in phase D. |
| `core/utils/astr_zone_scale.dart`, `astr_sky_model.dart` | Keep, wire up | These are the new verdict logic. |
| `DarknessCalculator`, `QualitativeConditionService`, `prime_view_calculator` | Replace | By `hourQuality`, `bestWindow`, `skyState`, `why` from `astr_sky_model.dart`. Delete after the replacement passes. |
| `BortleMpsasConverter`, `QualityCalculator`, `StargazingLogic`, `bortle_bar.dart` | Delete | Verify no references first. |
| `AltitudeGraph` (mock), `CloudCoverGraphPainter` (unused) | Delete | Their replacements are the documented graph components. |
| `AppColors`, `AppSpacing`, `AppTypography`, `AppTheme` | Replace | By the Astr tokens (phase A). |
| Every dashboard, catalog, forecast, profile and splash widget | Rebuild | In the order in section 6. |
| `GlassPanel`, `GlassToast`, `CosmicLoader`, `RedModeOverlay` | Restyle | Red mode stays and must be tested against the new tokens. |

## 4. Phase A: foundations (do first, about a day)

Goal: the app compiles on the new tokens, and nothing can be written on the old ones.

**A1. Branch and workflow.** Work on a branch. Start through the quick-task workflow the root instructions require.

**A2. Bring the tokens in.** Copy the six `astr_*.dart` files from `website/content/flutter/` to `lib/core/design/`. The website copy is the source. Add a test that fails if the two copies differ. Add `astr_glass.dart` to `lib/core/widgets/` the same way, with the same test.

**A3. Fonts.** The type system names Satoshi for headings and Inter for body. The app currently ships Satoshi only (the files are not tracked in git, correctly). Decide Inter for body text and add it (it is OFL licensed). Run the fonts script with its application flag on a fresh checkout. **Open risk:** confirm Satoshi's licence allows embedding in a distributed app binary. The licence forbids redistributing the font files, and an app bundle contains them. Treat this as unverified until checked, and have a fallback plan.

**A4. The bridge, then the replacement.**

1. Re-point the old tokens at the new ones so every widget changes at once and the app compiles: make `AppColors`, `AppSpacing` and `AppTypography` thin deprecated aliases of the Astr tokens, using the table in the appendix.
2. Replace `AppTheme` with a `ThemeData` built from `AstrColors`, `AstrType` and `AstrRadius`. Remove the `FlexColorScheme` dependency if nothing else needs it.
3. Migrate widgets off the aliases one at a time (section 6). When the last one is off, delete the aliases.

**A5. The token guard.** Add a test (or a custom lint rule) that fails on `Color(0x`, `Colors.` other than `Colors.transparent`, numeric `fontSize`, numeric `EdgeInsets` and numeric `SizedBox` in `lib/features` and `lib/core/widgets`. Start it as an allow-list of files not yet migrated, and shrink the list as phase C goes. This is what stops regression.

**A6. Finish the component set before screens need it.** The site has pages for tile, button, toggle, text field, nav bar, cloud bar, visibility card, moon card, conditions card, sky state background, and the three graphs. The Flutter side still needs these built from `astr_glass.dart`:

- `AstrNavBar` (bottom bar with notch and round action; top bar). Port the app's existing `ScaffoldWithNavBar`, `NavBarClipper` and `NotchShinePainter` onto the tokens.
- The documented cards (`CloudBar`, visibility, moon, conditions, sky state) rebuilt on `AstrGlassCard`.
- The three graph painters on the tokens, with the NOW pulse and the label pills.

**A7. Red mode.** Keep `RedModeOverlay`. Add a widget test that renders each component under it and asserts no meaning is carried by hue alone.

**Acceptance for phase A:** `flutter analyze` is clean, all existing tests pass, the token copies match the site, the guard test runs, and the app launches with the new look through the aliases.

## 5. Phase B: logic correctness (can run alongside A and C)

Goal: the verdict the app shows is the one the specifications define.

**B1. Wire the sky model.** Build one provider that produces, for the selected place and date, the list of hourly inputs (dark or not, cloud, artificial ratio, moon brightness) and the outputs `bestWindow`, `nightState`, `instantState` and `why`. The hero uses the night state and the window, the chip uses the instant state, and the cause line uses `why`. The test vectors in `test/fixtures/` already pin the behaviour. Do not reimplement the maths.

**B2. Moon inputs.** For each hour compute the moon altitude, azimuth and illuminated fraction from the engine and feed them to the moonlight model. Extinction uses surface pressure and, when available, aerosol optical depth. Until aerosol data is wired in, use the documented default and say so.

**B3. Zone data.** The model needs the ratio r. Until the zone database is regenerated on the ladder, convert stored radiance with the legacy chain exactly as the zone scale page specifies. Then regenerate the data (the pipeline scripts are in `archive/data-pipeline`), rename the fields as listed in "Names to fix", and ship the new file. Run the validation set (25 places) before and after.

**B4. One zone vocabulary.** Delete the three label sets. Show the zone number, the sky brightness and, where room allows, the limiting magnitude.

**B5. Delete the old logic** once B1 passes: `DarknessCalculator`, `QualitativeConditionService`, `prime_view_calculator` and the unused helpers.

**Acceptance for phase B:** the Python, Dart and TypeScript vector tests pass, and a manual walk-through of five known places gives the verdicts the validation page lists.

## 6. Phase C: screens, one at a time

For every screen, in this order: confirm the components it needs exist, build the screen from them, write widget tests for each state (loading, data, stale, offline, error, empty), check under the red overlay, then mark its widgets migrated and update the component pages.

| Order | Screen | Components | Notes |
| --- | --- | --- | --- |
| C1 | Navigation shell | `AstrNavBar` bottom and top | Four tabs, the sky-map action opens a "coming soon" state until the star map exists. |
| C2 | Home | Sky state background, hero label with zone, conditions card, visibility card, moon card, highlights feed, hourly list, weather summary | The hero shows the best window state, the chip shows now, the cause line is always present. |
| C3 | Atmospherics sheet | Conditions graph, cloud graph, tiles, hourly list | Prime view band near the top. Show the best window, not the old three-to-five-hour average. |
| C4 | Objects (catalogue) and object detail sheet | Object list item, object visibility graph (both variants), time cells, stats | Draw the "optimal hours" the old code computed and never showed. |
| C5 | Forecast | Forecast day rows | Each day gets the night state and cause, not just cloud. |
| C6 | Settings, locations, add location, location sheet | Text field, toggle, button, list rows | Search uses the text field's search type. |
| C7 | Splash and terms of service | Loader, button | Keep the init sequence. |

**Components with no page yet** (write the page and the Flutter before the screen needs them, on the website first, one at a time): hourly forecast list, weather summary card, highlights feed, object list item, forecast day row, list row, bottom sheet, toast, the loader, the atmospherics sheet layout and the location sheet. Each follows the eight-step "Adding or changing a component" list in `website/AGENTS.md`.

**Acceptance for each screen:** zero hex, `Colors.*`, numeric size or numeric font in its files; every state has a test; a screenshot at one phone width and one narrow width is reviewed; no regressions in the other tests.

## 7. Phase D: the object corpus and the star map (planned, not started)

Decided: free, open source, tip-funded; the corpus should match the best planetarium apps; core bundled data plus optional region packs; include the literal interstellar visitors; the ephemeris moves to free JPL data.

Before any code, write the specification and get the owner's answers on:

- Which catalogues form the core (stars, Messier, NGC and IC, planets and moons, comets, satellites), with the licence of each. Only data that is compatible with Apache-2.0 for code and CC BY-SA for data packs.
- The size budget of the bundled core and of each region pack.
- The projection and rendering approach for the star map, and its performance target on a mid-range phone.
- How visibility intelligence per object is computed (altitude window, moon angle cost, cloud), reusing the sky model.

Pages for these (object corpus, star map) go on the website first.

## 8. Phase E: tests

- Keep the 83 existing tests, repairing the ones the migration breaks.
- Add a widget test per component and per screen state, and a golden test per component variant that matters.
- Keep the shared vector tests (zone scale, sky synthesis) in CI for all three languages.
- Add the token guard and the token-copy match test (A2, A5).
- Add a red-mode test (A7).
- An integration test for the first-launch flow: splash, terms, home, switching place and date (the two known provider staleness bugs from the old roadmap must be covered).

## 9. Phase F: store submission

- Licences: confirm and record every dependency and asset in `NOTICE`. Open items: the VIIRS nighttime lights licence for the 2024 composite (marked unverified on the site), the Satoshi embedding question (A3), the catalogue licences (phase D).
- Privacy: location is requested at runtime with a clear reason; no account; no tracking. Write the privacy text and the store data-safety answers truthfully.
- Tips: the product is tip-funded through the stores. Add the in-app tip products on both stores, and link the Ko-fi page from the website.
- Store assets: icons, screenshots from the finished screens (dark only), descriptions, age rating.
- Terms of service screen content reviewed.
- Release builds on both platforms from a clean checkout, with background sync tested on a real device.

## 10. Open decisions for the owner

1. Inter for body text in the app, or Satoshi throughout (the app uses Satoshi throughout today; the type system says Inter for body)?
2. Satoshi embedding in the app: confirm the licence, or choose a fallback.
3. Adopt the nav bar as documented (icon-tile tabs, round action, rounded corners), or keep the app's bare icons?
4. The mini cards: 144 by 165 (token sizes) instead of 164 by 154. Confirm.
5. Phase D scope and order: object corpus before the star map, or together?
6. Whether to regenerate the zone database before launch (recommended) or ship the legacy chain first.

## 11. Tomorrow's order of work

1. Read `website/AGENTS.md`. Create the branch and start the quick task.
2. A2: copy the tokens and add the match test.
3. A4 step 1 and 2: the aliases and the new theme. Run the app and the tests.
4. A5: the token guard with the allow-list.
5. A6: `AstrNavBar` and the card components.
6. C1: the navigation shell on the new nav bar.
7. B1: wire the sky model behind the home screen's hero and chip (it can be developed against the existing home screen).
8. C2: the home screen, component by component.
9. At each step: `flutter analyze`, the tests, a screenshot, a commit. Update the component page for each migrated widget.

## Appendix A: old token to new token

Use this for the bridge in A4 and for reading old code. Do not add new code against the old names.

| Old | New | Notes |
| --- | --- | --- |
| `AppColors.surface`, `oledBlack` | `AstrColors.spaceGrey[950]` | Pure black ground. |
| `AppColors.surfaceOverlay`, `surfaceGlass` | the card material: `AstrGlassCard` | A sheen over the ink at `Mag.m1`, not a flat fill. |
| `AppColors.accent`, `accentSecondary` | `AstrColors.deepSpace[200]` | One accent. |
| `AppColors.borderPrimary`, `borderSubtle`, `borderSurface` | space grey fifty at `Mag.m5` | One hairline. |
| `AppColors.textPrimary` | `AstrColors.spaceGrey[50]` | |
| `AppColors.textSecondary`, `textMuted` | `AstrColors.spaceGrey[300]` | |
| `AppColors.textSubdued` | `AstrColors.spaceGrey[400]` | |
| `AppColors.zonePillFill`, `zonePillText` | deep space two hundred at `Mag.m4`, deep space fifty | |
| `AppColors.ratingBarActive`, `cloudTrack`, `ratingBarInactive` | deep space two hundred, space grey five hundred at `Mag.m4` | |
| `AppColors.glowShadow` | the button glow in `AstrGlassButton` | Glow only on buttons, tiles and toggles. |
| `AppSpacing.kCardRadius` (16), `kInnerRadius` (12) | `AstrRadius.f21`, `AstrRadius.f13` | |
| `AppSpacing.kMiniCardWidth`, `kMiniCardHeight` (164, 154) | `AstrSpace.f144`, `AstrSpace.f144 + AstrSpace.f21` | |
| `AppSpacing.kConditionsCardWidth`, `Height` (345, 242) | a width up to 377, height from content | Flow layout. |
| `AppSpacing.kCardPadding` (16) | `AstrSpace.f13` | |
| `AppSpacing.kCloudTrackHeight`, `kRatingBarHeight` (8, 5) | `AstrSpace.f8`, `AstrSpace.f5` | |
| `AppSpacing.kSunMoonCellHeight` (64) | `AstrSize.control` (55) | |
| `AppSpacing.kPillHeight`, `kExploreButtonHeight` (28, 27) | `AstrSize.controlCompact` (34) | Compact button. |
| `AppSpacing.xs` to `xxxl` (4 to 64) | `f3` or `f5`, `f8`, `f13`, `f21` or `f34`, `f55` | See the cheat sheet in AGENTS.md. |
| `AppTypography.display` (72) | `AstrType.s6` (68) | |
| `AppTypography.title` (28) | `AstrType.s2` (26) or `s3` (33), by role | |
| `AppTypography.heading`, `body` (16) | `AstrType.s0` | |
| `AppTypography.labelMd` (12) | `AstrType.sNeg1` (13) | |
| `AppTypography.labelSm`, `micro`, `nav` (10, 8, 8) | `AstrType.sNeg2` (10) | |
| `GraphTheme.moonColor`, moon fill and stroke | deep space three hundred at `Mag.m4`, deep space two hundred | |
| `GraphTheme.objectCurveColor` | the chosen tone (`AstrTone`) | |
| `GraphTheme.nowIndicatorColor` | sodium airglow four hundred | |
| `GraphTheme.primeViewColor` | aurora green four hundred | |
| moon rise purple | aurora pink four hundred | |

## Appendix B: old widget to new component

| Old widget | New | Status |
| --- | --- | --- |
| `CloudBar` | cloud bar (page exists) | documented, app not migrated |
| `VisibilityMiniCard` | visibility card | documented, layout already updated in the app, tokens not migrated |
| `MoonMiniCard` | moon card | documented, quarter artwork fixed, tokens not migrated |
| `ConditionsCard` | conditions card, with the small filled button for Explore | documented |
| `SkyStateBackground` | sky state background | documented |
| `ConditionsGraph` | conditions graph | documented |
| `VisibilityGraphWidget`, `VisibilityGraphPainter` | object visibility graph, visibility variant | documented |
| `AltitudeGraph` | object visibility graph, altitude variant | the app's version is a mock: rebuild it on real data |
| `CloudCoverGraphPainter` | cloud cover graph | rebuild on the conditions graph |
| `ScaffoldWithNavBar`, `NavBarClipper`, `NotchShinePainter`, `_NavBarItem` | nav bar | documented, app not migrated |
| `GlassPanel`, `GlassToast` | card material, toast (page to write) | |
| `BortleBar`, `DarknessCalculator` callers | delete | old verdict |
| `MoonPhaseCard`, `DataCard`, `TimeCard`, `HighlightCard`, `SummaryText`, `SkyPortal`, `NebulaBackground`, `DashboardHeader`, `DashboardGrid` | check usage, then rebuild or delete | not documented yet |
| `HeroConditionLabel` | hero label (page to write) | |
| `HourlyForecastList`, `WeatherSummaryCard`, `HighlightsFeed` | pages to write first | |
| `AtmosphericsSheet`, `CelestialDetailSheet` | sheet layouts (pages to write first) | |
| `ObjectListItem` | page to write first | |
| `LocationSheet`, locations and add-location screens, ToS and splash screens | rebuild from text field, button, toggle | |

## Appendix C: commands

Website (from `website/`): `npx tsc --noEmit`, `npm run lint`, `npm run build`, `npm run build:turbo`, `npm run check`, `npm run check -- --http prod`.

Flutter (from the repository root): `flutter analyze`, `flutter test`, and `dart run build_runner build` after changing a provider, model or adapter.

Specifications: the Python tests in `scripts/` and the Dart tests under `test/core/utils/` must pass before the site's checks after any change to a specification or reference implementation.
