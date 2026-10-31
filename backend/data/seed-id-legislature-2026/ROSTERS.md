# Idaho Legislature — verified roster, 105 elected seats

**Wave:** Idaho deep seed (Boise / Ada County / legislature), 2026-10-30.
**Migrations:** `CC_0309` (structure), `CC_0310` (occupancy), `CC_0314` (portraits).

🔴 **EVERY SEAT IN THIS FILE TURNS OVER ON 2026-12-01.** Idaho Const. Art. III §3: senators and
representatives are "elected for the term of two years, **from and after the first day of December
next following the general election**". All 105 seats were on the 2026-11-03 ballot. This roster is
correct **today** and has a known expiry 32 days out. The re-seat is a `seat_officeholder` pass
against the certified results, not a re-import — see ▶ Open items.

## Sources

| # | Source | What it is | Pulled | File |
| --- | --- | --- | --- | --- |
| 1 | `legislature.idaho.gov/senate/membership/` | The Senate's own 2026 session directory | 2026-10-30 | `senate_members.html` |
| 2 | `legislature.idaho.gov/house/membership/` | The House's own 2026 session directory | 2026-10-30 | `house_members.html` |
| 3 | `ballotpedia.org/Idaho_State_Senate` | Independent roster + date assumed office | 2026-10-30 | `bp_senate.html` |
| 4 | `ballotpedia.org/Idaho_House_of_Representatives` | Independent roster + date assumed office | 2026-10-30 | `bp_house.html` |
| 5 | `legislature.idaho.gov/statutesrules/idconst/ArtIII/Sect3/` | Term-start rule, primary text | 2026-10-30 | `const3_3.html` |
| 6 | `legislature.idaho.gov/statutesrules/idconst/ArtIV/Sect1/` | The seven executive officers | 2026-10-30 | `const_art4.html` |

Parsers: `parse-roster.mjs` (sources 1–2 → `roster-legislature.json`), `diff-sources.mjs`
(1–2 vs 3–4), `_gen_rosters.mjs` (→ `roster-final.json`). Raw bytes were parsed throughout.
**No name, date or count in this file came from a `WebFetch` summary or a search-result snippet.**

## Structural rulings

🔴 **IDAHO'S HOUSE IS MULTI-MEMBER. 35 POLYGONS, 70 SEATS.** Each of the 35 legislative districts
elects one senator and **two** representatives — **Seat A** and **Seat B** — over the *same*
boundary. TIGER SLDU and SLDL are therefore both 35 polygons, and they carry the **same district
numbers**: all 12 pre-flight anchors returned an identical number from both layers. A seeder that
reads the SLDL polygon count as a seat count builds half a chamber and nothing errors.

🔴 **THE TWO SEATS ARE DISTINGUISHED BY OFFICE TITLE, NEVER BY DISTRICT CODE.** Unlike MN/MD/SD/ND,
Idaho has **no lettered district codes** — there is no `16A`. The loader's ID pre-flight asserts that
absence explicitly, so a future TIGER that started splitting them would abort rather than load.

⚠ `G5210` and `G5220` share a `geo_id` in Idaho — Senate District 19 and House District 19 are both
`16019`. **The key is the pair (mtfcc, geo_id)**, never `geo_id` alone.

## 🔴 Source defects found

1. **Two of 105 portrait filenames contain a literal space** — `Den Hartog3124.jpg` (Sen. Lori Den
   Hartog) and `Vander Woude67.jpg` (Rep. John Vander Woude). A `[A-Za-z'-]+` surname pattern missed
   both and returned `photo: null`, which reads as "the legislature publishes no portrait for them".
   Nothing errored. The per-chamber count check caught it, not the regex. Fixed; 105/105 now resolve.
2. **The city line is not always preceded by `<br />`.** Members who list a PO Box first have the
   city after an `&nbsp;`. The stricter pattern matched **51 of 105** and the other 54 came back
   null. Fixed; 105/105 now resolve.
3. **Ten name disagreements between the legislature and Ballotpedia, all formal-vs-common** — e.g.
   "Daniel D. Foreman" / "Dan Foreman", "Michael Leman Veile" / "Mike Veile", "Anne Henderson Haws" /
   "Annie Haws". **None is a different person**; every district, seat letter and party matched. The
   legislature's own formal rendering is used, and the common form belongs in `alternate_names`.

## Identity rulings

- **No seat is disputed.** Both sources return exactly 35 Senate and 70 House rows, with the same
  person in every (district, seat). Party split matches the Senate page's own stated totals
  (29 R / 6 D) and the House's (61 R / 9 D).
- **Freshness was tested as an absence, not assumed.** Rep. Wendy Horman resigned 2026-01-05 and
  Rep. Josh Andrus left in 2025. Both are **absent** from this roster and both replacements —
  Erin M. Bingham (32 B) and Michael Leman Veile (35 A) — are **present**. A roster that had gone
  stale would have failed that pair.
- **`term_start` is continuous occupancy, not the current term.** Ballotpedia's "date assumed
  office" is used because it carries the earlier arrival for appointees. 88 of 105 are a December 1;
  the other 17 are mid-term gubernatorial appointments (Idaho fills legislative vacancies by
  appointment, never by special election).
- **Four members have a year-only arrival** (Crane 2006, Boyle 2008, Palmer 2008, Anthon 2015).
  Those get `start_precision => 'year'` at `YYYY-01-01`. **No date is invented.**

## Roster

| Chamber | District | Name | Party | Home city | term_start | precision |
| --- | --- | --- | --- | --- | --- | --- |
| Senate | 1 | James W. "Jim" Woodward | Republican | Sagle | 2024-12-01 | day |
| Senate | 2 | Phil Hart | Republican | Kellogg | 2022-12-01 | day |
| Senate | 3 | Doug Okuniewicz | Republican | Hayden | 2022-12-01 | day |
| Senate | 4 | Ben Toews | Republican | Alene | 2022-12-01 | day |
| Senate | 5 | Carl J. Bjerke | Republican | Alene | 2022-12-01 | day |
| Senate | 6 | Daniel D. Foreman | Republican | Moscow | 2022-12-01 | day |
| Senate | 7 | Cindy J. Carlson | Republican | Riggins | 2022-12-01 | day |
| Senate | 8 | Christy Zito | Republican | Mountain Home | 2024-12-01 | day |
| Senate | 9 | Brandon Shippy | Republican | New Plymouth | 2024-07-18 | day |
| Senate | 10 | Tammy Nichols | Republican | Middleton | 2022-12-01 | day |
| Senate | 11 | Camille Blaylock | Republican | Caldwell | 2024-12-01 | day |
| Senate | 12 | Ben Adams | Republican | Nampa | 2022-12-01 | day |
| Senate | 13 | Brian Lenney | Republican | Nampa | 2022-12-01 | day |
| Senate | 14 | C. Scott Grow | Republican | Eagle | 2018-08-15 | day |
| Senate | 15 | Codi Galloway | Republican | Boise | 2024-12-01 | day |
| Senate | 16 | Alison "Ali" Rabe | Democrat | Boise | 2022-12-01 | day |
| Senate | 17 | Carrie Semmelroth | Democrat | Boise | 2021-11-30 | day |
| Senate | 18 | Janie Ward-Engelking | Democrat | Boise | 2014-01-08 | day |
| Senate | 19 | Melissa Wintrow | Democrat | Boise | 2020-12-01 | day |
| Senate | 20 | Josh Keyser | Republican | Meridian | 2024-12-01 | day |
| Senate | 21 | Treg A. Bernt | Republican | Meridian | 2022-12-01 | day |
| Senate | 22 | Lori Den Hartog | Republican | Meridian | 2014-12-01 | day |
| Senate | 23 | Todd M. Lakey | Republican | Nampa | 2022-12-01 | day |
| Senate | 24 | Glenneda Zuiderveld | Republican | Twin Falls | 2022-12-01 | day |
| Senate | 25 | Joshua Kohl | Republican | Twin Falls | 2024-12-01 | day |
| Senate | 26 | Ron C. Taylor | Democrat | Hailey | 2022-12-01 | day |
| Senate | 27 | Kelly Arthur Anthon | Republican | Rupert | 2015-01-01 | year |
| Senate | 28 | Jim Guthrie | Republican | McCammon | 2012-12-01 | day |
| Senate | 29 | James D. Ruchti | Democrat | Pocatello | 2022-12-01 | day |
| Senate | 30 | Julie VanOrden | Republican | Pingree | 2022-12-01 | day |
| Senate | 31 | Van T. Burtenshaw | Republican | Terreton | 2022-12-01 | day |
| Senate | 32 | Kevin Cook | Republican | Idaho Falls | 2022-12-01 | day |
| Senate | 33 | Dave Lent | Republican | Idaho Falls | 2018-12-01 | day |
| Senate | 34 | Doug Ricks | Republican | Rexburg | 2020-12-01 | day |
| Senate | 35 | Mark Harris | Republican | Soda Springs | 2022-12-01 | day |
| House | 1 A | Mark Sauter | Republican | Sandpoint | 2022-12-01 | day |
| House | 1 B | Cornel S. Rasor | Republican | Sagle | 2024-09-30 | day |
| House | 2 A | Heather Scott | Republican | Blanchard | 2022-12-01 | day |
| House | 2 B | Dale R. Hawkins | Republican | Fernwood | 2022-12-01 | day |
| House | 3 A | Vito Barbieri | Republican | Dalton Gardens | 2022-12-01 | day |
| House | 3 B | Jordan Redman | Republican | Alene | 2022-12-01 | day |
| House | 4 A | Joe Alfieri | Republican | Alene | 2022-12-01 | day |
| House | 4 B | Elaine Price | Republican | Alene | 2022-12-01 | day |
| House | 5 A | Ron Mendive | Republican | Alene | 2022-12-01 | day |
| House | 5 B | Tony Wisniewski | Republican | Post Falls | 2022-12-01 | day |
| House | 6 A | Lori Ann McCann | Republican | Lewiston | 2021-05-17 | day |
| House | 6 B | Brandon Mitchell | Republican | Moscow | 2022-12-01 | day |
| House | 7 A | Kyle Harris | Republican | Lewiston | 2024-12-01 | day |
| House | 7 B | Charlie Shepherd | Republican | Pollock | 2020-12-01 | day |
| House | 8 A | Robert "Rob" Beiswenger | Republican | Horseshoe Bend | 2024-12-01 | day |
| House | 8 B | Faye Thompson | Republican | McCall | 2024-12-01 | day |
| House | 9 A | John Shirts | Republican | Weiser | 2024-12-01 | day |
| House | 9 B | Judy Boyle | Republican | Midvale | 2008-01-01 | year |
| House | 10 A | Mike Moyle | Republican | Star | 2022-12-01 | day |
| House | 10 B | Bruce D. Skaug | Republican | Nampa | 2022-12-01 | day |
| House | 11 A | Kent A. Marmon | Republican | Caldwell | 2024-12-01 | day |
| House | 11 B | Lucas B. Cayler | Republican | Caldwell | 2024-12-01 | day |
| House | 12 A | Jeff J. Cornilles | Republican | Nampa | 2022-12-01 | day |
| House | 12 B | Jaron Crane | Republican | Nampa | 2022-12-01 | day |
| House | 13 A | Brent Crane | Republican | Nampa | 2006-01-01 | year |
| House | 13 B | Steven Tanner | Republican | Nampa | 2024-12-01 | day |
| House | 14 A | Ted Hill | Republican | Eagle | 2022-12-01 | day |
| House | 14 B | Josh Tanner | Republican | Eagle | 2022-12-01 | day |
| House | 15 A | Steve Berch | Democrat | Boise | 2018-12-01 | day |
| House | 15 B | Dori Healey | Republican | Boise | 2022-12-01 | day |
| House | 16 A | Soñia R. Galaviz | Democrat | Boise | 2022-12-01 | day |
| House | 16 B | Anne Henderson Haws | Democrat | Boise | 2025-07-22 | day |
| House | 17 A | John Gannon | Democrat | Boise | 2012-12-01 | day |
| House | 17 B | Megan Egbert | Democrat | Boise | 2024-05-07 | day |
| House | 18 A | Ilana Rubel | Democrat | Boise | 2014-01-08 | day |
| House | 18 B | Brooke Green | Democrat | Boise | 2018-12-01 | day |
| House | 19 A | Monica C. Church | Democrat | Boise | 2024-12-01 | day |
| House | 19 B | Chris Mathias | Democrat | Boise | 2020-12-01 | day |
| House | 20 A | Joe A. Palmer | Republican | Meridian | 2008-01-01 | year |
| House | 20 B | James Holtzclaw | Republican | Meridian | 2012-12-01 | day |
| House | 21 A | James Petzke | Republican | Meridian | 2022-12-01 | day |
| House | 21 B | Jeff Ehlers | Republican | Meridian | 2022-12-01 | day |
| House | 22 A | John Vander Woude | Republican | Nampa | 2012-12-01 | day |
| House | 22 B | Jason A. Monks | Republican | Meridian | 2012-12-01 | day |
| House | 23 A | Chris Bruce | Republican | Kuna | 2024-12-01 | day |
| House | 23 B | Shawn Dygert | Republican | Melba | 2024-12-01 | day |
| House | 24 A | Clint Hostetler | Republican | Twin Falls | 2024-12-01 | day |
| House | 24 B | Steve Miller | Republican | Fairfield | 2022-12-01 | day |
| House | 25 A | Don Hall | Republican | Twin Falls | 2025-12-12 | day |
| House | 25 B | David J. Leavitt | Republican | Twin Falls | 2024-12-01 | day |
| House | 26 A | Mike J. Pohanka | Republican | Jerome | 2024-12-01 | day |
| House | 26 B | Jack Nelsen | Republican | Jerome | 2022-12-01 | day |
| House | 27 A | Douglas T. Pickett | Republican | Oakley | 2022-12-01 | day |
| House | 27 B | Clay Handy | Republican | Burley | 2022-12-01 | day |
| House | 28 A | Richard W. "Rick" Cheatum | Republican | Pocatello | 2022-12-01 | day |
| House | 28 B | Dan Garner | Republican | Clifton | 2022-12-01 | day |
| House | 29 A | Dustin Manwaring | Republican | Pocatello | 2020-12-01 | day |
| House | 29 B | Tanya Burgoyne | Republican | Pocatello | 2024-12-01 | day |
| House | 30 A | David M. Cannon | Republican | Blackfoot | 2022-12-01 | day |
| House | 30 B | Ben G. Fuhriman | Republican | Shelley | 2024-12-01 | day |
| House | 31 A | Jerald Raymond | Republican | Menan | 2022-12-01 | day |
| House | 31 B | Rod Furniss | Republican | Rigby | 2022-12-01 | day |
| House | 32 A | Stephanie Jo Mickelsen | Republican | Idaho Falls | 2022-12-01 | day |
| House | 32 B | Erin M. Bingham | Republican | Idaho Falls | 2026-01-10 | day |
| House | 33 A | Barbara Ehardt | Republican | Idaho Falls | 2017-12-27 | day |
| House | 33 B | Marco Adam Erickson | Republican | Idaho Falls | 2020-12-01 | day |
| House | 34 A | Jon O. Weber | Republican | Rexburg | 2020-12-01 | day |
| House | 34 B | Britt Raybould | Republican | Rexburg | 2022-12-01 | day |
| House | 35 A | Michael Leman Veile | Republican | Soda Springs | 2025-09-24 | day |
| House | 35 B | Josh Wheeler | Republican | Ammon | 2022-12-01 | day |
## Counts, for the payload guard

| Measure | Value |
| --- | --- |
| Senate offices | 35 |
| House offices | 70 (35 districts x Seat A + Seat B) |
| Total offices | 105 |
| Total seated | 105 |
| Distinct districts | 35 |
| Portraits resolved | 105 / 105 |
| `start_precision = day` | 101 |
| `start_precision = year` | 4 |
| `start_precision = unknown` | 0 |

## Statewide executive — the two offices production was missing

Idaho Const. Art. IV §1 names **seven** executive officers; production held five. `CC_0311` added
the **State Controller** and the **Superintendent of Public Instruction** and seated them;
`CC_0315` gave both a portrait.

| Office | Holder | term_start | precision | Portrait |
| --- | --- | --- | --- | --- |
| State Controller | Brandon D. Woolf | 2012-10-15 | day (appointed) | `sco.idaho.gov`, 135x133 PNG |
| Superintendent of Public Instruction | Debbie Critchfield | 2023-01-02 | day (elected) | `sde.idaho.gov`, 900x900 WebP |

⚠ **THE CONTROLLER'S PORTRAIT IS 135x133 AND THAT IS NOT A SCRAPING ERROR.** It is the only size
any Idaho state source publishes. The SCO home page serves exactly one image of him; the
un-cropped and un-suffixed variants of that filename all 404; the office has no bio page;
Ballotpedia soft-404s on all four name forms tried (`/Brandon_Woolf`, `/Brandon_D._Woolf`,
`/Brandon_Woolf_(Idaho)`, `/Brandon_Woolf_(Idaho_Controller)`, each HTTP 200 with a
"does not exist" body); and Wikimedia Commons has nothing — its two hits for "Brandon Woolf" are
a 1910s genealogy book and an unrelated military exercise photograph. It upscales softly in the
4:5 frame but the face is centred and unmistakably his. ▶ Replace it if the office ever publishes
a larger one.

Both files are stored in their **native format** — one PNG, one WebP, neither re-encoded.
Production already carries 87 PNG and 22 WebP default images alongside the JPEGs.

Both pages' own `alt` attributes name the person *and* the office, which is the strongest
identity signal available for a portrait:
`alt="State Controller Brandon D Woolf Photo"` and `alt="Superintendent Debbie Critchfield headshot"`.

## ▶ Open items

- 🔴 **2026-12-01 — RE-SEAT ALL 105.** Terms run "from and after the first day of December next
  following the general election" (Const. Art. III §3). 99 of 105 incumbents sought re-election, so
  most rows survive unchanged; use `essentials.seat_officeholder`, which closes the predecessor's
  term. Do **not** re-run `CC_0309` — structure is already there.
- ⚠ Confirm each winner against the **certified** canvass, not election-night returns.
