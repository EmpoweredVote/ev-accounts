---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 06
subsystem: stance-research
tags: [stances, inform, compass, house-candidates, minnesota, sonnet-agents, primary-source-verified]

# Dependency graph
requires:
  - phase: 162 (plan 05)
    provides: 35 new MN candidates on prod (band -270804..-270101) + MN 2026 Statewide General election
  - phase: 161 (plans 06/08)
    provides: tn-2026-house/_push.ts + _merge.ts, quick-candidates-2026/_push_uuid.ts (scaffold clones)
provides:
  - 146 sourced federal-24 stance answers across 31/35 new MN candidates on PROD (inform.politician_answers + politician_context + essentials.quotes)
  - 4 gate-pinned whole-record honest-skips with written search trails (for 162-11 pin table)
  - backend/data/stance-research/mn-2026-house/ scaffold + per-candidate CSVs (gitignored; PROD is durable store)
affects: [162-11 (verify.sql MN 0-unsourced assertion + whole-record skip pin table)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["1 stance agent PER DISTRICT (8 agents, 3 waves @ 3-concurrency, Sonnet); live-regenerated federal-24 topic scale; merge-validate-then-push per wave for resilience"]

key-files:
  created:
    - backend/data/stance-research/mn-2026-house/_TOPIC_SCALE_FULL.txt  (live-regenerated federal-24)
    - backend/data/stance-research/mn-2026-house/_merge.ts (MN OUT + IN_SCOPE=35)
    - backend/data/stance-research/mn-2026-house/_push.ts, _push_uuid.ts (verbatim clones)
    - backend/data/stance-research/mn-2026-house/_AGENT_BRIEF.md (shared agent contract)
    - backend/data/stance-research/mn-2026-house/*.csv (31 per-candidate CSVs + _merged; gitignored)
    - backend/data/stance-research/mn-2026-house/_SKIPS.md (4 whole-record skip trails; gitignored)
  modified: []

key-decisions:
  - "federal-24 topic set live-verified: 44 active compass_topics minus 20 non-federal (11 city/local + 8 judicial-* + data-centers) = 24. Regenerated _TOPIC_SCALE_FULL.txt from live inform.compass_stances (value/text cols) rather than copying TN's file; abortion text confirmed identical (no drift). The 24th key is medicare/aid (slash-keyed)."
  - "Scaffold _push.ts/_push_uuid.ts are state-agnostic (csvPath argv, resolves external_id->pid + topic_key->tid, upserts answers+context+quotes with surname-leak guard) — reused verbatim. Only _merge.ts customized (OUT filename + IN_SCOPE = 35 MN external_ids)."
  - "MN incumbents (-27001..-27008) all partial-tier → out of scope, never topped up (band-scoped targeting excludes them by construction; Craig -27002 has no active row)."
  - "Ran 1 agent PER DISTRICT (8 agents) in 3 waves at 3-concurrency (validate wave 1 before wave 2). Merged + pushed to PROD after each wave for resilience (stance CSVs gitignored → PROD is durable store)."
  - "Push verify query in the PLAN referenced a stale schema (pc.answer_id/pc.source_url); real schema keys politician_context by (politician_id, topic_id) with a `sources` text[]. Gate adapted: 0 answers lack a context row with array_length(sources)>=1."

# Verification (all pass)
live-federal-24-count: 44 active - 20 non-federal = 24
answers-on-prod: 146
unsourced: 0
candidates-with-stances: 31 / 35
whole-record-skips-for-162-11-pin: [-270207 Christopher Mosel, -270501 DeVelle L. Jackson, -270505 Abbey Zieska, -270507 Abena A. McKenzie]
partial-tier-incumbent-topups: 0
surname-leaks: 0
---

# 162-06 Summary — MN Stance Research (full field, PROD)

Researched and pushed federal-24 policy stances for all 35 new MN 2026 US House
candidates. **146 sourced answers across 31 candidates, 0 unsourced**, primary-source-
verified, chairs-not-polarity. The other 4 candidates are genuine whole-record honest-
skips (no usable web presence), each logged with a full written search trail for the
162-11 pin table. MN incumbents are all partial-tier and were excluded (out of scope).

## Method
- Scaffold cloned from tn-2026-house (`_push`/`_merge`) + quick-candidates (`_push_uuid`);
  `_TOPIC_SCALE_FULL.txt` regenerated LIVE (24 federal topics, count re-verified vs 44 active).
- 1 stance-research agent PER DISTRICT (8 agents), Sonnet, dispatched in 3 waves at
  ≤3-concurrency. Wave 1 (MN-2/5/8, richest fields) validated before waves 2–3.
- Each wave: merge-validate (scope/topic/value/http-source checks, 0 problems) → push to
  PROD (idempotent upsert) → 0-unsourced gate. PROD is the durable store (CSVs gitignored).

## Coverage (rows per candidate)
- MN-1: Goetzman 2, Morlan 4, Eaton 3, Johnson 8
- MN-2: Pratt 2, Abdulle 4, Berg 9, Klein 6, Little 9, McTavish 5 — **skip: Mosel (-270207)**
- MN-3: Bass 2, Wittrock 8
- MN-4: Rechtzigel 2, Wikstrom 4, Xiong 1, Rahman 12
- MN-5: Al-Aqidi 6, Nagel 2, Windhauser 2, Le 4, Reeves 11, Schluter 2 — **skips: Jackson (-270501), Zieska (-270505), McKenzie (-270507)**
- MN-6: Corey 1, Foley 5, Chapin 9
- MN-7: Carlson 1, Osberg 2
- MN-8: Hamilton 1, Gulbranson 5, Munter 7, Swanson 7

## Whole-record honest-skips (gate-pin these in 162-11)
| external_id | name | why (trail in _SKIPS.md) |
|---|---|---|
| -270207 | Christopher Mosel (DFL, MN-2) | No campaign site (confirmed by West St. Paul Reader "[No response]"), $0 FEC, no survey/socials/news |
| -270501 | DeVelle L. Jackson (Ind, MN-5) | No site/FEC/news; isidewith hit was a different GA-Senate "Develle Jackson" (correctly rejected) |
| -270505 | Abbey Zieska (R, MN-5) | Pre-infrastructure; Hometown Source explicitly noted "did not have websites" at filing |
| -270507 | Abena A. McKenzie (DFL, MN-5) | Site is local-community-services framing; nothing maps to the 24 federal topics |

## Data-quality flags surfaced (informational — party is NOT on the candidate card, no data impact)
- **Oliver R. Morlan (-270102)**: local MN news describes him campaigning as an *Independent* who split from the GOP, though the record lists Republican. (An indirect ukraine-support row was correctly dropped for non-specific evidence.)
- **Kaela Berg (-270203)**: is a MN *House* Rep (55B), not a State Senator as first labeled.
- **Abdi Abdulle (-270202)**: legal/filing name Abdisallam Abdulle; campaign site abdulle4congress.com.
Consider a roster spot-check in a future data-quality pass; none block this plan.

## Next
Per D-03, MN is now fully end-to-end (seed → headshots → stances). Remaining Phase 162
plans: IN (07/08), MD (09/10), and 162-11 verify.sql (add MN 0-unsourced assertion +
the 4-row whole-record skip pin table above).
