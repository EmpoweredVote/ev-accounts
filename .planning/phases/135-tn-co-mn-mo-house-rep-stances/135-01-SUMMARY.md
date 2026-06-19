---
phase: 135-tn-co-mn-mo-house-rep-stances
plan: 01
status: complete
requirements: [USHS-09]
---

# 135-01 SUMMARY — TN House Batch A (TN-1..TN-5)

**Completed:** 2026-06-19
**Scope:** external_id −47001..−47005 (5 reps), all previously 0 stances.

## Result

74 sourced answers + 74 paired sourced context rows pushed to production (`kxsdzaojfaibhuzmclfq`). **0 unsourced.** 15 quotes inserted + selected as Read & Rank picks, 0 surname leaks.

| ext_id | District | Rep | Answers |
|--------|----------|-----|---------|
| −47001 | TN-1 | Diana Harshbarger | 13 |
| −47002 | TN-2 | Tim Burchett | 16 |
| −47003 | TN-3 | Charles Fleischmann | 20 |
| −47004 | TN-4 | Scott DesJarlais | 14 |
| −47005 | TN-5 | Andrew Ogles | 11 |

Per-scope verification (external_id −47001..−47005): answers=74, unsourced=0. Confirmed via per-scope counts (not the global counter).

## Method

3-concurrent `politician-stance-researcher` agents (premium tier), WebFetch-only, five-chairs/evidence-over-party framing against the 25-federal-topic scale. Honest-skips on topics with no documentable evidence above the isidewith bar (Ogles thinnest at 11/25 — Freedom Caucus member, most aggregator/.gov sources 403'd). No party inference; no isidewith-only rows.

## Artifacts

- `backend/data/stance-research/2026-06-19-tn-house-batch-a.csv` (committed, force-added past gitignore)
- `backend/data/stance-research/tn-house-a/` (per-rep CSVs + _TOPIC_SCALE.txt + _merge.ts + _push.ts)

## Self-Check: PASSED
