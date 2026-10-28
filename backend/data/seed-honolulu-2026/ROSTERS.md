# City and County of Honolulu — verified roster, 11 elected seats

Honolulu deep-seed program, **wave 1**. Compiled **2026-10-28**.

**11 seats, and that is the whole elected government:** 9 district council members + the Mayor +
the Prosecuting Attorney. There is nothing else to seed. Honolulu elects no clerk, no sheriff, no
treasurer, no assessor and no auditor — every one of those is appointed (charter ruling 3).

🔴 **THE CITY AND COUNTY OF HONOLULU IS THE ONLY LOCAL GOVERNMENT ON OAHU.** It is a consolidated
city-county covering the entire island plus every island not in another county. There is no
"City of Honolulu" beneath it and no municipality beside it. Hawaii has **no incorporated places
at all** (ruling 1) — a fact that decides this seed's `geo_id` and would silently corrupt it if
assumed otherwise.

**No party affiliation is recorded here or in the migrations.** The council, the Mayor and the
Prosecuting Attorney are elected on a **nonpartisan** ballot — the Office of Elections prints
these contests with no party letter at all, unlike every state legislative race on the same
sheet. Party lives on `races.primary_party`, never on an officeholder.

---

## Sources

| # | Source | Retrieved | What it establishes |
|---|---|---|---|
| S1 | `https://www.honolulucitycouncil.org/` — the council's own site; nine per-member pages under `/district-N-<surname>` | 2026-10-28 | All nine sitting members, by seat, each from the page's own `<title>`. Also the Chair, and the "Current Term" strings in defect 1. |
| S2 | Legislative Reference Bureau, *City and County of Honolulu* (`https://lrb.hawaii.gov/wp-content/uploads/CCHonolulu_guide.pdf`) | 2026-10-28 | The charter's structure: which offices are elected, term length, term limits, and the full appointed-officer list. State publication, not the city's own PR. |
| S3 | Hawaii Office of Elections certified summary, **2024 Primary**, `cch.pdf` — "FINAL", printed 08/19/2024 | 2026-10-28 | Districts I, III, V, VII, IX; Mayor; Prosecuting Attorney. All seven decided here. |
| S4 | Certified summary, **2024 General**, `cch.pdf` — "Final", printed 11/13/2024 | 2026-10-28 | **Carries no Honolulu council race at all.** The negative that proves S3 was final. |
| S5 | Certified summary, **2022 General**, `cch.pdf` — "Run 5", printed 11/16/2022 | 2026-10-28 | Districts II, IV, VI, VIII — the four even seats. |
| S6 | Certified summary, **2022 Primary**, `cch.pdf` | 2026-10-28 | Districts II, VI, VIII only. **District IV is absent**, which is what evidences ruling 5. |
| S7 | Certified summary, **2020 Primary** and **2020 General**, `cch.pdf` | 2026-10-28 | Continuous occupancy for Tupola, Kiaʻāina, Cordero, Tulba, Blangiardi and Alm. |
| S8 | Certified summary, **2026 Primary**, `cch.pdf` — "FINAL", printed 08/14/2026 | 2026-10-28 | Weyer and Okimoto re-elected outright; District IV forced to the general; District VI absent. |
| S9 | Office of Elections **2026 General Voter Guide** (English) | 2026-10-28 | The two Honolulu contests still live on 2026-11-03. ⚠ Candidate-submitted — see defect 3. |
| S10 | `https://www.honolulu.gov/elections/candidates/` — the City Clerk's own filing page | 2026-10-28 | That Districts **II, IV, VI and VIII** were the seats up in 2026. Settles that District VI's primary absence is not a seat that was never up. |
| S11 | HRS §12-41 and §12-42, current text from `capitol.hawaii.gov/hrscurrent/` | 2026-10-28 | The sole-candidate rule for county offices. |
| S12 | Hawaii Statewide GIS, `AdminBnd/MapServer/11` "Honolulu County Council Districts" | 2026-10-28 | The nine district polygons. Layer is the **2021 Reapportionment Commission** map, sourced from the city's Elections Division, April 2022. |
| S13 | TIGERweb `Places_CouSub_ConCity_SubMCD` layers 3 and 4, and `State_County` layer 1 | 2026-10-28 | That Hawaii has zero incorporated places and zero consolidated cities, and that Honolulu County is `15003` / `G4020` / FUNCSTAT A. |
| S14 | Prod query against `essentials.politicians` | 2026-10-28 | The identity scan in "Identity rulings". |

---

## Charter rulings

Each one decides a column, and none is guessable from another city.

**1. 🔴 Hawaii has NO incorporated places, so `mtfcc` CANNOT be `G4110`.** Measured against
TIGERweb (S13): the Incorporated Places layer returns **0** features for state 15, and the
Consolidated Cities layer returns **0**. The same query against California returns **483**, so the
query works and the zero is real. Honolulu is therefore keyed on the **county**:
`geo_id = '15003'`, `mtfcc = 'G4020'` — the Nashville/Indianapolis convention, not the
Anchorage/San Francisco one.

⚠ **This is the trap this seed most needed to avoid.** Both conventions are already live in prod,
so copying the nearest-looking precedent had even odds of being wrong, and `G4110` would have
pointed at a boundary that does not exist. The landing chip keys on `governments.geo_id` and
address search never touches it, so the city would have seeded cleanly, answered addresses, and
been invisible on the main page.

**2. Nine members, four-year terms, two-term limit, nonpartisan.** S2:

> legislative powers are vested in and exercised by the City Council, which consists of nine
> nonpartisan members elected to four-year terms. No council member may serve for more than two
> consecutive full terms.

So `chambers.official_count` is **9**.

**3. The elected set is exactly 11, and the appointed list is long.** S2 names the Salary
Commission's remit as "all elected City and County officials, including the Mayor, council
members, and Prosecuting Attorney" — and separately records the **City Clerk**, **City Auditor**
(six-year term), **Managing Director** and **Corporation Counsel** as appointed. Do not add county
row officers here out of habit; Honolulu has none.

**4. The Prosecuting Attorney is elected to four years and S2 says is NOT term-limited.** This is
the one asymmetry against the Mayor and council. ⚠ See defect 4 — a 2020 ballot question appears to
contradict it, and this seed does not resolve that.

**5. 🔴 THREE DIFFERENT THINGS CAN END A HONOLULU RACE AT THE PRIMARY, AND THEY ARE NOT THE SAME
RULE.** Getting this wrong misreads a term start by two to four months, or invents a runoff that
never happened.

- **A majority elects outright.** This is why S4 carries no council race: all five odd districts,
  the Mayor and the Prosecuting Attorney finished in August 2024.
- **A sole candidate is declared elected** under HRS §12-41(a) (S11), "regardless of the number of
  votes received", for any **county** office.
- **A two-candidate race skips the primary entirely and goes straight to the general.** Evidenced
  from the sheets themselves, not from commentary: District IV had exactly two candidates in 2022
  and is **absent from S6** while appearing in S5; District VI has exactly two candidates in 2026
  and is **absent from S8** while appearing in S9 and S10.

**6. Councilmembers take office on January 2.** District VII's page (S1) states it outright —
"Serving Since: Jan. 2, 2021" — and every other term string is consistent with it. So a member
elected in year *Y* starts `Y+1-01-02`.

**7. The Council Chair is a role, not a seat.** Tommy Waters is Chair (S1) and the council elects
its presiding officer from among the nine. It is **deliberately not modelled as an office** and not
written to any column: it moves between sitting members without an election, and caching it would
be the same mistake as caching "current".

---

## 🔴 Source defects found

**1. The council's own pages disagree with each other about the same term.** For the cycle elected
in 2022, District II reads `2023-2027` while Districts VI and VIII read `2022-2027`. Both describe
one term. The pages are inconsistent about whether the label means the election year or the year
service began. **Every `term_start` in this file comes from the certified results plus ruling 6,
not from these strings.**

**2. District IV's page reads `Current Term 2019-2027`, which is not a term.** Honolulu terms are
four years (ruling 2); this is eight. It is the page conflating *serving since* with *current
term*. Waters' current term began 2023-01-02; his continuous service began in 2019.

**3. ⚠ THE VOTER GUIDE IS CANDIDATE-SUBMITTED AND IS NOT THE BALLOT.** S9 lists Gregory and Ozawa
for District IV and does not list Waters. That is evidence those two are candidates. It is **not**
evidence that Waters is not one — the guide prints what candidates send it, and one entry in it
reads "No Photo Submitted". The actual reason Waters is off the general ballot is the court ruling
in identity ruling 2, which had to be established separately.

**4. The Prosecuting Attorney term-limit question is unresolved, and this seed does not resolve
it.** S2 states the office "is not subject to term limits". But S7's 2020 General sheet carries a
charter question, **"HONOLULU: Term Limits for Prosecuting Attorney"**, which passed
**294,387 YES (76.4%) to 59,589 NO (15.5%)**. Either S2 is stale or the question did something
narrower than its title. **`chambers.term_limit` is therefore left NULL for that chamber rather
than guessed.** A blank is correct; a wrong number would be asserted to voters.

**5. ⚠ THE PERCENTAGE COLUMN ON THE CERTIFIED SHEETS INCLUDES BLANK VOTES, SO A 50% TEST ON IT
LIES.** In S3, Esther Kiaʻāina's District III line reads **47.5%** — below a majority, which
predicts a November runoff. There was none, and S4 proves it. Her share of votes *cast for a
candidate* is **12,197 / 20,947 = 58.2%**, a clear majority. The printed denominator includes
4,720 blank and 26 over votes. Recomputed for every race in this file; it changes the reading for
District III and for no other.

**6. 🔴 `pdftotext` SILENTLY INTERLEAVES THESE SHEETS, AND A COORDINATE READER DID NOT FIX IT.**
The sheets are three newspaper columns. Both `pdftotext -layout` and a glyph-coordinate splitter
written for the job attributed a state-representative race's vote totals to a council candidate on
the same visual row. It does not error; it returns a plausible wrong number. **Every figure in this
file was read from the rendered page image**, not from extracted text. This is the Nashville
column-count failure in another costume.

**7. The district polygon layer excludes the Northwestern Hawaiian Islands.** S12 says so itself:
"This layer depicts Oahu land areas only". Those islands are legally in the City and County of
Honolulu and are uninhabited, so no address is affected — but the county's mapped area is not its
legal area.

---

## 🔴 Identity rulings

**1. All eleven are new rows. There are no collisions.** Scanned twice against prod (S14): once on
normalised last name, once as a substring sweep over `full_name` and `alternate_names` **including
archived rows**, because the duplicate-name guard keys on `(first_name, last_name)` and cannot see
a differently-split name. The sweep's positive control (`%waters%`) returned **27** rows, so it was
not blind. Everything it found is a different person or a California committee row: Carlos and
Karina Cordero; Allen, Courtney, David, Kevin, Mary and Maxine Waters; `PARDUE-OKIMOTO FOR
ASSEMBLY 2018`; Peter Sch**weyer**.

**2. 🔴 District IV is contested on 2026-11-03 and the sitting member is NOT on the ballot.** This
is the seat's second disputed election in eight years and both involve the same two people.

- The November 2018 District IV result was **invalidated by the Hawaii Supreme Court** and a
  court-ordered rerun held in April 2019, which Waters won. He was sworn in in **May 2019**, more
  than four months after the term began on January 2 — the seat was held on an interim basis until
  then.
- In 2026 Trevor Ozawa challenged Waters' eligibility for a third consecutive term, arguing the
  2019 rerun was the same regular term rather than a partial one. A judge ruled Waters **ineligible**;
  Waters has appealed to the Intermediate Court of Appeals, and the City Clerk has said votes for
  Waters will not be counted "unless modified by a subsequent court order".
- Waters nevertheless **polled second in the August 2026 primary (8,678, 28.2%)** and Gregory, third
  on 4,225, advanced in his place.

⚠ **This ruling is sourced from news reporting, and the two outlets disagree on the swearing-in day
(6 vs 8 May 2019).** So Waters' `term_start` is written `2019-05-01` at **month** precision. Do not
promote it to a day without a primary source. **Nothing about the appeal is written to the
database** — he holds the seat today, which is all the seed asserts.

---

## Roster

`ext_id` band: `-1500301` … `-1500311`. Councilmembers run in district order, then Mayor, then
Prosecuting Attorney.

**Every row is `is_incumbent = true` and `how_started = 'elected'`.** There is not one appointee.

| ext_id | district geo_id | district_type | office_title | full_name | first_name | last_name | aliases | term_start | precision | source |
|---|---|---|---|---|---|---|---|---|---|---|
| -1500301 | honolulu-hi-council-district-1 | LOCAL | Councilmember, District I | Andria Tupola | Andria | Tupola | — | 2021-01-02 | day | S1+S7 — won the 2020 primary outright, 14,420 of 24,229 candidate votes (59.5%) |
| -1500302 | honolulu-hi-council-district-2 | LOCAL | Councilmember, District II | Matt Weyer | Matt | Weyer | — | 2023-01-02 | day | S1+S5 — won the 2022 general 11,613 to Rothman's 9,268. Re-elected outright in the 2026 primary (S8) |
| -1500303 | honolulu-hi-council-district-3 | LOCAL | Councilmember, District III | Esther Kiaʻāina | Esther | Kiaʻāina | Esther Kiaaina | 2021-01-02 | day | S1+S7 — won the 2020 general 27,895 to Thielen's 19,143. Re-elected in the 2024 primary (S3, defect 5) |
| -1500304 | honolulu-hi-council-district-4 | LOCAL | Councilmember, District IV | Thomas Waters | Thomas | Waters | Tommy Waters | 2019-05-01 | **month** | S1+S5 — court-ordered April 2019 rerun; sworn in May 2019, day disputed (identity ruling 2). Re-elected 2022 general, 28,512 to Nakoa's 10,203 |
| -1500305 | honolulu-hi-council-district-5 | LOCAL | Councilmember, District V | Scott Y. Nishimoto | Scott | Nishimoto | Scott Nishimoto | 2025-01-02 | day | S1+S3 — won the 2024 primary outright, 13,399 of 18,839 candidate votes (71.1%). Succeeded Calvin K.Y. Say, who won D5 in 2020 (S7) |
| -1500306 | honolulu-hi-council-district-6 | LOCAL | Councilmember, District VI | Tyler Dos Santos-Tam | Tyler | Dos Santos-Tam | Tyler F. Dos Santos-Tam | 2023-01-02 | day | S1+S5 — won the 2022 general 13,496 to Toguchi's 11,247. On the 2026 general ballot (S9) |
| -1500307 | honolulu-hi-council-district-7 | LOCAL | Councilmember, District VII | Radiant Cordero | Radiant | Cordero | — | 2021-01-02 | day | S1 states "Serving Since: Jan. 2, 2021"; won the 2020 general 12,730 to Aki's 11,342 (S7) |
| -1500308 | honolulu-hi-council-district-8 | LOCAL | Councilmember, District VIII | Val Aquino Okimoto | Val | Okimoto | Val Okimoto | 2023-01-02 | day | S1+S5 — won the 2022 general 22,456 to Menor's 16,745. Re-elected outright in the 2026 primary (S8) |
| -1500309 | honolulu-hi-council-district-9 | LOCAL | Councilmember, District IX | Augusto E. Tulba | Augusto | Tulba | Augie Tulba, Augie T | 2021-01-02 | day | S1+S7 — won the 2020 general 21,265 to Espero's 19,702. **Ballot name is `TULBA, Augusto E. (AugieT)`; the council calls him Augie** |
| -1500310 | 15003 | COUNTY | Mayor | Rick Blangiardi | Rick | Blangiardi | — | 2021-01-02 | day | S7 — won the 2020 general 224,474 to Amemiya's 149,735. Re-elected outright in the 2024 primary, 125,076 of 160,302 candidate votes (78.0%) (S3) |
| -1500311 | 15003 | COUNTY | Prosecuting Attorney | Steven S. Alm | Steven | Alm | Steve Alm | 2021-01-02 | day | S7 — won the 2020 general 199,399 to Kau's 159,745. Re-elected in the 2024 primary on 127,367 as sole candidate (S3) |

### Names worth not flattening

- **Esther Kiaʻāina** carries an ʻokina (U+02BB) and a kahakō. The ballot prints `KIAAINA, Esther`,
  stripped. The council's spelling is the person's name; the ballot spelling is the alias.
  ⚠ The extraction pipeline for this seed raised `UnicodeEncodeError` on cp1252 the first time it
  touched this name — on Windows, a Hawaiian name will vanish rather than degrade.
- **Augusto E. Tulba** is the legal name on the certified sheet; "Augie" is what he is called
  everywhere including his own page.
- **Thomas "Tommy" Waters** — S1's own byline gives both.

---

## Counts, for the payload guard

| Group | Rows |
|---|---|
| `Councilmember, District <roman>` | 9, one per district, titles all distinct, **Roman numerals** |
| `Mayor` | 1 |
| `Prosecuting Attorney` | 1 |
| **Total offices** | **11** |
| Politicians inserted | **11** — no reused rows, no collisions (identity ruling 1) |
| `is_incumbent = true` | **11** |
| `how_started = 'appointed'` | **0** |
| `start_precision = 'month'` | **1** (District IV) |
| `start_precision = 'day'` | **10** |
| Serving since Jan 2021 | 5 — Tupola, Kiaʻāina, Cordero, Tulba, plus Blangiardi and Alm (6 incl. both) |
| Serving since Jan 2023 | 3 — Weyer, Dos Santos-Tam, Okimoto |
| Serving since Jan 2025 | 1 — Nishimoto |
| Serving since May 2019 | 1 — Waters |
| Districts with a polygon | 9 of 9 (S12) |

---

## ▶ Open items

1. 🔴 **2026-11-03 — two seats change or confirm, and one of them changes for certain.**
   District IV is Ozawa vs Gregory and **cannot** return the sitting member; District VI is
   Dos Santos-Tam vs Morihara. Winners take office **2027-01-02**, not on election night. Weyer
   (II) and Okimoto (VIII) are already re-elected and need no action.
2. **Defect 4 — the Prosecuting Attorney term limit.** `chambers.term_limit` is NULL pending a read
   of the actual 2020 charter amendment text.
3. **The Revised Charter itself was never read directly.** Every charter ruling above rests on S2,
   the Legislative Reference Bureau's guide. The city does not publish the charter at a stable URL
   that this pass could reach; `codelibrary.amlegal.com` returns 403 to a scripted request.
4. **Neighborhood boards are NOT seeded and are out of scope for wave 1.** Honolulu elects members
   to 33 advisory neighborhood boards. They are real elections, they are not legislative seats, and
   they would multiply this seed's row count by roughly forty. Flagged for a ruling, not assumed.
5. **The Hawaii State Legislature is entirely absent from prod** — 25 Senate and 51 House seats.
   This is not a Honolulu gap, it is a statewide one, but it means a Honolulu address currently
   returns federal, governor and city with a hole where its state legislators belong. The 2022
   district maps are layers 33 and 34 of S12.
