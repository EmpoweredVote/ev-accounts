---
phase: 130-il-house-rep-stances
plan: 02
status: complete
completed: 2026-06-18
requirements: [USHS-04]
---

# 130-02 SUMMARY — IL House Rep Stances, Batch B + Coverage Gate

## What was built

Researched + pushed sourced compass stances for the remaining 8 Illinois US House reps
(IL-10..17, external_id -17010..-17017) across the 25 federal topics, completing IL coverage.

- **113 `inform.politician_answers`** rows upserted; **113 paired context rows** (0 unsourced)
- **26 `essentials.quotes`** inserted; **26 Read-&-Rank selected**; 0 leaks
- CSV: `backend/data/stance-research/2026-06-18-il-house-batch-b.csv`

## Per-rep stance counts (of 25 federal topics)

Schneider 17, Miller 17, Bost 16, Foster 16, LaHood 15, Underwood 14, Budzinski 10, Sorensen 8.

## Coverage gate (whole-phase) — PASS ✅

17-rep IL coverage check (`external_id -17001..-17017`):
- **17/17 IL House reps covered** — 0 reps with zero stances
- **270 total IL answers** (157 batch A + 113 batch B)
- **0 answers lacking sourced context**
- min coverage = Sorensen (8) and Budzinski (10) — both purple-district freshmen with thin/blocked
  local sourcing; honest, not guessed

**USHS-04 substantially met.** (Formal milestone gate is Phase 131.)

## Evidence-over-party highlights

- **Sorensen (D) deportation=4** — voted for the Laken Riley Act; clear purple-district calibration,
  not flattened to 2. immigration=3 likewise.
- **LaHood (R) same-sex-marriage=2** — agent caught his documented Respect for Marriage Act vote,
  reversing his 2015 opposition, distinct from his otherwise consistent center-right 4s.
- **Schneider & Budzinski (D)** moderate on climate/fossil/medicare (3s) reflecting competitive
  districts — distinct from the Chicago progressives in batch A.
- **Miller (R)** is the most conservative member across the FL/NY/PA/IL set (5 on 10 of 17 topics).
- **Bost (R)** medicare=3 & social-security=3 — opposes cuts despite otherwise hard-right profile.

## Process notes

- **Concurrency held at 3** throughout; no session-limit pauses this run.
- **CSV escaping:** Bost emitted the quad-quote `""""` pattern again (handled by the pre-collapse).
  García (batch A) needed name-field quote escaping. Standard canonical re-parse/re-stringify per
  CSV before merge; both merges reported 0 problems.
- Push via reusable external_id-keyed `pa-house-a/_push.ts`.
- house.gov/congress.gov/govtrack 403; productive sources = OnTheIssues (IL/), Wikipedia,
  Ballotpedia, LCV scorecard, NPR Illinois, The Pantagraph, Roll Call.
