# Duvall + Redmond, WA — deep seed

**Status:** spec, awaiting approval. Nothing written yet.
**Author:** Chris Cantrell (namespace `CC_`).
**Scope ruling (Cantrell, 2026-10-06):** the two city governments only — offices, people, terms —
plus headshots and a banner for each. **No stances. No school, fire, port or hospital districts.**
**Steward claims:** `place:5319035` (Duvall), `place:5357535` (Redmond), both taken 2026-10-06.

---

## Why this is smaller than St. Louis or Nashville

Three of the four layers a deep seed normally builds already exist, measured against production
2026-10-06:

| Layer | State |
|---|---|
| State of Washington | 11 chambers, 156 offices — seeded |
| King County | 6 chambers, 14 offices, **all 14 seated** — seeded |
| WA legislative + congressional geography | 49 `sldu`, 49 `sldl`, 10 `cd` — loaded |
| **City of Duvall / City of Redmond** | **absent — no government, chamber, office or person** |

An address in either city already returns its state and county officials. Only the city layer is
missing.

### 🟢 There is NO geography wave. The polygons are already loaded.

`load-state-tiger-boundaries.ts` line 69 already carries `WA: new Set(['place', 'sldu', 'sldl'])`,
and both city polygons are in `essentials.geofence_boundaries` from `census_tiger_2024`:

| City | `geo_id` | `mtfcc` | Geometry | Area |
|---|---|---|---|---|
| Duvall city | `5319035` | `G4110` | `ST_Polygon` | 6.40 km² |
| Redmond city | `5357535` | `G4110` | `ST_MultiPolygon` | 44.65 km² |

Probed with PostGIS, not trusted from the loader's count:

- Duvall City Hall (−121.9857, 47.7423) → inside Duvall, **outside Redmond**
- Redmond City Hall (−122.1215, 47.6740) → inside Redmond, **outside Duvall**
- Chicago control (−87.6298, 41.8781) → inside neither

Areas agree with the published 2.47 and 17.2 square miles. **Do not re-run the TIGER loader.**
The district rows this seed creates point at these existing `(mtfcc, geo_id)` pairs.

---

## What the cities are

Both are Washington **code cities** with a mayor-council form and **at-large council positions**.
**Neither has council wards**, so no ward polygons are needed — every council district row is the
citywide `G4110` polygon, the shape Bainbridge Island and Seattle's at-large seats already use.

### Redmond — 8 seats

The city's own page (`/1300/Learn-About-Redmonds-City-Council`, retrieved 2026-10-06) states:

> Redmond has a mayor-council, non-partisan form of government, with a strong-mayor. Seven
> Councilmembers and the Mayor, all representing the community at large, are each elected directly
> by the people.

Roster from `Directory.aspx?did=33` (retrieved 2026-10-06) — **seven members, no position numbers
published**:

| Member | Leadership role |
|---|---|
| Jessica Forsythe | — |
| Vanessa Kritzer | — |
| Angie Nuevacamina | Council Vice President |
| Sayna Parsi | — |
| Vivek Prakriya | — |
| Menka Soni | — |
| Melissa Stuart | Council President |

Mayor: **Angela Birney**.

### Duvall — 8 seats

Roster and term expiries from `/166/City-Council` (retrieved 2026-10-06):

| Position | Member | Term expires |
|---|---|---|
| 1 | Adam Olen | December 2029 |
| 2 | Linda Conway | December 2027 |
| 3 | Sara Taylor | December 2029 |
| 4 | Ronn Mercer (Mayor Pro Tempore) | December 2027 |
| 5 | Mike Supple | December 2029 |
| 6 | Paul Wiggins | December 2029 |
| 7 | Jennifer Hernandez | December 2027 |

⚠ **Duvall has seven council positions, not the five a town of 8,400 would suggest.** This was
verified on the city's roster page; do not assume five.

Mayor: **Amy McHenry**. Her page states the term in words, which is the document a term start must
come from:

> Amy McHenry was elected Mayor of the City of Duvall in November, 2025. Her term will run from
> January 1, 2026, to December 31, 2029.

The same page states the council is "elected directly by the people for staggered 4-year terms,
representing the community at large".

**16 seats in total across the two cities.**

---

## 🔴 What is NOT yet established — resolve each before writing a migration

1. **Redmond position numbers.** The directory publishes names and leadership roles but **no
   position numbers**. Positions 1–7 must come from **King County Elections certified results**,
   keyed by position, not inferred from the directory's alphabetical order.
2. **The Redmond council vacancy.** The city advertised a council vacancy and later published
   "Redmond Completes City Council". One of the seven is an appointee. Three members carry
   sequential directory ids (1014, 1015, 1016), which is a hint and **not evidence**. Establish who
   was appointed, to which position, and on what date — an appointment date is not an election date.
3. **Term starts.** A term is the member's continuous occupancy of **that position**. "Term expires
   December 2027" gives the end, never the start. Walk King County Elections certified results back
   per position until the person is absent. Do not read "first elected" as a term start — it fails
   both ways.
4. **Elected municipal court judges.** Washington code cities above a threshold elect a municipal
   court judge. Redmond operates a municipal court; Duvall's court arrangement is unconfirmed. If a
   judge is elected, that is a seat and belongs in this seed. If the court is contracted to King
   County District Court, it is not.
5. **The Redmond Mayor's vote.** The city page says the Mayor "attends and presides over Council
   meetings but does not vote, except in the" — the sentence is truncated in the markup. Read the
   Redmond Municipal Code. If the Mayor presides without a vote, `offices.voting_powers` is **not**
   `full`, and `offices.representation_note` becomes **required** by the CHECK, exactly as the
   Nashville Vice Mayor ruling found. **Do not default this to `full`.**
6. **Leadership roles are not offices.** Redmond's Council President and Vice President, and
   Duvall's Mayor Pro Tempore, are elected **from among** the members. They are board roles, not
   separately elected seats — the Asheville precedent. They get **no `offices` row**; record them in
   the chamber or office description only.

---

## Waves

Each migration is idempotent, ends in a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a
wrong count, and is dry-run against production inside `BEGIN; ... ROLLBACK;` **with the rollback
confirmed to have reverted** before the real apply.

**Wave 1 — structure.** Two `governments` rows (with `geo_id` **and** `mtfcc` set, or the city is
invisible on the landing page even when fully seeded), their chambers, the citywide district rows
pointing at the existing polygons, and the offices. Gate: 16 offices, 0 outside Washington, every
district resolving to exactly one existing boundary.

**Wave 2 — occupancy.** People and terms through `essentials.seat_officeholder`. 🔴 Every insert
sets `politicians.is_incumbent` **explicitly** — it defaults to `false` now, and a seated person
inserted without it is hidden from address search. Gate: 16 seated, `offices_missing_terms`
unflagged still **239**, and a live probe — a Duvall address returns McHenry and the Duvall council;
a Redmond address returns Birney and the Redmond council; neither returns the other's; a Seattle
control returns neither.

**Wave 3 — headshots.** 🔴 `photo_custom_url` is what renders; a `politician_images` row alone
changes nothing a voter sees. Official and press sources only, no monochrome, approved on a contact
sheet with a **per-image `alt`** — a sheet without one is blind when the wrong person is plausible.
A blank beats a wrong face.

**Wave 4 — banners.** Two entries in `buildingImages.js` in the **essentials** repo, certified in the
6:1 band, with the Washington state banner read in the band first. Plus the two coverage chips, with
`hasContext` **omitted** — this seed writes no stances.

---

## Working rules for this seed

- **Own worktree**, since `C:\EV-Accounts` holds unrelated in-flight work on
  `feat/numeric-answer-scales`:
  `git worktree add -b seed/wa-duvall-redmond /c/ev-accounts-wa origin/master`.
- **Migration numbers are allocated, never counted**: `npm run steward --prefix backend -- slot CC
  --purpose "..."`, and the file is named that number immediately.
- **Commit with an explicit pathspec**: `git commit -F msg -- <path>`.
- **Squash-only since 2026-10-06** — the PR is the unit of history, so the PR body carries the
  detail.

## Measurements to re-take at the end

- `essentials.offices_missing_terms` unflagged — **239 before this seed**. It must still read 239.
- `npm run check:occupancy --prefix backend`
- `npm run check:migrations --prefix backend` after `git fetch origin`
