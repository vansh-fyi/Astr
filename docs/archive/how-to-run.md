# How to Run Your Astr App

Since you're coming from a React background (`npm run dev`), here is the Flutter equivalent to see your work in action.

## 1. Prerequisites
Ensure you have an emulator running or a physical device connected.
- **iOS Simulator:** `open -a Simulator`
- **Android Emulator:** Open Android Studio > Device Manager > Start device.

## 2. Run the App
In your terminal (at the project root), run:

```bash
flutter run
```

This is the direct equivalent of `npm run dev`. It compiles the code and launches the app on your connected device/simulator.

## 3. "Hot Reload" (The Magic)
Once the app is running, you don't need to restart it to see changes.
- **Press `r`** in the terminal to **Hot Reload**. This instantly updates the UI while keeping the app state (like where you scrolled to).
- **Press `R`** (Shift+R) to **Hot Restart**. This resets the app state and rebuilds everything.

## 4. Debugging
If you see errors, the terminal will show stack traces.
- **DevTools:** Flutter has a powerful web-based debugger. When you run `flutter run`, it will print a URL (e.g., `The Flutter DevTools debugger and profiler on ... is available at: http://127.0.0.1:9100...`). Open that link in Chrome to inspect the widget tree, performance, and memory.

## 5. What You Should See Now (Epic 3 Status)
- **Home Tab:** The Dashboard with Bortle Bar and "Is Tonight Good?" summary.
- **Celestial Bodies Tab:** A list of planets/stars (The Catalog).
- **Detail Page:** Tap any object in the catalog to see the new Detail Page with your **Visibility Graph**.

## Quick Command Summary

| React Command | Flutter Equivalent |
| :--- | :--- |
| `npm run dev` | `flutter run` |
| `Ctrl + C` | `q` (in the running terminal) |
| (Browser Refresh) | `r` (Hot Reload keypress) |
| `npm install` | `flutter pub get` |
