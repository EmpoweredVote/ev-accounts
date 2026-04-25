# Execution Backlog — v2026.4.4 (Indiana Primary Fix Wave)

**Source:** `.planning/GAP-REPORT.md` (Phase 115 synthesis)
**Target completion:** May 1, 2026 (4 days before May 5 primary)
**Generated:** 2026-04-14
**Closes requirement:** GAP-03

## Format

Each phase entry below is ROADMAP-ready per D-08. To start v2026.4.4, copy these entries into a new `.planning/ROADMAP.md` (or new milestone roadmap) and run `/gsd-discuss-phase` for each. Effort signal uses D-09 T-shirt sizes:

- **S** = few hours (single-file fixes, string updates, config)
- **M** = 1-3 plans (component debugging, integration wiring, scoped data work)
- **L** = 3+ plans (data import pipelines, multi-app changes, new infrastructure)



## Tier 1 Phases (target: shipped by May 1, 2026)

### Phase 116: Quick Correctness Fixes
**Goal:** Correct high-visibility factual errors and broken navigation that a Monroe County voter would notice immediately on a first visit — wrong election date, broken header links, wrong default tab.
**Gaps closed:** G-114-006 (wrong election date), G-114-026 (broken SiteHeader nav links), G-114-003 (default Representatives tab hides challengers)
**Effort:** S
**Depends on:** None
**Notes:** All three are surface-level string / logic fixes. G-114-026 ships via the ev-ui auto-bump pipeline. Should be done first to clear high-visibility wins.

### Phase 117: Candidate Stub Resolution + Data Import (PATTERN-001)
**Goal:** Create politician records and import minimum viable data (name, office, photo, 1-line bio) for the 30 stub candidates blocking Essentials profiles, Compass picker, and Read & Rank quotes for contested Monroe County races.
**Gaps closed:** PATTERN-001, G-114-010 (empty stub profiles), G-114-012 (challengers absent from Compass picker), G-114-018 (zero quotes for challenger candidates), AUDIT-02, AUDIT-03 (stub portion), AUDIT-04 (stub portion)
**Effort:** L
**Depends on:** None (but should start in parallel with Phase 116 due to data-sourcing lead time)
**Notes:** **CRITICAL FEASIBILITY DEPENDENCY** — Tier 1 status is contingent on whether minimum data can be sourced for ~30 county-level candidates by May 1. Discuss-phase MUST include a data-sourcing sub-task evaluating public record availability (county clerk filings, candidate websites, local press) BEFORE code work. If sourcing slips past April 25, escalate the highest-impact 5-10 candidates only and demote the rest to Tier 2.

### Phase 118: Read & Rank Quote Display Fix (G-114-029)
**Goal:** Restore Read & Rank verdict badges on politician profile pages — debug why 10 Pierce quotes in the DB are not rendering on PoliticianProfile.jsx in production.
**Gaps closed:** G-114-029 (verdict badges missing despite quotes in DB)
**Effort:** M
**Depends on:** None
**Notes:** Discuss-phase must include a code-investigation step BEFORE implementation (see RESEARCH.md Open Question 2). Possible causes: CSS regression, feature flag, prop wiring break, or ev-ui consumer not picking up a recent bump. Investigate published ev-ui versions in essentials before writing the fix plan.

### Phase 119: Read & Rank Location Filter Repair (G-114-016)
**Goal:** Restore the Monroe County location filter in Read & Rank so voters can scope quotes to their candidates — both filter mechanisms are currently non-functional.
**Gaps closed:** G-114-016 (broken location filter mechanisms)
**Effort:** M
**Depends on:** None
**Notes:** Geocoding wiring + filter logic. Independent of PATTERN-001 because the filter UI gap exists regardless of underlying data quality.

### Phase 120: Contested-Race Bio + Photo Authoring
**Goal:** Manually author bios and source headshots for the small set of candidates in contested Monroe County May 5 races (D-61 IN House, IN-9 US House, contested county offices) — the Tier 1 subset of PATTERN-003 (app-wide bio gap).
**Gaps closed:** G-114-007 (Pierce no bio), G-114-009 (Young no headshot), AUDIT-05a (contested-race photo subset), AUDIT-06 (contested-race bio subset)
**Effort:** M
**Depends on:** None
**Notes:** Scope-limited to ~5-10 candidates in contested races, NOT all 51 linked. The full 51-candidate bio program is Tier 2 (see Phase 124 below). This phase is hand-authoring + photo sourcing, not pipeline work.

### Phase 121: County Council D1→D4 Geofence Repair (PATTERN-004)
**Goal:** Fix the County Council District 1 → District 4 geofence binding bug — Kirkwood Bloomington addresses currently resolve to the wrong council district, returning the wrong race for the voter.
**Gaps closed:** PATTERN-004, AUDIT-08 (geofence resolution test gap surfaced via dual evidence per D-06)
**Effort:** M
**Depends on:** None
**Notes:** Single geofence polygon repair, possibly a coordinate or MTFCC issue. Verify against the Kirkwood test address used in MATRIX.md Dim 1. This is a benchmark-derived gap evidenced by both MATRIX.md Dim 1 footnote AND the AUDIT-01 race table claiming the geofence exists.



## Tier 2 Phases (future milestone — post-primary)

### Phase 122: Cross-App Loop Polish (PATTERN-002)
**Goal:** Repair the remaining cross-app integration gaps in the Compass → Read & Rank → Essentials voter loop (CompassCard state relay, Compass→Essentials profile links, Essentials→Treasury handoff).
**Gaps closed:** PATTERN-002, G-114-027, G-114-028, G-114-030, G-114-031
**Effort:** M
**Depends on:** Phase 118 (Read & Rank verdict fix landed first — same component surface)
**Notes:** All Tier 2 confusing/feature regressions. G-114-029 is excluded — already shipped in Phase 118 as a Tier 1 blocker.

### Phase 123: Photo Coverage Expansion (broader)
**Goal:** Extend the headshot scraping/sourcing pipeline to fill the 62-missing-photo gap for non-contested-race linked candidates.
**Gaps closed:** AUDIT-05b (broader photo gap, 62 candidates with no photo)
**Effort:** M
**Depends on:** Phase 120 (contested-race photos delivered first)
**Notes:** Pipeline work — extends the scraper from v2026.4.1 to additional candidate sources.

### Phase 124: App-Wide Bio Authoring (PATTERN-003 broader)
**Goal:** Author bios for the remaining ~45 linked candidates not covered by Phase 120 — close the 0/51 bio gap that drives EV's lowest score (Dim 3 = 0) on the competitive matrix.
**Gaps closed:** PATTERN-003 (broader), AUDIT-06 (full row), G-114-007 (broader closure)
**Effort:** L
**Depends on:** Phase 120 (contested races first)
**Notes:** Largest non-intentional benchmark gap. Likely 3-4 plans: bio authoring methodology, contested-race batch (already done in 120), state-race batch, federal-race batch.

### Phase 125: Tier 2 UX Polish Bundle
**Goal:** Address the 21 Tier 2 G-114 entries that are confusing/minor severity (no race-coverage data impact) — small UX cleanups that improve polish but do not block voters.
**Gaps closed:** G-114-001, G-114-002, G-114-004, G-114-005, G-114-008, G-114-011, G-114-013, G-114-014, G-114-015, G-114-017, G-114-019, G-114-020, G-114-021, G-114-022, G-114-023, G-114-024, G-114-025
**Effort:** M
**Depends on:** None
**Notes:** Could be split into per-app sub-phases during discuss-phase. Bundle for now to avoid backlog bloat (Pitfall 5).

### Phase 126: Geofence Hardening (broader)
**Goal:** Address rural address geocoding failures (e.g., Mt Tabor Rd) and import the 11 missing Monroe County township geofences for precinct-level precision.
**Gaps closed:** AUDIT-08 (broader), INFRA-01 reference
**Effort:** L
**Depends on:** Phase 121 (CC D1 fix landed first)
**Notes:** Township import is a known v2026.4.4 carry-over from the milestone backlog. Out of Tier 1 scope.



### Treasury: Geo-match address to available budgets (PostGIS)
**Goal:** When a user arrives at Treasury Tracker with an `evUserAddress` cookie, use the address to run a proper geofence match (ST_Intersects, same pattern as Essentials) against treasury municipality boundaries — returning only the township, city, and county that actually contain the address, rather than all municipalities in the same state.
**Context:** Current "Near you" section filters by state only, which surfaces every municipality in that state. A real address like "123 Kirkwood Ave, Bloomington IN" should match Monroe County + Bloomington City (and maybe Perry Township) — not all IN municipalities as we add more. Requires storing lat/lng in the `evUserAddress` cookie (or geocoding on the Treasury backend) and maintaining PostGIS boundaries for each treasury municipality.
**Depends on:** Nothing — already needed. Treasury has both Indiana and California municipalities, so state-level filtering already shows all CA municipalities to any California user, which will be overwhelming as coverage grows. Should be prioritized before adding more municipalities.


## Excluded from Backlog (per D-02 feasibility ceiling)

The following benchmark-derived gaps are NOT in this backlog because they cannot plausibly ship by May 1 AND they represent new product surface area, not fixes:

- **No candidate-response Q&A product** (MATRIX.md E4 — Vote411=2, VoteSmart=3, Ballotpedia=3). New product feature; v2026.5.x or later.
- **No withdrawn candidate tracking** (MATRIX.md E5 — Ballotpedia=3). New data category; v2026.5.x or later.

These appear in `.planning/GAP-REPORT.md` Tier 2 for awareness but do not generate backlog phases for v2026.4.4 (Pitfall 1 — treating benchmark features as Tier 1 gaps).



## Sequencing Recommendation

Suggested order for v2026.4.4 execution (by dependency + impact):

1. **Phase 117** (PATTERN-001 stub resolution) — start FIRST due to data-sourcing lead time
2. **Phase 116** (Quick correctness fixes) — clear easy wins in parallel with 117
3. **Phase 121** (CC D1 geofence) — independent, fast feedback
4. **Phase 118** (verdict badges) — investigate-first, then fix
5. **Phase 119** (location filter) — independent
6. **Phase 120** (contested-race bio + photo) — manual content work in parallel
7. **Phase 122** onward — Tier 2 work post-primary
