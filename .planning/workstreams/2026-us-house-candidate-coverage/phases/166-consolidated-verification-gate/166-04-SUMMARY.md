---
phase: 166-consolidated-verification-gate
plan: 04
subsystem: database
tags: [postgres, plpgsql, verification, gate, invariants, redistricting]

requires:
  - phase: 161-165
    provides: the fifteen invariants each declared as carry-forward to Phase 166
  - phase: 164.1
    provides: migrations 1247/1248/1249 that un-withheld TN, AL and LA
provides:
  - "backend/scripts/166-verify-invariants.sql — all fifteen inherited invariants, independently runnable"
  - "The delimited MO POST-2026-08-04 FLIP REGION that plan 164.1-07 edits"
affects: [166-05, 164.1-07, 167]

tech-stack:
  added: []
  patterns:
    - "Inherited invariants are re-probed live before assertion; a mismatch is investigated, never accommodated"

key-files:
  created:
    - backend/scripts/166-verify-invariants.sql
  modified: []

key-decisions:
  - "OPEN-SEAT's predicate corrected from 164's '0 active rows anywhere' to '0 active NATIONAL_LOWER rows'. Hern and Hinson now hold active US Senate rows — the reason their House seats are open. The expected count stays 0; only the predicate was corrected."
  - "UT-REKEY's incumbent clause scoped to the UT general, because the past 2026 Utah Primary doubles every incumbent's row count from 3 to 6."
  - "AK-FIELD's active count re-derived live (15) rather than inherited, since AK is a PROVISIONAL: state with an August primary."
  - "No migration required — the gate is read-only and adds no schema."

patterns-established:
  - "When a frozen invariant fails live, fix the predicate to match the invariant's real subject rather than relaxing the expected value"

requirements-completed: [USHC3-06]
---

# 166-04: the fifteen inherited invariants

## Result

```
cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/166-verify-invariants.sql
```

**Exit 0**, fifteen `PASS` blocks, `ALL INHERITED INVARIANTS PASSED`.

Fully **write-free**: zero `INSERT`/`UPDATE`/`DELETE` of any kind; 2 `CREATE TEMP TABLE … ON COMMIT
DROP`. `npm run check:occupancy --prefix backend` exits 0.

## Live probe results — every block, against its frozen expectation

Each block was run as a plain `SELECT` against prod **before** being converted to an assertion.

| # | Block | Source | Expected | Live probe | Match |
|---|---|---|---|---|---|
| 1 | TN-SURFACING | 161 + 164.1-04 | 0 on marker, 9 on general | 0 / 9 (4701-4709) | ✓ |
| 2 | AL-SURFACING | 163 + 164.1-05 | 0 on marker, 7 on general | 0 / 7 (0101-0107) | ✓ |
| 3 | LA-SURFACING | 163 + 164.1-05 | 0 marker, 6 general, 0 non-null party, 0 Dec runoff | 0 / 6 / 0 / 0 | ✓ |
| 4 | MO-SEVERE | 162 | 5 withheld, 0 leaked, 3 surfacing | 5 (2902-2906) / 0 / 3 (2901,2907,2908) | ✓ |
| 5 | IN9-FLAG | 162 (mig 1212) | 1 incumbent total, 0 on 7d3f0042, a61ab808 is it | 1 / 0 / a61ab808 on race 9d2de2ae | ✓ |
| 6 | AZ-RECONCILE | 161 (mig 1204) | 0 active for all 5 ineligible | 0,0,0,0,0 | ✓ |
| 7 | MA-INCUMBENT-DEDUP | 161 | Clark 1 on 2505, Pressley 1 on 2507 | 1 / 1 | ✓ |
| 8 | CO1-DEGETTE | 163 | 2 active, DeGette absent | 2 / 0 | ✓ |
| 9 | OPEN-SEAT | 164 | 0 active rows for all 5 | **Hern 1, Hinson 1** — see below | **✗ → resolved** |
| 10 | OR-REUSE | 164 | 6 reused, 0 outside | 6 / 0 | ✓ |
| 11 | NV-RECONCILE | 165 | 4 reused, 0 outside, 1 election, Chapman set, 6 ids | 4 / 0 / 1 / 1 / 6 | ✓ |
| 12 | ME-RECONCILE | 165 | 2 + 2 active, 0 outside, 1 election | 2 / 2 / 0 / 1 | ✓ |
| 13 | UT-REKEY | 165 (via 1641 D04-NOTOUCH) | md5 baseline, 3 incumbents, Owens 0 | md5 ✓, **6 incumbents** — see below, Owens 0 | **✗ → resolved** |
| 14 | AK-FIELD | 165 | 1 race, party NULL, active re-derived | 1 / NULL / **15** | ✓ (re-derived) |
| 15 | COLLISION-BAND | 164 + 165 | 0 ids below any of 19 floors | 0 | ✓ |

Thirteen matched exactly. The two that did not were resolved by investigation, not by adjusting the
expectation to whatever prod happened to say.

## Discrepancy 1 — OPEN-SEAT (resolved by correcting the predicate)

164 worded this invariant as "0 active `essentials.race_candidates` rows **anywhere**, not merely 0
in scope". Probed live, two of the five failed:

| Politician | Active rows | Where |
|---|---|---|
| Kevin Hern (OK-1) | 1 | geo_id `40`, `NATIONAL_UPPER`, IA/OK 2026 Statewide General — a **US Senate** race |
| Ashley Hinson (IA-2) | 1 | geo_id `19`, `NATIONAL_UPPER` — a **US Senate** race |

Both rows were created **2026-07-10**, three days after 164 froze.

These candidacies are precisely *why* their House seats are open. The invariant's subject is a
**House seat**; 164's "anywhere" was over-broad. The fix scopes the predicate to
`d.district_type = 'NATIONAL_LOWER'`, which returns **0 for all five**. The expected value is
unchanged at 0 — only the predicate was corrected.

Additional check while investigating: both hold correctly-titled
`Candidate for U.S. Senate — {State}` offices alongside their still-current `U.S. Representative`
seats. That matches the migration-1327 convention (`o.title NOT ILIKE 'Candidate for%'` filters
candidate offices out of officeholder queries), so this is **not** a recurrence of the Senate
candidate-office leak.

## Discrepancy 2 — UT-REKEY (resolved by scoping to the general)

The md5 matched the binding baseline `4d8bbfb221d4babca6e9f7201bce391e` exactly. The
incumbent-placement clause, however, returned **6** rather than 3, because UT also has a past
`2026 Utah Primary` (2026-06-23) whose NATIONAL_LOWER races carry the same three incumbents —
doubling every count. Scoped to `UT 2026 Statewide General` it returns **3**. 165 never hit this
because its `_house` covered only the 17 general elections.

## MO flip region — marker lines verbatim

`grep -c "MO POST-2026-08-04 FLIP REGION"` returns **2**:

```
  -- === MO POST-2026-08-04 FLIP REGION — see 166-mo-flip-runbook.md ===
```
```
  -- === END MO POST-2026-08-04 FLIP REGION ===
```

Both branches of the date-gated plan 164.1-07 are documented inside:

- **MAP-HOLDS** — MO G5200V26 polygons imported, the five severe races re-pointed to
  `MO 2026 Statewide General`. The block must then invert: withheld array empty, surfacing set
  becomes all 8 geo_ids 2901-2908, pass notice rewritten to the AL-SURFACING wording. The
  `166-coordinate-smoke.ts` negative sample flips to five positives at the same time.
- **REFERENDUM-QUALIFIES** — MO does zero polygon work, the five stay withheld for the cycle, the
  revert diverts to Phase 167's MO cluster. **`THIS BLOCK REQUIRES NO EDIT`** — stated explicitly so
  nobody edits it defensively.

## Post-164.1 correctness

TN, AL and LA assert **SURFACING**, not withholding. Migrations 1247 (TN), 1248 (AL) and 1249 (LA)
un-withheld thirteen districts on 2026-07-07. Inheriting 161's and 163's original withheld
assertions would have produced a gate that is green about a world that no longer exists. Each block
names its migration in the pass notice. MO's five are the only withheld set remaining, which the
live withheld census in `166-pins.generated.sql` independently confirms (TN 0 / AL 0 / LA 0 / MO 5).

## No migration required

The gate is read-only and adds no schema, so this plan authored no migration — stated explicitly
because the plan's verification block requires the conclusion either way.

## Self-Check: PASSED
