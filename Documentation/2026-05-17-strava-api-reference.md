# Strava API Reference — FitnessTracker Integration

**Date:** 2026-05-17
**Purpose:** Implementation reference for Phase 1 (Strava integration in FitnessTracker backend)
**API Docs:** https://developers.strava.com/docs/reference/

## Authentication (OAuth 2.0)

### Flow
1. Redirect user to `GET https://www.strava.com/oauth/authorize` with `client_id`, `redirect_uri`, `response_type=code`, `scope=activity:read_all`
2. User approves → Strava redirects back with `code` param
3. Exchange code via `POST https://www.strava.com/api/v3/oauth/token` with `client_id`, `client_secret`, `code`, `grant_type=authorization_code`
4. Response includes `access_token`, `refresh_token`, `expires_at`, and `athlete` profile

### Token Lifecycle
- Access tokens expire every **6 hours** (21,600 seconds)
- Refresh via `POST https://www.strava.com/api/v3/oauth/token` with `grant_type=refresh_token`
- **Refresh tokens rotate** — each refresh response returns a new `refresh_token`. Store it every time.
- Refresh proactively when `expires_at` is within ~1 hour

### Scopes
| Scope | Access |
|-------|--------|
| `activity:read` | Public activities only |
| `activity:read_all` | All activities including private (use this) |
| `profile:read_all` | Full athlete profile |

### Deauthorization
`POST https://www.strava.com/oauth/deauthorize` with `access_token` in body.

## Endpoints

### List Athlete Activities
```
GET /athlete/activities
```
**Params:** `before` (epoch), `after` (epoch), `page` (default 1), `per_page` (default 30, max 200)

Primary sync endpoint. Use `after=<last_sync_timestamp>` for incremental sync.

Returns `SummaryActivity` objects (lighter than full detail).

### Get Activity Detail
```
GET /activities/{id}
```
Returns `DetailedActivity` with full stats, splits, laps, gear, map polyline.

### Get Athlete Stats
```
GET /athletes/{id}/stats
```
Returns aggregate totals in three buckets:
- `recent_run_totals` — last 4 weeks
- `ytd_run_totals` — year-to-date
- `all_run_totals` — all-time

Each bucket: `count`, `distance` (meters), `moving_time` (seconds), `elapsed_time`, `elevation_gain`.

**Note:** No weekly or monthly breakdowns — compute these from stored activities.

### Get Activity Laps
```
GET /activities/{id}/laps
```
Per-lap stats: `distance`, `elapsed_time`, `moving_time`, `average_speed`, `average_heartrate`.

### Get Activity Streams
```
GET /activities/{id}/streams?keys=time,distance,heartrate,altitude,cadence
```
Time-series arrays for GPS, heartrate, cadence, altitude, etc. Useful for charts but not needed for V1 dashboard.

## Activity Data Fields (Running-Relevant)

| Field | Type | Unit | Notes |
|-------|------|------|-------|
| `distance` | float | meters | Total distance |
| `moving_time` | int | seconds | Time spent moving |
| `elapsed_time` | int | seconds | Total time including stops |
| `total_elevation_gain` | float | meters | Cumulative climb |
| `average_speed` | float | m/s | Convert: pace (min/mi) = 26.8224 / average_speed |
| `max_speed` | float | m/s | |
| `average_heartrate` | float | bpm | Requires HR monitor |
| `max_heartrate` | float | bpm | |
| `average_cadence` | float | steps/min | |
| `calories` | float | kcal | Strava estimate |
| `start_date` | string | ISO 8601 UTC | |
| `start_date_local` | string | ISO 8601 local | Use for display |
| `timezone` | string | | e.g., "(GMT-08:00) America/Los_Angeles" |
| `sport_type` | string | | "Run", "TrailRun", "VirtualRun" |
| `type` | string | | Legacy field, same purpose as sport_type |
| `splits_metric` | array | | Per-km splits with pace/elevation/HR |
| `pr_count` | int | | Personal records hit |
| `achievement_count` | int | | Strava achievements |
| `gear_id` | string | | Links to shoes via `GET /gear/{id}` |
| `map.summary_polyline` | string | | Encoded route polyline |

## Unit Conversions

```
meters → miles:        distance / 1609.344
m/s → min/mile pace:   26.8224 / speed_m_s
m/s → mph:             speed_m_s * 2.23694
meters → feet:         elevation * 3.28084
```

## Rate Limits

| Limit | Value |
|-------|-------|
| Per 15 minutes | 200 requests |
| Per day | 2,000 requests |
| Scope | Per application (shared across all users) |

**Headers returned:** `X-RateLimit-Limit`, `X-RateLimit-Usage` (format: `15min_usage,daily_usage`)

### Staying Within Limits
- Store all activity data locally after first fetch — never re-fetch what you have
- Use `after` param on `/athlete/activities` for incremental sync
- Batch initial history sync across multiple 15-min windows if needed
- For a single-user local app, rate limits are unlikely to be an issue

## Webhooks (Future Enhancement)

Strava supports push notifications for near-real-time sync. Not needed for V1 but useful later.

### Setup
- One subscription per application
- Register via `POST https://www.strava.com/api/v3/push_subscriptions`
- Strava sends a `GET` with `hub.challenge` for verification — echo it back
- Events arrive as `POST` to your callback URL

### Event Payload
```json
{
  "object_type": "activity",
  "object_id": 12345678,
  "aspect_type": "create",
  "owner_id": 99999,
  "event_time": 1716000000
}
```
Payload does **not** include activity data — fetch via `GET /activities/{id}` after receiving.

### Considerations
- Callback must respond **200 within 2 seconds** — process async
- Requires a publicly reachable URL (not localhost) — would need a tunnel (ngrok) or deployment
- Optional HMAC-SHA256 signature verification via `X-Strava-Signature`

## Sync Strategy for FitnessTracker Backend

### Initial Sync
1. After OAuth, call `GET /athlete/activities?per_page=200` paginating through all history
2. For each activity where `sport_type` is "Run", "TrailRun", or "VirtualRun":
   - Store summary data in Postgres
   - Optionally fetch `GET /activities/{id}` for full detail (splits, laps)
3. Record the most recent `start_date` as sync watermark

### Incremental Sync (on dashboard refresh or scheduled)
1. Call `GET /athlete/activities?after=<last_sync_epoch>&per_page=200`
2. Store any new activities
3. Update sync watermark

### Data to Store in Postgres
At minimum, store these fields per activity for dashboard queries:
- `strava_id` (unique, for dedup)
- `sport_type`
- `start_date_local`
- `distance`, `moving_time`, `elapsed_time`
- `average_speed`, `max_speed`
- `total_elevation_gain`
- `average_heartrate`, `max_heartrate` (nullable)
- `average_cadence` (nullable)
- `calories`
- `pr_count`

### Computing Aggregates
Weekly/monthly summaries are computed via SQL queries on stored activities:
```sql
-- Weekly summary (current week)
SELECT COUNT(*), SUM(distance), AVG(average_speed), SUM(moving_time)
FROM activities
WHERE sport_type IN ('Run', 'TrailRun', 'VirtualRun')
  AND start_date_local >= date_trunc('week', CURRENT_DATE);
```

## Strava App Registration

1. Go to https://www.strava.com/settings/api
2. Create application → get `client_id` and `client_secret`
3. Set authorization callback domain (e.g., `localhost` for local dev)
4. Store credentials in `.env` (never commit)

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 401 | Token expired or revoked | Refresh token; if refresh fails, re-auth |
| 403 | Insufficient scope | Re-authorize with correct scopes |
| 429 | Rate limited | Back off, check `X-RateLimit-Usage` headers |
| 404 | Activity deleted or not found | Remove from local DB if stored |
