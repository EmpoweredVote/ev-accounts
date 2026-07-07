---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 10
subsystem: stance-research
tags: [stances, inform, compass, house-candidates, maryland, sonnet-agents, primary-source-verified, isidewith]

# Dependency graph
requires:
  - phase: 162 (plan 08)
    provides: 13 MD challengers (band -240101..-240802 + Boafo -2420067) + 7 zero-tier incumbents on 8 existing races
  - phase: 162 (plan 09)
    provides: IN stances done (serialized — two stance plans never run concurrently, 3-conc cap)
provides:
  - 204 sourced federal-24 stance answers across 19/20 MD targets on PROD; 207 total incl. 3 pre-existing on a reused record
  - 0 unsourced; 1 gate-pinned whole-record skip (Jonathan Burruss -240502) with written trail
  - backend/data/stance-research/md-2026-house/ scaffold + per-candidate CSVs (gitignored; PROD durable)
affects: [162-11 (verify.sql MD 0-unsourced assertion + Burruss skip pin)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["reused-record stance targeting by assigned external_id (challenger band, Boafo's out-of-band -2420067, incumbent -2440xxx all via _push.ts external_id join); sitting-incumbent stances from congressional voting record; iSideWith ChatGPT-Party-Research flag exclusion (applied by MD-8 agent on Cheryl Riley)"]

key-files:
  created:
    - backend/data/stance-research/md-2026-house/_TOPIC_SCALE_FULL.txt (live-regenerated federal-24, identical to MN/IN — no drift)
    - backend/data/stance-research/md-2026-house/_merge.ts (MD OUT + 20-target IN_SCOPE)
    - backend/data/stance-research/md-2026-house/_push.ts, _push_uuid.ts (verbatim clones)
    - backend/data/stance-research/md-2026-house/_AGENT_BRIEF.md (MD variant)
    - backend/data/stance-research/md-2026-house/*.csv (19 per-candidate CSVs + _merged; gitignored)
    - backend/data/stance-research/md-2026-house/_SKIPS.md (1 entry: Burruss)
  modified: []

key-decisions:
  - "20 targets = 12 new challengers (band -240101..-240802) + Adrian Boafo (-2420067, reused state-delegate record; stanced from his MD General Assembly voting record) + 7 active zero-tier incumbents (-2440001..-2440008 minus Hoyer). Hoyer -2440005 RETIRED, no active row → historical backfill N/A (verified 0 answers, correct)."
  - "MD had the highest incumbent-stance ratio in the phase — all 7 active incumbents were zero-tier. Sitting reps stanced from congressional voting records (Raskin 22, Harris 17, Elfreth/Olszewski/Ivey 16, Mfume 15, McClain Delaney 11)."
  - "1 agent PER DISTRICT (8 agents), Sonnet, 3 waves @ 3-concurrency, merge-validate → push per wave. Serialized AFTER 162-09 IN (never two stance plans concurrent — 3-conc cap). No agent stalls this plan."
  - "iSideWith trap applied: MD-8 agent found Cheryl Riley's iSideWith entries flagged 'ChatGPT Party Research' (AI-inferred) and correctly EXCLUDED them (4 real rows kept, 20 inferred dropped). Reinforces the 162-11 review flag on IN's James Sceniak (20 iSideWith rows)."
  - "Agent self-corrections: Raskin (fixed a misattributed school-vouchers quote), Chris Chaffee (discarded a fabricated marylandiq.org summary), Boafo (dropped an unverifiable RENEW Act quote + a withdrawn bill), multiple declined-to-guess on vague platform language."
  - "Push verify adapted to real schema (politician_context keyed by politician_id+topic_id with sources text[])."

# Verification (all pass)
live-federal-24-count: 24 (identical to MN/IN, no drift)
answers-pushed: 204 (207 total incl. 3 pre-existing sourced answers on the Boafo reused record)
unsourced: 0
targets-covered: 19 / 20 (Burruss -240502 = documented whole-record skip)
hoyer-check: 0 answers (retired, correctly N/A)
surname-leaks: 0

# Whole-record honest-skip (gate-pin in 162-11)
| external_id | name | why (trail in _SKIPS.md) |
|---|---|---|
| -240502 | Jonathan Burruss (Unaffiliated, MD-5) | Campaign site burruss4congress.com = empty Wix placeholder; Ballotpedia 403/451; no socials/news/positions anywhere |
---

# 162-10 Summary — MD Stance Research (20 targets, PROD)

Researched and pushed federal-24 stances for all 20 MD targets — 13 challengers (incl. reused
Boafo) plus the 7 active zero-tier incumbents. **204 sourced answers, 0 unsourced, 19/20 covered**
(Jonathan Burruss the sole documented whole-record skip — no web presence). MD is now fully
end-to-end. Hoyer (retired) correctly has no stance record. This completes all four states'
stance work for the phase.

## Coverage (rows per target)
Raskin 22 · Harris 17 · Elfreth 16 · Olszewski 16 · Ivey 16 · Mfume 15 · Boafo 13 (10 new + 3 pre-existing) ·
McClain Delaney 11 · Ficker 11 · Landman 11 · McDermott 11 · Dan Schwartz 11 · Chaffee 10 · Nancy Wallace 7 ·
Cheryl Riley 4 · Berney Flowers 4 · Dave Wallace 3 · Scott Collier 3 · Brian Jordan 3 · **Burruss 0 (skip)**.

## Next
Only plan 11 (verify.sql) remains: add MN/IN/MD 0-unsourced assertions + pin the whole-record
skips (MN: Mosel/Jackson/Zieska/McKenzie; IN: none; MD: Burruss) + the IN Sceniak iSideWith review.
That closes Phase 162.
