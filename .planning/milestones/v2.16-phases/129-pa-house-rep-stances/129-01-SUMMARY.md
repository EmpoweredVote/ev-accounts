---
phase: 129-pa-house-rep-stances
plan: 01
status: complete
completed: 2026-06-17
requirements: [USHS-03]
---

# 129-01 SUMMARY — PA House Rep Stances, Batch A

## What was built

Researched + pushed sourced compass stances for the first 9 Pennsylvania US House reps
(PA-01..09, external_id -42001..-42009) across the 25 federal topics.

- **136 `inform.politician_answers`** rows upserted; **136 paired context rows** (0 unsourced)
- **28 `essentials.quotes`** inserted; **28 Read-&-Rank selected**; 0 leaks
- CSV: `backend/data/stance-research/2026-06-17-pa-house-batch-a.csv`

## Per-rep stance counts (of 25 federal topics)

Evans 20, Boyle 18, Scanlon 18, Fitzpatrick 17, Houlahan 17, Dean 14, Mackenzie 12,
Meuser 12, Bresnahan 8.

## Evidence-over-party highlights

- **Fitzpatrick (R, PA-01)** scores as a genuine moderate — abortion=3, same-sex-marriage=2
  (voted for Respect for Marriage Act), climate=3, immigration=2 — clearly distinct from the
  other PA Republicans. Highest-LCV House Republican.
- **Mackenzie/Meuser (R)** cluster 4–5 (climate=5, deportation=4, immigration=4), but Mackenzie
  healthcare=3 (signed ACA discharge petition) and medicare=3 ("no changes to SS/Medicare") —
  not auto-rightward.
- **Dems (Boyle/Evans/Dean/Scanlon/Houlahan)** cluster 1–2; tariffs=3 across nearly everyone
  (USMCA/selective protectionism, not free-trade or blanket).
- **Bresnahan (R, PA-08)** honestly thin at 8 — freshman, campaign site offline, local news
  blocked to WebFetch. Honest-skip of 17 rather than party-inference.

## Process notes

- **Concurrency held at 3.** One session-limit pause (usage limit, resets 10pm PT — NOT 429)
  hit the Dean/Scanlon/Houlahan triple before they wrote CSVs; all three re-dispatched cleanly
  on resume and completed.
- **CSV escaping:** Mackenzie emitted systematic quad-quote (`""""`) wrapping on quote fields
  and several rows had extra trailing commas. Fixed with a canonical re-parse/re-stringify step
  (csv-parse `relax_column_count` → csv-stringify) applied to every per-rep CSV before merge —
  more robust than manual repair. Merge parser reported 0 problems on 136 rows.
- **Push keyed by external_id→UUID** (not name) for answers/context/quotes — handles name
  variants ("Robert P. Bresnahan, Jr." vs CSV "Robert P. Bresnahan Jr.") cleanly. Reusable
  script: `backend/data/stance-research/pa-house-a/_push.ts`.
- house.gov/congress.gov/govtrack 403; productive sources = OnTheIssues (PA/), Wikipedia,
  Ballotpedia, LCV scorecard, lehighvalleynews.com (key unlock for Mackenzie).
