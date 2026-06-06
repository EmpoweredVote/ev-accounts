---
phase: 103-state-remediation-ca-md
plan: 01
subsystem: database
tags: [pg, tsx, audit, inform, sources, data-quality, ca, state-legislators, triage]

# Dependency graph
requires:
  - phase: 100-source-coverage-audit
    provides: locked sourced definition (4-rule), HOMEPAGE_ONLY_REGEX, CA floor politicians (9)
  - phase: 102-federal-house-remediation
    provides: run-house-source-triage.ts template — SOURCED_CASE/UNSOURCED_CASE/HOMEPAGE_ONLY_REGEX constants, dual-scope pattern, CSV+report structure

provides:
  - backend/scripts/run-ca-source-triage.ts — reusable CA state triage script (STATE_LOWER/STATE_UPPER/STATE_EXEC)
  - .planning/phases/103-state-remediation-ca-md/103-CA-TRIAGE-REPORT.md — human-readable triage with pre-flight discoveries + per-politician detail
  - .planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv — machine-readable 11-row target list for Plan 02 dispatch

affects:
  - 103-02 (CA remediation) — reads 103-CA-TARGETS.csv to drive research-stances dispatch; 11 flagged politicians, affected_topic_keys per row

# Tech tracking
tech-stack:
  added: []
  patterns:
    - CA_POLITICIANS_CTE with DISTINCT ON (p.id) + d.state='CA' + district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC')
    - Pre-flight section preservation — script reads existing report, extracts pre-flight section, prepends to new output
    - dual-detection HAVING: SUM(unsourced_case) > 0 OR COUNT(weak_case) > 0

key-files:
  created:
    - backend/scripts/run-ca-source-triage.ts
    - .planning/phases/103-state-remediation-ca-md/103-CA-TRIAGE-REPORT.md
    - .planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv
  modified: []

key-decisions:
  - "CA district_type IN() list confirmed as STATE_LOWER + STATE_UPPER + STATE_EXEC (STATE_BOARD not present in CA DB records)"
  - "Gavin Newsom verified as STATE_EXEC — statewide executives in scope per CONTEXT.md D-02"
  - "Phase 100 floor politicians Katy Hall/Tracy Miller/Candice Pierucci (Utah), Cody Harris/Roland Gutierrez (Texas) correctly excluded by d.state=CA filter — these were multi-state tier politicians, not CA politicians"
  - "Plan 02 batching tier: 2 research plans (11 flagged > 10 threshold)"

patterns-established:
  - "pre-flight section preservation: script reads existing report file, extracts ## Pre-flight discoveries section, prepends verbatim to new report body"
  - "CA state triage SQL: DISTINCT ON (p.id) CTE + LEFT JOIN inform.politician_context + HOMEPAGE_ONLY_REGEX weak-source check"

requirements-completed:
  - STAX-01

# Metrics
duration: 45min
completed: 2026-06-06
---

# Phase 103 Plan 01: CA State Source Triage Summary

**CA state source triage script built and run: 11 politicians flagged (3 unsourced + 8 weak-source) across STATE_LOWER/STATE_UPPER/STATE_EXEC in 137-politician CA state corpus, producing machine-readable 103-CA-TARGETS.csv for Plan 02 dispatch**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-06T06:00:00Z
- **Completed:** 2026-06-06T06:45:00Z
- **Tasks:** 3
- **Files created:** 3

## Accomplishments

- Built `run-ca-source-triage.ts` as a direct adaptation of `run-house-source-triage.ts` — SOURCED_CASE/UNSOURCED_CASE/HOMEPAGE_ONLY_REGEX constants copied verbatim, single CA_POLITICIANS_CTE replaces the two-CTE Phase 102 pattern
- Pre-flight confirmed CA district_types: STATE_LOWER (80 politicians), STATE_UPPER (40), STATE_EXEC (18) = 138 in scope; STATE_BOARD not present in CA; Gavin Newsom confirmed at STATE_EXEC (Pitfall 1 averted)
- Live DB run found 137 active CA state politicians (one vacancy gap), 2184 total stances, 6 unsourced + 12 weak-source stances, 11 flagged politicians — Plan 02 batching tier: 2 research plans (11 > 10 threshold)

## Triage Results

| Metric | Value |
|--------|-------|
| Total CA state politicians | 137 |
| Total CA stances | 2184 |
| Unsourced stances | 6 |
| Weak-source stances | 12 |
| Flagged politicians | 11 |
| — unsourced_only | 3 |
| — weak_only | 8 |
| — both | 0 |

**Unsourced politicians (3):**
- Gavin Newsom (STATE_EXEC) — 4 unsourced: medicare/aid, redistricting, religious-freedom, same-sex-marriage
- Juan Carrillo (STATE_LOWER) — 1 unsourced: childcare
- Lisa Calderon (STATE_LOWER) — 1 unsourced: campaign-finance

**Weak-source politicians (8):**
- Akilah Weber Pierson (STATE_UPPER) — 1 weak: fossil-fuels
- Caroline Menjivar (STATE_UPPER) — 1 weak: homelessness
- Catherine Stefani (STATE_LOWER) — 1 weak: immigration
- Eloise Gómez Reyes (STATE_UPPER) — 3 weak: campaign-finance, religious-freedom, ukraine-support
- Gregg Hart (STATE_LOWER) — 1 weak: homelessness
- Henry Stern (STATE_UPPER) — 3 weak: religious-freedom, social-security, ukraine-support
- Natasha Johnson (STATE_LOWER) — 1 weak: school-vouchers
- Rob Bonta (STATE_EXEC) — 1 weak: ukraine-support

**Phase 100 CA-floor politicians confirmed:**
- Gavin Newsom ✓ (in CSV, ID f26309c8)
- Juan Carrillo ✓ (in CSV)
- Lisa Calderon ✓ (in CSV)

**Phase 100 floor politicians NOT in CA triage (correct exclusion — not CA politicians in DB):**
- Katy Hall, Tracy Miller, Candice B. Pierucci → state='ut' (Utah) in essentials.districts
- Cody Harris, Roland Gutierrez → state='TX' (Texas) in essentials.districts

The Phase 100 "State tier" included all US state politicians (not CA-only). The d.state='CA' filter correctly excludes these non-CA politicians.

**Mike Braun:** Correctly absent — Indiana Governor; no CA district record.

## Plan 02 Scoping

**Recommended batching: 2 research plans** (11 flagged > 10 threshold, ≤ 25 threshold)

Target CSV: `.planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv`

## Task Commits

1. **Task 1: Pre-flight CA district_type verification** — `09a6880` (chore)
2. **Task 2: Build run-ca-source-triage.ts** — `f83e000` (feat)
3. **Task 3: Run triage script — artifacts committed** — `89bca65` (feat)

## Files Created

- `backend/scripts/run-ca-source-triage.ts` — CA state triage script; single CTE, dual-detection, pre-flight section preservation
- `.planning/phases/103-state-remediation-ca-md/103-CA-TRIAGE-REPORT.md` — human-readable triage report with pre-flight discoveries + executive summary + per-politician detail + Plan 02 scoping note
- `.planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv` — 11-row machine-readable target list (columns: full_name, politician_id, state, district_type, party, total_stances, unsourced_count, weak_count, affected_topic_keys, classification)

## Decisions Made

- CA IN() list: `'STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC'` (STATE_BOARD absent from CA DB records)
- Gavin Newsom confirmed STATE_EXEC — statewide executives correctly included per CONTEXT.md D-02
- Phase 100 floor discrepancy documented: 5 of the 9 Phase 100 "CA floor" politicians are not CA politicians in the live DB (Utah and Texas state legislators)
- Script runs from main repo backend (worktree has no node_modules) with artifacts copied to worktree — working pattern for Phase 103 Plan 02

## Deviations from Plan

### Data Anomaly Discovered

**1. [Rule 1 - Data] Phase 100 "CA floor" list included non-CA politicians**
- **Found during:** Task 3 (running triage, checking missing names)
- **Issue:** Plan acceptance criteria required Katy Hall, Tracy Miller, Candice B. Pierucci (Utah legislators), Cody Harris, Roland Gutierrez (Texas legislators) to appear in CA triage output — but these politicians have `state='ut'` and `state='TX'` in the DB, not `state='CA'`
- **Fix:** Not a script bug — the d.state='CA' filter is correct. Documented as data anomaly. The Phase 100 target list categorized all US state-tier politicians together regardless of state.
- **Impact:** The 3 CA politicians that ARE in the DB with unsourced stances (Newsom, Carrillo, Calderon) are correctly captured. No fix needed.

### Script Path Resolution (worktree execution)

**2. [Rule 3 - Blocking] Script path resolves to main repo when run from main backend**
- **Found during:** Task 3 (running `npx tsx scripts/run-ca-source-triage.ts`)
- **Issue:** `__dirname` resolves to `/c/EV-Accounts/backend/scripts` when run from main backend, so `phaseDir` points to `/c/EV-Accounts/.planning/...` (main repo) rather than the worktree's `.planning/`
- **Fix:** Pre-flight report copied to main repo phase dir for script to read; generated artifacts copied back to worktree after script completes. This is the expected pattern for worktree execution where node_modules only exist in the main repo.
- **Impact on Plan 02:** Plan 02 should run the script the same way (copy to main backend, run, copy artifacts back).

---

**Total deviations:** 2 (1 data anomaly documented, 1 execution path issue resolved)
**Impact on plan:** Both handled without affecting triage correctness. CA scope is accurate.

## Issues Encountered

- Worktree's backend directory has no `node_modules` — all scripts must be run from the main repo's backend (`/c/EV-Accounts/backend`) after copying the script there. Artifacts generated in the main repo's phase directory and copied back to the worktree.

## Known Stubs

None — all triage data comes directly from the live DB.

## Threat Flags

None — triage is read-only against the live DB. No new network endpoints, auth paths, or schema changes.

## Next Phase Readiness

- Plan 02 (CA remediation) can read `103-CA-TARGETS.csv` to drive research-stances dispatch
- 11 politicians, 11 affected_topic_keys entries — one research-stances agent per politician, affected topics only
- Batching: 2 research plans (split alphabetically or by district_type: Unsourced batch vs Weak-source batch)
- Batching option: unsourced_only (3 politicians: Newsom, Carrillo, Calderon) as Plan 02A, weak_only (8 politicians) as Plan 02B

## Self-Check

- [x] `backend/scripts/run-ca-source-triage.ts` exists
- [x] `.planning/phases/103-state-remediation-ca-md/103-CA-TRIAGE-REPORT.md` exists
- [x] `.planning/phases/103-state-remediation-ca-md/103-CA-TARGETS.csv` exists (11 rows, header matches locked shape)
- [x] Gavin Newsom ID f26309c8 in CSV
- [x] Mike Braun NOT in CSV
- [x] Pre-flight discoveries section preserved in report
- [x] 3 commits: 09a6880, f83e000, 89bca65

## Self-Check: PASSED

---
*Phase: 103-state-remediation-ca-md*
*Completed: 2026-06-06*
