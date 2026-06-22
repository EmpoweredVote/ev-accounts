# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v2.18 — State Leaders

**Shipped:** 2026-06-22
**Phases:** 4 (141–144) | **Plans:** 34 | **Commits:** 45 | **Timeline:** 3 days (2026-06-20 → 2026-06-22)

### What Was Built
- Authoritative 209-office elected Big-5 roster across all 50 states (gov 50 / lt-gov 43 / AG 43 / SoS 35 / treasurer 38) — records, headshots (173+), and `role_canonical`, deduped on `(STATE_EXEC, state, role_canonical)`.
- Sourced compass stances for 199 in-scope execs across two office-typed waves (Gov+AG, then SoS+Treasurer+LtGov); 0 unsourced; 10 documented whole-record honest-skips.
- One consolidated read-only production gate `verify-phase-141-144.sql` (11 labeled assertions incl. a SEXR-05 feed-surfacing SQL simulation) — all PASS.

### What Worked
- **Office-type evidence guidance up front (SEXS-01).** Splitting stance waves by office type (richer-archive Gov+AG first, narrow-record SoS/Treasurer/LtGov second) and giving the researcher office-specific evidence rules kept exec actions mapping to topics without over-reading.
- **Querying prod before authoring every gate/seed.** Per-role counts, the honest-skip ORDER BY string, hygiene violators, and feed counts were all captured live first — so the consolidated gate passed on the first real run (one self-inflicted assertion bug aside).
- **Belt-and-suspenders honest-skip pinning** (USHS-14a pattern) carried from v2.17 — every uncovered in-scope exec pinned to an exact external_id so a future regression fails loudly instead of hiding in a slack count.
- **Inline execution for data/gate phases** (no worktrees) matched the work: single SQL file, live prod verification, full orchestrator control.

### What Was Inefficient
- **Over-engineered one gate assertion.** The first-pass SEXR-03 added a NULL-`role_canonical`-by-title heuristic that false-failed on 8 legitimately-out-of-scope / duplicate offices, costing an investigation cycle. The exact per-role counts in SEXR-01/02 already guard a missing canonical row — the extra check was redundant and wrong.
- **CLI accomplishment auto-extraction produced garbage** ("Status:" ×23) — the MILESTONES.md entry had to be hand-written. Phase SUMMARY one-liner extraction doesn't survive these summary formats.

### Patterns Established
- **Consolidated milestone gate = one read-only SQL file folding all per-phase gates + a feed-surfacing SQL simulation**, proving the whole data milestone with a single `psql ... exit 0`.
- **Records-gate scoping rule:** assert on `role_canonical IN (Big-5)`, never on a bare `district_type` count and never via title regex — out-of-scope offices (legislature-selected, appointed) and legacy duplicate rows legitimately carry NULL `role_canonical`.
- **Functional-treasurer aliasing:** FL CFO + NY/TX Comptroller fold into `role_canonical='treasurer'`; MD elected Comptroller stays out.

### Key Lessons
1. Don't add "defensive" assertions a gate doesn't need — the exact-count assertions are the guard; a redundant heuristic only invents false-fail surface (and out-of-scope NULLs are correct, not bugs).
2. For ordered honest-skip pins, capture the expected literal verbatim from the live `ORDER BY` — never hand-order (carried from the v2.17/143 lesson; held again here).
3. Verify officeholders and counts against live prod, not training data — Jan-2026 inaugurations and 2024-race outcomes aren't reliably known.

### Cost Observations
- Model mix: planning/execution orchestrated on Opus; subagents (planner/checker/verifier/executor) on Sonnet.
- Notable: a pure-data milestone with no backend code shipped in 3 days/34 plans because the feed query (`STATE_EXEC`) was already wired — the work was roster accuracy + sourced evidence, gated by SQL.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v2.16 | 5 | 9 | National House stance pipeline established (shared `_TOPIC_SCALE.txt`, external_id→UUID push) at 3-concurrency |
| v2.17 | 9 | 45 | Largest-first wave ordering; one-try-per-URL agent efficiency rule; honest-skip external_id pinning (USHS-14a) |
| v2.18 | 4 | 34 | Office-typed stance waves; single consolidated milestone gate folding all per-phase gates + feed-surfacing SQL simulation |

### Top Lessons (Verified Across Milestones)

1. **Source every value to a fetched URL; honest-skip beats inference; never infer from party.** Held across v2.16, v2.17, v2.18.
2. **Pin the exact uncovered set by external_id** so future regressions fail loudly — and match the expected literal to the query's exact `ORDER BY`.
3. **Query production before authoring seeds/gates** — heterogeneous external_ids, irregular rosters, and recent elections defeat assumptions.
