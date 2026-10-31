# Contradiction check, round three — migration 1944

144 rows read across four groups. **37 written: 8 seated, 29 withdrawn. 108 left alone.**
Queue `--sole` **138 groups / 853 rows → 136 / 845**; full queue **345 / 2,556 → 341 / 2,437**.

| rows | instrument | ladder | decision | written |
|---:|---|---|---|---:|
| 53 | Inflation Reduction Act | climate-change | **not a mapping** — fix the 4 chair-1 rows | 4 |
| +1 | *(the same chair, never reported)* | climate-change | found by a guard, not by the check | 1 |
| 55 | Texas HB 3 (89R) | school-vouchers | re-seat the lone dissenter | 1 |
| 7 | Texas HB 4 (89R) | school-vouchers | **off-axis grouping** — fix 2 rows | 2 |
| 29 | Texas SB 10 / SB 11 (89R) | religious-freedom | withdraw 28, re-seat 1 | 29 |

Every target served from the **closed Season 1**, so every write is an insert of a Season 2 row.
Season 1 was not touched: no value, no reasoning, no `updated_at` moved, and the migration's
post-flight block proves it row by row.

---

## 1. What this pass learned about the check itself

Two of the four groups needed almost no write, for two different reasons — and a third problem
surfaced that is worse than either.

### 1.1 A group is not a mapping just because it shares a citation

Measured across the whole queue by the share of rows carrying a **byte-identical source set**:

```
   n  modal  dist  share  rungs   level                        instrument / topic / dir
   5      5     1   100%  3/4     Texas House                  TX:HB0014 / fossil-fuels
  16     10     6    63%  1/2/3   California Senate+Assembly   CA:SJR0007 / tariffs
  26     11    12    42%  4/5     Texas Senate+House           TX:SB0010 / religious-freedom
  ...
  53      1    53     2%  1/2/3   U.S. House + Senate          ACT:inflation reduction act
```

Every mapping-shaped group is a **state legislature cohort voting on one bill**. The large federal
`ACT:` groups are rows researched one at a time that happen to cite the same statute. Round two's
wins were all the former; the Tax Cuts and Jobs Act group it withdrew was the latter, and so is the
Inflation Reduction Act group here.

### 1.2 The shared instrument can be off-axis for the ladder it groups

All seven rows of the Texas HB 4 group cite HB 4 (89R), the public education **accountability**
act, which carries no voucher content. Their voucher positions come from elsewhere — SB 2, HB 3, a
campaign site — so the 1-versus-5 spread the check reports is produced by a citation that says
nothing about the question.

### 1.3 🔴🔴 The check silently drops rows whose side it cannot score

A row is grouped only if `directionFor` can tell which side of the instrument it took; a `null`
drops the row before any comparison. That is sound in principle — an ambiguous side cannot create a
contradiction — but it is **correlated with the defect**.

Guard 6 of migration 1944 asserts that *every* Season 1 climate row naming the Inflation Reduction
Act and still sitting on chair 1 is a target. Its first run failed: there were **five**, and the
check had reported **four**. The fifth, Pete Aguilar, reads:

> "His position aligns with **stance 2** (rapid renewable transition, phase out fossil fuels by
> 2030) **rather than stance 1 (declaring a climate emergency and banning all carbon-increasing
> activities)**."

and was stored at **value 1** — the one stance its own sentence rules out. `directionFor` scored
`null` on "voted for the Inflation Reduction Act" inside that sentence, so the row was never
compared with anything.

⚖ **1.1 and 1.2 are reasons to distrust a flag. 1.3 is a reason to distrust a clean run.** It is
why this file's guards count populations instead of merely verifying the targets they were handed.

---

## 2. Inflation Reduction Act → climate-change, FOR — 53 rows, 5 written

All 53 serve from Season 1, whose climate ladder ranks **ambition**:

```
1 declare a climate emergency and ban all activities that increase carbon emissions
2 rapidly transition to renewable energy and phase out fossil fuels by 2030
3 invest in clean energy while gradually reducing reliance on fossil fuels
```

**The chair 2 / chair 3 split is the ladder working, not a defect.** It tracks member-specific
records faithfully:

| chair 3 | chair 2 |
|---|---|
| Dingell — *"represents the auto-manufacturing Dearborn area and has been cautious about full fossil fuel phase-outs"* | Takano — Green New Deal co-sponsor, *"'50% clean and carbon free electricity by 2030'"* |
| Houlahan — *"Problem Solvers Caucus… not mandating a complete fossil fuel phase-out by 2030"* | Lofgren — Green New Deal co-sponsor, same 2030 target |
| Brownley — *"does NOT support the Green New Deal… 100% renewable by 2050 (not 2030)"* | Quigley — *"endorses 50% clean electricity by 2030"* |
| Sherrill — *"'all-of-the-above clean energy investments'"* | Sherman — co-sponsored a resolution *declaring* a climate emergency |

**What is defective is chair 1.** Five rows claim *"declare a climate emergency and ban all
activities that increase carbon emissions"* and not one cites an emergency declaration or a ban on
anything: an Attorney General who *"supported the Inflation Reduction Act and other climate
legislation"*; two members resting on an IRA vote plus Green New Deal sympathy; a Senator whose
strongest cited state record is *"25% renewable by 2025"*; and Aguilar, whose own text rejects the
chair he was stored at.

### The remedy lands on a different question

Season 1 is closed (ADR 0005 §1.6), so the lever is a Season 2 insert — and by ADR 0006 that row is
read against the **Season 2** ladder, which ranks **instruments**:

```
1 Require a shift to clean energy through mandates and firm deadlines.
2 Fund clean energy with major subsidies, tax credits, and public investment.
3 Speed up clean energy by cutting permitting red tape and upgrading the grid.
```

Every one of the five cites support for the Inflation Reduction Act, which funds clean energy
through tax credits, grants and loans and imposes no economy-wide mandate and no deadline to shift.
That is chair 2, named by each row's own evidence. **No cited evidence in any of the five describes
a mandate or a firm deadline**, so chair 1 on the new ladder is not available to them either.

⚖ **Why only these five and not the group.** The other 48 sit at Season 1 chairs 2 and 3 on records
that support them. They are not one vote producing two answers; they are 48 different records. The
rule applied here is narrower than migration 1943's: **fix the rows whose serving text is false of
the member, leave the rows whose serving text is defensible.**

---

## 3. Texas HB 3 (89R) → school-vouchers, SPONSOR — 55 rows, 1 written

54 co-authors at chair 5, one at chair 4. **The bill was read, not the title** —
`capitol.texas.gov/tlodocs/89R/billtext/html/HB00003I.htm`:

- **§29.355(a)** — *"A child is eligible to participate in the program"* if the child may attend a
  public school under §25.001 or enrol in prekindergarten under §29.153.
- **§29.356(b)** — when applications exceed funding the comptroller fills places *"by lottery"*
  through income tiers, the lowest being households *"at or above 500 percent of the federal
  poverty guidelines"*. The tiers order a queue; they gate nothing.
- **§29.361(b)** — up to *"$30,000"* a school year for a child with a disability.

Universal eligibility with the money following the child to a private or religious school is
chair 5 verbatim. Chair 4 — *"most families"* — fails on the bill's own text, because nobody is
left out.

### 🔑 The reason the dissenting row looked right has been deleted from the ladder

John Lujan's row rests on co-authoring **HB 2**, the public school finance companion — and Season 1
chair 4 ended with a clause Season 2 dropped:

```
S1 c4  Expanding voucher eligibility to most families ... WHILE MAINTAINING BASELINE PUBLIC
       SCHOOL FUNDING
S2 c4  Expanding voucher eligibility to most families so parents can choose the school that
       best fits their child
```

The limb he satisfied no longer exists. **Eight rows in the group cite both HB 3 and HB 2, and the
other seven sit at chair 5.** His remaining distinguishing content is a remark about the politics of
his district, which is not a position.

The migration asserts the deletion directly: if `baseline public school funding` ever returns to
Season 2 chair 4, the guard fails and this decision must be re-argued.

---

## 4. Texas HB 4 (89R) → school-vouchers, SPONSOR — 7 rows, 2 written

The grouping is off-axis (§1.2), but two rows are wrong on their own terms.

**Withdrawn — Sergio Munoz**, chair 1 (*"Eliminating voucher programs that divert taxpayer money
from public schools to private institutions"*). The row rests on three things: that he did **not**
co-author HB 3, that he **did** co-author HB 4, and that *"as a Rio Grande Valley Democrat,
opposition to public school defunding via vouchers is consistent with his district's reliance on
public schools."* An absence of sponsorship, an off-axis bill and an inference from district
demographics are not a position, and chair 1 is an affirmative claim.

**Re-seated — Jolanda Jones**, chair 1 → chair 2. Her campaign site (fetched 2026-10-26) commits to
exactly one thing on this subject: *"Opposing the use of public money for private school
vouchers."* That is opposition, not elimination.

```
S1 c2  Prioritizing public school funding while restricting vouchers to low-income families
S2 c2  Opposing voucher programs and blocking their expansion, without moving to eliminate
       existing ones
```

On the Season 1 ladder chair 1 was the **nearest available seat**, because chair 2 meant
means-tested vouchers. Her original answer was not careless; the Season 2 rewrite finally created
the chair that holds her position.

---

## 5. Texas SB 10 / SB 11 (89R) → religious-freedom, SPONSOR — 29 people, 29 written

Two overlapping groups (26 and 23 rows, 29 distinct people), split 4/5. Chairs 2–5 are **identical**
in both seasons, so this is the same question it always was:

```
c4  protect religious freedom and allow faith-based exemptions from laws that conflict with
    sincere religious beliefs.
c5  strongly protect religious freedom and allow religious organizations complete autonomy in
    their operations and hiring practices.
```

SB 10 requires the Ten Commandments displayed in every public school classroom; SB 11 requires a
period of prayer and Bible reading in public schools. Both put religious content **into** a public
institution. This ladder asks the opposite question — whether religious belief may be excused
**from** generally applicable law, and how far a religious organisation's internal autonomy runs.

**The rows say it themselves.** The leap is always in the second clause, and the second clause is
what picked the chair:

> *"co-authored SB 10 … and SB 11 … This pattern strongly supports protecting religious freedom
> **including complete autonomy for religious organizations**."*

> *"mandatory Bible/religious text displays in public schools indicates strong support for religious
> expression in public institutions **and faith-based exemptions**."*

By the standing rule, the sponsorship proves the **side** and not the **rung**, and an off-axis
instrument is wrong at every rung. 28 rows withdrawn.

### ⚖ One row kept and moved, not blanked

**Bob Hall.** His Senate biography — a source this row already cites, fetched 2026-10-26 — says he
was *"instrumental in … protecting religious organizations and churches from Government shutdown."*
Excusing churches from a generally applicable closure order **is** a faith-based exemption from a
law: chair 4, on the record, in his own words. The same page says nothing about operations or
hiring, which is what chair 5 claims. So chair 5 is withdrawn from him and chair 4 written in its
place.

### ⚠ Two near misses, recorded because they are the same trap

- **Donna Campbell's** row claims she is *"Author of legislation preventing government oversight of
  religious organizations"* — which would be chair 5 squarely. **That clause is unsourced**: the
  row's only citations are the SB 10 and SB 11 bill pages. Blanked with the rest. The distinction
  between her row and Hall's is entirely whether the on-axis claim carries a citation.
- **Phil King chairs**, and **Angela Paxton vice-chairs**, the Senate Religious Liberty Select
  Committee. A committee assignment is not a position and does not say where on this axis they sit.

---

## 6. 🔴 A new defect class, measured but not fixed: the value that contradicts its own reasoning

Aguilar's row prompted a corpus-wide measurement. Of **3,387** valued rows whose reasoning names its
own chair in so many words (*"aligns with stance N"*, *"matching stance N"*, …), **199 are stored at
a different number.**

That headline is misleading on its own, and the breakdown is the finding:

| | mismatches | off by exactly +1 | topics |
|---|---:|---:|---:|
| **Season 2** | 191 | **190** | 3 |
| **Season 1** | 8 | 6 | 6 |

**The 191 Season 2 rows are explained and are not wrong positions.** They concentrate on `housing`
and `same-sex-marriage` — the ladders renumbered between seasons — and are almost perfectly off by
one in a single direction. The *value* was remapped correctly; the *prose* still names the
pre-remap chair. The voter sees a correct position above a sentence citing the old number. That is a
provenance and readability defect, not a false position, and it must not be "fixed" by moving any
value.

**The 8 Season 1 rows have no such excuse**, because Season 1 was never remapped. They are the
Aguilar shape and they span six different topics. That is the worklist.

▶ **Owed:** read those 8 rows. The query that produces them is in this file's §6 and the regex is
deliberately narrow — it only matches a row *asserting* its own chair, never a contrastive mention.

---

## 7. Gates

| gate | before | after |
|---|---|---|
| `audit-chair-evidence --csv` (pre-write, 8 seated rows) | **OK: all 8** | — |
| `audit-chair-evidence --check` (post-write) | — | **OK: all 8** |
| `check-stance-sources` | 789 across 4 checks | **789 across 4 checks — identical** |

The sourcing outcome was **predicted before the write** by running the gate's own predicates over
the 8 rows entering its universe: all 8 clean, nothing leaving (the 29 blanks never enter a universe
defined by `value <> 0`, and Season 1 is untouched). No baseline commit is owed.

⚠ **The two modes take different inputs and this costs a run every time.** `--csv` filters on a
column literally named `value` and reports `full_name` / `topic_key`; `--check` reads a **JSON**
file of `{season_id, rows:[{politician_id, topic_id, chair_after}]}`. Feeding the CSV to `--check`
dies in `JSON.parse`. Feeding a CSV keyed `chair_after` to `--csv` scores zero rows and prints a
cheerful `OK: all 0`.

Verified deltas, pre-state queried before committing:

| topic | value | before → after | Δ |
|---|---|---|---|
| climate-change | 2 | 6 → 11 | +5 |
| religious-freedom | 0 | 29 → 57 | +28 |
| religious-freedom | 4 | 8 → 9 | +1 |
| school-vouchers | 0 | 98 → 99 | +1 |
| school-vouchers | 2 | 4 → 5 | +1 |
| school-vouchers | 5 | 0 → 1 | +1 |

Live serving confirmed after the commit: Kaine and Aguilar now read *"Fund clean energy with major
subsidies, tax credits, and public investment."*; Lujan *"Providing universal vouchers…"*; Jones
*"Opposing voucher programs and blocking their expansion, without moving to eliminate existing
ones"*; Hall *"…faith-based exemptions from laws…"*; Middleton blank on religious-freedom with his
climate and voucher rows untouched at Season 1.

---

## 8. Open items

1. ▶ **The 8 Season 1 rows whose value contradicts their own reasoning** (§6). Measured, scoped,
   unread.
2. ▶ **The 191 Season 2 rows citing a pre-remap chair number** (§6). Not a wrong position; a
   rewrite of stale prose, and it must not move a value.
3. ▶ **28 Texas legislators now have no religious-freedom row**, and 1 more has no voucher row. A
   coverage debt, the same one migration 1943 left for 20 Maryland legislators on school-vouchers.
4. ▶ **The climate-change and school-vouchers `rung_map`s still lie.** ~1,100 Season 1 climate
   answers sit behind an identity map over a ladder rewritten from ambition to instrument. Ladder
   governance, untouched by this file and bigger than it.
5. ▶ **`--sole` is not what its name promises, for the third time.** It means one *keyed*
   instrument. In 1942 it hid the Green New Deal; in 1943 it made a group look defective that was
   not; here Green New Deal co-sponsorships and LCV lifetime scores are invisible to it throughout
   the Inflation Reduction Act group.
6. ▶ **Groups keyed on an off-axis instrument should be removable from the queue by keying rather
   than by adjudication** — Texas HB 4 here, the Tax Cuts and Jobs Act in round two.
