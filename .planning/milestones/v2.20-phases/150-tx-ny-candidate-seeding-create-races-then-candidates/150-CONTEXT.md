# Phase 150: TX + NY Candidate Seeding (create races, then candidates) - Context

**Gathered:** 2026-06-29
**Status:** Ready for planning
**Source:** Operator decisions at discuss-phase (4 locked decisions) + Phase 149 carry-forwards + Phase 148 locked field

<domain>
## Phase Boundary

Phase 150 seeds the full Nov-3, 2026 general candidate field for all **38 TX + 26 NY = 64 US House districts** onto `/elections`, applying the validated Phase 149 (CA) pipeline. The **one structural difference from CA**: TX and NY have **no `essentials.elections` / `essentials.races` rows yet** — those must be **authored first**, then `race_candidates` wired on top. (CA was turnkey: races pre-existed.)

In scope (USHC-02/03/04/05 — TX + NY portion):
- `essentials.elections` row per state ("TX 2026 Statewide General" / "NY 2026 Statewide General", `election_date='2026-11-03'`, mirroring "CA 2026 Statewide General").
- `essentials.races` row per district (one per TX 48NN / NY 36NN geo_id), linked to that district's **existing `U.S. Representative` office** (`office_id` = that office; **NEVER `office_id IS NULL`**).
- `race_candidates` rows on every TX/NY race (each `politician_id`-linked, `candidate_status='active'`, incumbent `is_incumbent=true`).
- New `essentials.politicians` records for the genuinely-new TX (48) + NY (33) = ~81 candidates, with dedup against existing records.
- Headshots for every newly-seeded TX/NY candidate (find-headshots conventions).
- Federal-24-topic chairs-not-polarity evidence-only stances per the top-up decision below (D-01).

Out of scope: CA (Phase 149, done), FL (Phase 151), the full-144 completion gate (Phase 152), FL provisional prune (Phase 153).

The source-of-truth field is locked in `148-field-table.csv` + `148-FIELD-TABLE.md` (TX/NY rows, `field_status=decided`) — Phase 150 consumes it, does not re-derive it. TX/NY rows carry an **empty `existing_race_id`** (vs CA's live UUIDs), which is the explicit signal that races must be authored here.
</domain>

<decisions>
## Implementation Decisions

### D-01: Incumbent stance top-up threshold = ZERO-ONLY [LOCKED — operator]
Consistent with Phase 149 D-01 and the "partial top-up deferred to a later sweep" rationale. Because the stance gap differs by state:
- **TX**: 37 incumbents all at **0** stances → each gets the full federal-24 evidence-only set. (TX-23 is a vacancy — no incumbent record.)
- **NY**: **0 zero / 25 partial (4–21 topics) / 1 done** (AOC at 24). NY partial incumbents are **left as-is this phase** — NOT topped up. They already surface with real, sourced stance content; bringing them to full-24 is deferred to a later sweep.
- **All ~81 genuinely-new TX/NY challengers** get the full federal-24 set regardless.

Net: TX 37 incumbents → full-24; NY 25 partial incumbents → untouched; all 81 new challengers → full-24. (Stance gaps from 148-FIELD-TABLE.md stance-gap summary.)

### D-02: Minor-party / third-line candidates = SEED ALL + honest-skip thin ones [LOCKED — operator]
NY uses fusion voting and a few districts have a genuine third candidate on a minor line — e.g. **NY-13** Bob Cohen (Working Families) alongside D + R; **NY-21** Robert Smullen (Conservative) alongside R + D; **NY-13** also has 3 candidates total. Seed **every listed candidate** as an active `race_candidate` (party-agnostic on the card, per D-05 below). Research stances normally; if a minor candidate has thin/no fetchable primary sources → **documented whole-record honest-skip**, pinned by UUID in `150-verify.sql` (the 149 pattern — 149 had 17 such pinned skips). Do NOT silently drop minor candidates; the card must reflect the true ballot field.

### D-03: TX cross-district / previously-seeded dedup = MANDATORY pre-insert live-DB check [LOCKED — operator]
Before inserting ANY "new" TX/NY record, query the **live DB by name (and identity)** and reuse the existing `politician_id` if found. This is the CA Hilda Solis / Linda Sánchez / Raul Ruiz failure-vector, intensified in TX by **cross-district** redistricting:
- **Greg Casar** — sitting **TX-35** incumbent (redistricted), but is the **active Democratic candidate in TX-37**. Reuse his existing TX-35 `incumbent_pid` for the TX-37 active row; TX-35's incumbent gets NO active row there (its general is Johnny Garcia (D) vs Carlos De La Cruz (R), both new).
- **Colin Allred** — active D in **TX-33**; likely has an existing record from his 2024 Senate run. Confirm + reuse, don't create.
- Verify every TX redistricted incumbent (TX-9 Al Green, TX-30 Crockett, TX-32 Julie Johnson, TX-33 Veasey, TX-35 Casar) and any previously-seeded figure isn't double-created.
- Enforce **zero duplicate `full_name` per state** in `150-verify.sql`. The 148 `new_records_needed` column used naive name-matching — confirm each reuse target against live DB before insert (148-VERIFICATION caveat).

### D-04: Phase structure = ONE phase, planner waves [LOCKED — operator]
Keep 150 as a single phase; the planner splits into waves (suggested seam: election/race authoring → records + race-wiring → headshots + stances; TX and NY as parallel tracks since they're fully independent — different elections, different incumbent gaps). Matches 149 precedent. Planner MAY still recommend a TX-vs-NY split if it exceeds the context budget.

### D-05: race_candidates + stance integrity conventions [INHERITED from 149 — project invariants]
- **race_candidates (D-03/149)**: non-null `politician_id` (NULL = no stances/photo resolve), `candidate_status='active'`, incumbent flagged `is_incumbent=true`. **NEVER `office_id IS NULL`** on a House race — the race carries the district's existing U.S. Representative office. **NEVER put party on the candidate card** (party reads from `races.primary_party`).
- **Lost-incumbent / non-nominee flags (148)**: the defeated/retired/redistricted incumbent keeps its record but gets **NO active race_candidates row**, and the primary WINNER is the active candidate. TX/NY flagged cases: **TX-2** (Crenshaw lost → Steve Toth active), **NY-10** (Goldman lost → Brad Lander active), **NY-13** (Espaillat lost → Darializa Avila Chevalier active); retirements NY-7/NY-12/TX-8/TX-10/TX-19/TX-21/TX-37/TX-38/NY-21; redistricted TX-9/30/32/33/35; open-seat **TX-23** (all candidates new).
- **Multi-candidate generals recorded party-agnostically (D-04/149)**: seed every advancer/listed candidate; do not assume one-D-one-R; do not drop the second/third candidate.
- **Stance integrity (D-05/149, project rule)**: chairs-not-polarity (stance value = exact scale position the evidence supports, never inferred from party); every answer paired to an `inform.politician_context` row with a real fetched source URL; **0 unsourced**; honest-skip (incl. whole-record) where evidence is thin; **mandatory primary-source verification pass before push** (agents over-read / fabricate specifics even when citing URLs); federal-24 topic set (24 federal-tier topics incl. social-security/tariffs/ukraine, minus the 5 state-only).

### Claude's Discretion
- Wave/batch structure across TX (38) + NY (26) districts; TX/NY parallel tracks; whether headshots + stances are separate waves from records + race-wiring or interleaved (D-04).
- Whether to recommend a TX-vs-NY split if context budget is exceeded (operator open to it).
- Exact push-script mechanics — UUID-keyed `_push_uuid.ts` for NULL-external_id new records vs external_id push; reuse the 149 malformed-CSV repair pipeline (relax-parse + canonical-restringify + `source_url_1` misalignment guard) for stance-researcher CSV output.
- Election/race authoring SQL mechanics (migration file vs script) — follow established conventions; mirror "CA 2026 Statewide General" shape.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 148 source-of-truth artifacts (the locked TX/NY field)
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv` — per-district field (13-col); TX/NY rows have **empty `existing_race_id`** (races must be authored). Columns: state, cd, geo_id, target_election, existing_race_id, incumbent_name, incumbent_pid, incumbent_external_id, incumbent_stance_count, incumbent_top_up_tier, nominee_status, general_candidates, new_records_needed, field_status, source_url.
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md` — narrative + full per-district table + non-incumbent-nominee flag list (lost/retired/redistricted/open) + per-state stance-gap summary (TX 37 zero; NY 0 zero/25 partial/1 done).
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-incumbent-map.csv` — DB incumbent→politician_id map (join key geo_id; TX 48NN / NY 36NN).
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-VERIFICATION.md` — flagged follow-ups (naive name-match caveat for new_records_needed → D-03 mandatory live-DB confirm).

### Phase 149 pattern (the validated pipeline this phase reuses)
- `.planning/phases/149-ca-candidate-seeding-race-candidates-only-turnkey/149-CONTEXT.md` — locked CA decisions D-01..05 inherited here.
- `.planning/phases/149-ca-candidate-seeding-race-candidates-only-turnkey/149-verify.sql` — the verify-gate template (race_candidates coverage, dedup, 0-unsourced, pinned honest-skips) to adapt for TX/NY.
- Phase 149 stance-CSV repair pipeline + `_FED24_SCALE.txt` + repair/validate/finalize `.mjs` scratch (gitignored; DB is source of truth) — reuse for malformed stance-researcher CSVs.

### Pipeline conventions (STATE.md + project skills)
- `.planning/STATE.md` — race_candidates shape, two-path/seed conventions, inline-sequential ≤3-concurrent-researcher methodology, `_push_uuid.ts` for NULL-external_id records.
- Project skills: `research-stances` / `find-headshots` (read each SKILL.md) — established stance + headshot pipelines.
- `backend/src/lib/db` — `pg` pool for read-only diagnostics / verify gates.
- Memory: [[project-149-stance-gate-standard]] — USHC-05b accepts honest per-topic skips; hard floor = 0-unsourced + ≥1 sourced OR pinned whole-record skip; never force 24/24 via inference.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 149 push scripts (`_push_uuid.ts` UUID-keyed insert for NULL-external_id records) — TX/NY new records also have NULL external_id, so reuse the UUID-keyed path.
- 149 stance-CSV relax-parse + canonical-restringify repair pipeline — stance-researcher agents emit malformed CSVs (trailing-comma 11-col, quadruple-`""""` quotes, unquoted-reasoning-with-commas); reuse the repair/validate/finalize scripts + `source_url_1` misalignment guard.
- `essentials.elections` / `essentials.races` schema — mirror the existing "CA 2026 Statewide General" rows (id prefix `728d0074-…`) for shape when authoring TX/NY.

### Established Patterns
- TX/NY US Representative offices already exist (geo_id 48NN / 36NN) — races link to those office_ids; never create offices, never `office_id IS NULL`.
- `races.primary_party` carries party; candidate cards are party-free (D-05).
- Verify-gate pins honest-skips by UUID (149 had 17) — adapt for TX/NY thin minor candidates.

### Integration Points
- `/elections` feed surfaces races via `essentials.races` + `essentials.race_candidates` (NOT Path-A offices) — coordinate smoke-test (149-coordinate-smoke.ts pattern) confirms in-district coordinates surface the full field; reused in Phase 152 gate.
</code_context>

<specifics>
## Specific Ideas

- target_election names already set in CSV: "TX 2026 Statewide General" / "NY 2026 Statewide General"; election_date `2026-11-03`.
- New-record counts per 148: TX = 48, NY = 33 (~81 total) — but naive-matched; D-03 mandatory live-DB confirm may reduce these (Casar/Allred reuse).
- TX is all-zero-incumbent (like CA); NY is all-partial-incumbent (unlike CA) — drives the D-01 asymmetry.
- NY fusion/minor lines: NY-13 (Working Families), NY-21 (Conservative) — seed all (D-02).
- Lost-primary actives: TX-2 Steve Toth, NY-10 Brad Lander, NY-13 Darializa Avila Chevalier (D-05).
</specifics>

<deferred>
## Deferred Ideas

- Top-up of the 25 NY partial incumbents (4–23 topics) to full federal-24 — deferred to a later sweep (D-01). Same deferral as CA's 7 partials.
- FL seeding (Phase 151), 144-completion coordinate gate (Phase 152), FL provisional prune post-Aug-18 primary (Phase 153).

### Reviewed Todos (not folded)
None — discussion stayed within phase scope.
</deferred>

---

*Phase: 150-tx-ny-candidate-seeding-create-races-then-candidates*
*Context gathered: 2026-06-29 via discuss-phase operator decisions (4 locked) + 149/148 carry-forwards*
