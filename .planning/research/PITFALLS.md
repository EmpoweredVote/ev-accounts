# PITFALLS.md — Empowered Vote Platform Improvements

Research type: Pitfalls
Question: What do civic engagement and multi-app platform projects commonly get wrong when adding guest auth, evolving data models, and consolidating codebases?

---

## Domain: Guest Auth / Login-Optional Conversion

### PITFALL 1: Session identity collision when guest becomes authenticated user

**What goes wrong:** A guest user takes a quiz or builds up state (answers, selected topics, progress). When they create an account or log in, the backend creates a new session but the frontend still holds the guest state in localStorage or component memory. The merge never happens, so the user loses their work — or worse, the guest state silently overwrites the authenticated user's server-side state.

**Warning signs:**
- Any "save progress" CTA that routes to login without a post-login redirect that triggers a sync
- localStorage keys that are written under a guest key and never migrated on auth
- Backend session endpoint returns a new user ID with no merge/claim mechanism

**Prevention strategy:**
- Design a guest session token (anonymous UUID, stored in a cookie or localStorage) from day one
- On login/register, POST the guest token to the backend so the server can merge guest state into the new account
- Compass: before launching guest mode, define which state is mergeable (quiz answers) vs. discarded (temporary UI state)
- **Phase:** Guest auth phase (before any frontend work ships guest-first flows)

---

### PITFALL 2: Treating "guest" as "no auth" rather than a distinct identity tier

**What goes wrong:** The team implements guest mode by simply removing the auth guard. There is no persistent guest identity. Every page refresh resets the user. Analytics, personalization, and A/B experiments become impossible. When the user eventually creates an account there is nothing to associate.

**Warning signs:**
- "Guest" is implemented as a boolean flag on existing session logic
- No cookie or token is issued to the guest browser
- Backend has no guest user row or ephemeral session record

**Prevention strategy:**
- Issue a real (but limited) session or anonymous ID to every visitor, even before login
- Store minimal guest state server-side (or at minimum sign it client-side) so it survives tab close
- Compass: the quiz answer set and topic selections are the key mergeable artifacts — design for that from the start
- **Phase:** Guest auth phase, auth layer design step

---

### PITFALL 3: Guarded API endpoints accidentally exposed to guests (or vice versa)

**What goes wrong:** After removing the login gate from the frontend, developers forget that certain backend routes require a valid session. Guests hit 401s on data they should see. Alternatively, routes are opened too broadly and authenticated-only writes (saving stances, account preferences) accept unauthenticated requests.

**Warning signs:**
- Chi middleware applied at the router level rather than per-route or per-group
- No integration test that makes unauthenticated requests to every route and asserts the expected status code
- Frontend silently swallows 401s without distinguishing "not logged in" from "actually forbidden"

**Prevention strategy:**
- Audit the Chi route tree in EV-Backend: explicitly mark every route as public, guest-ok, or auth-required
- Add a middleware pattern (e.g., `OptionalSession` vs. `RequireSession`) so intent is encoded in the route definition, not assumed
- Write a route manifest document during auth phase that lists expected auth levels per endpoint
- **Phase:** Guest auth phase, backend route audit step

---

### PITFALL 4: Compass live users lose existing sessions during the auth model change

**What goes wrong:** The session cookie domain, SameSite, or expiry changes as part of the guest auth rollout. Existing logged-in users are silently logged out. On a civic platform used during election season this can cause real trust damage.

**Warning signs:**
- Cookie config changes (domain, SameSite, Secure flags) in the same deploy as guest mode
- No session migration or backward-compatible cookie handling for existing sessions
- The CLAUDE.md "Cookie Domain Configuration" note is not resolved before the auth change ships

**Prevention strategy:**
- Resolve the cookie domain issue (restore `.empowered.vote` domain) in a separate deploy before any auth model changes
- Test existing session continuity on Compass with real browsers (Safari, Chrome, Firefox) after every deploy that touches auth middleware
- Keep session TTL and cookie attributes stable during the guest auth rollout; change only the issuance logic
- **Phase:** Pre-guest-auth — cookie domain fix must ship first

---

## Domain: Data Model Evolution on Live Data

### PITFALL 5: Adding a non-nullable field to a table with existing rows

**What goes wrong:** A new column (`question`, `prompt`, `is_candidate`) is added via AutoMigrate without a DEFAULT. Existing rows get NULL. The Go struct has `not null` or the frontend assumes the field is always present. API responses break for old records. Alternatively, the migration adds a DEFAULT that semantically wrong for existing data.

**Warning signs:**
- AutoMigrate used for schema changes on tables with production data (AutoMigrate adds columns but does not alter or backfill)
- New Go struct fields added without `gorm:"default:..."` or a corresponding SQL migration script
- No backfill step planned for existing rows after adding the column

**Prevention strategy:**
- For every new column on an existing table: write an explicit SQL migration (not just AutoMigrate) with a safe DEFAULT, then a separate backfill query, then (if needed) a NOT NULL constraint
- Compass topics table: add `question` and `prompt` as nullable with `omitempty` in JSON; make them required only after all rows are backfilled
- Treat AutoMigrate as a development convenience only — any column change on a live table needs an explicit migration script
- **Phase:** Data model evolution phase, schema change step

---

### PITFALL 6: Changing the meaning of an existing field breaks client contracts

**What goes wrong:** `shortTitle` on a Compass topic was the quiz card label. The team decides it should now be the question stem. Old frontend code reads `shortTitle` expecting a 2-4 word label; new frontend reads it expecting a full sentence question. Both are in production at the same time during a deploy window. Users see garbled UI.

**Warning signs:**
- Field is repurposed without a new field name or versioned API response
- Frontend and backend deploy simultaneously rather than backend-first
- No API versioning or additive-only field policy

**Prevention strategy:**
- Never change the meaning of an existing field — add a new field instead (`question_text`, `prompt_text`)
- Deprecate the old field with `omitempty` and remove it only after all clients have migrated
- Backend deploys first (new field present but optional), frontend deploys second (reads new field, falls back to old)
- **Phase:** Data model evolution phase, field design step

---

### PITFALL 7: BallotReady candidate data overwrites incumbent data

**What goes wrong:** The BallotReady API returns both officeholders and candidates in certain queries. The upsert logic (which uses `external_id` as the conflict key) treats a candidate record as an update to the sitting politician record, clobbering office title, district, or contact data.

**Warning signs:**
- A single `external_id` appears in both officeholder and candidacy API responses with different field values
- Upsert uses ON CONFLICT DO UPDATE with broad SET clauses that overwrite every column
- No `is_candidate` / `is_officeholder` flags on the politician record to distinguish record types

**Prevention strategy:**
- Treat candidates as a separate data entity: either a separate table (`essentials.candidates`) or a type discriminator column on politicians
- Upsert logic should be additive: candidacy data enriches but does not replace officeholder data
- During BallotReady candidacy fetch, check if the `external_id` already exists as an officeholder before writing
- **Phase:** Candidate data phase, BallotReady integration step

---

### PITFALL 8: ZIP/cache invalidation logic doesn't account for candidates who are not yet officials

**What goes wrong:** The 90-day TTL cache was designed for incumbent data that changes rarely. Candidates appear and drop out on a weeks-long cycle during election season. Stale candidate data (a candidate who dropped out 3 weeks ago is still showing) erodes user trust on a civic platform where accuracy is the core value proposition.

**Warning signs:**
- Candidate data stored in the same cache tables as officeholder data with the same TTL
- No election-cycle-aware refresh logic (candidates should refresh more frequently near election dates)
- Frontend shows "running for office" for a candidate who withdrew

**Prevention strategy:**
- Use a shorter TTL for candidate data (7-14 days vs 90 days) or store separately with its own cache table
- Add an `election_date` field so the system can auto-expire candidate records after the election
- Consider a manual "force refresh" admin endpoint to invalidate candidate data on demand
- **Phase:** Candidate data phase, caching strategy step

---

## Domain: Deterministic Randomization

### PITFALL 9: Seeded randomization that is not reproducible across sessions or servers

**What goes wrong:** Quiz topics are randomized so users see different questions each visit. A seeded PRNG is used. The seed is the current timestamp or a short session ID that differs between page loads. Users who refresh get a completely different quiz, making it impossible to share "I got question set #42" or to A/B test consistently.

**Warning signs:**
- `Math.random()` or `rand.Intn()` used without an explicit seed
- Seed derived from `Date.now()` or a UUID that changes per session
- No way to reconstruct a given randomization from a URL or user ID

**Prevention strategy:**
- Seed the PRNG with a stable per-user value: authenticated user ID (hashed) or a guest session token
- For shareable quiz sets, encode the seed in the URL so the exact question order is reproducible
- Validate: given the same seed + topic pool, the output must be identical across backend restarts and across the Go/JS boundary if both sides randomize
- **Phase:** Compass guest-first phase, quiz randomization step

---

### PITFALL 10: Seeded randomization feels less random than expected (short cycles, clustering)

**What goes wrong:** A simple LCG or modulo seed produces visually non-random distributions when the topic pool is small (10-20 items). Users notice that questions always cluster in the same political categories. The platform looks biased even when it is not.

**Warning signs:**
- Topic pool is small enough that seed collisions produce near-identical sequences
- No shuffle quality check (run 100 seeds, verify even distribution across topic categories)
- Topics not tagged by category, making it impossible to enforce balance in the shuffle

**Prevention strategy:**
- Use Fisher-Yates shuffle with a well-seeded PRNG (e.g., a 64-bit seed derived from user ID + topic set hash)
- Add category-balanced selection: ensure each shuffle draws proportionally from each political topic area
- Run a distribution test during development: generate 1,000 seeded shuffles and verify topic category spread
- **Phase:** Compass randomization phase, algorithm validation step

---

## Domain: Candidate Data Alongside Incumbents

### PITFALL 11: UI conflates candidates with officeholders — no clear distinction

**What goes wrong:** The Essentials app shows a mix of sitting officials and candidates on the same ZIP results page with no visual distinction. Users think a candidate is already in office, or think an incumbent is just running again. In a civic context, this is a misinformation risk.

**Warning signs:**
- Same card component used for both politician types with no badge or label
- `is_candidate` / `is_officeholder` fields exist in the API but are not used in the UI
- No UX review of the candidate card design before launch

**Prevention strategy:**
- Design and enforce a visual distinction at the component level: "Currently in office" vs. "Candidate — [Office] — [Election date]"
- Make the distinction data-driven: derive from `is_appointed`, `is_vacant`, and election record fields already captured from BallotReady
- Add a filter toggle on the Dashboard ("Show officials" / "Show candidates" / "Show both") so users can control the view
- **Phase:** Candidate data phase, frontend integration step

---

### PITFALL 12: Missing or inconsistent race/election context on candidate records

**What goes wrong:** BallotReady returns candidate data tied to a specific race. The backend stores the candidate but loses the race context (which office, which election date, which district). Downstream, it is impossible to answer "Who is running for City Council in my district?" because the race is not linked.

**Warning signs:**
- `ElectionRecord` stored but not joined to the politician in API responses
- Frontend queries politicians by ZIP and gets candidates back with no office/race context
- District on a candidate record is NULL because the district hasn't been won yet (it is a future position)

**Prevention strategy:**
- Store race context on the candidacy record: target office title, district, election date, race ID from BallotReady
- API responses for candidates must always include race context (do not rely on the politician's current office, which may not exist yet)
- During fetch, if a candidate has no existing district record, create a pending/prospective district entry rather than leaving it null
- **Phase:** Candidate data phase, data model design step

---

## Domain: Multi-App Consolidation

### PITFALL 13: Shared component library version skew causes silent visual regressions

**What goes wrong:** `ev-ui` (`@chrisandrewsedu/ev-ui`) is updated for the consolidated app. Compass and Essentials pull the new version. `RadarChartCore` behaves differently with the new prop interface. One app gets the fix, the other does not, or both break in different ways. Because there is no visual regression test, the breakage only appears in production.

**Warning signs:**
- `ev-ui` version pinned differently across Compass, Essentials, and the consolidated app
- No Storybook or isolated component test for `RadarChartCore`
- Prop interface changes made without a deprecation period

**Prevention strategy:**
- Pin `ev-ui` to an exact version in every consumer app's `package.json` (not `^` or `~`)
- Before bumping the version in any consumer, test the component in isolation with the new version
- For breaking prop interface changes, bump the major version and provide a migration guide in the changelog
- **Phase:** Consolidation phase, shared library audit step

---

### PITFALL 14: Route namespace collisions when combining apps under one domain

**What goes wrong:** Compass uses `/quiz`, `/compass`, `/library`. Essentials uses `/dashboard`, `/profile/:id`. When consolidated, both route to a shared router. If the consolidated app reuses component names (e.g., `Dashboard` from both apps), the wrong component renders or imports break.

**Warning signs:**
- Both apps have a component named `Dashboard`, `Profile`, or `Layout`
- No agreed-upon URL namespace before consolidation begins (e.g., `/compass/*` vs `/essentials/*`)
- React Router config is copy-pasted from both apps into one without conflict check

**Prevention strategy:**
- Before consolidating, audit all routes in every app and define a canonical URL map for the consolidated app
- Rename conflicting components at the source level before merging (e.g., `CompassDashboard`, `EssentialsDashboard`)
- Use React Router's nested route layout pattern to scope each sub-app under its own prefix
- **Phase:** Consolidation phase, route design step (must be done before any code merge)

---

### PITFALL 15: Four separate Netlify deployments means four separate auth cookie scopes

**What goes wrong:** Compass at `compass.empowered.vote` sets a session cookie for `.empowered.vote`. The user navigates to `essentials.empowered.vote`. The cookie is present but CORS or SameSite policy on the API blocks the credentials. The user appears logged out. Alternatively, after consolidation to one domain, the old subdomains 404 and existing links from social/email break.

**Warning signs:**
- Each app has `credentials: "include"` but no test that verifies the cookie is sent cross-subdomain
- API CORS allow-list does not include all four frontend origins
- No redirect plan for old subdomain URLs post-consolidation

**Prevention strategy:**
- Resolve cookie domain to `.empowered.vote` (already noted in CLAUDE.md) before any cross-app auth is needed
- Update CORS allow-list in `internal/middleware/middleware.go` every time a new subdomain is added or consolidated
- When consolidating, add Netlify redirects from old subdomain URLs to the new consolidated paths; keep old subdomains alive for 60+ days
- **Phase:** Pre-consolidation — cookie domain fix and CORS audit are blockers

---

### PITFALL 16: NPM_TOKEN for GitHub registry breaks during consolidation

**What goes wrong:** The consolidated app merges the `package.json` from Compass and Essentials. The `.npmrc` from one app is used, which contains the GitHub registry config. But the other app's `.npmrc` is dropped. Netlify CI fails because it cannot pull `@chrisandrewsedu/ev-ui` without `NPM_TOKEN`.

**Warning signs:**
- `.npmrc` is not committed in the consolidated app root (or committed without the `//npm.pkg.github.com/` line)
- `NPM_TOKEN` env var not set in the new Netlify site's environment settings
- Local installs work (because `~/.npmrc` has the token) but CI fails silently

**Prevention strategy:**
- The consolidated app's `.npmrc` must include `//npm.pkg.github.com/:_authToken=${NPM_TOKEN}` (per MEMORY.md)
- Verify `NPM_TOKEN` is configured in Netlify environment settings for the consolidated site during site setup
- Add a CI check step that validates the package can be installed before running the build
- **Phase:** Consolidation phase, CI/CD setup step

---

## Domain: Government/Civic Image Management

### PITFALL 17: Government building images have inconsistent aspect ratios across contexts

**What goes wrong:** A government building image is used as a hero banner on a politician profile (wide, 16:9), as a card thumbnail in search results (square, 1:1), and as a background in a quiz card (variable). The same image URL is used in all contexts. Some displays are stretched, cropped incorrectly, or too small to be recognizable.

**Warning signs:**
- Image `<img>` elements without explicit `object-fit` and `object-position` CSS
- Only one image size/URL stored in the database per building (no thumbnail variants)
- Building images sourced from Wikipedia Commons or similar with unpredictable dimensions

**Prevention strategy:**
- Store at minimum two variants per image: original (for hero/banner) and thumbnail (for cards)
- Use CSS `object-fit: cover` universally for building images in card contexts
- Define a canonical aspect ratio per usage context (profile hero: 3:1, card thumbnail: 1:1) and enforce at the component level
- **Phase:** Candidate/profile data phase, image component design step

---

### PITFALL 18: BallotReady politician images expire or return 404 after a period

**What goes wrong:** BallotReady provides CDN image URLs for politician headshots. These URLs are stored in `essentials.politician_images`. After 6-12 months, BallotReady rotates CDN keys or changes the URL structure. All stored image URLs 404. The platform shows broken images for every politician.

**Warning signs:**
- Image URLs stored verbatim with no expiry tracking
- No fallback image or graceful degradation in the frontend when `<img>` fails to load
- No periodic health check on stored image URLs

**Prevention strategy:**
- Always implement an `onError` fallback on every politician image (`<img onError={...}>`): show initials avatar or a generic silhouette
- Track `image_fetched_at` timestamp alongside the URL; re-fetch from BallotReady during the 90-day cache refresh cycle
- Consider proxying images through the backend or re-uploading to Supabase Storage to own the CDN lifecycle
- **Phase:** Image handling phase; fallback is a day-one requirement, proxy is a later optimization

---

## Domain: Small Team / Nonprofit Constraints

### PITFALL 19: Demo-readiness and production-readiness treated as the same thing

**What goes wrong:** The team scrambles to make features demo-ready (hardcoded data, disabled error handling, skipped edge cases). These demo shortcuts ship to production because there is no clear line between the two environments. Live users encounter demo-quality code.

**Warning signs:**
- "Demo" data or flags hardcoded in shared environment config
- Features flagged as "demo-only" with a TODO comment but no tracking issue
- Production deploy pipeline is the same as the demo pipeline

**Prevention strategy:**
- Maintain a dedicated demo Netlify site (or deploy preview) that is not the production URL
- Use Vite environment variables (`VITE_DEMO_MODE=true`) to enable demo shortcuts, and ensure these are never set on the production Netlify site
- Create a "demo debt" tracking label in GitHub Issues; review before each production deploy
- **Phase:** All phases — establish this discipline before the first milestone ships

---

### PITFALL 20: 2-3 person team accumulates too many open state changes across apps

**What goes wrong:** Work begins on guest auth in Compass at the same time as consolidation planning and candidate data integration. Each stream makes changes to shared files (`internal/essentials/`, `ev-ui`, shared auth middleware). Merge conflicts multiply. The team spends more time on merge resolution than on features.

**Warning signs:**
- More than one active branch touching the same Go package or React component at once
- No agreed-upon branch strategy (feature branches vs trunk-based development)
- PRs sit open for more than 2-3 days because reviewers are working on conflicting branches

**Prevention strategy:**
- Sequence milestones so that shared dependencies (auth, data model) are completed and merged before dependent features begin
- Use trunk-based development with short-lived feature flags rather than long-lived feature branches
- Treat `ev-ui` and `internal/auth/` as shared infrastructure: changes require explicit team sign-off before merge
- **Phase:** Project planning level — enforce before milestone 1 begins

---

## Summary Table

| # | Pitfall | Phase |
|---|---------|-------|
| 1 | Guest→auth state merge never happens | Guest auth phase |
| 2 | Guest has no persistent identity | Guest auth phase |
| 3 | Wrong API endpoints exposed/protected for guests | Guest auth phase |
| 4 | Existing sessions broken during auth model change | Pre-guest-auth (cookie fix first) |
| 5 | Non-nullable column added without backfill | Data model evolution phase |
| 6 | Field meaning changes break client contracts | Data model evolution phase |
| 7 | Candidate upsert overwrites incumbent data | Candidate data phase |
| 8 | Candidate cache TTL too long for election cycle | Candidate data phase |
| 9 | Seeded randomization not reproducible | Compass randomization phase |
| 10 | Seeded shuffle produces biased distributions | Compass randomization phase |
| 11 | UI conflates candidates with officeholders | Candidate data — frontend phase |
| 12 | Candidate records missing race/election context | Candidate data — data model phase |
| 13 | ev-ui version skew causes visual regressions | Consolidation phase |
| 14 | Route namespace collisions when merging apps | Consolidation phase |
| 15 | Cookie scope breaks cross-subdomain auth | Pre-consolidation (cookie fix blocker) |
| 16 | NPM_TOKEN missing in consolidated Netlify site | Consolidation phase — CI/CD setup |
| 17 | Building images wrong aspect ratio across contexts | Profile/image component phase |
| 18 | BallotReady image URLs expire and 404 | Image handling phase |
| 19 | Demo shortcuts ship to production | All phases |
| 20 | Parallel streams cause unmanageable merge conflicts | Project planning level |
