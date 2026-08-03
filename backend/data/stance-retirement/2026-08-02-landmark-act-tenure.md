# Landmark-act pre-tenure pass — the TCJA cluster generalised

**Built to answer one question from the term-start detector:** six of its twelve confirmations were the
same December-2017 Tax Cuts and Jobs Act vote, which "looks like one systematic error, not eight."
It is. Finding out what kind grew the operator queue from **26 rows to 39**.

Artifacts: `2026-08-02-tcja-cluster.json` · `2026-08-02-landmark-act-tenure.json` ·
`2026-08-02-pretenure-union.json` · `scripts/_tmp-tcja-cluster.mjs` ·
`scripts/_tmp-landmark-act-tenure.mjs` · `scripts/_tmp-pretenure-union.mjs`

---

## 1. The TCJA cluster: one topic, and two different mechanisms

Exhaustive, not sampled — every row whose reasoning names the act.

| | n |
|---|---|
| rows mentioning TCJA with a live chair | 144 |
| …**on the single topic "Taxation and Public Spending"** | **141** |
| action-asserting clauses bound to the 2017 act, matched to a federal legislator | 75 |
| …seated for the December-2017 vote | 68 |
| 🔴 …**pre-tenure** | **7** |

**The cause is topic concentration, not a bad prompt.** 141 of 144 mentions sit on one topic, because
that topic has one obvious landmark federal vote and the research pass reached for it every time. It
was right 68 times out of 75. There is no distinct source signature to find: the seven defective rows
draw on the same hosts in the same proportion as the 68 correct ones (OnTheIssues and Wikipedia
dominate both). **The sourcing is not what failed; the reading is.**

🔴 **And two of the seven cite the genuine roll call.** Bentz and Hoyle both source to
`clerk.house.gov/evs/2017/roll699.xml` — the real TCJA vote, a record that lists the entire chamber
and therefore *contains the proof they were not in it*. The pipeline found the correct evidence and
then attributed the chamber's vote to someone absent from it. Nothing checked membership.

⚠ **Barry Moore is a different defect and must not be retired.** His only source,
`ontheissues.org/Senate/Barry_Moore.htm`, reads **"One Big Beautiful Bill delivers largest tax cut in
history. (Jul 2025)"** and contains **zero** occurrences of "TCJA" or "2017". Our row says *"Voted for
the largest tax cut in history (TCJA)"*. He cast that 2025 vote; the act name was **supplied by the
research pass, not read from the source**. This is the composed-citation failure mode applied to a
bill name — invention in the gap left by a real source. Correct the name; coverage is preserved.

## 2. The generalisation, and it found 13 more rows

If the cause is "topic has a landmark bill", the defect should appear on every such topic. It does.
Each of 18 landmark federal acts carries its **real floor-vote dates**, so this pass needs no year in
the text at all — a strict improvement on year-adjacency.

**32 clauses / 32 distinct rows**, spread over 16 topics. The 2017 concentration is real but not the
whole story: Same-Sex Marriage contributes 4, Healthcare Access 4, Taxation 8.

🔴 **New people the earlier passes could not see:**

| politician | rows | what is asserted | seated |
|---|---|---|---|
| **Matt Van Epps** | **5** | voted for the One Big Beautiful Bill (May 2025) | **2025-12-04** |
| **Mike Collins** | 2 | "Voted FOR the Respect for Marriage Act … breaking with most conservative Republicans" | 2023-01-03 |
| **Ayanna Pressley** | 1 | voted for the First Step Act (Dec 2018) | 2019-01-03 |
| **Greg Landsman** | 1 | voted for the Respect for Marriage Act (Dec 2022) | 2023-01-03 |
| **Robert Menendez** (NJ-8) | 1 | voted for the IRA (Aug 2022) | 2023-01-03 |
| **Anthony G. Brown** | 1 | "voted for the Affordable Care Act … **as a Congressman**" (2010) | 2017-01-03 |

⚠ **Mike Collins is the highest-harm row found in this workstream.** It credits a conservative
Republican with a *pro*-same-sex-marriage vote he could not have cast and editorialises that he broke
with his party for it. The chair is 3.0 on a five-point axis, so the fabrication is load-bearing.

🔴 **Robert Menendez was hidden by an ambiguous surname**, and the matcher was right to abstain: two
men of that name, both New Jersey. Ours is NJ-8 (bioguide **M001226**, the son, seated 2023); his
father was Senator 1993–2024. ⚠ **This is NOT a father/son identity swap** — the row's sources are the
son's own Wikipedia page. It is a plain pre-tenure claim that name ambiguity concealed. Resolved by
chamber, from our own office row.

## 3. The union: 39 distinct rows, not 26

Three passes now find this defect by three different routes, so the queue is the union on
`(politician_id, topic_id)`.

| found by | rows |
|---|---|
| landmark-act only | 12 |
| landmark-act + roll-call | 8 |
| landmark-act + roll-call + term-start | 6 |
| roll-call only | 6 |
| landmark-act + term-start | 6 |
| landmark-act, hand-resolved (Menendez) | 1 |
| **total distinct** | **39** |

| verdict | rows | meaning |
|---|---|---|
| **FABRICATED** | **36** | the action cannot have happened; no citation change repairs it |
| PARTLY_FABRICATED | 1 | Anthony G. Brown — strike the ACA vote, keep "and its expansions" (ARP 2021) |
| MISLABELLED | 1 | Barry Moore — real 2025 vote, wrong act name |
| IMPRECISE | 1 | Suzanne Bonamici — "voted YES on ACA **protections**" plausibly describes real defence-of-ACA votes; reword, do not retire |

Heaviest: **Val Hoyle 12 rows** (of 20 stances), **Andrea Salinas 6** (of 13), **Van Epps 5**. Nobody is
zeroed out by retirement.

⚠ The roll-call audit's "Hoyle ×11" was a *citation* count; by row it is 12, and 12 + 6 + 2 = the 20
rows that audit reported. The two figures were always consistent.

## 🔴 The detector was wrong seven ways — eighth consecutive first cut to over-fire

First cut: **76 findings. Final: 32.** Every reduction was a real modelling error, and two of the
suppressed classes were *false accusations that a politician's record is fabricated* — the expensive
direction to be wrong in.

| bug | what it produced |
|---|---|
| **one vote date per act** | the largest false block: **29 For the People Act hits**. H.R. 1 passed the House in **2019 and again in 2021**, so members elected in 2020 were judged against the 2019 date. Same for the George Floyd Act (2020, 2021) and the John Lewis VRAA (2019, 2021). `votes` is now a **list**; pre-tenure requires being absent for **all** of them. |
| **verb not bound to the measure** | 12 of 18 TCJA hits were people who voted for the **2025 One Big Beautiful Bill** in a sentence mentioning TCJA only because OBBBA extends it, or who co-sponsored the separate **TCJA Permanency Act** |
| **subject assumed to be our politician** | *"**Unlike Murkowski and Sullivan who voted for** the Respect for Marriage Act, Moody has given no indication…"* — a vote correctly credited to two other senators |
| **"whose members voted"** | Pettersen flagged for her **caucus's** votes |
| **conditionals read as claims** | Lawler *"stated he **would have voted for**"* it — a row being careful, punished for it |
| **acting *on* an act read as voting *for* it** | Fedorchak (2025-) *"introduced legislation to **eliminate** IRA tax credits"* — a real 2025 bill about a 2022 law |
| **vehicle named *after* the act** | Moulton *"voted for the ACA's protections and expansion **via the American Rescue Plan**"* — an ARP vote, in a sentence whose first act name is the ACA. Looking only leftwards missed it. |

Also fixed in matching: compound surnames need every trailing token tried (**Moore Capito** is filed
under *Capito*), and members are stored under familiar names the dataset carries only as a nickname or
inside `official_full` (**Lou** Correa is *J. Luis Correa*). Both had abstained as "unmatched"; both
turned out to be **correct rows**, seated well before the votes they describe.

## What is owed

1. **39 rows — ⏳ operator decision**, per the verdict table above.
2. **Ask whether the same "landmark item" concentration bites non-legislative topics** — this pass can
   only judge federal measures. A state-level equivalent (landmark state bills) is unbuilt.
3. ⚠ **A duplicate government row exists**: `United States Federal Government` appears with
   `type='NATIONAL'` (535 politicians) **and** `type='federal'` (9). Every detector in this workstream
   gates on `'NATIONAL'`. Today that is harmless — the 9 have **zero** stances — but it is a live trap
   for the next one, and the gate should be `IN ('NATIONAL','federal')` or the rows merged.
