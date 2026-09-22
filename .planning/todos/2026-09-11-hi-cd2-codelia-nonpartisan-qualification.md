# HI CD-2 — Edward A. Codelia, nonpartisan qualification unresolved

**Opened:** 2026-09-11 (during the HI 2026 primary certification pass, migration 1853)
**Re-enter:** on/after **2026-09-25**. `provisional_until` on the row is 2026-09-25 — that is the
date the row goes stale and the Elections read path starts flagging it, not a date anything is
expected to happen.

## The question

Hawaii's 2026 Primary (2026-08-08), U.S. Representative Dist II. Certified totals:

| | candidate | party | votes |
|---|---|---|---|
| | TOKUDA, Jill N. | D | 92,075 |
| | AWA, Brenton | R | 26,290 |
| | **CODELIA, Edward A.** | **N** | **1,230** |
| | TERRY, Randall | N | 738 |
| | KING, Steven | D | 3,917 |
| | GUITHUES, Greg | D | 3,160 |
| | BASIN, Kirill | D | 1,530 |

Total cast for the office: **128,940**.

HRS §12-41(b), as stated in the Office of Elections' own Candidate's Manual 2026 Elections (p.18),
qualifies a nonpartisan for the general ballot if they either

- receive at least **10% of the votes cast for the office**, or
- receive a vote **equal to or greater than the lowest vote received by a partisan candidate who
  was nominated**.

Codelia fails the second prong outright: 1,230 < 26,290 (Awa, the lowest nominated partisan).
The first prong depends on what "the votes cast for the office" counts:

- **all party contests for the office** — 1,230 / 128,940 = **0.95%**, and Codelia is OUT;
- **the nonpartisan contest alone** — 1,230 / 1,968 = **62.5%**, and Codelia is IN.

🔴 **No State of Hawaii document consulted settles the denominator.** The Statewide Summary prints
percentages *within* each party contest (Codelia 16.9%), which is a presentation choice about that
report, not a reading of the statute. The Statement of Vote marks no winners.

## Why the row was held rather than culled

The broad reading is the coherent one — under the narrow reading almost any nonpartisan clears 10%
and the second prong would never be needed — but the cost is asymmetric. Holding a candidate who is
really out shows one extra name, flagged provisional, for a few weeks. Culling a candidate who is
really in removes a real person from a voter's ballot view seven weeks before the election. Same
principle as WA LD 42 in migration 1842: a cut line that is not settled is not a settled field.

## How to close it

1. **Best:** Hawaii's published general-election ballot or certified general-election candidate
   list. It is the state saying who is on the ballot, and it ends the argument. Not yet published
   at elections.hawaii.gov as of 2026-09-11.
2. Failing that, ask the Office of Elections directly (elections@hawaii.gov, 808-453-VOTE) how
   §12-41(b)'s 10% denominator is computed, and record the answer here verbatim.
3. Then either set `result = 'advanced'` (with the ballot list cited) or `result = 'not_nominated'`
   (with the state's own statement of the rule cited), and clear `provisional_until`.

⚠ **Randall Terry is NOT the same case and was already culled in 1853.** He is out under *both*
readings: he fails the second prong, and under the narrow reading Codelia's 1,230 beats his 738 for
the single nonpartisan slot the manual allows when there is one seat available.
