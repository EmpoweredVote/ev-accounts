# Phase 149: CA Candidate Seeding (race_candidates only — turnkey) - Context

**Gathered:** 2026-06-28
**Status:** Ready for planning
**Source:** Operator decisions at plan-phase (2 locked decisions) + Phase 148 carry-forwards

<domain>
## Phase Boundary

Phase 149 is the **anchor** of the 3-phase CA/TX/NY/FL seeding pipeline. It seeds the full Nov-3 general field for all 52 CA US House districts onto the **existing** pre-seeded races in the "CA 2026 Statewide General" election (id prefix `728d0074-…`) — CA is turnkey because its `elections` + `races` rows already exist (0 race_candidates). Phases 150 (TX+NY) and 151 (FL) reuse the exact pattern established here but must author `elections`/`races` first.

In scope (USHC-02/03/04/05, CA only):
- `race_candidates` rows on the 52 existing CA races (each `politician_id`-linked, `candidate_status='active'`, incumbent `is_incumbent=true`)
- New `essentials.politicians` records for the 38 genuinely-new CA candidates (challengers + open-seat), with dedup against existing records
- Headshots for every newly-seeded CA candidate (find-headshots conventions)
- Federal-24-topic chairs-not-polarity evidence-only stances for every CA candidate lacking them (see top-up decision below)

Out of scope: TX/NY/FL (Phases 150/151), the full-144 completion gate (Phase 152), FL provisional prune (Phase 153).

The source-of-truth field is already locked in `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv` + `148-FIELD-TABLE.md` — Phase 149 consumes it, does not re-derive it.
</domain>

<decisions>
## Implementation Decisions

### D-01: Incumbent stance top-up threshold = ZERO-ONLY [LOCKED]
Seed federal-24 stances ONLY for the **36 CA incumbents currently at 0 stances**. The **7 partial CA incumbents (1–23 topics) are left as-is** in this phase — they are NOT topped up to 24 here. The 9 already-done CA incumbents (≥24) are skipped via the stance-gap diagnostic. All **38 genuinely-new CA candidates** (challengers + open-seat) get the full federal-24 evidence-only set regardless. Rationale: gets every CA incumbent onto the board at lowest cost; partial top-up deferred to a later sweep. (CA stance gap from 148-01: 36 zero / 7 partial / 9 done.)

### D-02: Record reuse + dedup [LOCKED — USHC-02]
Incumbent-nominees and previously-seeded figures REUSE their existing `incumbent_pid` (from 148-incumbent-map.csv) — NEVER INSERT a new politician row for a sitting rep (the v2.4 two-Andy-Barrs / mig-1074 failure vector). Only the 38 names in `new_records_needed` get new `essentials.politicians` rows. Zero duplicate `full_name` within CA after seeding. **Known dedup target carried from Phase 148 verification: duplicate "Raul Ruiz" records in CA-25 (both 0 stances) — resolve before/at seeding.** Party normalized to canonical form (Democratic, not Democrat).

### D-03: race_candidates conventions [LOCKED — project invariant]
Every `race_candidates` row: non-null `politician_id` (NULL = no stances/photo will resolve), `candidate_status='active'`, incumbent flagged `is_incumbent=true`. NEVER `office_id IS NULL` on a House race (statewide-general convention — the race carries the district's existing U.S. Representative office). NEVER put party on the candidate card (party reads from `races.primary_party`). existing_race_id per CA district is the live UUID in 148-field-table.csv (re-query/confirm against the live DB at execution; do not trust a stale copy if the table drifted).

### D-04: Same-party (top-two) generals recorded party-agnostically [LOCKED]
CA has 8 D-vs-D + 1 R-vs-R same-party general districts (per 148-FIELD-TABLE.md). Seed BOTH advancers as active candidates; do NOT assume one-D-one-R; do NOT drop the second same-party candidate.

### D-05: Stance integrity [LOCKED — USHC-05, project rule]
Chairs-not-polarity (stance value = exact scale position the evidence supports, never inferred from party); every answer paired to an `inform.politician_context` row with a real fetched source URL; **0 unsourced**; honest-skip (incl. documented whole-record skip) where evidence is thin; mandatory primary-source verification pass before push (agents over-read / fabricate specifics even when citing URLs — see prior milestone lessons). Federal-24 topic set (the 24-topic federal tier, incl. social-security/tariffs/ukraine, minus the 5 state-only topics).

### Claude's Discretion
- Wave/batch structure across the 52 districts (e.g., by largest-population-first, by new-record count, or same-party-generals grouped) — planner decides.
- Whether headshots + stances are separate waves from records + race-wiring, or interleaved.
- Whether to split the phase if the planner finds it exceeds the context budget (operator open to a split recommendation).
- Exact push-script mechanics (UUID-keyed `_push_uuid.ts` for NULL-external_id new records vs external_id push) — follow established STATE.md conventions.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 148 source-of-truth artifacts (the locked CA field)
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv` — per-district CA field: existing_race_id, incumbent_pid, incumbent_stance_count, incumbent_top_up_tier, general_candidates, new_records_needed, nominee_status
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md` — narrative + same-party-general list + non-incumbent-nominee flags + stance-gap summary
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-incumbent-map.csv` — DB incumbent→politician_id map (join key geo_id)
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-verify.sql` — read-only assertions (CA races still 0 race_candidates baseline)
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-VERIFICATION.md` — flagged follow-ups (Raul Ruiz dedup; naive name-match caveat for new_records_needed)

### Pipeline conventions (STATE.md + project skills)
- `.planning/STATE.md` — race_candidates shape, two-path/seed conventions, v2.17/v2.18 inline-sequential methodology
- Project skills: `research-stances` / `find-headshots` (read SKILL.md for each) — established stance + headshot pipelines
- `backend/src/lib/db` — `pg` pool for read-only diagnostics / verify gates
</canonical_refs>

<specifics>
## Specific Ideas

- CA target_election = "CA 2026 Statewide General" (`728d0074-…`), 52 races at geo_id `06NN`, all currently 0 race_candidates.
- new_records_needed count per 148: CA = 38.
- A new-vs-reuse confirmation per candidate is required before insert — 148's `new_records_needed` used naive name matching; confirm each reuse target against the live DB (verifier finding).
</specifics>

<deferred>
## Deferred Ideas

- Top-up of the 7 CA partial incumbents (1–23 topics) to full 24 — deferred to a later sweep (D-01).
- TX/NY (Phase 150), FL (Phase 151), 144-completion gate (Phase 152), FL prune (Phase 153).
</deferred>

---

*Phase: 149-ca-candidate-seeding-race-candidates-only-turnkey*
*Context gathered: 2026-06-28 via plan-phase operator decisions*
