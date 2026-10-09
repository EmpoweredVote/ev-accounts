# The six remaining finance splits — adjudicated 2026-10-09

Follow-on from `CC_0211` / `CC_0212`. Those two retired 11 archived duplicate rows and recovered the
campaign finance stranded on them (Jehlen 3,649 contributions, DiDomenico 8,598, Decker 6,926,
Rogers 2,783). The sweep behind them found **170 inactive rows sharing a first and last name with an
active row, 9 of which hold contributions.** Four are done. These are the remaining six.

## 🔴🔴 THE HEADLINE: FIVE OF THE SIX MUST NOT BE MERGED

**Merging them would have published other people's donations on a real politician's page.** The
money on those rows does not belong to the person named on them.

`confirm-cal-access.ts` matched CAL-ACCESS committees to politicians **by surname**, and attached
every same-surname committee it found to one row. The rows became surname buckets. Measured, with
the committee's own appended forename against the row's forename:

| Row (all `is_active = false`) | Committee name says | Contributions | Dollars |
|---|---|---|---|
| Gil Hurtado | **MELISSA**, ESMERALDA | 476 | $3,441,162 |
| David Patterson | **JOE** ×3 | 1,418 | $2,337,165 |
| Arthur Dixon | **DIANE** ×5, RONDA | 1,746 | $1,885,399 |
| Fernando Dutra | **JOHN** | 1,631 | $1,599,020 |
| John M. Erickson | BRIAN | 323 | $120,037 |
| Angie Reyes English | KEN | 167 | $93,652 |
| Bryan "Bubba" Fish | JONATHAN | 9 | $34,649 |

Melissa Hurtado, Joe Patterson, Diane Dixon and John Dutra are all real California legislators.
**Every one of these is marked `confirmed_by: confirm-cal-access.ts`, not `--ambiguous`.**

Gil Hurtado's row is the clearest case: **24 committees belonging to at least seven different
Hurtados** — Melissa (state senator), Esmeralda, Jewel, G. Sylvia, Ricky, Jaime and Gil — of which
Melissa's three Senate committees hold 2,044 of the 2,061 contributions. Arthur Dixon's row holds 43,
including committees named for the **city** of Dixon ("DIXON CITY COUNCIL", "DIXON UNIFIED SCHOOL
DISTRICT", "BOGUE FOR DIXON CITY COUNCIL") — the surname is also a place name.

🟢 **No voter sees any of this today: all seven affected rows are inactive.** The harm would have been
created by the merge, not by the bug. That is the whole point.

### ⚠ TWO FALSE TRAILS, BOTH WORTH KEEPING

1. **"The politician's forename does not appear in the committee name" is a USELESS predicate.** Most
   CAL-ACCESS committees are named `SURNAME FOR OFFICE YEAR` with no forename at all, so that test
   flags **"NEWSOM FOR CALIFORNIA GOVERNOR 2018" on Gavin Newsom** — and ~$13M of other perfectly
   correct attributions (Muratsuchi, Strickland, Gipson, Irwin, Caloza, Lackey, Bryan, Solache…).
   ▶ The only reliable signal is an **explicit forename that CONFLICTS**, taken from the `;`/`,` tail.
2. **A middle name in `full_name` fakes a conflict.** `KAREN` against "Karen Ruth" Bass, `JOHN`
   against "John M." Erickson, `AMY` against "Amy Thomas" Howorth, `HOLLY` against "Holly J."
   Mitchell, `JANET` against "Janet Keo" Conklin — all five correct, all five flagged until the
   comparison allowed a leading-forename match.

An earlier draft of this note reported 2,614 disagreements corpus-wide. **That number is wrong** and
came from predicate (1); the defensible figure is the table above.

## ▶ THE ONE GENUINE MERGE: JOHN FLEMING — needs a decision, not a migration

| | `a750bce8` (active) | `8be7e981` (inactive) |
|---|---|---|
| seat | **Treasurer, Louisiana** (open term) | Candidate for U.S. Senate — Louisiana, `2024-12-13 .. 2026-06-27` |
| stance answers | **15** across 2 seasons | **20** across 2 seasons |
| finance | none | `fec_senate:S6LA00318` |
| photo origin | none | `unitedstates.github.io/images/congress/225` (a congressional portrait) |

**Identity is settled, two sources.** `treasury.la.gov/about/meet-the-treasurer` names "John Fleming,
MD" as Treasurer; Ballotpedia's "John Fleming (Louisiana)" records the Treasurer tenure (2024–),
the 4th Congressional District service, and that **he lost the Republican Senate primary runoff on
2026-06-27** — which is exactly the `term_end` on our inactive row. One man: US Rep → Senate
candidate → State Treasurer.

🔴 **This is NOT the CC_0211/CC_0212 shape and must not be done the same way.** Those retired rows
held *nothing*. This one holds **20 stance answers across two seasons**, against an active row that
holds 15. A merge has to decide what happens where both rows answer the same topic in the same
season, and Season 1 is closed — `inform.closed_season_is_immutable()` will refuse, and the
`inform.allow_closed_season_write` hatch is legitimate only for re-pointing `politician_id` without
touching content ([[reference_duplicate_name_guard_predicate]], the `CC_0186` precedent).

**Open question for the operator: what happens to an overlapping (topic, season) pair?** Nothing
should be guessed here.

## The two Indiana leads — weak, left alone

- **Michael Thompson** `b01acc58` — `indiana:8112`, committee "Patriots for Mike Thompson",
  33 contributions / $13,035. The active namesake holds no seat and 23 contributions of its own.
  An extremely common name; no evidence either way. **Not ruled.**
- **Jessica Mccormick** `2f1440e0` — `indiana:7997`, committee "McCormick for Indiana",
  2 contributions / $1,594. The active namesake is Councilor, District 16. "McCormick for Indiana"
  reads like a statewide committee, which a district councillor is not. **Not ruled.**

## Recommended order, if this is picked up

1. **Fix the attribution first, then merge — never the reverse.** Detaching a mis-attributed
   committee is reversible and invisible; publishing it on an active politician is neither.
2. The real defect is in `confirm-cal-access.ts`: it writes `confirmed` for a surname match. It
   should require the forename where CAL-ACCESS supplies one, and mark the rest `needs_research`
   rather than `confirmed`.
3. Only then retire the duplicate rows (Hurtado, Dutra, Dixon are each plausibly one person with
   their active namesake — the dispute is the money, not the identity).
4. Fleming is independent of all of the above and blocked only on the season question.
