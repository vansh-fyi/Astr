# Project Overview

**Astr** is a comprehensive stargazing planner application designed to help astronomers and enthusiasts plan their observation sessions. It combines real-time weather data, light pollution maps, and celestial object catalogs into a unified interface.

## Executive Summary

The project consists of a **Flutter-based mobile application** for iOS and Android, supported by a **Python/Flask backend** deployed on Vercel. The app features a modern, glassmorphic UI ("Glass UI") and includes advanced features like "Red Mode" for night vision preservation and Rive-based animations.

## Technology Stack

| Category | Technology | Description |
|----------|------------|-------------|
| **Mobile Framework** | Flutter | Cross-platform mobile development (Dart) |
| **State Management** | Riverpod | Reactive state management |
| **Backend Framework** | Flask | Python micro-framework for API endpoints |
| **Database** | MongoDB | NoSQL database for user data and logs |
| **Runtime** | Vercel | Serverless deployment for Python backend |
| **Astronomy Engine** | Swiss Ephemeris | High-precision celestial calculations (`sweph` package) |
| **Local Storage** | Hive | Fast key-value storage for offline data |

## Architecture

The project follows a **Multi-part Architecture**:

*   **Mobile Client**: Clean Architecture (Layered) with `app`, `core`, `data`, and `features` layers.
*   **Backend API**: Micro-service style serverless functions handling specific tasks (e.g., light pollution data processing).

## Repository Structure

*   **Monorepo-style**: Both client and backend code reside in the same repository.
*   **Root**: Flutter application code.
*   **`backend/`**: Python backend code.

## Documentation Links

*   [Source Tree Analysis](./source-tree-analysis.md)
*   [Component Inventory](./component-inventory.md)
*   [Development Guide](./development-guide.md) _(To be generated)_
*   [API Contracts](./api-contracts.md) _(To be generated)_
