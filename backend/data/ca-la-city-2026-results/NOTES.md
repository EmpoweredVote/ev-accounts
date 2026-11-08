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
| ⏳ | **Mayor** | 94,921 | 131,000 | Nithya Raman 579,501 · Karen Ruth Bass 484,580 *(incumbent)* |
| ⏳ | Council District 3 | 1,869 | 10,080 | Barri Worth Girvan 34,442 · Timothy K. Gaspar 32,573 |
| ⏳ | Council District 9 | 417 | 5,094 | Jose Ugarte 18,487 · Estuardo Mazariegos 18,070 |

## ⚠ A sitting mayor is 94,921 votes behind and that is still not arithmetic

131,000 ballots remain uncounted countywide, so the trailing candidate *could* in principle
overtake. AP would call this race. **We have no caller**, so this programme records `called` only
where the margin exceeds everything that could still arrive.

Leaving the mayoralty NULL for three more weeks is the cost of that standard, and it is the right
cost: the alternative is a rule that sometimes means "arithmetic" and sometimes means "it looks
settled", and nobody downstream could tell which. LA certifies by **2026-12-01**, ten working days
before these seats turn over.

🔴 A control plants a result on the mayoralty specifically, and the migration refuses it.

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

**2026-12-01 — LA certifies.** Record the Mayor, Council District 3 and Council District 9, and
upgrade all four to `certified`.

**2026-12-14 — seat the four winners**, Charter § 205(c). 🔴 `seat_officeholder` does not clear
`is_vacant`, and Karen Bass's term must be closed the day before her successor's begins if she
does not hold the seat.
