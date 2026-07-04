# 157-02 SUMMARY — 157-verify.sql NJ-scoped gate

**Status:** COMPLETE ✅
**Requirements:** USHC2-02/03/04/05

## What was built
- `backend/scripts/157-verify.sql` — write-free, labeled-assertion gate, single-state reduction of 156-verify.sql. NJ election `cdb3f77b-7f10-4d0a-ae79-0d8329cbd026`, geo prefix `34`.

## Assertion labels
- **USHC2-03a** — 12 NJ races; all ≥1 active; **NJ-8 (3408) exactly 1** (uncontested); other 11 ≥2.
- **USHC2-03b** — 0 active rows with NULL politician_id.
- **USHC2-02a** — 0 duplicate full_name among active NJ candidates (D-03).
- **USHC2-02c** — 11 reused incumbents (NJ-1..11, incl. NJ-11 Mejia `93874414-…` special-seated) present as active `is_incumbent=true`. NJ-12 Watson Coleman intentionally excluded.
- **D-04-NJ12** — Watson Coleman `a75a3e6e-…` absent from active field; Hamawy + Mele active (geo 3412). Retirement, NOT vacancy — no office/vacancy assertion.
- **D-04-NJ8** — the single active NJ-8 candidate = Menendez `fc7a00d6-…`, `is_incumbent=true`.
- **D-02** — NJ-3 Welzer + Kelly + NJ-5 Rueda present as active.
- **USHC2-04** — new-candidate band (`external_id BETWEEN -341299 AND -340101`) all have politician_images row, minus `_img_skip` pins.
- **USHC2-05a** — 0 unsourced stance rows for the in-scope set.
- **USHC2-05b** — each in-scope candidate ≥1 sourced federal stance OR pinned in `_stance_skip`.

## In-scope-set convention
- `_new_cands` = active NJ candidates with `external_id BETWEEN -341299 AND -340101` (new band only). **NO incumbent is in scope** — NJ has no zero-stance incumbent (contrast NC-6 McDowell in 156). Incumbent band `-34001..-34012` is numerically > `-340101`, so the cut cleanly separates.
- `_stance_skip` (UUID) and `_img_skip` (external_id) start EMPTY; **157-04 populates `_img_skip`, 157-05 populates `_stance_skip`, 157-06 finalizes pins** — each with explicit ORDER BY (143 lesson).

## How 157-04/05 invoke it mid-wave
`cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/157-verify.sql`

## Verification
- Write-free + NJ-scoped + Mejia/Watson-Coleman pins: PASS.
- Runs read-only against prod; scope sanity passes (12 races → 157-01 live); first data-dependent assertion (USHC2-03a, 0 active) fails pre-seed — **documented expected**, goes green after 157-03/04/05.
