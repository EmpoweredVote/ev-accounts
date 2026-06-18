---
phase: 128-ny-house-rep-stances
plan: 02
status: complete
completed: 2026-06-17
requirements: [USHS-02]
commit: 52b583a5
---

# 128-02 SUMMARY — NY House Rep Stances, Batch B + Coverage Gate

## What was built

Researched + pushed sourced compass stances for NY US House reps NY-14..26
(external_id -36014..-36026) across the 25 federal topics, completing NY coverage.

- **211 `inform.politician_answers`** rows upserted; **211 paired context rows** (0 unsourced)
- **62 `essentials.quotes`** inserted; **62 Read-&-Rank selected**; 0 leaks
- CSV: `backend/data/stance-research/2026-06-17-ny-house-batch-b.csv`

## Per-rep stance counts (of 25 federal topics)

AOC 24, Torres 21, Latimer 15, Lawler 15, Ryan 13, Riley 18, Tonko 17, Stefanik 21,
Mannion 14, Langworthy 15, Tenney 18, Morelle 16, Kennedy 4.

## Coverage gate (whole-phase) — PASS ✅

26-rep NY coverage check (`external_id -36001..-36026`):
- **26/26 NY House reps covered** — 0 reps with zero stances
- **412 total NY answers** (201 batch A + 211 batch B)
- **0 answers lacking sourced context** — every answer has a paired sourced context row
- min coverage = Timothy Kennedy (4) — honest (May-2024 special-election member; sources 403), not guessed

**USHS-02 substantially met.** (Formal milestone gate is Phase 131.)

## Evidence-over-party highlights

- AOC most progressive (mostly 1s), `ai-regulation=5` (strict — correct direction); Torres `deportation=3` (Laken Riley shift).
- Lawler (R) `abortion=3`/`ssm=2`/`ukraine=2`/`immigration=3` — moderate, distinct from conservatives; Stefanik (R) `ssm=2` (Respect for Marriage Act) + `social-security=3` despite otherwise hard-right.
- Swing-district Dems (Ryan/Riley/Mannion/Latimer) cluster 2–3 with `deportation=3`/`immigration=3` — purple-district calibration, not auto-progressive.

## Process notes

- **Escaping rule largely worked:** 1 malformed CSV out of 26 NY agents (Tonko — unwrapped quote field), vs 2/27 in FL. Repaired in place; full batch parses clean.
- **Concurrency held at 3.** Several clock-based usage session-limit pauses between triples (NOT rate-limiting); incomplete agents re-dispatched cleanly on resume.
- house.gov/congress.gov/govtrack 403; productive sources = OnTheIssues (NY/), Wikipedia, Ballotpedia, LCV scorecard, campaign sites.
