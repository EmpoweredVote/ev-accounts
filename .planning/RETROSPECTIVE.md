# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v2.20 — 2026 US House Candidate Coverage (Wave 1)

**Shipped:** 2026-06-30
**Phases:** 5 (148–152) | **Plans:** 32 | **Timeline:** ~2 days (scoped 2026-06-28, executed 2026-06-28→29, closed 06-30)

### What Was Built
The Nov-3 2026 US House general-ballot field for the four largest-delegation states — CA (52) / TX (38) / FL (28) / NY (26) = **144 districts, 415 active `race_candidates`** — surfacing on `/elections` for any in-district address via the elections feed (`races` + `race_candidates`, PostGIS `ST_Covers`). Federal-24 chairs-not-polarity stances (0 unsourced), headshots, 0 duplicate-incumbent records. Pure-data milestone, no backend code. Proven by the Phase 152 consolidated gate (`152-verify.sql` 8/8 + `152-coordinate-smoke.ts` 4/4).

### What Worked
- **Diagnostic-first phase (148) prevented the two highest-cost traps** — the v2.4 two-Andy-Barrs duplicate-incumbent failure and the lost-incumbent-primary assumption (NY-10 Goldman / NY-13 Espaillat both lost 6/23). Resolving the field + stance-gap up front meant the seeding phases never INSERTed a duplicate politician row.
- **CA-turnkey-first sequencing (149) validated the pipeline** before the harder author-elections-then-candidates work in TX+NY (150) and FL (151). Each phase reused the prior's stance/headshot/repair scripts.
- **Consolidated gate as a single milestone proof (152)** — one `152-verify.sql` re-asserting all-144 invariants + a 4-state coordinate smoke gave a clean, re-runnable green surface, mirroring the v2.18 `verify-phase-141-144.sql` precedent.
- **0-unsourced as an existence check, not coverage** — the key insight that let the consolidated gate coexist with FL's intentionally-incomplete provisional field without false-failing.

### What Was Inefficient
- **Stance-researcher agents emit malformed CSVs** (trailing-comma 11-col rows, quadruple-`""""` quote typos, unquoted-reasoning-with-commas) — required a reusable relax-parse + canonical-restringify repair pipeline + `source_url_1` misalignment guard. Now standard, but cost rework in 149 before it was systematized.
- **Quote verbatim-verification** — aggregator quote strings were only ~60% locatable on the exact cited URL; quotes were withheld from push (values+reasoning+sources only) pending a deferred Read-and-Rank pass.
- **`milestone.complete` auto-extracted accomplishments were noisy** (CA-149-heavy, empty "Status:" lines) — hand-rewritten at close.

### Patterns Established
- **Pure-data elections-feed surfacing (Path B)**: `race_candidates.politician_id` NON-NULL (NULL = no stances/photo); never `office_id IS NULL` on a House race; party lives on `races.primary_party` only (antipartisan invariant, enforced at query layer + gate-asserted via `information_schema`).
- **Provisional-field convention**: pre-primary fields seeded now with a `PROVISIONAL:` race-description sentinel + a date-gated re-check phase for the prune (two-path: `is_active=false` AND `candidate_status='withdrawn'`, never hard-DELETE).
- **Consolidated milestone gate = fold per-phase gates' invariants into one all-scope assertion surface** + a multi-sample coordinate smoke asserting the challenger (not just incumbent) surfaces.

### Key Lessons
- A milestone-level "0 unsourced / 0 duplicate" gate must be an **existence check**, never a per-entity coverage requirement, or it false-fails on intentionally-deferred scope (FL pre-primary).
- PL/pgSQL `RAISE` treats a literal `%` in the message as a format placeholder — escape `%%` or avoid it (`PROVISIONAL:*`).
- Time-gated work (FL post-primary) is a legitimate **carry-forward at milestone close**, exactly like AZ-LtGov at v2.18 — ship the deliverable, document the carry-forward, don't block the milestone.

### Cost Observations
- Model mix: opus (planner/orchestrator) + sonnet (researchers/executor/verifier/checker).
- Inline-sequential stance research at ≤3 concurrency (premium-tier rate-limit ceiling).
- Notable: the diagnostic-first phase is the cheapest insurance in the program — it converts the two most expensive failure modes into plan-time facts.

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
