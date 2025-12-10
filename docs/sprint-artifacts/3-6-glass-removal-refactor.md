# Story 3.6: Glass Removal Refactor

Status: review

## Story

As a user,
I want the app to scroll efficiently with zero frame drops,
so that I have a smooth and responsive experience even on older devices.

## Acceptance Criteria

1. **Card Styling Update:**
   - **Given** any scrolling list (Home, Catalog, Settings), **When** cards are rendered, **Then** they MUST NOT use `BackdropFilter` (Blur).
   - **Visuals:** Cards should use a semi-transparent background color (Opacity) with a thin border/stroke to maintain the "Glassy" feel without the performance cost of real-time blur.

2. **Static Blur Preservation:**
   - **Given** static UI elements (Top Bar/Header, Bottom Navigation Bar), **When** rendered, **Then** they SHOULD continue to use `BackdropFilter` (Blur) to maintain the premium aesthetic where performance impact is minimal.

3. **Performance Target:**
   - **Given** the refactored UI, **When** scrolling a list of 50+ items, **Then** the UI thread must maintain a consistent 60fps (16ms/frame) on reference devices (e.g., iPhone 11, Pixel 4).

## Tasks / Subtasks

- [x] Remove Blur from GlassPanel Widget
  - [x] Modify `GlassPanel` (or equivalent) to accept a `enableBlur` flag (default false for lists).
  - [x] Implement new style: Color.withOpacity(...) + Border.all(...).
- [x] Update List Implementations
  - [x] Audit all uses of `GlassPanel` in `ListView` or `SliverList`.
  - [x] Ensure `enableBlur` is false for these instances.
- [x] Verify Static Elements
  - [x] Ensure Headers and NavBars still have blur enabled.
- [ ] Performance Comparison
  - [ ] Profile old vs new implementation in Flutter DevTools (Profile Mode) to verify GPU reduction.

## Dev Notes

- **Architecture:** Presentation Layer (UI).
- **Components:** `ui/common/glass_panel.dart` (or similar), `ui/features/home`, `ui/features/catalog`.
- **Rationale:** Blur is computationally expensive (Gaussian pass). Removing it from list items (which rebuild/move frequently) drastically reduces GPU load.
- **Visuals:** Use a border color that contrasts slightly with the background to define edges (e.g., White w/ 0.1 opacity).

### Context Reference

- [Context XML](3-6-glass-removal-refactor.context.xml)s

- [Source: docs/architecture.md](#2-architectural-decisions) - Revalidates performance priority over pure aesthetics for scrolling.

---

## Senior Developer Review (AI)

**Reviewer:** Vansh  
**Date:** 2025-12-09  
**Outcome:** 🔴 BLOCKED

### Summary

Story 3.6 implementation is **incomplete**. While the `GlassPanel` widget correctly supports `enableBlur` flag and key list items (ObjectListItem, HighlightsFeed, DashboardGrid) use it correctly, **multiple scrolling list contexts still use blur**. Tasks are not marked complete. Static elements (Header/NavBar) correctly retain blur.

---

### Key Findings

#### 🔴 HIGH Severity

| Finding | Location | Description |
|---------|----------|-------------|
| Missing `enableBlur: false` | `forecast_list_item.dart:20` | List item in ListView still uses blur |
| Missing `enableBlur: false` | `bortle_bar.dart:24` | Card in scrolling context uses blur |
| Missing `enableBlur: false` | `profile_screen.dart:60,111,147` | 3 cards inside ListView missing flag |
| Broken import + missing flag | `catalog_screen.dart:5,81` | Imports from non-existent `dashboard/.../glass_panel.dart`, ListView items missing flag |
| Broken test import | `highlights_feed_test.dart:5` | Imports non-existent `dashboard/.../glass_panel.dart` |

#### 🟡 MEDIUM Severity

| Finding | Location | Description |
|---------|----------|-------------|
| Tasks not marked complete | Story file | All 4 tasks marked `[ ]` but partial work exists |

---

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
|-----|-------------|--------|----------|
| AC1 | Cards in lists MUST NOT use BackdropFilter | ❌ PARTIAL | `object_list_item.dart:25`, `highlights_feed.dart:70`, `dashboard_grid.dart:81,194` have flag ✓ but `forecast_list_item.dart:20`, `bortle_bar.dart:24`, `profile_screen.dart:60,111,147`, `catalog_screen.dart:81` MISSING |
| AC2 | Static elements (Headers/NavBars) SHOULD use blur | ✅ IMPLEMENTED | `scaffold_with_nav_bar.dart:52-53` (Header), `scaffold_with_nav_bar.dart:252-256` (NavBar) |
| AC3 | 60fps on 50+ item lists | ⏳ NOT VERIFIED | Requires DevTools profiling in Profile mode |

**Summary:** 1 of 3 ACs fully implemented, 1 partial, 1 not verified

---

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
|------|-----------|-------------|----------|
| Remove Blur from GlassPanel Widget | `[ ]` | PARTIAL | `glass_panel.dart:18-28` has `enableBlur` flag, default `true` |
| Update List Implementations | `[ ]` | PARTIAL | 4 files updated, 4+ files missing |
| Verify Static Elements | `[ ]` | DONE | Header/NavBar retain blur (`scaffold_with_nav_bar.dart:52-53,252-256`) |
| Performance Comparison | `[ ]` | NOT DONE | No profiling evidence |

**Summary:** 0 of 4 tasks marked complete. 2 partially done, 1 effectively done, 1 not started.

---

### Test Coverage

| Type | Status | Evidence |
|------|--------|----------|
| Widget Test for `enableBlur` | ✅ EXISTS | `test/core/widgets/glass_panel_test.dart` - Tests both blur/no-blur rendering |
| Broken Test Import | ❌ ISSUE | `highlights_feed_test.dart:5` imports non-existent path |

---

### Architectural Alignment

✅ Architecture docs (`docs/architecture.md:17`) mandate 60fps Glass UI target. Implementation direction is correct.

---

### Action Items

**Code Changes Required:**

- [ ] [High] Add `enableBlur: false` to GlassPanel in `forecast_list_item.dart:20`
- [ ] [High] Add `enableBlur: false` to GlassPanel in `bortle_bar.dart:24`
- [ ] [High] Add `enableBlur: false` to 3 GlassPanels in `profile_screen.dart:60,111,147`
- [ ] [High] Fix import in `catalog_screen.dart:5` → use `package:astr/core/widgets/glass_panel.dart`
- [ ] [High] Add `enableBlur: false` to GlassPanel in `catalog_screen.dart:81`
- [ ] [High] Fix import in `highlights_feed_test.dart:5` → use `package:astr/core/widgets/glass_panel.dart`
- [ ] [Med] Mark tasks complete in story as work is completed
- [ ] [Med] Run Flutter DevTools profile to verify 60fps target

**Advisory Notes:**

- Note: Consider whether `bortle_bar.dart` is truly a "list item" vs static card - may be OK with blur if not scrolling frequently
- Note: `catalog_screen.dart` appears to be a legacy/unused screen (simple placeholder UI). Confirm if still in use.
