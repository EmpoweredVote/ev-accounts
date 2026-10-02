# Re-audit owed by the 2026-10-01 annex rulings (Chris Andrews)

Rulings live in `docs/codebook/annex/` (commit `482cbd1a`, branch `claude/intelligent-meitner-e72e0c`).
Counts are text matches on open-season `politician_context.reasoning`, read-only, 2026-10-01. They
show where to look, not a verdict. Re-code each row against the new annex line; any change ships as a
reviewed migration (allocator slot), never an in-place edit.

## same-sex-marriage — RFMA reads as rung 2

- **57 of 146 rung-3 rows cite the RFMA.** A row that rests on the RFMA vote alone moves to rung 2. A
  row whose own words make the religious exemption part of the position stays at rung 3 (the CA_0100
  placements that named the exemption should stay).
- Also check: 59 rung-5 and 11 rung-4 rows cite the RFMA (likely No votes; a No on a recognition bill
  is direction-only on its own).

## gun-policy — reciprocity alone is direction-only (option A, replaces the 2026-09-08 seating rule)

- **49 rung-4 rows, all citing reciprocity.** Each needs a second passage (own words, or a recorded
  vote against a new restriction or a repeal), or it goes blank.
- **3 rung-3 rows rest on the Background Check Expansion Act only** (CC_0078). Clause [a] "allow all
  types" is unevidenced → `compound-partial` unless a second passage exists.

## civil-rights — DEI-office closures are direction-only (2026-10-01)

- **1 rung-5 row (Barr)** rests on DEI-office bills only (an office is not a programme that allocates
  by race). → `direction-only` unless an affirmative-action record exists.

## social-security — wording only

- Barragán (rung 2) reasoning says SS 2100 "does not remove the cap"; the 2026-10-01 ruling says a
  donut design does remove it and the benefit size separates rungs 1/2. Chair stays 2; fix the
  sentence at the next re-audit.

## tariffs — who-sets-tariffs bills are adjacent (2026-10-01)

- **1 rung-2 row (Moulton)** rests on the Prevent Tariff Abuse Act (which branch sets tariffs →
  `adjacent`) plus one remark against across-the-board tariffs, which does not clearly say "reduce
  most tariffs". Re-code; likely `direction-only` without more.

## data-centers — a study bill is not a chair (Season 1 carry-over)

- The `data-centers` memory note (CA_0033) records a Season 1 move to rung 3 that rests on a bill for
  a data-centre impact **study**. Under the codebook that is V4 `study-directive` and cannot seat a
  chair. Check whether the row carried into Season 2; if so, re-code it.

## Not owed

- ukraine-support: 0 open-season answers; the H.R. 8035 ruling moves nothing.
