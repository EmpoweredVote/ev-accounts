# The re-read of the 165 — migration 1928

**2026-10-22.** Migration 1926 blanked 165 Season 2 chairs whose own reasoning said the cited
instrument *"does not by itself separate the rungs WITHIN that side"*. It kept every roll call and
the original reasoning verbatim, and called the rows **candidates for re-seating, not write-offs.**
This is that re-read.

**Result: 34 re-seated, 131 stay blank.**

Prior: [`MEASUREMENT.md`](MEASUREMENT.md) · [`../2026-10-20-repaired-chairs/LEDGER.md`](../2026-10-20-repaired-chairs/LEDGER.md)

---

## ⚖⚖ The unit of work is not 165 rows

The instruments repeat. **165 rows reduce to 59 distinct (topic, instrument-set) pairs**, each
judged once against the Season 2 ladder. That is why a re-read is tractable where row-by-row
re-research would not be — and it is the reason this pass could be done honestly in one sitting
when seating 165 rows by hand could not.

## 🔑 The one test that can rescue a direction-only row

> **Does the instrument's content state the rung's own distinguishing clause?**

Not *which rung is nearest*. Not *which is least extreme* — that is a tiebreaker, and reaching for
a tiebreaker is the signal that a row is **not** evidenced. The 34 below pass because the rung text
and the instrument say the same thing.

## The 34 re-seats

| topic | rung | rows | why the instrument **is** the rung |
|---|---:|---:|---|
| **Redistricting** | 5 | 14 | Rung 5: *"the party that controls the state legislature **without outside interference**."* The instrument is a vote **for** the 2025 **mid-decade** congressional map drawn by the legislative majority — outside the decennial cycle, no commission, no court mandate. Rung 4 asserts court oversight *to prevent extreme partisan bias*, which that vote is not. |
| **Religious Freedom** | 4 | 6 | Rung 4: *"allow **faith-based exemptions from laws that conflict with sincere religious beliefs**."* The phrase is in the bills' own captions. Rung 5 needs **complete autonomy in operations and hiring**, which none of them grants. |
| **Voting Rights** | 4 | 5 | Rung 4: *"Require photo ID in person **and an ID number on every mail ballot**."* The instrument is a vote for the bill the row itself describes as *"which requires an ID number on every mail ballot"*. |
| **Same-Sex Marriage** | 3 | 5 | Rung 3: *"Allow same-sex marriage, but **protect religious organizations' right to decline to perform or host these marriages**."* Each instrument is a bill doing exactly that — HB 3567, HB 1923, HB 2109 (*"right of recusal from the performance of certain marriage ceremonies"*). |
| **School Vouchers** | 2 | 3 | Rung 2: *"Opposing voucher programs and **blocking their expansion, without moving to eliminate existing ones**."* A vote against the bill **creating** the ESA programme is a block; Texas had nothing to eliminate. |
| **Healthcare** | 4 | 1 | Rung 4: *"**Only help the poorest people** afford healthcare."* HJR 130, authored — a constitutional amendment **prohibiting** Medicaid expansion. A prohibition asserts the ceiling. |

⚠ **The Same-Sex Marriage reservation is stated in the rows themselves, not hidden.** Filing an
exemption bill establishes the exemption position; it does not by itself prove the author would vote
to keep marriage legal. Rung 3 is the only rung of five whose text the instrument states, which is
the test. A reader who disagrees should return those rows to blank rather than move them.

## 🔴 Why 131 stayed blank — the test refused tempting rows

- **14 Healthcare rows filed Medicaid-expansion bills.** Rung 3 says *"expand programs for …
  low-income residents, **while keeping private insurance for everyone else**."* The bill expands the
  programme; it does not assert the ceiling. In Texas a legislator who wants rung 1 or 2 files the
  **same bill**, because it is the achievable step. ⚖ **Expansion proves a floor, never a ceiling** —
  which is exactly why the one row *prohibiting* expansion **was** re-seated.
- **31 Civil Rights rows.** A vote against repealing DEI offices is equally consistent with rungs 1,
  2 and 3. It excludes the anti side and chooses nothing. ⚠ And rung 4 names **federal** enforcement,
  which a state legislator cannot reach — the anti side of this ladder is short a rung for them.
- **11 Abortion rows.** Texas's trigger ban permits abortion only to save the mother's life. Rung 4
  names *"rape, incest, or serious threats to the mother's life"*; rung 5 is *"no exceptions"*. The
  instrument falls **between the two rungs**. A ladder-reachability finding, not a seat.
- **13 Climate and 11 Fossil Fuel rows.** Barring state investment in firms that boycott energy
  companies, and prohibiting a carbon tax, are neither *"ending clean energy subsidies and mandates"*
  (rung 5) nor *"expanding drilling permits"* (rung 4). Off axis.
- **1 Redistricting row authored HB 312 (86R)** — a redistricting commission bill, the one row that
  could have reached rung 1 or 2. **Fetched**: the bill sets eligibility *by reference to* a proposed
  Section 28a, Article III, which lives in a **companion constitutional amendment, not in this
  instrument**. Rung 1 (*no elected officials at any level*) versus rung 2 (*equal representation
  from both major parties*) turns on exactly that text. Blank, for want of the composition.
- **1 Redistricting row is nothing but** *"absent, undisclaimed, on 7 of 7 quorum rolls"*. An absence
  is not a position.

## Verified

| check | result |
|---|---:|
| re-seated by 1928 | **34** |
| still blank from 1926 | **131** |
| direction-only rows still seated | **0** |
| re-seated rows that lost citations | **0** |
| Season 1 answers touched | **0** |

**Chair-evidence gate on the 34: 33 pass.** The one failure is the Healthcare row — the pattern has
no alternative for **`HJR`**, a Texas House Joint Resolution, so it cannot see an instrument the row
plainly names. 🔴 **The regex was not widened in the pass that fails it.** `HJR` now joins LA council
files and SF board files on the list of vocabulary this gate cannot read; that belongs in its own
change, with its test.

## ⚠ A third concurrent write, and the board still cannot see it

Seated Season 2 rows read **3,505** where 3,496 + 34 = 3,530. The 25-row gap is **migration 1927**,
another session, applied at **04:28:35 UTC — two and a half minutes before this one** — blanking 25
rows and re-seating 14. This pass's guards confirmed 165 blanked-by-1926 before and 131 after, so
the two sets were **disjoint** and nothing was lost. That was luck, not coordination: the
`queue:repair-marker-436` lease taken for this work is still the only non-geographic claim on a
board of 760.

## ▶ Still open

- **131 rows** need real re-research, not a re-read: new evidence that separates rungs.
- **Two ladder findings** worth a ruling: Civil Rights rung 4 is unreachable for state legislators,
  and Texas's trigger ban falls between Abortion rungs 4 and 5.
- **`HJR` is invisible to the chair-evidence gate.**
- The 67 sponsorship rows and the 156 rows carrying neither template, from `MEASUREMENT.md`.
