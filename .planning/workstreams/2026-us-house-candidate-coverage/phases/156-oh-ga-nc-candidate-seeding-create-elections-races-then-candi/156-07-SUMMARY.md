# 156-07 SUMMARY — OH new-candidate stances

**Status:** COMPLETE ✅
**Data:** `backend/data/stance-research/oh-2026-house/` (8 CSVs) → pushed via `_push_relaxed.ts`

## Result — 9 covered / 10 whole-record skips (of 19 new OH candidates); 67 stance rows, 0 unsourced
Researched federal-24 chairs-not-polarity stances via `politician-stance-researcher` agents (batched, ≤3 concurrent). OH partial incumbents untouched (D-01). Pushed by UUID; 0-unsourced enforced by the relaxed push (drops any row lacking a real http source).

### Covered (9)
| candidate | ext | topics | primary source |
|-----------|-----|--------|----------------|
| Derek Merrin (OH-9 R) | -390901 | 8 | derekmerrin.com |
| Vanessa Enoch (OH-8 D) | -390801 | 9 | enochforcongress.com |
| Jerrad Christian (OH-12 D) | -391201 | 18 | iSideWith (tier-6, candidate-stated; voting-rights=3 shown-not-inferred) |
| Kristina Knickerbocker (OH-10 D) | -391001 | 7 | kristinaknickerbocker.com |
| Brian Shaver (OH-5 D) | -390501 | 9 | brianshaverforcongress.com |
| Eric Conroy (OH-1 R) | -390101 | 7 | ericconroy.com |
| Carey Coleman (OH-13 R) | -391301 | 5 | careycoleman.com |
| Matthew Althaus (OH-9 L) | -390902 | 3 | mattalthausforcongress.com / lpo.org |
| Brennan Barrington (OH-15 L) | -391502 | 1 | lpo.org |

### Whole-record honest-skips (10, pinned by UUID in `156-verify.sql` `_stance_skip`)
Maria Jukic (-391401), Jennifer Mazzuckelli (-390201), Mike Kirchner (-391101), Joshua Kolasinski (-390401), Brian Poindexter (-390701), Tamie Wilson (-390402), Don Leonard (-391501), Elizabeth Kirtley (-390601), Cleophus Dulaney (-390301), John Hancock (-390102) — all: no fetchable primary-source positions (sites down/404/ECONNREFUSED, Ballotpedia empty). Party-inference refused (chairs-not-polarity).

## Verification pass
0-unsourced enforced by push filter (67/67 rows carry ≥1 fetched http source). Verification relied on the agents' fetch-only-real-URLs discipline + the push filter (155 precedent). Jerrad Christian's iSideWith-only rows: iSideWith is a real fetched source of candidate-stated positions; the non-obvious voting-rights=3 (voter ID) was explicitly shown in the data (not party-inferred), so retained.

## ⚠ Carry-forward data flag
**OH-1 Libertarian**: the batch-D agent reports the LP of Ohio lists **Jason Stoops** (not John Hancock) as the OH-1 congressional candidate; the 154 field table listed "John Hancock (Libertarian)". Possible 154 mis-ID. Record kept (ballot-listed per 154 source) + stance honest-skipped. Flag for a post-hoc 154 re-check.

## Gate
0 unsourced for the 19 race-scoped OH pids; every OH new candidate covered-or-skipped. `_stance_skip` has 10 OH pins (GA/NC appended by 156-08/09).
