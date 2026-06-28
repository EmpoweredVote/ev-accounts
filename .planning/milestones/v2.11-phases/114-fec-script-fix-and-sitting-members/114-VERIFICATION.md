---
phase: 114-fec-script-fix-and-sitting-members
verified: 2026-06-11T00:00:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 114: FEC Script Fix and Sitting Members — Verification Report

**Phase Goal:** The FEC ingestion script correctly resolves finance data for all previously-matched sitting members — committee lookup failures are patched, and LaMalfa/Swalwell are identified via direct FEC name search and ingested, reducing the NULL finance_summary count from ~40 to ~34.
**Verified:** 2026-06-11
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Glenn Ivey, Keith Self, Raphael Warnock, and Ted Cruz each have non-null finance_summary | VERIFIED | SUMMARY SQL Query 1: all 4 rows show has_summary=true with real dollar amounts (Ivey $562,697, Self $504,420, Warnock $206M, Cruz $107M) |
| 2 | Doug LaMalfa and Eric Swalwell each have a non-null finance_summary and a politician_sources row with research_status = 'confirmed' | VERIFIED | SUMMARY SQL Query 2: both rows present — fec_house, confirmed, external_id H2CA02142 / H2CA15094. SQL Query 1: both have has_summary=true |
| 3 | Script prints MATCH or DIRECT for these 6 politicians and no [skip] No committee lines for them | VERIFIED | SUMMARY console output: Ivey=MATCH→H2MD04232, Self=MATCH→H2TX00064 (final run); LaMalfa=DIRECT→H2CA02142, Swalwell=DIRECT→H2CA15094, Warnock=MATCH, Cruz=MATCH (first run). Stats show no_committee=0 |
| 4 | NULL finance_summary count for federal politicians drops from ~40 to approximately 34 | VERIFIED | SUMMARY SQL Query 3: null_finance_federal = 34. Reduced by 6 from baseline of 40. Meets acceptance criterion (≤38) and hits target (~34) exactly |

**Score:** 4/4 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/scripts/fix-fec-name-mismatches.ts` | Committee lookup fallback (`candidate/${fecId}/committees/`) | VERIFIED | Line 138: `fbUrl = \`${FEC_BASE}/candidate/${fecId}/committees/?api_key=...\`` |
| `backend/scripts/fix-fec-name-mismatches.ts` | Fallback field name `committee_id` | VERIFIED | Lines 134, 142: both primary path and fallback use `.committee_id` |
| `backend/scripts/fix-fec-name-mismatches.ts` | Multi-cycle totals loop | VERIFIED | Line 153: `for (const cycle of [FEC_CYCLE, '2024', '2022'])` |
| `backend/scripts/fix-fec-name-mismatches.ts` | `cycle: usedCycle` in return | VERIFIED | Line 175: `return { ..., cycle: usedCycle, source: 'FEC' }` |
| `backend/scripts/fix-fec-name-mismatches.ts` | `resolveViaDirectSearch` function | VERIFIED | Lines 178–195: function defined and called at line 243 |
| `backend/scripts/fix-fec-name-mismatches.ts` | `let fecId` (not const) | VERIFIED | Line 224: `let fecId = resolveFecId(...)` |
| `backend/scripts/fix-fec-name-mismatches.ts` | `DIRECT_FEC_ID_OVERRIDES` map for Ivey/Self | VERIFIED | Lines 36–39: map with H2MD04232 (Ivey) and H2TX00064 (Self) — deviation from plan, auto-fixed |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `fetchFecData()` | `GET /v1/candidate/{id}/committees/` | Fallback when principal_committees empty | WIRED | Lines 136–144: fallback URL constructed and called on empty committeeId |
| `main()` | `GET /v1/candidates/?q=NAME&state=CA&office=H` | `resolveViaDirectSearch()` when resolveFecId() returns null | WIRED | Lines 226–243: isKnownCaHouseMember guard then resolveViaDirectSearch() called |
| `fix-fec-name-mismatches.ts` | `transparent_motivations.politician_sources` | `pool.query()` DELETE+INSERT | WIRED | Lines 254–263: DELETE then INSERT with ON CONFLICT DO NOTHING. Deviation from plan's ON CONFLICT DO UPDATE — no unique constraint on (essentials_politician_id, source_system) exists; DELETE+INSERT achieves identical upsert semantics. Documented in SUMMARY deviations. |
| `fix-fec-name-mismatches.ts` | `essentials.politicians.finance_summary` | `pool.query()` UPDATE | WIRED | Lines 284–287: `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2` |

---

### Data-Flow Trace (Level 4)

This is a data ingestion script (not a rendering component). Level 4 traces the data flow from FEC API to DB:

| Stage | Source | Produces Real Data | Status |
|-------|--------|-------------------|--------|
| FEC candidates/search → committeeId | Live FEC API, parameterized by fecId | Yes — committee_id from principal_committees or fallback endpoint | FLOWING |
| FEC candidates/totals → totalRaised | Live FEC API, multi-cycle loop | Yes — receipts field, cycle fallback confirmed by Warnock (2022) and Cruz (2024) results | FLOWING |
| FEC schedules/schedule_a → topDonors | Live FEC API | Yes — employer/amount/count array | FLOWING |
| pool.query UPDATE → essentials.politicians | finance_summary = JSON.stringify(summary) | Yes — SQL verified 6 rows with non-null values including real dollar amounts | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Evidence | Status |
|----------|----------|--------|
| Script exits 0 with written >= 6 across all runs | SUMMARY: first run wrote LaMalfa/Swalwell/Warnock/Cruz (4 writes); final run wrote Ivey/Self (2 writes). Total written = 6 across the two runs. error=0 in both. | PASS |
| Warnock multi-cycle fallback uses 2022 cycle | SUMMARY Query 1: cycle=2022 for Warnock — confirms multi-cycle loop found data at 2022 when 2026 returned 0 | PASS |
| Cruz multi-cycle fallback uses 2024 cycle | SUMMARY Query 1: cycle=2024 for Cruz | PASS |
| LaMalfa/Swalwell external_ids start with 'H' | SUMMARY Query 2: H2CA02142 and H2CA15094 | PASS |

---

### Probe Execution

No probe scripts declared or conventional probe files exist for this phase. Script is a one-time data ingestion tool verified via SQL queries run during the live run (documented in SUMMARY).

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| FECF-01 | 114-01-PLAN.md | `fix-fec-name-mismatches.ts` updated with committee lookup fallback and multi-cycle totals | SATISFIED | Script contains all 3 patches. REQUIREMENTS.md line 5 marked with checkmark and date 2026-06-11 |
| FECF-02 | 114-01-PLAN.md | finance_summary populated for Ivey, Self, Warnock, Cruz by re-running fixed script | SATISFIED | SUMMARY SQL Query 1: all 4 rows has_summary=true. REQUIREMENTS.md line 6 marked 2026-06-11 |
| FECF-03 | 114-01-PLAN.md | FEC candidate IDs resolved for LaMalfa/Swalwell via direct search; finance_summary populated; politician_sources rows confirmed | SATISFIED | SUMMARY SQL Queries 1+2: both have finance_summary and confirmed fec_house rows with H-prefix IDs. REQUIREMENTS.md line 7 marked 2026-06-11 |

All 3 requirements assigned to Phase 114 are satisfied. FECF-04 and FECF-05 are Phase 115 scope — not evaluated here.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| No TBD/FIXME/XXX markers | — | — | — | — |

Script contains no TODO/FIXME/TBD markers. No placeholder implementations. All pool.query calls use parameterized queries ($1, $2). API key logged at `apiKey.slice(0,8)...` per established pattern (verified via the established ehn-fec-finance.ts pattern — not inlined here but PLAN threat model T-114-02 documents it).

One notable deviation from PLAN (documented, intentional):

- **PLAN key_link declared** `ON CONFLICT (essentials_politician_id, source_system) DO UPDATE` as the upsert pattern for LaMalfa/Swalwell politician_sources. **Actual code** uses `DELETE+INSERT` because the transparent_motivations.politician_sources table has no unique constraint on (essentials_politician_id, source_system). The functional outcome is identical: a single confirmed row per politician per source_system. SUMMARY documents this as an auto-fixed deviation (commit cd3a90b5). Not a blocker.

---

### Human Verification Required

None. All success criteria are verifiable via code inspection and DB query results documented in SUMMARY.md. The DB is live; the SQL results are authoritative.

---

### Gaps Summary

No gaps. All 4 must-have truths verified. All 3 requirement IDs (FECF-01, FECF-02, FECF-03) satisfied. Phase goal achieved.

---

_Verified: 2026-06-11_
_Verifier: Claude (gsd-verifier)_
