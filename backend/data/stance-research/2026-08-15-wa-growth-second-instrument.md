# Balducci + Dunn / Growth and Development — the second instrument does not exist

**Closed 2026-08-15. No migration; both stay blank. Nothing written to the database.**

Task 10 (mig 1754) seated **Sarah Perry** at `growth-and-development` chair 1 on Ordinance 19613, the
seven-month Fall City subdivision moratorium, which passed 6-3. Balducci and Dunn both voted Yes on it
and were **held rather than seated**, on the reasoning that one *localized, seven-month* moratorium in
**Perry's own district** cannot separate a shared low-growth position from district courtesy. Both were
recorded as "candidate chair 1, needs a 2nd instrument".

This pass looked for that second instrument across the whole King County corpus and did not find one.

## 🔴 The corpus was searched at the wrong threshold, and widening it more than doubled it

`votefirst.py divided` defaults to `--min-oppose 0.20`. The cached
`kingcounty-divided-all.json` had been built at that default, holding **118** divided items.

**A 20% floor cannot see an 8-1 or a 9-2 full-council vote** — those are 11% and 18% against. On a
nine-member council that band is where the *lone dissent* lives, which is the strongest individual
signal there is. Re-running at `--min-oppose 0.10` over the same 12,631 indexed agenda items returned
**260** divided items, and land-use/growth candidates went **11 → 20**.

⚠ **Every instrument that decided this pass came out of the newly visible band**, including all three
lone dissents below. The file is now rebuilt at 10%.

⚠ **This affects more than these two rows.** Task 10's other conclusions — including the 20-of-25
blanks — were drawn against the 118-item view. The **9 seated rows are unaffected**, because they rest
on evidence that was read, not on absence. The **blanks rest on a narrower sweep than was assumed** and
should be re-checked against the 10% corpus before anyone treats them as exhaustive.

## What was examined

Every divided item touching Balducci or Dunn on any growth/land-use keyword, plus a sponsorship sweep
for both members across `zoning`, `urban growth`, `subdivision`, `comprehensive plan`, `density`.
Enacted text was read for the three strongest candidates — never the title, per the standing rule.

| Matter | Vote | Why it does not seat |
|---|---|---|
| **2018-0241** / Ord 19030 | 5-4 final, **both Yes**, Balducci **mover** twice | Winery/brewery/distillery code. Enacted findings are entirely about the **adult beverage industry** and state licensing; "population growth" appears **only as background** for why 2003-era winery rules needed updating. On-topic by vocabulary, not by rationale. |
| **2019-0433** / Ord 19040 | **Balducci LONE No**, twice | Golf facility lodging. The ordinance has **no findings section at all** — it amends the use tables and stops. There is no stated rationale to read, and opposing one commercial use in a rural zone describes no chair on managing population growth. |
| **2025-0127** / Ord 19965 | **Dunn LONE No** at final (8-1) | School impact fee formula. Its findings **cap** the fee for middle housing and larger apartments expressly "as one measure to limit the impact of the fee on housing production", and exempt affordable housing. So a No **cannot** evidence chair 4's "reduce fees" — the ordinance already reduces them. Mixed instrument; the vote cannot be attributed. |
| **2023-0438** UGA + Four-to-One | Dunn **No in committee → Yes at final (9-0)** | Unanimous final passage is not a position. |
| **2024-0315** development permitting fees | Dunn **No in committee → Yes at final (9-0)** | Same. |
| **2023-0440** comprehensive planning | Dunn lone No at final (8-1) | Omnibus amending ~300 code sections. A No cannot be attributed to any one growth position. |
| **2022-0009** interim use permits | 7-2, both Yes | Permit-processing procedure, not growth pace. |
| 2020-0165 rent moratorium · 2019-0437 / 2019-0050 fossil fuel moratoria · 2023-0373 VSHSL levy · 2018-0258 / FCD2018-05 levee condemnation · 2026-0048 detention moratorium · 2021-0199 temporary small house sites | — | Different axes. "Moratorium" is a vocabulary match, not a growth-management rationale. |

Sponsorship added nothing: Balducci's only on-keyword items are school-district capital facilities
plans (a GMA-required annual administrative act), two individual plat authorizations that **lapsed**,
and the winery SEPA follow-up motion. Dunn's are interlocal agreements and a motion on comprehensive-plan
**timelines**.

## 🔑 Findings worth carrying

**Dunn's committee dissents reverse.** Twice — 2023-0438 and 2024-0315 — he voted No in committee and
Yes at a unanimous full council. **A single-vote scan that happens to hit the committee roll call would
record a position he did not hold at passage.** For this member, a committee No is not evidence without
checking final passage. (Same shape as Hollingsworth switching on three Seattle bills.)

**A lone dissent is the strongest available signal and still is not automatically a chair.** All three
lone dissents here failed, each for a different reason: no findings exist (19040), the findings say the
opposite of the obvious reading (19965), or the instrument is too broad to attribute (2023-0440).

**Read the findings, not the title, and read them for RATIONALE not vocabulary.** Ord 19030 is titled
"relating to planning and permitting" and does mention population growth; it is a winery ordinance.

## Disposition

**Balducci / Growth and Development — blank.** **Dunn / Growth and Development — blank.**
Not "unresearched": examined against the full 2018+ King County divided corpus at a 10% threshold, plus
sponsorship, with enacted text read for every plausible instrument. Following the Task 10 convention,
blanks are recorded here rather than as `politician_context` rows, so no row enters the gate's universe.

▶ Owed, and now the more valuable item: **re-check Task 10's other blanks against the 10% corpus.**
