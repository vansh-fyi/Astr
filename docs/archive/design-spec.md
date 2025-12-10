# UX Design Specification: Astr

> **Status:** Active Revision
> **Theme:** Astr Aura (Deep Cosmos + Glass) - **NO Light Mode**
> **Reference:** `docs/Home.html`, `docs/Details.html`
> **Audience:** Casual Planners (Relief/Confidence) & Astrophotographers (Awe/Precision)

## 1. Design Philosophy
**"The Sky is the UI."**
Astr does not just show data; it simulates the viewing experience.
*   **Direct Answer Philosophy:** We prioritize **Instant Clarity** ("Is tonight good?") for beginners, while offering **Deep Precision** for pros.
*   **Atmospheric Immersion:** The app background mirrors the night sky (Deep gradients, subtle stars, nebula glows).
*   **Interference-First Logic:** We don't just show "Saturn is up". We show "Saturn is up, *but* the Moon is blocking it."
*   **Glassmorphism:** All UI elements are floating glass panels (`backdrop-blur`), preserving context of the "sky" behind them.
*   **Unified Consistency:** The **Home Screen** is the visual source of truth. All drawers, sheets, and screens MUST use the exact same `GlassPanel`, `NebulaBackground`, and Typography as the Home Screen. No deviations.

---

## 2. Visual System: "Astr Aura"

### Color Palette (Tailwind Extracted)
| Role | Name | Hex/Class | Description |
| :--- | :--- | :--- | :--- |
| **Canvas** | **Deep Cosmos** | `#020204` | The void. Absolute black with a hint of blue. |
| **Glow** | **Nebula Indigo** | `indigo-600/10` | Ambient background blobs (`blur-[120px]`). |
| **Glow** | **Nebula Purple** | `purple-600/10` | Secondary ambient glow. |
| **Text** | **Starlight** | `#FFFFFF` | Primary headings and data. |
| **Text** | **Moon Dust** | `zinc-400` | Secondary labels and descriptions. |
| **Accent** | **Signal Emerald** | `emerald-500` | "Excellent" ratings, "Prime View" windows. |
| **Accent** | **Saturn Orange** | `orange-500` | Current time, Planet highlights, Warnings. |
| **Accent** | **Cosmic Purple** | `purple-400` | Deep sky objects, magical vibes. |
| **Glass** | **Panel Base** | `rgba(20, 20, 25, 0.6)` | `border-white/10`, `backdrop-blur-xl`. |

### Typography
*   **Family:** `Inter` (Primary).
*   **Display:** `font-medium`, `tracking-tight` (e.g., "Excellent", "Saturn").
*   **Micro:** `text-[10px]`, `uppercase`, `tracking-wider`, `font-semibold` (e.g., "CONDITIONS", "ALTITUDE").

### Animation Physics
*   **Float:** `animate-float` (6s ease-in-out infinite) for the Sky Portal.
*   **Pulse:** `animate-pulse-glow` (4s ease-in-out) for active states.
*   **Slide:** `animate-slide-up` (0.4s cubic-bezier) for Sheets.

---

## 3. The "Universal Visibility Graph" Logic
**The Core UX Innovation.**
Instead of generic altitude curves, EVERY celestial object (Planets, Stars, ISS) uses the "Interference Graph" concept from `Details.html`.

### The Formula
For any given time `t`:
`Visibility(t) = Altitude(t) - [CloudCover(t) + LightPollution + MoonGlare(t)]`

### Visual Representation (The Chart)
1.  **X-Axis:** Time (Now -> +12 Hours).
2.  **Background Layer:** The "Potential" Sky.
    *   Starry background.
    *   Represents 100% Visibility.
3.  **Interference Layers (The Blockers):**
    *   **Cloud Layer:** A semi-transparent white/grey area chart overlaid from the top. High clouds = Low visibility.
    *   **Moon Layer:** A gradient block that appears during Moonrise/Moonset times.
    *   **Horizon Layer:** A solid black block at the bottom representing the horizon (0° Altitude).
4.  **The Object Line:**
    *   **Crucial:** The line fades/disappears when it intersects with Cloud or Moon layers.
5.  **The "Prime View" Window:**
    *   **Logic:** If `Visibility > Threshold` for > 30 mins.
    *   **Visual:** A Green Pill / Highlight over that specific time range on the graph.
    *   **Label:** "Prime View: 23:30 - 01:00".

---

## 4. App Structure & Navigation

### Global Elements
*   **Bottom Navigation Bar:** Persistent across all top-level screens.
    1.  **Home** (Dashboard)
    2.  **Celestial Bodies** (Catalog)
    3.  **7-Day Forecast** (Planner)
    4.  **Profile** (Settings)
*   **Global Context:** Location and Date pills are persistent in the header (or top sheet) regardless of the active tab. Changing them updates the data for *all* tabs.

### A. Home Screen ("The Dashboard")
*   **Reference:** `docs/Home.html`
*   **Header:** Sky Portal (Status Orb).
*   **Body:** Forecast Strip, Bortle/Moon Grid.
*   **Highlights:** Lists **Top 3** Celestial Bodies for the night.
    *   *Interaction:* Clicking a highlight opens the **Object Detail Page** (Full Screen, not popup).

### B. Celestial Bodies Screen ("The Catalog")
*   **Layout:** List View with Sub-category Chips at top.
*   **Categories:** Planets, Galaxies, Star Clusters, Constellations.
*   **List Items:**
    *   Icon + Name + "Best Time" (if visible) or "Below Horizon".
    *   *Interaction:* Tap -> Opens **Object Detail Page**.
*   **Object Detail Page (Full Screen):**
    *   **Reference:** `docs/Details.html` (Visual style).
    *   **The "Interference Graph" (Crucial):**
        *   **Base:** Object Altitude Curve (When is it high?).
        *   **Interference:** **Moon Graph** overlay. The Moon's position/brightness is the primary negative factor.
        *   **Calculation:** `Best Time = Max(Object Altitude) where (Moon is Low/Set)`.
        *   *Visual:* Show the Object's curve. Overlay the Moon's curve (maybe in red/grey). Highlight the gap where Object is high and Moon is low.

### C. 7-Day Forecast Screen ("The Planner")
*   **Layout:** Vertical List of the next 7 days.
*   **List Item:** Date + Weather Icon + "Star Rating" (e.g., 5/5 stars) + Moon Phase.
*   **Interaction:** Tap a Day -> Opens a **Day Detail View**.
    *   *View:* Identical structure to the **Home Screen** (Portal, Grid, Highlights) but populated with data for that specific future date.

### D. Profile Screen ("The User")
*   **Status:** Optional.
*   **Features:**
    *   "Sign In to Sync" (Optional).
    *   **Saved Locations:** Manage list of favorite dark sky spots.
    *   **Settings:** Units (F/C), Notifications.
    *   **Data Persistence:** Even without login, settings/locations are saved locally on device.

---

## 5. Component Library (Flutter Ready)

| Component | Description |
| :--- | :--- |
| `GlassPanel` | Container with `BackdropFilter`, `BoxDecoration(color: white.withOpacity(0.05))`. |
| `SkyPortal` | Custom Painter. Radial gradients + AnimationController (Scale/Fade). |
| `ConditionsGraph` | `CustomPaint`. Cloud Cover Area + Moon Block. (For Atmospherics). |
| `AltitudeGraph` | `CustomPaint`. Object Parabola + Cloud Background. (For Celestial Details). |
| `MetricCard` | Standard grid item. Icon + Label + Value + Mini-visual. |
| `EventRow` | List tile. Leading Icon, Title, Trailing "View" button. |
| `BottomSheet` | `showModalBottomSheet` with rounded corners and glass background. |

---

## 6. Implementation Plan (Flutter)
1.  **Theme Setup:** Port Tailwind colors to `ThemeData`.
2.  **Layout Shell:** `Scaffold` with `Stack` for the Ambient Background.
3.  **Home Page:** Implement the Portal and Grid.
4.  **The Chart Engine:** Build the `VisibilityChart` widget (The hardest part).
5.  **Data Layer:** Mock the "Interference" logic (Clouds, Moon, Object Altitude).
