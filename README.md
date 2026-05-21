# Project Rebuild: Modular Physical & Mental Transformation Architecture

> A component-driven Flutter application engineering a unified, low-latency ecosystem for synchronizing physical metrics and mental well-being in real-time.

![App UI Architecture](./assets/app-preview.png)

## Systems Architecture & Data Flow

Project Rebuild leverages a component-driven UI architecture that decouples distinct domains into highly focused routing tabs (`dashboard_tab`, `workouts_tab`, `nutrition_tab`, `journal_tab`, `mobility_tab`). This strict separation of concerns allows for independent feature scaling without polluting global state. By maintaining modular feature boundaries, the application ensures O(1) complexity in rendering individual components and limits unnecessary widget rebuilds.

The architecture integrates Cloud Firestore (NoSQL) for the real-time synchronization of diverse data streams via asynchronous fetching. Instead of monolithic payloads, the system retrieves localized document snapshots (e.g., retrieving specific week schemas like `week_01` for the `workouts_tab`). This asynchronous architecture minimizes latency and prevents UI blocking on the main thread, achieving sustained 60fps performance on Android devices, even during heavy DOM manipulation.

The UI rendering engine is explicitly optimized utilizing a custom "FIRE" Dark Theme (`#121212` / `#1E1E1E`), which incorporates complex glassmorphism effects mathematically driven by `BackdropFilter` and matrix blurring techniques.

### Visual Architecture Documentation
* **Authentication Module – Flutter & Firebase:** User authentication interface designed in Flutter and integrated with Firebase Authentication for secure login and account management.
  ![Authentication Module – Flutter & Firebase](./docs/assets/1_auth.png)
* **Core Dashboard – Progress Analytics System:** Main dashboard displaying workout progress, streak tracking, level system, and real-time performance metrics implemented using Flutter and Cloud Firestore.
  ![Core Dashboard – Progress Analytics System](./docs/assets/2_dashboard.png)
* **Nutrition & Hydration Tracking Module:** Module for tracking daily calorie intake, protein consumption, and water levels with dynamic progress indicators and user-defined targets.
  ![Nutrition & Hydration Tracking Module](./docs/assets/3_nutrition.png)
* **Mental Health & Reflection Tracking Interface:** Daily reflection module with mood and energy sliders, journaling features, and structured data storage using Firebase Firestore.
  ![Mental Health & Reflection Tracking Interface](./docs/assets/4_journal.png)
* **Workout Planning & Progress System:** Workout scheduling interface organized by weekly plans, designed to track exercise routines and progression over time.
  ![Workout Planning & Progress System](./docs/assets/5_workouts.png)
* **Application Navigation & Feature Architecture:** Side navigation system showcasing modular app architecture with features such as notes, scheduling, mobility tracking, and settings management.
  ![Application Navigation & Feature Architecture](./docs/assets/6_navigation.png)

## Tech Stack & Dependencies

* **Frontend Framework:** Flutter (Dart)
* **Backend Services:** Firebase Auth (Session Management), Cloud Firestore (NoSQL Real-Time Sync)
* **Data Visualization:** `fl_chart`, `percent_indicator`
* **Media Serving:** `chewie`, `video_player` (Native instructional media)
* **Formatting & UI:** `intl`, `font_awesome_flutter`

## Setup & Execution

To execute this architecture locally, ensure the Flutter SDK and a target device/emulator are configured.

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/yourusername/project-rebuild.git
   cd project-rebuild
   ```

2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Inject Backend Credentials:**
   The application requires authorized Firebase credentials to connect to the backend.
   * Obtain the `google-services.json` file from the Firebase console.
   * Inject the file into the `android/app/` directory.
   * If compiling for iOS, inject `GoogleService-Info.plist` into the `ios/Runner/` directory.

4. **Deploy Application:**
   ```bash
   flutter run
   ```
