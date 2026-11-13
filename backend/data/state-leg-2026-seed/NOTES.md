# 2026-11-03 state legislatures — the SEEDING pass (MA and ME)

Everything this wave learned. `CC_0413` is Massachusetts, `CC_0414` is Maine; the pipeline is
five scripts in this directory and every raw input is committed beside them.

```
fetch-ap.mjs          reused from ../state-leg-2026-results — AP's per-state feed
dump-our-races.mjs    our 2026-11-03 legislative RACES, candidates or not -> our-races-2026-11-13.json
analyse.mjs           match races, then build the ballot rows -> analysis-2026-11-13.json
verify-ma-soc.mjs     a second reading of Massachusetts' ballot, from the Secretary of the Commonwealth
verify-me-sos.mjs     a second reading of Maine's ballot, from the Secretary of State
emit-migration.mjs    analysis -> ../../migrations/CC_0413_*.sql and CC_0414_*.sql
controls.mjs          11 controls against the two migrations
ma-district-key.mjs   the Massachusetts district key, in ONE place because three readers use it
xlsx2json.mjs         a minimal .xlsx reader, because an official list arrives as a spreadsheet
```

---

## What was recorded

**600 candidacies across 382 races — 378 won, 214 lost, 8 with no result.** The unseeded
legislative backlog goes **641 → 259** (Maryland 118, Oregon 88, Nevada 53 remain), and the
legislative tier now holds **864 recorded winners**, 378 of them from this wave.

| state | our races | seeded | rows | won | lost | no result | linked to a person |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MA | 200 | 196 | 256 | 195 | 59 | 2 | 178 |
| ME | 186 | 186 | 344 | 183 | 155 | 6 | 116 |

Four Massachusetts races already carried a candidacy (`CC_0381` and the zero-vote wave: Decker,
Connolly, DiDomenico, Brownsberger) and are **not touched**. Verified after applying:
`259` races still empty · `864` legislative winners · `604` MA/ME candidacies · occupancy
`294 / 56 / 238`, the drift baseline unmoved.

---

## 🔴 THIS IS A SEEDING PASS, AND IT IS NOT A RESULTS PASS

`CC_0381` recorded calls onto candidacies that already existed. It could not touch these races,
and said so: *"641 of our 1,114 races carry no candidate rows at all. That is seeding work and it
is not what this file does."* The two acts differ in what they rest on:

- a results pass **matches** AP's ballot to rows we hold, and the danger is the NAME MATCH;
- a seeding pass **inserts** AP's ballot, and there is no name to match — so the danger moves to
  the **join key** (which district is this?) and to **what a row claims about a person**.

Both are handled below, and neither is handled the way the results pass handled them.

---

## 🔴 THE JOIN KEY, AND WHY MASSACHUSETTS IS THE HARD CASE

- **Maine numbers its districts on every source.** AP's `seatName` is "District 42", `seatNum` is
  "42", and ours is the `sldl:`/`sldu:` suffix of `districts.ocd_id`. ⚠ **The numbers repeat
  across chambers** — ME has a House 28 and a Senate 28 — so every key and every message carries
  the chamber. A report that printed "ME d28" sent the first reading of this wave to the wrong
  race.
- 🔴 **MASSACHUSETTS NAMES ITS DISTRICTS AND `ocd_id` CARRIES AN INTERNAL INDEX THAT HAPPENS TO BE
  A NUMBER.** `sldl:19` is the **10th Bristol District**; the senate rows carry **`sldu:NaN`**.
  AP's `seatNum` is its own internal index ("524"). So MA joins on the **normalised name**, and
  all 200 districts resolved one-to-one.
- 🔴🔴 **THE ORDER OF THE COUNTY TOKENS IS LOAD BEARING.** "Middlesex & Norfolk" and "Norfolk &
  Middlesex" are **both** real senate districts, as are Suffolk/Middlesex and Worcester/Middlesex.
  A key that sorted its tokens — the obvious way to absorb "and" versus "&" — would collide three
  real pairs and hand one district's winner to another.
- 🔴 **EACH SOURCE SPELLS THE ORDINAL ITS OWN WAY, AND ONE SOURCE DISAGREES WITH ITSELF.** AP
  writes "21st Middlesex"; the Secretary of the Commonwealth writes "Twenty-First Middlesex
  District"; our own labels use words in the senate ("Fifth Middlesex District") and numerals in
  the house ("25th Middlesex District"). Leaving the compound ordinals out of the map cost 17
  house districts, which came back as "no district of this name". The key now lives in
  `ma-district-key.mjs` and all three readers import it, because a key that drifts between
  readers is a silent mis-join.

---

## 🟢 BOTH BALLOTS ARE READ TWICE, AND THAT IS WHAT MAKES 600 INSERTED NAMES EVIDENCE

| source | what it is | result |
| --- | --- | --- |
| MA Secretary of the Commonwealth, "2026 State Election Candidates" | the official ballot | **200 of 200 races agree line for line, all 261 lines** |
| ME Secretary of State, "2026 General Candidate List - FINAL" (.xlsx) | the official filings | **185 of 186 races agree, 342 of 344 lines** |
| ME Secretary of State, "Declared Write-In Candidates" (PDF, 10/15/26) | the declared write-ins | names the one line the filing list lacks |

**Maine's arithmetic closes exactly**: 343 filings + 1 declared write-in = AP's 344. The single
difference was **Daniel LaPointe, House District 24**, and Maine's own write-in list gives him at
that district and that party.

- ⚠ **TEN MASSACHUSETTS LINES AGREED ONLY ONCE THE SUFFIX WAS SET ASIDE** — the Secretary prints
  "Angelo J. Puppolo" where AP writes "Angelo J. Puppolo Jr.". That is recorded as its own class
  rather than relaxing the comparison for all 261.
- 🔴 **AP MARKS A DECLARED WRITE-IN INSIDE THE SURNAME FIELD** — `"LaPointe (write-in)"` — so the
  marker reaches `last_name` and the display name unless it is lifted out. It is a column of ours
  (`is_write_in`), not part of anybody's name.
- ⚠ **NEITHER STATE PUBLISHES A GENERAL-ELECTION RETURN FOR THESE RACES.** Massachusetts
  publishes no unofficial results at all (`CC_0411` quotes the Secretary saying so). Maine's
  results page, read 2026-11-13, carries only the CD-2 ranked-choice tabulation and the June
  primary files. **So both states are read twice for the BALLOT and once for the CALL**, and the
  citations say which is which. A call and a canvass are two facts.

---

## 🔴 NO VOTE COUNT IS WRITTEN INTO ANY CITATION

AP calls an uncontested race **on the ballot** and then publishes `voteCount: 0` for everyone in
it. **171 of these 600 rows carry a published count of zero** (MA 140, ME 31) — Massachusetts
runs 140 uncontested races out of 196. Four migrations, `CC_0408`–`CC_0411`, exist because that
zero reached production as prose. We store no vote counts in any column, so the only way one
could get in is the citation text, and the post-verify **refuses any citation matching
`[0-9][0-9,]* votes`**. Where AP published a count the citation names the **share**; where it
published none it says so, in terms: *a published zero is not a tally of zero*.

---

## HOW A CANDIDACY IS LINKED TO A PERSON, AND WHY MOST ARE NOT

294 of the 600 rows carry a `politician_id`. The other 306 carry **NULL**, which is the normal
shape for a candidate in this repo — and **seeding a person is a separate act** that this wave
deliberately does not perform. A challenger who is not in `essentials.politicians` gets a
candidacy and no person.

An incumbent is different. The link rests on **two facts, neither of them a name**: AP flags the
ballot line as that seat's incumbent, and `essentials.office_current_holder` independently names
the politician holding that same office. The name is then a **check** on the pair:

| basis | n | what it rests on |
| --- | --- | --- |
| `holder-exact-full-name` | 127 | the two names are identical once accents, case and punctuation go |
| `holder-exact-first-last` | 157 | first and last agree field for field |
| `holder-surname-plus-roster` | 10 | surname agrees; the first names are a legal/diminutive pair |
| `holder-DISAGREES` | 0 | would be seeded with NULL and reported — none occurred |

🔴 **THE TEN ARE ALL WINNERS, SO THE BASIS HAD TO BE SOMETHING OTHER THAN THE NAME.** They are
Ted/Edward Philips, Nick/Nicholas Collins, Cindy/Cynthia Friedman, Matt/Matthew Moonen,
Drew/Andrew Gattine, Sally/Sally Jeane Cluchey, **Trey/Harold L. Stewart III**, Mike/Michael
Tipping, Chip/Glenn Chip Curry and Matt/Matthew A. Harrington. A name comparison relaxed until
those matched is how this repo once shipped Mark Harris as NC-8. ▶ **The seat is the key and the
surname is the check**, and the migration re-asserts the pair against production rather than
trusting the analyser.

⚠ **TWO "SURNAME DISAGREEMENTS" WERE FIELD BOUNDARIES, NOT DISAGREEMENTS.** AP splits
"Rachel | Talbot | Ross" where our roster holds the surname as "Talbot Ross", and writes
"Fluker Reid" where ours reads "Fluker-Reid". Comparing the whole name with the boundaries
removed is still an exact comparison; comparing one field invents differences.

---

## Controls — 11, all behaved

**V0 is the untampered file, for each state, and had to come back green.**

| variant | what it proves |
| --- | --- |
| **V1 transposed win** | 🔴 the win moved to the candidate with fewer votes, counts unchanged — the file agrees with itself and only AP's **independent vote field** can see it |
| V2 second winner, paid for elsewhere | the winner count is read against `races.seats`, not assumed to be 1 |
| **V3 a race that is already seeded** | 🔴 the premise of the whole file: these races are EMPTY |
| V4 an unknown race id | the positive control for every gate that joins production |
| **V5 two incumbent links swapped** | 🔴 each still names a real politician holding a real seat — just not THAT seat |
| V6 link kept, AP's incumbent flag cleared | the link rests on the flag, not on the name beside it |
| **V7 a count put back into the citation** | 🔴 the `CC_0408`–`CC_0411` defect, planted deliberately |
| V8 a dropped ballot line | the count gate stands between a partial read and a silent partial write |
| **V9 the mirror trigger woken** | 🔴 `trg_race_candidate_mirror_data` fires on any INSERT carrying a `politician_id` and can write a photo or a url **onto the politician**; both columns here are NULL, and the gate proves it |

🔴 **TWO OF THE ELEVEN WERE SHADOWED ON THE FIRST RUN, AND BOTH LOOKED LIKE A GATE FAILING.**
V3 and V4 moved **one row of a two-row race**, which left the old race behind and added a new one
— 197 distinct races where the file says 196 — so the RACE COUNT gate fired and the gate under
test was never reached. Rebuilt to move the only line of a **one-candidate** race, both go red on
the right gate. That is the tenth and eleventh time in this programme. ▶ **A TAMPER MUST SATISFY
EVERY GATE BEFORE ITS OWN.**

🔴 **AND TWO GATES ARE DELIBERATELY NOT CONTROLLED, WHICH IS SAID HERE RATHER THAN IMPLIED.** The
`external_id` collision gate cannot be tripped without writing a colliding row to production
first, and the occupancy baseline cannot be tripped without moving occupancy. Both are asserted,
neither is proven; the baseline check at least refuses to run against an empty view.

---

## 🔴 THREE PARSER ARTEFACTS, EACH OF WHICH PRODUCED A COMPLETE, PLAUSIBLE, WRONG TABLE

The tooling here read two official spreadsheets and one official web page. Every one of them
produced a clean-looking wrong answer first.

1. **An empty cell in an `.xlsx` is self-closing** (`<c r="B2" s="12"/>`), and a paired-tag-only
   regex swallows the next real cell into it, shifting every column after it. Read that way,
   Susan Collins' US Senate row reported district **"17"**, which is her party code.
2. **A missing name part is not the word "null".** Template-stringing the name fields put `null`
   into every AP key and reported **647 differences across 344 lines**.
3. **"A district header has no comma" is wrong in Massachusetts** and silently ate five senate
   districts whose names list three counties ("Berkshire, Hampden, Franklin & Hampshire"),
   folding each into the previous district as a candidate named "Hampden". A header is a line
   ending in `District` that carries **no digit**; every candidate line carries a street number.

⚠ **`sec.state.ma.us` SITS BEHIND AN INCAPSULA WAF**: `curl` with browser headers and a cookie jar
answers **HTTP 200 with a 212-byte challenge page**, after a redirect loop. Neither is a status
code you can judge. Read it in Playwright.

---

## ▶ What is next

1. **The other three states: Maryland 118, Oregon 88, Nevada 53.** The same pipeline;
   `fetch-ap.mjs MD,OR,NV` and a state profile in `emit-migration.mjs`. ⚠ Each needs its own
   second source and its own key: **Maryland's House elects up to three members per district**,
   so `seatNum` alone will not identify a race, and **Nevada's "None of These Candidates" is a
   ballot line that can win** (AP id `100013`, excluded by id here).
2. **The 4 uncalled races** — MA 1, ME 3 — carry ballot lines and no result. They shrink
   themselves as AP calls them; re-run `fetch-ap.mjs` and `analyse.mjs` and write a delta.
3. **Seating.** Nobody is seated by this wave. Both legislatures convene in January 2027 and each
   state's date needs its own authority.
4. ⚠ **The four already-seeded Massachusetts races.** AP's ballot for `Suffolk & Middlesex` names
   **two** candidates (Brownsberger and Brandon Charles Wood) and we hold one row. That is a real
   gap in a race this file skips by design — `CC_0381` also recorded Wood as a person we do not
   hold.
5. 🔴 **Sal DiDomenico's zero-vote row is still the one open item from that wave**, and it is a
   Massachusetts senate race: Everett has published nothing. Unblocks from **2026-11-18**.
