# 155-08 SUMMARY — IL new-candidate stances

**Status:** ✅ Complete · **Date:** 2026-06-30 · **Requirement:** USHC2-05 (IL slice)

## What was done
Researched federal-24 chairs-not-polarity, evidence-only stances for the 28 new IL candidates via `politician-stance-researcher` agents (≤3 concurrent; obscure challengers batched ~5-6/agent). Pushed via `_push_relaxed.ts` (0-unsourced enforced). IL partial incumbents untouched (D-01).

## Result — 13 covered / 15 whole-record skips (of 28 new IL candidates); 83 stance rows
| Candidate | District | Topics |
|---|---|---|
| Daniel Biss | IL-9 | 18 |
| Melissa Bean | IL-8 | 18 |
| La Shawn Ford | IL-7 | 8 |
| Paul Nolley | IL-16 | 7 |
| Niki Conforti | IL-6 | 6 |
| Lupe Castillo | IL-4 | 5 |
| Byron Sigcho-Lopez | IL-4 | 5 |
| Tommy Hanson | IL-5 | 5 |
| John Elleson | IL-9 | 4 |
| Donna Miller | IL-2 | 3 |
| Ed Hershey | IL-4 | 2 |
| Angel Oakley | IL-3 | 1 |
| Dillan Vancil | IL-17 | 1 |

## Whole-record honest-skips (15, pinned by UUID in 155-verify.sql `_stance_skip`)
Patty Garcia (IL-4), Christian Maxwell (IL-1), Mike Noack (IL-2), Ashley Banks (IL-2), Lindsay Church (IL-4), Chris Getty (IL-4), Mayra Macías (IL-4), Chad Koppie (IL-7), Jennifer Davis (IL-8), Carl Lambrecht (IL-10), Jeff Walter (IL-11), Julie Fortier (IL-12), Jeff Wilson (IL-13), James Marter (IL-14), Jennifer Todd (IL-15). Reason: obscure candidates — dead/JS-walled campaign sites, empty Ballotpedia, 403/404/429 news; party-inference refused.

## Integrity + notable chairs-not-polarity calls
- 0 unsourced rows. Melissa Bean **taxes=4** (documented Blue Dog record — 0% CTJ rating — despite being a Democrat). Castillo (R) scored 4s from explicit quotes; Hershey (Working Class Party) scored immigration=1/taxes=1 from platform. Agents self-dropped inference-only rows (e.g. Vancil school-vouchers, Nolley fossil-fuels).
- IL-4's 7-way general is genuine (independents petition directly onto the IL general ballot) — confirmed in 155-04.
