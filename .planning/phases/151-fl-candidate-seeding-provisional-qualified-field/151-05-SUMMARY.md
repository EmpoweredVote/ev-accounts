---
phase: 151-fl-candidate-seeding-provisional-qualified-field
plan: 05
wave: 3
status: complete
requirements: [USHC-05]
---

# 151-05 SUMMARY — federal-24 stances for the 17 FL independents

## Outcome
All 17 independent/NPA new candidates researched via `politician-stance-researcher` agents (≤3 concurrent, 6 waves). **6 stanced (36 sourced answers, 0 unsourced) + 11 whole-record honest-skips** (pinned by UUID in `_stance_skip`). Full `151-verify.sql` gate now **PASSES all assertions, exit 0**.

## Stanced (6 candidates, 36 answers — all from real fetched campaign URLs)
| Candidate | Dist | topics | source |
|-----------|------|--------|--------|
| Tony D'Arrigo | FL-13 | 8 (healthcare2, medicare2, social-security2, taxes3, campaign-finance2, fossil-fuels3, climate3, housing3) | tonydarrigo.com |
| Alec Pavlik | FL-6 | 8 (abortion4, taxes5, social-security5, deportation2, immigration3, misinformation5, ssm3, religious4) | alecpavlik.com |
| Mark Davis | FL-16 | 7 (healthcare1, abortion2, tariffs1, taxes1, immigration2, civil-rights2, school-vouchers1) | markdavisforcongress.com |
| Mike Klein | FL-3 | 6 (campaign-finance2, redistricting2, social-security2, deportation2, immigration2, healthcare2) | mikeklein4congress.com |
| Eddy Rojas | FL-28 | 4 (taxes4, school-vouchers4, healthcare3, medicare3) | eddyrojas.com |
| Deva Simmons | FL-18 | 3 (healthcare2, school-vouchers1, redistricting2) | devasimmons.com |

Per-topic honest-skips left absent (no documented position), per [[project-149-stance-gate-standard]] — full-24 NOT required.

## Whole-record honest-skips (11, pinned by UUID in `_stance_skip`)
Tyler Davis FL-1, Todd Schaefer FL-4, Andrew Parrott FL-6, Branden Scrivener FL-12, Michael Quirk FL-17, Seth Haskins FL-19, Alexander Cooke FL-21, Kedner MaximeDe FL-20, Andy Daro FL-24, Patricia Gonzalez FL-24, Deborah Ann Meidinger Hosey FL-26. All genuinely no-record: campaign site with no issues page / FEC filing only / bare landing page; no Ballotpedia, Vote411, localcandidates, or news coverage of positions. NEVER inferred from NPA status (chairs-not-polarity).

## Quotes WITHHELD (149 precedent)
Pushed **values + reasoning + sources only**; quote columns blanked before push. No verbatim Read&Rank verification pass was run, so quotes are deferred (matches Phase 149, where agent quote strings were only ~60% verbatim-locatable). All 36 answers still satisfy USHC-05a (every answer paired to a `politician_context` row with non-empty `sources[]`).

## Verification
- Push: `_push_uuid.ts` → 36 answers, 36 contexts, 0 quotes, 0 surname-leaks.
- Full gate `151-verify.sql`: **ALL ASSERTIONS PASSED, exit 0** (USHC-02/03/04/05 + D-01..D-05).
- 27 incumbents + 138 partisan new candidates NOT touched (D-01).

## Artifacts
- `backend/data/stance-research/fl-2026-house-indep/` — 17 per-candidate CSVs + `_merged_push.csv` + `_RESEARCH_INSTRUCTIONS.md` + `_TOPIC_SCALE_FULL.txt`.
- `151-verify.sql` `_stance_skip` pin set (11 UUIDs, ORDER BY).

## Session note
Wave 5 (MaximeDe/Cooke/Daro) hit a session limit mid-run; Cooke's skip CSV had already landed, the other two were re-dispatched and completed. No data lost.
