# Life Dashboard — Design Spec

**Date:** 2026-05-17 (UI revamp: 2026-05-24)
**Status:** Implemented (V1 + Premium Dark Cockpit UI)

## Context

Caleb has two personal projects — **VaultTracker** (investment portfolio tracker, production-ready) and **FitnessTracker** (fitness platform, backend Phase 3 of 11). Rather than building separate frontends for each, the goal is a unified **macOS dashboard app** that aggregates key data from both backends into a single daily-glance view.

The dashboard is a **read-only aggregation layer** — each backend stays independent and owns its domain. The dashboard simply consumes their APIs.

## Decision Record

| Question | Decision |
|----------|----------|
| Dashboard type | Quick-glance overview + aggregation layer (not a deep interaction hub) |
| Platform | Native macOS app (SwiftUI) |
| Distribution | Locally signed .app via Xcode Archive → Export (no TestFlight, no App Store) |
| Hosting | Both backends run locally on the same machine |
| Fitness data source | FitnessTracker backend handles Strava integration; dashboard reads from backend |
| Health data source | FitnessTracker backend handles Oura/Whoop integration; dashboard reads from backend |
| Wearable support | One provider at a time (Oura or Whoop), abstracted behind common schema |
| Standalone FitnessTracker frontend | Deferred — dashboard is the primary consumer for now |
| UI/UX design | To be designed separately; this spec covers architecture and structure only |

## System Architecture

```
┌─────────────────────────────────────────────┐
│        macOS Dashboard App (SwiftUI)        │
│        Locally signed .app                  │
│                                             │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────────┐ │
│  │ Fitness View  │ │ Health View  │ │ Investments View│ │
│  └──────┬───────┘ └──────┬───────┘ └────────┬────────┘ │
└─────────┼───────────┼─────────────────┼────────────┘
          │           │                 │
          │      localhost:8000         │
          │       (both endpoints)  localhost:8001
          │                             │
          ▼                             ▼
┌──────────────────┐  ┌──────────────────────┐
│ FitnessTracker   │  │ VaultTracker API     │
│ Backend (FastAPI)│  │ (FastAPI)            │
│ + Strava sync    │  │ + Local Postgres     │
│ + Oura/Whoop sync│  │                      │
│ + Local Postgres │  │                      │
└──────────────────┘  └──────────────────────┘
```

Both backends are self-hosted on the same machine. All communication is over localhost.

## Project Structure

```
LifeDashboard/
├── Package.swift                            # Swift Package (macOS 14+)
├── LifeDashboard/
│   ├── App/LifeDashboardApp.swift           # Root → AppNavigation
│   ├── Configuration/APIConfiguration.swift
│   ├── Theme/                               # AppTheme, typography, glassCard modifier
│   ├── Navigation/                          # Sidebar + destination routing
│   ├── Models/                              # Vault, Fitness, Health Codable types
│   ├── Networking/                          # APIClient, domain clients, protocols
│   ├── ViewModels/DashboardViewModel.swift  # Shared across all pages
│   └── Views/                               # Dashboard cards, section pages, components
├── LifeDashboardTests/
├── Assets/stitch_unified_life_metrics_dashboard/
└── CLAUDE.md
```

## UI Architecture (2026-05-24 Revamp)

The app uses a **Premium Dark Cockpit** layout with a custom 240px sidebar (no `NavigationSplitView` vibrancy conflicts on pure-black background).

```
AppNavigation (owns DashboardViewModel)
├── SidebarView → NavigationDestination (dashboard, investments, fitness, recovery, settings)
├── HeaderBar (title, search pill, status, refresh)
└── Content
    ├── DashboardView — card grid (net worth, run, recovery/sleep, schedule, tasks, timer)
    ├── InvestmentsView / FitnessView / RecoveryView — section detail pages
    └── SettingsView — static local config display
```

**Design system:** `AppTheme` (colors, spacing, radius), `AppTypography`, `.glassCard()` modifier.

**Reusable components:** `RingGauge`, `SparklineChart` (Swift Charts), `ProgressBarView`, `.glassCard()` modifier, `MetricView`.

**Local-only UI state (no API):** daily schedule timeline (static), task checkboxes and deep-work timer via `CockpitLocalState` (survives tab switches, not persisted).

**Unchanged:** networking layer, Codable models, `DashboardViewModel` fetch orchestration, debug auth tokens, parallel per-domain error handling.

## Architectural Decisions

### Networking
Simple `URLSession` + `async/await`. No third-party HTTP libraries needed — two localhost APIs with a handful of endpoints each. A thin `APIClient` base class handles JSON decoding, error mapping, and auth headers.

### Auth
Both backends support debug auth mode. The dashboard uses static debug tokens stored in `APIConfiguration.swift`. No Firebase/Supabase needed since everything is local.

### Data Flow
`DashboardViewModel` calls both API clients in parallel via `async let`, combines results, and publishes to views via `@Published` properties. No caching or persistence — every launch/refresh fetches fresh data.

### Configuration
`APIConfiguration` holds base URLs (`localhost:8000` for fitness, `localhost:8001` for vault) and auth credentials. Easy to swap if hosting changes later.

### No Persistence
Pure network-driven. No CoreData, SwiftData, or local caching. The backends are the source of truth.

## Dashboard Content (V1)

### Fitness Panel
- Latest run stats from Strava (distance, pace, date)
- Weekly/monthly running summary (total miles, avg pace)
- Streak or consistency indicator

### Health Panel
- Sleep: score, total duration, stage breakdown (deep/REM/light), efficiency
- Recovery: score, resting heart rate, HRV
- Strain/Activity: score, active calories
- Source indicator (Oura or Whoop)

### Investments Panel
- Current net worth (total)
- Daily/weekly change ($ and %)
- Top holdings or allocation breakdown
- FIRE progress indicator

### Shared
- Last refreshed timestamp
- Manual refresh button

## API Dependencies

### From FitnessTracker Backend (needs to be built)
The backend currently has `GET /health` and `GET /api/v1/users/me` only. New endpoints needed:

**Running (Strava):**
- `GET /api/v1/activities/recent` — latest Strava activities
- `GET /api/v1/activities/summary` — weekly/monthly aggregates

**Health (Oura/Whoop):**
- `GET /api/v1/health/today` — today's sleep, recovery, strain scores
- `GET /api/v1/health/recent` — last 7 days of daily health records
- `GET /api/v1/health/summary` — averages over configurable period

This requires adding Strava OAuth, Oura/Whoop OAuth, and API integrations to the FitnessTracker backend. Health data from both wearables is normalized into a common `daily_health_record` schema (see `2026-05-17-wearable-api-reference.md`).

### From VaultTracker Backend (already exists)
- `GET /api/v1/dashboard` — net worth, category breakdown, holdings
- `GET /api/v1/net-worth-history` — historical chart data
- `GET /api/v1/fire/profile` — FIRE progress

## Port Configuration

Both backends currently default to port 8000. VaultTracker needs to be configured to run on port 8001 (via env var or start command flag) to avoid conflicts.

## Build Order

### Phase 1a: FitnessTracker Backend — Strava Integration
- Add Strava OAuth flow and API client to existing FastAPI backend
- New endpoints: `GET /api/v1/activities/recent`, `GET /api/v1/activities/summary`
- Store synced activity data in existing Postgres DB
- Builds on top of existing Phase 3 work

### Phase 1b: FitnessTracker Backend — Wearable Integration (Oura/Whoop)
- Add OAuth flow for Oura and/or Whoop (support one active provider per user)
- Sync daily sleep, recovery, and strain/activity data
- Normalize into common `daily_health_record` schema in Postgres
- New endpoints: `GET /api/v1/health/today`, `GET /api/v1/health/recent`, `GET /api/v1/health/summary`
- See `2026-05-17-wearable-api-reference.md` for API details and common schema

### Phase 2: Port Configuration
- Configure VaultTracker API to run on port 8001 (or make configurable via env var)
- Update CORS/client configs as needed

### Phase 3: macOS Dashboard App
- Scaffold Xcode project with structure above
- Build networking layer (VaultAPIClient + FitnessAPIClient)
- Build DashboardViewModel that fetches from both APIs
- Build views (UI/UX to be designed separately)
- Archive and export as locally signed .app

> **Note:** Phase 3 can start in parallel with Phase 1 — the VaultTracker panel and networking layer can be built while Strava integration is in progress, using mock fitness data.

## Verification

- Run both backends locally on separate ports and confirm no conflicts
- Dashboard app fetches and displays VaultTracker data correctly
- Dashboard app fetches and displays FitnessTracker/Strava data correctly
- Dashboard app fetches and displays health data (sleep/recovery/strain) correctly
- App launches independently from Xcode (via archived .app)
- Manual refresh re-fetches all data
