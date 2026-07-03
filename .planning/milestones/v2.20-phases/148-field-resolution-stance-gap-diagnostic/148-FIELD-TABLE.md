# Phase 148: Wave-1 US House Field Table + Stance-Gap Diagnostic

**Plan:** 148-02 | **Requirement:** USHC-01 | **Generated:** 2026-06-28
**Scope:** The verified Nov-3, 2026 general-ballot field for all 144 Wave-1 US House districts — **CA (52), TX (38), FL (28), NY (26)** — overlaid on the live DB incumbent map (Plan 148-01) and the 52 live CA general-race UUIDs.

This is the reviewable narrative companion to the machine-readable `148-field-table.csv` (13-column schema, consumed by Phases 149–151). It is the source of truth that prevents the milestone's two costliest traps — **duplicate incumbent records** and **surfacing a wrong/lost nominee** — and removes guessing from the CA seeding path.

## How the field was resolved

- **Field discovery:** Wikipedia `action=parse` API (per-district section list → per-district wikitext), bypassing the WebFetch TOC-only wall. CA/TX/NY general candidates read from each district's election infobox (`candidateN`/`nomineeN` + `partyN`); FL (pre-Aug-18 primary) read from the per-party `Declared`/`Nominee` qualified field (legally final — qualifying closed June 12, 2026).
- **Identity cross-check:** one paginated FEC `/v1/candidates` call per state (office=H, election_year=2026, registered key). FEC's `incumbent_challenge_full` is a cross-check only — never the source of who won the primary.
- **Incumbent map:** joined from `148-incumbent-map.csv` by **geo_id** (never a computed external_id; the scheme differs per state).
- **CA `existing_race_id`:** re-queried **live** from `essentials.races` JOIN `essentials.offices` (`races.office_id = offices.id`) JOIN `essentials.districts` (`offices.district_id = districts.id`) within the **"CA 2026 Statewide General"** election (`728d0074-…`), one live UUID per CA House geo_id 06NN. The query returned exactly **52** rows; no research-copied UUIDs.
- **`new_records_needed`:** general candidates with no existing `essentials.politicians` row. Renominated incumbents are excluded (they reuse `incumbent_pid`); previously-seeded figures (e.g. redistricted incumbents running in a new district) reuse their existing record.

## Per-state summary

| State | Districts | General candidates | New records needed | Incumbent stance tiers (zero / partial / done / vacant) | Renominated | Flagged (non-renominated) | Field status |
|-------|:---------:|:------------------:|:------------------:|:--------------------------------------------------------:|:-----------:|:-------------------------:|:------------:|
| CA | 52 | 104 | 38 | 36 / 7 / 9 / 0 | 43 | 9 | decided |
| TX | 38 | 76 | 48 | 37 / 0 / 0 / 1 | 25 | 13 | decided |
| FL | 28 | 181 | 155 | 0 / 27 / 0 / 1 | 20 | 8 | **provisional** |
| NY | 26 | 54 | 33 | 0 / 25 / 1 / 0 | 21 | 5 | decided |
| **Total** | **144** | **415** | **274** | — | **109** | **35** | — |

Notes:
- **CA/TX/NY field is decided** (primaries done — CA top-two June 2, TX March 3 + May 26 runoff, NY June 23–24). **FL is provisional** — the Aug-18 primary still narrows each party's qualified field; the FL rows list the full per-party qualified field and are re-checked in Phase 153.
- **FL `general_candidates` is the full qualified primary field** (not a two-name general), because FL has not yet held its primary. Each FL row therefore lists many new records; Phase 151 seeds the provisional field and Phase 153 prunes to the two general nominees post-primary.

## Non-incumbent-nominee flag list

Every district whose **seated incumbent is NOT the 2026 nominee in that geo_id** is flagged below with a citation, re-confirmed from the field source rather than trusting incumbency. These are the districts where the seeding phases must NOT reuse the incumbent as the active candidate.

#### incumbent-lost-primary (3) — incumbent defeated in the 2026 primary; do NOT surface as a candidate

| District | geo_id | Seated incumbent (DB) | Citation |
|----------|--------|------------------------|----------|
| TX-2 | 4802 | Dan Crenshaw | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_2 |
| NY-10 | 3610 | Daniel S. Goldman | https://www.axios.com/2026/06/24/dan-goldman-brad-lander-mamdani-new-york-primary |
| NY-13 | 3613 | Adriano Espaillat | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_13 |

#### incumbent-retired (17) — incumbent not seeking re-election / left to run for another office

| District | geo_id | Seated incumbent (DB) | Citation |
|----------|--------|------------------------|----------|
| CA-11 | 0611 | Nancy Pelosi | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_11 |
| CA-14 | 0614 | Eric Swalwell | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_14 |
| CA-26 | 0626 | Julia Brownley | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_26 |
| CA-48 | 0648 | Darrell Issa | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_48 |
| TX-8 | 4808 | Morgan Luttrell | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_8 |
| TX-10 | 4810 | Michael McCaul | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_10 |
| TX-19 | 4819 | Jodey Arrington | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_19 |
| TX-21 | 4821 | Chip Roy | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_21 |
| TX-37 | 4837 | Lloyd Doggett | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_37 |
| TX-38 | 4838 | Wesley Hunt | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_38 |
| FL-2 | 1202 | Neal P. Dunn | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_2 |
| FL-16 | 1216 | Vern Buchanan | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_16 |
| FL-19 | 1219 | Byron Donalds | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_19 |
| FL-24 | 1224 | Frederica S. Wilson | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_24 |
| NY-7 | 3607 | Nydia M. Velázquez | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_7 |
| NY-12 | 3612 | Jerrold Nadler | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_12 |
| NY-21 | 3621 | Elise M. Stefanik | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_New_York#District_21 |

#### incumbent-redistricted (12) — mid-decade redistricting (CA Prop 50 / TX) moved the incumbent to a different seat; they keep their record but get no active race_candidates row here

| District | geo_id | Seated incumbent (DB) | Citation |
|----------|--------|------------------------|----------|
| CA-3 | 0603 | Kevin Kiley | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_3 |
| CA-6 | 0606 | Ami Bera | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_6 |
| CA-38 | 0638 | Linda T. Sanchez | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_38 |
| CA-41 | 0641 | Ken Calvert | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_41 |
| TX-9 | 4809 | Al Green | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_9 |
| TX-30 | 4830 | Jasmine Crockett | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_30 |
| TX-32 | 4832 | Julie Johnson | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_32 |
| TX-33 | 4833 | Marc Veasey | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_33 |
| TX-35 | 4835 | Greg Casar | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_35 |
| FL-22 | 1222 | Lois Frankel | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_22 |
| FL-23 | 1223 | Jared Moskowitz | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_23 |
| FL-25 | 1225 | Debbie Wasserman Schultz | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_25 |

#### incumbent-deceased (1) — incumbent died in office; seat held via special election

| District | geo_id | Seated incumbent (DB) | Citation |
|----------|--------|------------------------|----------|
| CA-1 | 0601 | Doug LaMalfa | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_1 |

#### open-seat-vacancy (2) — DB-confirmed 0-holder; no incumbent record to reuse — all candidates are new records

| District | geo_id | Seated incumbent (DB) | Citation |
|----------|--------|------------------------|----------|
| TX-23 | 4823 | VACANT | https://www.cbsnews.com/news/tony-gonzales-drops-out-of-house-runoff-race-after-admitting-affair-with-aide/ |
| FL-20 | 1220 | VACANT | https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Florida#District_20 |


**Re-confirmation of inherited milestone claims (Assumptions A1–A2):**
- **NY-10 (3610) — Daniel S. Goldman: LOST primary.** Defeated by Brad Lander on June 24, 2026 (Axios, cited). Nominees: Brad Lander (D) vs Jennifer Moore (R). ✅ confirmed.
- **NY-13 (3613) — Adriano Espaillat: LOST primary.** Defeated by Darializa Avila Chevalier in the 2026 Democratic primary (Wikipedia "the incumbent was Democrat Adriano Espaillat … defeated in the 2026 Democratic primary by Darializa Avila Chevalier"). ✅ confirmed.
- **NY-7 (3607) — Nydia M. Velázquez: RETIRED.** Not seeking re-election; Claire Valdez (D) nominee. ✅ confirmed.
- **NY-12 (3612) — Jerrold Nadler: RETIRED.** Not seeking re-election; Micah Lasher (D) nominee. ✅ confirmed.
- **FL-20 (1220) & TX-23 (4823): open-seat vacancies** confirmed live as 0-holder offices (Plan 148-01).

**Uncalled races:** none. Every CA/TX/NY district resolved to a decided two-(or-more)-candidate general; no genuinely-uncalled NY race remained as of 2026-06-28.

## CA same-party (top-two) generals

CA is a jungle primary, so a district's two advancers can be same-party. These were read from results party-agnostically (not assumed one-D-one-R):

| District | Matchup | Advancers |
|----------|---------|-----------|
| CA-4 | D vs D | Mike Thompson (D); Eric Jones (D) |
| CA-7 | D vs D | Doris Matsui (D); Mai Vang (D) |
| CA-11 | D vs D | Connie Chan (D); Scott Wiener (D) |
| CA-12 | D vs D | Lateefah Simon (D); Jamie Joyce (D) |
| CA-14 | D vs D | Melissa Hernandez (D); Aisha Wahab (D) |
| CA-29 | D vs D | Luz Rivas (D); Angélica María Dueñas (D) |
| CA-34 | D vs D | Jimmy Gomez (D); Angela Gonzales-Torres (D) |
| CA-37 | D vs D | Sydney Kamlager-Dove (D); Samantha Mota (D) |
| CA-40 | R vs R | Ken Calvert (R); Young Kim (R) |

CA-40 is an R-vs-R general between two redistricted Republican incumbents (Calvert, DB-incumbent of CA-41, and Young Kim, DB-incumbent of CA-40). The CSV records both advancers with party on the race, never inferred.

## Stance-gap summary (carried from Plan 148-01)

Per-state incumbent stance coverage (live 2026-06-28), reproduced so Phases 149–151 scope incumbent top-up:

| State (FIPS) | Incumbents | zero | partial (1–23) | done (≥24) | min / max / avg |
|--------------|:----------:|:----:|:--------------:|:----------:|:----------------:|
| CA (06) | 52 | 36 | 7 | 9 | 0 / 29 / 7.5 |
| FL (12) | 27 | 0 | 27 | 0 | 6 / 23 / 14.6 |
| NY (36) | 26 | 0 | 25 | 1 | 4 / 24 / 15.8 |
| TX (48) | 37 | 37 | 0 | 0 | 0 / 0 / 0.0 |

CSV-wide top-up tiers across all 144 rows: **73 zero / 59 partial / 10 done / 2 vacant**. ~134/142 mapped incumbents are below the federal-24 bar (73 at zero) — incumbent stance top-up is a substantial 149–151 workstream, not incidental.

> **The full-24-vs-only-zeros top-up threshold is a Phase 149 scoping decision — NOT decided here.** Plan 148 emits the exact `incumbent_stance_count` + `incumbent_top_up_tier` per district; whether the milestone brings every incumbent to the full federal-24 set or only researches the zero-stance incumbents is set by the operator at Phase 149 plan time.

## Full per-district field table

| District | geo_id | Seated incumbent (DB) | Stance (count/tier) | nominee_status | general_candidates | new_records_needed | field_status |
|----------|--------|------------------------|:-------------------:|----------------|--------------------|--------------------|:------------:|
| CA-1 | 0601 | Doug LaMalfa | 0/zero | incumbent-deceased | James Gallagher (Republican); Mike McGuire (Democratic) | — | decided |
| CA-2 | 0602 | Jared Huffman | 0/zero | incumbent-renominated | Jared Huffman (Democratic); Robin Littau (Republican) | Robin Littau | decided |
| CA-3 | 0603 | Kevin Kiley | 0/zero | incumbent-redistricted | Ami Bera (Democratic); Robb Tucker (Republican) | Robb Tucker | decided |
| CA-4 | 0604 | Mike Thompson | 0/zero | incumbent-renominated | Mike Thompson (Democratic); Eric Jones (Democratic) | Eric Jones | decided |
| CA-5 | 0605 | Tom McClintock | 0/zero | incumbent-renominated | Tom McClintock (Republican); Michael Masuda (Democratic) | Michael Masuda | decided |
| CA-6 | 0606 | Ami Bera | 0/zero | incumbent-redistricted | Richard Pan (Democratic); Kevin Kiley (Independent) | Richard Pan | decided |
| CA-7 | 0607 | Doris Matsui | 0/zero | incumbent-renominated | Doris Matsui (Democratic); Mai Vang (Democratic) | — | decided |
| CA-8 | 0608 | John Garamendi | 0/zero | incumbent-renominated | John Garamendi (Democratic); Rudy Recile (Republican) | Rudy Recile | decided |
| CA-9 | 0609 | Josh Harder | 0/zero | incumbent-renominated | Josh Harder (Democratic); John McBride (Republican) | John McBride | decided |
| CA-10 | 0610 | Mark DeSaulnier | 0/zero | incumbent-renominated | Mark DeSaulnier (Democratic); Jeff Frese (Republican) | Jeff Frese | decided |
| CA-11 | 0611 | Nancy Pelosi | 0/zero | incumbent-retired | Connie Chan (Democratic); Scott Wiener (Democratic) | — | decided |
| CA-12 | 0612 | Lateefah Simon | 0/zero | incumbent-renominated | Lateefah Simon (Democratic); Jamie Joyce (Democratic) | Jamie Joyce | decided |
| CA-13 | 0613 | Adam Gray | 0/zero | incumbent-renominated | Adam Gray (Democratic); Kevin Lincoln (Republican) | Kevin Lincoln | decided |
| CA-14 | 0614 | Eric Swalwell | 0/zero | incumbent-retired | Melissa Hernandez (Democratic); Aisha Wahab (Democratic) | Melissa Hernandez | decided |
| CA-15 | 0615 | Kevin Mullin | 0/zero | incumbent-renominated | Kevin Mullin (Democratic); Charles Hoelter (Republican) | Charles Hoelter | decided |
| CA-16 | 0616 | Sam Liccardo | 0/zero | incumbent-renominated | Sam Liccardo (Democratic); Peter Sundin Soulé (Republican) | Peter Sundin Soulé | decided |
| CA-17 | 0617 | Ro Khanna | 0/zero | incumbent-renominated | Ro Khanna (Democratic); Ritesh Tandon (Republican) | Ritesh Tandon | decided |
| CA-18 | 0618 | Zoe Lofgren | 0/zero | incumbent-renominated | Zoe Lofgren (Democratic); Shane Lewis (Republican) | Shane Lewis | decided |
| CA-19 | 0619 | Jimmy Panetta | 0/zero | incumbent-renominated | Jimmy Panetta (Democratic); Peter Verbica (Republican) | Peter Verbica | decided |
| CA-20 | 0620 | Vince Fong | 0/zero | incumbent-renominated | Vince Fong (Republican); Sandra Van Scotter (Democratic) | Sandra Van Scotter | decided |
| CA-21 | 0621 | Jim Costa | 0/zero | incumbent-renominated | Jim Costa (Democratic); Kyle Kirkland (Republican) | Kyle Kirkland | decided |
| CA-22 | 0622 | David Valadao | 0/zero | incumbent-renominated | David Valadao (Republican); Randy Villegas (Democratic) | Randy Villegas | decided |
| CA-23 | 0623 | Jay Obernolte | 29/done | incumbent-renominated | Jay Obernolte (Republican); Tessa Lynn Hodge (Democratic) | Tessa Lynn Hodge | decided |
| CA-24 | 0624 | Salud Carbajal | 0/zero | incumbent-renominated | Salud Carbajal (Democratic); Bob Smith (Republican) | Bob Smith | decided |
| CA-25 | 0625 | Raul Ruiz | 0/zero | incumbent-renominated | Raul Ruiz (Democratic); Joe Males (Republican) | — | decided |
| CA-26 | 0626 | Julia Brownley | 20/partial | incumbent-retired | Jacqui Irwin (Democratic); Sam Gallucci (Republican) | Sam Gallucci | decided |
| CA-27 | 0627 | George Whitesides | 21/partial | incumbent-renominated | George Whitesides (Democratic); Jason Gibbs (Republican) | — | decided |
| CA-28 | 0628 | Judy Chu | 21/partial | incumbent-renominated | Judy Chu (Democratic); April Verlato (Republican) | — | decided |
| CA-29 | 0629 | Luz Maria Rivas | 17/partial | incumbent-renominated | Luz Rivas (Democratic); Angélica María Dueñas (Democratic) | Angélica María Dueñas | decided |
| CA-30 | 0630 | Laura Friedman | 21/partial | incumbent-renominated | Laura Friedman (Democratic); Scott Meyers (Republican) | — | decided |
| CA-31 | 0631 | Gil Cisneros | 0/zero | incumbent-renominated | Gil Cisneros (Democratic); Eric Ching (Republican) | — | decided |
| CA-32 | 0632 | Brad Sherman | 28/done | incumbent-renominated | Brad Sherman (Democratic); Larry Thompson (Republican) | — | decided |
| CA-33 | 0633 | Pete Aguilar | 21/partial | incumbent-renominated | Pete Aguilar (Democratic); Stephanie Vargas (Republican) | — | decided |
| CA-34 | 0634 | Jimmy Gomez | 21/partial | incumbent-renominated | Jimmy Gomez (Democratic); Angela Gonzales-Torres (Democratic) | — | decided |
| CA-35 | 0635 | Norma Torres | 28/done | incumbent-renominated | Norma Torres (Democratic); Mike Cargile (Republican) | — | decided |
| CA-36 | 0636 | Ted W. Lieu | 25/done | incumbent-renominated | Ted Lieu (Democratic); Houston Brignano (Republican) | — | decided |
| CA-37 | 0637 | Sydney Kamlager-Dove | 27/done | incumbent-renominated | Sydney Kamlager-Dove (Democratic); Samantha Mota (Democratic) | — | decided |
| CA-38 | 0638 | Linda T. Sanchez | 28/done | incumbent-redistricted | Hilda Solis (Democratic); Pedro Antonio Casas (Republican) | Hilda Solis; Pedro Antonio Casas | decided |
| CA-39 | 0639 | Mark Takano | 0/zero | incumbent-renominated | Mark Takano (Democratic); Steve Manos (Republican) | Steve Manos | decided |
| CA-40 | 0640 | Young Kim | 0/zero | incumbent-renominated | Ken Calvert (Republican); Young Kim (Republican) | — | decided |
| CA-41 | 0641 | Ken Calvert | 0/zero | incumbent-redistricted | Linda Sánchez (Democratic); Mitch Clemmons (Republican) | Linda Sánchez; Mitch Clemmons | decided |
| CA-42 | 0642 | Robert Garcia | 27/done | incumbent-renominated | Robert Garcia (Democratic); Brian Burley (Republican) | Brian Burley | decided |
| CA-43 | 0643 | Maxine Waters | 28/done | incumbent-renominated | Maxine Waters (Democratic); Cristian Morales (Republican) | Cristian Morales | decided |
| CA-44 | 0644 | Nanette Diaz Baragán | 0/zero | incumbent-renominated | Nanette Barragán (Democratic); Genevieve Angel (Republican) | Genevieve Angel | decided |
| CA-45 | 0645 | Derek Tran | 29/done | incumbent-renominated | Derek Tran (Democratic); Chuong Vo (Republican) | Chuong Vo | decided |
| CA-46 | 0646 | Lou Correa | 0/zero | incumbent-renominated | Lou Correa (Democratic); David Pan (Republican) | David Pan | decided |
| CA-47 | 0647 | Dave Min | 0/zero | incumbent-renominated | Dave Min (Democratic); Jenny Le Roux (Republican) | Jenny Le Roux | decided |
| CA-48 | 0648 | Darrell Issa | 0/zero | incumbent-retired | Jim Desmond (Republican); Marni von Wilpert (Democratic) | Jim Desmond | decided |
| CA-49 | 0649 | Mike Levin | 0/zero | incumbent-renominated | Mike Levin (Democratic); Armen Kurdian (Republican) | Armen Kurdian | decided |
| CA-50 | 0650 | Scott Peters | 0/zero | incumbent-renominated | Scott Peters (Democratic); Steve Cohen (Republican) | — | decided |
| CA-51 | 0651 | Sara Jacobs | 0/zero | incumbent-renominated | Sara Jacobs (Democratic); Richardo Cabrera (Republican) | Richardo Cabrera | decided |
| CA-52 | 0652 | Juan Vargas | 0/zero | incumbent-renominated | Juan Vargas (Democratic); Jeff Belle (Republican) | Jeff Belle | decided |
| TX-1 | 4801 | Nathaniel Moran | 0/zero | incumbent-renominated | Nathaniel Moran (Republican); Yolanda Prince (Democratic) | Yolanda Prince | decided |
| TX-2 | 4802 | Dan Crenshaw | 0/zero | incumbent-lost-primary | Steve Toth (Republican); Shaun Finnie (Democratic) | Shaun Finnie | decided |
| TX-3 | 4803 | Keith Self | 0/zero | incumbent-renominated | Keith Self (Republican); Evan Hunt (Democratic) | Evan Hunt | decided |
| TX-4 | 4804 | Pat Fallon | 0/zero | incumbent-renominated | Pat Fallon (Republican); Jason Pearce (Democratic) | Jason Pearce | decided |
| TX-5 | 4805 | Lance Gooden | 0/zero | incumbent-renominated | Lance Gooden (Republican); Chelsey Hockett (Democratic) | Chelsey Hockett | decided |
| TX-6 | 4806 | Jake Ellzey | 0/zero | incumbent-renominated | Jake Ellzey (Republican); Danny Minton (Democratic) | Danny Minton | decided |
| TX-7 | 4807 | Lizzie Fletcher | 0/zero | incumbent-renominated | Lizzie Fletcher (Democratic); Alexander Hale (Republican) | Alexander Hale | decided |
| TX-8 | 4808 | Morgan Luttrell | 0/zero | incumbent-retired | Jessica Steinmann (Republican); Laura Jones (Democratic) | Jessica Steinmann; Laura Jones | decided |
| TX-9 | 4809 | Al Green | 0/zero | incumbent-redistricted | Leticia Gutierrez (Democratic); Alex Mealer (Republican) | Leticia Gutierrez; Alex Mealer | decided |
| TX-10 | 4810 | Michael McCaul | 0/zero | incumbent-retired | Chris Gober (Republican); Caitlin Rourk (Democratic) | Chris Gober; Caitlin Rourk | decided |
| TX-11 | 4811 | August Pfluger | 0/zero | incumbent-renominated | August Pfluger (Republican); Claire Reynolds (Democratic) | Claire Reynolds | decided |
| TX-12 | 4812 | Craig Goldman | 0/zero | incumbent-renominated | Craig Goldman (Republican); Angela Rodriguez Prilliman (Democratic) | Angela Rodriguez Prilliman | decided |
| TX-13 | 4813 | Ronny Jackson | 0/zero | incumbent-renominated | Ronny Jackson (Republican); Mark Nair (Democratic) | Mark Nair | decided |
| TX-14 | 4814 | Randy Weber | 0/zero | incumbent-renominated | Randy Weber (Republican); Thurman Bartie (Democratic) | Thurman Bartie | decided |
| TX-15 | 4815 | Monica De La Cruz | 0/zero | incumbent-renominated | Monica De La Cruz (Republican); Bobby Pulido (Democratic) | Bobby Pulido | decided |
| TX-16 | 4816 | Veronica Escobar | 0/zero | incumbent-renominated | Veronica Escobar (Democratic); Adam Bauman (Republican) | Adam Bauman | decided |
| TX-17 | 4817 | Pete Sessions | 0/zero | incumbent-renominated | Pete Sessions (Republican); Casey Shepard (Democratic) | Casey Shepard | decided |
| TX-18 | 4818 | Christian Menefee | 0/zero | incumbent-renominated | Christian Menefee (Democratic); Ronald Whitfield (Republican) | Ronald Whitfield | decided |
| TX-19 | 4819 | Jodey Arrington | 0/zero | incumbent-retired | Tom Sell (Republican); Kyle Rable (Democratic) | Tom Sell; Kyle Rable | decided |
| TX-20 | 4820 | Joaquin Castro | 0/zero | incumbent-renominated | Joaquin Castro (Democratic); Edgardo Baez (Republican) | Edgardo Baez | decided |
| TX-21 | 4821 | Chip Roy | 0/zero | incumbent-retired | Mark Teixeira (Republican); Kristin Hook (Democratic) | Mark Teixeira; Kristin Hook | decided |
| TX-22 | 4822 | Troy Nehls | 0/zero | incumbent-renominated | Trever Nehls (Republican); Marquette Greene-Scott (Democratic) | Marquette Greene-Scott | decided |
| TX-23 | 4823 | VACANT | 0/vacant | open-seat-vacancy | Brandon Herrera (Republican); Katy Padilla Stout (Democratic) | Brandon Herrera; Katy Padilla Stout | decided |
| TX-24 | 4824 | Beth Van Duyne | 0/zero | incumbent-renominated | Beth Van Duyne (Republican); Kevin Burge (Democratic) | Kevin Burge | decided |
| TX-25 | 4825 | Roger Williams | 0/zero | incumbent-renominated | Roger Williams (Republican); Dione Sims (Democratic) | Dione Sims | decided |
| TX-26 | 4826 | Brandon Gill | 0/zero | incumbent-renominated | Brandon Gill (Republican); Steven Shook (Democratic) | Steven Shook | decided |
| TX-27 | 4827 | Michael Cloud | 0/zero | incumbent-renominated | Michael Cloud (Republican); Tanya Lloyd (Democratic) | Tanya Lloyd | decided |
| TX-28 | 4828 | Henry Cuellar | 0/zero | incumbent-renominated | Henry Cuellar (Democratic); Tano Tijerina (Republican) | Tano Tijerina | decided |
| TX-29 | 4829 | Sylvia Garcia | 0/zero | incumbent-renominated | Sylvia Garcia (Democratic); Martha Fierro (Republican) | Martha Fierro | decided |
| TX-30 | 4830 | Jasmine Crockett | 0/zero | incumbent-redistricted | Frederick Haynes III (Democratic); Everett Jackson (Republican) | Frederick Haynes III; Everett Jackson | decided |
| TX-31 | 4831 | John Carter | 0/zero | incumbent-renominated | John Carter (Republican); Justin Early (Democratic) | Justin Early | decided |
| TX-32 | 4832 | Julie Johnson | 0/zero | incumbent-redistricted | Dan Barrios (Democratic); Jace Yarbrough (Republican) | Jace Yarbrough | decided |
| TX-33 | 4833 | Marc Veasey | 0/zero | incumbent-redistricted | Colin Allred (Democratic); Patrick Gillespie (Republican) | Colin Allred; Patrick Gillespie | decided |
| TX-34 | 4834 | Vicente Gonzalez | 0/zero | incumbent-renominated | Vicente Gonzalez (Democratic); Eric Flores (Republican) | Eric Flores | decided |
| TX-35 | 4835 | Greg Casar | 0/zero | incumbent-redistricted | Johnny Garcia (Democratic); Carlos De La Cruz (Republican) | Johnny Garcia; Carlos De La Cruz | decided |
| TX-36 | 4836 | Brian Babin | 0/zero | incumbent-renominated | Brian Babin (Republican); Rhonda Hart (Democratic) | Rhonda Hart | decided |
| TX-37 | 4837 | Lloyd Doggett | 0/zero | incumbent-retired | Greg Casar (Democratic); Lauren Peña (Republican) | Lauren Peña | decided |
| TX-38 | 4838 | Wesley Hunt | 0/zero | incumbent-retired | Jon Bonck (Republican); Melissa McDonough (Democratic) | Jon Bonck; Melissa McDonough | decided |
| FL-1 | 1201 | Jimmy Patronis | 6/partial | incumbent-renominated | Douglas C. Chico (Republican); John Frankman (Republican); Jimmy Patronis (Republican); Gay Valimont (Democratic); Tyler Davis (Independent) | Douglas C. Chico; John Frankman; Gay Valimont; Tyler Davis | provisional |
| FL-2 | 1202 | Neal P. Dunn | 14/partial | incumbent-retired | Keith Gross (Republican); Lee Jones (Republican); Nick Lewis (Republican); Luke Murphy (Republican); Jim Norton (Republican); Evan Power (Republican); Austin Rogers (Republican); Audie Rowell (Republican); Yen Bailey (Democratic); Brice Barnes (Democratic); Amanda Green (Democratic); Nic Zateslo (Democratic) | Keith Gross; Lee Jones; Nick Lewis; Luke Murphy; Jim Norton; Evan Power; Austin Rogers; Audie Rowell; Yen Bailey; Brice Barnes; Amanda Green; Nic Zateslo | provisional |
| FL-3 | 1203 | Kat Cammack | 16/partial | incumbent-renominated | Kat Cammack (Republican); Troy Albers (Democratic); Seth Harp (Democratic); George Hubac (Democratic); Tom Wells (Democratic); Mike Klein (Independent) | Troy Albers; Seth Harp; George Hubac; Tom Wells; Mike Klein | provisional |
| FL-4 | 1204 | Aaron Bean | 14/partial | incumbent-renominated | Aaron Bean (Republican); LaShonda L.J. Holloway (Democratic); Michael Kirwan (Democratic); Brit Robinson (Democratic); Mike Sell (Democratic); Todd Schaefer (Independent) | LaShonda L.J. Holloway; Michael Kirwan; Brit Robinson; Mike Sell; Todd Schaefer | provisional |
| FL-5 | 1205 | John H. Rutherford | 13/partial | incumbent-renominated | John Rutherford (Republican); Mark Kaye (Republican); Rachel Grage (Democratic); Alex Hazen (Democratic); Mark Heggestad (Democratic) | Mark Kaye; Rachel Grage; Alex Hazen; Mark Heggestad | provisional |
| FL-6 | 1206 | Randy Fine | 11/partial | incumbent-renominated | Manuel Asensio (Republican); Aaron Baker (Republican); Dan Bilzerian (Republican); Randy Fine (Republican); Charles Gambaro (Republican); Robert Cooper (Democratic); Steve Morgan (Democratic); Ronnie Murchinson-Rivera (Democratic); Eric Yonce (Democratic); Andrew Parrott (Independent); Alec Pavlik (Independent) | Manuel Asensio; Aaron Baker; Dan Bilzerian; Charles Gambaro; Robert Cooper; Steve Morgan; Ronnie Murchinson-Rivera; Eric Yonce; Andrew Parrott; Alec Pavlik | provisional |
| FL-7 | 1207 | Cory Mills | 7/partial | incumbent-renominated | Ryan Elijah (Republican); Mike Johnson (Republican); Cory Mills (Republican); Sarah Ulrich (Republican); Bale Dalton (Democratic); Alan Grayson (Democratic); Marialana Kinter (Democratic); Christopher Dennison (Democratic) | Ryan Elijah; Sarah Ulrich; Bale Dalton; Alan Grayson; Marialana Kinter; Christopher Dennison | provisional |
| FL-8 | 1208 | Mike Haridopolos | 12/partial | incumbent-renominated | Mike Haridopolos (Republican); Jennifer Jenkins (Democratic) | Jennifer Jenkins | provisional |
| FL-9 | 1209 | Darren Soto | 17/partial | incumbent-renominated | Darren Soto (Democratic); Ben Butler (Republican); Marcus Carter (Republican); Thomas Chalifoux (Republican); Dan Green (Republican); Jorge Martinez (Republican); Steve Rance (Republican); Justin Story (Republican) | Ben Butler; Marcus Carter; Thomas Chalifoux; Dan Green; Jorge Martinez; Steve Rance; Justin Story | provisional |
| FL-10 | 1210 | Maxwell Frost | 9/partial | incumbent-renominated | Maxwell Frost (Democratic) | — | provisional |
| FL-11 | 1211 | Daniel Webster | 15/partial | incumbent-renominated | Carey Baker (Republican); Ivette Palomo (Republican); Nizam Razack (Republican); Joe Strada (Republican); Tim Wilkins (Republican); James Pericola (Democratic); Royal Webster (Democratic); Dan Williams (Democratic); Ralph Groves (Democratic) | Carey Baker; Ivette Palomo; Nizam Razack; Joe Strada; Tim Wilkins; James Pericola; Dan Williams; Ralph Groves | provisional |
| FL-12 | 1212 | Gus M. Bilirakis | 18/partial | incumbent-renominated | Gus Bilirakis (Republican); Darren McAuley (Democratic); Kimberly Overman (Democratic); Branden Scrivener (Independent) | Darren McAuley; Kimberly Overman; Branden Scrivener | provisional |
| FL-13 | 1213 | Anna Paulina Luna | 15/partial | incumbent-renominated | Anna Paulina Luna (Republican); Leela Gray (Democratic); John Liccione (Democratic); Timothy Brandt Robinson (Democratic); Tony D'Arrigo (Independent) | Leela Gray; John Liccione; Timothy Brandt Robinson; Tony D'Arrigo | provisional |
| FL-14 | 1214 | Kathy Castor | 19/partial | incumbent-renominated | Kathy Castor (Democratic); Mike Beltran (Republican); Michael Marcel (Republican); John Peters (Republican); Robert Rochford (Republican); Gavriel Soriano (Republican); Kevin Steele (Republican); Ergin Tek (Republican); Bea Valenti (Republican); Brian Lambert (Republican) | Mike Beltran; Michael Marcel; John Peters; Robert Rochford; Gavriel Soriano; Kevin Steele; Ergin Tek; Bea Valenti; Brian Lambert | provisional |
| FL-15 | 1215 | Laurel M. Lee | 12/partial | incumbent-renominated | Laurel Lee (Republican); Chris Irizarry (Democratic); Robert People (Democratic) | Chris Irizarry; Robert People | provisional |
| FL-16 | 1216 | Vern Buchanan | 18/partial | incumbent-retired | Sydney Gruters (Republican); Edward Pope (Republican); Eddie Speir (Republican); Jon Harris (Democratic); Kelly Kirschner (Democratic); Tamika Lyles (Democratic); Glenn Pearson (Democratic); Jan Schneider (Democratic); Mark Davis (Independent) | Sydney Gruters; Edward Pope; Eddie Speir; Jon Harris; Kelly Kirschner; Tamika Lyles; Glenn Pearson; Jan Schneider; Mark Davis | provisional |
| FL-17 | 1217 | W. Gregory Steube | 18/partial | incumbent-renominated | Greg Steube (Republican); Matthew Montavon (Democratic); Allen Spence (Democratic); Michael Quirk (Independent) | Matthew Montavon; Allen Spence; Michael Quirk | provisional |
| FL-18 | 1218 | Scott Franklin | 9/partial | incumbent-renominated | Scott Franklin (Republican); Curtis Gibson (Democratic); Deva Simmons (Independent) | Curtis Gibson; Deva Simmons | provisional |
| FL-19 | 1219 | Byron Donalds | 16/partial | incumbent-retired | Greg Bukowski (Republican); Madison Cawthorn (Republican); Chris Collins (Republican); Ola Hawatmeh (Republican); Catalina Lauf (Republican); Jim Oberweis (Republican); Mike Pedersen (Republican); Linda Sawyer (Republican); Jim Schwartzel (Republican); John Strand (Republican); Victor Arias (Democratic); Robert Neeld (Democratic); Howard Sapp (Democratic); Seth Haskins (Independent) | Greg Bukowski; Madison Cawthorn; Chris Collins; Ola Hawatmeh; Catalina Lauf; Jim Oberweis; Mike Pedersen; Linda Sawyer; Jim Schwartzel; John Strand; Victor Arias; Robert Neeld; Howard Sapp; Seth Haskins | provisional |
| FL-20 | 1220 | VACANT | 0/vacant | open-seat-vacancy | Luther Campbell (Democratic); Sheila Cherfilus-McCormick (Democratic); Dale Holness (Democratic); Elijah Manley (Democratic); Debbie Wasserman Schultz (Democratic); Brent Andersen (Republican); Lateresa Jones (Republican); Rod Joseph (Republican); Carla Spalding (Republican); Kedner MaximeDe (Independent) | Luther Campbell; Sheila Cherfilus-McCormick; Dale Holness; Elijah Manley; Brent Andersen; Lateresa Jones; Rod Joseph; Carla Spalding; Kedner MaximeDe | provisional |
| FL-21 | 1221 | Brian J. Mast | 19/partial | incumbent-renominated | Brian Mast (Republican); James Martin (Democratic); Bernard Taylor (Democratic); Alexander Cooke (Independent) | Bernard Taylor; Alexander Cooke | provisional |
| FL-22 | 1222 | Lois Frankel | 17/partial | incumbent-redistricted | Pia Dandiya (Democratic); Kaysia Earley (Democratic); Casey Askar (Republican); David Burck (Republican); Michael Carbonara (Republican); Richard Evans (Republican); Terri Hasdorff (Republican); Belinda Keiser (Republican); Michael Thompson (Republican) | Pia Dandiya; Kaysia Earley; Casey Askar; David Burck; Michael Carbonara; Richard Evans; Terri Hasdorff; Belinda Keiser | provisional |
| FL-23 | 1223 | Jared Moskowitz | 8/partial | incumbent-redistricted | Victoria Doyle (Democratic); Lois Frankel (Democratic); Mark Piper (Democratic); Deborah Adeimy (Republican); Paola Branda (Republican) | Victoria Doyle; Mark Piper; Deborah Adeimy; Paola Branda | provisional |
| FL-24 | 1224 | Frederica S. Wilson | 20/partial | incumbent-retired | Marshall Davis Sr. (Democratic); Oliver Gilbert (Democratic); Shevrin Jones (Democratic); Kendrick Meek Jr. (Democratic); Rudy Moise (Democratic); Jean Monestime (Democratic); Roderick Vereen (Democratic); Mayonna Te Brown (Republican); Andy Daro (Independent); Patricia Gonzalez (Independent) | Marshall Davis Sr.; Oliver Gilbert; Shevrin Jones; Kendrick Meek Jr.; Rudy Moise; Jean Monestime; Roderick Vereen; Mayonna Te Brown; Andy Daro; Patricia Gonzalez | provisional |
| FL-25 | 1225 | Debbie Wasserman Schultz | 19/partial | incumbent-redistricted | Oliver Larkin (Democratic); Jared Moskowitz (Democratic); Dan Franzese (Republican); Raven Harrison (Republican); Joseph Kaufman (Republican); George Moraitis (Republican); Scott Singer (Republican); Peter Jassenoff (Republican) | Oliver Larkin; Dan Franzese; Raven Harrison; Joseph Kaufman; George Moraitis; Scott Singer; Peter Jassenoff | provisional |
| FL-26 | 1226 | Mario Diaz-Balart | 17/partial | incumbent-renominated | Mario Diaz-Balart (Republican); Nicole Locklin (Democratic); Deborah Ann Meidinger Hosey (Independent) | Nicole Locklin; Deborah Ann Meidinger Hosey | provisional |
| FL-27 | 1227 | Maria Elvira Salazar | 12/partial | incumbent-renominated | Maria Elvira Salazar (Republican); Vincent Michael Arias (Republican); Robin Peguero (Democratic); Eliott Rodriguez (Democratic) | Vincent Michael Arias; Robin Peguero; Eliott Rodriguez | provisional |
| FL-28 | 1228 | Carlos A. Gimenez | 23/partial | incumbent-renominated | Carlos Giménez (Republican); Phil Ehr (Democratic); Eddy Rojas (Independent) | Phil Ehr; Eddy Rojas | provisional |
| NY-1 | 3601 | Nick LaLota | 10/partial | incumbent-renominated | Nick LaLota (Republican); Chris Gallant (Democratic) | Chris Gallant | decided |
| NY-2 | 3602 | Andrew R. Garbarino | 12/partial | incumbent-renominated | Andrew Garbarino (Republican); Patrick Halpin (Democratic) | Patrick Halpin | decided |
| NY-3 | 3603 | Thomas R. Suozzi | 15/partial | incumbent-renominated | Tom Suozzi (Democratic); Mike LiPetri (Republican) | Mike LiPetri | decided |
| NY-4 | 3604 | Laura Gillen | 10/partial | incumbent-renominated | Laura Gillen (Democratic); Jeanine Driscoll (Republican) | Jeanine Driscoll | decided |
| NY-5 | 3605 | Gregory W. Meeks | 18/partial | incumbent-renominated | Gregory Meeks (Democratic); George Marsh (Republican) | George Marsh | decided |
| NY-6 | 3606 | Grace Meng | 18/partial | incumbent-renominated | Grace Meng (Democratic); Joseph Chou (Republican) | Joseph Chou | decided |
| NY-7 | 3607 | Nydia M. Velázquez | 20/partial | incumbent-retired | Claire Valdez (Democratic); Melvin Rivera (Republican) | Claire Valdez; Melvin Rivera | decided |
| NY-8 | 3608 | Hakeem S. Jeffries | 16/partial | incumbent-renominated | Hakeem Jeffries (Democratic); Lewis Mizrahi (Republican) | Lewis Mizrahi | decided |
| NY-9 | 3609 | Yvette D. Clarke | 20/partial | incumbent-renominated | Yvette Clarke (Democratic); Joel Anabilah-Azumah (Republican) | Joel Anabilah-Azumah | decided |
| NY-10 | 3610 | Daniel S. Goldman | 14/partial | incumbent-lost-primary | Brad Lander (Democratic); Jennifer Moore (Republican) | Brad Lander; Jennifer Moore | decided |
| NY-11 | 3611 | Nicole Malliotakis | 12/partial | incumbent-renominated | Nicole Malliotakis (Republican); Michael DeCillis (Democratic) | Michael DeCillis | decided |
| NY-12 | 3612 | Jerrold Nadler | 18/partial | incumbent-retired | Micah Lasher (Democratic); Caroline Shinkle (Republican) | Micah Lasher; Caroline Shinkle | decided |
| NY-13 | 3613 | Adriano Espaillat | 18/partial | incumbent-lost-primary | Darializa Avila Chevalier (Democratic); Jomo M. Williams (Republican); Bob Cohen (Working Families) | Darializa Avila Chevalier; Jomo M. Williams; Bob Cohen | decided |
| NY-14 | 3614 | Alexandria Ocasio-Cortez | 24/done | incumbent-renominated | Alexandria Ocasio-Cortez (Democratic); Diamant Hysenaj (Republican) | Diamant Hysenaj | decided |
| NY-15 | 3615 | Ritchie Torres | 21/partial | incumbent-renominated | Ritchie Torres (Democratic); Stylo Sapaskis (Republican) | Stylo Sapaskis | decided |
| NY-16 | 3616 | George Latimer | 15/partial | incumbent-renominated | George Latimer (Democratic); Joseph Cinquemani (Republican) | Joseph Cinquemani | decided |
| NY-17 | 3617 | Michael Lawler | 15/partial | incumbent-renominated | Mike Lawler (Republican); Cait Conley (Democratic) | Cait Conley | decided |
| NY-18 | 3618 | Patrick Ryan | 13/partial | incumbent-renominated | Pat Ryan (Democratic); Jacqueline Auringer (Republican) | Jacqueline Auringer | decided |
| NY-19 | 3619 | Josh Riley | 18/partial | incumbent-renominated | Josh Riley (Democratic); Peter Oberacker (Republican) | Peter Oberacker | decided |
| NY-20 | 3620 | Paul Tonko | 17/partial | incumbent-renominated | Paul Tonko (Democratic); Ralph Ambrosio (Republican) | Ralph Ambrosio | decided |
| NY-21 | 3621 | Elise M. Stefanik | 21/partial | incumbent-retired | Anthony Constantino (Republican); Blake Gendebien (Democratic); Robert Smullen (Conservative) | Anthony Constantino; Blake Gendebien; Robert Smullen | decided |
| NY-22 | 3622 | John W. Mannion | 14/partial | incumbent-renominated | John Mannion (Democratic); Kailee Buller (Republican) | Kailee Buller | decided |
| NY-23 | 3623 | Nicholas A. Langworthy | 15/partial | incumbent-renominated | Nick Langworthy (Republican); Aaron Gies (Democratic) | Aaron Gies | decided |
| NY-24 | 3624 | Claudia Tenney | 18/partial | incumbent-renominated | Claudia Tenney (Republican); Alissa Ellman (Democratic) | Alissa Ellman | decided |
| NY-25 | 3625 | Joseph D. Morelle | 16/partial | incumbent-renominated | Joseph Morelle (Democratic); Virginia McIntyre (Republican) | Virginia McIntyre | decided |
| NY-26 | 3626 | Timothy M. Kennedy | 4/partial | incumbent-renominated | Tim Kennedy (Democratic); Dennis Hannon (Republican) | Dennis Hannon | decided |

---

*`148-field-table.csv` is the machine-readable companion (adds `target_election`, `existing_race_id`, `incumbent_pid`, `incumbent_external_id`, `source_url`). `148-verify.sql` asserts read-only that the live DB still matches this locked table (142 mapped incumbents, FL-20/TX-23 0-holder, 52 CA races at 0 candidates, and all 52 CA existing_race_id values resolving to a live CA-general race by geo_id).*
