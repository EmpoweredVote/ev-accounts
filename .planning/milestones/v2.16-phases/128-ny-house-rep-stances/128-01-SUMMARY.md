---
phase: 128-ny-house-rep-stances
plan: 01
status: complete
completed: 2026-06-17
requirements: [USHS-02]
commit: fbd3767f
---

# 128-01 SUMMARY — NY House Rep Stances, Batch A

## What was built

Researched + pushed sourced compass stances for NY US House reps NY-01..13
(external_id -36001..-36013) across the 25 federal topics, via research-stances.

- **201 `inform.politician_answers`** rows upserted; **201 paired context rows** (0 unsourced)
- **76 `essentials.quotes`** inserted; **74 Read-&-Rank selected**; 0 leaks
- CSV: `backend/data/stance-research/2026-06-17-ny-house-batch-a.csv`

## Per-rep stance counts (of 25 federal topics)

LaLota 10, Garbarino 12, Suozzi 15, Gillen 10, Meeks 18, Meng 18, Velázquez 20,
Jeffries 16, Clarke 20, Goldman 14, Malliotakis 12, Nadler 18, Espaillat 18.

## Process notes

- **Escaping fix worked:** the explicit RFC-4180 escaping rule added to every agent
  prompt eliminated the malformed-CSV repairs that Phase 127 needed — all 13 files
  parsed clean first try (0 problems).
- **Concurrency held at 3.** Multiple usage session-limit pauses occurred between
  triples (clock-based, NOT rate-limiting); agents that hadn't written re-dispatched
  cleanly on resume. Cap=3 remains valid for batch B.
- Evidence-over-party held: LaLota (R) abortion=3/ssm=2/deportation=3; Suozzi (D)
  deportation=4/trans-athletes=4 (centrist crossover); Malliotakis (R) abortion=3/ssm=2.
- house.gov/congress.gov/govtrack 403; productive sources = OnTheIssues (NY/), Wikipedia,
  Ballotpedia, LCV scorecard.

## Reusable for 128-02

- `backend/data/stance-research/ny-house-b/_TOPIC_SCALE.txt` (already written, identical 25 topics)
- `backend/data/stance-research/ny-house-a/_push_quotes.ts` (swap PID map + CSV path for batch B)
