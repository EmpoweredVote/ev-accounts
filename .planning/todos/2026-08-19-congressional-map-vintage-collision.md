# Two US Representatives for one address: the `G5200V26` vintage collision

**Created** 2026-08-19 · **Found while** wiring Austin council district geography (migration 1836)
**Scope** 9 states · **Severity** voter-facing wrong answer, silent

---

## ✅ FIXED — and re-measured 2026-10-25 against the memo's own control

**Option 1 was taken, and then some.** `G5200V26` now sits in `FALLBACK_EXCLUDED_MTFCCS` in
`geoIdGuard.ts`, so it never reaches the catch-all; the address path answers *who represents you
now* from `G5200` alone, and only `electionService.ts`'s opt-in join may resolve against the
2026 vintage — *whose race is on your ballot*. `essentialsBrowseService.test.ts` asserts the browse
helper's body does not even contain the token, and `geoIdGuard.test.ts` pins the exclusion list.

**The memo's own cheap detector, re-run against production 2026-10-25** (`/api/essentials/address-search`):

| Point | House seats returned | then | now |
|---|---|---|---|
| **Austin TX City Hall** — the known positive | **1** — Lloyd Doggett, CD-37 `[G5200]` | 2 | ✅ 1 |
| Los Angeles CA | 1 — Jimmy Gomez, District 34 | 1 | 1 |
| Columbus OH | 1 — Mike Carey, CD-15 | 1 | 1 |
| Kansas City MO | 1 — Emanuel Cleaver, CD-5 | — | 1 |

The known positive discriminates and has flipped; the three negatives did not move. **Everything
below this line is kept as the record of the defect, not as a description of today's code.** The
"Confirmed 2026-08-19: `grep -rn G5200V26` returns nothing" line in particular is now false — it
returns about 35 hits, which is the fix.

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

---

## 🔴 MISSOURI IS THE TENTH STATE, AND IT GOES THE OTHER WAY — added 2026-10-25

Missouri redistricted mid-decade in 2025 like the nine above. **It is deliberately NOT in
`G5200V26`, and it must stay out.** This is the case the memo did not anticipate: a new map that
was drawn, enacted, used for a primary — and then **struck down before the general**.

Supreme Court of the United States, *People Not Politicians v. Onder*, No. 26A388, per curiam,
**25 September 2026**, 609 U.S. ___ (2026), at 1:

> "In short, as a matter of state law, the 2022 map — not the 2025 map — must be used in the 2026
> congressional election."

quoting the Missouri Supreme Court's 3 September 2026 holding that the 2025 map **"is not the law
and has never been the law"** in Missouri. It takes effect only if voters approve it by referendum
— **Proposition A, on the 2026-11-03 ballot**.

So for Missouri the two questions this memo exists to separate have the **same** answer, and
`census_tiger_2024` / `G5200` / `2901`–`2908` is it.

### Three traps, in the order a session will hit them

1. ⚠ **THE CENSUS GEOCODER'S `120th Congressional Districts` LAYER SERVES THE 2025 MAP.** It puts
   414 E 12th St, Kansas City in **CD-4**; we answer **CD-5, Emanuel Cleaver**, and we are right.
   The Census layer is ahead of the courts. 🔴 **It is not an authority on which map governs an
   election.** This is backlog item 8, which spent a month asserting the opposite.
2. 🔴 **LOADING MO INTO `G5200V26` WOULD BREAK THE BALLOT SILENTLY.** `electionService.ts` prefers a
   2026-vintage polygon whenever one exists for a `NATIONAL_LOWER` geo_id, and falls back to the
   current vintage only when none does. MO has none, so elections resolve against the 2022 map,
   correctly. Load the 2025 map there and every Missouri race re-points at the blocked map with
   nothing erroring — **and it would look like helpful catch-up work, finishing a set of 9 that
   "should" be 10.** `CC_0290`'s precondition refuses to run while any MO `G5200V26` row exists.
3. ⚠ **THE PRIMARY AND THE GENERAL RAN ON DIFFERENT MAPS.** The same opinion, at 4: the Secretary
   of State *"chose to proceed with the 2025 map for the primary"*. So August's winners were chosen
   by 2025-map electorates and appear on 2022-map general ballots. Our data is right because the
   **Secretary of State's certification is keyed to the districts that govern the general** — do
   not reconcile a Missouri candidate to a district by reasoning from the primary.

### What it cost

Nothing, by luck. `1206` hedged by withholding the 5 most-changed districts behind a past-dated
marker election, and the hedge was correct either way — but **nobody un-withheld them when the
courts settled it**, so five of Missouri's eight U.S. House races, including Cleaver v. Brattin,
returned *no election at all* to an address until **nine days before the election**. Fixed by
`CC_0290`, 2026-10-25.

▶ **Dated follow-up, 2026-11-04: read the Proposition A result.** YES → Missouri joins the
`G5200V26` set for the **120th Congress**, a January-2027 change, and the whole of this memo's
option-1/option-2 question applies to it. NO → the 2022 map stands and Missouri is done.
