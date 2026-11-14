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

- **Seed 45 races** — 42 Oregon, South Tucson, 2 Racine — after answering the two structural
  questions above.
- **Re-point 5 Arizona races** off 2026-11-03 onto the election that actually filled those seats.
- Read Racine's vote figures from a source whose columns are not drifting.
- ⚠ Out of scope and worth noting: Multnomah County **Sheriff** and **Auditor** were both on this
  ballot and we hold **no race row for either**, so neither shows up as a gap anywhere. An office
  with no race is invisible, not incomplete.

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

# State of play, 2026-11-14 — 46 of the 50 are done, 4 are left

| | | |
| --- | --- | --- |
| `CC_0421` | Arizona, 6 rows | 5 races moved to the 2026-07-21 primary that held them; South Tucson split across both elections; 32 candidacies |
| `CC_0422` | Oregon, 21 → 7 rows | the multi-seat council contests collapsed to one race each, `seats = 3` |
| `CC_0423` | Oregon, 26 races | 102 candidacies — 18 won, 26 lost, **58 with no result** |

**Empty 2026-11-03 races nationwide: 50 → 4.** Occupancy baseline unmoved at 238 throughout; nothing
in any of the three seats anybody.

## ▶ The 4 that are left, and what is already known about each

### Racine County, Wisconsin — Sheriff and Clerk of Circuit Court

**Both were on the 2026-11-03 ballot; that part is settled.** Wis. Stat. 59.20(2)(b) puts the sheriff
on the gubernatorial cycle (2006 + 4n → 2026) and (2)(a) puts the register of deeds on the
presidential one, and Racine's own summary carries a `Sheriff` and a `Clerk of Circuit Court`
contest and **no Register of Deeds** — the statute predicts which offices appear and the ballot
matches.

What is NOT settled is the numbers, and there are two obstacles:

- 🔴 **`curl` gets 403 on `racinecounty.gov` document URLs** even with a browser User-Agent and a
  Referer, and on the alternate `racinecounty.com` host too. The file comes down inside the browser,
  where it is same-origin.
- 🔴 **The text extracted from that PDF is OFFSET BY ONE BLOCK.** It pairs `Sheriff (Vote for 1)`
  with `Amy Vanderhoef 54,674` — Vanderhoef is the **Clerk of Circuit Court** — and pairs
  `Clerk of Circuit Court (Vote for 1)` with `Yes 43,284 / No 36,344`, which is a **referendum**.
  The contest titles are usable; **not one number in that extraction may be read.**

▶ Try the **Statement of Votes Cast** rather than the Election Summary Report, or the Wisconsin
Elections Commission, or screenshot the summary pages and read them. ⚠ Press reporting has **Don
Vandervest** winning the sheriff's race over Cary Madrigal, with our roster still seating
**Christopher Schmaling** after 16 years — treat that as a lead until a county figure is read.

### Wood Village, Oregon — City Council Seat 1 and Seat 2

🔴 **Do not map these without evidence.** Three separate problems:

1. The ballot has `Councilor, Position 1` (**Charlene Gothard**, unopposed, 802) and
   `Councilor, Position 4` (**Christine Bierman**, unopposed, 810). We hold `Seat 1` and `Seat 2`.
2. Our **Seat 2's** holder is **Charlene Gothard**, who is on the ballot for the city's **Position
   1** — so our numbering is not the city's numbering.
3. Our **Seat 1's** holder is **John Miner**, who was made **Mayor by the council in January 2023**.
   That is the rotating-chair shape CLAUDE.md warns about, which *eats a council seat*. He may no
   longer hold a council seat at all.

⚠ We hold **2 offices for a council that numbers at least 4 positions**, so this is partly a
missing-office problem, not only a mapping one. ▶ Read the city's own roster and charter
(`woodvillageor.gov`; `woodvillage.municipal.codes/Charter`) before touching either row.

## ▶ Two follow-ups that wait on other people, not on us

- **13 uncalled Oregon contests** carry their ballot and no outcome, because Oregon publishes no
  winner flag and no outstanding-ballot count. The counties certify within 20 days of the election
  and the Secretary of State's page still reads `UNOFFICIAL`. ▶ A results pass after that; the
  analysis JSON already holds every vote total and margin.
- **South Tucson's general** has no winner recorded: Pima publishes a canvass for the July primary
  and none for 2026-11-03, and the second seat rests on **8 votes**. ▶ Revisit after Pima canvasses.

## ⚠ Session state a fresh session should know

- Leases `state:or`, `state:az`, `state:wi` were claimed for this work and should be released when
  it is finished.
- The worktree `C:/ev-accounts-locals` exists; the branches for `CC_0421`-`CC_0423` are merged.
- 🔴 **`C:\EV-Accounts` itself has been parked on a dead branch**, `perf/cities-summary-index-only`,
  squash-merged as PR #1345 on 2026-11-08 with its remote copy deleted. It has 0 modified tracked
  files and was **105 commits behind master** on 2026-11-14, which is why a session reading
  `CLAUDE.md` from it gets a copy 651 lines out of date. The rule against moving HEAD in a worktree
  you did not create has no exit condition for a branch that no longer exists anywhere.
  ▶ `git switch master && git pull` there, once somebody confirms no session is live in it.
