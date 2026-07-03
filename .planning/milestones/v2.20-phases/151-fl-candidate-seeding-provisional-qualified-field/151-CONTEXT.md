# Phase 151: FL Candidate Seeding (provisional qualified field) — Context

**Gathered:** 2026-06-29
**Status:** Ready for planning
**Source:** Operator decision at plan-phase (Option A — records-now / stances-at-153) + Phase 148 locked FL field + Phase 149/150 validated pipeline

<domain>
## Phase Boundary

Phase 151 seeds the full **provisional, pre-primary qualified** US House candidate field for all **28 FL districts** (FIPS 12, geo `1201`..`1228`) onto `/elections`, applying the validated Phase 149/150 pipeline. Like TX/NY (not CA), FL has **no `essentials.elections` / `essentials.races` rows yet** — those must be authored first, then `race_candidates` wired on top.

The defining difference from CA/TX/NY: FL's **Aug-18-2026 partisan primary has not happened**. The field is the *qualified* field (qualifying closed → universe final/downloadable), so it is **crowded** — many districts list multiple same-party candidates (FL-19: 14, FL-2: 12, FL-24: 10). Per the locked operator decision, the field is seeded **provisionally** now (so residents get upcoming-vote data) and the partisan losers are pruned after Aug-18 in **Phase 153** (the two-path prune).

In scope (USHC-02/03/04/05 — FL portion, as scoped by D-01 below):
- One `essentials.elections` row: **"FL 2026 Statewide General"**, `election_date='2026-11-03'`, mirroring "CA 2026 Statewide General".
- One `essentials.races` row per district (28), linked to that district's **existing `U.S. Representative` office** (`office_id` = that office; **NEVER `office_id IS NULL`**). **FL-20 (geo 1220) trap:** the seat is currently VACANT and has **no office row** — its U.S. Representative office must be **created first** (mirror a sibling FL office's shape), or its race cannot link.
- `race_candidates` rows for **every qualified candidate** in all 28 districts (each `politician_id`-linked, `candidate_status='active'`; sitting incumbent `is_incumbent=true`). This is field completeness — the provisional field shows every ballot-qualified candidate.
- New `essentials.politicians` records for the **155 genuinely-new** FL candidates (live-DB dedup against existing records, esp. redistricted incumbents who appear cross-district).
- **Stances + headshots are SCOPED by D-01 below** — NOT the full 155.

Out of scope: CA (149), TX/NY (150), the full-144 completion gate (152), and — by the D-01 deferral — full-24 stances + headshots for the **138 partisan (R/D) primary candidates** (those land in Phase 153 once the field narrows to actual nominees).

The source-of-truth field is locked in `148-field-table.csv` (28 FL rows, `field_status=provisional`) + `148-incumbent-map.csv` (FL geo `12NN` → incumbent `politician_id`). Per roadmap success-criterion 1, the candidate universe is **reconciled against the authoritative FL DoE `downloadcanlist.asp` tab-delimited download** (the 148 field was Wikipedia-sourced; the FL DoE list is the official record — research resolves access + any field deltas).
</domain>

<decisions>
## Implementation Decisions

### D-01: Coverage depth for the provisional field = RECORDS-NOW / STANCES-AT-153 [LOCKED — operator, plan-phase Option A]
The 155 new candidates are a **pre-primary** universe; ~138 are partisan (R/D) primary entrants who will be winnowed on Aug-18 and pruned in Phase 153. Investing full-24 stance research + headshots into candidates who lose in 7 weeks is wasted work. Therefore:
- **All 28 districts:** author election + races + `race_candidates` for **every qualified candidate** → the complete provisional field surfaces as cards now (USHC-02/03). This is non-negotiable field completeness.
- **All 155 new candidates:** create `politician_id`-linked records now (dedup-checked). **No headshot, no stance research** for the partisan-primary subset this phase.
- **Incumbents (27 partial-stance):** LEFT AS-IS — none are zero-stance, so by the established zero-only top-up rule (Phase 149/150 D-01, matching NY) they are not topped up here. They already surface with real sourced stances.
- **Independents / No-Party-Affiliation (NPA) new candidates (17):** these **bypass the Aug-18 partisan primary** and are already on the Nov ballot — they are NOT pruned in 153. So they **DO get full-24 chairs-not-polarity stances + headshots NOW** (same pipeline as 149/150 new candidates; honest-skip where thin). The 17 (from `general_candidates` party labels):
  FL-1 Tyler Davis · FL-3 Mike Klein · FL-4 Todd Schaefer · FL-6 Andrew Parrott, Alec Pavlik · FL-12 Branden Scrivener · FL-13 Tony D'Arrigo · FL-16 Mark Davis · FL-17 Michael Quirk · FL-18 Deva Simmons · FL-19 Seth Haskins · FL-20 Kedner MaximeDe · FL-21 Alexander Cooke · FL-24 Andy Daro, Patricia Gonzalez · FL-26 Deborah Ann Meidinger Hosey · FL-28 Eddy Rojas.

Net Phase-151 stance scope = **17 independent/NPA new candidates** (full-24 attempt, honest-skip thin). Phase 153 (post-Aug-18) adds headshots + full-24 stances for the ~28–56 surviving partisan nominees.

**This refines roadmap success-criterion 2** (which read "every newly-seeded FL candidate has a headshot + stances"). The ROADMAP is updated alongside this CONTEXT to record the records-now/stances-at-153 split (151) and the expanded nominee-coverage scope (153).

### D-02: Seed EVERY qualified candidate (incl. multi-same-party + minor lines) [LOCKED — provisional intent]
The provisional field is party-agnostic on the card and must reflect the **true qualified ballot field** — including multiple candidates of the same party in a district (a pre-primary reality, e.g. FL-19's 11 Republicans). Seed every listed qualified candidate as an active `race_candidate`. Do NOT pre-prune, do NOT guess the primary winner, do NOT collapse same-party fields. The race is marked **provisional** (see D-04). Independents/NPA/write-ins are seeded the same way.

### D-03: Dedup = MANDATORY pre-insert live-DB check (cross-district redistricting) [LOCKED — 149/150 invariant]
Before inserting ANY "new" FL record, query the **live DB by name + identity** and reuse the existing `politician_id` if found. FL has cross-district redistricting collisions that are the CA Solis / TX Casar failure-vector:
- **Lois Frankel** — sitting **FL-22** incumbent (redistricted), but appears as a **candidate in FL-23**. Reuse her existing FL-22 `incumbent_pid` for any FL-23 active row; do not create a duplicate.
- **Jared Moskowitz** — sitting **FL-23** incumbent (redistricted), appears as a **candidate in FL-25**. Reuse.
- **Debbie Wasserman Schultz** — sitting **FL-25** incumbent (redistricted), appears as a **candidate in FL-20**. Reuse.
- **Sheila Cherfilus-McCormick** — candidate in FL-20 open seat. **CORRECTION (RESEARCH Q4, live-verified): she has 0 DB records → she is genuinely NEW, NOT a reuse.** Create a new record (do not search-and-fail then skip).
- Reuse targets are exactly **3** (Frankel `-12022`, Moskowitz `-12023`, Wasserman Schultz `-12025`), matched by **exact `external_id`** (NOT name substring — FEC committee-noise rows like "FRANKEL 4 PV SCHOOLS" exist and must not false-match). New-record external_id band = `-12NNXX` (mirrors TX `-48NNXX`; band currently empty).
- Enforce **zero duplicate `full_name`** (FL-scoped) in `151-verify.sql`. The 148 `new_records_needed` used naive name-matching — confirm each reuse target against live DB before insert (148-VERIFICATION caveat). Cross-district incumbents get their active row in the NEW district; their OLD seat's general field is all-new candidates (their incumbent record gets no active row in the old seat).

### D-04: Provisional marking [LOCKED — D-01 success-criterion 3]
The FL field is recorded as **provisional** (mechanism follows established conventions — e.g. `races.notes`/status field or a documented gate convention; planner resolves the exact column against the live `races` schema, mirroring how CA/TX/NY rows are marked `decided`). Multiple same-party candidates per district are present **by design** pre-primary and must NOT trip a dedup/one-D-one-R assertion. Phase 152's gate asserts FL rows are present and marked provisional; Phase 153 re-marks FL `decided` after the prune.

### D-05: race_candidates + stance integrity conventions [INHERITED from 149/150 — project invariants]
- **race_candidates:** non-null `politician_id` (NULL = no stances/photo resolve), `candidate_status='active'`, sitting incumbent flagged `is_incumbent=true`. **NEVER `office_id IS NULL`** on a House race. **NEVER put party on the candidate card** (party reads from `races.primary_party` / race-level, not the card).
- **Retired / redistricted / vacant incumbents (148 flags):** FL-2 Dunn (retired), FL-16 Buchanan (retired), FL-19 Donalds (retired→Gov run), FL-24 Wilson (retired), FL-22 Frankel / FL-23 Moskowitz / FL-25 Wasserman Schultz (redistricted), FL-20 (vacant). A retired/redistricted incumbent keeps its record but gets **no active `race_candidates` row in the seat it left**.
- **Stance integrity (for the 17 independents in scope):** chairs-not-polarity (stance value = exact scale position the evidence supports, never inferred from party); every answer paired to an `inform.politician_context` row with a real fetched source URL; **0 unsourced**; honest-skip (incl. whole-record, pinned by UUID in `151-verify.sql`) where evidence is thin; **mandatory primary-source verification pass before push**; federal-24 topic set. Independents are often thin-sourced → expect many whole-record honest-skips (the 149/150 pattern).

### D-06: Phase structure = ONE phase, planner waves [LOCKED — 149/150 precedent]
Single phase; planner splits into waves. Suggested seam: (W1) author election + 28 races + the FL-20 office + `151-verify.sql` gate; (W2) reconcile + insert 155 records + wire all `race_candidates` (full field); (W3) headshots + full-24 stances for the **17 independents only**; (W4) consolidated gate + FL coordinate smoke. Far lighter than 150's stance waves because only 17 candidates are stanced this phase.

### Claude's Discretion
- Exact wave/batch split; whether the 17-independent stance work is one plan or two (≤3 concurrent researchers per [[feedback-stance-research-one-at-a-time]]).
- FL DoE `downloadcanlist.asp` access mechanics + how to reconcile its tab-delimited field against the 148 Wikipedia-sourced field (researcher resolves); whether to treat 148-field-table.csv as authoritative if the DoE endpoint is fetch-walled (document the source used either way).
- Provisional-marking column choice (D-04) against the live `races` schema.
- FL-20 office creation SQL (mirror sibling FL U.S. Representative office shape).
- Election/race authoring as migration vs script — follow established conventions; mirror "CA 2026 Statewide General".
- Reuse 149/150 assets: `_push_uuid.ts` UUID-keyed insert for NULL-external_id new records; the stance-CSV relax-parse + canonical-restringify repair pipeline + `source_url_1` misalignment guard; `150-verify.sql` + `150-coordinate-smoke.ts` as gate/smoke templates (single-state '12' scope).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 148 source-of-truth artifacts (the locked FL field)
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv` — 28 FL rows (`field_status=provisional`); empty `existing_race_id` (races must be authored). Cols incl. `general_candidates` (party-labeled full qualified field), `new_records_needed` (non-incumbent names), `incumbent_pid`, `incumbent_stance_count`, `nominee_status`.
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-incumbent-map.csv` — FL geo `12NN` → incumbent `politician_id`.
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-VERIFICATION.md` — naive name-match caveat → D-03 mandatory live-DB confirm.

### Phase 149/150 pattern (the validated pipeline this phase reuses)
- `.planning/phases/150-tx-ny-candidate-seeding-create-races-then-candidates/150-CONTEXT.md` — TX/NY create-races-first pattern (FL's direct analog, single-state).
- `backend/scripts/150-verify.sql` — per-state gate template (race_candidates coverage, dedup, 0-unsourced, pinned honest-skips, provisional-field handling) → adapt single-state FL '12'.
- `backend/scripts/150-coordinate-smoke.ts` — ST_Covers surfacing smoke → adapt single-state FL.
- `.planning/phases/149-ca-candidate-seeding-race-candidates-only-turnkey/149-CONTEXT.md` — inherited D-01..05.
- 149 stance-CSV repair pipeline + `_FED24_SCALE.txt` (gitignored scratch; DB is source of truth) — reuse for the 17 independents' stance CSVs.

### Pipeline conventions (STATE.md + project skills)
- `.planning/STATE.md` — race_candidates shape, two-path/seed conventions, inline-sequential ≤3-concurrent-researcher methodology, `_push_uuid.ts` for NULL-external_id records.
- Project skills: `research-stances` / `find-headshots` (read each SKILL.md).
- `backend/src/lib/db` — `pg` pool for read-only diagnostics / verify gates; `electionService.ts` `getElectionsByCoordinate` for the surfacing join.
- Memory: [[project-149-stance-gate-standard]] — USHC-05b accepts honest per-topic skips; hard floor = 0-unsourced + ≥1 sourced OR pinned whole-record skip; never force 24/24 via inference. [[project-150-playwright-stance-method]] — Ballotpedia "Key votes" via Playwright bypasses WebFetch 403 walls.
</canonical_refs>

<infrastructure_verified>
## Live-DB Infrastructure (verified 2026-06-29)
- **28 FL House geofence boundaries** present with geometry → coordinate surfacing will resolve (smoke can pass).
- **28 FL House districts** (geo `1201`..`1228`, `district_type='NATIONAL_LOWER'`).
- **27 FL House offices** — **FL-20 (geo 1220) has 0 offices** (vacant seat); its office must be created in Wave 1 (D-05 trap).
- **0 FL 2026 elections/races** exist → must author (W1).
- **CA 2026 Statewide General** template election present to mirror.
- Field volume: **209 qualified candidates** total; **155 new records** needed; 27 partial-stance incumbents (1 vacant seat, 0 zero-stance); **17 new independent/NPA** candidates in stance scope.
</infrastructure_verified>
