# Custom NIN Liveness Verification Guide

## Overview

This document describes what is needed to replace the `qoreldsdk` integration with an in-house National Identification Number (NIN) liveness verification experience in a Flutter application. It focuses on the mobile client work required, assuming that the backend services (biometrics processing, NIN lookups, and orchestration) can be provisioned or already exist.

## Scope and Assumptions

- Target platforms: Android and iOS Flutter apps.
- Backend can expose secure APIs for liveness scoring, face matching, and NIN record lookups.
- Solution must satisfy regulatory requirements for Know Your Customer (KYC) onboarding in Nigeria.
- App must operate in low-bandwidth scenarios, with strict privacy and data residency requirements.

## End-to-End Flow

1. **Session bootstrap** – mobile client requests a verification session token from the backend.
2. **Environment prep** – device capability checks (camera, sensors, OS version), network connectivity, and user consent for biometrics.
3. **Guided capture** – app walks user through NIN entry, liveness challenges, and selfie capture.
4. **Data packaging** – captured frames/video plus metadata (device info, challenge outcomes) are signed and uploaded.
5. **Backend evaluation** – backend validates liveness, compares selfie to official portrait, and confirms NIN record.
6. **Result delivery** – backend returns pass/fail plus actionable reasons; app persists minimal state and informs user.

## Flutter Client Requirements

- **State management** – define a verification state machine (`Idle → Ready → Capturing → Uploading → Result`) to drive UI and error handling.
- **Permissions & privacy** – request camera/microphone permissions with rationale screens and explicit consent logging.
- **Network layer** – authenticated HTTPS client supporting retries, exponential backoff, and graceful handling of offline states.
- **Session storage** – temporary, encrypted storage (e.g., `flutter_secure_storage`) for session tokens and pending uploads.

### User Experience

- Clear pre-capture instructions (`good lighting`, `remove glasses`, `no hats`).
- Real-time feedback overlays (bounding boxes, smile/blink status) for a user-friendly capture.
- Accessible design: text-to-speech prompts, large buttons, color-contrast compliant.
- Localization support for English, Hausa, Yoruba, Igbo (as required by stakeholders).

### Camera & Sensor Integration

- Use the `camera` plugin or `camerawesome` for fine-grained control (30+ FPS preferred).
- Lock exposure and white balance during capture to avoid drastic frame differences.
- Capture multiple frames per challenge and embed timestamps plus gyroscope readings when available.
- Optional: leverage `sensors_plus` or `flutter_head_pose_detection` for head-movement challenges.

### Face Detection & Tracking

- Choose an on-device SDK: `google_mlkit_face_detection`, `mediapipe`, or a custom TensorFlow Lite model.
- Require: face presence probability, eye openness, head Euler angles, facial landmarks.
- Enforce live face checks by confirming continuous tracking across frames before accepting a challenge.

### Active Liveness Challenges

Implement at least two randomized prompts:

- Blink detection – confirm eye openness variance within 2 seconds.
- Head turn – prompt user to look left/right, validate yaw angle change.
- Optional voice prompt – capture short audio clip and analyze for playback attacks.

An animation/timer should guide the user, and the app must handle retries with friendly messaging.

### Anti-Spoofing Measures

- Texture analysis: run a light-weight CNN to detect screen replays or printed photos.
- Depth cues: leverage dual camera support (where available) or motion parallax checks using accelerometer data.
- Reflection detection: track specular highlights to disqualify flat displays.
- Tamper protection: root/jailbreak detection and screenshot blocking during capture.

### NIN Data Capture

- Input form for NIN and optional scanning of NIN slip/QR (if available).
- Validate NIN format client-side (11 digits) before submission.
- Redact sensitive data immediately after upload, retaining only verification status.

## Backend Integration Points

Even though backend setup is assumed, the app must conform to the following contract:

- **Session API** – `POST /nin-liveness/session` returns session token, challenge script, upload URLs, SLA timers.
- **Upload API** – `PUT /nin-liveness/session/{id}/evidence` accepts multipart payload (JSON metadata + media).
- **Result polling** – `GET /nin-liveness/session/{id}` provides current status and failure reasons.
- **Error taxonomy** – standardized codes (`DEVICE_UNSUPPORTED`, `FACE_NOT_DETECTED`, `NIN_MISMATCH`) for analytics.

## Security & Compliance

- Enforce TLS 1.2+ with certificate pinning to mitigate MITM.
- Store captures only transiently on-device; delete once upload succeeds.
- Obfuscate app binaries (`dart compile aot`, ProGuard/R8) and use Firebase App Check / device attestation.
- Audit trail: log consent, prompts served, result, and device ID (hashed).
- Align with NDPR (Nigeria Data Protection Regulation) and biometric data handling policies.

## Observability & Analytics

- Client metrics: capture rates, challenge retry counts, framerate, lighting score, upload latency.
- Crash reporting: integrate Sentry/Firebase Crashlytics.
- Feature flags: toggle experimental models or thresholds remotely using a config service.

## Testing Strategy

- **Unit tests** – state machine transitions, network client, validators.
- **Widget tests** – instruction flow, permission dialogs, challenge UI.
- **Integration tests** – camera capture mocks using `camera_platform_interface`.
- **Field tests** – verify across representative Nigerian devices, varying network quality, and lighting conditions.
- **Security testing** – penetration tests for replay attacks and API misuse.

## Deployment Checklist

- [ ] Feature flags and rollout plan in place.
- [ ] Backend SLA monitoring configured.
- [ ] Data retention & purge policies documented.
- [ ] Support playbooks for failure scenarios agreed with operations team.
- [ ] Regulatory and legal approvals recorded prior to go-live.

## Next Steps

1. Validate legal/compliance constraints with stakeholders.
2. Choose SDKs/models for detection and anti-spoofing based on internal capability.
3. Prototype the capture flow with mocked backend responses.
4. Conduct pilot testing with real users before full rollout.
