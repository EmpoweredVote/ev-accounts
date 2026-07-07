# 156-02 SUMMARY — 156-verify.sql per-phase gate

**Status:** COMPLETE ✅
**Artifact:** `backend/scripts/156-verify.sql` (write-free, ~330 lines)

## What was built
A read-only, per-state OH/GA/NC-scoped labeled-assertion gate adapting the validated `155-verify.sql`
to THREE states. All assertions scoped by `d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN ('39','13','37')`
within the three named 2026 Statewide General elections — no cross-state contamination.

## Assertion labels
- **scope** — exactly 15 OH + 14 GA + 14 NC House races (passes NOW post-156-01).
- **USHC2-03a** — every race ≥1 active candidate (hard floor); NOTICE reports <2.
- **USHC2-03b** — 0 active race_candidates with NULL politician_id.
- **USHC2-02a** — 0 duplicate full_name among active candidates within each state (D-03).
- **USHC2-02c** — 39 pinned renominated incumbents reuse their 154 pid (OH 15 + GA 10 + NC 14 incl. **NC-6 McDowell -37006**). GA-1/10/11 + GA-13 intentionally excluded (documented).
- **D-04-GA** — GA-1 Carter / GA-10 Collins / GA-11 Loudermilk pids ABSENT from active field; certified nominees (Kingston/Hollowell, Gaines/DeLancy, Cowan/Harden) present by name.
- **D-04-GA13** — TRUE VACANCY: NO incumbent-absent pin; asserts Clark + Chavez both active, non-null pid, neither is_incumbent=true.
- **D-02** — OH-4 Tamie Wilson + NC-11 John Rogers independents pinned by name; Libertarian/Green lines appended to `_minor` by 156-03/05.
- **USHC2-04** — every new candidate has a politician_images row (minus `_img_skip` pins).
- **USHC2-05a** — 0 unsourced stance rows in the in-scope set.
- **USHC2-05b** — each in-scope candidate ≥1 sourced federal stance OR pinned whole-record skip.

## In-scope set convention (D-01 asymmetry — the 150 TX/NY model, NOT 155)
`_in_scope` = the three new-candidate external_id bands (**OH -399999..-390000, GA -139999..-130000, NC -379999..-370000**) **UNION the single McDowell pid** `74579547-1454-475e-ab35-12cf88a998b9`. All OTHER OH/GA/NC partial incumbents are EXCLUDED (left as-is) so their partial coverage can't false-fail. McDowell is the ONE incumbent in scope (zero-stance-gets-full-set).

## Honest-skip pin convention
`_stance_skip` (UUID, ORDER BY politician_id) and `_img_skip` (external_id, ORDER BY external_id) start
EMPTY — Wave 3 waves append rows (156-06 img; 156-07/08/09 stance). 143 ORDER-BY lesson noted in header.

## How 156-06..09 invoke it mid-wave
`cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/156-verify.sql`
Each wave that adds skip pins edits `_stance_skip`/`_img_skip` in this file before re-running.

## Verification
- Plan automated check: `PASS-scoped-mcdowell-and-write-free`.
- Read-only run against prod NOW: parses + executes; scope check PASSES (15/14/14 races live post-156-01), then fails at USHC2-03a (`43 races have 0 active candidates`) — the expected pre-seed data-dependent failure. Write-free (no DELETE/UPDATE/INSERT INTO essentials|inform).
