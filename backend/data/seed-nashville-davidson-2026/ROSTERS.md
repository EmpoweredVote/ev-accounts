# Nashville / Davidson County — verified roster, 42 Metro seats

Nashville deep-seed program, **wave 1a**.
Spec: [`.planning/todos/2026-08-27-nashville-davidson-deep-seed.md`](../../../.planning/todos/2026-08-27-nashville-davidson-deep-seed.md)
Plan: [`docs/superpowers/plans/2026-08-27-nashville-wave-1a.md`](../../../docs/superpowers/plans/2026-08-27-nashville-wave-1a.md)

Compiled **2026-08-27**. Consumed by `scripts/gen-nashville-migrations.mjs`.

**42 seats:** 35 district council members + 5 at-large council members + Mayor + Vice Mayor. All
belong to ONE government — the Metropolitan Government of Nashville and Davidson County is a
consolidated city-county and has no separate county commission.

**No party affiliation is recorded here or in the migrations.** Every source below publishes it; it
is deliberately dropped. Party lives on `races.primary_party` — which ballot a voter requests —
never on an officeholder.

---

## Sources

| # | Source | Retrieved | What it establishes |
|---|---|---|---|
| S1 | `https://www.nashville.gov/departments/council/metro-council-members` — the council's own roster page (page states "Last updated: October 7, 2025") | 2026-08-27 | All 40 council members, by seat. Server-rendered. |
| S2 | `https://maps.nashville.gov/arcgis/rest/services/Elections/PoliticalDistricts/MapServer/0` — attributes `DISTRICT`, `Representative`, `FirstName`, `LastName` | 2026-08-27 | The 35 district members carried on the boundary layer itself, plus the authoritative first/last split. **Last edited 2023-09-22 / 2023-10-16 — frozen since the 2023 election.** |
| S3 | The 41 individual member pages under `https://www.nashville.gov/departments/council/districts/` | 2026-08-27 | Per-seat confirmation of the sitting member, independent of the roster page. Also the Vice Mayor's full name and prior service. |
| S4 | Certified results, `.../election-results/230803` (2023-08-03 general) and `/230914` (2023-09-14 runoff) | 2026-08-27 | **Who won each seat in 2023**, with vote totals. |
| S5 | Certified results, `.../election-results/190801` (2019-08-01 general) and `/190912` (2019-09-12 runoff) | 2026-08-27 | Who won each seat in 2019 — the continuity test. **Not listed in the site's own results index; reachable only by direct URL.** |
| S6 | Certified results, `.../election-results/150806` (2015-08-06 general) and `/150910` (2015-09-10 runoff) | 2026-08-27 | Proves no sitting member's occupancy reaches back to 2015, so the 2019 dates are evidenced rather than inferred from term limits. |
| S7 | Metropolitan Charter, Art. 3 sec. 3.03, Art. 5 sec. 5.05, Art. 15 sec. 15.01, and Tenn. Const. Art. VII sec. 5 as incorporated | 2026-08-27 | The Vice Mayor's role and vote; the 40 + mayor + vice mayor composition; the date terms are computed from. |
| S8 | `https://www.nashville.gov/departments/mayor` | 2026-08-27 | Freddie O'Connell is the sitting Mayor, and the page dates 2026-09-25 as the start of his third year in office. |
| S9 | Prod query against `essentials.politicians` | 2026-08-27 | The two identity collisions recorded below. |

---

## Charter rulings

Quoted from S7, because each one decides a column and none of them is guessable.

**1. The Vice Mayor is the presiding officer, and is NOT a voting member.** Sec. 3.03:

> The vice county mayor shall be the presiding officer of the council, but without vote therein,
> except in the event of a tie vote, when he may cast the deciding vote.

So the office is real and separately elected — the Asheville "Vice Mayor is only a board role"
precedent does not apply. But the charter's default is **no vote**, with a tie as the single
exception. **`offices.voting_powers` is therefore `non_voting`, not `full`**, and the tie-break power
is carried in `representation_note`.

⚠ This reverses the plan, which specified `full` before the charter had been read. `full` is not
defensible against the sentence above, and it has a second cost: both read paths gate the note on
`voting_powers <> 'full'`, so a `full` seat would carry an explanation that is never rendered.
`non_voting` states the charter's default accurately AND makes the explanation visible today,
without waiting for the wave 1c read-path change.

**2. The Council is 40, and the Vice Mayor is elected separately.** Sec. 15.01 provides for electing
"a mayor, vice-mayor, five (5) councilmen-at-large and thirty-five (35) district councilmen". So
`chambers.official_count` for the Metropolitan Council is **40**, and the Vice Mayor is a 41st office
in that chamber as its presiding officer — not one of the 40.

**3. Terms are computed from 1 September.** Art. 15 incorporates Tenn. Const. Art. VII sec. 5:

> The term of each officer so elected shall be computed from the first day of September next
> succeeding his election.

So every 2023 start is written `2023-09-01` and every 2019 start `2019-09-01`, at **month**
precision — a runoff winner is sworn in later in the same month, and no source gives a per-member
day. The one exception is the Mayor, whose own page dates his start to 2023-09-25 (day precision).

---

## 🔴 Source defects found

**1. S2 froze in 2023 and cannot report a change.** Its `last_edited_date` is 2023-09-22 for 33
districts and 2023-10-16 for two. It is a detector, not an oracle. Every seat was therefore checked
against S3 — the member's own page — and against S4. **All 35 district members, all 5 at-large
members, the Mayor and the Vice Mayor are the certified 2023 winners. No seat has changed hands by
appointment or special election since 2023.**

**2. S2 disagrees with itself on District 25.** `Representative` reads `Jeff Preptit`, `LastName`
reads `Prepit`. S1, S3 and S4 all read **Preptit**. The `LastName` field is simply wrong; it is not
recorded as an alias, because a source typo is not an alternate name.

**3. The member pages do not publish a service-start year.** Only District 20 and District 29 carry
an "Elected 2023" line. So nashville.gov cannot establish continuous occupancy, and the certified
results (S4, S5, S6) are the source for every `term_start` in this file.

**4. 🔴 The 2019 and 2023 certified results pages have DIFFERENT COLUMN COUNTS, and the difference
is silent.** 2023 is `Election Day | Absentee | Early | Total Votes`; 2019 and 2015 are
`Election Day | Absentee | Early | FS / PV | Total Votes | Percent`. A parser that assumes four
numeric columns and takes the last reads `FS / PV` on the older pages, which is 0 for nearly every
candidate. It does not error: every total comes back 0, the ranking degrades silently to
"first row listed", and the output still looks like a table of winners. The first run of
`_parse_results.py` reported Charles Flowers, Jr. as the 2019 winner of District 5 — Sean Parker won
it with 50.84%. Nine seats were wrong. The parser now reads the header row and locates
`Total Votes` by name.

**5. S5 and S6 are not in the site's own archive index.** The results index lists 13 elections,
beginning at 2016. The 2019 and 2015 Metro pages exist and are reachable by direct URL
(`/190801`, `/190912`, `/150806`, `/150910`). Anyone who trusts the index will conclude the data
does not exist.

---

## 🔴 Identity rulings

Both collisions were measured in prod on 2026-08-27 (S9). Neither is theoretical.

**1. `Robert Nash` — INSERT A NEW PERSON.** Prod holds `Robert Nash` at `external_id -5515005`, an
active **Village Trustee in Wisconsin** with a photo. District 27's Robert Nash is a different
person. A name-based insert guard would have inserted nothing, passed a 1:1 assertion, and seated a
Wisconsin village trustee on the Nashville Metro Council. This is wave 2's Mike Lee failure,
reproduced exactly, in this roster.

**2. `Mike Cortese` — REUSE THE EXISTING ROW `-470405`. SAME PERSON.** Prod holds `Mike Cortese` at
`external_id -470405`, `is_incumbent = true`, holding no office but standing as a candidate in the
**TN 2026 Statewide General** race for `U.S. Representative District 4`, alongside nine others in
`-470401..-470410`.

The tempting reading is the opposite one. Nashville is split between the 5th and 7th congressional
districts, not the 4th, so "TN-04 candidate" and "Council District 4" look like two different people
whose district numbers coincide. **That reading is wrong**, and the coincidence of the number 4 is
genuinely a coincidence — it is not what makes them the same person.

What settles it is the candidate's own statement in the Nashville Banner's 2026 candidate
questionnaire (`nashvillebanner.com/2026/07/16/mike-cortese-congress-tennessee-district-4/`,
retrieved 2026-08-27):

> **Political Experience:** I serve as the elected representative for District 4 on the Davidson
> County Metro Council

with the same page listing his occupation as "Adjunct Professor / Metro Councilman". He filed
originally in TN-05 and moved to TN-04 after Tennessee's May 2026 congressional redistricting, which
is why his campaign site still reads "Fifth Congressional District" on its landing page.

**Consequence for the migration:** District 4 carries `ext_id -470405`, not `-4730004`. The
politician INSERT must not create a second Mike Cortese, the seating join must resolve him by that
id, and the post-verify gate counts **41** people in the `-4730001..-4730042` band plus this one
outside it. Seeding him fresh would leave prod with two Mike Cortese rows: one holding the council
seat, one holding his photo and his candidacy.

---

## Roster

`ext_id` bands: district seats `-4730000 - N`; at-large `-4730036..-4730040` in the order S1 lists
them; Mayor `-4730041`; Vice Mayor `-4730042`. **District 4 is the one exception** — it carries the
pre-existing `-470405`, per identity ruling 2. `-4730004` is deliberately left unused.

| ext_id | geo_id | district_type | office_title | full_name | first_name | last_name | middle_initial | name_suffix | aliases | term_start | start_precision | how_started | source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| -4730001 | nashville-tn-council-district-1 | LOCAL | Council Member, District 1 | Joy Kimbrough | Joy | Kimbrough | - | - | Joy Smith Kimbrough | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730002 | nashville-tn-council-district-2 | LOCAL | Council Member, District 2 | Kyonzté Toombs | Kyonzté | Toombs | - | - | Kyonzte Toombs | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730003 | nashville-tn-council-district-3 | LOCAL | Council Member, District 3 | Jennifer Gamble | Jennifer | Gamble | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -470405 | nashville-tn-council-district-4 | LOCAL | Council Member, District 4 | Mike Cortese | Mike | Cortese | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 — REUSES the existing prod politician row; see identity ruling 2 |
| -4730005 | nashville-tn-council-district-5 | LOCAL | Council Member, District 5 | Sean Parker | Sean | Parker | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730006 | nashville-tn-council-district-6 | LOCAL | Council Member, District 6 | Clay Capp | Clay | Capp | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730007 | nashville-tn-council-district-7 | LOCAL | Council Member, District 7 | Emily Benedict | Emily | Benedict | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730008 | nashville-tn-council-district-8 | LOCAL | Council Member, District 8 | Deonté Harrell | Deonté | Harrell | - | - | Deonte Harrell | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730009 | nashville-tn-council-district-9 | LOCAL | Council Member, District 9 | Tonya Hancock | Tonya | Hancock | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730010 | nashville-tn-council-district-10 | LOCAL | Council Member, District 10 | Jennifer Frensley Webb | Jennifer | Webb | F | - | Jennifer F. Webb | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730011 | nashville-tn-council-district-11 | LOCAL | Council Member, District 11 | Jeff Eslick | Jeff | Eslick | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730012 | nashville-tn-council-district-12 | LOCAL | Council Member, District 12 | Erin Evans | Erin | Evans | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730013 | nashville-tn-council-district-13 | LOCAL | Council Member, District 13 | Russ Bradford | Russ | Bradford | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730014 | nashville-tn-council-district-14 | LOCAL | Council Member, District 14 | Jordan Huffman | Jordan | Huffman | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730015 | nashville-tn-council-district-15 | LOCAL | Council Member, District 15 | Jeff Gregg | Jeff | Gregg | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730016 | nashville-tn-council-district-16 | LOCAL | Council Member, District 16 | Ginny Welsch | Ginny | Welsch | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730017 | nashville-tn-council-district-17 | LOCAL | Council Member, District 17 | Terry Vo | Terry | Vo | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730018 | nashville-tn-council-district-18 | LOCAL | Council Member, District 18 | Tom Cash | Tom | Cash | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730019 | nashville-tn-council-district-19 | LOCAL | Council Member, District 19 | Jacob Kupin | Jacob | Kupin | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730020 | nashville-tn-council-district-20 | LOCAL | Council Member, District 20 | Rollin Horton | Rollin | Horton | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730021 | nashville-tn-council-district-21 | LOCAL | Council Member, District 21 | Brandon Taylor | Brandon | Taylor | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730022 | nashville-tn-council-district-22 | LOCAL | Council Member, District 22 | Sheri Weiner | Sheri | Weiner | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730023 | nashville-tn-council-district-23 | LOCAL | Council Member, District 23 | Thom Druffel | Thom | Druffel | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730024 | nashville-tn-council-district-24 | LOCAL | Council Member, District 24 | Brenda Gadd | Brenda | Gadd | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730025 | nashville-tn-council-district-25 | LOCAL | Council Member, District 25 | Jeff Preptit | Jeff | Preptit | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730026 | nashville-tn-council-district-26 | LOCAL | Council Member, District 26 | Courtney Johnston | Courtney | Johnston | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730027 | nashville-tn-council-district-27 | LOCAL | Council Member, District 27 | Robert Nash | Robert | Nash | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730028 | nashville-tn-council-district-28 | LOCAL | Council Member, District 28 | David Benton | David | Benton | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730029 | nashville-tn-council-district-29 | LOCAL | Council Member, District 29 | Tasha Ellis | Tasha | Ellis | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730030 | nashville-tn-council-district-30 | LOCAL | Council Member, District 30 | Sandra Sepulveda | Sandra | Sepulveda | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730031 | nashville-tn-council-district-31 | LOCAL | Council Member, District 31 | John Rutherford | John | Rutherford | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730032 | nashville-tn-council-district-32 | LOCAL | Council Member, District 32 | Joy Styles | Joy | Styles | - | - | - | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730033 | nashville-tn-council-district-33 | LOCAL | Council Member, District 33 | Antoinette Lee | Antoinette | Lee | W | - | Antoinette W. Lee | 2019-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4; held the seat continuously since 2019 per S5, and did not win it in 2015 per S6 |
| -4730034 | nashville-tn-council-district-34 | LOCAL | Council Member, District 34 | Sandy Ewing | Sandy | Ewing | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730035 | nashville-tn-council-district-35 | LOCAL | Council Member, District 35 | Jason Spain | Jason | Spain | - | - | - | 2023-09-01 | month | elected | S1+S2+S3 agree; won 2023 per S4 |
| -4730036 | 47037 | COUNTY | Council Member at-Large | Zulfat Suara | Zulfat | Suara | - | - | Z | 2019-09-01 | month | elected | S1+S3 agree; elected at-large 2023 per S4 (Suara outright in the general, the other four in the runoff); held an at-large seat continuously since 2019 per S5, and did not hold one in 2015 per S6 |
| -4730037 | 47037 | COUNTY | Council Member at-Large | Delishia Porterfield | Delishia | Porterfield | - | - | Delishia Danielle Porterfield | 2023-09-01 | month | elected | S1+S3 agree; elected at-large 2023 per S4 (Suara outright in the general, the other four in the runoff) |
| -4730038 | 47037 | COUNTY | Council Member at-Large | Quin Evans Segall | Quin | Evans Segall | - | - | Quin Evans-Segall | 2023-09-01 | month | elected | S1+S3 agree; elected at-large 2023 per S4 (Suara outright in the general, the other four in the runoff) |
| -4730039 | 47037 | COUNTY | Council Member at-Large | Burkley Allen | Burkley | Allen | - | - | - | 2019-09-01 | month | elected | S1+S3 agree; elected at-large 2023 per S4 (Suara outright in the general, the other four in the runoff); held an at-large seat continuously since 2019 per S5, and did not hold one in 2015 per S6 |
| -4730040 | 47037 | COUNTY | Council Member at-Large | Olivia Hill | Olivia | Hill | - | - | - | 2023-09-01 | month | elected | S1+S3 agree; elected at-large 2023 per S4 (Suara outright in the general, the other four in the runoff) |
| -4730041 | 47037 | COUNTY | Mayor | Freddie O'Connell | Freddie | O'Connell | - | - | - | 2023-09-25 | day | elected | S8 — the Mayor's own page dates 25 September 2026 as the start of his third year in office; won the 2023 runoff per S4 |
| -4730042 | 47037 | COUNTY | Vice Mayor | Angie Emery Henderson | Angie | Henderson | E | - | Angie E. Henderson | 2023-09-01 | month | elected | S3+S4 — won the vice mayoral race outright in the 2023 general, defeating the incumbent Jim Shulman; previously District 34 Council Member 2019-2023 per S5, which is a DIFFERENT seat |

---

## Counts, for the payload guard

| Group | Rows |
|---|---|
| `Council Member, District N` | 35, one per district, titles all distinct |
| `Council Member at-Large` | 5, **identical titles** — Nashville does not number the at-large seats |
| `Mayor` | 1 |
| `Vice Mayor` | 1 |
| **Total** | **42** |
| `how_started = 'appointed'` | **0** — every sitting member won their seat outright |
| ext_ids inside `-4730001..-4730042` | **41** |
| ext_ids outside the band | **1** — District 4, reusing `-470405` (identity ruling 2) |
| `start_precision = 'day'` | 1 (the Mayor) |
| Continuous since 2019 | 19 — 17 districts plus Suara and Allen at-large |
| Began 2023 | 23 |
