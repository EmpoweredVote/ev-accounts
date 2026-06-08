# Phase 107: DC Finance - Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 1 new file (+ 1 conditional assessment document)
**Analogs found:** 2 / 1 (2 strong analogs for the single new script)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `backend/scripts/ehn-fec-finance.ts` | utility script | request-response (FEC API → DB write) | `backend/scripts/run-fec-finance-summary.ts` | exact |
| `107-OCF-ASSESSMENT.md` (conditional) | documentation | N/A — write only if DC OCF has no accessible API | none | N/A |

---

## Pattern Assignments

### `backend/scripts/ehn-fec-finance.ts` (utility script, FEC API → DB)

**Primary analog:** `backend/scripts/run-fec-finance-summary.ts`
**Secondary analog:** `backend/scripts/fix-fec-name-mismatches.ts`

**Key simplification:** This script is single-politician, not a loop. All multi-politician
scaffolding (DB query for federal politicians list, FederalPolitician interface, crosswalk
for the full roster, per-politician loop counters) is replaced by hardcoded EHN constants.
The three FEC API functions and `updateFinanceSummary` copy verbatim.

---

#### Imports pattern (analog lines 27-29):

```typescript
import 'dotenv/config';
import { load as yamlLoad } from 'js-yaml';
import { pool } from '../src/lib/db.js';
```

Note: `js-yaml` is only needed if looking up EHN's FEC ID via the congress-legislators YAML
crosswalk. Since EHN's bioguide_id `N000147` is known, the script can fetch YAML and do a
targeted lookup — same `buildCrosswalkMaps` pattern but narrowed to a single result.
Alternatively, if the FEC candidate ID is pre-known, skip YAML entirely and hardcode it.

---

#### Constants pattern (analog lines 35-48):

```typescript
// Hardcode EHN-specific values instead of the loop-wide constants
const EHN_POLITICIAN_UUID = '4dbc8de1-9984-42a5-b2aa-5445bf0619b9';
const EHN_BIOGUIDE_ID = 'N000147';

const SLEEP_BETWEEN_FEC_CALLS_MS = 1500; // stay under 1000 req/hr
const FEC_CYCLE = '2026';
const TOP_DONORS_LIMIT = 10;
const LEGISLATORS_YAML_URL =
  'https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml';

const FEC_BASE = 'https://api.open.fec.gov/v1';
const FEC_SEARCH_URL  = `${FEC_BASE}/candidates/search/`;
const FEC_TOTALS_URL  = `${FEC_BASE}/candidates/totals/`;
const FEC_BY_EMPLOYER_URL = `${FEC_BASE}/schedules/schedule_a/by_employer/`;
```

---

#### Types pattern (analog lines 54-67):

```typescript
interface FecEmployerRow {
  committee_id: string;
  employer: string | null;
  total: number;
  count: number;
  cycle: number;
}

interface FinanceSummary {
  total_raised: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'FEC';
}
```

Copy verbatim — same JSONB shape that `essentials.politicians.finance_summary` stores and
`essentialsService.ts` serializes (confirmed at lines 82-91 of `essentialsService.ts`).

---

#### sleep helper (analog lines 86-88):

```typescript
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

---

#### YAML crosswalk — EHN-specific lookup (adapted from analog lines 113-154):

The full `buildCrosswalkMaps()` builds maps for all 535 legislators. For EHN, narrow to a
single-entry lookup:

```typescript
async function resolveEhnFecId(): Promise<string> {
  const resp = await fetch(LEGISLATORS_YAML_URL, { signal: AbortSignal.timeout(60_000) });
  if (!resp.ok) throw new Error(`Failed to fetch legislators-current.yaml: HTTP ${resp.status}`);
  const legislators = yamlLoad(await resp.text()) as Array<{
    id: { bioguide: string; fec?: string[] };
    terms: Array<{ type: string }>;
  }>;
  const leg = legislators.find(l => l.id.bioguide === EHN_BIOGUIDE_ID);
  if (!leg?.id.fec?.length) {
    throw new Error(`No FEC ID found for bioguide_id ${EHN_BIOGUIDE_ID}`);
  }
  // EHN is a House delegate — prefer H-prefix FEC ID
  return leg.id.fec.find(id => id.startsWith('H')) ?? leg.id.fec[0];
}
```

---

#### Step 1 — fetchCommitteeId (analog lines 243-259):

```typescript
async function fetchCommitteeId(fecCandidateId: string, apiKey: string): Promise<string | null> {
  const params = new URLSearchParams({
    api_key: apiKey,
    candidate_id: fecCandidateId,
    per_page: '1',
  });
  const resp = await fetch(`${FEC_SEARCH_URL}?${params}`, {
    signal: AbortSignal.timeout(30_000),
  });
  if (!resp.ok) {
    throw new Error(`FEC candidates/search HTTP ${resp.status} for ${fecCandidateId}`);
  }
  const data = (await resp.json()) as {
    results: Array<{ principal_committees: Array<{ committee_id: string }> }>;
  };
  return data.results[0]?.principal_committees?.[0]?.committee_id ?? null;
}
```

**committee_id fallback** (from CONTEXT.md D-02 / project memory): if
`principal_committees` is empty, call `GET /v1/candidate/{id}/committees/?per_page=5`:

```typescript
// Fallback: candidates/search may return empty principal_committees for delegates
// Use /v1/candidate/{id}/committees/ which returns all committees regardless of cycle
async function fetchCommitteeIdFallback(fecCandidateId: string, apiKey: string): Promise<string | null> {
  const params = new URLSearchParams({ api_key: apiKey, per_page: '5' });
  const resp = await fetch(
    `${FEC_BASE}/candidate/${fecCandidateId}/committees/?${params}`,
    { signal: AbortSignal.timeout(30_000) },
  );
  if (!resp.ok) return null;
  const data = (await resp.json()) as { results: Array<{ committee_id: string }> };
  return data.results[0]?.committee_id ?? null;
}
```

---

#### Step 2 — fetchTotalRaised (analog lines 266-281):

```typescript
async function fetchTotalRaised(fecCandidateId: string, apiKey: string): Promise<number> {
  const params = new URLSearchParams({
    api_key: apiKey,
    candidate_id: fecCandidateId,
    cycle: FEC_CYCLE,
    per_page: '1',
  });
  const resp = await fetch(`${FEC_TOTALS_URL}?${params}`, {
    signal: AbortSignal.timeout(30_000),
  });
  if (!resp.ok) {
    throw new Error(`FEC candidates/totals HTTP ${resp.status} for ${fecCandidateId}`);
  }
  const data = (await resp.json()) as { results: Array<{ receipts: unknown }> };
  return Number(data.results[0]?.receipts ?? 0); // always coerce — never store raw string
}
```

---

#### Step 3 — fetchTopDonorsByEmployer (analog lines 289-317):

```typescript
async function fetchTopDonorsByEmployer(
  committeeId: string,
  apiKey: string,
): Promise<Array<{ employer: string; amount: number; count: number }>> {
  const params = new URLSearchParams({
    api_key: apiKey,
    committee_id: committeeId,
    cycle: FEC_CYCLE,
    per_page: String(TOP_DONORS_LIMIT + 5), // fetch extra to account for null filtering
    sort: '-total',
  });
  const resp = await fetch(`${FEC_BY_EMPLOYER_URL}?${params}`, {
    signal: AbortSignal.timeout(30_000),
  });
  if (!resp.ok) {
    throw new Error(`FEC schedule_a/by_employer HTTP ${resp.status} for ${committeeId}`);
  }
  const data = (await resp.json()) as { results: FecEmployerRow[] };
  return data.results
    .filter((r): r is FecEmployerRow & { employer: string } =>
      r.employer != null && r.employer.trim() !== '',
    )
    .slice(0, TOP_DONORS_LIMIT)
    .map(r => ({
      employer: r.employer,
      amount: Number(r.total),
      count: Number(r.count),
    }));
}
```

---

#### DB write pattern (analog lines 323-328):

```typescript
async function updateFinanceSummary(politicianId: string, summary: FinanceSummary): Promise<void> {
  await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId],
  );
}
```

Copy exactly. The `::jsonb` explicit cast and parameterized form are required.

---

#### main() pattern (analog lines 334-461, trimmed for single-politician):

```typescript
async function main(): Promise<void> {
  if (!process.env.FEC_API_KEY) {
    console.error('ERROR: FEC_API_KEY is not set.');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL is not set');
    process.exit(1);
  }

  const apiKey = process.env.FEC_API_KEY;
  console.log('[ehn-fec-finance] EHN FEC finance ingestion');
  console.log(`[ehn-fec-finance] Politician UUID: ${EHN_POLITICIAN_UUID}`);
  console.log(`[ehn-fec-finance] Cycle: ${FEC_CYCLE}`);

  // Resolve FEC candidate ID via YAML crosswalk
  const fecId = await resolveEhnFecId();
  console.log(`[ehn-fec-finance] FEC ID: ${fecId}`);

  // Step 1: committee ID
  await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
  let committeeId = await fetchCommitteeId(fecId, apiKey);
  if (!committeeId) {
    console.log('[ehn-fec-finance] principal_committees empty — trying fallback endpoint...');
    await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
    committeeId = await fetchCommitteeIdFallback(fecId, apiKey);
  }
  if (!committeeId) throw new Error(`No committee found for FEC ID ${fecId}`);
  console.log(`[ehn-fec-finance] Committee: ${committeeId}`);

  // Step 2: total raised
  await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
  const totalRaised = await fetchTotalRaised(fecId, apiKey);
  console.log(`[ehn-fec-finance] Total raised: $${totalRaised.toLocaleString()}`);

  // Step 3: top donors
  await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
  const topDonors = await fetchTopDonorsByEmployer(committeeId, apiKey);
  console.log(`[ehn-fec-finance] Top donors: ${topDonors.length} entries`);

  // Build finance_summary — never spread raw FEC response
  const summary: FinanceSummary = {
    total_raised: totalRaised,
    top_donors: topDonors,
    cycle: FEC_CYCLE,
    source: 'FEC',
  };

  // Write to DB
  await updateFinanceSummary(EHN_POLITICIAN_UUID, summary);
  console.log('[ehn-fec-finance] finance_summary written.');
  console.log(JSON.stringify(summary, null, 2));

  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[ehn-fec-finance] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore */ }
  process.exit(1);
});
```

---

### `107-OCF-ASSESSMENT.md` (conditional documentation)

**Analog:** None — no existing "no-data" assessment files in the codebase.
**Applicable only if:** DC OCF at ocf.dc.gov provides no REST API or bulk download.
**Format guidance from CONTEXT.md D-05/Claude's Discretion:** A brief paragraph is sufficient.
Minimum content: what was checked, what was found, why ingestion is not feasible, and that
DCFI-02 is closed with this finding.

---

## Shared Patterns

### pool import

**Source:** `backend/src/lib/db.ts` (lines 1-20)
**Apply to:** `ehn-fec-finance.ts`

```typescript
// Import exactly as other scripts do — note the .js extension (ESM)
import { pool } from '../src/lib/db.js';
```

Pool is Session Pooler (port 5432). `pool.end()` must be called before `process.exit(0)` on
all exit paths — both success and fatal catch.

---

### Env guards

**Source:** `backend/scripts/run-fec-finance-summary.ts` (lines 336-343)
**Apply to:** `ehn-fec-finance.ts`

```typescript
if (!process.env.FEC_API_KEY) {
  console.error('ERROR: FEC_API_KEY is not set. Register at https://api.data.gov/signup/');
  process.exit(1);
}
if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}
```

Both checks must appear at the top of `main()` before any I/O.

---

### AbortSignal.timeout on every fetch

**Source:** `backend/scripts/run-fec-finance-summary.ts` (lines 249, 274, 302)
**Apply to:** Every `fetch()` call in `ehn-fec-finance.ts`

```typescript
// Every FEC fetch must include this — never omit
signal: AbortSignal.timeout(30_000)
// YAML fetch uses longer timeout
signal: AbortSignal.timeout(60_000)
```

---

### finance_summary JSONB shape

**Source:** `backend/src/lib/essentialsService.ts` (lines 82-91)
**Apply to:** The `FinanceSummary` object built in `ehn-fec-finance.ts`

```typescript
// Confirmed interface from essentialsService.ts — must match exactly
export interface FinanceSummary {
  total_raised: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'FEC';  // EHN uses 'FEC'; DC OCF would use 'DC_OCF' per D-06
}
```

The `source` field must be the string literal `'FEC'` (not a variable) since it discriminates
the data origin for frontend consumers.

---

### Rate limiting between FEC calls

**Source:** `backend/scripts/run-fec-finance-summary.ts` (lines 385, 396, 401)
**Apply to:** Every FEC API call in `ehn-fec-finance.ts`

```typescript
// 1500ms sleep before EVERY FEC API call, including the fallback committee endpoint
await sleep(SLEEP_BETWEEN_FEC_CALLS_MS); // 1500ms
```

The YAML fetch does not count against the FEC rate limit — no sleep needed before it.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `107-OCF-ASSESSMENT.md` | documentation | N/A | No precedent for "no accessible API" findings in this codebase |

---

## Metadata

**Analog search scope:** `backend/scripts/`, `backend/src/lib/`, `backend/src/routes/`
**Files scanned:** 4 (`run-fec-finance-summary.ts`, `fix-fec-name-mismatches.ts`, `db.ts`, `essentialsService.ts`)
**Pattern extraction date:** 2026-06-08
