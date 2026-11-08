# The 2026-12-14 handover — City of Los Angeles

**Four Los Angeles city seats take office on Monday 2026-12-14** — LA City Charter § 205(c),
the second Monday in December. This is the third and last dated piece of the December local wave,
after the 2026-12-04 special districts (`CC_0377`) and the 2026-12-11 school boards (`CC_0378`).

The pipeline is the shared one in
[`../ca-special-districts-2026-results/`](../ca-special-districts-2026-results/NOTES.md) — read
that first. Only what is different about the city is here.

## State as of 2026-11-08 (`CC_0379`)

| | contest | margin | bound | |
| --- | --- | --- | --- | --- |
| ✅ | **City Attorney** | 360,182 | 131,000 | 🏆 Marissa Roy 673,463 · John McKinney 313,281 |
| ✅ | **Mayor** | — | — | 🏆 Nithya Raman 579,501 · Karen Ruth Bass 484,580 *(incumbent, DEFEATED)* — on **AP's call**, `CC_0380` |
| ⏳ | Council District 3 | 1,869 | 10,080 | Barri Worth Girvan 34,442 · Timothy K. Gaspar 32,573 |
| ⏳ | Council District 9 | 417 | 5,094 | Jose Ugarte 18,487 · Estuardo Mazariegos 18,070 |

## 🔴🔴 CORRECTED 2026-11-08 — AP HAD ALREADY CALLED THE MAYORALTY, AND I DID NOT LOOK

`CC_0379` held the mayoralty back and said, in its own header: *"AP would call this race. We
have no caller."* **The second half was false, and it was false when it was written.**

AP's feed carries **nine mayoral races** under `officeID: "M"`, the Los Angeles mayoralty among
them, and it had called it for Nithya Raman at **2026-11-05T19:49:13Z** — three days before
`CC_0379` was applied. The absence of a caller was **asserted, not checked**, against a feed
this repo reads for every federal and state-executive result.

▶ **AN ABSENCE YOU DID NOT LOOK FOR IS NOT A FINDING.** The 96 cancelled school elections were
held to exactly this rule — *run the check from the source's own catalogue* — and it was not
applied to the source we use most. `CC_0380` records the result on AP's flag, the same basis as
`CC_0339` (Senate), `CC_0350` (House) and `CC_0357` (state executives).

⚠ **Nothing `CC_0379` WROTE was wrong.** The City Attorney row stands, and Council Districts 3
and 9 were correctly held — AP carries no council contest, so for those the bound really is the
only test. Only its *reason* for holding the mayoralty was wrong.

🟢 **TWO INDEPENDENT SOURCES AGREE TO THE VOTE.** AP publishes 579,501 and 484,580; the county
feed publishes 579,501 and 484,580. Neither is reading the other — both are reading the county.

⚠ **THE CONCESSION IS CORROBORATION, NOT THE BASIS.** Karen Bass conceded on 2026-11-05 — *"I
have called Councilmember Nithya Raman to congratulate her on her victory"*. A concession is a
statement by a candidate, not a count and not a call. It is recorded because it explains why the
question was re-opened, not because anything rests on it.

⚠ **WE HOLD 19 MAYORAL RACES ON THIS BALLOT AND AP CARRIES 9; ONLY LOS ANGELES IS IN BOTH SETS.**
AP's other eight are cities we hold no race for — a seeding gap, reported and not acted on.

## 🔴 The bound still governs everything AP does not carry

It was never the wrong rule — it is the rule for contests with no caller, which is almost all of
this wave. Council Districts 3 and 9 remain held on margins of 1,869 and 417.


## 🔴 A safety multiple can exceed the county's whole outstanding pile

The mayoral contest is **37% of the county's ballots**, so its proportional share of the 131,000 is
~49,025 — and three times that is **147,087**, which is more late ballots than exist anywhere in
Los Angeles County. A bound larger than the most that could possibly arrive is not a bound.

▶ **The bound is now capped at the countywide outstanding figure.** It changes no outcome here,
but a cap that only bites in the largest contests is exactly the one nobody notices is missing.

## ⚠ Three things about this city that the matcher had to learn

1. **All four contests share one title prefix** — `LOS ANGELES CITY GENERAL MUNICIPAL ELECTION` —
   so the title cannot say which council district a contest is. The anchor is the candidate set.
2. **Our district labels are bare**: `District 3`, `District 9`, with the city named nowhere in
   them (CLAUDE.md: there is no jurisdiction key in this data). The title check now falls back to
   the **government's own name**, taking the part before the first comma, because governments are
   named "Los Angeles, California, US" and no county contest title says California.
3. **The same seat is numbered four ways** across these sources — `Division 2`, `Trustee Area 3`,
   `District 9`, and the county's ordinal `9th District`. The seat-number check reads all four.

⚠ The county calls it `LOS ANGELES CITY GENERAL MUNICIPAL ELECTION`, **not** "City of Los
Angeles". Searching for the latter returns nothing and reads as the city being absent from the
feed.

## 🔴 We hold TWO Los Angeles mayoral races, and a control fell into the gap

The **June 2026 primary** (14 candidates, no swearing-in row) and the **November general** (Bass
and Raman). Both are correct and both should be there.

A control that planted a result on "the Mayor row for Nithya Raman, `LIMIT 1`" landed on the
**primary**, which this wave does not contain — so it never reached the gate it was written for,
and the run read as *the gate failing*. ▶ **A tamper must reach its target; address the row by
uuid.** Fixed, and the control then fired.

## ▶ What happens next

**2026-12-01 — LA certifies.** Record Council Districts 3 and 9, and upgrade all four to
`certified`. ⚠ AP reports `isCertified: false` on the mayoralty too, so it is upgraded from the
state's return like everything else — a call and a canvass are two facts.

**2026-12-14 — seat the four winners**, Charter § 205(c). 🔴 `seat_officeholder` does not clear
`is_vacant`, and **Karen Bass's term must be closed on 2026-12-13**, the day before Nithya
Raman's begins. Her term row today is open-ended with `term_start` NULL (a phase-2 backfill from
the dropped `offices.politician_id`), so closing it is the whole of what makes the handover
visible — the view resolves "current" by date containment and nothing else.

▶ **AP carries 9 mayoral races and we hold a race for only one of them.** The other eight —
Oakland, Washington DC, Louisville, Little Rock, and the NC, NV, RI and WV cities — are seats we
have no 2026 race for at all. That is a seeding gap, not a results one, and it is the same shape
as the 73 state-executive races `CC_0359` had to create.
