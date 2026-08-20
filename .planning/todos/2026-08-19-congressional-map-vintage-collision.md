# Two US Representatives for one address: the `G5200V26` vintage collision

**Created** 2026-08-19 · **Found while** wiring Austin council district geography (migration 1836)
**Scope** 9 states · **Severity** voter-facing wrong answer, silent

## What happens

An address at Austin City Hall (-97.7470, 30.2649) returns **two** `NATIONAL_LOWER`
offices:

| District | geo_id | Holder | Layer |
|---|---|---|---|
| Congressional District 37 | `4837` | Lloyd Doggett | `G5200` |
| Congressional District 10 | `4810` | Michael McCaul | `G5200V26` |

Doggett is the **sitting** representative for downtown Austin. CD-10 is where that
address lands on the **2026 ballot** under Texas plan C2333. Both rows are true
statements about different things, and nothing in the read path distinguishes them —
the voter is simply told they have two representatives.

## Why it happens

`essentials.geofence_boundaries` carries two congressional layers:

- `G5200` — `census_tiger_2024`, all states
- `G5200V26` — the 2026 mid-decade redistricting maps, **9 states**, each with a
  named source: `al_sos_2026`, `ca_swdb_prop50_2026`, `fl_legislature_2026`,
  `la_legis_2026`, `nc_ncga_2025`, `oh_orc_2025`, `tn_tnmap_2026`,
  `tx_tlc_planc2333_2026`, `ut_agrc_2026` (173 polygons total).

`G5200V26` is deliberate, sourced work — **do not delete it.**

The defect is in `backend/src/lib/geoIdGuard.ts`. Its MTFCC→district_type table
lists `G5200` but not `G5200V26`, so `G5200V26` falls through to the catch-all:

```sql
OR (gp.mtfcc NOT IN (${FALLBACK_EXCLUDED_MTFCC_SQL_LIST}) AND gp.mtfcc NOT LIKE 'X%')
```

which means "match ANY district_type for this geo_id". Confirmed 2026-08-19:
`grep -rn "G5200V26" src/ scripts/` returns **nothing** — no code anywhere is aware
of the vintage.

## 🔴 It only fires where the two maps DISAGREE

This is why it has stayed invisible. Where the old and new maps assign a point to the
same district number, both layers share a `geo_id`, join to the same `districts` row,
and collapse to one result. Measured:

| Point | House districts returned |
|---|---|
| Austin TX | **2** — CD-37 `[G5200]` + CD-10 `[G5200V26]` |
| Los Angeles CA | 1 — District 34 on both layers |
| Columbus OH | 1 — CD-15 on both layers |
| Miami FL | 1 — CD-27 on both layers |
| Seattle WA / Chicago IL | 1 — no `G5200V26` layer in those states |

So the blast radius is **the redrawn areas of 9 states**, not all of them — but those
are precisely the places where the answer matters most, and a sampling check that
happens to land on unchanged ground reports "fine".

## The decision this needs

Not a pure bug fix — a product call on what "your representative" means:

1. **One vintage wins.** Add `G5200V26` to the guard scoped to `NATIONAL_LOWER`, and
   pick which layer answers officeholder lookups. `G5200`/TIGER-2024 is the honest
   answer for *who represents you now*; `G5200V26` is the honest answer for *whose
   race is on your ballot*.
2. **Both, labelled.** Surface the sitting member and the 2026 ballot district as
   distinct things. Needs read-path and frontend work, not just a guard change.

Option 1 is a guard change plus a verification sweep across the 9 states. Option 2 is
the more truthful product but a bigger build. Either way the guard must stop treating
`G5200V26` as an unknown layer.

## Re-verify before acting

- Litigation moved the Texas map more than once; confirm plan C2333 is still the
  operative 2026 map before treating `G5200V26` as the ballot truth for TX.
- Re-run the point table above — it is the cheap detector, and Austin City Hall is a
  known-positive control for the disagreement case.
- Do NOT gate on a count of `G5200V26` rows; 173 polygons load fine either way. The
  test is whether a disagreement point returns one district or two.
