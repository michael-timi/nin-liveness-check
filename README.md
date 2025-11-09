# NIN Liveness Verification Flutter App

This application demonstrates how to implement a custom National Identification Number (NIN) liveness verification flow in Flutter without relying on the `qoreldsdk`. The client consumes backend services (assumed to be available) that provide session orchestration, biometric analytics, and NIN record checks.

The high-level architecture, requirements, and feature descriptions are documented in `docs/custom_nin_liveness_verification.md`.

## Features

- NIN input and validation with secure session bootstrapping.
- User consent flow with environment preparation guidelines.
- Live camera preview using the front-facing camera with active liveness prompts.
- Device motion capture via accelerometer to enrich evidence metadata.
- Secure evidence submission flow with simulated backend responses.
- Result and failure states with ability to restart the verification journey.

## Getting Started

1. Ensure you have Flutter installed (3.19 or later) and the necessary platform tooling.
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on a physical device or emulator:
   ```bash
   flutter run
   ```

### Permissions

The app requests camera and microphone access to complete liveness challenges. Audio capture is included to support voice prompts and anti-spoofing checks. Accept the permission dialog when prompted.

### Backend Integration

This sample uses a mock API client (`MockVerificationApi`) that simulates session creation, evidence upload, and result polling. Replace it with a real implementation that talks to your backend when available.

## Testing

Execute unit and widget tests with:

```bash
flutter test
```

Add additional tests to cover state management, permission handling, and network integrations as the app evolves.
