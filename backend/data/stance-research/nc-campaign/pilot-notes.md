# NC stance campaign — pilot batch notes (2026-08-24)

Task 3 of `.planning/workstreams/nc-stance-campaign/PLAN.md`. Three people, one per cohort,
selected by seat rather than by profile. Recorded here before any agent was dispatched.

## The three

| # | Name | politician_id | Seat | District | Scale |
|---|---|---|---|---|---|
| 1 | Eric Ager | `650f9783-8295-4947-bd8a-0c1cbf3b4c16` | State Representative | State House District 114 (`STATE_LOWER`) | `scale-state.txt` — 28 topics |
| 2 | Julie Mayfield | `5205c14a-a599-4f5f-abfd-505fe7e2ef07` | State Senator | State Senate District 49 (`STATE_UPPER`) | `scale-state.txt` — 28 topics |
| 3 | Matt Kopac | `903de6c5-aee9-45db-b29e-dfd34b3ee298` | Council Member, Ward 1 | Durham Citywide (`LOCAL`) | `scale-local.txt` — 22 topics |

## Why these three

The plan asks for one `STATE_LOWER`, one `STATE_UPPER` and one wave 2b local, chosen by seat, with
a preference for districts that share geography with wave 2b. None of the three holds a chamber
leadership post, because a pilot stacked with leadership overstates yield.

- **Ager** — HD 114 sits 100% inside Buncombe County. Rank-and-file member, so he is the closest
  thing the House cohort has to a median case.
- **Mayfield** — SD 49 sits 100% inside Buncombe County. Multi-term, not leadership. She is likely
  to be *better* documented than the median senator, so treat her row count as an upper estimate
  rather than a typical one. Task 4 must say so when it reports the measured yield.
- **Kopac** — a ward seat on Durham City Council. A council member is the most common local seat
  shape in wave 2b, and Durham is its largest body.

Buncombe supplies both state seats and Durham supplies the local, so the pilot covers both wave 2b
counties without spending three agents on one of them.

## Districts were matched by geometry, not by name

`geo_id` is **not unique** in `essentials.geofence_boundaries`. NC county FIPS `37021` (Buncombe)
and `37063` (Durham) are also the `geo_id`s of State House/Senate District 21 and State House
District 63. A join on `geo_id` alone silently matched Bladen and Alamance County members to Durham.
Discriminate with `mtfcc`:

| `mtfcc` | Layer |
|---|---|
| `G4020` | County |
| `G5210` | State upper (Senate) district |
| `G5220` | State lower (House) district |

## Wave 2b composition, confirmed against prod

32 people: Durham 15 (Durham County 8 + Durham Citywide 7), Asheville 7 (Asheville Citywide),
Buncombe 10 (Buncombe County 4 + Commissioner Districts 1/2/3, two seats each).

**Six of the 32 are administrative or law-enforcement officers** — Sheriff, Register of Deeds and
Clerk of Superior Court in each of Durham and Buncombe. Most of the 22 local topics ask about
policy those seats do not set. Expect a much lower yield from them, and expect blanks rather than
stretched chairs. Where a topic asks about a role the person neither holds nor seeks, the honest
result is no row at all.
