# Candidate → person linking — handoff

**Written 2026-10-20. Author: Chris Cantrell (`CC_`). Status: CA Statewide General DONE, LA County General NOT STARTED.**

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

## 6. ▶ NEXT JOB: 2026 LA County General — 427 unlinked

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

## 7. Clearing — and it does NOT gate LA County

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
