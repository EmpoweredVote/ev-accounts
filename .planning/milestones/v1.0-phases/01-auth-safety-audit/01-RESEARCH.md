# Phase 1: Auth Safety Audit - Research

**Researched:** 2026-02-17
**Domain:** Go session-based authentication, Chi router, HTTP cookie configuration
**Confidence:** HIGH (all findings from direct codebase inspection)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Route manifest design**
- Three auth levels: public, guest-ok, auth-required — with an admin flag annotation on auth-required routes that need elevated privileges
- Manifest includes both views: primary grouping by module (auth, compass, essentials, etc.) with a summary table grouped by auth level at the top
- Manifest should include a Phase 2 handoff section explicitly listing what Phase 2 can rely on

**Confirmed safe bar**
- Automated tests that verify auth behavior programmatically — not just code review and docs
- Tests should confirm: login works, session persists across requests, logout clears session, tab reload preserves login state

**Domain migration notes**
- No timeline for domain migration — document what needs to change, but treat as a future task
- Hosting may consolidate (currently Netlify + Render split) — notes should be hosting-agnostic where possible

**Audit deliverable format**
- Dual location: planning summary in .planning/, detailed auth docs in the codebase at EV-Backend/docs/
- Codebase docs go in a new EV-Backend/docs/ directory
- Include a "Phase 2 handoff" section that explicitly lists what Phase 2 can assume is true

### Claude's Discretion

- Level of detail per route entry (path + method + level minimum; handler names if useful)
- Whether to flag Phase 2 mismatches (routes that are auth-required now but should become guest-ok)
- Testing approach: integration tests vs handler unit tests vs both — pick what gives the most confidence
- Whether to surface security concerns found during audit (CSRF, session fixation, etc.) as recommendations or stay strictly behavioral
- Test database strategy — isolated Supabase, in-memory, or whatever makes tests reliable and easy to run
- Whether to scope migration notes beyond cookie config (CORS origins, frontend env vars, DNS)
- Whether to include a rollback plan for cookie config changes
- Whether route manifest is a standalone file or a section within the auth audit doc

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | Audit current cookie/session configuration to ensure guest-first auth changes don't break existing login flow across current domains (Netlify + Render/AWS) | Cookie config fully audited below; session mechanics documented; CORS origin list catalogued; route manifest compiled |
</phase_requirements>

---

## Summary

The EV-Backend uses a hand-rolled, database-backed session system with HTTP-only cookies. There is no external session library — sessions are stored in `app_auth.sessions` (PostgreSQL), looked up per request by the `SessionMiddleware`, and expired at a fixed 6-hour TTL with no sliding window. The cookie configuration is environment-sensitive: production gets `Secure=true, SameSite=None`; local dev gets `Secure=false, SameSite=Lax`. The `Domain` attribute is intentionally omitted to allow cross-domain operation between Netlify frontends and the Render-hosted API.

All routes across five modules (auth, compass, essentials, treasury, staging, webhooks) have been catalogued. The auth model is clear and consistent: Chi groups protected by `middleware.SessionMiddleware`, with a nested `middleware.AdminMiddleware` layer for elevated routes. No existing integration tests target the auth flow — only one geocoding test file exists in the entire backend.

**Primary recommendation:** Write integration tests using Go's `net/http/httptest` package against a real test database (the isolated Supabase instance), since the `SessionFetcher` interface enables clean mocking for unit tests but behavioral confirmation requires the real DB path. Produce the route manifest as a section within the main auth audit doc, not a standalone file.

---

## Standard Stack

### Core (already in place — no new dependencies needed)

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `net/http/httptest` | stdlib | HTTP handler testing | Already available; no install needed |
| `github.com/go-chi/chi/v5` | v5.2.1 | Router; `chi.NewRouter()` for test servers | Already in go.mod |
| `gorm.io/gorm` | v1.30.0 | DB access in handlers | Already in go.mod |
| `golang.org/x/crypto` | v0.38.0 | bcrypt for password hashing | Already in go.mod |
| `testing` | stdlib | Go test runner | No install needed |

### Supporting (for test isolation)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `github.com/joho/godotenv` | v1.5.1 | Load `.env.local` in tests | Already in go.mod; use in `TestMain` to load test DB URL |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Real Supabase test DB | In-memory SQLite | SQLite won't replicate Postgres-specific behavior (schema namespacing `app_auth.*`, UUID types). Real DB is higher confidence. |
| `httptest.NewServer` | Direct handler calls | `httptest.NewServer` tests cookie round-trips properly; direct calls miss cookie jar behavior |

**Installation:** No new packages required. All testing dependencies are Go stdlib or already in go.mod.

---

## Architecture Patterns

### How Auth Works End-to-End

```
Client                         Server
  |                               |
  |  POST /auth/login             |
  |  {username, password}         |
  |------------------------------>|
  |                               |  1. Look up user by username
  |                               |  2. bcrypt.CompareHashAndPassword
  |                               |  3. Generate UUID session_id
  |                               |  4. Upsert session into app_auth.sessions (6hr TTL)
  |                               |  5. http.SetCookie("session_id", uuid, MaxAge=21600)
  |<------------------------------|
  |  Set-Cookie: session_id=...   |
  |                               |
  |  GET /auth/me                 |
  |  Cookie: session_id=...       |
  |------------------------------>|
  |                               |  SessionMiddleware:
  |                               |  1. Extract session_id from cookies
  |                               |  2. DB lookup: SELECT * FROM app_auth.sessions WHERE session_id=?
  |                               |  3. Check ExpiresAt > now
  |                               |  4. Set userID into request context
  |                               |  5. Call next handler
  |<------------------------------|
  |  {user_id, username, ...}     |
```

### Cookie Configuration (Production vs Local)

The `sessionCookie()` function in `internal/auth/handlers.go` (lines 20-40) switches behavior based on the `PORT` environment variable:

```go
// Production (PORT is set and does not start with "5050")
Cookie{
    Name:     "session_id",
    Value:    uuid,
    Path:     "/",
    MaxAge:   21600,  // 6 hours in seconds
    HttpOnly: true,
    Secure:   true,
    SameSite: http.SameSiteNoneMode,
    // Domain: NOT SET (intentionally omitted for cross-domain Netlify+Render)
}

// Local dev (PORT="" or starts with "5050")
Cookie{
    Name:     "session_id",
    Value:    uuid,
    Path:     "/",
    MaxAge:   21600,
    HttpOnly: true,
    Secure:   false,
    SameSite: http.SameSiteLaxMode,
    // Domain: NOT SET
}
```

**Why SameSite=None in production:** Netlify frontends (e.g., `compass.empowered.vote`) and the Render API (`api.empowered.vote`) are on different domains, so `SameSite=Lax` would block cross-site cookie sends. `SameSite=None` requires `Secure=true`, which is enforced in production.

**Why Domain is omitted:** Per the CLAUDE.md code comment, Domain is intentionally omitted so the cookie works cross-domain without being scoped to a specific domain. When/if hosting consolidates under `*.empowered.vote`, restoring `Domain: ".empowered.vote"` becomes possible and would scope the cookie properly.

### Middleware Chain (SessionMiddleware)

Source: `internal/middleware/middleware.go` lines 16-46

```go
// SessionMiddleware behavior:
// 1. Iterates r.Cookies() looking for "session_id" with non-empty value
// 2. Calls fetcher.FindSessionByID(sessionID) — hits app_auth.sessions table
// 3. Checks session.ExpiresAt.Before(time.Now()) — hard expiry, no sliding window
// 4. Injects userID into context via utils.ContextUserIDKey
// 5. Returns 401 on any failure
```

**Important:** There is NO session renewal. A session created at T=0 expires at T+6h regardless of activity.

### AdminMiddleware

Source: `internal/middleware/middleware.go` lines 106-134

```go
// AdminMiddleware behavior:
// 1. Extracts userID from context (set by SessionMiddleware which must run first)
// 2. DB lookup: SELECT * FROM app_auth.users WHERE user_id=?
// 3. Checks user.Role == "admin"
// 4. Returns 401 if user not found, 403 if role != "admin"
```

AdminMiddleware **always runs after** SessionMiddleware. The two are always stacked, never standalone.

### SessionFetcher Interface Pattern

Each module (`auth`, `compass`, `essentials`, `treasury`, `staging`) has its own `SessionInfo` struct implementing `middleware.SessionFetcher`. They all do the same thing — look up `app_auth.sessions`. This pattern enables clean mocking in tests:

```go
// Test double — no DB needed for unit tests
type mockFetcher struct {
    session utils.SessionData
    err     error
}
func (m mockFetcher) FindSessionByID(id string) (utils.SessionData, error) {
    return m.session, m.err
}
```

### UpdatePasswordHandler: Duplicate Session Validation

`UpdatePasswordHandler` (lines 263-330 in handlers.go) does its own cookie lookup and DB session query INSTEAD of relying on middleware context. This handler is registered under the `SessionMiddleware` group, so the middleware already validated the session. The handler then re-validates from scratch — belt-and-suspenders, but the context `userID` is ignored. This is a code smell to flag but not fix in Phase 1.

---

## Complete Route Manifest

Source: direct inspection of all `routes.go` files across the codebase.

### Summary by Auth Level

| Auth Level | Count | Notes |
|------------|-------|-------|
| public | 21 | No cookie required |
| auth-required | 27 | `SessionMiddleware` must pass |
| auth-required + admin | 14 | `SessionMiddleware` + `AdminMiddleware` |

### Module Breakdown

#### Module: Root (`main.go`)

| Method | Path | Auth Level | Handler |
|--------|------|-----------|---------|
| GET | `/` | public | `RootHandler` |

#### Module: Auth (`/auth`)

| Method | Path | Auth Level | Handler |
|--------|------|-----------|---------|
| POST | `/auth/login` | public | `LoginHandler` |
| POST | `/auth/register` | public | `RegisterHandler` |
| GET | `/auth/healthz` | public | inline 200 ok |
| GET | `/auth/me` | auth-required | `MeHandler` |
| POST | `/auth/complete-onboarding` | auth-required | `OnboardingHandler` |
| POST | `/auth/update-password` | auth-required | `UpdatePasswordHandler` |
| POST | `/auth/logout` | auth-required | `LogoutHandler` |
| GET | `/auth/empowered-accounts` | auth-required | `EmpoweredAccountHandler` |
| GET | `/auth/admin-check` | auth-required | `AdminCheckHandler` |
| GET | `/auth/admin` | auth-required + **admin** | inline 200 ok |
| POST | `/auth/create-dummy` | auth-required + **admin** | `CreateDummyHandler` |
| POST | `/auth/update-profile-pic` | auth-required + **admin** | `UpdateProfilePicHandler` |
| POST | `/auth/update-username` | auth-required + **admin** | `UpdateUsername` |
| DELETE | `/auth/delete-user/{userID}` | auth-required + **admin** | `DeleteUser` |

#### Module: Compass (`/compass`)

| Method | Path | Auth Level | Handler |
|--------|------|-----------|---------|
| GET | `/compass/topics` | public | `TopicHandler` |
| POST | `/compass/topics/batch` | public | `TopicBatchHandler` |
| GET | `/compass/categories` | public | `CategoryHandler` |
| GET | `/compass/politicians/{politician_id}/{topic_id}/context` | public | `GetPoliticianContext` |
| GET | `/compass/politicians/{politician_id}/answers` | public | `GetPoliticianAnswers` |
| GET | `/compass/politicians` | public | `PoliticiansWithAnswersHandler` |
| POST | `/compass/answers` | auth-required | `UserAnswersHandler` |
| GET | `/compass/answers` | auth-required | `UserAnswersHandler` |
| POST | `/compass/answers/batch` | auth-required | `UserAnswerBatchHandler` |
| GET | `/compass/selected-topics` | auth-required | `SelectedTopicsHandler` |
| PUT | `/compass/selected-topics` | auth-required | `SelectedTopicsHandler` |
| POST | `/compass/politicians/{politician_id}/answers/batch` | auth-required | `PoliticianAnswerBatch` |
| POST | `/compass/compare` | auth-required | `CompareHandler` |
| PATCH | `/compass/topics/update` | auth-required + **admin** | `TopicUpdateHandler` |
| POST | `/compass/topics/create` | auth-required + **admin** | `CreateTopicHandler` |
| PATCH | `/compass/stances/update` | auth-required + **admin** | `StancesUpdateHandler` |
| PATCH | `/compass/topics/categories/update` | auth-required + **admin** | `UpdateTopicCategoriesHandler` |
| POST | `/compass/politicians/context` | auth-required + **admin** | `PoliticianContextHandler` |
| PUT | `/compass/politicians/{politician_id}/answers` | auth-required + **admin** | `UpsertPoliticianAnswers` |
| DELETE | `/compass/topics/delete/{id}` | auth-required + **admin** | `DeleteTopicHandler` |

#### Module: Essentials (`/essentials`)

| Method | Path | Auth Level | Handler |
|--------|------|-----------|---------|
| GET | `/essentials/politicians` | public | `GetAllPoliticians` |
| GET | `/essentials/politicians/{zip}` | public | `GetPoliticiansByZip` |
| POST | `/essentials/politicians/search` | public | `SearchPoliticians` |
| GET | `/essentials/cache-status/{zip}` | public | `GetCacheStatus` |
| GET | `/essentials/politician/{id}` | public | `GetPoliticianByID` |
| GET | `/essentials/politician/{id}/endorsements` | public | `GetPoliticianEndorsements` |
| GET | `/essentials/politician/{id}/stances` | public | `GetPoliticianStances` |
| GET | `/essentials/politician/{id}/elections` | public | `GetPoliticianElections` |
| POST | `/essentials/admin/import` | auth-required + **admin** | `StartBulkImport` |
| GET | `/essentials/admin/import/{jobID}` | auth-required + **admin** | `GetImportStatus` |
| GET | `/essentials/admin/import` | auth-required + **admin** | `ListImportJobs` |

#### Module: Treasury (`/treasury`)

| Method | Path | Auth Level | Handler |
|--------|------|-----------|---------|
| GET | `/treasury/cities` | public | `ListCities` |
| GET | `/treasury/cities/{city_id}` | public | `GetCity` |
| GET | `/treasury/budgets` | public | `ListBudgets` |
| GET | `/treasury/budgets/{budget_id}` | public | `GetBudget` |
| GET | `/treasury/budgets/{budget_id}/categories` | public | `GetBudgetCategories` |
| POST | `/treasury/cities` | auth-required + **admin** | `CreateCity` |
| PUT | `/treasury/cities/{city_id}` | auth-required + **admin** | `UpdateCity` |
| DELETE | `/treasury/cities/{city_id}` | auth-required + **admin** | `DeleteCity` |
| POST | `/treasury/budgets` | auth-required + **admin** | `CreateBudget` |
| POST | `/treasury/budgets/import` | auth-required + **admin** | `ImportBudget` |
| PUT | `/treasury/budgets/{budget_id}` | auth-required + **admin** | `UpdateBudget` |
| DELETE | `/treasury/budgets/{budget_id}` | auth-required + **admin** | `DeleteBudget` |

#### Module: Staging (`/staging`)

| Method | Path | Auth Level | Handler |
|--------|------|-----------|---------|
| GET | `/staging/data` | auth-required | `GetAllData` |
| GET | `/staging/stances` | auth-required | `ListStances` |
| GET | `/staging/stances/review-queue` | auth-required | `GetReviewQueue` |
| POST | `/staging/stances` | auth-required | `CreateStance` |
| GET | `/staging/stances/{id}` | auth-required | `GetStance` |
| PUT | `/staging/stances/{id}` | auth-required | `UpdateStance` |
| POST | `/staging/stances/{id}/submit` | auth-required | `SubmitForReview` |
| POST | `/staging/stances/{id}/approve` | auth-required | `ApproveStance` |
| POST | `/staging/stances/{id}/reject` | auth-required | `RejectStance` |
| POST | `/staging/stances/{id}/edit-resubmit` | auth-required | `EditAndResubmit` |
| POST | `/staging/stances/{id}/lock` | auth-required | `AcquireLock` |
| DELETE | `/staging/stances/{id}/lock` | auth-required | `ReleaseLock` |
| GET | `/staging/politicians` | auth-required | `ListPoliticians` |
| POST | `/staging/politicians` | auth-required | `CreatePolitician` |
| GET | `/staging/politicians/review-queue` | auth-required | `GetPoliticianReviewQueue` |
| GET | `/staging/politicians/{id}` | auth-required | `GetPolitician` |
| PUT | `/staging/politicians/{id}` | auth-required | `UpdatePolitician` |
| POST | `/staging/politicians/{id}/submit` | auth-required | `SubmitPoliticianForReview` |
| POST | `/staging/politicians/{id}/review-approve` | auth-required | `ApprovePoliticianReview` |
| POST | `/staging/politicians/{id}/review-reject` | auth-required | `RejectPoliticianReview` |
| POST | `/staging/politicians/{id}/edit-resubmit` | auth-required | `EditAndResubmitPolitician` |
| POST | `/staging/politicians/{id}/lock` | auth-required | `AcquirePoliticianLock` |
| DELETE | `/staging/politicians/{id}/lock` | auth-required | `ReleasePoliticianLock` |
| POST | `/staging/politicians/{id}/approve` | auth-required + **admin** | `ApprovePolitician` |
| POST | `/staging/politicians/{id}/reject` | auth-required + **admin** | `RejectPolitician` |

#### Module: Webhooks (`/webhooks`)

| Method | Path | Auth Level | Handler |
|--------|------|-----------|---------|
| POST | `/webhooks/framer/volunteer` | public | `FramerFormWebhook` |

---

## Testing Strategy

### Recommendation: Integration Tests Against Isolated Supabase

**Rationale:** The session system is a DB-roundtrip chain. Unit tests with mock fetchers confirm middleware logic but cannot confirm that login actually writes a session that /auth/me can read. The behavioral requirements (login works, session persists, logout clears, tab reload works) demand real HTTP + real DB roundtrips.

**Recommended approach:** Integration tests in `internal/auth/auth_test.go` using:
- `httptest.NewRecorder()` + real handler calls
- `net/http/cookiejar` to carry cookies between requests (simulates browser)
- Real database connection via `DATABASE_URL` in test environment (use isolated Supabase)
- `testing.Short()` skip guard so unit-only runs stay fast

**Test database strategy:** Use the isolated Supabase instance. Create test users with randomized usernames (e.g., `testuser_<uuid>`) and clean up with `t.Cleanup`. Do not use fixtures or seeded data — create fresh state per test.

### Test Cases Required (per locked decisions)

1. **Login works** — POST /auth/login with valid credentials returns 200 + Set-Cookie header
2. **Session persists across requests** — /auth/me returns 200 using cookie from login response
3. **Logout clears session** — POST /auth/logout returns 200, subsequent /auth/me returns 401
4. **Tab reload preserves login** — /auth/me with same cookie returns 200 (simulates reload; this is just session persistence confirmed again from cookie)
5. **Expired session is rejected** — Session with ExpiresAt in past returns 401 from middleware

### Unit Tests: Middleware in Isolation

For middleware behavior (separate from DB), unit tests with mock fetchers are appropriate:
- `SessionMiddleware` with missing cookie → 401
- `SessionMiddleware` with expired session → 401
- `SessionMiddleware` with valid session → userID in context
- `AdminMiddleware` with non-admin user → 403
- `AdminMiddleware` with admin user → passes through

### Pattern: cookiejar for request chaining

```go
// Source: Go stdlib net/http/cookiejar
jar, _ := cookiejar.New(nil)
client := &http.Client{Jar: jar}

// POST login
resp, _ := client.Post(server.URL+"/auth/login", "application/json", body)
// Cookie jar now holds session_id

// GET /auth/me — cookie sent automatically
resp2, _ := client.Get(server.URL+"/auth/me")
// Should be 200
```

---

## Cookie Configuration: Full Specification

### Current State (Production)

```
Name:     session_id
Value:    <UUID v4>
Path:     /
MaxAge:   21600  (6 hours)
HttpOnly: true   (not readable by JavaScript)
Secure:   true   (HTTPS only)
SameSite: None   (cross-site sends allowed — required for Netlify+Render split)
Domain:   (not set — browser scopes to exact API domain)
```

### Current State (Local Dev)

```
Name:     session_id
Value:    <UUID v4>
Path:     /
MaxAge:   21600
HttpOnly: true
Secure:   false   (allows HTTP)
SameSite: Lax     (same-site + top-level navigation cross-site)
Domain:   (not set)
```

### Environment Detection Logic

Source: `internal/auth/handlers.go` lines 26-29

```go
port := os.Getenv("PORT")
if port == "" || strings.HasPrefix(port, "5050") {
    // local dev mode
}
```

**Risk:** If `PORT=5050` is set in a production-like environment, it would downgrade to dev cookie settings. The condition should be checking an explicit `ENV=production` flag rather than inferring from port. This is a documentation note, not a Phase 1 fix.

### Domain Migration Notes (Hosting-Agnostic)

When hosting consolidates or a custom domain is configured:

| Setting | Current | What to Change | Why |
|---------|---------|---------------|-----|
| `Domain` | (omitted) | Set to `.empowered.vote` | Allows cookie to be shared across subdomains (compass., essentials., etc.) |
| `SameSite` | `None` | Can downgrade to `Lax` if all frontends move to `*.empowered.vote` | `Lax` is more secure; `None` only needed for true cross-site |
| `Secure` | `true` | Keep `true` | Always required when SameSite=None; good practice regardless |

These changes are to `sessionCookie()` in `internal/auth/handlers.go`. The function is called in two places: `LoginHandler` (line 135) and `LogoutHandler` (line 185, with MaxAge=-1 to clear).

**CORS side:** When adding new frontend origins, add to the `allowed` map in `internal/middleware/middleware.go`. Currently has 16 allowed origins including localhost ports, Netlify domains, and `*.empowered.vote` subdomains. This map must be updated for any new deployment domain.

**Frontend env vars:** Each frontend app uses `VITE_API_URL` pointing to the API. No change needed to auth cookie mechanics when these change — the cookie SameSite=None handles cross-origin sends automatically.

---

## Architecture Patterns

### Pattern: All Auth Protected Routes Follow This Structure

```go
r.Group(func(r chi.Router) {
    r.Use(middleware.SessionMiddleware(sessionFetcher))
    // auth-required routes here

    r.Group(func(r chi.Router) {
        r.Use(middleware.AdminMiddleware(sessionFetcher))
        // admin routes here
    })
    // OR:
    r.With(middleware.AdminMiddleware(sessionFetcher)).Method("/path", handler)
})
```

There is no `guest-ok` tier currently implemented — it does not exist in the codebase. Phase 2 will introduce it. All routes today are either public (no middleware) or auth-required (SessionMiddleware).

### Anti-Patterns Observed

- **`UpdatePasswordHandler` re-validates session from cookie** instead of using context userID set by middleware. This duplicates validation logic and ignores the context-injected userID. Should be noted in the audit doc; fix is out of scope for Phase 1.
- **`AdminCheckHandler` does its own role check in handler body** despite also being registered behind SessionMiddleware. The role check is correct but the handler could be simplified to just use the context. Not a security problem.
- **Port-based environment detection** for cookie settings is fragile. A dedicated `APP_ENV` variable would be more robust.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Cookie round-trip in tests | Manual header parsing | `net/http/cookiejar` stdlib |
| Test HTTP server | Custom server setup | `httptest.NewServer(handler)` stdlib |
| Session store | Custom DB session code | Already exists — audit it, don't replace it |

---

## Common Pitfalls

### Pitfall 1: SameSite=None Without Secure=true

**What goes wrong:** Browser rejects or ignores the cookie. Auth appears to work in dev (Lax mode) but fails silently in production.

**Why it happens:** The `SameSite=None` spec requires `Secure=true`. If Secure is false, some browsers silently drop the cookie.

**How to avoid:** The current code correctly enforces `Secure=true` when `SameSite=None`. Do not change this.

**Warning signs:** Login returns 200 but subsequent authenticated requests return 401.

### Pitfall 2: Missing CORS `Access-Control-Allow-Credentials`

**What goes wrong:** Browser blocks cookie sends even when SameSite=None and Secure=true are correct.

**Why it happens:** Cross-origin cookie sends require both `withCredentials: true` on the frontend AND `Access-Control-Allow-Credentials: true` on the backend.

**Current state:** The backend sets `Access-Control-Allow-Credentials: true` for all origins in the allow-list. Correct.

**Warning signs:** Browser console shows "Credential is not supported if the CORS header 'Access-Control-Allow-Origin' is '*'".

### Pitfall 3: Test Cookie Isolation

**What goes wrong:** Test cases share session state, causing tests to pass or fail based on run order.

**Why it happens:** If tests use the same session_id or username, DB state bleeds between tests.

**How to avoid:** Generate unique usernames per test (e.g., `fmt.Sprintf("testuser_%s", uuid.New())`). Clean up with `t.Cleanup(func() { db.DB.Delete(&user) })`.

### Pitfall 4: httptest.NewRecorder Does Not Handle Cookies

**What goes wrong:** `httptest.NewRecorder` captures `Set-Cookie` headers but does not automatically send them on subsequent requests.

**Why it happens:** `ResponseRecorder` is not a browser. It captures responses but has no cookie jar.

**How to avoid:** Use `httptest.NewServer` + `http.Client` with `cookiejar.New(nil)` when testing multi-request flows (login → authenticated request → logout).

---

## Phase 2 Handoff: What Phase 2 Can Rely On

After Phase 1 is complete, Phase 2 (Guest-First Auth) can assume:

1. **Auth flow is confirmed working** — login, session persistence, logout, tab reload all verified by passing automated tests.
2. **Cookie config is documented** — the exact production cookie settings are written down; no guessing required.
3. **Route manifest exists** — every route is categorized as public, auth-required, or auth-required+admin.
4. **No guest-ok tier exists today** — Phase 2 is introducing it from scratch; there is no existing code to preserve or conflict with.
5. **SessionMiddleware interface is mockable** — the `SessionFetcher` interface enables clean unit test doubles for any handler Phase 2 introduces.
6. **CORS origin list is documented** — Phase 2 can add new origins knowing exactly where the list lives.

**Routes Phase 2 will likely change from auth-required to guest-ok:**
- `/compass/answers` (GET and POST) — currently auth-required; guest users should be able to take the quiz
- `/compass/answers/batch` (POST) — same reason
- `/compass/selected-topics` (GET/PUT) — quiz configuration; guests should be able to use it
- `/compass/compare` (POST) — quiz results comparison; guests should be able to compare

These are flagged here for Phase 2 awareness; Phase 1 does not modify them.

---

## Deliverable Structure

### .planning/ (planning summary)
- `01-RESEARCH.md` — this file
- `01-01-PLAN.md` — single plan covering both sub-tasks (cookie doc + test suite)
- `01-01-SUMMARY.md` — post-completion summary

### EV-Backend/docs/ (codebase documentation — to be created)
- `EV-Backend/docs/auth-audit.md` — full auth audit document containing:
  - Cookie configuration specification
  - Session lifecycle documentation
  - Route auth level manifest (as a section, not standalone file)
  - CORS origins list
  - Domain migration notes
  - Phase 2 handoff section

### Test files (to be created)
- `EV-Backend/internal/auth/auth_integration_test.go` — integration tests against real DB
- `EV-Backend/internal/middleware/middleware_test.go` — unit tests with mock fetcher

---

## Sources

### Primary (HIGH confidence)

Direct source code inspection of:
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/auth/handlers.go` — cookie config, login/logout/me/update-password handlers
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/auth/routes.go` — auth route definitions
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/auth/models.go` — Session and User models
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/auth/fetcher.go` — SessionFetcher implementation
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/middleware/middleware.go` — SessionMiddleware, AdminMiddleware, CORS, allowed origins
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/compass/routes.go` — compass route definitions
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/routes.go` — essentials route definitions
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/staging/routes.go` — staging route definitions
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/treasury/routes.go` — treasury route definitions
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/webhooks/routes.go` — webhooks route definitions
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/main.go` — router assembly and module mounting
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/go.mod` — module name and dependency versions
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/utils/context.go` — context key for userID
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/utils/sessiondata.go` — SessionData struct

### Secondary (MEDIUM confidence)

- Go stdlib documentation for `net/http/httptest` and `net/http/cookiejar` — testing patterns consistent with published Go testing idioms

---

## Metadata

**Confidence breakdown:**
- Cookie config audit: HIGH — read directly from source code
- Route manifest: HIGH — compiled from all routes.go files by direct inspection
- Testing approach: HIGH — based on existing Go stdlib capabilities + existing test pattern in google_test.go
- Security observations: HIGH — behavioral, not speculative

**Research date:** 2026-02-17
**Valid until:** Stable — only changes if route files or auth handlers change
