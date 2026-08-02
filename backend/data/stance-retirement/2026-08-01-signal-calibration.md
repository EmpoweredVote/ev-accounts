# Calibrating a risk signal for the homepage-cited backlog — result

Ran against the **78 hand-labelled rows** of the `NO_QUOTE` review (13 retire · 3 chair · 9 reasoning ·
53 keep). Tools: `scripts/calibrate-noquote-signals.mjs`, `scripts/rank-homepage-rows.mjs`.

---

## 🔴 Headline: the signal we set out to calibrate cannot be calibrated, and would not have worked

**"The row's only source is a bare campaign homepage" is true of 78 of 78 labelled rows.** Zero
variance. That is not a coincidence — it is the *definition* of the bucket they came from:
`PRIMARY_SITE_NO_PATH` selects rows whose citation has no path.

So it separates that bucket from the rest of the corpus and **orders nothing inside it**. The earlier
claim that it "risk-ranks all 535 `PRIMARY_SITE_NO_PATH` rows" was wrong: every one of those 535
already has the property.

The original observation was real but came from comparing in-cohort rows (32% defective) against
**seven** out-of-cohort rows picked by hand (0% defective). Suggestive; not a sample, not a control.
Testing it properly would need a control group drawn from rows *outside* the backlog, hand-labelled —
which is a different and more expensive experiment, and is not what was run here.

---

## What actually predicts a defect

Target: **severe** defects only — the voter saw a wrong chair (retire + chair = 16 of 78, base 20.5%).

| feature | n | severe | precision | rest | lift | recall |
|---|---|---|---|---|---|---|
| **reasoning argues FROM ABSENCE** | 10 | 7 | **70%** | 13% | **5.3x** | 44% |
| reasoning hedges (implies/likely/would favour) | 3 | 2 | 67% | 19% | 3.6x | 13% |
| reasoning leans on PARTY / EMPLOYER / ENDORSER | 5 | 2 | 40% | 19% | 2.1x | 13% |
| site carries 3+ rows AND is one page | 14 | 4 | 29% | 19% | 1.5x | 25% |
| ~~source is a bare homepage~~ | 78 | 16 | 21% | — | — | 🔴 constant |
| probe found NO topic passage | 5 | 1 | 20% | 21% | **1.0x** | 6% |
| chair is extreme (1 or 5) | 22 | 4 | 18% | 21% | 0.8x | 25% |
| site is ONE page only | 32 | 5 | 16% | 24% | **0.7x** | 31% |

**The one that works is textual, and it is the same tell in every case: the REASONING is carrying the
weight the SOURCE should carry.** Union of absence/prior/geography/hedge markers:

- markers alone — **15 flagged, 60% precision, 5.4x lift, 56% recall**
- plus the site-shape signal — 28 flagged, 43% precision, **75% recall**

### Three results that contradicted expectation, and matter more than the wins

1. 🔴 **"Site is one page only" is ANTI-predictive (0.7x).** Kirkland's four defective rows all came
   off one thin page, and I generalised from him. Thin sites are, if anything, slightly *safer*. That
   intuition would have become folklore if it had not been measured.
2. 🔴 **"The probe found no topic passage" has a lift of 1.0 — literally no predictive value** (20% vs
   21%). This is the exact thing `probe-topic-evidence.mjs` warns about in its own header: *"an empty
   result is a prompt to look, never a verdict."* Now measured rather than asserted.
3. 🔴 **Chair extremity does not predict either (0.8x).** An extreme chair is not a riskier chair.

---

## ⚠ Two limits that must travel with these numbers

**They are in-sample.** The patterns were written *after* reading the 78 rows they score well on.
Working the top of the queue is the out-of-sample test. If the hit rate holds near 40–60% the signal
is real; if it collapses it was overfitted, and the right response is to delete it, not defend it.

**It cannot see fabrication.** Every severe defect the signal MISSED was written *confidently*:

| missed | why the signal cannot reach it |
|---|---|
| Welford / Healthcare | a **fabricated quotation** — reads like the best-sourced row in the cohort |
| Tandon / Childcare | confident, specific, and describes a mechanism the page does not have |
| Kirkland / Housing, Healthcare, Taxes | flat declaratives cut from a slogan |
| Benson / Housing | accurate prose, wrong axis |
| Hernandez / Housing | terse and assured |

A queue built on hedging language systematically skips the worst failure mode, because **fabricators
do not hedge**. This ranks reading order; it is not coverage.

---

## A refinement that was tried and rejected

Spot-checking the corpus queue surfaced two false positives and an appealing hypothesis:

- **Monteiro** was tagged geography because `strongly pro-` matched *"a strongly pro-economic-development
  position"* — a description of the candidate, not a district prior. **Fixed**: anchored to a place noun.
- **Hooslyn** was tagged absence for *"he does not call for the government to directly build/own all
  housing, so this sits at the second chair rather than the most maximalist option"* — which is
  **correct practice**: using absence to narrow between adjacent chairs.

That suggested splitting absence into **establish** ("no evidence… therefore chair 5" — the defect)
versus **narrow** ("doesn't go as far as chair 1, so chair 2" — fine). Measured against the labels:
**4/5 and 3/5 defective**. The split is not supported at that n and was **not adopted**. Recorded here
so it is not re-proposed on the strength of the story alone.

---

## Product: the reading queue

`2026-08-01-homepage-reading-queue.md` — **42 of 517 unread rows** carry a marker
(32 absence · 6 hedge · 4 party/employer/endorser). Expected yield if the calibration holds: ~17–25
real defects. That is the out-of-sample test.

⚠ **The site-shape signal was dropped from scoring at corpus scale.** Its labelled form needs a page
count (requires a crawl); the fetch-free stand-in, host row-count, fires on **327 of 517 rows — 63%**.
A signal that flags two thirds of the population is a restatement of "candidates have several stances
on their own site", not a ranking. Kept as an annotation only.

**Note on the count:** the query finds 587 rows to the gate's 535, because it does not replicate the
gate's proxy and Ballotpedia carve-outs. Slightly wider than the bucket — fine for a reading order,
wrong for a gate number.
