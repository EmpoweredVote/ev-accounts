# Project Research Summary

**Project:** v2026.3.8 Essentials Election Central
**Domain:** Civic tech — Election Central page + elected/appointed filter for the Essentials app
**Researched:** 2026-03-29
**Confidence:** MEDIUM (data sourcing has LOW-confidence gaps; architecture and pitfalls are HIGH)

## Executive Summary

This milestone adds two features to the existing Essentials app: an Election Central page showing upcoming races grouped by government body, and an elected/appointed filter toggle on the existing representatives page. Both features build directly on established infrastructure — PostGIS geofence matching, the existing `essentials.*` schema, and the PoliticianProfile/PoliticianCard components in ev-ui. No new npm packages are needed. The entire stack extension is two new API keys (Google Civic API + FEC OpenAPI), two new service files, and three new database tables.

The highest-risk decision is not architectural — it is data sourcing. BallotReady was decommissioned in v1.5, and no replacement pipeline was established. Election Central is data-driven: if candidate data is stale, incorrect, or absent, the page misleads users and destroys trust faster than having no page at all. The recommended path is to use the CivicEngine GraphQL API (the renamed BallotReady — an existing vendor relationship) via a nightly import script for the two target jurisdictions (Monroe County IN and LA County CA), supplemented by manual staging entry for any gaps in local race coverage. This requires confirming API access before any schema work begins.

The elected/appointed filter is deceptively simple — `is_appointed_position` already exists in the schema — but carries a hidden data quality risk. Officials imported since v1.5 via the ArcGIS gap-fill pipeline may have `is_appointed` defaulted to `false` rather than properly classified. Displaying the filter against unverified data produces incorrect groupings that are immediately noticeable to civic-informed users. A data audit must precede the filter UI build. Retention judges (appellate-level Indiana and California judges who face a public yes/no retention vote) also require special handling: they are both appointed and subject to election and must appear in both filter states simultaneously.

---

## Key Findings

### Recommended Stack

The existing stack handles all new requirements without modification or new dependencies. The backend (Express 4, TypeScript, Node.js 20, native `fetch()`) already has the geocoding, PostGIS, caching, and Zod validation infrastructure needed for the new election search endpoint. The frontend (React 19, Vite 7, Tailwind CSS 4, react-router-dom ^7.8.2) needs only a new `/elections` route and two new components (`ElectionGroup`, `RaceCard`).

**Core technologies — new additions only:**

- **Google Civic Information API v2:** Primary upstream source for contest and candidate data per address — free, 25K req/day, covers Indiana and California state/federal races. The Representatives API was shut down April 30, 2025; the Elections/voterInfoQuery API is still active. New env var: `GOOGLE_CIVIC_API_KEY`.
- **FEC OpenAPI v1:** Federal candidate incumbency verification — free, authoritative for House and Senate incumbency. New env var: `FEC_API_KEY`.
- **CivicEngine GraphQL API:** Recommended for nightly import of race and candidacy data for Bloomington IN and LA County CA. This is the renamed BallotReady (existing vendor relationship). Requires confirming API access before relying on it as the import source.
- **Native `fetch()` + existing `cache.ts`:** Reused for all external API calls and 24h response caching — same pattern as `geocodingService.ts`.
- **Three new DB tables:** `essentials.elections`, `essentials.races`, `essentials.race_candidates` — fully specified in ARCHITECTURE.md with indexes and FK structure.

**What NOT to use:** Google Civic Representatives API (shut down April 30, 2025), BallotReady (`BALLOTREADY_API_KEY` already decommissioned in v1.5), California SOS API (election-night results only), Indiana SOS (no machine-readable API), OpenElections (historical results only), Ballotpedia scraping (ToS violation).

### Expected Features

**Must have (table stakes):**

- Races grouped by government body then position — universal voter guide convention; mirrors existing Representatives hierarchy for cognitive consistency
- Incumbent badge on candidate cards — `is_incumbent` already exists; a small pill/chip is sufficient
- Election date per race with primary/general label — users arrive asking "when?" before "who?"
- Candidate name, photo, and position sought — minimum viable candidate card; initials avatar fallback already in ev-ui for missing photos
- Contested race display showing all candidates under one seat heading — users must see the full field per seat
- Elected vs. appointed filter toggle on the representatives page — `is_appointed_position` already in schema; data quality audit required first
- "No upcoming races found" empty state with coverage note — absent explanations destroy trust

**Should have (differentiators):**

- Candidate links to full Essentials-style profile pages — legislative record, Compass card, Read & Rank verdicts; deeper than any competing voter guide
- Primary vs. general distinction per race — Monroe County has May primary + November general; LA County has June primary + November general
- Retention judges appearing in BOTH Elected and Appointed filter tabs with "Retention Election" label — more accurate than any single-category treatment
- Open seat / vacancy label when no incumbent exists

**Defer (v1.x and v2+):**

- Days-until countdown — low effort; add after election dates are verified accurate
- Read & Rank quotes for candidates — requires data research and import via existing pipeline
- Compass stances for candidates — requires admin data entry
- Ballot measures / referendums — different data model and UX; separate scope
- Multi-jurisdiction expansion beyond two supported jurisdictions

**Anti-features (never add):**

- Party affiliation display — absolute violation of the antipartisan mission documented in MEMORY.md
- Polling place / voting logistics — scope mismatch; link to county registrar instead
- Real-time election results — link to official county source
- Endorsement lists — partisan signals by definition; violates antipartisan mission
- Animated countdown timers — gimmicky; undermines serious/trustworthy tone; plain "X days away" text only

### Architecture Approach

Election Central integrates as a peer route to `/results` in the Essentials app, sharing the same `?q=` address URL parameter pattern and Google Maps autocomplete input. A new backend service (`electionService.ts`) handles election search via the same geocode → PostGIS geofence match → DB join pipeline already used by `essentialsService.ts`. All election data is pre-imported nightly from CivicEngine into three new tables (`elections`, `races`, `race_candidates`) keyed to geofences via `geo_id + mtfcc` — no live API proxying per user request. The elected/appointed filter on the representatives page is entirely client-side: `is_elected` is already in every `PoliticianFlatRecord` response.

**Major components:**

1. **`essentials/src/pages/ElectionCentral.jsx`** — New page: address input, fetch races via `useElectionData` hook, render grouped by election then organization
2. **`ev-accounts/src/lib/electionService.ts`** — New service: `searchElectionsByAddress()` using geocode + PostGIS join against `essentials.races`
3. **`ev-accounts/src/routes/elections.ts`** — New routes: `POST /api/elections/search` and `GET /api/elections/:id/races`
4. **`essentials.elections / races / race_candidates` (DB)** — Three new tables; `races` linked to existing geofences via `geo_id + mtfcc` for address-based lookup
5. **CivicEngine nightly import script** — Pulls upcoming races for Bloomington IN + LA County CA coordinates; upserts to DB; best-effort name-match to `essentials.politicians`
6. **`essentials/src/lib/classify.js` (modified)** — Add `filterByAppointmentStatus()` for purely client-side elected/appointed filtering

### Critical Pitfalls

1. **Stale `is_appointed` data from post-v1.5 scraping** — Run `SELECT COUNT(*), is_appointed FROM essentials.politicians GROUP BY is_appointed` before building any filter UI. If 97%+ show `false`, the data is defaulted, not researched. Budget a manual classification pass for all in-scope officials before the toggle ships. This is a data task, not a code task.

2. **Retention judges must appear in BOTH filter states** — Binary `is_appointed` cannot model this hybrid status. Add `faces_retention_vote boolean` to `essentials.politicians` in Phase 1. Filter logic: show in Appointed if `is_appointed = true`; show in Elected if `is_appointed = false` OR `faces_retention_vote = true`. If this schema decision is deferred, it requires a migration and re-audit of all judicial records to fix.

3. **No election data pipeline means data rot** — Manual candidate entry without `last_verified_at` and `candidate_status` becomes stale within weeks. Candidates drop out, special elections are called. Establish the data source strategy and embed freshness fields in the schema before any data is entered. Never display a candidate whose `candidate_status = 'withdrawn'`.

4. **Candidates and officials must not share the `essentials.politicians` table** — Adding an `is_candidate` flag to `essentials.politicians` causes geofence searches to return candidates mixed with officials, runs the legislative pipeline on non-officials, and pollutes the officials dataset with challenger records post-election. `essentials.race_candidates` must be a separate table with a nullable FK to `politicians` for incumbents only.

5. **Party affiliation must be excluded at the ingestion layer, not the frontend** — Every external data source (Democracy Works, Ballotpedia, CivicEngine) includes party fields. If stored in the DB they will leak into API responses. Document the exclusion with antipartisan rationale comments in every import script. Audit all election API endpoints before launch.

---

## Implications for Roadmap

Based on combined research, suggested phase structure with strict dependency ordering:

### Phase 1: Data Audit, Schema Design, and Import Pipeline

**Rationale:** Every subsequent phase depends on this. The schema design must enforce the candidates/officials separation. The `is_appointed` data audit must occur before the filter UI is built. The data source decision (CivicEngine vs. Google Civic vs. manual) determines what the import script looks like. Building UI before the data layer is settled guarantees rework.

**Delivers:** Three new DB tables (`elections`, `races`, `race_candidates`) with correct FK structure and indexes; `faces_retention_vote` boolean on `essentials.politicians`; CivicEngine import script with Bloomington IN + LA County CA coordinates; verified seed data for test addresses; `is_appointed` audit findings and any required backfill; data source decision documented.

**Addresses:** All data-dependent table stakes features (race grouping, incumbent badge, election dates, candidate cards)

**Avoids:** Pitfall 1 (stale `is_appointed`), Pitfall 2 (retention judges schema), Pitfall 3 (no pipeline → data rot), Pitfall 4 (schema collision), Pitfall 5 (party affiliation storage), and election dates stored as `DATE` instead of `TIMESTAMPTZ`

### Phase 2: Backend Election Search Endpoint

**Rationale:** With verified data in the DB, the backend endpoint is straightforward and follows the identical pattern to `essentialsService.ts`. Build and integration-test before any frontend work so the response contract is stable.

**Delivers:** `POST /api/elections/search` returning `ElectionSearchResult[]` grouped by election and race; `GET /api/elections/:id/races`; wired into `index.ts`; integration tests with Bloomington and LA County test addresses.

**Uses:** Existing `geocodingService.ts`, `cache.ts` (24h TTL), `pool.query()` pattern, `optionalAuth` middleware

**Implements:** `electionService.ts` + `routes/elections.ts` components

### Phase 3: Election Central Frontend Page

**Rationale:** Backend API is stable before frontend work begins. The page mirrors the structure of `Results.jsx` but is simpler (no progressive loading, no showCandidates toggle). New components are small and well-scoped.

**Delivers:** `/elections` route in `App.jsx`; `ElectionCentral.jsx` page with address search; `ElectionGroup.jsx` and `RaceCard.jsx` components; `useElectionData.js` hook; `fetchElections()` in `api.jsx`; "Elections" nav link from Results page carrying `?q=` forward; empty state for no upcoming elections; `ev:election-results` sessionStorage cache key (separate from `ev:results`).

**Addresses:** All table stakes UI features — race grouping, incumbent badges, election dates, primary/general labels, open seat labeling, coverage note, "no races found" empty state

### Phase 4: Elected/Appointed Filter on Representatives Page

**Rationale:** Entirely client-side; depends only on `is_appointed` data quality verified in Phase 1. Kept as its own phase so it can be shipped or held independently if the data audit reveals quality issues requiring extended remediation.

**Delivers:** `filterByAppointmentStatus()` in `classify.js`; filter toggle UI in `Results.jsx`; retention judge dual-filter behavior tested against known Indiana appellate judges; validated with Bloomington and LA County addresses.

**Avoids:** Pitfall 1 (showing filter against bad data) and Pitfall 2 (retention judges invisible in the Elected tab)

### Phase 5: Candidate Profile Links

**Rationale:** Final integration step. Incumbents already have politician records — linking is trivial. The decision for unmatched challengers (inline display vs. stub page vs. no link) is a product decision that benefits from seeing the live data first.

**Delivers:** Incumbent candidate cards linking to `/politician/:id`; product decision documented for unmatched challengers; challenger profile pages render without legislative history section (no empty loading states, no API calls to legislative endpoints for challengers).

**Avoids:** Performance trap of triggering the legislative data fetch for challenger candidates who have no legislative history

### Phase Ordering Rationale

- Data before UI: Every UI phase depends on verified data and a stable API contract. Phases 1 and 2 are strict prerequisites for Phases 3-5.
- Filter after data audit: The elected/appointed filter (Phase 4) is intentionally placed after the data audit (Phase 1) to prevent shipping with defaulted classification data.
- Candidate links last: Linking candidates to profiles requires knowing which candidates have matched politician records — determined by the import script output from Phase 1.
- Separate route prefix: `POST /api/elections/search` is a new route prefix from `/api/essentials/` to maintain clear domain boundaries and avoid breaking the existing `PoliticianFlatRecord[]` response contract that Results.jsx depends on.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 1 (Import Pipeline):** CivicEngine API access status must be confirmed before import script development begins. The vendor relationship from the BallotReady era may require a new contract. If CivicEngine is unavailable or cost-prohibitive, the fallback (Google Civic API + manual staging) has known local race coverage gaps for Monroe County that must be documented and budgeted before development starts.
- **Phase 1 (Data Audit):** The actual distribution of `is_appointed` values across ~800+ in-scope officials is unknown until the audit query runs. Could range from "all correct" to "all defaulted to false." If poor, a manual classification pass for all Bloomington/Monroe County IN and LA County CA officials is required before Phase 4 can proceed — budget 1-2 days.

Phases with standard patterns (skip research-phase):

- **Phase 2 (Backend endpoint):** Follows the exact same geocode → PostGIS → JOIN pattern established in `essentialsService.ts`. Internal, well-documented pattern. No external unknowns.
- **Phase 3 (Frontend page):** Mirrors `Results.jsx` structure with `useElectionData` hook following `usePoliticianData`. New components are small and well-scoped. No novel architecture decisions.
- **Phase 5 (Candidate links):** Straightforward nullable FK lookup; existing `PoliticianProfile` component is reused without modification for incumbents.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Existing stack is HIGH confidence (direct code inspection). New APIs (Google Civic, FEC, CivicEngine) are MEDIUM — officially documented and active, but Monroe County IN local race coverage under Google Civic is unconfirmed; CivicEngine access requires contract verification. |
| Features | MEDIUM | Domain conventions (race grouping, incumbent display, election dates) confirmed from Ballotpedia, VOTE411, Center for Civic Design. Antipartisan constraints confirmed from MEMORY.md. Retention judge edge case confirmed from Indiana Judicial Branch docs and Ballotpedia. |
| Architecture | HIGH | Based on direct code inspection of ev-accounts and essentials. Patterns are internal with no external unknowns. Schema design fully specified. Build order dependencies explicit. |
| Pitfalls | HIGH | Derived from direct codebase inspection (v1.5 BallotReady decommission, v1.6 gap-fill pipeline), confirmed via Indiana Judicial Branch and Ballotpedia for retention elections, and Democracy Works / Ballotpedia coverage research. |

**Overall confidence:** MEDIUM

### Gaps to Address

- **CivicEngine API access:** Architecture research recommends CivicEngine as the nightly import source (existing vendor relationship). STACK.md recommends Google Civic API (free, no contract). These recommendations diverge. Resolve in Phase 1 by confirming CivicEngine access status before writing any import script. If neither is viable, manual staging entry is the fallback for both jurisdictions.
- **Google Civic local race coverage for Monroe County:** VIP data coverage for Indiana depends on county cooperation with the Voting Information Project. Monroe County's participation is unconfirmed. If Google Civic does not cover Bloomington city council races, manual staging entry becomes mandatory for local races — budget accordingly in Phase 1 scope.
- **`is_appointed` data quality for post-v1.5 officials:** Unknown until the audit query runs. Treat as a blocker for Phase 4 until audited. If data quality is poor, Phase 4 cannot ship until remediation is complete.
- **Ballotpedia coverage of Bloomington (pop. ~90K):** If Ballotpedia is considered as a fallback candidate data source, coverage of Bloomington must be verified before any contract discussion — their standard API covers top 100 cities and Bloomington may not qualify.
- **Candidate withdrawal deadline edge case:** In some jurisdictions, a candidate who publicly withdraws past the filing deadline remains on the ballot. The `candidate_status` enum should include a `ballot_required` state to handle this accurately and avoid hiding a candidate who must legally appear on the ballot.

---

## Sources

### Primary (HIGH confidence)

- Direct codebase: `ev-accounts/backend/src/lib/essentialsService.ts` — confirmed `is_elected`, `is_appointed_position`, `is_incumbent` derivations and address search flow
- Direct codebase: `ev-accounts/backend/migrations/033_politician_schema.sql` — column availability confirmed
- Direct codebase: `essentials/src/pages/Results.jsx`, `App.jsx`, `lib/classify.js`, `lib/api.jsx` — routing and data flow patterns confirmed
- Direct codebase: `CivicEngine GraphQL API Documentation.md` + `BallotReadyDataDictionary.csv` — GraphQL schema and candidacy fields confirmed
- [Google Civic Information API docs](https://developers.google.com/civic-information/docs/v2) — voterInfoQuery fields confirmed active
- [Google Civic Representatives API turndown notice](https://groups.google.com/g/google-civicinfo-api/c/9fwFn-dhktA) — Elections API still active; Representatives API shut down April 30, 2025
- [FEC OpenAPI docs](https://api.open.fec.gov/developers/) — free federal candidate API confirmed
- [Indiana Judicial Branch: Retention System](https://www.in.gov/courts/about/retention/) — appellate judges appointed then face retention vote; hybrid classification confirmed
- [Ballotpedia: Monroe County IN elections 2026](https://ballotpedia.org/Monroe_County,_Indiana,_elections,_2026) — race structure and judicial election types confirmed
- [Ballotpedia: LA County elections 2026](https://ballotpedia.org/Los_Angeles_County,_California,_elections,_2026) — race structure confirmed
- [LA County Registrar: Upcoming Elections](https://www.lavote.gov/home/voting-elections/current-elections/upcoming-elections) — June 2 primary, November 3 general confirmed

### Secondary (MEDIUM confidence)

- [Google Civic API rate limits](https://groups.google.com/g/google-civicinfo-api/c/1H7WZ0lG594) — 25,000/day (community forum, not official docs)
- [Voting Information Project coverage](https://www.votinginfoproject.org/election-coverage) — Indiana local race coverage for Monroe County not itemized
- [Center for Civic Design: Designing Election Websites (2025)](https://civicdesign.org/wp-content/uploads/2025/03/Designing-Election-Websites-2.pdf) — UX scanning behavior, plain language conventions
- [Democracy Works Elections API](https://data.democracy.works/ballot-info) — nonprofit-friendly, free calendar tier; candidate data requires partnership agreement
- [Ballotpedia: Buy Political Data](https://ballotpedia.org/Ballotpedia:Buy_Political_Data) — top 100 cities coverage; Bloomington inclusion unconfirmed
- [CivicEngine developer docs](https://developers.civicengine.com/) — comprehensive coverage confirmed; pricing requires direct contact

### Tertiary (LOW confidence)

- [California SOS Election Night API](https://api.sos.ca.gov/) — returned 403 on direct access; election-night results only; not suitable for pre-election candidate discovery
- [Indiana SOS candidate information](https://www.in.gov/sos/elections/candidate-information/) — confirmed no machine-readable API; PDF and web pages only

---

*Research completed: 2026-03-29*
*Ready for roadmap: yes*
