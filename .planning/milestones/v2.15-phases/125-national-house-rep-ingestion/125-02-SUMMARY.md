---
phase: 125-national-house-rep-ingestion
plan: 02
status: complete
completed: 2026-06-16
requirements: [USHR-01, USHR-02, USHR-03]
---

# 125-02 Summary — Apply migration 739 + verify

## What was done

Applied `backend/migrations/739_national_house_reps.sql` to production
(`kxsdzaojfaibhuzmclfq`) via `psql -v ON_ERROR_STOP=1` (single transaction). 299
politician + 299 office rows inserted; `UPDATE 299` office_id backfill; `COMMIT`.
Migration version `739` recorded in `supabase_migrations.schema_migrations`.

## Verification results

| Check | Expected | Actual | ✓ |
|-------|----------|--------|---|
| Linked NATIONAL_LOWER office rows | ~436 | 437 (see note) | ✓ |
| Distinct NATIONAL_LOWER districts | 437 | 437 | ✓ |
| Districts still unlinked | 4 | 4 (1198 dup DC + FL-20/GA-13/TX-23 vacancies) | ✓ |
| Batch politicians (external_id -56999..-1000) | 299 | 299 | ✓ |
| Orphan politicians in batch (office_id NULL) | 0 | 0 | ✓ |
| party='Democrat' in batch | 0 | 0 | ✓ |
| party='Democratic' in batch | — | 127 | ✓ |
| Idempotent re-run | 0 inserts | 299× `INSERT 0 0`, `UPDATE 0`, COMMIT | ✓ |
| CA / VA / MA linked (untouched) | 53 / 11 / 9 | 53 / 11 / 9 | ✓ |
| Path 0 join (newly-seeded) | resolves | AOC NY-14, Frost FL-10, Babin TX-36, Latta OH-5, Jackson IL-1, Begich AK-AL, Hageman WY-AL | ✓ |

**Note on 437 vs 436:** 437 distinct NATIONAL_LOWER districts; 433 linked + 4 unlinked.
The "linked office rows" count (437) exceeds distinct linked districts because of TWO
pre-existing multi-office districts, NEITHER caused by this batch (`involves_batch=false`):
- **CA-29** (`0629`): Luz Maria Rivas + Tony Cárdenas — stale Cárdenas office from the v2.2 CA seed (he left Congress). **Follow-up data-hygiene item — out of scope for Phase 125.**
- **DC At-Large** (`dc-national-lower`): Eleanor Holmes Norton + Ankit Jain + Paul Strauss (delegate + 2 shadow senators) — legitimate, seeded in Phase 105.

## Idempotency fix (deviation)

The first apply succeeded, but the original pre-flight asserted `unseeded >= 299`, which
made a re-run ERROR (unseeded had dropped to 4) instead of cleanly no-op'ing. Changed the
guard in both `seed-national-house-reps.ts` and `739_national_house_reps.sql` to assert
`total NATIONAL_LOWER districts >= 435` (i.e. "districts loaded" — the actual orphan-prevention
intent) so re-runs are a clean no-op while still guarding the first apply. Re-verified: clean
`INSERT 0 0` ×299. Applied effect is identical (same 299 inserts); only the guard changed.

## Vacancies (carry to v2.16 / future)

3 genuine current US House vacancies, unseeded by design (confirmed absent from
`legislators-current.yaml`): **FL-20, GA-13, TX-23**. When special elections seat new
members, re-running `seed-national-house-reps.ts --generate` + apply will pick them up
(idempotent). The DC `1198` TIGER row stays intentionally unlinked (delegate already
seeded under `dc`-prefixed geoids).

## Requirements satisfied

- **USHR-01** ✓ — all current House reps for the 50 states + DC delegate are seeded + FK-linked via tiger_geoid (DC was already seeded; 299 new for the 50 states minus 3 vacancies).
- **USHR-02** ✓ — idempotent, unseeded-only; 137 pre-existing reps untouched; clean no-op re-run; 0 orphans.
- **USHR-03** ✓ — Democrat→Democratic normalized; at-large `00` handled; territories excluded; DC handled.

Formal consolidated gate + headshots + Path 0 spot-checks across ≥5 states = Phase 126.
