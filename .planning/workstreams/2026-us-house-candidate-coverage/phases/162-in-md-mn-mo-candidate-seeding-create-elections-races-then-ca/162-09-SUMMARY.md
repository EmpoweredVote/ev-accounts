---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 09
subsystem: stance-research
tags: [stances, inform, compass, house-candidates, indiana, sonnet-agents, primary-source-verified, isidewith]

# Dependency graph
requires:
  - phase: 162 (plan 07)
    provides: 12 IN challengers (band -180101..-180902) + IN 2026 Statewide General; 3 zero-tier incumbents (Baird/Carson/Messmer)
  - phase: 161 (plans 06/08)
    provides: tn-2026-house scaffold + quick-candidates _push_uuid
provides:
  - 153 sourced federal-24 stance answers across all 15 IN targets on PROD (12 challengers + 3 zero-tier incumbents); 161 total incl. 8 pre-existing on Bradley Meyer
  - 0 unsourced; 0 whole-record skips (every target has >=1 sourced stance)
  - backend/data/stance-research/in-2026-house/ scaffold + per-candidate CSVs (gitignored; PROD durable)
affects: [162-11 (verify.sql IN 0-unsourced assertion; Sceniak iSideWith review flag)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["reused-record stance targeting by assigned band external_id (works for both negative challenger ids and positive incumbent SoS ids); sitting-incumbent stances from congressional voting record (GovTrack/congress.gov/clerk.house.gov); iSideWith ChatGPT-Party-Research flag exclusion for record-less challengers"]

key-files:
  created:
    - backend/data/stance-research/in-2026-house/_TOPIC_SCALE_FULL.txt (live-regenerated federal-24, identical to MN — no drift)
    - backend/data/stance-research/in-2026-house/_merge.ts (IN OUT + 15-target IN_SCOPE incl. 3 positive incumbent ids)
    - backend/data/stance-research/in-2026-house/_push.ts, _push_uuid.ts (verbatim clones)
    - backend/data/stance-research/in-2026-house/_AGENT_BRIEF.md (IN variant — notes positive incumbent ids)
    - backend/data/stance-research/in-2026-house/*.csv (15 per-candidate CSVs + _merged; gitignored)
  modified: []

key-decisions:
  - "Targets = 12 IN challengers (band -180101..-180902, incl. 7 reused records assigned band external_ids in mig 1214) + 3 zero-tier incumbents by POSITIVE SoS external_id (Baird 499386, Carson 499408, Messmer 499413). _push.ts joins on external_id, so positive-id incumbents push identically."
  - "Houchin (done-tier, 25 stances) and 5 partial-tier incumbents (Mrvan/Yakym/Stutzman/Spartz/Shreve) NOT topped up — verified Houchin still 25 post-push."
  - "1 agent PER DISTRICT (9 agents), Sonnet, 3 waves @ 3-concurrency. Zero-tier sitting incumbents first (D-03a) — Carson 18 / Baird 15 / Messmer 10 rows from congressional voting records. Wave 3 had 2 stream-watchdog stalls (IN-1, IN-3, infra not rate-limit); re-dispatched fresh, both completed."
  - "Verification catches by agents: Baird — discarded a GovTrack id that resolved to Ro Khanna + a bioguide that returned Dan Bishop; Messmer — corrected a fabricated 'voted for abortion ban' claim (he voted to preserve exceptions); Brad Meyer — dropped an inferential same-sex-marriage row; Kelly Thompson — dropped a housing row whose secondary source didn't match her page."
  - "iSideWith for record-less challengers (sanctioned fallback): Cinde Wirth agent explicitly checked iSideWith's 'ChatGPT Party Research' disclosure and confirmed its 14 iSideWith rows do NOT overlap the ~7 AI-flagged items. James Sceniak (20 rows, iSideWith-heavy) did NOT explicitly report that exclusion check → FLAGGED for 162-11 review (prune any ChatGPT-flagged topics)."
  - "Push verify adapted to real schema (politician_context keyed by politician_id+topic_id with sources text[]), same as 162-06."

# Verification (all pass)
live-federal-24-count: 24 (identical to MN, no drift)
answers-pushed: 153 (161 total incl. 8 pre-existing sourced answers on Bradley Meyer 926943ad — same rc-linked IN person)
unsourced: 0
targets-covered: 15 / 15
whole-record-skips: 0
houchin-topup-check: 25 (unchanged — not topped up)
surname-leaks: 0

# Data-quality flags (for 162-11 / future cleanup)
- Reused records display DB full_name (Bradley Meyer / Cynthia Wirth / Jonathan Ford / Patrick Mcauley); candidate card uses race_candidates.full_name (ballot names). Consider preferred_name backfill if any surface shows politicians.full_name with stances.
- James Sceniak (-180702): 20 rows almost entirely iSideWith; review against iSideWith's ChatGPT-Party-Research flags in 162-11 and prune inferred topics if any.
- William Henry (-180202) ukraine-support=4 was mapped from general non-interventionist platform language (agent noted, not a Ukraine-specific statement).
---

# 162-09 Summary — IN Stance Research (15 targets, PROD)

Researched and pushed federal-24 stances for all 15 IN targets — the 12 general challengers
plus the 3 zero-tier sitting incumbents (Baird, Carson, Messmer). **153 sourced answers,
0 unsourced, 0 whole-record skips**, primary-source-verified, chairs-not-polarity. IN is now
fully end-to-end (seed → headshots → stances). Houchin (done-tier) and the 5 partial-tier
incumbents were correctly left untouched.

## Method
- Scaffold cloned (tn `_push`/`_merge` + quick-candidates `_push_uuid`); topic scale live-
  regenerated (24 federal, identical to MN). _merge IN_SCOPE = 12 challenger band ids + 3
  positive incumbent SoS ids.
- 9 per-district Sonnet agents, 3 waves @ ≤3-concurrency, merge-validate → push per wave.
  Sitting incumbents first (richest: congressional voting records). Two Wave-3 stream stalls
  re-dispatched and completed.

## Coverage (rows per target)
Carson 18 · Sceniak 20 · Cinde Wirth 20 · Bradley Meyer 20 (12 new + 8 pre-existing) · Baird 15 ·
J.D. Ford 11 · Jamee Decio 11 · Messmer 10 · Drew Cox 10 · Kelly Thompson 8 · Mary Allen 7 ·
Tonya Hudson 4 · Patrick McAuley 3 · William Henry 3 · Barb Regnitz 1 (site not yet launched).

## Next
Chain to plan 08 (MD seed — races-only reuse onto 8 pre-existing MD races; look up MD election
name live) then plan 10 (MD stances) + 162-11 verify. Watch for MD dedup surprises like IN's.
