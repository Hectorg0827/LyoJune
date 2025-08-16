# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - YYYY-MM-DD

### Added
- **Initial Project Scaffolding:**
  - Created the complete project directory structure.
  - Set up a `Package.swift` file to define the project for Xcode.
  - Added a `.gitignore` file for Swift projects.
- **Core Architecture & Services:**
  - Implemented a robust, async `HTTPClient` with support for token refresh and exponential backoff.
  - Implemented `AuthService` for handling JWT storage and refresh logic.
  - Created `KeychainStorage` (mocked) for secure token persistence.
- **Design System Primitives:**
  - Created `LoadingSkeleton` view for placeholder content.
  - Created `EmptyStateView` for handling views with no data.
  - Created an `ErrorToast` system for non-intrusive error notifications.
- **CI/CD Workflow:**
  - Created a GitHub Actions workflow (`ci.yml`) to build, test, and archive the application.
  - Added an `ExportOptions.plist` for creating `.ipa` files.
- **Features:**
  - Implemented the UI and ViewModel for the **Authentication** flow (Apple, Google, Meta).
  - Implemented the UI for the multi-step **Onboarding** flow.
- **Testing:**
  - Wrote unit tests for `AuthViewModel`, including mock objects for its dependencies.
  - Wrote a basic UI smoke test to ensure the app launches to the authentication screen.
- **Documentation:**
  - Created `README.md` with setup and configuration instructions.
  - Created this `CHANGELOG.md`.
