# The unmeasured remainder of the national generic-sourcing queue — MEASURED

**2026-10-20. Read-only: nothing was written to the database.** This closes the ▶▶ NEXT item left
by the absence tier-B handoff ("measure the ~1,500 unmeasured keys of the ~2,800-key national
queue"). Every number here was taken from production in this session; none is inherited.

---

## 1. Where the remainder actually sits

The queue reproduces exactly: **3,566 rows / 2,812 keys / 766 politicians** carry at least one
context row whose sources are *all* generic. (#953 recorded 3,547 / 2,812; the key count is
identical and 19 rows have been added since.)

Broken down by which generic host the key rests on — **this is the answer to "where does the rest
of it sit", and it was never a mystery about jurisdictions. It is a split by HOST:**

| keys | generic host combination |
|---:|---|
| 1,094 | wikipedia only |
| 532 | MD mgaleg member page |
| 399 | MD mgaleg + ballotpedia |
| 242 | MA legislature profile |
| 159 | ballotpedia only |
| 115 | MA profile + ballotpedia |
| 87 | TX capitol member page + wikipedia |
| 57 | TX capitol member page |
| 53 | ballotpedia + wikipedia |
| 20 | congress.gov member |
| 19 | ME legislature profile |
| 44 | everything else (MA+wiki 17, MD+wiki 8, AZ 5, congress/govtrack +wiki 5, govtrack 1) |

🔑 **Every closed cohort — federal, MD, MA, TX, CA, VA, candidates — was keyed on a LEGISLATURE or
CONGRESS member page.** The remainder is therefore not a jurisdiction nobody got to; it is the
**1,306 keys that hold no member page at all** and so fell outside every cohort predicate ever
written. That is the "~1,500".

## 2. 🔴🔴 THE QUEUE OVERSTATES ITSELF BY 15%, FOR A SECOND TIME

The 2,812 figure counts a key if **any** of its context rows is all-generic. But a key's
voter-facing row is the **serving** one — the Season 2 row if an S2 answer exists, else Season 1 —
and a key can carry a stale all-generic S1 row underneath a properly sourced S2 repair. Measured at
the serving-row level:

| | keys |
|---|---:|
| keys whose serving season has a sourced context row | 33,675 |
| serving row is ALL-GENERIC | **2,398** |
| … and serving value <> 0 (not blanked) | **1,868** |
| … and no legislature/congress member page | **884** |
| … and the politician is_active — **THE BLOCK** | **884** |

⚖ **414 keys (15%) are in the headline count only because of a superseded row.** This is the same
shape as #953's own 15% correction and as #954: *a queue measured at the wrong grain reports work
that does not exist.* **Measure this queue on the SERVING row.**

The block is **884 keys / 345 people / 38 topics**; 732 serve from Season 1 and 152 from Season 2.

## 3. The measurement: 75% defect rate, CI 62–85%

Seeded uniform random sample of the 884 (`sha256('2026-10-20-natqueue-serving' + key)`), read one
at a time against the seated rung's **own text**, under `STANDARD.md`.

| | defect rate | 95% CI |
|---|---|---|
| measurement sample, n=40 | 31/40 = **78%** | 62–88% |
| fresh verification sample, n=12 (drawn and read separately) | 8/12 = **67%** | 39–86% |
| **COMBINED, n=52** | **39/52 = 75%** | **62–85%** |

**▶▶ "Unranked" was not "clean." This remainder is worse than most of what has already been
worked** — tier A came in at 67%, tier B's three bands at 80.8 / 62.1 / 53.0. The unmeasured block
sits at the top of that range, not the bottom.

**Projected: ~670 defective keys of 884.**

### 🔴 I drifted high, in exactly the documented direction, and the fresh sample caught it
My first pass on the 40 called **82.5%**. Re-checking the riskiest calls against `STANDARD.md`'s
band-vs-rung clause — *"the standard does NOT require the positive evidence to exclude both
neighbours by itself; an absence may decline a neighbour that requires MORE"* — **two rows flipped
to KEEP** (Grijalva/deportation, Simon/religious-freedom), both rows where attributed on-axis
evidence set the direction and an absence declined the *stronger* neighbour. That is the precise
failure the tier-B calibration measured at 17%; I ran 2 of 11 true KEEPs = 18%.
The independently drawn fresh 12 then came in at 67%, below my corrected 78%.
⚖ **Confirms the standing rule: a READER converging on ever LARGER numbers is finding their own
drift.** Quote the combined 75%, not the first-pass 82.5%.

## 4. 🔑 THE ONE PREDICATE THAT SPLITS THIS BLOCK

Whether the reasoning **names an instrument** — a bill or resolution number, a named Act or
Amendment, a numbered ballot measure, an explicit own roll-call vote, or an authored/sponsored
claim. One definition, applied to the 884 and to the 52 read rows alike:

| | share of the 884 | defect rate in sample | CI |
|---|---:|---|---|
| **names an instrument** | 423 (48%) | 15/26 = **58%** | 39–74% |
| **names none** | 461 (52%) | 24/26 = **92%** | 76–98% |

⚖ **A named instrument roughly halves the defect rate but does not clear a row** — 58% of the
instrument rows still failed, almost always because the instrument is **off-axis** or proves the
**side rather than the rung**. The sharpest cases:
- **Venhuizen / school-vouchers**: HB 1055 named, vote counts given, signed into law — and it
  raises a **college merit scholarship**, not a K-12 voucher.
- **Siddiqui / childcare**: Cambridge RISE and Rise Up are her own programmes with real figures —
  and they are **guaranteed income**, not childcare subsidies or provider grants.
- **Neal / judicial-transparency**: subpoenaing a president's tax returns is congressional
  oversight; judicial **financial disclosure** is not courtroom **openness**, which is this ladder.

🔑 **12 of the 13 KEEPs have the same shape:** a named instrument *the person themself acted on*,
whose **content is the rung's own distinguishing clause**. Five of them are the identical row —
a Yea on the 2025 reconciliation act seating `taxes` rung 4 (Pfluger, Lawler, Weber, Goldman,
Carter). That is why `taxes` is the only topic in the sample with repeated KEEPs.

## 5. Shapes measured across the whole block (not sampled — counted)

| count | share | shape |
|---:|---:|---|
| 285 | 32% | names a bill or resolution number |
| 150 | 17% | carries a party or ideological label |
| 132 | 15% | cites a **caucus** |
| **96** | **11%** | cites a caucus and names **no instrument or vote of their own** |
| 76 | 9% | cites an alignment score or rating |
| 40 | 5% | was already "repaired" by an earlier citation migration |
| 31 | 4% | explicit absence phrasing |

### ▶▶ Two closable sub-queues fall straight out of this

**(a) THE CAUCUS-ONLY QUEUE — 79 keys. ✅ WORKED 2026-10-20: 60 BLANK / 14 KEEP / 5 blocked = 81%.**
🔴 **Two corrections to what this file first said.** The count was **79, not 96** — the 96 came from
a looser instrument predicate than the 58%/92% split above, and 17 rows that DO name an instrument
were wrongly inside it. And "every one in the sample failed" was 5 rows; the full read found **14
sound rows**. See `../2026-10-20-caucus-only/LEDGER.md` and migration 1920.
Rows whose entire evidence is membership of a caucus. `STANDARD.md` step 1(a) rules the caucus's
act out explicitly. Four fell in the sample (Ross, Watson Coleman, Pettersen, Tran) and all four
blanked; a fifth (Hoskins/redistricting) came up in the fresh set and blanked too. Top topics:
same-sex-marriage 16 · **ukraine-support 16** · civil-rights 13 · abortion 6 · immigration 6.
🔴 **`ukraine-support` is the block's largest topic (81 keys) and 23 of them cite a caucus, 18 of
those naming no vote at all.** One row says it outright: *"No specific roll-call vote on Ukraine
aid was retrievable, but Ukraine Caucus membership signals support."* All 3 ukraine rows read
failed. This is a near-uniform cluster, and a uniform cluster is the one thing a consensus detector
cannot see ([[instrument_topic_detector]]).

**(b) 🔴🔴 THE REPAIRED-40 — a citation repair left the wrong chair in place, now looking sourced.**
40 block rows carry the mig-1903/1909 repair marker ("Citation repaired … THE CHAIR IS UNCHANGED").
The repair rule — *a repair must not move a chair* — is right, but its consequence was never
queued: **both repaired rows that fell in the sample are chair defects.**
- **DeMaio / same-sex-marriage**: the repair proved he supports same-sex marriage. Rungs 1, 2 and 3
  all do. Rung 3's religious-exemption clause is still unevidenced.
- **Michelle Rodriguez / healthcare**: the repair surfaced "legislative priorities included
  advancing **universal healthcare**" — that is rung **1**, and she is seated at **2**.
⚖ **A repair that is forbidden from moving the chair converts a visible defect into an invisible
one:** the row now reads as sourced and no detector flags it. These 40 need a chair pass, and
nothing currently queues them.

## 6. Defect shapes in the 39 blanks

RUNGTEXT 14 · AFFIL 10 · OFFAXIS 5 · AWAY 3 · ADMITS 3 · NONCOSP 2 · BODY 2 · AFFIRM 2 ·
VEHICLE 1 · OMISSION-FOR-COMMITMENT 1 · SCORE 1 · STALE-PROSE 1 · VINTAGE 1.

**RUNGTEXT leads here as it did in tier B's middle band** — the evidence is real and on-axis and
the *mapping* fails. Repeatedly the row's own prose argues for a neighbouring rung and seats this
one: Tran's gloss describes rung 2 while seated at 3; Hoskins's caucus description is rung 5 while
seated at 4; Frumin's prose says "Value=3" while seated at 4 **and quotes a rung text that is not
on this ladder at all**.

⚖ **A new sub-shape worth naming: THE MAXIMAL-RUNG SEAT.** Rung 1 and rung 5 are the ends of the
ladder, so the narrowing rule cannot rescue them — there is no stronger neighbour for an absence to
decline. Four blanks are exactly this (Driscoll/immigration 1, Guzzone/immigration 1, Karen Lewis
Young/abortion 1, Pritzker/school-vouchers 1): real directional evidence, seated at the ladder's
extreme, where the extra clause (full public-service access; public funding at all stages;
*eliminating* vouchers) is never evidenced. **Seating an end rung requires affirmative evidence for
the end clause itself.**

## 7. Topic order in the sample (cells are small — the ORDER is the signal, not the size)

Clean-ish: `taxes` 1/6 · `deportation` 1/5 · `abortion` 1/2 · `redistricting` 1/2 ·
`religious-freedom` 1/2 · `same-sex-marriage` 2/3.
Total failure: `immigration` 5/5 · `school-vouchers` 4/4 · `ukraine-support` 3/3 ·
`trans-athletes` 3/3 · `housing` 3/3 · `healthcare` 3/3 · `childcare` 2/2 · `climate-change` 2/2.

🔑 Consistent with the tail's lesson — **a rung stating a DIRECTION is describable by the evidence;
a rung stating a MECHANISM or an EXCEPTION FRAMEWORK is not.** `taxes` rung 4 states a direction
and a named reconciliation vote lands on it. `school-vouchers` rungs name eligibility mechanisms;
`trans-athletes` rung 2 still demands "basic documentation of their transition", the clause the
resume state already flags as unstateable.

---

## ▶ What this hands the next session

1. **The caucus-only queue, 96 keys** — mechanically identified, sample says ~100% defective. The
   cheapest real reduction available anywhere in this programme.
2. **The repaired-40** — a chair pass over rows a previous pass deliberately left seated.
3. **The bare-evidence stratum, 461 keys at 92%** — a reading queue, not a repair queue.
4. **The instrument stratum, 423 keys at 58%** — genuinely mixed; these need reading, because the
   failure mode is off-axis instruments, which no URL or keyword test can see.
5. **Re-measure on the SERVING row.** Any future count of this backlog taken at the key level,
   rather than the serving-row level, is ~15% too high.

Artifacts for this pass live in the session scratchpad (`natqueue/`): `block884.json` (the block),
`sample40.json` + `calls40.json`, `reserve.json` + `fresh12.json`, `final.mjs` (the one shared
instrument predicate and the projection), `patterns.mjs` (the corpus-wide shape counts).
