# 155-07 SUMMARY — PA new-candidate stances

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirement:** USHC2-05 (PA slice)

## What was done
Researched federal-24 chairs-not-polarity, evidence-only stances for the 17 new PA candidates via `politician-stance-researcher` agents (≤3 concurrent). Pushed via `data/stance-research/_push_relaxed.ts` (URL-boundary reasoning reconstruction; 0-unsourced enforced). PA partial incumbents untouched (D-01).

## Result — 7 covered / 10 whole-record skips (of 17 new PA candidates); 52 stance rows
| Candidate | District | Topics |
|---|---|---|
| Nancy Mannion | PA-11 | 12 |
| Chris Rabb | PA-3 | 9 |
| Janelle Stelson | PA-10 | 8 |
| Bob Harvie | PA-1 | 8 |
| David Alan Bradstock | PA-14 | 5 |
| Bob Brooks | PA-7 | 5 |
| Paige Cognetti | PA-8 | 5 |

## Whole-record honest-skips (10, pinned by UUID in 155-verify.sql `_stance_skip`)
Jessica Arriaga (PA-2), Aurora Stuski (PA-4), Nicholas Manganaro (PA-5), Marty Young (PA-6), Rachel Wallace (PA-9), James Hayes (PA-12), Beth Farnham (PA-13), Ray Bilger (PA-15), Justin Wagner (PA-16), Tony Guy (PA-17). Reason: obscure first-time challengers — campaign sites dead/ECONNREFUSED or JS-walled, Ballotpedia empty, local PA news 403/404/429; party-inference refused (chairs-not-polarity).

## Integrity
- 0 unsourced rows (every answer paired to `inform.politician_context` with ≥1 fetched source URL; the relaxed push drops any row lacking a real http source).
- chairs-not-polarity honored (e.g., Bradstock ai-regulation=3, Mannion school-vouchers=1 from platform text — not party-inferred).
- Malformed-CSV trap (149/150) handled by `_push_relaxed.ts` (agents emit unquoted-comma / variable-length rows).
