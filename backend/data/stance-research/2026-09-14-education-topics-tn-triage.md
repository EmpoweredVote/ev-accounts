# The 8 education topics vs. Tennessee statute, 2026-09-14: ZERO rows, and the reason is structural

**Result: no stance rows, and none should be forced.** Four candidate statutes were read in their
enacted text and each fails to evidence a chair — in four *different* ways. This note exists so the
next pass does not re-buy the same four PDFs.

Companion to `2026-09-14-tn-ranked-choice-voting-ban.csv`, which seated 74 rows from the same
legislature with the same machinery. The contrast is the finding.

## First, two things that are NOT the obstacle

**1. The school-board rule does not block these topics.** `inform.compass_topic_roles` scopes all
eight to **`local*` + `state*`**, and there is no school-board role scope in the system at all. The
standing instruction is to skip school-board *members* until a badge ships (it has not — nothing in
essentials `src/` references one, checked 2026-09-14). State legislators are explicitly in scope.

**2. Tennessee has the statutes.** Curriculum, library materials, school safety and DEI have all been
legislated, recently, with recorded roll calls. The corpus exists.

## 🔑🔑 WHAT ACTUALLY BLOCKS THEM: the chair-matches-instrument pattern needs THREE properties

`ranked-choice-voting` worked because SB1820/HB1868 was **single-subject**, **outcome-shaped** (chair
5 is "Ban ranked-choice voting by law"; the act bans ranked-choice voting by law), and **divided**
(74-19, 26-4). Every education statute checked fails at least one, and the four failure modes are
worth naming separately because they generalise to any state:

| statute | failure | detail |
|---|---|---|
| **PC 493** (SB0623/HB0580, 2021) — "divisive concepts" | **OMNIBUS** | Its own caption: "deletes several obsolete provisions and makes various substantive changes to education laws; establishes parameters for the teaching of certain concepts related to race and sex." A vote is bundled across unrelated subject matter. Its floor record is also mostly *previous question*, *lay on the table* and *conference committee report* motions — none seatable. |
| **PC 1137** (SB2247/HB2666, 2022) — library materials | **PROCESS, NOT OUTCOME** | Expands the Textbook Commission and creates guidance, review and appeal machinery for challenged library materials. `education-library-books` chairs describe *outcomes* (keep everything / parents limit their own child / remove only on committee finding / pull pending review / remove on report). A Yes fits chairs 3, 4 **and** 5 alike. |
| **PC 367** (SB0274/HB0322, 2023) — school safety | **NEAR-UNANIMOUS** | House 95-4 and 98-0, Senate 33-0. A vote everyone casts the same way discriminates nothing. |
| **PC 458** (SB1084/HB0923, 2025) — "Dismantling DEI Departments Act" | **WRONG SCOPE** | Single-subject and properly divided (72-25, 27-6), so it passes the first two tests — and still fails. Its operative sections reach Title 4 state government, Title 5 county, Title 6 municipal, Title 7 metropolitan and **Title 49 Chapter 7, higher education**. There is **no K-12 section**. `education-equity-programs` chairs are explicitly about "the district". |

🔴 **PC 458 is the instructive one.** Read from its title — "Dismantling DEI Departments Act" — it
looks like `education-equity-programs` chair 5 verbatim ("Eliminate equity programs, training, and
staff from the district"). It is not, and only the enacted text shows that. Same class of error as
BL2026-1498 in Nashville, where a drone bill's title read expansionary and the text was restrictive.

## The remaining four, triaged without spending a fetch

- **`education-ai`** — chairs run prohibit → unrestricted classroom AI. No Tennessee statute governs
  AI in K-12 instruction. Nothing to read.
- **`education-school-budget`** — chairs are **magnitudes** tied to taxes ("raise taxes to
  significantly increase" / "modestly, without raising taxes" / "flat" / "cut overhead" / "cut
  significantly"). TISA rewrote the funding formula without a tax change, and a bill citation proves
  direction, never magnitude — the identical wall the Maryland taxes pass hit.
- **`education-gender-identity`** and **`education-charter-authorization`** — not probed. The pattern
  above is strong enough that they should be scoped against the three properties before any fetch,
  not researched hopefully.

## ⚖ The generalisable finding, which is the point of this note

**These eight ladders are written as DISTRICT-LEVEL POSTURES; the available corpus is STATE-LEVEL
STATUTE. They do not meet.** A school board decides whether to pull a challenged book; the General
Assembly decides who reviews it and who hears the appeal. Both are real, and the ladder can only
represent the first.

That is the same shape as three findings already on record — `rent-regulation` cannot hold an enacted
eviction right-to-counsel ordinance, `taxes` cannot hold a grocery-tax resolution, `gun-policy` cannot
hold a prime-sponsored resolution on arming teachers (all in ev-accounts #502 and #505). This is the
fourth and the broadest: it is eight topics at once.

▶ **Do not force seatings here.** Either the education ladders get rescoped to the level that
legislates, or these topics wait for a school-board corpus — which is itself gated on the badge.
▶ The reachable remainder of the zero-stance list is `cannabis-policy` (chairs are legal-status
levels, which statutes do set). `defense-spending` (magnitudes) and `2020-election` (belief
statements) are not reachable from votes at all.
