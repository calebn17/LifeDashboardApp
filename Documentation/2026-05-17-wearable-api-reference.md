# Wearable API Reference — Oura Ring & Whoop

**Date:** 2026-05-17
**Purpose:** Implementation reference for adding sleep, strain, and recovery data to the FitnessTracker backend
**Oura Docs:** https://cloud.ouraring.com/docs/
**Whoop Docs:** https://developer.whoop.com/api/

---

## Quick Comparison

| Feature | Oura Ring | Whoop |
|---------|-----------|-------|
| Auth | OAuth 2.0 + Personal Access Token option | OAuth 2.0 only |
| Rate limits | 5,000 req / 5 min | 100 req / min, 10,000 / day |
| Daily summaries | Yes (`daily_*` endpoints) | No (cycle-based, compute yourself) |
| Webhooks | Undocumented (may exist) | Yes (sleep, recovery, workout events) |
| Sleep data | Score, stage durations, HRV, HR, efficiency | Score, stage durations, sleep debt, respiratory rate |
| Recovery | Readiness score + temperature deviation | Recovery score (0-100%) + HRV + resting HR + SpO2 |
| Strain/Activity | Activity score + steps + calories | Strain score (0-21) + HR zones + kilojoules |
| Data model | Calendar-day based | Cycle-based (sleep-to-sleep) |
| Best for | Sleep quality, readiness, temperature trends | Strain quantification, HR zone tracking, recovery |

---

## Oura Ring API (V2)

### Authentication

**OAuth 2.0 Authorization Code flow:**
1. Redirect to `GET https://cloud.ouraring.com/oauth/authorize` with `client_id`, `redirect_uri`, `response_type=code`, `state`
2. Exchange code at `POST https://api.ouraring.com/oauth/token`
3. Refresh tokens are single-use — store new one on each refresh

**Personal Access Token (simpler for single-user):**
- Generate at Oura cloud dashboard
- Use as `Authorization: Bearer {token}`
- Good for local/dev use — no OAuth flow needed

**Scopes:** `email`, `personal`, `daily`, `heartrate`, `workout`, `tag`, `session`, `spo2`

### Endpoints

**Base URL:** `https://api.ouraring.com/v2/usercollection`

All endpoints accept `start_date` and `end_date` query params (YYYY-MM-DD).

#### Sleep

```
GET /v2/usercollection/daily_sleep?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
```
Daily sleep summary.

| Field | Type | Notes |
|-------|------|-------|
| `day` | string | Date (YYYY-MM-DD) |
| `score` | int | Overall sleep score (0-100) |
| `total_sleep_duration` | int | seconds |
| `deep_sleep_duration` | int | seconds |
| `rem_sleep_duration` | int | seconds |
| `light_sleep_duration` | int | seconds |
| `efficiency` | int | Sleep efficiency % |
| `average_heart_rate` | float | bpm during sleep |
| `average_hrv` | float | HRV during sleep |
| `lowest_heart_rate` | int | bpm |
| `bedtime_start` | string | ISO 8601 |
| `bedtime_end` | string | ISO 8601 |

```
GET /v2/usercollection/sleep
```
Detailed per-session sleep data (multiple sessions per night possible).

#### Recovery (Readiness)

```
GET /v2/usercollection/daily_readiness?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
```

| Field | Type | Notes |
|-------|------|-------|
| `day` | string | Date |
| `score` | int | Readiness score (0-100) |
| `temperature_deviation` | float | Degrees from baseline |
| `contributors` | object | Breakdown of score factors |

#### Activity (Strain equivalent)

```
GET /v2/usercollection/daily_activity?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
```

| Field | Type | Notes |
|-------|------|-------|
| `day` | string | Date |
| `score` | int | Activity score (0-100) |
| `steps` | int | Total steps |
| `active_calories` | int | kcal |
| `total_calories` | int | kcal |
| `equivalent_walking_distance` | float | meters |

#### Other Useful Endpoints

| Endpoint | Purpose |
|----------|---------|
| `/v2/usercollection/heartrate` | HR samples |
| `/v2/usercollection/daily_spo2` | Blood oxygen |
| `/v2/usercollection/daily_stress` | Stress measurements |
| `/v2/usercollection/personal_info` | User profile |

### Rate Limits

- **5,000 requests per 5-minute window**
- HTTP 429 on exceeding
- Very generous for a single-user app

---

## Whoop API (V2)

### Authentication

**OAuth 2.0 Authorization Code flow only (no personal token option):**
1. Redirect to `GET https://api.prod.whoop.com/oauth/oauth2/auth` with `client_id`, `redirect_uri`, `response_type=code`, `state` (min 8 chars), `scope`
2. Exchange code at `POST https://api.prod.whoop.com/oauth/oauth2/token`
3. Include `offline` scope to get refresh tokens
4. Redirect URIs must be HTTPS or custom scheme (`whoop://`)

**App registration:** https://developer-dashboard.whoop.com (max 5 apps per developer)

**Scopes:** `read:cycles`, `read:recovery`, `read:sleep`, `read:workout`, `read:profile`, `read:body_measurement`, `offline`

### Data Model — Cycle-Based

Whoop uses **physiological cycles** (sleep onset to next sleep onset), not calendar days. Each cycle contains:
- One strain score (on the cycle itself)
- One associated sleep
- One associated recovery
- Zero or more workouts

### Endpoints

**Base URL:** `https://api.prod.whoop.com/developer`

All list endpoints support `start`, `end` (ISO 8601) and cursor-based pagination via `nextToken`.

#### Cycles (Daily Strain)

```
GET /developer/v2/cycle?start=ISO8601&end=ISO8601
```

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | Cycle ID |
| `start` / `end` | string | ISO 8601 |
| `score.strain` | float | 0-21 scale |
| `score.kilojoule` | float | Energy burned |
| `score.average_heart_rate` | float | bpm |
| `score.max_heart_rate` | float | bpm |
| `score_state` | string | "SCORED", "PENDING_SCORE", "UNSCORABLE" |

#### Sleep

```
GET /developer/v2/activity/sleep?start=ISO8601&end=ISO8601
```
Or per-cycle: `GET /developer/v2/cycle/{cycleId}/sleep`

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | |
| `nap` | bool | True if nap vs primary sleep |
| `total_in_bed_time_milli` | int | ms |
| `total_awake_time_milli` | int | ms |
| `total_light_sleep_time_milli` | int | ms |
| `total_slow_wave_sleep_time_milli` | int | ms (deep sleep) |
| `total_rem_sleep_time_milli` | int | ms |
| `sleep_cycle_count` | int | |
| `disturbance_count` | int | |
| `respiratory_rate` | float | breaths/min |
| `sleep_performance_percentage` | float | % of sleep need met |
| `sleep_consistency_percentage` | float | % |
| `sleep_efficiency_percentage` | float | % |
| Sleep need breakdown | | `baseline_milli`, `need_from_sleep_debt_milli`, `need_from_recent_strain_milli`, `need_from_recent_nap_milli` |

#### Recovery

```
GET /developer/v2/recovery?start=ISO8601&end=ISO8601
```
Or per-cycle: `GET /developer/v2/cycle/{cycleId}/recovery`

| Field | Type | Notes |
|-------|------|-------|
| `score.recovery_score` | float | 0-100% |
| `score.resting_heart_rate` | float | bpm |
| `score.hrv_rmssd_milli` | float | HRV in ms |
| `score.spo2_percentage` | float | Blood oxygen % |
| `score.skin_temp_celsius` | float | |
| `score.user_calibrating` | bool | True during initial calibration |

#### Workouts

```
GET /developer/v2/activity/workout?start=ISO8601&end=ISO8601
```

| Field | Type | Notes |
|-------|------|-------|
| `sport_name` | string | 100+ sport types |
| `score.strain` | float | Per-workout strain (0-21) |
| `score.average_heart_rate` | float | bpm |
| `score.max_heart_rate` | float | bpm |
| `score.kilojoule` | float | |
| `score.distance_meter` | float | |
| `score.altitude_gain_meter` | float | |
| HR zone durations | int | `zone_zero_milli` through `zone_five_milli` |

### Webhooks

Configured via Developer Dashboard. Events:
- `sleep.updated`, `sleep.deleted`
- `recovery.updated`, `recovery.deleted`
- `workout.updated`, `workout.deleted`

Creation events are sent as `.updated`. Payload includes `user_id`, `id`, `type`, `trace_id`.
Verify via `X-WHOOP-Signature` header (HMAC-SHA256 with client secret).

### Rate Limits

- **100 requests per minute**
- **10,000 requests per day**
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- HTTP 429 on exceeding

---

## Unit Conversions

```
milliseconds → hours:    ms / 3_600_000
milliseconds → minutes:  ms / 60_000
seconds → hours:         s / 3600
```

---

## Sync Strategy for FitnessTracker Backend

### Approach: Support One Wearable at a Time

The user will have either an Oura or Whoop (or switch between them). The backend should:
1. Store a `wearable_provider` config per user (`oura` or `whoop`)
2. Abstract the data into a common schema (see below)
3. Sync on dashboard refresh or on a schedule

### Common Schema for Storage

Normalize both APIs into a unified daily health record:

```
daily_health_record:
  date                    DATE
  provider                TEXT        -- "oura" or "whoop"
  
  # Sleep
  sleep_score             INT         -- 0-100 (both provide this)
  total_sleep_seconds     INT         -- convert Whoop ms to seconds
  deep_sleep_seconds      INT
  rem_sleep_seconds       INT
  light_sleep_seconds     INT
  sleep_efficiency        FLOAT       -- percentage
  
  # Recovery
  recovery_score          INT         -- Oura: readiness score, Whoop: recovery score
  resting_heart_rate      FLOAT       -- bpm
  hrv                     FLOAT       -- ms (Oura: average_hrv, Whoop: hrv_rmssd_milli)
  spo2                    FLOAT       -- % (Whoop direct, Oura via daily_spo2)
  
  # Strain / Activity
  strain_score            FLOAT       -- Oura: activity score (0-100), Whoop: strain (0-21)
  active_calories         INT
  total_calories          INT
  steps                   INT         -- Oura only (Whoop doesn't track steps)
```

### Sync Flow (Oura — simpler)
1. Call `daily_sleep`, `daily_readiness`, `daily_activity` with date range
2. Map to common schema
3. Store in Postgres

### Sync Flow (Whoop — cycle-based)
1. Fetch cycles for date range via `GET /v2/cycle`
2. For each cycle, fetch recovery and sleep (or batch via list endpoints)
3. Map cycle date to calendar date (use cycle `end` date)
4. Map to common schema
5. Store in Postgres

### Dashboard Endpoints to Add

```
GET /api/v1/health/today        -- today's sleep, recovery, strain
GET /api/v1/health/recent       -- last 7 days of daily health records
GET /api/v1/health/summary      -- averages over configurable period
```

---

## App Registration Links

- **Oura:** https://cloud.ouraring.com/console/personal-access-tokens (personal token) or create an app via the Oura developer portal
- **Whoop:** https://developer-dashboard.whoop.com (max 5 apps)
- **Strava:** https://www.strava.com/settings/api

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 401 | Token expired/revoked | Refresh; if fails, re-auth |
| 403 | Insufficient scope | Re-authorize with correct scopes |
| 429 | Rate limited | Back off, check rate limit headers |
| 404 | Resource not found | Whoop returns 404 if no recovery for a cycle (normal) |
