# Requirements: v2.17 National House Rep Stances (Tier 2 continuation)

**Milestone:** v2.17
**Status:** Active
**Scope:** 212 remaining seeded US House reps across 38 states. Completes national US House
stance coverage (FL/NY/PA/IL done in v2.16; CA/VA/TX/MA and other pre-existing reps already covered).

Pure scale-out of the v2.16 pipeline — no new architecture. Every stance backed by a real fetched
source URL in `inform.politician_context`; honest-skip per topic where no evidence; **never infer
from party**; embed the 1–5 stance scale texts per topic; up to 3 reps researched concurrently
(premium tier, validated). Researched largest-delegation-first in 8 multi-state waves so coverage
is maximized early if interrupted.

**In-scope rep set:** `essentials.politicians` rows with `external_id BETWEEN -56999 AND -1000`
that have **no** rows in `inform.politician_answers` (212 reps). State derived from external_id:
`state_fips = floor((-external_id)/1000)`.

**Reusable assets (from v2.16):** shared `_TOPIC_SCALE.txt` (25 federal topics = 44 live minus 11
city + judicial-*), `politician-stance-researcher` agent → per-rep CSV → canonical
re-parse(`relax_column_count`)/re-stringify → merge, external_id→UUID push
(`backend/data/stance-research/pa-house-a/_push.ts`), gate pattern
(`backend/scripts/verify-phase-127-131.sql`).

**Out of scope:** FEC finance summary for the newly-seeded reps (separate FINA stream); the 3
genuine vacancies (FL-20/GA-13/TX-23); the 137 pre-existing reps (already covered).

---

## House Rep Stances (USHS)

Each wave requirement: sourced stances + a paired `inform.politician_context` row (real source URL)
for every in-scope rep in the listed states; honest-skip topics with no evidence; **zero unsourced
rows** at wave close.

- [ ] **USHS-06**: Sourced stances + context for all OH (15) + NC (14) reps = **29**. Zero unsourced rows.
- [ ] **USHS-07**: Sourced stances + context for all GA (13) + MI (13) reps = **26**. Zero unsourced rows.
- [ ] **USHS-08**: Sourced stances + context for all NJ (12) + WA (10) + AZ (9) reps = **31**. Zero unsourced rows.
- [ ] **USHS-09**: Sourced stances + context for all TN (9) + CO (8) + MN (8) + MO (8) reps = **33**. Zero unsourced rows.
- [ ] **USHS-10**: Sourced stances + context for all WI (8) + AL (7) + SC (7) + KY (6) reps = **28**. Zero unsourced rows.
- [ ] **USHS-11**: Sourced stances + context for all LA (6) + CT (5) + IN (5) + OK (5) + AR (4) + IA (4) reps = **29**. Zero unsourced rows.
- [ ] **USHS-12**: Sourced stances + context for all KS (4) + MS (4) + NV (4) + NE (3) + NM (3) reps = **18**. Zero unsourced rows.
- [ ] **USHS-13**: Sourced stances + context for all HI/ID/MT/NH/RI/WV (2 ea) + AK/DE/ND/SD/VT/WY (1 ea) reps = **18**. Zero unsourced rows.
- [ ] **USHS-14**: Consolidated phase-gate verify SQL — every in-scope rep (all 212) has ≥1 sourced stance; zero answer rows lack a paired context row with a real source URL; per-state coverage counts asserted.

**Total: 212 reps across 38 states (29+26+31+33+28+29+18+18).**

## Future Requirements (deferred)

- FEC finance summary (`finance_summary` JSONB) for the newly-seeded US House reps — FINA stream.

## Out of Scope

- The 3 genuine House vacancies (FL-20/GA-13/TX-23) — auto-fill on seed re-run after special elections.
- The 137 pre-existing reps (CA/VA/TX/MA and others) — already have stance coverage from prior milestones.
- Any schema, geofencing, or seeding work — Tier 1 (v2.15) and geofencing (v2.11) are complete.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| USHS-06 | 132 | pending |
| USHS-07 | 133 | pending |
| USHS-08 | 134 | pending |
| USHS-09 | 135 | pending |
| USHS-10 | 136 | pending |
| USHS-11 | 137 | pending |
| USHS-12 | 138 | pending |
| USHS-13 | 139 | pending |
| USHS-14 | 140 | pending |
