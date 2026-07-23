# Phase 173 — OPS-04 Cadence Decision (live-data confirmation)

**Date checked:** 2026-07-23
**Checked against:** production project `kxsdzaojfaibhuzmclfq` (Supabase Postgres, via `psql "$DATABASE_URL"` — read-only)

## Query run (bare `SELECT count(*)`, no mutation)

```sql
SELECT count(*)
FROM essentials.discovery_jurisdictions
WHERE election_date > now()
  AND election_date <= now() + interval '180 days';
```

This is the exact predicate implemented in `backend/src/lib/discoveryCron.ts` (`SWEEP_HORIZON_DAYS = 180`,
query at the jurisdiction-selection site — `election_date > now() AND election_date <= $1` where
`$1 = now() + SWEEP_HORIZON_DAYS days`).

## Result

**46** jurisdictions currently fall within the 180-day sweep horizon.

## Cadence decision: KEEP (weekly Sunday 02:00 UTC + 180-day horizon)

46 in-horizon jurisdictions is a modest, clearly bounded weekly cost:

- Each sweep now makes **one canary call** (OPS-01 preflight, `claude-haiku-4-5`, `max_tokens: 1`)
  plus **at most one paid `runDiscoveryAgent` call per in-horizon jurisdiction** (≤ 46 calls this week).
- This is a small, predictable weekly ceiling — not the "144x credit-exhaustion failures" flood the
  cron audit surfaced, which was caused by the *lack* of a pre-flight gate (OPS-01, fixed in 173-01/02),
  not by the horizon/cadence size itself.
- Weekly (not daily) cadence means this bounded cost recurs once per week, not once per day — a 7x
  reduction in worst-case spend frequency versus a naive daily re-scan of the same horizon.
- 46 is well within a range where a full sweep completes comfortably inside the existing
  `LOCK_TTL_MS = 2 hours` run-lock window, with room to grow before that ceiling becomes a concern.

**Decision: the weekly Sunday-02:00-UTC cadence and the 180-day horizon remain the deliberate,
confirmed cost choice.** No code change to the cron expression or `SWEEP_HORIZON_DAYS` is made by
this plan — this is a confirm-and-record deliverable (OPS-04), not an adjustment.

## Follow-up note for the operator

If the in-horizon count grows substantially in future (e.g., during a high-election-density period
where many more `discovery_jurisdictions` rows enter the 180-day window simultaneously — such as a
general-election year with many concurrent state/local filing deadlines), the operator may choose to:

- Shorten `SWEEP_HORIZON_DAYS` (fewer jurisdictions per sweep, more frequent re-checks needed near
  election day), or
- Split the sweep into multiple smaller batches per run, or
- Accept the higher weekly Anthropic spend if the jurisdiction growth is itself the intended coverage
  expansion (e.g., v2.22's Wave-3 national completion work naturally grows this count over time as new
  jurisdictions are seeded).

This is a cost/coverage tradeoff decision for the operator to make when the count materially changes,
not something this phase pre-empts.

## Code cross-references (OPS-04 comments landed in prior plans)

- `backend/src/lib/discoveryCron.ts` (173-02) — comment on `SWEEP_HORIZON_DAYS = 180` explaining the
  deliberate-cost-choice rationale and its direct proportionality to weekly Anthropic spend.
- `backend/src/cron/discoverySweep.ts` (173-03) — comment on the `cron.schedule('0 2 * * 0', ...)`
  registration explaining that the weekly (not daily) cadence deliberately bounds recurring spend,
  proportional to `discovery_jurisdictions` within `SWEEP_HORIZON_DAYS`.

## Verification

- Query is a bare `SELECT count(*)` — confirmed read-only, no `INSERT`/`UPDATE`/`DELETE`/DDL executed
  against prod. No prod data was mutated.
