# Phase 155: PA + IL Candidate Seeding (create elections + races, then candidates) - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning
**Source:** Operator decision at plan-phase (auto-generate from Phase 150 locked decisions D-01..D-05 + Phase 154 PA/IL field findings) — no new operator decisions open; all decisions inherited 1:1 from the v2.20 TX/NY pattern.

<domain>
## Phase Boundary

Phase 155 seeds the full Nov-3, 2026 general candidate field for all **17 PA + 17 IL = 34 US House districts** onto `/elections`, applying the validated Phase 149/150 pipeline. PA and IL are the **anchor** seeding phase of v2.21 Wave 2 — the per-state pipeline established here is continued by Phase 156 (OH+GA+NC), Phase 157 (NJ), and the date-gated Phase 159 (MI+VA).

The **structural shape is identical to Phase 150 (TX/NY), not Phase 149 (CA)**: PA and IL have **no `essentials.elections` / `essentials.races` rows yet** — those must be **authored first**, then `race_candidates` wired on top. (CA was turnkey: races pre-existed. PA/IL `existing_race_id` is BLANK for all 34 rows, the explicit signal that races are authored here.)

In scope (USHC2-02/03/04/05 — PA + IL portion):
- `essentials.elections` row per state ("PA 2026 Statewide General" / "IL 2026 Statewide General", `election_date='2026-11-03'`, mirroring "CA/TX/NY 2026 Statewide General").
- `essentials.races` row per district (one per PA 42NN / IL 17NN geo_id), linked to that district's **existing U.S. Representative office** (`office_id` = that office; **NEVER `office_id IS NULL`**).
- `race_candidates` rows on every PA/IL race (each `politician_id`-linked, `candidate_status='active'`, incumbent `is_incumbent=true`).
- New `essentials.politicians` records for the genuinely-new PA (~20) + IL (~28) = ~48 candidates, with mandatory live-DB dedup against existing records.
- Headshots for every newly-seeded PA/IL candidate (find-headshots conventions).
- Federal-24-topic chairs-not-polarity evidence-only stances for every newly-seeded candidate (D-01 below).

Out of scope: OH/GA/NC (Phase 156), NJ (Phase 157), MI+VA (date-gated Phase 159, Aug-4 primary), the full 113-district completion gate (Phase 158), all already-stanced PA/IL incumbents (left as-is, D-01), backend/frontend code (pure-data surfacing, Path B).

The source-of-truth field is locked in `154-field-table.csv` + `154-FIELD-TABLE.md` (PA/IL rows, `field_status=decided`) — Phase 155 consumes it, does not re-derive it.
</domain>

<decisions>
## Implementation Decisions

### D-01: Incumbent stance top-up = NONE this phase; all-new-challengers get full-24 [LOCKED — inherited 150 D-01 + 154 finding]
Per Phase 154's stance-gap diagnostic, **every PA and IL incumbent is PARTIAL** (PA range 11–20 of federal-24; IL range 8–22; none at 0, none at full 24). Per the project stance-gate standard, **partial incumbents are NOT topped up** — they already surface real, sourced stance content; bringing them to full-24 is deferred to a later sweep. This mirrors NY in Phase 150 (all-partial → untouched), NOT TX (all-zero → full set). PA/IL have **no zero-stance incumbents** (the only Wave-2 zero-stance incumbent is NC-6 McDowell → Phase 156).

Net: PA incumbents (17) → untouched; IL incumbents (16; IL-9 Schakowsky retired) → untouched; **all ~48 genuinely-new PA/IL challengers + open-seat candidates → full federal-24 evidence-only set.**

### D-02: Minor-party / third-line candidates = SEED ALL + honest-skip thin ones [LOCKED — inherited 150 D-02]
Seed **every ballot-qualified Nov-3 general candidate** as an active `race_candidate` (party-agnostic on the card, per D-05). Several PA/IL districts have a third (Libertarian/Green/independent) candidate and several open-seat districts have multi-candidate fields. Research stances normally; if a minor candidate has thin/no fetchable primary sources → **documented whole-record honest-skip**, pinned by UUID in `155-verify.sql` (the 149/150 pattern). Do NOT silently drop minor candidates; the card must reflect the true ballot field.

### D-03: Mandatory pre-insert live-DB dedup + certified-general re-confirm [LOCKED — inherited 150 D-03, sharpened for IL primaries]
Before inserting ANY "new" PA/IL record, query the **live DB by name (and identity)** and reuse the existing `politician_id` if found (the CA Solis/Sánchez/Ruiz and TX Casar/Allred failure-vector). Enforce **zero duplicate `full_name` per state** in `155-verify.sql`.

**Sharpened for IL:** the 154 field table's `general_candidates`/`new_records_needed` column for hot open-seat retirements lists the **primary field, not the certified general nominee** — e.g. **IL-4 lists 7 names** (Patty Garcia; Lupe Castillo; Ed Hershey; Chris Getty; Mayra Macias; Byron Sigcho-Lopez; Lindsay Church) and **IL-2 lists 3** (Donna Miller; Michael Noack; Ashley Banks). The seeding phase MUST **re-confirm the certified Nov-3 general nominees per district from the IL/PA Secretary of State certified ballot list** before inserting, and seed only ballot-qualified general candidates (D-02 inclusion bar). Do not seed the entire primary field.

### D-04: Lost / retired / open-seat incumbent handling [LOCKED — inherited 150 D-05 lost-incumbent rule + 154 flags]
The defeated/retired incumbent keeps its existing `politician_id` (still in office through Jan 2027) but gets **NO active `race_candidates` row**; the certified general nominee(s) are the active candidates. PA/IL flagged non-incumbent-nominee districts (154-FIELD-TABLE.md):
- **PA-3** — Dwight Evans retired → Chris Rabb (D) nominee.
- **IL-2** — Robin Kelly ran for Senate → Donna Miller (D) nominee (re-confirm general field).
- **IL-4** — Chuy García retired → certified D nominee (re-confirm; 7-name primary field listed).
- **IL-7** — Danny Davis retired → La Shawn Ford (D); Chad Koppie (R).
- **IL-8** — Raja Krishnamoorthi ran for Senate → Melissa Bean (D); Jennifer Davis (R).
- **IL-9** — Jan Schakowsky retired → Daniel Biss (D); John Elleson (R).

All other PA/IL districts are `renominated` — the sitting incumbent reuses its existing `politician_id` (mapped in `154-incumbent-map.csv`) as the active `is_incumbent=true` candidate, and the challenger(s) are the new records.

### D-05: Phase structure = ONE phase, planner waves [LOCKED — inherited 150 D-04]
Keep 155 as a single phase; the planner splits into waves. Suggested seam (mirrors 150's 12-plan / 4-wave shape): **Wave 1** election/race authoring (PA + IL) + write-free verify-gate authoring; **Wave 2** records + race-wiring (PA and IL as parallel tracks — fully independent: different elections, different fields); **Wave 3** headshots + stances (batched per state); **Wave 4** consolidated `155-verify.sql` run. PA and IL are parallel tracks throughout. Planner MAY recommend a PA-vs-IL split if it exceeds the context budget.

### D-06: race_candidates + stance integrity conventions [INHERITED — project invariants]
- **race_candidates**: non-null `politician_id` (NULL = no stances/photo resolve), `candidate_status='active'`, incumbent flagged `is_incumbent=true`. **NEVER `office_id IS NULL`** on a House race — the race carries the district's existing U.S. Representative office. **NEVER put party on the candidate card** (party reads from `races.primary_party`).
- **Stance integrity**: chairs-not-polarity (stance value = exact scale position the evidence supports, never inferred from party); every answer paired to an `inform.politician_context` row with a real fetched source URL; **0 unsourced**; honest-skip (incl. whole-record) where evidence is thin; **mandatory primary-source verification pass before push** (agents over-read / fabricate specifics even when citing URLs); federal-24 topic set (24 federal-tier topics, minus the 5 state-only). Wipe `essentials.quotes` per pid before re-push on any quote correction.
- **external_id scheme for new challengers**: `-(state_fips * 10000 + cd * 100 + seq)` — **PA fips=42, IL fips=17**. Verify 0 collisions per state against live IDs before authoring.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 154 source-of-truth artifacts (the locked PA/IL field)
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — per-district field (15-col); PA/IL rows have **empty `existing_race_id`** (races must be authored). Columns: state, cd, geo_id, target_election, existing_race_id, incumbent_name, incumbent_pid, incumbent_external_id, incumbent_stance_count, incumbent_top_up_tier, nominee_status, general_candidates, new_records_needed, field_status, source_url. **CSV caveat:** quote-escaping artifacts exist (PA-8 "Robert P. Bresnahan, Jr." comma shifts columns; IL-4 "Chuy" double-quotes) — reuse the 149/150 relax-parse repair pipeline; do not trust raw column splits on those rows.
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-FIELD-TABLE.md` — narrative + non-incumbent-nominee flag list + per-state stance-gap summary (PA/IL all-partial) + new-record counts (PA 20 / IL 28).
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv` — DB incumbent→politician_id map (join key geo_id; PA 42NN / IL 17NN) — the reuse source for renominated incumbents.

### Phase 150 pattern (the validated create-races-first pipeline this phase reuses)
- `.planning/phases/150-tx-ny-candidate-seeding-create-races-then-candidates/150-CONTEXT.md` — locked TX/NY decisions D-01..05 inherited here.
- `.planning/phases/150-tx-ny-candidate-seeding-create-races-then-candidates/150-01-PLAN.md` — elections+races authoring plan (mirror for PA/IL).
- `.planning/phases/150-tx-ny-candidate-seeding-create-races-then-candidates/150-12-PLAN.md` + the 150 verify SQL — the verify-gate template (race_candidates coverage, dedup, 0-unsourced, pinned honest-skips) to adapt per-state for PA/IL.

### Phase 149 pattern (turnkey predecessor + stance gate)
- `.planning/phases/149-ca-candidate-seeding-race-candidates-only-turnkey/149-verify.sql` — original verify-gate template.
- Memory: [[project-149-stance-gate-standard]] — USHC2-05 accepts honest per-topic skips; hard floor = 0-unsourced + ≥1 sourced OR pinned whole-record skip; never force 24/24 via inference.

### Pipeline conventions (STATE.md + project skills)
- `.planning/STATE.md` — "v2.21 Execution Methodology" section: production project ref `kxsdzaojfaibhuzmclfq`, race_candidates shape, create-races-first pattern, external_id scheme, stance pipeline (`_TOPIC_SCALE_FULL.txt`, `politician-stance-researcher` @ 3-concurrency, `_merge.ts` → `_push_uuid.ts`/`_push.ts`), fetch-walls (Ballotpedia/Wikipedia → Playwright/raw-wikitext), finance out-of-scope.
- Project skills: `research-stances` / `find-headshots` (read each SKILL.md).
- `backend/src/lib/db` — `pg` pool for read-only diagnostics / verify gates. Scripts run from `backend/` with `set -a && source .env && set +a`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 150 push scripts (`_push_uuid.ts` UUID-keyed insert for NULL-external_id records) — PA/IL new records also have NULL external_id → reuse the UUID-keyed path; existing-incumbent reuse needs no insert.
- 149/150 stance-CSV relax-parse + canonical-restringify repair pipeline + `source_url_1` misalignment guard — stance-researcher agents emit malformed CSVs; reuse.
- `essentials.elections` / `essentials.races` schema — mirror the existing "CA/TX/NY 2026 Statewide General" rows for shape when authoring PA/IL.

### Established Patterns
- PA/IL US Representative offices already exist (geo_id 42NN / 17NN) — races link to those office_ids; never create offices, never `office_id IS NULL`.
- `races.primary_party` carries party; candidate cards are party-free (D-06).
- Verify-gate pins honest-skips by UUID (149 had 17; 150 reused) — adapt for PA/IL thin minor candidates.

### Integration Points
- `/elections` feed surfaces races via `essentials.races` + `essentials.race_candidates` (NOT Path-A offices); reps feed filters `is_incumbent=true` (excludes challengers) — challengers ONLY surface via the elections feed. Coordinate smoke-test confirms in-district coordinates surface the full field; reused in the Phase 158 gate.
</code_context>

<specifics>
## Specific Ideas

- target_election names to author: "PA 2026 Statewide General" / "IL 2026 Statewide General"; election_date `2026-11-03`.
- New-record counts per 154: PA = 20, IL = 28 (~48 total) — naive-matched; D-03 mandatory live-DB confirm + certified-general re-confirm may change these.
- Both PA and IL are all-partial-incumbent (like NY) → drives the D-01 "no top-up" for incumbents.
- Renominated incumbents (reuse `incumbent_pid`): PA — all 17 except PA-3; IL — all except IL-2/4/7/8/9 (5 retirements/Senate runs). PA-8 incumbent Bresnahan IS renominated (CSV comma artifact); challenger Paige Cognetti (D) is the new record.
- Lost/retired/open actives to seed (re-confirm certified general): PA-3 Chris Rabb; IL-2 Donna Miller; IL-4 (re-confirm D nominee); IL-7 La Shawn Ford; IL-8 Melissa Bean; IL-9 Daniel Biss.
- State FIPS for external_id: PA=42, IL=17.
</specifics>

<deferred>
## Deferred Ideas

- Top-up of PA/IL partial incumbents to full federal-24 — deferred to a later sweep (D-01).
- Challenger FEC `finance_summary` — out of scope (v2.22+); record no-FEC-ID rather than retry.
- OH/GA/NC seeding (Phase 156), NJ (Phase 157), MI+VA (Phase 159), 113-completion gate (Phase 158).

### Reviewed Todos (not folded)
None — phase scope inherited cleanly from 150.

</deferred>

---

*Phase: 155-pa-il-candidate-seeding-create-elections-races-then-candidat*
*Context gathered: 2026-06-30 via plan-phase auto-generate (Phase 150 locked decisions + Phase 154 PA/IL field findings)*
