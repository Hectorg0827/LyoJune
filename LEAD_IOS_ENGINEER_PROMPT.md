# [MASTER PROMPT] For Lead iOS Engineer: Comprehensive Architectural Refactoring & Modernization of the LyoApp

**Project:** LyoApp - AI Learning Assistant (Native iOS - Swift/SwiftUI)

## Overall Mandate

You are tasked with leading a comprehensive architectural refactoring and modernization of the LyoApp Swift codebase. The primary objective is to resolve deep-seated architectural issues that have caused persistent build failures, as documented in the provided markdown files (DUPLICATE_CLASSES_RESOLVED.md, PERMANENT_API_SOLUTION_COMPLETE.md). The end goal is a stable, scalable, and maintainable application with a modern user experience, ready for production.

The work is divided into four distinct, prioritized phases.

## Phase 1: Architectural Stabilization & Core Refactoring (Highest Priority)

**Objective:** To completely resolve the build instability by dismantling the current anti-pattern and implementing a clean, professional architecture. This phase is critical and must be completed before any UI enhancements or new features are developed.

### Task 1: Eradicate the "Self-Contained Service" Anti-Pattern

**Problem:** The current "permanent solution," where each service file contains its own embedded APIClientProtocol, clients, and models, has solved compilation order errors by introducing massive code duplication. This architecture is unsustainable, difficult to maintain, and a significant source of future bugs.

**Action Plan:**

1. **Create a Shared Core Network Module:**
   - Create a single, definitive `APIProtocol.swift` file (e.g., in `/Core/Networking/Protocols/`). This file will contain the `APIClientProtocol` and the `HTTPMethod` enum.
   - Create a single, definitive `APIClient.swift` (in `/Core/Networking/`) for the production network client that conforms to `any APIClientProtocol`.
   - Create a single, definitive `MockAPIClient.swift` for mock data and testing.
   - Centralize all shared request/response models into their own files (e.g., `/Core/Models/CourseModels.swift`, `/Core/Models/UserModels.swift`). Files like `APIModels.swift` and `EnhancedLearningModels.swift` are good starting points for this consolidation.

2. **Refactor All Services:** Go through every service file (`ReelsService.swift`, `LearningService.swift`, etc.) and remove all duplicated, embedded protocol, client, and model code.

3. **Dependency Injection:** Update each service's initializer to depend on the centralized `any APIClientProtocol`, not its own local version.

### Task 2: Verify Xcode Target Membership (The Critical Missing Step)

**Problem:** The original "Cannot find type in scope" errors were likely caused by the shared protocol and model files not being correctly included in the main app target, which prevented the compiler from "seeing" them before compiling the services.

**Action Plan:**

1. In Xcode, select every file created in Task 1 (`APIProtocol.swift`, `APIClient.swift`, etc.).
2. Open the File Inspector (right-hand sidebar).
3. Under Target Membership, ensure the checkbox next to your main "LyoApp" target is checked. This is the true permanent fix for the protocol scoping issues.

### Task 3: Consolidate Configuration

**Problem:** The file `DEVELOPMENTCONFIG_REDECLARATION_FIXED.md` indicates there were multiple, conflicting `DevelopmentConfig` structs. The fix was to centralize this, which is correct.

**Action Plan:**

1. Confirm that there is only one `DevelopmentConfig.swift` file in the project, serving as the single source of truth for all configuration flags (like `useMockData` and `backendURL`).
2. Ensure all services and clients reference this single, shared configuration file.

## Phase 2: UI/UX Modernization & Polish (SwiftUI Focus)

**Objective:** To elevate the app's look and feel to compete with modern applications.

### Task 4: Implement Modern Loading States

**Problem:** Standard `ProgressView` loaders can feel dated.

**Action Plan:**

1. Implement **Skeleton Loaders** using SwiftUI. Create shimmering placeholder views that mimic the shape of the content that is about to load. This can be done by creating a `.redacted(reason: .placeholder)` view modifier combined with a shimmering animation.
2. Apply these skeleton loaders to all data-driven views, such as course lists, user profiles, and feed screens.

### Task 5: Enhance Animations, Transitions, and Feedback

**Problem:** A static UI feels less engaging than a dynamic one.

**Action Plan:**

1. **SwiftUI Animations:** Use `withAnimation { ... }` blocks to create fluid state transitions. Animate changes in data, layout, and visibility.
2. **Custom Transitions:** Implement custom `AnyTransition` for more sophisticated screen presentations and dismissals, especially for modal sheets and navigation links.
3. **Haptic Feedback:** Use `UIImpactFeedbackGenerator` to provide subtle haptic feedback on key user interactions like button taps, successful data submissions, or completing a lesson.

## Phase 3: Feature Completeness & Backend Integration

**Objective:** To move the app from a prototype to a fully functional, data-driven product.

### Task 6: Complete API Endpoint Integration

**Problem:** The project documentation indicates several missing API methods and response types that were recently fixed.

**Action Plan:**

1. Systematically review every feature in the UI and ensure it is connected to the corresponding method in the newly refactored service layer (e.g., `CourseService`, `LearningService`).
2. Replace all remaining mock data logic (e.g., `if DevelopmentConfig.useMockData`) with live network requests to a staging backend.
3. Implement robust error handling in the UI for failed network requests (e.g., show an alert or a "retry" view).

### Task 7: Bolster Social & EdTech Features

**Problem:** Core features need more depth to be competitive.

**Action Plan:**

1. **Real-time Features:** For features like study group chat or live feed updates, architect a solution using WebSockets. The Swift URLSession has native support for WebSocket tasks.
2. **Interactive Content:** Plan for and build SwiftUI views that can render more than just text and images. This could involve using `AVPlayerViewController` for video or creating custom views for interactive quizzes.

## Phase 4: Production Readiness

**Objective:** To ensure the app is robust, testable, and maintainable for long-term success.

### Task 8: Establish a Formal SwiftUI Design System

**Problem:** Ad-hoc styling leads to an inconsistent UI.

**Action Plan:**

1. Create a centralized `Theme.swift` file to define shared colors, fonts, and spacing constants.
2. Develop a library of reusable SwiftUI components (e.g., `PrimaryButton`, `InfoCard`, `FormField`) that use these theme constants. This will enforce a consistent design language.

### Task 9: Implement a Comprehensive Testing Strategy

**Problem:** A professional app must be thoroughly tested.

**Action Plan:**

1. **Unit Tests (XCTest):** Write unit tests for all business logic in your services and view models.
2. **UI Tests (XCTest):** Create UI tests to automate user flows, verify that UI elements are present, and confirm that the app state changes correctly in response to user interaction.

### Task 10: Set Up a CI/CD Pipeline

**Problem:** Manual builds and deployments are slow and error-prone.

**Action Plan:**

1. Configure a Continuous Integration service (like Xcode Cloud or GitHub Actions) to automatically build the project and run all tests on every pull request.
2. Set up Continuous Deployment to automatically submit builds to TestFlight for beta testing.

## Final Deliverables

1. A stable, refactored Swift codebase with a clean, single-source-of-truth network layer.
2. An application fully integrated with a live backend API, with all mock data logic removed for production builds.
3. A polished and modern SwiftUI interface incorporating skeleton loaders and fluid animations.
4. A comprehensive suite of unit and UI tests ensuring application stability.
5. Updated documentation outlining the new architecture and build process.

## Environment Configuration

The project includes a comprehensive `.env` file with the following configuration structure:

```properties
# Backend Configuration
BACKEND_BASE_URL=https://api.lyo.app/v1
BACKEND_WS_URL=wss://api.lyo.app/v1/ws

# Authentication Configuration  
JWT_SECRET_KEY=your_jwt_secret_key_here
API_KEY=your_api_key_here

# AI Service Configuration
GEMMA_API_KEY=your_gemma_api_key_here
GEMMA_API_ENDPOINT=https://api.google.com/gemma/v1/generate
OPENAI_API_KEY=your_openai_api_key_here
CLAUDE_API_KEY=your_claude_api_key_here

# Development Settings
DEBUG_MODE=true
MOCK_BACKEND=false
LOG_LEVEL=debug
```

Ensure that the centralized configuration manager properly reads from this `.env` file and provides a clean interface for accessing these values throughout the application.

## Current Project State

The project currently has the following structure:

- Core services are located in `LyoApp/Core/Services/`
- Models are located in `LyoApp/Core/Models/`
- Network layer is in `LyoApp/Core/Networking/`
- UI components are in `LyoApp/Features/`

All services have been updated with singleton patterns and the duplicate symbolic links have been removed from the project root. The Xcode project file has been cleaned up to ensure proper file references and group organization.

## Priority Order

1. **Phase 1 must be completed first** - This resolves the architectural instability
2. **Phases 2-4 can be approached in parallel** once Phase 1 is complete
3. **Testing should be integrated throughout** all phases, not just at the end

## Success Metrics

- [ ] Project builds without errors or warnings
- [ ] All services use a single, shared API client protocol
- [ ] No duplicate model or protocol definitions exist
- [ ] UI loads quickly with modern skeleton loaders
- [ ] All features are connected to live backend APIs
- [ ] Comprehensive test coverage (>80% for critical paths)
- [ ] CI/CD pipeline successfully builds and deploys

---

*This document serves as the master plan for the LyoApp refactoring project. Each phase should be completed thoroughly before moving to the next, with regular check-ins to ensure architectural decisions align with the overall vision.*
