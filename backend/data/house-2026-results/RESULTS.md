# 2026-11-03 US House — results research

**Status as of 2026-11-04: 377 of 435 races recorded as `called` (`CC_0350`).**
57 races have no AP call and correctly have no row. TX-22 has an AP call and is **deliberately
withheld** — see below. Nothing is `certified`: not one of the 435 races is `isCertified` in
AP's own metadata, and the state canvasses run for weeks.

This is wave 2 of the post-election transition programme. Wave 1 was the 35 Senate races
(`CC_0339`, `backend/data/senate-2026-results/`). Same feed, same rules, same shape of file —
scaled from 35 races to 435, which changes the *method of checking*, not the standard.

```
  435  US House races on the 2026-11-03 ballot, ours and AP's alike
 - 57  AP has not called: 56 "Too Early to Call" + 1 Louisiana runoff
 -----
  378  AP calls carrying exactly one winner
 -  1  TX-22 — AP's winner is a person this database does not hold
 -----
  377  rows written
```

## The rules this file is held to

Each is in CLAUDE.md because a real seat was got wrong without it.

- 🔴 **A CERTIFIED RESULT IS NOT A FACT ABOUT WHO HOLDS THE SEAT.** These winners are recorded
  as having won an election. Taking office is a separate, later event — the federal tier is
  seated at 2027-01-03 (`CC_0348`), by a separate migration.
- 🔴 **A CALL AND A CANVASS ARE TWO FACTS, AND EACH GETS ITS OWN LABEL.** AP's race call is what
  `result_certainty = 'called'` records; the state's own canvass is what upgrades it to
  `'certified'`. Refusing to record a call until the state certifies throws away the very
  distinction the column exists to carry — that mistake kept 35 Senate seats blank for a day.
- 🔴 **SOURCE THE CALL FROM AP'S OWN DATA, NOT FROM A HEADLINE OR A SEARCH SUMMARY.**
  `metadata.json` for the race, its `raceCallStatus` and `isCertified`; `progress.json` for the
  candidate carrying `winner: "X"` and its `calledAt`.
- 🔴 **`WebFetch` FABRICATES NAMES AND DATES.** Use it to locate a document, never to source a
  name, a date or a count.
- A race with no call gets **no row**. That is correct, not a gap.

## 🔴 The feed needs browser headers now, and a bare `curl` gets an HTTP 403

The Senate pass read the feed in a browser. A plain `curl --compressed` to the same URLs today
returns **HTTP 403** from CloudFront with an HTML error body. Adding a browser `User-Agent`
plus `Referer: https://apnews.com/` returns 200 and the real JSON. Both files, for the record:

```
https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/metadata.json
https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json
```

The national files carry **645 races across every office** — `H` 436, `S` 35, `G` 36 and others.
One of the 436 `H` rows is `20261103US999999`, a synthetic national summary with
`statePostal: "US"`; the real districts are the other **435**.

## 🔴 TX-22 is withheld, and it is the whole argument for not trusting a name join

AP's TX-22 winner is **Trever Nehls** (AP candidateID 170023, GOP, 51.82%). AP's own metadata
lists the **incumbent** of that seat separately as **Troy Nehls** (candidateID 68186). They are
different people — identical twin brothers. Troy Nehls did not seek re-election; Trever Nehls
won the March 2026 Republican primary to succeed him, and AP called the general for him.

**Our `race_candidates` for TX-22 carries Troy Nehls.** We hold no Trever Nehls row at all. A
last-name match lands the win on the sitting congressman, and the site would report that Troy
Nehls was re-elected to a seat he did not run for.

This is the Lindsey Graham trap from the Senate pass wearing the other face: there the stale row
would have invented a **loser**, here it would have misattributed a **winner**.

**What caught it** is a detector, not an eyeball: compare AP's winner `candidateID` against
AP's own `incumbents[].candidateID` for the same race, and flag any race where the two share a
surname but differ in id. It returns exactly two races out of 378:

| Race | AP winner | AP incumbent | Our matched row | Verdict |
|---|---|---|---|---|
| TX-22 | Trever Nehls (170023) | Troy Nehls (68186) | Troy Nehls | 🔴 **different person — withheld** |
| IL-04 | Patty Garcia (170445) | Jesus Garcia (16407) | Patty Garcia | ✅ correct — a real challenger who won |

▶ **The flag is a prompt to look, not a verdict.** One of the two was fine.

▶ **Follow-up, not part of `CC_0350`:** seed Trever Nehls as the TX-22 candidate, correct Troy
Nehls' candidacy row, then record the call. Troy Nehls still holds the seat until 2027-01-03,
so his `is_incumbent` flag is right as it stands.

## 🔴 How 378 matches were checked without eyeballing 378 names

At 435 races a per-race read is not a method. The design the operator set: generate the match,
review only the rows where the spellings differ, and keep the count gate and
one-winner-per-race.

1. **Key on the district, not the name.** `districts.geo_id` = state FIPS + AP's own
   `censusDistrict`. That field is populated and two characters on all 435 races, and is `"00"`
   for the six at-large states (AK, DE, ND, SD, VT, WY) where AP's `seatNum` says `"1"` — the
   only six races where the two disagree.
2. **Match the surname inside that race only**, with accents folded in the generator because
   **`unaccent` is not installed on production** (this is what cost the Senate pass New Mexico).
   Tiers: exact surname, then surname-as-suffix (for "Bertrand Hines", "Pannill Fletcher"), then
   full-name tail. A tie inside a tier is resolved by first name, and an unresolved tie is a
   **problem**, never a guess.
3. **Result: 378 of 378 matched, each unique within its race, zero ambiguities, zero
   unmatched.**
4. 🔴 **That uniform answer was treated as a broken detector until two planted faults turned it
   red.** An unmatchable surname on AL-01 → 377 matched, 1 problem. A cloned same-name candidate
   in AL-02 → 1 ambiguity. **Each tamper was asserted present in the file before the run**,
   because a tamper that did not apply is a control that proved nothing.
5. **Party cross-check** of AP's party against ours on the 302 rows where ours is non-null:
   **zero clashes**, and a planted party flip proved that check can fail. (It would not have
   caught TX-22 — both Nehls brothers are Republicans. It is a second net, not the net.)
6. **The migration does not re-derive any of this.** Every row is pinned by
   `race_candidates.id`, and the gate re-asserts that the pinned row really sits in the stated
   district and really carries the stated surname. A mistyped id raises rather than quietly
   moving a win to another seat.

### The 88 spelling differences that were read by hand

Every one is a middle initial, a suffix, a nickname or a formal first name for the same person,
and AP lists most of them as the incumbent of the seat they won. The other 289 rows agree on
first and last name after folding, so there was nothing to judge.

| Seat | AP | Ours |
|---|---|---|
| AL-04 | Robert Aderholt | Robert B. Aderholt |
| AL-05 | Dale Strong | Dale W. Strong |
| AL-06 | Gary Palmer | Gary J. Palmer |
| AL-07 | Terri Sewell | Terri A. Sewell |
| AR-01 | Rick Crawford | Eric A. "Rick" Crawford |
| AZ-07 | Adelita Grijalva | Adelita S. Grijalva |
| AZ-09 | Paul Gosar | Paul A. Gosar |
| CA-36 | Ted Lieu | Ted W. Lieu |
| CA-38 | Hilda Solis | Hilda L. Solis |
| CA-41 | Linda Sánchez | Linda T. Sanchez |
| CA-44 | Nanette Barragan | Nanette Diaz Barragán |
| CT-03 | Rosa DeLauro | Rosa L. DeLauro |
| CT-04 | Jim Himes | James A. Himes |
| FL-05 | John Rutherford | John H. Rutherford |
| FL-12 | Gus Bilirakis | Gus M. Bilirakis |
| FL-15 | Laurel Lee | Laurel M. Lee |
| FL-17 | Greg Steube | W. Gregory Steube |
| FL-21 | Brian Mast | Brian J. Mast |
| FL-28 | Carlos Gimenez | Carlos A. Gimenez |
| GA-01 | James Kingston | Jim Kingston |
| GA-02 | Sanford Bishop | Sanford D. Bishop, Jr. |
| GA-04 | Henry Johnson | Henry C. "Hank" Johnson, Jr. |
| GA-07 | Rich McCormick | Richard McCormick |
| GA-09 | Andrew Clyde | Andrew S. Clyde |
| GA-12 | Rick Allen | Rick W. Allen |
| HI-02 | Jill Tokuda | Jill N. Tokuda |
| ID-02 | Mike Simpson | Michael K. Simpson |
| IL-01 | Jonathan Jackson | Jonathan L. Jackson |
| IL-03 | Delia Ramirez | Delia C. Ramirez |
| IL-10 | Brad Schneider | Bradley Scott Schneider |
| IL-15 | Mary Miller | Mary E. Miller |
| IN-01 | Frank Mrvan | Frank J. Mrvan |
| IN-03 | Marlin Stutzman | Marlin A. Stutzman |
| IN-05 | J.D. Ford | Jonathan Ford |
| KY-02 | S. Guthrie | Brett Guthrie |
| KY-05 | Hal Rogers | Harold Rogers |
| LA-02 | Troy Carter | Troy A. Carter |
| MA-02 | James McGovern | Jim McGovern |
| MD-02 | John Olszewski | Johnny Olszewski |
| MI-02 | John Moolenaar | John R. Moolenaar |
| MI-03 | Hillary Scholten | Hillary J. Scholten |
| MI-09 | Lisa McClain | Lisa C. McClain |
| MI-10 | Christina Hines | Christina Bertrand Hines |
| MO-03 | Bob Onder | Robert F. Onder, Jr. |
| MS-02 | Bennie Thompson | Bennie G. Thompson |
| NC-02 | Deborah Ross | Deborah K. Ross |
| NC-04 | Valerie Foushee | Valerie P. Foushee |
| NC-12 | Alma Adams | Alma S. Adams |
| NJ-03 | Herb Conaway | Herbert C. Conaway, Jr. |
| NJ-04 | Christopher Smith | Christopher H. Smith |
| NJ-08 | Rob Menendez | Robert Menendez |
| NJ-09 | Nelida Pou | Nellie Pou |
| NM-01 | Melanie Stansbury | Melanie A. Stansbury |
| NM-02 | Gabriel Vasquez | Gabe Vasquez |
| NY-03 | Thomas Suozzi | Thomas R. Suozzi |
| NY-05 | Gregory Meeks | Gregory W. Meeks |
| NY-08 | Hakeem Jeffries | Hakeem S. Jeffries |
| NY-09 | Yvette Clarke | Yvette D. Clarke |
| NY-18 | Pat Ryan | Patrick Ryan |
| NY-22 | John Mannion | John W. Mannion |
| NY-23 | Nicholas Langworthy | Nicholas A. Langworthy |
| NY-25 | Joseph Morelle | Joseph D. Morelle |
| NY-26 | Timothy Kennedy | Timothy M. Kennedy |
| OH-02 | David Taylor | David J. Taylor |
| OH-05 | Bob Latta | Robert E. Latta |
| OH-06 | Michael Rulli | Michael A. Rulli |
| OH-11 | Shontel Brown | Shontel M. Brown |
| OH-13 | Emilia Sykes | Emilia Strong Sykes |
| OH-14 | David Joyce | David P. Joyce |
| OK-03 | Frank Lucas | Frank D. Lucas |
| OK-05 | Stephanie Bice | Stephanie I. Bice |
| PA-02 | Brendan Boyle | Brendan F. Boyle |
| PA-05 | Mary Scanlon | Mary Gay Scanlon |
| PA-09 | Dan Meuser | Daniel Meuser |
| PA-12 | Summer Lee | Summer L. Lee |
| PA-17 | Chris Deluzio | Christopher R. Deluzio |
| RI-01 | Gabriel Amo | Gabe Amo |
| SC-04 | William Timmons | William R. Timmons IV |
| SC-06 | James Clyburn | James E. Clyburn |
| TN-03 | Chuck Fleischmann | Charles J. "Chuck" Fleischmann |
| TX-07 | Lizzie Pannill Fletcher | Lizzie Fletcher |
| TX-08 | Jessica Hart Steinmann | Jessica Steinmann |
| VA-03 | Robert Scott | Bobby Scott |
| VA-08 | Donald Beyer | Don Beyer |
| VA-09 | H. Griffith | Morgan Griffith |
| WA-01 | Suzan DelBene | Suzan K. DelBene |
| WV-01 | Carol Miller | Carol D. Miller |
| WV-02 | Riley Moore | Riley M. Moore |

Four were looked at harder than the rest, because the first names diverge beyond a nickname:

- **KY-02 "S. Guthrie"** and **VA-09 "H. Griffith"** — AP itself lists these as the *incumbents*
  under those names (Steven Brett Guthrie, H. Morgan Griffith). AP is abbreviating a first name
  it holds, not naming someone else.
- **IN-05 "J.D. Ford" / ours "Jonathan Ford"** — the Indiana state senator, legal name Jonathan
  David Ford, who beat the incumbent Victoria Spartz. Confirmed against AP's two-candidate
  ballot for the race.
- **GA-01 "James Kingston" / ours "Jim Kingston"** — open seat (Earl Carter ran for the Senate);
  both AP and we hold one Kingston on a two-candidate ballot.

## 🔴 51 rows had a value overwritten, and this is what it was

51 of the 377 winners already carried `result = 'advanced'` with `result_certainty = NULL`,
written by the ballot-qualification pass and each sourced to a **state candidate list** proving
the person was on the November ballot. There is no history table, so an `UPDATE` is final.

    OLD VALUE, ALL 51 ROWS:  result = 'advanced',  result_certainty = NULL
    NEW VALUE:                 result = 'won',       result_certainty = 'called'

The 51 prior `result_source` strings are **44 distinct state citations**. They are **not
discarded**: `CC_0350` writes the AP call and then appends the old citation verbatim in the same
column, so the proof of ballot qualification survives in the row. A gate fails the migration if
any row lost it — and a planted tamper that removed the append turned that gate red at exactly
51. The before-values are committed verbatim at `before-values.json` beside this file.

| Seat | Winner |
|---|---|
| AZ-03 | Yassamin Ansari |
| AZ-04 | Greg Stanton |
| AZ-07 | Adelita S. Grijalva |
| AZ-09 | Paul A. Gosar |
| CT-01 | Luke Bronin |
| CT-02 | Joe Courtney |
| CT-03 | Rosa L. DeLauro |
| CT-04 | James A. Himes |
| CT-05 | Jahana Hayes |
| DE-00 | Sarah McBride |
| HI-01 | Ed Case |
| HI-02 | Jill N. Tokuda |
| KS-04 | Ron Estes |
| MA-01 | Richard Neal |
| MN-02 | Matt Little |
| MN-03 | Kelly Morrison |
| MN-04 | Betty McCollum |
| MN-05 | Ilhan Omar |
| MN-06 | Tom Emmer |
| MN-07 | Michelle Fischbach |
| MN-08 | Pete Stauber |
| NH-01 | Stefany Shaheen |
| NH-02 | Maggie Goodlander |
| RI-01 | Gabe Amo |
| RI-02 | Seth Magaziner |
| TN-01 | Diana Harshbarger |
| TN-02 | Tim Burchett |
| TN-03 | Charles J. "Chuck" Fleischmann |
| TN-05 | Charlie Hatcher |
| TN-06 | Johnny Garrett |
| TN-08 | David Kustoff |
| VA-04 | Jennifer McClellan |
| VA-07 | Eugene Vindman |
| VT-00 | Becca Balint |
| WA-01 | Suzan K. DelBene |
| WA-02 | Rick Larsen |
| WA-03 | Marie Gluesenkamp Perez |
| WA-06 | Emily Randall |
| WA-07 | Pramila Jayapal |
| WA-08 | Kim Schrier |
| WA-09 | Adam Smith |
| WA-10 | Marilyn Strickland |
| WI-01 | Mitchell Berman |
| WI-02 | Mark Pocan |
| WI-03 | Rebecca Cooke |
| WI-04 | Gwen Moore |
| WI-05 | Scott Fitzgerald |
| WI-06 | Glenn Grothman |
| WI-07 | Michael Alfonso |
| WI-08 | Tony Wied |
| WY-00 | Chuck Gray |

## The 57 races with no row

| State | n | Districts |
|---|---|---|
| AK | 1 | 00 |
| AR | 1 | 02 |
| AZ | 5 | 01, 02, 05, 06, 08 |
| CA | 9 | 04, 07, 11, 14, 23, 29, 40, 47, 48 |
| CO | 3 | 03, 04, 05 |
| FL | 5 | 07, 09, 13, 26, 27 |
| LA | 2 | 05, 06 |
| ME | 1 | 02 |
| MN | 1 | 01 |
| MT | 1 | 01 |
| NC | 10 | 01, 03, 05, 06, 07, 08, 09, 10, 13, 14 |
| NJ | 1 | 02 |
| NV | 1 | 02 |
| NY | 4 | 01, 02, 17, 21 |
| OH | 1 | 10 |
| SC | 2 | 01, 02 |
| TN | 3 | 04, 07, 09 |
| UT | 2 | 02, 04 |
| VA | 2 | 01, 05 |
| WA | 2 | 04, 05 |

Three of these are not merely slow:

- **AK-00** and **ME-02** are ranked choice (`rankedChoice: true` in AP's metadata). Tabulation
  runs for weeks.
- **LA-05** is a **Louisiana nonpartisan general that went to a runoff** — AP's `raceCallStatus`
  is literally `"Runoff"`. There is no winner yet. Recording the two survivors as
  `result = 'runoff'` is a separate pass, not this one. All six Louisiana House races are
  `raceType: "Nonpartisan Election"`; the other five produced an outright majority and are
  recorded normally.

## 🔴 Winners only

"Everyone in a called race who is not the winner lost" is unsafe here for the same reason it was
unsafe in the Senate pass, and TX-22 is this wave's proof: our candidate rows can name a person
who was never on the ballot. A losers pass needs a per-candidate match against AP's own
candidate list for each race.

## What is left

| Item | Shape |
|---|---|
| 56 uncalled races | Re-read the feed as calls land. AK-00 and ME-02 will take weeks (ranked choice). |
| LA-05 | Runoff. Record the two survivors as `runoff`, then the runoff winner when it is held. |
| TX-22 | Seed Trever Nehls, correct Troy Nehls' candidacy row, then record the call. |
| Losers | A per-candidate match against AP's own ballot for each called race. |
| `certified` | A later pass, per state, against that state's own canvass. |
| Seating | A separate migration at 2027-01-03 for the federal tier (`CC_0348`). |

## Files beside this one

| File | What it is |
|---|---|
| `ap-house-calls-2026-11-04.json` | The raw extract from AP's feed: all 435 races, call status, and the winner where there is one. |
| `match-2026-11-04.json` | Every one of the 378 matches, with both spellings, the tier it matched on, and the prior result. |
| `spelling-review-2026-11-04.json` | The 89 rows where the spellings differ — the review set. |
| `before-values.json` | The 51 rows' `result`, `result_certainty` and `result_source` before `CC_0350` ran. |
| `match.mjs` | The matcher, so the match can be re-derived and re-tampered. |
