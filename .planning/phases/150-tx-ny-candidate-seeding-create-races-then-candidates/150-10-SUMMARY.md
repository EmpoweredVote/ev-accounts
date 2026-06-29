# 150-10 SUMMARY — TX-31..38 federal-24 stances (Playwright/PDF-verified)

**Status:** ✅ Complete — **TX stance workstream complete (batch 4 of 4)**
**Wave:** 3 (executed inline per operator pacing decision)
**Requirement:** USHC-05 (TX batch 4 of 4)

## In-scope set: 16 candidates (4 incumbents + 11 new challengers + Barrios UUID top-up)

Live diagnostic (federal-24 count < 24) confirmed all 15 external_id pids at 0 federal stances;
Dan Barrios (UUID `e8c863a7`) already carried 3 federal stances (housing3/homelessness2/civil-rights2,
all sourced — USHC-05a already satisfied) + topped up. **0 unsourced** for all 16 pids (USHC-05a slice
PASS). **15 stanced + 1 whole-record honest-skip. 72 new stances pushed** (71 via `_push.ts` external_id
path, 1 via `_push_uuid.ts` for Barrios; 0 surname leaks, 0 quotes — values+reasoning+sources only).

### Incumbents (4) — 24 stances
| pid | incumbent | n | notes |
|-----|-----------|---|------|
| -100331 | John Carter (R, TX-31) | 4 | Ballotpedia Key votes all Yea → deport4/voting4/trans4/taxes4 |
| -100334 | **Vicente Gonzalez (D, TX-34)** | 6 | **chairs-not-polarity payoff** — Yea on Laken Riley→deport4 & Women-in-Sports→trans4; house.gov: healthcare2/medicare2, fossil3 (chairs Oil&Gas Caucus), tariffs2 (NAFTA/USMCA free-trade) |
| -100335 | **Greg Casar (D, TX-37)** | 10 | reused -100335 (zero-stance incumbent); all Key votes Nay → used casar.house.gov issue pages: healthcare1/medicare1 (M4A), immigration2/deport2 (Dream&Promise/New Way Forward), abortion2 (WHPA), housing1 (GND for Public Housing), climate2 (GND), voting2 (JLVRAA), social-security1 (SS Expansion Act), civil-rights2 (Equality Act) |
| -100336 | Brian Babin (R, TX-36) | 4 | Key votes all Yea → deport4/voting4/trans4/taxes4 |

### New challengers (10 stanced) — 47 stances
| pid | candidate | n | topics |
|-----|-----------|---|--------|
| -4813301 | **Colin Allred (D, TX-33)** | 11 | from 3 primary campaign PDFs (immigration/affordability/anti-corruption): immigration1 + deport1 (abolish ICE), tariffs2, social-security1, childcare2, housing3, medicare3, taxes2, campaign-finance2, redistricting1, voting1 |
| -4813201 | Jace Yarbrough (R, TX-32) | 7 | deport5 (mass deportation), immigration4, fossil4, climate5, abortion4, trans4, voting4 |
| -4813802 | Melissa McDonough (D, TX-38) | 7 | tariffs2, school-vouchers1, voting2, healthcare2, climate3, fossil3, civil-rights2 |
| -4813101 | Justin Early (D, TX-31) | 6 | taxes2, healthcare2, social-security1, school-vouchers1, ai4 (ban high-risk AI), civil-rights2 |
| -4813501 | Johnny Garcia (D, TX-35) | 5 | tariffs2, healthcare2, medicare2 (expand Medicaid), immigration2, deport2 (refocus ICE on serious criminals) |
| -4813302 | Patrick Gillespie (R, TX-33) | 3 | immigration4, climate5 (exit Paris), voting4 |
| -4813502 | Carlos De La Cruz (R, TX-35) | 2 | immigration3 (welcome legal + secure border), tariffs4 (stop China) |
| -4813801 | Jon Bonck (R, TX-38) | 4 | immigration4 (finish wall), abortion5 ("Life begins at conception. No compromise"), religious-freedom4, ukraine4 |
| -4813601 | Rhonda Hart (D, TX-36) | 1 | abortion2 (codify Roe) — site has only Gun Safety/Veterans/Healthcare; only abortion maps |
| -4813701 | Lauren Peña (R, TX-37) | 1 | immigration3 — CC survey is welfare/policing/national-security focused |

### Reuse by UUID — Barrios top-up
| pid | candidate | added | now |
|-----|-----------|-------|-----|
| e8c863a7 | Dan Barrios (D, TX-32) | healthcare2 (CC survey "expanding access to affordable, quality medical care") | 5 federal (housing3/homelessness2/civil-rights2 prior + healthcare2); pushed via `_push_uuid.ts` |

## Honest-skips (pinned for the gate)
- **Whole-record:** **Eric Flores -4813401 (TX-34, R)** — campaign site (ericflores.com/priorities + /abouteric)
  and Ballotpedia carry only bullet-point slogans ("SECURE THE BORDER", "ENERGY INDEPENDENCE", "SAFEGUARD
  SENIORS' BENEFITS") with no chair-pinning specifics; no Candidate Connection survey; party-inference
  refused. **Pinned by UUID `66e11441-bc75-4d06-b5b3-d371463abef4` in `_stance_skip`** of
  `scripts/150-verify.sql` (WITH ORDER BY, 143 lesson; joins Prince/Whitfield/Fierro).
- **Per-topic:** pervasive and expected (chairs-not-polarity) — e.g. Carter/Babin's 20 non-roll-call
  federal topics; Gonzalez SAVE/reconciliation Nay → voting/taxes skipped (Nay pins no chair); Casar all
  Key votes Nay → roll-call skipped, issues-page positions used instead; Yarbrough's economy sections had
  site copy-paste errors → tariffs/taxes skipped; Hart/Peña single-issue records.

## Verification
- **Rows deleted in primary-source pass: 0** — every value mapped conservatively from a live-fetched
  source at write time (Allred read from 3 campaign PDFs directly; all others from Ballotpedia
  "Key votes"/Candidate Connection/campaign-quote blocks or house.gov issue pages via Playwright). No
  speculative rows created → no over-reads to delete.
- Merge/repair: `_merge_validate.mjs` (149 relax-parse + canonical re-stringify + source_url_1 guard) —
  14 CSVs → 71 rows, 0 issues, 0 dup. Barrios UUID CSV (`_barrios-tx32-uuid.csv`) excluded from merge by
  leading-underscore (different `politician_id` contract) and pushed separately.
- Gate slice: **0 unsourced** for all 16 in-scope pids; all 15 stanced carry ≥1 federal stance; Flores
  pinned in `_stance_skip`. (Full `150-verify.sql` is deferred to the 150-12 coordinate gate — it spans
  TX+NY and would false-fail until NY is seeded in 150-11.)
- **Notable:** Vicente Gonzalez (D) at deport4/trans4/fossil3 — a Democrat correctly mapped from his
  actual roll-call record + Oil&Gas-Caucus chairmanship, never inferred from party (continues the b3
  Cuellar chairs-not-polarity demonstration). Allred fully sourced from his own published policy PDFs.

## Files
- `backend/data/stance-research/tx-2026-house-b4/` — 14 per-candidate CSVs + `_barrios-tx32-uuid.csv` +
  `tx-b4-batch.csv` (merged) + `_merge_validate.mjs` (gitignored scratch; DB is source of truth).
- `backend/scripts/150-verify.sql` — Eric Flores pinned in `_stance_skip` (150-10 block).

## TX stance workstream — COMPLETE
150-07 (TX-1..10) + 150-08 (TX-11..20) + 150-09 (TX-21..30) + 150-10 (TX-31..38) all done. All 76 active
TX candidates resolved: stanced (federal-24 or per-topic honest-skip) or whole-record honest-skip
(Prince/Whitfield/Fierro/Flores, 4 total pinned). **Remaining in Wave 3: 150-11 (NY new 33).** Then
150-12 (Wave 4 coordinate gate — runs full 150-verify.sql once NY is seeded).
