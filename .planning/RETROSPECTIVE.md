# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v2.19 — Local Civic Coverage

**Shipped:** 2026-06-23 (formalized retroactively)
**Phases:** 3 (145–147, inline-executed) | **Commits:** 9 (this repo) + 3 (essentials) | **Timeline:** 2 days (2026-06-22 → 2026-06-23)

### What Was Built
- Three new local jurisdictions fully covered: **Falls Church VA** (17 officials, Alexandria template), **Greene County MO** (13, LA County template), **Springfield MO** (16, city + SPS school board). 46 records, 4 geofence boundaries, 118 evidence-only stances (0 unsourced), 46 headshots, 3 essentials coverage entries. Migrations 1047–1049.
- A Springfield resident now stacks four coverage layers at one address — city + SPS school district + Greene County + Missouri statewide execs (the last from v2.18).

### What Worked
- **Reusing locked blueprints.** Each build was a near-mechanical application of a prior template (Alexandria for independent VA cities, LA County for counties), so the work was fast and the structural traps were already known and documented.
- **Evidence-only discipline held under source walls.** Where political-record sources were fetch-walled (Ballotpedia JS-empty, VoteSmart 403, News-Leader paywall, sgfcitizen 429), officials were left as honest blanks rather than padded from party — keeping the 0-unsourced invariant across all three builds.
- **Clean-sourcing pass on headshots.** Springfield's default CivicEngage portraits had a baked-in decorative ring; the operator rejected them and a targeted re-source (SPS `meet-the-board`, Daily Citizen press) produced clean alternates rather than shipping degraded images.

### What Was Inefficient
- **Executed entirely outside GSD tracking, then reconstructed.** All three builds shipped inline with no requirements/roadmap/phase dirs, so this milestone had to be reverse-engineered from git history and memory deep-dives — and the first scope pass undercounted (missed the CA-city siblings) until the full post-v2.18 commit log was pulled. Lesson: even informal coverage builds benefit from a one-line roadmap entry at the time, so the milestone boundary isn't ambiguous later.
- **County boundaries weren't pre-loaded.** MO had zero county geofences, so Greene County needed a live TIGERweb import before the feed would surface anyone — an easy-to-miss prerequisite for any first-in-state county build.

### Patterns Established
- **`chambers.slug` collides across same-named cities** (generated column) — Springfield MO silently bound to Springfield MA's council chamber. **Always scope chamber lookups/guards by unique government name + chamber name, never slug**, and assert the right N offices landed in the intended chamber.
- **TIGERweb layer map for non-county boundaries:** Incorporated Places = `Places_CouSub_ConCity_SubMCD/MapServer` layer 4 (G4110); Unified School Districts = `School/MapServer` layer 0 (G5420); Counties = `State_County/MapServer` layer 1 (G4020). School districts are NOT always coterminous with the city — fetch the real boundary, don't copy the place polygon (Falls Church's school *was* coterminous; Springfield's was not).
- **Coverage-type split:** cities → `COVERAGE_STATES` (landing chip + typeahead, `hasContext: true` = purple); counties → `COVERAGE_COUNTIES` (search-only, `skip_overlap=1` shows only the county's own officials).

### Key Lessons
- Informal/inline execution is fine for templated coverage work, but **mark the milestone boundary as you go** — a stray ROADMAP line is cheap insurance against the reconstruction cost paid here.
- The first-in-state build for any jurisdiction type carries a hidden boundary-import prerequisite (no loaded geofence = nobody surfaces, regardless of records).

---

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
