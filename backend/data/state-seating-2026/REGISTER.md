# State seating, 2026-11-03 — the register

**Open this before any state seating work.** It is the queue, the recipe, and the two rulings that
would otherwise be made 70 times, differently.

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

**69 bodies still to do · 1162 offices · 0 of the 69 carry a cited start date.** Measured 2026-11-22. A body leaves this table when every seat in it is scheduled; see "What is already done".

| # | state | body | offices | winners | re-elected | no record | multi-seat | vacant | no date | start date |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | MA | STATE_LOWER | 159 | 159 | 141 | 18 | — | 2 | 159 | — |
| 2 | ME | STATE_LOWER | 149 | 149 | 88 | 61 | — | — | 149 | — |
| 3 | WA | STATE_LOWER | 95 | 95 | 71 | — | — | — | 95 | — |
| 4 | CA | STATE_LOWER | 75 | 75 | 60 | — | — | 1 | 75 | — |
| 5 | MD | STATE_LOWER | 67 | 131 | 54 | 77 | 38 | — | 67 | — |
| 6 | OR | STATE_LOWER | 60 | 60 | 51 | 9 | — | — | 60 | — |
| 7 | MD | STATE_UPPER | 47 | 47 | 39 | 8 | — | — | 47 | — |
| 8 | UT | STATE_LOWER | 42 | 42 | 30 | — | — | — | 42 | — |
| 9 | NV | STATE_LOWER | 41 | 41 | 29 | 12 | — | — | 41 | — |
| 10 | MA | STATE_UPPER | 40 | 40 | 37 | 3 | — | — | 40 | — |
| 11 | ME | STATE_UPPER | 34 | 34 | 18 | 16 | — | — | 34 | — |
| 12 | AZ | STATE_UPPER | 30 | 30 | 17 | — | — | — | 30 | — |
| 13 | AZ | STATE_LOWER | 29 | 58 | 19 | — | 29 | — | 29 | — |
| 14 | WA | STATE_UPPER | 23 | 23 | 16 | — | — | — | 23 | — |
| 15 | CA | STATE_UPPER | 17 | 17 | 8 | — | — | 1 | 17 | — |
| 16 | OR | STATE_UPPER | 15 | 15 | 9 | 6 | — | — | 15 | — |
| 17 | NV | STATE_UPPER | 11 | 11 | 10 | 1 | — | — | 11 | — |
| 18 | GA | STATE_EXEC | 10 | 10 | 1 | — | — | — | 10 | — |
| 19 | AL | STATE_EXEC | 9 | 9 | 2 | — | — | — | 9 | — |
| 20 | UT | STATE_UPPER | 8 | 8 | 5 | — | — | — | 8 | — |
| 21 | AR | STATE_EXEC | 7 | 7 | 5 | — | — | — | 7 | — |
| 22 | AZ | STATE_EXEC | 7 | 8 | 3 | — | 1 | — | 7 | — |
| 23 | ID | STATE_EXEC | 7 | 7 | 7 | — | — | — | 7 | — |
| 24 | NM | STATE_EXEC | 7 | 7 | 3 | — | — | — | 7 | — |
| 25 | TX | STATE_BOARD_EDUCATION | 7 | 7 | 2 | — | — | — | 7 | — |
| 26 | TX | STATE_EXEC | 7 | 7 | 0 | — | — | — | 7 | — |
| 27 | CA | STATE_EXEC | 6 | 6 | 3 | — | — | — | 6 | — |
| 28 | CO | STATE_LOWER | 6 | 6 | 5 | — | — | — | 6 | — |
| 29 | NV | STATE_EXEC | 6 | 6 | 1 | — | — | — | 6 | — |
| 30 | SD | STATE_EXEC | 6 | 6 | 2 | — | — | — | 6 | — |
| 31 | UT | STATE_BOARD_EDUCATION | 6 | 6 | 3 | — | — | — | 6 | — |
| 32 | CT | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 | — |
| 33 | HI | STATE_EXEC | 5 | 7 | 4 | — | 1 | — | 5 | — |
| 34 | IL | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 35 | MA | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 | — |
| 36 | MI | STATE_EXEC | 5 | 7 | 2 | — | 2 | — | 5 | — |
| 37 | ND | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 | — |
| 38 | NE | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 39 | NH | STATE_BOARD | 5 | 5 | 1 | — | — | — | 5 | — |
| 40 | OK | STATE_EXEC | 5 | 5 | 0 | — | — | — | 5 | — |
| 41 | RI | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 | — |
| 42 | SC | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 | — |
| 43 | VT | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 44 | AL | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 | — |
| 45 | CO | STATE_EXEC | 4 | 4 | 0 | — | — | — | 4 | — |
| 46 | FL | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 | — |
| 47 | IA | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 | — |
| 48 | MN | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 | — |
| 49 | NE | STATE_BOARD | 4 | 4 | 0 | — | — | — | 4 | — |
| 50 | NE | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 | — |
| 51 | NM | STATE_BOARD_EDUCATION | 4 | 4 | 3 | — | — | — | 4 | — |
| 52 | WY | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 | — |
| 53 | CO | STATE_BOARD | 3 | 3 | 2 | — | — | — | 3 | — |
| 54 | CO | STATE_UPPER | 3 | 3 | 2 | — | — | — | 3 | — |
| 55 | DE | STATE_EXEC | 3 | 3 | 2 | — | — | — | 3 | — |
| 56 | IN | STATE_EXEC | 3 | 3 | 1 | — | — | — | 3 | — |
| 57 | MD | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 | — |
| 58 | NY | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 | — |
| 59 | CO | STATE_BOARD_EDUCATION | 2 | 2 | 2 | — | — | — | 2 | — |
| 60 | LA | STATE_BOARD | 2 | 2 | 0 | — | — | — | 2 | — |
| 61 | OH | STATE_EXEC | 2 | 2 | 0 | — | — | — | 2 | — |
| 62 | PA | STATE_EXEC | 2 | 2 | 2 | — | — | — | 2 | — |
| 63 | CA | STATE_BOARD | 1 | 1 | 0 | — | — | — | 1 | — |
| 64 | KS | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 65 | ME | STATE_EXEC | 1 | 1 | 0 | — | — | — | 1 | — |
| 66 | MO | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 67 | NH | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 68 | OR | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 69 | TN | STATE_EXEC | 1 | 1 | 0 | — | — | — | 1 | — |

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

   🔴 **Four corrections to those two templates. The applied files still carry the old shapes —
   migrations here run once and are never edited — so the fixes live in your copy, not in theirs.**

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
