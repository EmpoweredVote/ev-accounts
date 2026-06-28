---
phase: 142-stance-research-wave-1-governors-ags
plan: 02
wave: 2
requirements: [SEXS-02]
status: complete
completed: 2026-06-21
---

# 142-02 SUMMARY — batch A (FL/NY/IL/PA/TX Gov+AG)

## Result
10/10 execs covered, **141 answers / 141 contexts, 0 unsourced, 0 leaks**. 47 quotes inserted + selected.
Coverage assertion: `PASS covered=10/10 unsourced=0`.

## Per-exec rows
| exec | external_id | rows |
|------|-------------|------|
| Ron DeSantis (FL Gov) | -1200001 | 19 |
| James Uthmeier (FL AG) | -1200003 | 10 |
| Kathy Hochul (NY Gov) | -3600001 | 18 |
| Letitia James (NY AG) | -3600003 | 17 |
| JB Pritzker (IL Gov) | -1700001 | 19 |
| Kwame Raoul (IL AG) | -1700003 | 7 (honest-partial — IL AG site 404'd most press URLs) |
| Josh Shapiro (PA Gov) | -4200001 | 16 |
| Dave Sunday (PA AG) | -4200003 | 3 (honest-partial — Jan-2025 freshman, ex-DA) |
| Greg Abbott (TX Gov) | -100202 | 17 |
| Ken Paxton (TX AG) | -100204 | 15 |

## Pipeline
- Dispatched 10 `politician-stance-researcher` agents at ≤3 concurrency (4 serial groups). First triple validated non-empty — no 429 empty-output; held at 3.
- `_merge.ts` (IN_SCOPE = the 10 batch-A ids; OUT = 2026-06-21-gov-ag-batch-a.csv): **0 problems**, 141 rows.
- Proxy-row review: **no isidewith sources**; only SSM=5 is Paxton, backed by his documented 2015 anti-recognition action (supporting clerks defying Obergefell) — keep per the rule. Abbott/DeSantis SSM=4 (not over-read to 5). Auto-pushed (0 problems AND 0 unsourced).
- `_push.ts`: 141/141, then `verify-stance-coverage.mjs` PASS.

## Notes
- Calibration discipline observed: Paxton voting-rights=4 / medicare=4 (not maxed); Abbott misinformation=4 (HB20 anti-censorship, not absolute). Thin freshman AGs (Sunday, Raoul) honest-partialed rather than inferring from party.
- IN_SCOPE-keyed push → no previously-stanced exec touched.
