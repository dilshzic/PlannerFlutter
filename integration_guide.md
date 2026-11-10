# Master Integration Guide: Planner Modular Monorepo

This guide provides the definitive steps to maintain and deploy the modular Planner application across **Linux**, **Android**, and **Web**.

## 1. Authentication Stability (Critical)

To ensure Google Sign-In works flawlessly, you must maintain fixed ports for local development and whitelisted origins for production.

### Local Development Ports
The application is currently locked to **Port 8080** for both Linux and Web to provide a stable, predictable environment.

*   **Linux (OAuth Loopback)**: Locked to `http://localhost:8080`
*   **Web (Dev Server)**: Locked to `http://localhost:8080`

### Google Cloud Console Whitelist
You **MUST** add the following to your Google Cloud Console (OAuth 2.0 Client IDs):

1.  **Authorized JavaScript Origins (Web)**:
    *   `http://localhost:8080`
    *   `https://planner-47c07.web.app` (Firebase Hosting)
    *   `https://planner-47c07.firebaseapp.com` (Firebase Hosting)
2.  **Authorized Redirect URIs (Linux/Web)**:
    *   `http://localhost:8080`
    *   `http://localhost:8080/`

---

## 2. Platform-Specific Launching

Always use these commands to ensure the fixed ports are used:

### Linux
```bash
flutter run -d linux
```
*(The port is handled internally by the `DesktopAuthHandler`)*

### Web
```bash
flutter run -d chrome --web-port 8080
```

### Android
```bash
flutter run -d <device_id>
```

---

## 3. Production Deployment (Web)

To avoid the "localhost" issue entirely in production, use Firebase Hosting.

### Build and Deploy
1.  **Build the Web App**:
    ```bash
    flutter build web --release
    ```
2.  **Deploy to Firebase**:
    ```bash
    firebase deploy --only hosting
    ```

---

## 4. Module Architecture

The core logic has been isolated into project-agnostic packages:

*   `flutter_core_entities`: Domain models (AppUser, Task, Project).
*   `flutter_core_auth_hybrid`: Cross-platform OAuth/Firebase Auth.
*   `flutter_core_firestore_bridge`: Abstracted database logic.
*   `flutter_core_sync_engine`: Self-healing data synchronization.
*   `flutter_ui_identity`: Reusable theme and Auth UI (AuthWrapper, LoginScreen).

---

**Guide Status**: 100% COMPLETE & STABLE 🏗️🛰️🚀🏁
