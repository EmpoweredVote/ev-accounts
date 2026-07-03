# 150-09 SUMMARY — TX-21..30 federal-24 stances (Playwright-verified)

**Status:** ✅ Complete
**Wave:** 3 (executed inline per operator pacing decision)
**Requirement:** USHC-05 (TX batch 3 of 4)

## In-scope set: 20 candidates (7 active incumbents + 13 new challengers)

Chip Roy (TX-21, retired) & Jasmine Crockett (TX-30, redistricted away) have no active row → out of
scope; TX-23 is an open-seat vacancy. **0 unsourced** for all 20 pids (USHC-05a slice PASS).
19 stanced + 1 whole-record honest-skip. **78 new stances pushed** (`_push.ts`, 0 surname leaks).

### Incumbents (7) — 29 stances
| pid | incumbent | n | notes |
|-----|-----------|---|------|
| -100322 | Troy Nehls (R) | 4 | Key votes: all 4 Yea (deport/voting/trans/taxes=4) |
| -100324 | Beth Van Duyne (R) | 4 | all 4 Yea |
| -100325 | Roger Williams (R) | 3 | **Not Voting on Laken Riley** → deportation skipped; voting/trans/taxes=4 |
| -100326 | Brandon Gill (R) | 4 | all 4 Yea |
| -100327 | Michael Cloud (R) | 4 | all 4 Yea |
| -100328 | **Henry Cuellar (D)** | 3 | **chairs-not-polarity payoff** — a Democrat who voted Yea on Laken Riley, SAVE Act, and Women-in-Sports → deportation4/voting4/trans4; taxes Nay → skipped |
| -100329 | Sylvia Garcia (D) | 7 | house.gov issues: immigration2/deportation2 (Dream & Promise Act), healthcare2/medicare2, abortion2 (WHPA cosponsor), climate3 (IRA), civil-rights2 |

### New challengers (13) — 49 stances
| pid | candidate | n | topics |
|-----|-----------|---|--------|
| -4812101 | Mark Teixeira (R) | 7 | immigration4, deportation4, taxes4, fossil4, religious4, civil-rights4, voting4 |
| -4812102 | Kristin Hook (D) | 8 | healthcare2, medicare2, social-security2, taxes1, childcare2, housing2, abortion2, civil-rights2 |
| -4812201 | Marquette Greene-Scott (D) | 2 | healthcare1, immigration2 |
| -4812301 | Brandon Herrera (R) | 2 | immigration4, taxes4 |
| -4812302 | Katy Padilla Stout (D) | 7 | healthcare1, medicare1, abortion2, immigration2, climate2, taxes2, voting2 |
| -4812401 | Kevin Burge (D) | 4 | tariffs2, healthcare2, childcare2, immigration2 |
| -4812501 | Dione Sims (D) | 4 | immigration2, civil-rights2, voting2, healthcare2 |
| -4812601 | Steven Shook (D) | 1 | healthcare2 (rest = public-safety/accountability) |
| -4812701 | Tanya Lloyd (D) | 4 | school-vouchers1, healthcare2, childcare2, abortion2 |
| -4812801 | Tano Tijerina (R) | 3 | immigration4, taxes4, ai2 |
| -4813001 | Frederick Haynes III (D) | 4 | healthcare1, medicare1 (M4A), deportation1 (abolish ICE), immigration2 (Texas Tribune) |
| -4813002 | Everett Jackson (R) | 3 | religious4, taxes4, fossil4 |

## Honest-skips (pinned for the gate)
- **Whole-record:** Martha Fierro -4812901 (TX-29, R) — no completed Candidate Connection survey, no
  Ballotpedia campaign quote, only social-media pages (no issues content); party-inference refused.
  **Pinned by UUID `96721078-0aed-4414-86df-d6c26f755646` in `_stance_skip`** of `scripts/150-verify.sql`
  (joins Prince -4810101 and Whitfield -4811801).
- **Per-topic:** Roger Williams deportation (Not Voting on Laken Riley); Cuellar taxes (Nay); same-sex-marriage
  and abortion skipped on ambiguous slogans (Teixeira "Protect the unborn"); pervasive elsewhere.

## Verification
- Rows deleted in primary-source pass: **0** (values mapped conservatively at write time).
- Merge/repair: `_merge_validate.mjs` (149 pipeline) — 15 CSVs → 78 rows, 0 issues, 0 dup.
- Gate slice: 0 unsourced for all 20 TX-21..30 pids.
- **Notable:** Cuellar's three cross-party Yea votes (deportation/voting/trans=4) are the strongest
  chairs-not-polarity demonstration so far — a Democrat correctly mapped to value 4 from his actual
  roll-call record, never inferred from party.

## Files
- `backend/data/stance-research/tx-2026-house-b3/` — 15 per-candidate CSVs + `tx-b3-batch.csv` + `_merge_validate.mjs` (gitignored scratch).
- `backend/scripts/150-verify.sql` — Fierro pinned in `_stance_skip`.

## Remaining in Wave 3
150-10 (TX-31..38, incl. Casar + Barrios top-up), 150-11 (NY new 33). Then 150-12 (Wave 4 coordinate gate).
