# Phase 109: LA County Finance — Pattern Map

**Mapped:** 2026-06-08
**Files analyzed:** 4 new files to create
**Analogs found:** 4 / 4

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `backend/scripts/write-la-city-finance-summary.ts` | script/utility | batch, CRUD | `backend/scripts/run-fec-finance-summary.ts` | role-match (same finance_summary write pattern, different data source) |
| `backend/scripts/seed-la-county-city-netfile.ts` | script/utility | request-response, CRUD | `backend/scripts/seed-la-county-netfile-officials.ts` | exact (same QuickNameSearch probe + politician_sources upsert) |
| `backend/scripts/write-la-county-city-finance-summary.ts` | script/utility | batch, CRUD | `backend/scripts/run-fec-finance-summary.ts` | role-match (same finance_summary write pattern, Netfile source_system) |
| `backend/scripts/verify-la-county-109.sql` | test/verification | batch | `backend/scripts/verify-la-county-108.sql` | exact (same SQL assertion pattern, different requirements) |

---

## Pattern Assignments

### `backend/scripts/write-la-city-finance-summary.ts` (script, batch+CRUD)

**Analog:** `backend/scripts/run-fec-finance-summary.ts`

**Imports pattern** (lines 27-29):
```typescript
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
```

**Env guard pattern** (lines 336-340):
```typescript
if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}
```

**DB query pattern — fetch politicians with confirmed la_socrata sources** (adapted from lines 165-184):
```typescript
async function getLACityPoliticiansWithSocrataSources(): Promise<Array<{ id: string; full_name: string }>> {
  const sql = `
    SELECT DISTINCT p.id, p.full_name
    FROM essentials.politicians p
    JOIN transparent_motivations.politician_sources ps
      ON ps.essentials_politician_id = p.id
    WHERE ps.source_system = 'la_socrata'
      AND ps.research_status = 'confirmed'
    ORDER BY p.full_name
  `;
  const result = await pool.query<{ id: string; full_name: string }>(sql);
  return result.rows;
}
```

**Finance summary aggregation from contributions table** (RESEARCH.md Pattern 4):
```typescript
async function buildFinanceSummaryFromSocrata(
  politicianId: string
): Promise<FinanceSummary | null> {
  const result = await pool.query<{ total_raised: string; contribution_count: string }>(
    `SELECT
       COALESCE(SUM(c.amount), 0) AS total_raised,
       COUNT(*) AS contribution_count
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.committees cm ON cm.id = c.committee_id
     JOIN transparent_motivations.politician_sources ps ON ps.id = cm.politician_source_id
     WHERE ps.essentials_politician_id = $1
       AND ps.source_system = 'la_socrata'
       AND ps.research_status = 'confirmed'
       AND c.amount > 0`,
    [politicianId]
  );
  const row = result.rows[0];
  if (!row || Number(row.total_raised) === 0) return null;
  return {
    total_raised: Number(row.total_raised),
    top_donors: [],
    cycle: 'all',
    source: 'LA_SOCRATA',
  };
}
```

**finance_summary write pattern** (lines 323-327 of run-fec-finance-summary.ts):
```typescript
async function updateFinanceSummary(politicianId: string, summary: FinanceSummary): Promise<void> {
  await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId],
  );
}
```

**FinanceSummary type** — use this exact shape for LA_SOCRATA (must have `total_raised`, `cycle`, `source`; `top_donors` can be `[]`; add `total_spent` per ROADMAP SC1):
```typescript
interface FinanceSummary {
  total_raised: number;
  total_spent?: number;   // from Socrata: contributions with amount < 0 — future enhancement
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;          // 'all' for Socrata (all-time, not per-cycle)
  source: 'LA_SOCRATA';
}
```

**Main loop pattern** (lines 367-422 of run-fec-finance-summary.ts):
```typescript
for (const p of politicians) {
  processed++;
  console.log(`\n[${processed}/${politicians.length}] ${p.full_name}`);
  try {
    const summary = await buildFinanceSummaryFromSocrata(p.id);
    if (!summary) {
      console.log(`  [SKIP] No contributions found — leaving finance_summary = NULL`);
      skipped_no_data++;
      skippedNames.push(p.full_name);
      continue;
    }
    await updateFinanceSummary(p.id, summary);
    console.log(`  [OK] finance_summary written. total_raised=$${summary.total_raised.toLocaleString()}`);
    succeeded++;
  } catch (err) {
    const errMsg = err instanceof Error ? err.message : String(err);
    console.error(`  [ERROR] ${p.full_name}: ${errMsg}`);
    errors++;
  }
}
```

**Pool shutdown pattern** (lines 452-460 of run-fec-finance-summary.ts):
```typescript
main()
  .catch(async (err) => {
    console.error('[write-la-city-finance-summary] Fatal error:', err);
    try { await pool.end(); } catch { /* ignore pool close errors on fatal path */ }
    process.exit(1);
  });
// In main():
await pool.end();
process.exit(0);
```

**CRITICAL NOTE:** `seed-la-city-confirmed.ts` uses `new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } })` (its own pool), while `run-fec-finance-summary.ts` imports `pool` from `../src/lib/db.js`. Use the shared `pool` import (db.js) for all new Phase 109 scripts — it is already configured with ssl and env loading via `env.ts`.

---

### `backend/scripts/seed-la-county-city-netfile.ts` (script, request-response+CRUD)

**Analog:** `backend/scripts/seed-la-county-netfile-officials.ts`

**Full file pattern** — this is a near-exact copy with a different `OFFICIALS` array for the 26 non-LA-City municipalities and an added per-city agency code probe step.

**Imports pattern** (lines 19-20):
```typescript
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
```

**Official/Committee interface** (lines 26-36):
```typescript
interface Committee {
  filerId: string;      // 'TBD-...' means resolve via QuickNameSearch
  label: string;        // Used for notes + name matching
  searchQuery?: string; // Query for QuickNameSearch if filerId is TBD
  agencyCode?: string;  // NEW for Phase 109: per-city agency code (default: 'LACO')
}

interface Official {
  name: string;       // Matches essentials.politicians.full_name
  district: string;   // Human-readable location for notes
  committees: Committee[];
  skipFinance?: boolean;  // NEW: for appointed officials with no campaign committee
}
```

**QuickNameSearch probe pattern — adapted for per-city agency codes** (lines 109-161 of seed-la-county-netfile-officials.ts):
```typescript
async function resolveFilerId(
  label: string,
  searchQuery: string,
  agencyCode: string = 'LACO'  // per-city code override
): Promise<string | null> {
  const url = `https://netfile.com/api/public/sites/api/QuickNameSearch?aid=${agencyCode}&query=${encodeURIComponent(searchQuery)}`;
  console.log(`[seed] QuickNameSearch: aid=${agencyCode} query="${searchQuery}" for label="${label}"`);
  // ... same response handling as analog (lines 113-161)
}
```

**Politician lookup pattern** (lines 168-188):
```typescript
async function lookupPoliticianId(fullName: string): Promise<string | null> {
  const result = await pool.query<{ id: string }>(
    `SELECT id FROM essentials.politicians
     WHERE LOWER(full_name) = LOWER($1) AND is_active = true
     LIMIT 2`,
    [fullName]
  );
  if (result.rows.length === 0) { console.warn(...); return null; }
  if (result.rows.length > 1) { console.warn(...); return null; }
  return result.rows[0].id;
}
```

**Upsert politician_sources pattern** (lines 194-213):
```typescript
async function upsertSource(
  politicianId: string,
  filerId: string,
  notes: string
): Promise<string | null> {
  const result = await pool.query<{ id: string }>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes, created_at, updated_at)
     VALUES ($1, 'la_county_netfile', $2, 'confirmed', $3, NOW(), NOW())
     ON CONFLICT (essentials_politician_id, source_system, external_id)
       DO UPDATE SET
         research_status = 'confirmed',
         notes           = EXCLUDED.notes,
         updated_at      = NOW()
     RETURNING id`,
    [politicianId, filerId, notes]
  );
  return result.rows[0]?.id ?? null;
}
```

**probe-first pattern** (RESEARCH.md Pitfall 3 — NEW for Phase 109, not in analog):
```typescript
// Before populating OFFICIALS array, probe a known official per city to confirm
// LACO agency code covers city filings. If no result, document as no-data city.
async function probeAgencyCode(
  agencyCode: string,
  searchName: string
): Promise<boolean> {
  const url = `https://netfile.com/api/public/sites/api/QuickNameSearch?aid=${agencyCode}&query=${encodeURIComponent(searchName)}`;
  const resp = await fetch(url, { headers: { Accept: 'application/json', 'User-Agent': 'EV-CampaignFinance/1.0 (+https://empowered.vote)' } });
  if (!resp.ok) return false;
  const data = (await resp.json()) as { committees: unknown[] };
  return (data.committees?.length ?? 0) > 0;
}
```

**Main + summary table + pool.end pattern** (lines 227-311):
```typescript
main()
  .catch((err) => {
    console.error('[seed] FATAL:', err instanceof Error ? err.message : String(err));
    process.exitCode = 1;
  })
  .finally(() => pool.end());
```

---

### `backend/scripts/write-la-county-city-finance-summary.ts` (script, batch+CRUD)

**Analog:** `backend/scripts/run-fec-finance-summary.ts` (same structure as `write-la-city-finance-summary.ts` above, different source_system)

The only differences from `write-la-city-finance-summary.ts`:
1. `source_system = 'la_county_netfile'` instead of `'la_socrata'`
2. `source: 'LA_COUNTY_NETFILE'` in the FinanceSummary object
3. Script name in all log prefixes

**Finance summary aggregation from Netfile contributions** (same SQL shape, different source_system filter):
```typescript
async function buildFinanceSummaryFromNetfile(
  politicianId: string
): Promise<FinanceSummary | null> {
  const result = await pool.query<{ total_raised: string; contribution_count: string }>(
    `SELECT
       COALESCE(SUM(c.amount), 0) AS total_raised,
       COUNT(*) AS contribution_count
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.committees cm ON cm.id = c.committee_id
     JOIN transparent_motivations.politician_sources ps ON ps.id = cm.politician_source_id
     WHERE ps.essentials_politician_id = $1
       AND ps.source_system = 'la_county_netfile'
       AND ps.research_status = 'confirmed'
       AND c.amount > 0`,
    [politicianId]
  );
  const row = result.rows[0];
  if (!row || Number(row.total_raised) === 0) return null;
  return {
    total_raised: Number(row.total_raised),
    top_donors: [],
    cycle: 'all',
    source: 'LA_COUNTY_NETFILE',
  };
}
```

**NOTE:** Netfile REST API only covers data from approx 2025+. Zero contributions after ingest is expected and valid — `finance_summary = NULL` is correct in that case. Do NOT error on zero rows.

---

### `backend/scripts/verify-la-county-109.sql` (test, batch)

**Analog:** `backend/scripts/verify-la-county-108.sql`

**File header pattern** (lines 1-16):
```sql
-- ============================================================
-- verify-la-county-109.sql
-- Phase 109 Phase Gate — LA County Finance
-- Run: psql "$DATABASE_URL" -f backend/scripts/verify-la-county-109.sql
--
-- N labeled assertions covering all Phase 109 success criteria.
-- Each assertion outputs a query result; zero-row failures or
-- unexpected counts indicate gaps to investigate.
--
-- LAFI-01: finance_summary non-null for all LA City officials with confirmed Socrata sources
-- LAFI-02: finance_summary populated or NULL-with-doc for all 26 other cities' officials
-- ============================================================
```

**\echo + assertion block pattern** (lines 19-39):
```sql
\echo ''
\echo '==================================================================='
\echo 'Phase 109 LA County Finance — Verification Gate'
\echo '==================================================================='

\echo ''
\echo '--- ASSERTION 1: LAFI-01 — confirmed la_socrata sources exist for LA City officials ---'
\echo 'Expected: confirmed_sources >= 15 (18 officials, Lattimore may have 0)'

SELECT COUNT(*) AS confirmed_sources
FROM transparent_motivations.politician_sources ps
JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
WHERE ps.source_system = 'la_socrata'
  AND ps.research_status = 'confirmed';
```

**finance_summary presence assertion pattern** (adapted from verify-la-county-108.sql assertion style):
```sql
\echo ''
\echo '--- ASSERTION 2: LAFI-01 — finance_summary written for officials with confirmed Socrata sources ---'
\echo 'Expected: officials_with_summary >= 15 (Lattimore/Jurado may be NULL — acceptable)'

SELECT
  COUNT(*) AS officials_with_confirmed_source,
  COUNT(p.finance_summary) AS officials_with_summary,
  COUNT(*) - COUNT(p.finance_summary) AS officials_null_summary
FROM essentials.politicians p
JOIN transparent_motivations.politician_sources ps
  ON ps.essentials_politician_id = p.id
WHERE ps.source_system = 'la_socrata'
  AND ps.research_status = 'confirmed';
```

**Closing \echo pattern** (lines 238-243):
```sql
\echo ''
\echo '==================================================================='
\echo 'Verification complete. Review above for any unexpected counts.'
\echo 'LAFI-01: confirmed_sources >= 15, officials_with_summary >= 15'
\echo 'LAFI-02: netfile_sources > 0 for cities where data is accessible'
\echo '==================================================================='
```

---

## Shared Patterns

### Pool Import (applies to all 3 TypeScript new files)
**Source:** `backend/src/lib/db.ts` (lines 1-16) + `backend/scripts/run-la-county-netfile-ingest.ts` (line 14)
**Apply to:** All three new `.ts` scripts
```typescript
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
// pool.end() in .finally() or at end of main()
```
Note: `seed-la-city-confirmed.ts` creates its own `new Pool()` — do NOT copy that pattern. Use the shared `pool` from `db.js`.

### runAdapterForAll Trigger (applies after seeding)
**Source:** `backend/scripts/run-la-county-netfile-ingest.ts` (lines 12-27)
**Apply to:** `seed-la-county-city-netfile.ts` — call `runAdapterForAll('la_county_netfile')` after seeding, same as `seed-la-city-confirmed.ts` calls `runAdapterForAll('la_socrata')` at line 590.
```typescript
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';
// After seeding loop:
if (!isDryRun) {
  console.log('\n[Step N] Triggering runAdapterForAll("la_county_netfile")...');
  await runAdapterForAll('la_county_netfile');
}
```
CRITICAL: Never trigger ingest via HTTP POST — Cloudflare blocks it. Always use `runAdapterForAll` directly.

### finance_summary UPDATE (applies to both summary scripts)
**Source:** `backend/scripts/run-fec-finance-summary.ts` (lines 323-327)
**Apply to:** Both `write-la-city-finance-summary.ts` and `write-la-county-city-finance-summary.ts`
```typescript
await pool.query(
  `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
  [JSON.stringify(summary), politicianId],
);
```
The `::jsonb` cast is required — do not omit it.

### Dry-run Arg Parsing (applies to seed scripts)
**Source:** `backend/scripts/seed-la-city-confirmed.ts` (lines 40-41)
**Apply to:** `seed-la-county-city-netfile.ts`
```typescript
const isDryRun = process.argv.includes('--dry-run');
```

### Non-aborting Error Loop (applies to all scripts)
**Source:** `backend/scripts/run-fec-finance-summary.ts` (lines 371-423), `backend/scripts/seed-la-county-netfile-officials.ts` (lines 227-284)
**Apply to:** All new scripts — never let one politician failure abort the whole run.
```typescript
try {
  // ... per-politician work
} catch (err) {
  const errMsg = err instanceof Error ? err.message : String(err);
  console.error(`  [ERROR] ${name}: ${errMsg}`);
  errors++;
  // continue to next politician
}
```

---

## No Analog Found

All four files have strong analogs. No files require falling back to RESEARCH.md patterns exclusively.

---

## Key Anti-Patterns (from RESEARCH.md — do not copy these)

| Anti-Pattern | Where It Lives | What to Do Instead |
|-------------|---------------|-------------------|
| `source_system = 'cal_access'` for LA City officials | Not in codebase (hypothetical) | Always use `'la_socrata'` for Mayor/Council/Controller/Clerk |
| HTTP POST to trigger ingest | — | Call `runAdapterForAll()` directly (lines 589-591 of seed-la-city-confirmed.ts) |
| `new Pool({ connectionString: process.env.DATABASE_URL })` | seed-la-city-confirmed.ts line 44 | Use `import { pool } from '../src/lib/db.js'` |
| Assuming `aid=LACO` covers all 26 cities | netfileAdapter.ts line 43 | Probe each city with `probeAgencyCode()` before seeding |
| `discover-netfile-filers.ts` WebForms approach | that script | Use QuickNameSearch REST endpoint (netfileAdapter.ts line 42) |

---

## Metadata

**Analog search scope:** `backend/scripts/`, `backend/src/lib/adapters/`, `backend/src/lib/`
**Files scanned:** 7 (seed-la-city-confirmed.ts, run-fec-finance-summary.ts, seed-la-county-netfile-officials.ts, netfileAdapter.ts, socrataAdapter.ts, campaignFinanceScheduler.ts, verify-la-county-108.sql)
**Pattern extraction date:** 2026-06-08
