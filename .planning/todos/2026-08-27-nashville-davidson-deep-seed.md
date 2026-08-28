# Nashville / Davidson County deep seed

**Created** 2026-08-27 · **Status** designed, not started · **Author namespace** `CC_`
**Scope** the Metropolitan Government of Nashville and Davidson County — 35 council districts,
42 Metro seats, ~10 countywide elected officers, ~52 headshots, one city banner.
**Out of scope for wave 1** judicial seats, the MNPS school board, the TN General Assembly,
compass stances, 2027 candidates. Each is named at the bottom with what it would cost.

Every number in "Probe evidence" was measured on 2026-08-27 against prod and against Metro's own
GIS. The probe was read-only and its script was thrown away. Re-verify anything you are about to
act on — but do not re-derive the seven findings below, they cost real effort.

---

## Why this document exists

The obvious plan — "seed Nashville like we seeded Austin" — is wrong in three places, and each one
fails silently.

1. **Nashville has no county commission.** It is a consolidated city-county. Seeding a city body and
   a county body would invent a government that does not exist.
2. **The city polygon is the wrong polygon.** TIGER files Nashville as `4752006`, the *balance*,
   which excludes six satellite cities. Metro Council districts cover the whole county. Hanging Metro
   seats off the place polygon returns no representative for those addresses, and nothing errors.
3. **The county officers change five days after this was written.** Davidson County voted on
   2026-08-06 and the new terms start 2026-09-01. Seeding on 2026-08-27 writes about ten terms that
   expire the same week.

---

## Probe evidence (2026-08-27)

### 1. What prod holds for Tennessee

| Item | State |
|---|---|
| US House / US Senate / Governor | 9 + 2 + 1 offices, seeded |
| TN General Assembly (99 House, 33 Senate) | **absent** — no districts, no offices |
| County districts (`G4020`) | 95 rows, **0 offices** on every one |
| Davidson County TN (`47037`) | district row exists, 0 offices |
| TIGER `place` (`G4110`) for FIPS 47 | **not loaded** |
| TIGER `sldl` / `sldu` for FIPS 47 | **not loaded** |
| `essentials.governments` for TN | one row only: `State of Tennessee` |

Boundary layers present for state `47`: `G4020` 95, `G5200` 9, `G5200V26` 9, `G6350` 638.

### 2. Nashville is one government

The Metropolitan Government of Nashville and Davidson County has been consolidated since 1963. The
40-member Metro Council is both the city and the county legislature: 35 single-member districts plus
5 at-large members elected countywide. There is no county commission. The Mayor and the Vice Mayor
are elected countywide. The county constitutional officers are elected separately under state law.

### 3. Council districts cover the entire county — measured

Eight point-in-polygon probes against
`maps.nashville.gov/arcgis/rest/services/Elections/PoliticalDistricts/MapServer/0`:

| Point | Council district returned |
|---|---|
| Metro Courthouse `-86.7761, 36.1665` | 19 — Jacob Kupin |
| Belle Meade City Hall `-86.8583, 36.1006` | 23 — Thom Druffel |
| Goodlettsville City Hall `-86.7133, 36.3231` | 10 — Jennifer F. Webb |
| Berry Hill City Hall `-86.7657, 36.1183` | 26 — Courtney Johnston |
| Forest Hills `-86.8419, 36.0705` | 34 — Sandy Ewing |
| Oak Hill `-86.7856, 36.0663` | 25 — Jeff Preptit |
| Ridgetop `-86.7686, 36.3906` | 10 — Jennifer F. Webb |
| **Brentwood, Williamson County** `-86.7828, 35.9739` | **no match** |

The six satellite cities — Belle Meade, Berry Hill, Forest Hills, Goodlettsville, Oak Hill,
Ridgetop — sit inside Metro Council districts. Their residents elect the Metro Council.
🔴 **So the parent geography is the county polygon `47037`, never the TIGER place `4752006`.**

The Brentwood row is the control of the control. A query that cannot fire also returns nothing.

### 4. The council layer, and what it is good for

`Elections/PoliticalDistricts/MapServer`, layer 0 `Council Districts`, layer 1 `School Board Districts`.

- 35 polygons, one per district. 35 distinct `DISTRICT` values.
- Native spatial reference is **3857**. 🔴 `outSR=4326` is load-bearing — projected coordinates in a
  geographic column pass every count check and put the polygon in the wrong hemisphere.
- The layer publishes `Representative`, `FirstName`, `LastName`, `Email`, `Website` per district.
- `last_edited_date` is 2023-09-22 for 33 rows and 2023-10-16 for two. The layer has not been touched
  since the 2023 election. **Treat it as a detector, not an oracle.**
- The layer disagrees with itself on District 25: `Representative` says `Jeff Preptit`,
  `LastName` says `Prepit`. The council roster page settles it as **Preptit**.

### 5. Two independent sources agree on all 40 members

`https://www.nashville.gov/departments/council/metro-council-members` is server-rendered, returns the
full roster to `curl`, and was last updated 2025-10-07. It lists 5 at-large members and 35 district
members, and every district name matches the GIS layer. Read it as UTF-8 — Kyonzté Toombs and
Deonté Harrell carry diacritics that a Latin-1 read corrupts.

At-large as of that page: Zulfat Suara, Delishia Porterfield, Quin Evans Segall, Burkley Allen,
Olivia Hill.

⚠ Both sources are older than the seeding date. Every seat still gets checked for a vacancy or a
replacement since the last edit. The GIS layer froze in 2023, so it cannot report one.

### 6. 🔴 The county officers turn over on 2026-09-01

Davidson County held its general election on **2026-08-06**. On the ballot: Sheriff, Trustee, County
Clerk, Register of Deeds, Circuit Court Clerk, Criminal Court Clerk, Juvenile Court Clerk, Public
Defender, plus three special judicial elections. New terms begin **2026-09-01**.

Two officers were **not** on that ballot and must be dated from their own cycle, not from this one:
the Assessor of Property and the District Attorney General of the 20th Judicial District. Confirm
both cycles from the Election Commission before writing a term.

The Clerk and Master is appointed by the Chancery Court, not elected. It is excluded.

### 7. Identity and slot facts

- 🔴 **`Davidson County` exists twice** — NC `37057` and TN `47037`, identical label. Key on
  `(geo_id, district_type)`, never on a label.
- The `-47xxxxx` external_id band holds one row: `-4700001` Bill Lee, the Governor.
- Highest synthetic mtfcc in use is `X0034` (Buncombe). **Next free is `X0035`.**
- Bespoke layers use a slug `geo_id`, e.g. `buncombe-nc-commissioner-district-1`.
- Governments are named `City of Austin, Texas, US` / `Buncombe County, North Carolina, US`.
- Next free migration slot in the Cantrell namespace is **`CC_0004`**. Take numbers last, and verify
  against `origin/master` with `npm run check:migrations --prefix backend`.

---

## Design

### Geography

One new synthetic layer:

| Field | Value |
|---|---|
| mtfcc | `X0035` |
| rows | 35 |
| `geo_id` | `nashville-tn-council-district-1` … `-35` |
| `label` | `Nashville Metro Council District N` |
| `district_type` | `LOCAL` |
| `state` | `tn` |
| loader | `backend/scripts/load-davidson-council-boundaries.ts` |

The loader follows `load-buncombe-commissioner-boundaries.ts`. It passes `outSR=4326`, asserts 35
features, and asserts the returned coordinates fall inside the Davidson County polygon.

Everything countywide hangs off the **existing** `47037` COUNTY district. No TIGER `place` load is
needed and none is done. No matview refresh is needed: `check:child-county` defines children as
`mtfcc IN ('G4110','G5420','G5400','G5410')` and does not track `X%` layers at all.

### Government and chambers

One `governments` row: `Metropolitan Government of Nashville and Davidson County, Tennessee, US`.

| Chamber `name` | `name_formal` | Offices | District |
|---|---|---|---|
| Metropolitan Council | Metropolitan Council of Nashville and Davidson County | 41 | 35 × `X0035`, 6 × `47037` |
| Office of the Mayor | Office of the Mayor of Nashville and Davidson County | 1 | `47037` |
| Countywide Elected Officials | Davidson County Elected Officials | ~10 | `47037` |

`chambers.slug` is generated from `name_formal` and cannot be inserted. Getting `name_formal` wrong
yields a different slug silently.

The Vice Mayor sits in the Council chamber, because the office presides over the Council. That makes
the Council chamber 41 offices: 35 district + 5 at-large + Vice Mayor.

### Offices

- 35 district seats, titled `Council Member, District N`. Nashville numbers districts on the ballot.
- 5 at-large seats with **identical** titles, `Council Member at-Large`. Nashville does not number
  the at-large seats; the top five vote-getters win. Identical titles are correct here — prod already
  holds 468 `(district_id, title)` groups with more than one office.
- 🔴 **The multi-seat top-up must count by `(chamber_id, district_id)`, not by `chamber_id` alone.**
  The Council chamber spans 36 districts. Counting by chamber alone can land every seat on one
  district while reporting the right total. This is the `CA_0006` caveat, and it applies here.
- Metro offices set `representing_city = 'Nashville'` and `representing_state = 'TN'`. County officer
  offices set state only and leave city NULL, per the Austin rule.
  ⚠ **Known consequence:** a Belle Meade address will see the Nashville banner. That is judged
  correct, because Metro is that voter's city-county government, and no satellite city is seeded.
  Revisit if a satellite city is ever seeded.

### 🔴 The Vice Mayor, and the explanation problem it exposes

The Vice Mayor is elected countywide, presides over the Council, and **votes only to break a tie**.
So it is an office, not a board role — the Asheville Vice Mayor precedent does not apply.

`offices.voting_powers` offers `full`, `committee_only`, `non_voting`. None of the three states
"votes to break ties". The seat is written `full`, because the vote is real and only conditional, and
the conditional part is carried in `representation_note` in plain voter-facing language.

🔴 **But today that note would never be displayed.** Both read paths gate it on the powers value:

- `admin/src/pages/admin/FederalDelegationPanel.tsx:41` — `m.voting_powers !== 'full' && …`
- essentials `src/pages/Profile.jsx:136` — `powers !== 'full' && pol.representation_note`

So wave 1 includes a small read-path change: **render `representation_note` whenever it is present**,
and keep the amber `non-voting` / `committee-only` badge only for seats whose powers are not full.
This does not weaken ADR 0003 — a seat that is not full still requires a note, in the schema and in
the read path. It widens what a note is allowed to explain.

That change is also the foundation for the general case: how a seat is elected is not the same
question as what powers it has. Ranked-choice, at-large, staggered terms and runoffs all need an
explanation, and none of them is a `voting_powers` value. See "Follow-ups".

### Identity

`external_id` bands, all verified empty before use:

| Range | Contents |
|---|---|
| `-4730001 .. -4730035` | council district seats, by district number |
| `-4730036 .. -4730040` | at-large council seats |
| `-4730041` | Mayor |
| `-4730042` | Vice Mayor |
| `-4731001 .. -4731015` | countywide elected officers |

Politician inserts join on `external_id` **and** `full_name`, so a wrong pin drops the row rather than
seating the wrong person. A cross-state homonym assertion is mandatory before the insert: several
members carry common names, and `Davidson County` exists in two states. This is the Mike Lee lesson —
guarding on `full_name` alone would have seated a Utah senator on a North Carolina county commission.

### Terms

- `term_start` is the start of **continuous occupancy by that person**, not the start of the current
  term. Re-election does not end an occupancy. Several Metro members were first seated before 2023;
  each one needs its own start date.
- Where a source gives only a month or a year, `start_precision` says `month` or `year`. Do not invent
  a day. Where the start is genuinely unknown, write an open-ended term with `start_precision`
  `unknown`.
- No `term_end` is written. Writing a future `term_end` would make the seats silently self-vacate.
- Use `essentials.seat_officeholder(...)`; do not hand-roll the two-step.
- 🔴 An office with no `office_terms` row is invisible and nothing errors. After each migration,
  check `essentials.offices_missing_terms` against the 699-unflagged baseline.

---

## Waves

| Wave | Content | Slot | Gate |
|---|---|---|---|
| 1a-structure | `X0035` loader + 35 districts + government + 2 chambers + 42 Metro offices | `CC_0004` | structure only, no people |
| 1a-people | 42 Metro politicians + 42 terms | `CC_0005` | roster re-checked against both sources |
| 1b | `Countywide Elected Officials` chamber + ~10 officer offices + their people, `term_start` 2026-09-01 | `CC_0006` | **apply on or after 2026-09-01**, results certified |

🔴 **Offices and their people ship in the same wave, per tier.** An earlier draft of this table put
the officer *offices* in 1a and the officer *people* in 1b. That is wrong: an office with no
`office_terms` row is invisible, and the split would push `essentials.offices_missing_terms` above
its 699-unflagged baseline for the days between the two applies. Corrected 2026-08-27 while planning
wave 1a. Plan: [`docs/superpowers/plans/2026-08-27-nashville-wave-1a.md`](../../docs/superpowers/plans/2026-08-27-nashville-wave-1a.md).
| 1c | read-path change: render the note whenever present | admin + essentials repos | Vice Mayor note visible in the live render |
| 1d | ~52 headshots, one batch contact sheet | — | press / official / public-domain only |
| 1e | `cities/nashville.jpg` banner | essentials repo | certified in the 6:1 desktop band |

Migrations are idempotent, and each ends with a `DO $$ … $$` post-verify gate that raises on a wrong
count. Dry-run against prod first by wrapping the body `BEGIN; … ROLLBACK;` through `psql`, and
confirm the rollback reverted.

---

## Verification

Address probes, each paired with a control:

| Probe | Expect |
|---|---|
| Metro Courthouse | 42 Metro seats + the county officers + CD-5 |
| Belle Meade City Hall | the same 42 Metro seats — the satellite-city test |
| Brentwood, Williamson County | **zero** Metro seats — proves the query can fail |
| Goodlettsville City Hall | Metro District 10, and no Sumner County seat |

CI and local gates:

- `npm run check:migrations --prefix backend` — after `git fetch origin`
- `npm run check:occupancy --prefix backend`
- `npm run check:reachability` — a Nashville address must return a council member
- `essentials.offices_missing_terms`, unflagged count unchanged
- 🔴 A `workflow_dispatch` run covers only half the jobs. Run `migration numbering`,
  `answer-delete context guards`, `cal-access predicate tripwire` and `office occupancy` locally, or
  push to master, before trusting green.

---

## Follow-ups, with what each would cost

- **A general "how this seat is elected" explanation.** Ranked-choice, at-large, staggered terms,
  runoffs and tie-break votes are properties of an *election method*, not of a seat's powers. The
  wave 1c change makes `representation_note` able to carry them; it does not model them. A real model
  probably belongs on `districts` or in its own table, and needs its own ADR. Raised by Chris
  Cantrell on 2026-08-27 while approving this design.
- **Judicial seats**, about 30 — Circuit, Criminal, Chancery, General Sessions and Juvenile. Austin
  deferred its judicial tier the same way. Three were filled by special election on 2026-08-06.
- **MNPS Board of Education**, 9 seats — needs layer 1 of the same GIS service, a second synthetic
  mtfcc, and a second government. School districts **do** roll up in `geofence_child_county`, so this
  one needs a matview refresh, which `ev_api` cannot do.
- **TN General Assembly**, 132 seats — needs the TIGER `sldl` / `sldu` load for FIPS 47, absent
  today. State-scale, like NC wave 1.
- **Compass stances** for the 40 council seats on the LOCAL topic scale. Confirm the local topic
  list from `inform.compass_topic_roles` at the time; do not assume the count.
- **The six satellite cities** — Belle Meade, Berry Hill, Forest Hills, Goodlettsville, Oak Hill,
  Ridgetop — each has its own mayor and commission, and none is seeded. Goodlettsville and Ridgetop
  cross county lines.
