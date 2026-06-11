# Phase 114: fec-script-fix-and-sitting-members — Pattern Map

**Mapped:** 2026-06-11
**Files analyzed:** 1 (fix-fec-name-mismatches.ts — in-place edit only)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `backend/scripts/fix-fec-name-mismatches.ts` | ingestion script | batch + request-response | `backend/scripts/ehn-fec-finance.ts` | exact |

No new files are created. All three requirements (FECF-01, FECF-02, FECF-03) are in-place edits to `fix-fec-name-mismatches.ts`.

---

## Pattern Assignments

### `backend/scripts/fix-fec-name-mismatches.ts` (ingestion script, batch)

This file is the **only edit target**. Three distinct patches are needed.

---

#### PATCH 1 — FECF-01: Committee lookup fallback inside `fetchFecData()`

**Analog:** `backend/scripts/ehn-fec-finance.ts` lines 136–145 + 246–256

**Exact fallback function to copy** (ehn-fec-finance.ts lines 136–145):
```typescript
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

**CRITICAL field name difference:** The inline `principal_committees` from `candidates/search` uses field `.id`. The `/candidate/{id}/committees/` fallback endpoint uses `.committee_id`. Never confuse them. The analog already handles this correctly.

**Integration point** — existing `fetchFecData()` lines 122–126 currently read:
```typescript
const committeeId = searchData.results?.[0]?.principal_committees?.[0]?.id;
if (!committeeId) {
  console.log(`  [skip] No committee for ${fecId}`);
  return null;
}
```

Replace with (pattern from ehn-fec-finance.ts lines 246–256):
```typescript
let committeeId: string | undefined = searchData.results?.[0]?.principal_committees?.[0]?.id;

if (!committeeId) {
  await sleep(SLEEP_MS);
  const fbUrl = `${FEC_BASE}/candidate/${fecId}/committees/?api_key=${apiKey}&per_page=5`;
  const fbResp = await fetch(fbUrl, { signal: AbortSignal.timeout(30_000) });
  if (fbResp.ok) {
    const fbData = await fbResp.json() as { results?: Array<{ committee_id: string }> };
    committeeId = fbData.results?.[0]?.committee_id ?? undefined;
  }
}
if (!committeeId) {
  console.log(`  [skip] No committee for ${fecId}`);
  return null;
}
```

---

#### PATCH 2 — FECF-01 (continued): Multi-cycle totals fallback inside `fetchFecData()`

**Analog:** `backend/scripts/ehn-fec-finance.ts` lines 151–166 (`fetchTotalRaised`)

**Current code** (fix-fec-name-mismatches.ts lines 128–134) hardcodes `FEC_CYCLE`:
```typescript
const totalsUrl = `${FEC_BASE}/candidates/totals/?api_key=${apiKey}&candidate_id=${fecId}&cycle=${FEC_CYCLE}&per_page=1`;
await sleep(SLEEP_MS);
const totalsResp = await fetch(totalsUrl, { signal: AbortSignal.timeout(30_000) });
if (!totalsResp.ok) throw new Error(`FEC totals HTTP ${totalsResp.status}`);
const totalsData = await totalsResp.json() as { results?: Array<{ receipts?: number }> };
const totalRaised = totalsData.results?.[0]?.receipts ?? 0;
```

Replace with multi-cycle fallback (try 2026 → 2024 → 2022, stop at first non-zero):
```typescript
let totalRaised = 0;
let usedCycle = FEC_CYCLE;
for (const cycle of [FEC_CYCLE, '2024', '2022']) {
  const totalsUrl = `${FEC_BASE}/candidates/totals/?api_key=${apiKey}&candidate_id=${fecId}&cycle=${cycle}&per_page=1`;
  await sleep(SLEEP_MS);
  const totalsResp = await fetch(totalsUrl, { signal: AbortSignal.timeout(30_000) });
  if (!totalsResp.ok) throw new Error(`FEC totals HTTP ${totalsResp.status}`);
  const totalsData = await totalsResp.json() as { results?: Array<{ receipts?: number }> };
  const receipts = totalsData.results?.[0]?.receipts ?? 0;
  if (receipts > 0) { totalRaised = receipts; usedCycle = cycle; break; }
}
```

Also update Step 3 (donors) to use `usedCycle` instead of the hardcoded `FEC_CYCLE`:
```typescript
// line 137 — change FEC_CYCLE to usedCycle in donorsUrl:
const donorsUrl = `${FEC_BASE}/schedules/schedule_a/by_employer/?api_key=${apiKey}&committee_id=${committeeId}&cycle=${usedCycle}&per_page=${TOP_DONORS_LIMIT}&sort=-total`;
```

And update the return value to record the actual cycle used:
```typescript
// line 148 — change FEC_CYCLE to usedCycle:
return { total_raised: totalRaised, top_donors: topDonors, cycle: usedCycle, source: 'FEC' };
```

---

#### PATCH 3 — FECF-03: Direct FEC name search for null-fecId politicians (LaMalfa/Swalwell)

**Analog:** `backend/src/lib/fecResearch.ts` lines 168–219 (`searchFecCandidates`) + lines 136–162 (`scoreMatch`, `parseFecName`, `normalize`)

**New function to add** (pattern from fecResearch.ts `searchFecCandidates`):
```typescript
async function resolveViaDirectSearch(
  pol: FedPolitician,
  apiKey: string,
): Promise<string | null> {
  // Look up state from pol — requires adding `representing_state` to FedPolitician interface
  // and the DB query (JOIN essentials.offices o → o.representing_state).
  // For Phase 114 scope (LaMalfa CA-01, Swalwell CA-14), both are CA.
  const state = 'CA';
  const searchUrl = `${FEC_BASE}/candidates/?api_key=${apiKey}&q=${encodeURIComponent(pol.full_name)}&state=${state}&office=H&per_page=20`;
  await sleep(SLEEP_MS);
  const resp = await fetch(searchUrl, { signal: AbortSignal.timeout(30_000) });
  if (!resp.ok) throw new Error(`FEC direct search HTTP ${resp.status}`);
  const data = await resp.json() as {
    results?: Array<{ candidate_id: string; name: string; state: string; office: string }>
  };
  if (!data.results?.length) return null;

  // Pick best match: last-name exact match is sufficient given state+office filters
  const lastName = pol.full_name.toLowerCase().split(' ').pop()!;
  const best = data.results.find(r => r.name.toLowerCase().includes(lastName));
  return best?.candidate_id ?? null;
}
```

**Integration point** — in `main()`, the existing `resolveFecId` null branch (lines 180–185):
```typescript
if (!fecId) {
  console.log(`NO_MATCH  ${pol.full_name} (${pol.chamber_short})`);
  noMatchList.push(pol.full_name);
  stats.no_match++;
  continue;
}
```

Replace with:
```typescript
if (!fecId) {
  if (DRY_RUN) {
    console.log(`NO_MATCH  ${pol.full_name} (${pol.chamber_short}) — would attempt direct search`);
    stats.no_match++;
    continue;
  }
  // Attempt direct FEC name search for politicians with no YAML FEC ID
  const directId = await resolveViaDirectSearch(pol, apiKey);
  if (!directId) {
    console.log(`NO_MATCH  ${pol.full_name} (${pol.chamber_short})`);
    noMatchList.push(pol.full_name);
    stats.no_match++;
    continue;
  }
  console.log(`DIRECT    ${pol.full_name} → ${directId}`);
  stats.matched++;
  fecId = directId; // fall through to existing MATCH path below
  // Upsert politician_sources with DO UPDATE to handle prior partial runs
  await pool.query(`
    INSERT INTO transparent_motivations.politician_sources
      (essentials_politician_id, source_system, external_id, research_status, source_type)
    VALUES ($1, $2, $3, 'confirmed', 'candidate_committee')
    ON CONFLICT (essentials_politician_id, source_system)
    DO UPDATE SET external_id = EXCLUDED.external_id,
                  research_status = EXCLUDED.research_status
  `, [pol.id, 'fec_house', fecId]);
}
```

**Note on `ON CONFLICT` key:** The existing INSERT at line 193 uses `ON CONFLICT DO NOTHING` without a target column list. For LaMalfa/Swalwell use the explicit `ON CONFLICT (essentials_politician_id, source_system)` form with `DO UPDATE` so that if a prior partial run left a row with an empty `external_id`, it gets overwritten. Verify the UNIQUE constraint column names by checking the original `politician_sources` CREATE TABLE migration (not in migrations 190/191 which only add `source_type`).

---

## Shared Patterns

### Pool import
**Source:** `backend/src/lib/db.ts` line 8 / `backend/scripts/fix-fec-name-mismatches.ts` line 22
```typescript
import { pool } from '../src/lib/db.js';
```
All DB writes use `pool.query()` — `transparent_motivations` and `essentials` schemas are NOT in PostgREST exposed schema list. Never use `supabaseAdmin.schema()` for these writes.

### `finance_summary` UPDATE pattern
**Source:** `backend/scripts/fix-fec-name-mismatches.ts` lines 204–207 / `backend/scripts/ehn-fec-finance.ts` lines 208–216
```typescript
await pool.query(
  `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
  [JSON.stringify(summary), pol.id],
);
```
Always `::jsonb` cast. Never string-interpolate the JSON. Check `rowCount` if strictness needed (ehn pattern lines 212–215).

### `politician_sources` INSERT pattern
**Source:** `backend/scripts/fix-fec-name-mismatches.ts` lines 193–198
```typescript
await pool.query(`
  INSERT INTO transparent_motivations.politician_sources
    (essentials_politician_id, source_system, external_id, research_status, source_type)
  VALUES ($1, $2, $3, 'confirmed', 'candidate_committee')
  ON CONFLICT DO NOTHING
`, [pol.id, source_system, fecId]);
```
For LaMalfa/Swalwell (FECF-03), use `ON CONFLICT (essentials_politician_id, source_system) DO UPDATE SET external_id = EXCLUDED.external_id, research_status = EXCLUDED.research_status` instead to handle prior partial runs.

### FEC API fetch pattern
**Source:** `backend/scripts/fix-fec-name-mismatches.ts` lines 119–120 / `backend/scripts/ehn-fec-finance.ts` lines 119–128
```typescript
await sleep(SLEEP_MS);
const resp = await fetch(url, { signal: AbortSignal.timeout(30_000) });
if (!resp.ok) throw new Error(`FEC <endpoint> HTTP ${resp.status}`);
```
Always: sleep before call, AbortSignal timeout, throw on non-ok. Never skip the sleep — 2000ms in fix script, 1500ms in ehn script. Fix script uses 2000ms; preserve that.

### Error handling per politician (non-aborting loop)
**Source:** `backend/scripts/fix-fec-name-mismatches.ts` lines 200–214
```typescript
try {
  const summary = await fetchFecData(fecId, apiKey);
  if (!summary) { stats.no_committee++; continue; }
  await pool.query(...);
  stats.written++;
} catch (err) {
  console.error(`  [ERR] ${pol.full_name}: ${(err as Error).message}`);
  stats.error++;
}
```
Per-politician errors increment `stats.error` and continue the loop. Script never aborts the full batch on a single politician failure.

### API key logging (security)
**Source:** `backend/scripts/ehn-fec-finance.ts` line 235
```typescript
console.log(`[script] FEC API key: ${apiKey.slice(0, 8)}...`);
```
Never log the full API key. Slice to first 8 chars + `...`.

---

## No Analog Found

None. All patterns have direct analogs in the codebase.

---

## Key Patch Summary for Planner

| Req | Location in file | What changes | Copy from |
|-----|-----------------|--------------|-----------|
| FECF-01 | `fetchFecData()` after line 122 | Add `fetchCommitteeIdFallback()` call when `committeeId` is undefined | `ehn-fec-finance.ts` lines 136–145, 246–256 |
| FECF-01 | `fetchFecData()` lines 128–134 | Replace hardcoded totals fetch with 3-cycle loop (2026→2024→2022) | `ehn-fec-finance.ts` lines 151–166 |
| FECF-01 | `fetchFecData()` lines 137, 148 | Change `FEC_CYCLE` → `usedCycle` in donors URL and return value | — |
| FECF-02 | No code change needed | Fixed by FECF-01 — Ivey/Self/Warnock/Cruz already in `politician_sources` with `confirmed` status | — |
| FECF-03 | `main()` null-fecId branch line 180 | Add `resolveViaDirectSearch()` fallback; upsert `politician_sources` with `DO UPDATE` | `fecResearch.ts` lines 168–219 |

---

## Metadata

**Analog search scope:** `backend/scripts/`, `backend/src/lib/`
**Files read:** `fix-fec-name-mismatches.ts`, `ehn-fec-finance.ts`, `fecResearch.ts`, `campaignFinanceService.ts`, `db.ts`, migrations 190/191
**Pattern extraction date:** 2026-06-11
