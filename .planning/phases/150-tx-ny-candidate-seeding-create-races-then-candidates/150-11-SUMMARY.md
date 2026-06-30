# 150-11 SUMMARY — NY new-candidate federal-24 stances (Playwright/PDF-verified)

**Status:** ✅ Complete — **NY stance workstream complete; full 150-verify.sql gate ALL-PASS**
**Wave:** 3 (executed inline per operator pacing decision)
**Requirement:** USHC-05 (NY slice)

## In-scope set: 33 NEW NY candidates only (D-01 asymmetry honored)

The 25 NY partial incumbents + NY-14 AOC were **NOT touched** (D-01 — they keep existing partial
coverage; deferred to a later sweep). Live diagnostic confirmed all 33 new candidates at 0 federal
stances. **18 stanced (84 stances, 0 unsourced) + 15 whole-record honest-skips.** Pushed via
`_push_uuid.ts` (all new → UUID path); 0 surname leaks, 0 quotes (values+reasoning+sources only).
Verified: the 15 skip pids carry 0 stance rows (untouched, party-inference refused).

### Stanced (18) — 84 stances
| pid | candidate | n | notes |
|-----|-----------|---|------|
| -3611201 | **Micah Lasher (D, NY-12)** | 15 | most comprehensive — full platform page (taxes2/childcare2/housing2/deport1/imm2/voting2/campaign-fin2/civil2/health1/medicare1/abortion2/climate2/fossil2/ssm1/ai4) |
| -3611301 | Darializa Avila Chevalier (D, NY-13) | 10 | progressive Day-1 Agenda: housing1/climate2/fossil2/imm2/deport1/childcare1/ss1/medicare1/health1/taxes1 |
| -3610701 | Claire Valdez (D, NY-7) | 8 | DSA: housing1/health1/medicare1/taxes1/deport1/imm2/climate2/fossil2 |
| -3611701 | Cait Conley (D, NY-17) | 7 | school-vouchers1/climate3/housing3/tariffs2/health2/medicare3/abortion2 |
| -3611001 | Brad Lander (D, NY-10) | 6 | blocked ICE→deport1; imm2/housing2/homeless2/health1/medicare1 (M4A) |
| -3610301 | Mike LiPetri (R, NY-3) | 5 | taxes4/imm4/deport4/health4/trans4 |
| -3612102 | Blake Gendebien (D, NY-21) | 5 | moderate: health3/medicare3/imm3/deport2/ai3 |
| -3610401 | Jeanine Driscoll (R, NY-4) | 2 | taxes4/imm4 |
| -3610201 | Patrick Halpin (D, NY-2) | 1 | health2 (ACA) |
| -3610901 | Joel Anabilah-Azumah (R, NY-9) | 3 | ai4/ukraine4/misinfo4 (libertarian) |
| -3611601 | Joseph Cinquemani (R, NY-16) | 4 | taxes4/fossil4 (drill baby drill)/health4/ukraine4 |
| -3611901 | Peter Oberacker (R, NY-19) | 1 | taxes4 (WAMC-quoted; site is signup splash) |
| -3612101 | Anthony Constantino (R, NY-21) | 3 | imm4/health4/misinfo4 |
| -3612201 | **Kailee Buller (D, NY-22)** | 4 | **chairs-not-polarity**: a Democrat at climate4/fossil4 (repeal climate mandates, all-of-above) + childcare3/housing4 |
| -3612401 | Alissa Ellman (D, NY-24) | 4 | campaign-fin2/redistrict1/health1/medicare1 |
| -3612501 | Virginia McIntyre (R, NY-25) | 1 | taxes4 |
| -3612601 | Dennis Hannon (R, NY-26) | 4 | imm4/taxes4/medicare3/fossil4 |
| -3610702 | Melvin Rivera (D, NY-7) | 1 | housing3 (TOPA tenant-purchase) |

## Honest-skips (15, pinned for the gate)
Obscure challengers in safe seats + thin minor-line candidates (D-02). No completed CC survey, no
Ballotpedia campaign-website quote, and no campaign-site issues content (only social-media pages or
signup splash); **party-inference refused**. **All 15 pinned by exact UUID in `_stance_skip` of
`scripts/150-verify.sql` (WITH ORDER BY, 143 lesson):**
- Gallant NY-1 (-3610101), Marsh NY-5 (-3610501), Chou NY-6 (-3610601), Mizrahi NY-8 (-3610801),
  Moore NY-10 (-3611002), DeCillis NY-11 (-3611101), Shinkle NY-12 (-3611202), Williams NY-13
  (-3611302), Cohen NY-13 WF (-3611303), Hysenaj NY-14 (-3611401), Sapaskis NY-15 (-3611501),
  Auringer NY-18 (-3611801), Ambrosio NY-20 (-3612001), Smullen NY-21 Conservative (-3612103),
  Gies NY-23 (-3612301).
- **Per-topic skips** pervasive (chairs-not-polarity): e.g. Lander/Valdez foreign-policy sections are
  anti-militarism re: Israel/Gaza/Iran, not a clean Ukraine chair → ukraine skipped; Lasher's
  mid-decade-redistricting tit-for-tat is not an independent-commission chair → redistricting skipped.

## Verification
- **Rows deleted in primary-source pass: 0** — values mapped conservatively from live-fetched sources
  at write time (Ballotpedia Candidate Connection / campaign-quote blocks + candidate campaign-site
  issue/platform pages via Playwright; Allred-style PDF reads where applicable). No over-reads created.
- Merge/repair: `_merge_validate.mjs` (149 pipeline, UUID-keyed variant) — 18 CSVs → 84 rows, 0 issues, 0 dup.
- **Full `scripts/150-verify.sql` gate ALL 11 assertions PASS, psql exit 0** (USHC-02/03/04/05 + D-01/02/03/05):
  USHC-05a 0 unsourced; USHC-05b every in-scope candidate stanced or pinned; D-01 confirmed (15 skip
  pids = 0 stance rows; NY partial incumbents + AOC untouched).
- **Notable:** Kailee Buller (D, NY-22) at climate4/fossil4 — a Democrat correctly mapped from her
  actual anti-climate-mandate / all-of-the-above energy platform, never inferred from party.

## Files
- `backend/data/stance-research/ny-2026-house/` — 18 per-candidate CSVs + `ny-batch.csv` (merged) +
  `_merge_validate.mjs` (gitignored scratch; DB is source of truth).
- `backend/scripts/150-verify.sql` — 15 NY honest-skips pinned in `_stance_skip` (150-11 block).

## Phase 150 stance workstream — COMPLETE
TX (150-07..10, all 76 active TX candidates) + NY (150-11, all 33 new NY candidates) done.
**NEXT: 150-12 (Wave 4 coordinate gate)** — final phase-completion verification (the full gate already
passes here; 150-12 wraps coordinate/feed smoke-tests + phase close).
