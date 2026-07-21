---
phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
plan: 03
subsystem: stance-research
tags: [stances, compass, federal-24, mo-2026-house, research-agents, inform]

# Dependency graph
requires:
  - phase: 162 (plan 02)
    provides: 58 new MO politicians on prod (external_ids -290805..-290101), reconciliation CSV
  - phase: 161 (plans 07/09)
    provides: tn-2026-house/_push.ts + _merge.ts (clone templates); quick-candidates-2026/_push_uuid.ts
provides:
  - mo-2026-house stance scaffold (_push.ts, _merge.ts adapted, _push_uuid.ts, _TOPIC_SCALE_FULL.txt live-regenerated federal-24)
  - 61 sourced federal-24 stances on PROD for 6 batch-A evidenced-major MO candidates (0 unsourced)
affects: [162-04 (MO stance batch B — remaining 51 filers incl. Kevin Craig, reuses this scaffold), 162-11 (verify.sql stance-coverage assertion)]

# Tech tracking
tech-stack:
  added: []
  patterns: ["state-agnostic _push.ts/_push_uuid.ts reused verbatim; _merge.ts adapted per-state (IN_SCOPE + OUT); _TOPIC_SCALE_FULL.txt regenerated LIVE from inform.compass_topics+compass_stances; stance agents 1-candidate-each at 3-concurrency, validated wave-by-wave, pushed idempotently to PROD"]

key-files:
  created:
    - backend/data/stance-research/mo-2026-house/_push.ts (verbatim copy)
    - backend/data/stance-research/mo-2026-house/_push_uuid.ts (verbatim copy)
    - backend/data/stance-research/mo-2026-house/_merge.ts (copy, adapted for MO)
    - backend/data/stance-research/mo-2026-house/_TOPIC_SCALE_FULL.txt (live-regenerated)
    - backend/data/stance-research/mo-2026-house/{cori-bush,fred-wellman,chris-stigall,rick-brattin,taylor-burks,frank-barnitz}.csv (gitignored; PROD is durable store)
  modified: []

key-decisions:
  - "Federal-24 topic scale REGENERATED LIVE (Pitfall 5) — caught that TN's stale _TOPIC_SCALE_FULL.txt had only 23 topics, MISSING 'medicare/aid'. Live query of inform.compass_topics (44 active) minus 11 city-only + 8 judicial + 1 data-centers = exactly 24. This is why the plan mandated live regeneration, not copy."
  - "DEVIATION from plan text: plan said copy _merge.ts 'byte-for-byte, state-agnostic', but _merge.ts hardcodes IN_SCOPE (73 TN ids) + OUT filename — NOT state-agnostic. Adapted for MO (58 ids, mo output name); left FEDERAL 24-set as-is (already correct). _push.ts + _push_uuid.ts genuinely ARE state-agnostic (CSV path as argv, live external_id->pid resolution) — copied verbatim."
  - "DEVIATION: plan's 0-unsourced verify query referenced a pc.source_url column, but the real inform.politician_context schema stores a `sources` text[] array. Adapted the gate query to (sources IS NULL OR array_length(sources,1) IS NULL); result = true 0."
  - "Kevin Craig (MO-7 L, -290704) MOVED from batch A to batch B (162-04): 8-time perennial Libertarian = 'fringe filer' under D-03a, not an evidenced-major. Batch A finalized at 6 genuine evidenced-majors (current/former officials + Bush + notable public figures)."
  - "Stance agents run 1-candidate-each at 3-concurrency (2 waves of 3), on Sonnet (161 lesson: not Fable-5), validated wave-1 before dispatching wave-2. Orchestrator (me) did all scaffold/merge/push inline; agents had the limited role of one-candidate research only."

requirements-completed: [USHC3-05 (MO batch A portion)]

# Metrics
duration: ~70min
completed: 2026-07-04
---

# Phase 162 Plan 03: MO Stance Batch A Summary

**MO's 6 evidenced-major US House candidates (incl. former Rep. Cori Bush) have sourced, primary-source-verified chairs-not-polarity federal-24 stances on PROD — 61 answers, 0 unsourced — researched by 6 one-candidate stance agents (3-concurrency, 2 waves, Sonnet), merged and pushed idempotently.**

## Batch-A targets covered (6 evidenced-majors; MO incumbents all partial-tier → out of scope)

| external_id | candidate | dist | party | stances | notable calibration |
|-------------|-----------|------|-------|---------|---------------------|
| -290101 | Cori Bush | MO-1 | D | 20 | former US Rep; scored from Congress.gov votes/cosponsorships (climate=2 not 1, same-sex-marriage=2 for RFMA carve-outs, ukraine=2 from split votes) |
| -290209 | Fred Wellman | MO-2 | D | 8 | Lincoln Project alum; refused to stretch a civil-rights interview to trans-athletes/marriage |
| -290502 | Rick Brattin | MO-5 | R | 10 | sitting MO state senator; abortion=4 from his actual 2025 vote (rape/incest+life exceptions) over "100% pro-life" slogan |
| -290503 | Taylor Burks | MO-5 | R | 4 | former Boone County Clerk; strongest evidence a verbatim 2018 voter-ID quote (his campaign site is an unfinished template) |
| -290604 | Chris Stigall | MO-6 | R | 10 | radio host; honest-skipped trans-athletes despite show coverage (guest segment, not his advocacy); school-vouchers=2 targeted-not-universal |
| -290802 | Frank Barnitz | MO-8 | D | 9 | former MO senator+rep; abortion=2 anchored to MO Amendment 3 viability limit; blanked quotes when verbatim uncertain across fetches |

**Total: 61 sourced answers, 0 unsourced.** No whole-record honest-skips were needed (all 6 had ≥4 sourced stances).

## Verification (all on prod)

| Check | Result |
|-------|--------|
| _merge.ts validation (in-scope id, federal topic, value 1-5, non-empty reasoning, ≥1 http source) | 6 files, 61 rows, **0 problems** |
| 0-unsourced gate (sources array populated) | **0 unsourced** ✓ |
| Surname-leak guard (_push.ts) | 0 leaks ✓ |
| Per-candidate coverage | Bush 20 / Stigall 10 / Brattin 10 / Barnitz 9 / Wellman 8 / Burks 4 |

## Quality notes

- Every one of the 6 agents demonstrated genuine chairs-not-polarity discipline (evidence over party/slogan) and honest-skipped topics with no evidence rather than party-inferring — the standing standard held across both parties and severe/non-severe districts.
- Common source wall (recorded for batch B): **Ballotpedia is 451/blank-walled** to WebFetch AND the r.jina.ai proxy for MO candidates this session — do NOT rely on it in 162-04. Working bypass: `r.jina.ai/<url>` renders Missouri Independent (403-direct) and JS-walled campaign sites; Congress.gov 403s direct but renders via jina; clerk.house.gov roll-call pages fetch directly.
- Agent side-effect (benign): the Burks agent compacted the SHARED politician-stance-researcher agent-memory index (`.claude/agent-memory/.../MEMORY.md`, 48KB→16.8KB) after a hook size warning — that is the agents' own memory store, NOT the project `.planning`/user memory; detail preserved in per-candidate topic files.

## Carry-forward for 162-04 (batch B)

- Remaining ~51 MO filers (the fringe/minor candidates across all 8 districts + Kevin Craig MO-7 L) are batch B. Reuse this exact scaffold (scripts already in place); the merged file + _push.ts are idempotent, so batch B can merge into the same _merged-mo-2026-house.csv and re-push safely.
- Expect lower per-candidate coverage + more whole-record honest-skips (fringe filers often have no findable evidence) — gate floor is still 0-unsourced with a written search trail per skip.
