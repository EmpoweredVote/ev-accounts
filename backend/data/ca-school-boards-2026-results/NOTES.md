# The 2026-12-11 handover — California school and community-college boards

**197 board seats take office on Friday 2026-12-11** — Cal. Educ. Code § 5017, second Friday in
December, with the organisational meeting (and the oath) anywhere in the following 15 days under
§ 35143. This is the bulk of the December local wave.

Same two counties and the same pipeline as the 2026-12-04 special districts. The fetcher, the
analyser, the bound and their controls live in
[`../ca-special-districts-2026-results/`](../ca-special-districts-2026-results/NOTES.md) — **read
that file first**; it explains why `GetElectionData` is the ballot and not the result, why the
call here is arithmetic rather than a published flag, and why the bound decides instead of the
margin. Only what is different about the school boards is written here.

## 🔴🔴 Nearly half of this wave had no election at all

**96 of the 197 races were cancelled.** Los Angeles County cancelled them for *insufficiency of
candidates*, and the seats are filled by **appointment in lieu of election** — Educ. Code § 5328
and Elec. Code § 10515. An appointee takes office exactly as if elected, on the same 2026-12-11.

So nearly half of this wave has a determinate outcome today and no result to record — and
**nothing in our data says so**. Those races sit with candidates, no winner and no explanation,
which is indistinguishable from a count nobody has read yet.

🔴 **AN ABSENCE IS NOT A FINDING UNTIL A SOURCE NAMES IT.** "No contest in the county's results"
is equally consistent with *the election was cancelled* and with *our race row is wrong about
which seat was up* — and the second would be ours to fix. All 96 were therefore checked, one at a
time, against the county's own list:

> **FINAL LIST OF CANCELED ELECTIONS — APPOINTMENT IN LIEU OF ELECTION DUE TO INSUFFICIENCY OF
> CANDIDATES**, LA County RR/CC, General Election November 3, 2026, 4 pages.
> `content.lavote.gov/docs/rrcc/documents/canceled-elections-november-2026.pdf`
> (committed here as `la-canceled-elections-final-2026-11-08.pdf`, retrieved 2026-11-08)

**96 of 96 are named on it.** `check-canceled.mjs` runs that comparison and exits non-zero on any
race it cannot find.

⚠ **A TENTATIVE VERSION IS SERVED FROM A NEARLY IDENTICAL URL** (`…-november-2026-tentative.pdf`)
and predates the extended nomination period that closed 2026-08-12, so the two disagree. The
checker refuses any PDF whose text does not say **FINAL**.

### 🔴 We know the election was cancelled. We do NOT know who was appointed.

Our candidate rows come from the **September nomination list** and cannot answer it. **Azusa
Trustee Area 3 is the proof**: we hold two candidates for one seat and the county still cancelled
it for insufficiency, so at least one of ours never qualified.

Naming an appointee from that list would be guessing an officeholder, which is this repo's most
expensive error. It needs each district's own record — a board resolution or minutes naming the
appointee. **That is the next real piece of work in this wave, and it is research per district,
not a results pass.**

⚠ The county's list also names **4 cancelled school seats we hold no 2026-12-11 race for at all**.
That is a seeding gap, reported by `check-canceled.mjs` and not acted on here.

## State as of 2026-11-08 (`CC_0378`)

| | races | |
| --- | --- | --- |
| **recorded** | **49** | 59 seats, 59 won / 63 lost, all `called` |
| cancelled — appointment in lieu | 96 | all 96 confirmed on the county's final list |
| held, margin inside the bound | 48 | LA certifies 2026-12-01 |
| held, district spans a county line | 4 | see below |
| **total** | **197** | |

**The four cross-county districts**, each flagged by the county in the contest's own text:
Antelope Valley Community College Area 2 and Antelope Valley Joint Union High Area 1 (**Kern**),
Las Virgenes Unified (**Ventura**), Rowland Unified Area 5 (**Orange**). Los Angeles publishes
only its own slice; ranking a board on part of its electorate is the Wrightwood trap from
`CC_0377` and is refused here too. ▶ Each needs that county's own results before it can be called.

## Two matcher defects this wave paid for

🔴 **FULL-NAME EQUALITY CANNOT SEE A MIDDLE NAME, AND THE COUNTY PRINTS THE LONG FORM.** Our
"Cheryl Williams" is Inglewood's `CHERYL SHAW WILLIAMS`; our "Brandon Myers" is
`BRANDON GEORGE MYERS`. On exact equality **both** Inglewood contests came back as if nobody on
our ballot was on the county's — the same shape as a genuinely missing contest. The matcher now
also compares first-plus-last, and **asserts the relaxation stays one-to-one inside a contest**
before any of it is trusted; the migration repeats both checks in SQL.

🔴 **OUR ROWS ARE A NOMINATION LIST; THE COUNTY'S BALLOT IS THE BALLOT.** Four races hold a
candidate the county never printed — **Joe Radabaugh** (La Cañada Unified), **Alfonso Morales**
(Lynwood Unified), **Rick Phillips** (Palos Verdes Peninsula Unified) and **Tomas Ursua** (Pomona
Unified Area 1). Set *equality* reported all four as "no county contest", lumping them in with the
cancelled races, so three different conditions read as one bucket. The anchor is now the county's
ballot being **contained in** our rows, with each direction reported separately, because they mean
opposite things:

- someone of **ours** missing from the ballot is a candidacy to resolve — a **warning**;
- someone on the **ballot** we do not hold is a **winner we could miss** — and **blocks**.

⚠ Those four rows are **left untouched**. "Never filed" means deleting the row and "withdrew"
means setting `candidate_status`; they are opposite acts and need a source neither the results
feed nor this list provides.

## 🔴 Three parser bugs, and all three read as findings about the county

The cancelled-list checker reported 24, then 5, then 3 races as "not on the county's list" before
it was right. **Every one of those was this repo's parser**, and each failure looked like a
statement about the county's document:

1. **A name was allowed to span 40 characters**, and `"TES COMMUNITY COLLEGE DISTRICTS Cerritos"`
   is exactly 40 — so the name **swallowed the section heading** and, because the leftmost match
   wins, beat the heading alternative that started four characters later. The whole **COMMUNITY
   COLLEGE DISTRICTS** section vanished: 8 districts, 13 seats, every one reported as uncancelled.
   ▶ **Bound a parse by the document's own structure** — split on headings first, then read
   entries between the document's own parentheses.
2. **`"1, 2, and 5"` dropped the last area** of every entry with three or more, losing 11 real
   seats; and `"C, E, and B U/T ending 12/28"` needed the trailing words read as part of the same
   list item, not as another one.
3. **Embedded font and CMap streams leaked printable fragments between pages**, so the first
   district on page 2 parsed as `"AdobeUCS  Glendora"`. ▶ A font program's dictionary carries
   `/Length1`; a ToUnicode CMap says `begincmap`. **The document itself says which streams are
   page content** — no blacklist of junk strings.

The checker now refuses to run unless it can see three specific entries it must be able to see:
a plain one, one whose area is the last of three, and one from the section the first draft lost.

## 🟢 The migration's own allowance caught its author

`CC_0378` exempts the candidates the county's ballot omits — and **gates that exemption**. The
first draft listed all four names; three of them sit in races the file never measures, so three
quarters of the allowance was an exemption for nothing. **The dry run refused the file.**
▶ Gate the allowance, not just the rule.

## ▶ What happens next

**2026-12-01 — LA certifies.** Re-run the fetcher and analyser; record the 48 held on the bound
and upgrade everything to `certified`.

**Per district, any time — the 96 appointees.** Each district's board resolution or minutes name
the person appointed in lieu. This is the largest remaining piece of the December wave and the
only one that is not waiting on a count.

**The 4 cross-county districts** need Kern, Ventura and Orange County results.

**2026-12-11 — seat the winners and the appointees.** 🔴 `seat_officeholder` does not clear
`is_vacant`; re-election is common here, so `p_allow_reelection => true` is required (`CC_0338`);
and Educ. Code § 5017 commences the term while § 35143 puts the oath up to 15 days later — **our
existing rows record the OATH**, so decide which event is being written before writing it. That
operator decision is still open; see `../ca-2026-swearing-in/RULES.md`.

## Running the tools

```bash
node ../ca-special-districts-2026-results/fetch-county-results.mjs .
RESOLVE_FROM=<checkout>/backend/package.json node -r dotenv/config \
  ../ca-special-districts-2026-results/dump-our-rows.mjs ./our-candidacies-YYYY-MM-DD.json 2026-12-11 197 392
node ../ca-special-districts-2026-results/analyse-results.mjs . YYYY-MM-DD
node check-canceled.mjs analysis-YYYY-MM-DD.json la-canceled-elections-final-2026-11-08.pdf
node ../ca-special-districts-2026-results/emit-values.mjs analysis-YYYY-MM-DD.json [--bounds]
node controls378.mjs <migration.sql> <dry-run-migration.mjs>
```
