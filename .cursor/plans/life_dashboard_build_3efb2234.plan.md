---
name: Life Dashboard Build
overview: "Implement the Life Dashboard end-to-end per the cursor plan: backend prerequisites (FitnessTracker debug auth, VaultTracker port 8001), then a Swift Package macOS SwiftUI app that aggregates both localhost APIs with tested networking, error-isolated panels, and doc sync."
todos:
  - id: task-1-fitness-debug-auth
    content: "Task 1: Add FitnessTracker debug_auth_enabled + security bypass + test_debug_auth.py; run pytest"
    status: pending
  - id: task-2-vault-port
    content: "Task 2: Change VaultTrackerAPI/start.sh to port 8001; bash -n verify"
    status: pending
  - id: task-3-scaffold
    content: "Task 3: Create Swift Package scaffold (Package.swift, LifeDashboardApp, folders); swift build"
    status: pending
  - id: task-4-config
    content: "Task 4: Add APIConfiguration.swift with localhost URLs and debug bearer tokens"
    status: pending
  - id: task-5-models
    content: "Task 5: Add Vault/Fitness/Health Codable models + decode tests (swift test per suite)"
    status: pending
  - id: task-6-networking
    content: "Task 6: Add APIError, APIClient, MockURLProtocol, APIClientTests"
    status: pending
  - id: task-7-clients
    content: "Task 7: Add VaultAPIClient and FitnessAPIClient with listed endpoints"
    status: pending
  - id: task-8-viewmodel
    content: "Task 8: Add DashboardViewModel + tests (parallel fetch, error isolation)"
    status: pending
  - id: task-9-components
    content: "Task 9: Add GlassCard, MetricView, StatusBar per DESIGN.md"
    status: pending
  - id: task-10-panels
    content: "Task 10: Add Fitness/Health/Investments panels + DashboardView; wire app entry"
    status: pending
  - id: task-11-automated-verify
    content: "Task 11: Run swift test + FitnessTracker pytest; fix regressions"
    status: pending
  - id: task-12-manual-integration
    content: "Task 12: Manual localhost integration (both backends, offline isolation)"
    status: pending
  - id: task-13-docs
    content: "Task 13: Sync design doc, tech spec, and local runbook with final implementation"
    status: pending
isProject: false
---

# Life Dashboard Implementation Plan

Derived from `[Documentation/Plans/2026-05-20-life-dashboard-cursor-plan.md](Documentation/Plans/2026-05-20-life-dashboard-cursor-plan.md)`. Authoritative specs: `[Documentation/2026-05-17-life-dashboard-design.md](Documentation/2026-05-17-life-dashboard-design.md)`, `[Documentation/2026-05-20-life-dashboard-tech-spec.md](Documentation/2026-05-20-life-dashboard-tech-spec.md)`, detailed steps in `[Documentation/Plans/2026-05-20-life-dashboard-execution-plan.md](Documentation/Plans/2026-05-20-life-dashboard-execution-plan.md)`.

## Current state


| Area                                | Status                                                                                                                                                                       |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [LifeDashboard](.)                  | Docs + design assets only — **no Swift source**                                                                                                                              |
| [FitnessTracker](../FitnessTracker) | `get_supabase_jwt_claims` in `[fitness-backend/app/core/security.py](../FitnessTracker/fitness-backend/app/core/security.py)` — **no debug bypass**; no `test_debug_auth.py` |
| [VaultTracker](../VaultTracker)     | Debug auth **already exists** (`vaulttracker-debug-user`); `[VaultTrackerAPI/start.sh](../VaultTracker/VaultTrackerAPI/start.sh)` still binds **port 8000**                  |


## Architecture

```mermaid
flowchart LR
  subgraph app [LifeDashboard macOS]
    VM[DashboardViewModel]
    VaultClient[VaultAPIClient]
    FitClient[FitnessAPIClient]
    API[APIClient]
    VM --> VaultClient
    VM --> FitClient
    VaultClient --> API
    FitClient --> API
  end
  subgraph backends [Local FastAPI]
  FT[FitnessTracker :8000]
  VT[VaultTracker :8001]
  end
  API -->|Bearer fitnesstracker-debug-user| FT
  API -->|Bearer vaulttracker-debug-user| VT
```



- **Thin read-only client** — no persistence; backends own data.
- **Parallel fetch** in `DashboardViewModel.refresh()` with **per-domain errors** (`vault`, `fitness`, `health`).
- **Key decoding:** VaultTracker `.useDefaultKeys` (camelCase + explicit keys for snake_case fields); FitnessTracker `.convertFromSnakeCase`.

## Execution constraints (from plan + workspace rules)

- **One task per review checkpoint** unless you explicitly ask to batch.
- **No** reading `.env` files; ask you to confirm env var names/values when needed.
- **No** `pip install` / `npm install`, **no** `git push`; **no commits** unless you request them (plan commit steps = review boundaries).
- **Tests first** for behavior changes (pytest / `swift test`).

## Scaffold choice

**Default: Swift Package** at repo root (`[Package.swift](Package.swift)` + `LifeDashboard/` + `LifeDashboardTests/`), per execution plan. Builds with `swift build` / `swift test`; GUI launch via Xcode opening the package or `swift run` where applicable.

Alternative (`.xcodeproj`) only if you prefer Xcode-native project layout — would change Task 3 file paths only.

---

## Phase 1: Backend prerequisites

### Task 1 — FitnessTracker debug auth

**Goal:** Accept `Authorization: Bearer fitnesstracker-debug-user` only when `DEBUG_AUTH_ENABLED=true`; normal Supabase JWT path unchanged.

**Files:**

- `[FitnessTracker/fitness-backend/app/config.py](../FitnessTracker/fitness-backend/app/config.py)` — add `debug_auth_enabled: bool = False`
- `[FitnessTracker/fitness-backend/app/core/security.py](../FitnessTracker/fitness-backend/app/core/security.py)` — in `get_supabase_jwt_claims`, after `_parse_bearer_token`, before `decode_supabase_access_token`:
  - If `settings.debug_auth_enabled` and `raw == "fitnesstracker-debug-user"`, return synthetic claims (e.g. `sub: "debug-user"`, `aud` from settings, `exp` far future)
- **Create** `FitnessTracker/fitness-backend/tests/unit/test_debug_auth.py` — mirror patterns in `[test_security_dependency.py](../FitnessTracker/fitness-backend/tests/unit/test_security_dependency.py)`

**Test cases:**

- Debug token accepted when enabled
- Debug token rejected when disabled
- Valid JWT still accepted
- Random invalid token still 401

**Verify:**

```bash
cd ../FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_debug_auth.py tests/unit/test_security_dependency.py -v
```

**Local env (you configure):** `DEBUG_AUTH_ENABLED=true` in FitnessTracker `.env` (names only in docs; agent does not open `.env`).

---

### Task 2 — VaultTracker port 8001

**Goal:** Run beside FitnessTracker without port collision.

**File:** `[VaultTracker/VaultTrackerAPI/start.sh](../VaultTracker/VaultTrackerAPI/start.sh)`

**Changes:**

- Echo/docs URL: `localhost:8000` → `localhost:8001`
- Uvicorn: `--port 8000` → `--port 8001`

**Verify:**

```bash
cd ../VaultTracker/VaultTrackerAPI && bash -n start.sh
```

VaultTracker debug auth is already implemented in `[VaultTrackerAPI/app/dependencies.py](../VaultTracker/VaultTrackerAPI/app/dependencies.py)` — no auth code changes.

---

## Phase 2: macOS app (Tasks 3–10)

### Task 3 — Swift Package scaffold

**Create structure:**

```text
Package.swift
LifeDashboard/App/LifeDashboardApp.swift
LifeDashboard/{Configuration,Models,Networking,ViewModels,Views/Components}/
LifeDashboardTests/{Models,Networking,ViewModels}/
```

`**Package.swift`:** macOS 14+, executable target `LifeDashboard`, test target `LifeDashboardTests` (see execution plan snippet ~lines 396–414).

**Entry:** `Text("Life Dashboard")`, min window `1200×800`.

**Verify:** `swift build` from repo root.

---

### Task 4 — API configuration

**Create** `[LifeDashboard/Configuration/APIConfiguration.swift](LifeDashboard/Configuration/APIConfiguration.swift)`:


| Domain  | baseURL                 | authToken                   |
| ------- | ----------------------- | --------------------------- |
| Fitness | `http://localhost:8000` | `fitnesstracker-debug-user` |
| Vault   | `http://localhost:8001` | `vaulttracker-debug-user`   |


**Verify:** `swift build`

---

### Task 5 — Codable models + decode tests

**Models** (payloads from `[2026-05-20-life-dashboard-implementation-plan.md](Documentation/Plans/2026-05-20-life-dashboard-implementation-plan.md)` / tech spec §4–6):

- `VaultModels.swift` — dashboard, net worth, FIRE types; default keys + explicit `CodingKeys` for mixed fields (e.g. `current_value`)
- `FitnessModels.swift` — health check, activities; snake_case decoder
- `HealthModels.swift` — daily/recent/summary health; snake_case decoder

**Tests:** `VaultModelsTests`, `FitnessModelsTests`, `HealthModelsTests` with representative JSON fixtures.

**Verify (incremental):**

```bash
swift test --filter VaultModelsTests
swift test --filter FitnessModelsTests
swift test --filter HealthModelsTests
```

---

### Task 6 — Shared networking

**Create:**

- `APIError.swift` — `invalidResponse`, `unauthorized`, `rateLimited`, `httpError(statusCode:)`, `backendUnavailable`
- `APIClient.swift` — `get(path:queryItems:)`, bearer auth, configurable `JSONDecoder.KeyDecodingStrategy`, `.iso8601` dates, HTTP status mapping
- `MockURLProtocol.swift` + `APIClientTests.swift` — success decode, auth header, query encoding, 401, 429, unavailable

**Verify:** `swift test --filter APIClientTests`

---

### Task 7 — Domain API clients

`**VaultAPIClient`** (`.useDefaultKeys`):

- `/api/v1/dashboard`
- `/api/v1/networth/history?period=...`
- `/api/v1/fire/profile`
- `/api/v1/fire/projection`

`**FitnessAPIClient`** (`.convertFromSnakeCase`):

- `/health`
- `/api/v1/activities/recent`, `/summary`
- `/api/v1/health/today`, `/recent`, `/summary`

**Verify:** `swift build`

---

### Task 8 — DashboardViewModel

**Create:**

- `DashboardViewModel.swift` (`@MainActor`) — `refresh()` with concurrent vault + fitness/health fetches; `DashboardError` ids: `vault`, `fitness`, `health`; `lastRefreshed`
- Protocol or closure injection for clients (no live localhost in tests)
- `DashboardViewModelTests` — all succeed; single-domain failures; both fail; `lastRefreshed` updates

**Verify:** `swift test --filter DashboardViewModelTests`

---

### Task 9 — Shared UI components

Read `[Assets/stitch_unified_life_metrics_dashboard/DESIGN.md](Assets/stitch_unified_life_metrics_dashboard/DESIGN.md)` first.

**Create:**

- `GlassCard` — 16px padding/radius, translucent material, subtle stroke
- `MetricView` — label + monospaced value
- `StatusBar` — last refreshed, loading, refresh action, **Cmd+R**

**Verify:** `swift build`

---

### Task 10 — Panels + layout

**Create:**

- `FitnessPanel` — latest run, weekly summary, streak, empty/error states
- `HealthPanel` — sleep, recovery, strain, provider, empty/error states
- `InvestmentsPanel` — net worth, allocation, FIRE, empty/error states
- `DashboardView` — `StatusBar`, scroll layout, design background, `.task { await viewModel.refresh() }`
- Update `LifeDashboardApp` → `DashboardView`, min `1200×800`

**Verify:** `swift build`

---

## Phase 3: Verification and docs

### Task 11 — Automated verification

```bash
# LifeDashboard
swift test

# FitnessTracker (debug auth)
cd ../FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_debug_auth.py tests/unit/test_security_dependency.py -v
```

Fix failures in the smallest scope of the failing task.

---

### Task 12 — Manual local integration

**You confirm** backend env (e.g. `DEBUG_AUTH_ENABLED` on both APIs) — agent does not read `.env`.

1. Start FitnessTracker on `:8000`, VaultTracker on `:8001`
2. `curl` health + authenticated sample endpoints (per cursor plan §Task 12)
3. Launch app; verify three panels populate or show intentional empty states
4. Kill VaultTracker → investments panel errors only
5. Kill FitnessTracker → fitness/health panels error only

---

### Task 13 — Documentation sync

**Update:**

- `[Documentation/2026-05-17-life-dashboard-design.md](Documentation/2026-05-17-life-dashboard-design.md)` — final ports, auth, data flow
- `[Documentation/2026-05-20-life-dashboard-tech-spec.md](Documentation/2026-05-20-life-dashboard-tech-spec.md)` — resolve draft JWT Option A vs implemented debug auth; final model names, endpoints, decoding strategies
- Add/update root `CLAUDE.md` or runbook — build/test/integration commands; **env var names only**

**Check off** items in cursor plan “Final Done Criteria” when complete.

---

## Suggested first execution step

Start **Task 1** (FitnessTracker debug auth): write failing `test_debug_auth.py`, implement bypass, run pytest, pause for your review.

If you want **Tasks 1–2 batched** (both backend prereqs in one pass), say so before implementation begins.