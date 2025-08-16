# Project Handoff: LyoAppNewUI

**Date:** 2025-08-16
**From:** Jules (AI Software Engineer)
**To:** Lyo Development Team

This document summarizes the current state of the `LyoAppNewUI` iOS project.

## 1. Project Overview

This repository contains a new, production-quality SwiftUI application for Lyo. The project has been scaffolded with a robust and scalable architecture, including a full networking stack, dependency injection, and a foundational design system. The initial Authentication and Onboarding feature has been implemented.

The project is structured as a Swift Package, which can be opened directly in Xcode 15.4+.

## 2. What's Done

*   **Core Architecture:**
    *   **Networking:** A resilient `HTTPClient` with async/await, automatic token refresh, and exponential backoff.
    *   **Authentication:** An `AuthService` manages JWTs, which are stored securely in `KeychainStorage` (currently mocked for the sandbox).
    *   **Dependency Injection:** Services are injected into ViewModels, and protocols are used where appropriate (`HTTPClienting`, `AuthServicing`, `SecureStoring`).
    *   **Project Structure:** The project is organized by feature (`Lyo/Features/*`) and responsibility (`Services`, `Models`, `DesignSystem`, etc.).
*   **Design System:**
    *   Initial primitive components have been created: `LoadingSkeleton`, `EmptyStateView`, and an `ErrorToast` notification system.
*   **Feature: Auth & Onboarding:**
    *   The UI for the main authentication screen (`AuthView`) and the multi-step onboarding flow (`OnboardingContainerView`) has been built.
    *   The `AuthViewModel` has been implemented to handle the logic, including placeholder flows for Google and Meta sign-in and a full implementation for the Apple Sign-In callback.
*   **CI/CD:**
    *   A GitHub Actions workflow (`.github/workflows/ci.yml`) is fully configured to build, run unit tests, and archive the app for release.
*   **Testing:**
    *   Unit tests have been written for `AuthViewModel`, with full mocking of dependencies.
    *   A basic UI smoke test has been written to ensure the app launches successfully.

## 3. What Remains (Next Steps)

The core architecture is in place. The primary remaining work is to implement the other feature modules as specified in the original brief. The recommended order is:

1.  **Learn:** Course List → Overview → Lesson → Practice → Result.
2.  **Tutor:** Tutor chat interface and state management.
3.  **Feed + Composer + Stories:** The main social feed, post creation, and stories.
4.  **Messaging:** 1-on-1 chat with WebSockets.
5.  **Notifications:** The notifications list screen.
6.  **Search & Explore:** Search results and trending content.
7.  **Profile & Settings:** User profiles and application settings.

For each feature, the recommended process is:
- Define Models and Endpoints.
- Implement the Service.
- Implement the ViewModel.
- Build the SwiftUI Views.
- Write unit and UI tests.

## 4. Required Configuration

To run the app against a live backend, the following placeholders must be replaced:

*   **In `Lyo/Config/Config.plist`:**
    *   `LYO_BASE_URL`: The HTTPS base URL for the backend.
    *   `LYO_WS_URL`: The WSS URL for the WebSocket server.
*   **OAuth Credentials:** The project is wired for SSO, but you must provide the actual SDKs and credentials for Google and Meta. This is documented in the `AuthViewModel`.
*   **In `.github/ExportOptions.plist`:**
    *   `teamID` and provisioning profile information must be updated to enable code signing and `.ipa` export in CI.

## 5. Staging Environment

*   **Staging API:** `[Link to Staging API Docs]`
*   **Staging WebSocket:** `[Link to Staging WebSocket Info]`
*   **Test Users:** `[Credentials for Test Accounts]`
