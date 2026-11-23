# State seating, 2026-11-03 — the register

**Open this before any state seating work.** It is the queue, the recipe, and the two rulings that
would otherwise be made 70 times, differently.

▶▶ **AFTER A CONTEXT CLEAR, READ [`PICKUP.md`](./PICKUP.md) NEXT** — where the pass stands, what
California needs, and the traps this pass has already paid for, on one screen.

Design: `docs/superpowers/specs/2026-11-21-transition-display-and-state-seating-design.md` §8.
Plan: `docs/superpowers/plans/2026-11-21-state-seating.md`.

> Regenerate the table with `node scripts/build-state-seating-register.mjs --write` from
> `backend/`. It rewrites only what is between the generated markers — the recipe and the rulings
> below are decisions, not measurements, and the script never touches them.

## The queue

🔴 **Dated bodies first, soonest first; undated bodies sink below all of them, largest first.** An
undated body has no deadline to be late for. Sorting a missing date as if it were a real one would
put the entire undated backlog ahead of the one body that actually has a December deadline — in
JS, `null < '2027-01-01'` is true, so this is the default behaviour and it is wrong.

<!-- BEGIN GENERATED TABLE -->

**57 bodies still to do · 619 offices · 1 of the 57 carry a cited start date.** Measured 2026-11-23. A body leaves this table when every seat in it is scheduled; see "What is already done".

| # | state | body | offices | winners | re-elected | no record | multi-seat | vacant | no date | start date |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | HI | STATE_EXEC | 1 | 3 | 1 | — | 1 | — | — | 2026-11-03 |
| 2 | WA | STATE_LOWER | 95 | 95 | 71 | — | — | — | 95 | — |
| 3 | MD | STATE_LOWER | 67 | 131 | 54 | 77 | 38 | — | 67 | — |
| 4 | OR | STATE_LOWER | 60 | 60 | 51 | 9 | — | — | 60 | — |
| 5 | MD | STATE_UPPER | 47 | 47 | 39 | 8 | — | — | 47 | — |
| 6 | UT | STATE_LOWER | 42 | 42 | 30 | — | — | — | 42 | — |
| 7 | AZ | STATE_UPPER | 30 | 30 | 17 | — | — | — | 30 | — |
| 8 | AZ | STATE_LOWER | 29 | 58 | 19 | — | 29 | — | 29 | — |
| 9 | WA | STATE_UPPER | 23 | 23 | 16 | — | — | — | 23 | — |
| 10 | OR | STATE_UPPER | 15 | 15 | 9 | 6 | — | — | 15 | — |
| 11 | GA | STATE_EXEC | 10 | 10 | 1 | — | — | — | 10 | — |
| 12 | AL | STATE_EXEC | 9 | 9 | 2 | — | — | — | 9 | — |
| 13 | UT | STATE_UPPER | 8 | 8 | 5 | — | — | — | 8 | — |
| 14 | AR | STATE_EXEC | 7 | 7 | 5 | — | — | — | 7 | — |
| 15 | AZ | STATE_EXEC | 7 | 8 | 3 | — | 1 | — | 7 | — |
| 16 | ID | STATE_EXEC | 7 | 7 | 7 | — | — | — | 7 | — |
| 17 | NM | STATE_EXEC | 7 | 7 | 3 | — | — | — | 7 | — |
| 18 | TX | STATE_BOARD_EDUCATION | 7 | 7 | 2 | — | — | — | 7 | — |
| 19 | TX | STATE_EXEC | 7 | 7 | 0 | — | — | — | 7 | — |
| 20 | CO | STATE_LOWER | 6 | 6 | 5 | — | — | — | 6 | — |
| 21 | NV | STATE_EXEC | 6 | 6 | 1 | — | — | — | 6 | — |
| 22 | SD | STATE_EXEC | 6 | 6 | 2 | — | — | — | 6 | — |
| 23 | UT | STATE_BOARD_EDUCATION | 6 | 6 | 3 | — | — | — | 6 | — |
| 24 | CT | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 | — |
| 25 | IL | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 26 | MI | STATE_EXEC | 5 | 7 | 2 | — | 2 | — | 5 | — |
| 27 | ND | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 | — |
| 28 | NE | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 29 | NH | STATE_BOARD | 5 | 5 | 1 | — | — | — | 5 | — |
| 30 | OK | STATE_EXEC | 5 | 5 | 0 | — | — | — | 5 | — |
| 31 | RI | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 | — |
| 32 | SC | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 | — |
| 33 | VT | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 34 | AL | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 | — |
| 35 | CO | STATE_EXEC | 4 | 4 | 0 | — | — | — | 4 | — |
| 36 | FL | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 | — |
| 37 | IA | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 | — |
| 38 | MN | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 | — |
| 39 | NE | STATE_BOARD | 4 | 4 | 0 | — | — | — | 4 | — |
| 40 | NE | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 | — |
| 41 | NM | STATE_BOARD_EDUCATION | 4 | 4 | 3 | — | — | — | 4 | — |
| 42 | WY | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 | — |
| 43 | CO | STATE_BOARD | 3 | 3 | 2 | — | — | — | 3 | — |
| 44 | CO | STATE_UPPER | 3 | 3 | 2 | — | — | — | 3 | — |
| 45 | DE | STATE_EXEC | 3 | 3 | 2 | — | — | — | 3 | — |
| 46 | IN | STATE_EXEC | 3 | 3 | 1 | — | — | — | 3 | — |
| 47 | MD | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 | — |
| 48 | NY | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 | — |
| 49 | CO | STATE_BOARD_EDUCATION | 2 | 2 | 2 | — | — | — | 2 | — |
| 50 | LA | STATE_BOARD | 2 | 2 | 0 | — | — | — | 2 | — |
| 51 | OH | STATE_EXEC | 2 | 2 | 0 | — | — | — | 2 | — |
| 52 | PA | STATE_EXEC | 2 | 2 | 2 | — | — | — | 2 | — |
| 53 | KS | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 54 | MO | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 55 | NH | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 56 | OR | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 57 | TN | STATE_EXEC | 1 | 1 | 0 | — | — | — | 1 | — |

<!-- END GENERATED TABLE -->

## The recipe — nine steps per body

Every one of these was done once already, by the waves that shipped with this register.

1. **Claim it.** `npm run steward --prefix backend -- claim state:<usps> --label "<body> seating"`.
   It is the only thing that stops two sessions seating the same state, and the lease is 24 hours.
2. **Source and cite the start date, and answer the oath question in writing.** The body's own
   publication: constitution, statute, or the chamber's own convening notice. A legislative journal
   settles a disagreement between aggregators.
   - 🔴 **`WebFetch` may LOCATE a document and may never be the source of a date.** Open the page.
   - 🔴 **`chambers.inauguration_rules` is a lead, not a source.** 15 chambers carry it and the
     quality is uneven: Alabama's cites `Code of Alabama § 16-3-1` and computes 2027-01-18, while
     three California executives say only *"1st Monday in the new year following election"* and
     name no authority at all. A rule row earns its way in by its own citation or not at all.
   - 🔴 **Read what the source's date is a date OF.** Some states fix the term to a calendar date
     with the oath afterwards; others begin the term **on qualification**, which IS the oath. Where
     the law says qualification, a cited oath date is the term start. Where it names a calendar
     date, the oath is a different event and must not be rendered as one. Worked both ways already:
     Wisconsin's two events fall on one day (`CC_0462`); Indiana's constitution names only the term
     (`CC_0463`).
3. **Write the date rows**, following `CC_0445` (Wisconsin) or `CC_0463` (Indiana, three rows).
   `office_swearing_in` already CHECKs that `authority` and `source` are non-empty and that `basis`
   is one of `statute` / `published` / `estimated`. 🔴 **`estimated` may not seat anybody** — the
   seating migration's P4 refuses it.
4. **Create any missing `politicians` rows**, following `CC_0352`. 211 winner rows across the pass
   have none, concentrated in Maryland (85) and Maine (77).
   - 🔴 **Check the person against the BODY'S OWN ROSTER, never a name search.** A full-name match
     is not an identity: this repository has shipped Mark Harris as NC-8, and a 2026-11-02 audit
     found the portrait on Bell CA's *Ali Saleh* was the late President of Yemen.
5. **Derive the pin.** `node scripts/derive-seating-wave.mjs --state <usps> --type <TYPE> [--type …]`.
   It prints the four pinned values and every blocker. 🔴 **A non-empty blocker list is read, not
   routed around.**
6. **Write the seating migration**, following `CC_0462` (future-dated, the normal case) or
   `CC_0464` (a term that has already started). Reserve the slot first:
   `npm run steward --prefix backend -- slot CC --purpose "..."`. 🔴 **One migration per file.**

   🔴 **Five corrections to those two templates. The applied files still carry the old shapes —
   migrations here run once and are never edited — so the fixes live in your copy, not in theirs.**

   - 🔴🔴 **CLOSE THE NULL IN `is_reelection` BEFORE YOU PIN ANYTHING.** The library's expression
     is NULL — not false — on a seat with no current holder, because `och` is LEFT JOINed and
     `true AND NULL` is NULL. `'…' || NULL` is NULL and `string_agg` SKIPS it, so **the digest
     silently covers fewer rows than the counts claim**, and it is the holderless seats it drops.
     Add `AND och.politician_id IS NOT NULL` to the selection, and add a P1 gate that counts how
     many rows the digest expression actually evaluated — `count(<the expression>)` against
     `expect_winners`. ⚠ **This is also why `derive-seating-wave.mjs` and a migration can print
     different digests for the same selection**: the script's JS renders a NULL boolean as
     'false'. California found it with 2 vacant seats of 92. Worked in `CC_0478` and `CC_0483`.
     🔴🔴 **AND CAPTURE THE PIN AFTER THE PEOPLE FILE, BECAUSE IN MASSACHUSETTS THE DEFECT DID
     NOT EXIST UNTIL THAT FILE RAN.** Both its flagged seats are won by people the people file
     creates: before it, the WINNER id is NULL too, the first conjunct is FALSE, and
     `false AND NULL` is **FALSE** — no NULL and no defect. After it, `true AND NULL` is NULL. A
     digest captured early would have been right and would have silently become wrong.
     ▶ Rehearse `dates + people + a probe that prints the digest` in one rolled-back
     transaction, and pin what the probe prints.
   - 🔴🔴 **DO NOT ASSUME ONE CLAUSE MEANS ONE DATE.** `SOURCING.md`'s queue is built on "one
     constitutional clause usually dates a state's House, Senate and executives together".
     Massachusetts' Amend. Art. LXIV § 1 is a SINGLE sentence-group naming **three** days a
     fortnight apart, so the state ships as three waves. ▶ When a clause names several groups,
     compute the **anchor** once and derive each date from it (+0, +1, +14) rather than writing
     three literals — three literals hide an error in the anchor behind two that happen to agree.
     Worked in `CC_0481`.
   - **Put `P2` ABOVE `P1`'s row count.** `P2` asks whether this file has already been applied. In
     `CC_0461` and `CC_0462` it sits *after* `P1`, and on a second apply `P1` fires first: the
     selection returns 0 rows because the seats have left `office_pending_winner`, so the operator
     is told *"the data moved under this file, re-derive the digest"* when what happened is that
     they ran it twice. Measured on both files. `P2` is not a tautology — it is unreachable, which
     is the same thing from the operator's chair.
   - **The pin carries two counts, not one.** `expect_winners` is what `P1` compares against;
     `expect_offices` is what the post-verify's "N seats scheduled" assertions compare against.
     They are equal only while every office has one winner. `derive-seating-wave.mjs` now emits
     both and warns when they differ.
   - **A Ruling-A wave needs a different selection.** `WAVE_SELECTION_SQL` keys every winner on the
     **race-carrying** office. Ruling A writes the second winner to a **different** office, so
     post-verify 1 — which joins `office_terms` back to the selection on `office_id` — would not
     find that term and the file would abort *after* writing. Build the selection with the
     **assigned** office before copying `CC_0462` for Maryland or Arizona.
   - 🔴 **Capture the predecessor rows in the pre-image, and assert what you are overwriting.**
     `seat_officeholder` does `UPDATE office_terms SET term_end = p_term_start - 1` on the
     predecessor **with no `term_end IS NULL` guard** and writes nothing to that row's `source`. So
     the new terms are recoverable by slot and **the closures are not**: undoing a declined winner
     means restoring a `term_end` that no file recorded. `CLAUDE.md` is explicit that a migration
     overwriting a value records the value it overwrote — `CA_0335` cost a production clone for
     this. Capture `(office_id, term_id, term_end, how_ended)` for every predecessor, assert
     `term_end IS NULL` across all of them, and state the count in the header.
7. **Watch one control fail.** Not optional and not ceremony — a gate nobody has seen go red is not
   a gate. `CC_0461`'s control found that `CC_0453`'s P2 was dead code; `CC_0462`'s moved the
   nationwide holder digest; `CC_0464`'s seated the wrong person into a seat. 🔴 **Assert the
   tamper is PRESENT before trusting the verdict** — a tamper that did not apply looks exactly like
   a pass.
8. **Dry run, confirm the rollback reverted, apply, and READ the gate's output.** Not its exit code.
9. **Verify and report.** Both views (`office_pending_winner` → 0 for the body,
   `office_next_term` → the full count), the 238 unflagged drift baseline unmoved, and **one live
   address through the deployed API**. 🔴 **Reasoning about a read path is not measuring it.** Then
   refresh the live transition tracker artifact in place, and regenerate this register.

## Ruling A — a multi-member seat is assigned by incumbent anchor, under an interchangeability gate

🔴 **This is a claim about real people's seats. Read it before you rely on it.**

**71 offices carry more than one winner**, holding 169 winners between them — Maryland's House (38
offices), Arizona's House (29, every pending one), and four executives in Michigan, Arizona and
Hawaii. The cause is structural: a multi-seat race attaches **all** its winners to **one** office
row, so the winner-to-seat mapping is not in the data.

The display could decline to claim a mapping, and does. **A seating cannot** — a term row names one
person and one office.

**What makes an arbitrary assignment honest here.** Measured on Arizona House District 1: the
district's two office rows are both titled `State Representative`, both held, and identical in
every column. Nothing distinguishes one from the other except who currently sits in it. Where that
holds, the seats carry no separate public identity, so assigning a winner to a sibling office makes
no claim a voter could see as wrong.

**The eligible set.** Not "the district's offices" — **the offices that could receive this race's
winners**: same `district_id`, same `chamber_id`, same `title` as the race's own office. Everything
below is asserted over that set, and a single-winner office is exempt from all of it.

**The rule.** A winner who already holds one of the eligible offices is seated into **that** office.
Then, and only under the gate below, the remaining winners fill the remaining eligible offices in
`office_id` order.

**The gate, asserted per race, before any write.** Refuse unless **all** of:

- every eligible office shares `seats`, `voting_powers` and `representation_note`, and none carries
  a `description` that distinguishes it from the others; **and**
- 🔴 **the count of eligible offices EQUALS the number of winners.**

🔴🔴 **THE SECOND CLAUSE USED TO READ "AT LEAST" AND THAT WAS THE DEFECT.** For a **staggered**
body — one that elects part of itself each cycle — "at least" is the condition that *permits* the
error, not the one that catches it.

**The worked counter-example, measured in production: the Arizona Corporation Commission.** Five
office rows, one district, all titled `Commissioner`, `seats` / `description` /
`representation_note` all NULL and `voting_powers` identical on every one — so every
interchangeability clause **passes**. The 2026 race carries `seats = 2` and two winners, **Clara
Pratte and Jonathon Hill, neither of whom holds any of the five**. Under "at least", 5 ≥ 2 passes
too, no winner anchors, and the rule falls through to "fill the remaining offices" — where all five
are remaining. Two sitting commissioners with two to six years left would be closed out and
replaced on the page, while the two actually leaving stayed. **There are ten ways to choose two of
five and one of them is right.**

Under equality the race is refused, which is correct: **a body with more eligible seats than
winners is staggered, and which seats are up is not in our data at all.** Such a body is seated only
by naming each winner's office from **the body's own published term table**, cited in the migration
— which is `CLAUDE.md`'s existing rule: *"Attach the race to the office of the member who is
actually leaving, sourced from the body's own term table."*

🔴 **Maryland is why the gate is per race and not per body.** Maryland splits delegate districts
into lettered subdistricts (19A, 19B) that elect separately. If those arrive as distinct office
rows, "fill a remaining eligible office" would claim a subdistrict nobody sourced.

⚠ **Only `title` and `chamber_id` presently discriminate anything.** Measured across all 190 sibling
office rows in multi-winner state-tier districts: `seats` non-null **0**, `description` non-null
**0**, `representation_note` non-null **0**, `voting_powers` one distinct value. The other three
clauses are insurance against a future row, not checks that have ever fired. Do not read the
five-column list as five independent assurances.

⚠ **Scoping to the eligible set is also what unblocks the innocent.** Hawaii's OHA district holds
nine offices across six titles. A gate asserted over the whole district refuses all of them —
including Kalei Akaka's and Carmen Hulu Lindsey's **single-seat, single-winner re-elections**, which
need no ruling at all. Scoped to the race's own title, those two proceed and OHA's At-large race —
three winners, one of whom (Ikaika Anderson) holds no eligible office — is refused by the equality
clause, which is the right answer for it.

### The corrected gate, measured against every multi-winner body in the pass

| verdict | offices | bodies |
|---|---|---|
| **admit** — eligible offices = winners | **67** | AZ House (2 winners, 2 eligible) · MD Delegate (2/2) · MD Delegate (3/3) |
| **refuse** — staggered, not assignable from our data | **4** | AZ Corporation Commission (2 winners, 5 eligible) · HI OHA At-large Trustee (3/4) · MSU Trustee (2/8) · MI State Board of Education (2/8) |

🔴 **All four of the refused bodies were ADMITTED by the "at least" clause.** The defect was not one
state's edge case; it was every staggered body in the pass. Arizona is the one where it would have
shown first, because neither of its winners holds an eligible office, so nothing would have
anchored and the fall-through would have chosen two of five seats outright.

**What it costs if wrong:** a named sitting official unseated on our pages in favour of somebody who
did not win their seat. **The gate is not optional, and the equality clause is the whole of it.**

## Ruling B — a wave seats from a `called` result, and records which it was

**1,943 of the 1,945 November winners are `called`, not `certified`**, so waiting for certification
means shipping nothing. `CC_0453` already seated 427 House seats from called results and that
precedent stands.

So each wave records, in its pin block and its header, **how many of its rows were `called` on the
day it ran** — `derive-seating-wave.mjs` prints the split — and **every term's `source` carries the
migration slot**, asserted in the post-verify. When a canvass reverses one, the rows are recovered
with `source LIKE '%CC_XXXX%'` rather than from memory.

**What it costs if wrong:** a term written for somebody a recount unseats. Recoverable, because the
rows are findable by slot. Invisible if the certainty is not recorded — which is why it is.

## ✅✅ APPLIED 2026-11-23 — Massachusetts, 204 offices, ONE CLAUSE AND THREE DATES

**204 offices left the queue** (823 → 619) and all three Massachusetts bodies left the table.
Five files applied; a sixth is written and waits for 2027-01-06.

| order | slot | what it does | state |
|---|---|---|---|
| 1 | `CC_0481` | 204 date rows — 199 on **2027-01-06**, 2 on **2027-01-07** (noon), 3 on **2027-01-20** | ✅ applied |
| 2 | `CC_0482` | create 18 legislative winners, **link 3** sitting officials | ✅ applied |
| 3 | `CC_0483` | seat 199 House + Senate winners for **2027-01-06** (178 re-elections, 21 handovers) | ✅ applied |
| 4 | `CC_0484` | seat Governor + Lieutenant Governor for **2027-01-07** | ✅ applied |
| 5 | `CC_0485` | seat Attorney General, Treasurer and Receiver-General, Auditor for **2027-01-20** | ✅ applied |
| 6 | `CC_0486` | clear `is_vacant` on 1st Franklin and 17th Middlesex | ⏳ **WAITS FOR 2027-01-06 — refuses to run before then, by interlock** |

### 🔴🔴 THE QUEUE'S OWN ASSUMPTION IS FALSE HERE: ONE CLAUSE NAMED THREE DAYS, A FORTNIGHT APART

`SOURCING.md` is built on "one constitutional clause usually dates a state's House, Senate and
executives together". **Mass. Const. Amend. Art. LXIV § 1, as appearing in Amend. Art. LXXXII, is
a single sentence-group that names three different days:**

    2027-01-06   House (159) and Senate (40)          "the first Wednesday in January"
    2027-01-07   Governor, Lieutenant Governor (2)    "at noon on the Thursday next following
                                                       the first Wednesday in January"
    2027-01-20   Attorney General, Treasurer, Auditor "the third Wednesday in January"

🔴 **A FILE THAT COPIED THE HOUSE'S DATE ONTO THE ATTORNEY GENERAL WOULD PUT HER IN OFFICE TWO
WEEKS EARLY**, and nothing downstream would look wrong. ▶ All three dates are computed from **one
anchor** — the first Wednesday — plus 0, +1 and +14, so `CC_0481` computes the anchor and derives
the rest rather than writing three literals. **Three literals would hide an error in the anchor
behind two that happened to agree.**

⚠ **"Third" is plus 14, not plus 7**, and plus 7 gives 2027-01-13 — a real Wednesday in the right
month, entirely plausible in the column. `CC_0481`'s assertion 3b refuses that explicitly.

⚠ **TWO SUPERSEDED VERSIONS OF THE ARTICLE ARE PRINTED ON THE SAME PAGE AND BOTH READ PLAUSIBLY.**
All three carry the same three-way split, so a reader who stopped at the first would get the right
days for the wrong reason — but Art. LXIV as adopted and Art. LXXX both put the governor on a
**two-year** term. 🔴 **2026 is a Massachusetts gubernatorial year only under Art. LXXXII**, so
which version is in force decides whether the Governor is on this ballot at all.

### ⚠ THE CORROBORATION IS THIN, AND WHICH PART IS THIN IS RECORDED

🟢🟢 **ONE RECORDED TERM PINS ALL THREE DATES, BECAUSE ALL THREE COME FROM ONE ANCHOR.** Maura
Healey's governorship starts **2023-01-05** in `office_terms`, backfilled by migration 1459 from a
pass that never read this clause. That is "the Thursday next following the first Wednesday in
January 2023" — and it is that date *only if* the anchor is the 4th. So a single row measures the
anchor exactly, and the other two dates are that anchor plus 0 and plus 14.

🟢 The House Journal for the convening of the 193rd General Court
(`malegislature.gov/Journal/House/193/hj01042023.pdf`, read 2026-11-22) says it convened "on the
**first Wednesday of January**, being the fourth day of the year two thousand twenty-three" — the
rule and the day it produced, in the body's own words, for a cycle this pass does not write.

⚠ **THE THIRD-WEDNESDAY OFFSET HAS NOTHING BUT THE CLAUSE AND A NEWS DATELINE.** Not one of those
three offices carries a `term_start` anywhere in our database, and **no Massachusetts legislative
term is dated either** — `CC_0481`'s assertion 3d asserts that absence, so a future reader cannot
mistake it for a check that was made. Campbell, Galvin and Goldberg were sworn on 2023-01-18, the
third Wednesday, per Boston Globe/WGBH/Boston.com datelines. **A dateline is not a document, and
it is written into every row `CC_0485` creates** so the weakness travels with the data.

### 🔴 TWENTY-ONE WINNERS HAD NO PERSON RECORD, AND THREE OF THEM ALREADY EXISTED

`winner_no_record` means "no record in **this race**", never "no record anywhere". Nevada: 1 of 13.
Maine: 18 of 77. **Massachusetts: 3 of 21.** The whole table was swept twice — by surname across
every row including archived ones, and on `full_name` containing both names.

🔴 **AND THE SWEEP IS NOT THE EVIDENCE.** Each link rests on a structural fact, asserted by a gate:

- **Kate Lipper-Garabedian** (32nd Middlesex → Fifth Middlesex) and **Erika Uyterhoeven**
  (27th Middlesex → Second Middlesex) each currently hold a House seat **that is itself in this
  wave and won by a different, newly created person**. `CC_0482`'s **P5** measures exactly that, so
  "she vacated her seat to run for the Senate" is a measurement and not a story.
- **Ben Ewen-Campen** holds a Somerville ward seat and wins a Somerville House seat; **P6** asserts
  his surname is unique in the table, because an exact full-name match is only evidence while it is
  the only one.

### 🔴🔴 ONE NAME WAS DELIBERATELY *NOT* LINKED, AND THE DUPLICATE WAS WRITTEN DOWN

The 34th Middlesex winner is **"Will Mbah"**. The table already holds **"Wilfred N. Mbah"**, a
Somerville councilor seeded in the same batch as Ewen-Campen (`external_id` -2562535003 against
-2562535008), and the 34th Middlesex is a Somerville seat. **They are very probably the same
person.**

🔴 **"VERY PROBABLY" IS NOT EVIDENCE, AND THE NAMES DO NOT MATCH.** Somerville's own council roster
and the councilor's own page (both read 2026-11-23, HTTP 200) write him "Wilfred N. Mbah" and
**never once "Will"**. No document consulted ties the two names to one person.

▶ **So a new row was created and the suspected duplicate was recorded in that person's own
`source`, with the merge named as owed.** The two errors are not symmetric: **a duplicate is a
visible, reversible gap that `reference_person_merge_policy` exists to resolve; a wrong link
publishes a false claim about a named real person.** `CC_0482`'s **P7** refuses to link that id at
all, and assertion 3 refuses unless the source text records the duplicate — *a duplicate nobody
wrote down is a duplicate nobody will merge*.

### ⚠ THE VACANT SEATS ARE NOT CALIFORNIA'S SHAPE, AND THE DIFFERENCE IS IN THE PRE-IMAGE

1st Franklin District (vacant since 2026-01-20) and 17th Middlesex District (2026-03-19) carry
**no `office_terms` row whatsoever** — California's two carried a *closed* term from the member who
resigned. So:

- the pre-image is **197, not 199**, and nothing of theirs is overwritten because there is nothing
  to overwrite. `CC_0483`'s **P7** asserts the count and names the two exceptions; **P8** asserts
  they really have no term row, since the 197 depends on it;
- `CC_0483` writes their **first ever term**, which takes them out of `offices_missing_terms`.
  Assertion 16 asserts **both** halves — the unflagged 238 unmoved *and* the view down by exactly
  two — because "the baseline held" and "the view shrank by two" are different claims.

🔴 **A LEFT JOIN NEARLY MANUFACTURED A FINDING HERE.** Reading the two offices through
`LEFT JOIN office_terms` returned a row with `term_start NULL, term_end NULL, how_ended NULL`,
which reads exactly like an open placeholder term held by nobody. There is no such row anywhere in
the repo — `politician_id IS NULL` on `office_terms` returns **0** — and those were the join's own
NULLs. ▶ **Before believing a row shaped like a defect, check the row exists.**

### 🔴 THE `is_reelection` NULL IS BACK, AND MASSACHUSETTS MAKES IT WORSE THAN CALIFORNIA DID

The library's `is_reelection` is NULL on a seat with no current holder, and `string_agg` drops a
NULL silently, so the pinned digest covers fewer rows than every count reports. California found it.

⚠ **IN MASSACHUSETTS IT DOES NOT EXIST UNTIL THE PEOPLE FILE RUNS.** Both flagged seats are won by
people `CC_0482` creates. *Before* that file the winner id is NULL too, the first conjunct is
FALSE, and `false AND NULL` is **FALSE** — no NULL, no defect. *After* it, the winner id exists and
the holder is NULL, and `true AND NULL` is **NULL**. Measured in one transaction:

| selection | digest | rows actually in the digest |
|---|---|---|
| as published, after `CC_0482` | `2169c36f62827dbca2a510829595ab51` | **197** |
| with `AND och.politician_id IS NOT NULL` | `ae5a242989f59dbc0249571223ec378e` | **199** |

▶ **A DIGEST CAPTURED BEFORE THE PEOPLE FILE WOULD HAVE BEEN RIGHT, AND WOULD HAVE SILENTLY BECOME
WRONG WHEN THAT FILE RAN.** Capture the pin after the people file, close the NULL in the selection,
and **count what entered the aggregate** — `CC_0483`'s P1 does all three.

### 🟢 Step 9 — verified AFTER the apply, from outside the migrations

| measurement | result |
|---|---|
| Massachusetts state seats still in `office_pending_winner` | **0** (was 204) |
| terms citing `CC_0483` / `CC_0484` / `CC_0485` | **199 · 2 · 3** |
| predecessors closed 2027-01-05 / 01-06 / 01-19 | **197 · 2 · 3** |
| Massachusetts offices answering `office_next_term` | **204** |
| politicians | 91,970 → **91,988** (+18) |
| 1st Franklin / 17th Middlesex still flagged `is_vacant` | **2**, as intended |
| unflagged `offices_missing_terms` | **238**, unmoved |

🟢🟢 **AND THROUGH THE DEPLOYED API.** Two real addresses through `api.empowered.vote`:

- **24 Beacon St, Boston** → all three dates on one page, which is the whole Massachusetts claim:
  Senator Michael F. Rush `held`, **incoming Persis S. Yu on 2027-01-06** (one of the 18 created);
  Representative Rob Consalvo re-elected, same day; **Governor Maura Healey → 2027-01-07**;
  **Attorney General, Treasurer and Auditor → 2027-01-20**. ⚠ The **Secretary of the
  Commonwealth** shows William Francis Galvin with **no incoming**, which is the missing 2026
  result rendering correctly rather than a gap in this work.
- **14 Court Sq, Greenfield** → **1st Franklin District, `seat_status=vacant`, incoming
  Lora L. Wondolowski on 2027-01-06.** The seat is honestly empty today and the handover is dated.

### Controls, each watched going red (step 7)

🔴 Recorded by the gate each one FIRED ON, not the gate it was aimed at.

| tamper | gate it fired on | what it proves |
|---|---|---|
| `CC_0481` gives the third-Wednesday officers the LEGISLATURE's date | `CC_0481` **1** | the two-week error, caught at the row level |
| `CC_0481`'s anchor shifted a week | `CC_0481` **3a** | 🟢 the anchor is computed and checked; 3b and 3c sit behind it |
| a new person collides on `(first_name, last_name)` | `CC_0482` **P3** | the duplicate-name guard's own predicate, run before the insert |
| a chamber switcher linked to someone holding a MA seat **not** in this wave | `CC_0482` **P5** | 🟢🟢 **the link rests on structure, not on the name** — this is the gate that makes the three links evidence rather than assertion |
| `CC_0483` restores the library's published `is_reelection` | `CC_0483` **P1 NULL-count gate** | 🟢 the digest covers 199 rows or the file stops: *"evaluated to NULL on 2 of 199 rows"* |
| `CC_0483` pinned to the Attorney General's day | `CC_0483` **P4** | the seating file READS the recorded date; the fortnight gap cannot be crossed by a pin |
| `CC_0483` clears both vacancy flags while seating | `CC_0483` **11** | the `DEAD_GEOGRAPHY` act, stopped |
| `CC_0484` pinned to the legislature's day | `CC_0484` **P4** | same, one day out instead of fourteen |
| `CC_0485` pinned to the legislature's day | `CC_0485` **P4** | the Attorney General two weeks early, refused |
| `CC_0486` run unchanged, today | `CC_0486` **P3** | 🟢 the interlock refuses: *"1st Franklin District has 0 term(s) covering today (2026-11-23)"* |

⚠ **`CC_0482`'s P7 — "do not link Wilfred N. Mbah" — HAS NO CONTROL OF ITS OWN.** Any tamper that
links that id also changes the create count, and P1 stops it four gates earlier. It is a backstop,
not a tested gate. ⚠ **`CC_0486`'s positive path is unrehearsable before 2027-01-06 by
construction** (P3 wants a term covering today, P4 wants that term to start 2027-01-06). Its body
was rehearsed with `CURRENT_DATE` read as the 6th and passed assertions 1–5; **assertion 6 reads
`office_current_holder`, whose own clock is out of reach, so it runs for the first time on the
day.**

## ✅✅ APPLIED 2026-11-23 — California, 99 offices, three files and one that waits

**California is the largest state written in this pass so far, and the first with no people file
at all.** Every one of the 99 winners already had a `politicians` row, so step 4 of the recipe
was skipped outright. **99 offices left the queue** (922 → 823) and all four California bodies
left the table.

| order | slot | what it does | state |
|---|---|---|---|
| 1 | `CC_0477` | 99 date rows — 92 on **2026-12-07** (`Cal. Const. art. IV, § 2(a)(3)`), 7 on **2027-01-04** (`art. II, § 20`) | ✅ applied |
| 2 | `CC_0478` | seat 92 Assembly + Senate winners for **2026-12-07** (68 re-elections, 24 handovers) | ✅ applied |
| 3 | `CC_0479` | seat 6 statewide executives + Board of Equalization District 3 for **2027-01-04** (3 re-elections, 4 handovers) | ✅ applied |
| 4 | `CC_0480` | clear `is_vacant` on Assembly District 3 and State Senate District 10 | ⏳ **WAITS FOR 2026-12-07 — it refuses to run before then, by interlock** |

### 🔴🔴 THE DEFECT THIS STATE FOUND: `is_reelection` IS **NULL** ON A SEAT WITH NO HOLDER, AND A NULL SHRINKS THE DIGEST WITHOUT CHANGING A SINGLE COUNT

`scripts/lib/seating-wave.mjs` publishes `is_reelection` as

    ((win.value ->> 'id') IS NOT NULL AND och.politician_id::text = (win.value ->> 'id'))

`och` is LEFT JOINed, so on a seat with no current holder `och.politician_id` is NULL, the
comparison is NULL, and `true AND NULL` is **NULL** — not false. California is the first state in
this pass to reach that branch: Assembly District 3 and State Senate District 10 are both vacant.

🔴 **Then `'…' || NULL` is NULL and `string_agg` SKIPS NULL input**, so the in-SQL digest a
migration pastes over its own selection would have been computed over **90 of the 92 rows** —
dropping exactly the two seats whose identity is least certain — while `count(*)`,
`count(DISTINCT office_id)` and the re-election count all still read 92. Measured 2026-11-23:

| selection | digest | rows actually in the digest |
|---|---|---|
| as published | `8f11f4f3c18a8026fefca528e922629d` | **90** |
| with `AND och.politician_id IS NOT NULL` | `3c5becfefe95c6450eb4548f3cc036ec` | **92** |

⚠ **`derive-seating-wave.mjs` PRINTS THE SECOND ONE**, because its JS `digestKey` renders a NULL
boolean as `'false'`. So the script's digest and the migration's digest **disagree for exactly
this shape of row**, and they agreed on every earlier state only because no earlier state had a
holderless seat. That disagreement is how this was found: the counts matched and the two digests
did not.

▶ **`CC_0478` and `CC_0479` add `och.politician_id IS NOT NULL` to the selection**, and `CC_0478`
adds a P1 gate that counts how many rows the digest expression actually evaluated to a non-NULL
value, so a future NULL announces itself instead of shrinking the pin. 🔴 **THE NEXT STATE WITH A
VACANT SEAT MUST DO THE SAME.** Massachusetts has 2 and is next in the queue.

⚠ It is not only the digest: `p_allow_reelection => r.is_reelection` would pass NULL into
`seat_officeholder`, whose guard reads `NOT p_allow_reelection`. NULL is not TRUE, so the
re-election refusal would be **skipped rather than enforced**. It does not fire on these two
seats — neither has a term covering 2026-12-07, so the guard is never reached — but it is one
data shape away from mattering.

### 🔴 A CORRECT `is_vacant` FLAG IS NOT A BLOCKER, AND CLEARING IT EARLY IS THE MISTAKE

`derive-seating-wave.mjs` reports both seats as `flagged_vacant` blockers, and `CC_0475`'s P6
would have refused the wave outright. **Both flags are correct**: James Gallagher resigned
(Assembly District 3, term closed 2026-06-09) and Aisha Wahab resigned (State Senate District 10,
2026-09-01). The seats really are empty until 2026-12-07.

- **`CC_0478`'s P6 names the two and refuses a third**, instead of refusing any flag at all. A
  blanket refusal is the right default and the wrong rule here: it would stop a file whose data
  is correct.
- **The flag is cleared by `CC_0480`, on the day.** Each of these is the only office in its
  district, so clearing it while the seat is empty makes the district read
  `offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim `DEAD_GEOGRAPHY` in
  `check-address-reachability.mjs`, a **master-only** gate that would then fail on somebody
  else's pull request. The federal pair (TX-23, FL-20) has the same shape and `CC_0455` clears
  them on 2027-01-03.
- 🟢 **`CC_0480`'s GUARD IS AN INTERLOCK, NOT A DIARY ENTRY.** P3 refuses unless each office
  already has a term covering **today**, which becomes true on 2026-12-07 on its own. The file
  cannot be applied early and needs no reminder to be applied on time. ⚠ Its positive path is
  **unrehearsable before the day by construction** — P3 wants a term covering today and P4 wants
  that term to start 2026-12-07, and only on the 7th are both true. Its body was rehearsed with
  `CURRENT_DATE` read as 2026-12-07 and passed assertions 1–5; assertion 6 reads
  `office_current_holder`, whose own `CURRENT_DATE` is out of reach, so it runs for the first
  time on the day. **Rehearse the chain again on 2026-12-07 before applying it.**

### ⚠ Three things about California that will catch the next reader

- **The Board of Equalization seat is `STATE_BOARD` and its `chamber_id` is NULL.** 🔴 An INNER
  JOIN to `essentials.chambers` silently drops it and California reads as **98** offices instead
  of 99 — which is how it was first mis-measured. Join chambers LEFT, or not at all.
- **Fiona Ma and Eleni Kounalakis exchange offices**: the Treasurer wins Lieutenant Governor and
  the Lieutenant Governor wins Treasurer, both on 2027-01-04. Each is a winner AND a predecessor
  in the same file, which is why the incumbency guard's scope is a UNION. `CC_0479`'s assertion 6
  measures the result **from the people's side** — one term closing, one opening, two distinct
  offices each — because an exchange is the shape that leaves somebody holding two seats at once
  and no per-office count can see that.
- **Mike Gipson is out of office for 28 days, and that is correct.** His Assembly term closes
  2026-12-06 under art. IV, § 2(a)(3); his Board of Equalization term opens 2027-01-04 under
  art. II, § 20. Two clauses, two days, one person. ▶ Do not "fix" it by moving either date.

### 🟢 Step 9 — verified AFTER the apply, from outside the migrations

🔴 **A migration's own `RAISE NOTICE` is the migration marking its own homework.** Every number
below was re-measured once all three had committed.

| measurement | result |
|---|---|
| California state seats still in `office_pending_winner` | **0** (was 99) |
| terms starting 2026-12-07 citing `CC_0478` · predecessors closed 2026-12-06 | **92 · 90** |
| terms starting 2027-01-04 citing `CC_0479` · predecessors closed 2027-01-03 | **7 · 7** |
| California offices answering `office_next_term` | **99** |
| Assembly District 3 / State Senate District 10 still flagged `is_vacant` | **2**, as intended |
| unflagged `offices_missing_terms` | **238**, unmoved |

⚠ **A state-wide count of terms closed on 2027-01-03 answers 8, not 7, and the eighth is
innocent**: Santa Cruz County's Supervisor, 4th District, closed by `CC_0405` with
`how_ended = 'defeated'`. It is a county seat from another programme that happens to end on the
same day. `CC_0479`'s assertion 5 counts only the rows named in its own pre-image, which is why
it was right and the loose measurement was not.

🟢🟢 **AND THROUGH THE DEPLOYED API, NOT THE DATABASE.** *Reasoning about a read path is not
measuring it*, so three real addresses were put through `api.empowered.vote`:

- **1315 10th St, Sacramento** → Assembly District 7 and State Senate District 6 both
  `seat_status=held` with the sitting member incoming again **on 2026-12-07** (re-elections);
  **Governor Gavin Newsom, incoming Xavier Becerra on 2027-01-04**; and 🟢 the exchange
  rendering correctly on a voter's page — **Treasurer Fiona Ma, incoming Eleni Kounalakis** and
  **Lieutenant Governor Eleni Kounalakis, incoming Fiona Ma**, both on 2027-01-04.
- **411 Main St, Chico** → **Assembly District 3, `seat_status=vacant`, incoming Dom Belza on
  2026-12-07.** 🟢 That one line is the whole vacancy decision: the seat is honestly empty today
  AND the handover is dated rather than guessed. Had `CC_0478` cleared the flag, this would read
  "held by nobody".
- **701 E Carson St, Carson** → **Board of Equalization District 3, Antonio Vazquez held,
  incoming Mike A. Gipson on 2027-01-04** — the `chamber_id = NULL` seat is reachable and
  renders.
- ⚠ The Sacramento lookup also returns a **federal** "Secretary of State" row (Marco Rubio)
  beside California's. Two different offices with one title, no incoming on the federal one.
  Not this pass's business, but it reads oddly next to the state row.

### Controls, each watched going red (step 7)

🔴 **Recorded by the gate each one FIRED ON, not by the gate it was aimed at.** Two were stopped
early, and both are listed because of it.

| tamper | gate it fired on | what it proves |
|---|---|---|
| `CC_0477` implements "the Monday after January 1" as "the first Monday of January" | `CC_0477` **3c** | 🟢 **3b stayed GREEN** — the two readings agree in 2027, so only a check against a year the file does not write can see the wrong rule. This is the `chambers.inauguration_rules` error, caught |
| `CC_0477` writes the SECOND Monday in December to the 92 legislative rows | `CC_0477` **1** | the written value is checked, not assumed |
| `CC_0477`'s selection loses its `district_type` filter | `CC_0477` **P0** | ⚠ aimed at P1; **P0 stopped it two gates earlier**, because the widened selection swept in 2 school seats that already carry a 2026-11-03 row. P1 was not reached by this tamper |
| `CC_0477`'s state filter widened to `('ca','wa')` | `CC_0477` **P1** | reaches P1, which the tamper above could not: Washington's 118 seats carry no date row, so P0 stays green. "Copied it for the next state and missed a filter" |
| `CC_0478` restores the library's published `is_reelection` | `CC_0478` **P1 NULL-count gate** | 🟢🟢 **the defect this state found, caught by the gate written for it** — "the digest expression evaluated to NULL on 2 of 92 rows" |
| `CC_0478` clears both vacancy flags while seating | `CC_0478` **11** | the future-dated wave may not clear a flag; this is the `DEAD_GEOGRAPHY` act, stopped |
| `CC_0477`'s date changed to 2026-12-14 throughout, then `CC_0478` run after it | `CC_0477` **3a** | ⚠ aimed at `CC_0478`'s P4; **the previous FILE's clause check stopped it**. A tamper stopped by an earlier gate — in an earlier file — says nothing about the later one |
| `CC_0478`'s `expect_term_start` pinned to 2026-12-14 | `CC_0478` **P4** | reaches P4: the seating file READS the recorded date and compares it to its pin |
| `CC_0479`'s `expect_term_start` pinned to 2027-01-11 | `CC_0479` **P4** | the same, for the statewide wave |
| `CC_0479` re-seats the sitting officer into both exchanging offices (the swap never happens) | `CC_0479` **P1 digest** | ⚠ aimed at **P8** and assertion 6; the pinned digest caught it first |
| `CC_0480` run unchanged, today | `CC_0480` **P3** | 🟢 the interlock refuses: *"Assembly District 3 has 0 term(s) covering today (2026-11-23)"* |

🔴 **SO SAY IT PLAINLY: `CC_0479`'s P8 AND ASSERTION 6 HAVE NO CONTROL OF THEIR OWN, AND MAY NOT
BE REACHABLE BY ONE.** Any tamper that breaks the exchange also changes the selection, and the
pinned digest sits in front of both. Any tamper that leaves the selection intact leaves the
exchange correct. They are defence in depth behind a gate that does have a control — they are
**not** gates this wave has tested. ▶ Do not read the eleven red rows above as eleven tested
assertions per file. This is the register's own warning about `CC_0471`'s assertion 4, arriving
again in a different shape: **a file that pins its selection by digest makes its later named
gates unreachable by any realistic tamper.**

## ✅✅ APPLIED 2026-11-23 — the two states whose dates had already passed

**Seven files, all applied 2026-11-23.** Nevada's legislature had held its seats since
**2026-11-04** and Hawaii's OHA trustees since **2026-11-03**, so these were not future waves —
our pages were naming the predecessors. **56 offices left the queue** (1,162 → 1,106) and the
two Nevada legislative bodies left the table entirely.

| order | slot | what it does | rehearsed |
|---|---|---|---|
| 1 | `CC_0472` | 🔴 **DDL.** Widen `office_swearing_in_after_election` from `>` to `>=` | ✅✅ **APPLIED 2026-11-23** |
| 2 | `CC_0465` | NV · 52 date rows, 2026-11-04 (`Nev. Const. art. 4 §§ 3(1), 4(1)`) | ✅ applied |
| 3 | `CC_0466` | NV · create 12 winners, **link** a 13th who already exists | ✅ applied |
| 4 | `CC_0467` | NV · seat 52 (39 re-elections, **13 handovers**) | ✅ applied |
| 5 | `CC_0469` | HI · 5 date rows — 3 on **2026-11-03**, 2 on **2026-12-07** | ✅ applied |
| 6 | `CC_0470` | HI · seat the Maui and Oahu OHA trustees (At-large refused, Ruling A) | ✅ applied |
| 7 | `CC_0471` | HI · schedule Governor + Lieutenant Governor for 2026-12-07 | ✅ applied |

### 🟢 Step 9 — verified AFTER the apply, from outside the migrations

🔴 **A migration's own `RAISE NOTICE` is the migration marking its own homework.** Every number
below was re-measured in a separate session once all six had committed.

| measurement | result |
|---|---|
| NV legislature in `office_pending_winner` | **0** (was 52) |
| NV terms starting 2026-11-04 · predecessors closed 2026-11-03 · citing `CC_0467` | **52 · 52 · 52** |
| HI `STATE_EXEC` still pending | **1**, and it is the **At-large Trustee** — the Ruling A refusal, exactly where it was |
| HI OHA resident trustee terms from 2026-11-03 | **2** |
| HI executives in `office_next_term` for 2026-12-07 | **2** |
| HI Lieutenant Governor **today** / **next** | **Sylvia Luke** / **Derek Kawakami** |
| `AD15` name round-trip | **Miguel Dávila** — the accent survived |
| unflagged `offices_missing_terms` | **238**, unmoved |

🟢🟢 **AND THROUGH THE DEPLOYED API, NOT THE DATABASE.** *Reasoning about a read path is not
measuring it*, so two real addresses were put through `api.empowered.vote`:

- **500 S Grand Central Pkwy, Las Vegas NV** → *Assembly District 11, Cinthia Zermeño Moore,
  `seat_status=held`, `term_start=2026-11-04`* and *State Senate District 2, Edgar Flores,
  same date*. The voter's page now names the member who actually holds the seat.
- **415 S Beretania St, Honolulu HI** → *Lieutenant Governor, **Sylvia Luke**, `seat_status=held`,
  `incoming=Derek Kawakami`, `on=2026-12-07`*. 🟢 **That one line is the whole future-dated
  claim**: the sitting officer still holds the seat, and the handover is dated rather than
  guessed. Kalei Akaka and Carmen Hulu Lindsey read `term_start=2026-11-03`.
- ⚠ The four **At-large** trustees return their current holders with **no incoming**, which is
  the Ruling A refusal rendering correctly rather than a gap. The page names Keliʻi Akina,
  Brickwood Galuteria, Keoni Souza and John Waihee IV; two of those four are also 2026
  winners, and Ikaika Anderson holds none of them — so the seat that changes hands is Akina's
  or Waihee's and our data does not say which.

🔴 **THE QUEUE NOW SORTS THE AT-LARGE BLOCK FIRST**, because it is the only dated body left and
its date is already past. That is the register behaving correctly and it is **not** work that
can be done by sourcing: it needs OHA's own roster of term expirations.

🔴🔴 **`CC_0472` IS APPLIED FIRST, THOUGH ITS SLOT NUMBER IS LAST.**
`essentials.office_swearing_in` carried `CHECK (swearing_in_date > election_date)` — STRICTLY
after. Twenty states never touched it, so it read as a sound invariant for 1,086 offices. It is
not one: **`HRS § 13D-5` begins an OHA trustee's term ON the day of the election**, and the
constraint forbade recording a date the statute states in words. The alternative was to carry
that date as a literal in the seating file, which is the one thing this pass refuses. `CC_0469`'s
**P0** reads the constraint definition and refuses to start until it finds the widened form, so
the order is enforced by the data rather than by this table.

🟢 **`CC_0472` WAS APPLIED 2026-11-23** through the owner connection, after being rehearsed
the same way inside `BEGIN; … ROLLBACK;` and re-read afterwards to confirm the rollback had put
`>` back. Read back after the apply: the constraint reads `CHECK ((swearing_in_date >=
election_date))` and **all five of the table's other constraints are intact** — a `DROP`/`ADD` on
one constraint is the shape of change that quietly loses a neighbour, and `office_swearing_in_basis_check`
is the one enforcing *an estimate may not seat anybody* two files downstream. **No row was
written.** The six remaining files seat nobody until they are applied.

⚠ **`ev_api` CANNOT RUN DDL**, so `apply-migration-file.mjs` and `rehearse-migration-chain.mjs`
both fail `CC_0472` with *"must be owner of table office_swearing_in"*. Apply and rehearse it
through the owner connection (the Supabase MCP), inside `BEGIN; … ROLLBACK;` to rehearse. That is
why it is its own file rather than folded into `CC_0469`: folding it in would have made `CC_0469`
impossible to rehearse at all.

🟢 **A chain is rehearsed as a chain now**: `scripts/rehearse-migration-chain.mjs` runs several
files in ONE transaction and always rolls back. 🔴 **Rehearsing them separately proves nothing
and fails in the direction that reads as success** — `CC_0467`'s P4 reads dates `CC_0465` writes,
and its selection digest is taken over the politician ids `CC_0466` creates, so on its own it
measures the digest of a world that will not exist when it runs.

### Five controls, each watched going red (step 7)

| tamper | gate it fired on | what it proves |
|---|---|---|
| `CC_0465` writes 2026-11-**05** | `CC_0465` assertion **3** | Nevada and Indiana must read *"from the day next after their election"* the same way — the cross-state agreement is measured, not asserted in a comment |
| `CC_0467` pinned to 2026-11-**05** | `CC_0467` **P4** | 🟢 **the seating file READS the recorded date and does not carry a literal.** Had it carried one, this tamper would have changed what it WROTE instead of stopping it |
| `CC_0467` says **12** new holders | `CC_0467` assertion **4** | the rewritten delta assertion is live and names all 13 moving seats, Danielle Gallant's double move among them |
| HI executives given the **trustees'** date (2026-11-03) | `CC_0471` **incumbency guard** | 🟢 **it named the right person for the right reason**: *"Derek Kawakami … says is_incumbent=f, office_terms now say t"*. He was not an incumbent on election day, and a term backdated to it would have made him one |
| HI executives given **2026-11-10**, a day already past | `CC_0471` assertion **2** | a future handover must answer `office_next_term`; a past one cannot, and the file stops before the voter's page is touched |

⚠ **TWO TAMPERS FIRED ON THE WRONG GATE, AND BOTH ARE RECORDED BECAUSE OF IT.** Changing
`CC_0465`'s date was meant to reach `CC_0467`'s P4; `CC_0465`'s own assertion 3 stopped it two
files earlier. Both Hawaii tampers were aimed at `CC_0471`'s assertion **4** — *nobody was
unseated today* — and neither reached it. That is the register's own warning working: *a tamper
stopped by an earlier gate says nothing about a later one.*

🔴 **SO SAY IT PLAINLY: `CC_0471`'s ASSERTION 4 HAS NO CONTROL OF ITS OWN, AND IT MAY NOT BE
REACHABLE BY ONE.** The assertion says a future-dated seating must not move today's holder map.
Any tamper that moves the map must give the term a date in the past — and a past date trips the
incumbency guard or assertion 2 first, because a past term cannot be a *next* term. The gate is
defence in depth behind two gates that do have controls; it is **not** a gate this wave has
tested. ▶ Do not read the five green rows above as five tested assertions per file.

🔴 **`CC_0467` IS NOT `CC_0464` WITH BIGGER NUMBERS.** `CC_0464` could assert the nationwide
current-holder map **unchanged**, because all three of its rows were re-elections. 13 of
Nevada's 52 are handovers, so the map MUST move, by exactly thirteen seats. Copying that
assertion would have been the defect; `CC_0467` pins the map **outside** its 52 seats and counts
the delta **inside** them.

## What is already done

| slot | body | offices | start date | notes |
|---|---|---|---|---|
| `CC_0461` | AK Senate + NC-03 (federal, not state) | 2 | 2027-01-03 | the two seats `CC_0453` named and could not seat |
| `CC_0462` | Wisconsin — Assembly, Senate, executives | 121 | 2027-01-04 | `Wis. Const. art. XIII §1` with `Wis. Stat. §13.02(1)` |
| `CC_0463` | Indiana House — date rows only | 3 | 2026-11-04 | `Ind. Const. art. 4 §3` |
| `CC_0464` | Indiana House — the three re-elected | 3 | 2026-11-04 | the only wave whose term had already started |

### What those four waves overwrote

🔴 **Recorded here because none of the four files recorded it, and `CLAUDE.md` requires it.**
`seat_officeholder` closes each predecessor with an unguarded
`UPDATE office_terms SET term_end = p_term_start - 1`, so the previous `term_end` of **126**
predecessor rows (2 + 121 + 3) was replaced and exists in no file.

**The overwritten value was `NULL` on all 126.** That is an inference from three measurements, not
a copy of the record, and it is written down so the claim stays testable:

- all 126 now read `how_ended = 'term_expired'`, a single distinct value, and the helper
  `COALESCE`s that column — so **not one of them carried a prior `how_ended`**;
- repo-wide, 50 `office_terms` rows *are* closed with a null `how_ended`, so "closed but
  unannotated" is a shape that exists here and its absence among the 126 is informative rather than
  vacuous;
- every predecessor was a sitting officeholder whose term no earlier pass had any date to close.

⚠ **An inference is weaker than a record.** It is sufficient to reverse these four waves and it is
not the standard — step 6 above makes the next wave capture the values instead.
