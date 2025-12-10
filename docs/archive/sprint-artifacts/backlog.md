# Project Backlog

## Tech Debt
- [ ] **Refine PNG Light Pollution Mapping**
    - **Source:** Story 2.4 (Real Visibility Data).
    - **Description:** The current PNG fallback uses a luminance heuristic. We should implement exact color-to-value mapping based on the `djlorenz.github.io` legend to ensure accuracy when binary tiles fail.
    - **Priority:** Low.

- [ ] **Migrate Weather API to Cloudflare Worker**
    - **Source:** Story 2.1 (Visual Dashboard).
    - **Description:** `OpenMeteoWeatherService` currently calls the API directly. This exposes the app to rate limits and lacks a caching layer. Move this logic to the Cloudflare Worker proxy.
    - **Target:** Epic 6.

## Future Improvements
- [ ] **Expand Highlights Catalog**
    - **Source:** Story 2.3.
    - **Description:** Currently limited to major planets. Expand to include major stars and deep sky objects.
    - **Target:** Epic 3.
