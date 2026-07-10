# MO SOS removed-candidates: Vivio + Conner withdrawn — cull from 2026 House races

Found 2026-07-09 during MO headshot sweep (agent verified against MO SOS removed-candidates list):

- **Nick Vivio (D), Maryland Heights — U.S. Rep District 2 — removed 5/18/2026 (Withdrawn).**
  Ballotpedia still lists him in the Aug 4 primary (stale). DB pid `91d176cc-a851-4ad5-aa79-f8d27f600b96`,
  race_candidates.candidate_status still active. Headshot found (BP S3 original, excellent) and HELD at
  `scratchpad/wmo/vivio_hold.jpg` — import only if the cull decision is to keep him.
- **Mike Conner (D), Auxvasse — U.S. Rep District 3 — withdrew 4/8/2026.**
  DB pid `af595c20-e62c-43ce-a928-c5308f5c1ba9`. Ballotpedia: "will not appear on the ballot". No photo exists.

Action: set candidate_status='withdrawn' for both when the MO pre-primary cull runs (existing gate ≥ 2026-08-05
per seed source notes; Phase 164.1 MO wave date-gated ≥ 2026-08-04). Related: Harbison -290803 flag (MO-8) —
headshot agent found NO withdrawal evidence for him 2026-07-09; he remains active per SE Missourian.
