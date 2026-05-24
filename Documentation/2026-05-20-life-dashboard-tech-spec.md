# Life Dashboard — Technical Specification

**Date:** 2026-05-20 (UI revamp: 2026-05-24)
**Status:** Implemented (V1 local dashboard + Premium Dark Cockpit UI)
**Design Doc:** `LifeDashboard/2026-05-17-life-dashboard-design.md`

---

## 1. Overview

A native macOS SwiftUI app that aggregates data from two locally hosted FastAPI backends — **VaultTracker** (investment portfolio) and **FitnessTracker** (running + wearable health data) — into a single read-only dashboard.

Both backends run on `localhost`. The dashboard fetches from them via `URLSession` + `async/await`. No persistence, no caching — backends are the source of truth.

---

## 2. Port Configuration

Both backends currently default to port `8000`. They must run on separate ports.

| Backend | Port | Base URL |
|---------|------|----------|
| FitnessTracker | `8000` | `http://localhost:8000` |
| VaultTracker | `8001` | `http://localhost:8001` |

### VaultTracker Port Change

VaultTracker's `start.sh` hardcodes port 8000:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Change required:** Update `start.sh` (or add a `PORT` env var) to run on `8001`. VaultTracker's CORS config at `app/config.py` already allows comma-separated origins via `ALLOWED_ORIGINS` env var — add `http://localhost:8001` if Swagger UI is needed on the new port.

FitnessTracker stays on `8000` (its default in the Makefile `make dev` command).

---

## 3. Authentication

The two backends use different auth systems. The dashboard needs to handle both.

### 3a. VaultTracker — Debug Auth

VaultTracker supports a debug auth mode for local development.

| Setting | Value |
|---------|-------|
| Env var | `DEBUG_AUTH_ENABLED=true` (in VaultTracker's `.env`) |
| Header | `Authorization: Bearer vaulttracker-debug-user` |
| Behavior | Bypasses Firebase JWT verification; maps to fixed `firebase_id: "debug-user"` |

The dashboard sends this static Bearer token on every VaultTracker request. No token refresh needed.

### 3b. FitnessTracker — Debug Auth (implemented)

FitnessTracker supports local debug auth (same pattern as VaultTracker) when `DEBUG_AUTH_ENABLED=true`.

| Setting | Value |
|---------|-------|
| Env var | `DEBUG_AUTH_ENABLED=true` (FitnessTracker `.env`) |
| Header | `Authorization: Bearer fitnesstracker-debug-user` |
| Behavior | Bypasses Supabase JWT decode; synthetic claims `sub: "debug-user"` |

Production paths still use Supabase HS256 JWT validation when debug auth is disabled.

### 3c. APIConfiguration.swift

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

---

## 4. VaultTracker API Integration

VaultTracker's dashboard-relevant endpoints are **already built and functional**.

### 4a. Endpoints

#### GET /api/v1/dashboard

Returns current portfolio snapshot.

**Headers:** `Authorization: Bearer vaulttracker-debug-user`

**Response:**
```json
{
  "totalNetWorth": 150000.00,
  "categoryTotals": {
    "crypto": 25000.00,
    "stocks": 60000.00,
    "cash": 15000.00,
    "realEstate": 0.00,
    "retirement": 50000.00
  },
  "groupedHoldings": {
    "crypto": [
      {
        "id": "uuid",
        "name": "Bitcoin",
        "symbol": "BTC",
        "quantity": 0.5,
        "current_value": 25000.00
      }
    ],
    "stocks": [...],
    "cash": [...],
    "realEstate": [...],
    "retirement": [...]
  }
}
```

#### GET /api/v1/networth/history?period={period}

Returns historical net worth snapshots.

**Query params:** `period` — `"all"` | `"daily"` | `"weekly"` | `"monthly"` (default: `"daily"`)

**Response:**
```json
{
  "snapshots": [
    { "date": "2026-05-01T00:00:00", "value": 148000.00 },
    { "date": "2026-05-02T00:00:00", "value": 149200.00 }
  ]
}
```

#### GET /api/v1/fire/profile

Returns FIRE profile inputs.

**Response:**
```json
{
  "id": "uuid",
  "currentAge": 28,
  "annualIncome": 120000.00,
  "annualExpenses": 60000.00,
  "targetRetirementAge": 45,
  "createdAt": "2026-01-01T00:00:00",
  "updatedAt": "2026-05-15T00:00:00"
}
```

#### GET /api/v1/fire/projection

Returns computed FIRE projections.

**Response:**
```json
{
  "status": "reachable",
  "inputs": {
    "currentAge": 28,
    "annualIncome": 120000.00,
    "annualExpenses": 60000.00,
    "currentNetWorth": 150000.00,
    "targetRetirementAge": 45
  },
  "blendedReturn": 0.08,
  "annualSavings": 60000.00,
  "savingsRate": 0.50,
  "fireTargets": {
    "leanFire": { "targetAmount": 900000.00, "yearsToTarget": 10, "targetAge": 38 },
    "fire": { "targetAmount": 1500000.00, "yearsToTarget": 14, "targetAge": 42 },
    "fatFire": { "targetAmount": 3000000.00, "yearsToTarget": 20, "targetAge": 48 }
  },
  "projectionCurve": [
    { "age": 28, "year": 2026, "projectedValue": 150000.00 },
    { "age": 29, "year": 2027, "projectedValue": 222000.00 }
  ],
  "monthlyBreakdown": {
    "monthlySurplus": 5000.00,
    "monthsToFire": 168
  },
  "goalAssessment": {
    "targetAge": 45,
    "status": "ahead",
    "gapAmount": 0.00
  }
}
```

### 4b. Rate Limits

| Type | Limit |
|------|-------|
| Read | 60/minute |
| Write | 30/minute |
| Debug key | `user:debug-user` (shared bucket for all debug requests) |

Not a concern for a single-user dashboard doing a handful of reads per refresh.

---

## 5. FitnessTracker API Integration

### 5a. Existing Endpoints (Available Now)

#### GET /health

Health check. No auth required.

**Response:**
```json
{
  "status": "healthy",
  "checks": { "database": "connected" }
}
```

Useful for the dashboard to verify the FitnessTracker backend is running before attempting data fetches.

#### GET /api/v1/users/me

Returns or provisions the current user.

**Headers:** `Authorization: Bearer <jwt>`

**Response:**
```json
{
  "id": "uuid",
  "supabase_id": "dashboard-user-uuid",
  "email": "dashboard@local",
  "created_at": "2026-05-20T00:00:00",
  "updated_at": null
}
```

### 5b. Endpoints to Build (Running / Strava)

These endpoints don't exist yet. They need to be added to the FitnessTracker backend as part of Phase 1a.

#### GET /api/v1/activities/recent

Returns latest Strava activities (running only).

**Query params:** `limit` (default 10), `sport_type` (optional filter)

**Expected response:**
```json
{
  "activities": [
    {
      "id": "uuid",
      "strava_id": 12345678,
      "sport_type": "Run",
      "start_date_local": "2026-05-20T07:30:00",
      "distance_meters": 8046.72,
      "distance_miles": 5.0,
      "moving_time_seconds": 2400,
      "pace_min_per_mile": 8.0,
      "average_speed_mps": 3.35,
      "total_elevation_gain_meters": 45.0,
      "average_heartrate": 155.0,
      "max_heartrate": 175.0,
      "calories": 480.0,
      "pr_count": 0
    }
  ]
}
```

#### GET /api/v1/activities/summary

Returns aggregated running stats over a time period.

**Query params:** `period` — `"week"` | `"month"` | `"year"` (default: `"week"`)

**Expected response:**
```json
{
  "period": "week",
  "start_date": "2026-05-13",
  "end_date": "2026-05-20",
  "total_runs": 4,
  "total_distance_miles": 22.5,
  "total_moving_time_seconds": 10800,
  "average_pace_min_per_mile": 8.0,
  "total_elevation_gain_feet": 580.0,
  "total_calories": 2100,
  "streak_days": 3
}
```

### 5c. Endpoints to Build (Health / Wearable)

These need to be added as part of Phase 1b. Data is normalized from either Oura or Whoop into a common `daily_health_record` schema.

#### GET /api/v1/health/today

Returns today's health record.

**Expected response:**
```json
{
  "date": "2026-05-20",
  "provider": "oura",
  "sleep": {
    "score": 85,
    "total_sleep_seconds": 28800,
    "deep_sleep_seconds": 7200,
    "rem_sleep_seconds": 5400,
    "light_sleep_seconds": 16200,
    "efficiency": 92.5
  },
  "recovery": {
    "score": 78,
    "resting_heart_rate": 52.0,
    "hrv": 45.0,
    "spo2": 97.5
  },
  "strain": {
    "score": 65.0,
    "active_calories": 450,
    "total_calories": 2200,
    "steps": 8500
  }
}
```

#### GET /api/v1/health/recent

Returns last N days of health records.

**Query params:** `days` (default 7)

**Expected response:**
```json
{
  "records": [
    { "date": "2026-05-20", "provider": "oura", "sleep": {...}, "recovery": {...}, "strain": {...} },
    { "date": "2026-05-19", "provider": "oura", "sleep": {...}, "recovery": {...}, "strain": {...} }
  ]
}
```

#### GET /api/v1/health/summary

Returns averaged health metrics over a period.

**Query params:** `days` (default 30)

**Expected response:**
```json
{
  "period_days": 30,
  "provider": "oura",
  "avg_sleep_score": 82,
  "avg_total_sleep_hours": 7.5,
  "avg_recovery_score": 75,
  "avg_resting_heart_rate": 54.0,
  "avg_hrv": 42.0,
  "avg_strain_score": 60.0,
  "avg_active_calories": 420
}
```

### 5d. Rate Limits

| Type | Limit |
|------|-------|
| Read | 100/minute |
| Write | 20/minute |

Not a concern for dashboard reads.

---

## 6. Networking Layer (Swift)

### 6a. APIClient — Shared HTTP Base

Handles JSON decoding, auth headers, and error mapping for both backends.

```swift
final class APIClient {
    let baseURL: URL
    let authToken: String
    private let decoder: JSONDecoder
    private let session: URLSession

    init(baseURL: URL, authToken: String) {
        self.baseURL = baseURL
        self.authToken = authToken
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
        self.session = .shared
    }

    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch http.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.httpError(statusCode: http.statusCode)
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case rateLimited
    case httpError(statusCode: Int)
    case backendUnavailable
}
```

### 6b. VaultAPIClient

```swift
final class VaultAPIClient {
    private let client: APIClient

    init() {
        self.client = APIClient(
            baseURL: APIConfiguration.Vault.baseURL,
            authToken: APIConfiguration.Vault.authToken
        )
    }

    func getDashboard() async throws -> VaultDashboardResponse {
        try await client.get(path: "/api/v1/dashboard")
    }

    func getNetWorthHistory(period: String = "daily") async throws -> NetWorthHistoryResponse {
        try await client.get(
            path: "/api/v1/networth/history",
            queryItems: [URLQueryItem(name: "period", value: period)]
        )
    }

    func getFireProfile() async throws -> FIREProfileResponse {
        try await client.get(path: "/api/v1/fire/profile")
    }

    func getFireProjection() async throws -> FIREProjectionResponse {
        try await client.get(path: "/api/v1/fire/projection")
    }
}
```

### 6c. FitnessAPIClient

```swift
final class FitnessAPIClient {
    private let client: APIClient

    init() {
        self.client = APIClient(
            baseURL: APIConfiguration.Fitness.baseURL,
            authToken: APIConfiguration.Fitness.authToken
        )
    }

    // Health check (no auth needed, but including it is harmless)
    func checkHealth() async throws -> HealthCheckResponse {
        try await client.get(path: "/health")
    }

    // Running / Strava
    func getRecentActivities(limit: Int = 10) async throws -> ActivitiesResponse {
        try await client.get(
            path: "/api/v1/activities/recent",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    func getActivitySummary(period: String = "week") async throws -> ActivitySummaryResponse {
        try await client.get(
            path: "/api/v1/activities/summary",
            queryItems: [URLQueryItem(name: "period", value: period)]
        )
    }

    // Health / Wearable
    func getHealthToday() async throws -> DailyHealthResponse {
        try await client.get(path: "/api/v1/health/today")
    }

    func getHealthRecent(days: Int = 7) async throws -> RecentHealthResponse {
        try await client.get(
            path: "/api/v1/health/recent",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }

    func getHealthSummary(days: Int = 30) async throws -> HealthSummaryResponse {
        try await client.get(
            path: "/api/v1/health/summary",
            queryItems: [URLQueryItem(name: "days", value: String(days))]
        )
    }
}
```

---

## 7. Swift Codable Models

### 7a. VaultTracker Models

```swift
// GET /api/v1/dashboard
struct VaultDashboardResponse: Codable {
    let totalNetWorth: Double
    let categoryTotals: CategoryTotals
    let groupedHoldings: GroupedHoldings
}

struct CategoryTotals: Codable {
    let crypto: Double
    let stocks: Double
    let cash: Double
    let realEstate: Double
    let retirement: Double
}

struct GroupedHoldings: Codable {
    let crypto: [Holding]
    let stocks: [Holding]
    let cash: [Holding]
    let realEstate: [Holding]
    let retirement: [Holding]
}

struct Holding: Codable, Identifiable {
    let id: String
    let name: String
    let symbol: String?
    let quantity: Double
    let currentValue: Double
}

// GET /api/v1/networth/history
struct NetWorthHistoryResponse: Codable {
    let snapshots: [NetWorthSnapshot]
}

struct NetWorthSnapshot: Codable {
    let date: Date
    let value: Double
}

// GET /api/v1/fire/profile
struct FIREProfileResponse: Codable {
    let id: String
    let currentAge: Int
    let annualIncome: Double
    let annualExpenses: Double
    let targetRetirementAge: Int?
    let createdAt: Date
    let updatedAt: Date
}

// GET /api/v1/fire/projection
struct FIREProjectionResponse: Codable {
    let status: String  // "reachable", "beyond_horizon", "unreachable"
    let annualSavings: Double?
    let savingsRate: Double?
    let fireTargets: FIRETargets
    let projectionCurve: [ProjectionPoint]
    let monthlyBreakdown: MonthlyBreakdown?
    let goalAssessment: GoalAssessment?
}

struct FIRETargets: Codable {
    let leanFire: FIRETarget
    let fire: FIRETarget
    let fatFire: FIRETarget
}

struct FIRETarget: Codable {
    let targetAmount: Double
    let yearsToTarget: Int?
    let targetAge: Int?
}

struct ProjectionPoint: Codable {
    let age: Int
    let year: Int
    let projectedValue: Double
}

struct MonthlyBreakdown: Codable {
    let monthlySurplus: Double
    let monthsToFire: Int?
}

struct GoalAssessment: Codable {
    let targetAge: Int
    let status: String  // "ahead", "on_track", "behind"
    let gapAmount: Double
}
```

### 7b. FitnessTracker Models

```swift
// GET /health
struct HealthCheckResponse: Codable {
    let status: String
}

// GET /api/v1/activities/recent
struct ActivitiesResponse: Codable {
    let activities: [Activity]
}

struct Activity: Codable, Identifiable {
    let id: String
    let stravaId: Int
    let sportType: String
    let startDateLocal: String
    let distanceMeters: Double
    let distanceMiles: Double
    let movingTimeSeconds: Int
    let paceMinPerMile: Double
    let totalElevationGainMeters: Double
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    let calories: Double
    let prCount: Int
}

// GET /api/v1/activities/summary
struct ActivitySummaryResponse: Codable {
    let period: String
    let startDate: String
    let endDate: String
    let totalRuns: Int
    let totalDistanceMiles: Double
    let totalMovingTimeSeconds: Int
    let averagePaceMinPerMile: Double
    let totalElevationGainFeet: Double
    let totalCalories: Int
    let streakDays: Int
}

// GET /api/v1/health/today
struct DailyHealthResponse: Codable {
    let date: String
    let provider: String
    let sleep: SleepData
    let recovery: RecoveryData
    let strain: StrainData
}

struct SleepData: Codable {
    let score: Int
    let totalSleepSeconds: Int
    let deepSleepSeconds: Int
    let remSleepSeconds: Int
    let lightSleepSeconds: Int
    let efficiency: Double
}

struct RecoveryData: Codable {
    let score: Int
    let restingHeartRate: Double
    let hrv: Double
    let spo2: Double?
}

struct StrainData: Codable {
    let score: Double
    let activeCalories: Int
    let totalCalories: Int
    let steps: Int?  // Oura only
}

// GET /api/v1/health/recent
struct RecentHealthResponse: Codable {
    let records: [DailyHealthResponse]
}

// GET /api/v1/health/summary
struct HealthSummaryResponse: Codable {
    let periodDays: Int
    let provider: String
    let avgSleepScore: Int
    let avgTotalSleepHours: Double
    let avgRecoveryScore: Int
    let avgRestingHeartRate: Double
    let avgHrv: Double
    let avgStrainScore: Double
    let avgActiveCalories: Int
}
```

---

## 8. DashboardViewModel — Data Orchestration

Fetches from both APIs in parallel and publishes results to views.

```swift
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var vaultDashboard: VaultDashboardResponse?
    @Published var fireProjection: FIREProjectionResponse?
    @Published var recentActivities: [Activity] = []
    @Published var activitySummary: ActivitySummaryResponse?
    @Published var healthToday: DailyHealthResponse?

    @Published var isLoading = false
    @Published var errors: [DashboardError] = []
    @Published var lastRefreshed: Date?

    private let vaultClient = VaultAPIClient()
    private let fitnessClient = FitnessAPIClient()

    func refresh() async {
        isLoading = true
        errors = []

        async let vaultResult = fetchVault()
        async let fitnessResult = fetchFitness()

        let (vaultErrors, fitnessErrors) = await (vaultResult, fitnessResult)
        errors = vaultErrors + fitnessErrors

        lastRefreshed = Date()
        isLoading = false
    }

    private func fetchVault() async -> [DashboardError] {
        var errors: [DashboardError] = []
        do {
            async let dashboard = vaultClient.getDashboard()
            async let projection = vaultClient.getFireProjection()
            let (d, p) = try await (dashboard, projection)
            self.vaultDashboard = d
            self.fireProjection = p
        } catch {
            errors.append(.vault(error))
        }
        return errors
    }

    private func fetchFitness() async -> [DashboardError] {
        var errors: [DashboardError] = []
        
        // Fetch running and health in parallel
        async let runningResult: Void = {
            do {
                async let activities = fitnessClient.getRecentActivities(limit: 5)
                async let summary = fitnessClient.getActivitySummary(period: "week")
                let (a, s) = try await (activities, summary)
                self.recentActivities = a.activities
                self.activitySummary = s
            } catch {
                errors.append(.fitness(error))
            }
        }()

        async let healthResult: Void = {
            do {
                self.healthToday = try await fitnessClient.getHealthToday()
            } catch {
                errors.append(.health(error))
            }
        }()

        _ = await (runningResult, healthResult)
        return errors
    }
}

enum DashboardError: Identifiable {
    case vault(Error)
    case fitness(Error)
    case health(Error)

    var id: String {
        switch self {
        case .vault: return "vault"
        case .fitness: return "fitness"
        case .health: return "health"
        }
    }
}
```

### Error Handling Strategy

Each panel fetches independently. If one backend is down, the other panels still populate. Errors are collected and displayed per-panel (e.g., "VaultTracker unavailable" shown in the investments panel, while fitness/health panels work normally).

### Backend Availability Check

On app launch, hit `GET /health` on FitnessTracker and `GET /` on VaultTracker (both unauthenticated) to verify backends are running before attempting authenticated fetches.

---

## 9. Project Structure

```
LifeDashboard/
├── Package.swift                        # SwiftPM executable, macOS 14+
├── LifeDashboard/
│   ├── App/
│   │   ├── LifeDashboardApp.swift       # WindowGroup → AppNavigation
│   │   └── WindowConfigurator.swift     # Hidden title bar, draggable background
│   ├── Configuration/
│   │   └── APIConfiguration.swift       # Base URLs, ports, auth tokens
│   ├── Theme/
│   │   ├── AppTheme.swift
│   │   ├── AppTypography.swift
│   │   └── ViewModifiers.swift          # .glassCard()
│   ├── Navigation/
│   │   ├── NavigationDestination.swift
│   │   ├── SidebarView.swift
│   │   └── AppNavigation.swift        # Owns @StateObject DashboardViewModel
│   ├── Networking/                      # Unchanged from V1
│   ├── Models/                          # Unchanged from V1
│   ├── ViewModels/
│   │   └── DashboardViewModel.swift     # Shared @ObservedObject across pages
│   └── Views/
│       ├── Components/                  # HeaderBar, RingGauge, SparklineChart, …
│       ├── Dashboard/                   # Card grid + assembly DashboardView
│       ├── Investments/ Fitness/ Recovery/ Settings/
├── LifeDashboardTests/
└── CLAUDE.md
```

### UI data binding (revamp)

| View | ViewModel properties |
|------|---------------------|
| `NetWorthCard` | `vaultDashboard`, `fireProjection` |
| `RunPerformanceCard` | `recentActivities`, `activitySummary` |
| `RecoveryCard` / `SleepCard` | `healthToday` |
| Section pages | Same properties; errors filtered by `DashboardError.id` |

Schedule is static UI. Tasks and deep-work timer use `CockpitLocalState` in `AppNavigation` (in-memory only, no persistence).

---

## 10. Local Development Setup

### Prerequisites

1. **VaultTracker backend** running on port 8001 with debug auth enabled:
   ```bash
   cd VaultTracker/VaultTrackerAPI
   # .env must contain: DEBUG_AUTH_ENABLED=true
   # start.sh must use port 8001
   ./start.sh
   ```

2. **FitnessTracker backend** running on port 8000:
   ```bash
   cd FitnessTracker/fitness-backend
   # Start Postgres + Redis
   make dev
   # .env must contain SUPABASE_JWT_SECRET
   ```

3. **Pre-generate** a FitnessTracker JWT using the script in Section 3b and place it in `APIConfiguration.swift`.

### Verification Checklist

- [ ] VaultTracker responds on `http://localhost:8001/`
- [ ] FitnessTracker responds on `http://localhost:8000/health`
- [ ] `curl -H "Authorization: Bearer vaulttracker-debug-user" http://localhost:8001/api/v1/dashboard` returns portfolio data
- [ ] `curl -H "Authorization: Bearer <jwt>" http://localhost:8000/api/v1/users/me` returns user data
- [ ] Dashboard app fetches and displays VaultTracker data
- [ ] Dashboard app fetches and displays running data (after Phase 1a)
- [ ] Dashboard app fetches and displays health data (after Phase 1b)
- [ ] Manual refresh re-fetches all panels
- [ ] One backend down doesn't crash the app — other panels still work

---

## 11. Build Order

### Phase 1a: FitnessTracker — Strava Endpoints
Add to FitnessTracker backend:
- Strava OAuth flow + token storage
- Activity sync service (initial + incremental)
- `GET /api/v1/activities/recent`
- `GET /api/v1/activities/summary`

### Phase 1b: FitnessTracker — Wearable Endpoints
Add to FitnessTracker backend:
- Oura/Whoop OAuth + token storage
- `daily_health_record` table + common schema
- Sync service (Oura calendar-based or Whoop cycle-based)
- `GET /api/v1/health/today`
- `GET /api/v1/health/recent`
- `GET /api/v1/health/summary`

### Phase 2: Port Configuration
- Update VaultTracker `start.sh` to use port 8001
- Update VaultTracker CORS if needed

### Phase 3: macOS Dashboard App
- Scaffold Xcode project
- Build `APIClient`, `VaultAPIClient`, `FitnessAPIClient`
- Build Swift Codable models
- Build `DashboardViewModel`
- Build views (designed separately)
- Archive and export as locally signed `.app`

Phase 3 can start in parallel with Phase 1 — the VaultTracker panel and networking layer can be built while Strava/wearable integration is in progress, using mock fitness responses.

---

## 12. Testing Strategy

### CI (GitHub Actions)

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) on `macos-14`, two jobs in order:

1. **lint** — `swiftlint lint` (config: [`.swiftlint.yml`](../.swiftlint.yml))
2. **unit-tests** — `swift test` (runs only after lint succeeds)

Triggers: push to `main`, all pull requests.

Local verification (same commands as CI):

```bash
swiftlint lint
swift test
```

### Unit Tests
- `APIClient`: mock `URLProtocol` to test JSON decoding, error mapping, auth header injection
- `VaultAPIClient` / `FitnessAPIClient`: verify correct paths and query params are constructed
- `DashboardViewModel`: mock both API clients to test parallel fetch, partial failure, error collection

### Integration Tests (Manual)
- Start both backends locally and confirm end-to-end fetch
- Kill one backend and verify the other panel still works
- Test with invalid auth tokens to confirm 401 handling

### No Automated UI Tests for V1
Manual verification that views render data correctly. Automated UI tests deferred.
