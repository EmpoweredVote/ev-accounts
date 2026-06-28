---
phase: 142-stance-research-wave-1-governors-ags
plan: 04
wave: 2
requirements: [SEXS-02]
status: complete
completed: 2026-06-21
---

# 142-04 SUMMARY — batch C (WA/AZ/TN/IN/MO/WI)

## Result
10/10 execs covered, **120 answers/120 contexts, 0 unsourced, 0 leaks**. 51 quotes. `PASS covered=10/10 unsourced=0`.

## Per-exec rows
| exec | external_id | rows |
|------|-------------|------|
| Bob Ferguson (WA Gov) | -5300001 | 17 |
| Nick Brown (WA AG) | -5300003 | 12 |
| Katie Hobbs (AZ Gov) | -400091 | 8 (news sites 403'd; Wikipedia-sourced honest-partial) |
| Kris Mayes (AZ AG) | -400092 | 10 |
| Bill Lee (TN Gov) | -4700001 | 15 |
| Todd Rokita (IN AG) | **499453** (positive id) | 12 |
| Mike Kehoe (MO Gov) | -2900001 | 15 |
| Catherine Hanaway (MO AG) | -2900003 | 12 |
| Tony Evers (WI Gov) | -5500001 | 18 |
| Josh Kaul (WI AG) | -5500003 | 1 (verified WI source wall — see note) |

TN AG appointed → out of scope. IN Gov (Braun) already stanced → out of scope.

## Notes
- **Josh Kaul (WI AG) = thin honest-partial (1 row), re-researched once.** wisdoj.gov 401'd all sub-paths; Ballotpedia empty; ontheissues 404; major news 403'd. Both attempts (including a Wikipedia-first retry) confirmed the wall. Only verifiable sourced action: fake-electors prosecution → voting-rights=2. Honest-skip on the rest beats inference (his abortion/multistate record is real but no page returned fetchable content). Same precedent as Fry SC-7 (v2.17).
- Positive external_id `499453` (Rokita) resolved correctly by `_push.ts`.
- Calibration: Lee SSM=4 / trans-athletes=4 (no anti-recognition vote / no full ban); Mayes correctly honest-skipped her tariff suit (constitutional-authority grounds, not trade policy); Rokita SSM honest-skipped.
- Proxy gate: no isidewith; no over-read SSM=5. Auto-pushed (0 problems, 0 unsourced).
- Efficiency budget held — all agents finished in 3–10 min, no usage-window parking this batch.
