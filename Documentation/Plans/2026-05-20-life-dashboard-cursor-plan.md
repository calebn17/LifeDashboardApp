# Life Dashboard Cursor Plan

> **For agentic workers:** Execute one task at a time. After each task, run the listed verification, summarize the diff, update task status, and pause for review before starting the next task unless the user explicitly asks to batch work.

**Goal:** Build a native macOS SwiftUI dashboard that reads from local VaultTracker and FitnessTracker FastAPI backends and displays investments, fitness, and health in one read-only app.

**Source Plan:** `Documentation/Plans/2026-05-20-life-dashboard-implementation-plan.md`

**Architecture:** Keep the dashboard as a thin local aggregation client. FitnessTracker remains the source of truth for activities and wearable health on `localhost:8000`; VaultTracker remains the source of truth for investments and FIRE projections on `localhost:8001`. The SwiftUI app uses a shared `APIClient`, domain clients, a single `DashboardViewModel`, and error-isolated panels.

**Tech Stack:** SwiftUI, Swift concurrency, URLSession, XCTest, FastAPI, pytest.

---

## Cursor Execution Rules

- Do not read, search, print, or summarize `.env` files. If an env value is needed, ask the user for explicit permission and prefer documented variable names only.
- Do not install dependencies and do not run `git push`.
- Do not commit unless the user explicitly asks. The source execution plan includes commit checkpoints; treat those as review boundaries unless commit permission is granted.
- Before backend edits, confirm the sibling repository paths exist:
  - `/Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker`
  - `/Users/calebngai/Desktop/Agentic-Engineering-Projects/VaultTracker`
- For each task, prefer tests first where behavior changes. Keep each task small enough to be reviewed as one logical commit.

---

## Todo Checklist

- [x] **Task 1: Add FitnessTracker Debug Auth** — Add tested local debug auth bypass without weakening normal Supabase JWT validation.
- [x] **Task 2: Move VaultTracker to Port 8001** — Update startup script so VaultTracker can run beside FitnessTracker.
- [x] **Task 3: Scaffold the macOS Dashboard Project** — Create a buildable SwiftUI app scaffold with tests wired.
- [x] **Task 4: Add Local API Configuration** — Centralize localhost URLs and debug bearer tokens.
- [ ] **Task 5: Add Codable Models and Decode Tests** — Define Vault, activity, and health models with representative decode coverage.
- [ ] **Task 6: Add Shared Networking Layer** — Add tested URLSession client, auth injection, decoding, and HTTP error mapping.
- [ ] **Task 7: Add Domain API Clients** — Wrap VaultTracker and FitnessTracker endpoints in typed clients.
- [ ] **Task 8: Add Dashboard ViewModel** — Fetch domains concurrently with loading state and per-domain error isolation.
- [ ] **Task 9: Build Shared Dashboard UI Components** — Add glass cards, metric display, and refresh status controls.
- [ ] **Task 10: Build Dashboard Panels and Layout** — Render investments, fitness, and health panels with empty/error states.
- [ ] **Task 11: Run Automated Verification** — Run all touched-stack tests and fix regressions.
- [ ] **Task 12: Manual Local Integration** — Verify live localhost backend behavior and offline-backend isolation.
- [ ] **Task 13: Documentation and Runbook Sync** — Update design docs, tech spec, and durable verification commands.

---

## File Map

### FitnessTracker Backend

| Action | File | Responsibility |
|---|---|---|
| Modify | `FitnessTracker/fitness-backend/app/config.py` | Add `debug_auth_enabled` setting |
| Modify | `FitnessTracker/fitness-backend/app/core/security.py` | Add debug bearer token bypass |
| Create | `FitnessTracker/fitness-backend/tests/unit/test_debug_auth.py` | Validate debug auth on/off behavior |

### VaultTracker Backend

| Action | File | Responsibility |
|---|---|---|
| Modify | `VaultTracker/VaultTrackerAPI/start.sh` | Run VaultTracker API on port `8001` |

### LifeDashboard App

| Action | File | Responsibility |
|---|---|---|
| Create | `Package.swift` or Xcode project | Project scaffold |
| Create | `LifeDashboard/App/LifeDashboardApp.swift` | App entry point and window setup |
| Create | `LifeDashboard/Configuration/APIConfiguration.swift` | Local backend URLs and debug tokens |
| Create | `LifeDashboard/Models/VaultModels.swift` | VaultTracker Codable models |
| Create | `LifeDashboard/Models/FitnessModels.swift` | Activity Codable models |
| Create | `LifeDashboard/Models/HealthModels.swift` | Wearable health Codable models |
| Create | `LifeDashboard/Networking/APIError.swift` | Shared HTTP error model |
| Create | `LifeDashboard/Networking/APIClient.swift` | Shared URLSession client |
| Create | `LifeDashboard/Networking/VaultAPIClient.swift` | VaultTracker endpoint wrapper |
| Create | `LifeDashboard/Networking/FitnessAPIClient.swift` | FitnessTracker endpoint wrapper |
| Create | `LifeDashboard/ViewModels/DashboardViewModel.swift` | Parallel refresh and error isolation |
| Create | `LifeDashboard/Views/**` | Dashboard layout, panels, and shared UI components |
| Create | `LifeDashboardTests/**` | Decode, networking, and view-model tests |

---

## Task 1: Add FitnessTracker Debug Auth

**Outcome:** FitnessTracker accepts `Authorization: Bearer fitnesstracker-debug-user` only when `DEBUG_AUTH_ENABLED=true`, while normal Supabase JWT validation still works.

**Files:**
- Modify: `FitnessTracker/fitness-backend/app/config.py`
- Modify: `FitnessTracker/fitness-backend/app/core/security.py`
- Create: `FitnessTracker/fitness-backend/tests/unit/test_debug_auth.py`

**Steps:**
- [ ] Read `app/config.py`, `app/core/security.py`, and nearby security tests. Do not open `.env`.
- [ ] Add tests covering debug token accepted when enabled, rejected when disabled, valid JWT still accepted, and random invalid token still rejected.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_debug_auth.py -v
  ```
  Expected before implementation: fails because the setting/bypass does not exist.
- [ ] Add `debug_auth_enabled: bool = False` to settings.
- [ ] Add constants `_DEBUG_AUTH_TOKEN = "fitnesstracker-debug-user"` and `_DEBUG_USER_ID = "debug-user"` in `app/core/security.py`.
- [ ] In `get_supabase_jwt_claims`, after parsing the bearer token and before JWT decoding, return synthetic claims when debug auth is enabled and the raw token matches.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_debug_auth.py tests/unit/test_security_dependency.py -v
  ```
  Expected after implementation: all tests pass.

**Review checkpoint:** Summarize the backend auth diff and test output, then pause.

---

## Task 2: Move VaultTracker to Port 8001

**Outcome:** VaultTracker can run beside FitnessTracker without both trying to bind `localhost:8000`.

**Files:**
- Modify: `VaultTracker/VaultTrackerAPI/start.sh`

**Steps:**
- [ ] Read `VaultTracker/VaultTrackerAPI/start.sh`.
- [ ] Change the startup echo/docs URL from `localhost:8000` to `localhost:8001`.
- [ ] Change the uvicorn port from `--port 8000` to `--port 8001`.
- [ ] Verify the script syntax by reading the final file and, if appropriate, running a non-mutating shell syntax check:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/VaultTracker/VaultTrackerAPI && bash -n start.sh
  ```
  Expected: no output and exit code `0`.

**Review checkpoint:** Summarize the port-only diff, then pause.

---

## Task 3: Scaffold the macOS Dashboard Project

**Outcome:** `LifeDashboard` has a buildable SwiftUI app scaffold with tests wired.

**Files:**
- Create: `Package.swift` or `LifeDashboard.xcodeproj`
- Create: `LifeDashboard/App/LifeDashboardApp.swift`
- Create: `LifeDashboardTests/`

**Steps:**
- [ ] Check whether the user wants a Swift Package scaffold or an Xcode `.xcodeproj`. If no preference is given, use the Swift Package scaffold from `Documentation/Plans/2026-05-20-life-dashboard-execution-plan.md`.
- [ ] Create folders:
  ```text
  LifeDashboard/App
  LifeDashboard/Configuration
  LifeDashboard/Models
  LifeDashboard/Networking
  LifeDashboard/ViewModels
  LifeDashboard/Views/Components
  LifeDashboardTests/Models
  LifeDashboardTests/Networking
  LifeDashboardTests/ViewModels
  ```
- [ ] Add a minimal SwiftUI app entry point that renders `Text("Life Dashboard")` with a minimum window size of `1200x800`.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build
  ```
  Expected: build succeeds.

**Review checkpoint:** Summarize scaffold files and build output, then pause.

---

## Task 4: Add Local API Configuration

**Outcome:** The app has one source for localhost base URLs and debug bearer tokens.

**Files:**
- Create: `LifeDashboard/Configuration/APIConfiguration.swift`

**Steps:**
- [ ] Add `APIConfiguration.Fitness.baseURL = http://localhost:8000`.
- [ ] Add `APIConfiguration.Fitness.authToken = "fitnesstracker-debug-user"`.
- [ ] Add `APIConfiguration.Vault.baseURL = http://localhost:8001`.
- [ ] Add `APIConfiguration.Vault.authToken = "vaulttracker-debug-user"`.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build
  ```
  Expected: build succeeds.

**Review checkpoint:** Summarize config choices and build output, then pause.

---

## Task 5: Add Codable Models and Decode Tests

**Outcome:** Vault, activity, and health API responses decode against representative payloads before networking is added.

**Files:**
- Create: `LifeDashboard/Models/VaultModels.swift`
- Create: `LifeDashboard/Models/FitnessModels.swift`
- Create: `LifeDashboard/Models/HealthModels.swift`
- Create: `LifeDashboardTests/Models/VaultModelsTests.swift`
- Create: `LifeDashboardTests/Models/FitnessModelsTests.swift`
- Create: `LifeDashboardTests/Models/HealthModelsTests.swift`

**Steps:**
- [ ] Write VaultTracker decode tests from the implementation plan payloads. Use default keys for camelCase, with explicit coding keys for mixed fields like `current_value`.
- [ ] Add `VaultDashboardResponse`, `CategoryTotals`, `Holding`, `NetWorthHistoryResponse`, `NetWorthSnapshot`, `FIREProfileResponse`, and `FIREProjectionResponse` family types.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter VaultModelsTests
  ```
  Expected: tests pass.
- [ ] Write FitnessTracker activity decode tests using `convertFromSnakeCase`.
- [ ] Add `HealthCheckResponse`, `ActivitiesRecentResponse`, `Activity`, and `ActivitySummaryResponse`.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter FitnessModelsTests
  ```
  Expected: tests pass.
- [ ] Write health decode tests using `convertFromSnakeCase`.
- [ ] Add `DailyHealthResponse`, `SleepData`, `RecoveryData`, `StrainData`, `HealthRecentResponse`, and `HealthSummaryResponse`.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter HealthModelsTests
  ```
  Expected: tests pass.

**Review checkpoint:** Summarize model coverage, any schema mismatches discovered, and test output, then pause.

---

## Task 6: Add Shared Networking Layer

**Outcome:** The app has a tested URLSession wrapper that injects auth, decodes JSON, maps common HTTP errors, and supports different key decoding strategies.

**Files:**
- Create: `LifeDashboard/Networking/APIError.swift`
- Create: `LifeDashboard/Networking/APIClient.swift`
- Create: `LifeDashboardTests/Networking/MockURLProtocol.swift`
- Create: `LifeDashboardTests/Networking/APIClientTests.swift`

**Steps:**
- [ ] Write `MockURLProtocol` and `APIClientTests` for successful decode, auth header injection, query item encoding, `401`, `429`, and backend unavailable behavior.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter APIClientTests
  ```
  Expected before implementation: compile failure for missing networking types.
- [ ] Add `APIError` with `invalidResponse`, `unauthorized`, `rateLimited`, `httpError(statusCode:)`, and `backendUnavailable`.
- [ ] Add `APIClient.get(path:queryItems:)` using URLSession, bearer auth, configurable `JSONDecoder.KeyDecodingStrategy`, `.iso8601` dates, and explicit HTTP status mapping.
- [ ] Run the same `swift test --filter APIClientTests`.
  Expected after implementation: all tests pass.

**Review checkpoint:** Summarize networking behavior and test output, then pause.

---

## Task 7: Add Domain API Clients

**Outcome:** VaultTracker and FitnessTracker endpoints are represented by small typed clients.

**Files:**
- Create: `LifeDashboard/Networking/VaultAPIClient.swift`
- Create: `LifeDashboard/Networking/FitnessAPIClient.swift`

**Steps:**
- [ ] Add `VaultAPIClient` using `.useDefaultKeys` and endpoints:
  - `/api/v1/dashboard`
  - `/api/v1/networth/history?period=...`
  - `/api/v1/fire/profile`
  - `/api/v1/fire/projection`
- [ ] Add `FitnessAPIClient` using `.convertFromSnakeCase` and endpoints:
  - `/health`
  - `/api/v1/activities/recent?limit=...`
  - `/api/v1/activities/summary?period=...`
  - `/api/v1/health/today`
  - `/api/v1/health/recent?days=...`
  - `/api/v1/health/summary?days=...`
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build
  ```
  Expected: build succeeds.

**Review checkpoint:** Summarize client endpoints and build output, then pause.

---

## Task 8: Add Dashboard ViewModel

**Outcome:** A single main-actor view model refreshes all panels, keeps loading state accurate, and isolates errors by domain.

**Files:**
- Create: `LifeDashboard/ViewModels/DashboardViewModel.swift`
- Create: `LifeDashboardTests/ViewModels/DashboardViewModelTests.swift`

**Steps:**
- [ ] Introduce protocols or closure-based injection for `VaultAPIClient` and `FitnessAPIClient` before writing tests. Avoid tests that depend on live localhost services.
- [ ] Write tests for:
  - all domains succeeding populates published properties
  - Vault failure leaves fitness and health populated
  - fitness activity failure leaves investments and health populated
  - health failure leaves investments and fitness populated
  - both clients failing clears loading and records errors
  - `lastRefreshed` updates after refresh completes
- [ ] Add `DashboardError` with stable ids: `vault`, `fitness`, `health`.
- [ ] Add `DashboardViewModel.refresh()` that starts both backend groups concurrently and records partial results.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter DashboardViewModelTests
  ```
  Expected: all tests pass.

**Review checkpoint:** Summarize concurrency/error-isolation behavior and test output, then pause.

---

## Task 9: Build Shared Dashboard UI Components

**Outcome:** Reusable SwiftUI components express the design system's dark glassmorphism style.

**Files:**
- Create: `LifeDashboard/Views/Components/GlassCard.swift`
- Create: `LifeDashboard/Views/Components/MetricView.swift`
- Create: `LifeDashboard/Views/Components/StatusBar.swift`

**Steps:**
- [ ] Read `Assets/stitch_unified_life_metrics_dashboard/DESIGN.md` before editing.
- [ ] Add `GlassCard` with 16px padding, 16px corner radius, translucent material/fill, and subtle stroke.
- [ ] Add `MetricView` for compact label/value metrics using monospaced numeric styling.
- [ ] Add `StatusBar` with last refreshed timestamp, loading state, refresh action, and Cmd+R shortcut.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build
  ```
  Expected: build succeeds.

**Review checkpoint:** Summarize design-system mapping and build output, then pause.

---

## Task 10: Build Dashboard Panels and Layout

**Outcome:** The app displays fitness, health, and investments with per-panel empty/error states and manual refresh.

**Files:**
- Create: `LifeDashboard/Views/FitnessPanel.swift`
- Create: `LifeDashboard/Views/HealthPanel.swift`
- Create: `LifeDashboard/Views/InvestmentsPanel.swift`
- Create: `LifeDashboard/Views/DashboardView.swift`
- Modify: `LifeDashboard/App/LifeDashboardApp.swift`

**Steps:**
- [ ] Add `FitnessPanel` with latest run, weekly summary, streak, empty state, and fitness error state.
- [ ] Add `HealthPanel` with sleep, recovery, strain, provider, empty state, and health error state.
- [ ] Add `InvestmentsPanel` with net worth, allocation, FIRE progress, empty state, and vault error state.
- [ ] Add `DashboardView` with `StatusBar`, scrollable layout, design-system background, and `.task { await refresh() }`.
- [ ] Update `LifeDashboardApp` to show `DashboardView` with minimum size `1200x800`.
- [ ] Run:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build
  ```
  Expected: build succeeds.

**Review checkpoint:** Summarize UI behavior and build output, then pause.

---

## Task 11: Run Automated Verification

**Outcome:** All automated checks for touched stacks pass before manual integration.

**Files:**
- No source changes expected unless fixing failures.

**Steps:**
- [ ] Run LifeDashboard tests:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test
  ```
  Expected: all tests pass.
- [ ] Run FitnessTracker unit tests touched by debug auth:
  ```bash
  cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_debug_auth.py tests/unit/test_security_dependency.py -v
  ```
  Expected: all tests pass.
- [ ] If failures occur, apply the smallest fix in the relevant previous task area and rerun the failed check.

**Review checkpoint:** Summarize final automated verification and any fixes, then pause.

---

## Task 12: Manual Local Integration

**Outcome:** The dashboard works against both local backends and handles one backend being offline.

**Files:**
- No source changes expected unless fixing integration failures.

**Steps:**
- [ ] Ask the user to confirm required local backend env vars are configured. Do not inspect `.env`.
- [ ] Start FitnessTracker on `localhost:8000`.
- [ ] Start VaultTracker on `localhost:8001`.
- [ ] Verify health endpoints with `curl`:
  ```bash
  curl http://localhost:8000/health
  curl -H "Authorization: Bearer fitnesstracker-debug-user" http://localhost:8000/api/v1/users/me
  curl -H "Authorization: Bearer vaulttracker-debug-user" http://localhost:8001/api/v1/dashboard
  ```
- [ ] Launch the app from Xcode or the selected Swift build workflow.
- [ ] Verify investments data renders.
- [ ] Verify fitness data renders or shows an intentional no-data/provider-not-configured state.
- [ ] Verify health data renders or shows an intentional no-data/provider-not-configured state.
- [ ] Kill VaultTracker and verify only the investments panel shows an error.
- [ ] Kill FitnessTracker and verify only the fitness/health panels show errors.

**Review checkpoint:** Summarize manual integration results and any follow-up fixes, then pause.

---

## Task 13: Documentation and Runbook Sync

**Outcome:** The design docs and local runbook match the implemented app behavior and verification commands.

**Files:**
- Modify: `Documentation/2026-05-17-life-dashboard-design.md`
- Modify: `Documentation/2026-05-20-life-dashboard-tech-spec.md`
- Create or modify: `CLAUDE.md` or a local runbook if the app scaffold includes one

**Steps:**
- [ ] Update the system design doc with final implemented architecture, port assignments, auth behavior, and dashboard data flow.
- [ ] Update the tech spec with final model names, endpoint paths, key decoding strategies, and known local-only assumptions.
- [ ] Add a concise local runbook with build, test, and manual integration commands. Include env var names only, never values.
- [ ] Run relevant markdown/readback checks available in the repo. If none exist, read the edited sections for consistency.

**Review checkpoint:** Summarize documentation updates and verification, then pause.

---

## Final Done Criteria

- [ ] FitnessTracker debug auth is tested and only active behind `DEBUG_AUTH_ENABLED`.
- [ ] VaultTracker runs on `localhost:8001`.
- [ ] LifeDashboard builds and tests pass.
- [ ] The dashboard fetches from both local backends.
- [ ] Each panel handles missing data and backend errors independently.
- [ ] Manual refresh re-fetches all dashboard domains.
- [ ] Architecture docs and runbook commands match the final implementation.
