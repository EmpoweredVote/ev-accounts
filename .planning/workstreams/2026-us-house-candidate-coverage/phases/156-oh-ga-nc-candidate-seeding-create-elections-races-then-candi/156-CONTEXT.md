# Phase 156: OH + GA + NC Candidate Seeding (create elections + races, then candidates) - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning
**Source:** Auto-generated from Phase 155 anchor decisions (D-01..D-06) + Phase 154 OH/GA/NC field findings — inherited pipeline; new decisions only where OH/GA/NC differ from PA/IL (NC-6 zero-stance incumbent, GA vacancy/open seats, heavier third-party field).

<domain>
## Phase Boundary

Phase 156 seeds the full Nov-3, 2026 general candidate field for all **15 OH + 14 GA + 14 NC = 43 US House districts** onto `/elections`, applying the Phase 155-validated create-races-first pipeline. Independent of Phase 155 (disjoint states) but sequenced after it to inherit the proven pipeline (`_push_relaxed.ts`, `_fed24-scale-block.txt`, the 155-verify.sql gate shape).

Structural shape = Phase 150/155 (TX/NY/PA/IL), NOT CA turnkey: OH, GA, NC have **no `essentials.elections`/`races` rows yet** — author them first, then wire `race_candidates`. All 43 rows in `154-field-table.csv` carry BLANK `existing_race_id`.

In scope (USHC2-02/03/04/05 — OH/GA/NC portion):
- `essentials.elections` per state ("OH/GA/NC 2026 Statewide General", `election_date='2026-11-03'`).
- `essentials.races` per district (OH 39NN / GA 13NN / NC 37NN) on the district's existing U.S. Representative office (`office_id` NEVER NULL).
- `race_candidates` on every race (`politician_id`-linked, `candidate_status='active'`, incumbent `is_incumbent=true`).
- New `essentials.politicians` for the genuinely-new candidates (~OH 19 / GA 18 / NC 25 = ~62; naive, D-03 dedup confirms).
- Headshots for every new candidate (find-headshots conventions; expect mostly honest-skips per 155 precedent).
- Federal-24 chairs-not-polarity stances for every new candidate **plus NC-6 McDowell** (see D-01).

Out of scope: PA/IL (Phase 155, done), NJ (Phase 157), MI+VA (Phase 159), the 113-district gate (Phase 158), all already-stanced (partial) OH/GA/NC incumbents.

Source-of-truth field: `154-field-table.csv` + `154-FIELD-TABLE.md` (OH/GA/NC rows, `field_status=decided`). Consumed, not re-derived.
</domain>

<decisions>
## Implementation Decisions

### D-01: Incumbent stance scope — partial untouched; the ONE zero-stance incumbent (NC-6 McDowell) IS in scope [LOCKED — 155 D-01 + 154 finding]
Per Phase 154's diagnostic, every OH/GA/NC incumbent is PARTIAL (stance counts 1–20) and **left as-is** (not topped up) — EXCEPT **NC-6 Addison P. McDowell (external_id-mapped incumbent, stance_count = 0)**, the only zero-stance incumbent in all of Wave 2. Per the zero-stance-gets-full-set rule (TX in Phase 150), **McDowell is IN the stance in-scope set** and gets the full federal-24 research as an existing record (push by his existing pid/external_id, `_push.ts` path, NOT `_push_uuid.ts`). All other OH/GA/NC incumbents are untouched.

Net: OH 15 incumbents untouched; GA 10 renominated incumbents untouched (GA-14 Fuller sc=1 = partial, untouched); NC 13 incumbents untouched + **NC-6 McDowell → full-24**; all ~62 new challengers/open-seat nominees → full-24.

### D-02: Third-party / minor-line candidates = SEED ALL + honest-skip thin ones [LOCKED — 155 D-02]
OH/NC have a heavy third-party field (Libertarians in OH-1/9/15 and NC-1/2/3/4/5/7/10/11/13; a Green in NC-13; Independents in OH-4 Tamie Wilson and NC-11 John Rogers). Seed EVERY ballot-qualified Nov-3 general candidate as an active `race_candidate` (party-agnostic card). Research stances normally; thin/no-source minor candidates → whole-record honest-skip, pinned by UUID in `156-verify.sql`. Do NOT drop minor candidates.

### D-03: Mandatory pre-insert live-DB dedup + certified-general re-confirm [LOCKED — 155 D-03]
Query live DB by name before any insert; reuse existing `politician_id` if found; enforce 0 duplicate `full_name` per state. GA open-seat nominees especially need certified-general re-confirm from the GA Secretary of State certified list (GA-1/10/11 open; GA-13 vacancy). NC/OH primaries held → renominated fields reliable. NOTE the potential dedup targets: some GA/NC/OH nominees may be sitting state legislators/officials with existing records (e.g. GA-13 Jasmine Clark is a GA state rep; GA-1 Amanda Hollowell; NC nominees) — live-confirm each.

### D-04: Lost / retired / open / vacancy handling [LOCKED — 155 D-04, extended for GA vacancy]
The sitting incumbent who is NOT the 2026 nominee keeps its `politician_id` but gets **NO active `race_candidates` row**; the certified nominee(s) are active. OH/GA/NC flagged districts (154-FIELD-TABLE.md):
- **GA-1** — Buddy Carter (ran for Senate) → Jim Kingston (R) / Amanda Hollowell (D).
- **GA-10** — Mike Collins (ran for Senate) → Houston Gaines (R) / Pamela DeLancy (D).
- **GA-11** — Barry Loudermilk (retired) → John Cowan (R) / Chris Harden (D).
- **GA-13** — **TRUE VACANCY** (David Scott died Apr 2026; incumbent = VACANT, NO politician_id). Nominees Jasmine Clark (D) / Jonathan Chavez (R) are both new records. **No incumbent-absent pin** (there is no incumbent pid); **do NOT create a ghost incumbent/office row** — verify the GA-13 NATIONAL_LOWER office exists (like the FL-20 vacancy in mig 1115, the office may need creating BEFORE its race if absent — plan-time live check).
- All other OH/GA/NC districts are `renominated`: reuse the incumbent_pid from `154-incumbent-map.csv` as the active `is_incumbent=true` candidate. (GA-14 Clay Fuller + others already seeded as incumbents — reuse, do not duplicate.)

### D-05: Phase structure = ONE phase, planner waves [LOCKED — 155 D-05]
Single phase; planner splits into waves. Suggested seam (mirror 155's 9-plan shape, extended to 3 states): W1 election/race authoring (OH+GA+NC, incl. GA-13 office check) + write-free `156-verify.sql`; W2 records+wiring (OH, GA, NC parallel tracks); W3 headshots + stances (per state; McDowell in NC stance batch); W4 consolidated gate + coordinate smoke. Planner MAY split by state if context budget requires.

### D-06: race_candidates + stance integrity conventions [INHERITED — project invariants]
- **race_candidates**: non-null `politician_id`, `candidate_status='active'`, incumbent `is_incumbent=true`. NEVER `office_id IS NULL`; NEVER party on the card (party via `races.primary_party`, kept NULL for multi-candidate generals).
- **Stance integrity**: chairs-not-polarity; every answer paired to `inform.politician_context` with a real fetched source URL; **0 unsourced**; honest-skip (per-topic or whole-record) where thin; **primary-source verification pass before push** (agent self-audit + 0-unsourced push filter + chairs-not-polarity framing, per 155). Wipe `essentials.quotes` per pid before re-push on quote correction.
- **external_id for new challengers**: `-(state_fips*10000 + cd*100 + seq)` — **OH fips=39, GA=13, NC=37**. Verify 0 collisions per state before insert. New records → `_push_uuid.ts`; existing-record reuse (incl. NC-6 McDowell stances) → `_push.ts`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 154 source-of-truth (the locked OH/GA/NC field)
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — per-district field; OH/GA/NC rows have empty `existing_race_id`. CSV quote-escaping artifacts possible on names with commas/quotes (relax-parse).
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-FIELD-TABLE.md` — non-incumbent-nominee flags (GA-1/10/11/13) + stance-gap (NC-6 McDowell = only zero) + new-record counts (OH 19 / GA 18 / NC 25).
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv` — geo_id → incumbent_pid + external_id (OH 39NN / GA 13NN / NC 37NN); reuse source + McDowell's pid/external_id.

### Phase 155 pattern (the just-validated pipeline this phase repeats)
- `.planning/phases/155-pa-il-candidate-seeding-create-elections-races-then-candidat/155-CONTEXT.md` — the PA/IL decisions this mirrors.
- `.planning/phases/155-.../155-01-PLAN.md` (elections+races authoring), `155-03/04-PLAN.md` (records+wiring), `155-09-PLAN.md` (gate+smoke) — adapt for OH/GA/NC.
- `backend/migrations/1117_seed_pa_il_2026_house_elections_races.sql` (races scaffold precedent), `1118`/`1119` (candidate seed precedent), `1115` (FL-20 **vacancy office-creation** precedent for GA-13).
- `backend/scripts/155-verify.sql` (gate template — adapt: 3 states, geo prefixes 39/13/37; **include NC-6 McDowell in the stance in-scope set**; GA-13 has no incumbent-absent pin), `155-coordinate-smoke.ts` (smoke template).
- `backend/scripts/seed-pa-il-house-headshots.py` (parameterize `--state OH|GA|NC` with bands), `backend/data/stance-research/_push_relaxed.ts` (robust stance push), `_fed24-scale-block.txt` (24 topic scales).

### Conventions
- `.planning/STATE.md` "v2.21 Execution Methodology" (prod ref `kxsdzaojfaibhuzmclfq`, create-races-first, external_id scheme, stance pipeline, fetch-walls). Scripts run from `backend/` with `set -a && source .env && set +a`.
- Memory: [[project-149-stance-gate-standard]] (0-unsourced + ≥1-sourced-or-pinned-skip), [[project_phase155_planned]] (the executed 155 run + traps: session-limit re-dispatch, cwd resets, malformed-CSV repair).
</canonical_refs>

<specifics>
## Specific Ideas
- Election names: "OH/GA/NC 2026 Statewide General", date 2026-11-03. State FIPS: OH=39, GA=13, NC=37.
- New-record counts (naive, 154): OH 19 / GA 18 / NC 25 (~62). D-03 dedup + certified-general re-confirm may adjust.
- **NC-6 McDowell**: the sole zero-stance incumbent → full-24 research, push by existing external_id (`_push.ts`), reused as active is_incumbent=true.
- **GA-13**: true vacancy — Clark/Chavez both new; verify GA-13 office exists (create like FL-20 if absent); no incumbent-absent pin.
- GA open/retired absents: GA-1 Carter, GA-10 Collins, GA-11 Loudermilk (reuse pids kept, no active row).
- Third-party seed-all: OH-1/9/15 (Libertarian), OH-4 (Independent), NC-1/2/3/4/5/7/10/11/13 (Libertarian), NC-13 (Green), NC-11 (Independent).
- GA-13 Jasmine Clark (GA state rep) + other nominees may have existing records → dedup live.
</specifics>

<deferred>
## Deferred Ideas
- Top-up of partial OH/GA/NC incumbents to full-24 — deferred (D-01).
- Challenger FEC finance — out of scope (v2.22+).
- NJ (Phase 157), MI+VA (Phase 159), 113-completion gate (Phase 158).

### Reviewed Todos (not folded)
None — scope inherited cleanly from 155.
</deferred>

---

*Phase: 156-oh-ga-nc-candidate-seeding-create-elections-races-then-candi*
*Context gathered: 2026-06-30 via plan-phase auto-generate (155 anchor decisions + 154 OH/GA/NC field)*
