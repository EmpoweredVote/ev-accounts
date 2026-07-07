# 157-05 SUMMARY — NJ new-candidate federal-24 stances

**Status:** COMPLETE ✅
**Requirement:** USHC2-05

## What was built
- `backend/data/stance-research/nj-2026-house/` — 15 per-candidate CSVs (federal-24, chairs-not-polarity, evidence-only).
- Pushed via `_push_relaxed.ts` (UUID-keyed, 0-unsourced enforced): **80 answers + 80 contexts across 11 pids**.

## Coverage (11 stanced / 4 whole-record skip)
| candidate | district | topics | basis |
|-----------|----------|--------|-------|
| Rebecca Bennett | NJ-7 | 16 | own campaign priorities pages |
| Steven Welzer | NJ-3 (Green) | 20 | Green Party platform he runs on as official nominee + lifelong GP leader (documented basis) |
| Joe Hathaway | NJ-11 | 11 | own platform + NJ-11 debate coverage |
| Zack Mullock | NJ-2 | 10 | own campaign issues page |
| Adam Hamawy | NJ-12 | 7 | endorsement coverage + own M4A quote |
| Sean Kirrane | NJ-5 | 6 | own campaign platform |
| Rachel Peace | NJ-4 | 4 | endorsement orgs + platform |
| Hillary Herzig | NJ-6 | 2 | own campaign platform |
| Rosie Pino | NJ-9 | 2 | own Immigrant Trust Act vote/quote (verified below) |
| Carmen Bucco | NJ-10 | 1 | own campaign issues page |
| Gregg Mele | NJ-12 | 1 | American Promise pledge |

## Whole-record honest-skips (4) — pinned in `157-verify.sql` `_stance_skip` (ORDER BY politician_id)
- Ryan Michael Kelly (3fa31dfc-…) NJ-3 — party-line name, no platform.
- Damon Galdo (a339de8c-…) NJ-1 — sites down, empty Ballotpedia, no policy coverage.
- Michael McGuire (ce32b48e-…) NJ-3 — site under construction, only vague themes.
- Adam Rueda (ceb5cd67-…) NJ-5 — no site, no coverage, party-line name only.

## Verification pass (D-06, before push)
- **Rosie Pino misattribution risk CLEARED:** WebFetch of the NJ Globe source confirmed the Immigrant Trust Act vote + "no one…regardless of legal status should live in fear" quote are genuinely Pino's own (she is a Clifton City Councilwoman). chairs-not-polarity → scored the evidence (immigration=3/deportation=3), not the party.
- **Welzer basis documented:** 20 stances sourced from the Green Party platform he runs on as the official GP nominee + his documented career as a GP movement leader (not lazy party-inference). Agent disciplined-skipped 4 topics where the platform was silent/uncertain.
- All 80 rows parse cleanly (relax-parse), valid values 1–5, source_url_1 present on every row, 0 no-source rows skipped.

## Gate result
- USHC2-05a (0 unsourced) + USHC2-05b (≥1 sourced OR pinned skip): **PASS**. Full gate all 11 assertions GREEN.
- D-01 honored: all 12 NJ partial incumbents untouched; NO incumbent in the in-scope set (NJ has no zero-stance incumbent).
