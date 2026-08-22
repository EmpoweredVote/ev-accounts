# Austin TX / Travis County deep seed — verified rosters (wave 1)

Verified 2026-08-18. **Step 0 output: no database writes were made to produce this file.**

Scope approved for wave 1: **City of Austin (11 seats) + Travis County elected executives (12 seats) = 23 offices.**
Deferred to wave 2: Travis County judiciary (~30 seats), 5 Justices of the Peace, 5 Constables, Austin ISD (9 trustees).

## Sources

| # | Source | What it establishes | Retrieved |
|---|---|---|---|
| S1 | `https://www.austintexas.gov/government` (raw HTML) | City roster: district `href` → member-name link text. **Structural mapping, not positional.** | 2026-08-18 |
| S2 | `https://www.traviscountytx.gov/images/docs/County-wide-Chart-6-22-2026.pdf` — org chart dated **June 15, 2026** | County roster; explicitly colour-codes which boxes are elected | 2026-08-18 |
| S3 | `https://votetravis.gov/candidates-office-holders/elected-officials/` — Travis County Clerk (election authority) | Independent second county roster + term lengths | 2026-08-18 |
| S4 | `https://en.wikipedia.org/wiki/Austin_City_Council` | City assumed-office dates, day precision | 2026-08-18 |
| S5 | `https://www.austintexas.gov/clerk/programs/history-council` — Austin City Clerk | Official city service-date ranges (year precision) | 2026-08-18 |
| S6 | `https://ballotpedia.org/Government_of_Travis_County,_Texas` | County assumed-office dates | 2026-08-18 |
| S7 | KUT `2026-06-03` + Community Impact `2026-05-26` | Gómez retirement; Morales appointment date | 2026-08-18 |
| S8 | `https://www.traviscountytx.gov/commissioners-court/precinct-four` | Morales' name form on his own official page | 2026-08-18 |

### Source defects found (do not silently re-trust)

- 🔴 **S6 (Ballotpedia) is STALE on Precinct 4** — still lists Margaret Gómez, assumed 1995. S2, S3 and S8 all say George Morales III. Official county publications win. This is the "detector, not oracle" rule.
- 🔴 **S1's `alt` attributes are unusable** — incomplete (D4 and D10 have no `alt`) *and* diacritic-stripped (`Jose Velasquez` for `José Velásquez`). The `member-name` link text is the reliable field. Same defect class as the Kitsap `alt`-off-by-one.
- ⚠ `votetravis.gov` is JS-rendered: `curl` returns **HTTP 200 with 0 bytes**. Must be rendered (Playwright). Not a WAF.
- ⚠ S3 prints the DA's formal title as "District Attorney, 53rd Judicial District"; S2 prints "District Attorney". Using the short form to match the existing Tarrant County template.

## City of Austin — `district_type='LOCAL'`

`label='City of Austin'` · `geo_id='4805000'` · `mtfcc='G4110'` · `state='tx'` · `city=NULL`

Geofence **already present** in `essentials.geofence_boundaries` (`Austin city`, state `48`, G4110). `geo_id 4805000` is unused by any existing district — no collision.

Titles follow the Fort Worth template exactly (`Mayor`, `Council Member District N`). All 11 offices share the single citywide geofence — Austin's 10-1 map is **not** modelled as per-district geometry, matching Fort Worth. An Austin address therefore returns all 10 council members. That is the existing convention, not a defect.

| Office title | `full_name` | term_start | precision | Term ends | Source |
|---|---|---|---|---|---|
| Mayor | Kirk Watson | 2023-01-06 | day | Jan 2029 | S1, S4, S6 |
| Council Member District 1 | Natasha Harper-Madison | 2019-01-07 | day | Jan 2027 | S1, S4, S5 |
| Council Member District 2 | Vanessa Fuentes | 2021-01-06 | day | Jan 2029 | S1, S4, S5 |
| Council Member District 3 | José Velásquez | 2023-01-06 | day | Jan 2027 | S1, S4 |
| Council Member District 4 | José "Chito" Vela | 2022-02-04 | day | Jan 2029 | S1, S4, S5 |
| Council Member District 5 | Ryan Alter | 2023-01-06 | day | Jan 2027 | S1, S4 |
| Council Member District 6 | Krista Laine | 2025-01-06 | day | Jan 2029 | S1, S4 |
| Council Member District 7 | Mike Siegel | 2025-01-06 | day | Jan 2029 | S1, S4 |
| Council Member District 8 | Paige Ellis | 2019-01-07 | day | Jan 2027 | S1, S4, S5 |
| Council Member District 9 | Zohaib "Zo" Qadri | 2023-01-06 | day | Jan 2027 | S1, S4 |
| Council Member District 10 | Marc Duchen | 2025-01-06 | day | Jan 2029 | S1, S4 |

**Term-date semantics.** `term_start` is the **start of continuous occupancy of this seat by this person**, not the start of the current 4-year term. Re-election does not end an occupancy. This is what makes `essentials.office_holders_as_of('2020-06-01')` correctly return Harper-Madison for D1 — CLAUDE.md's stated purpose for that function ("who represented me in 2019"). Recording 2023-01-06 for her instead would make that query wrongly report no holder.

Cross-check that pinned this: the 4-year stagger predicts exactly six seats sworn in 2025-01-06 (Mayor, D2, D4, D6, D7, D10) and five in 2023-01-06 (D1, D3, D5, D8, D9). Contemporaneous reporting names all six and all five individually. Watson also served as Mayor 1997–2001; that span is **non-continuous** and is deliberately not recorded.

Nickname forms `José "Chito" Vela` and `Zohaib "Zo" Qadri` keep the printed quoted nickname, normalised to straight double quotes. Precedent in `essentials.politicians`: `Abusana "Micky" Bondo`, `Adam "Ditch" Kurtz`.

## Travis County — `district_type='COUNTY'`

District row **already exists**: `label='Travis County'`, `geo_id='48453'`, `ocd_id='ocd-division/country:us/state:tx/county:travis'`, `state='tx'`, currently **0 offices**. Geofence already present (G4020). Do not create a district.

🔴 **`Austin County` (`geo_id 48015`) is a real and different Texas county already in our data.** Every statement in the migrations must key on `geo_id='48453'`, never on a label match against `%austin%`.

| Office title | `full_name` | term_start | precision | Source |
|---|---|---|---|---|
| County Judge | Andy Brown | 2020-11-17 | day | S2, S3, S6 |
| Commissioner, Precinct 1 | Jeffrey W. Travillion, Sr. | 2017-01-01 | **year** | S2, S3, S6 |
| Commissioner, Precinct 2 | Brigid Shea | 2015-01-01 | **year** | S2, S3, S6 |
| Commissioner, Precinct 3 | Ann Howard | 2021-01-01 | day | S2, S3, S6 |
| Commissioner, Precinct 4 | George Morales III | 2026-06-11 | day | S2, S3, S7, S8 |
| District Attorney | José Garza | 2021-01-01 | day | S2, S3, S6 |
| County Attorney | Delia Garza | 2021-01-01 | day | S2, S3, S6 |
| Sheriff | Sally Hernandez | 2017-01-01 | **year** | S2, S3, S6 |
| Tax Assessor-Collector | Celia Israel | 2025-01-01 | day | S2, S3, S6 |
| County Clerk | Dyana Limon-Mercado | 2023-01-01 | day | S2, S3, S6 |
| District Clerk | Velva L. Price | 2015-01-01 | **year** | S2, S3, S6 |
| County Treasurer | Dolores Ortega Carter | 1987-01-01 | **year** | S2, S3, S6 |

Rows marked **year** precision: S6 gave only a year. Per CLAUDE.md, pass January 1 of that year with `start_precision => 'year'` rather than inventing a day. Texas county terms do begin January 1, so the date is very probably exact — but the *source* gave a year, so the record says year.

**A County Treasurer exists.** This was an open question at design time (many Texas counties abolished the office); S2 and S3 both list Dolores Ortega Carter. Verified, not assumed.

**Name forms.** Where the county's own publications disagree in formality, the fuller printed form is used: S2 prints `Jeffrey W. Travillion, Sr.` and `George Morales III` where S3 prints `Jeff Travillion` and the commissioners-court index prints `George Morales`. Morales' own precinct page (S8) prints `George Morales III`. Precedent for suffixes in `essentials.politicians`: `Roderick Miles Jr`, `Michael D. Crain`.

🔴 **Two-surname / suffix trap.** Per the Puerto Rico wave (5-for-5 failure rate), do **not** gate the migration on a name rule. Gate on a SQL seat guard: assert 23 offices, each with exactly one `office_terms` row and `politician_id IS NOT NULL`.

### Precinct 4 succession

Margaret Gómez held Precinct 4 from 1995 and retired **early**, on 2026-06-11, after losing the ability to walk; she had originally intended to serve out her term to December 2026 (S7). George Morales III — who had already won the Democratic primary runoff on 2026-05-26 — was **appointed** the same day, 2026-06-11.

Consequences for the seed:
- Gómez is **not** being seeded, so there is no predecessor term for `seat_officeholder` to close. Her 1995–2026 occupancy is real history we are choosing not to backfill; this is an omission, not an assertion that the seat was empty.
- Morales' current occupancy is by **appointment** and runs only to the end of Gómez's term. He is unopposed in the 2026 general (2026-11-03), after which a fresh elected term begins 2027-01-01. **Recheck January 2027.**

## Occupancy model — how these get written

Use `essentials.seat_officeholder(office_id, politician_id, term_start, source)`. It writes an **open-ended** term (`term_end IS NULL`) and is idempotent.

Term-end dates are recorded in the city table above for reference but are **deliberately not written**. The documented lifecycle is: open-ended term, closed when a successor is seated (`seat_officeholder` closes the predecessor the day before) or when `vacate_office` is called. Writing a future `term_end` would make every one of these seats silently self-vacate in January 2027 or 2029 if no one updates them.

🔴 Do **not** use `term_end IS NULL` as a synonym for "current" when querying these rows — `office_current_holder` uses date containment, and fixed-term bodies elsewhere in the corpus carry real `term_end` values.

## Pre-existing drift observed in the Tarrant template (not fixed by this wave)

Worth a separate cleanup pass, reported rather than copied:

- 30+ `essentials.office_terms` rows under `Tarrant County` carry `start_precision='day'` with **`term_start IS NULL`** — incoherent, since `'day'` asserts a known day. The Fort Worth rows in the same seed correctly pair a NULL start with `start_precision='unknown'`.
- Tarrant County has **no** Sheriff, County Attorney, Tax Assessor-Collector, Treasurer or Constable offices, despite seeding 30 judicial seats. Its elected-executive tier is materially less complete than its judiciary.

Austin/Travis wave 1 writes real day- or year-precision starts for all 23 seats, so it does not reproduce the first defect.

## Portrait assets located (for the headshot step)

City — all 11 found on `austin.widen.net`. Filenames are district-labelled for 9 of 11; D4 and D10 are name-labelled (`Council_Jose_Chito_Vela_Crop.jpg`, `Council_Duchen_Marc_Crop2.jpg`). Unambiguous either way, but the mapping must be read from the surrounding card, not assumed from order.

| Seat | Asset |
|---|---|
| Mayor | `Austin Mayor - Web_mayor-headshot-optimized.jpg` |
| D1 | `Austin District 1 - Web_D1-Headshot.jpg` |
| D2 | `Austin District 2 - Web_vanessa-headshot-council.jpg` |
| D3 | `Austin District 3 - Web_jose-velasquez-headshot-opt.jpg` |
| D4 | `Austin City Council - Web_Council_Jose_Chito_Vela_Crop.jpg` |
| D5 | `Austin District 5 - Web_ryan-headshot.jpg` |
| D6 | `Austin District 6 - Web_laine-headshot-opt.jpg` |
| D7 | `Austin District 7 - Web_mike-headshot.jpg` |
| D8 | `Austin District 8 - Web_PJE-profiledetail-opt.png` |
| D9 | `Austin District 9 - Web_zo-headshot-opt.jpg` |
| D10 | `Austin City Council - Web_Council_Duchen_Marc_Crop2.jpg` |

Base URL form: `https://austin.widen.net/content/<id>/web/<filename>` — a Widen DAM. Query params (`?crop=yes&w=821&h=821`) control size; request without them, or at the largest offered width, for maximum resolution.

County — one confirmed so far: `/images/commissioners_court/Gmoralesheadshot.jpeg` (relative to `traviscountytx.gov`). The `commissioners_court` directory pattern is worth probing for the other four Commissioners Court members. Remaining 7 countywide officials not yet located.

⚠ A contact sheet is **required** before importing any of these. Legislator/official sites run a ~29% defect rate in this corpus and a contact sheet has caught something on every wave, including a wrong person.

## Banner candidate

`Austin City Council - Web_austin-city-hall-council.jpg` on the same Widen DAM — a City of Austin-published city hall photograph. Banners live in the **essentials** repo (`buildingImages.js` + Storage `cities/<slug>.jpg`), *not* `treasury.municipalities.hero_image_url`, which is dead. Version the filename; overwriting does not purge the CDN.

## Congressional districts covering Travis County (incidental finding, S3)

TX-10, TX-17, TX-21, TX-35, TX-37 — five congressional districts touch Travis County. All are already seeded, in both the 2020 and V26 boundary vintages. No action.
