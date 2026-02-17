# Codebase Concerns

**Analysis Date:** 2026-02-17

## Tech Debt

### Handler File Complexity

**Area:** Large monolithic handler files causing maintenance burden

**Files:**
- `EV-Backend/internal/essentials/handlers.go` (3570 lines)
- `EV-Backend/internal/staging/handlers.go` (1595 lines)
- `EV-Backend/internal/compass/handlers.go` (1205 lines)

**Impact:** Difficult to locate functionality, test individual endpoints, and reason about data flow. Handler files mix routing, business logic, database queries, and caching logic. Makes refactoring risky.

**Fix approach:**
1. Extract database query logic into separate repository layer (`handlers/db_queries.go`)
2. Extract data transformation into service layer (`services/transform.go`)
3. Split handlers by feature domain (e.g., `handlers/politicians.go`, `handlers/cache.go`)
4. Use dependency injection to pass services to handlers

---

### Missing Session Locking in Concurrent Edits

**Area:** Data entry concurrent editing protection

**Files:** `EV-Backend/internal/staging/handlers.go` (mentions 10-minute locking), but implementation not consistently used across all edit operations

**Issue:** `LockDuration = 10 * time.Minute` is defined but concurrent writes to `StagingStance` and `StagingPolitician` may proceed without lock checks. Race conditions possible if multiple users edit same record simultaneously.

**Risk:** Data corruption, lost edits, inconsistent review workflow state

**Fix approach:**
1. Create explicit locking check before any update: `AcquireLock(politicianID)` or abort with 409 Conflict
2. Audit all UPDATE/DELETE handlers for lock validation
3. Add integration test for concurrent edit scenarios
4. Log lock contention for monitoring

---

### Ignored Error Returns

**Area:** Error handling gaps in non-critical paths

**Files:**
- `EV-Backend/internal/essentials/handlers.go` (lines 28, 378, 1164, 1958, 1977) - JSON encoding errors silently dropped
- `EV-Backend/internal/essentials/transform.go` (lines 216-218, 536-538) - CheckAndOmitIfEqual errors ignored

**Issue:** When JSON encoding fails (`_ = json.NewEncoder(w).Encode(v)`), the client receives malformed response with no HTTP error. When transform functions encounter DB errors, silently returns partial data.

**Risk:** Silent failures, difficult debugging, incomplete data sent to clients

**Fix approach:**
1. Replace `_ =` with proper error handling: log error and set appropriate HTTP status
2. For transform errors, wrap return type: `(T, error)` instead of `(T, _)`
3. Propagate transform errors to handler as HTTP 500
4. Use linter rule to forbid `_ = ` on non-void functions

---

## Security Considerations

### Cookie Domain Configuration Temporary State

**Area:** Session authentication cross-domain

**Files:** `EV-Backend/internal/auth/handlers.go` (lines 20-40, 135, 185)

**Risk:** Session cookies currently omit `Domain` attribute for local dev compatibility. If deployed to production without fix, cookies will be browser-restricted to specific domain (e.g., `api.empowered.vote` only, not accessible from `compass.empowered.vote`). This breaks SPA authentication.

**Current mitigation:** Code comment at line 24 ("Detect local development: PORT env not set") attempts auto-detection, but heuristic is fragile

**Recommendations:**
1. Environment variable control: `COOKIE_DOMAIN=.empowered.vote` (or empty for dev)
2. Pre-deploy checklist: verify `COOKIE_DOMAIN` set for production
3. Integration test: validate cookie can be read across subdomains in staging

**Status:** BLOCKING for multi-domain production deployment

---

### Admin/Permission Checks Inconsistent

**Area:** Authorization validation across endpoints

**Files:**
- `EV-Backend/internal/compass/handlers.go` (lines 536-542) - Manual role checks
- `EV-Backend/internal/auth/handlers.go` (lines 353-372) - AdminCheckHandler separate from middleware
- `EV-Backend/internal/auth/models.go` - No Role validation on create

**Issue:** Admin routes sometimes use middleware (`AdminMiddleware`), sometimes manual DB checks. Inconsistency creates bypass opportunities. No input validation on role values (could set role to invalid string).

**Risk:** Privilege escalation, unauthorized admin access to protected endpoints

**Recommendations:**
1. Always use `AdminMiddleware` for protected routes, never manual role checks
2. Define enum for valid roles: `type Role string` with const values
3. Validate role on User create/update: `if r != RoleAdmin && r != RoleUser && r != RoleDummy { error }`
4. Audit all routes with "admin" in name to ensure middleware protection

---

### No Input Validation on Search/Query Parameters

**Area:** User input in API endpoints

**Files:**
- `EV-Backend/internal/essentials/handlers.go` (lines 3438-3442) - Query parameters (`q`, `state`, `limit`, `offset`) used directly with minimal validation
- `EV-Backend/internal/treasury/handlers.go` (lines 48, 55, 60, 70) - Query params (`city`, `city_id`, `year`, `dataset`) used without sanitization

**Issue:** Parameters like `limit` and `offset` parsed from strings but not validated for range (could be negative, extremely large). Search query `q` not validated for length (could cause expensive DB queries). No protection against malformed UUIDs or invalid enum values.

**Risk:** DoS via large LIMIT/OFFSET, expensive full-text searches causing resource exhaustion

**Recommendations:**
1. Create validation helper: `ValidateLimit(val string, defaultVal, maxVal int) (int, error)`
2. Define max search query length: `const MaxSearchLength = 500`
3. Validate offset >= 0, limit >= 0 and <= maxLimit (e.g., 1000)
4. Use typed query params: parse to int/uuid.UUID early, error if invalid format

---

## Performance Bottlenecks

### N+1 Query Problem in Politician Search

**Area:** Database queries for politician data

**Files:** `EV-Backend/internal/essentials/handlers.go` (search endpoint around line 3400+)

**Problem:** Politicians queried, then for each politician, committees fetched separately. If 100 politicians returned, 101 queries total (1 for politicians + 100 for committees).

**Cause:** Batch load happens (`ids = make([]uuid.UUID, 0, len(rows))`), but may not be optimal for all nested data (images, degrees, experiences, endorsements, stances).

**Impact:** Search response time scales linearly with result count. Large ZIP codes (500+ politicians) experience slow response.

**Improvement path:**
1. Use SQL `LEFT JOIN` to fetch committees in single query
2. Batch-load images/degrees/experiences/endorsements/stances with `ANY()` operator
3. Benchmark: measure query count before/after with query logs: `?queryLog=true` in Supabase or `EXPLAIN ANALYZE`
4. Add caching for committees/images (rarely change)

---

### Caching Architecture Relies on Background Goroutines

**Area:** Data freshness for ZIP code politician searches

**Files:** `EV-Backend/internal/essentials/handlers.go` (lines 245-320)

**Problem:** For stale/missing cache, endpoint immediately returns 202 "Warming" and starts background goroutine. Client polls until data ready. If many concurrent requests for same ZIP, multiple goroutines fetch same data redundantly.

**Risk:** Thundering herd effect. 1000 users search same ZIP → 1000 API calls to BallotReady, all concurrent. Rate limiting on BallotReady API (unknown limits) may cause cascading failures. Background goroutines may leak if client disconnects (though AbortSignal mechanism partially mitigates).

**Improvement path:**
1. Add distributed locking (Redis): only first request fetches, others wait for lock release and retry
2. Implement request deduplication: key = (zip, state), queued requests wait on same channel
3. Add BallotReady rate limiting: max 10 concurrent requests globally, queued locally
4. Monitor goroutine count: alert if >100 active background warmers

---

### Large Handler Response Objects Not Streamed

**Area:** API response encoding for large politician lists

**Files:** `EV-Backend/internal/essentials/handlers.go` (line 28, 378, 3569) - All use `json.NewEncoder(w).Encode(v)`

**Problem:** Entire object marshaled to memory before sent to client. For large ZIP codes with 500+ politicians and nested data (images, degrees, experiences, stances), response can exceed 10MB. Memory-intensive and slow.

**Risk:** Clients with slow connections timeout. Large response bodies bloat memory use under load.

**Improvement path:**
1. Use streaming JSON encoder for lists: batch encode 50 politicians at a time
2. Implement cursor-based pagination: return 50 results, next cursor for page 2
3. Add HTTP compression: `Content-Encoding: gzip` (already supported by Chi middleware)
4. Measure response size: log response bytes for searches returning >100 results

---

## Known Bugs

### JSON Encoding Silently Fails

**Area:** Response serialization

**Files:** `EV-Backend/internal/essentials/handlers.go` (lines 26-29, 378)

**Problem:**
```go
func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)  // Error ignored
}
```

If encoding fails (circular reference, marshaling error), no error response sent. Client receives headers + partial/corrupted JSON.

**Workaround:** None currently; client sees `Content-Type: application/json` but malformed body.

**Fix:** Replace with:
```go
func writeJSON(w http.ResponseWriter, v any) error {
	w.Header().Set("Content-Type", "application/json")
	return json.NewEncoder(w).Encode(v)
}
// In handlers: if err := writeJSON(w, data); err != nil { log.Printf(...) }
```

---

## Fragile Areas

### Schema Migrations Executed at Runtime

**Area:** Database initialization

**Files:** `EV-Backend/internal/essentials/setup.go` (lines 20-97)

**Why fragile:**
- `db.DB.AutoMigrate(...)` called at server startup
- If migration fails (constraint conflict, version mismatch), server crashes
- No rollback mechanism; partially-migrated state leaves DB inconsistent
- If schema already exists, unsafe to run twice (could drop/recreate data)

**Safe modification:**
1. Use separate `migrate` command: `./server migrate` vs `./server run`
2. Version schema with timestamps: `migrations/001_initial_schema.up.sql`
3. Test migrations on staging before deploy
4. Add pre-migration backup check

**Test coverage gaps:**
- No test suite for schema migrations
- No verification that migrations are idempotent

---

### Transaction Handling Incomplete

**Area:** Multi-step database operations

**Files:** `EV-Backend/internal/compass/handlers.go` (lines 171-244, 644-839) - Uses `tx := db.DB.Begin()` but no error check before operations

**Issue:** Transaction started but never validated. If `Begin()` returns error, code continues and executes queries on closed transaction. No `ROLLBACK` on error path (relies on implicit rollback only).

**Risk:** Data corruption if transaction fails mid-operation. Partial updates not rolled back.

**Safe modification:**
1. Always check Begin() error: `tx := db.DB.Begin(); if tx.Error != nil { ... }`
2. Defer rollback: `defer func() { if tx.Error != nil { tx.Rollback() } }()`
3. Check every query: `if err := tx.Create(&x).Error; err != nil { ... }`
4. Use transactions as boundary: wrap entire multi-step operation

---

### Session Validation Checks Missing on Some Endpoints

**Area:** Authentication enforcement

**Files:**
- `EV-Backend/internal/staging/handlers.go` - Some endpoints missing `SessionMiddleware` protection
- `EV-Backend/internal/compass/handlers.go` (UpdatePolitician, others) - Manual session checks mixed with middleware

**Issue:** If endpoint accidentally omitted from middleware chain, becomes public. Manual checks can be bypassed if logic error.

**Safe modification:**
1. Audit all routes in `SetupRoutes()`: verify protected endpoints under middleware
2. Default-deny: middleware wraps all routes, specific public routes opt-out
3. Test: attempt to access protected endpoint without session_id cookie, expect 401

---

## Test Coverage Gaps

### No Tests for Frontend Polling Behavior

**Area:** Frontend data fetching

**Files:**
- `essentials/src/hooks/usePoliticianData.js` (polling with retry logic)
- `essentials/src/lib/api.js` (API calls)

**What's not tested:**
- Retry logic on 202 responses (warming status)
- Abort signal cancellation (cleanup on unmount)
- Backoff delay calculation
- Error recovery after max retries

**Risk:** Polling logic regression could cause:
- Memory leaks (unused retries)
- Unresponsive UI if retry loop broken
- Users stuck on loading screen if error not handled

**Priority:** HIGH - this is user-facing

---

### No E2E Tests for Authentication Flow

**Area:** User login/logout

**Files:** `EV-Backend/internal/auth/handlers.go` (LoginHandler, LogoutHandler)

**What's not tested:**
- Session cookie set correctly on login
- Session expires after 6 hours
- Logout clears session from DB
- Cross-domain cookie accessible (main production risk)

**Risk:** Auth breaking silently, users locked out of app, privilege escalation

**Priority:** CRITICAL

---

### No Integration Tests for Concurrent Operations

**Area:** Data entry workflow

**Files:** `EV-Backend/internal/staging/handlers.go` (concurrent editing with 10-minute locks)

**What's not tested:**
- Two users editing same politician simultaneously
- Lock timeout behavior
- Approval workflow state transitions

**Risk:** Data corruption in volunteer data entry, inconsistent review state

**Priority:** HIGH

---

### Frontend Components Missing Unit Tests

**Area:** React components

**Files:**
- `CompassV2/src/pages/Quiz.jsx` (674 lines, no tests)
- `CompassV2/src/components/RadarChart.jsx` (no tests)
- `essentials/src/pages/Dashboard.jsx` (complex classification logic, no tests)

**What's not covered:**
- Quiz answer submission logic
- Radar chart rendering and interactions
- Politician classification (federal/state/local)
- Search parameter URL handling

**Risk:** UI regressions, classification bugs causing wrong politicians shown, quiz data loss

**Priority:** MEDIUM

---

## Scaling Limits

### BallotReady API Rate Limiting Unknown

**Area:** External API dependency

**Files:** `EV-Backend/internal/essentials/ballotready/client.go`

**Current capacity:**
- No built-in rate limiting
- Concurrent requests per ZIP: unlimited (background warmers)
- Max batch size for ID resolution: not limited

**Limit:** Unknown. BallotReady API rate limits not documented in code. No monitoring for 429 responses.

**Scaling path:**
1. Contact BallotReady support for rate limit documentation
2. Implement token bucket: e.g., 100 requests/minute
3. Retry on 429 with exponential backoff
4. Log all 429 responses to identify patterns

---

### Database Connection Pool Not Tuned

**Area:** Database connections

**Files:** `EV-Backend/internal/db/db.go` (connection pooling)

**Current capacity:** GORM default pool (check actual value in code)

**Scaling concern:** If pool size too small, concurrent requests queue up and timeout. If too large, database runs out of connections.

**Scaling path:**
1. Set explicit pool size: `SetMaxIdleConns(10)`, `SetMaxOpenConns(100)`
2. Monitor connection usage: log pool stats periodically
3. Load test with expected concurrent users, adjust based on p99 query time

---

### No Request Deduplication for Cache Warming

**Area:** Concurrent requests for same ZIP

**Current capacity:** Each request to `/essentials/politicians/{zip}` starts independent background warmer if cache stale

**Limit:** 1000 concurrent requests for same ZIP → 1000 background goroutines + 1000 BallotReady API calls (thundering herd)

**Scaling path:**
1. Implement request deduplication: shared channel per (zip, state) pair
2. First request fetches, others wait for channel close
3. Cap concurrent warmers: max 10 globally, queued locally
4. Add metrics: goroutine count, BallotReady requests/sec

---

## Dependencies at Risk

### Cicero API Provider Still in Codebase

**Area:** API providers

**Files:**
- `EV-Backend/internal/essentials/cicero/` (entire package)
- `EV-Backend/internal/essentials/provider/` (provider abstraction)

**Risk:** Cicero API deprecated in favor of BallotReady, but code still present. Creates confusion, maintenance burden. If someone accidentally routes request to Cicero provider, stale data returned.

**Migration plan:**
1. Verify all essentials endpoints use BallotReady only
2. Remove cicero package entirely
3. Remove provider abstraction (no longer needed with single provider)
4. Simplify handlers: use ballotready client directly

**Timeline:** Can be done in one cleanup phase (1-2 hours)

---

### Deprecated GraphQL Fields in BallotReady Responses

**Area:** External API dependency

**Files:** `CivicEngine GraphQL API Documentation.md` (multiple DEPRECATED markers)

**Risk:** BallotReady API may remove deprecated fields in future version. If code uses deprecated field, requests will fail. No versioning in place.

**Recommendation:**
1. Audit all GraphQL queries for DEPRECATED markers
2. Test with latest BallotReady API version (may differ from docs)
3. Pin API version if available, or add request header for version
4. Monitor deprecation warnings in responses

---

## Missing Critical Features

### No Data Export/Import for Backup

**Area:** Data persistence and recovery

**Files:** No export functionality in essentials, compass, or staging modules

**Problem:** If database corrupted, no way to recover data. Volunteer-entered stances in staging schema not backed up separately. Politician data depends entirely on BallotReady API (re-fetchable, but expensive).

**Blocks:** Production deployment without backup strategy

**Recommendations:**
1. Add `POST /admin/export` endpoint: dump all schema data as JSON
2. Add `POST /admin/import` endpoint: restore from JSON
3. Automate daily backups via cron: call export endpoint, store in S3
4. Test restore: verify backup can be imported to new DB

---

### No Monitoring or Alerting

**Area:** Operational observability

**Files:** No metrics, logging, or alerting infrastructure

**Problem:** If API returns error, no one knows. If BallotReady API times out, no alert sent. If database fills up, no warning.

**Recommendations:**
1. Add structured logging: use `slog` package (Go 1.21+) with JSON output
2. Log all errors with context: request ID, user ID, operation
3. Add metrics: response times, error counts, goroutine count
4. Integrate with monitoring tool: Datadog, Prometheus, or similar
5. Alert on: 5xx errors sustained for 1min, >100 concurrent goroutines, response time p99 >5s

---

### No Admin Dashboard for Data Auditing

**Area:** Data management and review

**Files:** No admin endpoints for viewing/auditing data changes

**Problem:** No way to see who created/modified politicians in staging schema. No audit trail for approvals. Can't easily search/filter politicians by creation date or modifier.

**Blocks:** Compliance requirements, troubleshooting volunteer data issues

**Recommendations:**
1. Add `created_at`, `updated_at`, `updated_by` columns to staging tables
2. Create audit log table: record all create/update/delete operations
3. Add `GET /admin/audit-log` endpoint with filters (entity_type, user_id, date range)
4. Add `GET /admin/dashboard` with summary metrics (politicians added this week, pending approvals, etc.)

---

## Miscellaneous Concerns

### Frontend Polling Hook Not Cleaning Up on Unmount

**Area:** Memory management

**Files:** `essentials/src/hooks/usePoliticianData.js` (cleanup at line 142-145)

**Issue:** While `controller.abort()` is called on unmount, any pending fetch is cancelled. However, if fetch completes after unmount (race condition), state updates will occur on unmounted component. React 18 Strict Mode flags this as memory leak.

**Risk:** Memory leaks if many rapid mount/unmount cycles (navigation)

**Fix:** Add effect return cleanup function to abort controller:
```js
return () => {
  console.log(`[usePoliticianData] #${id} cleanup — aborting`);
  controller.abort();
};
```
This is already present, but verify it runs before state updates.

---

### Polling Hook Console Logs Left in Production Code

**Area:** Code hygiene

**Files:** `essentials/src/hooks/usePoliticianData.js` (lines 60, 81, 105, 112, 134, 143)

**Issue:** Many `console.log()` statements for debugging. Will spam browser console in production, potentially exposing internal state to users.

**Fix:** Replace with logging to configured debug level (e.g., `if (DEBUG) console.log(...)`), or use library like `debug` package.

---

### Magic Numbers in Codebase

**Area:** Code maintainability

**Examples:**
- `6 * time.Hour` (session TTL) appears in multiple places: `EV-Backend/internal/auth/handlers.go` (lines 135, 143)
- `90 * 24 * time.Hour` (cache TTL) appears in multiple places: `EV-Backend/internal/essentials/handlers.go` (lines 249, 1989)
- `10 * time.Minute` (lock duration): `EV-Backend/internal/staging/handlers.go` (line 22)

**Issue:** If you want to change session TTL, must find and update all locations. Inconsistency risk if one location missed.

**Fix approach:**
1. Define constants at package level:
```go
const SessionTTL = 6 * time.Hour
const CacheTTL = 90 * 24 * time.Hour
const LockDuration = 10 * time.Minute
```
2. Use constants everywhere instead of inline values

---

### No Type Safety in Query Parameters

**Area:** API robustness

**Files:** `EV-Backend/internal/essentials/handlers.go`, `EV-Backend/internal/treasury/handlers.go`

**Issue:** Query parameters parsed as strings, then manually converted to int/uuid/enum. Conversion errors not always handled gracefully.

**Example:**
```go
limitStr := r.URL.Query().Get("limit")
// If limitStr is "abc", strconv.Atoi will fail
// But error may not be checked or logged
```

**Fix:** Create middleware or helper that validates query params early:
```go
type SearchQuery struct {
  Q      string `query:"q" validate:"max=500"`
  Limit  int    `query:"limit" validate:"min=1,max=1000"`
  Offset int    `query:"offset" validate:"min=0"`
}
// Parse and validate in single step
```

---

*Concerns audit: 2026-02-17*
