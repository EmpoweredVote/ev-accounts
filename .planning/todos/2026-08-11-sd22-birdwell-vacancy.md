# TX Senate District 22 — Birdwell seated on prod after resigning

## RESOLVED 2026-08-11 (same day) — vacated on prod (migration 1712), full TX roster diffed clean

- **SD-22 vacated.** Birdwell's open backfill term is closed `term_end = 2026-05-26`,
  `how_ended = 'resigned'`; office `ddd89781` is `is_vacant = true`, `vacant_since = 2026-05-27`.
  `office_current_holder` now returns a NULL holder for the seat. He keeps his `politicians` row
  and all **25** `inform.politician_answers` — this closed a tenure, it deleted nobody.
- **All four pre-checks ran and passed.** (1) The seat resolves 1:1 — but note `geo_id` 48022 is
  NOT unique, it also names **TX House District 22 (Christian Manuel, still seated)**; the
  migration keys on `(state, district_type, geo_id)`. (2) Date re-verified against a primary
  source: **lrl.texas.gov member 5678** lists his service as "Jan 10, 2023 - May 26, 2026",
  footnoting the 5/26/2026 letter to Gov. Abbott — so 2026-05-26 is his LAST day and 05-27 is the
  first vacant one. (3) No successor: senate.texas.gov returns 30 named senators, District 22
  shows "Constituent Services*". (4) Person and research confirmed intact.
- **🔴 The first draft's post-verify passed vacuously.** `essentials.office_current_holder`
  LEFT JOINs from `offices`, so it has **exactly one row per office always** — a vacancy is a NULL
  `politician_id`, not an absent row. `count(*) = 0` can never fire; assert
  `politician_id IS NULL`, and add `AND politician_id IS NOT NULL` to any seated-count join or it
  silently counts the vacant seat too. The dry run caught this.

## The sweep the todo asked for — done, and it came back clean

Diffed **all 181 seats** against the official rosters (house.texas.gov ships its roster as escaped
JSON inside `<get-members :members="...">`, where `id` is the district number; senate.texas.gov via
`member.php?d=N` link text). Result: **zero missing, zero extra, zero wrong-person** — every one of
150 House and 30 Senate seats matches, and SD-22 is vacant on both sides.

**SD-4 (Ligon) and SD-9 (Rehmet) were already correct in prod** — the concern below was unfounded;
they had been seated already.

25 seats differ in **name form only**, all the same person: middle initials (`Bernal, Diego M.`),
nicknames (`Guerra, R.D. "Bobby"` vs our `Robert Guerra`), short forms (Ben/Benjamin Bumgarner,
Wes/Wesley Virdell), dropped diacritics (`Gámez`/Gamez, `Anchía`/Anchia), and one dropped surname
(`Rodríguez Ramos, Ana-María` vs our `Ana-Maria Ramos`). **These are cosmetic, not occupancy** —
left alone deliberately. They are also the reason a name diff needs a proven comparator: it was
checked against 6 benign variations (must match) and 3 real differences including a one-character
change and a first-name swap (must flag) before being trusted.

**For the next state:** the comparator and both scrapers are the reusable part. Normalize with
`normalize(lower(x), NFD)` — **`unaccent` is not installed on prod** — then strip `[^a-z ]`, which
drops the combining marks as a side effect.

---
_Original writeup below._


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
