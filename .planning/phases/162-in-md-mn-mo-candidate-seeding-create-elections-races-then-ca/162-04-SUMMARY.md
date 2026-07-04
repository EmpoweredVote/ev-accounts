---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 04
subsystem: stance-research
tags: [stances, compass, federal-24, mo-2026-house, research-agents, inform, honest-skip]

# Dependency graph
requires:
  - phase: 162 (plan 03)
    provides: mo-2026-house scaffold (_push.ts, _merge.ts adapted, _push_uuid.ts, _TOPIC_SCALE_FULL.txt); batch-A covered list (6 evidenced-majors)
  - phase: 162 (plan 02)
    provides: 58 new MO politicians on prod
provides:
  - MO full-field stance coverage on PROD — 176 sourced federal-24 answers across 39 of 58 new MO candidates, 0 unsourced
  - 19 enumerated whole-record honest-skips (external_ids below) for the 162-11 verify.sql pin table
affects: [162-11 (verify.sql MO stance-coverage assertion + pinned whole-record skip set), 167 (MO Aug-4 re-pull)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["one-agent-PER-DISTRICT batching (8 agents, 3 waves @ 3-conc, Sonnet) for fringe filers instead of one-per-candidate (would be 52 agents); idempotent merge+push to PROD; honest-skip with per-candidate search trail is the expected down-ballot outcome"]

key-files:
  created:
    - backend/data/stance-research/mo-2026-house/mo{1,2,3,4,5,6,7,8}-batchb.csv (gitignored; PROD is durable store)
  modified: []

key-decisions:
  - "Batch B researched ONE AGENT PER DISTRICT (8 agents across 3 waves @ 3-concurrency), not one-per-candidate — 52 candidates would have been ~17 waves. Per-district batching lets an agent fetch each district's field once and compare filers, and is higher quality for fringe candidates. Honored the 3-concurrency cap + first-wave-validation standard throughout."
  - "19 of 52 batch-B candidates are WHOLE-RECORD HONEST-SKIPS: confirmed real 2026 filers (FEC/BallotReady/campaign-tracker verified) but with NO findable scale-mappable policy content — only Civoren/GoodParty boilerplate, bio-only profiles, or dead/placeholder campaign sites. Per the standing standard, honest-skip with a written search trail is correct; NO party-inference padding was used anywhere."
  - "Agents showed consistent chairs-not-polarity discipline: declined to score vague meta-statements ('common-sense gun laws', 'individual liberty'), flagged dated/vintage sources (Daugherty 2024 voter guide, Berry 2022 lawsuit), refused unverifiable secondhand claims (Casey YouTube, Reichard town-hall abortion), and scored idiosyncratic libertarian positions on evidence (Craig same-sex-marriage=3 for 'government out of marriage', flagged as imperfect fit)."

requirements-completed: [USHC3-05 (MO batch B portion — MO now stance-complete)]

# Metrics
duration: ~65min
completed: 2026-07-04
---

# Phase 162 Plan 04: MO Stance Batch B Summary

**MO's full 2026 US House field is stance-complete on PROD — 176 sourced federal-24 answers across 39 of 58 new candidates, 0 unsourced, with 19 documented whole-record honest-skips (confirmed-real filers with no findable policy content). Researched by 8 one-district-each stance agents (3 waves @ 3-concurrency, Sonnet), merged and pushed idempotently.**

## Coverage (batch A + batch B combined, all 58 new MO candidates)

- **39 candidates** with ≥1 sourced stance (176 total answers, 0 unsourced)
- **19 candidates** = whole-record honest-skips (enumerated below)
- Richest batch-B records: Kevin Craig MO-7 (13), Beebe MO-5 (7), Smead MO-6 (5), Heslop MO-8 (5), Russell MO-4 (5), Harris MO-1 (5), Schmitz MO-1 (6), Patty MO-5 (5), Wilkinson MO-2 (5)

## Batch-B waves (one agent per district, 3-concurrency)

| Wave | Districts | Rows | Skips |
|------|-----------|------|-------|
| 1 | MO-1 (13r/3skip), MO-2 (20r/1skip), MO-3 (8r/4skip) | 41 | 8 |
| 2 | MO-4 (12r/7skip), MO-5 (15r/2skip), MO-6 (20r/0skip) | 47 | 9 |
| 3 | MO-7 (19r/1skip), MO-8 (8r/1skip) | 27 | 2 |
| **Total batch B** | 52 candidates | **115** | **19** |

(Batch A added 61 rows across 6 candidates in 162-03 → MO grand total 176 answers.)

## Whole-record honest-skips — the 162-11 verify.sql pin set (19 external_ids)

All confirmed real 2026 filers (per FEC / BallotReady / campaign-tracker sites) with no findable scale-mappable policy content. Search trails in each district agent's return (captured in this session's transcript).

```
-290103  Carl E. Henderson (MO-1 D)   -- Civoren/GoodParty boilerplate only
-290104  Alissa Murphy (MO-1 D)       -- BallotReady bio only, no positions
-290106  Andrew Jones (MO-1 R)        -- Civoren vague growth language only
-290201  Elizabeth Sparks-Holmes (MO-2 R) -- site themes only, no scale-mappable position
-290302  Mike Conner (MO-3 D)         -- FEC-confirmed, no site/news/social
-290303  Tommy Holstein (MO-3 D)      -- FEC-confirmed, no working site/news
-290305  Paul Wilson (MO-3 D)         -- JS-placeholder Wix platform, no extractable text
-290306  Jim Higgins (MO-3 L)         -- only stale 2012-2015 gubernatorial coverage
-290401  Heather Shelton (MO-4 R)     -- Civoren vague pledges only
-290402  Scott Vera (MO-4 R)          -- FEC-confirmed, no site/content
-290403  Jeanette Cass (MO-4 D)       -- Civoren generic phrases, unmappable
-290404  Hartzell Gray (MO-4 D)       -- FEC-confirmed, no policy content
-290405  Jordan Herrera (MO-4 D)      -- Civoren meta-political statements only
-290407  G Rick (MO-4 D)              -- Civoren: no bio/policy submitted
-290410  Thomas Holbrook (MO-4 L)     -- FEC-confirmed, ideology label only
-290505  Berton A. Knox (MO-5 R)      -- BallotReady-confirmed, no content
-290507  Randall Langkraehr (MO-5 L)  -- FEC-confirmed, unclaimed/placeholder profiles
-290701  John Casey (MO-7 R)          -- no site; unquotable YouTube ref only
-290805  Rebecca Sharpe Lombard (MO-8 L) -- bio only, all sources walled/404
```

## Verification (all on prod)

| Check | Result |
|-------|--------|
| _merge.ts validation (14 files, batch A+B) | 176 rows, **0 problems** |
| 0-unsourced gate (sources array populated) | **0 unsourced** ✓ |
| Surname-leak guard (_push.ts) | 0 leaks ✓ |
| Candidates with neither answers nor context | exactly **19** (all documented whole-record skips) ✓ |
| Batch B did not clobber batch A | idempotent re-upsert, batch-A counts unchanged ✓ |

## Data-quality flags carried forward (for 162-11 / Phase 167)

- **Clayton Harbison (MO-8 D, -290803):** a Ballotpedia snippet suggested he may NOT appear on the primary ballot — re-check at the Phase-167 MO Aug-4 cull (his row kept for now: live site, named in-scope candidate).
- MO general-election map remains unsettled (referendum cert ~Jul-27) — the whole MO field is a Phase-167 re-pull regardless.

## Notes

- **Source walls this session (for future MO work):** Ballotpedia 451/blank even via r.jina.ai; FEC api.open.fec.gov DEMO_KEY hard rate-limited (429, ~100min) after ~first queries. Best working discovery method: `r.jina.ai/https://duckduckgo.com/html/?q=...` to surface non-obvious campaign domains; `[name]forcongress.com` guessing; r.jina.ai for Missouri Independent (403-direct) + JS-walled Wix/campaign sites; kevincraig.us needs http:// on some subpages (cert scope).
- Agents updated their own shared politician-stance-researcher agent-memory (per-district method notes) — that is the agents' store, not project/user memory.
- **MO is now fully end-to-end complete** (audit → seed → headshots → stances A+B) per D-03. Next state per D-03: MN (162-05 seed, 162-06 stances).
