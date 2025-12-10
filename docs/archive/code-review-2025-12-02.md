# Ad-Hoc Code Review: Moon Icon Logic

**Reviewer:** Amelia (AI Senior Developer)
**Date:** 2025-12-02
**Files Reviewed:**
- `lib/features/dashboard/presentation/widgets/dashboard_grid.dart`
- `lib/features/dashboard/presentation/home_screen.dart`
- `lib/features/astronomy/data/repositories/astro_engine_impl.dart`
- `lib/features/astronomy/presentation/providers/astronomy_provider.dart`

**Review Focus:** Moon Icon logic implementation and moon phase display.

## Summary
The current implementation of the Moon Icon in the dashboard grid is incomplete. It correctly displays the illumination percentage but fails to accurately represent the moon phase (Waxing vs. Waning) because it relies on a hardcoded label ("Moon") and ambiguous illumination data. The underlying astronomy engine calculates the necessary phase angle but does not currently expose it to the UI.

## Outcome
**CHANGES REQUESTED**

## Key Findings

### High Severity
- **Incorrect Moon Phase Logic**: The `_getMoonEmoji` function in `DashboardGrid` relies on the `moonPhaseLabel` to distinguish between Waxing and Waning phases. However, `HomeScreen` currently hardcodes this label to `'Moon'`, causing the logic to fall back to a simple illumination check which cannot differentiate 50% Waxing (First Quarter) from 50% Waning (Last Quarter).
- **Data Underutilization**: `AstroEngineImpl` uses `Sweph.swe_pheno_ut` which returns the phase angle (index 0), but only the illumination (index 1) is returned to the app. The phase angle is required to correctly determine the phase.

### Medium Severity
- **Hardcoded Strings**: The label 'Moon' is hardcoded in `HomeScreen`, preventing localization or dynamic updates.

## Architectural Alignment
The current implementation violates the principle of "Smart Domain, Dumb UI". The UI (`DashboardGrid`) is trying to derive the icon from a label, whereas the Domain (`AstroEngine`) should provide the semantic phase information (Angle or Enum).

## Action Items

### Code Changes Required
- [ ] [High] Update `IAstroEngine` and `AstroEngineImpl` to return a `MoonPhaseInfo` object containing both `illumination` (double) and `phaseAngle` (double). (AC #N/A) [file: lib/features/astronomy/domain/repositories/i_astro_engine.dart]
- [ ] [High] Update `AstronomyState` to store the full `MoonPhaseInfo`. [file: lib/features/astronomy/domain/entities/astronomy_state.dart]
- [ ] [High] Update `DashboardGrid` to accept `phaseAngle` and implement correct emoji selection logic:
    - New: 0-1%
    - Waxing Crescent: 1-49%
    - First Quarter: 50% (approx 49-51%)
    - Waxing Gibbous: 51-99%
    - Full: 99-100%
    - Waning Gibbous: 99-51%
    - Last Quarter: 50% (approx 51-49%)
    - Waning Crescent: 49-1%
- [ ] [Med] Remove the hardcoded 'Moon' label from `HomeScreen` and pass the calculated phase name instead.

### Advisory Notes
- Note: Consider creating a `MoonPhase` enum in the domain layer to encapsulate this logic centrally.
