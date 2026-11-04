# Hawaii State Legislature — verified roster, 76 seats

Compiled **2026-10-28**. Applied as `CC_0306` (structure and seating) and `CC_0307` (portraits).

**76 seats: 25 Senate + 51 House.** Before this, Hawaii held **six** offices in production — two
U.S. Senators, two U.S. Representatives, the Governor and the Lieutenant Governor — so a Hawaii
address returned federal and statewide officials with a hole where its legislators belong.

🔴 **Hawaii had NO state-legislative polygons at all.** Production held **0 of 1,178** `G5210`
rows and **0 of 3,065** `G5220` rows for state 15. The whole state had been skipped by the
national TIGER load, which is why the districts had to be loaded before anything could be seated.

---

## Sources

| # | Source | Retrieved | What it establishes |
|---|---|---|---|
| S1 | `capitol.hawaii.gov/legislature/legislators.aspx?chamber=S` and `=H` | 2026-10-28 | Every sitting member, by seat, with party letter, district area list, official photograph, and the "Appointed" / "Term of Office Ended" flags. |
| S2 | The individual member pages under `/legislature/memberpage.aspx?member=<id>` | 2026-10-28 | Per-member confirmation, and the appointment and term-ended dates in defect 1. |
| S3 | Constitution of the State of Hawaii, Art. III §4 and §5, via the Legislative Reference Bureau (`lrb.hawaii.gov/constitution/`) | 2026-10-28 | The term-start rule (ruling 1), the unopposed-at-the-general rule, and that vacancies are filled by appointment. |
| S4 | Hawaii Office of Elections certified statewide summaries, **2026 Primary** and **2024 Primary** (`histatewide.pdf`) | 2026-10-28 | Which Senate districts were on which ballot, and that all 51 House seats run every cycle. |
| S5 | TIGER 2024 `SLDU`/`SLDL` for state 15, via `scripts/load-state-tiger-boundaries.ts` | 2026-10-28 | The 25 + 51 district polygons. |
| S6 | Prod query against `essentials.politicians` and `race_candidates` | 2026-10-28 | The identity rulings. |
| S7 | Press coverage of Awa, Keohokalole and Ratcliffe | 2026-10-28 | The three identity/appointment facts that no official page states. ⚠ Used only where an official source was silent, and never for a name or a count. |

---

## Rulings

**1. 🔴 TERMS BEGIN AND END ON GENERAL ELECTION DAY, NOT IN JANUARY.** S3, Art. III §4:

> The term of a member of the legislature shall begin **on the day of the general election at
> which elected** or if elected at a primary election, on the day of the general election
> immediately following the primary election at which elected. For a member of the house of
> representatives, the terms shall **end on the day of the general election immediately
> following** the day the member's term commences.

So on **2026-11-03** every one of the 51 House terms seated here ends and the winners' terms
begin the same day. This is the single most consequential fact in this file, and it is why the
re-seat is an election-night operation rather than a new-year one.

**2. The Senate staggers; the House does not.** Measured from the certified statewide primary
sheets (S4): **14** Senate districts were on the 2026 ballot (2, 5, 8, 9, 10, 11, 13, 14, 15, 17,
19, 20, 21, 25) and **13** on the 2024 ballot. Districts 5 and 19 appear in **both**, which is
consistent with an unexpired-term election following an appointment. **All 51 House districts
appear in both cycles**, because the term is two years.

**3. A vacancy is filled by APPOINTMENT, never by special election.** S3, Art. III §5: a vacancy
"shall be filled for the unexpired term in such manner as may be provided by law, or, if no
provision be made by law, by appointment by the governor". HRS §17-3 provides gubernatorial
appointment from three names submitted by the departing member's party. So every mid-term arrival
in this roster is `how_started = 'appointed'`.

**4. Party is recorded on the roster and NOT written to the database.** These are partisan offices
and S1 prints a letter for every member, but `politicians.party` stays NULL — which is what
Minnesota, South Carolina and Florida carry for their legislators (0 of 441 between them). Party
lives on `races.primary_party`.

**5. Office titles are the bare role.** `Senator` and `Representative`, with the district carried
on `districts.label` — the convention in all four comparable states.

---

## 🔴 Source defects found

**1. THE "ACTIVE" ROSTER PRINTS DEPARTED MEMBERS.** Both pages put every block under
`MembersActive_RepeaterActive`, yet the Senate page carries **26** blocks for 25 seats and the
House **52** for 51. The extra one in each is a member whose term has ended, printed beside their
replacement:

- Senate 18 — **Kidani, Michelle N.**, "Term of Office Ended: 06/30/2026", beside Danielle M.M. Bass
- House 28 — **Holt, Daniel**, "Term of Office Ended: 02/13/2026", beside M. Cov Ratcliffe

Taking the repeater at face value seats two people in one district. The parser reads the
ended-term flag per block and excludes them; it refuses to write its output unless the result is
exactly 25 and 51 with no gaps.

⚠ The flag sits **after** the district `<div>` closes, so a block has to be delimited by the next
member link. A first attempt that captured only to `</div>` found neither the ended-term nor the
appointment markers and reported 26 and 52 sitting.

**2. The published name format is not "Last, First".** Three shapes appear and comma-counting does
not separate them: `Ihara, Jr., Les` and `Richards, III, Herbert M. "Tim"` put the **suffix in the
middle**; `Alcos III, David` glues it to the **surname**; `San Buenaventura`, `Keohokapu-Lee Loy`,
`Dela Cruz`, `La Chica` and `Reyes Oda` are **multi-word surnames**. A naive split puts "Jr." in
the first-name column, and the duplicate-name guard keys on `(first_name, last_name)`.
`Ratcliffe, M. Cov` additionally leads with an initial, so the given name used is **Cov**.

**3. The certified sheets label the chamber "State Senator", not "State Senate".** A pattern
written the obvious way returns zero and looks like an absent race.

**4. Fetching 76 photographs back-to-back got every connection dropped** — all 76 returned curl
code `000`, which reads like 76 missing files. A single request succeeded immediately afterwards.
Refetched over one reused connection with `curl -K`; all 76 arrived.

---

## 🔴 Identity rulings

Scanned twice against production: on normalised `(first_name, last_name)`, and as a substring
sweep over `full_name` and `alternate_names` **including archived rows**. The sweep's control
returned **395** rows, so it was not blind. Four names already existed, and they split two–two.

**1. REUSE — Brenton Awa (`-150204`) and Jarrett Keohokalole (`-150103`).** Both already existed
as **2026 U.S. House candidates**, loaded 2026-07-07 from the Office of Elections filing grid.
Both are the sitting senators: coverage describes "Republican state Sen. Brenton Awa … has
represented the 23rd district since 2022", the GOP nominee for HI-02; and "state Sen. Jarrett
Keohokalole", the HI-01 candidate who lost the 2026 Democratic primary to Ed Case. Seeding them
fresh would leave two of each — one holding the Senate seat, one holding the candidacy.

**2. 🔴 INSERT NEW — Mike Lee and Chris Todd. THE EXISTING ROWS ARE DIFFERENT PEOPLE.**

- `Mike Lee` (`-400077`) is the **U.S. Senator for Utah**, Republican, photographed from the
  Congressional bioguide (`L000577`). Hawaii **House District 50**'s Mike Lee is someone else.
  This is the documented "Mike Lee failure" appearing again, in this roster.
- `Chris Todd` (`-4720073`) is a **Tennessee state representative, House District 73**,
  photographed from `wapp.capitol.tn.gov`. Hawaii **House District 3**'s Chris Todd is someone
  else.

Both were confirmed by the office each row actually holds, and then visually on the contact sheet.

**Consequence for the migration, and it is structural:** the people INSERT could **not** use the
usual "insert where no active row matches (first_name, last_name)" guard, which would have
silently skipped both and seated the Utah senator and the Tennessee representative in Hawaii.
CC_0306 inserts in **two passes** — 72 with the duplicate-name guard **armed**, then exactly these
two with `essentials.allow_duplicate_name` lowered and raised again immediately. The repo's own
guard caught Chris Todd on the first dry run, which is how the two-pass shape was arrived at.

**3. Four appointees.** Hawaii fills a vacancy by gubernatorial appointment (ruling 3):

| Seat | Member | Appointed | Precision |
|---|---|---|---|
| Senate 18 | Danielle M.M. Bass | 2026-08-09 | day — the roster prints it |
| Senate 19 | Rachele Lamosao | 2025-12-03 | day — the roster prints it |
| House 36 | Daisy Hartsfield | 2026-01-12 | day — the roster prints it |
| House 28 | M. Cov Ratcliffe | 2026-04 | **month** — see below |

⚠ **Ratcliffe is the one the Legislature does not date.** Governor Green appointed Michael
Covenant "Cov" Ratcliffe in April 2026 to replace Daniel Holt, from three names submitted by a
Democratic Party district council. Reporting disagrees on the oath day, so this is month
precision and must not be promoted without a primary source.

---

## Dates

`office_terms.term_start` is the start of **continuous occupancy**. The Legislature publishes no
service-start date for an elected member, so the **72 elected members carry `start_precision =
'unknown'` with a NULL date** — the same thing Minnesota (200 of 200), South Carolina (153 of 170)
and Mississippi (167 of 174) carry, and for the same reason. **"First elected is not a term
start."** Only the four appointees are dated.

⚠ **Hawaii is unusually datable in principle, and that is a lead rather than a result.** Ruling 1
fixes the day, so a member's start is computable from the general election at which their
continuous service began. Establishing that election for 72 people across several cycles is a
research pass this seed does not make.

---

## Geography

Loaded by `scripts/load-state-tiger-boundaries.ts --state HI --fips 15 --layers sldu,sldl`, which
required adding `HI` to that file's per-state allowlist — deliberately a code change. **No `place`
layer**: Hawaii has no incorporated places at all, so a place load would import nothing and the
empty result would look like a broken fetch.

🟢 **VINTAGE VERIFIED, NOT ASSUMED.** TIGER 2024 should carry the 2022 reapportionment map. Seven
points were probed against the loaded polygons and checked against the Legislature's own area
descriptions — **14 independent matches across both chambers**:

| Point | Resolved | The Legislature's own description |
|---|---|---|
| Chinatown / Iwilei | S13 / H28 | S13 "… Iwilei, Chinatown"; H28 "Sand Island, Iwilei, Chinatown" |
| Hawaiʻi Kai | S9 / H19 | S9 "Hawaiʻi Kai, Kuliʻouʻou …"; H19 "… Niu Valley, Kuliʻouʻou" |
| Hilo | S1 / H1 | S1 "Hilo, Paukaʻa …"; H1 "Hāmākua, portion of Hilo, Kaūmana" |
| Kahului (Maui) | S5 / H9 | S5 "Wailuku, Kahului …"; H9 "Kahului, Puʻunēnē …" |
| Kapolei | S21 / H42 | S21 "Kapolei, Makakilo …"; H42 "… and Kapolei" |
| Līhuʻe (Kauaʻi) | S8 / H16 | S8 "Kauaʻi, Niʻihau"; H16 "… Līhuʻe …" |
| Mililani | S17 / H37 | S17 "Portion of Mililani, Mililani Mauka …"; H37 "Portions of Mililani Town …" |

🔴 **`geo_id` ALONE IS NOT A KEY, AND THIS SEED SHOWS IT TWICE.** `15001` is Senate District 1
under `G5210` **and** House District 1 under `G5220` — the same string, two different places. (And
production separately holds `15003` under `G6350` for 16 km² of Pennsylvania.) Every predicate is
written on the `(geo_id, mtfcc)` pair.

---

## Portraits

**74 of 76.** All from the Legislature's own member photographs
(`capitol.hawaii.gov/memberfiles/repsenphotos/`), mirrored into Supabase storage under
`politician_photos/hi-legislature-2026/`, licence `press_use`.

🔴 **All 76 were rendered to two contact sheets and looked at**, because nothing in this repo asks
whether a headshot contains a face — on the Honolulu seed that step caught a department seal being
imported as the Prosecuting Attorney's portrait. All 76 are genuine, distinct individual
headshots. Senate 18 (Bass) is an outdoor photograph rather than the studio set, consistent with
her appointment in August. House 50's Mike Lee is visibly not the Senator for Utah.

⚠ **Senate 23 (Awa) and Senate 24 (Keohokalole) are deliberately NOT repainted.** Their existing
rows already carry a mirrored portrait under a **`public_domain`** licence from the congressional
candidate load; overwriting with a `press_use` image would trade a freer licence for a narrower
one on a picture that already renders. Their Legislature photographs were uploaded and are
unreferenced.

Portraits are bound **by seat**, not by politician UUID or name — a name-bound update would have
put a Hawaii representative's face on the Utah senator. The gate asserts the resolved holder still
matches the name the file was generated against.

---

## Counts, for the payload guard

| Group | Rows |
|---|---|
| `Hawaii Senate` offices | 25 |
| `Hawaii House of Representatives` offices | 51 |
| **Total offices** | **76** |
| Politicians inserted | **74** |
| Production rows reused | **2** (Awa, Keohokalole) |
| Inserted past the duplicate-name guard, deliberately | **2** (Mike Lee, Chris Todd) |
| `how_started = 'appointed'` | **4** |
| `how_started = 'elected'` | **72** |
| `start_precision = 'unknown'`, NULL date | **72** |
| Dated starts | **4** (3 day, 1 month) |
| Officeholders carrying a party | **0** |
| Districts with a polygon | **76 of 76** |
| Portraits written | **74** |

---

## ▶ Open items

1. 🔴🔴 **2026-11-03 — ALL 51 HOUSE TERMS END THAT DAY, AND 14 SENATE TERMS WITH THEM.** Not in
   January (ruling 1). This is the largest scheduled re-seat on the board and it is six days out
   from this seed. Use `essentials.seat_officeholder`, which closes the predecessor's term.
2. **The 72 elected members have no start date.** Ruling 1 makes them computable from the general
   election at which continuous service began; that research pass is not made here.
3. **Jarrett Keohokalole's candidate row still reads `candidate_status = 'active'`** although he
   lost the 2026 HI-01 Democratic primary on 2026-08-08. Noticed while resolving his identity;
   not this seed's to fix.
4. **Two uploaded portraits are unreferenced** (`s23-awa.jpg`, `s24-keohokalole.jpg`) — see the
   licence note above.
