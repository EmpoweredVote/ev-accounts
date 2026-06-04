# SECURITY AUDIT — Phase 90: Campaign Finance Schema, Ingestion, API

**Audited:** 2026-06-04
**ASVS Level:** 1
**Plans Covered:** 90-01, 90-02, 90-03
**Auditor:** gsd-secure-phase (claude-sonnet-4-6)
**Result:** SECURED — 13/13 threats closed, 0 open

---

## Threat Verification

| Threat ID | Plan | Category | Disposition | Status | Evidence |
|-----------|------|----------|-------------|--------|----------|
| T-90-01 | 01→02 | Tampering | mitigate | CLOSED | `run-fec-finance-summary.ts:406-411` — explicit `FinanceSummary` object literal constructed field-by-field; zero `JSON.stringify(*Response)` matches in grep; forbidden pattern absent |
| T-90-02 | 01 | Denial of Service | accept | CLOSED | Accepted risk documented here (see Accepted Risks section); table ~1,049 rows; `ADD COLUMN IF NOT EXISTS` with no default is metadata-only in PG11+; 90-01-SUMMARY confirms apply output was `ALTER TABLE / COMMENT` with no table rewrite |
| T-90-03 | 01 | Tampering | mitigate | CLOSED | No new packages in Plan 01; 90-01-SUMMARY `tech_stack.added: []` confirms zero installs |
| T-90-SC | 01 | Supply Chain | mitigate | CLOSED | Migration applied via psql/$DATABASE_URL (path B per plan); verification query against `information_schema.columns` returned `data_type=jsonb, is_nullable=YES` (90-01-SUMMARY Task 2 output); channel is authenticated DB connection, not untrusted pipe |
| T-90-04 | 02 | Tampering | mitigate | CLOSED | `run-fec-finance-summary.ts:406-411` — `const summary: FinanceSummary = { total_raised: totalRaised, top_donors: topDonors, cycle: FEC_CYCLE, source: 'FEC' }`; `fetchTotalRaised` coerces via `Number(data.results[0]?.receipts ?? 0)` at line 280; `fetchTopDonorsByEmployer` maps with `amount: Number(r.total), count: Number(r.count)` at lines 312-314; no raw spread pattern found |
| T-90-05 | 02 | Information Disclosure | mitigate | CLOSED | `run-fec-finance-summary.ts:347` — `console.log(\`FEC API key: ${apiKey.slice(0, 8)}...\``); full key never logged; .env is gitignored per project posture |
| T-90-06 | 02 | Denial of Service | mitigate | CLOSED | `run-fec-finance-summary.ts:35` — `const SLEEP_BETWEEN_FEC_CALLS_MS = 1500`; sleep called before every FEC call (lines 385, 396, 401 — three sleeps per politician); ~430 total calls at 1500ms = ~10 min runtime, well under 1000 req/hr |
| T-90-07 | 02 | Tampering | mitigate | CLOSED | `run-fec-finance-summary.ts:195-196` — `AND source_system LIKE 'fec%' AND research_status = 'confirmed'`; Path-1 crosswalk filters by chamber prefix (`id.startsWith('S')` for senators, `id.startsWith('H')` for House) at lines 134-136; both filters confirmed present |
| T-90-08 | 02 | Repudiation | accept | CLOSED | Accepted risk documented here (see Accepted Risks section); idempotent UPDATE is intended behavior; git history + 90-02-SUMMARY records the run |
| T-90-SC2 | 02 | Supply Chain | mitigate | CLOSED | No new packages; `js-yaml` already in package.json (^4.1.1 per 90-02-SUMMARY deviation note); `node-fetch`, `axios` absent from imports; only `dotenv`, `js-yaml`, `pool` (pg), native `fetch` used |
| T-90-09 | 03 | Tampering | mitigate | CLOSED | Smoke test 1 confirmed `typeof finance_summary === 'object'` for 191 politicians (90-03-SUMMARY "LIST OK"); `essentialsService.ts:534` — `finance_summary: row.finance_summary ?? null`; Pitfall 6 did not manifest — no JSON.parse wrapper needed |
| T-90-10 | 03 | Repudiation | mitigate | CLOSED | Smoke test 3 confirmed non-federal politician returns `finance_summary: null` not absent field (90-03-SUMMARY "NULL OK"); no existing field type changed per backward compatibility confirmation in 90-03-SUMMARY; `PoliticianFlatRecord` and `PoliticianDetail` both received additive-only `finance_summary: FinanceSummary \| null` |
| T-90-11 | 03 | Information Disclosure | accept | CLOSED | Accepted risk documented here (see Accepted Risks section); campaign finance is public record by law (FEC.gov disclosure); endpoints use `optionalAuth`; ASVS V4 does not apply |
| T-90-12 | 03 | Tampering | mitigate | CLOSED | `grep transparent_motivations.contributions essentialsService.ts` — 0 matches; `grep transparent_motivations.contributions essentialsBrowseService.ts` — 0 matches; pre-computed JSONB column used exclusively at query time |
| T-90-SC3 | 03 | Supply Chain | mitigate | CLOSED | Plan 03 is pure source edit; 90-03-SUMMARY `tech_stack.added: []` confirms zero installs; no new imports in `essentialsBrowseService.ts` beyond existing `PoliticianFlatRecord, FinanceSummary` from `essentialsService.js` |

---

## Accepted Risks Log

| Threat ID | Risk | Rationale | Owner |
|-----------|------|-----------|-------|
| T-90-02 | ADD COLUMN on `essentials.politicians` during business hours | Table is ~1,049 rows; `ADD COLUMN IF NOT EXISTS` with no default and no constraint is metadata-only in PostgreSQL 11+ (no table rewrite, no lock escalation beyond brief ACCESS EXCLUSIVE for catalog update). Risk accepted per threat register. | Platform |
| T-90-08 | Re-running ingestion script overwrites prior `finance_summary` values | Idempotent UPDATE is the intended behavior — re-runs refresh stale finance data. Git history of SUMMARY.md records each run date, key prefix, and processed/succeeded/error counts. | Engineering |
| T-90-11 | `finance_summary` exposes politician fundraising data without authentication | Campaign finance is public record by law (FEC.gov disclosure requirements). `/api/essentials/politicians` endpoints intentionally use `optionalAuth`. ASVS V4 authorization controls do not apply to legally-mandated public data. | Legal / Product |

---

## Unregistered Flags

None. No threat flags were raised in 90-01-SUMMARY, 90-02-SUMMARY, or 90-03-SUMMARY `## Threat Flags` sections. All three summaries contain a "Threat Surface Scan" section confirming no new network endpoints, no auth path modifications, and no new trust boundaries beyond those in the registered threat model.

**Notable deviation not in threat register (informational only — not a gap):** The `theunitedstates.io/congress-legislators/legislators-current.json` endpoint returned HTTP 410 Gone during Plan 02 execution. The script was updated to use the YAML source from `raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml` using `js-yaml` (already in package.json). This deviation was auto-fixed by the executor and does not introduce new supply-chain risk — `js-yaml` was a pre-existing dependency. The RESEARCH.md fallback path A1 explicitly anticipated this scenario.

---

## Verification Commands Used

| Check | Command | Result |
|-------|---------|--------|
| T-90-01: No raw FEC spread | `grep 'JSON.stringify.*Response'` in script | 0 matches |
| T-90-04: Explicit object construction | Read `run-fec-finance-summary.ts:406-411` | `FinanceSummary` literal confirmed |
| T-90-05: Key logging | `grep apiKey` in script | Only `apiKey.slice(0, 8) + '...'` logged |
| T-90-07: `research_status = 'confirmed'` | `grep research_status.*confirmed` | Found at line 196 |
| T-90-12: No contributions join | `grep transparent_motivations.contributions` in both service files | 0 matches each |
| T-90-SC: Migration verification | 90-01-SUMMARY Task 2 output | `data_type=jsonb, is_nullable=YES` |
| T-90-09: JSONB as object | 90-03-SUMMARY smoke test 1 | `typeof === 'object'` for 191 politicians |
| T-90-10: Non-federal null | 90-03-SUMMARY smoke test 3 | `finance_summary: null` returned |
| Wave-0 tests GREEN | 90-03-SUMMARY vitest output | 5 passed / 0 failed |
