# Wisconsin 2026 swearing-in dates — rules, sources, and what is still owed

Piece 4 of the post-election transition programme, Wisconsin slice. Read this before touching
`essentials.office_swearing_in` for Wisconsin, and before seating any Wisconsin winner.

**Applied to production 2026-11-16 as `CC_0445`: 123 offices, one date, four authorities.**

🟢 **THIS IS THE FIRST STATE LEGISLATURE IN THE PROGRAMME TO CARRY SWEARING-IN DATES.**
Measured straight after applying: **116 `STATE_LOWER`/`STATE_UPPER` offices nationwide have a
swearing-in date, and all 116 are Wisconsin's.** Before this, the whole legislative tier had
none and only Wisconsin's 8 US House seats had one.

---

## The date

**Every Wisconsin office elected on 2026-11-03 hands over on Monday 4 January 2027.**

Computed, not assumed: 2027-01-01 is a Friday, so the first Monday of January 2027 is the 4th.
The migration's gate re-derives this (`ISODOW = 1`, day ≤ 7, month 1, year 2027) rather than
trusting the literal, because a one-day transcription slip would otherwise pass every count.

| Group | n | Authority |
|---|---|---|
| Representatives to the Assembly | 99 | [Wis. Const. art. XIII § 1](https://docs.legis.wisconsin.gov/document/wisconsinconstitution/XIII,1) + [Wis. Stat. § 13.02(1)](https://docs.legis.wisconsin.gov/statutes/statutes/13/i/02) |
| State Senators (odd districts) | 17 | same |
| Statewide executives | 5 | art. XIII § 1; terms from [art. V § 1](https://docs.legis.wisconsin.gov/document/wisconsinconstitution/V,1) and [art. VI § 1](https://docs.legis.wisconsin.gov/document/wisconsinconstitution/VI,1) |
| Racine County Sheriff | 1 | [Wis. Stat. § 59.20(2)(b)](https://docs.legis.wisconsin.gov/document/statutes/59.20) |
| Racine County Clerk of Circuit Court | 1 | [Wis. Stat. § 59.20(2)(bm)](https://docs.legis.wisconsin.gov/document/statutes/59.20) |

### The two texts that do the work

**Wis. Const. art. XIII § 1** (political year; elections) —

> "The political year for this state shall commence on the first Monday of January in each
> year, and the general election shall be held on the Tuesday next succeeding the first Monday
> of November in even-numbered years."

**Wis. Stat. § 13.02(1)** (regular sessions) —

> "The legislature shall convene in the capitol on the first Monday of January in each
> odd-numbered year, at 2 p.m., **to take the oath of office**, select officers, and do all
> other things necessary to organize itself for the conduct of its business, but if the first
> Monday of January falls on January 1 or 2, the actions here required shall be taken on
> January 3."

Art. XIII § 1 gives the term commencement; § 13.02(1) gives the oath. They coincide.

### Corroboration specific to this cycle

**2025 Senate Joint Resolution 1 (enrolled), § 1(1)** —

> "The legislature declares that the biennial session period of the 2025 Wisconsin Legislature
> began on Monday, January 6, 2025, and that the biennial session period **ends at noon on
> Monday, January 4, 2027**."

The outgoing session ends at noon; § 13.02(1) convenes the incoming one at 2 p.m. the same day.
▶ **This is the Legislature's own cycle-specific statement**, not an inference from the general
rule, and it is the thing to re-read if the date is ever doubted.

---

## 🔴 § 59.20(2) IS NOT A BLANKET COUNTY RULE, AND IT CONTAINS A COUNTER-EXAMPLE TO ITSELF

Paragraph **(a)** names only the register of deeds, county clerk, treasurer and surveyor —
**not** the sheriff, **not** the clerk of circuit court. Each of those has its own paragraph,
(b) and (bm). And paragraph **(am)** puts the comptroller on the **3rd Tuesday in April**.

So the subsection that looks like "all county officers, first Monday of January" contains an
office that commences in April. ▶ **Cite the paragraph, never the subsection.** This is the
California lesson (`Elec. Code § 10554` applied to all 25 district offices, then over-corrected)
arriving in a different state, and it was caught here only by reading which officers paragraph
(a) actually names.

## 🔴 ONLY 17 OF THE 33 SENATE SEATS ARE HERE, AND THAT IS CORRECT

**Wis. Const. art. IV § 5** —

> "The senate districts shall be numbered in the regular series, and the senators shall be
> chosen **alternately from the odd and even-numbered districts** for the term of 4 years."

The odd districts were up in 2026. The 16 even-numbered senators are mid-term and this election
does not touch them, so they get no row for it.

⚠ **A pass that expected 33 would read 16 absences as drift.** The migration's pre-check asserts
17 *and* asserts that none of the 17 is an even-numbered district — because a wrong 17 is also
17, and the count alone cannot tell the difference.

## ⚠ The § 13.02(1) adjustment is live; it just does not bite this cycle

It moves the day to January 3 when the first Monday is January 1 or 2. That has happened within
the current data's memory:

| cycle | first Monday | oath day under § 13.02(1) |
|---|---|---|
| 2019 | Mon 2019-01-07 | 2019-01-07 |
| 2021 | Mon 2021-01-04 | 2021-01-04 |
| **2023** | **Mon 2023-01-02** | **2023-01-03 — adjusted** |
| 2025 | Mon 2025-01-06 | 2025-01-06 |
| **2027** | **Mon 2027-01-04** | **2027-01-04 — no adjustment** |

🟢 **AND 2023 ANSWERS A QUESTION THE TEXTS DO NOT.** Art. XIII § 1 sets the political year to the
first Monday with no adjustment clause, so on its face the 2023 executives' terms began Jan 2
while the legislature's oath moved to Jan 3. In practice Wisconsin swore in **the governor,
lieutenant governor, attorney general, secretary of state, treasurer and both houses together on
January 3, 2023**. The executives follow the adjusted legislative day. ▶ **If a future cycle
lands on January 1 or 2, use the adjusted date for the executives too** — do not reason from
art. XIII § 1 alone.

---

## 🔴 NOBODY IS SEATED, AND THAT IS THE POINT

`CC_0445` records **when** the handover happens. It does not perform it, and its gate asserts
that zero Wisconsin terms start on 2027-01-04.

**Every losing Wisconsin incumbent still holds their seat today and keeps it until 4 January.**
A seating pass before that date would unseat sitting officials and hand their seats to people
who do not yet hold them.

### ▶ 2027-01-04 — the seating pass

On or after that date, one migration should:

1. Close the outgoing term at **2027-01-03** and open the winner's at **2027-01-04**, via
   `essentials.seat_officeholder`. The helper closes the predecessor at `term_start - 1`, so
   passing 2027-01-04 does the right thing.
2. Handle **re-elected incumbents** — most of the 121 state winners already hold the seat. That
   is where `p_allow_reelection` matters.
3. 🔴 **Clear `is_vacant` by hand on any seat that carries it.** `seat_officeholder` does NOT
   clear the flag, so a seated-and-flagged office emits a spurious all-NULL row.
4. Set `politicians.is_incumbent = true` explicitly on every person seated. It defaults to
   `false`, and a seated person without it is hidden from address search.
5. Expect the 99 Assembly seats to need **term_end** set two years out and the 17 Senate seats
   four, per art. IV §§ 4 and 5 — but do not write a `term_end` you cannot cite.

---

## Still owed for Wisconsin

- 🔴 **The Racine County Sheriff race has no result recorded.** Two candidates, Cary A. Madrigal
  and Donald E. Vandervest, both `result = NULL`, no `result_source`. It has a swearing-in date
  and no winner to seat. The Clerk of Circuit Court race beside it *is* recorded (Amy Vanderhoef,
  cited to the county's own final Election Summary Report), so this is a gap in that one race,
  not in the county.
  ⚠ Watch the shape of the query that finds it: a `count(DISTINCT rc.politician_id) FILTER
  (WHERE result='won')` reported **0 winners** for the whole Wisconsin county tier, which is
  wrong — Vanderhoef won, but her row's `politician_id` is NULL, so counting distinct person ids
  hid a recorded result. **Count the candidacy rows, not the people behind them.**
- **9 of the 2026 winners still have no headshot** — see
  `backend/data/wi-transition-headshots-2026/NOTES.md`.
- **The 16 even-numbered Senate districts** are up in 2028, not now.

## The controls, and the two that exposed real holes

Four tampers, each meant to change one thing. **Two passed on the first run, and both were real
gaps in the gate, not noise:**

| control | expected | first run | after the fix |
|---|---|---|---|
| wrong day on the executives' insert | wrong-date gate | ✅ `5 row(s) are not on 2027-01-04` | ✅ |
| sheriff insert widened to grab the clerk too | per-group counts | 🔴 **PASSED** | ✅ `COUNTY/Clerk of Circuit Court → wi-county-sheriff-59-20-2-b` |
| executives given the legislature's rule_id | rule check | 🔴 **PASSED** | ✅ `STATE_EXEC → wi-legislature-first-monday` |
| Assembly insert widened to every state | scope-leak gate | ✅ `751 row(s) landed outside the intended scope` | ✅ |

🔴🔴 **THE HOLE WAS THE SAME IN BOTH: THE GATE CHECKED THE RULE VOCABULARY, NOT THE PAIRING.**
It asserted every `rule_id` was one of the four allowed strings. It never asserted that the
executives carry the *executive* rule and the sheriff the *sheriff* rule. So a row could cite a
statute that does not govern it — the exact defect the whole file exists to prevent — while every
count stayed right. **Counting the right number of rows says nothing about whether each row says
the right thing.** The gate now asserts the `(group → rule_id)` pairs explicitly, and separately
asserts all five pairings are present, so a vanished group cannot pass by having nothing to
disagree with.

🔴 **AND THE THIRD CONTROL PASSED A SECOND TIME FOR A DIFFERENT REASON — THE TAMPER EDITED THE
DETECTOR.** A global `sed` on `'wi-state-exec-first-monday'` rewrote the gate's own expectation
list along with the INSERT, so the file agreed with itself and passed. The tamper applied
perfectly and tested nothing. ▶ **A tamper must change the data and leave the assertion alone;
check that the expectation survived it**, not merely that the file changed.
