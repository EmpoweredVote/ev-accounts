# TX Senate District 22 — Birdwell seated on prod after resigning

Found 2026-08-11 while sourcing portraits for the TX legislature headshot wave (migration 1699).
He was the only one of 159 targets whose district had no member on the official roster, which is
what surfaced it — a photo sweep doubling as a vacancy detector, same as the 2026-07-12 bioguide
audit that caught LaMalfa and Swalwell.

## What is true

- **Brian Birdwell vacated SD-22 on 2026-05-26**, on taking the oath as Assistant Secretary of War
  for Sustainment. He had already announced (2025-06-30) that he would not seek re-election in 2026;
  the resignation is separate and earlier than the end of his term.
- `senate.texas.gov/members.php` lists District 22 as **"Constituent Services"**, and
  `senate.texas.gov/member.php?d=22` serves a member page with no member on it. Every other one of
  the 31 districts returns a named senator.
- Prod still has him on an **open `office_terms` row** — he resolves through
  `essentials.office_current_holder`, so he is a current officeholder everywhere that view reaches.

## Why it matters beyond one row

He carries researched stances, so this is a departed member rendering as a sitting senator on a
live Essentials profile. Deliberately **not** fixed in 1699 — that migration only writes portraits,
and seating/vacating is a different decision that wants its own post-verify.

## The fix, when someone takes it

`vacate_office` needs the **first VACANT day**, not the resignation day:

```sql
SELECT essentials.vacate_office(
  (SELECT o.id FROM essentials.offices o
     JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.label = 'TX Senate District 22'),      -- confirm this resolves to exactly one office
  DATE '2026-05-27',
  'senate.texas.gov roster 2026-08-11; resignation effective 2026-05-26');
```

Before running it:

1. **Confirm the office resolves 1:1.** `districts.geo_id` is not unique — key on
   `(geo_id, district_type)`. Assert one row, do not `LIMIT 1`.
2. **Re-verify the effective date against a primary source.** The 2026-05-26 date came from a
   secondary summary; the Secretary of State's or the Lt. Governor's own notice is the oracle, and
   a special-election proclamation will name the vacancy date precisely.
3. **Check whether a successor has since been seated.** If a special election has already been
   called or held, the right move is `seat_officeholder` for the winner (which closes the
   predecessor's term itself), not a standalone vacate.
4. Birdwell keeps his `politicians` row and his stances — this closes a *tenure*, it does not
   delete a person.

## Worth a sweep, not just a row

SD-4 (Brett Ligon) and SD-9 (Taylor Rehmet) are also names that postdate our seeding. They were not
in the headshot backlog, so this wave never checked them. **Run the full 181-seat TX roster against
`office_current_holder` and diff on name** — the scraper for it is the roster pass in migration
1699's trail. Same check is worth running for every state where we hold a full chamber.
