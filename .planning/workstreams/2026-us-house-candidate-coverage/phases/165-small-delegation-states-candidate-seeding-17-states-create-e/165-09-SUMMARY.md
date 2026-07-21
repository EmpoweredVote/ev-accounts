---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 09
state: NV+ME
status: complete
completed: 2026-07-07
requirements: [USHC3-05]
---

# 165-09 SUMMARY — NV + ME stance research pushed to PROD

## What was built
nv/me-2026-house scaffolds (KS-clone pipeline + **live-regenerated federal-24 `_TOPIC_SCALE_FULL.txt`** — live active count re-verified at 44, federal subset = 24) and full stance research for the NV/ME 2026 fields, pushed to PROD (durable store; CSVs gitignored).

## Coverage (52 answers total, 0 unsourced, 0 surname leaks)
- **ME (36 answers):** Pingree (-230201, **zero-tier incumbent, FULL research: 18 topics** — congress.gov cosponsor pages + clerk.house.gov roll calls + campaign site), Dunlap (-230203, 12 topics — campaign site + Maine Public questionnaire; verification pass fixed 2 quote-fidelity issues + removed 1 misattributed quote), Russell (-230103, 6 topics — own campaign issue pages; iSideWith AI-inferred rows correctly excluded). RCV over-indulgence applied throughout.
- **NV (16 answers):** Khan (-320174, 6), St John (-320175, 4), Chapman (-320251, 2 — incl. a 2025 legislative-testimony voting-rights row and a dated-but-definitive same-sex-marriage row, staleness flagged in reasoning), Kamerath (-320301, 4).
- **Whole-record honest-skips (gate-pin for 165-17):** **-320479 Russell Best** and **-320480 William Johnson** — both perennial/fringe filers with zero policy web presence; full search trails written to `nv-2026-house/_SKIPS.md`.

## Key determinations
- **Golden (pid c420f946) confirmed OFF-BALLOT live (0 active race_candidates rows) → out of scope**, per plan branch.
- NV partial-tier incumbents (-32001..-32004) not topped up (correct per diagnostic).
- Chapman researched under her new -320251 external_id (normal _push.ts path; no UUID path needed).
- Push results: ME `{answers:36, contexts:36, quotes:25, leaks:[]}`; NV `{answers:16, contexts:16, quotes:15, leaks:[]}`. Canonical 0-unsourced query (politician_context.sources array) = 0 for both states. NOTE: the plan's inline verify query referenced a nonexistent `pc.answer_id/source_url` schema — the canonical 164-verify.sql sources-array query was used instead.

## Agent method notes (inherited by later plans)
3-concurrency held throughout; first wave validated before further dispatch; 2 transient API-error deaths (Dunlap ×2) recovered — second death was post-CSV and resumed in place to finish its verification fix. Source intel: Ballotpedia hard-walled (empty/403 even via r.jina.ai) for NV/ME candidates; html.duckduckgo.com + lite.duckduckgo.com work as discovery targets; raw `curl` + grep beats WebFetch summarization for verbatim quotes on small sites; r.jina.ai rescues PDF parses.

## Self-Check: PASSED
0 unsourced on PROD for all pushed NV/ME rows; every new candidate + Pingree has ≥1 sourced stance OR a written-trail whole-record skip; ≤3 concurrency; verification passes performed. Gate pins: -320479, -320480.
