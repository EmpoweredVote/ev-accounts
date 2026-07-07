---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 08
state: CT
status: complete
completed: 2026-07-06
requirements: [USHC3-05]
---

# 164-08 SUMMARY — CT Stances

## Result
All 17 new CT candidates resolved on **PROD**: **15 stance-complete (97 sourced answers), 2 gate-pinned whole-record skips**, 0 unsourced, 0 surname leaks.

## Pipeline
- Scaffold `ct-2026-house/` (IN_SCOPE = 17 CT ids). 5 `politician-stance-researcher` agents (Sonnet), ≤3 concurrent (CT-1 / CT-2+3 / CT-4 first, CT-5 after a slot freed). Merge: 15 files, 97 rows, 0 problems. Push: 97 answers + 97 contexts + 84 quotes, 0 leaks. Gate: 0 unsourced.

## Per-candidate row counts (15 covered)
Bronin 12, Gilchrest 16, Fortune 5, Chai 2 (CT-1); Austin 9 (CT-2); Lancia 5, Irizarry 2, Andrew Rice 10 (CT-3); Goldstein 8, Miressi 5, Perez-Caputo 7 (CT-4); Shea 2, De Barros 4, Botelho 4, Taddeo-Waite 6 (CT-5).

## Whole-record skips (gate-pinned for 164-13, trails in `_SKIPS.md`)
- **-90403 Luz Helena Bueno** — FEC-filed but no reachable primary source (campaign site empty/404, Ballotpedia/FEC empty, only unattributed aggregator paraphrases). Provisional filer.
- **-90405 Damon Lawrence Cerreta** — FEC-filed but only generic non-specific campaign language, unmappable to any scale without guessing. Provisional filer.

## Integrity calls (verified)
- **Andrew Rice (-90303) identity CONFIRMED as the CT-3 candidate** (own campaign site: "#ReplaceRosa," lifelong Nutmegger) — distinct from the OK ex-senator homonym whose headshot was purged in 164-02. Stance data correctly attributed.
- **Amy Chai `ukraine-support` row DROPPED** by orchestrator — agent flagged it as inferred from a general non-interventionism statement (no Ukraine-specific evidence); removed per chairs-not-polarity/no-inference (Chai now 2 clean rows).
- **Botelho (-90503)** HOLD→INCLUDE decision validated: 4 real sourced rows (abortion, deportation, trans-athletes, tariffs).
- Taddeo-Waite party (Independent per seed) unconfirmed vs some sources showing Democratic — does not affect stance push (party not stored on answers).
- Lancia/Irizarry (both CT-3 R) cross-checked to avoid quote bleed-through; Taddeo-Waite agent self-corrected a wrong-URL misattribution mid-flight.

## Files (CSVs gitignored → PROD durable store)
`backend/data/stance-research/ct-2026-house/`: `_merge.ts`, `_push.ts`, `_push_uuid.ts`, `_AGENT_BRIEF.md`, `_TOPIC_SCALE_FULL.txt`, `_SKIPS.md` (all gitignored) + gitignored CSVs.

## Self-Check: PASSED
0 unsourced on prod; 15/17 stance-complete; 2 skips with written trails; ≤3 concurrency; verification pass per agent; no incumbent topped up.
