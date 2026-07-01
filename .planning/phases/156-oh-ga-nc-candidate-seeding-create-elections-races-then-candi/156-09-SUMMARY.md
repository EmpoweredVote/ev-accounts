# 156-09 SUMMARY — NC new-candidate stances + NC-6 McDowell (zero-stance incumbent)

**Status:** COMPLETE ✅
**Data:** `backend/data/stance-research/nc-2026-house/` (9 CSVs) → pushed via `_push_relaxed.ts`

## Result — 2 new covered + McDowell / 23 whole-record skips (of 25 new); 35 stance rows, 0 unsourced
Pushed by UUID, 0-unsourced enforced. NC (except McDowell) incumbents untouched (D-01).

### Covered (3 pids, 35 rows)
| figure | ext | topics | source |
|--------|-----|--------|--------|
| **Addison P. McDowell (NC-6 incumbent, D-01)** | -37006 | **22** | iSideWith questionnaire + Wikipedia (redistricting dropped as implausible in self-audit) |
| Richard Ojeda (NC-9 D) | -370901 | 9 | Wikipedia (former WV senator / 2020 pres candidate) |
| Laurie Buckhout (NC-1 R) | -370101 | 4 | lauriebuckhoutforcongress.com + Carolina Journal (2 party-inferred rows dropped) |

**McDowell (D-01 zero-stance-gets-full-set):** the ONLY in-scope incumbent — went from 0 → 22 sourced federal stances. Note: his coverage leans on iSideWith (candidate-stated). Candidate for a later vote-based corroboration pass, but 0-unsourced and chairs-not-polarity satisfied (same-sex-marriage=5 had a verbatim quote; agent self-audited out redistricting).

### Whole-record honest-skips (23 new candidates, pinned in `156-verify.sql` `_stance_skip`)
Cyril Jefferson, Ashley Bell, Jamie Ager, Raymond Smith Jr., Kimberly Hardy, Colby Watson, Gene Douglass, Chuck Hubbard, Max Ganorkar, Paul Barringer, Jack Codiga, Lakesha Womack, John Rogers (I), Anthony Aguilar (Green), Travis Groo (L), Tom Bailey (L), Matt Laszacs (L), Daniel Cavender (L), Guy Meilleur (L), Robert Luffman (L), Maad Abu-Ghazalah (L), Steven Feldman (L), Steven Swinton (L) — all: no fetchable positions (sites down/parked/404, Ballotpedia empty).

## ⚠ Carry-forward data flag (NCSBE certified-list reconciliation)
The batch-G agent fetched the official **NCSBE 2026 Candidate Filing CSV** and found only ONE Libertarian for NC US House: **Robert B. Luffman (NC-5)**. The other NC Libertarians from the 154 field (Bailey NC-1, Laszacs NC-2, Cavender NC-3, Meilleur NC-4, Abu-Ghazalah NC-7, Feldman NC-10, Groo NC-11, Swinton NC-13) may not have certified. Records were KEPT (locked 154 source; not deleted mid-phase). **Recommend a post-hoc NCSBE certified-list prune** (Phase-153-style) to drop any uncertified NC minor-line records.

## FULL GATE — ALL PASS ✅
`156-verify.sql` all 11 assertions PASS, **psql exit 0**: USHC2-03a/b, 02a, 02c (39 incl. McDowell), D-04-GA, D-04-GA13, D-02, USHC2-04, USHC2-05a (0 unsourced), USHC2-05b. `_stance_skip` = 10 OH + 13 GA + 23 NC = 46 whole-record skips.

## Phase-wide stance totals
Covered: OH 9 + GA 5 + NC 2 new + McDowell = 17 candidates, 130 stance rows, 0 unsourced. Whole-record skips: 10 + 13 + 23 = 46.
