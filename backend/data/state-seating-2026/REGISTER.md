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

| # | state | body | offices | winners | re-elected | no record | multi-seat | start date | status |
|---|---|---|---|---|---|---|---|---|---|
| 1 | MA | STATE_LOWER | 159 | 159 | 141 | 18 | — | — | 159 left |
| 2 | ME | STATE_LOWER | 149 | 149 | 88 | 61 | — | — | 149 left |
| 3 | WA | STATE_LOWER | 95 | 95 | 71 | — | — | — | 95 left |
| 4 | CA | STATE_LOWER | 75 | 75 | 60 | — | — | — | 75 left |
| 5 | MD | STATE_LOWER | 67 | 131 | 54 | 77 | 38 | — | 67 left |
| 6 | OR | STATE_LOWER | 60 | 60 | 51 | 9 | — | — | 60 left |
| 7 | MD | STATE_UPPER | 47 | 47 | 39 | 8 | — | — | 47 left |
| 8 | UT | STATE_LOWER | 42 | 42 | 30 | — | — | — | 42 left |
| 9 | NV | STATE_LOWER | 41 | 41 | 29 | 12 | — | — | 41 left |
| 10 | MA | STATE_UPPER | 40 | 40 | 37 | 3 | — | — | 40 left |
| 11 | ME | STATE_UPPER | 34 | 34 | 18 | 16 | — | — | 34 left |
| 12 | AZ | STATE_UPPER | 30 | 30 | 17 | — | — | — | 30 left |
| 13 | AZ | STATE_LOWER | 29 | 58 | 19 | — | 29 | — | 29 left |
| 14 | WA | STATE_UPPER | 23 | 23 | 16 | — | — | — | 23 left |
| 15 | CA | STATE_UPPER | 17 | 17 | 8 | — | — | — | 17 left |
| 16 | OR | STATE_UPPER | 15 | 15 | 9 | 6 | — | — | 15 left |
| 17 | NV | STATE_UPPER | 11 | 11 | 10 | 1 | — | — | 11 left |
| 18 | GA | STATE_EXEC | 10 | 10 | 1 | — | — | — | 10 left |
| 19 | AL | STATE_EXEC | 9 | 9 | 2 | — | — | — | 9 left |
| 20 | UT | STATE_UPPER | 8 | 8 | 5 | — | — | — | 8 left |
| 21 | AR | STATE_EXEC | 7 | 7 | 5 | — | — | — | 7 left |
| 22 | AZ | STATE_EXEC | 7 | 8 | 3 | — | 1 | — | 7 left |
| 23 | ID | STATE_EXEC | 7 | 7 | 7 | — | — | — | 7 left |
| 24 | NM | STATE_EXEC | 7 | 7 | 3 | — | — | — | 7 left |
| 25 | TX | STATE_BOARD_EDUCATION | 7 | 7 | 2 | — | — | — | 7 left |
| 26 | TX | STATE_EXEC | 7 | 7 | 0 | — | — | — | 7 left |
| 27 | CA | STATE_EXEC | 6 | 6 | 3 | — | — | — | 6 left |
| 28 | CO | STATE_LOWER | 6 | 6 | 5 | — | — | — | 6 left |
| 29 | NV | STATE_EXEC | 6 | 6 | 1 | — | — | — | 6 left |
| 30 | SD | STATE_EXEC | 6 | 6 | 2 | — | — | — | 6 left |
| 31 | UT | STATE_BOARD_EDUCATION | 6 | 6 | 3 | — | — | — | 6 left |
| 32 | CT | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 left |
| 33 | HI | STATE_EXEC | 5 | 7 | 4 | — | 1 | — | 5 left |
| 34 | IL | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 left |
| 35 | MA | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 left |
| 36 | MI | STATE_EXEC | 5 | 7 | 2 | — | 2 | — | 5 left |
| 37 | ND | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 left |
| 38 | NE | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 left |
| 39 | NH | STATE_BOARD | 5 | 5 | 1 | — | — | — | 5 left |
| 40 | OK | STATE_EXEC | 5 | 5 | 0 | — | — | — | 5 left |
| 41 | RI | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 left |
| 42 | SC | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 left |
| 43 | VT | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 left |
| 44 | AL | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 left |
| 45 | CO | STATE_EXEC | 4 | 4 | 0 | — | — | — | 4 left |
| 46 | FL | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 left |
| 47 | IA | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 left |
| 48 | MN | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 left |
| 49 | NE | STATE_BOARD | 4 | 4 | 0 | — | — | — | 4 left |
| 50 | NE | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 left |
| 51 | NM | STATE_BOARD_EDUCATION | 4 | 4 | 3 | — | — | — | 4 left |
| 52 | WY | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 left |
| 53 | CO | STATE_BOARD | 3 | 3 | 2 | — | — | — | 3 left |
| 54 | CO | STATE_UPPER | 3 | 3 | 2 | — | — | — | 3 left |
| 55 | DE | STATE_EXEC | 3 | 3 | 2 | — | — | — | 3 left |
| 56 | IN | STATE_EXEC | 3 | 3 | 1 | — | — | — | 3 left |
| 57 | MD | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 left |
| 58 | NY | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 left |
| 59 | CO | STATE_BOARD_EDUCATION | 2 | 2 | 2 | — | — | — | 2 left |
| 60 | LA | STATE_BOARD | 2 | 2 | 0 | — | — | — | 2 left |
| 61 | OH | STATE_EXEC | 2 | 2 | 0 | — | — | — | 2 left |
| 62 | PA | STATE_EXEC | 2 | 2 | 2 | — | — | — | 2 left |
| 63 | CA | STATE_BOARD | 1 | 1 | 0 | — | — | — | 1 left |
| 64 | KS | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 left |
| 65 | ME | STATE_EXEC | 1 | 1 | 0 | — | — | — | 1 left |
| 66 | MO | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 left |
| 67 | NH | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 left |
| 68 | OR | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 left |
| 69 | TN | STATE_EXEC | 1 | 1 | 0 | — | — | — | 1 left |

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

**The rule.** A winner who already holds one of the district's sibling offices is seated into **that**
office. Remaining winners fill remaining sibling offices in name order.

**The gate, asserted per district, before any write.** Refuse the district unless:

- every sibling office in the district shares `chamber_id`, `title`, `seats`, `voting_powers` and
  `representation_note`; **and**
- no sibling office carries a `description` that distinguishes it from its siblings; **and**
- the count of sibling offices is **at least** the number of winners.

🔴 **Maryland is the reason the gate is per district.** Maryland splits delegate districts into
lettered subdistricts (19A, 19B) that elect separately. If those arrive as distinct office rows
under one district, "fill a remaining sibling" would claim a subdistrict nobody sourced — a
wrong-seat claim about a named person. The gate is what stops that being silent.

**What it costs if wrong:** exactly that wrong-seat claim. **The gate is not optional.**

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
