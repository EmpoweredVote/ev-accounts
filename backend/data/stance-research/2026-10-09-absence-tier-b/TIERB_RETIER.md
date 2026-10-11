# Absence tier B — re-tier and measurement · 2026-10-09

**Nothing written to the database.** This pass re-ranked tier B, measured the ranking, and then
measured the measurer — which is where the result turned out to be.

Corpus re-extracted first (`extract.sql`): **38,583 context rows** carrying reasoning, up from the
38,405 of the previous run. Tier B reproduces exactly: **954 raw · 852 voter-facing · 39 blocked on
`immigration` · 813 actionable.**

---

## 1. The ranking model — built from the 307 labels, not from the six written shapes

`LEDGER.md` plus `decisions_blank.json` reconstruct a clean labelled set: **307 rows, 206 BLANK /
101 KEEP (67.1%)**, every (politician, topic) key accounted for. Rather than hand-weight the six
defect shapes, each candidate signal was measured against those labels (`features.py`) and a
logistic model fitted on them (`model.py`).

**5-fold out-of-fold AUC 0.763.** Out-of-fold top 75 rows: **94.7% BLANK** against a 67.1% base;
bottom 75: **34.7%**. The ranking is real, and it was never scored in-sample.

What the labels actually say, measured (n = rows where the signal fires):

| pushes to BLANK | | pushes to KEEP | |
|---|---|---|---|
| `ideology` ("conservative", "progressive") | 89.5% blank, n=57 | `questionnaire` (iSideWith, voter guides) | 14.3% blank, n=7 |
| `committee` / chairmanship | 83.3%, n=48 | `mechanism` (a number, cap, threshold, repeal) | 39.5%, n=38 |
| any affiliation | 78.6%, n=117 | a `year` on the evidence | 48.4%, n=91 |
| `endorse` | 78.9%, n=19 | `statement` ("stated", "told", op-ed) | 44.4%, n=27 |

**Off-axis is measurable.** Overlap between the row's vocabulary and the seated rung's own text runs
monotonically: ≤0.05 overlap → **89.7% blank** (n=29); ≥0.20 → 60.4% (n=197).

⚠ **Two of the handoff's six shapes did not survive contact with the labels.** `hedge` ("would be
expected to", "consistent with") separates almost nothing (+0.026) — it is everywhere in tier A, in
good rows and bad. `band_not_rung` came out **backwards** (−0.100): it is a sound reason to blank a
row, but as a *ranking* signal it selects rows that at least name a direction. Both remain valid
adjudication reasons; neither earns a place in a ranker.

**`sources` and `evidence_tier` were tested and add nothing.** `evidence_tier` is empty on all 307.
Source count barely moves (1 source 70.2% vs 2 sources 64.2%). Domains are person-specific and too
sparse, except that `isidewith.com` is 0/5 blank — already captured by `questionnaire`.

---

## 2. The two samples, read blind

58 distinct rows (30 model top band + 30 uniform-random control, 2 overlapping), shuffled together
with the score hidden (`blind.py`), because I built the ranker and am also its judge.

| arm | observed | 95% CI |
|---|---|---|
| **model top band** | **30/30 = 100% BLANK** | 89–100% |
| **uniform control** | **23/30 = 76.7% BLANK** | 59–88% |

Fisher one-sided **p = 0.0053**. AUC of the score against these 58 calls: **0.840**.

🔴 **The remembered ~33% for tier B is not supported.** It rested on six rows. Thirty uniformly
drawn rows read at 77%.

---

## 3. 🔴🔴 THE RESULT THAT MATTERS — my reading standard is not the ledger's

A jump from a remembered 33% to an observed 77% has two explanations pointing opposite ways: tier B
really is that defective, or **my standard has drifted stricter than the one that wrote the ledger**.
No number inside the tier B sample can separate them. So 24 already-adjudicated tier A rows —
stratified 12 KEEP / 12 BLANK, verdicts stripped, same format — were re-read blind (`calib.py`).

| ledger → mine | n |
|---|---|
| BLANK → BLANK | 11 |
| BLANK → KEEP | 1 |
| **KEEP → BLANK** | **6** |
| KEEP → KEEP | 6 |

**Agreement 17/24 = 71%. I call 50% of ledger-KEEPs BLANK (95% CI 25–75%).**

The six disagreements are not scattered; they are two rules:

- **Four are shape 5 — "positive evidence points one way, the absence picks between two adjacent
  rungs."** Ossoff (96% LCV + an IRA vote, absence seats *maintain current levels* over *stop new
  permits*); Frankel (100% ARA + ACA defence, absence seats *improve current programs* over
  *expand*); Raoul and Chen the same. **The ledger KEEPs these. I blanked all four.**
- **Two are "real own acts, but the rung is reached by eliminating both neighbours"** — Jacobs's
  dated council motions, Wied's own immigration positions. Ledger KEEP, I blanked.
- **One runs the other way:** Riley's transportation row, where the evidence is a 2020 bond campaign
  predating his council seat and the row says so. Ledger BLANK, I kept it. **Staleness relative to
  the current office is a seventh shape, and it is not in the handoff's six.**

### What this does and does not undermine

✅ **The 206 blanks already written to production are not threatened.** The disagreement is
asymmetric: on ledger-BLANKs I agree **11/12**. The instability sits entirely on the KEEP side — and
a KEEP is *no action*, so nothing was written on the unstable rows.

🔴 **But it makes the tier B base rate unmeasurable from this sample.** Inverting my observed 77%
through the calibration gives a ledger-standard estimate of **~64%** — and the calibration's own
95% interval is so wide (s ∈ 0.25–0.75) that the corrected rate spans roughly 0–79%. Twelve
calibration KEEPs cannot pin a number. The point estimate is ~64%, near tier A's 67%; the honest
statement is that **tier B is materially more defective than 33% and probably close to tier A, but
the figure is not established.**

⚖ **The mirror of the #954 lesson.** A detector finding a defect in ever *smaller* numbers is
converging on its own bugs. A **reader** finding it in ever *larger* numbers is converging on their
own drift. Both are measured the same way: against a record that was made earlier.

---

## 4. ▶ What to do next, in order

1. **Write the adjudication standard down before reading another row.** One page, and it must rule
   on the two cases above — shape 5, and elimination-of-both-neighbours — because those are 6 of 7
   disagreements. Without it, tier B gets adjudicated on a different standard than tier A and the
   two passes cannot be compared or combined.
2. **Then re-run the 24-row calibration.** Agreement should exceed ~90% before any production write.
   This is cheap and it is the only check that the standard took.
3. **Then read the top band.** `tierb_scored.json` is sorted: **63 rows score ≥0.90, 193 ≥0.80.**
   Both arms say the ranking works, so the top band is where the reading goes. ⚠ Under my strict
   reading the top band saturated at 30/30, so the *lift* is a lower bound — the model is at least
   this good and may be better.
4. **The "~550 wasted reads" premise is retired.** At a control rate of 64–77%, the unranked
   remainder of tier B is worth reading too; ranking changes the ORDER, not whether to go.

**Artifacts** (`C:/ev-stance-work/absence/`): `features.py`, `model.py`, `model.json`, `tierb.py`,
`tierb_scored.json` (813 rows, scored and sorted), `blind.py`, `blind_read.md`, `blind_key.json`,
`mycalls.json`, `calib.py`, `calib_read.md`, `calib_key.json`, `calib_calls.json`,
`labelled_a.json`. Corpus extracts in `C:/ev-stance-work/detectors/`: `extract.sql`,
`s2answers.sql`, `extra.sql`.

---

# Part 2 — the standard, written and tested (same session)

## 5. `STANDARD.md` — derived from the ledger, not from opinion

The 101 KEEP rulings were parsed out of `LEDGER.md` and read as a body. They apply one rule
consistently, and it is **more permissive than the one I had been applying**:

> **Step 1** — the positive evidence must be the person's OWN, on THIS ladder's axis, and establish a
> DIRECTION. **Step 2** — the absence is legitimate when it declines a neighbour that would require
> MORE than the evidence shows, or when it is an omission inside the person's own document on a rung
> about emphasis. **Step 3** — the seated rung's TEXT must describe what the evidence shows.

Crucially: **the standard does NOT require the positive evidence to exclude both neighbours by
itself.** Step 2's narrowing is allowed to do that work. That single clause is where my first pass
drifted — 4 of 6 misses were rows of exactly that shape. ⚖ "A defensive record IS the maintain rung"
(Frankel) is an explicit ledger ruling, not a band failure.

Two rules were added after the second calibration: **vintage is a flag that ROUTES to re-research,
and a KEEP on a vintage row is provisional** (mig 1916 re-researched that queue and 6 of 8 failed);
and **a rung NUMBER in the prose may be stale — test the prose's DESCRIPTION against the rung TEXT.**

⚠ **11 of the 101 ledger KEEPs have since acquired a Season 2 answer** — refresh before refitting.

## 6. Second calibration — 24 FRESH rows, never seen, blind

| | first pass | with the standard |
|---|---|---|
| agreement | 17/24 = **71%** | 22/24 = **92%** |
| ledger-KEEPs called BLANK | 6/12 = **50%** | 2/12 = **17%** |
| ledger-BLANKs called KEEP | 1/12 = 8% | **0/12** |

Both residual misses have causes and neither is drift: **Bengs** is a *stale label* (mig 1916 blanked
him; my call matches production), and **Ford** produced rule 5. Counting Bengs against the current
data gives **23/24 = 96%**.

## 7. 🔑 Tier B's base rate, measured — **43%**

30 **fresh** tier B rows, uniform random from the 755 not yet seen, read under the standard:

| estimate | value | basis |
|---|---|---|
| remembered | ~33% | 6 rows |
| my first pass | 76.7% | 30 rows, no standard, reader 50% drifted |
| **under the standard** | **13/30 = 43.3%** | **30 fresh rows, 95% CI 27–61%** |

**So ~350 real defects in the 813, not ~270 and not ~620.** The gap to tier A's 67% is what the
tiering predicted all along: tier B is "absence *plus* other evidence", and the other evidence is
usually real.

## 8. The ranker holds under the standard

AUC **0.810** against these 30 calls (it was fitted on tier A labels and never saw them).

| score band | rows in the 813 | blank rate in the fresh sample |
|---|---|---|
| ≥0.80 | 193 | **80%** (n=5) |
| 0.50–0.80 | 369 | 56% (n=16) |
| **<0.50** | **251** | **0%** (n=9) |

⚠ Small cells — treat the band rates as indicative. But the shape is consistent with the overall 43%
(193×0.80 + 369×0.56 ≈ 360 ≈ 44% of 813), and **the bottom 251 rows produced no defects at all.**
That is the first defensible answer to where the wasted reads live: not spread evenly, but in the
sub-0.50 third.

## ▶ Revised plan

1. ✅ Standard written and validated at 92%/96%. **Re-run `calib2.py --score` on a third fresh draw
   if another reader takes over** — the check is cheap and it is the only thing that keeps two passes
   comparable.
2. **Read the 193 rows at ≥0.80 first** (~154 expected defects), then the middle band.
3. **Deprioritise the 251 rows below 0.50** — 0 of 9 sampled were defects. Not proven empty (CI
   0–30%), but clearly last.
4. Carry rule 4 forward: any KEEP on a vintage row goes to the re-research queue, not to "done".
