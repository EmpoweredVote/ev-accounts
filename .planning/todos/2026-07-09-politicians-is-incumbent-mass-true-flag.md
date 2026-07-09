# Data flag: `politicians.is_incumbent = true` on ~1,041 2026 House challengers (nationwide)

**Found:** 2026-07-09 during TN headshot sweep.

**Symptom:** every one of TN's 70 challengers has `politicians.is_incumbent = true` even though
`race_candidates.is_incumbent = false`. Scoped nationally: **1,041 active 2026 House challengers**
across all seeded states carry `p.is_incumbent = true` (FL 161, TN 73, WA 60, MO 58, MI 56, CA 51,
TX 51, …). Likely a seeding default in the bulk House-candidate waves.

**Feed exposure is limited:** only **22 of the 1,041** also have `office_id IS NOT NULL`, and the
reps feed joins `politicians → offices → districts`, so the other 1,019 can't surface there.
Some of the 22 are *correct* (current officeholders running for a different seat — e.g. Todd
Warner, sitting TN state rep, running TN-9): `p.is_incumbent` = "holds their current office",
`rc.is_incumbent` = "incumbent in this race". The mass `true` on office-less nobodies is still
wrong data even if invisible.

**Action items:**
1. Audit the 22 `office_id IS NOT NULL` cases — verify each is a real current officeholder;
   fix any that aren't.
2. Decide semantics: if `p.is_incumbent` should mean "holds any current office", bulk-flip the
   ~1,019 office-less challengers to `false` (idempotent migration, scoped via race_candidates
   join per dedup convention — NOT raw external_id bands).
3. Standing rule for sweeps/gates: **use `race_candidates.is_incumbent`**, never
   `politicians.is_incumbent`, to split incumbents from challengers.

Repro query: active 2026 House race_candidates with `rc.is_incumbent=false AND p.is_incumbent=true`,
grouped by `substring(districts.geo_id,1,2)`.
