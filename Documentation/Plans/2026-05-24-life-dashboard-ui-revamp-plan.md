# Life Dashboard UI Revamp — Premium Dark Cockpit

**Date:** 2026-05-24  
**Status:** Approved  
**Reference:** `Assets/stitch_unified_life_metrics_dashboard/code.html`

## Context

The current LifeDashboard macOS app has a minimal, functional UI with three basic panels (Fitness, Health, Investments) using simple glassmorphism cards on a dark background. This plan transforms it into a premium "Life Intelligence Cockpit" matching the HTML reference — adding sidebar navigation, circular ring gauges, sparkline charts, a schedule/tasks section, and a deep work timer — while preserving the existing ViewModel/networking layer unchanged.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Navigation | Custom `HStack` sidebar | Avoids macOS vibrancy/material conflicts with pure-black background |
| Theme | Centralized `AppTheme` enum | Single source of truth for colors, spacing, typography |
| Grid layout | `HStack` + `layoutPriority` | Simulates 12-column CSS grid proportions |
| Ring gauges | `Circle().trim()` + animated stroke | Lightweight, GPU-accelerated, animatable |
| ViewModel | Lift to `AppNavigation` | All pages share data without redundant API calls |
| Fonts | System fonts for v1 | Inter can be bundled later |
| Schedule/Tasks/Timer | Static/local state | No new APIs required |

## File Changes Overview

### New Files (21)

**Theme (3)**
- `LifeDashboard/Theme/AppTheme.swift` — colors, spacing, radius, Color(hex:) extension
- `LifeDashboard/Theme/AppTypography.swift` — font definitions
- `LifeDashboard/Theme/ViewModifiers.swift` — glass card modifier, .glassCard() extension

**Navigation (3)**
- `LifeDashboard/Navigation/NavigationDestination.swift` — route enum
- `LifeDashboard/Navigation/SidebarView.swift` — 240px sidebar with nav items
- `LifeDashboard/Navigation/AppNavigation.swift` — root container, owns ViewModel

**Components (4)**
- `LifeDashboard/Views/Components/HeaderBar.swift` — top bar with title, search, status
- `LifeDashboard/Views/Components/RingGauge.swift` — circular progress ring
- `LifeDashboard/Views/Components/SparklineChart.swift` — Swift Charts mini line chart
- `LifeDashboard/Views/Components/ProgressBarView.swift` — linear progress bar

**Dashboard Cards (7)**
- `LifeDashboard/Views/Dashboard/DashboardView.swift` — grid assembly
- `LifeDashboard/Views/Dashboard/NetWorthCard.swift` — full-width sparkline card
- `LifeDashboard/Views/Dashboard/RunPerformanceCard.swift` — run metrics + progress
- `LifeDashboard/Views/Dashboard/RecoveryCard.swift` — green ring gauge
- `LifeDashboard/Views/Dashboard/SleepCard.swift` — blue ring gauge
- `LifeDashboard/Views/Dashboard/DailyScheduleCard.swift` — static timeline
- `LifeDashboard/Views/Dashboard/TasksCard.swift` — toggleable checklist
- `LifeDashboard/Views/Dashboard/DeepWorkTimerCard.swift` — countdown timer

**Stub Pages (4)**
- `LifeDashboard/Views/Investments/InvestmentsView.swift`
- `LifeDashboard/Views/Fitness/FitnessView.swift`
- `LifeDashboard/Views/Recovery/RecoveryView.swift`
- `LifeDashboard/Views/Settings/SettingsView.swift`

### Modified Files (3)
- `LifeDashboard/App/LifeDashboardApp.swift` — root becomes `AppNavigation`
- `LifeDashboard/Views/Components/GlassCard.swift` — rewrite with new design system
- `LifeDashboard/Views/Components/MetricView.swift` — restyle with AppTypography

### Deleted Files (5)
- `LifeDashboard/Views/DashboardView.swift` — replaced by Dashboard/DashboardView.swift
- `LifeDashboard/Views/FitnessPanel.swift` — content moves to RunPerformanceCard
- `LifeDashboard/Views/HealthPanel.swift` — splits to RecoveryCard + SleepCard
- `LifeDashboard/Views/InvestmentsPanel.swift` — moves to NetWorthCard + InvestmentsView
- `LifeDashboard/Views/Components/StatusBar.swift` — absorbed into HeaderBar

### Unchanged
All networking, models, configuration, view models.

---

## Implementation Steps

### Step 1: Theme Foundation

**`AppTheme.swift`** — Color constants:
- Background: `#000000`
- Surface: `#131317`
- Card background: `Color.white.opacity(0.05)`
- Card border: `Color.white.opacity(0.10)` (gradient, lit top-left)
- Accent green: `#4edea3` (fitness, recovery, investments)
- Accent blue: `#adc6ff` (sleep, tertiary)
- On-surface: `#e4e1e7`
- On-surface secondary: 60% opacity

Spacing: xs=4, sm=8, md=16, lg=24, xl=32. Radius: card=16, button=8.

**`AppTypography.swift`** — Font scale:
- Display: 40px bold, -0.02em tracking
- Headline: 24px semibold, -0.01em
- HeadlineSm: 20px semibold
- Body: 14px regular
- LabelCaps: 12px semibold, 0.05em tracking, uppercase
- DataMono: 18px medium monospaced

**`ViewModifiers.swift`** — `GlassCardModifier`:
- Configurable padding (default 20)
- Card background fill + ultraThinMaterial at 30% opacity
- Gradient stroke border (white 10% → transparent, topLeading → bottomTrailing)

### Step 2: Navigation Shell

**`NavigationDestination.swift`** — Enum: dashboard, investments, fitness, recovery, settings. Each case provides `icon` (SF Symbol) and `title`.

**`SidebarView.swift`** — 240px fixed width:
- Top: Logo area ("Life Intelligence" bold + "PREMIUM COCKPIT" label-caps in green/60%)
- Middle: Nav items (VStack of buttons, icon + label, active = green text + bg highlight)
- Bottom: User profile (circle avatar, "Alex Mercer", "PRO ACCESS" badge, green status dot)
- Background: `AppTheme.Colors.background` with right border

**`AppNavigation.swift`** — Root layout:
```
HStack(spacing: 0) {
    SidebarView(selection: $selectedDestination)
    VStack(spacing: 0) {
        HeaderBar(title: selectedDestination.title, ...)
        // Content switch
    }
}
```
Owns `@StateObject var viewModel = DashboardViewModel()`.

### Step 3: Header Bar

**`HeaderBar.swift`** — 64px tall:
- Left: page title (headline-sm)
- Left-center: search field (cosmetic, dark pill with magnifying glass)
- Right: green pulse dot + "SYSTEMS OPTIMIZED", notification bell, account circle
- Bottom border + backdrop blur

### Step 4: Reusable Components

**`RingGauge.swift`**:
- Background ring: `Circle().stroke(color.opacity(0.15), lineWidth: 8)`
- Progress ring: `Circle().trim(from: 0, to: progress)` with round lineCap, rotated -90°
- Glow: `.shadow(color: color.opacity(0.4), radius: 8)`
- Center: value text (bold 24px) + subtitle (caption)
- Animates progress on appear

**`SparklineChart.swift`** (Swift Charts, macOS 14+):
- `LineMark` + `AreaMark` with gradient fill
- Hidden axes/legend
- Accepts `[Double]` + accent color

**`ProgressBarView.swift`**:
- Background capsule in dark surface color
- Foreground capsule (progress width) with accent color + glow
- Animatable

### Step 5: Dashboard Cards

**`NetWorthCard.swift`** (full width):
- Header: "TOTAL NET WORTH" label-caps
- Value: display typography (40px bold)
- Change badge: green arrow + "+X.X% VS LAST QUARTER"
- Right side: "INVESTMENTS" and "CASH" totals from categoryTotals
- Bottom: SparklineChart (green, use projectionCurve or placeholder data)

**`RunPerformanceCard.swift`**:
- Header: "RECENT RUN PERFORMANCE"
- 3 metric boxes (dark rounded bg): Distance, Duration, Avg Pace
- Weekly Goal Progress: description + percentage + ProgressBarView
- Data: latest activity + activitySummary (totalDistanceMiles / target)

**`RecoveryCard.swift`**:
- "WHOOP RECOVERY" label
- RingGauge: green, progress = score/100
- Status: "Optimized" / "Ready for strain"

**`SleepCard.swift`**:
- "OURA SLEEP" label
- RingGauge: blue, progress = score/100
- Status: "Restored" + duration formatted

**`DailyScheduleCard.swift`** (static):
- "DAILY SCHEDULE" + calendar icon
- Timeline with vertical connector line + colored dots
- 3 entries: 9:00 AM, 11:30 AM, 2:00 PM

**`TasksCard.swift`** (local state):
- "TODAY'S TASKS" + checklist icon
- 3 toggleable tasks with checkbox UI
- `@State` booleans, no persistence

**`DeepWorkTimerCard.swift`** (local state):
- Horizontal: timer icon (blue bg) + title, countdown + play/pause
- `Timer.publish(every: 1)` driving `@State timeRemaining`
- "MM:SS" in bold tertiary color

### Step 6: Dashboard Assembly

**`DashboardView.swift`** — ScrollView + VStack(spacing: 24):
- Row 1: `NetWorthCard` (full width)
- Row 2: `RunPerformanceCard` (priority 7) + `HStack(RecoveryCard, SleepCard)` (priority 5)
- Row 3: `DailyScheduleCard` (priority 7) + `TasksCard` (priority 5)
- Row 4: `DeepWorkTimerCard` (full width)

### Step 7: Stub Pages

- **InvestmentsView**: Net worth + allocation grid + FIRE progress (restyled from old panel)
- **FitnessView**: Recent activities list + weekly summary
- **RecoveryView**: Large ring gauges for all health metrics
- **SettingsView**: Static — API endpoints, app version, about

### Step 8: App Entry Point

Modify `LifeDashboardApp.swift`:
- Root: `AppNavigation()`
- `.preferredColorScheme(.dark)`
- `.windowStyle(.hiddenTitleBar)` for immersive cockpit
- Keep min 1200×800

### Step 9: Cleanup

Delete old panel files and StatusBar.

---

## Technical Notes

- **ViewModel sharing:** AppNavigation owns `@StateObject`, passes as `@ObservedObject` to pages
- **Grid proportions:** `layoutPriority(7)` + `layoutPriority(5)` with `.frame(maxWidth: .infinity)` ≈ 7:5 split
- **Hidden title bar:** Use `NSWindow.isMovableByWindowBackground = true` via NSViewRepresentable for drag
- **No external deps:** Swift Charts handles sparklines. All other UI is custom SwiftUI.
- **Animations:** Rings animate on appear (0.8s easeInOut). Cards can add hover scale via `.onHover`

## Verification

1. `swift build` — compiles without errors
2. `swift test` — existing tests pass (ViewModel/networking unchanged)
3. Run in Xcode:
   - Sidebar with 5 nav items, Dashboard active
   - All cards render in correct grid layout
   - Ring gauges animate on data load
   - Timer counts down, pause/play works
   - Task checkboxes toggle
   - Sidebar navigation switches pages
   - Window resizes gracefully (min 1200×800)
4. Dark theme: no light elements bleeding through
5. With backends: real data populates Net Worth, Run, Recovery, Sleep cards
