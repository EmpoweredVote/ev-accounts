# Project Research Summary

**Project:** Empowered Accounts -- v2.20 2026 US House Candidate Coverage (Wave 1: CA/TX/FL/NY)
**Domain:** Civic-data sourcing + election-race surfacing (no application code change)
**Researched:** 2026-06-27
**Confidence:** HIGH

## Executive Summary

v2.20 is a **pure-data milestone**. The four research tracks converge on one load-bearing conclusion: surfacing a 2026 US House race on the Elections page (`/elections`) requires **no backend code change**. The races to offices to districts to geofence join in `getElectionsByCoordinate` (`electionService.ts`) already matches a House race to a resident address by coordinate, and the CA scaffolding (all 53 district `races` rows linked to incumbent offices) is already seeded. The only missing data is `essentials.race_candidates` rows (plus the politician records, headshots, and stances they link to). This is **Path B** -- the elections feed reading `race_candidates`. It is NOT Path A (the Senate-style `Candidate for U.S. ...` candidacy offices, proven invisible to `/elections` with 0 races and 0 race_candidates), and NOT the representatives feed (which filters `is_incumbent=true` and therefore excludes every challenger by design).

The recommended approach is **seed-now / prune-after-primary**, driven by field readiness. As of 2026-06-27, three of four states have a fully decided general-election field: **CA (52, top-two primary June 2), TX (38, March 3 + May 26 runoff), and NY (26, June 23) -- 116 districts decided NOW**. Only **FL (28 districts) is pending its Aug 18 primary**, but the FL federal qualifying period has closed, so the qualified field is final and downloadable today -- seed it now, prune losers in a single pass after Aug 18. Per candidate, the work is the established pipeline: reuse-or-create a politician record (NEVER duplicate an incumbent), source a headshot, and research the **federal 24-topic chairs-not-polarity** stance set with a **mandatory primary-source verification pass** and a **0-unsourced gate**.

The dominant risks are all data-discipline traps, not technical ones. The four highest-impact: (1) **duplicate incumbent records** (the v2.4 two-Andy-Barrs failure -- reuse the existing `politician_id`, never insert a new row for a sitting rep); (2) **lost-incumbent-primary** assumptions (NY-10 Goldman and NY-13 Espaillat both LOST 6/23 -- never derive the nominee from incumbency, verify per district); (3) **stance over-read** (agents pin plausible-but-false chairs even with cited URLs -- 16 rows were deleted in the prior pass; re-fetch raw quotes and honest-skip where evidence is thin); and (4) **two-path prune** (retire losers via `is_active=false` AND `candidate_status='withdrawn'`, never hard-DELETE). Field discovery is gated by fetch-walls (Ballotpedia returns blank, long Wikipedia pages return TOC-only) -- Playwright is the universal workaround, and a registered FEC API key (1000/hr) is required to avoid the DEMO_KEY 10/hr stall.

## Key Findings

### Recommended Stack

This is a data-sourcing milestone; the "stack" is authoritative sources plus fetch tooling. The stance pipeline, find-headshots conventions, TIGER geofencing, and chairs-not-polarity methodology are already built and out of scope. See STACK.md.

**Core sources/tools:**
- **Wikipedia per-state House pages**: primary field discovery -- fetchable, structured by district. CAVEAT: WebFetch returns TOC-only on the long pages; use raw wikitext API / section anchors / Playwright.
- **FEC OpenFEC API** (`/v1/candidates/?office=H&state={ST}&election_year=2026`): authoritative FEC candidate IDs + finance -- one paginated call per state, NOT per district. Requires a registered key (1000/hr); the DEMO_KEY 10/hr cap will stall a 144-district pull.
- **FL DoE candidate download** (`downloadcanlist.asp`, tab-delimited): the official, final FL field -- bypasses the JS/ASP wall. Re-download after Aug 18.
- **NBC/AP results**: confirm NY June-23 nominees and any uncalled close race.
- **Playwright**: universal workaround for fetch-walled sources (Ballotpedia blank, SoS SPAs, VOTE411 address-gating).

### Expected Features

v2.20 is overwhelmingly a data milestone -- the election schema, address-to-races feed, incumbent marker, headshot COALESCE fallback, stance FK, visibility window, and antipartisan invariant are all shipped. See FEATURES.md.

**Must have (table stakes):**
- Race surfaces for the resident address/district (seed `race` + `race_candidates`)
- Candidate card per candidate (name + headshot) -- faceless cards read as broken
- Incumbent / open-seat / uncontested framing (data already present, frontend renders)
- Sourced chairs-not-polarity stances per candidate (federal 24-topic, honest-skip where no source) -- the core differentiator, requires `politician_id` link
- Graceful partial-coverage / not-yet-covered empty state (never hard-fail a resolved district)

**Should have (competitive):**
- Viewer-personalized compass alignment ("matches you on N topics") -- Connected tier
- Sourced-stance transparency (every chair backed by a fetched URL)
- Antipartisan candidate cards (party lives on `races.primary_party` only, never the candidate)
- Seamless undecided-to-decided transition as primaries resolve (time-driven, no code change)

**Defer (v2.21+):**
- States beyond the top-4 delegations
- Finance summary on challenger cards (FEC ingestion for new records) -- null-safe, stretch
- Multi-candidate compass overlay rendering

**Anti-features (explicitly avoid):** party label/color on cards; inferring stances from party; seeding primary-only/withdrawn/speculative candidates; predicting winners/polling; live results; long-tail write-in/micro-party candidates.

### Architecture Approach

The definitive surfacing path is **Path B -- `getElectionsByCoordinate` reading `essentials.races` + `essentials.race_candidates`**, geography inherited through `office_id` to `districts.geo_id` + PostGIS `ST_Covers`. A race with `office_id IS NULL` is treated as statewide and will NOT geo-match a district. See ARCHITECTURE.md.

**Major components (the required row chain -- most already exist):**
1. `essentials.elections` -- 1 per state event (CA exists; create for TX/FL/NY)
2. `essentials.offices` / `districts` / `geofence_boundaries` -- all 435 districts already seeded + geofenced; **reuse the incumbent U.S. Representative office, never create a new one**
3. `essentials.races` -- exists for all 53 CA; **MISSING for TX/FL/NY -- create first, `office_id` to the district House office**
4. `essentials.race_candidates` -- **THE CORE MISSING DATA** -- 1 per candidate, `politician_id` linked (incumbent or seeded challenger), `is_incumbent`, `candidate_status='active'`

**Per-state work split:**
- **CA** = insert `race_candidates` only (53 races + offices + geofences pre-seeded; template: `ingest-ca-sos-2026-challengers.ts`)
- **TX / FL / NY** = create `elections` (if absent) + `races` rows first, then `race_candidates`

The empty-state message lives in the separate Essentials frontend repo, not this repo -- backend always returns `{elections:[]}`. No empty-state code work in this milestone.

### Critical Pitfalls

1. **Duplicate incumbent records (v2.4 two-Andy-Barrs)** -- reuse the existing `politician_id`; new work is challengers + open-seat candidates only. Gate: zero duplicate `full_name` per state.
2. **Lost-incumbent-primary assumption** -- NY-10 Goldman and NY-13 Espaillat LOST 6/23. Never derive the nominee from incumbency; verify per district from a primary-results source. Defeated incumbent stays in reps feed, gets no active `race_candidates` row.
3. **Stance over-read** -- agents pin plausible-but-false chairs even with cited URLs (16 rows deleted in the prior pass). Mandatory primary-source re-fetch of raw quotes; honest-skip thin topics; 0-unsourced gate; embed exact 1-5 stance texts per topic.
4. **Two-path prune (seed-now/prune-later)** -- never hard-DELETE losers; `UPDATE is_active=false` (reps feed) AND `candidate_status='withdrawn'` (elections feed) to preserve records/stances/headshots/FEC.
5. **Two-surfacing-paths confusion** -- challengers only surface via the elections feed (`race_candidates`); the reps feed `is_incumbent=true` filter excludes them. A `race_candidates` row with NULL `politician_id` shows no stances and no photo.

Lower-tier: thin-source over-fill (whole-record honest-skip is acceptable, gate-pinned by id), headshot sourcing + antipartisan display, FEC rate/name-match (best-effort), malformed-CSV + stale-quote duplication (field-count-validate; wipe `essentials.quotes` per pid then re-push).

## Implications for Roadmap

Based on combined research, the suggested phase structure follows the dependency chain: **diagnose, resolve nominees, seed records/headshots/stances per state, verify, deferred FL re-check.** Stance work is the bulk of effort and the highest-risk; field-discovery and seeding are mechanical once nominees are confirmed.

### Phase 1: Diagnostic + Nominee Resolution
**Rationale:** Must run before any seeding -- prevents the two costliest traps (duplicate incumbents, wrong nominees). Field is already decided for CA/TX/NY (116 districts).
**Delivers:** Per-district verified general-election field (CA top-two advancers, TX runoff winners, NY 6/23 nominees, FL final qualified field); a stance-gap/existence diagnostic mapping each district incumbent to its existing `politician_id`.
**Addresses:** race-surfaces-by-address (field definition); incumbent/open-seat framing.
**Avoids:** Pitfall 1 (duplicate incumbents -- link to existing record), Pitfall 2 (lost-primary -- NY-10/NY-13 confirmed explicitly).

### Phase 2: CA Candidate Seeding (race_candidates only)
**Rationale:** Lowest-friction state -- 53 races + offices + geofences already exist; turnkey target. Validates the seed pattern before the create-races states.
**Delivers:** `race_candidates` rows (incumbent + challengers) on all 52 CA House races; new politician records + headshots + federal-24 stances for non-incumbent candidates.
**Uses:** `ingest-ca-sos-2026-challengers.ts` template; FEC API for IDs; find-headshots flow; stance pipeline.
**Implements:** `essentials.race_candidates` (component 4).
**Avoids:** Pitfall 3 (stance over-read -- verification sub-step), Pitfall 9 (CSV/quote hygiene).

### Phase 3: TX + NY Candidate Seeding (create races, then candidates)
**Rationale:** Decided fields; differ from CA only in needing `elections`/`races` rows created first. Groups the two create-races decided states together (top-two CA already handled; TX/NY are partisan-primary).
**Delivers:** `elections` (if absent) + `races` rows per TX/NY district, then `race_candidates` + politician records + headshots + stances.
**Uses:** `importElectionData.ts` / `seed-la-county-2026-primary-state-federal.sql` precedents.
**Implements:** `essentials.races` (component 3) + `race_candidates` (component 4).
**Avoids:** Pitfall 2 (NY lost incumbents), AP-2 (never `office_id IS NULL`).

### Phase 4: FL Candidate Seeding (final qualified field, provisional)
**Rationale:** FL primary is Aug 18 -- seed the final qualified field NOW (it is closed/downloadable) so residents get upcoming-vote data; flag as pending.
**Delivers:** `elections` + `races` + `race_candidates` for all 28 FL districts from the FL DoE download; records/headshots/stances.
**Uses:** FL DoE `downloadcanlist.asp` tab-delimited bulk download.
**Avoids:** Pitfall 4 (seed-now discipline -- do not guess the general winner).

### Phase 5: Coordinate Verification Gate
**Rationale:** Proves Path B end-to-end per state -- the success criterion is type-address-see-your-House-race-field.
**Delivers:** For a known address in each Wave-1 state, `getElectionsByCoordinate` / `/elections-by-address` returns the House race with the full candidate field, headshots, and stances.
**Avoids:** Pitfall 5 (two-path confusion -- assert the challenger field is present, not just the incumbent); confirms no party on candidate cards.

### Phase 6 (Deferred): FL Post-Primary Re-Check
**Rationale:** Keyed to Aug 18 -- prune FL primary losers using the two-path method.
**Delivers:** `is_active=false` + `candidate_status='withdrawn'` for losers (records preserved); re-research advancing thin-stance winners against primary sources.
**Avoids:** Pitfall 4 (no hard-DELETE).

### Phase Ordering Rationale

- **Diagnostic first** is mandatory: the two most expensive recovery scenarios (duplicate-record cleanup = migration-1074-class work; wrong nominee surfaced) are both prevented only by resolving identity/nominee before any insert.
- **CA before TX/NY/FL** because CA is `race_candidates`-only (races pre-seeded) -- it validates the seed + stance + headshot pattern on the turnkey state before the create-races states add a step.
- **FL last among the seeding phases + a deferred re-check** because it is the only pending-primary state; everything else is decided now.
- **Verification gate before the deferred re-check** so the live experience is proven for all 144 districts (116 final, 28 provisional) before Aug 18.

### Research Flags

Phases likely needing deeper per-district research during planning:
- **Phase 1 (Nominee Resolution):** field discovery is fetch-walled -- needs Playwright/raw-wikitext approach per state; CA top-two same-party generals and NY upsets need explicit confirmation.
- **Phases 2-4 (Stance Research):** the bulk of effort and highest-risk; each is a research-heavy phase requiring the mandatory primary-source verification pass. Low-profile challengers yield ~5-9 honest stances (expect whole-record honest-skips, gate-pinned by id).

Phases with standard patterns (skip research-phase):
- **Phase 2 CA seeding mechanics:** `race_candidates` insert pattern is established (`ingest-ca-sos-2026-challengers.ts`).
- **Phase 5 Verification:** existing v2.6 ELEC-01 coordinate-verification pattern.
- **Phase 6 Re-check:** the LA re-check two-path prune pattern is project-validated.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Primary calendar (CA/TX/FL/NY dates) + source fetch behavior + FEC rate limits all verified live this session. |
| Features | HIGH | Grounded in this repo live election schema + feed service; external civic-tool norms (Ballotpedia/Vote411) are MEDIUM. |
| Architecture | HIGH | Traced live code file:line; production DB inspected -- Path A invisibility and CA scaffolding proven, not assumed. |
| Pitfalls | HIGH | Verified against current service code, migrations 042/196/1074, and project memory of the v2.4 Senate run + LA re-check. |

**Overall confidence:** HIGH

### Gaps to Address

- **FL final nominees (Aug 18):** seed the qualified field now as provisional; the deferred re-check (Phase 6) resolves losers. Known and scheduled, not a blocker.
- **NY uncalled close races:** any genuinely-uncalled 6/23 race needs a brief NBC/AP cross-check during Phase 1 nominee resolution.
- **CA same-party (top-two) generals:** confirm both advancers from results -- do NOT assume one D + one R.
- **Thin-source challengers:** stance coverage will be uneven; whole-record honest-skips are acceptable and must be gate-pinned by id. Plan stance gates to allow documented skips, not require full 24-topic sets.
- **FEC name-match at 144-district scale:** finance is best-effort/nullable -- record no-FEC-ID rather than retrying; reuse the existing fix-name-mismatch script. Not on the critical path.

## Sources

### Primary (HIGH confidence)
- Repo: `electionService.ts`, `essentialsService.ts`, `electionGrouping.ts`, `geoIdGuard.ts`, `routes/essentials.ts` -- surfacing path, visibility window, is_incumbent filter, empty-array contract
- Repo: `migrations/042_election_schema.sql`, `196_us_senate_candidates_2026.sql`, `1074_dedupe_david_brock_smith.sql`, `1072_seed_2026_statewide_general_candidates.sql` -- schema, seed convention, dedup recovery
- Repo: `scripts/ingest-ca-sos-2026-challengers.ts` -- canonical `race_candidates` seed pattern
- Live production DB inspection 2026-06-27 -- 53 CA House races (0 candidates), TX/FL/NY absent, 27 Path-A offices with 0 races/race_candidates
- FEC OpenFEC `/v1/candidates` (verified live; DEMO_KEY 10/hr vs registered 1000/hr); CA/TX/FL/NY SoS primary-date pages
- FL DoE candidate download (`downloadcanlist.asp`); NBC News 2026 NY House results
- `.planning/PROJECT.md` (v2.20 goal, Wave-1 scope, federal-24-topic, deferrals); MEMORY.md (chairs-not-polarity, no-inference, seed-now rules)

### Secondary (MEDIUM confidence)
- Wikipedia per-state 2026 House pages -- field discovery (WebFetch TOC-only caveat; needs Playwright/raw wikitext)
- Ballotpedia / Vote411 / BallotReady -- civic-tool feature norms; Ballotpedia confirmed fetch-walled (blank)

### Tertiary (LOW confidence)
- Politics1 per-state roll-ups -- minor-party/independent cross-check, human-curated

---
*Research completed: 2026-06-27*
*Ready for roadmap: yes*
