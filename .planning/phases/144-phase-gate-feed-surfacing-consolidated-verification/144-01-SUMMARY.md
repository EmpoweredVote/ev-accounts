# Plan 144-01 — SUMMARY

**Phase:** 144 — Phase Gate — Feed Surfacing + Consolidated Verification (v2.18 State Leaders, final phase)
**Status:** Complete ✅
**Requirements closed:** SEXR-05, SEXS-03
**Executed:** 2026-06-22 (INLINE from main checkout against production `kxsdzaojfaibhuzmclfq`)

## What was built

One read-only, labeled-assertion SQL gate — `backend/scripts/verify-phase-141-144.sql` — consolidating the
three already-passing v2.18 single-phase gates (141 records+headshots, 142 Gov+AG stances, 143
SoS+Treasurer+LtGov stances) into a single pass, plus the SEXR-05 feed-surfacing smoke test as a SQL
simulation of the production `GET /representatives/me` feed predicate.

**Run:** `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f backend/scripts/verify-phase-141-144.sql`
**Result:** psql exit 0 — all 11 labeled assertions emit RAISE NOTICE PASS.

### Assertions (all PASS against production 2026-06-22)

| Label | What it proves |
|-------|----------------|
| SEXR-01/02-consolidated | 209 in-scope STATE_EXEC offices (gov 50 / lt 43 / ag 43 / sos 35 / treas 38) |
| SEXR-03-consolidated | No in-scope (state, role_canonical) pair duplicated (dedup invariant) |
| SEXR-04-consolidated | Every newly-seeded exec has a `politician_images.url` headshot |
| SEXS-03-hygiene | All in-scope Big-5 districts have `state = upper(state)` + non-empty `geo_id` (2 legacy non-Big-5 rows correctly excluded) |
| SEXS-03-coverage | 199 in-scope execs sourced (gov 50 / ag 42 / sos 34 / treas 34 / lt 39) |
| SEXS-03-skip | The 10 in-scope-uncovered execs are EXACTLY the documented whole-record honest-skips (pinned by external_id) |
| SEXS-03-unsourced | 0 in-scope answer rows lack a paired http-sourced context row |
| SEXR-05-feed-A/B/C | NC / WA / CO each surface 5 newly-seeded execs incl. their seeded governor (-3700001 / -5300001 / -800001) |

## Key decisions / deviations

- **SEXR-05 = in-gate SQL simulation** (operator decision): replicates the production feed predicate
  (`district_type='STATE_EXEC' AND state=$1 AND (is_active OR is_vacant) AND COALESCE(is_incumbent,true)`)
  for 3 newly-seeded states. No live curl / node harness as the assertion.
- **Honest-skip literal captured verbatim from the live `ORDER BY o.role_canonical, p.external_id`** (143
  lesson), not hand-ordered. The 10: AG -3900003; LtGov -4000002/-3900002/-3100002/-1900002; SoS -4500004;
  Treasurer -4600005/-2800005/-2100005/-100005.
- **DEVIATION (resolved during execution):** The first-authored SEXR-03 block included a NULL-`role_canonical`
  title-regex heuristic that false-failed on 8 offices. Investigation confirmed all 8 are correct: 6 are
  legitimately out-of-scope offices that *should* carry NULL role_canonical (ME AG/SoS/Treasurer = legislature;
  MD elected Comptroller + MD appointed Treasurer; IN Comptroller), and 2 are legacy duplicate "State of Indiana"
  rows for IN SoS Morales (642977) / IN Treasurer Elliott (688298) — both already counted via their canonical
  role rows. The heuristic over-reached beyond the plan's intent; the exact per-role counts in SEXR-01/02 already
  guard against a missing canonical row. Replaced with the duplicate-pair check (the meaningful SEXR-03 invariant).
- **Hygiene scoping trap (encoded by the planner, confirmed live):** a bare whole-STATE_EXEC hygiene count
  returns 2 (legacy CA "Board of Equalization" + IN "Indiana", both geo_id=''); the assertion is scoped to
  in-scope Big-5 offices → 0 violators.

## Files

- `backend/scripts/verify-phase-141-144.sql` (new, read-only — no schema/data changes)

## Commits

- `e63c9858` — Task 1: records + hygiene + coverage assertions
- Task 2: honest-skip pin + zero-unsourced + NC/WA/CO feed smoke-test + closing summary + SEXR-03 fix

## Self-Check: PASSED

Gate runs read-only against production, psql exit 0, every labeled assertion PASS. Write-keyword grep = 0.
This closes the v2.18 State Leaders milestone (Phases 141–144 all complete).
