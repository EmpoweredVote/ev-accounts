---
phase: 142-stance-research-wave-1-governors-ags
plan: 03
wave: 2
requirements: [SEXS-02]
status: complete
completed: 2026-06-21
---

# 142-03 SUMMARY — batch B (OH/GA/NC/MI/NJ)

## Result
9 in-scope execs: **8 sourced + 1 documented honest-skip**. 132 answers/132 contexts, 0 unsourced, 0 leaks. 58 quotes inserted+selected. Coverage assertion (8 sourced): `PASS covered=8/8 unsourced=0`.

## Per-exec rows
| exec | external_id | rows |
|------|-------------|------|
| Mike DeWine (OH Gov) | -3900001 | 22 |
| Brian Kemp (GA Gov) | -1300001 | 15 |
| Chris Carr (GA AG) | -1300003 | 13 |
| Josh Stein (NC Gov) | -3700001 | 17 |
| Jeff Jackson (NC AG) | -3700003 | 18 |
| Gretchen Whitmer (MI Gov) | -2600001 | 20 |
| Dana Nessel (MI AG) | -2600003 | 10 (michigan.gov/ag 403'd; honest-partial) |
| Mikie Sherrill (NJ Gov) | -3400001 | 17 (Nov-2025 freshman; scored from US House record) |
| **Andy Wilson (OH AG)** | **-3900003** | **0 — HONEST-SKIP** |

NJ AG is appointed → out of scope (not seeded).

## OH AG roster note (IMPORTANT for the Phase-142 gate)
The seeded name "Andy Wilson" for OH AG (-3900003) is **CORRECT**. Verified from .gov: **Dave Yost resigned June 7, 2026**; Gov. DeWine appointed **Andy Wilson** (former OH Public Safety Director / Clark County Prosecutor), sworn in **June 8, 2026 — 13 days before research**. Wilson has essentially no compass record yet; the researcher correctly returned 0 rows and explicitly refused to attribute Yost's litigation record to Wilson (would violate no-inference rule). This is a legitimate honest-skip, same pattern as McDowell NC-6 (v2.17, pinned by external_id).

**Net Phase-142 denominator: 80 in-scope → 79 sourced + 1 documented honest-skip (-3900003).** The 142-10 gate must assert covered=79 and pin -3900003 as the known exemption (belt-and-suspenders).

## Pipeline
- ≤3 concurrency, 3 serial groups. Efficiency budget added after group 3 (a usage-limit window had parked the Jackson agent ~7.4h wall-clock despite ~4 active calls) — Nessel re-dispatch with the budget finished in 4.4 min.
- `_merge.ts` (IN_SCOPE = 9 batch-B ids): 0 problems, 132 rows, 8 reps with rows.
- Proxy gate: no isidewith; no over-read SSM=5 (DeWine SSM=3; Nessel SSM=1 per DeBoer v. Snyder). Auto-pushed.
