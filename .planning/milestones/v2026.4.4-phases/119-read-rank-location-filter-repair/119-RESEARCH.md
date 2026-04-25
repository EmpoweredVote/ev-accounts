# Phase 119: Read & Rank Location Filter Repair — Research

**Researched:** 2026-04-15
**Domain:** Full-stack filter wiring — React (read-rank frontend) + Express API (ev-accounts backend) + PostgreSQL (essentials schema)
**Confidence:** HIGH — all claims verified against source files in this session

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Root cause is unknown — research step must diagnose end-to-end before any code changes.
- **D-02:** Both address mode (Census Geocoder path) and browse mode (PostGIS browse-by-area path) must be investigated.
- **D-03:** Diagnosis must check: (a) do Monroe County politicians have quotes in the DB? (b) do API endpoints return politician IDs for a Monroe County address/area? (c) does the frontend correctly wire those IDs into the filter predicate?
- **D-04:** Keep the 2+ unique local reps threshold per issue.
- **D-05:** Issues with fewer than 2 local reps with quotes remain hidden entirely when location filter is active.
- **D-06:** Zero-matching-issues state shows "No issues with local quotes for this area" with a clear filter button — do NOT auto-clear silently.
- **D-07:** CORS/routing between readrank.empowered.vote and api.empowered.vote is unverified — must test both endpoints from readrank origin.
- **D-08:** Google Maps Places API key is confirmed configured on readrank.empowered.vote.
- **D-09:** Use the Kirkwood Ave Bloomington test address from Phase 121 MATRIX.md as the canonical test case.
- **D-10:** Final verification must happen on production (readrank.empowered.vote) after Render deploy.
- **D-11:** Both address and browse paths must be verified.

### Claude's Discretion
- Exact diagnostic commands, DB queries, and API inspection steps during investigation.
- Which layer to fix first if multiple breaks are found (suggest: data gaps first, then wiring, then frontend).
- Whether to add a defensive empty-state message in the existing code or create a new component for the zero-state UX (D-06).

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RR-03 | Monroe County location filter in Read & Rank successfully scopes quote list to Monroe County candidates | Requires: DB quotes with matching `candidateId`, API endpoints returning correct politician IDs, frontend filter predicate working correctly |
| RR-04 | Both filter mechanisms (geocoding + filter logic) functional and tested against a Monroe County address | Both address (Census Geocoder) and browse (PostGIS by-area) paths must be validated |
</phase_requirements>

---

## Summary

Phase 119 repairs the Monroe County location filter in Read & Rank end-to-end. The filter has two user-facing modes — address search (Google Places → Census Geocoder → politician IDs) and browse (State → Area dropdowns → PostGIS intersection) — and a frontend predicate that uses the returned politician IDs to scope the issue list. Any one of three independent layers could be the failure point: (1) missing DB data (Monroe County politicians have no quotes, or quotes have no `candidateId`), (2) broken API wiring (endpoints return empty or CORS-blocked), or (3) broken frontend wiring (IDs not reaching the filter predicate). The canonical context files have been read in full, and the code is well-understood.

The most likely root cause is **data gap**: the `essentials.quotes` table stores quotes with `politician_id` and `topic_key`, but the quotes endpoint JOIN on `inform.compass_topics.topic_key` means any quote whose `topic_key` does not match a compass topic is silently dropped. If Monroe County politicians lack quotes in the DB entirely, both filter paths return politician IDs correctly but the filter predicate finds zero qualifying issues — appearing broken. The diagnosis must start with a DB query before touching code.

The zero-state UX (D-06) is a net-new component specified in detail in the UI-SPEC. All other changes are diagnostic and wiring repairs only.

**Primary recommendation:** Run the DB data audit first (diagnostic SQL query), then CORS check, then frontend filter predicate inspection — in that order. Fix whichever layer is broken; the frontend zero-state is always needed regardless of which layer is fixed.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Quote data existence (Monroe County politicians have quotes) | Database / Storage | — | `essentials.quotes` table; no quotes = filter always returns empty |
| topic_key JOIN validity | Database / Storage | API / Backend | Quotes silently dropped if topic_key doesn't match compass_topics |
| Address geocoding | API / Backend | External (Census Geocoder) | `POST /essentials/candidates/search` calls Census Geocoder internally |
| Browse area politician lookup | API / Backend | Database / Storage | `POST /essentials/browse/by-area` runs PostGIS ST_Intersects |
| CORS between readrank origin and API | API / Backend | — | `CORS_ORIGIN` env var on ev-accounts; missing readrank origin = CORS error |
| Frontend filter predicate | Browser / Client | — | IssueHub.tsx §59–66 Set intersection; depends on non-null `candidateId` on quotes |
| Zero-state empty message | Browser / Client | — | IssueHub.tsx render path when filteredIssues.length === 0 |
| Google Places autocomplete | Browser / Client | External (Google Maps API) | `useGooglePlacesAutocomplete` hook — already confirmed working (D-08) |

---

## Standard Stack

### Core (all already in-project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19 | UI components | Project standard |
| Zustand | (existing) | Location filter state | `useReadRankStore` already has `locationFilter`, `setLocationFilter`, `clearLocationFilter` |
| Framer Motion | (existing) | Zero-state entrance animation | Used throughout IssueHub already |
| `apiFetch` (lib/auth.ts) | — | All API calls from read-rank | Handles auth headers + 401 redirect; both filter modes use it |
| Express + cors npm | (existing) | CORS enforcement on API | `CORS_ORIGIN` env var controls allowed origins in production |

### No New Dependencies
This phase requires zero new npm packages. The zero-state component uses existing `framer-motion` and the `.ev-button-secondary` CSS class already defined in `index.css`.

---

## Architecture Patterns

### System Architecture Diagram

```
[User in read-rank browser]
        |
        | (1a) Address mode: types address
        v
[Google Places Autocomplete] --> onPlaceSelected(formattedAddress)
        |
        | (1b) Browse mode: selects State > Area Type > Area
        v
[/api/essentials/browse/states]          [/api/essentials/browse/states/:state/areas]
        |                                         |
        +---> [/api/essentials/browse/by-area] <--+
        |           (PostGIS ST_Intersects)
        |
        | Both paths produce: politicianIds[]
        v
[setLocationFilter({ address, politicianIds })] --> Zustand store
        |
        v
[IssueHub filter predicate]
  quotes.filter(q => localPoliticianSet.has(q.candidateId))
  issues.filter(issue => uniqueLocalReps.size >= 2)
        |
        v
[filteredIssues rendered as cards]   OR   [zero-state message if length === 0]


Data layer:
[essentials.quotes] -- politician_id, topic_key
        |
        | JOIN
        v
[inform.compass_topics] -- topic_key (must match)
        |
        v
[GET /api/essentials/quotes] --> { quotes[].candidateId, issues[], candidates[] }
        |
        v
[IssueHub useEffect: fetchQuotesData()] -- cached in module var
```

### Critical Join Path

The `/api/essentials/quotes` endpoint [VERIFIED: ev-accounts/backend/src/routes/essentials.ts:208]:

```sql
FROM essentials.quotes q
JOIN essentials.politicians p ON p.id = q.politician_id AND p.is_active = true
LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key)
```

And then filters: `rows.filter((r) => r.topic_id !== null)` — meaning any quote whose `topic_key` does not match a `compass_topics` row is **silently dropped** from the output. This is the most likely silent failure mode.

### Key Data Flow: candidateId linkage

`quotes[].candidateId` in the frontend = `q.politician_id` (UUID) from the DB.
`locationFilter.politicianIds[]` = politician `id` UUIDs from the search or browse API.

Both are the same UUID from `essentials.politicians.id`. The linkage is correct **IF** Monroe County politicians appear in both the quotes table and the geofence lookup — which is the diagnosis question.

### Recommended Diagnostic Order

1. **DB audit** (highest ROI first):
   ```sql
   -- Check: do Monroe County politicians have quotes?
   SELECT p.full_name, p.id, COUNT(q.id) AS quote_count
   FROM essentials.politicians p
   JOIN essentials.offices o ON o.politician_id = p.id
   JOIN essentials.districts d ON d.id = o.district_id
   LEFT JOIN essentials.quotes q ON q.politician_id = p.id
   WHERE d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')
     AND o.representing_state = 'IN'
     AND p.is_active = true
   GROUP BY p.full_name, p.id
   ORDER BY quote_count DESC;
   ```

   ```sql
   -- Check: do those quotes have matching compass topics?
   SELECT q.topic_key, ct.topic_key AS matched_topic, q.politician_id
   FROM essentials.quotes q
   LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key)
   JOIN essentials.politicians p ON p.id = q.politician_id
   JOIN essentials.offices o ON o.politician_id = p.id
   WHERE o.representing_state = 'IN'
   ORDER BY q.topic_key;
   ```

2. **API check** — curl the search endpoint with a Bloomington address:
   ```bash
   curl -s -X POST https://accounts-api.empowered.vote/api/essentials/candidates/search \
     -H "Content-Type: application/json" \
     -d '{"query": "401 N Morton St, Bloomington, IN 47404"}' | jq 'length, .[].full_name'
   ```

3. **CORS check** — verify the readrank origin is in `CORS_ORIGIN` on the Render env.

4. **API URL mismatch check** — confirmed critical finding (see below).

---

## CRITICAL FINDING: API URL Mismatch

[VERIFIED: read-rank/render.yaml, read-rank/src/lib/auth.ts]

The read-rank `render.yaml` sets:
```
VITE_API_URL=https://accounts-api.empowered.vote
```

The `read-rank/.env.production` file sets:
```
VITE_API_URL=https://ev-accounts-api.onrender.com
```

The `src/lib/auth.ts` hardcodes:
```
API_HUB_URL = 'https://accounts-api.empowered.vote'
```

The CLAUDE.md states the backend API is at `api.empowered.vote`. The `accounts-api.empowered.vote` domain appears in the backend's own `render.yaml` as the domain for the ev-accounts Render deployment. These may be the same service, or may differ.

**This URL discrepancy must be confirmed during diagnosis.** If `accounts-api.empowered.vote` is a live alias for `api.empowered.vote`, it's fine. If the `.env.production` value (`ev-accounts-api.onrender.com`) overrides `render.yaml`, the actual production API URL differs from `render.yaml`. Vite's env var resolution: `render.yaml` env vars are injected at build time; `.env.production` is also read at build time; the **last writer wins** (typically render.yaml env vars override `.env.production` because they're set as Render service env vars, which take precedence). This needs confirmation.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CORS policy enforcement | Custom middleware | Express `cors` package (already configured) | Already handles multiple origins via comma-separated `CORS_ORIGIN` env var |
| PostGIS area intersection | Custom SQL geometry | Existing `essentialsBrowseService.getPoliticiansByArea()` | Already implements bidirectional ST_Intersects; do not duplicate |
| Location filter state | New state variable | Existing Zustand `locationFilter` + `setLocationFilter` + `clearLocationFilter` | Fully implemented; zero-state only needs to read `locationFilter !== null && filteredIssues.length === 0` |
| Zero-state animation | CSS transitions | Framer Motion `motion.div` (already in IssueHub) | Consistent with existing patterns |

---

## Common Pitfalls

### Pitfall 1: Silent quote drop from topic_key mismatch
**What goes wrong:** Monroe County quotes exist in `essentials.quotes` but their `topic_key` doesn't match any `inform.compass_topics.topic_key`. The `/api/essentials/quotes` endpoint silently filters them out (`filter((r) => r.topic_id !== null)`), so the frontend never sees them. The filter returns politician IDs correctly but finds no qualifying issues.
**Why it happens:** The topic_key join is a LEFT JOIN followed by a null filter — a dropped quote produces no error, just missing data.
**How to avoid:** Run the diagnostic SQL to confirm topic_key alignment. Migration 055 already fixed two mismatches (`data-center-energy` → `data-centers`, `homelessness-policy` → `homelessness`). There may be others.
**Warning signs:** API returns politician IDs for Monroe County address, but `filteredIssues` after applying the set intersection is still empty.

### Pitfall 2: `candidateId` is undefined on some quotes
**What goes wrong:** The `Quote` type has `candidateId?: string` (optional). The filter predicate checks `q.candidateId && localPoliticianSet.has(q.candidateId)`. If some quotes have `candidateId: undefined`, they are silently excluded.
**Why it happens:** The API maps `q.politician_id` to `candidateId`; this should always be non-null. But if the DB query returns null politician_id (e.g., orphaned quote), the quote passes through with undefined candidateId.
**How to avoid:** Confirm all quotes in the DB have non-null `politician_id`. Query: `SELECT COUNT(*) FROM essentials.quotes WHERE politician_id IS NULL`.

### Pitfall 3: CORS blocks the API from readrank.empowered.vote
**What goes wrong:** `apiFetch` calls from `readrank.empowered.vote` to `accounts-api.empowered.vote` are blocked by the browser because `readrank.empowered.vote` is not in the backend's `CORS_ORIGIN` env var on Render.
**Why it happens:** The backend CORS config does exact-match against `CORS_ORIGIN` — if `readrank.empowered.vote` is missing, every fetch fails with a CORS error. This would silently return `null` from `apiFetch` (the 401 redirect path would not trigger since CORS errors happen before the response is received; they throw network errors instead).
**How to avoid:** Check the `CORS_ORIGIN` env var in the Render dashboard for the ev-accounts service. Confirm `readrank.empowered.vote` is included.
**Warning signs:** Browser DevTools shows "CORS error" on fetch to accounts-api.empowered.vote. The `AddressFilterInput` shows `browseError` or `noMatchWarning` immediately without a spinner.

### Pitfall 4: Browse mode catches error silently on non-ok response
**What goes wrong:** `handleBrowse()` checks `if (!res || !res.ok)` and sets `browseError('No representatives found for this area.')` — but this same error message appears for both "area genuinely has no reps" and "network/CORS failure". The user sees the same message for very different root causes.
**Why it happens:** The error branching in AddressFilterInput.tsx lines 99–101 conflates API failure with data emptiness.
**How to avoid:** During diagnosis, check the actual HTTP status code. A CORS failure won't produce a response at all (caught in `catch` block), while a 200 with empty data is a data problem.

### Pitfall 5: `fetchQuotesData()` falls back to mock data silently
**What goes wrong:** `fetchQuotesData()` uses plain `fetch` (not `apiFetch`) and catches all errors with a fallback to `mockData`. If `/api/essentials/quotes` is unreachable, the app loads mock data instead of real data — but the filter still tries to match real politician IDs against mock `candidateId` values (which won't match).
**Why it happens:** The fallback is intentional for offline dev but creates a subtle production failure mode: filter appears to work (no error shown) but always returns zero issues because mock `candidateId` values don't match real politician IDs.
**How to avoid:** During diagnosis, open DevTools Network tab and confirm `/api/essentials/quotes` returns 200 with real data. Check the response body for `quotes[].candidateId` values.

### Pitfall 6: VITE_API_URL points to wrong backend in production
**What goes wrong:** `render.yaml` sets `VITE_API_URL=https://accounts-api.empowered.vote` but `.env.production` sets `VITE_API_URL=https://ev-accounts-api.onrender.com`. Depending on build resolution order, the frontend may be hitting a different URL than intended.
**Why it happens:** Render injects env vars from its dashboard/yaml at build time. The `.env.production` file is baked into the Docker context. Render service env vars typically override `.env.production`.
**How to avoid:** Confirm in Render dashboard which URL is active. During diagnosis, check the browser's network requests to see which API host is being used.

---

## Code Examples

### Zero-State Empty Message (new element — from UI-SPEC)
[VERIFIED: 119-UI-SPEC.md]

Insert in `IssueHub.tsx` after `AddressFilterInput` and before the issue card list:

```tsx
// Source: 119-UI-SPEC.md D-06
{locationFilter !== null && displayedIssues.length === 0 && (
  <motion.div
    className="max-w-2xl mx-auto text-center py-12"
    initial={{ opacity: 0, y: 8 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.3 }}
  >
    <p style={{
      fontFamily: "'Manrope', sans-serif",
      fontSize: '0.9375rem',
      fontWeight: 700,
      color: '#1a1a2e',
      marginBottom: '0.5rem',
    }}>
      No issues with local quotes for this area
    </p>
    <p style={{
      fontFamily: "'Manrope', sans-serif",
      fontSize: '0.8125rem',
      fontWeight: 400,
      color: '#64748b',
      lineHeight: 1.5,
      marginBottom: '1rem',
    }}>
      We don&apos;t have quotes from your representatives for any issues yet.
    </p>
    <button
      className="ev-button-secondary"
      onClick={clearLocationFilter}
    >
      Clear location filter
    </button>
  </motion.div>
)}
```

### DB Diagnostic Query — Confirm Quote + Topic Match
```sql
-- Source: derived from essentials.ts quotes endpoint logic
SELECT
  q.topic_key          AS quote_topic_key,
  ct.topic_key         AS compass_topic_key,
  ct.short_title,
  COUNT(q.id)          AS quote_count,
  CASE WHEN ct.id IS NULL THEN 'DROPPED' ELSE 'MATCHED' END AS status
FROM essentials.quotes q
LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key)
GROUP BY q.topic_key, ct.topic_key, ct.short_title, ct.id
ORDER BY status DESC, q.topic_key;
```

### API Smoke Test — Address Search
```bash
# Replace with canonical Kirkwood Ave address from MATRIX.md
curl -s -X POST https://accounts-api.empowered.vote/api/essentials/candidates/search \
  -H "Content-Type: application/json" \
  -H "Origin: https://readrank.empowered.vote" \
  -d '{"query": "401 N Morton St, Bloomington, IN 47404"}' \
  -v 2>&1 | grep -E "HTTP|Access-Control|politician_id|full_name" | head -20
```
Note: The `-H "Origin: ..."` header triggers CORS evaluation — a CORS block is detectable from the absence of `Access-Control-Allow-Origin` in the response headers.

### API Smoke Test — Browse By Area (Monroe County)
```bash
# Monroe County FIPS geo_id = 18105 (Indiana FIPS 18, Monroe County 105)
# mtfcc G4020 = county
curl -s -X POST https://accounts-api.empowered.vote/api/essentials/browse/by-area \
  -H "Content-Type: application/json" \
  -H "Origin: https://readrank.empowered.vote" \
  -d '{"geo_id": "18105", "mtfcc": "G4020"}' \
  -v 2>&1 | grep -E "HTTP|Access-Control|id|full_name" | head -30
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| topic_key join via string-mangling short_title | Direct topic_key column on compass_topics | Migration 055 | Quotes with mismatched topic_key now detectable |
| Single ZIP-based candidate search | Full address geocoding + PostGIS geofence | Phase 107–109 | More precise politician matching for address search |
| No browse mode | Browse mode (State → Area → PostGIS) | Phase 108 | Fallback for addresses Census Geocoder can't handle |

**Key architecture note:** The `fetchQuotesData()` call in IssueHub uses plain `fetch` (no auth), while `searchPoliticians()` and browse calls use `apiFetch` (with optional auth header). This is intentional — quotes are a public endpoint; search/browse are also public (`optionalAuth`) but routed through `apiFetch` for consistent header handling.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Monroe County geo_id is `18105` for the county-level TIGER geofence (mtfcc G4020) | Code Examples | Wrong geo_id in smoke test would return 404 or empty — test would need correct geo_id from DB |
| A2 | `accounts-api.empowered.vote` and `api.empowered.vote` point to the same Render service | CRITICAL FINDING | If different services, the API URL used by read-rank in production may not have the same data or CORS config |
| A3 | The Render `CORS_ORIGIN` env var for ev-accounts does not currently include `readrank.empowered.vote` | Pitfall 3 | If it already includes it, CORS is not the failure point |

---

## Open Questions

1. **Does `readrank.empowered.vote` appear in the `CORS_ORIGIN` env var on the Render ev-accounts service?**
   - What we know: The backend does exact-match CORS in production. The `.env.example` has no example `CORS_ORIGIN` value. The Render dashboard (not in git) holds the actual value.
   - What's unclear: Whether `readrank.empowered.vote` was ever added.
   - Recommendation: First task of Wave 0 — check the Render dashboard or run the curl smoke test with an Origin header.

2. **Do Monroe County politicians currently have quotes in `essentials.quotes`?**
   - What we know: The quotes table has `politician_id` + `topic_key` + `quote_text`. Migration 055 fixed two topic_key mismatches.
   - What's unclear: Whether any Monroe County local politician records have been given quotes at all, and whether those quotes' topic_keys match current compass_topics.
   - Recommendation: Run the DB diagnostic query in Wave 0 before any code changes.

3. **Is `accounts-api.empowered.vote` the correct production API URL for read-rank?**
   - What we know: `render.yaml` sets `VITE_API_URL=https://accounts-api.empowered.vote`; `.env.production` has an old Render internal URL. `src/lib/auth.ts` uses `API_HUB_URL = 'https://accounts-api.empowered.vote'` (used for auth redirects, not API calls).
   - What's unclear: Which value wins at build time; whether `accounts-api.empowered.vote` actually resolves.
   - Recommendation: Check browser DevTools Network tab on production to see the actual host being called.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Render dashboard access | CORS_ORIGIN verification (D-07) | [ASSUMED] yes | — | curl with Origin header as proxy |
| Supabase SQL editor or psql | DB diagnostic queries | [ASSUMED] yes | — | Could infer from API response patterns instead |
| Production readrank.empowered.vote | Final verification (D-10) | yes — Render auto-deploy | — | — |
| Census Geocoder (external) | Address mode (POST /candidates/search) | [ASSUMED] yes — external service | — | Browse mode as fallback |

---

## Validation Architecture

No automated test framework exists in read-rank (no vitest/jest config, no test scripts in package.json). [VERIFIED: read-rank/package.json]

The ev-accounts backend has vitest configured at `ev-accounts/backend/vitest.config.ts` for integration tests, but the filter predicate and zero-state logic are frontend-only.

**Verification approach for this phase:**

| Req ID | Behavior | Test Type | Command |
|--------|----------|-----------|---------|
| RR-03 | Monroe County filter scopes issues to local candidates | Manual — production smoke | Open readrank.empowered.vote, enter Kirkwood Ave address, observe filtered issue list |
| RR-04 | Both geocoding + filter logic functional | Manual — production smoke | Test address mode AND browse mode (State: IN, Area: County, Area: Monroe County) |

**Wave 0 gaps:** No test infrastructure to create — this is a repair phase with no existing tests and no new automated test coverage required. All verification is manual production smoke testing per D-10.

---

## Security Domain

This phase does not introduce authentication changes, new data inputs, or cryptographic operations. Both `/api/essentials/candidates/search` and `/api/essentials/browse/by-area` use `optionalAuth` — they are public endpoints. The only input validation risk is the `query` field on the search endpoint (already validated: `typeof query !== 'string'` check) and `geo_id`/`mtfcc` on the browse endpoint (already validated: string presence checks). No new ASVS controls required.

CORS fix (if needed) is a configuration change to an existing control, not a new security surface.

---

## Sources

### Primary (HIGH confidence — verified against source files this session)
- `read-rank/src/components/AddressFilterInput.tsx` — full file read, both filter modes
- `read-rank/src/components/IssueHub.tsx` — full file read, filter predicate lines 59–69
- `read-rank/src/store/useReadRankStore.ts` — full file read, LocationFilter type and actions
- `read-rank/src/data/api.ts` — full file read, searchPoliticians + fetchQuotesData
- `read-rank/src/hooks/useGooglePlacesAutocomplete.ts` — full file read
- `read-rank/src/lib/auth.ts` — full file read, apiFetch implementation
- `ev-accounts/backend/src/routes/essentials.ts` lines 182–265 — quotes endpoint
- `ev-accounts/backend/src/routes/essentialsCandidates.ts` — search endpoint
- `ev-accounts/backend/src/routes/essentialsBrowse.ts` — browse endpoints
- `ev-accounts/backend/src/lib/essentialsBrowseService.ts` — full file read, PostGIS queries
- `ev-accounts/backend/src/index.ts` — CORS config and route wiring
- `ev-accounts/backend/migrations/055_compass_topic_key.sql` — topic_key join fix
- `ev-schema-export.sql` — essentials.quotes schema (politician_id, topic_key, quote_text)
- `read-rank/render.yaml` — VITE_API_URL = accounts-api.empowered.vote
- `read-rank/.env.production` — VITE_API_URL = ev-accounts-api.onrender.com (older value)
- `.planning/phases/119-read-rank-location-filter-repair/119-UI-SPEC.md` — zero-state spec
- `.planning/phases/119-read-rank-location-filter-repair/119-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- `ev-accounts/backend/.env.example` — CORS_ORIGIN is optional with no example value
- `read-rank/src/lib/auth.ts` API_HUB_URL hardcode — confirms accounts-api.empowered.vote as intended API host

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified against source files
- Filter predicate logic: HIGH — full source read, logic is straightforward Set intersection
- Root cause identification: MEDIUM — data gap is the most likely cause but unconfirmed until DB query runs
- CORS status: LOW — cannot verify `CORS_ORIGIN` env var value without Render dashboard access
- API URL correctness in production: LOW — render.yaml vs .env.production discrepancy unresolved

**Research date:** 2026-04-15
**Valid until:** 2026-05-01 (stable codebase; no external dependencies change)
