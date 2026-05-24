# Life Dashboard — Implementation Plan

**Date:** 2026-05-20
**Status:** Draft
**Design Doc:** `LifeDashboard/Documentation/2026-05-17-life-dashboard-design.md`
**Tech Spec:** `LifeDashboard/Documentation/2026-05-20-life-dashboard-tech-spec.md`
**Design System:** `LifeDashboard/Assets/stitch_unified_life_metrics_dashboard/DESIGN.md`

---

## Scope

Build the macOS SwiftUI dashboard app that aggregates data from two locally hosted FastAPI backends (VaultTracker + FitnessTracker) into a single read-only dashboard.

**In scope:**
- Add debug auth to FitnessTracker backend (prerequisite)
- Update VaultTracker to run on port 8001 (prerequisite)
- Scaffold, build, and distribute the macOS dashboard app

**Out of scope (already shipped May 20):**
- Strava integration (activities domain — `GET /api/v1/activities/recent`, `/activities/summary`)
- Whoop integration (health domain — `GET /api/v1/health/today`, `/health/recent`, `/health/summary`)

**Approach:** Bottom-up build in dependency order. Each layer is testable before building the next.

---

## Phase 0: Prerequisites

Backend setup required before app development begins.

### 0.1 Add Debug Auth to FitnessTracker

FitnessTracker uses Supabase JWT with no debug bypass. Add one matching VaultTracker's pattern.

**Files to modify:**

**`FitnessTracker/fitness-backend/app/config.py`** — Add config flag:
```python
debug_auth_enabled: bool = False  # Set DEBUG_AUTH_ENABLED=true in .env
```

**`FitnessTracker/fitness-backend/app/core/security.py`** — Add debug bypass to `get_supabase_jwt_claims`:
- Define constants: `_DEBUG_AUTH_TOKEN = "fitnesstracker-debug-user"`, `_DEBUG_USER_ID = "debug-user"`
- Before JWT decode, check: if `settings.debug_auth_enabled` and token matches `_DEBUG_AUTH_TOKEN`, return synthetic claims (`sub: _DEBUG_USER_ID`, `aud: "authenticated"`) without validating
- Otherwise, fall through to existing JWT validation

**`FitnessTracker/fitness-backend/.env`** — Add:
```
DEBUG_AUTH_ENABLED=true
```

**Tests:** Add test in `tests/` that:
- With `DEBUG_AUTH_ENABLED=true`, `Bearer fitnesstracker-debug-user` returns valid claims
- With `DEBUG_AUTH_ENABLED=false`, the same token returns 401
- Real JWT validation still works when debug is enabled but token doesn't match

**Verification:**
```bash
curl -H "Authorization: Bearer fitnesstracker-debug-user" http://localhost:8000/api/v1/users/me
# Should return user object with supabase_id: "debug-user"
```

### 0.2 Update VaultTracker Port

**`VaultTracker/VaultTrackerAPI/start.sh`** — Change `--port 8000` to `--port 8001`.

**Verification:**
```bash
curl http://localhost:8001/
# Should return VaultTracker root response
```

### 0.3 Verify Both Backends

With both backends running on separate ports:

```bash
# FitnessTracker on :8000
curl http://localhost:8000/health
# → {"status": "healthy", "checks": {"database": "connected"}}

# VaultTracker on :8001
curl -H "Authorization: Bearer vaulttracker-debug-user" http://localhost:8001/api/v1/dashboard
# → Portfolio data JSON

# FitnessTracker debug auth
curl -H "Authorization: Bearer fitnesstracker-debug-user" http://localhost:8000/api/v1/users/me
# → User object

# FitnessTracker activities (requires Strava OAuth completed)
curl -H "Authorization: Bearer fitnesstracker-debug-user" http://localhost:8000/api/v1/activities/recent
# → Activities array (or provider_not_configured if Strava creds not set)

# FitnessTracker health (requires Whoop OAuth completed)
curl -H "Authorization: Bearer fitnesstracker-debug-user" http://localhost:8000/api/v1/health/today
# → Health record (or provider_not_configured if Whoop creds not set)
```

---

## Phase 1: Xcode Project Scaffold

### 1.1 Create Xcode Project

- New macOS App project: `LifeDashboard`
- Interface: SwiftUI
- Language: Swift
- Deployment target: macOS 14.0+ (Sonoma)
- Location: `LifeDashboard/` (alongside existing Documentation/)
- Include test target: `LifeDashboardTests`

### 1.2 Folder Structure

Create groups matching the tech spec (Section 9):

```
LifeDashboard/
├── App/
│   └── LifeDashboardApp.swift
├── Configuration/
├── Networking/
├── Models/
├── ViewModels/
└── Views/
```

### 1.3 App Sandbox Configuration

In the Xcode project target:
- Enable App Sandbox
- Check "Outgoing Connections (Client)" — required for localhost HTTP requests
- Uncheck all others (no file access, no camera, etc.)

### 1.4 CLAUDE.md

Create `LifeDashboard/CLAUDE.md` with project conventions, build commands, and architecture notes.

**Verification:** Project builds and runs, showing an empty window.

---

## Phase 2: Configuration Layer

### 2.1 APIConfiguration.swift

Create `LifeDashboard/Configuration/APIConfiguration.swift`:

```swift
enum APIConfiguration {
    enum Fitness {
        static let baseURL = URL(string: "http://localhost:8000")!
        static let authToken = "fitnesstracker-debug-user"
    }

    enum Vault {
        static let baseURL = URL(string: "http://localhost:8001")!
        static let authToken = "vaulttracker-debug-user"
    }
}
```

**Verification:** Compiles. Tokens and URLs accessible from other files.

---

## Phase 3: Codable Models

Models must be defined before the networking layer, since API clients return these types.

### 3.1 VaultModels.swift

Create `LifeDashboard/Models/VaultModels.swift` per tech spec Section 7a:
- `VaultDashboardResponse` (totalNetWorth, categoryTotals, groupedHoldings)
- `CategoryTotals`, `GroupedHoldings`, `Holding`
- `NetWorthHistoryResponse`, `NetWorthSnapshot`
- `FIREProfileResponse`
- `FIREProjectionResponse`, `FIRETargets`, `FIRETarget`, `ProjectionPoint`, `MonthlyBreakdown`, `GoalAssessment`

**Key:** VaultTracker uses camelCase JSON keys. Verify whether `convertFromSnakeCase` handles this or if `CodingKeys` are needed for mixed conventions.

### 3.2 FitnessModels.swift

Create `LifeDashboard/Models/FitnessModels.swift` per tech spec Section 7b:
- `HealthCheckResponse`
- `ActivitiesResponse`, `Activity` (Identifiable)
- `ActivitySummaryResponse`

**Key:** FitnessTracker uses snake_case JSON keys → `convertFromSnakeCase` handles this.

### 3.3 HealthModels.swift

Create `LifeDashboard/Models/HealthModels.swift` per tech spec Section 7b:
- `DailyHealthResponse` (date, provider, sleep, recovery, strain)
- `SleepData`, `RecoveryData`, `StrainData`
- `RecentHealthResponse`
- `HealthSummaryResponse`

### 3.4 Model Validation

Verify models decode correctly by writing tests that decode the sample JSON payloads from the tech spec (Sections 4a, 5b, 5c). These can be simple decode-from-string tests.

**Important:** Before writing models, `curl` each live endpoint and compare the actual response shape against the tech spec. The tech spec was written before Strava/Whoop shipped — response shapes may differ slightly. Adjust models to match actual API responses.

**Verification:** All model decode tests pass against sample and live JSON.

---

## Phase 4: Networking Layer

Build in order: error types → base client → domain clients. API clients reference the model types from Phase 3.

### 4.1 APIError.swift

Create `LifeDashboard/Networking/APIError.swift`:
- `invalidResponse` — non-HTTP response
- `unauthorized` — 401
- `rateLimited` — 429
- `httpError(statusCode: Int)` — other non-2xx
- `backendUnavailable` — connection refused / timeout
- Conform to `LocalizedError` with user-facing descriptions

### 4.2 APIClient.swift

Create `LifeDashboard/Networking/APIClient.swift` per tech spec Section 6a:
- `init(baseURL: URL, authToken: String)`
- `JSONDecoder` with `.convertFromSnakeCase` key strategy and `.iso8601` date strategy
- `func get<T: Decodable>(path:queryItems:) async throws -> T`
- Bearer token injected on every request
- Map HTTP status codes to `APIError` cases
- Wrap `URLError` connection failures as `.backendUnavailable`

### 4.3 VaultAPIClient.swift

Create `LifeDashboard/Networking/VaultAPIClient.swift` per tech spec Section 6b:
- `getDashboard() async throws -> VaultDashboardResponse`
- `getNetWorthHistory(period:) async throws -> NetWorthHistoryResponse`
- `getFireProfile() async throws -> FIREProfileResponse`
- `getFireProjection() async throws -> FIREProjectionResponse`

### 4.4 FitnessAPIClient.swift

Create `LifeDashboard/Networking/FitnessAPIClient.swift` per tech spec Section 6c:
- `checkHealth() async throws -> HealthCheckResponse`
- `getRecentActivities(limit:) async throws -> ActivitiesResponse`
- `getActivitySummary(period:) async throws -> ActivitySummaryResponse`
- `getHealthToday() async throws -> DailyHealthResponse`
- `getHealthRecent(days:) async throws -> RecentHealthResponse`
- `getHealthSummary(days:) async throws -> HealthSummaryResponse`

### 4.5 Networking Tests

Create tests in `LifeDashboardTests/Networking/`:

**APIClientTests.swift:**
- Custom `URLProtocol` subclass that returns canned JSON responses
- Test: successful decode of generic Codable type
- Test: 401 → `APIError.unauthorized`
- Test: 429 → `APIError.rateLimited`
- Test: connection refused → `APIError.backendUnavailable`
- Test: auth header is set correctly

**VaultAPIClientTests.swift:**
- Verify correct URL paths and query parameters for each method
- Verify response decoding with sample JSON from tech spec Section 4a

**FitnessAPIClientTests.swift:**
- Verify correct URL paths and query parameters for each method
- Verify response decoding with sample JSON from tech spec Sections 5b/5c

**Verification:** All networking unit tests pass. No live backend needed for this phase.

---

## Phase 5: ViewModel

### 5.1 DashboardViewModel.swift

Create `LifeDashboard/ViewModels/DashboardViewModel.swift` per tech spec Section 8:

- `@MainActor`, `ObservableObject`
- Published properties for each data domain:
  - `vaultDashboard: VaultDashboardResponse?`
  - `fireProjection: FIREProjectionResponse?`
  - `recentActivities: [Activity]`
  - `activitySummary: ActivitySummaryResponse?`
  - `healthToday: DailyHealthResponse?`
- State: `isLoading`, `errors: [DashboardError]`, `lastRefreshed: Date?`
- `refresh()` — fetches from both backends in parallel via `async let`
- Per-panel error isolation: VaultTracker failure doesn't block fitness/health panels and vice versa

### 5.2 DashboardError

- `.vault(Error)`, `.fitness(Error)`, `.health(Error)`
- Conform to `Identifiable` for SwiftUI presentation

### 5.3 ViewModel Tests

Create `LifeDashboardTests/ViewModels/DashboardViewModelTests.swift`:
- Mock both API clients (protocol-based or closure injection)
- Test: both backends succeed → all published properties populated
- Test: VaultTracker fails → vault properties nil, fitness/health populated, `.vault` error in errors array
- Test: FitnessTracker fails → fitness/health properties empty, vault populated
- Test: both fail → both error types present, `isLoading` returns to false
- Test: `lastRefreshed` updates on each refresh

### 5.4 Integration Smoke Test

With both backends running locally:
- Instantiate real `DashboardViewModel` (not mocked)
- Call `refresh()`
- Verify published properties are populated with real data
- This is a manual test, not automated

**Verification:** Unit tests pass. Manual integration test shows real data flowing through the view model.

---

## Phase 6: Views

UI design follows the design system at `Assets/stitch_unified_life_metrics_dashboard/DESIGN.md`. This phase builds the SwiftUI views to display the data.

### 6.1 App Entry Point

Update `LifeDashboardApp.swift`:
- Create window with fixed minimum size (e.g., 1200×800)
- Instantiate `DashboardViewModel` as `@StateObject`
- Trigger `refresh()` on appear

### 6.2 Dashboard Layout

Create `Views/DashboardView.swift`:
- Three-column or grid layout with panels for Fitness, Health, Investments
- Last refreshed timestamp
- Manual refresh button
- Loading overlay during fetch

### 6.3 Fitness Panel

Create `Views/FitnessPanel.swift`:
- Latest run: distance, pace, date from `recentActivities[0]`
- Weekly summary: total miles, avg pace, total runs from `activitySummary`
- Streak or consistency indicator from `activitySummary.streakDays`

### 6.4 Health Panel

Create `Views/HealthPanel.swift`:
- Sleep: score, total duration (formatted as hours), stage breakdown, efficiency from `healthToday.sleep`
- Recovery: score, resting HR, HRV from `healthToday.recovery`
- Strain: score, active calories from `healthToday.strain`
- Provider indicator (Oura/Whoop) from `healthToday.provider`

### 6.5 Investments Panel

Create `Views/InvestmentsPanel.swift`:
- Net worth (formatted as currency) from `vaultDashboard.totalNetWorth`
- Category breakdown from `vaultDashboard.categoryTotals`
- Top holdings from `vaultDashboard.groupedHoldings`
- FIRE progress from `fireProjection` (target amounts, years to target, status)

### 6.6 Error States

Each panel handles its own error state:
- Backend unavailable → "FitnessTracker is offline" message in panel
- No data (e.g., no Strava activities synced) → "No recent activities" placeholder
- Other panels remain functional

### 6.7 Shared Components

- Formatted number displays (currency, distance, pace, time)
- Section headers consistent with design system
- Glass card containers per design system spec

**Verification:** Launch app with both backends running. All three panels display live data. Kill one backend and verify the other panels still work. Manually refresh and confirm data updates.

---

## Phase 7: Polish & Distribution

### 7.1 Loading States

- Global loading indicator during initial fetch
- Per-panel loading during refresh

### 7.2 Edge Cases

- Both backends down → all panels show error, app doesn't crash
- Strava/Whoop not configured → fitness/health panels show appropriate message
- Empty portfolio → investments panel shows zero state

### 7.3 Archive & Export

- Xcode → Product → Archive
- Export as "Copy App" (locally signed, no notarization)
- Verify exported `.app` launches independently from Xcode
- Verify it fetches data from both backends

### 7.4 Final Verification Checklist

- [ ] VaultTracker on :8001 responds and dashboard displays portfolio data
- [ ] FitnessTracker on :8000 responds and dashboard displays activity data
- [ ] Health panel displays sleep/recovery/strain data
- [ ] One backend down doesn't crash the app
- [ ] Manual refresh re-fetches all panels
- [ ] Exported `.app` runs independently
- [ ] All unit tests pass

---

## Key References

| Resource | Path |
|----------|------|
| Design spec | `LifeDashboard/Documentation/2026-05-17-life-dashboard-design.md` |
| Tech spec (code templates) | `LifeDashboard/Documentation/2026-05-20-life-dashboard-tech-spec.md` |
| Strava API reference | `LifeDashboard/Documentation/2026-05-17-strava-api-reference.md` |
| Wearable API reference | `LifeDashboard/Documentation/2026-05-17-wearable-api-reference.md` |
| UI design system | `LifeDashboard/Assets/stitch_unified_life_metrics_dashboard/DESIGN.md` |
| UI mockup | `LifeDashboard/Assets/stitch_unified_life_metrics_dashboard/screen.png` |
| VaultTracker debug auth | `VaultTracker/VaultTrackerAPI/app/dependencies.py` (pattern to replicate) |
| FitnessTracker auth | `FitnessTracker/fitness-backend/app/core/security.py` (file to modify) |

## Notes

- The tech spec (Sections 5b, 5c) lists Strava/Whoop endpoints as "to be built" — they were shipped May 20 and already exist. Use the live endpoints as-is.
- VaultTracker uses camelCase JSON keys; FitnessTracker uses snake_case. The `APIClient`'s `convertFromSnakeCase` decoder strategy handles FitnessTracker, but VaultTracker models may need explicit `CodingKeys` or a separate decoder. Verify during Phase 3.
- Both backends are local-only. CORS doesn't apply to native macOS `URLSession` requests (no Origin header sent). No CORS changes needed.
- Rate limits (100/min read on FitnessTracker, 60/min on VaultTracker) are not a concern for a single-user dashboard doing ~5 reads per refresh.
