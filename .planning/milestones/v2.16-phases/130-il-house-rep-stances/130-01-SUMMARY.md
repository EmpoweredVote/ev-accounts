---
phase: 130-il-house-rep-stances
plan: 01
status: complete
completed: 2026-06-18
requirements: [USHS-04]
---

# 130-01 SUMMARY — IL House Rep Stances, Batch A

## What was built

Researched + pushed sourced compass stances for the first 9 Illinois US House reps
(IL-01..09, external_id -17001..-17009) across the 25 federal topics.

- **157 `inform.politician_answers`** rows upserted; **157 paired context rows** (0 unsourced)
- **42 `essentials.quotes`** inserted; **40 Read-&-Rank selected** (2 had blank de-id → library-only); 0 leaks
- CSV: `backend/data/stance-research/2026-06-18-il-house-batch-a.csv`

## Per-rep stance counts (of 25 federal topics)

Jackson 22, Krishnamoorthi 19, Davis 18, Quigley 18, Schakowsky 18, Casten 17, Kelly 17,
García 16, Ramirez 12.

## Evidence-over-party highlights

All 9 are Democrats, but real within-party variation surfaced:
- **Senior progressives** (Davis, Schakowsky, García) carry more value-1 stances; **New-Dem types**
  (Krishnamoorthi, Kelly, Casten) cluster at 2.
- **Jackson misinformation=4 + ai-regulation=4** — documented "no government regulation of social
  media (private entities)" position (iSideWith), unusual for a progressive but recorded, not inferred.
- **Ramirez childcare=3 / social-security=3** — scored to her documented positions, not flattened to 1–2.
- **Tariffs=3** recurs (USMCA/selective), consistent with FL/NY/PA.

## Process notes

- **Concurrency held at 3** throughout; no session-limit pauses this run.
- **CSV escaping:** García's name field `Jesús G. "Chuy" García` had unescaped quotes (fixed by
  wrapping + doubling on every row); Krishnamoorthi had one unwrapped quote_deidentified field.
  Both repaired, then the standard `""""`→`"""` pre-collapse + canonical re-parse/re-stringify per
  CSV before merge. Merge reported 0 problems on 157 rows.
- **Jackson 22 vs agent-claimed 23:** voting-rights not present in the final file (agent self-count
  off or row never written); all 22 rows clean with no dups. Accepted as honest 22/25 rather than
  re-dispatching for a single topic.
- Push via reusable external_id-keyed `pa-house-a/_push.ts` (suffix-aware leak-check; García's
  accented surname handled).
- house.gov/congress.gov/govtrack 403; productive sources = OnTheIssues (IL/), Wikipedia,
  Ballotpedia, LCV scorecard, iSideWith, candidate sites.
