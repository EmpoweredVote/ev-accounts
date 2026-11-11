# 2026-11-03 state legislatures — the AP results pass

Everything this wave learned. `CC_0381` is the migration; the pipeline is four scripts in this
directory and every raw input is committed beside them.

```
fetch-ap.mjs        AP's per-state feed -> ap-2026-11-08/<ST>-{metadata,progress}.json
dump-our-rows.mjs   our 2026-11-03 legislative candidacies -> our-rows-2026-11-08.json
analyse.mjs         match races, then candidates -> analysis-2026-11-08.json
emit-migration.mjs  analysis -> ../../migrations/CC_0381_*.sql
verify-wa-sos.mjs   a second, independent reading of all 122 Washington contests
controls381.mjs     11 controls against the migration's gates
controls-analyse.mjs 6 controls against the matcher
```

---

## 🔴🔴 THE TIER WAS AT ZERO BECAUSE OF A BELIEF ABOUT AP, AND THE BELIEF WAS WRONG

The state legislatures are the biggest tier in the programme — 1,114 races of 2,340 — and held
**no recorded winner at all** while every worked tier was nearly finished. The reason was a line
in this repo's own notes: AP's coverage ceiling, *enumerated from its own feed*, as
**U.S. House, Governor, U.S. Senate, Attorney General, Secretary of State, Lieutenant Governor,
Mayor, U.S. Delegate, Railroad Commissioner** — no legislative contest anywhere.

That enumeration was correct and it was taken from
`results/**national**/metadata.json`, which holds **645 races**. AP publishes the rest **per
state**:

```
https://interactives.apelections.org/election-results/data-live/2026-11-03/results/races/<ST>/metadata.json
https://interactives.apelections.org/election-results/data-live/2026-11-03/results/races/<ST>/progress.json
```

Across the 51 state files: **6,938 races**, of which **5,759 are state-legislative** and
**5,439 are already called** — `officeID` **`Y`** for the lower chamber (State House / State
Assembly / House of Delegates) and **`Z`** for the upper (State Senate / State Legislature).

▶ **THE CATALOGUE OF A SOURCE IS A PROPERTY OF THE ENDPOINT, NOT OF THE SOURCE.** "AP does not
carry this" was true of the file we were reading and false of AP. It is `CC_0380`'s lesson — *an
absence you did not look for is not a finding* — met again one endpoint out, and found the same
way the feed itself was found in the first place: by watching what an AP results page requests.

⚠ **THE SAME CORRECTION APPLIES TO THE REST OF THAT CEILING.** "No treasurer, comptroller,
controller, auditor, superintendent, land or agriculture commissioner — ANYWHERE" is a statement
about the national file. The per-state files carry **24 Treasurer, 14 Auditor, 5 Comptroller,
3 Controller, 30 State Board of Education, 10 Public Service Commission, 51 City Council, 18
School Board, 10 Sheriff** and much else. Several of those are tiers this programme has been
sourcing by hand. **Enumerate the per-state catalogue before deciding what AP cannot answer.**

---

## What was recorded

**809 candidacies across 403 races — 427 won, 382 lost, all `called`.** The tier goes **0 → 427**.

| state | our races | writable | uncalled | rows | won | lost |
| --- | --- | --- | --- | --- | --- | --- |
| AZ | 60 | 54 | 6 | 139 | 78 | 61 |
| CA | 100 | 79 | 21 | 154 | 79 | 75 |
| CO | 12 | 9 | 3 | 21 | 9 | 12 |
| IN | 4 | 4 | 0 | 7 | 4 | 3 |
| MA | 4 | 4 | 0 | 4 | 4 | 0 |
| OR | 2 | 2 | 0 | 3 | 2 | 1 |
| UT | 53 | 40 | 13 | 81 | 40 | 41 |
| WA | 122 | 95 | 27 | 170 | 95 | 75 |
| WI | 116 | 116 | 0 | 230 | 116 | 114 |

**All 473 of our races carrying candidates matched an AP race**, and 0 were blocked.

🔴 **THIS IS A RESULTS PASS, NOT A SEEDING ONE.** We hold legislative races in **9 states of the
49 AP covers**, and 641 of our 1,114 races carry no candidate rows at all (MA, ME, MD, OR, NV).
**501 AP legislative races in these nine states alone have no race of ours**, and the national
figure is far larger. That is seeding work and it is not what this file does.

---

## 🔴🔴 THE NAME MATCH IS THE DANGEROUS STEP — FOUR NAMED BASES, NOT ONE FUZZY RULE

771 of 809 rows matched on an identical full name (676) or identical first-plus-last (97). The
other 38 disagreed in spelling, and **a comparison relaxed until they match is how this repo
once shipped Mark Harris as NC-8**. Each relaxation is a separate, named basis:

| basis | n | what it rests on |
| --- | --- | --- |
| `exact-full-name` | 676 | identical once accents are folded |
| `exact-first-last` | 97 | identical first and last columns |
| **`holder`** | **19** | AP flags the candidate as that seat's **incumbent** AND `essentials.office_current_holder` independently names the politician our row links to, **for that same office**. Two facts, neither of them a name. |
| `first-last-tokens` | 12 | first token and last token equal once nicknames, suffixes and punctuation are stripped, landing on exactly **one** unmatched row in that contest |
| **`reviewed`** | **1** | hand-checked, evidence in `name-overrides.json` |

🟢 **THE `holder` BASIS IS THE ONE WORTH COPYING.** It settled **18 of the 23 races that first
came back blocked**, with no name reading at all: AP's "Quang Nguyen" for our "Quang H Nguyen",
"Mia Gregerson" for "Mia Su-Ling Gregerson", "Jeffrey Mursau" for "Jeff Mursau", "Tony Exum" for
"Tony Exum Sr". It is `CC_0359`'s rung that needs no reading, and the migration re-asserts it
against production rather than trusting the analyser's word.

🔴 **THE ONE REVIEWED ROW IS THE ONE WHERE THE FIRST NAME ITSELF DIFFERS**, and checking it found
a trap. AP's **"Patricia Contreras"** won Arizona Senate LD12; our row reads **"Patty Contreras"**.
A diminutive is not an identity — and **Arizona's legislature seats TWO Contrerases**.
`azleg.gov`'s own Member Roster gives **Patty Contreras as District 12** and **Lupe Contreras as
District 22**. ▶ **THE DISTRICT DISAMBIGUATES WHAT THE SURNAME COULD NOT.** A surname match here
would have been a coin toss and nothing would have errored.

---

## 🟢 WASHINGTON IS READ TWICE, AND THAT IS WHAT MAKES THE RELAXED MATCHES EVIDENCE

Washington's Secretary of State publishes its own canvass through the API its public results site
reads, found the same way as AP's:

```
https://results.votewa.gov/results/public/api/elections/washington/20261103/data
```

`verify-wa-sos.mjs` joins all **122** AP contests to it and compares every ballot line.

- 🟢 **ALL 25 WASHINGTON NAME VARIANTS CARRY THE SAME VOTE COUNT ON BOTH SOURCES.** AP's
  "Kim Harless" and the state's "Kim D. Harless" are both **41,205**; "Luc Jasmin" and
  "Luc Jasmin III" both **37,485**; "Michael Shepard" and "Michael Alvarez Shepard" both
  **43,990**. Two readings of one ballot line. That is why the relaxed match is evidence and not
  convenience.
- 🔴 **THE STATE PUBLISHES NO WINNER FLAG — every `isWinner` is null.** A state **canvasses**; it
  does not **call**. So the state owns the BALLOT and the COUNT, AP owns the CALL, and each
  source is used only for the field it owns. ⚠ *A call and a canvass are two facts.*
- ⚠ **THE TWO DISAGREE ON 117 OF 225 COUNTS**, and that is not a defect in either. AP publishes
  **0 votes for every candidate** in the 19 unopposed contests and lags the canvass elsewhere.
  **We store no vote counts**, so it changes nothing we write — but no number here is quoted as
  a canvassed total. ▶ **Ask which FIELD you need before judging a source whole.**
- ⚠ The state's ballot carries **one extra line per contest, all 122 of them "Write-in"** — the
  twin of AP's `Total Write-ins` (id `100008`) and Nevada's `None of These Candidates`
  (`100013`). Both AP ids are excluded **by id** before anything is counted.

---

## 🔴 A TOP-VOTE-GETTER CROSS-CHECK OVER AN ALL-ZERO BALLOT COMPARES NOTHING AND PASSES

AP calls an unopposed race **on the ballot, not on the count**, and then publishes `voteCount: 0`
for everyone in it — 19 of Washington's 122. A gate that compares the flagged winner against the
top vote-getter is **vacuous** there.

The gate therefore fires only where AP had a choice to make: **more candidates than winners, and
no votes to choose on**. 🟢 Measured: every all-zero race here has **exactly as many candidates as
winners**, so no ordering decision exists in any of them. Arizona's four all-zero House races are
2 candidates for 2 seats.

⚠ **ARIZONA'S HOUSE ELECTS TWO MEMBERS PER DISTRICT.** 24 of these races carry `seats = 2` and
two winners, so **a one-winner-per-race gate would be wrong here**. The gate compares the winner
count against `races.seats`, and separately asserts our `seats` agrees with production's.

🔴 **AND THE VOTE-RANK GATE IS THE ONLY THING IN THE MIGRATION THAT CAN SEE A TRANSPOSED WIN.**
Every other check reads the `outcome` column beside the name, so a file that has swapped two
outcomes **agrees with itself** — the write reads the file's table and the post-verify reads the
same table. AP publishes the winner flag and the vote count as **independent fields**, so
requiring the winners to be the top `seats` rows by votes brings in a second fact a tamper would
also have to forge. **It was missing from the first draft of `CC_0381` and control A is what
found it.**

---

## 🔴 THE JOIN KEY, WHICH IS WHERE A LEGISLATIVE PASS GOES WRONG

- Most states number their seats: AP's `seatNum` is the district number, and ours is the
  `sldl:`/`sldu:` suffix of `districts.ocd_id`.
- 🔴🔴 **WASHINGTON'S HOUSE ELECTS TWO MEMBERS PER DISTRICT AND `seatNum` DOES NOT SAY WHICH.**
  49 districts, 98 races, and `seatNum` is **duplicated across every pair** — the position lives
  only in `seatName` (`District 1 - Position 1`). A `seatNum` join silently matches two races
  per district. Our side carries it in `offices.title` (`State Representative (Position 2)`).
- 🔴🔴 **MASSACHUSETTS NAMES ITS DISTRICTS, AND ITS `ocd_id` SUFFIX IS AN INTERNAL INDEX THAT
  HAPPENS TO BE A NUMBER.** `sldl:83` is the **25th Middlesex**. A numeric key matched nothing
  and **two real races vanished from the analysis with no error** — found only because the
  report prints "ours with NO AP race" as a number and it read 2. The matcher now offers both a
  numeric and a name key and requires exactly one to resolve. ⚠ Its senate districts carry
  `sldu:NaN`, so they were already on the name key and already matched — **half a state working
  is how this hides.**

---

## What is deliberately NOT written

- **70 matched races are UNCALLED by AP** (AZ 6, CA 21, CO 3, UT 13, WA 27) and get no row.
  Not a backlog — these seats turn over in January.
- **43 of our candidacies are not on AP's ballot** and are left untouched: 33 already read
  `not_nominated` (Washington's top-two primary losers, who were never on this ballot), one
  `withdrew`, nine carry no result. 🔴 **A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM,
  NEVER BECAUSE THEY ARE NOT THE WINNER.**
- **3 people on AP's ballots have no row of ours** — MA Suffolk & Middlesex "Brandon Wood",
  UT House 57 "Nancy Peterson", WA House 28 "Kerry Hills". **All three lost**, so no winner is
  missed. Seeding a person is a separate act.
- 🟢 **`advanced` MEANS SOMETHING REAL IN WASHINGTON.** 307 rows carried `result = 'advanced'`
  with a state citation — Arizona's SoS candidate list, and Washington's **August top-two primary
  canvass**, where advancing to the general is a true and load-bearing fact. Those citations are
  **appended, never overwritten** (`CC_0350`'s rule), the UPDATE reads the **live** column rather
  than the file's copy, and a post-verify gate asserts all 307 survive verbatim.

---

## Controls

**11 of 11 against the migration, none shadowed** — transposed winner (the gate that was
missing), swapped uuid, a congressional row smuggled in, winners against `races.seats`, a moved
prior value, the incumbent basis gone stale, the citation append removed, a dropped row, the
occupancy baseline, an officeholder moved, and a result written outside the pinned set.

**6 of 6 against the matcher** — a progress file read as a map, a zero-byte input, a race whose
key stops matching, a winner we hold no row for, an override pointing outside its race, and an
override that has stopped being needed.

🔴 **THREE OF THE ELEVEN WERE SHADOWED ON THE FIRST RUN AND EACH ONE LOOKED LIKE A GATE FAILING.**
Pointing one row's uuid at another row **duplicated a primary key** and died on the INSERT;
moving one row into another race left **404 races** and tripped the race count; promoting one
loser left **428 winners** and tripped the total. Every one had to be rebuilt to be internally
consistent — swap the uuids rather than duplicate one, replace **both** rows of a race, demote a
winner elsewhere to keep the total — before it could reach the gate it was aimed at. That is the
seventh, eighth and ninth time in this programme. ▶ **A TAMPER MUST SATISFY EVERY GATE BEFORE
ITS OWN.**

---

## ▶ What is next

1. **The 70 uncalled races.** Re-run `fetch-ap.mjs` and `analyse.mjs`; this shrinks itself as AP
   calls them. A delta pass is cheap — **re-read the feed rather than assuming this one is still
   current.**
2. **`certified` upgrades.** AP reports `isCertified: false` on every one of these. Washington's
   canvass API above is already the right source for that state.
3. **641 races with no candidates** (MA 196, ME 186, MD 118, NV 53, OR 88). Seeding, not results
   — and AP's per-state files carry the ballots.
4. **Seating.** Nobody is seated here. Most of these chambers convene in January 2027 and each
   state's date needs its own authority, the way piece 4 did for California.
   - ⚠ **Wisconsin: Romaine Quinn (`2dbf3032`) MOVES SEAT, SD-25 → SD-23** (noted 2026-11-10, `CA_0373`).
     He holds SD-25 today and won SD-23; Erik Severson won SD-25. Seat **both** seats in the same pass
     with `seat_officeholder`: SD-23 → Quinn, SD-25 → Severson, which closes Quinn's SD-25 term the day
     before. Seat only SD-23 and he holds two seats; seat neither and the old roster stays live. His
     race rows are already on `2dbf3032` — the duplicate `a0ea7354` was merged and is inactive.
5. 🔴 **The other 40 states.** AP has called **5,439** legislative races; we recorded 427 because
   we hold races in nine states. The gap is an office-and-occupancy act, not a results one.
