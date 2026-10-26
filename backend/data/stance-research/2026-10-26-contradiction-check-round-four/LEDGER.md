# Contradiction check, round four — migration 1945

79 rows read across five instruments. **76 written: 12 seated, 64 withdrawn.** 1 row left alone,
2 were already blanked by an earlier pass.
Queue `--sole` **136 groups / 845 rows → 132 / 807**; full queue **341 / 2,437 → 337 / 2,386**.

| rows | instrument | ladder | decision | written |
|---:|---|---|---|---:|
| 5 | Texas HB 14 (89R) | fossil-fuels | withdraw all 5 | 5 |
| 30 | California SJR 7 (2025-26) | tariffs | withdraw 28; 2 already blank | 28 |
| 15 | California SB 314 (2023-24) | redistricting | **re-seat 12 to chair 1**, withdraw 2 | 14 |
| 14 | California SB 57 (2025-26) | data-centers | withdraw all 14 | 14 |
| 15 | California "SB 42" | campaign-finance | withdraw all 15 | 15 |

Every target served from the **closed Season 1**, so every write is an insert of a Season 2 row.
Season 1 is untouched and the post-flight block proves it row by row.

---

## 1. This pass was chosen by a score, not by group size

Round three established that a queue group is only a **mapping** — one piece of evidence applied to
many members — when its rows share the *same* evidence, and that the cheap test is the share of
rows whose source set is byte-identical. Scoring the queue that way puts a different five at the
top than group size does:

```
   n  modal  share  rungs    chamber                     instrument / topic / dir
   5      5   100%  3/4      Texas House                 TX:HB0014 / fossil-fuels
  16     10    63%  1/2/3    California Senate           CA:SJR0007 / tariffs
  13      7    54%  1/2      California Senate           CA:SB0314 / redistricting
  11      6    55%  3/4      California Senate           CA:SB0057 / data-centers
   9      6    67%  2/3      California Assembly         CA:SB0042 / campaign-finance
```

It worked: **76 of the 79 rows read were written**, against 37 of 144 in round three.

### 🔑 And the unit read is the INSTRUMENT, not the check's group

Round three's other lesson was to count **populations**. Applying it here found **25 further rows**
citing these same five instruments that the check never grouped — most because they take the
AGAINST side, which the check rightly separates. They carry the same defects and some worse ones,
so they are adjudicated here too. What this file settles is every row that cites one of these five
instruments on these five ladders.

---

## 2. Texas HB 14 (89R) → fossil-fuels — 5 rows, all withdrawn

The most mapping-shaped group in the queue: five rows, one citation, byte-identical. The bill was
read, not the title. The Texas Legislature's bill page for HB 14 of the 89th Regular Session gives
the caption **"Relating to support for the development of the nuclear energy industry"** and the
subject **"Energy--Nuclear"**.

**Nuclear power is not a fossil fuel**, and every chair on this ladder is about fossil fuel drilling
and extraction permits. An off-axis instrument is wrong at every rung, so the 3/4 split is not
resolved by picking one.

### ⚠ What filled the gap is worse than the misfile

Take the nuclear bill out and what is left in these rows is party and geography:

> *"Democrats rarely advocate for new fossil fuel drilling bans in Texas but also don't push for
> expanding permits."*
> *"As a rural Republican representing Bastrop/Caldwell counties — an oil-and-gas-adjacent region…"*
> *"As a West Texas banker representing Abilene-area counties with strong energy sector ties…"*

And one row states the method outright:

> *"**Insufficient direct fossil fuel drilling bill evidence — scoring 4 based on Republican
> baseline** and HB14 energy-expansion signal."*

That is a party prior written into a voter-facing position.

---

## 3. California SJR 7 (2025-26) → tariffs — 30 rows, 28 withdrawn

One revision serves both seasons, so this ladder is the live one:

```
1 eliminate all tariffs and pursue completely free trade with every country.
2 reduce most tariffs while keeping some on products that harm the environment.
3 use tariffs selectively to protect key American industries and jobs.
4 increase tariffs on countries that don't trade fairly with America.
```

The resolution was read in full. Its operative text is three RESOLVED clauses:

> *"…the Legislature urges President Donald J. Trump to avoid raising the cost of living for
> American consumers by **rescinding the tariffs that he has imposed since taking office in January
> 2025**, and refunding the American people for the costs passed on to them by his tariffs"*
> *"…urges the United States Congress to enact a joint resolution to rescind President Trump's
> tariffs and to oppose all future **unilateral and arbitrary** tariff increases"*

So it opposes **one administration's tariffs**, argued from Congress's exclusive power to *"regulate
Commerce with foreign Nations."* It does not call for eliminating all tariffs, mentions no
environmental carve-out, and endorses no selective-tariff policy. **Chairs 1, 2 and 3 all fail on
its own text.** The free-trade material — Eisenhower, Reagan, the *"bipartisan consensus … supporting
free trade"* — is confined to WHEREAS clauses, and a findings clause is not an operative provision.

### 🔑 Each row described the same resolution to fit its chair

| chair | how the row describes SJR 7 |
|---|---|
| 1 | *"call for eliminating tariffs and pursuing stable free trade"* |
| 2 | *"while **potentially** keeping targeted protections"* |
| 2 | *"while **potentially** supporting targeted ones for environmental or fair-trade purposes"* |
| 3 | *"calling for **selective rather than blanket** tariff application"* |
| 3 | *"while **leaving room for** targeted measures to protect American workers"* |

The hedges give the method away. The vote proves the **side** and not the **rung**, and this ladder
has no chair for the side alone, so the honest write is a blank rather than a pick.

**A no vote proves less still.** Five rows sit at chair 4 — *"increase tariffs on countries that
don't trade fairly"* — on a vote against the resolution, reasoned as *"consistent with Republican
protectionist trade policy"*. Voting against a rebuke of one president's tariffs establishes no
affirmative tariff policy.

**And some rows rest on no vote at all.** Two cite NVR — no vote recorded — one of them saying so
and seating a chair anyway. Both of those were already blanked by an earlier audit pass, which had
reached the same conclusion independently: *"the chair rested on an absence of evidence rather than
on evidence of a position."* They are excluded here and the migration's guard exempts them
explicitly.

---

## 4. California SB 314 (2023-24) → redistricting — 15 rows, 12 re-seated, 2 withdrawn

🔑 **The one group where the lone dissenter was right and the other twelve were wrong.**

```
1 independent citizens' commissions with no elected officials involved at any level.
2 independent redistricting commissions with equal representation from both major parties.
```

SB 314 establishes the Citizens Redistricting Commission in the County of Sacramento, 14 members
and 2 non-voting alternates. New Elections Code §21595: *"A commission member shall be ineligible
for a period of five years beginning from the date of appointment to hold elective public office at
the federal, state, county, or city level in this state."* Eight commissioners are drawn from
applicant subpools and those eight then *"appoint six additional applicants"*. **No elected official
is involved at any stage — chair 1.**

Chair 2 fails because the Act says the opposite of "equal representation from both major parties":

> *"The political party preferences of the commission members … shall be **as proportional as
> possible** to the total number of voters who are registered with each political party in the
> County of Sacramento, **or who decline to state** or do not indicate a party preference."*

⚖ **And it is a real vote, not a local courtesy.** Contested at every stage: Senate 31-7 and 32-7,
Assembly 62-18, no committee vote unanimous after March. An aye endorses the model.

**The two no-vote rows are withdrawn.** A no vote proves opposition to this commission; it does not
establish an affirmative preference for legislative control with court oversight (chair 4) or for
party-controlled redistricting (chair 5). What carried those chairs instead was a party prior —
*"aligns with the Republican preference for party-controlled redistricting"* — resting on a
description of the Act, *"equal party representation"*, that the Act contradicts.

---

## 5. California SB 57 (2025-26) → data-centers — 14 rows, all withdrawn

*"Electrical corporations: data centers: report."* The Act authorises the Public Utilities
Commission to assess whether costs from new data centre loads *"result in cost shifts to other
electrical corporation customers"*, and requires that assessment to reach the Legislature and be
posted publicly on or before 1 January 2027. That is the whole Act.

| chair | why it fails |
|---|---|
| 1 moratorium | the Act imposes none |
| 2 bar cost pass-through | the Act bars none; it *measures* the shift |
| 3 assessments and community benefits **before approval** | the Act has no approval step at all |
| 4 **streamlined permitting** with transparency | the Act contains no permitting provision |

Ten rows chose 3 and one chose 4, each quoting the half of the chair the Act resembles and passing
over the half it does not. The other instruments in these rows — a regional energy market bill, an
AI transparency act, a greenhouse gas fund — are off this ladder too, and one row's remaining
support is a committee membership.

**Two no-vote rows describe a different bill entirely**, reporting that SB 57 *"would have required
data centers to fund their own power generation and barred utilities from passing data center
infrastructure costs to residential customers"* and that it required assessments *"before
approval"*. That is chair 2 and chair 3 text, not the Act.

---

## 6. 🔴🔴 California "SB 42" → campaign-finance — 15 rows, all withdrawn

**One lexical key merged two different bills of the same legislature.** The check scopes a numeric
bill by its legislature host but not by its **session**, and this cohort contains both.

### The 2025-26 SB 42 is real, and has no chair

*"Political Reform Act of 1974: public campaign financing: California Fair Elections Act of 2026."*
It removes the existing prohibition on a candidate accepting public funds, requires candidates who
take them to abide by expenditure limits and qualifying criteria, bars public funds from paying
legal fees or repaying personal loans, and raises the penalty for foreign-government contributions.

It is a **voluntary public financing scheme**. It does not strictly limit corporate donations or
dark money (chair 2) and it does not ban private money (chair 1).

⚖ **And this ladder has no chair for public financing, by design.** Topic revision v2r2's own note:

> *"Reworded the first option to state one position — banning private money — instead of also
> requiring support for public campaign financing, **which is a separate policy**."*

The clearest case is the member who **authored** SB 24 (2023-24, public campaign financing) and
co-authored SB 42. His position is real, strongly evidenced, and simply has no seat on a ladder that
measures how far private money is limited.

Three rows sit at chair 4 on a **no** vote, reasoned as *"Aligns with reducing restrictions on
political donations."* Voting against a public funding option is not voting to reduce restrictions.

### 🔴 The three rows that cite the wrong bill

Three rows cite `202320240SB42` and call it the *"DISCLOSE Act"*, the *"Fair Elections Act"* or
*"public campaign financing reform"*. The 2023-24 SB 42 is the **Community Assistance, Recovery, and
Empowerment (CARE) Court Program** Act, chaptered 09/27/24. The vote they cite is real — the
Assembly Floor passed it **75-0 on 08/29/24** — but the motion is *"SB 42 Umberg Third Reading
Urgency"*, on a mental health measure.

**This is a failure neither gate can see.** The citation is a valid primary source on the right
legislature's site, so `check-stance-sources` passes it. The reasoning names an act, so
`audit-chair-evidence` passes it. Only opening the cited page shows it describes a different bill.
Call it a **misdescribed citation**: the URL is right, the sentence about it is not.

---

## 7. 🔴🔴 A third lying `rung_map`, and this one documents its own lie

campaign-finance v2r3 carries the identity map `{1:1,2:2,3:3,4:4,5:5}` with this public note:

> *"Rebuilt the scale so all five options measure one thing — how much to limit private money in
> campaigns. **The old middle option ("require full disclosure of donations") measured transparency,
> which is a separate question, so it was removed from this limits scale.**"*

```
S1 c3  require full disclosure of all political donations
S2 c3  Keep contribution limits at current levels
```

The note says chair 3 was removed and replaced; the map says 3 → 3. **89 Season 1 answers sit on
that deleted chair, unshadowed and still serving.** They are harmless while they serve Season 1
text and wrong the moment anything ports them or writes a Season 2 row — the same latent shape as
climate-change's ~1,100 and school-vouchers'.

This file writes **no** campaign-finance chair at all, and the migration guards that: it asserts
Season 2 chair 3 does not mention disclosure, and that nothing here seats a campaign-finance chair.

---

## 8. 🔴 Season 3 exists, is a draft, and is inside the check's universe

`inform.seasons` holds a third season, **Season 3, status `draft`, 60 questions and 74 answers.**

The check's `serving` CTE orders by `(season_id = SEASON_2) DESC` and takes the first row, so for a
pair with no Season 2 answer the tiebreak decides whether a **draft** answer or the real Season 1
answer is treated as voter-facing. **57 Season 3 answers have no Season 2 row; 42 of them have no
Season 1 row either**, so the check can count a draft answer as voter-facing when nothing serves.

Checked and clean for this work: no round-four group contains a Season 3 row, and none of migration
1944's 37 targets had one. This is a defect in the check's query, not a contamination of the writes.

⚠ A reading habit this exposed: `CASE WHEN season_id = <S1> THEN 'S1' ELSE 'S2' END` **labels
Season 3 as Season 2**. Label by explicit id, three ways.

---

## 9. Gates

| gate | before | after |
|---|---|---|
| `audit-chair-evidence --csv` (pre-write, 12 seated rows) | **OK: all 12** | — |
| `audit-chair-evidence --check` (post-write) | — | **OK: all 12** |
| `check-stance-sources` | 789 across 4 checks | **789 across 4 checks — identical** |

Predicted before the write from the gate's own predicates: all 12 entering rows clean, the 64 blanks
never enter a universe defined by `value <> 0`, and nothing leaves because Season 1 is untouched.
No baseline commit is owed.

Verified deltas, pre-state queried before committing:

| topic | value | before → after | Δ |
|---|---|---|---|
| campaign-finance | 0 | 31 → 46 | +15 |
| data-centers | 0 | 11 → 25 | +14 |
| fossil-fuels | 0 | 77 → 82 | +5 |
| redistricting | 0 | 99 → 101 | +2 |
| redistricting | **1** | 5 → 17 | **+12** |
| tariffs | 0 | 20 → 48 | +28 |

### Two guard failures worth recording, both caught before any write

1. **GUARD 2 rejected 7 rows** because the generator keyed its name/chair map on the politician id
   alone. Several people appear in more than one of these groups — one appears in three — so a later
   topic overwrote an earlier one, corrupting both the VALUES comments and the guard's chair list.
   Keyed on person **and topic** now.
2. **GUARD 5 rejected 2 targets** that already had a Season 2 answer. The widened cohort was built
   by querying Season 1 directly rather than the serving row, so it picked up two rows already
   shadowed — and already blanked — by an earlier pass.

---

## 10. Open items

1. ▶ **The check treats draft Season 3 answers as voter-facing** (§8). Up to 57 rows. A fix belongs
   in PR #1085's query, not in a migration.
2. ▶ **`CA:SB0042` collided two sessions of one legislature** (§6). The check's self-test covers one
   bill number across two *legislatures*; sessions are not scoped.
3. ▶ **Misdescribed citations are invisible to both gates** (§6). No detector exists for "the cited
   page is not the bill the sentence describes".
4. ▶ **89 Season 1 campaign-finance answers sit on a deleted chair** (§7), joining climate-change's
   ~1,100 and school-vouchers'. Ladder governance.
5. ▶ **64 people lose a position across five topics.** A coverage debt, as in rounds two and three.
6. ▶ Still open from round three: the 8 Season 1 rows whose value contradicts their own reasoning,
   and the 191 Season 2 rows citing a pre-remap chair number.
