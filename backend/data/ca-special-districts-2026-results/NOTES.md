# The 2026-12-04 handover — California special districts

**19 seats across 14 special districts take office at noon on Friday 2026-12-04.** That is the
earliest handover anywhere in the post-election transition programme, and the first piece of the
local tier, which held zero recorded winners against 524 races until `CC_0377`.

The swearing-in date is not a guess: `essentials.office_swearing_in` carries one row per office
with the statute quoted, from piece 4 (`CC_0344`–`CC_0347`). The rules themselves are in
[`../ca-2026-swearing-in/RULES.md`](../ca-2026-swearing-in/RULES.md) — read that before changing
a date here.

| authority | bodies |
| --- | --- |
| Cal. Water Code § 71253 | municipal water districts (Foothill ×3, Las Virgenes, San Gabriel Valley, Three Valleys, West Basin ×2) |
| Cal. Elec. Code § 10554 | county water districts (Crescenta Valley, La Puente Valley, Valley County) |
| Cal. Water Code § 35057 → UDEL → § 10554 | California water districts (Walnut Valley ×3) |
| Cal. Water Code § 21101 | irrigation districts (La Cañada, Palmdale) |
| Cal. Educ. Code § 19700(b) | library districts, chapter 9 (Altadena, Palos Verdes) |
| Cal. Gov. Code § 61042(a) | community services districts (Wrightwood) |

## Where the numbers come from

Two counties run these contests, and **neither publishes a winner flag**.

### Los Angeles County RR/CC

`results.lavote.gov` serves the page's own JSON API, with no key. `fetch-county-results.mjs`
calls it. It arrives in two pieces and **neither is usable alone**:

| endpoint | what it holds |
| --- | --- |
| `ElectionResults/GetElectionData?electionID=4348` | contests, candidates, candidate ids. **Every `Votes` is 0 and every `Winner` is false.** |
| `ElectionResults/GetCounterData?electionID=4348` | the counts, keyed by candidate id (`ReferenceType: "CAND"`), plus per-contest `CBLT` ballots cast, `CUV`/`COV` under- and overvotes, `WRTN-nn` write-ins, `NSEL-nn` not-selected per seat position |

🔴🔴 **`GetElectionData` IS THE BALLOT, NOT THE RESULT.** Read on its own it describes a complete
election in which nobody received a vote — and a zero that arrives in the shape of a result reads
as "no results yet", not as a wrong endpoint. The analyser refuses to proceed unless the join
carries votes.

The menu endpoints are `GetMenuYears`, `GetMenuElections?year=NNNN` and
`GetMenuGroups?electionID=N`. Election **4348** is the 2026-11-03 General.

🟢 **A FREE SECOND READING OF EVERY NUMBER.** `results.lavote.gov/text-results/4348` is rendered
by the server from the same data, independently of the JSON the analyser joins. All 22 recorded
numbers agree across the two.

### San Bernardino County ROV

`results.rov.sbcounty.gov/Results/20261103/` — one server-rendered page per election, with a
Print-Friendly PDF and an XLSX beside it. As of 2026-11-08 it still reads **"Final Unofficial
Election Night Results"**, Summary Report #5, 366,322 of 1,249,278 cast (29.32%), and the "next
update" line on the page is a week stale. It publishes **no outstanding-ballot estimate**.

## 🔴🔴 A special district can straddle a county line, and each county publishes only its slice

**Wrightwood CSD is in both counties.** Los Angeles holds **71** ballots and files it under
**"Recreation and Park"** — not "Water Districts", and not anywhere you would look. San Bernardino
holds **1,309**. Each county's page shows the full five-candidate ballot and a complete-looking
contest.

Reading either county alone would have ranked that board on 5% or 95% of its electorate, and
nothing would have looked wrong.

▶ **The analyser anchors every race on its CANDIDATE SET, and sums across counties when the same
set appears in more than one.** It also refuses any contest LA itself flags `Shared with …` when
only one county's slice was found. LA marks these in `AdditionalText`; Wrightwood is the only one
of our 19, but Antelope Valley–East Kern (Kern, Ventura) and Santa Clarita Valley (Ventura) carry
the same note.

## 🔴 The call is ours, so it is arithmetic and nothing else

Every earlier pass in this programme recorded `called` on **AP's own flag** or Ballotpedia's, and
the rule that made it safe was *use the flag, never the count*. There is no flag here.

A contest is recorded only when the trailing candidate **could not overtake the leader even if
every ballot still uncounted in that contest broke their way** and the leader gained none. That is
a bound on the worst case, not a projection about how late ballots lean.

🔴 **THE PER-CONTEST OUTSTANDING FIGURE DOES NOT EXIST.** Only a countywide one is published — LA's
"Post-Election Night Ballot Count Update", read 2026-11-08: **131,000 outstanding** (94,000
vote-by-mail, 32,000 conditional-registration, 5,000 provisional) against **3,041,114 counted**,
51.47% turnout. It is apportioned by each contest's share of ballots cast and multiplied by
**three**, so a district would have to hold three times its proportional share of everything left
before the bound could be wrong.

⚠ **THE BOUND DECIDES, NOT THE MARGIN, AND A BIG LEAD CAN FAIL IT.** West Basin Division 2 leads by
2,614 and is held; La Cañada Division 4 leads by 290 and is recorded. The difference is contest
size — 57,515 ballots against 992.

## State as of 2026-11-08 (`CC_0377`)

**9 races recorded (11 seats) · 10 held · 0 certified.**

| | race | margin | bound | why |
| --- | --- | --- | --- | --- |
| ✅ | Crescenta Valley WD (3 of 4) | 2,466 | 1,116 | |
| ✅ | Foothill MWD Div 2 | 1,445 | 966 | |
| ✅ | Foothill MWD Div 4 | 3,495 | 1,053 | incumbent Laura Olhasso defeated |
| ✅ | Foothill MWD Div 5 | 985 | 915 | ⚠ the narrowest call here |
| ✅ | La Cañada ID Div 4 | 290 | 129 | incumbent Sheree Rae Butts defeated |
| ✅ | Las Virgenes MWD Div 2 | 1,895 | 651 | |
| ✅ | Walnut Valley WD Div 2 | 1,194 | 930 | |
| ✅ | Walnut Valley WD Div 3 | 2,469 | 783 | |
| ✅ | West Basin MWD Div 1 | 13,773 | 8,904 | |
| ⏳ | Altadena Library Trustee Area 3 | 179 | 282 | |
| ⏳ | La Puente Valley CWD (3 of 6) | 266 | 369 | |
| ⏳ | Palmdale WD Div 2 | 589 | 762 | |
| ⏳ | Palos Verdes Library (3 of 6) | 1,360 | 4,254 | |
| ⏳ | San Gabriel Valley MWD Div 5 | 674 | 1,266 | |
| ⏳ | Three Valleys MWD Div 3 | 1,145 | 4,044 | fills a vacancy dated 2026-06-03 (`CC_0301`) |
| ⏳ | Valley County WD (3 of 5) | 465 | 1,653 | |
| ⏳ | Walnut Valley WD Div 5 | 113 | 747 | **special election, unexpired term ending 2028-12-01** |
| ⏳ | West Basin MWD Div 2 | 2,614 | 7,434 | incumbent Gloria D. Gray trailing |
| ⏳ | Wrightwood CSD (3 of 5) | 98 | — | spans two counties; San Bernardino bounds nothing |

## ▶ What happens next, and when

**2026-12-01 — both counties certify** (28 days after the election, Cal. Elec. Code § 15372).
Re-run `fetch-county-results.mjs` and `analyse-results.mjs`, then one migration that:

1. records the ten held-back races, and
2. upgrades all nineteen to `result_certainty = 'certified'`.

**2026-12-04 — seat 29 winners**, dated `2026-12-04`, with `essentials.seat_officeholder`.
Three things that wave must get right:

- 🔴 **`seat_officeholder` DOES NOT CLEAR `is_vacant`.** Three Valleys MWD Division 3 is flagged
  vacant since 2026-06-03 (`CC_0301`); seating its winner leaves the seat held **and** vacant
  unless the migration clears the flag itself and asserts it.
- 🔴 **Re-election is the majority case here** — six of the eleven winners already recorded are
  sitting directors. `seat_officeholder` needs `p_allow_reelection => true` (`CC_0338`) and
  RAISEs without it.
- 🔴 **Four of these bodies are ONE office carrying `seats = 3`**, so `office_current_holder` can
  only ever name one of the three sitting directors. Do not read that as a vacancy, and do not
  build a gate that expects the view to know about the other two.
- ⚠ **Walnut Valley Division 5 is a SPECIAL election for an unexpired term ending 2028-12-01.**
  The term this seating writes is shorter than the others; do not copy the four-year pattern onto
  it.

**Not before then.** A certified result is not a fact about who holds the seat, and these winners
take office at noon on 2026-12-04 and not a day earlier. `CC_0377` seats nobody and asserts it.

## Running the tools

```bash
# from a checkout with node_modules; the fetchers and the analyser need none
node fetch-county-results.mjs .                     # raw extracts, stamped with today's date
RESOLVE_FROM=<checkout>/backend/package.json \
  node -r dotenv/config dump-our-rows.mjs ./our-candidacies-YYYY-MM-DD.json
node analyse-results.mjs . YYYY-MM-DD               # the decision; writes analysis-<date>.json
node emit-values.mjs analysis-YYYY-MM-DD.json       # the migration's VALUES, never retyped
node controls-analyse.mjs . YYYY-MM-DD              # 7 tampers against the analyser
node controls377.mjs <migration.sql> <dry-run-migration.mjs>   # 10 tampers against the gates
```

⚠ **ESM ignores `NODE_PATH`,** and a linked worktree has no `node_modules`. `dump-our-rows.mjs`
takes `RESOLVE_FROM` instead. **Do not plant a `node_modules` junction** — `git worktree remove`
follows one straight into the main checkout.

## Two traps this piece paid for

🔴 **A UNIFORM ZERO IS A BROKEN DETECTOR, NOT AN EMPTY ELECTION.** The first read of
`GetElectionData` returned 1,023 candidates at 0 votes with every winner flag false. That is the
shape of "the election has no results yet" and it was the wrong endpoint.

🔴 **THE PAGES WRITE ACCENTS AS NUMERIC ENTITIES.** `LA CA&#xD1;ADA`, `ERIK PE&#xD1;A`. Three
candidates in two contests came back "absent from the text-results page", which reads exactly like
two sources disagreeing about who was on the ballot — and it was this repo's own parser. A
positive control now refuses to believe **any** absence unless the index can first see those two
lines. ▶ Never report a mismatch that a normalisation step could have produced.
