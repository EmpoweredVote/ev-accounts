---
phase: 129-pa-house-rep-stances
plan: 02
status: complete
completed: 2026-06-18
requirements: [USHS-03]
---

# 129-02 SUMMARY — PA House Rep Stances, Batch B + Coverage Gate

## What was built

Researched + pushed sourced compass stances for the remaining 8 Pennsylvania US House reps
(PA-10..17, external_id -42010..-42017) across the 25 federal topics, completing PA coverage.

- **126 `inform.politician_answers`** rows upserted; **126 paired context rows** (0 unsourced)
- **37 `essentials.quotes`** inserted; **37 Read-&-Rank selected**; 0 leaks
- CSV: `backend/data/stance-research/2026-06-17-pa-house-batch-b.csv`

## Per-rep stance counts (of 25 federal topics)

Lee 20, Perry 17, Kelly 17, Joyce 16, Smucker 15, Reschenthaler 15, Thompson 15, Deluzio 11.

## Coverage gate (whole-phase) — PASS ✅

17-rep PA coverage check (`external_id -42001..-42017`):
- **17/17 PA House reps covered** — 0 reps with zero stances
- **262 total PA answers** (136 batch A + 126 batch B)
- **0 answers lacking sourced context** — every answer has a paired sourced context row
- min coverage = Bresnahan (8, freshman, sources blocked) and Deluzio (11, swing-district
  freshman) — honest, not guessed

**USHS-03 substantially met.** (Formal milestone gate is Phase 131.)

## Evidence-over-party highlights

- **Scott Perry** most consistently far-right (multiple 5s incl. deportation/immigration/
  healthcare) — matches Freedom Caucus record. **Summer Lee** mirror image (mostly 1–2) but
  ukraine=3 (opposed $61B aid package — populist, not auto-progressive).
- **Tariffs=3** recurs across PA Republicans (Smucker/Joyce/Reschenthaler/Kelly) — documented
  USMCA/free-trade orientation, NOT high-tariff extreme. Thompson the exception at 4.
- **Kelly social-security=3** — explicitly opposes privatization, real departure from default.
- **Thompson same-sex-marriage=5**: agent verified he voted AGAINST the Respect for Marriage
  Act, correctly contradicting a wrong hint in the dispatch prompt — evidence-over-assumption
  working as intended.
- **Deluzio** (swing-district Dem) honestly skipped immigration/deportation/tariffs; M4A
  cosponsor → healthcare/medicare/social-security=1.

## Process notes

- **Concurrency held at 3** throughout batch B; no session-limit pauses this run.
- **CSV escaping:** Same canonical re-parse/re-stringify step (with a `""""`→`"""` pre-collapse
  guard) applied to every per-rep CSV before merge. Both merges reported 0 problems.
- Push keyed by external_id→UUID via reusable `pa-house-a/_push.ts` (answers + context + quotes
  in one transaction, surname leak-check handles "Jr."/suffixes).
- house.gov/congress.gov/govtrack 403; productive sources = OnTheIssues (PA/), Wikipedia,
  Ballotpedia, LCV scorecard, candidate platform sites (summerforpa.com key for Lee).
