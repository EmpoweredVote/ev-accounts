# Candidate → person linking — handoff

**Written 2026-10-20. Author: Chris Cantrell (`CC_`).**
**Status: CALIFORNIA NOVEMBER BALLOT DONE. Next job is CLEARING (§7), then the other states.**

| Election | total | linked | left |
| --- | --- | --- | --- |
| CA 2026 Statewide General | 324 | **324** | 0 |
| 2026 LA County General | 796 | **793** | 3 (judged — §6b) |
| 2026 San Bernardino County General | 5 | 2 | 3 (not examined) |

Migrations: `CC_0262`-`CC_0272`. 549 candidacies linked, 518 people created, 11 wrong people
refused, 7 left unlinked by judgement across the programme.

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

### 6c. Not examined: 2026 San Bernardino County General — 3 unlinked, all designated

Smallest cohort in the corpus and 100% designated. An hour's work with instrument A.

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

## 7. ▶▶ NEXT JOB: THE CLEARING. Start here when picking this back up.

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

**The queue, in order:**

1. **THE CLEARING (§7)** — 85 WA/CO rows that must not become people. No migration needed; it is a
   filter on the next creation sweep. Decide the 'filed' rule and record it here.
2. **San Bernardino County General (§6c)** — 3 rows, all designated. An hour.
3. **The other states** — WA 134 live, CO 72, IN 13, TX 11, NV 3, OR 3 = **236**. 🔴 **None has a
   ballot designation**, so instrument A cannot run and this is creation-only unless a per-state
   document is found first. That is the open question in §11.
4. **The three LA residue rows (§6b)** — one citation each.
5. **Brock / de la Torre / Parra closed-term backfill** — history, not occupancy. Needs documented
   start AND end dates. **DO NOT SEAT THEM** (see the correction at the top).

**Before any creation sweep, every time:**
- Run the dedupe pass (§5) with the **nickname list**, accents, punctuation and archived rows.
- Run the cross-state test (§4). One in ten single-namesake matches is a different human.
- Read the **area share**, never bare `ST_Intersects` (§3).
- Run the guards **in this branch's own worktree**, and read the file count they print (§10).
- Expect to find the next CI statement-timeout ceiling; work in slices (§10).

**State of the work as of 2026-10-20:** `CC_0262`-`CC_0272` applied and on master. Branch
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
