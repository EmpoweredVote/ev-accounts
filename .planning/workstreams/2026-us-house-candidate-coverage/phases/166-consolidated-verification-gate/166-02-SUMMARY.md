---
phase: 166-consolidated-verification-gate
plan: 02
subsystem: database
tags: [postgis, geofencing, elections, candidates, smoke-test, coordinate-surfacing]

requires:
  - phase: 163
    provides: the post-164.1 vintage-preference surfacing engine this clones
  - phase: 164.1
    provides: the G5200V26 2026-vintage polygons that the LATERAL prefers, and migs 1247/1248/1249
provides:
  - "backend/scripts/166-coordinate-smoke.ts — 38 positive samples + the severe-MO negative, plus --select"
  - "A live enumeration mode (--select) that is the authority for future sample re-picks"
  - "The national coverage footer separating 411 gate-proven from 24 gate-pending districts"
affects: [166-05, 164.1-07, 167]

tech-stack:
  added: []
  patterns:
    - "Sample picks are re-derived live via --select, never inherited from a frozen smoke file"
    - "Negative samples carry a delimited flip region documenting both branches of the resolving plan"

key-files:
  created:
    - backend/scripts/166-coordinate-smoke.ts
  modified: []

key-decisions:
  - "Engine cloned from 163-coordinate-smoke.ts (JOIN LATERAL vintage preference), not 165's hard mtfcc pin: the pin is correct only for UT, the LATERAL generalises to TN/AL/LA/UT and every non-dual-map state and is what the deployed service does."
  - "WI stays scoped to its GENERAL election even though its field moved to a primary on 2026-07-25, so all 38 states are compared on the same surfacing behaviour; the WI primary field is covered by 166-verify.sql instead."
  - "minActive was NOT relaxed for WI — its best general race still clears 2 active / 2 challengers."
  - "The footer separates 411 gate-proven districts from 24 seeded-but-gate-pending (MI+VA), because 158-verify.sql's own header states it must not reference MI or VA."

patterns-established:
  - "Pitfall-5 guard asserts on is_incumbent=false count >= 1, never on the race merely resolving"

requirements-completed: [USHC3-06]
---

# 166-02: 38-state coordinate-surfacing smoke

## Result

`node --import tsx scripts/166-coordinate-smoke.ts` exits **0** with **38 positive PASS lines plus
the severe-MO negative**, and the terminal line
`166 COORDINATE SMOKE GREEN: 38/38 states surface their US House race with full challenger-inclusive field`.

Every state proves, through the same code path production uses, that a resident resolves to exactly
one US House race with a **challenger-inclusive** field — not merely that the incumbent resolves.

## Engine

Cloned from `163-coordinate-smoke.ts`, the post-164.1 vintage-preference form:

- Anchor query orders `CASE WHEN gb.mtfcc = 'G5200V26' THEN 0 ELSE 1 END`, so a 2026-vintage polygon
  wins when one exists.
- Surfacing query uses the `JOIN LATERAL` that takes the `G5200V26` geometry for a geo_id when
  present and otherwise falls back to the district-mtfcc branch.

165's hard `mtfcc` pin was deliberately **not** used: a hard pin is correct only for UT, whereas the
LATERAL generalises to TN, AL, LA, UT and every non-dual-map state at once, and mirrors the deployed
`getElectionsByCoordinate` Part A. 164.1-04 recorded that the pre-164.1 plain join double-matches for
dual-map states and would spuriously surface two races.

SELECT-only. `grep -c "extensions\.ST_"` returns **0** — every PostGIS call is `public.`-prefixed.

Five election names deviate from the `{ABBR} 2026 Statewide General` convention because those
elections were pre-existing and reused rather than authored: OR (164-03), MD (162-08), MA (161),
ME and NV (165-01).

## Sample selection

`--select` enumerates, live, every in-scope district with its active and challenger counts ordered by
contest depth. It printed 38 `SELECT-CANDIDATES` lines and is the **sole** authority for the picks —
none were copied from 161/162/163/164/165, whose picks were frozen in early July. MO's line omits
2902-2906.

Rule applied: highest challenger count, open seat preferred on ties.

## The 38 chosen samples

| ST | geo_id | active | challengers | Note |
|---|---|---|---|---|
| AZ | 0401 | 8 | 8 | open |
| WA | 5304 | 11 | 11 | open — tied with 5305 on challengers, open seat won |
| TN | 4706 | 11 | 11 | open |
| MA | 2506 | 7 | 7 | open, only MA open seat |
| IN | 1802 | 3 | 2 | three-way tie, none open |
| MD | 2405 | 4 | 4 | open (Hoyer seat) |
| MN | 2705 | 10 | 9 | |
| MO | 2901 | 8 | 7 | NON-SEVERE |
| WI | 5503 | 2 | 2 | open — **thinnest sample, see below** |
| CO | 0801 | 2 | 2 | open, only CO open seat |
| AL | 0102 | 7 | 6 | un-withheld by 164.1-05 (mig 1248) |
| SC | 4501 | 4 | 4 | open |
| LA | 2205 | 12 | 12 | open jungle — deepest field in the phase |
| KY | 2104 | 4 | 4 | open |
| OR | 4104 | 3 | 2 | |
| CT | 0904 | 6 | 5 | |
| OK | 4005 | 4 | 3 | |
| AR | 0501 | 3 | 2 | tied with 0503, none open |
| IA | 1902 | 4 | 4 | open |
| KS | 2004 | 11 | 10 | |
| MS | 2801 | 3 | 2 | four-way tie, none open |
| NV | 3202 | 3 | 3 | open (Amodei retired) |
| UT | 4903 | 6 | 5 | dual-map, resolves via G5200V26 |
| NM | 3501 | 2 | 1 | three-way tie, none open |
| NE | 3102 | 3 | 3 | open (Bacon retired) |
| WV | 5402 | 4 | 3 | |
| ID | 1602 | 6 | 5 | |
| HI | 1501 | 8 | 7 | |
| ME | 2302 | 2 | 2 | open |
| NH | 3301 | 14 | 14 | open |
| RI | 4401 | 3 | 2 | tied with 4402, none open |
| MT | 3001 | 3 | 3 | open (Zinke retired) |
| AK | 0200 | 15 | 14 | at-large jungle |
| DE | 1000 | 2 | 1 | at-large |
| ND | 3800 | 2 | 1 | at-large |
| SD | 4600 | 2 | 2 | at-large open |
| VT | 5000 | 4 | 3 | at-large |
| WY | 5600 | 14 | 14 | at-large open |

All 38 report **0 null politician_id** and **≥ 1 challenger**.

## The one thin sample — WI

WI's best general races are `5503` and `5506`, both at 2 active / 2 challengers, and **4 of WI's 8
general races hold zero active candidates**. That is not a seeding gap. As 166-01 established, on
**2026-07-25** a party-split `WI 2026 Partisan Primary` (2026-08-11) was created and WI's field —
32 active candidates including 7 incumbents — moved onto it.

Two decisions follow, both recorded in the file:

1. **`minActive` was NOT relaxed.** The plan is explicit that a thin state is a signal, not a
   nuisance. WI clears the 2-active / 1-challenger bar on its own merits, so no guard was weakened.
2. **WI stays scoped to the general here.** The smoke's purpose is to compare all 38 states on the
   same surfacing behaviour. The WI primary field is not ignored — 166-01 put
   `WI 2026 Partisan Primary` into the Phase-166 scope, so `166-verify.sql` covers those 32
   candidates.

## Severe-MO negative sample

```
PASS MO 2905 (severe negative sample): coordinate (39.0841,-94.4623) surfaced ZERO House races
  on MO 2026 Statewide General — withholding confirmed end-to-end
```

MO-5 (the dismantled Cleaver seat) is one of the five severity-routed districts. Its races live on
the withheld `MO 2026 Congressional Redistricting - Polygon Pending` election, which
`ELECTION_VISIBILITY_WINDOW` never returns. On failure the message names the leaked geo_ids rather
than only reporting a count.

The block is delimited `-- === MO POST-2026-08-04 FLIP REGION (see 166-mo-flip-runbook.md) ===` and
documents both branches of plan 164.1-07:

- **map-holds** — the five severe MO races move to the general. The negative sample becomes five
  positive samples (2902-2906), `SEVERE_MO_GEO_IDS` empties, `MIN_DISTRICTS` goes 38 → 43, and the
  `--select` MO exclusion drops.
- **referendum-qualifies** — MO stays withheld this cycle and **this block needs no edit**.

## National coverage footer

```
NATIONAL COVERAGE — 178 + 144 + 89 + 24 = 435 US House districts
  178  Wave-3 (v2.22), proven here and by backend/scripts/166-verify.sql
  144  v2.20 CA/TX/FL/NY, owned by backend/scripts/152-verify.sql
   89  v2.21 decided states, owned by backend/scripts/158-verify.sql
  ---
  411  GATE-PROVEN
   24  v2.21 MI and VA — SEEDED BUT GATE-PENDING, owned by plan 159-06,
       date-gated on or after 2026-08-05.
  ---
  435  total US House districts covered
```

The 24 MI+VA districts are deliberately **not** described as gate-proven: `158-verify.sql`'s own
header states it must not reference MI or VA.

## Verification

| Check | Result |
|---|---|
| `node --import tsx scripts/166-coordinate-smoke.ts` | exit 0 |
| `PASS ` lines | 39 (38 positive + MO negative) |
| `166 COORDINATE SMOKE GREEN: 38/38 ...` | present |
| Every PASS reports ≥ 1 challenger and 0 null pid | pass |
| `SAMPLES` length / `MIN_DISTRICTS` | 38 / 38 |
| MO sample geo_id ∈ {2901, 2907, 2908} | 2901 |
| Every sample carries a district-naming comment | pass |
| `--select` emits exactly 38 `SELECT-CANDIDATES` lines, MO omits 2902-2906 | pass |
| `grep -c "extensions\.ST_"` | 0 |
| `-- === MO POST-2026-08-04 FLIP REGION` delimiter present, both branches documented | pass |
| Footer carries 178 + 144 + 89 + 24 = 435 and names 152/158/159-06 | pass |
| `npm run check:occupancy --prefix backend` | exit 0 |

## Self-Check: PASSED
