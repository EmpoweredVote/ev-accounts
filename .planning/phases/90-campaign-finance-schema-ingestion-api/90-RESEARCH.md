# Phase 90: Campaign Finance Schema + Ingestion + API — Research

**Researched:** 2026-06-04
**Domain:** FEC API ingestion, PostgreSQL JSONB schema, Express REST API extension
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FINA-01 | `finance_summary` JSONB column added to `essentials.politicians` (not `inform.politicians` — see Critical Finding below); migration applied | Schema confirmed; migration pattern documented; next migration is 268 |
| FINA-02 | FEC ingestion script built and run; loads `{ total_raised, top_donors, cycle, source: "FEC" }` for all federal politicians; uses congress-legislators YAML for bioguide → FEC ID crosswalk | FEC endpoints verified live; crosswalk format confirmed; script pattern established from existing `fecResearch.ts` |
| FINA-03 | `GET /api/essentials/politicians` and single-politician endpoints return `finance_summary` when non-null; `null` for non-federal politicians; backward-compatible | API surface mapped; `essentialsService.ts` pattern understood; two endpoints to update |
</phase_requirements>

---

## Critical Finding: `inform.politicians` vs. `essentials.politicians`

**FINA-01 as written says "add `finance_summary` to `inform.politicians`."** This is incorrect for FINA-03 to work.

After Phase 35 deduplication (migration 050), `essentials.politicians` is the unified politician table. `inform.politicians` is a legacy table used only by the Compass CompassV2 internal comparison feature (it stores comparison stances, not main politician data). The `GET /api/essentials/politicians` endpoint (FINA-03 target) reads exclusively from `essentials.politicians` via `essentialsService.ts::getPoliticiansFlatList()` and `getPoliticianById()`.

**Planner decision needed:** The column should go on `essentials.politicians`, not `inform.politicians`. The REQUIREMENTS.md requirement text was written before the Phase 35 deduplication pattern was established and references the wrong table. This is the only path that satisfies all three FINA requirements as a unit.

---

## Summary

Phase 90 adds campaign finance summaries to the politician data layer. It is three sequential waves: schema migration, FEC data ingestion script, API surface update.

The project already has a full FEC ingestion infrastructure (`transparent_motivations` schema, `fecAdapter.ts`, `campaignFinanceService.ts`, `campaignFinanceScheduler.ts`). That system ingests individual Schedule A contribution records for per-contribution browsing. Phase 90's `finance_summary` is a **denormalized JSONB snapshot** — a cheaper cached summary per politician rather than joining the full `transparent_motivations.contributions` table at request time. These two systems are complementary: the existing system supports the detailed `/api/campaign-finance/politician/:id/contributions` endpoint; the new `finance_summary` column supports the high-traffic `/api/essentials/politicians` list endpoint.

The existing `transparent_motivations.politician_sources` table already has FEC IDs for many senators (confirmed via `run-fec-auto-match.ts` and `check-fec-sources.ts` scripts). For Phase 90, we need a lighter approach: use the FEC `/candidates/totals/` and `/schedules/schedule_a/by_employer/` endpoints to compute a summary directly, using the congress-legislators YAML bioguide → FEC ID crosswalk for politicians without a `politician_sources` row.

**Primary recommendation:** Add `finance_summary JSONB` to `essentials.politicians` in migration 268. Write a standalone `tsx backend/scripts/run-fec-finance-summary.ts` script that fetches totals + top-10 by-employer donors from FEC for all federal politicians and writes to the column. Update `getPoliticiansFlatList()` and `getPoliticianById()` to return `finance_summary` (null for non-federal politicians).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema migration (ADD COLUMN) | Database | — | DDL change to essentials.politicians |
| FEC data ingestion | Backend script (one-time) | FEC API (external) | Runs once as a Node.js/tsx script; not a cron (Alpha scale) |
| `finance_summary` read | API / Backend | Database | essentialsService.ts query update |
| Null for non-federal politicians | API / Backend | — | Filter in service layer by district_type |
| Backward compatibility | API / Backend | — | finance_summary not in PoliticianFlatRecord TypeScript type yet |

---

## Standard Stack

### Core (all already installed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pg` | already used | Direct Postgres queries (pool.query) | Required for non-public schemas; all DB writes use this |
| `node-fetch` / native `fetch` | Node 20 built-in | FEC API HTTP calls | Already used in fecAdapter.ts via native fetch |
| `tsx` | ^4.19.0 | Run TypeScript scripts directly | Already used for all backend scripts |
| `js-yaml` | — | Parse congress-legislators YAML | See package check below |
| `dotenv` | already used | Load .env for FEC_API_KEY + DATABASE_URL | Already used in all scripts |

### Package Check: js-yaml

The FINA-02 requirement calls for a congress-legislators YAML crosswalk. The YAML file is at:
`https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml`

Option A: Use `js-yaml` npm package to parse the YAML.
Option B: Fetch the JSON equivalent: `https://theunitedstates.io/congress-legislators/legislators-current.json`

**Recommendation: Use the JSON endpoint.** The `theunitedstates.io` JSON API is machine-generated from the same YAML source. It avoids adding a YAML parsing dependency entirely. The JSON fields `id.bioguide` and `id.fec` (array of strings) are identical in structure. `[ASSUMED]` that the JSON endpoint remains available — verify before executing.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `js-yaml` | — | YAML parsing | Only if JSON endpoint unavailable |

**Installation (only if using js-yaml):**
```bash
npm install js-yaml @types/js-yaml --save-dev
```

---

## Package Legitimacy Audit

> No new runtime packages are required for this phase. The ingestion script uses only:
> - `node-fetch` / native fetch (Node 20 built-in)
> - `pg` (already installed, [VERIFIED: npm registry])
> - `tsx` (already installed, [VERIFIED: npm registry])
> - `dotenv` (already installed, [VERIFIED: npm registry])
> - Possibly `js-yaml` — but JSON alternative avoids it

| Package | Registry | Disposition |
|---------|----------|-------------|
| `pg` | npm | Already installed — Approved |
| `tsx` | npm | Already installed — Approved |
| `js-yaml` | npm | Skip — use JSON endpoint instead |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## FEC API Reference

### Endpoints Used

All endpoints require `?api_key=` query parameter. Rate limit: **1,000 requests/hour** for free keys.
[CITED: env.ts comment — "register free at api.data.gov/signup/ for 1000 req/hr limit"]

#### 1. Candidate Totals — Total Raised

```
GET https://api.open.fec.gov/v1/candidates/totals/
  ?api_key=YOUR_KEY
  &candidate_id=S8WA00194     ← FEC candidate ID
  &cycle=2026                  ← election cycle (2-year period)
  &per_page=1
```

**Response key field:** `results[0].receipts` — total amount raised in cycle (float).
Also: `results[0].disbursements`, `results[0].cycle`.

[VERIFIED: live API call — Maria Cantwell S8WA00194 cycle 2024 returned receipts=$13,025,509.69]

#### 2. Committee ID Lookup (needed for by_employer)

```
GET https://api.open.fec.gov/v1/candidates/search/
  ?api_key=YOUR_KEY
  &candidate_id=S8WA00194
  &per_page=1
```

**Response key field:** `results[0].principal_committees[*].committee_id` — string like `C00349506`.
One politician can have multiple principal committees across cycles.

[VERIFIED: live API call — Cantwell returns committee C00349506 "FRIENDS OF MARIA"]

#### 3. Top Donors by Employer

```
GET https://api.open.fec.gov/v1/schedules/schedule_a/by_employer/
  ?api_key=YOUR_KEY
  &committee_id=C00349506     ← committee ID (NOT candidate_id)
  &cycle=2026
  &per_page=10
  &sort=-total                 ← descending by total
```

**Response per result:** `{ committee_id, employer, total, count, cycle }`
- `employer`: string (can be "NOT EMPLOYED", "SELF EMPLOYED", null)
- `total`: float (dollars)
- `count`: integer (number of contributions)

[VERIFIED: live API call — Cantwell C00349506 cycle 2026 returned top employers including "NOT EMPLOYED" $188,924.23]

### FEC Candidate ID Format

FEC candidate IDs follow the pattern `[S/H][digit][STATE][digits]`:
- Senate: `S6AK00268` (S = Senate, state = AK)
- House: `H2WA01054` (H = House, state = WA, district = 01)

### Rate Limit Budget for Phase 90

Federal politicians in scope: ~143 (100 senators + 43 declared 2026 candidates).

Per politician API calls:
1. `candidates/search/` to get committee IDs: 1 call
2. `candidates/totals/` to get receipts: 1 call
3. `schedule_a/by_employer/` per committee (typically 1, sometimes 2): 1-2 calls

Total estimated calls: ~430 (3 per politician, plus margin). At 1.5s sleep between calls: ~10 minutes. Well within 1,000/hour rate limit.

---

## congress-legislators Crosswalk

### JSON Endpoint (Recommended)

URL: `https://theunitedstates.io/congress-legislators/legislators-current.json`
[ASSUMED: This endpoint remains available. Verify before executing ingestion script.]

### YAML Source (Fallback)

URL: `https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml`
[CITED: .planning/phases/73-senator-records/73-01-SUMMARY.md — used in Phase 73 for bioguide verification]

### Field Structure

Each legislator entry:
```json
{
  "id": {
    "bioguide": "C000127",
    "fec": ["S8WA00194", "H2WA01054"]
  },
  "name": { "first": "Maria", "last": "Cantwell" },
  "terms": [...]
}
```

**Key facts:**
- `id.fec` is an **array** — a legislator can have multiple FEC IDs (different chambers, special elections)
- `id.bioguide` is the same string stored in `essentials.politicians.bioguide_id`
- Most senators have 1-2 FEC IDs; the most recent Senate ID is what we want for cycle 2026
- Non-incumbents (2026 candidates) are NOT in `legislators-current` — they need to be looked up via `transparent_motivations.politician_sources` where `research_status = 'confirmed'` and `source_system = 'fec_senate'`

[CITED: live fetch of legislators-current.yaml — Cantwell bioguide=C000127, fec=["S8WA00194","H2WA01054"]]

### Crosswalk Strategy

The ingestion script should use a two-path lookup:

**Path 1 — Congress-legislators (incumbents):**
```
essentials.politicians.bioguide_id → congress-legislators JSON → id.fec[latest S-prefix ID]
```

**Path 2 — transparent_motivations.politician_sources (candidates + incumbents already matched):**
```
essentials.politicians.id → politician_sources WHERE source_system LIKE 'fec%' AND research_status = 'confirmed' → external_id (= FEC candidate_id)
```

Use Path 2 as primary (already done), fall back to Path 1 (congress-legislators). For 2026 candidates not yet in either: skip with a logged warning.

---

## Architecture Patterns

### System Architecture Diagram

```
[Ingestion Script: run-fec-finance-summary.ts]
  │
  ├─→ DB: SELECT federal politicians FROM essentials.politicians
  │         JOIN essentials.offices → chambers (U.S. Senate, U.S. House)
  │
  ├─→ Path 1: transparent_motivations.politician_sources (confirmed FEC IDs)
  │
  ├─→ Path 2: fetch congress-legislators JSON → bioguide_id → fec[] array
  │
  ├─→ FEC API: GET /v1/candidates/search/ → committee_id
  │
  ├─→ FEC API: GET /v1/candidates/totals/ → receipts (total_raised)
  │
  ├─→ FEC API: GET /v1/schedules/schedule_a/by_employer/ → top 10 employers
  │
  └─→ DB: UPDATE essentials.politicians SET finance_summary = $1 WHERE id = $2

[API: GET /api/essentials/politicians]
  │
  ├─→ essentialsService.ts::getPoliticiansFlatList()
  │     SELECT p.*, p.finance_summary FROM essentials.politicians p ...
  │
  └─→ Response: { ...politicianFields, finance_summary: { total_raised, top_donors, cycle, source } | null }

[API: GET /api/essentials/politicians/:id]
  │
  ├─→ essentialsService.ts::getPoliticianById()
  │     SELECT p.*, p.finance_summary FROM essentials.politicians p WHERE p.id = $1
  │
  └─→ Response: { ...fullPoliticianProfile, finance_summary: ... | null }
```

### Recommended Project Structure

No new directories needed. Changes touch:
```
backend/migrations/
  268_finance_summary_column.sql   ← new: ADD COLUMN finance_summary JSONB on essentials.politicians
backend/scripts/
  run-fec-finance-summary.ts       ← new: standalone ingestion script
backend/src/lib/
  essentialsService.ts             ← update: add finance_summary to SELECT + response shape
```

### finance_summary JSONB Schema

```typescript
interface FinanceSummary {
  total_raised: number;           // float, from FEC receipts field
  top_donors: Array<{
    employer: string;             // FEC by_employer.employer string
    amount: number;               // FEC by_employer.total float
    count: number;                // FEC by_employer.count integer
  }>;
  cycle: string;                  // "2026" (4-digit year string)
  source: "FEC";                  // always "FEC" for this phase
}
```

Top donors: filter out null/empty employer strings, cap at 10 entries, sort descending by amount.

### Migration Pattern (268)

```sql
-- Migration 268: Add finance_summary JSONB column to essentials.politicians
-- Stores { total_raised, top_donors, cycle, source } from FEC API.
-- NULL for non-federal politicians; populated by run-fec-finance-summary.ts script.

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS finance_summary JSONB;

COMMENT ON COLUMN essentials.politicians.finance_summary IS
  'Campaign finance summary from FEC. NULL for non-federal politicians.
   Shape: { total_raised: float, top_donors: [{employer, amount, count}], cycle: string, source: "FEC" }';
```

Note: `ADD COLUMN IF NOT EXISTS` is idempotent. No index needed — JSONB is for read-only display.

### Script Pattern: run-fec-finance-summary.ts

Follows the same pattern as `run-fec-auto-match.ts`:

```typescript
import 'dotenv/config';
import { pool } from '../src/lib/db.js';

// 1. Fetch congress-legislators JSON for bioguide → fec[] crosswalk
// 2. Query federal politicians from DB
// 3. For each politician:
//    a. Resolve FEC candidate ID (politician_sources → congress-legislators fallback)
//    b. GET /candidates/search/ → committee IDs
//    c. GET /candidates/totals/ → receipts
//    d. GET /schedule_a/by_employer/ → top donors
//    e. UPDATE essentials.politicians SET finance_summary = {...}
// 4. Log summary: processed, succeeded, skipped, errors
```

Rate-limit guard: 1,500ms sleep between FEC API calls (already established in fecResearch.ts — `SLEEP_BETWEEN_SEARCHES_MS = 1500`).

### API Update Pattern

In `essentialsService.ts::getPoliticiansFlatList()`:

```typescript
// Add to SELECT clause:
p.finance_summary,

// Add to PoliticianFlatRecord interface:
finance_summary: FinanceSummary | null;

// Add to map() in response builder:
finance_summary: row.finance_summary ?? null,
```

Same pattern for `getPoliticianById()`.

**Backward compatibility:** `finance_summary` is a new field added to response objects. Frontend clients that don't reference it are unaffected. No existing fields change.

### Anti-Patterns to Avoid

- **Do NOT join `transparent_motivations.contributions` at request time for the list endpoint.** The existing `campaignFinanceService.ts::getSummary()` is appropriate for the dedicated `/api/campaign-finance/politician/:id/summary` endpoint — not for the high-traffic `/api/essentials/politicians` list. Use the pre-computed JSONB column instead.
- **Do NOT add `finance_summary` to `inform.politicians`.** That table is legacy and not queried by the essentials API.
- **Do NOT compute employer groupings from raw contributions at runtime.** The FEC `by_employer` endpoint returns pre-aggregated data — use it directly.
- **Do NOT skip null/empty employer strings silently.** Filter them out before storing in `top_donors` (FEC returns "NOT EMPLOYED", "SELF EMPLOYED", and null as common values — these are fine to include if present, but null strings should be filtered).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| FEC rate limit backoff | Custom retry logic | Existing `fetchWithRetry()` in fecAdapter.ts | Already handles 429 with exponential backoff |
| Bioguide → FEC ID crosswalk | Manual mapping | congress-legislators JSON endpoint | Authoritative source, machine-readable |
| Employer aggregation | Group `transparent_motivations.contributions` at runtime | FEC `schedule_a/by_employer` endpoint | Pre-aggregated; no need for local computation |

**Key insight:** The project already has a complete FEC ingestion pipeline. Phase 90's summary script is much simpler — it only needs the totals and employer aggregation, not raw Schedule A pagination.

---

## Common Pitfalls

### Pitfall 1: Wrong table — inform.politicians vs. essentials.politicians
**What goes wrong:** Column added to `inform.politicians`; FINA-03 API endpoint reads from `essentials.politicians`; `finance_summary` is always null in all API responses.
**Why it happens:** REQUIREMENTS.md was written before Phase 35 deduplication established `essentials.politicians` as the unified table.
**How to avoid:** Apply migration 268 to `essentials.politicians` only. Confirm with: `SELECT column_name FROM information_schema.columns WHERE table_schema='essentials' AND table_name='politicians' AND column_name='finance_summary';`
**Warning signs:** `finance_summary` always null despite ingestion script succeeding.

### Pitfall 2: FEC committee_id vs. candidate_id confusion
**What goes wrong:** Passing `candidate_id` to `schedule_a/by_employer` endpoint → HTTP 422. The by_employer endpoint requires `committee_id`.
**Why it happens:** FEC requires a 2-step lookup: candidate_id → committee_id → by_employer.
**How to avoid:** Always call `candidates/search/?candidate_id=X` first to get `principal_committees[*].committee_id`, then pass committee_id to by_employer.
**Warning signs:** HTTP 422 from FEC API.

### Pitfall 3: 2026 candidates not in congress-legislators YAML
**What goes wrong:** Script fails for 43 non-incumbent 2026 candidates because their bioguide IDs don't appear in `legislators-current`.
**Why it happens:** `legislators-current.yaml` only includes current (sworn-in) Congress members. Declared non-incumbent candidates are not included.
**How to avoid:** Use `transparent_motivations.politician_sources` (Path 2) as primary lookup. Many candidates were already matched by `run-fec-auto-match.ts`. For unmatched candidates, log as skipped and set `finance_summary = null`.
**Warning signs:** Script throws "bioguide not found in congress-legislators" for all 2026 candidates.

### Pitfall 4: Multiple FEC IDs per politician
**What goes wrong:** `id.fec` in congress-legislators is an array. Picking the wrong ID (e.g., House ID for a senator) causes wrong totals or empty results.
**Why it happens:** Maria Cantwell has two FEC IDs: `S8WA00194` (Senate) and `H2WA01054` (House, from before she was senator).
**How to avoid:** When a politician has multiple FEC IDs, filter by office type: use IDs starting with `S` for senators, `H` for House. Use the most recent one (cycle-appropriate).
**Warning signs:** Unexpectedly low totals for long-serving senators with prior House service.

### Pitfall 5: pg returns numeric columns as strings
**What goes wrong:** `total_raised` stored as `"0"` (string) instead of `0` (number) in JSONB.
**Why it happens:** pg driver returns `DECIMAL/NUMERIC` columns as strings. FEC `receipts` comes back as a JSON number directly from the FEC API response (not through pg), so this is less of an issue here — but verify.
**How to avoid:** Always `Number(fecResponse.receipts)` and `Number(result.total)` before building the `finance_summary` object.

### Pitfall 6: DB `finance_summary` returns as string from pg, not object
**What goes wrong:** After ingestion, reading `finance_summary` from pg returns it as a JSON string, not a parsed object. The API response includes `"finance_summary": "{\"total_raised\":...}"` (string) instead of an object.
**Why it happens:** pg may return JSONB columns as a string in some drivers. The `pg` library returns JSONB as a JavaScript object by default (it has a built-in type parser for OID 3802), but verify in context.
**How to avoid:** Test that `typeof row.finance_summary === 'object'` after a SELECT. If it's a string, add `JSON.parse()` in the service layer.
**Warning signs:** API response shows `finance_summary` as a JSON-encoded string rather than a nested object.

---

## Code Examples

### Fetching Top Donors for One Committee

```typescript
// Source: live FEC API verification 2026-06-04
interface FecEmployerRow {
  committee_id: string;
  employer: string | null;
  total: number;
  count: number;
  cycle: number;
}

async function getTopDonorsByEmployer(
  committeeId: string,
  cycle: string,
  apiKey: string,
  limit = 10
): Promise<FecEmployerRow[]> {
  const params = new URLSearchParams({
    api_key: apiKey,
    committee_id: committeeId,
    cycle,
    per_page: String(limit + 5), // +5 to filter out null/empty and still get limit
    sort: '-total',
  });

  const resp = await fetch(
    `https://api.open.fec.gov/v1/schedules/schedule_a/by_employer/?${params}`,
    { signal: AbortSignal.timeout(30_000) }
  );
  if (!resp.ok) throw new Error(`FEC by_employer HTTP ${resp.status} for ${committeeId}`);
  const data = await resp.json() as { results: FecEmployerRow[] };
  return data.results.filter(r => r.employer != null && r.employer.trim() !== '');
}
```

### Crosswalk Lookup (JSON endpoint)

```typescript
// Source: verified structure from live fetch of legislators-current.yaml 2026-06-04
interface LegislatorId {
  bioguide: string;
  fec?: string[];
}
interface Legislator {
  id: LegislatorId;
  terms: Array<{ type: 'sen' | 'rep'; start: string; end: string; state: string }>;
}

async function buildBioguideToFecMap(): Promise<Map<string, string>> {
  const resp = await fetch('https://theunitedstates.io/congress-legislators/legislators-current.json');
  const legislators: Legislator[] = await resp.json();
  const map = new Map<string, string>();
  for (const leg of legislators) {
    if (!leg.id.fec || leg.id.fec.length === 0) continue;
    const lastTerm = leg.terms[leg.terms.length - 1];
    if (!lastTerm) continue;
    const isSenate = lastTerm.type === 'sen';
    // Pick the FEC ID that matches their current chamber
    const fecId = leg.id.fec.find(id =>
      isSenate ? id.startsWith('S') : id.startsWith('H')
    ) ?? leg.id.fec[0];
    if (fecId) map.set(leg.id.bioguide, fecId);
  }
  return map;
}
```

### UPDATE pattern for finance_summary

```typescript
// Source: established pool.query pattern per project architecture (pool.query for non-public schemas)
await pool.query(
  `UPDATE essentials.politicians
   SET finance_summary = $1::jsonb
   WHERE id = $2`,
  [JSON.stringify(summaryObject), politicianId]
);
```

### SELECT pattern in essentialsService.ts

```typescript
// Add to existing SELECT in getPoliticiansFlatList():
// p.finance_summary,

// Add to row mapper:
finance_summary: row.finance_summary ?? null,
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| inform.politicians as politician table | essentials.politicians as unified table | Phase 35 (migration 050) | FINA-01 must target essentials, not inform |
| Direct pg query from service layer | Same | Always | All non-public schema reads must use pool.query() |
| FEC individual contributions (transparent_motivations.contributions) | Existing system for detail; new JSONB for summary | Phase 90 (new) | Two-tier: summary snapshot + detail browsing |

**Deprecated/outdated:**
- Adding columns to `inform.politicians`: That table is for CompassV2 stances comparison only. Do not add operational columns to it.

---

## Current Database State

### inform.politicians schema (legacy)
From migration 015 + 033 additions: `id, first_name, last_name, preferred_name, full_name, office_title, photo_origin_url, is_active, created_at, representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, is_vacant`

**No `finance_summary` column.** No action needed on this table.

### essentials.politicians schema (target)
[ASSUMED from dedup-essentials-politicians.ts and fecResearch.ts column references]: Includes `id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id, bioguide_id, photo_origin_url, bio_text, slug, party_short_name, external_global_id, photo_custom_url, last_synced, leg_data_fetched_at, total_years_in_office, data_source, photo_custom_url_manual_override, bio_text_manual_override, full_name_manual_override` + many more.

**No `finance_summary` column.** Migration 268 adds it.

### transparent_motivations.politician_sources (existing crosswalk source)
- `essentials_politician_id` → UUID FK to essentials.politicians
- `source_system` → 'fec_senate' | 'fec_house' | other
- `external_id` → FEC candidate_id string (e.g., 'S8WA00194')
- `research_status` → 'confirmed' | 'needs_research'

Many senators already have confirmed FEC IDs from Phase 73-76 `run-fec-auto-match.ts` runs. These should be used as the primary crosswalk source (Path 2).

### Last applied migration
- `backend/migrations/`: 267 (two files with same number: `267_allen_mayor_office_fix.sql` and `267_ut_2026_primary.sql`)
- Next available: **268**

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `FEC_API_KEY` | FINA-02 ingestion script | Yes | — (set in backend/.env) | None — required |
| `DATABASE_URL` | FINA-01 migration, FINA-02 script | Yes | — | None — required |
| Node.js / tsx | FINA-02 script | Yes | Already used by all scripts | None |
| FEC API endpoint | FINA-02 | Available | Live (verified 2026-06-04) | None |
| congress-legislators JSON endpoint | FINA-02 crosswalk | [ASSUMED] | — | Fall back to YAML + js-yaml |
| Pool connection to remote DB | FINA-01 migration | Yes | — | None — apply via DATABASE_URL |

**Missing dependencies with no fallback:** None — all dependencies are confirmed available.

**Note on migration application:** Per project pattern (v2.2 notes), migrations are applied directly via `psql` to the remote Supabase DB using `DATABASE_URL`. Local Docker/Supabase is not running. Use session pooler at port 5432.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `theunitedstates.io/congress-legislators/legislators-current.json` endpoint remains available | Congress-legislators Crosswalk | Fall back to YAML + js-yaml package; same data, extra parsing step |
| A2 | `essentials.politicians` has a `bioguide_id` column (referenced in fecResearch.ts and dedup script but no migration file found adding it) | Current Database State | Script must handle null `bioguide_id` gracefully; fall back to Path 2 only |
| A3 | Most incumbents already have confirmed FEC IDs in `transparent_motivations.politician_sources` | Crosswalk Strategy | Script may need to rely more heavily on congress-legislators crosswalk |
| A4 | pg driver returns JSONB columns as JavaScript objects (not strings) | Pitfall 6 | Service layer may need `JSON.parse()` wrapper if string is returned |

---

## Open Questions (RESOLVED)

1. **Should "NOT EMPLOYED" / "SELF EMPLOYED" top-donor entries be included?**
   - RESOLVED: Include them. They accurately reflect grass-roots small-donor base. Filter only null/empty employer strings.

2. **Which cycle to use for incumbent senators?**
   - RESOLVED: Always use `cycle=2026` for all politicians. Consistent across the 143-politician set and reflects current fundraising status.

3. **Does `bioguide_id` column actually exist on `essentials.politicians` in the live DB?**
   - RESOLVED: Script handles `bioguide_id IS NULL` gracefully — falls back to Path 2 (politician_sources) for any politician where bioguide_id is null. No blocking dependency on column existence.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | vitest ^2.1.0 |
| Config file | `backend/vitest.config.ts` |
| Quick run command | `cd backend && npm test` |
| Full suite command | `cd backend && npm test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FINA-01 | `finance_summary` column exists on `essentials.politicians` | smoke (DB query) | Manual verification via psql | No — Wave 0 |
| FINA-02 | Ingestion script runs without error; finance_summary populated for federal politicians | manual | Run script + check row count | No — manual |
| FINA-03 | `GET /api/essentials/politicians` response includes `finance_summary` field | unit (source scan) | `cd backend && npm test` | No — Wave 0 |

### Wave 0 Gaps

- [ ] `backend/test/essentialsService-finance-summary.test.ts` — unit test that `finance_summary` appears in `getPoliticiansFlatList` response shape (source scan pattern like existing tests)
- [ ] Smoke test: after migration 268, `SELECT COUNT(*) FROM essentials.politicians WHERE finance_summary IS NOT NULL` should be > 0 after script runs

*(Existing test infrastructure covers MTFCC routing — no gaps there.)*

---

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth changes |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | finance_summary is public data |
| V5 Input Validation | Yes (FEC API response) | Parse and validate FEC response before storing; never spread raw API response into JSONB |
| V6 Cryptography | No | |

### Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Storing unvalidated FEC API response in JSONB | Tampering | Build explicit `{ total_raised, top_donors, cycle, source }` object; never `JSON.stringify(fecRawResponse)` |
| FEC API key in commit | Info Disclosure | Key in `.env` only; already confirmed not in source files |

---

## Sources

### Primary (HIGH confidence)
- Live FEC API calls (2026-06-04): `/v1/candidates/totals/`, `/v1/candidates/search/`, `/v1/schedules/schedule_a/by_employer/` — verified response shapes and field names
- `C:/EV-Accounts/backend/src/lib/fecResearch.ts` — existing FEC candidate search + auto-match pattern
- `C:/EV-Accounts/backend/src/lib/adapters/fecAdapter.ts` — existing FEC Schedule A ingestion pattern
- `C:/EV-Accounts/backend/src/lib/essentialsService.ts` — confirmed API query patterns and response builder
- `C:/EV-Accounts/backend/src/routes/essentialsPoliticians.ts` — confirmed endpoint surface
- `C:/EV-Accounts/backend/migrations/` — migration numbering (last = 267, next = 268)

### Secondary (MEDIUM confidence)
- `legislators-current.yaml` via unitedstates/congress-legislators (fetched 2026-06-04) — confirmed `id.bioguide` + `id.fec[]` structure
- `.planning/phases/73-senator-records/73-01-SUMMARY.md` — bioguide crosswalk pattern established in Phase 73

### Tertiary (LOW confidence / ASSUMED)
- `theunitedstates.io` JSON endpoint availability — assumed based on xlsx/README.md reference in node_modules; not independently verified
- `bioguide_id` column existence on `essentials.politicians` in live DB — referenced in code but no migration file found

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed; no new packages needed
- Architecture: HIGH — existing patterns (pool.query, script runners, service layer) verified in codebase
- FEC API: HIGH — live verified; endpoints and response shapes confirmed
- Crosswalk: MEDIUM — congress-legislators JSON endpoint assumed available; bioguide_id column existence not confirmed via live DB query

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 (FEC API structure is stable; rate limits may change)
