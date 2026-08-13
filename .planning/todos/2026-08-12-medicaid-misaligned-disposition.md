# The "backed Medicaid expansion" MISALIGNED slice — disposition (2026-08-12)

Closes the chair half of the template class opened in `project_medicaid_expansion_template`.
Sourcing half: migs 1722 (MD) and 1724 (TX). **Chair half: mig 1726.**

## The headline: "18 misaligned rows" was a regex estimate. The true count is 3.

The 18 came from matching pro/anti wording across whole reasoning strings and comparing to the
pole. It over-fires the way every first cut in this workstream has
(`project_detector_first_cut_overfires`). Rather than re-run a regex, the class was **read**:

| slice | rows | read | misaligned |
|---|---|---|---|
| chair 4-5 (anti pole) — every row that could be pro-worded there | 140 | 140 | 2 |
| chair 1-2 (pro pole) — every row that could be anti-worded there | 82 | 82 | 1 |
| chair 3 (middle) | 32 | 32 | 0 |
| **class total** | **304** | **254** | **3** |

The 50 rows not individually read are chair 1-2 rows already covered by the whole-reasoning
polarity scan (below); no row at a pole went unexamined.

### ✅ The anti-at-the-pro-pole direction is EMPTY
Not one of the 82 rows at chair 1-2 is anti-worded. And all 82 Medicare/Medicaid rows at chair 4-5
are genuine opponents of expansion correctly at the anti pole — Abbott, Paxton, McConnell, Reeves,
Tillis, Stitt, Kemp, Ivey, DeSantis, Ricketts.

### Rows the detector would have flagged and reading REJECTED
- **Nikema Williams** (chair 1) — "voted against a limited Medicaid expansion in Georgia because
  she favored full expansion". Anti-worded, correctly at the pro pole.
- **Marty Jackley** (chair 4) — "touts that states stopped ObamaCare's forced Medicaid expansion".
  Contains support vocabulary, correctly at the anti pole.
- **Vern Buchanan** (chair 4) — names "value 5" only to rule it out: "preventing a pure value 5
  assignment".
- **Dianne Hesselbein** (chair 3) — reasoning says "aligning with chair 2", but carries an explicit
  2026-07-27 orchestrator note recording the deliberate 2 → 3 correction and the compound-chair
  rule behind it. Superseded inside the same paragraph.
- **Shannon W. Bray** (chair 4) — "government should not be involved in healthcare" *while*
  supporting a narrow Medicaid expansion for the elderly and disabled. Mixed, and 4 is defensible.

## ✅ FIXED — mig 1726 (applied, verified; corpus 33,083 / 32,542, orphans 0, class still 304)
| politician | topic | chair | defect |
|---|---|---|---|
| Benjamin F. Kramer (MD) | Healthcare Access | 5 → 2 | pole inversion |
| Jeff Waldstreicher (MD) | Healthcare Access | 5 → 2 | pole inversion |
| Pete Aguilar (CA) | Medicare / Medicaid | 1 → 2 | self-contradiction |

Kramer and Waldstreicher are the two rows mig 1722 **predicted** and refused to re-source. Target
2 not 1 per the least-extreme-pro-option rule: chair 1 is single payer, which neither row claims.
Aguilar's own last sentence names stance 2 and rules out stance 1.

🔑 **Sourcing is still owed on the two Maryland rows** — they remain on 1722's owed list carrying
the unsourced template sentence. 1726 changed chairs only.

## 🔴🔴 STILL OPEN — the cohort is the defect again: 18 rows on these same two politicians

Reading *all* of Kramer's and Waldstreicher's rows shows the migration-1714 intensity-rating defect
is **not confined to this class**. `project_chair_reasoning_inversion` records the 1714 re-scan as
showing "the batch signature is gone (0 politicians, was 15)" — it is not gone. It is sitting in
the topics that scan scored **UNCALIBRATED**, which are exactly where these rows are.

**Chair 5 with plainly pro-worded reasoning — 8 rows, high confidence:**
- Kramer: Voting Rights ("opposes voter ID restrictions"), Abortion ("a reliable pro-choice vote"),
  Medicare/Medicaid ("supports expanding Medicaid and protecting Medicare")
- Waldstreicher: Immigration, Trans Athletes, Same-Sex Marriage, Abortion, Voting Rights

⚠ Waldstreicher/Same-Sex Marriage is the **exact shape** of the Sara Love row named in
`project_chair_reasoning_inversion` as the original exemplar — chair 5 is "make same-sex marriage
illegal" on reasoning describing a vocal supporter.

**Chair 4, polarity NOT established — 10 rows, must be calibrated before touching:**
- Kramer: Public Safety Approach, Taxes, Environmental Protection vs. Development, Economic
  Development Incentives
- Waldstreicher: Police Accountability, Criminal Justice, Public Safety Approach, Campaign Finance,
  Economic Development Incentives, Bail & Pretrial

⚠ Deliberately **not** swept into 1726. Each topic needs its pro pole read from `compass_stances`
first (`feedback_compass_chairs_not_polarity`: 1-5 are discrete options, not a L-R axis — Fossil
Fuel Policy's *restrictive* chair is the pro-climate one), and a mechanical 5 → 1 flip is precisely
the error mig 1714's header warns about: the same batch got Fossil Fuel Policy and School Vouchers
*right*, and both men's sourced rows (Kramer/Housing, Waldstreicher/Rent Regulation, Childcare,
Climate) sit correctly at 1-2.

**The real question this raises:** the batch was 15 politicians. If two of them still carry ~18
uncorrected rows each in untested topics, the other 13 need the same whole-politician read — the
1714 cohort was topic-scoped, so per-politician completeness was never established.

## ✅ ANSWERED — mig **1727**, applied and verified. 142 chairs corrected, 20 read and kept

Swept **all 24 politicians 1714 touched**, not just the 15-politician batch — same defective run.
Every anti-pole row read: **162 rows → 142 corrected · 20 kept**. Mark Warner and Tim Kaine hold
**zero** rows at a pole and needed nothing.

| | |
|---|---|
| Maryland (14 politicians) | 97 corrections |
| California (8: Berkeley, San Diego) | 45 corrections |
| Read and kept | 20 |

🔑 **CALIBRATION CHANGED THE ANSWER FOUR TIMES.** Polarity was read from `compass_stances` per
topic, never assumed, and four topics have their PRO end at the HIGH chair:
- **AI Oversight is REVERSED** — chair 1 is "allow AI companies to develop freely", chair 5 is
  "ban AI systems that could cause serious harm". Three rows at 4-5 are correct, including Sean
  Elo-Rivera's, whose evidence is that he *authored* the algorithmic-rent-setting ban.
- **Residential Zoning 4-5 is the upzoning end** — six Berkeley/San Diego rows correct.
- **Growth and Development Pace 4** is streamlined permitting — correct for Todd Gloria.
- **Affordable Housing 4** is "cut regulations so private developers can build" — correct for the
  YIMBY members, wrong for the tenant-protection ones. **Same chair, opposite verdicts.**

🔑 **The 20 kept rows are the proof it was not mechanical.** Todd Gloria's Rent Regulation stays at
4 because the row says he "prioritizes building new units over rent control". Muse's Religious
Freedom stays at 4 — an ordained minister championing faith-based protections. Rosapepe's Economic
Development stays at 5 — he really is a development champion. Reasons for all 20 in the rollback JSON.

🔑 **Targets, by the least-extreme-pro rule:** Voting Rights → 2 (chair 1 also demands online
voting); Public Safety → 3 for the Maryland "prevention alongside enforcement" rows but **2** for
Terry Taplin, whose row quotes chair 2's unarmed-co-responder option almost verbatim; Economic
Development → 3 (the rows never take a position on subsidies at all); Same-Sex Marriage → 1,
matching 1714.

✅ **Verified:** the 20 rows still at a pole are exactly the 20 read and kept, name for name;
corpus 33,083 / 32,542; orphans 0; no off-ladder values.

⚠ **Sourcing is still owed** on these 142 rows and on 71 of 1714's — most are Ballotpedia bios.
The chairs are right; the citations are not yet.

▶ **Still open:** the scan that produced 1714 was calibrated per topic, and the four topics it
scored UNCALIBRATED were never tested corpus-wide — only for these 24 people. A national re-scan
using the now-known polarity of Voting Rights, Reproductive Rights, Immigration and Fossil Fuel is
the next measurement.
