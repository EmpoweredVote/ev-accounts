# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.7 — LA County Data Enrichment

**Shipped:** 2026-02-26
**Phases:** 6 | **Plans:** 15 executed (1 deferred)

### What Was Built
- Headshot pipeline for LA County city councils (1,247-line scraper with 5-strategy extraction, 84 photos in Supabase CDN)
- High-value headshots for 20 LA County/City officials from Wikipedia Commons
- 11 city hall building photos from Wikimedia Commons
- Contact enrichment: 381 records with API endpoint and frontend section
- Term date precision formatting with UTC-safe year display
- Coverage validation script

### What Worked
- Schema-first approach (Phase 39), high-value officials first (Phase 40), config-driven pipeline
- Out-of-order phase execution: Phases 43/44 completed while Phase 42 manual curation deferred

### What Was Inefficient
- 80% headshot target unrealistic for automated scraping (~55 cities use Cloudflare WAF)
- Wikipedia strategy false positives, broken override URLs, REQUIREMENTS.md accuracy drift

### Key Lessons
1. Set realistic automation ceilings early — research anti-bot protections before setting targets
2. Manual curation is a valid engineering output — building tooling for efficient manual work
3. Deferred plans are acceptable when pipeline infrastructure is complete

---

## Milestone: v1.8 — Compass Data & Politician Research

**Shipped:** 2026-02-27
**Phases:** 6 | **Plans:** 28

### What Was Built
- Stance research CSV: 455 sourced data rows across 23 politicians on 21 compass topics
- Quote collection: 61 verbatim sourced quotes from 11 politicians
- Go CLI import subcommands with CSV parsing and upsert logic
- GET /essentials/quotes API with LATERAL JOIN; Read & Rank frontend integration
- Legacy cleanup: 2,584 lines removed; source URL integrity: 700+ fabricated URLs cleared

### What Worked
- CSV-first research pipeline, strict URL verification as separate plans, omit-rather-than-fabricate rule

### What Was Inefficient
- Phase 47 plan explosion (12 plans); Phase 49 quote attrition (179→61 rows)

### Key Lessons
1. AI-generated source URLs need systematic verification — 700+ fabricated URLs caught
2. Verbatim quote collection requires extractable sources — generic index pages don't contain quotes
3. Research milestones generate more plans than code milestones

---

## Milestone: v1.9 — Compare UX & Search Fixes

**Shipped:** 2026-02-28
**Phases:** 3 | **Plans:** 6

### What Was Built
- Inline politician picker on compare page with keyboard nav, search, clear, browse-all
- Level/state filters reused across both picker surfaces via shared hook
- ST_Intersects area-boundary search for city/ZIP/county queries
- Unified single search path (removed ZIP vs address branching)
- searchKey counter pattern fixing re-search-from-results bug
- Area label display on results page

### What Worked
- Shared hook pattern enabled zero code duplication across two picker surfaces
- Module-level cache avoided Provider wrapping; "keep old data visible" pattern for smooth morph
- Small focused milestone (3 phases, 6 plans) completed in 2 days with zero deviations

### What Was Inefficient
- "My reps" surfacing listed as target but deferred — should have been scoped out during requirements

### Key Lessons
1. Shared hooks + presentational components = maximum reuse
2. Conservative defaults for civic search (area over point) serve users better
3. Deprecation over deletion prevents build breakage in multi-consumer codebases

---

## Milestone: v2026.3 — Legislative Profile Data

**Shipped:** 2026-03-05
**Phases:** 6 | **Plans:** 19

### What Was Built
- 8-table legislative data model with cross-reference bridge (bioguide, legiscan, openstates IDs)
- Federal import pipeline: Go CLI for committees/leadership (YAML), bills/votes (Congress.gov + LegiScan)
- State import pipeline: Python scripts for IN (2,424 bills, 15,223 votes) and CA (5,310 bills, 105,151 votes)
- Local data pipeline: Bloomington (OnBoard scraping) and LA County (Legistar OData) with feasibility gating
- 5 legislative API endpoints with session filtering and significance defaults
- ev-ui components (LegislativeInlineSummary, LegislativeRecord) with profile integration

### What Worked
- Schema-first approach (Phase 54) before any import code — bridge table pattern prevented orphaned data
- Feasibility check gating (Phase 58) — confirmed local vote attribution infeasible before building scrapers, saving wasted effort
- Multi-language pipeline — Go CLI for federal (API client reuse), Python for state/local (faster iteration with psycopg2 direct inserts)
- Single-match-only guard pattern across all name matching — prevented bad data from ambiguous matches

### What Was Inefficient
- LegiScan getSessionPeople committee_id=0 discovery required fallback to Open States (Phase 57-03 added mid-milestone)
- Federal import CLIs built but not run on active database — gap discovered during Phase 59 frontend testing
- LA County legislation attribution turned out to be <5% — Legistar data quality lower than expected

### Patterns Established
- Bridge table before any import — bioguide/legiscan/openstates cross-reference enables multi-source data merging
- Feasibility check scripts before building scrapers — probes with live curl tests + name matching validation
- Python for data pipelines, Go for API clients — play to each language's strengths
- Atomic rename for persistent counters (LegiScan monthly budget tracker)
- Raw SQL JOINs for 3+ table queries instead of GORM chains

### Key Lessons
1. Always validate API data structure with live probes before building parsers — LegiScan getMasterList is a map not array, getSessionPeople has no committee data
2. Congress.gov pagination uses `len(items) < limit` as stop condition — never trust round numbers
3. State committee data is not available from bill-focused APIs — needed separate committee-focused API (IGA/Open States)
4. Local government data availability varies dramatically — feasibility-gate before committing to scrapers
5. Frontend should test with real data early — empty states for untested data sources discovered late

---

## Milestone: v2026.4 — State Data Completion & Image Coverage

**Shipped:** 2026-03-06
**Phases:** 7 | **Plans:** 21

### What Was Built
- IN/CA committee imports via IGA direct API and Open States with automated coverage validation
- State legislative data verification (audit scripts for bills, votes, committee membership coverage)
- Documented new-session playbook with state_legislative_config.json as shared config
- 304 politician headshot research (100% of manifest), 180 uploaded to Supabase CDN (503 total)
- Compass page refresh persistence — calibration, quiz, and resume-mode survive F5
- Coach mark hint system — reusable CoachMark component with SVG mask spotlight, 3 guided tours, contextual hints
- Welcome screen simplified, write-in awareness hint added

### What Worked
- Two-track parallelism: state data (60-62) and headshot research (63) ran independently, maximizing throughput
- Wayback Machine as systematic fallback for Cloudflare/CivicPlus-blocked government sites — 80% headshot hit rate
- state_legislative_config.json pattern — single config file updates for new legislative sessions instead of editing multiple scripts
- CoachMark component design — SVG mask spotlight + portal rendering enabled clean separation from host components
- Quick bug fix phases (65-66) added mid-milestone without disrupting data work

### What Was Inefficient
- 8 headshot research plans (63-01 through 63-08) — high plan count for what is essentially repetitive batch work
- 66 headshots failed upload due to same systematic 403 blocks discovered in research phase — could have been pre-filtered
- Population coverage only 66.8% vs 80% target — CDN health (100%) used as pass gate instead

### Patterns Established
- Wayback Machine (`web.archive.org/web/*/`) as standard fallback for government sites with WAF protection
- Research manifest CSV pattern with politician_id UUIDs enables direct upsert without fuzzy matching
- localStorage persistence pattern for multi-step flows (calibration_progress, quiz_progress keys)
- CoachMark with useCoachMark hook + storageKey pattern for persistent dismiss across sessions

### Key Lessons
1. Batch research plans should be consolidated — 8 plans of identical structure could have been 3-4 larger batches
2. Upload pipeline should pre-filter known-blocked URLs from dry-run failures to avoid wasted upload attempts
3. Coverage targets should distinguish health (URL accessibility) from population (has-photo-at-all) — different metrics for different gates
4. Page refresh bugs compound — fixing one flow (calibration) often reveals the same pattern needed elsewhere (quiz, resume-mode)
5. Coach mark tours need user testing — post-cal tour reduced from 4 to 3 steps after testing showed help button spotlight was awkward

---

## Milestone: v2026.3.2 — Compass on Profiles

**Shipped:** 2026-03-08
**Phases:** 5 | **Plans:** 8

### What Was Built
- Cross-app compass API integration with cookie domain fix and CompassContext provider
- Guest compass data bridge via URL fragment encoding (CompassV2 → Essentials cross-origin)
- CompassCard on politician profiles: dual-overlay radar chart + stance breakdown accordion
- CompassPreview mini radar popover on dashboard politician cards with CTA mode
- StanceAccordion with lazy context fetching, CSS grid-template-rows animation, favicon source links

### What Worked
- Self-gating component pattern — CompassCard returns null internally when politician lacks stances, keeping parent clean
- Boot priority chain (fragment > API > localStorage > CTA) — handles all user states elegantly with one code path
- Fragment bridge solved cross-origin guest data without any backend changes — pure client-side solution
- ev-ui RadarChartCore reuse — dual-overlay worked out-of-the-box, no new charting code needed
- useRef Map for context caching — avoids React re-renders while persisting fetched data across accordion opens

### What Was Inefficient
- Phase 72 stub added to roadmap during milestone but never planned or executed — created confusion at milestone completion
- Cookie domain fix could have been a single config change but required careful PORT-based branching for local dev compatibility

### Patterns Established
- URL fragment bridge for cross-origin data transfer between same-domain apps (BASE64 encoding, synchronous parsing before async)
- Self-gating component pattern — child decides rendering, parent passes props unconditionally
- CSS grid-template-rows (0fr/1fr) for smooth accordion animation without overflow hacks
- ReturnBanner with sessionStorage for round-trip cross-app navigation persistence

### Key Lessons
1. Cross-origin data sharing between same-domain apps is solvable client-side — URL fragments + localStorage cache avoid backend complexity
2. Don't add future phase stubs to roadmap during active milestone — creates tracking confusion
3. Intersection-only filtering (both user AND politician must have answers) is the right default for comparison UX
4. createPortal for popovers in scrollable panels prevents overflow:hidden clipping without CSS hacks

---

## Milestone: v2026.3.3 — Local Government Organization

**Shipped:** 2026-03-11
**Phases:** 5 | **Plans:** 6

### What Was Built
- GovernmentBody table with composite unique index and LEFT JOIN enrichment in both fetch functions
- classify.js commission keyword fix routing Monroe County Commissioners to County Legislators group
- 14 government_bodies seed rows for Monroe County and Bloomington with official website URLs
- ev-ui 0.1.41 with optional websiteUrl prop on CategorySection (external link icon in headers)
- splitByBodyName helper in Results.jsx for body-specific section headings with generic fallback

### What Worked
- DB audit first (Phase 72) — confirmed chamber_name_formal was empty, commission misclassification, and geo_id presence before writing any code; prevented incorrect assumptions from driving design
- Parallel execution of Phase 75 (ev-ui prop) alongside Phases 73-74 (backend) — independent work streams completed concurrently
- Small, focused milestone (5 phases, 6 plans, 2 days) with zero scope creep
- FIPS state code bug caught during Phase 74 execution and fixed immediately (commit b0a7f94) — Phase 76 Playwright tests confirmed the fix

### What Was Inefficient
- Phase 73 had to become a data migration phase (populating chamber_name_formal) before the feature phase — could have been anticipated if DB audit was part of milestone planning
- SearchPoliticians endpoint in geofence_lookup.go lacked the government_bodies LEFT JOIN that FindPoliticiansByGeoMatches already had — caught as a deviation during Phase 76

### Patterns Established
- DB audit phase before data-dependent features — confirm actual data state before writing classification/display code
- GovernmentBody enrichment follows PositionDescription pattern — composite unique index, COALESCE LEFT JOIN, omitempty JSON fields
- splitByBodyName: render-time sub-grouping pattern for heterogeneous lists with named/unnamed fallback buckets
- ON CONFLICT DO NOTHING for seed data — preserves manually-corrected production values on server restart
- geo_id fan-out: multi-district bodies require one row per distinct geo_id for JOIN resolution

### Key Lessons
1. Always audit live data before building features on assumed data shapes — chamber_name_formal was completely empty
2. classify.js consumer structures (LOCAL_ORDER, CATEGORY_DISPLAY_NAMES, GROUP_SORT_OPTIONS) must update atomically — partial updates cause silent rendering bugs
3. FIPS codes vs ISO abbreviations for state columns are a recurring data integration trap — document the format in schema comments
4. When two fetch functions serve the same model, both need the same JOINs — grep for all consumers when adding enrichment
5. government_body_name should be used directly as section title, never routed through qualifyLocalTitle() — prevents double-prefix bugs

### Cost Observations
- Model mix: ~80% sonnet, ~20% opus (research/planning)
- Sessions: 5 (one per phase)
- Notable: Smallest milestone to date in plan count (6) but high data-correctness rigor due to DB audit gating

---

## Milestone: v2026.3.4 — Read & Rank Integration

**Shipped:** 2026-03-12
**Phases:** 6 | **Plans:** 13

### What Was Built
- Read & Rank extracted from EV-prototypes monorepo to standalone `readrank.empowered.vote` on Cloudflare Pages
- EV brand design applied throughout (white card, amber/cyan verdict badges, ev-muted-blue accents)
- Backend `compass.quote_verdicts` table with bulk-upsert POST/GET endpoints
- ev-ui v0.1.43 with StanceAccordion `verdictsByQuote` prop and lazy quote fetch cache
- Verdict fragment bridge for guests (URL encoding + localStorage cache) and server-side sync for logged-in users

### What Worked
- Parallel phase design (Phases 78, 79, 80 ran independently) maximized throughput on a cross-app milestone
- URL fragment bridge pattern from v2026.3.2 reused as foundation — verdict encoding was an extension, not a rewrite
- ev-ui inline styles (no Tailwind coupling) kept the library portable across all three consuming apps
- `quotesCache useRef(null)` pattern — null vs empty array distinguishes unfetched from fetched-but-empty cleanly
- Fire-and-forget verdict POST with `useRef(false)` sync guard — triggered exactly once per session

### What Was Inefficient
- Phase 77 plans split extraction (77-01) from deployment (77-02) — a single-repo migration with minor config changes could have been one plan
- Some PLAN.md checkboxes left unchecked despite SUMMARY.md confirming completion — minor doc inconsistency

### Patterns Established
- Cloudflare Pages SPA routing: `public/_redirects` with `/* /index.html 200`
- Local ev-ui dev alias: `fs.existsSync` check against `../ev-ui/dist` in vite.config.ts
- Zustand persist versioning: `version + migrate passthrough` for storage key renames without data loss
- `apiUrl` prop pattern: library components receive API base URL via prop (not `import.meta.env`)
- Verdict priority chain: API > URL fragment > localStorage in CompassContext
- `parseCompassFragment` null guard: `answers !== null` check prevents crash on verdict-only fragments

### Key Lessons
1. Cross-app integration works cleanest with clear ownership boundaries — Read & Rank encodes, Essentials decodes; no shared state infrastructure needed
2. Inline styles in component libraries avoid Tailwind coupling — consumers provide the runtime; library provides the structure
3. URL fragment bridge is sufficient for MVP guest cross-app state — shared domain localStorage adds complexity without clear user benefit at this scale
4. Cloudflare auto-provisions DNS instantly for domains already on the account
5. `useRef(false)` sync guard prevents double-POSTs on React strict mode double-invoke

### Cost Observations
- Model mix: ~75% sonnet, ~25% opus
- Sessions: ~6 (one per phase + planning)
- Notable: Multi-repo milestone (5 active repos) completed in 2 days via parallel phase design

---

## Milestone: v2026.3.5 — Unified Navigation Header

**Shipped:** 2026-03-13
**Phases:** 3 | **Plans:** 5

### What Was Built
- ev-ui v0.1.49 with SiteHeader defaultNavItems updated to production .empowered.vote URLs
- Essentials Layout.jsx wrapping all 5 pages with auth-aware SiteHeader (username/logout/sign-in)
- ReadRank useAuthState hook extended with userName/logout, profileMenu wired into SiteHeader
- Floating AuthIndicator removed from Essentials
- returnTo redirect flow for cross-app login (Essentials/ReadRank → Compass login → return)

### What Worked
- Sequential dependency chain (83 → 84/85) executed cleanly — ev-ui published first, then both consumers in parallel
- Existing auth infrastructure in Essentials (CompassContext isLoggedIn/userName) meant Phase 84 was mostly wiring, not new auth plumbing
- profileMenu prop pattern from ev-ui SiteHeader handled both logged-in and logged-out states cleanly
- Vite proxy discovered during Phase 85 human verification solved local dev cross-origin cookie issue

### What Was Inefficient
- ev-ui lacks .d.ts files — TypeScript consumers (ReadRank) need spread cast workaround, creating type safety gap
- AuthIndicator.jsx left as orphaned dead code — should have been deleted in same PR

### Patterns Established
- Layout wrapper pattern for header integration — single Layout component wraps all pages, receives auth state from context
- profileMenu undefined during loading prevents "Sign in" flash for logged-in users
- Vite proxy for `/auth/*` routes in local dev — solves cross-origin cookie issues without CORS changes

### Key Lessons
1. Auth-aware headers are pure UI wiring when auth context already exists — this milestone was fast because the hard auth work was done in v2026.3.2
2. Human verification catches real bugs — returnTo URL and cross-origin cookie issues found during Phase 85 manual testing
3. TypeScript consumers of JS libraries need type stubs maintained alongside the library — deferred .d.ts generation creates ongoing friction

### Cost Observations
- Model mix: ~70% sonnet, ~30% opus
- Sessions: 3 (one per phase)
- Notable: Fastest milestone execution (1 day) — small scope with clear dependency chain

---

## Milestone: v2026.3.6 — Read & Rank Redesign

**Shipped:** 2026-03-16
**Phases:** 7 | **Plans:** 15

### What Was Built
- Unified evaluate+rank flow with head-to-head matchup comparisons replacing drag-to-rank
- Pizza-topping practice round with emoji character avatars for first-time onboarding
- 2-step coach mark spotlight tour on first real issue (swipe area + rank panel)
- Google Maps Places location-based filtering with Essentials cross-app ?address= context
- Results page redesign with MegaParticles, simplified cards, View on Essentials primary CTA
- Full Fraunces removal + Manrope typography throughout + AnimatePresence page transitions
- Chrome cleanup: 5 dead components deleted, Zustand store migrated through versions 2-7

### What Worked
- Zustand store versioning discipline — clean-reset migration at each store version bump (2→7) prevented localStorage corruption for returning users
- Practice state isolation — practiceProgress at top-level store (not inside issueProgress) guaranteed zero contamination of real verdict POST payloads
- Phase 87.1 urgent insertion mid-milestone worked seamlessly — head-to-head matchups replaced drag-to-rank without disrupting downstream phases
- Human checkpoint verification caught real UX issues: hub quote mark removal, results card redesign, practice splash value prop — all addressed in-phase
- Client-side location filtering avoided backend changes entirely — POST /essentials/politicians/search + client filter was sufficient at ~61 quote scale
- prefers-reduced-motion handled at render level (not just CSS) — MegaParticles component not mounted at all when reduced motion preferred

### What Was Inefficient
- REQUIREMENTS.md checkboxes for RSLT-01/02/03 not updated despite being implemented — discovered during milestone completion
- Zustand store version bumped 6 times across the milestone (v2→v7) — could consolidate if phases were planned as a single atomic migration
- Phase 91 had 3 plans when 2 would have sufficed — Fraunces removal was a small cleanup that didn't warrant its own plan

### Patterns Established
- Head-to-head matchup pattern: pairwise comparison → win counts → derived ranking (no manual drag)
- completedMatchupPairs as string[] not Set — Zustand/localStorage cannot serialize Set objects
- Practice isolation pattern: practiceProgress at top-level store, practiceActions read from practiceProgress directly (not getCurrentIssueProgress)
- effectiveQuotesToEvaluate derived at render time — store mutation avoided so clearing filter restores full quote set
- MegaParticles inlined per-component with CSS custom props (--dx/--dy) for burst direction
- CoachMark with allowSpotlightInteraction for interactive spotlights (user can swipe through the highlight)
- AnimatePresence mode='wait' with key={phase} for clean phase-switch transitions

### Key Lessons
1. Urgent phase insertions (87.1) work well when dependencies are clean — matchup flow replaced drag-to-rank without ripple effects because store actions were additive, not destructive
2. Human checkpoints are most valuable on visual redesign phases — AI-generated layouts need user judgment on information density and visual hierarchy
3. Store version migrations should use hardcoded initial state (not transform) — guarantees clean slate regardless of source version
4. Pairwise comparison is a superior ranking UX for <10 items — users make confident binary choices; explicit ranking is cognitively harder
5. Client-side filtering is the right default when data scale is small — avoids backend coupling for what is essentially a view filter
6. useCallback dependency arrays must include tour state — stale closures silently skip tour advancement on button press

### Cost Observations
- Model mix: ~70% sonnet, ~30% opus
- Sessions: ~8 (planning + one per phase + completion)
- Notable: 7 phases in 3 days — fastest per-phase velocity; urgent 87.1 insertion handled cleanly

---

## Milestone: v2026.3.8 — Essentials Election Central

**Shipped:** 2026-03-31
**Phases:** 5 | **Plans:** 12

### What Was Built
- Election schema (elections, races, race_candidates) with antipartisan enforcement at schema layer
- Election data import CLI for Indiana SoS Excel + LA County HTML incumbent scraper (2 elections, 12 races, 18 candidates)
- Election Central page with tier-grouped races, candidate cards, primary ballot labels, days-until countdown
- Elected/Appointed filter with retention judge dual-appearance in both views
- Candidate profile pages with incumbent/challenger branching — incumbents get full CompassCard, challengers get clean minimal view

### What Worked
- Schema-first approach (Phase 97) with data audit before any import code — is_appointed audit revealed 97.6% NULL-classified offices were BallotReady campaign finance records, not real data gaps
- Separate race_candidates table (not co-located with politicians) prevented geofence searches from returning candidates — clean architectural decision
- Two-part election query (geofence-matched + statewide fallback) handled the reality that imported races lack office_id linkage
- Self-gating CandidateProfile with incumbent/challenger branching — challengers skip legislative API calls entirely, no empty loading states
- Primary ballot labels as antipartisan exception — pragmatic decision since voters must choose a party ballot

### What Was Inefficient
- REQUIREMENTS.md checkboxes drifted from actual status throughout the milestone (DATA-02/03/04, FILT-03 all implemented but unchecked)
- 101-02-SUMMARY.md overclaimed PROF-04/PROF-05 as completed when they were deferred — summary frontmatter accuracy needs improvement
- All imported races have office_id=NULL meaning geofence-precision matching (query Part A) is inactive — manual office linking needed for full precision
- CandidateProfile.jsx formatElectionDateFull timezone bug (new Date without T12:00:00 anchor) shipped — minor but known

### Patterns Established
- race_candidates as separate table from politicians — prevents candidate/official mixing in geofence searches
- Two-part election query: Part A (office_id linked, geofence-precision) + Part B (statewide fallback by state code)
- inferDistrictType parsing position_name when office_id not yet linked — graceful degradation for unlinked data
- ev:fromView sessionStorage pattern for tab-aware back navigation between Elections/Representatives views
- SegmentedControl with resolveIsAppointed priority chain: politician.is_appointed > !is_elected — individual override beats position default

### Key Lessons
1. Data audit phases continue to pay off — 97.6% of "missing" is_appointed data turned out to be BallotReady campaign finance noise, not real gaps
2. Antipartisan enforcement at schema + ingestion layers (not just UI) prevents data leakage from upstream APIs that include party affiliation
3. Two-pass politician matching (exact name → fuzzy match with threshold) is the right pattern for election imports where canonical IDs don't exist
4. Deferred data imports (PROF-04/05) are acceptable when architectural wiring is complete — self-gating components render correctly with empty data
5. Indiana SoS Excel column names differ from documentation — always probe real files before building parsers

### Cost Observations
- Model mix: ~70% sonnet, ~30% opus (research/planning)
- Sessions: ~6
- Notable: 5 phases in 3 days — consistent with v2026.3.7 velocity

---

## Milestone: v2026.4.1 — Essentials Visual Polish & Election Improvements

**Shipped:** 2026-04-04
**Phases:** 5 | **Plans:** 11

### What Was Built
- ev-ui icon system (BallotIcon/CompassIcon/BranchIcon SVGs) with tierColors teal-scale token and face-centered imageFocalPoint
- Icon overlay component with @floating-ui/react tooltips on politician cards (ballot status, compass availability, branch type)
- Landing page with coverage area cards (Monroe County IN, LA County CA) and shortcut navigation buttons
- Election page restructured with position-first grouping and antipartisan party sub-labels
- Compass-first card prototype at /prototype with 3 layout variants (A/B/C) and mock dual-overlay radar
- Headshot audit TypeScript CLI scanning 645 CDN images with CSV output
- Edge-to-edge tier background bands (Federal=#FFFFFF, State=#F7FBFC, Local=#EDF6F8) with branch-specific icons
- Incumbent badge removal and Ruben Marte data fix (migration 049)
- Phase 105-106 gap closure: SUMMARY frontmatter backfill, seed SQL verification, tier hue + branch icon implementation

### What Worked
- Single-day milestone execution (all 5 phases on 2026-04-04) — tight scope with clear dependencies
- Inline SVG in ev-ui avoided external icon library dependency (tsup splitting:false blast radius)
- Milestone audit before completion caught DATA-02 partial requirement and frontmatter gaps — Phase 105/106 closed them cleanly
- IconOverlay with @floating-ui/react hooks (useHover, useFocus, useDismiss) provided accessible tooltips without custom positioning code
- COVERAGE_AREAS constant pattern for landing page — addresses hardcoded for covered areas only
- Phase 106 user feedback during checkpoint reversed tier color direction (federal=white, local=most-tinted) — interactive verification caught wrong assumption

### What Was Inefficient
- Original audit status was "tech_debt" with 12 items — many were human visual checks that couldn't be closed programmatically
- Phase 103 plan count (4 plans) could have been 3 — headshot audit script was small enough to bundle with another plan
- tierColors evolved through multiple ev-ui version bumps (0.1.55 → 0.1.60) due to iterative visual tuning during Phase 106

### Patterns Established
- tierColors token in ev-ui with bg/text/accent per tier — consumers import and apply via inline styles
- BranchIcon switch/case pattern — branch prop selects SVG path, default returns landmark fallback
- IconWithTooltip pattern — extraProps spread onto IconComponent, tooltip text derived from branch name
- Edge-to-edge tier bands: negative margin + padding (`-mx-4 md:-mx-8 px-4 md:px-8`) for full-bleed backgrounds
- Gap closure phases (105/106) as explicit roadmap entries — audit findings become planned work, not ad-hoc fixes
- VARIANT_CONFIG lookup object exported from CompassFirstCard for consumer grid layout access

### Key Lessons
1. Gap closure phases after audit formalize tech debt into tracked work — prevents drift between "known issues" and "actually fixed"
2. Inline SVG icons in a bundled library (tsup splitting:false) are safer than importing icon libraries that may tree-shake differently per consumer
3. Tier color direction matters — users expect "more important = whiter/cleaner" (federal=white), not "more local = lighter" — always checkpoint visual hierarchy assumptions
4. Compass-first card prototype with mock data validates layout without requiring real stance data — unblocks UX evaluation from data availability
5. Single-day milestones work when prior milestones established stable patterns — icon overlay, tier colors, and ComponentCard all built on v2026.3.8 foundations

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.7 | 6 | 15 | First milestone with Python scraping pipeline; manual curation accepted |
| v1.8 | 6 | 28 | First research-heavy milestone; URL verification as separate plans |
| v1.9 | 3 | 6 | Smallest milestone yet — tight scope, 100% plan adherence |
| v2026.3 | 6 | 19 | First multi-language pipeline milestone (Go + Python); feasibility gating pattern established |
| v2026.4 | 7 | 21 | Mixed data + UX milestone; Wayback Machine fallback; coach mark pattern established |
| v2026.3.2 | 5 | 8 | First cross-app integration milestone; URL fragment bridge pattern; self-gating components |
| v2026.3.3 | 5 | 6 | DB audit gating pattern; government_bodies enrichment; smallest plan count milestone |
| v2026.3.4 | 6 | 13 | First multi-repo cross-app milestone; parallel phase design; verdict fragment bridge pattern |
| v2026.3.5 | 3 | 5 | Fastest milestone (1 day); auth-aware header wiring across 3 apps; Layout wrapper pattern |
| v2026.3.6 | 7 | 15 | Full UX redesign milestone; urgent phase insertion (87.1); pairwise matchup pattern; store versioning discipline |
| v2026.3.7 | 5 | 11 | Treasury multi-entity expansion; config-driven import pipeline; entity switcher; EV design system applied |
| v2026.3.8 | 5 | 12 | Election Central + filter; race_candidates separation pattern; two-part election query; antipartisan schema enforcement |
| v2026.4.1 | 5 | 11 | Visual polish milestone; inline SVG icon system; tierColors token; gap closure phases from audit; single-day execution |

### Top Lessons (Verified Across Milestones)

1. Schema-first phases prevent retroactive migrations (v1.6, v1.7, v1.8, v2026.3)
2. Config-driven scripts with idempotent upserts enable safe re-runs (v1.6, v1.7, v1.8, v2026.3)
3. Coverage validation scripts with exit codes enable milestone gating (v1.7, v1.8)
4. AI-generated source URLs require systematic verification (v1.8)
5. Shared hooks are the best React feature reuse boundary (v1.5, v1.9)
6. Backend-first changes reduce frontend complexity (v1.3, v1.9)
7. Feasibility check gating prevents wasted scraper development (v2026.3)
8. Bridge table before any import prevents orphaned data across multi-source pipelines (v2026.3)
9. Wayback Machine is a reliable fallback for WAF-blocked government sites (v2026.4)
10. Research manifest with UUID primary keys enables direct DB upsert without fuzzy matching (v2026.4)
11. localStorage persistence for multi-step flows prevents user frustration on page refresh (v2026.4)
12. Cross-origin data sharing between same-domain apps solvable client-side via URL fragments (v2026.3.2)
13. Self-gating components keep parent code clean — child decides rendering based on data availability (v2026.3.2)
14. DB audit phase before data-dependent features prevents incorrect assumptions from driving design (v2026.3.3)
15. Atomic updates to consumer structures — partial updates to classification maps cause silent rendering bugs (v2026.3.3)
16. Cross-app feature integration works cleanest when each app owns its encoding boundary — no shared state infrastructure needed (v2026.3.4)
17. Inline styles in component libraries avoid Tailwind coupling — consumers provide the runtime; library provides the structure (v2026.3.4)
18. `useRef(false)` sync guard prevents double-POSTs in React strict mode double-invoke (v2026.3.4)
19. Auth-aware headers are pure UI wiring when auth context already exists — no new backend needed (v2026.3.5)
20. Human verification catches real integration bugs that automated tests miss — returnTo URLs, cross-origin cookies (v2026.3.5)
21. Pairwise comparison is superior to drag-to-rank for <10 items — binary choices are cognitively simpler (v2026.3.6)
22. Urgent phase insertions work cleanly when store actions are additive, not destructive (v2026.3.6)
23. Practice isolation pattern: separate store namespace prevents practice data from polluting real verdict payloads (v2026.3.6)
24. Client-side filtering is the right default at small data scale — avoids backend coupling for view-level concerns (v2026.3.6)
25. Separate candidate table from officials prevents search contamination — architectural isolation at DB layer beats filter logic (v2026.3.8)
26. Antipartisan enforcement at schema + ingestion layers prevents upstream data leakage — UI-only exclusion is insufficient (v2026.3.8)
27. Two-pass politician matching (exact → fuzzy with threshold) is the right pattern when canonical cross-system IDs don't exist (v2026.3.8)
28. Deferred data imports are acceptable when architectural wiring is complete — self-gating components handle empty data gracefully (v2026.3.8)
29. Gap closure phases formalize audit findings into tracked work — prevents drift between known issues and actual fixes (v2026.4.1)
30. Inline SVG in bundled libraries is safer than icon library imports — tree-shaking varies per consumer with splitting:false (v2026.4.1)
31. Visual hierarchy assumptions need user checkpoints — "more important = whiter" is not always intuitive (v2026.4.1)
