# 150-08 SUMMARY — TX-11..20 federal-24 stances (Playwright-verified)

**Status:** ✅ Complete
**Wave:** 3 (executed inline per operator pacing decision)
**Requirement:** USHC-05 (TX batch 2 of 4)

## In-scope set: 20 candidates (9 active incumbents + 11 new challengers)

Arrington (-100319, TX-19) retired → no active row → out of scope. **0 unsourced** for all 20 pids
(USHC-05a slice PASS). 19 stanced + 1 whole-record honest-skip. **76 new stances pushed**
(`_push.ts`, external_id path, 0 surname leaks).

### Incumbents (9) — 41 stances
| pid | incumbent | n | method / topics |
|-----|-----------|---|------|
| -100311 | August Pfluger (R) | 4 | Ballotpedia Key votes (all 4 Yea): deportation4, voting4, trans4, taxes4 |
| -100312 | Craig Goldman (R) | 4 | same 4 Yea |
| -100313 | Ronny Jackson (R) | 4 | same 4 Yea |
| -100314 | Randy Weber (R) | 4 | same 4 Yea |
| -100315 | Monica De La Cruz (R) | 3 | deportation4, trans4, taxes4 — **Not Voting on SAVE Act** → voting-rights honest-skipped (verified individually, not assumed party-line) |
| -100317 | Pete Sessions (R) | 4 | same 4 Yea |
| -100316 | Veronica Escobar (D) | 7 | house.gov issues: immigration2 (Dignity Act), healthcare2 + medicare3 (IRA), civil-rights2 + voting2 (Equality Act / John Lewis VRA), **same-sex-marriage1 (Respect for Marriage Act — real bill, not general-LGBTQ)**, climate3 (IRA) |
| -100318 | Christian Menefee (D) | 8 | Ballotpedia survey+platform: healthcare1 + medicare1 (Medicare for All), abortion2, voting2, taxes1, housing3, childcare2, social-security3 |
| -100320 | Joaquin Castro (D) | 3 | house.gov record: abortion2, healthcare2, climate3 (IRA vote) |

### New challengers (11) — 35 stances
| pid | candidate | n | topics |
|-----|-----------|---|--------|
| -4811101 | Claire Reynolds (D) | 4 | healthcare1, medicare/aid1 (M4A), abortion2, immigration2 |
| -4811201 | Angela Rodriguez Prilliman (D) | 5 | healthcare1, childcare1, taxes1, ai4, ukraine2 (campaign site helifortexas.com) |
| -4811301 | Mark Nair (D) | 4 | tariffs2, healthcare2, campaign-finance2, ai3 |
| -4811401 | Thurman Bartie (D) | 3 | healthcare2, tariffs2, immigration2 (votebartie.org) |
| -4811501 | Bobby Pulido (D) | 3 | immigration3, healthcare2, tariffs2 (moderate S-TX Dem) |
| -4811601 | Adam Bauman (R) | 1 | immigration4 (Border Patrol BORTAC; rest local property-tax) |
| -4811701 | Casey Shepard (D) | 9 | healthcare2, medicare3, housing2, immigration2, abortion2, civil-rights2, climate2, voting2, tariffs2 |
| -4811901 | Tom Sell (R) | 2 | immigration4, fossil-fuels4 (selltexastrue.com issue headings; "Protect Life" skipped — ambiguous 4-vs-5) |
| -4811902 | Kyle Rable (D) | 3 | housing2, childcare2, tariffs2 |
| -4812001 | Edgardo Baez (R) | 1 | taxes4 (smaller-government/fiscal-conservatism, Paul Ryan model) |

## Honest-skips (pinned for the gate)
- **Whole-record:** Ronald Whitfield -4811801 (TX-18, R) — no completed Candidate Connection survey,
  no Ballotpedia campaign-site quote, no campaign website surfaced in search; party-inference refused.
  **Pinned by UUID `848e2aa5-328d-47c8-9dfa-e425b60b9ca4` in `_stance_skip`** of `scripts/150-verify.sql`
  (joins Prince -4810101 from 150-07).
- **Per-topic:** De La Cruz voting-rights (Not Voting on SAVE Act); same-sex-marriage skipped on
  general-LGBTQ statements without a marriage-specific position (Shepard); abortion skipped on
  ambiguous "Protect Life" slogan (Sell); pervasive elsewhere (chairs-not-polarity).

## Verification
- Rows deleted in primary-source pass: **0** (values mapped conservatively from the fetched source at write time).
- Merge/repair: `_merge_validate.mjs` (149 relax-parse + canonical re-stringify + source_url_1 guard) — 14 CSVs → 76 rows, 0 issues, 0 dup.
- Gate slice: 0 unsourced for all 20 TX-11..20 pids.
- **Method note:** the GOP-incumbent Key-votes extractor maps cleanly only to the 4 marquee bills; Democratic incumbents required house.gov issue pages (Nay votes pin no chair). De La Cruz's "Not Voting" confirms per-candidate verification is load-bearing.

## Files
- `backend/data/stance-research/tx-2026-house-b2/` — 14 per-candidate CSVs + `tx-b2-batch.csv` + `_merge_validate.mjs` (gitignored scratch).
- `backend/scripts/150-verify.sql` — Whitfield pinned in `_stance_skip`.

## Remaining in Wave 3
150-09 (TX-21..30), 150-10 (TX-31..38 incl. Casar + Barrios top-up), 150-11 (NY new 33). Then 150-12 (Wave 4 coordinate gate).
