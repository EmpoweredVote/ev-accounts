# NC Stance Campaign — Batch Ledger

`inform.politician_answers` has no timestamps. This file is the only record of what each batch
wrote. Append one row per batch, in the same task that pushes it. Never backfill from memory.

| Batch | Date | Cohort | People | Rows pushed | Quotes drafted | CSV | written-*.json |
|---|---|---|---|---|---|---|---|
| 01 | 2026-08-24 | NC House districts 1-10 | 10 | **8** | 0 | `2026-08-24-nc-batch01.csv` | `written-batch01.json` |
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

## Batch notes — batch 01, NC House districts 1-10 (2026-08-24)

**8 rows across 6 people. Four members seated nothing.** Researched inline, primary sponsorships
first, every cited bill opened and read.

| District | Member | Rows |
|---|---|---|
| 1 | Edward C. Goodwin | 0 — veterans and commemorative bills only |
| 2 | B. Ray Jeffers | redistricting 1 |
| 3 | Steve Tyson | data-centers 2 |
| 4 | Jimmy Dixon | 0 — agriculture bills; a Medicaid rebase is routine funding, not a chair |
| 5 | Bill Ward | **0 — blanked by his own conflict** |
| 6 | Joseph Pike | data-centers 1 |
| 7 | Matthew Winslow | housing 4 |
| 8 | Gloristine Brown | childcare 2 · housing 3 · redistricting 1 |
| 9 | Timothy Reeder, MD | 0 |
| 10 | John R. Bell, IV | housing 3 |

### The Ward conflict, and why it matters

Ward is a **primary sponsor of both** House Bill 1189, which imposes a datacenter permit moratorium
(chair 1), **and** House Bill 638, which instead makes data centers pay for their own dispatchable
power (chair 2). Two adjacent chairs, both his own bills. His `data-centers` spoke is blank.

The same check cleared three others: Tyson is not on House Bill 1189, Pike is not on House Bill 638,
and Ager (pilot) is a cosponsor of 1189 only. **Check every member against every instrument on the
topic before seating, not just the one you found first.**

### Housing 3 versus housing 4 is a real distinction, not a partisan one

Ager, Gloristine Brown and Bell all sit at chair 3; Winslow sits at chair 4. The discriminator is
whether public money is present. Ager's House Bill 1056 pairs deregulation with a $40 million
subsidy; Brown pairs House Bill 404's Housing Trust Fund money with House Bill 626's easier
permitting; Bell's House Bill 1072 is $50 million in below-market loans. Winslow's two bills — House
Bill 765 and House Bill 627 — spend nothing and work purely by removing local rules, which is what
chair 4 says. **Bell is the House Majority Leader and lands on the same chair as two Democrats.**
That is the compass working as designed.

### 🔴 A SHORT TITLE IS NOT EVIDENCE. Five bills in ten members contradicted their own titles

- `Beyond The Choice Act` (H422) — veterans' tuition, not abortion
- `Expedited Removal of Unauthorized Persons` (H96) — amends the trespass statutes; squatters, not immigration
- `Energy Security Act of 2025` (H73) — physical security at electrical substations
- `Save the American Dream Act` (H765) — a local development-regulation omnibus
- `Limit Use of AI Medicaid/Commercial Insurance` (H565) — the text returned an organ-donor tax provision

**Cross-check by sponsor list.** When a bill's text and its title disagree, compare the sponsors on
the text page against the sponsors on the lookup page. If they match, the text is the right bill and
the title is just branding (H765). If it cannot be resolved, leave the spoke blank — H565 would have
been the campaign's only `ai-regulation` row and it is not worth seating on a self-contradicting
source.

### 🔴 Fourth ladder defect: voting-rights is asymmetric

Tyson is primary sponsor of House Bill 66, which shortens early voting by about a week. Chair 2
explicitly names *expanding* early voting periods, but **no chair names reducing them** — the
restrictive chairs are about photo ID, voter-roll maintenance and mail-in voting, none of which the
bill touches. So the ladder will seat members who expand early voting and blank members who restrict
it, on the same axis. That is a coverage bias built into the scale, and it belongs in the ADR 0004
revision queue with the `medicare/aid` and `same-sex-marriage` scope defects.
