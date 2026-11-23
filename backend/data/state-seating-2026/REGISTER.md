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

**51 bodies still to do · 376 offices · 1 of the 51 carry a cited start date.** Measured 2026-11-23. A body leaves this table when every seat in it is scheduled; see "What is already done".

| # | state | body | offices | winners | re-elected | no record | multi-seat | vacant | no date | start date |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | HI | STATE_EXEC | 1 | 3 | 1 | — | 1 | — | — | 2026-11-03 |
| 2 | MD | STATE_LOWER | 67 | 131 | 54 | 77 | 38 | — | 67 | — |
| 3 | MD | STATE_UPPER | 47 | 47 | 39 | 8 | — | — | 47 | — |
| 4 | AZ | STATE_UPPER | 30 | 30 | 17 | — | — | — | 30 | — |
| 5 | AZ | STATE_LOWER | 29 | 58 | 19 | — | 29 | — | 29 | — |
| 6 | GA | STATE_EXEC | 10 | 10 | 1 | — | — | — | 10 | — |
| 7 | AL | STATE_EXEC | 9 | 9 | 2 | — | — | — | 9 | — |
| 8 | AR | STATE_EXEC | 7 | 7 | 5 | — | — | — | 7 | — |
| 9 | AZ | STATE_EXEC | 7 | 8 | 3 | — | 1 | — | 7 | — |
| 10 | ID | STATE_EXEC | 7 | 7 | 7 | — | — | — | 7 | — |
| 11 | NM | STATE_EXEC | 7 | 7 | 3 | — | — | — | 7 | — |
| 12 | TX | STATE_BOARD_EDUCATION | 7 | 7 | 2 | — | — | — | 7 | — |
| 13 | TX | STATE_EXEC | 7 | 7 | 0 | — | — | — | 7 | — |
| 14 | CO | STATE_LOWER | 6 | 6 | 5 | — | — | — | 6 | — |
| 15 | NV | STATE_EXEC | 6 | 6 | 1 | — | — | — | 6 | — |
| 16 | SD | STATE_EXEC | 6 | 6 | 2 | — | — | — | 6 | — |
| 17 | UT | STATE_BOARD_EDUCATION | 6 | 6 | 3 | — | — | — | 6 | — |
| 18 | CT | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 | — |
| 19 | IL | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 20 | MI | STATE_EXEC | 5 | 7 | 2 | — | 2 | — | 5 | — |
| 21 | ND | STATE_EXEC | 5 | 5 | 5 | — | — | — | 5 | — |
| 22 | NE | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 23 | NH | STATE_BOARD | 5 | 5 | 1 | — | — | — | 5 | — |
| 24 | OK | STATE_EXEC | 5 | 5 | 0 | — | — | — | 5 | — |
| 25 | RI | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 | — |
| 26 | SC | STATE_EXEC | 5 | 5 | 3 | — | — | — | 5 | — |
| 27 | VT | STATE_EXEC | 5 | 5 | 4 | — | — | — | 5 | — |
| 28 | AL | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 | — |
| 29 | CO | STATE_EXEC | 4 | 4 | 0 | — | — | — | 4 | — |
| 30 | FL | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 | — |
| 31 | IA | STATE_EXEC | 4 | 4 | 3 | — | — | — | 4 | — |
| 32 | MN | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 | — |
| 33 | NE | STATE_BOARD | 4 | 4 | 0 | — | — | — | 4 | — |
| 34 | NE | STATE_BOARD_EDUCATION | 4 | 4 | 2 | — | — | — | 4 | — |
| 35 | NM | STATE_BOARD_EDUCATION | 4 | 4 | 3 | — | — | — | 4 | — |
| 36 | WY | STATE_EXEC | 4 | 4 | 2 | — | — | — | 4 | — |
| 37 | CO | STATE_BOARD | 3 | 3 | 2 | — | — | — | 3 | — |
| 38 | CO | STATE_UPPER | 3 | 3 | 2 | — | — | — | 3 | — |
| 39 | DE | STATE_EXEC | 3 | 3 | 2 | — | — | — | 3 | — |
| 40 | IN | STATE_EXEC | 3 | 3 | 1 | — | — | — | 3 | — |
| 41 | MD | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 | — |
| 42 | NY | STATE_EXEC | 3 | 3 | 3 | — | — | — | 3 | — |
| 43 | CO | STATE_BOARD_EDUCATION | 2 | 2 | 2 | — | — | — | 2 | — |
| 44 | LA | STATE_BOARD | 2 | 2 | 0 | — | — | — | 2 | — |
| 45 | OH | STATE_EXEC | 2 | 2 | 0 | — | — | — | 2 | — |
| 46 | PA | STATE_EXEC | 2 | 2 | 2 | — | — | — | 2 | — |
| 47 | KS | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 48 | MO | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 49 | NH | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 50 | OR | STATE_EXEC | 1 | 1 | 1 | — | — | — | 1 | — |
| 51 | TN | STATE_EXEC | 1 | 1 | 0 | — | — | — | 1 | — |

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

   🔴 **Fifteen corrections to those two templates. The applied files still carry the old shapes —
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
   - 🔴🔴 **RUN THE WRONG RULE BESIDE THE RIGHT ONE, OR THE CONTROL PASSES FOR BOTH.** A date
     control that only asks "does the computed day carry the recorded cluster?" is satisfied by
     any rule that happens to land there, and the near-miss rules in this pass are all one small
     offset away — *first* Monday where the law says second, *second* Wednesday where it says
     third, *the Thursday* where it says the Wednesday. ▶ **Compute the near-miss too, and assert
     it carries NOTHING.** Washington's seven biennia agree with the second Monday 5/6/7/12/16/23/
     25 times and with the first Monday **zero times in all seven**, which separates the two rules
     instead of merely agreeing with one. Worked in `CC_0487`'s assertion 3.
   - 🔴🔴 **A CITATION CAN BE RIGHT ABOUT THE DATE AND WRONG ABOUT THE LAW, AND NOTHING MEASURES
     IT.** Washington's constitution cannot date its legislature at all (Art. II fixes only the
     term's *length*) while Art. III § 4 names **the same day** for the state executives; the
     session statute names it a third time. Three citations, one date, one of them correct. 🔴 No
     count, digest or view can tell them apart — the defect surfaces only when a person reads the
     `authority` text. ▶ **Name the other body in a gate.** Both Washington files refuse to date
     or seat a state executive, which is the only mechanical trace the distinction leaves.
   - ⚠ **AN UNRECORDED RESULT AND AN UNDECIDED RACE ARE INDISTINGUISHABLE FROM THE SEAT.** Four
     Washington seats were on the ballot with no `won` row, and every candidate on them carried
     `result = 'advanced'` — the **August top-two primary** result, not a November one still being
     counted. ▶ **Read the `result` and `result_source` before calling a seat undecided**, name
     the seats in the file, and gate on them *staying* unrecorded: if one gains a winner the wave
     is larger and the pin is stale. Worked in `CC_0487`'s P2.
     - 🔴🔴 **AND "NO RACE ROW AT ALL" IS A THIRD, BIGGER CLASS THAT LOOKS LIKE THE OTHER TWO.**
       Utah: 2 House seats carry a race with a blank result and **31 carry no race row** — and
       Art. VI Sec. 3(1) elects the **whole** 75-seat House biennially, so all 75 were on the
       ballot as a matter of law and those 31 are *certainly* missing data. ▶ **Count seats with
       a 2026 race separately from seats that are pending, and read the body's own term clause
       to learn how many should have been up.** The constitution often turns "probably missing"
       into "certainly missing", which is what makes the gap actionable.
   - 🔴🔴 **TWO ELECTED BODIES IN ONE STATE NEED NOT SHARE A BOUNDARY, AND BORROWING IS THE
     MISTAKE.** Utah's legislature begins on "the first day of January" (Art. VI Secs. 3(2),
     4(2)); its Board of Education has no commencement in law at all, and the only dates in
     `20A-14-103` — a term that "ends January 6, 2025" and an incumbent serving until "January 2,
     2023" — are both **first Mondays**. ▶ **Refuse the body, and pin the evidence for refusing
     it**: `CC_0489`'s assertion 3c computes those two Mondays and fails if they stop agreeing,
     so the refusal is a measurement rather than an argument. ⚠ The near-miss is then live in
     that state — the first Monday is three days off in 2027 — so compute it and refuse it too.
   - 🔴🔴 **A "THE SECTION NUMBER IS PRESENT" GUARD PASSES ON A JAVASCRIPT SHELL.** `le.utah.gov`
     answers `curl` with HTTP 200 and ~26.6 KB of navigation and no section text — and carries
     the section number in the page `<title>` and in a JS variable, so the obvious guard clears
     it. ▶ **Assert on a distinctive phrase from the section's BODY.** ⚠ Two different sections
     coming back at an **identical byte count** is the tell. 🟢 **And look for the non-browser
     route before reaching for Playwright twice**: that site's own "Download Options" link gives
     an XML file plain `curl` fetches (565 and 709 bytes against the shell's 26,677) — but its
     name is **not** derivable from the page URL, so take it from the rendered page once.
   - 🔴🔴 **READ A TERM CLAUSE TO ITS FULL STOP — THE ESCAPE HATCH IS USUALLY AT THE END.** Oregon's
     Art. IV § 4(1) ends *"unless a different commencing day for such terms shall have been
     appointed by law"*, and `DATES.md` quoted it one clause short. Those words turn a fixed rule
     into a **default a statute may displace**, which is a different claim and a checkable one.
     ▶ **Then go and check it, and write down how far you looked.** Five ORS chapters were read in
     full here, not all of ORS — and the scan's positive control is that its pattern fired twice in
     one chapter while returning zero in the other four. ⚠ "Nothing found" across several
     documents is a uniform answer until something makes it go non-zero.
   - 🔴🔴 **TWO STATES CAN SHARE ONE CALENDAR DAY UNDER UNRELATED RULES, SO EVERY COUNT ABOUT THAT
     DAY IS A DELTA AND MUST NAME THE OTHER STATE'S `rule_id`.** Washington's 118 legislative seats
     start on **2027-01-11** under RCW 44.04.021, a statute; Oregon's 75 start the same day under
     its constitution; Idaho's Ada County is scheduled for it too. A gate counting rows on that day
     would have read **193** and called it success. ▶ Pin the before-image, pin the delta, and
     assert every row on the day belongs to a **named** rule — so a third state is caught rather
     than absorbed. Worked in `CC_0491` P5/assertion 6 and `CC_0493` P10/assertion 3, each with a
     control that makes the gate blind to Washington and watches it report 118 strangers.
   - ⚠ **A GATE THAT RESTATES ITS OWN EXPECTATION AS A SECOND LITERAL CAN PRINT A
     SELF-CONTRADICTION, AND ONLY A CONTROL SHOWS IT.** Two Oregon controls fired correctly and
     printed nonsense — *"starts 2023-01-09, expected 2023-01-09"*, and *"comprises House districts
     51 and 52"* while testing against 53 and 54 — because the condition and its message each held
     their own copy of the expectation. In the shipped file the copies agree, so the defect is
     invisible until something makes them disagree. ▶ **Read the expectation into one variable and
     let the condition and the message share it.**
   - 🟢🟢 **A CONTROL SUITE NEEDS A CONTROL.** "Eighteen of eighteen went red" is a uniform answer,
     and a harness that fails everything — a bad path, a dead connection, a stray argument —
     produces exactly that. ▶ **Run the UNTAMPERED chain through the same driver and require it to
     pass**, in the same run, before reporting any of the reds.
   - 🔴 **COUNT SEATS WITH A RACE SEPARATELY FROM SEATS THAT ARE PENDING, AND SAY WHICH CHECKS WERE
     IMPOSSIBLE.** Oregon is the first state in this pass with **no** results gap, and proving that
     took three different things: the constitution ("one-half, as nearly as possible" — proved
     arithmetically, 15 of 30), the state's own results export (**exactly 75 legislative contests,
     not 90**), and an honest blank where neither could answer — the classes are assigned **by
     lot**, so *which* half is up is not derivable, and we hold **no Oregon races before 2026**, so
     the complementary check is structurally unavailable. ▶ **An unavailable check is a finding.
     Record it beside the ones that passed.**
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

## ✅✅ APPLIED 2026-11-23 — Oregon, 75 offices, a shared calendar day and a clean results set

**75 offices left the queue** (451 → 376) and both Oregon legislative bodies left the table.
`OR STATE_EXEC` **stays in it on purpose** — the Governor, whose term commences on an event rather
than a day.

| order | slot | what it does | state |
|---|---|---|---|
| 1 | `CC_0491` | 75 date rows, all **2027-01-11** — 60 House, 15 of 30 Senate | ✅ applied |
| 2 | `CC_0492` | create **13** winners, link **2** sitting Oregon officials | ✅ applied |
| 3 | `CC_0493` | seat 75 winners for **2027-01-11** (60 re-elections, 15 handovers) | ✅ applied |

### 🔴🔴 A CITATION THAT STOPS ONE CLAUSE EARLY READS AS A FIXED RULE AND IS NOT ONE

`DATES.md` § OR quotes Or. Const. Art. IV § 4(1) and ends at *"as the case may be …"*. The clause
does not end there. It ends:

> … and shall continue for the full period of four years or two years, as the case may be,
> **unless a different commencing day for such terms shall have been appointed by law**.

🔴 **The constitutional date is a DEFAULT the Legislative Assembly may displace by statute.** The
elided words turn "the rule is the second Monday" into "the rule is the second Monday unless
somebody legislated otherwise", which is a different claim and a checkable one.
▶ **READ A TERM CLAUSE TO ITS FULL STOP. THE ESCAPE HATCH IS USUALLY AT THE END.**

🟢 **The hatch has not been exercised, and the one statute on point reaffirms the day.** ORS
171.051(6), on filling the back half of a Senate term, says the remaining two years *"will commence
on the second Monday in January following the general election"* — a different draftsman, in a
different code, for a different purpose, reaching for the same boundary.
⚠ **The search was BOUNDED and the bound is written down**: ORS chapters 171, 236, 249, 254 and 260
were read in full, not all of ORS. 🔴 **Its own positive control is that the same pattern fired
twice inside 171 while returning zero in the other four**, so the scan was alive on real input —
"nothing found" across four chapters is otherwise a uniform answer.

### 🔴🔴 FOUR CANDIDATE DAYS IN ONE MONTH, AND THE WRONG ONE IS A SUPERSEDED RULE

| day | what it is |
|---|---|
| **2027-01-04** | the first Monday — 🔴 **OREGON'S OWN PRE-1961 RULE** |
| **2027-01-11** | ✅ the second Monday, Art. IV § 4(1) |
| **2027-01-18** | the third Monday, the holiday for Martin Luther King, Jr.'s Birthday |
| **2027-01-19** | the Tuesday after it — **WHEN THE ASSEMBLY ACTUALLY CONVENES**, ORS 171.010(1) |

🔴 **The near miss here is not hypothetical and not borrowed from another body — it is this body's
own history.** Art. IV § 4(3) *is* the transition: a member "whose term, under the former
provisions of this section, would have expired on the **first** Monday in January 1961, shall
continue in office until the **second** Monday in January 1961."

⚠ **AND OREGON IS A STATE WHERE THE TERM START AND THE CONVENING GENUINELY DIFFER** — by eight
days — unlike Washington, Wisconsin, Maryland and California, where they fall together. Reaching
for a session date here is wrong by more than a week. `CC_0491`'s assertion 3c **measures that gap
at 8** rather than asserting it, so the separation is a number and not an argument.

### 🔴🔴 TWO STATES, ONE CALENDAR DAY, TWO UNRELATED RULES — EVERY COUNT IS A DELTA

`CC_0487`/`CC_0488` put **118 Washington seats** on **2027-01-11** under **RCW 44.04.021**, a
statute. Oregon's day comes from its **constitution**. A gate counting "rows on 2027-01-11" would
have read **193** and called it success.

▶ **Both Oregon files pin the DELTA and NAME Washington's `rule_id`**, so a third state landing on
this day is caught rather than absorbed. ⚠ Idaho's Ada County is scheduled for it too.
🟢 Two controls prove those gates read Washington's real rows rather than passing vacuously: making
each blind to `wa` reported **118 strangers**, not zero.

### 🔴 THE GOVERNOR IS REFUSED, AND A SECOND STATUTE SAYS WHY

Or. Const. Art. V § 7 hands the commencement to the Legislature, and **ORS 176.010** commences the
term *"upon the publication of the returns by the Speaker of the House of Representatives"* — an
event, and one that **cannot precede 2027-01-11**, because there is no Speaker until the new House
has organised and its members take office that day.

🔴🔴 **ORS 254.545(1) IS THE SAME REFUSAL IN STATUTE FORM.** The Secretary of State canvasses every
office *"except the office of Governor after the general election"*. Art. V § 4 says why: the
returns for Governor are "sealed up, and transmitted to the Secretary of State; **directed to the
Speaker of the House of Representatives**, who shall open, and publish them in the presence of both
houses". ▶ **Oregon's Governor is not merely undated here — the state does not canvass that race
through the same channel as the other 75.**

⚠ **And the two events are split across two sections.** ORS 176.010 attaches the successor's term
to the **publication**; **ORS 176.020** attaches the predecessor's exit to the **oath**. They agree
only because both happen the same morning. ▶ Whoever records this date must record **which event**.

### 🔴🔴 THE ONE OREGON DATE IN OUR OWN DATA LOOKS LIKE CORROBORATION AND IS NOT

`DATES.md` predicts the Governor's day from **Tina Kotek's term starting 2023-01-09**, "which was
the second Monday of January 2023". It was. 🔴 **It is still not evidence for Art. IV § 4(1), on two
counts.** It belongs to the office this pass refuses, governed by a different rule; and **its own
`source` line says what it is a date of — *"first day in office, elected"***, from a Blue Book
biography and an NGA page (`CA_0352`), not the publication of the returns and not the oath.

⚠ **So the row our own ledger reached for is itself an unlabelled date of exactly the kind
ORS 176.010/176.020 make dangerous.** ▶ **A DATE THAT AGREES IS NOT A RULE THAT AGREES.**
`CC_0491`'s assertion 5 pins that row and 3d pins the legislature's zero: **all 90 Oregon
legislative terms carry `term_start = NULL`**, so this date rests on the text alone.

### 🟢🟢 OREGON HAS NO RESULTS GAP — THE FIRST STATE IN THIS PASS — AND IT IS MEASURED, NOT INFERRED

| body | offices | with a 2026 race | with a winner | no race row |
|---|---|---|---|---|
| House | 60 | 60 | 60 | **0** |
| Senate | 30 | 15 | 15 | 15 |

⚠ **THOSE 15 ARE NOT A GAP.** Art. IV § 4(2) elects "one-half, as nearly as possible" of the Senate
biennially — 15 of 30, which `CC_0491`'s P2 proves **arithmetically** rather than asserting.
🔴🔴 **AND THE COUNT IS CONFIRMED FROM OUTSIDE OUR DATA: the Secretary of State's own results export
for this election holds exactly 75 legislative contests, not 90.** This is the inverse of Utah,
where the constitution turned "probably missing" into "certainly missing"; here it turns "possibly
missing" into **certainly complete**.

🔴 **Which half is up cannot be derived, and nothing in our data can check it.** § 4(2) assigns the
classes by the original division **BY LOT** — the 15 pending districts are 3, 4, 6, 7, 8, 10, 11,
13, 15, 16, 17, 19, 20, 24, 26: **7 odd and 8 even, not a parity class.** And our database holds
**no Oregon races at all before 2026**, so the complementary check ("were the other 15 elected in
2024?") is structurally unavailable. ▶ **Say which checks were impossible, not only which passed.**

### 🟢🟢 ALL 75 WINNERS WERE CONFIRMED AGAINST THE STATE'S OWN RESULTS, AND THE ROUTE IS REUSABLE

Our winners come from the AP race calls. Every one was compared, candidate by candidate, against
the **Oregon Secretary of State's own legislative results export**: **75 contests parsed, 75 agree,
0 disagree, 0 missing** — with one name deliberately corrupted first and the comparison watched
going red.

🟢 **AND IT IS REACHABLE WITHOUT A BROWSER.** `results.oregonvotes.gov/ResultsExport.aspx` is an
ASP.NET page whose export links are `__doPostBack` JavaScript, so **there is no GET URL for the
file**. A plain HTTP **POST** carrying the page's own `__VIEWSTATE`, `__VIEWSTATEGENERATOR` and
`__EVENTVALIDATION`, with `__EVENTTARGET = ctl00$MainContent$Legislative` and the CSV radio,
returns `Content-Disposition: attachment; filename=House and Senate.csv` — 36,024 bytes, HTTP 200,
no browser. ▶ **READ THE FORM BEFORE REACHING FOR PLAYWRIGHT.** Same lesson as Utah's XML download
in a different disguise: the machine-readable route exists and is not linked as a URL.
⚠ The export reports **"0 out of 47 Precincts Reported"** beside real vote totals. Oregon votes by
mail and does not report by precinct; that zero is not a count of anything.

### 🔴 TWO WINNERS ALREADY HAD A PERSON RECORD, AND NEITHER WAS LINKED ON A NAME

`derive-seating-wave.mjs` reported all 15 as `winner_no_record`, which is a fact about
`race_candidates.politician_id` and **not about the person**. Nevada 1 of 13; Maine 18 of 77;
Massachusetts 3 of 21; **Oregon 2 of 15**.

- **Jeff Helfrich** holds **House District 52** and wins **Senate District 26**. 🟢🟢 **Art. IV
  § 6(5) speaks of "the two representative districts comprising the senatorial district", and the
  Chief Clerk's own pairing is 2N-1 and 2N — so SD 26 = HD 51 + HD 52 and the seat he holds is
  *inside* the seat he won.** `CC_0492`'s P6 computes it. The Legislature's own member page names
  him ("Representative - Jeff Helfrich, Republican - District 52").
  - ⚠ **AND THE MASSACHUSETTS GUARD — "the surname is unique in the table" — IS FALSE HERE.** Two
    rows carry it: Jeff (Oregon HD 52) and **Beth Helfrich (North Carolina House District 98)**, an
    unrelated person. ▶ **Carry the reasoning, not the predicate. A guard that held in one state is
    not a guard.**
- **Tammy Carpenter** holds **Director, Zone 7, Beaverton School District 48J** and wins **House
  District 27**. 🔴 **Nothing structural connects a school board seat to a House seat, so this one
  is linked on a DOCUMENT**: the Secretary of State's official **Voters' Pamphlet**, Washington
  County book, prints her own filed statement — **"Prior Governmental Experience: Beaverton School
  Board Member"**.
  - ⚠ **THE PAMPHLET PRINTS TWO CANDIDATES SIDE BY SIDE AND A LINE-ORDER READ MIXES THEM.**
    `pdftotext -layout` interleaves the columns, so that line sits among her opponent's sentences.
    The columns were separated by **the document's own terminators** — each ends with "(This
    information furnished by …)" naming its own candidate. ▶ **Bound a PDF column by the document's
    structure, not by reading order.**

🔴 **The sweep that found them was given a positive control.** All 15 were checked against the
**300 sitting Oregon officeholders** this database holds, with the two known matches planted in the
same query: the scan returned exactly those two and nothing else. A sweep that returns "nothing
found" and has never been seen finding anything is not a sweep.

### 🟢 ONE WINNER VACATES A SEAT IN THIS WAVE AND IT RESOLVES ITSELF — THE UTAH CASE, FIXED

Helfrich's House District 52 has a **recorded successor**: Hank Sanders wins it in the same wave.
`seat_officeholder` closes the predecessor on the seat it is **filling**, so seating Sanders closes
Helfrich's House term at 2027-01-10 and seating Helfrich closes Christine Drazan's Senate term the
same day. **Both closures happen because a seat was filled, which is the only way these files close
anything.**

⚠ **CONTRAST WITH UTAH.** Doug Fiefia kept Utah House District 48 open after taking a Senate seat
because that seat's own 2026 **result is missing** and there was nobody to seat. ▶ **The difference
is a result, not a rule.** Oregon has no results gap, so the vacated seat closes itself.

🟢 **And one winner keeps a seat this pass does not touch, which is also correct.** Tammy Carpenter
stays a Beaverton school director — a SCHOOL seat, outside this wave, whose term has not ended. She
holds **two seats from 2027-01-11**. `CC_0493` gates on finding exactly one such term, names her,
and asserts it is still open afterwards. ▶ **Do not tidy it.**

### 🟢 Step 9 — verified AFTER the apply, from outside the migrations

| check | result |
|---|---|
| Oregon legislative seats still pending | **0** |
| Oregon Governor still pending | **1, as intended** |
| terms citing `CC_0493` | **75** |
| predecessors closed at 2027-01-10 | **75** |
| offices answering `office_next_term` | **75** |
| terms starting 2027-01-11, repo-wide | **193 = 118 WA + 75 OR** |
| `office_swearing_in` rows on 2027-01-11, repo-wide | **193**, the same split |
| Oregon state-executive terms on that day | **0** |
| politicians | 91,988 → **92,001** (+13) |
| flagged-vacant offices, repo-wide | **66**, unmoved |
| unflagged `offices_missing_terms` | **238**, unmoved |

🟢🟢 **AND THROUGH THE DEPLOYED API.** Three real addresses through `api.empowered.vote`:

- **Hood River** → **both halves of the chamber switch render on ONE page**: House District 52
  shows Jeff Helfrich held, **incoming Hank Sanders on 2027-01-11**, and Senate District 26 shows
  Christine Drazan held, **incoming Jeff Helfrich on 2027-01-11**. A voter at that address sees the
  seat he leaves and the seat he takes side by side.
- **Beaverton** → House District 27 shows Ken Helm held, **incoming Tammy Carpenter**; her
  Beaverton school directorship shows **no incoming**, because that seat was not up.
- **Portland** → House District 42 renders a re-election as **incoming-same-person** (Rob Nosse).
- ⚠ **The Governor shows NO INCOMING at all three addresses** — the refusal, visible to a voter —
  and so do Senate Districts 14 and 21, which are the staggered half not up this cycle.

🔴 **The first version of that probe reported "no incoming" for every row** and would have been
written up as a failure. The fields are `incoming_holder_name` / `incoming_on`, not an `incoming`
object. ▶ **A uniform answer is a broken detector**; the probe now refuses to report at all if it
finds no incoming holder anywhere.

### Controls, each watched going red (step 7)

🔴 Recorded by the gate each one FIRED ON, not the gate it was aimed at. **18 of 18 went red.**

🟢🟢 **AND A NEGATIVE CONTROL RAN FIRST, THROUGH THE SAME CODE PATH.** "Eighteen of eighteen went
red" is a uniform answer, and a harness failing everything — a bad path, a dead connection, a stray
argument — produces exactly that. The untampered chain was run by the same driver and came back
**green**. ▶ **A control suite needs a control.**

| # | what was broken | fired on |
|---|---|---|
| C0 | *nothing* — the untampered chain | 🟢 **passed, as required** |
| C1 | the first Monday written instead of the second | assertion **1** |
| C2 | the convening day computed as the third Monday + 2 | assertion **3b** |
| C3 | the second Monday computed as the first + 14 | assertion **3a** |
| C4 | `CC_0491` P5 made blind to Washington | **P5** — *"118 rows … are not Washington legislative rows"* |
| C5 | the federal exclusion narrowed to `NATIONAL_LOWER` | assertion **7** |
| C6 | the expected Kotek date changed to the first Monday 2023 | assertion **5** |
| C7 | House District 27 linked to Beth Helfrich (North Carolina) | **P4** |
| C8 | the Senate↔House pairing changed to 2N+1, 2N+2 | **P6** |
| C9 | Hank Sanders created under Bernie Sanders's name | **P3** |
| C10 | a winner row re-pointed at another person | **P1 digest** |
| C11 | a seat falls vacant **and** the library's published selection is used | **P1 coverage** |
| C11b | the same vacancy, with the `IS NOT NULL` fix in place | **P1 digest** |
| C12 | `CC_0493` assertion 3 made blind to Washington | assertion **3** |
| C13 | Tammy Carpenter's school term closed beforehand | **P8** |
| C14 | assertion 11 pointed at the wrong Helfrich | assertion **11** |
| C15 | one result becomes `certified` | **P11** |
| C16 | the term source stops saying "called, not certified" | assertion **15** |
| C17 | the Governor seated on the legislature's day | **P10** |

🟢🟢 **C11 AND C11b ARE THE COMPLEMENTARY-GATES PROOF, RUN ON ONE INPUT.** The same vacancy, two
selections. With the library's published selection the digest expression goes **NULL** and
`string_agg` drops the row — the **coverage** gate fires: *"the digest expression evaluated to NULL
on 1 of 75 rows"*. With `AND och.politician_id IS NOT NULL` the value becomes `false` instead and
the **digest** gate fires on a changed hash. 🔴 **Neither gate can be made to see the other's
fault. Keep both, even where neither can fire today.**

🔴 **TWO CONTROLS FIRED EARLIER THAN AIMED, AND BOTH ARE RECORDED RATHER THAN CONTRIVED AROUND.**
- **C1 fired on assertion 1**, a strict equality on the right date, so *any* wrong date trips it
  first — assertion 3b's "no seat carries a wrong day" arm is an **unreachable backstop**. Its
  *arithmetic* arms are reachable and were tested by C2 and C3.
- **C17 fired on P10**, not assertion 10. Seating the Governor beforehand makes **119** terms on
  2027-01-11, and the Washington pre-image gate catches that first. 🟢 **That is a finding, not a
  nuisance: the gate written to measure one state's rows also catches an unexpected term on that
  day from any source, including Oregon's own Governor.**

### ⚠ A GATE THAT RESTATES ITS OWN EXPECTATION AS A SECOND LITERAL CAN PRINT A SELF-CONTRADICTION

Two controls fired correctly and printed nonsense: assertion 5 said *"starts 2023-01-09, expected
2023-01-09"*, and P6 said *"comprises House districts 51 and 52"* while testing against 53 and 54.
Both messages recomputed the expectation independently of the condition, so a tamper of one left
the other saying the opposite.

▶ **Read one expression into a variable and let the condition AND the message share it.** Fixed in
both files before the apply. 🔴 **Only a control reveals this** — in the shipped file the two copies
agree, so the defect is invisible until something makes them disagree.

## ✅✅ APPLIED 2026-11-23 — Utah, 50 offices, a fixed calendar day, and a body left refused

**50 offices left the queue** (501 → 451) and both Utah legislative bodies left the table.
`UT STATE_BOARD_EDUCATION` **stays in it on purpose** — six seats with a recorded winner, no
commencement in law, and a refusal this wave did not overturn.

| order | slot | what it does | state |
|---|---|---|---|
| 1 | `CC_0489` | 50 date rows, all **2027-01-01** — 42 House, 8 Senate | ✅ applied |
| 2 | `CC_0490` | seat 50 House + Senate winners for **2027-01-01** (35 re-elections, 15 handovers) | ✅ applied |

### 🔴 THE DATE IS A FIXED DAY OF THE CALENDAR, AND THE NEAR MISS IS LIVE IN THIS STATE

Utah Const. Art. VI, Sec. 3(2) and Sec. 4(2) both read *"Their term of office shall be
[two / four] years from **the first day of January** next after their election."* No ordinal
weekday, no counting from the election.

⚠ **2027-01-01 is a Friday and a public holiday, and the clause does not care.** It names a day of
the calendar, not a sitting day; Utah's general session does not convene until the third Tuesday
in January. 🔴 Rounding it to the following Monday would be the same class of error as reaching
for a convening date.

🔴🔴 **AND THE FIRST MONDAY IS NOT A HYPOTHETICAL WRONG ANSWER HERE — THE STATE'S OTHER ELECTED
BODY APPEARS TO USE IT.** See the Board block below. For 2027 the two rules are **three days
apart**, 2027-01-01 against 2027-01-04. `CC_0489` computes both and refuses the Monday; `CC_0490`
refuses any seat on it.

### 🔴 THE BOARD OF EDUCATION IS REFUSED, AND THE STATUTE'S OWN DATES ARE THE EVIDENCE

`Utah Code § 20A-14-103` fixes the Board's term length and cycle and **names no commencement**.
Its only dates are transitional: a realigned member's term *"ends January 6, 2025"*, and an
incumbent may serve until *"January 2, 2023"*.

🔴 **BOTH ARE FIRST MONDAYS IN JANUARY**, where the legislature's boundary is the first *day*.
2023-01-02 and 2025-01-06 are exactly the computed first Mondays of those years. ▶ So **Utah's two
elected state bodies do not share a boundary**, and the Board's cannot be borrowed from the
House's. `CC_0489`'s assertion 3c computes both and refuses unless they still agree — it is the
only hard evidence available for the refusal, so it is pinned rather than argued.

🟢 **The refusal renders honestly to a voter.** Board of Education District 5 has a recorded 2026
winner and shows **no incoming**, because the seat was deliberately left undated.

### 🔴🔴 A CORRECTION TO DATES.md § UT: THE GAP IS MOSTLY MISSING **RACES**, NOT MISSING RESULTS

The ledger reads the shortfall as a result gap — "33 carry no recorded winner" of the House.
Measured against production, it is two different things and the larger one is not what the ledger
describes:

| body | offices | seated here | race, blank result | **no race row at all** |
|---|---|---|---|---|
| House | 75 | 42 | 2 | **31** |
| Senate | 29 | 8 | 1 | **20** |
| Board | 15 | 0 (refused) | 2 | 7 |

🔴🔴 **UTAH'S CONSTITUTION TURNS THE HOUSE NUMBER FROM A GUESS INTO A CERTAINTY.** Art. VI
Sec. 3(1) elects the **whole** House "biennially on even-numbered years", so all 75 seats were on
the 2026 ballot as a matter of law — and we hold a race row for 44. **The 31 are certainly missing
data**, not seats that were not up. That is a stronger statement than this pass can usually make,
and it belongs to the results programme.

⚠ **THE SENATE SHORTFALL IS REAL AND CANNOT BE SIZED FROM THE CONSTITUTION ALONE.** Sec. 4(3)
requires "as nearly one-half as may be practicable" — 14 or 15 of 29 — but adds "as the
Legislature shall determine by law with each apportionment", so **which** half is statutory and is
not in this database. We hold 9. ▶ Read that statute before asserting a number.

⚠ **THE THREE BLANK-RESULT LEGISLATIVE SEATS ARE BLANK, NOT PROVISIONAL.** House District 48,
House District 61 and Senate District 11 carry candidate rows whose `result` is **NULL** with no
`result_source` at all. Unlike Washington's four — which carried the August top-two primary result
and could be misread as a call — there is nothing here to misread. `CC_0489`'s P2 names all three
and refuses if one acquires a winner.

### 🔴🔴 ONE WINNER WILL HOLD TWO SEATS FROM 2027-01-01, AND THE MISSING RESULT IS WHY

**Doug Fiefia** holds **State House District 48** and wins **State Senate District 18**. House
District 48 is one of the three blank-result seats — he is vacating it, two newcomers contested
it, and our data records no winner. So unlike every other handover in this pass, **the seat he
leaves is not in this wave and gets no successor.**

⚠ **That is a visible consequence of a results gap, not a defect this file introduces, and it must
not be "tidied".** `seat_officeholder` closes the predecessor on the office being *seated* and
nothing else. Closing his House term would mean inventing a successor, or asserting an end date
from a clause that ends **all 75** House terms on the same day — doing it for one and not the
other 74 would be arbitrary. ▶ **The fix is the House District 48 result, not an edit here.**

Two further winners keep a seat this file does not touch: **Julie Jackson** (Granite School
District, wins House 34) and **Silvia Catten** (Millcreek City Council District 1, wins Senate 13).
`CC_0490` gates on finding exactly three and asserts all three are still open afterwards.

### 🔴 THE SOURCE SERVES A JAVASCRIPT SHELL, AND THE GUARD THE LEDGER RECOMMENDS DOES NOT CATCH IT

`le.utah.gov` returns HTTP 200 and ~26.6 KB of navigation with no section text. Both Art. VI
sections came back at **exactly 26,677 bytes** with "first day of January" absent.

🔴 **DATES.md says to "assert the section number is present before concluding a section is empty",
and that guard passes on the shell** — the shell carries the section number in its `<title>` and
again in a JavaScript variable. ▶ **Assert on a distinctive phrase from the section's body.**

🟢 **AND THERE IS A NON-BROWSER ROUTE, WHICH IS AN IMPROVEMENT ON "IT WAS READ IN A BROWSER".**
The section's own "Download Options" link gives an XML file that plain `curl` fetches — HTTP 200,
565 and 709 bytes, text identical to the rendered page:

    https://le.utah.gov/xcode/ArticleVI/UC_AVI_S3_1800010118000101.xml
    https://le.utah.gov/xcode/ArticleVI/UC_AVI_S4_1800010118000101.xml

🔴 **The XML name is not derivable from the section URL** — swapping `.html` for `.xml` 404s. Take
it from the rendered page once; after that the text is fetchable without a browser forever.

### ⚠ NO CONTROL EXISTS IN OUR OWN DATA, AND THE ABSENCE IS ASSERTED

**All 119 Utah legislative and Board terms carry `term_start = NULL`.** Nothing here corroborates
or contradicts 2027-01-01. `CC_0489`'s assertion 3d pins that zero so a future reader cannot
believe a check was made that could not be made, and `CC_0490`'s P7 refuses if a predecessor has
acquired a start date since.

▶ **A consequence worth stating:** `CC_0490` writes 50 term *ends* onto rows with no beginning.
That is the state Utah is in, not damage this file did, and assertion 6b asserts it.

### 🟢 Step 9 — verified AFTER the apply, from outside the migrations

| check | result |
|---|---|
| Utah legislative seats still pending | **0** |
| Board of Education seats still pending | **6**, as intended — refused, undated, unseated |
| terms on 2027-01-01 citing `CC_0490` | **50** |
| predecessors closed at 2026-12-31 | **50** |
| offices answering `office_next_term` | **50** |
| Board terms carrying any start date | **0** |
| politicians | **91,988**, unmoved — Utah needed no people file |
| flagged-vacant offices, repo-wide | **66**, unmoved |
| unflagged `offices_missing_terms` | **238**, unmoved |

🟢🟢 **AND THROUGH THE DEPLOYED API.** Three real addresses through `api.empowered.vote`:

- **13011 S Pioneer St, Herriman** → **House District 48 shows Doug Fiefia `held` with no
  incoming.** That is the blank-result seat rendering honestly. Senate District 17 and Board
  District 9 likewise show no incoming — both are seats with no 2026 race row at all.
- **12830 S 1700 W, Riverton** → **Senate District 18 shows Daniel McCay `held`, incoming Doug
  Fiefia on 2027-01-01.** Put beside the Herriman page, the double-seat case renders exactly as
  `CC_0490` documents it. ⚠ **Board of Education District 9 shows no incoming** although six Board
  seats have recorded winners — the refusal, visible to a voter.
- **451 S State St, Salt Lake City** → re-elections render as incoming-same-person on 2027-01-01
  (House District 24, Senate District 9), and **Board District 5 — which HAS a recorded 2026
  winner — shows no incoming**, because `CC_0489` deliberately left it undated.

### Controls, each watched going red (step 7)

🔴 Recorded by the gate each one FIRED ON, not the gate it was aimed at.

| # | file | the tamper | fired on |
|---|---|---|---|
| 1 | `CC_0489` | the first MONDAY written where the clause says first DAY | **1**, not 3b — see the note below |
| 2 | `CC_0489` | "next after their election" read as the same year | **3a**, computing 2026-01-01 |
| 3 | `CC_0489` | the near-miss formula itself broken | **3b**, naming 2027-01-11 as a wrong wrong-rule |
| 4 | `CC_0489` | the Board's 2025 transitional date read as a first DAY | **3c**, the boundary evidence |
| 5 | `CC_0489` | a Board of Education seat given the legislature's date | **4**, the refusal |
| 6 | `CC_0489` | a blank-result seat dated | **5** |
| 7 | `CC_0489` | the no-corroboration gate pointed at Washington | **3d**, reading 265 real rows |
| 8 | `CC_0489` | *(free, real)* applied, then dry-run again | **P0**, 50 of 50 already dated |
| 9 | `CC_0490` | a winner swapped for another real person | **P1 digest** — every count above it passed |
| 10 | `CC_0490` | a seat made holderless **and** the `IS NOT NULL` fix removed | **P1 coverage**, 1 of 50 rows NULL |
| 11 | `CC_0490` | a predecessor acquires a `term_start` | **P7**, the undated-tenure gate |
| 12 | `CC_0490` | a kept outside term closed early | **P8**, 2 where 3 are required |
| 13 | `CC_0490` | House District 48's result lands, pin re-derived | **P4** — see the chain below |
| 14 | `CC_0490` | Fiefia's vacated House seat "tidied away" after the write | **11**, 2 of 3 still open |
| 15 | `CC_0490` | a Board member seated on the legislature's day, deltas moved to match | **10** |
| 16 | `CC_0490` | *(free, real)* applied, then dry-run again | **P2**, 50 rows already cite CC_0490 |

🔴 **CONTROL 1 FIRED ON ASSERTION 1, NOT ON THE GATE IT WAS AIMED AT, AND THAT IS WORTH RECORDING
RATHER THAN RETRYING.** Assertion 1 is a strict equality on the right date, so *any* seat carrying
the wrong one trips it first. **3b's "no seat carries the first Monday" arm is therefore an
unreachable backstop** while assertion 1 stands; its two *arithmetic* arms are reachable and
controls 2 and 3 tested them. The same is true of `CC_0490`'s assertion 9.

🟢🟢 **CONTROL 13 FOUND SOMETHING BETTER THAN THE GATE IT WAS AIMED AT: A REFUSED DATE IS ITSELF AN
INTERLOCK.** The tamper recorded a winner for House District 48 and re-pinned the digest, as a
real re-derivation would. It did not reach P9 — it stopped at **P4**, because `CC_0489`
deliberately wrote no `office_swearing_in` row for that seat. ▶ **A seat refused a date cannot be
silently seated by a later file**, and the chain is three deep: the digest gate, then P4, then P9.
P9 is a named backstop whose value is its *message*, not its reachability.

---

## ✅✅ APPLIED 2026-11-23 — Washington, 118 offices, two files and no companion

**118 offices left the queue** (619 → 501) and both Washington bodies left the table. Two files,
both applied; **no third file waits on a date**, because no Washington state office is flagged
`is_vacant` — the first state in this pass to need no companion of the `CC_0480` / `CC_0486` kind.

| order | slot | what it does | state |
|---|---|---|---|
| 1 | `CC_0487` | 118 date rows, all on **2027-01-11** — 95 House, 23 Senate | ✅ applied |
| 2 | `CC_0488` | seat 118 House + Senate winners for **2027-01-11** (87 re-elections, 31 handovers) | ✅ applied |

### 🔴🔴 THE AUTHORITY IS A STATUTE, AND THE CONSTITUTION NAMES THE SAME DAY FOR SOMEBODY ELSE

Every state before this one in the pass was dated from its constitution. **Washington's
constitution cannot date its legislature at all**: Art. II §§ 5–6 fix the *length* of a
legislative term and never its start. The answer is **RCW 44.04.021** — *"The regular term of
office of each senator and representative shall commence on the second Monday in January following
the date of election."*

🔴 **AND THE PROVISION THAT LOOKS LIKE THE ANSWER GIVES THE RIGHT DATE FROM THE WRONG LAW.** Art.
III § 4 says *"The terms of all officers named in section one of this article shall commence on the
second Monday in January after their election"* — the executives, on the same day. A file that
cited it for a legislator would be correct about 2027-01-11 and wrong about why, and **no count,
digest or view could tell**. That is the shape of a citation defect: it fails only when somebody
reads it. Both files carry a gate refusing to date or seat a Washington executive, and both were
watched firing.

⚠ **The session convenes the same day too** (RCW 44.04.010), which is a third plausible-looking
citation for the same date. 44.04.021 is the one that says when the *term* begins; Maine is this
pass's proof the two can be different days.

### 🔴 A CORRECTION TO DATES.md § WA: THE OFF-DATES ARE NOT ALL APPOINTMENTS, AND THE LEDGER MISSED A SEAT

Two things in the sourcing write-up did not survive re-measurement. Neither changes the date;
both change what a later reader would believe.

1. **The ledger explains all 53 non-second-Monday rows as "appointments to vacancies". 26 are.
   The other 27 start on January 1st** and come from the Ballotpedia half of the source, which
   writes the first of the year when it knows only the year. 🔴 **Two of the 27 fall in EVEN
   years (2014 and 2016), where no regular Washington legislative term can begin at all** — which
   is the evidence that they are imprecise rather than real. Filed as a precision artifact, not a
   second rule, and asserted in `CC_0487` so the next reader cannot take 27 rounded dates for
   corroboration.

2. **The ledger says three House seats carry no recorded winner. There are four, and the fourth
   is in the Senate.** DATES.md framed all 26 non-pending Senate seats as mid-term. 25 are;
   **Legislative (Senate) District 35 was on the 2026 ballot** (Drew C MacEwen against Carolina
   Mejia) and has no recorded result.

### ⚠ FOUR SEATS ARE UNRECORDED, NOT UNDECIDED — AND THE TWO LOOK IDENTICAL

    Legislative (House) District 12   State Representative (Position 1)
    Legislative (House) District 23   State Representative (Position 1)
    Legislative (House) District 25   State Representative (Position 2)
    Legislative (Senate) District 35  State Senator

Every candidate row on all four carries `result = 'advanced'` — the **August top-two primary**
result. The November result was never written, while the other 114 seats in the two chambers do
carry a `won` row, so the general-election feed did run. 🔴 **Nothing here licenses inferring a
winner**: not `advanced`, not incumbency, not the primary margin — and two of the four had
primaries inside 600 votes. This is the results programme's work. `CC_0487`'s P2 names all four
and **refuses if one has since acquired a winner**, because the wave would then be larger than 118
and `CC_0488`'s pin stale. That gate was watched firing, naming Senate District 35.

### 🟢 THE CONTROL DISCRIMINATES BETWEEN THE TWO RULES INSTEAD OF AGREEING WITH ONE

94 Washington legislative terms already in `office_terms`, from the Legislature's own member web
service, retrieved by a pass that never read this statute. For seven biennia the computed second
Monday carries a cluster and the computed **first** Monday — one `+ 7` away, a real Monday in the
right month — carries **nothing**:

| cycle | second Monday | rows there | first Monday | rows there |
|---|---|---|---|---|
| 2013 | 2013-01-14 | 5 | 2013-01-07 | **0** |
| 2015 | 2015-01-12 | 6 | 2015-01-05 | **0** |
| 2017 | 2017-01-09 | 7 | 2017-01-02 | **0** |
| 2019 | 2019-01-14 | 12 | 2019-01-07 | **0** |
| 2021 | 2021-01-11 | 16 | 2021-01-04 | **0** |
| 2023 | 2023-01-09 | 23 | 2023-01-02 | **0** |
| 2025 | 2025-01-13 | 25 | 2025-01-06 | **0** |

▶ **A control that only confirmed the right rule would have passed for both rules.** `CC_0487`
runs both columns in a loop and refuses on either.

### 🟢 THE `is_reelection` NULL CANNOT OCCUR HERE, AND THE GATE IS IN THE FILE ANYWAY

All 147 Washington legislative seats are held and every winner already had a `politicians` row, so
the defect California and Massachusetts paid for has nothing to bite on: both digests were
computed side by side against production and are the same string over the same 118 rows. **The fix
and the coverage gate are carried regardless**, because "it cannot happen here" is a measurement
that expires the moment a seat falls vacant.

🔴 **AND THE TWO GATES TURN OUT TO BE COMPLEMENTARY, NOT REDUNDANT.** One control made a seat
holderless and ran the file twice:

- **with the fix** — `is_reelection` goes true → **false**, the digest changes, and the *digest*
  gate catches it.
- **without the fix** — `is_reelection` goes **NULL**, the row vanishes from `string_agg`, the
  digest would have covered **117 of 118 rows**, and only the *coverage* gate catches it.

Neither gate can see the other's fault. That is why the coverage gate stays in a file where it is
unreachable: it is unreachable *because* of the fix, and a gate added only where the defect is
already known is the gate that will be missing the first time it matters.

### 🔴 EIGHT WINNERS ALREADY HOLD A SEAT, SIX MOVE, AND TWO KEEP WHAT THEY HAVE

Six move inside the legislature, and **every seat they vacate is itself in this wave**:

    Alex Ybarra        House LD 13  → Senate LD 13
    Chipalo Street     House LD 37  → Senate LD 37
    Cindy Ryu          House LD 32  → Senate LD 32
    Jeremie Dufault    House LD 15  → Senate LD 15
    Sharlett Mena      House LD 29  → Senate LD 29
    Nikki Torres       Senate LD 15 → Senate LD 8   ⚠ SENATE TO SENATE

⚠ **Nikki Torres is a sitting senator winning a different Senate district, and the seat she leaves
is the one Jeremie Dufault wins.** A reader who assumed a mover is always a House member moving up
would mis-read that row. The incumbency guard's scope is a UNION of winners and predecessors for
exactly this reason — 118 + 118 people resolve to **143**, and the six are what the UNION removes.

🔴 **TWO WINNERS COME FROM CITY OFFICE AND KEEP IT.** Jessica Forsythe and Vanessa Kritzer each
hold a Redmond Citywide (At-large) council seat and won a House seat. `seat_officeholder` closes
the predecessor on the office being *seated* and nothing else, so **both council terms stay open —
and that is correct**. Whether either resigns is a fact nobody in this pass has read, and ending a
term with no evidence it ended would be a claim about a real person. `CC_0488` names both, gates
on finding exactly two, and asserts both are still open afterwards.

### ⚠ WASHINGTON'S EXISTING TERM ROWS ARE TENURES, NOT TERMS

All 147 seats carry exactly one open `office_terms` row whose `term_start` is when that member
first took the seat — 1999 for the longest. So closing a predecessor at 2027-01-10 writes an end
onto a tenure that may span a quarter of a century, and for the 87 re-elected members it closes
their own tenure the day before their new term opens. Same shape as every state in this pass, and
not this file's to change.

### 🟢 Step 9 — verified AFTER the apply, from outside the migrations

| check | result |
|---|---|
| Washington state seats still pending | **0** |
| terms on 2027-01-11 citing `CC_0488` | **118** |
| predecessors closed at 2027-01-10 | **118** |
| offices answering `office_next_term` | **118** |
| offices carrying the date | **118** |
| politicians | **91,988**, unmoved — Washington needed no people file |
| flagged-vacant offices, repo-wide | **66**, unmoved |
| unflagged `offices_missing_terms` | **238**, unmoved |

🟢🟢 **AND THROUGH THE DEPLOYED API.** Three real addresses through `api.empowered.vote`:

- **501 N Anderson St, Ellensburg** → the whole chamber move on one page: Senate LD 13 shows Judy
  Warnick `held` with **incoming Alex Ybarra on 2027-01-11**, and House LD 13 Position 2 shows
  **Ybarra himself `held`, with incoming Joshua Thompson the same day** — the seat he vacates,
  filled on the day he leaves it. Position 1, Tom Dent, re-elected.
- **15670 NE 85th St, Redmond** → **Jessica Forsythe appears twice on one page**: sitting
  Councilmember Position 3 with no incoming, and the **incoming State Representative for House
  LD 48 Position 2 on 2027-01-11**, replacing Amy Walen. The two-seats case rendering exactly as
  the file intends.
- **200 Madison Ave N, Bainbridge Island** → House LD 23 Position 1 shows **Tarra Simmons `held`
  with no incoming**. That is an unrecorded November result rendering honestly rather than as a
  gap in this work. Position 2, Greg Nance, re-elected 2027-01-11.

### Controls, each watched going red (step 7)

🔴 Recorded by the gate each one FIRED ON, not the gate it was aimed at.

| # | file | the tamper | fired on |
|---|---|---|---|
| 1 | `CC_0487` | `second_mon := first_mon + 0` — the first-Monday mistake | **3a**, printing anchor *and* computed day |
| 2 | `CC_0487` | the wrong-rule gate pointed at the right-rule day | **3c**, reading 5 real rows on 2013-01-07 |
| 3 | `CC_0487` | the January-1 finding pointed at January 2nd | **3d**, reading 0 where it expects 27 |
| 4 | `CC_0487` | a date row written for House LD 12 Position 1 | **4**, the unrecorded-seats gate |
| 5 | `CC_0487` | a date row written for a WA state executive | **5**, the Art. III § 4 gate — *not* 4 or 6 |
| 6 | `CC_0487` | Senate LD 35 gains a `won` row, P1's counts moved with it | **P2**, naming Senate District 35 |
| 7 | `CC_0487` | *(free, real)* applied, then dry-run again | **P0**, 118 of 118 already dated |
| 8 | `CC_0488` | Senate LD 13's winner swapped for another real person | **P1 digest** — every count above it passed |
| 9 | `CC_0488` | a seat made holderless **and** the `IS NOT NULL` fix removed | **P1 coverage**, 1 of 118 rows NULL |
| 10 | `CC_0488` | the same seat holderless, fix retained | **P1 digest** — the complementary half |
| 11 | `CC_0488` | the pin names 2027-01-04 | **P4**, all 118 dates disagree |
| 12 | `CC_0488` | Senate LD 48 flagged `is_vacant` | **P6**, naming the missing companion file |
| 13 | `CC_0488` | a predecessor given `how_ended = 'resigned'` | **P7**, the COALESCE trap |
| 14 | `CC_0488` | a Redmond council term closed early | **P8**, 1 kept term where 2 are required |
| 15 | `CC_0488` | a WA executive seated on 2027-01-11, deltas moved to match | **10**, the Art. III § 4 gate |
| 16 | `CC_0488` | *(free, real)* applied, then dry-run again | **P2**, 118 rows already cite CC_0488 |

⚠ **Control 15 moved two delta counts with the tamper**, because assertions 3 and 14 count terms
repo-wide and would have fired two gates earlier. An author who seated an executive here would
have written those deltas as 119. One coherent mistake, not three — but it is recorded, because a
tamper that needed help to reach its gate says something about the gate.

🔴 **Control 2's tamper builder refused once**, on `IF n <> 118 THEN`, because that string occurs
twice in `CC_0487`. The builder exits non-zero when its needle is not unique, so the run that
would have "passed" on an unmodified file never happened.

---

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
