# Source Tree Analysis

## Project Structure Overview

The **Astr** project is a multi-part repository containing a Flutter mobile application and a Python backend.

```
/
├── android/                 # Native Android configuration
├── ios/                     # Native iOS configuration
├── lib/                     # Flutter Mobile App Source
│   ├── app/                 # App-level configuration (Router, Theme)
│   ├── common/              # Shared UI components
│   ├── config/              # App configuration logic
│   ├── constants/           # App-wide constants (Assets, Strings, Endpoints)
│   ├── core/                # Core services and utilities
│   │   ├── config/          # API configuration
│   │   ├── error/           # Error handling
│   │   ├── providers/       # Global state providers
│   │   ├── services/        # Logic services (Location, Seeing, Darkness)
│   │   └── widgets/         # Core reusable widgets
│   └── data/                # Data layer (Models, Repositories)
├── test/                    # Flutter Tests
├── backend/                 # Python Backend Source
│   ├── api/                 # API Endpoints (Flask/Vercel)
│   ├── scripts/             # Data processing scripts (NASA data)
│   ├── tests/               # Backend tests
│   └── requirements.txt     # Python dependencies
├── api/                     # Vercel Entry Point
│   └── index.py             # Vercel serverless function entry
├── pubspec.yaml             # Flutter dependencies
└── vercel.json              # Vercel deployment config
```

## Critical Directories

### Mobile App (`lib/`)

*   **`lib/app/`**: Contains the application shell, routing logic (`app_router.dart`), and global theme definitions. This is the entry point for UI structure.
*   **`lib/core/`**: The backbone of the app. Contains essential services like `DeviceLocationService`, `SeeingCalculator`, and `DarknessCalculator`. Also houses core widgets used throughout the app.
*   **`lib/data/`**: Manages data flow. Includes data models (`user_model.dart`) and repositories for fetching and storing data.
*   **`lib/common/`**: Reusable UI components that are specific to the app's design system but used in multiple places (`link_card.dart`, `grid_item.dart`).

### Backend (`backend/`)

*   **`backend/api/`**: Contains the Flask application logic and API route definitions.
*   **`backend/scripts/`**: Utility scripts for backend operations, specifically downloading and processing NASA light pollution data (`process_nasa_data.py`).
*   **`backend/tests/`**: Unit and integration tests for the backend logic.

## Entry Points

*   **Mobile**: `lib/main.dart` (Implicit, standard Flutter entry)
*   **Backend**: `backend/api/index.py` (Flask app instance) & `api/index.py` (Vercel entry)
