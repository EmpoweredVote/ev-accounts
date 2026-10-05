# Knight Cities — stance programme tracker

The seeding programme ([`PROGRAM.md`](./PROGRAM.md)) deliberately excluded stances: *"No stances —
those are the next program."* This is that programme. **Update this file at the end of every
session.**

Standard: `docs/superpowers/specs/2026-09-23-stance-program-design.md`. Pipeline: the
`research-stances` skill. Every row goes to the admin review queue; nothing auto-publishes.

## Measured scope, 2026-10-02

| Tranche | Governments | Seated people | Holding a Season 2 chair before this programme |
| --- | --- | --- | --- |
| Cities | 25 | **287** | 20 (Long Beach 9, San José 11) + Detroit 1 |
| State legislatures | 16 | **2,551** | 171 (CA 116, NC 53) |
| Counties | 21 | **~302** | Miami-Dade only (13 rows) |

Order is **cities → state legislators → counties** (operator, 2026-10-02). State legislators have
far better evidence per row, but many lack portraits, and the municipal tier is the one the
programme is for.

## Slice status

| # | Slice | Members | Rows | Scored | Batch |
| --- | --- | --- | --- | --- | --- |
| 1 | Charlotte NC | 12 | 420 | 5 | `2026-10-02-knight-clt-city` (PR #856) |
| 2 | Bradenton, Miami, Tallahassee FL | 17 | 595 | 2 | `2026-10-03-knight-fl-cities` (PR #857) |
| 3 | Duluth, Saint Paul MN | 18 | 630 | 15 so far | `2026-10-04-knight-mn-cities` — **OPEN, 14/18 done: Saint Paul + Randorf, Durrwachter, Forsman, Nephew, Reinert, Kennedy** |

Eighteen chairs from 35 members. 🔴 **A low yield was the TOOLING, not the world** — re-mining with a
publisher-agnostic link extractor took Charlotte 3 → 5 and Florida 0 → 2, and attributed passages
from 22 → 122 in Florida. Price the next slice from these numbers, not from the first pass.

✅ **Slices 1 and 2 are merged** (2026-10-04): PR #855 (verifier fix), then #857, then #856. #856 had
cherry-picked only half of #855 and conflicted once #855 landed; the base was merged into it and both
verifier files were resolved to master, which is a strict superset. Charlotte’s five and Florida’s two
sit in the admin review queue awaiting human approval.

## Slice 3 — Duluth and Saint Paul, Minnesota (opened 2026-10-04)

- **18 seated people**: Duluth 9 councilors + Mayor Reinert; Saint Paul 7 councilmembers + Mayor Her.
  35 local ladders pinned into the open season (Season 2, 60 pinned, 35 at `local`). **630 rows.**
- **Baseline measured, not assumed: zero** `politician_answers` rows in the open season for all 18.
  A positive control confirmed the query shape returns rows for other politicians, so the zero is real.
- Leases: `place:2717000` (Duluth) and `place:2758000` (Saint Paul).
- Branch `knight/stances-mn`; batch `backend/data/stance-research/2026-10-04-knight-mn-cities`.

### Why Minnesota, and the claim the scope review must test FIRST

Charlotte spent 216 of its 420 rows on scope blanks, and Florida 306 of 595, because both states
preempt the whole field for firearms, municipal wages and rent regulation. Those rows prove a city
cannot act; they seat nobody.

Minnesota is expected to be the opposite case. Saint Paul is believed to have enacted **both** a rent
stabilisation ordinance and a municipal minimum wage — which, if true, makes those ladders live
levers carrying recorded votes and recorded member statements.

✅ **VERIFIED 2026-10-04 — the claim holds.** Full working:
[`scope-review.md`](../../backend/data/stance-research/2026-10-04-knight-mn-cities/scope-review.md).
**15 topics are scope blanks (270 rows), 20 are live (360).** 43% blank, against 51% for both
Charlotte and Florida. Four ladders that NC and FL could not reach are live here, each with a cited
Saint Paul instrument: `rent-regulation` (§ 471.9996 subd. 2 + Leg. Code ch. 193A), `minimum-wage`
(ch. 224, amended by Ord 26-31 four months ago), `local-immigration` (Admin. Code ch. 44; RES 25-1980,
Dec 2025) and `ranked-choice-voting` (ch. 31).

🔴 **`cannabis-policy` REVERSES THE FLORIDA FINDING — do not copy it across.** § 342.13 bars a
Minnesota city from prohibiting cannabis, and rung 4 *is* the state law, so it is blank here while it
was live in Florida.

🔴 **A LEGISTAR SEARCH FOR "ranked choice" RETURNED ZERO AND THE ZERO WAS FALSE.** Saint Paul’s
ordinances say **"ranked voting"**. Search the term the body uses, not the term the ladder uses.

🟢 **Saint Paul has the Legistar public Web API** (client `stpaul`, no key; control passed on
`charlottenc`). **Duluth does not** — `duluth` and `duluthmn` both 500, so Duluth needs HTML work and
should be priced higher per member.
⚠ `RLH RSA` rent-stabilization appeals are single-property determinations, not positions.

⚠ **Saint Paul's mayor reads as Kaohly Her, `is_incumbent` true.** Confirm the current officeholder
against the city's own page before citing the office — a roster label says how someone arrived, not
what they hold now, and a departed official's URL can serve their successor.

### ▶️ RESUME HERE

**SAINT PAUL IS DONE** — seven councilmembers and the mayor, 280 rows. **4 chairs**, all on `rent-regulation`:
Noecker 3 · Bowie 3 · Jost 3 · Johnson 2. Every row is queued for human review; nothing publishes.

**✅ RANDORF IS DONE — 35 rows, 3 chairs** (`homelessness` 3 · `rent-regulation` 3 · `economic-development` 3).
**✅ DURRWACHTER IS DONE — 35 rows, 2 chairs** (`climate-change` 1 · `economic-development` 2).
**✅ FORSMAN IS DONE — 35 rows, 2 chairs** (`homelessness` 3 · `economic-development` 4).
**✅ KENNEDY IS DONE — 35 rows, 1 chair** (`economic-development` 4, alongside Forsman). She argued
for the Sofidel package on the floor — *"I don’t want the perfect to get in the way of the good …
We need this economic development. I don’t think this is the time to stand back"* — and is one of
the three DEDA councilors who introduced the TIF policy that sets the limits.

**▶️ FOUR PEOPLE REMAIN, ALL IN DULUTH:** Jordon Johnson, Terese Tomanek, Diane Desotelle and
David Clanaugh. Desotelle, Clanaugh and Johnson took their seats in January 2026, so expect thin
records; Tomanek has served since 2020 and chaired the council in 2026.

🔴🔴 **A COMMON SURNAME MAKES THE CORPUS 94% NOISE, AND THE SWEEP CANNOT SEE IT.** The keep-filter
matches the SURNAME alone, so her sweep kept **359 articles of which only 23 name Janet Kennedy** —
the rest are RFK Jr., JFK, Justice Kennedy, the Kennedy Center, Harvard Kennedy School. The
ambiguity check then excluded 290, leaving 69 usable. ▶ **Measure that ratio before trusting a
corpus size**; for Durrwachter the same filter was harmless.

🔴 **A MIDDLE INITIAL DEFEATED THE AMBIGUITY CHECK.** *"Robert F. Kennedy Jr."* contains no
`[A-Z][a-z]+ Kennedy` pair, so those articles read as unambiguous and **three of ten attributed
quotes were the US Health Secretary**. The regex now allows one or two initials: exclusions rose
207 → 290 and attributions fell 10 → 7, with a regression control confirming Forsman stayed at 39.

⚠ **Her own sweep MISSED the paper-mill article** that another member’s sweep caught. A per-member
corpus is not exhaustive, and a citation need not come from the member’s own corpus.
⚠ **Kennedy is a common surname for `checkNameProximity` too**, which then demands a title
qualifier within 30 characters — both her snippets carry *"5th District Councilor Janet Kennedy"*.

**✅ MAYOR REINERT IS DONE — 35 rows, 3 chairs** (`homelessness` 5 · `residential-zoning` 4 ·
`growth-and-development` 4). The strongest member in the slice: 146 of 398 articles name him.

🟢 **`homelessness` NOW SEPARATES THE MAYOR FROM HIS OWN COUNCIL — Reinert 5, Randorf 3, Forsman 3.**
He proposed a misdemeanor carrying up to $1,000 and 90 days; the council refused it and cut the
penalty to a $200 fine. 🔴 **His argument EXCLUDES chair 4 by name** — the civil citation is the
city's only tool and *"individuals can literally tear them up and walk away"* — and excludes chair 3
in reverse, because chair 3 routes people to services *rather than* the criminal justice system and
he argues the criminal connection is what makes services reachable.

🔴 **RHETORIC AND INSTRUMENT POINTED AT DIFFERENT CHAIRS, AND THE INSTRUMENT WON.** On zoning he says
*"We need all the kinds, in all the places"*, which reads as chair 5. The ordinance he backs allows
**fourplexes in Residential-Traditional**, cuts lot widths and setbacks and raises height maximums —
chair 4. It neither ends single-family zoning nor allows any type on any lot. ▶ **Read what the
instrument does before seating the slogan.**

🟢 **A MAYOR LEAVES ALMOST NO RECORD IN LEGISTAR, and the near-zero is a real finding.**
`mayor_actions.mjs` over **1,914 items in 76 meetings** returns exactly one match: 25-016-O *"passes
without Mayoral signature"*. He has vetoed nothing. The pattern fired once, so the zero is measured,
not a broken detector. ⚠ Not signing has two readings and no reporting says which — a lead, never a
chair. ▶ **A mayor is researched from proposals and statements.**

