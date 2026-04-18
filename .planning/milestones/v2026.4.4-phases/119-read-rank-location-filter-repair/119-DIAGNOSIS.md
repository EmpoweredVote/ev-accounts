# Phase 119 Diagnosis

**Date:** 2026-04-16
**Diagnostician:** Claude (inline execution)

## Layer 1: DB Data

- Monroe County politicians with quotes: **5 confirmed** — David G Henry (22), Trent Deckard (16), Matt Pierce (10), Mike Braun (2 via state/federal overlap), Micah Beckwith (1)
- Topic_key match status: **ALL MATCHED** — 29 unique topic_key entries, zero DROPPED rows. Every quote has a valid `inform.compass_topics` match via `lower(q.topic_key)`.
- Null politician_id count: **0**
- Finding: **DATA_OK**

## Layer 2: API / CORS

- Address search (`POST /essentials/candidates/search` with "401 N Morton St, Bloomington, IN 47404"):
  - HTTP status: **200**
  - CORS header present: **yes** (`Access-Control-Allow-Origin: https://readrank.empowered.vote`)
  - Politician count: **105** (full Monroe County geofence match including federal/state/local)
- Quotes endpoint (`GET /essentials/quotes`):
  - HTTP status: **200**
  - CORS header present: **yes** (`Access-Control-Allow-Origin: https://readrank.empowered.vote`)
  - Quote count: **157**, Candidate count: **15**, Issue count: **24**
  - Sample candidateIds: `db4e6911` (Deckard), `72dd5219` (Pierce), `0be7d42f` (Henry)
- Finding: **API_OK**

## Layer 3: API URL

- render.yaml `VITE_API_URL`: `https://accounts-api.empowered.vote` ✅
- .env.production `VITE_API_URL`: `https://ev-accounts-api.onrender.com` ⚠️ STALE — differs from render.yaml
- auth.ts `API_BASE`: `import.meta.env.VITE_API_URL + "/api"` (dynamic, uses env var at build time)
- `accounts-api.empowered.vote` resolves: **yes**, HTTP 200 from `/api/health`
- `api.empowered.vote` also resolves: **yes**, HTTP 200 — both are valid
- Render env vars take precedence over `.env.production` at build time, so production uses the correct URL
- Finding: **URL_OK** (minor: `.env.production` is stale but non-blocking since Render env vars win)

## Layer 4: Frontend Predicate

- `q.issue` format: **topic_key slug** (e.g., "deportation", "abortion") — matches `issue.id` which is also keyed by `topic_key`
- `q.candidateId` format: **politician UUID** (e.g., `db4e6911-9dbb-430e-831c-08be094fd637`)
- ID intersection between search results (105 IDs) and quotes (15 candidateIds): **5 politicians overlap**
  - Mike Braun, Matt Pierce, Trent Deckard, David G Henry, Micah Beckwith
- Filter simulation (Monroe County address, ≥2 local reps per issue): **10 issues pass**
  - Deportation (4 reps), Abortion (4), Homelessness (3), Trans Athletes (3), Housing (2), Jail Capacity (2), Civil Rights (2), Redistricting (2), Same-Sex Marriage (2), Religious Freedom (2)
- Finding: **PREDICATE_OK**

## Root Cause Summary

**No code bug found.** All 4 layers are functioning correctly:

1. DB has Monroe County politician quotes with correct topic_key linkage
2. API endpoints return correct data with proper CORS headers for readrank.empowered.vote
3. Production API URL resolves correctly
4. Frontend predicate correctly intersects politician IDs with quote candidateIds

The reported "filter not working" was most likely caused by one of:
- Testing with an address outside Monroe County (no local quotes → empty results with no feedback)
- Missing zero-state UX (D-06) — when the filter returns 0 qualifying issues, the user sees a blank list with no explanation or way to clear the filter, making it appear "broken"

**Confidence: HIGH** — simulation confirmed 10/24 issues pass for Monroe County address.

## Fix Prescription

Plan 02 should implement **only the zero-state empty message (D-06)** and clean up the stale `.env.production`:

### Required Changes

1. **`read-rank/src/components/IssueHub.tsx`** — Add zero-state empty message:
   - Add `clearLocationFilter` to store destructure (line 37)
   - Insert zero-state block between AddressFilterInput section and Issue Cards section
   - Renders when `locationFilter !== null && displayedIssues.length === 0`
   - Shows "No issues with local quotes for this area" heading
   - Shows "We don't have quotes from your representatives for any issues yet." body
   - Shows "Clear location filter" button wired to `clearLocationFilter()`

2. **`read-rank/.env.production`** — Update stale URL:
   - Change `VITE_API_URL=https://ev-accounts-api.onrender.com` to `VITE_API_URL=https://accounts-api.empowered.vote`
   - Non-blocking (Render env vars already override) but reduces confusion for local `npm run build` testing

### No Changes Needed
- No CORS fix needed — `readrank.empowered.vote` is already in the CORS allow list
- No DB migration needed — all topic_keys match correctly
- No API endpoint changes needed — both search and quotes endpoints return correct data
- No `AddressFilterInput.tsx` changes needed — component is fully functional
- No `api.ts` changes needed — `fetchQuotesData` and `searchPoliticians` both work
