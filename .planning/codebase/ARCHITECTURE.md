# Architecture

**Analysis Date:** 2026-02-17

## Pattern Overview

**Overall:** Modular multi-tier architecture with:
- **Backend:** Go REST API using Chi router with plugin-based modules
- **Frontend:** React SPA applications with React Router and Context-based state management
- **Shared:** Component library published as npm package

**Key Characteristics:**
- Module-per-feature pattern in backend (auth, compass, essentials, treasury, staging)
- Each backend module owns its schema, routes, and handlers
- Session-based authentication with HTTP-only cookies
- API-first design: React apps consume `/api.empowered.vote` endpoints
- Provider pattern for pluggable data sources (BallotReady vs. Cicero)

## Layers

**Database Layer:**
- Purpose: PostgreSQL persistence with GORM ORM
- Location: `EV-Backend/internal/db/`
- Contains: Connection pooling, schema management, migration coordination
- Depends on: Environment configuration (DATABASE_URL)
- Used by: All internal modules

**Module Layer (Backend):**
- Purpose: Feature-scoped packages encapsulating domain logic
- Location: `EV-Backend/internal/<module>/` (auth, compass, essentials, treasury, staging, webhooks)
- Contains: Models, handlers, routes, fetchers, setup logic
- Depends on: db layer, middleware, external APIs
- Used by: Main router

**Middleware Layer:**
- Purpose: Cross-cutting concerns (CORS, authentication, authorization)
- Location: `EV-Backend/internal/middleware/`
- Contains: Session validation, admin checks, CORS headers
- Depends on: HTTP context, session data
- Used by: Route setup in each module

**HTTP Router Layer:**
- Purpose: Entry point and route composition
- Location: `EV-Backend/main.go`
- Contains: Chi router setup, module mounting
- Depends on: All modules via SetupRoutes()
- Used by: Go http.ListenAndServe

**Frontend Data Layer:**
- Purpose: API client functions and state fetching
- Location: `essentials/src/lib/api.jsx`, `CompassV2/src/components/CompassContext.jsx`
- Contains: Fetch wrappers, polling logic, data transformations
- Depends on: Backend API endpoints
- Used by: React components and hooks

**Frontend State Layer:**
- Purpose: Application state management and side effects
- Location: React Context (CompassV2), component-level state (essentials)
- Contains: Topics, answers, politician data, UI state
- Depends on: Data layer (API calls)
- Used by: React components

**Frontend UI Layer:**
- Purpose: Component rendering and user interaction
- Location: `CompassV2/src/pages/`, `CompassV2/src/components/`, `essentials/src/pages/`
- Contains: Page components, feature components, shared UI elements
- Depends on: State layer, ev-ui component library
- Used by: React Router

**Component Library:**
- Purpose: Shared React components for use across applications
- Location: `ev-ui/src/`
- Contains: RadarChartCore, PoliticianCard, PoliticianProfile, headers, forms
- Depends on: React, react-spring
- Used by: CompassV2, essentials, EV-prototypes

## Data Flow

**Politician Discovery Flow (essentials app):**

1. User enters ZIP code in `Dashboard.jsx`
2. Component calls `fetchPoliticiansProgressive(zip)` from `api.jsx`
3. `fetchPoliticiansOnce` hits `GET /essentials/politicians/{zip}`
4. Backend checks `essentials.zip_caches` for freshness (90-day TTL)
5. If fresh: returns cached data with `X-Data-Status: fresh`
6. If stale/missing: kicks background goroutines and returns `202 Accepted` with `Retry-After` header
7. Background goroutines call BallotReady GraphQL API via provider
8. Warmers upsert `essentials.politicians`, `essentials.offices`, etc.
9. Frontend polls with exponential backoff until `status !== 'warming'`
10. Final response returns `fresh` status with complete politician data

**Compass Quiz Flow (CompassV2 app):**

1. `CompassProvider` (Context) loads topics from `GET /compass/topics` on mount
2. User answers quiz questions, answers stored in context state
3. On submit, POST `answers` to `/compass/answers` (creates `compass.answers` table entry)
4. User selects subset of topics for comparison (saved to `compass.user_compass`)
5. Fetch politician answers for selected topics via `GET /compass/politicians`
6. Render radar chart comparing user vs. politicians on selected axes

**Authentication Flow:**

1. Public: POST `/auth/login` with credentials (no session yet)
2. Backend validates password, creates session record
3. Returns HTTP-only cookie with session ID
4. Client stores cookie automatically (browser manages)
5. Subsequent requests include cookie (credentials: "include")
6. Protected routes: `SessionMiddleware` validates session, extracts user context
7. Admin routes: `AdminMiddleware` checks role after session validation
8. Logout: DELETE `/auth/logout` deletes session, clears cookie

**State Management:**

- **CompassV2:** React Context in `CompassContext.jsx` with localStorage fallback
  - Topics loaded from server on mount
  - Selected topics persist to localStorage
  - User answers held in context until submitted
  - Inverted spokes (spoke inversion toggles) persisted to localStorage

- **essentials:** Component-level state in hooks
  - `usePoliticianData()` manages polling and retries
  - Politician data fetched on-demand per ZIP code
  - No global state needed

- **Server state:** Database tables are source of truth
  - Session state in `app_auth.sessions`
  - Compass answers in `compass.answers`
  - Cached politicians in `essentials.politicians`

## Key Abstractions

**Provider Pattern (Essentials):**
- Purpose: Abstract politician data sources (BallotReady vs. Cicero)
- Examples: `internal/essentials/provider/interface.go`, `internal/essentials/ballotready/client.go`, `internal/essentials/cicero/client.go`
- Pattern: Interface-based provider with factory pattern
  - `provider.NewProvider(cfg)` returns concrete implementation
  - Each provider implements `FetchOfficials()`, `FetchPositionsByZip()`, `FetchCandidacy()`
  - Registered via `init()` functions

**Module Pattern (Backend):**
- Purpose: Encapsulate domain logic with consistent interface
- Examples: Each `internal/<module>/` has: models.go, setup.go, routes.go, handlers.go, fetcher.go
- Pattern:
  - `Init()` called from main, does schema setup and initialization
  - `SetupRoutes()` returns Chi router with public/protected branches
  - Handlers use Chi context for request/response

**Handler Pattern:**
- Purpose: HTTP request processing with dependency injection
- Examples: `internal/compass/handlers.go` TopicHandler, UserAnswersHandler
- Pattern: `func(w http.ResponseWriter, r *http.Request)` signature
  - Use `r.Context()` for injected values (user ID, etc.)
  - Return JSON with structured response envelope or error

**Fetcher Pattern (Database Access):**
- Purpose: Isolate database queries from handlers
- Examples: `internal/compass/fetcher.go` FetchTopics, FetchUserAnswers
- Pattern: Separate layer for GORM queries
  - Returns domain models
  - Handlers call fetchers, serialize to JSON

**React Context Pattern:**
- Purpose: Shared state across component tree
- Examples: `CompassV2/src/components/CompassContext.jsx`
- Pattern:
  - Context created via `createContext()`
  - Provider wraps app tree
  - Components call `useContext(CompassContext)` to access state/dispatchers
  - Side effects handled in useEffect hooks

**Route Guarding (Frontend):**
- Purpose: Protect routes by authentication/authorization
- Examples: `CompassV2/src/components/ProtectedRoute.jsx`, `AdminRoute.jsx`
- Pattern: Wrapper components that check auth state and either render or redirect

## Entry Points

**Backend:**
- Location: `EV-Backend/main.go`
- Triggers: `go run .` or Docker container startup
- Responsibilities:
  - Load env vars from `.env.local`
  - Initialize database connection
  - Call `Init()` on all modules
  - Create Chi router and mount module routes
  - Listen on configured port (default 5050)

**CompassV2 Frontend:**
- Location: `CompassV2/src/main.jsx`
- Triggers: `npm run dev` or build artifact loading
- Responsibilities:
  - Mount React app to #root DOM element
  - Setup BrowserRouter with `CompassProvider` wrapper
  - Render App.jsx with route definitions

**essentials Frontend:**
- Location: `essentials/src/main.jsx`
- Triggers: `npm run dev` or build artifact loading
- Responsibilities:
  - Mount React app to #root DOM element
  - Setup BrowserRouter (no global context needed)
  - Render App.jsx with route definitions

**Component Library:**
- Location: `ev-ui/src/index.jsx`
- Triggers: `npm run build` generates dist/ exports
- Responsibilities:
  - Export all public components
  - Consumed by CompassV2, essentials, EV-prototypes via npm package

## Error Handling

**Strategy:**

Backend: Structured error responses with HTTP status codes + JSON error envelope
Frontend: Try/catch with user-facing messages + fallbacks

**Patterns:**

Backend:
```go
// Handlers check for errors and write appropriate status
if err := db.DB.First(&topic, id).Error; err != nil {
    if errors.Is(err, gorm.ErrRecordNotFound) {
        w.WriteHeader(http.StatusNotFound)
        json.NewEncoder(w).Encode(map[string]string{"error": "Not found"})
    } else {
        w.WriteHeader(http.StatusInternalServerError)
        json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
    }
    return
}
```

Frontend:
```javascript
// API functions return { status, data, error }
// Components check status and render appropriately
if (once.status === "error") {
  return { status: "error", data: [], error: error.message };
}

// Components handle warming with retry logic
if (once.status === "warming") {
  await sleep((once.retryAfter ?? 3) * 1000);
  continue;
}
```

## Cross-Cutting Concerns

**Logging:**
- Go: GORM logger configured in `internal/db/db.go` with 100ms slow query threshold
- JavaScript: `console.log/error` in fetch wrappers and context initialization

**Validation:**
- Backend: GORM struct tags (not null, unique indexes, foreign keys)
- Frontend: Form inputs check before submission; backend validates shape + constraints

**Authentication:**
- Session-based with HTTP-only secure cookies
- Middleware validates session, injects user ID into request context
- All sensitive operations require `SessionMiddleware` + optional `AdminMiddleware`

**CORS:**
- Configured in `internal/middleware/middleware.go`
- Allows credentials: true for session cookies
- Specifies allowed origins (frontend domains)

**Caching:**
- Politician data: 90-day TTL per ZIP (essentials.zip_caches)
- Federal/state: Nationwide caching with last-updated tracking
- Background warmers keep cache fresh on stale request

**Rate Limiting:** Not explicitly implemented; relies on database connection pooling

---

*Architecture analysis: 2026-02-17*
