# Contradiction check, round two — the next five groups

**Migration 1943, applied to production 2026-10-25.** 125 rows read one by one, 82 written:
**51 seated, 31 withdrawn, 43 deliberately left alone.**

The instrument/rung contradiction check (`backend/scripts/check-instrument-rung-contradictions.mjs`,
PR #1085, **not merged** — installed temporarily for this pass) groups rows that cite ONE instrument,
take the SAME side of it, and sit on DIFFERENT rungs of ONE ladder revision. Migration 1942 worked
its eight largest groups. This is the next five.

| rows | instrument | ladder | side | decision | written |
|---:|---|---|---|---|---:|
| 33 | Climate Solutions Now Act (MD SB 528, 2022) | climate-change | FOR | re-seat all 33 → Season 2 chair 1 | 33 |
| 33 | Tax Cuts and Jobs Act (2017) | taxes | FOR | **withdrawn from the pass** | 0 |
| 20 | Blueprint for Maryland's Future (HB 1300/HB 1372) | school-vouchers | FOR | withdraw all 20 | 20 |
| 20 | Respect for Marriage Act | same-sex-marriage | **AGAINST** | withdraw 11, keep 9 | 11 |
| 19 | Opting in on Opportunity Act (MD HB 455, 2026) | school-vouchers | SPONSOR | re-seat 18, leave 1 | 18 |

**Queue: 142 groups / 945 rows → 138 / 853.** Four groups dissolved; the Tax Cuts and Jobs Act
group stays in the queue, correctly, because nothing about it is defective.

---

## 1. The write shape, and why two of them

**51 of the 82 rows served from the CLOSED Season 1 with nothing shadowing them.** Season 1 is
immutable (ADR 0005 §1.6), so the only lever is to **INSERT a Season 2 row**, which shadows the
Season 1 one on read (`getPoliticianAnswers` collapses `DISTINCT ON (topic_id) … ORDER BY s.number
DESC` and then drops `value = 0`).

🔴 **And by ADR 0006 the inserted row is read against the SEASON 2 ladder** — `servedRevisionLateral`
resolves a pin to the latest published revision *of that pin's version*, so a Season 1 answer keeps
Season 1's text and the Season 2 row written to correct it serves Season 2's. **Both ladders must be
read before the number is chosen.** That is not a formality here: on two of these three topics the
seasons ask materially different questions.

| topic | Season 1 revision | Season 2 revision | same question? |
|---|---|---|---|
| climate-change | v1r1 `da9cf777` (ranks AMBITION) | v2r3 `5f1403f3` (ranks INSTRUMENT) | **no** |
| school-vouchers | v1r1 `835bc8d1` | v2r3 `88858826` | chairs 1–3 differ, 4–5 the same |
| same-sex-marriage | v1r1 `5d26a058` | v2r2 `8bc3d240` | chairs 4 and 5 identical |

The 11 same-sex-marriage rows already had a Season 2 row, so those are **UPDATEs in place** —
migration 1925's shape, on the other side of the same Act.

🔴🔴 **BOTH non-identical ladders carry a `rung_map` that claims IDENTITY.** climate-change v2r3 is
`{1:1,2:2,3:3,4:4,5:5}` over a ladder rewritten from ambition to instrument; school-vouchers v2r3 is
the same map over chairs 1–3 that were rewritten (S1 chair 2 "prioritising public school funding
while restricting vouchers to low-income families" became S2 chair 2 "opposing voucher programs and
blocking their expansion, without moving to eliminate existing ones" — a different position). **A
`rung_map` can lie. Compare the rung TEXTS.** Migration 1943 asserts the text of every chair it
reasons from, on both sides of the season boundary, and refuses to write if any of it has moved.

---

## 2. A — Climate Solutions Now Act → climate-change, FOR, 33 rows

Thirty-three Maryland legislators, one vote, three chairs: **22 at chair 1, 10 at chair 2, 1 at
chair 3.**

Season 1 ladder (ambition):

```
1 declare a climate emergency and ban all activities that increase carbon emissions
2 rapidly transition to renewable energy and phase out fossil fuels by 2030
3 invest in clean energy while gradually reducing reliance on fossil fuels
4 let market forces drive any transition to cleaner energy sources
5 reject climate change policies and focus on economic growth instead
```

**The enacted chapter was read, not the title** — Chapter 38 of the 2022 Laws of Maryland (Senate
Bill 528), fetched from `mgaleg.maryland.gov/2022RS/Chapters_noln/CH_38_sb0528e.pdf`:

- Environment §2‑1204.1 as amended: *"The State shall reduce statewide greenhouse gas emissions by
  [40%] **60%** from 2006 levels by [2030] **2031**."*
- new §2‑1204.2: *"THE STATE SHALL ACHIEVE NET‑ZERO STATEWIDE GREENHOUSE GAS EMISSIONS BY 2045."*
- new §2‑1602(a): building energy performance standards reaching *"NET ZERO DIRECT GREENHOUSE GAS
  EMISSIONS ON OR BEFORE JANUARY 1, 2040"*.

**No emergency is declared, nothing is banned, and no fossil fuel is phased out by 2030.** Chairs 1
and 2 are both false of a member whose evidence is this vote — and 22 people were showing voters the
ban.

### ⚖ Why chair 1 on the Season 2 ladder, and not a blank

Season 2 asks which instrument, not how much ambition:

```
1 Require a shift to clean energy through mandates and firm deadlines.
2 Fund clean energy with major subsidies, tax credits, and public investment.
3 Speed up clean energy by cutting permitting red tape and upgrading the grid.
```

The live alternative was to withdraw all 33 on migration 1925's rule — *a vote on a package holding
two chairs' content proves the side and not the rung.* **It was rejected because this Act does not
hold both limbs:**

- **chair 2 fails on the Act's own text.** The Climate Catalytic Capital Fund exists to *"leverage
  increased private capital investment"* (Econ. Dev. §10‑855(b)); the one recurring appropriation in
  the chapter is **$500,000 a year** for the Healthy Soils Program (Agric. §2‑1901(e)); and the Act
  creates no significant tax credit. Its money is incidental, not its instrument.
- **chair 3 fails**: the Act adds an Electric Distribution System *Planning* subtitle (Pub. Util.
  §§7‑801–804) and reforms no permitting.
- chairs 4 and 5 are the opposite of what it does.

One limb matches the statute's spine and the others fail on the statute's own text — the same test
that seated the For the People Act at redistricting chair 2 in migration 1942.

⚠ **The one row at Season 1 chair 3 is written too.** Chair 3 is right about Cheryl Kagan on the
ambition ladder and her Season 1 answer is untouched. But the live question is the instrument
question, 33 people hold identical evidence, and on that question they are one answer. Leaving her
out would publish two positions from one vote — the defect this check exists to find.

▶ **NOT FIXED, AND BIGGER THAN THIS FILE.** ~1,100 Season 1 climate answers sit behind that identity
`rung_map` and serve Season 1 ladder text. Whether v2r3 should have reused the numbering at all is a
ladder-governance decision, not a stance repair.

---

## 3. B — Tax Cuts and Jobs Act → taxes, FOR, 33 rows — **withdrawn, nothing written**

🔴🔴 **The second time `--sole` has promised more than it can deliver.** It compares rows resting on
one *keyed* instrument, and `extractInstrumentKeys` is lexical: it cannot see the **Taxpayer
Protection Pledge**, the **FairTax**, a **flat tax**, a **Club for Growth** or **Citizens for Tax
Justice** rating, or an **estate-tax repeal vote**.

Reading all 33, the 27/6 split is not a contradiction — it tracks exactly that unkeyed evidence:

- **all six** rows at chair 5 ("Drastically cut taxes and shrink government") carry a FairTax,
  national-sales-tax, abolish-the-IRS or flat-rate commitment in the member's own record —
  Schweikert, Wilson, Loudermilk, Higgins, Estes, Labrador.
- the chair-4 rows stop at rate cuts and pledges, and several say so in terms: *"without going as
  far as a flat tax"*, *"stops short of a drastic flat-tax restructuring"*.

A rung reflects the **sum** of a row's evidence, so two rows are comparable only when the sum is the
same. It is not, both readings can be right, and the group is not one unit of defect.

⚠ Separately and **not acted on**: nearly every row here cites only ontheissues.org and Wikipedia.
That is a sourcing-quality question for the coverage work, not a contradiction.

---

## 4. C — Blueprint for Maryland's Future → school-vouchers, FOR, 20 rows

🔑 **An off-axis instrument is wrong at every rung** — migration 1942's ruling on Texas HB 229,
reached again from the other direction.

The Blueprint (House Bill 1300 of 2020, House Bill 1372 of 2021) is a **public school funding and
policy** statute. HB 1300's synopsis: *"Repealing, altering, and adding certain provisions of law to
implement The Blueprint for Maryland's Future, which is intended to transform Maryland's education
system to the levels of high-performing systems around the world…"*. **Neither bill page contains
the word *voucher*, or *BOOST*, at all** (measured: 0 occurrences on each).

So it cannot seat a voucher rung. Season 1 chair 1 asserts *"eliminating voucher programs"* and
chair 2 asserts *"restricting vouchers to low-income families"*; supporting a school-funding law
establishes neither. The secondary claim that the member *"voted against school voucher
legislation"* names no bill and cites none.

**All 20 withdrawn.** ⚠ 15 of them were showing voters a demand to eliminate vouchers. Every
citation is kept, so any of them can be seated the day a voucher instrument is named.

---

## 5. D — Respect for Marriage Act, **AGAINST** side → same-sex-marriage, 20 rows

Migration 1925 blanked 53 rows on the FOR side, on the rule that the Act carries both chairs'
content so a vote for it proves the side and not the rung. **The against side is not the mirror
image and was not treated as one** — most of these rows carry something beyond the vote.

The test, applied row by row: **does a member-specific record beyond the vote describe the chair?**

- chair 4 — *"Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex
  couples."*
- chair 5 — *"Make same-sex marriage illegal and define marriage as only between one man and one
  woman."*

**KEPT at chair 5 — nine rows**, each with its own record:

| member | the record beyond the vote |
|---|---|
| Andy Harris | co-sponsored the Federal Marriage Amendment (2013, 2015) and a resolution disagreeing with *Obergefell* |
| James Lankford | supported Oklahoma's 2004 constitutional ban; endorsed DOMA |
| Mike Lee | condemned *Obergefell*; "I do not support gay marriage" (Jul 2010) |
| Jim Banks, David Kustoff, Ted Budd, Lauren Boebert, Kevin Hern, Clay Higgins | the member's own definition of marriage, on the record |

**WITHDRAWN — eleven rows.** Eight at chair 5 whose only marriage evidence is the vote plus a
paraphrase or an adjacent claim: *"business liberty over gay marriage"* (Mann), a 2012 objection to
a commitment ceremony (Hyde-Smith), a survey answer about not discriminating against people who
*hold a belief* (Carl), *"faith-based opposition be respected"* (Thompson), bare "opposes gay
marriage" (Bergman, Smucker), *"sexual preference is not a protected right"* (Balderson) — and one
row reasoning from **absence**: *"has not made public statements supporting same-sex marriage
recognition"* (Kennedy).

**And all three at chair 4.** 🔑 **Not one row in the group cites support for civil unions**, which
is chair 4's entire content. Two of the three read as leaving marriage to the states (Tuberville,
Braun) — **and that is Season 1 chair 3, which Season 2 INVALIDATED rather than renumbered**
(`rung_map {1:2, 2:3, 3:invalidated, 4:4, 5:5}`), so the position they actually hold has no chair on
the live ladder. The third (Grassley) carries votes for a constitutional ban — chair 5 evidence —
against a 2022 statement of personal support: conflicting records on one row, so it declines rather
than guesses, and chair 4 was never earned either way.

---

## 6. E — Opting in on Opportunity Act → school-vouchers, SPONSOR, 19 rows

Nineteen co-sponsors of one bill, with word-for-word identical evidence, split down the middle: the
ten whose summary says *"tax-credit-funded private school scholarships"* sit at chair 4, the nine
whose summary says *"private school choice programs"* sit at chair 5. **The summary chose the chair,
not the member** — migration 1925's finding, reproduced exactly.

The bill was read: **Maryland House Bill 455 of 2026**, adding Education §7‑137.

- §7‑137(B): intent that it be construed *"IN A MANNER THAT IS CONSISTENT WITH, AND ENABLES THE
  STATE TO PARTICIPATE IN, THE FEDERAL TAX CREDIT SCHOLARSHIP PROGRAM ESTABLISHED UNDER § 25F OF THE
  INTERNAL REVENUE CODE."*
- §7‑137(C)(1)(II): certifies an organisation that provides scholarships to *"ELIGIBLE STUDENTS, AS
  DEFINED IN § 25F OF THE INTERNAL REVENUE CODE"*.
- It creates **no State voucher**, appropriates nothing, and sets **no eligibility of its own**.

26 U.S.C. §25F(c)(2) defines an eligible student as one in *"a household with an income which … is
not greater than 300 percent of the area median gross income"* who is eligible to enrol in a public
school; §25F(c)(5)(F)(i) makes the organisation verify household income and family size.

So the programme this bill opts Maryland into is **income-capped**, which is Season 2 chair 3 —
*"Allowing income-based voucher programs, open to a wider range of families under an income cap"*.
Chair 4 expands eligibility past a cap and chair 5 is universal; this bill is neither.
**All 18 re-seated to chair 3.**

⚠ **One row left alone.** Jim Hinebaugh, Jr.'s row names a **second instrument** — a bill
establishing an Education Savings Account Program — which the lexical keyer never saw and which no
citation on the row establishes. Moving him would carry an unverified claim to a new chair, so his
row is pinned where it is and owed a one-row read. Same call as Ghrist in migration 1942.

---

## 7. Gates

| gate | when | result |
|---|---|---|
| `audit-chair-evidence.mjs --csv` | before the write, over the 51 seated rows | **OK — all 51 name an instrument, act or vote** |
| migration 1943 guards 1–6 | in-transaction | all passed; dry run rolled back first |
| `audit-chair-evidence.mjs --check` (with `season_id`) | after | **OK — all 51** |
| `check-stance-sources.mjs` | both sides | **789 / 4 checks, byte-identical before and after** |
| contradiction check `--sole` | after | 142 groups / 945 rows → **138 / 853** |

🔴 **The `--csv` gate filters on a column literally named `value`, and reports `full_name` /
`topic_key`.** A file keyed `chair_after` — which is what `--check` wants — scores **zero** rows and
prints `OK: all 0 valued row(s)`, the vacuous pass its own header warns about. That happened on the
first run here and was caught by reading the count, not the exit code. Both shapes are now generated
from one list.

🔑 **The stance-sources impact was predicted before the write** by running the gate's own predicates
locally over the 82 affected rows: 51 entering the universe (`value <> 0`), 20 inserted blanks, 11
leaving it — **all clean**, no `ORPHAN_CONTEXT` risk because a blank still has an answer row in its
own season. The prediction held exactly, so **no baseline commit is owed**.

---

## 8. Open, logged, not acted on

1. **The climate-change `rung_map`.** v2r3 claims identity over a ladder rewritten from ambition to
   instrument; ~1,100 Season 1 answers sit behind it. Ladder governance, not a stance repair.
2. **The school-vouchers `rung_map`.** Same shape, smaller: v2r3 claims identity although chairs 1–3
   were rewritten. Found while reading this pass.
3. **Jim Hinebaugh, Jr. / school-vouchers** — owes a one-row read for the Education Savings Account
   bill his row names and does not cite.
4. **The Tax Cuts and Jobs Act group (33 rows)** stays in the queue and should be *removed from it*
   by keying, not by adjudication: the Taxpayer Protection Pledge, the FairTax and scorecard ratings
   are invisible to `extractInstrumentKeys`.
5. **ontheissues.org / Wikipedia-only sourcing** across the whole TCJA and RFMA-against cohort.
6. **The 20 blanked Blueprint rows** leave 20 Maryland legislators with no `school-vouchers` row to
   host voucher evidence when it is found.
