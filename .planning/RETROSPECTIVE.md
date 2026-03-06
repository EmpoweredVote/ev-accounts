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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.7 | 6 | 15 | First milestone with Python scraping pipeline; manual curation accepted |
| v1.8 | 6 | 28 | First research-heavy milestone; URL verification as separate plans |
| v1.9 | 3 | 6 | Smallest milestone yet — tight scope, 100% plan adherence |
| v2026.3 | 6 | 19 | First multi-language pipeline milestone (Go + Python); feasibility gating pattern established |
| v2026.4 | 7 | 21 | Mixed data + UX milestone; Wayback Machine fallback; coach mark pattern established |

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
