# The 50 empty local races for 2026-11-03 — what each one actually is

Audited 2026-11-13/14, after `CC_0419` closed the legislative tier. These 50 were the only races in
production carrying no candidate at all. **The question asked of each was the same one the Oregon
senate wave asked: was this seat on that ballot?** The answer came back in **three different
shapes**, and none of them is the senate's.

| | rows | what they are | what they need |
| --- | --- | --- | --- |
| **Oregon** | 42 | **on the 2026-11-03 ballot** | seed the ballot |
| **Arizona — South Tucson** | 1 | **on the 2026-11-03 ballot** | seed the ballot |
| **Arizona — Marana, Oro Valley, Sahuarita** | 5 | **decided at the 2026-07-21 primary**, absent from the general | the race is on the wrong election |
| **Wisconsin — Racine** | 2 | **on the 2026-11-03 ballot** | seed the ballot |

🔴 **NOT ONE OF THE 50 IS A PHANTOM.** The senate's answer — *this election did not happen* — is not
the answer anywhere here. "No candidates" was the shape of *three* different facts, which is exactly
why `CC_0419` targeted an explicit list of districts and used the empty-race test only as a guard.

## Oregon — 42 rows, every one a real contest

Source: the Secretary of State's **per-county exports** (`ResultsExport.aspx`), Multnomah,
Washington and Clackamas, pulled by `fetch-or-county-export.mjs`.

⚠ **`curl` CAN do this postback, contrary to the note left by the previous wave.** That note said
the Legislative Export needed Playwright because the link is an ASP.NET `__doPostBack`. Replaying
the postback directly — carry the cookie and the `__VIEWSTATE` / `__VIEWSTATEGENERATOR` /
`__EVENTVALIDATION`, set `__EVENTTARGET` — works from the shell. What Playwright was needed for was
the *click*, not the *request*.

🔴 **A CLEAN 200 FROM THAT ENDPOINT IS NOT A CSV.** ASP.NET answers a rejected postback with the
page again, status 200. A reader that trusted the status would parse an HTML document as an empty
ballot — *"this county held no elections"* — so the fetcher requires the export's header row and
exits non-zero otherwise.

### 🔴🔴 The county's own `VoteFor` column is WRONG for every ranked-choice contest

The export gives **`VoteFor=1`** for `City of Portland, Councilor, District 3`. Multnomah County's
RCV site says, of the same contest:

> **3 Seats Up for Election** … This is a multi-winner ranked choice voting contest to elect 3
> candidates. Steve Novick, Angelita Morillo and Tiffany Koyama Lane are leading.

▶ **Trusting `VoteFor` would have marked four of our six Portland rows as off-cycle and deleted real
seats** — the Oregon senate error run in reverse, and from a field that is correct in every ordinary
contest in the same file. The tell is visible: every RCV contest in the export carries **zero votes
for every candidate**, because the counts live at `rcvresults.multco.us`. *A field that is right
everywhere else is still wrong here.*

RCV contests, read from the county's own reports rather than the export:

| contest | seats | result |
| --- | --- | --- |
| Portland Councilor D3 | 3 | Novick, Morillo, Koyama Lane won — **our three sitting holders, all re-elected** |
| Portland Councilor D4 | 3 | Mitch Green and Olivia Clark reached the threshold; the third seat not yet named |
| Portland Auditor | 1 | Simone Rede won |
| Multnomah County Chair | 1 | **Shannon Singleton** won |
| Multnomah Commissioner D2 | 1 | **Bri Williams** won |

🟢 Those last two cross-check each other: Singleton is our current holder of **Commissioner District
2**, and moves up to Chair; Williams takes the seat Singleton leaves. The chair she replaces is
Jessica Vega Pederson.

### ⚠ Two structural problems that seeding has to answer first

1. **Five cities run one at-large contest where we hold three seat rows.** Forest Grove, Sherwood
   and Tigard print `Council Members (Vote For 3)`; Maywood Park and Troutdale print
   `Councilor (Vote For 3)`. **The ballot does not assign a candidate to a seat** — the top three
   win. We hold three separate offices and three separate races. Portland D3 and D4 are the same
   shape (one contest, three seats, three rows). CLAUDE.md's rule for multi-member bodies is *one
   race carrying `seats = N`*, which means 7 contests are represented by 21 race rows.
2. 🔴 **Wood Village's seat labels do not match the city's.** The ballot has `Councilor, Position 1`
   (Charlene Gothard) and `Councilor, Position 4` (Christine Bierman). We hold `Seat 1` (John Miner)
   and `Seat 2` (Charlene Gothard). Our holder of "Seat 2" is on the ballot for the city's
   "Position 1", so the two numbering schemes are not the same scheme, and we hold 2 offices for a
   council that numbers at least 4 positions.

## Arizona — the primary elected five of the six seats

🟢 **Positive on one side, absent on the other, which is what makes it a finding.** Pima County's
own summary files:

| contest | Jul 2026 **primary** | Nov 2026 **general** |
| --- | --- | --- |
| Mayor — Town of Marana | **present** (Johnsen, Post) | absent |
| Council Member — Town of Marana | **present** (6 candidates) | absent |
| Mayor — Town of Oro Valley | **present** (Barrett, Napier) | absent |
| Council Member — Town of Oro Valley | **present** (5 candidates) | absent |
| Council Member — Town of Sahuarita | **present** (5 candidates) | absent |
| Council Member — City of South Tucson | **present** (8 candidates) | **present** (4 candidates) |

That is Arizona's municipal rule working as written: a candidate who takes a majority at the primary
is elected then and there, and the office never reaches the general ballot. South Tucson is the
control — nobody cleared the bar, so its field narrowed from eight to four and went to November.

▶ So these five race rows are **attached to the wrong election**. The seats were filled; the date on
our row is not the date it happened. That is a third thing again — neither "seed it" nor "delete
it".

## Wisconsin — both Racine rows were on the ballot, and the statute predicted which

**Wis. Stat. 59.20(2)(b):** *"Beginning in 2006 and quadrennially thereafter, a sheriff shall be
chosen at the general election by the electors of each county for the term of 4 years."*
2006 → 2010 → … → 2022 → **2026**. The sheriff is on the **gubernatorial** cycle.
**59.20(2)(a)** puts the register of deeds, county clerk and treasurer on **2008 and quadrennially**
— the **presidential** cycle.

🟢 **That gave a control nobody designed.** Racine County's own 2026-11-03 summary carries a
`Sheriff` contest and a `Clerk of Circuit Court` contest, and carries **no `Register of Deeds`** —
exactly what the statute predicts for each. Two independent things agreeing, rather than one source
read twice.

⚠ Our holder of the sheriff's office is **Christopher Schmaling**; press reporting has **Don
Vandervest** winning it. Treat that as a lead until the county's own figures are read properly —
see the next warning.

### 🔴 The Racine PDF is WAF-blocked to `curl`, and its extracted text is MISALIGNED

`curl` gets **403** on `racinecounty.gov` document URLs even with a browser User-Agent and Referer,
and on the alternate `racinecounty.com` host too. The file comes down inside the browser, where it
is same-origin. A small extractor inflates the `FlateDecode` streams with `DecompressionStream` and
pulls the text.

🔴 **Its first run inflated ZERO bytes and reported every contest ABSENT** — a perfectly uniform
"not found" from a detector that could not see anything. Only the returned
`streamTextChars: 0` showed it. **Print what the detector examined, not just its verdict.**

🔴 **Once it worked, the text came out OFFSET BY ONE BLOCK.** The extraction pairs
`Sheriff (Vote for 1)` with `Amy Vanderhoef REP 54,674` — Vanderhoef is the **Clerk of Circuit
Court** — and pairs `Clerk of Circuit Court (Vote for 1)` with `Yes 43,284 / No 36,344`, which is a
**referendum**. So the contest TITLES are usable and **not one number in that extraction may be
read**. Same hazard as the Massachusetts city PDFs and the Oregon 2024 abstract; third wave running.
▶ Racine's figures must be read another way before any of them is written.

## ▶ What this leaves to do

✅ **All three are done** — see "State of play" below for which migration did which. Kept as written
because the shape of the list is the finding: the 50 needed *three different acts*, not one.

- ~~**Seed 45 races** — 42 Oregon, South Tucson, 2 Racine~~ — `CC_0423`, `CC_0421`, `CC_0424`.
- ~~**Re-point 5 Arizona races** off 2026-11-03~~ — `CC_0421`.
- ~~Read Racine's vote figures from a source whose columns are not drifting~~ — `CC_0424`, and the
  answer was that **no source was drifting**; the reader was pairing in stream order.
- ⚠ **STILL OPEN. Out of scope then and now:** Multnomah County **Sheriff** and **Auditor** were both
  on this ballot and we hold **no race row for either**, so neither shows up as a gap anywhere. An
  office with no race is invisible, not incomplete — **the empty-race sweep cannot ever find these**,
  which is why finishing the 50 does not close this.

---

# Step 1 — Arizona, worked through (2026-11-14)

`az-apply-9-821-01.mjs` applies **A.R.S. § 9-821.01** to Pima County's published county totals. The
statute is quoted in that file rather than summarised, because every number below comes out of it.

- **(F)** the majority threshold = (votes for candidates **lawfully on the ballot** ÷ seats) ÷ 2,
  rounded up. 🔴 Write-ins are outside that denominator — Marana's aggregate write-in line alone is
  **4,680 votes**, and folding it in would move the bar for everyone in the contest. Marana even had
  an *official* write-in candidate, Jackie Craig, whose name is still not on the ballot.
- **(G)** if more clear the bar than there are seats, the highest vote-getters take the seats.
- **(H)** otherwise, **twice the number of open seats** advances to the general.
- **(D)** a winner at the primary is declared elected *"effective as of the date of the general
  election"*. ⚠ That is a fact about the **term**, not about which ballot carried the contest.

🟢 **The Town of Marana states the mechanism itself**, answering "Will there be a General Election?":
*"Maybe. A General Election will only be held if one or more Town races are not decided at the
Primary Election."*

| contest | seats | threshold | outcome |
| --- | --- | --- | --- |
| Marana Mayor | 1 | 6,985 | **Jon Post** (7,620) over Greg Johnsen (6,350) |
| Marana Town Council | 4 | 5,440 | **Kai, Murphy, Officer, McGuire**; Ritz and Prince out — all six cleared the bar, so (G) decides |
| Oro Valley Mayor | 1 | 7,415 | **Melanie Barrett** (8,471) over Mark Napier (6,359) |
| Oro Valley Town Council | 3 | 6,266 | **Dailey, Pina, Wood**; DeSimone and Herrington out |
| Sahuarita Town Council | 3 | 2,779 | **Morales, Murphy, Hundal**; Cubillo and Earl out |

## 🔴🔴 South Tucson is split across two elections, and the file said so before I did

The first version of this analysis assumed a contest is decided all at once. It put all three South
Tucson seats at the general and declared Aguirre, Baca and **Federico** elected. That is wrong.

**Roxanna Valenzuela cleared the (F) majority of 176 at the primary** (201 votes) and took one seat
there, leaving **two**. So the general elected only the top two — **Aguirre (388) and Baca (353)** —
and **Federico (345) came third by 8 votes.**

🟢 **The proof is a count, not a judgement.** (H) advances twice the open seats. South Tucson's
general ballot lists **four** candidates. Four is twice two, not twice three. The number of names on
the general ballot states how many seats were still open, independently of any threshold arithmetic.
The script now asserts it, so this cannot be got wrong quietly again.

⚠ A second bug fell out of the same fix: "did not win" is not "advanced". Only four of the seven who
missed the majority went forward; **Cook, Moreno-Sears and Dodson did not**, and calling them
"advanced" would have put them on a November ballot they were never on. Advancing is now read off
the general ballot, never inferred from losing.

## What may be recorded, and what may not

- 🟢 **The primary is canvassed.** Pima publishes a **2026 Primary Election — Canvass** and its live
  portal reports the July results as `OFFICIAL ELECTION RESULTS`, 265 of 265 precincts.
- 🔴 **The general is not.** There is **no canvass document for November 3** on the same page — only
  summary results and ballots-processed reports. With the second South Tucson seat resting on **8
  votes**, and the ballots-processed PDFs suffering the same column drift as every other PDF in this
  programme, **no winner is recorded for the South Tucson general in this wave.** A call needs the
  bound, and the bound is not legible.
- 🟢 **Control on the reader**: for `DEM U.S. Representative in Congress District 6` the CSV reader
  returns **65,097 / write-in 343**, which is exactly what Pima's live portal shows. The totals being
  read are the county's own.

## ⚠ The modelling wrinkle step 1 runs into

Five contests belong wholly to the primary and can simply move there. **South Tucson belongs to
both**: one seat filled in July, two in November. Our single race row carries `seats = 3` on the
general, which is the right number for the *office* and the wrong number for that *ballot*.

---

# State of play, 2026-11-14 — ALL 50 ARE DONE

| | | |
| --- | --- | --- |
| `CC_0421` | Arizona, 6 rows | 5 races moved to the 2026-07-21 primary that held them; South Tucson split across both elections; 32 candidacies |
| `CC_0422` | Oregon, 21 → 7 rows | the multi-seat council contests collapsed to one race each, `seats = 3` |
| `CC_0423` | Oregon, 26 races | 102 candidacies — 18 won, 26 lost, **58 with no result** |
| `CC_0424` | Wisconsin, 2 races | Racine sheriff and clerk of circuit court, 3 candidacies — the clerk's result recorded, the sheriff's left to the canvass |
| `CC_0425` | Oregon, 2 races | Wood Village mapped onto the city's own numbering and renamed; 2 candidacies, both won |

🟢 **Empty 2026-11-03 races nationwide: 50 → 0**, measured against all 2,309 races for that date.
Occupancy baseline unmoved at 238 throughout; not one of the five migrations seats anybody.

## ✅ The last 4, worked through (2026-11-14) — `CC_0424` and `CC_0425`

### Racine County, Wisconsin — Sheriff and Clerk of Circuit Court (`CC_0424`)

The ballot was already settled from Wis. Stat. 59.20. The figures are now read, and both of the
obstacles this file recorded turned out to be **half right in a way that mattered**.

🟢 **`curl` IS NOT BLOCKED BY `racinecounty.gov`. A `User-Agent` ALONE IS NOT "A BROWSER."** The
note above said the 403 persisted with a browser User-Agent and a Referer, and it did. The WAF
wants the whole header set: `Accept`, `Accept-Language`, `sec-ch-ua`, `sec-ch-ua-mobile`,
`sec-ch-ua-platform`, the four `Sec-Fetch-*` headers and `Upgrade-Insecure-Requests`. With those it
answers 200 and the PDF. ▶ **Before escalating to Playwright, send the headers a browser actually
sends** — the fetcher in `CC_0424`'s header lists them.

🔴🔴 **THE "OFFSET BY ONE BLOCK" WAS NOT A PROPERTY OF THE PDF, IT WAS THE READER PAIRING IN
CONTENT-STREAM ORDER.** The names and figures are all there and all correct; what is wrong is any
reader that walks the stream, because the generator emits a label and its value at different
baselines. ▶ The fix is to pair **geometrically**: `read-racine-pdf.mjs` clusters glyph runs by
their `y` and reads each row left-to-right by `x`, so a row is a row of the printed table whatever
order the stream emitted it in. **Every number became readable at once.** ⚠ The same hazard is
recorded against the Massachusetts city PDFs and the Oregon 2024 abstract; this is the fix for all
three shapes, not a Racine workaround.

**Sheriff** (88 of 88 precincts): Cary A. Madrigal (REP) **39,609**, Donald E. Vandervest (DEM)
**42,048**, write-in 166, Total Votes 81,657.
**Clerk of Circuit Court** (88 of 88): Amy Vanderhoef (REP) **54,674**, write-in 3,011, Total Votes
54,674.

🟢 **READ THREE INDEPENDENT WAYS** (`verify-racine.mjs`): positional extraction; the page rendered
to an image at 150dpi and read as a picture; and the 104-page **Statement of Votes Cast**, both its
own printed total rows and the **sum of its 89 per-ward rows**. The ward sums close exactly.
⚠ **Racine's "Total Votes" EXCLUDES write-ins** — 39,609 + 42,048 = 81,657 with the 166 outside it.
That is this clerk's convention, not a convention; close the arithmetic.
⚠ **The control was watched failing first, unprompted**: given the wrong page range it reported
Vanderhoef **44,255** against 54,674. A **partial sum** is the failure mode a ward tally has, and it
reads like two sources disagreeing rather than like a short read. ▶ A tally must state how many rows
it summed.

🔴 **"FINAL UNOFFICIAL" IS THIS PUBLISHER'S TERMINAL DOCUMENT, NOT A STAGE.** Every election on
Racine's results page back to 2018 carries the word — one is even headed "UNOFFICIAL Certification
Report". The county publishes no canvassed document at all. **Waiting for "official" from this
source waits for ever**, so the word carries no information and must not be read as one.

**The clerk's result is recorded; the sheriff's is not.** Unopposed, Vanderhoef's contest is
**forced** — the whole write-in line read as one person loses by 51,663. The sheriff's margin is
2,439 and **nobody calls it**: AP's Wisconsin file holds **131 races across Governor, Attorney
General, Secretary of State, Treasurer, U.S. House, State Senate, State Assembly and Question, and
not one county office** — measured, not assumed. A margin is not a bound.
⚠ Wisconsin is an **in-hand** state (an absentee ballot must reach the clerk by 8 p.m. on election
day), so there is no late-arriving pool and 100% of precincts have reported. That makes the margin
very likely safe — and *very likely* is still not a bound, because provisionals are cured afterwards
and are not published here. ▶ **Record the sheriff from the canvass** (below).

### Wood Village, Oregon — our Seat 1 and Seat 2 (`CC_0425`)

**The charter and the city's own roster dissolve all three problems, and two of them were not
problems.** Sources are committed under `sources/or-wood-village-{charter,council-roster}-2026-11-14.txt`.

1. ⚠ **"We hold 2 offices for a council that numbers at least 4 positions" — we do not.** We hold
   **five** offices in that chamber and Charter §8 prescribes **five councilors**; our roster and the
   city's are the same five people. The gap was an artefact of looking only at the two offices that
   carried an empty race. ▶ **Count the whole body before calling it incomplete.**
2. 🔴 **A ROTATING CHAIR DOES NOT ALWAYS EAT A SEAT, AND WHICH IT DOES IS A COUNTING QUESTION.**
   John Miner *was* made mayor by the council in January 2023 — Charter §10 has the council elect a
   mayor **from its members** at the first meeting of each odd-numbered year, so that is exactly
   when one is chosen, and it is a chair, not a seat. With five offices holding five councillors it
   costs nothing. In the Maine cities the same shape **did** eat a seat, because the body's size was
   already accounted for. ▶ The two facts ("he was made mayor" / "Rios-Campos is mayor") never
   conflicted: that mayoralty ran to early 2025.
3. 🟢 **THE NUMBERING MISMATCH IDENTIFIES THE MAPPING RATHER THAN BLOCKING IT.** §9 staggers the five
   seats **three-and-two**; the roster shows exactly **two** terms ending 12/31/2026, Miner's and
   Gothard's; the ballot carries exactly **two** contests, Positions 1 and 4; and **Gothard stands in
   Position 1**, so the seat she holds *is* Position 1. By elimination Miner's is Position 4, where
   Christine Bierman stands unopposed and Miner does not stand at all.
   🟢 **The charter also predicts a NEGATIVE that the ballot confirms**: a council-chosen mayor means
   there can be no mayoral contest, and there is none. A rule that says which contests must be
   **absent** is worth more than one that only says what may appear — the same shape as Wis. Stat.
   59.20 predicting Racine's missing Register of Deeds.

Both contests are **forced** (unopposed, write-in line below the named candidate): Gothard 802
(write-in 32) and Bierman 810 (write-in 28), both recorded won/called.

**Both races were renamed** to the city's own numbering — `Seat 1` → **Position 4**, `Seat 2` →
**Position 1** — because "Seat N" names seats the city does not have and no voter saw those numbers.
The old values are in `CC_0425`'s header; there is no history table for `races.position_name`.

✅ **The two wrong office TITLES are now fixed — `CC_0426`, below.** `CC_0425` left them alone on
purpose: widening a ballot seed to carry an occupancy-labelling edit would have mixed two unrelated
acts.

### ✅ Wood Village's council labels (`CC_0426`, 2026-11-13)

We called one office `Mayor` and one `Council President`. Under Charter §10 the council elects the
mayor **from its own members**, so neither is a seat voters fill — both are roles a sitting
councilor holds. The repo had already ruled on exactly this shape: `seed-me-municipal-2026/
ROSTERS.md` R5/R9, applied by `CC_0292` across six Maine cities, where the fix was `Mayor` →
`At-Large N`. Both offices are now `City Councilor`, like the other three.

🟢 **WOOD VILLAGE IS THE EASY HALF OF THAT SHAPE, WHICH IS EXACTLY WHY IT SURVIVED.** In all six
Maine cities the phantom office **ate** a seat, so the council came out one short and the shortfall
looked like an ordinary vacancy — an arithmetic defect something could count. Here the phantom
office **is** the fifth seat: five offices, five councilors, nothing missing. ▶ **A labelling defect
with no arithmetic consequence is invisible to every gate in this repo.** Only reading the body's
own charter against its own roster finds one.

🔴 **The `Mayor` row was three claims, not one, and renaming it alone would have left two standing.**

1. the **title** said the city elects a mayor;
2. **`is_appointed_position = true`**, and the API publishes `is_elected` as the negation of it
   (`essentialsService.ts`, plus seven mappers in `essentialsBrowseService.ts`) — so this council
   seat was being served to voters as **not elected**, against Charter §9. Measured on the live
   endpoint before the fix and after: `is_elected` went `false` → `true`;
3. it sat alone on a **second district**, `Wood Village (Citywide)`, typed **`LOCAL_EXEC`**, while
   the other four sat on `Wood Village (At-Large)`, `LOCAL`. That type is not decoration — it is how
   this repo says "this row is the municipality's executive" (`audit-district-urls.mjs` says so
   outright), and 228 of the 309 offices on the 266 `LOCAL_EXEC` districts are mayor-titled. The
   office was moved to the council's district and the executive district **deleted**.

⚠ **Address search never changed, and that was not a reason to skip any of it.** `districtQueries.ts`
admits `LOCAL` and `LOCAL_EXEC` through the same geofence arm and both rows carried the same
`geo_id`, so a Wood Village address returned all five seats throughout. The defect was in what the
five rows **said**.

🔴 **The emptied district could not simply be left behind.** `check-address-reachability.mjs` is
**master-only**, so it fails on the next PR and names an innocent author; Oregon has **no bucket of
any kind** in `address-reachability-baseline.json` and the gate fires on any new one. And
`DEAD_GEOGRAPHY` requires `offices > 0`, so an emptied district would have slipped past that check
specifically — leaving a polygon-backed row that resolves nobody for a later session to seat
something into by mistake. `CC_0426` carries the Oregon-wide check into its own post-verify.

🟢 **The delete lost nothing, and that is measured rather than asserted.** The two district rows were
identical in **every** column but `id`, `label` and `district_type` — same `geo_id`, `ocd_id`,
population, census unit, web URL. A gate checks that while both rows still exist, so the claim is
tested against prod instead of recorded on trust. The office was repointed **first**: `districts`
has no inbound foreign key, so deleting one that still carries an office orphans it in silence, and
the delete refuses unless the row is already empty.

**The two roles are deliberately not in the schema.** There is no column for a rotating chair and a
one-city migration is the wrong place to invent one — `CC_0292` did the same, keeping Caribou's
Deputy Mayor and Bath's Chairperson in that wave's notes. Recorded here instead, as of 2026-11-13:
**Jairo Rios-Campos is Mayor** and **Dara Tan is Council President**, both roles the council confers.

**The five seats are deliberately not numbered.** The city numbers its own and `CC_0425` established
Position 1 as Gothard's and Position 4 as Miner's **from the ballot**. The 2024 ballot is what maps
the other three, so guessing which of Rios-Campos, Tan or Smith holds 2, 3 or 5 would assert a fact
about a named person that no source states.

The chamber now states its size (`official_count = 5`, Charter §8), so a sixth office or a missing
fifth becomes countable — which is the thing that would have caught this had it ever had an
arithmetic consequence.

## 🔴 One follow-up this found in someone else's wave

**Two Maine offices carry `CC_0426`'s exact residue and are not fixed here.** `CC_0292` retitled six
phantom mayors into council seats and **cleared no flags**, so — measured in prod on 2026-11-13 —
Presque Isle `Council Member (At-Large 7)` (Debra Plummer) and Rockland `Council Member
(At-Large 5)` (Adam Lachman) still read `is_appointed_position = true` and are still published to
voters as **not elected**. Both cities elect their whole council at large; the flag was true because
the row used to be the mayoralty, which the council confers.

▶ **A one-line fix, left to Maine's own pass on purpose.** Maine is a closed wave with its own notes
(`seed-me-municipal-2026/ROSTERS.md`), and reaching into two Maine cities from an Oregon migration
would put the change where nobody maintaining Maine would look for it. ⚠ **The general lesson is
`CC_0426`'s, not Maine's: a retitle is rarely only a title.** An office row states several things at
once, and the one that reaches voters here was not the name.

## ▶ Three follow-ups that wait on other people, not on us

Each carries its ballot and no outcome. **That is the finished state for a contest nobody has
called** — not an unfinished race.

- **13 uncalled Oregon contests**, because Oregon publishes no winner flag and no outstanding-ballot
  count. The counties certify within 20 days of the election and the Secretary of State's page still
  reads `UNOFFICIAL`. ▶ A results pass after that; `or-analysis-2026-11-14.json` already holds every
  vote total and margin.
- **South Tucson's general** has no winner recorded: Pima publishes a canvass for the July primary
  and none for 2026-11-03, and the second seat rests on **8 votes**. ▶ Revisit after Pima canvasses.
- **Racine County Sheriff** has its two candidates and no result: contested by 2,439, and no
  publisher calls a Wisconsin county office. The **county board of canvassers** determines county
  offices, and county canvass statements were due to the Wisconsin Elections Commission by
  **2026-11-17**. ▶ Record it from the canvass. 🔴 **Do not wait for Racine to publish a document
  saying "official"** — it never has (see above). Ask the board of canvassers' statement, the
  commission, or the clerk.

## ▶ Seating, which none of these five migrations did

Nothing in `CC_0421`–`CC_0425` seats anybody, creates a politician, or links one; the drift baseline
read 238 before and after every one. The winners take office later:

- **Wood Village**: Charter §25 — "the term of office of a person elected at a regular city election
  shall commence the first of the year immediately following the election", so **2027-01-01**.
  Charlene Gothard is already seated on that office; **Christine Bierman is a new person** and will
  need creating as well as seating.
- **Racine**: the county terms begin in **January 2027**. Our roster still seats Christopher
  Schmaling as sheriff — he was on no line of this ballot — and Amy Vanderhoef as clerk.

## ⚠ Session state a fresh session should know

- 🟢 Leases `state:az` and `state:wi` are **released**. `state:or` was re-taken for `CC_0426` and is
  released again once that PR lands.
- The worktree `C:/ev-accounts-locals` exists; `CC_0421`–`CC_0425` are **merged** (PRs #1459, #1460),
  and `fix/wood-village-council-titles` carries `CC_0426`.
- `CC_0426` is **applied to production**. 🔴 Applied is not merged — it exists only as a file on that
  branch until its PR lands, and there is no `schema_migrations` table to say otherwise.
- 🔴 **`C:EV-Accounts` itself has been parked on a dead branch**, `perf/cities-summary-index-only`,
  squash-merged as PR #1345 on 2026-11-08 with its remote copy deleted. It has 0 modified tracked
  files and was **105 commits behind master** on 2026-11-14, which is why a session reading
  `CLAUDE.md` from it gets a copy 651 lines out of date — and since 2026-11-12 the occupancy and
  migration rules live in `backend/migrations/CLAUDE.md`, which such a copy does not even mention.
  ⚠ A stale root `CLAUDE.md` still names `politicians.is_incumbent`, **dropped by `CA_0378`**.
  The rule against moving HEAD in a worktree you did not create has no exit condition for a branch
  that no longer exists anywhere.
  ▶ `git switch master && git pull` there, once somebody confirms no session is live in it.
