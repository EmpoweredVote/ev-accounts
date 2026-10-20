# Candidate → person linking — handoff

**Written 2026-10-20. Author: Chris Cantrell (`CC_`).**
**Status: ✅✅ THE PROGRAMME IS COMPLETE. Every cohort examined. The only 5 rows left unlinked
nationally are the 5 DELIBERATE REFUSALS — there is no backlog.**
**🟢 WASHINGTON HAS AN EVIDENCE INSTRUMENT AFTER ALL — see §16. This file said it had none.**
**▶ What remains is listed in §12: judgement calls, occupancy gaps this work surfaced, and the
next cycle's re-run. None of it is linking.**

| Election | total | linked | left |
| --- | --- | --- | --- |
| CA 2026 Statewide General | 324 | **324** | 0 |
| 2026 LA County General | 796 | **793** | 3 (judged — §6b) |
| 2026 San Bernardino County General | 5 | **5** | 0 |

**States finished: CA · IN (102/103) · NV (28/28) · OR (49/50) · TX (170/170) · CO (103/103) ·
WA (394/394) · San Bernardino (5/5).** ✅ **No cohort anywhere is unexamined.**

**Exactly 5 rows remain unlinked nationally, and every one is a deliberate refusal:** 3 LA residue
(§6b), Dugger (OR), Smith III (IN). **There is no backlog left.**

Migrations: `CC_0262`-`CC_0279`. 770 candidacies linked, 803 people created, 17 wrong people
refused, 5 left unlinked by judgement across the programme.

---

## 🔴🔴 CORRECTION — DO NOT SEAT BROCK, DE LA TORRE OR PARRA

An earlier version of §6 said these three were "Santa Monica councilmembers with NO office_terms
row, so they are invisible in Essentials… Owed a seating migration." **That was wrong, and acting
on it would have done real damage.**

**They are FORMER councilmembers.** Phil Brock (then mayor) and Oscar de la Torre were incumbents
who **LOST re-election in November 2024**; Dan Hall, Ellis Raskin, Natalya Zernitskaya and Barry
Snell took the four open seats. Our database has all seven Santa Monica At-Large seats occupied by
the current members, including those four — **the roster is correct and current.** The three carry
`is_incumbent = false` and zero office_terms rows, which is the RIGHT state for someone who holds
nothing.

🔴 **Seating them would have called `essentials.seat_officeholder` on OCCUPIED offices, and that
helper CLOSES the predecessor's term.** The "missing term" I inferred was the absence of a seat
they do not hold.

⚠ **WHAT WENT WRONG:** I inferred CURRENT occupancy from an IMPORT COHORT. Their external_ids sit
inside a block of Santa Monica councilmembers, which correctly identified *who they are* — that
part stands and the `CC_0271` links are right — but a scrape records who held the seat **when it
ran**, not who holds it now. This is the same family as "a certified result is not a fact about
who holds the seat" and "FIRST ELECTED IS NOT A TERM START".
▶ **Before seating anyone, check whether the seat is already occupied and by whom.** One join.

▶ Genuinely owed, and much smaller: we record no CLOSED term for their 2020–2024 service, so their
history is missing. That is a backfill, not an occupancy defect, and needs a document for the
start and end dates — do not infer them from the election dates.

🔴 **READ THIS FILE BEFORE TOUCHING `race_candidates.politician_id`.** It carries the evidence
standard, the measured wrong-person rate, and the specific traps already identified by name. The
method is cheap to repeat and expensive to re-derive.

---

## 1. What this programme is

Many `essentials.race_candidates` rows carry a name and no `politician_id`. A ballot page then
shows a name with no profile, no photograph and no compass. Linking the row to the right person
fixes all three at once — and linking it to the **wrong** person publishes someone else's
positions under a candidate's name, so the bar is evidence, never a name match.

## 2. Done so far

| Migration | What |
| --- | --- |
| `CC_0262` | Ben Allen — the first link made on a ballot designation |
| `CC_0263` | 10 CA 2026 general candidates; 4 refused |
| `CC_0264` | Reverted Sonja Shaw on operator ruling |
| `CC_0265` | 5 WA House members → Senate seats in their own district; 35 refused |
| `CC_0266` | 3 Colorado statewide officeholders |
| `CC_0268` | 10 CA general candidates found by the dedupe pass |
| `CC_0269` | Tom Umberg + **110 new people created** |
| `CC_0270` | Sonja Shaw re-linked — the evidence was in our own DB all along |

**CA 2026 Statewide General: 324 of 324 linked.** That election is finished.

## 3. 🔴 The evidence standard — two instruments, and only one travels

**INSTRUMENT A — the ballot designation.** The candidate's own sworn occupation, printed by the
Secretary of State. When it names an office we independently record them holding, that is a
document tying candidate to officeholder. This is the gold standard.
⚠ **It exists in California and essentially nowhere else.** Measured 2026-10-20 on unlinked rows
in future elections: CA 164 rows carry a designation; **WA, CO, IN, TX, NV and OR carry ZERO.**
Outside California there is no instrument, and work there is creation-only until someone finds
a per-state equivalent. WA's certified list is a **scanned photocopier image with no text layer**
(`pdfinfo` producer: SHARP MX-4071).

**INSTRUMENT B — primary-advanced continuity.** The person already holds a `race_candidates` row
for the **same office** in the same cycle's primary with `result = 'advanced'`. A candidate
certified as having advanced for an office is that office's candidate in the general. Found
Morgan, Rascón, Brown, Hawks and Gates in `CC_0268`.

**CORROBORATOR — geography.** `ST_Intersects` over `essentials.geofence_boundaries` joined on
**(mtfcc, geo_id)**, never `geo_id` alone. Use it when the seat held and the seat sought are both
districted. It cannot run for a statewide race — there is no district to intersect.

🔴🔴 **`ST_Intersects` IS NOT "IS INSIDE". READ THE AREA SHARE.** Santa Barbara County against
Senate District 12 returns **intersects = TRUE at 0.0% shared area** — they touch along a
boundary line. The boolean said yes, the area said no. Using the predicate alone would have
attached a Santa Barbara sheriff to a Central Valley senate seat.

🔴 **ALWAYS RUN A CONTROL.** Every geometric test above was run against a district it should NOT
match; all returned 0.0%. A test that answers "true" to everything proves nothing.

## 4. 🔴🔴 The wrong-person test, and its measured rate

**One join: compare the election's state with the state of the seat the matched person holds.**

Confirmed different people, every one of which had *exactly one active namesake* — the cleanest
possible signal:

| Candidate | Race | Matched person actually is |
| --- | --- | --- |
| Cheryl Williams | Inglewood USD board, CA | Commissioner, Collin County, **TX** |
| Amanda Campbell | CO Secretary of State | Allen ISD board, **TX** |
| Ed Delgado | CA Assembly 60 | WI Assembly 57 candidate who **lost** |
| Mike Murphy | CA Assembly 27 | State senator, **KS** |
| Tony Rodriguez | CA Senate 20 | Commissioner, Miami-Dade, **FL** |
| William Brown Jr. | CA Senate 12 | Sheriff-Coroner, Santa Barbara County, CA (0.0% overlap) |

**Roughly one in ten single-namesake matches is a different human.**
▶ **"Exactly one active namesake" is a filter for what to INVESTIGATE. It is never a reason to
link.**

## 5. 🔴 The dedupe pass — run it BEFORE creating anyone

The duplicate-name guard keys on `(first_name, last_name)` and is blind four ways:

1. **a differently split `full_name`** — "Charles Frederick Hughes" vs "Charles Hughes"
2. **an accent** — "Sarah Rascón" vs "Sarah Rascon"
3. **punctuation** — "Herb W. Morgan" vs "Herb W Morgan" (one full stop)
4. **a nickname** — Tom/Thomas, Bill/William, Jim/James, Tony/Anthony

🔴 **A NICKNAME IS NOT A PREFIX.** `CC_0268`'s pass matched first names by equality-or-prefix and
dropped **Tom Umberg**, a sitting State Senator with 23 published compass answers, who was one
migration from being created a second time. An earlier, noisier version had caught him on
first-initial alone. **When you narrow a matcher, re-check what it used to find.** Use an explicit
diminutive list; there is one in `CC_0269`'s history and in §9 below.

**11 of CA's 117 "new people" already existed.** Creating them would have cost 11 merges, and a
merge moves answers and context across five cascading foreign keys, two of which hold stance
research.

🔴 **Read your own database before declaring evidence absent.** `CC_0264` reverted Shaw for want
of a district and wrote down which document would supply one — and that document had been loaded
into `office_terms` by `CA_0308` **five days earlier**. The revert examined the designation and
never joined the table that already held the answer.

## 6. ✅ DONE: 2026 LA County General — 793 of 796 (`CC_0271`, `CC_0272`)

16 linked by the dedupe pass, 408 created, 5 confirmed different people, 3 left unlinked.
The four evidence tiers and every named refusal are in `CC_0271`'s header — read it before
re-deriving anything. **§6b below is the live residue.**

### 6b. ⚠ The three still unlinked, and why no row was created either

For each, we can show neither sameness nor difference, so creating a row would assert "different
person" exactly as falsely as linking would assert "same". Unlinked is the finding.

- **Christine R. Sarmiento** (El Monte Mayor) — existing row holds a CA GOVERNOR candidacy and an
  IMAGE. Statewide-to-city on an exact name is the Shaw shape; a wrong link publishes a wrong face.
  ▶ *Settles it:* any El Monte source naming her, or a CA SOS designation.
- **Mark Copland** (Norwalk-La Mirada USD **Trustee Area 5**) — existing row holds **Area 6** of the
  same district. The two return `ST_Intersects` TRUE at **0.0%** shared area. ▶ *Settles it:* the
  trustee-area boundary redraw, or the district's own roster naming his area.
- **Michael Braun** (Walnut Valley Water District, Division 2) — matches three rows (an ARIZONA
  senate candidate, an archived row, a bare row) and the name also matches the Governor of Indiana.
  ▶ *Settles it:* a Walnut Valley source naming him.

### 6c. ✅ DONE: 2026 San Bernardino County General — `CC_0279`. 5 of 5.

⚠ **This section used to read "100% designated. An hour's work with instrument A." The first half
was right and the second did not follow — see §18.** All three were creations.

## 6d. (historical) The original LA County scoping

**Election date 2026-11-03. This is live.** `election.name = '2026 LA County General'`.

| Office class | unlinked | with designation |
| --- | --- | --- |
| City (council / mayor) | 188 | 63 |
| School / college board | 188 | 55 |
| Special district | 43 | **43 (100%)** |
| Judicial (LA Superior Court) | 8 | 0 |

**161 of 427 carry a ballot designation** — Instrument A works for 38% of this cohort. The
special-district rows are fully designated and are the cleanest slice to start with.

⚠ The 8 judicial rows carry no designation. `CC_0265` refused seven LASC candidates for the same
reason. Judges are also the subject of an open item: **364 LASC seats are named after their
sitting judge** (see `project_la_headshot_replenish_2026_10`).

### 25 variant hits in this cohort, already found — assess each, do not bulk-link

🔴 **FOUR ARE CROSS-STATE TRAPS. One is spectacular:**

- **Michael Braun** — Walnut Valley Water District Board, Division 2 — matches **Mike Braun,
  Governor of Indiana**. Also matches an archived *and* an active "Michael Braun". **REFUSE.**
- **Alisa Gentry** — Saugus Union School Board — matches "Al Gentry", **Kentucky** State House. **REFUSE.**
- **Melissa C. Smith** — Hacienda La Puente USD — matches "Melissa Price Smith", Prosecuting
  Attorney, St. Louis County, **MO**. **REFUSE.**
- **Cheryl Williams** — Inglewood USD Trustee Area 1 — matches the Collin County **TX**
  commissioner. Already confirmed wrong in `CC_0265`. **STILL SITTING THERE. REFUSE.**

🟢 **Strongest candidate to link:**
- **Alfonso Morales** — Lynwood City Council — designation **"Attorney/School Boardmember"**, and
  we record an Alfonso Morales as a **Lynwood Unified Board** member. Designation and record agree
  on the same district. This is the `CC_0262` shape exactly.

⚠ **Needs a careful look (same district, different area/seat):**
- **Mark Copland** — seeking Norwalk-La Mirada Unified **Trustee Area 5**, recorded on the same
  district's **Trustee Area 6**. Same person moving areas, or redistricting — check before linking.
- **David Stephen Siegrist** → "David Siegrist", El Monte City Board, seeking Rio Hondo CCD TA-1.
- **Francisco Sanchez** → "Francis De Leon Sanchez", Council Member At-Large, CA.
- **Sergio Roberto Mortara** → "Sergio R. Mortara", Hawthorne Board.
- **Dora D. Sandoval** → "Dora Sandoval"; designation "Economy Efficiency Commissioner".
- **James M. Bishop Sr.** → "Jim Bishop" (nickname + suffix, no office recorded).
- **Jose R. Gonzalez** → "Jose Gonzalez" (no office recorded).

**Exact-name matches with no office recorded** — probably the same person from an earlier import,
each still needs a reason: Anthony (A.J.) Bayne, Christine R. Sarmiento, David DeJute, David Ross,
Donna Tryfman, Elaine Alaniz, Justin Allen Clayton, Maria Ghobadi, Oscar de la Torre, Phil Brock,
Rhonda A. Haymon, Stacy Fortner, Tonia Arey.

## 7. ✅ CLOSED — "THE CLEARING" (historical; §14 ruled there was nothing to clear)

⚠ **Read this section only for how it was framed, not for what to do.** The operator's ruling in
§14 keeps primary losers, and §13a found Colorado's `filed` rows to be the source's own
distinction. Nothing here needs filtering out. The original text follows.

**Scope: 85 rows, all in WA and CO. No California row needs it.** This is now the front of the
queue because California is finished and nothing else should be created until it is done.

**The job, concretely:**
1. **Washington — 75 rows must NOT become people.** 70 carry `result = 'not_nominated'` (lost the
   top-two primary, not on the November ballot) and 5 are `withdrew`/`withdrawn`. They are already
   hidden from voters — `electionService` filters `not_nominated` — so this is **not a live
   defect** and there is no deadline pressure. The harm is only if a creation sweep includes them.
2. **Colorado — 10 rows** are `candidate_status = 'filed'` with no result: filed, not confirmed on
   the ballot. Decide whether 'filed' qualifies. ⚠ Note `essentials.is_live_candidate` currently
   counts 'filed' AS live, so the predicate alone will not exclude them.
3. **Decide the rule, then write it down**: does a certified candidate who lost a primary get a
   person record? The answer belongs in this file, not in a migration header.

🟢 **Use `essentials.is_live_candidate(candidate_status, result)`** — the codebase's own predicate,
already used by `electionService`. Do not hand-roll the filter.

▶ **Nothing in the clearing requires a migration.** It is a filter applied to the NEXT creation
sweep. If you only ever create from `is_live_candidate` rows plus an explicit 'filed' decision, the
85 never enter and there is nothing to clean up afterwards.

## 7b. (historical) Clearing did NOT gate LA County

⚠ **The clearing items are all in WA and CO. California has none** — all 430 CA unlinked rows pass
`essentials.is_live_candidate`. So clearing is a separate, small job and LA County is unblocked.

Before any creation in **Washington** (209 unlinked, 134 live):
- **70 rows are `result = 'not_nominated'`** — they lost the top-two primary and are not on the
  November ballot. Already hidden from voters (`electionService` filters them), so not a live
  defect — but creating 70 public person records for non-candidates asserts nothing true.
- **5 rows are `withdrew` / `withdrawn`.**

Before any creation in **Colorado** (72 unlinked):
- **10 rows are `candidate_status = 'filed'`** with no result — filed, not confirmed on the ballot.

🟢 **Use `essentials.is_live_candidate(candidate_status, result)`** — the codebase's own predicate,
already used by `electionService`. Do not hand-roll the filter.

## 8. What a created person row may assert

`CC_0269` is the pattern. Every new row:

```
is_active    = true      -- they are standing in a live election
is_incumbent = FALSE     -- 🔴 NAMED EXPLICITLY. Defaulted true until CA_0188 and created
                         --    1,817 active "incumbents" with no seat. check:occupancy fails
                         --    an INSERT that omits it.
external_id  = NULL      -- an external_id collision seats the WRONG person silently
party        = NULL      -- party is antipartisan here; it lives on races.primary_party
no office_terms row      -- they hold nothing, and an office with no term is invisible
source       = '<import> CC_NNNN (certified candidate list; no office asserted)'
```

**Insert ONE AT A TIME and key the link on `rc_id`, not `full_name`** — two candidates in
different districts can share a name, which is the whole problem.

🔴 **The database has its own duplicate-name trigger**, `essentials.politician_name_duplicate_guard`.
Leave it ARMED. For a genuinely different person sharing a name, open the house escape hatch for
**one statement** and re-arm immediately:

```sql
PERFORM set_config('essentials.allow_duplicate_name', 'on',  true);  -- true = LOCAL
-- the single INSERT
PERFORM set_config('essentials.allow_duplicate_name', 'off', true);
```

Then record the pair in `backend/data/duplicate-people-baseline.json` as `different_people` with a
note carrying the **evidence**, not just the verdict. `npm run check:duplicate-people -- --update-baseline`
adds it as `unreviewed` first.

## 9. Queries that do the work

The dedupe pass, the geometry test with controls, and the office-class breakdown are all in this
session's migrations: `CC_0268` (geography + primary-advanced), `CC_0269` (name splitting, the
diminutive list, the escape hatch). **Copy them from there rather than rewriting.**

Name normalisation, learned the hard way:
- 🔴 **Postgres word boundary is `\y`, NOT `\b`** — `\b` is a *backspace* and silently matches
  nothing. A suffix-stripping regex using `\b` fails without erroring, and every "Jr." then shares
  a last name.
- Strip quoted nicknames from the SPLIT only; `full_name` keeps the ballot spelling and accents.
- Exclude a generational suffix from `last_name` so the guard keys on the family name.

## 10. Operational cautions

- 🔴 **Run branch-scoped guards in that branch's OWN worktree.** `check:occupancy` and
  `check:duplicate-people` scope to changed files / read a baseline file. Run from the main
  checkout they diff the wrong branch and print **OK**. This cost 15 red CI runs on PR #1046.
  **Read the file count the guard prints.**
- 🔴 **Creating rows can tip a CI gate over its statement timeout.** 110 new people pushed
  `duplicate people` past `ev_api`'s 30s limit and reddened master twice; the query runs 13.2s
  cold and 0.39s warm. Raised to 180s in `#1056`. **The remaining live set is ~666 — expect to
  find the next ceiling. Work in slices.**
- **Migration numbers are ALLOCATED, never counted:** `npm run steward --prefix backend -- slot CC --purpose "..."`.
- **Dry-run every migration** against prod inside `BEGIN; … ROLLBACK;`, confirm the rollback
  reverted, and **plant a control that makes a guard FAIL before trusting it**.
- **State the weakest row in the migration header.** `CC_0263` named Shaw as its thinnest link,
  which made both the revert and the later reversal two-line decisions instead of audits.

## 11. Open questions for the operator

1. **The other states** — WA/CO/IN/TX/NV/OR have no evidence instrument. Is creation-only
   acceptable there, or should each wait for a per-state document?
2. **The judicial rows** — 8 in LA County, 7 refused in `CC_0265`. No designation, and LASC seats
   are already tangled with the "364 seats named after their sitting judge" item.
3. **`occupational_designation` is NULL on all CA statewide general rows** though the SOS prints
   it. Populating it is what makes future CA linking cheap and is the asset no other state has.

---

## 12. ▶ RESUME HERE — the shortest path back in

**Read in this order:** this file → `CC_0271` header (the four evidence tiers and every named
refusal) → `CC_0269`/`CC_0272` (the creation pattern, the name splitting, the escape hatch).

**The queue, in order** (rewritten 2026-10-20 after `CC_0276`; §7's "clearing" is CLOSED — the
operator's §14 ruling means there was never anything to filter out):

1. ✅ **WASHINGTON — DONE** (`CC_0277`, `CC_0278`). 394 of 394. **§16 is the write-up and it
   corrects this file's claim that WA had no instrument.**
2. ✅ **San Bernardino County General — DONE** (`CC_0279`). 5 of 5. Write-up in §18.
3. **The three LA residue rows (§6b)** — one citation each. ▶ **This is now the front of the
   queue, and it is five judgement calls, not a cohort.**
4. **Brock / de la Torre / Parra closed-term backfill** — history, not occupancy. Needs documented
   start AND end dates. **DO NOT SEAT THEM** (see the correction at the top).
5. **Occupancy gaps this programme surfaced.** ✅ **Colorado DONE** — Jefferson and Fremont
   counties seeded by `CC_0280` (18 offices, 18 terms), and **three of the people `CC_0276`
   created as candidates were seated rather than duplicated**, exactly as §15d predicted. Rulings
   in `backend/data/seed-co-counties-2026/ROSTERS.md`.
   ▶ Still open: in WA, dozens of city councils and school boards whose members we now hold as
   people with no seat (§16f). A seeding job with its own sources.
6. **Re-run the WA pamphlet sweep for the 2027 cycle** — `backend/scripts/wa-voter-pamphlet.mjs`,
   with the new election id in place of `e=898`.

**Before any creation sweep, every time:**
- Run the dedupe pass (§5) with the **nickname list**, accents, punctuation and archived rows.
- Run the cross-state test (§4). One in ten single-namesake matches is a different human.
- Read the **area share**, never bare `ST_Intersects` (§3).
- Run the guards **in this branch's own worktree**, and read the file count they print (§10).
- Expect to find the next CI statement-timeout ceiling; work in slices (§10).

**State of the work as of 2026-10-20:** `CC_0262`-`CC_0276` applied to prod. Branch
`fix/ca-2026-general-candidates`, worktree `C:/ev-accounts-ca-cands` — run
`npm run check:deletable --prefix backend -- /c/ev-accounts-ca-cands` before removing either.

---

## 13. PREP FOR THE OTHER STATES (written 2026-10-20, after the Colorado check)

### 13a. 🟢 Colorado's 10 `filed` rows are NOT a defect — checked, close it

They came from the SAME SOS document, on the same day, as the 73 `active` rows, and **every one of
the six affected races contains BOTH statuses**. The distinction is the source's own and our
importer carried it faithfully. `filed` is a fact, not a data-entry error.

⚠ They DO render: `result` is NULL so `electionService`'s `not_nominated` filter never touches
them, and `essentials.is_live_candidate` counts `filed` as live. Six races affected — U.S. Senate
(3 filed / 6 active), U.S. House 1 (3/5), 4 (1/3), 5 (1/4), State Rep 16 (1/3), 17 (1/3).

▶ **THE ONLY OPEN QUESTION IS A DISPLAY DECISION, NOT A CLEANUP:** should a candidate the state
lists as *filed* appear on a ballot page beside candidates it lists as *active*? Operator's call.
Nothing is wrong with the data either way.
🔴 **The cited source URL now 404s** (`…/2026GeneralCandidateListUnofficial.xlsx`), and
coloradosos.gov expressly prohibits automated retrieval of its content (see `CC_0267`). This
cannot be re-verified by script; a human with the certified list settles it in a minute.

### 13b. The cohorts, measured 2026-10-20

| State | unlinked | **live** | not live | variant hits to adjudicate | designations |
| --- | --- | --- | --- | --- | --- |
| WA | 209 | **134** | 75 | 15 | 0 |
| CO | 72 | 72 | 0 | 3 | 0 |
| IN | 13 | 13 | 0 | 10 | 0 |
| TX | 11 | 11 | 0 | 0 | 0 |
| NV | 3 | 3 | 0 | 1 | 0 |
| OR | 3 | 3 | 0 | 1 | 0 |
| **total** | **311** | **236** | **75** | **30** | **0** |

⚠ **INDIANA IS THE ODD ONE: 10 variant hits against 13 live candidates.** Three quarters of that
cohort matches an existing person. Do Indiana by hand as a LINKING job, not a creation sweep. It
is also the smallest, so it is the cheapest place to re-prove the method.

### 13c. 🔴 There is no evidence instrument in any of these states

Zero ballot designations. Instrument A cannot run outside California, and Washington's certified
list is a scanned image with no text layer. So for these 236:
- **Linking** is possible only via instrument B (primary-advanced continuity, which WA's top-two
  system supports well — 130 of its 134 live rows carry `result='advanced'`) and geography.
- **Creation** is name-only. Approved for California specifically. **Not approved anywhere else.**

▶ **Order I would work them:** Indiana (13, mostly links) → Nevada + Oregon (6) → Texas (11) →
Colorado (72) → Washington (134, the only one needing the 75-row filter).

### 13d. The two decisions needed before any of it

1. **Does a certified candidate who lost a primary get a person record?** Affects WA's 70. The rows
   are inert either way; this only decides whether a creation sweep includes them.
2. **Is name-only creation acceptable outside California?** 236 rows hang on this.

Neither is a data question and neither blocks linking work. Both block creation.

---

## 14. OPERATOR RULING 2026-10-20 — primary losers KEEP their person record

> "if someone loses the primary, we should hold onto their information, just not as a
> candidate/incumbent."

**This closes decision 1 of §13d and unblocks Washington.** The 70 WA `not_nominated` rows and the
5 `withdrew` rows are **IN SCOPE** for creation, not excluded from it. We keep the person; we do
not present them as a candidate or an incumbent.

**How it applies:**
- Create the person as normal: `is_active=true`, **`is_incumbent=false`**, no office, no term.
- Do **not** clear `race_candidates.result` or `candidate_status` — those fields are what stop the
  row being presented as a candidate, and `electionService` already filters `not_nominated` off
  the ballot page. The ruling changes WHO WE KEEP, not what we display.
- ⚠ So §7's framing was wrong in one respect: there is no filtering-out to do. The "clearing" is
  now just the Colorado `filed` display question (§13a), which is the operator's call and blocks
  nothing.

🟢 **Washington's real cohort is therefore 209, not 134.**

### Progress since §13 was written
| State | status |
| --- | --- |
| IN | ✅ `CC_0273` — 102 of 103. 8 linked, 4 created, Smith III unlinked |
| NV | ✅ `CC_0274` — 28 of 28 |
| OR | ✅ `CC_0274` — 49 of 50. Dugger unlinked |
| TX | ✅ `CC_0275` — 170 of 170. 11 created, 0 variant hits |
| CO | ✅ `CC_0276` — 103 of 103. 1 linked, 71 created, 2 wrong people refused |
| WA | 209 (now including the 75) — **the only state left** |

---

## 15. COLORADO — `CC_0276`, applied 2026-10-20. 103 of 103.

**1 linked · 71 created · 2 cross-state matches refused and created as separate people.**

### 15a. 🔴🔴 BOTH STANDING INSTRUMENTS WERE UNAVAILABLE, AND THE STANDARD STILL HELD

Colorado has **no ballot designation** (measured: zero) and **no primary in our data at all** —
`elections` holds exactly one Colorado row, the general — so instrument B had no
`result = 'advanced'` to read either. Neither A nor B could run.

The one link rests on the **singleton office**, the shape `CC_0266` established here:

> **Michael J. Allen**, seeking Attorney General → `daae06aa` "Michael Allen", **District
> Attorney, El Paso County**, term_start 2021-01-12 (source: elpasoco.com/elected-officials).

The document is the candidate's **own campaign site**, michaelallenforcolorado.com: *"Elected
District Attorney in the Fourth Judicial District (El Paso and Teller counties) in 2020 and
re-elected in 2024."* Corroborated by Colorado Politics' 2026-10-02 questionnaire (printed under
"Name: Michael J. Allen / Office Sought: Attorney General", in which he calls himself "the elected
District Attorney of Colorado's largest judicial district") and by CPR News 2026-06-30, headlined
"El Paso County prosecutor Michael Allen wins Republican attorney general primary".

🟢 **The dates corroborate independently:** elected 2020 ⇒ took office January 2021; our
term_start of 2021-01-12 was written from the county's own page months earlier. Neither source
derives from the other.
🟢 **It is a singleton that cannot move** — unlike "chair of the Joint Budget Committee", the DA of
a numbered judicial district does not rotate.
▶ **The migration asserts the SEAT, not the name:** its pre-check refuses unless that person holds
exactly one El Paso County District Attorney term. If he stops holding it the evidence has
evaporated and the link must be re-derived, not re-applied.

### 15b. 🔴 Two refused — and BOTH were created as separate people

| Candidate | Race | Matched person actually is |
| --- | --- | --- |
| Amanda Campbell | CO Secretary of State | Board Member Place 5, Allen ISD, **TX** |
| Travis Star Nelson | CO Senate 35 | State Rep, House District 44, **OREGON** (carries a PHOTO) |

Both got their own new row, because *different person* is the finding — leaving them unlinked
would assert we could not tell, and we could. The Colorado Amanda Campbell is an American
Constitution Party candidate who ran for this same office in 2022 (she is in the Colorado SOS's own
historical election data) and lives in Grand Junction; that is not a sitting Texas school trustee.

### 15c. 🔴🔴 A FIFTH BLINDNESS: THE DUPLICATE DETECTOR CANNOT SEE A CROSS-STATE PAIR

`findPairs` adds a NAME_STATE pair only when `!a.st || !b.st || a.st === b.st` — **same state, or
one state unknown.** Every wrong-person match this programme catches is by definition
*cross-state*, so `check:duplicate-people` **will never observe one of them**, and there is
nothing to record in `duplicate-people-baseline.json`.
▶ **Do not hand-add a cross-state pair to the baseline.** `--update-baseline` rebuilds from what
the detector observed, so an unobserved entry is silently dropped on the next run — and that drop
reads like a resolution. The adjudication belongs in the migration header and in this file.

⚠ **And only ONE of the two even reached the INSERT-time guard.** It keys on
`(first_name, last_name)`: Amanda Campbell splits to ('Amanda','Campbell') and was blocked;
`Travis Star Nelson` splits to ('Travis Star','Nelson') and sailed through. **The middle name, not
the adjudication, is what silenced the guard.** It did not agree with us about Nelson — it never
looked.
🟢 The guard was proved live first: inserting Amanda Campbell without the hatch raises
`DUPLICATE_POLITICIAN_NAME`, watched failing before the hatch was written.

### 15d. ⚠ Five of the 71 hold or have held real office — and a new row is still right

Amanda Gonzalez is the **Jefferson County Clerk and Recorder**; Lesley Dahlkemper a **Jefferson
County Commissioner**; Kevin Grantham a **Fremont County Commissioner**; Steph Vigil and Terri
Carver are former state representatives; Greg Lopez a former U.S. Representative.

🔴 **We seed no Jefferson County and no Fremont County at all** — `districts` holds zero CO rows
matching 'Jefferson County'. Colorado's seeded occupancy is the legislature, the statewide
executives and El Paso County, which is exactly why Michael Allen was the only link available.

▶ **THIS IS AN OCCUPANCY GAP WEARING A LINKING DEFECT'S CLOTHES.** Check which one you have before
concluding the evidence is thin. The rows created here hold nothing and claim nothing; if those
counties are seeded later, **these are the people to seat, not rows to duplicate.**

### 15e-bis. See §16 — Washington, and the correction to §3 and §13c

### 15e. The 10 `filed` rows were left exactly as the source wrote them

No field was touched. §13a settled that `filed` is the Secretary of State's own distinction,
carried faithfully. Whether a `filed` candidate should render beside an `active` one is still the
operator's **display** decision — it is not a reason to withhold a person record.

---

## 16. WASHINGTON — `CC_0277` + `CC_0278`, applied 2026-10-20. 394 of 394.

**12 linked · 196 people created for 197 candidacies · 4 wrong people refused.**

### 16a. 🔴🔴 CORRECTION TO §3 AND §13c — WASHINGTON *DOES* HAVE AN INSTRUMENT

§3 said WA's certified list is "a scanned photocopier image with no text layer" and §13c concluded
there is "no evidence instrument in any of these states". **The scan is real. The conclusion was
wrong.** The instrument is not in the PDF.

🟢 **The online voters' pamphlet publishes every candidate's own `Elected Experience` as JSON,
over a public endpoint, with no key:**

```
https://voter.votewa.gov/elections/voterguide.ashx?e=898&la=en&c=
   -> every category, race, BallotID and BallotName for the election
https://voter.votewa.gov/elections/candidate.ashx?e=898&r=<RaceID>&b=<BallotID>&la=en&c=
   -> statement.Statement is HTML; its first section is <b>Elected Experience</b>
```

🟢 **`backend/scripts/wa-voter-pamphlet.mjs` harvests it.** `--name "Nikki Torres"` for one,
no flags to sweep every unlinked WA row.

⚠ **READ THE PRIMARY, NOT THE GENERAL.** `e=898` is the 2026 primary and carries EVERY filed
candidate; the general carries only the survivors. Measured 2026-10-20: 1,311 ballot names over
757 races; of our 209 unlinked rows, **205 matched by ballot name and 193 carried Elected
Experience text — 92% coverage**, against the ballot designation's 38% in LA County.

⚠ **It is NOT `occupational_designation` and must not be stored there.** That column holds
California's three-word sworn ballot designation. A pamphlet paragraph is a different artefact
with different rules; one column holding both makes "which rows carry a designation?" count two
unlike things. The harvest is reproducible in a minute, so nothing is cached.

### 16b. 🟢 A SELF-DESCRIPTION DISCONFIRMS AS WELL AS IT CONFIRMS

Every earlier refusal in this programme was an argument from improbability: *the matched person
holds a seat in another state, so this is probably someone else.* The pamphlet makes four
refusals **positive**:

| Candidate | Elected Experience, in their own words | Matched person |
| --- | --- | --- |
| Angela Taylor (House 2) | **"None."** | NV State Senator D15 |
| Eric W. Pratt (House 24) | "Precinct Committee Officer" | MN Senator D54 |
| Kathy Richardson (House 28) | "Board member, ARNP's United" | Philadelphia Councilmember At Large |
| Michael Alvarez Shepard (Senate 42) | "Port Commissioner in his third term" | Lavon, **TX** council |

🔴 A sitting state senator does not write "None." That is evidence of difference, not absence of
evidence of sameness.
⚠ **Not one of the four trips the duplicate guard** — each splits to a first_name the existing row
does not carry. The silence is the guard not looking.

### 16c. The 12 links — two tiers

**Tier 1 (9): filed for the very seat we record them holding.** Two unrelated official systems
agreeing, which is what makes the name difference explainable rather than lucky — the candidacy
comes from the **SoS filings**, which print the LEGAL name ("Jamila E. Taylor", "Drew C MacEwen"),
and the seat from the **Legislature's own member web service**, which prints the COMMON name
("Jamila Taylor", "Drew MacEwen"). Three statements name the district number outright (Reed 36th,
Entenman 47th, Gregerson 33rd); MacEwen's and Frame's "2023 to present" match our `term_start` of
2023-01-09, written long before the pamphlet was read.

**Tier 2 (3): a different seat, named by the candidate, that we also record.**
- 🟢 **Forsythe and Kritzer INTERLOCK.** Forsythe: Redmond Council President '22-'23, VP '24-'25.
  Kritzer: VP 2022-2023, President 2024-2025. Two pamphlet entries, written separately, describing
  the same council's officer rotation from opposite sides. Coincidence of names cannot do that.
- 🔴 **Nikki Torres looks exactly like a wrong-person match and is not.** She holds Senate **15**
  and is standing in Senate **8** — same chamber, different district, the shape that should stop a
  link. Her own pamphlet entry for the 8th resolves it: *"Elected to the Senate, 15th District
  2022."* ⚠ Her 15th-District occupancy record is untouched. A candidacy is not occupancy.

### 16d. 🔴🔴 THE PRE-FLIGHT COLLISION CHECK IS BLIND TO THE BATCH ITSELF

**This nearly shipped and only the dry run caught it.** The collision check asks *does this name
already exist in `politicians`?* — it compares the batch against the **table**. It cannot see a
name repeated **inside** the batch, because the first insert is what creates the collision for the
second. It reported **ZERO** collisions for this cohort and was wrong: the loop inserted **Julia
Payne**, then hit `DUPLICATE_POLITICIAN_NAME` on her own freshly written row.

▶ **A BATCH MUST BE CHECKED AGAINST ITSELF AS WELL AS AGAINST THE TABLE.** `CC_0278` now does
both. Add this to any future creation sweep.

**And the adjudication matters as much as the gate.** Julia Payne has two rows, both in
**Legislative District 6** — Position 1 `withdrew`, Position 2 `advanced` — and the SoS pamphlet
carries **exactly one** Julia Payne (BallotID 1600273, LD6 Pos. 2, "I am a first-time candidate").
One person who filed for one position, withdrew, and ran for the other. One person row, two
candidacies.
🔴 **The gate refuses any repeated name whose rows sit in DIFFERENT districts** — that shape is two
people and must never be collapsed. The house rule "key the link on `rc_id`, not `full_name`" is
not broken here; it is what forced the question.

### 16e. ⚠ `race_candidates.is_incumbent` LOOKED LIKE THE ANSWER AND IS NOT

All 209 unlinked rows read `is_incumbent = false`, and all 113 rows reading true were already
linked — which invites "the source says these nine are not incumbents". 🔴 **It does not.**
Grouping by `source` shows the SoS filings feed carries 295 rows of which **93 ARE flagged** — so
the flag is set for some rows from that very source and absent for others. In all nine tier-1
races, no row is flagged and none is linked: the flag is missing for the whole race, not denied
for the candidate. **`false` here is an unset default, not an assertion.**

### 16f. 🔴 Many of the 196 hold office, and not one was seated

The pamphlet shows councilmembers in Tacoma, Shoreline, Edmonds, Vancouver, Burien, Bothell, Moses
Lake, Ellensburg, Port Angeles, Aberdeen and Yakima, school directors in Puyallup, Peninsula and
Walla Walla, and a port commissioner. **We hold no politician row for any of them** — our WA
occupancy is the legislature plus a slice of King County.

▶ **A self-description identifies a person; it does not seat them.** "I am a Tacoma
councilmember" is excellent for saying WHO someone is and worth nothing as a record of WHO HOLDS A
SEAT. Occupancy comes from the body's own roster, with dates. Same family as "a certified result
is not a fact about who holds the seat" and "FIRST ELECTED IS NOT A TERM START".
▶ If those cities are seeded later, **these are the people to seat, not rows to duplicate.**

### 16g. The 70 primary losers and 5 withdrawals kept their rows untouched

Created as people per the §14 ruling; `result` and `candidate_status` were not rewritten, and a
post-verify gate asserts all 70 `not_nominated` rows survived unchanged. Those fields are what
keep them off the ballot page.

---

## 17. 🔴 THE RULE THE WHOLE PROGRAMME ENDS ON

**"There is no document" is a claim about where you looked.**

This file recorded Washington as having no instrument, on the strength of a real observation — the
certified list is a scan. The same Secretary of State was publishing every candidate's sworn
Elected Experience as JSON the whole time.

▶ Before writing *no instrument exists*, ask what the instrument was **doing** — a published,
sworn self-description — and then look for anything that does that job, **in any format**. The
standard was never the form.

---

## 18. SAN BERNARDINO — `CC_0279`, applied 2026-10-20. 5 of 5. **The programme is complete.**

**3 created · 0 linked · 0 refused.** The whole election is one race: **Director, Wrightwood
Community Services District**, five candidates, two already linked.

### 18a. 🔴 "100% DESIGNATED" IS NOT "INSTRUMENT A CAN RUN"

§6c scoped this as *"Smallest cohort in the corpus and 100% designated. An hour's work with
instrument A."* The first half is true. The second does not follow.

**A ballot designation is only an instrument when it NAMES AN OFFICE.** These name none:

| Candidate | Designation |
| --- | --- |
| Jason Agraz | "Business Owner" |
| Russ Drew | "Retired / Community Volunteer" |
| Wes Zuber | "Local Businessman" |

▶ **COUNT DESIGNATIONS THAT NAME A SEAT, NOT DESIGNATIONS.** Only the first number is a lead worth
an hour. The LA County scoping in §6d made the same count — "161 of 427 carry a ballot
designation" — and the useful figure was always the subset naming an office we record.

🟢 **The consolation: the designation still earned its keep, as a DISCONFIRMATION.** A candidate
who swears their occupation is "Retired / Community Volunteer" is stating they hold no office.
Creating all three is the *evidenced* answer, not the fallback — the same shape as Angela Taylor's
"None." in §16b.

### 18b. 🔴 THE RACE'S `office_id` IS NOT EVIDENCE IN A MULTI-SEAT BOARD RACE

Wrightwood CSD has **five Director offices**, each separately seated from the district's own
roster (`CA_0250`). The single race row carries **five candidates against ONE of those five office
ids** (`25a12bc5`, currently Alexis Claiborne's).

⚠ So "the candidate holds the very seat sought" — the strongest test in this programme, which
carried nine of Washington's twelve links — is **meaningless here**. It would match a candidate
against whichever Director row the importer happened to pick.

▶ **Open modelling question for whoever owns multi-seat races**, not fixed here: a board election
for several seats is flattened onto one arbitrary seat row. Nothing in `CC_0279` depends on which
office the race points at. 🔴 **Before using seat identity as evidence, check the race is
single-seat.**

### 18c. The dedupe pass returned empty, and the control is what makes that worth anything

🔴 An empty answer from a detector is worth nothing until the detector is shown to work. Controls
were planted and **they fired**: the same query matched "David Schoenwetter" → `David E.
Schoenwetter` and "Rick Christensen" → `Rick J. Christensen`, both sitting Wrightwood directors,
including across the middle-initial difference.

A wider surname sweep over every row, active and archived, confirms it: we hold a **Claudia**
Agraz, a **Henry** Zuber III and a **Jefferson** Van Drew, and nothing closer. The many `Drew *`
rows are first-name Drews; the `ZUBER 2018 GOVERNOR`-style rows are CAL-ACCESS committee names
sitting in `politicians`, not people.

### 18d. ⚠ CORRECTION TO EVERY CREATION MIGRATION'S HEADER: "IDEMPOTENT" IS THE WRONG WORD

`CC_0272`, `CC_0275`, `CC_0276`, `CC_0278` and `CC_0279` all say *"Idempotent: re-running inserts
nothing."* **That is true about the outcome and wrong about the mechanism.**

Each defines its cohort as `politician_id IS NULL`, so a second run finds **zero** and the count
gate raises — measured by running `CC_0279` twice in one transaction:

```
CC_0279: expected 3 to create, found 0 - the cohort moved, re-run the dedupe pass ...
```

Nothing is inserted because the transaction **ABORTS**, not because the work is skipped.
🔴 **A re-run therefore looks like a FAILURE to anything reading exit codes.** Expect the
exception; it is not drift. `CC_0279`'s header now says so; the earlier four still carry the loose
wording and are not being retro-edited.

---

## 19. ✅ THE PROGRAMME IS COMPLETE — what is actually left

**Nothing in this file is a linking backlog any more.** Five rows remain unlinked nationally and
all five are deliberate refusals, each with a named document that would settle it:

| Row | Why unlinked | What settles it |
| --- | --- | --- |
| Christine R. Sarmiento (El Monte Mayor) | existing row holds a CA GOVERNOR candidacy **and an image** | any El Monte source naming her |
| Mark Copland (Norwalk-La Mirada TA 5) | existing row holds **Area 6**; 0.0% shared area | the trustee-area redraw, or the district roster |
| Michael Braun (Walnut Valley Water, Div 2) | matches 3 rows, and the Governor of Indiana | a Walnut Valley source naming him |
| Dugger (OR) | see `CC_0274` | — |
| William E. Smith III (IN, Van Buren Twp) | **suffix**: father or son, and the incumbent row carries an IMAGE | Monroe County certified list, which prints suffixes |

Everything else in §12 is a different kind of job: occupancy gaps this programme surfaced (**the
Colorado one is now closed — `CC_0280` seeded Jefferson and Fremont**; WA's city councils and
school boards remain), the Brock/de la Torre/Parra **closed-term** backfill, and re-running the WA
pamphlet sweep for the next cycle.

🟢 **The Colorado seed is the proof that writing down who someone is pays off later.** `CC_0276`
created Amanda Gonzalez, Lesley Dahlkemper and Kevin Grantham as candidates with no office and
recorded that they were a county clerk and two county commissioners. Six migrations later
`CC_0280` seated those same three rows instead of creating duplicates.
