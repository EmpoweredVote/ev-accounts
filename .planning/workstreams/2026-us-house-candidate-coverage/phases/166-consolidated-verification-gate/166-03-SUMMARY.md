---
phase: 166-consolidated-verification-gate
plan: 03
subsystem: database
tags: [postgres, plpgsql, verification, gate, elections, candidates]

requires:
  - phase: 166-01
    provides: the 43-election scope, the live pin fragment, and both censuses
provides:
  - "backend/scripts/166-verify.sql — the milestone structural gate, 12 assertions over 178 districts"
  - "The NATIONAL TOTAL footer: 411 gate-proven + 24 gate-pending = 435"
affects: [166-05, 167, 159-06]

tech-stack:
  added: []
  patterns:
    - "PROVISIONAL asserted as a per-state (marked, unmarked) count pair, which survives split states"
    - "District-level ACTIVE assertion with an explicit empty-race NOTICE, so coverage and emptiness are both visible"

key-files:
  created:
    - backend/scripts/166-verify.sql
  modified: []

key-decisions:
  - "ACTIVE asserts per DISTRICT, not per race: 5 WI general races are legitimately empty because WI's field moved to its primary, and a per-race assertion would fail on fully-covered districts. The empty races are reported as a NOTICE naming the geo_ids."
  - "PROVISIONAL asserted as an exact per-state (marked, unmarked) race-count pair instead of 164/165's two whole-state lists, because WI (8m/16u) and AL (4m/3u) are split and a list cannot express them."
  - "MA/MD/OR/ME/NV/UT excluded from the PROVISIONAL assertion (33 races) because their wording is inherited from reused pre-existing elections; 165 documented NV/UT/ME and the other three follow by the same logic."
  - "No migration required — the gate is read-only and adds no schema."

patterns-established:
  - "Probe new milestone-scale assertions as plain SELECTs before converting them to RAISE-on-failure blocks"

requirements-completed: [USHC3-06]
---

# 166-03: the 178-district structural gate

## Result

```
cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/166-verify.sql
```

**Exit 0**, twelve `PASS` blocks, `ALL ASSERTIONS PASSED`, and the `NATIONAL TOTAL` footer. Green on
the first run.

| Block | Result |
|---|---|
| SCOPE | 178 districts across 38 states, carried by 194 races over 43 elections |
| ACTIVE | all 178 districts have ≥1 active candidate; 2 with <2 (allowance) |
| NULLOFFICE | 0 of 194 races with NULL office_id |
| NULLPID | 0 active candidates with NULL politician_id |
| DUPNAME | 0 in-state duplicate names among active candidates |
| DUPINCUMBENT | 0 politicians active in 2+ races |
| RC-UNIQUE | exactly 1 rc row per (race_id, politician_id) |
| PARTY | no party column on race_candidates |
| PROVISIONAL | 81 marked + 80 unmarked + 33 excluded = 194 |
| HEADSHOT | every banded active candidate has an image or one of 51 pins |
| UNSOURCED | 0 unsourced stance rows |
| COVERAGE | 123 researched skips + 2 Phase-167 queued, reported separately |

## Probe results (required by the plan, recorded even though both are zero)

Both new milestone-scale assertions were run as plain `SELECT`s and inspected **before** being
converted into `RAISE`-on-failure blocks:

- **DUPINCUMBENT** — politicians active in ≥2 distinct in-scope races: **0 rows**.
- **RC-UNIQUE** — duplicated `(race_id, politician_id)` pairs: **0 rows**.

The DUPINCUMBENT zero carries extra information given 166-01's scope correction: because WI now has
both a general and a primary election in scope, a duplicated candidate was the plausible failure
mode. Zero confirms WI's field was **relocated** onto the primary, not **duplicated** across both.

## ACTIVE — asserted per district, not per race

Five in-scope races hold 0 active candidates: **WI 5501, 5502, 5505, 5507, 5508** — all
`WI 2026 Statewide General`. This is the downstream consequence of the 2026-07-25 move of WI's field
onto `WI 2026 Partisan Primary`, established in 166-01.

The plan's wording was "every one of the 178 races has at least 1 active candidate". Applied
per-race that assertion **fails** on districts that are in fact fully covered — WI-1's candidates
exist, they are on the primary race. So ACTIVE asserts at **district** granularity (every one of the
178 districts has ≥1 active candidate — verified, 0 exceptions) and the empty races are emitted as
an explicit NOTICE naming their geo_ids:

```
NOTE ACTIVE: 5 in-scope race(s) hold 0 active candidates (geo_ids 5501, 5502, 5505, 5507, 5508)
  — expected: WI's field moved to WI 2026 Partisan Primary on 2026-07-25, leaving its general
  races empty. Every district is still covered.
```

This keeps the fact visible rather than absorbing it into a passing assertion. 2 districts have <2
active candidates — the uncontested-seat allowance carried from 152, reported as a notice.

## PROVISIONAL — as asserted

Taken verbatim from the `166-pins.generated.sql` census header. Nothing was carried forward from
164's CT+KS list or 165's AK/HI/NH/RI/DE/VT/WY list; phases 161-163 authored no PROVISIONAL
assertion at all, and 164/165 measured theirs three weeks ago.

**Shape change.** Two states are split, so the 164/165 "marked-state list + unmarked-state list"
shape cannot express the census:

- **WI** — 8 marked (general races) / 16 unmarked (the two party primaries)
- **AL** — 4 marked / 3 unmarked

The block therefore asserts an exact per-state **(marked, unmarked) count pair** for each of the 32
asserted states, which is strictly stronger than the two-list form and handles splits natively.

Asserted (32 states): AZ 9m, WA 10m, TN 9m, MN 8m, MO 8m, WI 8m/16u, AL 4m/3u, LA 6m, CT 5m, KS 4m,
HI 2m, NH 2m, RI 2m, AK 1m, DE 1m, VT 1m, WY 1m; IN 9u, CO 8u, SC 7u, KY 6u, OK 5u, AR 4u, IA 4u,
MS 4u, NM 3u, NE 3u, WV 2u, ID 2u, MT 2u, ND 1u, SD 1u.

**Excluded (33 races across 6 states)** — MA, MD, OR, ME, NV, UT. Their PROVISIONAL wording is
inherited from **reused pre-existing elections** rather than authored by this milestone, so it is
not ours to assert. 165 documented the NV/UT/ME exclusion; MA (161), MD (162-08) and OR (164-03)
follow by the same logic. Their measured counts are named in the pass notice so the exclusion reads
as a decision, not an omission.

**81 marked + 80 unmarked + 33 excluded = 194** in-scope races over 178 districts.

The block comment records that Phase 167 clears these flags per primary-date cluster, that the
assertion is therefore expected to need updating at each cluster execution, and that the correct
update is to **move** a state's counts between marked and unmarked — never to delete the assertion.

## Pin counts, split by kind

`PASS COVERAGE` reports the two kinds as separate figures and the gate never conflates them:

- **123 RESEARCHED whole-record honest-skips** — each carrying a documented search trail, reason
  text carried verbatim from gates 161-165.
- **2 QUEUED TO PHASE 167** — 0-stance as of 2026-07-26 with **no research performed**. Recording
  these as researched skips would assert a judgment nobody made.

`PASS HEADSHOT` carries the **51** live-derived headshot pins.

The gate resolves `external_id` → `politician_id` **after** the inserts, so the pasted fragment stays
byte-identical to its source, and raises if any id fails to resolve. A `diff` of the spliced region
against `backend/scripts/166-pins.generated.sql` is empty.

## NATIONAL TOTAL footer (exact text)

> NATIONAL TOTAL: 178 Wave-3 (v2.22) districts asserted by this gate together with
> backend/scripts/166-verify-invariants.sql and backend/scripts/166-coordinate-smoke.ts; 144 v2.20
> Wave-1 districts owned by backend/scripts/152-verify.sql; 89 v2.21 decided-state districts owned by
> backend/scripts/158-verify.sql; 24 v2.21 MI and VA districts SEEDED BUT GATE-PENDING under plan
> 159-06, date-gated on or after 2026-08-05 (158-verify.sql's own header states it must not reference
> MI or VA, so no currently passing gate covers them). 411 gate-proven + 24 gate-pending = 435 US
> House districts nationally.

## Write-freeness

| Check | Result |
|---|---|
| Executable `CREATE` statements | 8, all `CREATE TEMP TABLE ... ON COMMIT DROP` |
| Write targets | `_img_skip`, `_stance_skip`, `_stance_queue_167` — temp tables only |
| DML against `essentials` / `inform` | none (`essentials.politicians` appears only as a `FROM` in two temp-table UPDATEs) |
| `offices.is_vacant` filter | absent everywhere |
| Reference to the dropped occupancy column | none |
| `npm run check:occupancy --prefix backend` | exit 0 |

## No migration required

The gate is read-only and adds no schema, so this plan authored no migration — stated explicitly
because the plan's verification block requires that conclusion be recorded either way.

## Self-Check: PASSED
