# LifeDashboard

Native macOS SwiftUI app aggregating **FitnessTracker** (`localhost:8000`) and **VaultTracker** (`localhost:8001`).

## Build and test

```bash
cd LifeDashboard
swift build
swift test
swiftlint lint
```

Open `Package.swift` in Xcode to run the GUI app (minimum window 1200×800). Root view is `AppNavigation` (sidebar + cockpit dashboard). **Cmd+R** in the header triggers refresh.

UI revamp plan: [Documentation/Plans/2026-05-24-life-dashboard-ui-revamp-plan.md](Documentation/Plans/2026-05-24-life-dashboard-ui-revamp-plan.md)

## Local backends (manual integration)

1. **FitnessTracker** — `make dev` in `FitnessTracker/fitness-backend` with `DEBUG_AUTH_ENABLED=true`
2. **VaultTracker** — `./start.sh` in `VaultTracker/VaultTrackerAPI` (port **8001**) with `DEBUG_AUTH_ENABLED=true`

Verify:

```bash
curl http://localhost:8000/health
curl -H "Authorization: Bearer fitnesstracker-debug-user" http://localhost:8000/api/v1/users/me
curl -H "Authorization: Bearer vaulttracker-debug-user" http://localhost:8001/api/v1/dashboard
```

## Auth tokens (local only)

Configured in `LifeDashboard/Configuration/APIConfiguration.swift`:

- Fitness: `fitnesstracker-debug-user` (requires FitnessTracker `DEBUG_AUTH_ENABLED`)
- Vault: `vaulttracker-debug-user` (requires VaultTracker `DEBUG_AUTH_ENABLED`)

## Architecture docs

- [Documentation/2026-05-17-life-dashboard-design.md](Documentation/2026-05-17-life-dashboard-design.md)
- [Documentation/2026-05-20-life-dashboard-tech-spec.md](Documentation/2026-05-20-life-dashboard-tech-spec.md)
- [Documentation/Plans/2026-05-20-life-dashboard-cursor-plan.md](Documentation/Plans/2026-05-20-life-dashboard-cursor-plan.md)
- [Documentation/Plans/2026-05-24-life-dashboard-ui-revamp-plan.md](Documentation/Plans/2026-05-24-life-dashboard-ui-revamp-plan.md)
