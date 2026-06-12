---
phase: 114
plan: "01"
status: findings
reviewed_at: 2026-06-11
effort: high
findings_count: 6
---

# Code Review — Phase 114

## Findings

### 1. PLAUSIBLE — Cross-cycle committeeId/usedCycle mismatch produces empty top_donors
**File:** `backend/scripts/fix-fec-name-mismatches.ts` · **Line:** 164

`committeeId` is fetched once from `/candidates/search/` (returns the candidate's current principal committee). `usedCycle` can fall back to `'2024'` or `'2022'`. If a senator has recently registered a new 2026 exploratory committee and it becomes the "current principal," the donors query against `cycle=2024` or `cycle=2022` on that committee will return empty `top_donors` — the actual donation history lives on the prior cycle's committee. The `finance_summary` would be written with `total_raised > 0` but `top_donors: []`.

**Scenario:** A senator not on the 2026 ballot creates a 2026 exploratory PAC; FEC `/candidates/search/` returns that committee as principal. `usedCycle='2024'` (receipts come from totals, which is cycle-scoped separately). Donors for 2024 on the 2026 committee = zero results.

---

### 2. CONFIRMED — DRY_RUN path never populates `noMatchList` — misleading operator output
**File:** `backend/scripts/fix-fec-name-mismatches.ts` · **Line:** 227

In `DRY_RUN` mode the `!fecId` branch hits `stats.no_match++` then `continue` — never reaching `noMatchList.push()`. The final `JSON.stringify({ ...stats, no_match_list: noMatchList })` always emits `no_match_list: []` in dry-run even though `stats.no_match` reflects the real count. An operator running `--dry-run` to preview which politicians need attention sees the count but not the names.

**Fix:** Add `noMatchList.push(pol.full_name)` before `continue` in the DRY_RUN branch (line 229).

---

### 3. CONFIRMED — DIRECT path fires a redundant second INSERT at line 273 (dead no-op)
**File:** `backend/scripts/fix-fec-name-mismatches.ts` · **Line:** 273

For any politician resolved via `resolveViaDirectSearch` (LaMalfa, Swalwell), lines 254–263 DELETE then INSERT `(pol.id, 'fec_house', directId)`. Code then falls through with `fecId = directId` and hits the shared INSERT at line 273 with the same `(pol.id, 'fec_house', directId)` tuple. The unique constraint on `(source_system, external_id)` causes this second INSERT to always `DO NOTHING`. No data corruption, but it's a dead write on every DIRECT-path politician and an extra DB round-trip.

**Fix:** Add `continue` after the DIRECT path writes and before the shared block, or wrap the shared INSERT in `else { /* MATCH path only */ }`.

---

### 4. PLAUSIBLE — Hardcoded cycle fallback list silently goes stale when `FEC_CYCLE` bumps
**File:** `backend/scripts/fix-fec-name-mismatches.ts` · **Line:** 153

`[FEC_CYCLE, '2024', '2022']` — when `FEC_CYCLE` is updated to `'2028'`, the fallback tries `'2024'` and `'2022'`, skipping `'2026'`. Senators elected in 2026 who haven't raised 2028 money yet would get stale 2024 data.

**Fix:** Derive dynamically: `[FEC_CYCLE, String(parseInt(FEC_CYCLE) - 2), String(parseInt(FEC_CYCLE) - 4)]`

---

### 5. PLAUSIBLE — `resolveViaDirectSearch` hardcodes `state='CA'`; `isKnownCaHouseMember` name list must be manually maintained
**File:** `backend/scripts/fix-fec-name-mismatches.ts` · **Line:** 183 / 235

`resolveViaDirectSearch` hardcodes `state='CA'` and `office='H'`. The `isKnownCaHouseMember` guard is a matching hardcoded allowlist. If a future non-CA no-YAML member is added to the allowlist without updating the function, the search silently returns wrong results (or null). The state is derivable from the `essentials.districts` join already in the query (add `d.state_code` or equivalent to the SELECT).

---

### 6. ALTITUDE — Missing `UNIQUE(essentials_politician_id, source_system)` constraint forces DELETE+INSERT workaround
**File:** `backend/scripts/fix-fec-name-mismatches.ts` · **Line:** 252

The DIRECT path comment explains: `ON CONFLICT DO UPDATE` can't be used because the unique constraint only covers `(source_system, external_id)`, not `(essentials_politician_id, source_system)`. The right fix is a migration adding `UNIQUE(essentials_politician_id, source_system)` on `transparent_motivations.politician_sources`, which eliminates the DELETE+INSERT entirely and makes Phase 115's batch upserts safe from races.

---

## Summary

| # | Severity | File | Line | Summary |
|---|----------|------|------|---------|
| 1 | plausible bug | fix-fec-name-mismatches.ts | 164 | Cross-cycle committeeId/usedCycle mismatch → empty top_donors |
| 2 | confirmed bug | fix-fec-name-mismatches.ts | 227 | DRY_RUN noMatchList always empty — misleading stats |
| 3 | confirmed | fix-fec-name-mismatches.ts | 273 | DIRECT path redundant second INSERT (dead no-op) |
| 4 | plausible cleanup | fix-fec-name-mismatches.ts | 153 | Hardcoded cycle list stales when FEC_CYCLE bumps |
| 5 | plausible altitude | fix-fec-name-mismatches.ts | 183 | resolveViaDirectSearch hardcodes state='CA' |
| 6 | altitude | fix-fec-name-mismatches.ts | 252 | Missing UNIQUE constraint forces DELETE+INSERT pattern |

All findings are in the one-time ingestion script (`fix-fec-name-mismatches.ts`), not production API paths. Findings 2 and 3 are the most actionable quick fixes. Finding 6 benefits Phase 115.
