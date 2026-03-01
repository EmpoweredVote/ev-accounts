# Project Research Summary

**Project:** v2026.3 Legislative Profile Data
**Domain:** Civic tech — legislative activity enrichment for existing politician profiles
**Researched:** 2026-03-01
**Confidence:** MEDIUM-HIGH (federal: HIGH; state: MEDIUM; local: LOW)

## Executive Summary

This milestone adds legislative activity data — committees, voting records, sponsored legislation, and leadership positions — to existing politician profiles in the Empowered Vote platform. The domain is well-understood at the federal level: Congress.gov API v3, the unitedstates/congress-legislators YAML dataset, and LegiScan together provide comprehensive, free-tier coverage for all federal officials. The recommended approach is a hybrid write model — static data (committee assignments, leadership) loaded via import CLI, dynamic data (bills, votes) cached via lazy-fetch goroutine on first profile view — extending the platform's existing candidacy data pattern cleanly. All APIs required are free; no new paid infrastructure is needed.

The central risk is that data availability, quality, and structure vary dramatically by government level. Federal data is rich and structured. State data (Indiana, California) is viable via LegiScan as primary source, with Open States as a verification layer. Local data is the weak point: Bloomington Common Council has no machine-readable vote data (PDF minutes only), and LA County Board of Supervisors Legistar provides legislative matters but not individual member vote attribution. The roadmap must scope local features to what is actually achievable — committee assignments via HTML scraping — and treat local voting records as deferred. Planning that assumes uniform coverage across federal/state/local will produce empty tables and misleading profile sections.

A second critical risk is the Congress.gov API: it silently truncates results at 250 per request (no error, just missing data), was subject to a confirmed outage in January 2026, and requires separate API calls for each sub-resource, creating N+1 request patterns. The import client must implement exhaustive pagination, token bucket rate limiting (4,500 req/hr), and incremental update logic from the first version. Lazy-fetch is appropriate for bills and lower-volume data but not for federal voting records — a two-term senator has 8,000-12,000 roll calls, which would time out a profile page request. Federal votes must be pre-imported via CLI batch job before any profile-serving code is written.

## Key Findings

### Recommended Stack

The existing Go + Python stack requires only minimal additions. Two new Go packages are needed: `github.com/goccy/go-yaml v1.18.0` for parsing congress-legislators YAML (the previously standard `gopkg.in/yaml.v3` is archived and must not be used) and `golang.org/x/time` (already transitively present) for rate limiting the Congress.gov client. On the Python side, one new package — `scraper-legistar` — handles LA County Board of Supervisors via the Legistar platform. No new npm packages are needed for the frontend; existing Tailwind CSS utilities and the ev-ui component pattern cover all new profile section UI.

All legislative data lives in the existing `internal/essentials/` Go package, not a new module. New tables use the `essentials` PostgreSQL schema with a `legislative_` prefix, keeping schema boundaries clean without the overhead of a new Go package and schema. All external API costs are zero: Congress.gov (5,000 req/hr free), Open States (free tier, limits not enforced), LegiScan (30,000 req/month free), and both local sources (public, no auth required).

**Core technologies:**
- Congress.gov API v3 + `net/http` stdlib: federal bills, House roll call votes, committee data — official LoC source, free, 5K req/hr
- unitedstates/congress-legislators YAML + `goccy/go-yaml v1.18.0`: federal committee membership, leadership roles — more complete than API, zero API budget, daily updates
- LegiScan API (Python, `requests`): Indiana + California state bills, votes, committees — primary state source, 30K req/month free, consistent schema
- Open States API v3 (Python, `requests`): state data verification layer — consistent schema but uneven quality and scraper outage risk
- `scraper-legistar` (Python): LA County Board of Supervisors legislation via Legistar — purpose-built for Granicus' partial-JSON/HTML interface
- `golang.org/x/time/rate`: token bucket rate limiter for Congress.gov client — enforce 4,500 req/hr ceiling during bulk imports

**Critical avoid:** Do not use `gopkg.in/yaml.v3` (archived 2025), `pyopenstates` (data model conflicts), `sigs.k8s.io/yaml` (wraps archived package), ProPublica Congress API (shut down), GovTrack bulk data (deprecated), or any Go HTTP client library (stdlib `net/http` is sufficient and consistent with existing codebase).

### Expected Features

The feature landscape is tiered by data availability, not by political level. Federal features are full-fidelity. State features are viable but require LegiScan as primary (not Open States). Local features are limited to committee assignments and legislation tracking only — individual vote attribution is not achievable from any structured source for this milestone.

**Must have (table stakes):**
- Data model foundation (legislative_sessions, committees, committee_memberships, bills, bill_cosponsors, votes tables) — prerequisite for all other features; schema must be designed from data inventory, not from aspirational coverage
- Committee assignments with roles (chair/vice-chair/ranking member/member) — expected by any civics-aware user; core accountability signal
- Leadership positions (speaker, majority leader, whip, committee chair) — signals influence at a glance; data available via congress-legislators YAML
- Sponsored legislation (current + previous session) — "what has this person tried to pass?"; highest user-value civic data
- Voting record (roll calls only, current + previous session) — most-requested civic feature; federal and state only at this milestone
- Frontend profile sections with graceful empty states — sections hidden when data unavailable (local officials), not shown as broken placeholders

**Should have (competitive differentiators):**
- Plain-language bill summaries (federal CRS summaries only, ~30-40% bill coverage) — usability win for cryptic bill titles; graceful fallback to short title when unavailable
- Significance filter on bills — default to bills that advanced past introduction; prevents profile from showing 200 stalled bills as the dominant content
- Session filter UI — toggle current vs. prior session; pure frontend filter on already-fetched data
- Committee chair/leadership badge — visual indicator distinguishing members from leaders; zero data cost once committee roles are captured

**Defer to later milestone:**
- Vote alignment / party-line percentage — computable from roll-call data, but requires complete roll-call coverage first; validate data stability before building derived metrics
- Bill topic tags for state/local — Congress.gov subjects work well for federal; state varies; local has none
- Notable / curated key votes — requires editorial workflow; high content labor; introduces bias risk
- Historical voting records beyond 2 sessions — DB size concern; start narrow and expand based on demand
- All LA City Council voting records — separate entity from LA County BOS, different Legistar instance, no structured vote API
- Local voting records via PDF extraction — Bloomington minutes are PDFs with no individual attribution; high effort, low reliability

### Architecture Approach

The milestone uses a hybrid write model within the existing `internal/essentials/` package. Static data (committee assignments, leadership) is imported via new CLI subcommands that parse YAML or call APIs and upsert into the database — run once per session boundary, not request-triggered. Dynamic data (bills, votes) is fetched by background goroutines triggered on first profile view, extending the existing lazy-fetch pattern from candidacy data. The critical exception is federal voting records, which must be pre-imported via CLI batch job due to volume (8,000-12,000 votes per senator makes lazy-fetch impractical). The frontend makes parallel sub-resource requests after the main profile loads, each with independent loading state and conditional rendering.

**Major components:**
1. Congress.gov API client (`internal/essentials/legislation/congress.go`) — rate-limited (4,500 req/hr via token bucket), exhaustive pagination (250/page, `len(items) < limit` stop condition), incremental update via `fromDateTime`; feeds bill and vote upserts
2. Import CLI subcommands (`import-committees`, `import-leadership`, `import-federal-votes`) — run at session boundaries; dependency-ordered (sessions → committees → bills → votes) to prevent FK violations; never triggered by HTTP requests
3. Seven new GORM models in `essentials/models.go` — `LegislativeSession`, `LegislativeCommittee`, `LegislativeCommitteeMembership`, `LegislativeLeadershipRole`, `LegislativeBill`, `LegislativeBillCosponsor`, `LegislativeVote`; all in `essentials` schema with `legislative_` prefix
4. ID bridge table (`legislative.politician_id_map`) — maps `bioguide`, `ocd_person`, `legiscan`, `legistar` IDs to `essentials.politicians.id`; must be populated before any data import to prevent orphaned records
5. Five new API endpoints under `/essentials/politician/{id}/` — committees, leadership, bills, votes, plus a combined `legislative-summary` for frontend initial render (one request, returns recent 5 bills + 10 votes)
6. `LegislativeActivity` section in `ev-ui/PoliticianProfile.jsx` — conditionally rendered per data availability; hides entirely for local officials with no data; parallel fetch calls in `Profile.jsx` with independent loading states

### Critical Pitfalls

1. **Over-engineering schema for jurisdictions that have no data** — designing the full 6-table schema from the Congress model before inventorying what Bloomington/LA County actually export leads to empty tables from day one and cascading FK migration complexity. Invert build order: data inventory first, schema second. Add tables only when data is confirmed available. Detection: after first import, any legislative table with 0 rows signals premature infrastructure.

2. **Congress.gov API pagination silently truncates at 250** — passing `limit=500` returns 250 with HTTP 200 and no error. The `total` field was removed from the API. Always use `len(items) < limit` as the stop condition. Implement exhaustive pagination in the first version of the client — do not add as a fixup after noticing missing data. Rate limit budget: a full session import of 535 members × multiple sub-resources takes 2-3 hours; plan for a background CLI job, not a one-time quick import.

3. **Legislator identity matching breaks without an ID bridge table** — each source uses different IDs (bioguide, OCD-ID, LegiScan people_id, Legistar PersonId, name-only for Bloomington). Building the `legislative.politician_id_map` bridge table before any import run is mandatory. Orphaned data — imported but unlinked to any politician — is the most insidious failure mode: it imports silently but never appears on profiles. After import, check: `SELECT COUNT(*) FROM legislative.committee_assignments WHERE politician_id IS NULL` — any non-zero count indicates an incomplete bridge.

4. **Lazy-fetch fails for federal voting records** — a two-term senator's 8,000-12,000 roll calls require 40-48 paginated API requests at 250/page, easily exceeding Render's 30-second request timeout. Federal votes must use CLI batch import, not request-triggered goroutines. Reserve lazy-fetch for lower-volume data: committee assignments (one call per member), leadership roles, and sponsored bills (reasonably bounded).

5. **Local government vote data does not exist in machine-readable form** — Bloomington Common Council votes are in PDF meeting minutes with no individual member attribution. LA County Legistar API provides legislative matters but not member-level vote positions (manually test `webapi.legistar.com/v1/LACounty/VoteRecords` before building any integration). Scoping "local voting records" into the milestone without a feasibility check first wastes significant engineering time. Each local body requires a 2-4 hour manual data inspection before committing to a scraper.

## Implications for Roadmap

Based on combined research, a 5-phase structure is recommended, organized around data availability confidence tiers and architectural dependencies.

### Phase 1: Schema Foundation and ID Bridge

**Rationale:** Every other feature depends on the database schema and the identity mapping table. Building schema from the data inventory (not the aspirational full model) prevents empty table proliferation. The ID bridge table must precede any import — orphaned legislative data is unrecoverable without it.
**Delivers:** 7 new GORM models + AutoMigrate in `essentials/setup.go`; `legislative.politician_id_map` bridge table populated for all current federal officials using congress-legislators YAML cross-referenced against `essentials.politicians.bioguide_id`; `leg_data_fetched_at` column added to politicians table; data inventory matrix documenting what each jurisdiction (federal, Indiana, California, Bloomington, LA County) actually exports at this milestone
**Addresses:** Data model foundation (P0 feature from FEATURES.md)
**Avoids:** Pitfall 1 (over-engineered schema), Pitfall 3 (orphaned legislative data from missing ID bridge), Pitfall 13 (FK violations from wrong import order)

### Phase 2: Federal Committee Assignments and Leadership

**Rationale:** Federal data has the highest confidence and the cleanest data source — congress-legislators YAML requires no API key, no rate limits, and is updated daily. This is the fastest path to visible value on profile pages. The CLI import pattern established here becomes the template for Phase 3. Committee chair and leadership badges are purely additive once the data is imported.
**Delivers:** `import-committees` and `import-leadership` CLI subcommands; committee membership display on federal politician profiles with role badges (Chair, Ranking Member, Member); leadership position display (Speaker, Majority Leader, Whip, President Pro Tempore); `congress_number` on every assignment row with `UNIQUE(politician_id, committee_id, congress_number)` constraint for session boundary tracking
**Uses:** `github.com/goccy/go-yaml v1.18.0`, congress-legislators YAML (zero API cost)
**Implements:** Import CLI architecture component, committee + leadership API endpoint handlers
**Avoids:** Pitfall 11 (session boundary discontinuities — congress_number on every row), Pitfall 9 (name matching — bioguide_id bridge lookup, not name fallback)

### Phase 3: Federal Bills and Voting Records (Batch Import)

**Rationale:** Bills and votes are the highest user-value features but require the most careful API client implementation. Federal votes must be batch-imported — not lazy-fetched — due to volume. This phase establishes the rate-limited Congress.gov API client with exhaustive pagination, incremental update logic, and a significance filter from day one. The decision to use batch import over lazy-fetch must be made before any profile-serving code is written.
**Delivers:** Congress.gov API client (`legislation/congress.go`) with token bucket (4,500 req/hr), exhaustive pagination (`len(items) < limit`), and `fromDateTime` incremental updates; `import-federal-votes` and `import-federal-bills` CLI subcommands; voting record and sponsored legislation sections on federal politician profiles; CRS plain-language summaries where available (graceful fallback to short title); significance filter defaulting to bills that advanced past introduction; `legislative-summary` endpoint for frontend initial render
**Uses:** `golang.org/x/time/rate`, Congress.gov API v3
**Implements:** Congress.gov API client, 5 new API endpoint handlers, `LegislativeActivity` section in ev-ui
**Avoids:** Pitfall 2 (pagination truncation at 250), Pitfall 4 (lazy-fetch timeout on 8K+ votes), Pitfall 7 (bill status normalization — store raw_status + status_label; apply significance filter), Pitfall 8 (N+1 requests and rate limit exhaustion), Pitfall 12 (bill summary unavailability — fallback to short title)

### Phase 4: State Data — Indiana and California

**Rationale:** State data uses LegiScan as primary source (not Open States, which has uneven coverage and scraper outage risk). The import pattern is Python-based (existing scraper pipeline), writing directly to PostgreSQL via psycopg2. This phase extends the committee, bill, and vote display already built in Phases 2-3 to state politicians, reusing frontend components. OCD-IDs from Open States populate the bridge table for state legislators before any import.
**Delivers:** LegiScan Python import scripts for Indiana and California (bills, votes, committee assignments); OCD-IDs populated in `politician_id_map` bridge table for state legislators; state politician profiles show legislative sections using the same frontend components built in Phase 3; Open States monitoring check (`last_bill_update` freshness) documented as recurring maintenance task
**Uses:** LegiScan API (Python, 30K req/month free), Open States API v3 (bridge table population and verification)
**Implements:** State data import pipeline
**Avoids:** Pitfall 5 (Open States coverage gaps and scraper outage — LegiScan as primary, Open States as verification), Pitfall 9 (name-only matching for state legislators — OCD-IDs in bridge table)

### Phase 5: Local Data — Committees and Legislation Only (Feasibility-Gated)

**Rationale:** Local data is the most uncertain. Each body requires a feasibility check (2-4 hours manual inspection) before any scraper is built. This phase commits only to committee assignments (available via HTML scraping) and legislation/matter tracking (Legistar API for LA County). Individual vote attribution for local officials is explicitly out of scope — confirmed infeasible from any structured source.
**Delivers:** HTML scrapers for Bloomington Common Council and LA County Board of Supervisors committee assignments; LA County Legistar Web API integration for matter/legislation tracking (not vote attribution); local politician profiles show committee sections; voting record section omitted or shows "not available for this jurisdiction" message; feasibility check documented for Bloomington OnBoard REST API and LA County Legistar VoteRecords endpoint
**Uses:** `scraper-legistar` (verify last commit date before adopting), `requests` + BeautifulSoup for Bloomington HTML
**Implements:** Local government data pipeline (scope-limited)
**Avoids:** Pitfall 6 (local vote data does not exist — scope to committees and matter tracking only), Pitfall 10 (Legistar token requirement — validate with manual curl test before building)

### Phase Ordering Rationale

- Schema and ID bridge must come first — all 4 data phases depend on it; orphaned imports are unrecoverable without the bridge
- Federal data before state before local — confidence decreases with each tier; establishing federal patterns first reduces risk in later phases
- CLI batch import (committees, leadership) before lazy-fetch (bills, votes) — simpler pattern first; validates schema before adding goroutine complexity
- Federal votes use batch import, not lazy-fetch — this architectural decision must precede writing any of `Profile.jsx` or the vote endpoint handler; changing it after is a significant rewrite
- Local phase gated on feasibility checks — ensures no empty tables or misleading profile sections from aspirational features

### Research Flags

Phases needing deeper research during planning:
- **Phase 3 (Federal Bills/Votes):** Congress.gov API rate limit behavior under concurrent imports not empirically tested for this codebase — validate token bucket implementation with actual API calls before scheduling a full session import
- **Phase 4 (State Data):** Open States scraper health monitoring approach needs a concrete implementation decision — polling `/states/` endpoint freshness vs. manual spot-check cadence; LegiScan person ID lookup pattern for state legislators not yet validated against actual IN/CA data
- **Phase 5 (Local Data):** Bloomington OnBoard REST API endpoint documentation not confirmed — requires direct validation against `data.bloomington.in.gov` before any scraper design; LA County Legistar token requirement requires manual curl test (`webapi.legistar.com/v1/LACounty/VoteRecords`) before committing to integration approach; `scraper-legistar` last commit date must be checked before adoption

Phases with well-documented standard patterns (skip research-phase):
- **Phase 1 (Schema):** GORM AutoMigrate pattern is established and well-understood in this codebase; congress-legislators YAML bioguide cross-reference is straightforward
- **Phase 2 (Federal Committees/Leadership):** congress-legislators YAML structure is fully documented; `goccy/go-yaml` API is stable; import CLI subcommand pattern matches existing `import-stances`, `import-quotes` subcommands exactly

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All APIs confirmed active with official documentation; library choices verified against official sources; `gopkg.in/yaml.v3` deprecation confirmed via multiple community sources |
| Features | HIGH (federal), MEDIUM (state), LOW (local) | Federal feature-data alignment is strong and verified. State coverage confirmed via LegiScan docs + Open States community. Local vote data confirmed unavailable from any structured source via manual site inspection. |
| Architecture | HIGH | Based on direct inspection of existing codebase patterns; lazy-fetch pattern already implemented for candidacy data in `handlers.go`; CLI import pattern established via existing `import-stances` subcommand |
| Pitfalls | HIGH (Congress.gov mechanics), MEDIUM (state coverage gaps), LOW (local data specifics) | Congress.gov pitfalls verified against official GitHub changelog and LoC rate limit docs. State pitfalls from community discussion and official docs. Local pitfalls from website inspection, not programmatic testing. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Bloomington OnBoard REST API endpoints:** Not confirmed via programmatic testing. Validate `data.bloomington.in.gov` API before Phase 5 planning. Fallback: HTML scraping of council website — but individual vote data remains unavailable regardless of scraping approach.
- **LA County Legistar token requirement:** Manually test `webapi.legistar.com/v1/LACounty/VoteRecords` with curl before Phase 5. If authentication required and token not available, matter-level data from Legistar Web API may be the practical ceiling.
- **`scraper-legistar` maintenance status:** Verify last commit date on `opencivicdata/python-legistar-scraper` before adopting. If unmaintained, fall back to direct Legistar Web API calls (OData v3 URL conventions).
- **Open States v3 rate limit enforcement:** Marked "TBD" in community discussions as of March 2026. For this milestone's data volume (2 states, ~200 legislators), it will not matter — but monitor when v3 moves to enforced limits.
- **Congress.gov API reliability post-January 2026 outage:** The API restored after its outage, but Library of Congress budget risk under DOGE-era cuts remains cited in reporting. Import CLI must log failures and degrade gracefully — never block profile rendering on API availability.
- **Significance filter thresholds for bill display:** After first federal import, validate what percentage of sponsored bills are "introduced" status only. Calibrate the default filter cutoff based on actual data distribution — a senator who sponsored 180 introduced-and-died bills plus 12 that passed should show 12 by default.
- **Senate roll call votes source:** Congress.gov API v3 confirmed does NOT include Senate votes as of March 2026. For Senate voting records, LegiScan covers US Congress including Senate — verify coverage before committing to a source strategy.

## Sources

### Primary (HIGH confidence)
- [Congress.gov API v3 — Library of Congress](https://www.loc.gov/apis/additional-apis/congress-dot-gov-api/) — endpoint coverage, rate limits
- [Congress.gov API ChangeLog](https://github.com/LibraryOfCongress/api.congress.gov/blob/main/ChangeLog.md) — pagination behavior (250 max, `total` field removed), House roll call votes added May 2025
- [Introducing House Roll Call Votes in the Congress.gov API](https://blogs.loc.gov/law/2025/05/introducing-house-roll-call-votes-in-the-congress-gov-api/) — confirmed out of beta
- [Congress.gov API January 2026 outage](https://www.govtech.com/gov-experience/congress-govs-api-has-gone-dark-impacting-data-access) — outage event confirmed
- [Library of Congress API rate limits](https://www.loc.gov/apis/json-and-yaml/working-within-limits/) — 5,000 req/hr, 100K deep paging limit
- [unitedstates/congress-legislators — GitHub](https://github.com/unitedstates/congress-legislators) — YAML structure, bioguide/thomas/govtrack/fec IDs, daily update cadence
- [goccy/go-yaml — GitHub](https://github.com/goccy/go-yaml) — v1.18.0 stable, actively maintained
- [gopkg.in/yaml.v3 archived discussion](https://github.com/go-task/task/issues/2171) — archived/unmaintained status confirmed
- [LegiScan API User Manual v1.91 (2025-03-17)](https://api.legiscan.com/dl/LegiScan_API_User_Manual.pdf) — 30K free queries/month, person ID system, Indiana + California coverage
- [golang.org/x/time/rate — pkg.go.dev](https://pkg.go.dev/golang.org/x/time/rate) — stdlib extension, stable, already transitively in go.sum

### Secondary (MEDIUM confidence)
- [Open States API v3 Documentation](https://docs.openstates.org/api-v3/) — endpoint coverage for Indiana + California
- [Open States rate limit discussion](https://github.com/openstates/issues/discussions/205) — v3 limits marked "TBD", not yet enforced
- [Ballotpedia Open States Legislative Data Report Card](https://ballotpedia.org/Open_States%27_Legislative_Data_Report_Card) — per-state quality grades; California MySQL dump complexity
- [opencivicdata/python-legistar-scraper — GitHub](https://github.com/opencivicdata/python-legistar-scraper) — LA County Legistar integration; verify last commit before adoption
- [LA County Legistar portal](https://lacounty.legistar.com/) — confirmed Granicus platform
- [Legistar Web API](https://webapi.legistar.com/) — OData v3 structure; matters endpoint; client-specific token requirements
- [GovTrack.us](https://www.govtrack.us/start) — competitive feature patterns (ideology score, party-line %, committee display)
- [VoteSmart](https://www.votesmart.org/) — six-domain profile structure reference
- [Ballotpedia](https://ballotpedia.org/Main_Page) — committee, leadership, scorecard display patterns
- [LegiScan product site](https://legiscan.com/legiscan) — state + federal bill/vote data model; pricing tiers

### Tertiary (LOW confidence — requires direct validation before Phase 5)
- [City-of-Bloomington/OnBoard — GitHub](https://github.com/City-of-Bloomington/OnBoard) — system confirmed; REST API endpoints not documented in search results
- [Bloomington Open Data](https://data.bloomington.in.gov/) — portal exists; legislative vote data availability not confirmed programmatically
- [LA County BOS Records](https://bos.lacounty.gov/services/records-of-the-board/) — Statement of Proceedings confirmed; individual vote attribution in Legistar API not confirmed
- [OCD-ID standard](https://medium.com/cicero-data/how-to-use-open-civic-data-identifiers-to-organize-political-data-c27755702509) — OCD-IDs designed as stable cross-source identifiers; used by Open States and existing geofence schema

---
*Research completed: 2026-03-01*
*Ready for roadmap: yes*
