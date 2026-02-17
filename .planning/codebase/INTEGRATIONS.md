# External Integrations

**Analysis Date:** 2026-02-17

## APIs & External Services

**BallotReady/CivicEngine GraphQL API:**
- What: Politician data, positions, endorsements, stances, elections, contact info
- SDK/Client: Custom Go client (`EV-Backend/internal/essentials/ballotready/client.go`)
  - GraphQL queries for officeholders, positions, candidacies
  - Relay cursor-based pagination support
  - 30-second HTTP timeout
- Auth: `BALLOTREADY_API_KEY` environment variable
- Endpoint: https://api.civicengine.com/graphql (inferred)
- Data captured: 95% of available BallotReady fields including:
  - Position-level: geo_id, seats, partisan_type, salary, retention, staggered_term
  - Officeholder-level: is_appointed, is_vacant, is_off_cycle, party_short_name
  - Person-level: biography, bioguide_id, images, education, experience
  - Candidacy data: endorsements, stances, election records, contact info

**Google Maps Geocoding API:**
- What: Address geocoding for ZIP code extraction, state/county/city parsing
- SDK/Client: Custom Go HTTP client (`EV-Backend/internal/essentials/geocoding/google.go`)
- Auth: `GOOGLE_MAPS_API_KEY` environment variable
- Endpoint: https://maps.googleapis.com/maps/api/geocode/json
- Request timeout: 5 seconds
- Used in: essentials app address search, essentials backend for politician location data
- Frontend: @googlemaps/js-api-loader v2.0.2 (essentials app)

**Framer Form Webhooks:**
- What: Volunteer form submissions (not currently integrated in main features)
- Endpoint: `/webhooks/framer/volunteer` (POST)
- Auth: HMAC-SHA256 signature verification
- Header validation: Framer-Signature, Framer-Webhook-Submission-Id
- Secret: `FRAMER_WEBHOOK_SECRET` environment variable
- Payload size limit: 1 MiB
- Location: `EV-Backend/internal/webhooks/handler.go`

## Data Storage

**Primary Database:**
- Type/Provider: PostgreSQL (via Supabase)
- Connection: `DATABASE_URL` environment variable
  - Format: PostgreSQL URI connection string
  - Development: Isolated Supabase project for AI-assisted work
  - Production: AWS Secrets Manager managed (AppRunner env injection)
- Client: GORM 1.30.0 (Go ORM)
- Connection pooling:
  - Max open connections: 20
  - Max idle connections: 20
  - Max lifetime: 30 minutes
- Slow query logging: Queries >100ms logged to stdout

**Database Schemas:**
- `app_auth` - Session and user credentials
- `compass` - Topics, answers, politician stances
- `essentials` - Politicians, offices, districts, chambers, ZIP mappings, images, education, experience, endorsements, issues, candidacy data
- `treasury` - Cities, budgets, budget categories, line items
- `staging` - Volunteer data entry (stances, politicians, review workflow)
- `inbox` - Reserved for future use

**File Storage:**
- Local filesystem only (no cloud storage integration)
- Static data in `/dist/data/` for prototypes (treasury-tracker, read-rank)
- CSV seed data in `EV-Backend/internal/compass/data/topics.json`

**Caching:**
- Application-level caching in database tables:
  - `essentials.zip_caches` - Tracks last fetch time per ZIP code (90-day TTL)
  - `essentials.federal_cache` - Tracks last national officials fetch
  - `essentials.state_caches` - Tracks last fetch per state
- Background warmer goroutines for async data refresh
- Containment status tracking: `essentials.zip_politicians.is_contained` (null for federal/state, true/false for local)

## Authentication & Identity

**Auth Provider:**
- Type: Custom session-based (HTTP-only cookies)
- Implementation: `EV-Backend/internal/auth/`
- Session storage: PostgreSQL (app_auth.sessions table)
- Mechanisms:
  - Username + password registration/login with bcrypt hashing
  - Session ID cookie (`session_id` HTTP-only)
  - Session expiry: Configurable per user
- Frontend pattern:
  - All API calls include `credentials: "include"`
  - Validates via `/auth/me` endpoint (protected by SessionMiddleware)
  - Stores session locally in HTTP-only cookie
- CORS configuration: Strict allow-list by origin
  - Development: localhost:5173, localhost:5174
  - Production: Configured via `ALLOWED_ORIGINS` env var (AWS Secrets Manager)

**Cookie Configuration:**
- Secure: true (production), false (development)
- HttpOnly: true (always)
- SameSite: None (production), Lax (development)
- Domain: Omitted for dev (note: must restore to `.empowered.vote` before production deployment)
- Path: /

## Monitoring & Observability

**Error Tracking:**
- None detected (not integrated)

**Logging:**
- Approach: stdout/stderr to CloudWatch (App Runner) or console (frontend)
- Backend: GORM query logging with execution time
  - Info level: SQL + timing for queries >100ms
  - Colorful output for CLI debugging
- Frontend: Browser console.error/console.log
- Logging handled at module level (no centralized logging service)

## CI/CD & Deployment

**Hosting:**
- Backend: AWS App Runner (managed container runtime)
  - Build via `apprunner.yaml` (Go 1.24.3 native build)
  - Runtime: Custom Go binary on App Runner
  - Database: Supabase (separate AWS region)
- Frontend (CompassV2): Netlify static hosting
  - Build: `npm run build` (Vite production build)
  - Publish: `dist/` directory
  - SPA routing: Redirects catch-all to index.html
  - API redirect: `/api/*` → `https://ev-backend-h3n8.onrender.com/:splat` (fallback to Render)
- Frontend (essentials): Netlify static hosting (similar config)
- Frontend (EV-prototypes): Netlify multi-project deployment
  - Each sub-project builds independently
  - Mounted at `/dist/` subdirectory per project

**CI Pipeline:**
- None detected (not currently automated)
- Manual deployments via platform UIs or git hooks

**Deployment Platforms:**
- AWS App Runner - Backend (Go binary deployment)
- Netlify - All React frontend deployments
- Render.com - Fallback API endpoint (used in CompassV2 netlify.toml)
- GitHub Pages - CompassV2 gh-pages deployment (see `npm run deploy`)

## Environment Configuration

**Backend Required env vars:**
- `DATABASE_URL` - PostgreSQL connection string (mandatory)
- `BALLOTREADY_API_KEY` - BallotReady API credentials
- `GOOGLE_MAPS_API_KEY` - Google Maps API key (optional, graceful degradation)
- `FRAMER_WEBHOOK_SECRET` - Webhook signature verification (optional)
- `ALLOWED_ORIGINS` - CORS allow-list (comma-separated origins)
- `PORT` - Server port (default: 5050)
- `CICERO_KEY` - Legacy/fallback (documented in apprunner.yaml but deprecated by BallotReady migration)

**Frontend Required env vars (VITE_ prefix):**
- `VITE_API_URL` - Backend API endpoint (default: `/api`)
  - CompassV2: Hardcoded to https://api.empowered.vote (production)
  - essentials: Configurable, defaults to /api (Netlify proxy)
- `VITE_GOOGLE_MAPS_API_KEY` - Google Maps JavaScript API key (essentials only)

**Secrets Storage:**
- Development: `.env.local` (git-ignored, never committed)
- Production: AWS Secrets Manager (referenced in apprunner.yaml)
  - Secret path: `ev/prod/backend-hKU59w` (prod), `ev/dev/backend-QwxP7W` (dev)

## Webhooks & Callbacks

**Incoming:**
- POST `/webhooks/framer/volunteer` - Framer form submissions
  - Validates HMAC-SHA256 signature using `FRAMER_WEBHOOK_SECRET`
  - Submits volunteer contact info to database
  - Currently in development (not actively used)

**Outgoing:**
- None detected

## Package Registry

**GitHub npm Registry:**
- Registry: https://npm.pkg.github.com
- Package: @chrisandrewsedu/ev-ui (published)
- Authentication: NPM_TOKEN environment variable (Netlify CI builds)
- Consumers: All frontend projects
- Files: `.npmrc` configured in all Node projects (do not remove _authToken line)

---

*Integration audit: 2026-02-17*
