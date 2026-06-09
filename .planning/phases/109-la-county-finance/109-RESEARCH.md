# Phase 109: LA County Finance — Research

**Researched:** 2026-06-08
**Domain:** Campaign finance data ingestion — CAL-ACCESS (LA City Socrata), Netfile LACO (other LA County cities)
**Confidence:** HIGH

---

## Summary

Phase 109 populates `essentials.politicians.finance_summary` for every LA County city official seeded in Phase 108. The phase has two sub-scopes: LA City officials (Mayor, 15 Council, Controller, Clerk) and the other 26 LA County cities.

**Critical discovery:** LA City officials do NOT use the `cal_access` adapter. They use the **LA Socrata** adapter (`source_system = 'la_socrata'`) via dataset `m6g2-gc6c` on `data.lacity.org`. The `seed-la-city-confirmed.ts` script already has all 18 LA City officials hardcoded — Mayor Bass and two council members are marked `alreadyConfirmed: true` (confirmed rows exist), and 15 others (including the Controller and Clerk) need discovery and seeding. The CAL-ACCESS requirement in LAFI-01 is interpreted as "campaign finance for LA City officials via LA City's own campaign finance disclosure system (Socrata, not the state CAL-ACCESS ZIP)". [VERIFIED: codebase]

**Finance summary gap:** The adapters (`la_socrata`, `la_county_netfile`) write to `transparent_motivations.contributions`, but `essentials.politicians.finance_summary` is a SEPARATE JSONB column populated by standalone summary scripts. No existing script aggregates Socrata or Netfile contributions into `finance_summary`. Phase 109 must build a new summary script for both Socrata and Netfile officials. [VERIFIED: codebase]

**Netfile coverage:** The existing Netfile adapter uses `source_system = 'la_county_netfile'` with agency code `LACO`. The LACO jurisdiction covers the unincorporated county and cities that file with the county — but city officials typically file with their own city jurisdiction on Netfile. A QuickNameSearch endpoint exists (`/api/public/sites/api/QuickNameSearch?aid=LACO&query=<name>`) and was used for supervisors. City-specific Netfile jurisdictions use different agency codes. Verification is needed per-city. [VERIFIED: codebase]

**Primary recommendation:** Two-wave plan. Wave 1: LA City officials — run `seed-la-city-confirmed.ts` to seed remaining Socrata confirmed rows + trigger ingest + build `write-la-city-finance-summary.ts` script. Wave 2: Netfile assessment for other 26 cities — run QuickNameSearch per city with correct agency codes, seed confirmed rows for cities with accessible data, document no-data findings for the rest, then write summaries.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Politician source discovery (filer IDs) | Database / Scripts | — | politician_sources rows are the FK that links politicians to external finance IDs |
| Contribution ingestion (raw rows) | Database / Backend scripts | Scheduled cron | transparent_motivations.contributions table |
| Finance summary computation | Backend scripts | — | Aggregate contributions → JSONB → write to essentials.politicians.finance_summary |
| API exposure of finance_summary | API / Backend | — | essentialsService.ts already returns finance_summary in all politician endpoints |

---

## Standard Stack

### Core (already in repo — no new installs)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pg` (Pool) | ^8.x | Direct Postgres writes to essentials schema | Non-public schemas require pool.query(), never PostgREST |
| `dotenv/config` | ^16.x | Load DATABASE_URL from .env | Project standard for all scripts |
| `tsx` | project dep | TypeScript script runner | All scripts run via `npx tsx scripts/...` |

### External APIs (no install needed — HTTP fetch)

| API | Base URL | Auth | Coverage |
|-----|----------|------|----------|
| LA City Socrata (SODA v2) | `https://data.lacity.org/resource/m6g2-gc6c.json` | Optional `X-App-Token` | Mayor + all 15 Council + Controller + Clerk |
| Netfile REST API | `https://netfile.com/api/public/sites/api` | None (public) | LA County cities — per-city agency code |
| Netfile WebForms (legacy) | `https://public.netfile.com/pub2/Default.aspx` | None | Historical bulk XLSX — broken as of 2026-04-15 for new REST API |

### Package Legitimacy Audit

> No new npm packages are installed in this phase. All dependencies are already in the repo.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `pg` | npm | 12+ yrs | 100M+/wk | github.com/brianc/node-postgres | OK | Approved — already installed |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Phase 109 Finance Ingestion Flow:

LA City Officials (LAFI-01):
  seed-la-city-confirmed.ts
    → Socrata API (data.lacity.org/m6g2-gc6c)
      → politician_sources (la_socrata, confirmed)
        → runAdapterForAll('la_socrata')
          → transparent_motivations.contributions
            → write-la-city-finance-summary.ts (NEW)
              → essentials.politicians.finance_summary (JSONB)

Other LA County Cities (LAFI-02):
  [new] seed-la-county-city-netfile.ts
    → Netfile QuickNameSearch (per city agency code)
      → politician_sources (la_county_netfile, confirmed)
        → runAdapterForAll('la_county_netfile')
          → transparent_motivations.contributions
            → write-la-county-city-finance-summary.ts (NEW)
              → essentials.politicians.finance_summary (JSONB)

Assessment-only path (when no machine-readable data):
  [documented finding] → finance_summary = NULL + gap documented in script output
```

### Recommended Project Structure

```
backend/scripts/
├── seed-la-city-confirmed.ts        # EXISTING — seeds Socrata confirmed rows for 18 LA City officials
├── run-la-socrata-ingest.ts         # EXISTING — triggers la_socrata ingest for all confirmed sources
├── run-la-county-netfile-ingest.ts  # EXISTING — triggers la_county_netfile ingest
├── write-la-city-finance-summary.ts # NEW (Wave 1) — aggregate Socrata contributions → finance_summary
├── seed-la-county-city-netfile.ts   # NEW (Wave 2) — discover + seed Netfile filer IDs for 26 cities
└── write-la-county-city-finance-summary.ts  # NEW (Wave 2) — aggregate Netfile contributions → finance_summary
```

### Pattern 1: Seed Confirmed Source Rows (Socrata — existing pattern)

```typescript
// Source: backend/scripts/seed-la-city-confirmed.ts
// Pattern: fetch Socrata committee list, name-match against politicians, upsert politician_sources

await pool.query(
  `INSERT INTO transparent_motivations.politician_sources
     (essentials_politician_id, source_system, external_id, research_status, notes)
   VALUES ($1, 'la_socrata', $2, 'confirmed', $3)
   ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
  [politicianId, cmtId, notes]
);
```

### Pattern 2: Seed Confirmed Source Rows (Netfile — existing pattern)

```typescript
// Source: backend/scripts/seed-la-county-netfile-officials.ts
// QuickNameSearch endpoint for discovering filerIds

const url = `https://netfile.com/api/public/sites/api/QuickNameSearch?aid=${AGENCY}&query=${encodeURIComponent(name)}`;
// Then upsert as source_system='la_county_netfile'
await pool.query(
  `INSERT INTO transparent_motivations.politician_sources
     (essentials_politician_id, source_system, external_id, research_status, notes)
   VALUES ($1, 'la_county_netfile', $2, 'confirmed', $3)
   ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
  [politicianId, filerId, notes]
);
```

### Pattern 3: Finance Summary Write (FEC pattern — adapt for Socrata/Netfile)

```typescript
// Source: backend/scripts/run-fec-finance-summary.ts (lines 320-325)
// Adapt this pattern: aggregate contributions from transparent_motivations.contributions
// for each politician_source, then write summary to essentials.politicians

await pool.query(
  `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
  [JSON.stringify(summary), politicianId]
);

// finance_summary shape for local politicians (non-FEC):
// {
//   total_raised: number,
//   total_spent: number,      // available from Socrata con_amount with signs; from Netfile transactions
//   cycle: string,            // "2025" or "all" — depends on available data
//   source: "LA_SOCRATA" | "LA_COUNTY_NETFILE",
//   top_donors: []            // optional — same shape as FEC if data available
// }
```

### Pattern 4: Aggregate Finance Summary from Contributions Table

```sql
-- Aggregate total raised for a politician from transparent_motivations.contributions
-- via their confirmed politician_sources rows
SELECT
  SUM(c.amount) AS total_raised,
  COUNT(*) AS contribution_count,
  MAX(c.contribution_date) AS latest_contribution
FROM transparent_motivations.contributions c
JOIN transparent_motivations.committees cm ON cm.id = c.committee_id
JOIN transparent_motivations.politician_sources ps ON ps.id = cm.politician_source_id
WHERE ps.essentials_politician_id = $1
  AND ps.research_status = 'confirmed'
  AND c.amount > 0;  -- filter out expenditures
```

### Anti-Patterns to Avoid

- **Using CAL-ACCESS for LA City officials:** LA City uses its own city-level Socrata dataset (`m6g2-gc6c`), NOT the state CAL-ACCESS system. `cal_access` source_system is for county supervisors and state politicians. NEVER use `cal_access` for Mayor Bass, City Council members, Controller, or Clerk. [VERIFIED: seed-la-city-confirmed.ts uses `la_socrata`]
- **Assuming LACO jurisdiction covers all 26 cities:** Netfile LACO (`aid=LACO`) covers the County of Los Angeles unincorporated areas and some cities. City officials typically file with their own city's Netfile jurisdiction. Each city needs an agency code lookup. [VERIFIED: netfileAdapter.ts hardcodes `NETFILE_AGENCY = 'LACO'` for county supervisors only]
- **Writing finance_summary from contributions without aggregating:** Do not copy the FEC pattern verbatim — FEC directly fetches totals from the FEC API. For Socrata/Netfile, totals must be aggregated from `transparent_motivations.contributions` rows already ingested by the adapters.
- **Triggering ingest via HTTP POST:** Cloudflare blocks POST to accounts.empowered.vote. Always call `runAdapterForAll(adapterName)` directly from scripts. [VERIFIED: seed-la-city-confirmed.ts comment line 14]
- **Not handling zero-contribution officials:** Some officials (e.g., Ysabel J. Jurado, Patrice Lattimore) may have zero contributions in Socrata — this is valid. Leave `finance_summary` as NULL and document in the script output.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Socrata committee name matching | Custom fuzzy matcher | `seed-la-city-confirmed.ts` (existing) | Already handles compound names, hyphenated names, common-name disambiguation |
| Netfile filer ID discovery | Custom web scraping | `QuickNameSearch` REST endpoint + `seed-la-county-netfile-officials.ts` pattern | Existing REST API is unauthenticated and CORS-open |
| Socrata pagination | Custom loop | `socrataAdapter.ts` `fetchAllPages()` | Already handles 50k-row pages, 429 retry, delta-fetch |
| Netfile API pagination | Custom loop | `netfileAdapter.ts` `getTransactionsByFilerName()` | Already handles `SearchCampaignTransactions` pagination |
| Redis-locked ingest scheduling | Custom cron | `runAdapterForAll(adapterName)` from `campaignFinanceScheduler.ts` | Non-aborting, already deployed |

**Key insight:** The hardest part of this phase is the finance_summary aggregation script — everything else reuses existing patterns. The new script is ~80 lines of SQL + TypeScript.

---

## Current State of Politician Sources (Critical Findings)

### LA City Officials (LAFI-01)

The `seed-la-city-confirmed.ts` script reveals the current state:

| Official | Office | Status in seed script |
|---------|--------|----------------------|
| Karen Ruth Bass | Mayor | `alreadyConfirmed: true` — Socrata row exists |
| Nithya Raman | CD-4 | `alreadyConfirmed: true` — Socrata row exists |
| Hugo Soto-Martinez | CD-13 | `alreadyConfirmed: true` — Socrata row exists |
| Hydee Feldstein Soto | City Attorney | Needs seeding — uses `searchTerms: ['feldstein']` |
| Kenneth Mejia | City Controller | Needs seeding — uses `searchTerms: ['mejia']` |
| Eunisses Hernandez | CD-1 | Needs seeding |
| Adrin Nazarian | CD-2 | Has `knownCmtIds: ['1453755', '1468093']` (pre-researched) |
| Bob Blumenfield | CD-3 | Needs seeding |
| Katy Yaroslavsky | CD-5 | Needs seeding (requireAllTerms: katy + yaroslavsky) |
| Imelda Padilla | CD-6 | Needs seeding (requireAllTerms: imelda + padilla) |
| Monica Rodriguez | CD-7 | Needs seeding (requireAllTerms: monica + rodriguez) |
| Marqueece Harris-Dawson | CD-8 | Needs seeding (requireAllTerms: harris + dawson) |
| Curren D. Price Jr. | CD-9 | Needs seeding (requireAllTerms: curren + price) |
| Heather Hutt | CD-10 | Needs seeding |
| Traci Park | CD-11 | May already be confirmed — script checks existing status |
| John Lee | CD-12 | Needs seeding (requireAllTerms: john + lee) |
| Ysabel J. Jurado | CD-14 | Needs seeding — zero contributions acceptable |
| Tim McOsker | CD-15 | Needs seeding (requireAllTerms: tim + mcosker) |

**IMPORTANT:** The City Clerk (Patrice Lattimore) and City Controller (Kenneth Mejia) were seeded in Phase 108 (external_ids -700002 and -700001). However, `seed-la-city-confirmed.ts` only covers 18 officials with the old set. Phase 109 must verify Lattimore is included — she may need to be added to the script's TARGET_POLITICIANS list if not already present. Her Socrata committee, if any, needs discovery. **Lattimore was appointed in September 2025** — she may not have a campaign committee in Socrata at all. [VERIFIED: migration 303]

### Other LA County Cities (LAFI-02)

The 26 non-LA-City municipalities seeded in Phase 108 use `external_id` range `-700001` to `-700699` (Phase 108 migrations 293-309). No `politician_sources` rows were seeded for any of these officials. [VERIFIED: grep of migrations 293-310 — zero transparent_motivations inserts]

**Netfile agency code question:** The existing Netfile adapter is hardcoded to `aid=LACO`. For city officials, each city may have its own Netfile agency code. Known from `seed-la-county-netfile-officials.ts`: LACO code worked for county supervisors (Holly Mitchell, Lindsey Horvath). Whether LACO also covers Beverly Hills, Santa Monica, Long Beach, etc. requires the QuickNameSearch probe. [ASSUMED — no confirmation of city-specific agency codes in codebase]

---

## Common Pitfalls

### Pitfall 1: Patrice Lattimore (City Clerk) Has No Campaign Committee
**What goes wrong:** Script tries to seed a Socrata confirmed source for Lattimore, finds no matching committee, exits with error or zero rows.
**Why it happens:** Lattimore was appointed by City Council in September 2025 (migration 303 notes). Appointed officials don't run campaigns and likely have no Socrata committee record.
**How to avoid:** Add a `skipFinance: true` flag or `alreadyConfirmed: false, knownCmtIds: []` entry for Lattimore. Leave `finance_summary = NULL` with documentation.
**Warning signs:** `[NO MATCH]` in script output for Lattimore; not an error.

### Pitfall 2: Confusing CAL-ACCESS with LA City Socrata
**What goes wrong:** Phase description says "CAL-ACCESS data assessed and ingested for LA City officials" — but the adapter used is `la_socrata`, not `cal_access`.
**Why it happens:** Both are California campaign finance disclosure systems. CAL-ACCESS is the state-level system run by CA Secretary of State. LA City has its own city-level disclosure system (Ethics Commission) exposed via Socrata. City officials file with the city system.
**How to avoid:** Use `source_system = 'la_socrata'` for all LA City officials. Use `source_system = 'cal_access'` only for state-level officials (legislators, state officers) and county supervisors.
**Warning signs:** `runAdapterForAll('cal_access')` returning zero matches for Bass/council members.

### Pitfall 3: Netfile LACO Agency Code May Not Cover City Officials
**What goes wrong:** QuickNameSearch with `aid=LACO` finds no committees for Beverly Hills or Santa Monica council members.
**Why it happens:** Cities may file with their own Netfile jurisdiction (e.g., `aid=BHILLS` for Beverly Hills) rather than the county LACO jurisdiction.
**How to avoid:** Before seeding, probe `QuickNameSearch?aid=LACO&query=<known_official>` for one known official per city. If no result, the city has its own Netfile jurisdiction or doesn't use Netfile. Document as "not accessible via LACO jurisdiction" in the assessment.
**Warning signs:** Zero results from QuickNameSearch for well-known officials like Santa Monica Mayor.

### Pitfall 4: finance_summary Shape Must Be Consistent
**What goes wrong:** New local finance script writes a different JSONB shape than FEC; frontend assumes `{ total_raised, top_donors, cycle, source: "FEC" }`.
**Why it happens:** The FEC pattern was built for FEC-specific data (by_employer). Local finance data has different fields available.
**How to avoid:** The `source` field must differ (`"LA_SOCRATA"` vs `"FEC"`), but `total_raised` and `cycle` must always be present. `top_donors` can be `[]` if not available. The migration 268 comment documents the expected shape. [VERIFIED: migration 268]
**Warning signs:** API returning 500s from JSON parsing failures; TypeScript type errors in essentialsService.ts.

### Pitfall 5: Socrata App Token Rate Limiting
**What goes wrong:** `seed-la-city-confirmed.ts` runs without `SOCRATA_APP_TOKEN` set; Socrata throttles requests.
**Why it happens:** Without an app token, Socrata limits unauthenticated requests more aggressively.
**How to avoid:** Set `SOCRATA_APP_TOKEN` in `.env` before running Socrata scripts. The token is free — register at dev.socrata.com. The script logs a warning if absent.

### Pitfall 6: contributions Table Has No Unique Constraint on Finance Summary Aggregation
**What goes wrong:** Running the finance_summary write script twice produces double-counts if aggregation is from live contributions table.
**Why it happens:** The UPDATE to `finance_summary` is idempotent (writes replace the whole JSONB), but re-running the SELECT SUM() before a new ingest will produce the same value.
**How to avoid:** The write script should be idempotent by design — `UPDATE ... SET finance_summary = $1::jsonb` replaces the field entirely. Safe to re-run after any new ingest.

---

## Code Examples

### LA City Official Finance Summary Aggregation (New Script Pattern)

```typescript
// Source: adapted from run-fec-finance-summary.ts + socrataAdapter.ts

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
    top_donors: [],  // Socrata has donor data — future enhancement
    cycle: 'all',    // Socrata is all-time, not per-cycle
    source: 'LA_SOCRATA',
  };
}
```

### Netfile City Discovery Pattern

```typescript
// Source: adapted from seed-la-county-netfile-officials.ts

async function probeNetfileCity(
  agencyCode: string,
  searchName: string
): Promise<boolean> {
  const url = `https://netfile.com/api/public/sites/api/QuickNameSearch?aid=${agencyCode}&query=${encodeURIComponent(searchName)}`;
  const resp = await fetch(url, { headers: { Accept: 'application/json' } });
  if (!resp.ok) return false;
  const data = await resp.json() as { committees: unknown[] };
  return (data.committees?.length ?? 0) > 0;
}
```

---

## Phase 108 Politicians Reference (for FK lookups)

Phase 108 used `external_id` ranges to track all seeded officials:

| Group | external_id range | Count | Source |
|-------|-------------------|-------|--------|
| LA City Controller (Mejia) | -700001 | 1 | migration 303 |
| LA City Clerk (Lattimore) | -700002 | 1 | migration 303 |
| Wave 2 (BH + SM) | -700003 to -700049 | ~15 | migrations 301-302 |
| Wave 1 gap-fill cities | -700050+ | varies | migrations 293-299 |
| Wave 3 (10 new cities) | -700200 to -700699 | ~52 | migrations 305-309 |

Additionally, pre-existing Phase 108 officials (LA City Council, Mayor Bass, County Supervisors) were already in the DB before Phase 108 with their own external_ids or NULL external_ids. The `seed-la-city-confirmed.ts` script looks them up by `full_name`, so external_id is not required for Socrata seeding.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Netfile WebForms bulk Excel export | Netfile REST API (`netfile.com/api`) | 2026-04-15 | discover-netfile-filers.ts still uses the old WebForms approach — broken; use QuickNameSearch REST instead |
| Assume LACO covers all cities | Per-city agency code probe | 2026-05 (quick-026 discovery) | Must check each city individually |
| theunitedstates.io JSON | GitHub YAML (`legislators-current.yaml`) | 2026-06-04 | Not applicable to this phase (FEC only) |

**Deprecated/outdated:**
- `discover-netfile-filers.ts`: uses the old WebForms POST pattern (`https://public.netfile.com/pub2/Default.aspx`) — broken as of 2026-04-15 when Netfile migrated to a new SPA + REST API. Do NOT use for new discovery. Use QuickNameSearch REST endpoint instead. [VERIFIED: netfileAdapter.ts discovery notes, line 8-14]
- Old Netfile bulk Excel approach: the adapter notes explicitly say "The old WebForms POST/Excel approach is broken." [VERIFIED: netfileAdapter.ts line 13]

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js / tsx | All scripts | ✓ | existing in repo | — |
| PostgreSQL connection (`DATABASE_URL`) | All scripts | ✓ | .env configured | — |
| LA City Socrata API | LAFI-01 | ✓ (public, no auth) | live | Optional `SOCRATA_APP_TOKEN` for rate limit relief |
| Netfile REST API | LAFI-02 | ✓ (public, no auth) | live | — |
| `SOCRATA_APP_TOKEN` env var | seed-la-city-confirmed.ts | ? | — | Works without it (rate-limited) |
| FEC_API_KEY | Not needed | N/A | — | Not applicable to this phase |

**Missing dependencies with no fallback:** None — all required APIs are public and unauthenticated.

**Missing dependencies with fallback:** `SOCRATA_APP_TOKEN` — recommended but optional; script logs a warning and continues.

---

## Validation Architecture

> Workflow nyquist_validation not explicitly disabled in config.json — treating as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | SQL assertion scripts (same pattern as verify-la-county-108.sql) |
| Config file | None — ad-hoc verification SQL |
| Quick run command | `psql "$DATABASE_URL" -f backend/scripts/verify-la-county-109.sql` |
| Full suite command | Same as quick run |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LAFI-01 | finance_summary non-null for all LA City officials with confirmed Socrata sources | SQL assertion | `psql "$DATABASE_URL" -f backend/scripts/verify-la-county-109.sql` | ❌ Wave 0 |
| LAFI-02 | finance_summary populated or NULL-with-doc for all 26 other cities' officials | SQL assertion | Same file as above | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Check individual politician finance_summary via API: `curl $API/essentials/politicians/:id | jq .finance_summary`
- **Per wave merge:** Run full verify-la-county-109.sql
- **Phase gate:** Full SQL assertion script green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `backend/scripts/verify-la-county-109.sql` — covers LAFI-01 and LAFI-02 assertions
- [ ] No new test framework needed — SQL pattern established in Phase 108

---

## Open Questions

1. **Does Patrice Lattimore (City Clerk) have a Socrata committee?**
   - What we know: She was appointed in September 2025, not elected. Appointed officials rarely have campaign committees.
   - What's unclear: Whether she registered any committee for any prior election.
   - Recommendation: Run `seed-la-city-confirmed.ts --dry-run` first. If no match, document as "appointed official — no campaign committee expected" and leave `finance_summary = NULL`. This is valid per LAFI-01 ("or the field is null with the gap documented").

2. **Which Netfile agency codes cover Beverly Hills, Santa Monica, Long Beach, Glendale, Burbank, and the other 21 cities?**
   - What we know: `aid=LACO` covers the County of LA. The existing `seed-la-county-netfile-officials.ts` used LACO for county supervisors (Holly Mitchell, Lindsey Horvath, Robert Luna, Jeff Prang).
   - What's unclear: Whether city officials (mayors, city council members) file with LACO or their own city Netfile jurisdiction. Some CA cities use Netfile under their own agency code (e.g., Los Angeles city is separate from the county).
   - Recommendation: Build a probe step into the Wave 2 script that tests QuickNameSearch for one well-known official per city (e.g., Beverly Hills Mayor Lester Friedman, Santa Monica Mayor Lana Negrete) with `aid=LACO` first, then fall back to a city-specific code if needed. Document the result per city.

3. **Should finance_summary include total_spent for Socrata/Netfile officials?**
   - What we know: The FEC-based `finance_summary` only has `total_raised`. The migration 268 comment also only mentions `total_raised`, `top_donors`, `cycle`, `source`.
   - What's unclear: Whether the ROADMAP SC1 for Phase 109 ("total raised, total spent, and cycle data") implies the existing JSONB shape must be extended.
   - Recommendation: Add `total_spent` to the JSONB for Socrata/Netfile summaries since the ROADMAP explicitly calls for it. The JSONB is schema-free — adding a field is backward-compatible. The FEC script can be updated later if needed.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Netfile LACO jurisdiction (`aid=LACO`) may NOT cover city-level officials for the 26 non-LA-City municipalities | Open Questions #2 | If wrong (LACO covers all): simpler Wave 2 (no per-city probe needed). If correct: need to discover city-specific agency codes or document as "no accessible data" |
| A2 | Patrice Lattimore has no Socrata campaign committee (appointed, not elected) | Open Questions #1 | If wrong: finance_summary is simply populated; no harm done |
| A3 | Some Wave 3 cities (Compton, Carson, South Gate, Hawthorne, Gardena, El Segundo) have no machine-readable campaign finance data accessible via LACO Netfile | Pitfall 3 | If wrong: pleasant surprise — those cities get finance data too |

**If this table is empty of blockers:** All three assumptions resolve in the "safe" direction — the plan can handle either outcome by probing first.

---

## Sources

### Primary (HIGH confidence)

- `backend/scripts/seed-la-city-confirmed.ts` — definitive list of 18 LA City officials with Socrata source_system, alreadyConfirmed states, search terms
- `backend/scripts/seed-la-county-netfile-officials.ts` — Netfile LACO filer ID seeding pattern, QuickNameSearch endpoint
- `backend/src/lib/adapters/socrataAdapter.ts` — LA City Socrata API constants, pagination logic
- `backend/src/lib/adapters/netfileAdapter.ts` — Netfile REST API endpoints, LACO agency code, REST API discovery notes
- `backend/src/lib/campaignFinanceScheduler.ts` — `runAdapterForAll` dispatch for all adapters
- `backend/scripts/run-fec-finance-summary.ts` — `finance_summary` write pattern (lines 320-325)
- `backend/migrations/268_finance_summary_column.sql` — `finance_summary` JSONB shape specification
- `backend/migrations/303_la_wave2_la_city_controller_clerk.sql` — Lattimore is_appointed=true, appointment date
- `.planning/STATE.md` — v2.10 scope notes, LAFI-01/02 requirements

### Secondary (MEDIUM confidence)

- `.planning/ROADMAP.md` lines 1147-1162 — Phase 109 success criteria
- `.planning/milestones/v2.9-ROADMAP.md` — Phase 108 completion notes, Phase 109 deferred context
- `backend/scripts/verify-la-county-108.sql` — 27-city FIPS list and external_id ranges

### Tertiary (LOW confidence)

- Netfile city-specific agency code availability — [ASSUMED: no documentation in codebase for per-city codes beyond LACO]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tooling already exists in repo, no new packages
- Architecture: HIGH — patterns fully verified in existing scripts
- Pitfalls: HIGH — extracted from actual script comments and codebase behavior
- Netfile city coverage: LOW — city-specific agency codes not confirmed; requires live probe

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (30 days) — Netfile API is stable; Socrata dataset is persistent
