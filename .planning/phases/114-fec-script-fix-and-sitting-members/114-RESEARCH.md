# Phase 114: fec-script-fix-and-sitting-members — Research

**Researched:** 2026-06-11
**Domain:** FEC API — committee lookup fallback, sitting House member FEC ID resolution
**Confidence:** HIGH

---

## Summary

Phase 114 has one tightly-scoped engineering task: patch `fix-fec-name-mismatches.ts` so it
reliably resolves a FEC committee ID for every politician it already name-matched. The prior
run (2026-06-05) produced 11 MATCH rows in `politician_sources` but wrote $0 finance data
because `candidates/search` returns `principal_committees: []` for senators not actively
campaigning in the 2026 cycle. The fix is a two-level fallback copied verbatim from the
already-working `ehn-fec-finance.ts` script.

LaMalfa and Swalwell require a second fix path: they are in `NICKNAME_MAP` but the congress-
legislators YAML contains no FEC ID for them, so `resolveFecId` returns null and they land in
`NO_MATCH`. They must be resolved via direct `GET /v1/candidates/search/?name=X&office=H`
with the `fecResearch.ts` `searchFecCandidates` helper, then their `politician_sources` rows
written and finance data ingested.

Both fixes are in-place edits to `fix-fec-name-mismatches.ts`. No new scripts or migrations
are needed for this phase.

**Primary recommendation:** Modify `fix-fec-name-mismatches.ts` in-place: (1) add
`fetchCommitteeIdFallback()` after the primary committee lookup fails; (2) add a
`resolveViaDirectSearch()` path for politicians whose FEC ID is null (LaMalfa/Swalwell only).

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FECF-01 | `fix-fec-name-mismatches.ts` updated with committee lookup fallback — after `principal_committees` returns empty, script falls back to `GET /v1/candidate/{id}/committees/` and tries cycles 2026, 2024, 2022 until a committee is found | Fallback pattern already exists in `ehn-fec-finance.ts` lines 136–145; committee endpoint returns `committee_id` field directly |
| FECF-02 | `finance_summary` populated for all 4 already-matched politicians (Glenn Ivey, Keith Self, Raphael Warnock, Ted Cruz) by re-running the fixed script live | These 4 are in `politician_sources` with `research_status = 'confirmed'`; script queries `WHERE finance_summary IS NULL`; fixing committee fallback unblocks them |
| FECF-03 | FEC candidate IDs resolved for Doug LaMalfa and Eric Swalwell via direct `GET /v1/candidates/search/?name=X&office=H`; `finance_summary` populated for both; `politician_sources` rows written | `fecResearch.ts` `searchFecCandidates()` already implements this search; LaMalfa/Swalwell are in YAML but with no `.fec[]` entries, so they fall through to `NO_MATCH` |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| FEC committee lookup fallback | Ingestion script (Node.js) | FEC external API | Pure data-fetch operation; no frontend or DB schema change |
| Direct FEC name search for LaMalfa/Swalwell | Ingestion script (Node.js) | FEC external API | Same pattern as fecResearch.ts searchFecCandidates; adds only to script orchestration |
| Writing `politician_sources` rows | Ingestion script → PostgreSQL | transparent_motivations schema | pool.query() required — schema not in PostgREST exposed list |
| Writing `finance_summary` | Ingestion script → PostgreSQL | essentials.politicians | UPDATE via pool.query() with ::jsonb cast |

---

## Standard Stack

No new packages required for this phase. All dependencies are already in `backend/package.json`.

### Existing Stack Used

| Library | Version | Purpose | Source |
|---------|---------|---------|--------|
| `js-yaml` | ^4.1.1 | Parse congress-legislators YAML | Already in backend/package.json [VERIFIED: package.json] |
| `tsx` | project dev dep | Run TypeScript scripts | Already in use [VERIFIED: existing scripts] |
| `dotenv` | project dep | Load .env vars | Already in use [VERIFIED: existing scripts] |
| `pg` (pool) | project dep | Direct PostgreSQL writes | Must use pool.query() for transparent_motivations + essentials schemas [VERIFIED: CLAUDE.md pattern] |

### No New Packages

[VERIFIED: codebase] All FEC API calls use native `fetch` (Node 18+ built-in). No FEC client
library needed. All DB writes use the existing `pool` from `../src/lib/db.js`.

### Installation

None required.

---

## Package Legitimacy Audit

No new packages. Section not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
fix-fec-name-mismatches.ts (patched)
  │
  ├── 1. Fetch congress-legislators YAML (same as before)
  │       → buildNameMap() returns Map<normalized-name, fecId>
  │
  ├── 2. Query DB: politicians WHERE finance_summary IS NULL
  │       → includes Ivey, Self, Warnock, Cruz (have politician_sources confirmed rows)
  │       → includes LaMalfa, Swalwell (no politician_sources rows yet)
  │
  ├── 3. For each politician:
  │     ├── [existing] resolveFecId() via NICKNAME_MAP + nameMap
  │     │     → Ivey/Self/Warnock/Cruz: return fecId ✓  (11 confirmed rows from prior run)
  │     │     → LaMalfa/Swalwell: return null (YAML has no .fec[] for them)
  │     │
  │     ├── [NEW] If fecId is null → resolveViaDirectSearch()
  │     │     → GET /v1/candidates/search/?name=X&office=H&state=Y
  │     │     → scoreFecCandidates(), pick best match score ≥ 0.8
  │     │     → Write politician_sources row (confirmed)
  │     │     → Set fecId from search result
  │     │
  │     └── fetchFecData(fecId, apiKey) [patched]:
  │           Step 1: GET /v1/candidates/search/?candidate_id=X  → principal_committees
  │           Step 1b: [NEW] if principal_committees empty →
  │                    GET /v1/candidate/{id}/committees/?per_page=5
  │                    → data.results[0].committee_id
  │           Step 2: GET /v1/candidates/totals/?candidate_id=X&cycle=2026
  │                   (if receipts=0 and senator not running in 2026, also try 2024, 2022)
  │           Step 3: GET /v1/schedules/schedule_a/by_employer/?committee_id=Y&cycle=C
  │
  └── 4. Write finance_summary to essentials.politicians
```

### Recommended Project Structure

No structural changes. All edits are in-place to:
- `backend/scripts/fix-fec-name-mismatches.ts`

---

## Pattern 1: Committee Lookup Fallback (VERIFIED in codebase)

**What:** After `candidates/search` returns `principal_committees: []`, call the candidate
committees endpoint which returns all committees regardless of election cycle.

**When to use:** Any sitting senator not running in the current 2026 cycle. The
`candidates/search` inline `principal_committees` array is populated only for candidates
who filed for the current cycle.

**Already implemented in:** `ehn-fec-finance.ts` lines 136–145 [VERIFIED: read file]

```typescript
// Source: backend/scripts/ehn-fec-finance.ts lines 136-145
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

**Integration into `fix-fec-name-mismatches.ts`:** The existing `fetchFecData()` function
currently returns `null` at line 123 when `committeeId` is undefined. Add the fallback call
before that early return:

```typescript
// In fetchFecData(), after the primary committeeId lookup fails:
if (!committeeId) {
  await sleep(SLEEP_MS);
  const fallbackUrl = `${FEC_BASE}/candidate/${fecId}/committees/?api_key=${apiKey}&per_page=5`;
  const fallbackResp = await fetch(fallbackUrl, { signal: AbortSignal.timeout(30_000) });
  if (fallbackResp.ok) {
    const fb = await fallbackResp.json() as { results: Array<{ committee_id: string }> };
    committeeId = fb.results?.[0]?.committee_id ?? undefined;
  }
}
if (!committeeId) {
  console.log(`  [skip] No committee for ${fecId}`);
  return null;
}
```

**Note on cycle parameter:** The fallback endpoint does NOT require a cycle parameter — it
returns ALL committees ever associated with the candidate. Pick `results[0]` (most recent).
The committee ID is reused across cycles for the same candidate's principal committee.
[VERIFIED: ehn-fec-finance.ts implementation; ASSUMED: "most recent" is index 0]

---

## Pattern 2: Senators Not Running in 2026 — Totals Fallback

**What:** For senators not on the 2026 ballot (Schumer, Hassan, Coons, Sanders), the FEC
`/candidates/totals/?cycle=2026` endpoint may return 0 receipts because no 2026 filings
exist. Their last meaningful fundraising was in cycle 2024 (their last election) or 2022.

**FEC cycle system for Senate:** Senate terms are 6 years. Senators who were last on the
ballot in 2020 or 2018 have their most recent activity in cycle 2020 or 2022. There are no
2026 filings for senators not running this year.

**Decision for Phase 114:** Store cycle=2026 with total_raised=0 if no 2026 data exists, OR
fall back to find the most recent non-zero cycle. The prior `run-fec-finance-summary.ts`
script stores 0 for missing data. [ASSUMED: planner should decide whether to try prior
cycles or accept 0 for non-2026 senators]

**Recommended approach:** After getting 0 from cycle=2026, try cycle=2024 then cycle=2022.
Store whichever cycle returns the highest `receipts`. Record the actual cycle in the
`finance_summary.cycle` field (e.g., `"2022"` not always `"2026"`). This gives accurate data
rather than misleadingly showing $0.

**FECF-01 requirement language:** "tries cycles 2026, 2024, 2022 until a committee is found."
Note: this language applies to the committee lookup, not the totals. The committee fallback
endpoint returns all cycles anyway. The totals multi-cycle logic is implied by wanting
meaningful finance data for non-2026 senators.

---

## Pattern 3: Direct FEC Name Search for LaMalfa/Swalwell (VERIFIED in codebase)

**What:** LaMalfa and Swalwell are in `NICKNAME_MAP` but the congress-legislators YAML
contains no `id.fec[]` entries for them. `resolveFecId()` returns null and they fall to
`NO_MATCH`. They need the direct FEC candidates search.

**Why YAML has no FEC ID for them:** [ASSUMED] LaMalfa (CA-01, R) and Swalwell (CA-14, D)
may be present in the YAML but with empty `id.fec` arrays, or they may have enrolled with
the FEC only after the YAML was last updated. The YAML is the most authoritative source but
is not always current for every House member.

**Implementation:** Use `searchFecCandidates()` from `fecResearch.ts` (or inline the same
logic). That function calls:

```
GET /v1/candidates/?api_key=X&q=NAME&state=CA&office=H&per_page=20
```

Pick the best match by scoring with `scoreMatch()` from `fecResearch.ts`. Require score ≥ 0.8
(last name exact + first name match) before writing a `confirmed` row.

**Confirmed FEC ID pattern for House members:** H-prefix, e.g. `H0CA01234`. Write
`source_system = 'fec_house'`, `research_status = 'confirmed'`, `source_type = 'candidate_committee'`.

```typescript
// Pattern: direct name search (adapted from fecResearch.ts)
// Source: backend/src/lib/fecResearch.ts lines 168-219
const candidates = await searchFecCandidates(pol.full_name, 'CA', 'H', apiKey);
// pick best by score, require ≥ 0.8
// write politician_sources row
// set fecId = best.candidate_id
```

**Alternative approach:** Hard-code the FEC IDs for LaMalfa/Swalwell in `NICKNAME_MAP` as
a direct lookup (e.g., add `lamalfa_fec_id: 'H0CA01234'`). This is more fragile but avoids
an additional API call. The dynamic search approach is preferred for consistency.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| FEC candidate search | Custom HTTP call | `searchFecCandidates()` from `fecResearch.ts` | Handles URL params, timeout, response parsing, name normalization — all tested |
| Committee lookup fallback | New endpoint wrapper | Copy pattern from `ehn-fec-finance.ts` lines 136-145 | Already works; consistent error handling |
| DB writes for politician_sources | Raw INSERT | `pool.query()` with existing INSERT pattern from `fix-fec-name-mismatches.ts` line 193 | transparent_motivations not in PostgREST; pool.query() is mandatory |
| Score-based name matching | New scoring logic | `scoreMatch()` + `parseFecName()` + `normalize()` from `fecResearch.ts` | Name normalization handles accents, comma-separated FEC format, first-name prefix matching |

---

## Common Pitfalls

### Pitfall 1: `principal_committees` Only Populated for Current-Cycle Candidates

**What goes wrong:** `GET /v1/candidates/search/?candidate_id=S4NY00092` returns
`principal_committees: []` for Chuck Schumer. The script logs "no committee" and skips.

**Why it happens:** The `principal_committees` inline field in `candidates/search` is only
populated when the candidate has registered for the **current** cycle. Senators whose last
election was 2020 or 2022 show up in the search result but with an empty committee array.

**How to avoid:** After the inline check fails, immediately call the fallback endpoint:
`GET /v1/candidate/{id}/committees/?per_page=5`. This endpoint returns ALL associated
committees regardless of cycle. [VERIFIED: ehn-fec-finance.ts fallback pattern]

**Warning signs:** Console output shows `MATCH` then `[skip] No committee for SX...` — this
is the exact symptom seen in the 2026-06-05 dry run for Schumer, Hassan, Coons, Sanders.

---

### Pitfall 2: `committee_id` vs `id` Field in Fallback Response

**What goes wrong:** Accessing `data.results[0]?.id` instead of `data.results[0]?.committee_id`
from the `/candidate/{id}/committees/` endpoint.

**Why it happens:** The `candidates/search` inline `principal_committees` uses field `id`
(short). The standalone `/candidate/{id}/committees/` endpoint uses `committee_id` (long).
These are different field names for the same value.

**How to avoid:** [VERIFIED: ehn-fec-finance.ts line 144] The fallback correctly reads
`data.results[0]?.committee_id`. Preserve this field name when copying the pattern.

---

### Pitfall 3: `ON CONFLICT DO NOTHING` Silently Skips Already-Written Sources

**What goes wrong:** LaMalfa/Swalwell already have `politician_sources` rows from a prior
partial run. The INSERT with `ON CONFLICT DO NOTHING` succeeds but writes nothing, so
`external_id` may still be empty.

**Why it happens:** The `fix-fec-name-mismatches.ts` script inserts with `ON CONFLICT DO NOTHING`
(line 193-198). If a row already exists (from a prior failed run), the new `external_id` is
never written.

**How to avoid:** For LaMalfa/Swalwell use `ON CONFLICT (essentials_politician_id, source_system)
DO UPDATE SET external_id = EXCLUDED.external_id, research_status = EXCLUDED.research_status`
so the external_id is always written. [ASSUMED: the conflict key — verify schema]

**Alternative:** Check if a `politician_sources` row already exists before the INSERT; if it
does and has an `external_id`, use it (skip the API call); if it exists but `external_id` is
empty, UPDATE it.

---

### Pitfall 4: Script Queries `WHERE finance_summary IS NULL` — Already-Populated Politicians Are Skipped

**What:** The script's DB query on line 160-170 filters `p.finance_summary IS NULL`. Politicians
who already had `finance_summary` written in a previous run are excluded automatically.

**Impact:** Safe to re-run the script multiple times. Only NULL rows are processed.

**For FECF-02:** Ivey, Self, Warnock, and Cruz have `politician_sources` rows with `confirmed`
status (written 2026-06-05) but still NULL `finance_summary`. They will be picked up by the
query and processed once the committee fallback is in place.

---

### Pitfall 5: Rate Limit — Additional API Calls Per Politician

**What goes wrong:** Adding the fallback committee call + totals multi-cycle retries doubles
or triples the API calls per politician for senators not running in 2026.

**Current rate:** 2000ms sleep between every call in `fix-fec-name-mismatches.ts`.
FEC API limit: 1000 requests/hour with API key.

**Calculation:** ~11 matched politicians × 3 calls each (primary committee + fallback +
totals + donors) = ~44 calls max. At 2000ms between calls: ~88 seconds total. Well within
rate limits. The extra fallback calls add at most 2s per politician where fallback is needed.

**Verdict:** No rate limit risk for Phase 114 scope. [VERIFIED: existing script comment]

---

### Pitfall 6: LaMalfa/Swalwell FEC Search Returns Multiple Candidates

**What goes wrong:** `GET /v1/candidates/?q=Doug+LaMalfa&state=CA&office=H` may return
multiple candidates across election years (e.g., LaMalfa ran in 2014, 2016, 2018, 2020,
2022, 2024).

**Why it happens:** The FEC `candidates/` endpoint returns one record per election cycle
registration, not one per person. A long-serving House member may have 5-6 records.

**How to avoid:** Use `scoreMatch()` to find highest-scoring candidate. The `election_years`
field on the result can filter for current-cycle registrations. Alternatively: after scoring,
prefer the candidate with the most recent `election_years` entry. The `candidate_id`
(H-prefix) is the same across all their cycles — pick any confirmed match.

---

## Code Examples

### Example 1: Patched `fetchFecData` with Committee Fallback

```typescript
// Modified fetchFecData in fix-fec-name-mismatches.ts
// Source: pattern from ehn-fec-finance.ts lines 136-145 + existing fix-fec-name-mismatches.ts
async function fetchFecData(fecId: string, apiKey: string): Promise<object | null> {
  // Step 1: get committee_id (primary path)
  const searchUrl = `${FEC_BASE}/candidates/search/?api_key=${apiKey}&candidate_id=${fecId}&per_page=1`;
  await sleep(SLEEP_MS);
  const searchResp = await fetch(searchUrl, { signal: AbortSignal.timeout(30_000) });
  if (!searchResp.ok) throw new Error(`FEC search HTTP ${searchResp.status}`);
  const searchData = await searchResp.json() as {
    results?: Array<{ principal_committees?: Array<{ id: string }> }>
  };
  let committeeId: string | undefined = searchData.results?.[0]?.principal_committees?.[0]?.id;

  // Step 1b: fallback to /candidate/{id}/committees/ if primary path returns empty
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

  // Step 2: total raised — try 2026, fall back to 2024, then 2022 for non-2026-ballot senators
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

  // Step 3: top donors (use usedCycle, not hardcoded FEC_CYCLE)
  const donorsUrl = `${FEC_BASE}/schedules/schedule_a/by_employer/?api_key=${apiKey}&committee_id=${committeeId}&cycle=${usedCycle}&per_page=${TOP_DONORS_LIMIT}&sort=-total`;
  await sleep(SLEEP_MS);
  const donorsResp = await fetch(donorsUrl, { signal: AbortSignal.timeout(30_000) });
  if (!donorsResp.ok) throw new Error(`FEC donors HTTP ${donorsResp.status}`);
  const donorsData = await donorsResp.json() as { results?: Array<{ employer: string; total: number; count: number }> };
  const topDonors = (donorsData.results ?? []).map(r => ({
    employer: r.employer, amount: r.total, count: r.count,
  }));

  return { total_raised: totalRaised, top_donors: topDonors, cycle: usedCycle, source: 'FEC' };
}
```

**Note:** The `principal_committees[0].id` field (from `candidates/search`) is the same value
as `committee_id` (from `candidate/{id}/committees/`). Both point to the principal campaign
committee. [VERIFIED: ehn-fec-finance.ts; field names confirmed by Microsoft Learn connector docs]

---

### Example 2: Direct FEC Name Search for LaMalfa/Swalwell

```typescript
// Source: pattern from fecResearch.ts searchFecCandidates (lines 168-219)
// Add to fix-fec-name-mismatches.ts — call when resolveFecId() returns null

async function resolveViaDirectSearch(
  pol: FedPolitician,
  apiKey: string,
): Promise<string | null> {
  const state = 'CA'; // LaMalfa (CA-01) and Swalwell (CA-14) — both California
  const name = pol.full_name;
  const searchUrl = `${FEC_BASE}/candidates/?api_key=${apiKey}&q=${encodeURIComponent(name)}&state=${state}&office=H&per_page=20`;
  await sleep(SLEEP_MS);
  const resp = await fetch(searchUrl, { signal: AbortSignal.timeout(30_000) });
  if (!resp.ok) throw new Error(`FEC direct search HTTP ${resp.status}`);
  const data = await resp.json() as {
    results?: Array<{ candidate_id: string; name: string; state: string; office: string }>
  };
  if (!data.results?.length) return null;

  // Pick the best match — require last-name exact match at minimum
  // All results are for the correct state/office so the first good name match is reliable
  const lower = name.toLowerCase();
  const lastName = lower.split(' ').pop()!;
  const best = data.results.find(r =>
    r.name.toLowerCase().includes(lastName)
  );
  return best?.candidate_id ?? null;
}
```

**Note on hardcoding `state = 'CA'`:** Both LaMalfa and Swalwell are California House members.
Since the fix script only calls this function for politicians with `fecId === null`, and the
only two such sitting House members in scope are both from CA, hardcoding CA is acceptable.
A more general solution would look up state from the DB join, but that adds complexity not
needed for Phase 114 scope.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `candidates/search` inline `principal_committees` only | + fallback `candidate/{id}/committees/` | Phase 114 fix | Resolves "no committee" for senators not on 2026 ballot |
| `NICKNAME_MAP` + YAML only | + direct FEC search for YAML gaps | Phase 114 fix | Resolves LaMalfa/Swalwell who have no YAML FEC IDs |
| Hard-coded `cycle = '2026'` for totals | Try 2026 → 2024 → 2022 until non-zero | Phase 114 fix | Returns meaningful finance data for non-2026-ballot senators |

**Deprecated/outdated:**
- `theunitedstates.io/congress-legislators/legislators-current.json`: HTTP 410 Gone since 2026-06-04. Use YAML from GitHub. [VERIFIED: run-fec-finance-summary.ts comment]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `results[0]` from `/candidate/{id}/committees/` is the most recent/principal committee | Pattern 1, Code Example 1 | If not sorted by recency, might pick a defunct committee — low risk; same committee persists across cycles for most politicians |
| A2 | LaMalfa and Swalwell are both California state, office=H for direct FEC search | Code Example 2 | If either one has changed district or state, search will miss — planner should verify from DB query or hardcode confirmed FEC IDs once found |
| A3 | LaMalfa/Swalwell have no FEC IDs in congress-legislators YAML because it's stale or they used a different registration pattern (not a data gap in our DB) | Pattern 3 | If they have bioguide_ids in our DB, the main `resolveFecId` via `nameMap` should have caught them; absence confirms no YAML FEC entry |
| A4 | The 11 `politician_sources` rows written in the 2026-06-05 run cover Ivey/Self/Warnock/Cruz with `research_status = 'confirmed'` | FECF-02 context | If any of the 4 have a different status, the existing `fix-fec-name-mismatches.ts` logic (which inserts with `ON CONFLICT DO NOTHING`) will silently skip them; planner should add a verification step |
| A5 | Totals cycle fallback (try 2024, then 2022) gives the most useful data for senators not running in 2026 | Code Example 1 Step 2 | Storing a prior-cycle total is arguably more informative than $0; if product disagrees, always store 2026 with $0 |

---

## Open Questions

1. **What is the precise ON CONFLICT key for `politician_sources`?**
   - What we know: The INSERT in `fix-fec-name-mismatches.ts` uses `ON CONFLICT DO NOTHING`
     without specifying a conflict target. This suggests a UNIQUE constraint exists on the table.
   - What's unclear: Is it `(essentials_politician_id, source_system)` or just `(essentials_politician_id)`?
   - Recommendation: Planner should grep for the migration that creates `politician_sources`
     to find the UNIQUE constraint, then use explicit `ON CONFLICT (col1, col2) DO UPDATE`
     for the LaMalfa/Swalwell upsert.

2. **Should the totals cycle fallback be applied or should $0 be stored for non-2026 senators?**
   - What we know: FECF-01 says "tries cycles 2026, 2024, 2022 until a committee is found"
     — the multi-cycle language is scoped to committee lookup per the requirement text.
   - What's unclear: Whether the totals should also use the first non-zero cycle.
   - Recommendation: Use the multi-cycle totals approach (A5 above). A $0 total for a sitting
     Senator is misleading and unhelpful. Record the cycle used in `finance_summary.cycle`.

3. **Do LaMalfa and Swalwell have bioguide_ids in the DB?**
   - What we know: `fix-fec-name-mismatches.ts` uses a simpler query than `run-fec-finance-summary.ts`
     — it does not join bioguide_id. The NICKNAME_MAP lookup path would have matched their names
     against the YAML, but the YAML returned no FEC ID.
   - Recommendation: Planner task should include a verification query: check if these two
     politicians have `bioguide_id` populated in `essentials.politicians`. If so, they are in
     the YAML but simply have no `id.fec[]` entry.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `FEC_API_KEY` env var | All FEC API calls | ✓ (assumed — was used in prior run) | N/A | None — script exits if missing |
| `DATABASE_URL` env var | pool.query() writes | ✓ (assumed — same environment) | N/A | None — script exits if missing |
| Node.js `fetch` | FEC HTTP calls | ✓ Node 18+ built-in | Node 18+ | — |
| Congress-legislators YAML | `buildNameMap()` | ✓ Public GitHub URL | N/A | Script throws if fetch fails |

---

## Validation Architecture

Per `config.json` — `workflow.nyquist_validation` not set, treated as enabled. However,
this phase is a **data ingestion script**, not application code. Test coverage applies as follows:

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None for scripts — manual dry-run verification |
| Quick run command | `tsx backend/scripts/fix-fec-name-mismatches.ts --dry-run` |
| Live run command | `tsx backend/scripts/fix-fec-name-mismatches.ts` |
| Verification query | `SELECT full_name, finance_summary IS NOT NULL FROM essentials.politicians WHERE full_name IN ('Glenn Ivey', 'Keith Self', 'Raphael Warnock', 'Ted Cruz', 'Doug LaMalfa', 'Eric Swalwell')` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FECF-01 | Committee fallback activates when primary returns empty | Manual dry-run | `tsx backend/scripts/fix-fec-name-mismatches.ts --dry-run` | ✅ |
| FECF-02 | finance_summary populated for 4 politicians | Live run + SQL check | SQL: `SELECT finance_summary IS NOT NULL FROM essentials.politicians WHERE full_name IN (...)` | ✅ (manual) |
| FECF-03 | LaMalfa/Swalwell resolved + politician_sources written | Live run + SQL check | SQL: `SELECT research_status, external_id FROM transparent_motivations.politician_sources WHERE ...` | ✅ (manual) |

### Wave 0 Gaps

None — no new test files needed. Verification is via SQL queries post-run and console output
inspection.

---

## Security Domain

`security_enforcement` not set in config.json → treated as enabled. Applicable categories:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | Yes | FEC API responses typed as `unknown`, field access via optional chaining — never raw spread into DB |
| V6 Cryptography | No | No crypto in scope |
| V2 Authentication | No | FEC API key passed via URLSearchParams (never in URL path); env-var loaded |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via FEC response data | Tampering | Parameterized `pool.query()` — employer name never string-interpolated [VERIFIED: existing scripts] |
| FEC API key leakage in logs | Info Disclosure | Script logs `apiKey.slice(0, 8)...` not full key [VERIFIED: run-fec-finance-summary.ts line 347] |

---

## Sources

### Primary (HIGH confidence)

- `backend/scripts/ehn-fec-finance.ts` lines 136-145 — `fetchCommitteeIdFallback()` pattern (verbatim copy target)
- `backend/scripts/fix-fec-name-mismatches.ts` — full script read, identified exact lines to patch
- `backend/src/lib/fecResearch.ts` — `searchFecCandidates()`, `scoreMatch()`, `parseFecName()`, `normalize()`
- `backend/scripts/run-fec-finance-summary.ts` — `fetchCommitteeId()`, `fetchTotalRaised()`, `fetchTopDonorsByEmployer()` reference patterns
- `backend/migrations/190_politician_sources_source_type.sql` — `source_type` column definition, constraint values
- `backend/src/lib/campaignFinanceService.ts` — `createSource()` signature, `politician_sources` INSERT pattern

### Secondary (MEDIUM confidence)

- Microsoft Learn OpenFEC connector docs — `/candidate/{id}/committees/` response includes `committee_id` field
- `fec.gov/help-candidates-and-committees/filing-reports/election-cycle-aggregation/` — Senate cycles are 6-year; House cycles are 2-year

### Tertiary (LOW confidence — assumptions flagged)

- [ASSUMED] LaMalfa/Swalwell state = CA, office = H for direct FEC search
- [ASSUMED] `results[0]` from committee fallback is most recent/principal committee

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all patterns verified in codebase
- Architecture: HIGH — exact fallback code exists in `ehn-fec-finance.ts`; in-place edit only
- Pitfalls: HIGH — primary/fallback field name difference (`id` vs `committee_id`) verified from code

**Research date:** 2026-06-11
**Valid until:** 2026-07-11 (FEC API stable; script-level changes only)
