# NC Stance Campaign — Batch Ledger

`inform.politician_answers` has no timestamps. This file is the only record of what each batch
wrote. Append one row per batch, in the same task that pushes it. Never backfill from memory.

| Batch | Date | Cohort | People | Rows pushed | Quotes drafted | CSV | written-*.json |
|---|---|---|---|---|---|---|---|
| pilot | 2026-08-24 | Ager (HD 114) · Mayfield (SD 49) · Kopac (Durham W1) | 3 | **8** | 5 parked, 0 inserted | `2026-08-24-nc-pilot-approved.csv` | `written-pilot.json` |

## Pre-campaign baselines (measured 2026-08-24, before any batch was pushed)

Task 6 compares the end state against these. Measure them again at close-out, not the delta.

| Measure | Baseline |
|---|---|
| `inform.politician_answers` rows, all corpora | 32,887 |
| `inform.politician_context` rows, all corpora | 33,541 |
| Context rows with no matching answer (orphan context) | **654** |
| Answer rows for anyone holding an NC seat | 326 |
| Answer rows for the 202 people in this campaign | 0 |

The orphan-context number is the one that must not grow. A context row without an answer is an
unpublished claim: it renders the moment someone writes an answer for that pair.

## Batch notes — pilot (2026-08-24)

**38 rows researched, 8 pushed.** Every instrument behind the 8 was opened and read on ncleg.gov
before the write; the reasoning was rewritten to name the bill in North Carolina's own style.

Held or dropped, and why — these are the shapes to expect for the other 199 people:

| Shape | Example | Disposition |
|---|---|---|
| Bill misdescribed | `school-vouchers` cited H87 as a voucher bill. H87 is a cell-phone-free education bill; the 114-3 vote was on cell phones. | dropped |
| Names no instrument | Mayfield `immigration` cited a campaign page describing "bipartisan legislation" with no number. | dropped |
| Direction, not magnitude | Mayfield `trans-athletes`: a No vote on a ban rules out chair 4 but cannot separate chair 1 from chair 2. | held |
| Bare roll-call vote | Mayfield `climate-change`: H951 passed the Senate 42-7. A vote 42 of 49 senators cast discriminates no personal chair. | held |
| Two adjacent chairs fit | Mayfield `childcare`: S412 raises subsidy rates but states no eligibility band, so chairs 2 and 3 both fit. | held |
| Aggregated across bills | Mayfield `housing` rested on S495 plus two unverified funding bills. S495 alone is a pure zoning mandate with no money, which reads closer to chair 4. | held |
| Chair is federal in scope | `same-sex-marriage` chair 1 requires recognition by all states and full federal benefits. No state bill can evidence either clause. | held, logged for season 2 |
| Promise, not instrument | All 7 of Kopac's rows rested on a campaign platform page. | held — he seated 0 |

Ager's `housing` survived the same test Mayfield's failed: House Bill 1056 is a **single** instrument
carrying both the deregulation and the $40 million subsidy, so chair 3 is the only chair that fits
both halves. Chair 4 has no room for the money.

**Two ladder defects for the ADR 0004 revision queue**, not workarounds for this campaign:
`medicare/aid` chair 2 reads "lower Medicare age to 55 and expand Medicaid significantly", and
`same-sex-marriage` chairs 1 and 2 are written at federal scope. A state legislator can never
evidence either fully, so those spokes are unreachable by construction for all 170.
