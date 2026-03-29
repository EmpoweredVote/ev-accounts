# Stack Research

**Project:** v2026.3.8 Essentials Election Central
**Domain:** Election/candidate data integration — Election Central page + elected/appointed filter
**Researched:** 2026-03-29
**Confidence:** MEDIUM — election APIs verified from official docs and community; state SOS machine-readable availability is LOW confidence for Indiana local races

---

## Context: What Is and Is Not New

This document covers **only what is new for v2026.3.8**. The prior STACK.md (v2026.3.7) covers Treasury Tracker.

**Existing stack — do not re-research or reinstall:**
- React 19 + Vite 7 + Tailwind CSS 4 + react-router-dom ^7.8.2 (essentials app)
- Express 4 + TypeScript + Node.js 20 native `fetch()` (ev-accounts backend)
- Supabase PostgreSQL + PostGIS (existing `essentials.*` schema)
- `@chrisandrewsedu/ev-ui ^0.1.53` — PoliticianCard, PoliticianProfile reusable for candidates
- Google Maps Places autocomplete (already wired for address input)
- `essentials.election_records` table — already exists with election_name, election_date, position_name, result, party_name, is_primary, is_runoff, is_active columns
- `is_appointed_position` on `essentials.offices` — `is_elected` already derived as `!row.is_appointed_position` in `essentialsService.ts`
- `is_incumbent` — already in use across `essentialsService.ts`; not a stored column but included in existing queries

---

## Election Data APIs — Research Findings

### Primary Recommendation: Google Civic Information API

**Status:** Active and free as of 2026-03. **The Representatives API was shut down April 30, 2025** — do not use it. The Elections API (`voterInfoQuery`) is still active.

**Base URL:** `https://www.googleapis.com/civicinfo/v2`

**Key endpoints:**
- `GET /elections` — returns list of supported upcoming elections with `id`, `name`, `electionDay`
- `GET /voterinfo?address=<addr>&electionId=<id>` — returns contests, candidates, polling info for a voter address

**Contest data returned per call:**
- `contests[]`: `office`, `level` (`country` / `administrativeArea1` / `administrativeArea2` / `locality`), `district.name`, `district.scope`, `type` (`General` / `Primary` / `Retention` / `Runoff` / `Referendum`)
- `candidates[]` per contest: `name`, `party`, `candidatesUrl`, `photoUrl`, `phone`, `email`, `channels[]` (social media)

**Authentication:** API key via query param `?key=<KEY>`. Free, register at Google Cloud Console.

**Rate limit:** 25,000 requests/day, 2,500/100 seconds — sufficient for Election Central (one call per address per election, cached 24 hours).

**Coverage caveat:** Data published 2-4 weeks before election day via the Voting Information Project. Indiana primary (May 5, 2026) and general (Nov 2026) plus California primary (June 2, 2026) should be covered for state + federal races. Bloomington city council local races may not be covered — VIP data coverage depends on county cooperation with the project.

**New env var needed:** `GOOGLE_CIVIC_API_KEY` — add to ev-accounts `.env` and Render environment.

### Secondary Recommendation: FEC OpenAPI (Federal Only)

**Use for:** Federal candidate incumbency verification (House, Senate) — more authoritative than Google Civic for incumbency status.

**Base URL:** `https://api.open.fec.gov/v1`

**Key endpoint:** `GET /candidates/?state=IN&election_year=2026&office=H&api_key=<KEY>`

**Authentication:** Free API key from https://api.data.gov/signup/

**Rate limit:** 1,000 req/hour (free tier) — sufficient for batch incumbency verification.

**Coverage:** Federal candidates only. Not useful for state or local races.

**New env var needed:** `FEC_API_KEY`

### Not Recommended: Commercial APIs (Budget Constraint)

**BallotReady/CivicEngine GraphQL API** — Comprehensive US candidate data including Indiana and California local races. GraphQL schema well-suited to race/candidate queries. Pricing requires contact; likely $1,000–$5,000/year for nonprofits. Do not pursue unless the Google Civic API proves insufficient and budget is allocated.

**Ballotpedia API** — Geographic point-based queries, incumbency data, biographies. Pricing not public; contact required. Same recommendation as BallotReady — defer unless budgeted.

### Not Recommended: State SOS APIs

**Indiana SOS** — No machine-readable API for candidate filings. Data available as PDFs and web pages only. The 2026 primary candidate list is accessible via indianacitizen.org as an interactive table, but has no stable CSV download endpoint. Bloomington/Monroe County local races require manual data entry.

**California SOS / CAL-ACCESS** — The Election Night Reporting API at `api.sos.ca.gov` covers only election night results, not pre-election candidate data. CAL-ACCESS covers statewide candidate filings (Form 501) only — not LA city council or county supervisor races. Not useful for upcoming race discovery.

**OpenElections** — Historical results only (post-election CSVs). Not useful for upcoming races.

**Democracy Works Elections API** — Focused on voting logistics (polling places, registration deadlines), not candidate data. Pricing opaque.

---

## Recommended Stack — New Additions Only

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Google Civic Information API | v2 (current) | Primary source for election contest + candidate data | Free, 25K req/day, returns grouped contests by level and district, covers Indiana and California state/federal races, still active (only Representatives API was retired) |
| FEC OpenAPI | v1 (current) | Federal candidate incumbency verification | Free, authoritative for federal incumbency, already fits pattern of external API clients in ev-accounts (same `fetch()` + AbortSignal pattern) |

### Supporting Libraries

No new npm packages needed. The entire feature is implementable with the existing stack:

| Existing Tool | Reused For |
|---------------|------------|
| Native `fetch()` (Node.js 20) | Backend HTTP calls to Google Civic API + FEC API — same pattern as `geocodingService.ts` and `indianaAdapter.ts` |
| `cache.ts` (ev-accounts) | Cache election contest responses — 24h TTL per address per election |
| `zod` (ev-accounts) | Validate Google Civic API response shape before DB write |
| `react-router-dom ^7.8.2` | New `/elections` route in essentials app |
| Tailwind CSS 4 | Election race cards, incumbent/challenger badge styling |
| `@chrisandrewsedu/ev-ui ^0.1.53` | PoliticianCard for candidate display; may need minor badge variant extension |
| Existing staging workflow | Manual data entry for Monroe County local races with no API coverage |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Google Civic API `electionQuery` | Discover available election IDs before querying voter info | Run once to find `electionId` values for IN/CA primaries and generals |
| Existing `backend/migrations/` | Schema extension for new elections table + race_id column | Follow established migration pattern (numbered SQL files) |

---

## Installation

```bash
# No new packages — everything is already installed

# New env vars to add to ev-accounts .env:
# GOOGLE_CIVIC_API_KEY=<from Google Cloud Console>
# FEC_API_KEY=<from api.data.gov/signup>
```

---

## Schema Extensions (New Migration Needed)

The existing `essentials.election_records` table is oriented around a politician's participation in a past election. Election Central needs to model **future races with multiple candidates**. Two additions are needed:

**New table: `essentials.elections`**
```sql
CREATE TABLE essentials.elections (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  election_name   TEXT NOT NULL,
  election_date   DATE NOT NULL,
  state           CHAR(2) NOT NULL,
  external_id     TEXT,          -- Google Civic electionId
  is_active       BOOLEAN NOT NULL DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);
```

**New columns on `essentials.election_records`:**
```sql
ALTER TABLE essentials.election_records
  ADD COLUMN IF NOT EXISTS elections_id    UUID REFERENCES essentials.elections(id),
  ADD COLUMN IF NOT EXISTS race_id         TEXT,    -- groups candidates in same race
  ADD COLUMN IF NOT EXISTS is_incumbent    BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS data_source     TEXT;    -- 'google_civic', 'fec', 'manual'
```

This approach reuses the existing `election_records` table (which already has `politician_id`, `election_date`, `party_name`, `position_name`, `is_active`) and adds grouping + incumbency columns needed for Election Central.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|------------------------|
| Google Civic API (free) | BallotReady/CivicEngine GraphQL | If budget allows ~$1,000–5,000/year and comprehensive local race coverage (including Bloomington city council) is required without manual data entry |
| Google Civic API (free) | Ballotpedia API | Same condition — budget allocated and richer candidate biography data needed |
| Manual staging entry for IN local races | Scraping Indiana Citizen / SOS web pages | Web scraping is brittle; staging workflow already exists and is proven; local Bloomington races are manageable in volume |
| Extend `essentials.election_records` | New `essentials.races` + `essentials.race_candidates` tables | A fully normalized race schema is cleaner long-term but overkill for MVP; extending election_records is faster and preserves existing data |
| Native `fetch()` for API calls | `node-fetch` or `axios` | No reason to add a dep; Node.js 20 fetch is stable and already used throughout the backend |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Google Civic API Representatives API | Shut down April 30, 2025 — returns errors | Already replaced by PostGIS geofence flow in v1.5 |
| `BALLOTREADY_API_KEY` | Decommissioned in v1.5 per PROJECT.md; all infrastructure removed | Google Civic API voterInfoQuery |
| OpenElections | Historical results CSV only — no upcoming race data | Google Civic API |
| California SOS `api.sos.ca.gov` | Election night results only, not pre-election candidate discovery; returned 403 on direct access | Google Civic API voterInfoQuery |
| CAL-ACCESS for LA races | Statewide Form 501 filings only — LA city council and county supervisor candidates not included | Google Civic API with lat/lng for LA area |
| Indiana SOS web scraping | No stable machine-readable format; brittle to layout changes | Manual staging entry for local races |
| Democracy Works Elections API | Pricing opaque; focused on voter logistics not candidate data | Google Civic API for contests |

---

## Stack Patterns for Election Central Implementation

**Fetching election contests (primary flow):**
1. User enters address on Election Central page (same Google Maps autocomplete component as Results page)
2. Backend geocodes via existing Census Geocoder (already in `geocodingService.ts`) to get lat/lng
3. Backend calls `GET /civicinfo/v2/elections` to get active election IDs
4. For each upcoming election, call `GET /civicinfo/v2/voterinfo?address=<addr>&electionId=<id>`
5. Cache response 24 hours per `(address_hash, election_id)` key using existing `cache.ts`
6. Merge Google Civic contest data with manually-entered DB races (DB wins on conflict — same pattern as politician data pipeline)
7. Return grouped contest list via `GET /api/essentials/elections?lat=X&lng=Y`

**Elected/appointed filter toggle:**
- `is_elected` is already derived in `essentialsService.ts` as `!row.is_appointed_position`
- Frontend filter: add `filter` query param (`elected` / `appointed` / `all`) to existing `GET /api/essentials/search`
- Backend: add `AND` clause using existing `is_appointed_position` field
- Retention judges: query param `include_retention=true` or treat `partisan_type = 'retention'` as a special case shown under both filters

**Race-by-race display grouping:**
- Group by `level` hierarchy: Federal → State → Local (same tier system as Results page)
- Within level, group by `district` or `office`
- Within race: incumbent card first with "Incumbent" badge (ev-coral chip), then challenger cards in party-neutral order
- Use existing `PoliticianCard` from ev-ui for candidate cards — extend with optional `badge` prop if not already present

**Candidate profile pages:**
- Reuse existing `Profile.jsx` + `PoliticianProfile` from ev-ui
- Candidates that exist in `essentials.politicians` (marked `is_incumbent = false`) already render correctly
- Non-incumbent challengers who are NOT in the essentials DB need a lightweight candidate record created via the staging workflow before they appear on profiles

---

## Version Compatibility

| Package | Version | Notes |
|---------|---------|-------|
| react-router-dom | ^7.8.2 | Already installed; add `/elections` route without changes |
| Tailwind CSS | ^4.1.12 | Already installed; no config changes needed |
| `@chrisandrewsedu/ev-ui` | ^0.1.53 | Already installed; `PoliticianCard` and `PoliticianProfile` reusable; may need `badge` prop for incumbent indicator |
| Node.js fetch() | Node 20 built-in | No version change; `AbortSignal.timeout()` pattern already used in `geocodingService.ts` |

---

## Sources

- [Google Civic Information API — Official Docs](https://developers.google.com/civic-information/docs/v2) — HIGH confidence; voterInfoQuery active as of 2025
- [Google Civic API voterInfoQuery Fields](https://developers.google.com/civic-information/docs/v2/elections/voterInfoQuery) — HIGH confidence; candidate fields confirmed: name, party, candidatesUrl, photoUrl, phone, email, channels
- [Google Civic API Representatives API Turndown Notice](https://groups.google.com/g/google-civicinfo-api/c/9fwFn-dhktA) — HIGH confidence; Representatives API shut down April 30, 2025; Elections API still active
- [Google Civic API Rate Limits](https://groups.google.com/g/google-civicinfo-api/c/1H7WZ0lG594) — MEDIUM confidence (community forum); 25,000/day confirmed
- [Voting Information Project Election Coverage](https://www.votinginfoproject.org/election-coverage) — MEDIUM confidence; data available 2-4 weeks before election; specific IN/CA state coverage not itemized on the page
- [FEC OpenAPI Documentation](https://api.open.fec.gov/developers/) — HIGH confidence; free federal candidate API; API key via api.data.gov
- [BallotReady/CivicEngine API](https://organizations.ballotready.org/ballotready-api) — MEDIUM confidence; GraphQL, comprehensive coverage, pricing requires contact
- [Ballotpedia API Developer Portal](https://developer.ballotpedia.org/geographic-apis/elections_by_point) — MEDIUM confidence; geographic point queries return races + candidates; pricing requires contact
- [California SOS Election Night API](https://api.sos.ca.gov/) — LOW confidence; returned 403; documented in CA SOS PDF guide as REST JSON/CSV for election night results only
- [CAL-ACCESS California Candidate Filings](https://cal-access.sos.ca.gov/Campaign/Candidates/) — HIGH confidence; statewide only; final 2026 candidate list available March 26, 2026
- [Indiana SOS Candidate Information](https://www.in.gov/sos/elections/candidate-information/) — HIGH confidence; confirmed no machine-readable API
- [Monroe County Indiana Elections 2026 — Ballotpedia](https://ballotpedia.org/Monroe_County,_Indiana,_elections,_2026) — MEDIUM confidence; confirms May 5, 2026 primary with county assessor, circuit court clerk, commissioner, council, prosecuting attorney, recorder, sheriff races
- [2026 LA County Elections — Wikipedia](https://en.wikipedia.org/wiki/2026_Los_Angeles_County_elections) — MEDIUM confidence; confirms June 2, 2026 primary; 8 of 15 LA City Council seats up; 2 of 5 LA County Supervisor seats up
- [ev-accounts `essentialsService.ts`](../ev-accounts/backend/src/lib/essentialsService.ts) — HIGH confidence; confirmed `is_incumbent`, `is_appointed_position`, `is_elected` derivation
- [ev-accounts schema export](../ev-schema-export.sql) — HIGH confidence; confirmed `essentials.election_records` existing columns and `essentials.offices.is_appointed_position`
- [essentials `package.json`](../essentials/package.json) — HIGH confidence; confirmed existing dependency list; no new packages needed

---
*Stack research for: v2026.3.8 Essentials Election Central*
*Researched: 2026-03-29*
