---
phase: 113-competitive-benchmarking
plan: 01
subsystem: research
tags: [benchmarking, methodology, scaffold, antipartisan, fairness]
requires: [BALLOT-BASELINE-2026-05-05.md, AUDIT-REPORT-112.md, PROJECT.md]
provides:
  - .planning/research/benchmark/METHODOLOGY.md
  - .planning/research/benchmark/MATRIX.md
  - .planning/research/benchmark/matrix.csv
  - 5 screenshot subdirectories under .planning/research/benchmark/screenshots/
affects: [plans 113-02 through 113-07]
tech-stack:
  added: []
  patterns: [markdown + CSV pairing, co-located research artifacts]
key-files:
  created:
    - .planning/research/benchmark/METHODOLOGY.md
    - .planning/research/benchmark/MATRIX.md
    - .planning/research/benchmark/matrix.csv
    - .planning/research/benchmark/screenshots/ballotready/.gitkeep
    - .planning/research/benchmark/screenshots/vote411/.gitkeep
    - .planning/research/benchmark/screenshots/votesmart/.gitkeep
    - .planning/research/benchmark/screenshots/ballotpedia/.gitkeep
    - .planning/research/benchmark/screenshots/ev/.gitkeep
  modified: []
decisions:
  - "Locked 10 core matrix dimensions before any scoring (D-04, D-10)"
  - "Picked Mt Tabor Rd (Benton Twp) and Covenanter Dr (SE Bloomington) as the two secondary district-boundary addresses (D-09)"
  - "Antipartisan framing (Dim 10) is the only inverted dimension; higher score = MORE antipartisan"
  - "EV intentional omissions (party labels, endorsements, ratings, donor data) are NOT scored as gaps"
metrics:
  duration: ~5 minutes
  completed: 2026-04-12
  tasks: 2
  files_created: 8
requirements: [BENCH-05]
---

# Phase 113 Plan 01: Methodology + Matrix Scaffold Summary

Locked the fairness ruler for the entire competitive benchmarking phase by writing METHODOLOGY.md and the unscored MATRIX.md/matrix.csv scaffold BEFORE any competitor scoring happens. Plans 02–07 now have a single source of truth for addresses, rubric, dimensions, blocker rules, and EV's intentional omissions.

## What Was Built

### METHODOLOGY.md (.planning/research/benchmark/METHODOLOGY.md)

The fairness mechanism for the phase. Eight sections:

1. **Addresses used** — primary (200 W Kirkwood Ave) for full matrix scoring; two secondaries for precinct-precision subsection only.
2. **Scoring rubric** — 0–3 depth scale with worked example (BallotReady candidate photo at Kirkwood) and the `blocked` class distinct from `0`.
3. **Locked core dimensions** — the 10 rows below.
4. **Race-count denominator** — points to BALLOT-BASELINE-2026-05-05.md (~43 race slots).
5. **Blocker handling** — every signup/captcha/paywall logged as `blocked` with human-fallback instructions; never silently treated as `0`.
6. **EV intentional omissions** — party labels, endorsements, interest-group ratings, donor data are NOT gaps.
7. **Self-audit stance** — EV scored on the same sheet, same rubric, no privileged column.
8. **Decision trace** — explicit mapping of D-01 through D-11 to methodology sections.

### MATRIX.md scaffold (.planning/research/benchmark/MATRIX.md)

Unscored 10×5 table (10 dimensions × EV + 4 competitors), all cells `TBD`. Includes header section pointing to METHODOLOGY.md, primary address, and the per-competitor source files. Stub sections for "Race / Candidate Count vs Baseline" and "Derived-Extra Dimensions" reserved for plan 07.

### matrix.csv scaffold (.planning/research/benchmark/matrix.csv)

CSV mirror of MATRIX.md: header `dimension,ev,ballotready,vote411,votesmart,ballotpedia` plus exactly 10 data rows, every cell `TBD`. 11 lines total. Plain comma separation.

### Screenshot directories

Five empty subdirectories under `.planning/research/benchmark/screenshots/` (one per subject) with `.gitkeep` placeholder files so plans 02–06 have committable destinations for Playwright captures.

## The 10 Locked Core Dimensions (the ruler)

| #  | Dimension                    | Notes for downstream plans                                                       |
| -- | ---------------------------- | -------------------------------------------------------------------------------- |
| 1  | Race coverage vs baseline    | Compare to ~43 race slots in BALLOT-BASELINE-2026-05-05.md                        |
| 2  | Candidate photo              | Headshot presence and quality                                                    |
| 3  | Candidate bio                | Biographical narrative depth                                                     |
| 4  | Candidate contact info       | Email, phone, website, mailing                                                   |
| 5  | Stance / issue data          | Structured policy positions                                                      |
| 6  | Candidate quotes / Q&A       | Sourced verbatim statements                                                      |
| 7  | Legislative record           | Votes, bills, committees (sitting officials)                                     |
| 8  | Geofence / address precision | Use the two secondary addresses below to verify district-list changes correctly  |
| 9  | Data freshness               | Last-updated signals                                                             |
| 10 | Antipartisan framing         | **INVERTED** — higher score = MORE antipartisan; EV expected score = 3           |

Up to 5 derived-extras may be added during plan 07 if a competitor surfaces something outside this core 10.

## The 3 Addresses

| Role         | Address                                       | Use                                                                 |
| ------------ | --------------------------------------------- | ------------------------------------------------------------------- |
| Primary      | 200 W Kirkwood Ave, Bloomington, IN 47404     | Full matrix scoring for all 5 subjects (matches Phase 112 baseline) |
| Secondary #1 | 7333 W Mt Tabor Rd, Bloomington, IN 47404     | Rural Benton Twp; tests IN State House District 46/60 boundary      |
| Secondary #2 | 2700 E Covenanter Dr, Bloomington, IN 47401   | SE Bloomington; tests IN State House District 61/62 boundary        |

Secondaries are NOT used for full matrix scoring — only for the per-competitor "Precinct Precision" subsection.

## Rubric Clarifications for Downstream Plans (02–07)

- **`blocked` is not `0`.** If signup/captcha/paywall/region gate prevents measurement, log `blocked` with the exact blocker name and a human-fallback step. Tally separately in the final report.
- **Dimension 10 inversion.** This is the only inverted row. Loud party labels and endorsement lists score 0. EV is expected to score 3 because its omissions are intentional.
- **EV omissions are not gaps.** Do not penalize EV on dimensions 4–6 for the absence of party labels, endorsements, interest-group ratings, or donor totals — those are intentional product decisions per `PROJECT.md`.
- **Self-audit stance.** Apart from the antipartisan carve-out, EV is scored on the same sheet using the same rubric. If EV genuinely lacks something a competitor has on a non-omitted dimension, EV scores 0 or 1 like any other subject. Source EV scoring from `AUDIT-REPORT-112.md` (5/51 stances, 4/51 quotes, 19/81 headshots, 0/51 bios).
- **Race-count denominator.** Always anchor Dimension 1 scoring to the ~43 race slots in `BALLOT-BASELINE-2026-05-05.md`. Do not estimate or recount.
- **Evidence required per cell.** Per D-03/D-05, every scored cell must carry a short evidence note citing the screenshot file or URL. Cells without evidence cannot be scored.

## Tasks Completed

| Task | Name                                                                      | Commit  | Files                                                                                                       |
| ---- | ------------------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------- |
| 1    | Write METHODOLOGY.md with addresses, rubric, blocker rule, omissions      | e0adbe8 | .planning/research/benchmark/METHODOLOGY.md                                                                  |
| 2    | Scaffold MATRIX.md + matrix.csv + 5 screenshot subdirectories             | 3fa8fbc | .planning/research/benchmark/MATRIX.md, matrix.csv, screenshots/{ballotready,vote411,votesmart,ballotpedia,ev}/.gitkeep |

## Deviations from Plan

None — plan executed exactly as written. All 11 must-have truths from the plan frontmatter are satisfied:

1. METHODOLOGY.md exists and is written before any scoring
2. Primary + 2 secondary addresses documented with district-boundary justification
3. 0–3 scoring scale defined with worked example (BallotReady candidate photo)
4. Blocker rule (`blocked` ≠ `0`) documented
5. EV intentional antipartisan omissions listed
6. Self-audit stance stated (EV column not privileged)
7. 10 core matrix dimensions locked and listed
8. MATRIX.md scaffold has 5 subject columns + 10 dimension rows, cells TBD
9. matrix.csv scaffold mirrors MATRIX.md (1 header + 10 data rows)
10. Screenshot subdirectories exist for all 5 subjects
11. METHODOLOGY.md explicitly references BALLOT-BASELINE-2026-05-05 as race-count denominator

## Verification

- METHODOLOGY.md exists with all required strings (`200 W Kirkwood Ave, Bloomington, IN 47404`, `0 = absent`, `blocked`, `antipartisan`, `BALLOT-BASELINE-2026-05-05`)
- MATRIX.md exists with ≥11 pipe-prefixed lines (header + separator + 10 data rows)
- matrix.csv exists with 11 lines (1 header + 10 data rows)
- All 5 screenshot subdirectories exist with `.gitkeep` placeholders
- Primary address string appears verbatim in both METHODOLOGY.md and MATRIX.md
- The 10 locked dimensions match exactly across METHODOLOGY.md, MATRIX.md, and matrix.csv

## Known Stubs

None. All `TBD` cells in MATRIX.md and matrix.csv are intentional scaffold placeholders explicitly scheduled for population in plan 07. METHODOLOGY.md is fully written.

## Self-Check: PASSED

- FOUND: .planning/research/benchmark/METHODOLOGY.md
- FOUND: .planning/research/benchmark/MATRIX.md
- FOUND: .planning/research/benchmark/matrix.csv
- FOUND: .planning/research/benchmark/screenshots/ballotready/.gitkeep
- FOUND: .planning/research/benchmark/screenshots/vote411/.gitkeep
- FOUND: .planning/research/benchmark/screenshots/votesmart/.gitkeep
- FOUND: .planning/research/benchmark/screenshots/ballotpedia/.gitkeep
- FOUND: .planning/research/benchmark/screenshots/ev/.gitkeep
- FOUND commit: e0adbe8 (Task 1)
- FOUND commit: 3fa8fbc (Task 2)
