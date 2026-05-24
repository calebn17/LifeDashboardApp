# Life Dashboard — Execution Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS SwiftUI app that aggregates data from two localhost FastAPI backends (VaultTracker + FitnessTracker) into a single read-only dashboard.

**Architecture:** Bottom-up layered build. A shared `APIClient` base class (URLSession + async/await) wraps two domain clients (`VaultAPIClient`, `FitnessAPIClient`). A single `DashboardViewModel` fetches both in parallel via `async let` and publishes results to three SwiftUI panels (Fitness, Health, Investments). Each panel is error-isolated — one backend going down doesn't affect the others. No persistence; backends are the source of truth.

**Tech Stack:** Swift/SwiftUI (macOS 14+), URLSession, async/await, XCTest. Backends: FastAPI (Python), PostgreSQL.

**Spec:** `LifeDashboard/Documentation/Plans/2026-05-20-life-dashboard-implementation-plan.md`
**Tech Spec:** `LifeDashboard/Documentation/2026-05-20-life-dashboard-tech-spec.md`
**Design System:** `LifeDashboard/Assets/stitch_unified_life_metrics_dashboard/DESIGN.md`

---

## File Map

### Prerequisites (FitnessTracker backend)

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `FitnessTracker/fitness-backend/app/config.py` | Add `debug_auth_enabled` setting |
| Modify | `FitnessTracker/fitness-backend/app/core/security.py` | Add debug token bypass to `get_supabase_jwt_claims` |
| Create | `FitnessTracker/fitness-backend/tests/unit/test_debug_auth.py` | Tests for debug auth bypass |

### Prerequisites (VaultTracker backend)

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `VaultTracker/VaultTrackerAPI/start.sh` | Change port from 8000 to 8001 |

### macOS Dashboard App

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `LifeDashboard/LifeDashboard/App/LifeDashboardApp.swift` | App entry point, window configuration |
| Create | `LifeDashboard/LifeDashboard/Configuration/APIConfiguration.swift` | Base URLs and auth tokens |
| Create | `LifeDashboard/LifeDashboard/Models/VaultModels.swift` | Codable types for VaultTracker responses |
| Create | `LifeDashboard/LifeDashboard/Models/FitnessModels.swift` | Codable types for activity responses |
| Create | `LifeDashboard/LifeDashboard/Models/HealthModels.swift` | Codable types for wearable health responses |
| Create | `LifeDashboard/LifeDashboard/Networking/APIError.swift` | Shared error enum |
| Create | `LifeDashboard/LifeDashboard/Networking/APIClient.swift` | Shared HTTP layer |
| Create | `LifeDashboard/LifeDashboard/Networking/VaultAPIClient.swift` | VaultTracker endpoint wrappers |
| Create | `LifeDashboard/LifeDashboard/Networking/FitnessAPIClient.swift` | FitnessTracker endpoint wrappers |
| Create | `LifeDashboard/LifeDashboard/ViewModels/DashboardViewModel.swift` | Parallel fetch orchestration |
| Create | `LifeDashboard/LifeDashboard/Views/DashboardView.swift` | Main dashboard layout |
| Create | `LifeDashboard/LifeDashboard/Views/FitnessPanel.swift` | Running activity panel |
| Create | `LifeDashboard/LifeDashboard/Views/HealthPanel.swift` | Sleep/recovery/strain panel |
| Create | `LifeDashboard/LifeDashboard/Views/InvestmentsPanel.swift` | Portfolio and FIRE panel |
| Create | `LifeDashboard/LifeDashboard/Views/Components/GlassCard.swift` | Reusable glass card container |
| Create | `LifeDashboard/LifeDashboard/Views/Components/MetricView.swift` | Reusable label + value metric display |
| Create | `LifeDashboard/LifeDashboard/Views/Components/StatusBar.swift` | Refresh button + last-refreshed timestamp |
| Create | `LifeDashboard/LifeDashboardTests/Models/VaultModelsTests.swift` | Decode tests for vault JSON |
| Create | `LifeDashboard/LifeDashboardTests/Models/FitnessModelsTests.swift` | Decode tests for fitness JSON |
| Create | `LifeDashboard/LifeDashboardTests/Models/HealthModelsTests.swift` | Decode tests for health JSON |
| Create | `LifeDashboard/LifeDashboardTests/Networking/MockURLProtocol.swift` | Shared test helper for mocking URLSession |
| Create | `LifeDashboard/LifeDashboardTests/Networking/APIClientTests.swift` | HTTP layer tests |
| Create | `LifeDashboard/LifeDashboardTests/ViewModels/DashboardViewModelTests.swift` | ViewModel tests with mocked clients |

---

## Task 1: Add Debug Auth to FitnessTracker Backend

**Files:**
- Modify: `FitnessTracker/fitness-backend/app/config.py:18` (add after `debug: bool = False`)
- Modify: `FitnessTracker/fitness-backend/app/core/security.py:66-120` (add bypass to `get_supabase_jwt_claims`)
- Create: `FitnessTracker/fitness-backend/tests/unit/test_debug_auth.py`

- [ ] **Step 1: Write failing tests for debug auth**

Create `FitnessTracker/fitness-backend/tests/unit/test_debug_auth.py`:

```python
"""Tests for debug auth bypass in get_supabase_jwt_claims."""

import time
from typing import Annotated, Any

import jwt
import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app.config import Settings, get_settings
from app.core.security import get_supabase_jwt_claims

_SECRET = "debug-auth-test-secret-at-least-32-bytes-long"
_AUDIENCE = "authenticated"
_DEBUG_TOKEN = "fitnesstracker-debug-user"
_DEBUG_USER_ID = "debug-user"


def _make_app() -> FastAPI:
    app = FastAPI()

    @app.get("/claims")
    def read_claims(
        claims: Annotated[dict[str, Any], Depends(get_supabase_jwt_claims)],
    ) -> dict[str, Any]:
        return claims

    return app


def _encode(payload: dict[str, Any]) -> str:
    return jwt.encode(payload, _SECRET, algorithm="HS256")


def _valid_payload(**overrides: Any) -> dict[str, Any]:
    now = int(time.time())
    base: dict[str, Any] = {
        "sub": "22222222-2222-2222-2222-222222222222",
        "aud": _AUDIENCE,
        "exp": now + 3600,
    }
    base.update(overrides)
    return base


@pytest.fixture
def debug_enabled_client() -> TestClient:
    get_settings.cache_clear()
    app = _make_app()

    def _settings() -> Settings:
        return Settings(
            debug_auth_enabled=True,
            supabase_jwt_secret=_SECRET,
            supabase_jwt_audience=_AUDIENCE,
        )

    app.dependency_overrides[get_settings] = _settings
    client = TestClient(app)
    yield client
    client.close()
    get_settings.cache_clear()


@pytest.fixture
def debug_disabled_client() -> TestClient:
    get_settings.cache_clear()
    app = _make_app()

    def _settings() -> Settings:
        return Settings(
            debug_auth_enabled=False,
            supabase_jwt_secret=_SECRET,
            supabase_jwt_audience=_AUDIENCE,
        )

    app.dependency_overrides[get_settings] = _settings
    client = TestClient(app)
    yield client
    client.close()
    get_settings.cache_clear()


def test_debug_token_returns_synthetic_claims(debug_enabled_client: TestClient) -> None:
    r = debug_enabled_client.get(
        "/claims",
        headers={"Authorization": f"Bearer {_DEBUG_TOKEN}"},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["sub"] == _DEBUG_USER_ID
    assert body["aud"] == _AUDIENCE


def test_debug_token_rejected_when_disabled(debug_disabled_client: TestClient) -> None:
    r = debug_disabled_client.get(
        "/claims",
        headers={"Authorization": f"Bearer {_DEBUG_TOKEN}"},
    )
    assert r.status_code == 401
    assert r.json()["detail"]["code"] == "token_invalid"


def test_real_jwt_still_works_when_debug_enabled(
    debug_enabled_client: TestClient,
) -> None:
    token = _encode(_valid_payload())
    r = debug_enabled_client.get(
        "/claims",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 200
    assert r.json()["sub"] == "22222222-2222-2222-2222-222222222222"


def test_non_debug_token_still_rejected_when_debug_enabled(
    debug_enabled_client: TestClient,
) -> None:
    r = debug_enabled_client.get(
        "/claims",
        headers={"Authorization": "Bearer some-random-invalid-token"},
    )
    assert r.status_code == 401
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_debug_auth.py -v`

Expected: Multiple failures — `Settings` doesn't accept `debug_auth_enabled`, and no debug bypass logic exists.

- [ ] **Step 3: Add `debug_auth_enabled` to Settings**

In `FitnessTracker/fitness-backend/app/config.py`, add after line 18 (`debug: bool = False`):

```python
    debug_auth_enabled: bool = False
```

- [ ] **Step 4: Add debug bypass to `get_supabase_jwt_claims`**

In `FitnessTracker/fitness-backend/app/core/security.py`, add constants after the imports (before `decode_supabase_access_token`):

```python
_DEBUG_AUTH_TOKEN = "fitnesstracker-debug-user"
_DEBUG_USER_ID = "debug-user"
```

Then modify `get_supabase_jwt_claims` to check for the debug token before JWT validation. Replace the function (lines 66–120) with:

```python
def get_supabase_jwt_claims(
    settings: Annotated[Settings, Depends(get_settings)],
    authorization: Annotated[str | None, Header(alias="Authorization")] = None,
) -> dict[str, Any]:
    """Decode the request Bearer token into Supabase JWT claims (or raise 401)."""
    raw = _parse_bearer_token(authorization)
    if settings.debug_auth_enabled and raw == _DEBUG_AUTH_TOKEN:
        return {
            "sub": _DEBUG_USER_ID,
            "aud": settings.supabase_jwt_audience,
        }
    if not settings.supabase_jwt_secret.strip():
        raise _unauthorized(
            {
                "code": "auth_not_configured",
                "message": "Server JWT validation is not configured.",
            },
        ) from None
    try:
        return decode_supabase_access_token(
            raw,
            jwt_secret=settings.supabase_jwt_secret,
            audience=settings.supabase_jwt_audience,
        )
    except ExpiredSignatureError as exc:
        raise _unauthorized(
            {
                "code": "token_expired",
                "message": "The access token has expired.",
            },
        ) from exc
    except InvalidAudienceError as exc:
        raise _unauthorized(
            {
                "code": "token_invalid_audience",
                "message": "The access token audience is invalid.",
            },
        ) from exc
    except InvalidSignatureError as exc:
        raise _unauthorized(
            {
                "code": "token_invalid_signature",
                "message": "The access token signature is invalid.",
            },
        ) from exc
    except MissingRequiredClaimError as exc:
        raise _unauthorized(
            {
                "code": "token_missing_claim",
                "message": "The access token is missing a required claim.",
                "claim": exc.claim,
            },
        ) from exc
    except InvalidTokenError as exc:
        raise _unauthorized(
            {
                "code": "token_invalid",
                "message": "The access token could not be validated.",
            },
        ) from exc
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_debug_auth.py -v`

Expected: All 4 tests PASS.

- [ ] **Step 6: Run existing security tests to verify no regressions**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/test_security_dependency.py tests/unit/test_debug_auth.py -v`

Expected: All tests PASS (existing + new).

- [ ] **Step 7: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker
git add fitness-backend/app/config.py fitness-backend/app/core/security.py fitness-backend/tests/unit/test_debug_auth.py
git commit -m "feat: add debug auth bypass to FitnessTracker backend

Adds DEBUG_AUTH_ENABLED config flag and debug token bypass to
get_supabase_jwt_claims, matching VaultTracker's debug auth pattern.
Token: 'fitnesstracker-debug-user' maps to fixed user 'debug-user'."
```

---

## Task 2: Update VaultTracker Port to 8001

**Files:**
- Modify: `VaultTracker/VaultTrackerAPI/start.sh:16` (change port)

- [ ] **Step 1: Update start.sh**

In `VaultTracker/VaultTrackerAPI/start.sh`, replace line 16:

Old:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

New:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

Also update the echo on line 12:

Old:
```bash
echo "Starting VaultTrackerAPI on http://localhost:8000"
```

New:
```bash
echo "Starting VaultTrackerAPI on http://localhost:8001"
```

And line 13:

Old:
```bash
echo "API docs: http://localhost:8000/docs"
```

New:
```bash
echo "API docs: http://localhost:8001/docs"
```

- [ ] **Step 2: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/VaultTracker
git add VaultTrackerAPI/start.sh
git commit -m "chore: change VaultTracker port to 8001 for LifeDashboard coexistence"
```

---

## Task 3: Scaffold Xcode Project

This task creates the Xcode project manually via Swift Package structure. Since Claude Code cannot invoke Xcode GUI, we create a Swift Package–based macOS app.

**Files:**
- Create: `LifeDashboard/LifeDashboard/Package.swift`
- Create: `LifeDashboard/LifeDashboard/App/LifeDashboardApp.swift`
- Create: directory stubs for all groups

- [ ] **Step 1: Create project directory structure**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
mkdir -p LifeDashboard/App
mkdir -p LifeDashboard/Configuration
mkdir -p LifeDashboard/Models
mkdir -p LifeDashboard/Networking
mkdir -p LifeDashboard/ViewModels
mkdir -p LifeDashboard/Views/Components
mkdir -p LifeDashboardTests/Models
mkdir -p LifeDashboardTests/Networking
mkdir -p LifeDashboardTests/ViewModels
```

- [ ] **Step 2: Create Package.swift**

Create `LifeDashboard/Package.swift`:

```swift
// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LifeDashboard",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LifeDashboard",
            path: "LifeDashboard"
        ),
        .testTarget(
            name: "LifeDashboardTests",
            dependencies: ["LifeDashboard"],
            path: "LifeDashboardTests"
        ),
    ]
)
```

- [ ] **Step 3: Create app entry point**

Create `LifeDashboard/LifeDashboard/App/LifeDashboardApp.swift`:

```swift
import SwiftUI

@main
struct LifeDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Life Dashboard")
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowResizability(.contentMinSize)
    }
}
```

- [ ] **Step 4: Verify it builds**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build`

Expected: Build succeeds. (Note: the app won't launch from `swift run` without a GUI context, but compilation confirms the scaffold is correct.)

- [ ] **Step 5: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git init
git add Package.swift LifeDashboard/ LifeDashboardTests/
git commit -m "feat: scaffold LifeDashboard macOS SwiftUI project"
```

---

## Task 4: Configuration Layer

**Files:**
- Create: `LifeDashboard/LifeDashboard/Configuration/APIConfiguration.swift`

- [ ] **Step 1: Create APIConfiguration.swift**

Create `LifeDashboard/LifeDashboard/Configuration/APIConfiguration.swift`:

```swift
import Foundation

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

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build`

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Configuration/APIConfiguration.swift
git commit -m "feat: add API configuration with base URLs and debug tokens"
```

---

## Task 5: Codable Models — VaultTracker

**Files:**
- Create: `LifeDashboard/LifeDashboard/Models/VaultModels.swift`
- Create: `LifeDashboard/LifeDashboardTests/Models/VaultModelsTests.swift`

VaultTracker uses camelCase JSON keys. Since `convertFromSnakeCase` only converts snake_case → camelCase (not identity), and VaultTracker keys are already camelCase, a decoder with `convertFromSnakeCase` will mangle them (e.g., `totalNetWorth` → `totalnetworth`). VaultTracker models must use a decoder WITHOUT `convertFromSnakeCase`, or use explicit `CodingKeys`. We'll handle this by giving `APIClient` a configurable key strategy and using `.useDefaultKeys` for VaultTracker.

- [ ] **Step 1: Write failing decode test**

Create `LifeDashboard/LifeDashboardTests/Models/VaultModelsTests.swift`:

```swift
import XCTest
@testable import LifeDashboard

final class VaultModelsTests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func testDecodeDashboardResponse() throws {
        let json = """
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
                "id": "abc-123",
                "name": "Bitcoin",
                "symbol": "BTC",
                "quantity": 0.5,
                "current_value": 25000.00
              }
            ],
            "stocks": [],
            "cash": [],
            "realEstate": [],
            "retirement": []
          }
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(VaultDashboardResponse.self, from: json)
        XCTAssertEqual(result.totalNetWorth, 150000.00)
        XCTAssertEqual(result.categoryTotals.crypto, 25000.00)
        XCTAssertEqual(result.categoryTotals.realEstate, 0.00)
        XCTAssertEqual(result.groupedHoldings["crypto"]?.count, 1)
        XCTAssertEqual(result.groupedHoldings["crypto"]?.first?.symbol, "BTC")
    }

    func testDecodeNetWorthHistoryResponse() throws {
        let json = """
        {
          "snapshots": [
            {"date": "2026-05-01T00:00:00", "value": 148000.00},
            {"date": "2026-05-02T00:00:00", "value": 149200.00}
          ]
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(NetWorthHistoryResponse.self, from: json)
        XCTAssertEqual(result.snapshots.count, 2)
        XCTAssertEqual(result.snapshots[0].value, 148000.00)
    }

    func testDecodeFIREProjectionResponse() throws {
        let json = """
        {
          "status": "reachable",
          "unreachableReason": null,
          "inputs": {
            "currentAge": 28,
            "annualIncome": 120000.00,
            "annualExpenses": 60000.00,
            "currentNetWorth": 150000.00,
            "targetRetirementAge": 45
          },
          "allocation": null,
          "blendedReturn": 0.08,
          "realBlendedReturn": null,
          "inflationRate": null,
          "annualSavings": 60000.00,
          "savingsRate": 0.50,
          "fireTargets": {
            "leanFire": {"targetAmount": 900000.00, "yearsToTarget": 10, "targetAge": 38},
            "fire": {"targetAmount": 1500000.00, "yearsToTarget": 14, "targetAge": 42},
            "fatFire": {"targetAmount": 3000000.00, "yearsToTarget": 20, "targetAge": 48}
          },
          "projectionCurve": [
            {"age": 28, "year": 2026, "projectedValue": 150000.00}
          ],
          "monthlyBreakdown": {"monthlySurplus": 5000.00, "monthsToFire": 168},
          "goalAssessment": {
            "targetAge": 45,
            "requiredSavingsRate": 0.40,
            "currentSavingsRate": 0.50,
            "status": "ahead",
            "gapAmount": 0.00,
            "computedBeyondProjectionHorizon": false
          }
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(FIREProjectionResponse.self, from: json)
        XCTAssertEqual(result.status, "reachable")
        XCTAssertEqual(result.savingsRate, 0.50)
        XCTAssertEqual(result.fireTargets.leanFire.targetAge, 38)
        XCTAssertEqual(result.goalAssessment?.status, "ahead")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter VaultModelsTests`

Expected: Compilation error — `VaultDashboardResponse` not found.

- [ ] **Step 3: Create VaultModels.swift**

Create `LifeDashboard/LifeDashboard/Models/VaultModels.swift`:

```swift
import Foundation

struct VaultDashboardResponse: Codable {
    let totalNetWorth: Double
    let categoryTotals: CategoryTotals
    let groupedHoldings: [String: [Holding]]
}

struct CategoryTotals: Codable {
    let crypto: Double
    let stocks: Double
    let cash: Double
    let realEstate: Double
    let retirement: Double
}

struct Holding: Codable, Identifiable {
    let id: String
    let name: String
    let symbol: String?
    let quantity: Double
    let currentValue: Double

    enum CodingKeys: String, CodingKey {
        case id, name, symbol, quantity
        case currentValue = "current_value"
    }
}

struct NetWorthHistoryResponse: Codable {
    let snapshots: [NetWorthSnapshot]
}

struct NetWorthSnapshot: Codable {
    let date: Date
    let value: Double
}

struct FIREProfileResponse: Codable {
    let id: String
    let currentAge: Int
    let annualIncome: Double
    let annualExpenses: Double
    let targetRetirementAge: Int?
    let createdAt: Date
    let updatedAt: Date
}

struct FIREProjectionResponse: Codable {
    let status: String
    let unreachableReason: String?
    let inputs: FIREProjectionInputs
    let allocation: FIREAllocation?
    let blendedReturn: Double?
    let realBlendedReturn: Double?
    let inflationRate: Double?
    let annualSavings: Double?
    let savingsRate: Double?
    let fireTargets: FIRETargets
    let projectionCurve: [ProjectionPoint]
    let monthlyBreakdown: MonthlyBreakdown
    let goalAssessment: GoalAssessment?
}

struct FIREProjectionInputs: Codable {
    let currentAge: Int
    let annualIncome: Double
    let annualExpenses: Double
    let currentNetWorth: Double
    let targetRetirementAge: Int?
}

struct FIREAllocationSlice: Codable {
    let value: Double
    let percentage: Double
    let expectedReturn: Double
}

struct FIREAllocation: Codable {
    let crypto: FIREAllocationSlice
    let stocks: FIREAllocationSlice
    let cash: FIREAllocationSlice
    let realEstate: FIREAllocationSlice
    let retirement: FIREAllocationSlice
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
    let requiredSavingsRate: Double
    let currentSavingsRate: Double
    let status: String
    let gapAmount: Double
    let computedBeyondProjectionHorizon: Bool
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter VaultModelsTests`

Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Models/VaultModels.swift LifeDashboardTests/Models/VaultModelsTests.swift
git commit -m "feat: add VaultTracker Codable models with decode tests"
```

---

## Task 6: Codable Models — FitnessTracker (Activities)

**Files:**
- Create: `LifeDashboard/LifeDashboard/Models/FitnessModels.swift`
- Create: `LifeDashboard/LifeDashboardTests/Models/FitnessModelsTests.swift`

FitnessTracker uses snake_case JSON. The `convertFromSnakeCase` decoder strategy handles this.

- [ ] **Step 1: Write failing decode test**

Create `LifeDashboard/LifeDashboardTests/Models/FitnessModelsTests.swift`:

```swift
import XCTest
@testable import LifeDashboard

final class FitnessModelsTests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    func testDecodeActivitiesRecentResponse() throws {
        let json = """
        {
          "activities": [
            {
              "id": "a1b2c3d4-0000-0000-0000-000000000000",
              "strava_id": 12345678,
              "sport_type": "Run",
              "start_date_local": "2026-05-20T07:30:00",
              "distance_meters": 8046.72,
              "moving_time_seconds": 2400,
              "elapsed_time_seconds": 2500,
              "average_speed_mps": 3.35,
              "max_speed_mps": 4.0,
              "total_elevation_gain_meters": 45.0,
              "average_heartrate": 155.0,
              "max_heartrate": 175.0,
              "average_cadence": 170.0,
              "calories": 480.0,
              "pr_count": 0,
              "distance_miles": 5.0,
              "pace_min_per_mile": 8.0
            }
          ],
          "synced_at": "2026-05-20T08:00:00"
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(ActivitiesRecentResponse.self, from: json)
        XCTAssertEqual(result.activities.count, 1)
        let activity = result.activities[0]
        XCTAssertEqual(activity.stravaId, 12345678)
        XCTAssertEqual(activity.sportType, "Run")
        XCTAssertEqual(activity.distanceMiles, 5.0)
        XCTAssertEqual(activity.paceMinPerMile, 8.0)
    }

    func testDecodeActivitySummaryResponse() throws {
        let json = """
        {
          "period": "week",
          "start_date": "2026-05-13",
          "end_date": "2026-05-20",
          "total_runs": 4,
          "total_distance_miles": 22.5,
          "total_moving_time_seconds": 10800,
          "average_pace_min_per_mile": 8.0,
          "total_elevation_gain_feet": 580.0,
          "total_calories": 2100.0,
          "streak_days": 3,
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(ActivitySummaryResponse.self, from: json)
        XCTAssertEqual(result.period, "week")
        XCTAssertEqual(result.totalRuns, 4)
        XCTAssertEqual(result.totalDistanceMiles, 22.5)
        XCTAssertEqual(result.streakDays, 3)
    }

    func testDecodeHealthCheckResponse() throws {
        let json = """
        {"status": "healthy"}
        """.data(using: .utf8)!

        let result = try decoder().decode(HealthCheckResponse.self, from: json)
        XCTAssertEqual(result.status, "healthy")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter FitnessModelsTests`

Expected: Compilation error — types not found.

- [ ] **Step 3: Create FitnessModels.swift**

Create `LifeDashboard/LifeDashboard/Models/FitnessModels.swift`:

```swift
import Foundation

struct HealthCheckResponse: Codable {
    let status: String
}

struct ActivitiesRecentResponse: Codable {
    let activities: [Activity]
    let syncedAt: String?
}

struct Activity: Codable, Identifiable {
    let id: String
    let stravaId: Int
    let sportType: String
    let startDateLocal: String
    let distanceMeters: Double
    let movingTimeSeconds: Int
    let elapsedTimeSeconds: Int
    let averageSpeedMps: Double
    let maxSpeedMps: Double?
    let totalElevationGainMeters: Double
    let averageHeartrate: Double?
    let maxHeartrate: Double?
    let averageCadence: Double?
    let calories: Double?
    let prCount: Int
    let distanceMiles: Double
    let paceMinPerMile: Double?
}

struct ActivitySummaryResponse: Codable {
    let period: String
    let startDate: String
    let endDate: String
    let totalRuns: Int
    let totalDistanceMiles: Double
    let totalMovingTimeSeconds: Int
    let averagePaceMinPerMile: Double?
    let totalElevationGainFeet: Double
    let totalCalories: Double?
    let streakDays: Int
    let syncedAt: String?
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter FitnessModelsTests`

Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Models/FitnessModels.swift LifeDashboardTests/Models/FitnessModelsTests.swift
git commit -m "feat: add FitnessTracker activity Codable models with decode tests"
```

---

## Task 7: Codable Models — Health

**Files:**
- Create: `LifeDashboard/LifeDashboard/Models/HealthModels.swift`
- Create: `LifeDashboard/LifeDashboardTests/Models/HealthModelsTests.swift`

- [ ] **Step 1: Write failing decode test**

Create `LifeDashboard/LifeDashboardTests/Models/HealthModelsTests.swift`:

```swift
import XCTest
@testable import LifeDashboard

final class HealthModelsTests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    func testDecodeDailyHealthResponse() throws {
        let json = """
        {
          "date": "2026-05-20",
          "provider": "whoop",
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
            "steps": null
          },
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(DailyHealthResponse.self, from: json)
        XCTAssertEqual(result.date, "2026-05-20")
        XCTAssertEqual(result.provider, "whoop")
        XCTAssertEqual(result.sleep.score, 85)
        XCTAssertEqual(result.sleep.totalSleepSeconds, 28800)
        XCTAssertEqual(result.sleep.efficiency, 92.5)
        XCTAssertEqual(result.recovery.score, 78)
        XCTAssertEqual(result.recovery.hrv, 45.0)
        XCTAssertEqual(result.strain.score, 65.0)
        XCTAssertEqual(result.strain.activeCalories, 450)
        XCTAssertNil(result.strain.steps)
    }

    func testDecodeHealthRecentResponse() throws {
        let json = """
        {
          "records": [
            {
              "date": "2026-05-20",
              "provider": "whoop",
              "sleep": {"score": 85, "total_sleep_seconds": 28800, "deep_sleep_seconds": null, "rem_sleep_seconds": null, "light_sleep_seconds": null, "efficiency": null},
              "recovery": {"score": 78, "resting_heart_rate": 52.0, "hrv": 45.0, "spo2": null},
              "strain": {"score": 65.0, "active_calories": 450, "total_calories": 2200, "steps": null},
              "synced_at": null
            }
          ],
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(HealthRecentResponse.self, from: json)
        XCTAssertEqual(result.records.count, 1)
        XCTAssertEqual(result.records[0].provider, "whoop")
    }

    func testDecodeHealthSummaryResponse() throws {
        let json = """
        {
          "period_days": 30,
          "actual_days_with_data": 28,
          "provider": "whoop",
          "avg_sleep_score": 82.0,
          "avg_total_sleep_hours": 7.5,
          "avg_recovery_score": 75.0,
          "avg_resting_heart_rate": 54.0,
          "avg_hrv": 42.0,
          "avg_strain_score": 60.0,
          "avg_active_calories": 420.0,
          "synced_at": null
        }
        """.data(using: .utf8)!

        let result = try decoder().decode(HealthSummaryResponse.self, from: json)
        XCTAssertEqual(result.periodDays, 30)
        XCTAssertEqual(result.actualDaysWithData, 28)
        XCTAssertEqual(result.avgSleepScore, 82.0)
        XCTAssertEqual(result.avgHrv, 42.0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter HealthModelsTests`

Expected: Compilation error — types not found.

- [ ] **Step 3: Create HealthModels.swift**

Create `LifeDashboard/LifeDashboard/Models/HealthModels.swift`:

```swift
import Foundation

struct DailyHealthResponse: Codable {
    let date: String
    let provider: String
    let sleep: SleepData
    let recovery: RecoveryData
    let strain: StrainData
    let syncedAt: String?
}

struct SleepData: Codable {
    let score: Int?
    let totalSleepSeconds: Int?
    let deepSleepSeconds: Int?
    let remSleepSeconds: Int?
    let lightSleepSeconds: Int?
    let efficiency: Double?
}

struct RecoveryData: Codable {
    let score: Int?
    let restingHeartRate: Double?
    let hrv: Double?
    let spo2: Double?
}

struct StrainData: Codable {
    let score: Double?
    let activeCalories: Int?
    let totalCalories: Int?
    let steps: Int?
}

struct HealthRecentResponse: Codable {
    let records: [DailyHealthResponse]
    let syncedAt: String?
}

struct HealthSummaryResponse: Codable {
    let periodDays: Int
    let actualDaysWithData: Int
    let provider: String
    let avgSleepScore: Double?
    let avgTotalSleepHours: Double?
    let avgRecoveryScore: Double?
    let avgRestingHeartRate: Double?
    let avgHrv: Double?
    let avgStrainScore: Double?
    let avgActiveCalories: Double?
    let syncedAt: String?
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter HealthModelsTests`

Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Models/HealthModels.swift LifeDashboardTests/Models/HealthModelsTests.swift
git commit -m "feat: add health Codable models with decode tests"
```

---

## Task 8: Networking — APIError and APIClient

**Files:**
- Create: `LifeDashboard/LifeDashboard/Networking/APIError.swift`
- Create: `LifeDashboard/LifeDashboard/Networking/APIClient.swift`
- Create: `LifeDashboard/LifeDashboardTests/Networking/MockURLProtocol.swift`
- Create: `LifeDashboard/LifeDashboardTests/Networking/APIClientTests.swift`

- [ ] **Step 1: Write failing tests**

Create `LifeDashboard/LifeDashboardTests/Networking/MockURLProtocol.swift`:

```swift
import Foundation

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
```

Create `LifeDashboard/LifeDashboardTests/Networking/APIClientTests.swift`:

```swift
import XCTest
@testable import LifeDashboard

final class APIClientTests: XCTestCase {

    private var session: URLSession!
    private var client: APIClient!

    override func setUp() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        client = APIClient(
            baseURL: URL(string: "http://localhost:9999")!,
            authToken: "test-token",
            session: session,
            keyDecodingStrategy: .convertFromSnakeCase
        )
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
    }

    func testSuccessfulDecode() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let data = """
            {"status": "healthy"}
            """.data(using: .utf8)!
            return (response, data)
        }

        let result: HealthCheckResponse = try await client.get(path: "/health")
        XCTAssertEqual(result.status, "healthy")
    }

    func testUnauthorizedThrows() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401,
                httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        do {
            let _: HealthCheckResponse = try await client.get(path: "/test")
            XCTFail("Expected APIError.unauthorized")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testRateLimitedThrows() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 429,
                httpVersion: nil, headerFields: nil
            )!
            return (response, Data())
        }

        do {
            let _: HealthCheckResponse = try await client.get(path: "/test")
            XCTFail("Expected APIError.rateLimited")
        } catch let error as APIError {
            XCTAssertEqual(error, .rateLimited)
        }
    }

    func testQueryItemsAppended() async throws {
        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("period=week"))
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            let data = """
            {"status": "ok"}
            """.data(using: .utf8)!
            return (response, data)
        }

        let _: HealthCheckResponse = try await client.get(
            path: "/test",
            queryItems: [URLQueryItem(name: "period", value: "week")]
        )
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter APIClientTests`

Expected: Compilation error — `APIClient`, `APIError` not found.

- [ ] **Step 3: Create APIError.swift**

Create `LifeDashboard/LifeDashboard/Networking/APIError.swift`:

```swift
import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case unauthorized
    case rateLimited
    case httpError(statusCode: Int)
    case backendUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .unauthorized:
            return "Authentication failed. Check your auth token."
        case .rateLimited:
            return "Too many requests. Try again shortly."
        case .httpError(let code):
            return "Server returned error (HTTP \(code))."
        case .backendUnavailable:
            return "Backend is not running or unreachable."
        }
    }
}
```

- [ ] **Step 4: Create APIClient.swift**

Create `LifeDashboard/LifeDashboard/Networking/APIClient.swift`:

```swift
import Foundation

final class APIClient: Sendable {
    let baseURL: URL
    private let authToken: String
    private let session: URLSession
    private let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy

    init(
        baseURL: URL,
        authToken: String,
        session: URLSession = .shared,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase
    ) {
        self.baseURL = baseURL
        self.authToken = authToken
        self.session = session
        self.keyDecodingStrategy = keyDecodingStrategy
    }

    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError
            where urlError.code == .cannotConnectToHost
            || urlError.code == .networkConnectionLost
            || urlError.code == .timedOut
        {
            throw APIError.backendUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = keyDecodingStrategy
            decoder.dateDecodingStrategy = .iso8601
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter APIClientTests`

Expected: All 4 tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Networking/ LifeDashboardTests/Networking/
git commit -m "feat: add APIClient and APIError with mock-based tests"
```

---

## Task 9: Networking — Domain Clients

**Files:**
- Create: `LifeDashboard/LifeDashboard/Networking/VaultAPIClient.swift`
- Create: `LifeDashboard/LifeDashboard/Networking/FitnessAPIClient.swift`

- [ ] **Step 1: Create VaultAPIClient.swift**

Create `LifeDashboard/LifeDashboard/Networking/VaultAPIClient.swift`:

```swift
import Foundation

final class VaultAPIClient: Sendable {
    private let client: APIClient

    init(session: URLSession = .shared) {
        self.client = APIClient(
            baseURL: APIConfiguration.Vault.baseURL,
            authToken: APIConfiguration.Vault.authToken,
            session: session,
            keyDecodingStrategy: .useDefaultKeys
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

- [ ] **Step 2: Create FitnessAPIClient.swift**

Create `LifeDashboard/LifeDashboard/Networking/FitnessAPIClient.swift`:

```swift
import Foundation

final class FitnessAPIClient: Sendable {
    private let client: APIClient

    init(session: URLSession = .shared) {
        self.client = APIClient(
            baseURL: APIConfiguration.Fitness.baseURL,
            authToken: APIConfiguration.Fitness.authToken,
            session: session,
            keyDecodingStrategy: .convertFromSnakeCase
        )
    }

    func checkHealth() async throws -> HealthCheckResponse {
        try await client.get(path: "/health")
    }

    func getRecentActivities(limit: Int = 10) async throws -> ActivitiesRecentResponse {
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

    func getHealthToday() async throws -> DailyHealthResponse {
        try await client.get(path: "/api/v1/health/today")
    }

    func getHealthRecent(days: Int = 7) async throws -> HealthRecentResponse {
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

- [ ] **Step 3: Verify it compiles**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build`

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Networking/VaultAPIClient.swift LifeDashboard/Networking/FitnessAPIClient.swift
git commit -m "feat: add VaultAPIClient and FitnessAPIClient"
```

---

## Task 10: DashboardViewModel

**Files:**
- Create: `LifeDashboard/LifeDashboard/ViewModels/DashboardViewModel.swift`
- Create: `LifeDashboard/LifeDashboardTests/ViewModels/DashboardViewModelTests.swift`

- [ ] **Step 1: Write failing test**

Create `LifeDashboard/LifeDashboardTests/ViewModels/DashboardViewModelTests.swift`:

```swift
import XCTest
@testable import LifeDashboard

@MainActor
final class DashboardViewModelTests: XCTestCase {

    func testRefreshSetsLastRefreshed() async {
        let vm = DashboardViewModel()
        XCTAssertNil(vm.lastRefreshed)
        await vm.refresh()
        XCTAssertNotNil(vm.lastRefreshed)
        XCTAssertFalse(vm.isLoading)
    }

    func testRefreshCollectsErrorsWhenBackendsDown() async {
        let vm = DashboardViewModel()
        await vm.refresh()
        XCTAssertFalse(vm.errors.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter DashboardViewModelTests`

Expected: Compilation error — `DashboardViewModel` not found.

- [ ] **Step 3: Create DashboardViewModel.swift**

Create `LifeDashboard/LifeDashboard/ViewModels/DashboardViewModel.swift`:

```swift
import Foundation

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

    var localizedDescription: String {
        switch self {
        case .vault(let e): return "Investments: \(e.localizedDescription)"
        case .fitness(let e): return "Fitness: \(e.localizedDescription)"
        case .health(let e): return "Health: \(e.localizedDescription)"
        }
    }
}

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

        async let vaultErrors = fetchVault()
        async let fitnessErrors = fetchFitness()

        let (ve, fe) = await (vaultErrors, fitnessErrors)
        errors = ve + fe

        lastRefreshed = Date()
        isLoading = false
    }

    private func fetchVault() async -> [DashboardError] {
        var errs: [DashboardError] = []
        do {
            async let dashboard = vaultClient.getDashboard()
            async let projection = vaultClient.getFireProjection()
            let (d, p) = try await (dashboard, projection)
            self.vaultDashboard = d
            self.fireProjection = p
        } catch {
            errs.append(.vault(error))
        }
        return errs
    }

    private func fetchFitness() async -> [DashboardError] {
        var errs: [DashboardError] = []

        async let runResult: Void = {
            do {
                async let activities = self.fitnessClient.getRecentActivities(limit: 5)
                async let summary = self.fitnessClient.getActivitySummary(period: "week")
                let (a, s) = try await (activities, summary)
                self.recentActivities = a.activities
                self.activitySummary = s
            } catch {
                errs.append(.fitness(error))
            }
        }()

        async let healthResult: Void = {
            do {
                self.healthToday = try await self.fitnessClient.getHealthToday()
            } catch {
                errs.append(.health(error))
            }
        }()

        _ = await (runResult, healthResult)
        return errs
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test --filter DashboardViewModelTests`

Expected: Both tests PASS. (The backends aren't running, so `refresh()` will collect errors but `lastRefreshed` will be set and `isLoading` will be false.)

- [ ] **Step 5: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/ViewModels/DashboardViewModel.swift LifeDashboardTests/ViewModels/DashboardViewModelTests.swift
git commit -m "feat: add DashboardViewModel with parallel fetch and error isolation"
```

---

## Task 11: Views — Shared Components

**Files:**
- Create: `LifeDashboard/LifeDashboard/Views/Components/GlassCard.swift`
- Create: `LifeDashboard/LifeDashboard/Views/Components/MetricView.swift`
- Create: `LifeDashboard/LifeDashboard/Views/Components/StatusBar.swift`

Reference: `LifeDashboard/Assets/stitch_unified_life_metrics_dashboard/DESIGN.md` — glass cards use semi-transparent fill with backdrop blur, 1px inner stroke, 16px internal padding, 16px corner radius.

- [ ] **Step 1: Create GlassCard.swift**

Create `LifeDashboard/LifeDashboard/Views/Components/GlassCard.swift`:

```swift
import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
```

- [ ] **Step 2: Create MetricView.swift**

Create `LifeDashboard/LifeDashboard/Views/Components/MetricView.swift`:

```swift
import SwiftUI

struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
        }
    }
}
```

- [ ] **Step 3: Create StatusBar.swift**

Create `LifeDashboard/LifeDashboard/Views/Components/StatusBar.swift`:

```swift
import SwiftUI

struct StatusBar: View {
    let lastRefreshed: Date?
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("Refreshing...")
                    .foregroundStyle(.secondary)
            } else if let date = lastRefreshed {
                Text("Last updated \(date.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(isLoading)
            .keyboardShortcut("r", modifiers: .command)
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 4: Verify it compiles**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build`

Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Views/Components/
git commit -m "feat: add GlassCard and StatusBar shared components"
```

---

## Task 12: Views — Panels and Dashboard Layout

**Files:**
- Create: `LifeDashboard/LifeDashboard/Views/FitnessPanel.swift`
- Create: `LifeDashboard/LifeDashboard/Views/HealthPanel.swift`
- Create: `LifeDashboard/LifeDashboard/Views/InvestmentsPanel.swift`
- Create: `LifeDashboard/LifeDashboard/Views/DashboardView.swift`
- Modify: `LifeDashboard/LifeDashboard/App/LifeDashboardApp.swift`

- [ ] **Step 1: Create FitnessPanel.swift**

Create `LifeDashboard/LifeDashboard/Views/FitnessPanel.swift`:

```swift
import SwiftUI

struct FitnessPanel: View {
    let activities: [Activity]
    let summary: ActivitySummaryResponse?
    let error: DashboardError?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Fitness", systemImage: "figure.run")
                    .font(.headline)
                    .foregroundStyle(.blue)

                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if activities.isEmpty && summary == nil {
                    Text("No recent activities")
                        .foregroundStyle(.secondary)
                } else {
                    if let latest = activities.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Run")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                MetricView(
                                    label: "Distance",
                                    value: String(format: "%.1f mi", latest.distanceMiles)
                                )
                                MetricView(
                                    label: "Pace",
                                    value: latest.paceMinPerMile.map {
                                        String(format: "%.1f min/mi", $0)
                                    } ?? "—"
                                )
                                MetricView(
                                    label: "Date",
                                    value: String(latest.startDateLocal.prefix(10))
                                )
                            }
                        }
                        Divider()
                    }

                    if let summary {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("This Week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                MetricView(
                                    label: "Total Miles",
                                    value: String(format: "%.1f", summary.totalDistanceMiles)
                                )
                                MetricView(
                                    label: "Runs",
                                    value: "\(summary.totalRuns)"
                                )
                                MetricView(
                                    label: "Avg Pace",
                                    value: summary.averagePaceMinPerMile.map {
                                        String(format: "%.1f", $0)
                                    } ?? "—"
                                )
                                MetricView(
                                    label: "Streak",
                                    value: "\(summary.streakDays)d"
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

```

- [ ] **Step 2: Create HealthPanel.swift**

Create `LifeDashboard/LifeDashboard/Views/HealthPanel.swift`:

```swift
import SwiftUI

struct HealthPanel: View {
    let healthToday: DailyHealthResponse?
    let error: DashboardError?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Health", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)

                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if let health = healthToday {
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sleep")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let score = health.sleep.score {
                                MetricView(label: "Score", value: "\(score)")
                            }
                            if let total = health.sleep.totalSleepSeconds {
                                let hours = Double(total) / 3600.0
                                MetricView(label: "Duration", value: String(format: "%.1fh", hours))
                            }
                            if let eff = health.sleep.efficiency {
                                MetricView(label: "Efficiency", value: String(format: "%.0f%%", eff))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recovery")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let score = health.recovery.score {
                                MetricView(label: "Score", value: "\(score)")
                            }
                            if let rhr = health.recovery.restingHeartRate {
                                MetricView(label: "RHR", value: String(format: "%.0f bpm", rhr))
                            }
                            if let hrv = health.recovery.hrv {
                                MetricView(label: "HRV", value: String(format: "%.0f ms", hrv))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Strain")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let score = health.strain.score {
                                MetricView(label: "Score", value: String(format: "%.1f", score))
                            }
                            if let cal = health.strain.activeCalories {
                                MetricView(label: "Active Cal", value: "\(cal)")
                            }
                        }
                    }

                    Text("Source: \(health.provider.capitalized)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No health data for today")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Create InvestmentsPanel.swift**

Create `LifeDashboard/LifeDashboard/Views/InvestmentsPanel.swift`:

```swift
import SwiftUI

struct InvestmentsPanel: View {
    let dashboard: VaultDashboardResponse?
    let fireProjection: FIREProjectionResponse?
    let error: DashboardError?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundStyle(.green)

                if let error {
                    Text(error.localizedDescription)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if let data = dashboard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Net Worth")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(data.totalNetWorth, format: .currency(code: "USD"))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allocation")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 16) {
                            CategoryPill(name: "Stocks", value: data.categoryTotals.stocks)
                            CategoryPill(name: "Crypto", value: data.categoryTotals.crypto)
                            CategoryPill(name: "Cash", value: data.categoryTotals.cash)
                            CategoryPill(name: "Retirement", value: data.categoryTotals.retirement)
                        }
                    }

                    if let fire = fireProjection {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FIRE Progress")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                MetricView(
                                    label: "Lean FIRE",
                                    value: fire.fireTargets.leanFire.targetAge.map { "Age \($0)" } ?? "—"
                                )
                                MetricView(
                                    label: "FIRE",
                                    value: fire.fireTargets.fire.targetAge.map { "Age \($0)" } ?? "—"
                                )
                                MetricView(
                                    label: "Savings Rate",
                                    value: fire.savingsRate.map {
                                        String(format: "%.0f%%", $0 * 100)
                                    } ?? "—"
                                )
                                if let assessment = fire.goalAssessment {
                                    MetricView(
                                        label: "Status",
                                        value: assessment.status.capitalized
                                    )
                                }
                            }
                        }
                    }
                } else {
                    Text("No portfolio data")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CategoryPill: View {
    let name: String
    let value: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
    }
}
```

- [ ] **Step 4: Create DashboardView.swift**

Create `LifeDashboard/LifeDashboard/Views/DashboardView.swift`:

```swift
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(
                lastRefreshed: viewModel.lastRefreshed,
                isLoading: viewModel.isLoading
            ) {
                Task { await viewModel.refresh() }
            }

            ScrollView {
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        FitnessPanel(
                            activities: viewModel.recentActivities,
                            summary: viewModel.activitySummary,
                            error: viewModel.errors.first { $0.id == "fitness" }
                        )
                        HealthPanel(
                            healthToday: viewModel.healthToday,
                            error: viewModel.errors.first { $0.id == "health" }
                        )
                    }

                    InvestmentsPanel(
                        dashboard: viewModel.vaultDashboard,
                        fireProjection: viewModel.fireProjection,
                        error: viewModel.errors.first { $0.id == "vault" }
                    )
                }
                .padding(20)
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.07))
        .task {
            await viewModel.refresh()
        }
    }
}
```

- [ ] **Step 5: Update LifeDashboardApp.swift**

Replace the contents of `LifeDashboard/LifeDashboard/App/LifeDashboardApp.swift`:

```swift
import SwiftUI

@main
struct LifeDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowResizability(.contentMinSize)
    }
}
```

- [ ] **Step 6: Verify it compiles**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift build`

Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard
git add LifeDashboard/Views/ LifeDashboard/App/LifeDashboardApp.swift
git commit -m "feat: add dashboard views with fitness, health, and investments panels"
```

---

## Task 13: Run All Tests

- [ ] **Step 1: Run the full test suite**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/LifeDashboard && swift test`

Expected: All tests PASS.

- [ ] **Step 2: Run FitnessTracker backend tests to verify no regressions**

Run: `cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend && PYTHONPATH=. pytest tests/unit/ -v`

Expected: All tests PASS (including the new debug auth tests).

---

## Task 14: Integration Verification (Manual)

This is a manual verification step. Start both backends and the app.

- [ ] **Step 1: Start FitnessTracker backend**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/FitnessTracker/fitness-backend
# Ensure .env has DEBUG_AUTH_ENABLED=true
make dev
```

Verify: `curl http://localhost:8000/health` returns `{"status": "healthy", ...}`

- [ ] **Step 2: Start VaultTracker backend**

```bash
cd /Users/calebngai/Desktop/Agentic-Engineering-Projects/VaultTracker/VaultTrackerAPI
# Ensure .env has DEBUG_AUTH_ENABLED=true
./start.sh
```

Verify: `curl -H "Authorization: Bearer vaulttracker-debug-user" http://localhost:8001/api/v1/dashboard` returns portfolio data.

- [ ] **Step 3: Verify debug auth on FitnessTracker**

```bash
curl -H "Authorization: Bearer fitnesstracker-debug-user" http://localhost:8000/api/v1/users/me
```

Expected: Returns user object with `supabase_id: "debug-user"`.

- [ ] **Step 4: Run the dashboard app**

Build and run from Xcode or via `swift run` (Xcode recommended for GUI). Verify:

- [ ] Investments panel shows portfolio data from VaultTracker
- [ ] Fitness panel shows activity data (or "No recent activities" if Strava not OAuth'd)
- [ ] Health panel shows health data (or "No health data" if Whoop not OAuth'd)
- [ ] Cmd+R refreshes all panels
- [ ] Killing VaultTracker backend → investments panel shows error, other panels still work
- [ ] Killing FitnessTracker backend → fitness/health panels show error, investments panel still works

- [ ] **Step 5: Final commit with any adjustments**

If any fixes were needed during integration testing, commit them with a descriptive message.
