# Codebase Structure

**Analysis Date:** 2026-02-17

## Directory Layout

```
/Users/chrisandrews/Documents/GitHub/
├── EV-Backend/                 # Go REST API backend
│   ├── main.go                 # Entry point: router setup and module initialization
│   ├── go.mod / go.sum         # Go dependencies
│   ├── internal/
│   │   ├── db/                 # Database layer (PostgreSQL + GORM)
│   │   ├── middleware/         # CORS, session, admin middleware
│   │   ├── auth/               # Authentication module (login, register, session)
│   │   ├── compass/            # Political compass module (topics, stances, answers)
│   │   ├── essentials/         # Politician data module (ZIP lookup, BallotReady API)
│   │   ├── treasury/           # Budget data module (cities, budgets, line items)
│   │   ├── staging/            # Data entry workflow module (volunteer stances, review)
│   │   ├── webhooks/           # Framer form integration
│   │   ├── utils/              # Shared utilities (UUID, context helpers)
│   │   ├── seeds/              # Database seed data
│   │   └── compassimport/      # CSV import utilities
│   ├── cmd/                    # CLI commands (seed, backfill, bulk-import)
│   └── .env.local              # Local environment (DATABASE_URL, API keys) - NOT COMMITTED
│
├── CompassV2/                  # React political compass app
│   ├── src/
│   │   ├── main.jsx            # App mount point with Context provider
│   │   ├── App.jsx             # Route definitions
│   │   ├── pages/              # Route components (Quiz, Compass, Library, etc.)
│   │   ├── components/         # Feature components
│   │   │   ├── CompassContext.jsx  # State management context
│   │   │   ├── RadarChart.jsx      # Chart visualization
│   │   │   ├── admin/              # Admin dashboard components
│   │   │   └── ...
│   │   ├── hooks/              # Custom React hooks
│   │   ├── util/               # Helper functions
│   │   ├── assets/             # Images, animations
│   │   └── index.css           # Global styles
│   ├── vite.config.js          # Vite build config
│   ├── package.json            # Dependencies
│   └── public/                 # Static assets
│
├── essentials/                 # React politician discovery app
│   ├── src/
│   │   ├── main.jsx            # App mount point
│   │   ├── App.jsx             # Route definitions
│   │   ├── pages/              # Route components (Dashboard, Profile, Results)
│   │   ├── components/         # UI components (PoliticianCard, Grid, etc.)
│   │   ├── hooks/              # Custom hooks (usePoliticianData, useGooglePlaces)
│   │   ├── lib/
│   │   │   ├── api.jsx         # API client (fetchPoliticiansProgressive, search)
│   │   │   ├── classify.js     # Politician categorization logic
│   │   │   └── compass.js      # Compass integration helper
│   │   ├── utils/              # Text, sorting utilities
│   │   └── App.css             # Global styles
│   ├── vite.config.js
│   ├── package.json
│   └── public/
│
├── ev-ui/                      # React component library (npm package)
│   ├── src/
│   │   ├── index.jsx           # Package entry point (exports all components)
│   │   ├── RadarChartCore.jsx  # Core chart component (animated, dual-dataset)
│   │   ├── PoliticianProfile.jsx   # Politician detail view
│   │   ├── PoliticianCard.jsx      # Politician grid card
│   │   ├── Header.jsx              # App header
│   │   ├── SiteHeader.jsx          # Site-wide header
│   │   ├── AuthForm.jsx            # Login/register form
│   │   └── ... (other components)
│   ├── package.json            # @EmpoweredVote/ev-ui published to GitHub npm
│   ├── tsup.config.js          # Build config (ESM + CJS)
│   └── dist/                   # Generated (NOT COMMITTED)
│
├── EV-prototypes/              # Feature prototype monorepo (Netlify deployment)
│   ├── package.json            # Root package
│   ├── netlify.toml            # Netlify routing config
│   ├── read-rank/              # Swipe-based candidate quote evaluation
│   ├── treasury-tracker/       # Budget visualization prototype
│   ├── data-entry/             # Volunteer data entry prototype
│   ├── empowered-badges/       # Learning modules prototype
│   └── fallacy-finders/        # Fallacy detection prototype
│
├── .planning/                  # Generated planning documents
│   └── codebase/               # GSD codebase analysis outputs
│       ├── ARCHITECTURE.md
│       ├── STRUCTURE.md
│       ├── STACK.md            # (if tech focus)
│       └── ... (other analyses)
│
└── ... (other repos: CouncilScribe, scrapers, etc.)
```

## Directory Purposes

**EV-Backend/:**
- Purpose: Central REST API serving all frontend applications
- Contains: Go modules, handlers, database access, external API integrations
- Key entry: `main.go` initializes all modules and starts server on port 5050
- Schemas: `app_auth`, `compass`, `essentials`, `treasury`, `staging`, `inbox`

**EV-Backend/internal/db/:**
- Purpose: Database connection and schema management
- Contains: GORM initialization, connection pooling, schema creation
- Key files: `db.go` (Connect function), `schema.go` (schema setup)
- Used by: All modules via `db.DB` global

**EV-Backend/internal/auth/:**
- Purpose: User authentication and session management
- Contains: Login/register handlers, session validation middleware
- Key files: `models.go` (User, Session), `handlers.go`, `routes.go`
- Routes: `/auth/login`, `/auth/register`, `/auth/me`, `/auth/logout`

**EV-Backend/internal/compass/:**
- Purpose: Political compass quiz and politician comparison
- Contains: Topic management, stance tracking, user answers
- Key files: `models.go` (Topic, Stance, Answer, Context), `handlers.go`, `fetcher.go`
- Routes: `/compass/topics`, `/compass/answers`, `/compass/politicians`, `/compass/compare`

**EV-Backend/internal/essentials/:**
- Purpose: Politician discovery by ZIP code with BallotReady API integration
- Contains: Politician data models, caching layer, BallotReady client, geocoding
- Key files: `models.go`, `setup.go`, `ballotready/client.go`, `provider/interface.go`
- Routes: `/essentials/politicians/{zip}`, `/essentials/politicians/search`, `/essentials/politician/{id}`
- Schemas: `essentials.politicians`, `essentials.offices`, `essentials.districts`, `essentials.zip_caches`

**EV-Backend/internal/essentials/ballotready/:**
- Purpose: BallotReady GraphQL client and data transformation
- Contains: GraphQL queries, response parsing, upsert logic
- Key files: `client.go` (FetchOfficials, FetchPositionsByZip), `transform*.go`

**EV-Backend/internal/essentials/provider/:**
- Purpose: Abstract politician data source selection
- Contains: Interface definition, factory for creating providers
- Key files: `interface.go` (OfficialProvider), `factory.go` (NewProvider)

**EV-Backend/internal/treasury/:**
- Purpose: Municipal budget data management
- Contains: City, Budget, BudgetCategory, BudgetLineItem models
- Routes: `/treasury/budgets/{city}`, `/treasury/cities`

**EV-Backend/internal/staging/:**
- Purpose: Data entry workflow for volunteer-entered politician stances
- Contains: StagingStance, StagingPolitician, ReviewLog models with review workflow
- Routes: `/staging/stances`, `/staging/review`, `/staging/approve`

**CompassV2/:**
- Purpose: Interactive political compass quiz with radar chart
- Key pages: Quiz, Compass (results), Library, Home
- State management: `CompassContext.jsx` (React Context)
- Key component: `RadarChart.jsx` for visualization

**CompassV2/src/pages/:**
- `Quiz.jsx` - Quiz question flow
- `Compass.jsx` - Results with radar chart
- `Home.jsx` - Dashboard after login
- `Library.jsx` - Topic/politician exploration
- `Login.jsx`, `Register.jsx` - Auth pages
- `BuildCompass.jsx` - Selected topics customization

**essentials/:**
- Purpose: Politician discovery and detail view by ZIP code
- Key pages: Dashboard (ZIP search), Results (list), Profile (detail)
- Key logic: `lib/classify.js` (politician categorization), `lib/api.jsx` (polling)
- Hooks: `usePoliticianData()` (progressive loading with polling)

**essentials/src/lib/:**
- `api.jsx` - API client with progressive polling
- `classify.js` - Categorize politicians into Federal/State/Local tiers
- `compass.js` - Cross-link to CompassV2 for political stances

**ev-ui/:**
- Purpose: Shared component library published to GitHub npm registry
- Main export: `RadarChartCore` (animated chart), `PoliticianProfile`, `PoliticianCard`
- Build: tsup generates ESM and CJS bundles to `dist/`
- Consumed by: CompassV2, essentials, EV-prototypes

**EV-prototypes/:**
- Purpose: Feature prototypes deployed to Netlify under single domain
- Sub-projects each have own `src/` and build output
- Root `package.json` defines build commands for all
- `netlify.toml` configures SPA routing

## Key File Locations

**Entry Points:**

- Backend: `EV-Backend/main.go` - Loads env, connects DB, mounts routes
- CompassV2: `CompassV2/src/main.jsx` - Mounts React app with CompassProvider
- essentials: `essentials/src/main.jsx` - Mounts React app with BrowserRouter
- ev-ui: `ev-ui/src/index.jsx` - Exports all public components

**Configuration:**

- Backend: `EV-Backend/.env.local` (local only, contains DATABASE_URL, BALLOTREADY_API_KEY)
- Backend: `EV-Backend/go.mod` - Go dependencies
- CompassV2: `CompassV2/vite.config.js`, `CompassV2/package.json`
- essentials: `essentials/vite.config.js`, `essentials/package.json`
- ev-ui: `ev-ui/tsup.config.js` - Bundler config
- EV-prototypes: `EV-prototypes/netlify.toml` - Deployment routing

**Core Logic:**

- Backend modules: Each at `EV-Backend/internal/<module>/`
  - `models.go` - GORM models
  - `setup.go` - Init() and migrations
  - `routes.go` - SetupRoutes()
  - `handlers.go` - HTTP handlers
  - `fetcher.go` - Database queries

- Frontend API clients: `essentials/src/lib/api.jsx`, `CompassV2/src/components/CompassContext.jsx`
- Classification logic: `essentials/src/lib/classify.js`
- Middleware: `EV-Backend/internal/middleware/middleware.go`

**Testing:**

- Not visible in directory structure (no test files found)
- Likely unit tests co-located with source or in `*_test.go` files

**Data & Utilities:**

- `EV-Backend/cmd/` - CLI commands (seed data, bulk import, backfill)
- `EV-Backend/ballotready_samples/` - Sample API responses for testing
- `EV-Backend/scripts/` - Shapefile data for district boundaries
- `EV-prototypes/treasury-tracker/data/` - Budget data files
- `essentials/src/utils/` - Sorting, text manipulation helpers

## Naming Conventions

**Files:**

- Go files: `lowercase_with_underscores.go` (e.g., `models.go`, `setup.go`)
- React files: `PascalCase.jsx` (e.g., `CompassContext.jsx`, `RadarChart.jsx`)
- Utility files: `lowercase-with-hyphens.js` or `camelCase.js` (e.g., `index.jsx`, `api.jsx`)
- Config files: lowercase with extensions (e.g., `package.json`, `vite.config.js`)

**Directories:**

- Backend packages: lowercase (e.g., `auth`, `compass`, `essentials`)
- Frontend features: lowercase or PascalCase (e.g., `pages/`, `components/`, `hooks/`)
- Shared: `lib/` for logic, `utils/` for helpers, `assets/` for static files

**Functions:**

- Go: PascalCase for exported (public), camelCase for unexported (private)
- JavaScript: camelCase for functions, PascalCase for React components
- Handlers: `<Domain><Action>Handler` (e.g., `TopicHandler`, `LoginHandler`)

**Variables:**

- Go: camelCase
- JavaScript: camelCase, use `const` by default
- React hooks: `use<Name>` (e.g., `usePoliticianData`, `useGooglePlacesAutocomplete`)

**Types:**

- Go structs: PascalCase (e.g., `Politician`, `CompassContext`)
- GORM table names: schema.lowercase (e.g., `compass.topics`, `essentials.politicians`)
- TypeScript/JavaScript: PascalCase for interfaces/types

## Where to Add New Code

**New Backend Feature:**

1. Create package: `EV-Backend/internal/<feature>/`
2. Create models: `models.go` with `TableName()` returning schema-qualified name
3. Create setup: `setup.go` with `Init()` calling `db.DB.AutoMigrate()`
4. Create routes: `routes.go` with `SetupRoutes()` returning Chi router
5. Create handlers: `handlers.go` with request handlers
6. Create fetcher: `fetcher.go` with database queries (optional, use if many queries)
7. Wire into main: Call `<feature>.Init()` and `r.Mount("/<feature>", <feature>.SetupRoutes())`

**New Frontend Component (React):**

1. Determine scope:
   - Page-level: `src/pages/<Feature>.jsx`
   - Feature component: `src/components/<Feature>.jsx` or `src/components/<Domain>/<Feature>.jsx`
   - Shared UI: Consider adding to `ev-ui` instead

2. Implement:
   ```jsx
   export default function <Feature>() {
     // Use hooks for data fetching
     // Use Context for shared state
     // Call API from lib/api.jsx
     return <div>...</div>
   }
   ```

3. Register route (if page) in `App.jsx`

**New Hook (React):**

1. Create file: `src/hooks/use<Feature>.js`
2. Implement following React Hooks conventions
3. Export from hook file
4. Import and use in components

**New Utility Function:**

- Shared across apps: Add to `ev-ui/src/`
- App-specific: Add to `src/lib/` or `src/utils/`

**Tests:**

- Backend: Create `*_test.go` alongside source
- Frontend: Create `*.test.jsx` or `.spec.js` alongside component

## Special Directories

**EV-Backend/cmd/:**
- Purpose: Standalone command-line tools
- Generated: No
- Committed: Yes
- Examples: `seed/` (populate test data), `bulk-import/`, `backfill-state-exec/`

**EV-Backend/ballotready_samples/:**
- Purpose: Sample API responses for development and testing
- Generated: No (manually collected from API)
- Committed: Yes
- Usage: Reference for API structure, potential test fixtures

**EV-Backend/scripts/:**
- Purpose: Data processing and utility scripts
- Generated: No
- Committed: Yes
- Contains: Shapefile data for boundary lookups, helper scripts

**ev-ui/dist/:**
- Purpose: Bundled component library exports (ESM and CJS)
- Generated: Yes (by `npm run build`)
- Committed: No
- Consumed by: CompassV2, essentials, EV-prototypes via `@EmpoweredVote/ev-ui`

**EV-prototypes/dist/:**
- Purpose: Built prototype artifacts for Netlify deployment
- Generated: Yes
- Committed: No
- Deployed to: Netlify with SPA routing

**.env.local files:**
- Purpose: Local development environment variables
- Generated: No (developer creates)
- Committed: No (in .gitignore)
- Contains: DATABASE_URL, API keys, local config
- Never commit secrets to git

**Temporary directories (node_modules, .next, build/):**
- Generated: Yes (by package managers and build tools)
- Committed: No
- Git-ignored: Yes

---

*Structure analysis: 2026-02-17*
