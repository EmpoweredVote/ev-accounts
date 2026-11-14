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
