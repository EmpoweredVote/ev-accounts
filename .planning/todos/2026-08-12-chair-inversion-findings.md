# Chair/reasoning inversion — diagnosis (2026-08-12)

Found while re-sourcing class C of [the 197](2026-08-12-the-197-disposition.md). **Not a sourcing
fault: a wrong chair is a wrong voter-facing position.** The compass dot and the "Why this position?"
text say opposite things about the same person.

## The defect
| person | topic | stored chair | what the chair text says | what the row's own reasoning says |
|---|---|---|---|---|
| Alonzo T. Washington | Civil Rights | **5** | *eliminate affirmative action and all race-based government programs* | "As an African American senator in PG County, he prioritizes racial justice" |
| Todd Gloria | Same-Sex Marriage | **5** | *make same-sex marriage illegal* | "the first openly gay mayor of San Diego … chairman of the San Diego LGBT Community Center" |
| Mark Warner | Ukraine | **5** | *end all aid to Ukraine immediately* | "among the most vocal Ukraine aid supporters in the Senate" |
| Tim Kaine | Ukraine | **5** | *end all aid to Ukraine immediately* | "one of the Senate's strongest Ukraine supporters … voted for the $95 billion supplemental" |
| Kevin M. Harris | Childcare | **5** | *no government subsidies or mandates* | sponsored SB0664 (2026) prioritising providers in the Child Care Scholarship Program |

## How the detector was built, and how it first failed
🔑 **Polarity must not be hand-asserted.** Chairs are 1-5 **discrete options**, not a strength scale
and not left-right, and direction is topic-specific — on **Fossil Fuel Policy the RESTRICTIVE chair
is the pro-climate one**, so any "expansive = chair 1" lexicon inverts. So the scan lets **the corpus
define each topic's polarity**: measure how pro/anti-worded reasoning distributes across the five
chairs, and take the majority pattern as the direction. Topics with a weak or non-monotonic pattern
are **UNCALIBRATED** and contribute no flags — Fossil Fuel Policy scores 0.00 and is correctly excluded.

🔴 **The first cut fired on 1,442 rows (4.4% of the corpus) and was mostly noise, because a verb has
an OBJECT the regex cannot see:**
- *"co-sponsored a resolution **opposing** Senate Bill 590"* — a PRO civil-rights act, scored ANTI.
- *"voted **against** the GOP budget that would cut Medicaid"* — PRO healthcare, scored ANTI.
- *"cosponsored legislation to **block** DEI programs"* — ANTI civil-rights, scored PRO.
- *"**supports limited** government-funded healthcare"* — ANTI, scored PRO.

🔑 **Fix: match on what distinguishes the real defect.** True inversions read as *wholly and
unambiguously* supportive with **no oppositional or restrictive word anywhere**. Any restrictive
marker disqualifies the row, because then direction depends on an object the test cannot read.
**1,442 → 194.**

⚠ **Two topics still produce only false positives and must be excluded by hand** — "support" attaches
to opposite objects in them: **School Vouchers** (*"supporter of public education and opponent of
voucher programs"* IS chair 1) and **AI Oversight** (*"promoting voluntary NIST standards"* IS chair 2).
That is 70 of the 194.

## 🔴🔴 IT IS ONE BAD BATCH, NOT SCATTERED NOISE
**15 politicians hold 79 inverted rows, and for 14 of them 100% of their pro-worded rows sit at the
anti pole** (7/7, 6/6 ×5, 5/5 ×6, 5/6, 4/4). **14 of the 15 are Maryland** — 302 of their source
citations are `mgaleg.maryland.gov`. The 15th is Terry Taplin (Berkeley, CA), a separate case.

Sara Love has **19 rows, every one with pro-progressive reasoning**, sitting at chair **5** on Civil
Rights, Healthcare, Childcare, Same-Sex Marriage, Climate, Environment, Reproductive Rights and
Voting Rights, and chair **4** on nine more.

🔑 **Best reading: one research run wrote the chair as an INTENSITY rating — 5 meaning "strongly holds
this view" — instead of picking one of five discrete policy options.** That is exactly the failure the
standing rule warns about.

⚠ **BUT A MECHANICAL 5→1 FLIP IS NOT SAFE.** The same batch got other topics *right*: Sara Love and
Ron Watson both sit at chair **2** on Fossil Fuel Policy (*"supports transitioning away from fossil
fuels"*) and School Vouchers (*"opposes school vouchers"*) — correct, because there the reasoning is
phrased as opposition and the writer picked a low number. The batch is **inconsistent**, so the
correction has to be judged per row.

## Confirmed by reading, per topic
| topic | flags | real inversions | notes |
|---|---|---|---|
| Civil Rights | 20 | **19** | only Harold Rogers is correct at chair 5 ("voted YES on ending racial preferences", 28% NAACP) |
| Same-Sex Marriage | 15 | **8** | the other 7 are genuine opponents (Steube, Kelly, Miller, Fischbach, Graves, Griffin, Reeves) |
| Childcare | 13 | **13** | all Blueprint-support rows at chairs 4-5 |
| Ukraine | 3 | **2** | Andy Harris is correct at chair 4 (voted Nay on H.R.8035) |
| Rent Regulation | 2 | **2** | |
| Misinformation | 4 | **1** | |
| School Vouchers | 45 | **0** | object-ambiguous, excluded |
| AI Oversight | 25 | **0** | object-ambiguous, excluded |
| Climate / Healthcare / Affordable Housing | 67 | not yet read | same 14-politician batch dominates |

## ▶ The open question: what is the remedy?
The stored chair is **unambiguously wrong**; the right replacement is **not** mechanical.
For *"supports civil rights legislation including racial equity measures and LGBTQ protections"*,
chair **2** (*strengthen civil rights enforcement and address systemic discrimination*) fits, but
chair **1** (*mandate racial equity requirements in all institutions and provide reparations*) is a
stronger claim the reasoning does not make. Choosing between them is a research judgement, per row.

Nothing has been changed. Tools: `scripts/chair-inversion-scan.mjs`,
`scripts/chair-inversion-batch.mjs`; records `2026-08-12-chair-inversion-{scan,batch}.json`.
