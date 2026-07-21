---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 17
state: ALL-17
status: complete
completed: 2026-07-07
requirements: [USHC3-02, USHC3-03, USHC3-04, USHC3-05]
---

# 165-17 SUMMARY — Consolidated 34-district gate GREEN

## What was built
`165-verify.sql` (15 criteria, read-only, all PASS on prod) + `165-coordinate-smoke.ts` (17/17 positive samples GREEN on prod). The phase's full scope — 34 districts across 17 states — is proven end-to-end.

## Gate results (2026-07-07, prod)
- **SCOPE:** NV 4 + UT 4 + NM 3 + NE 3 + WV 2 + ID 2 + HI 2 + ME 2 + NH 2 + RI 2 + MT 2 + AK 1 + DE 1 + ND 1 + SD 1 + VT 1 + WY 1 = **34 races** ✅
- **NULLOFFICE / NULLPID / DUPNAME / PARTY:** all 0 ✅
- **NV-RECONCILE:** 4 pre-existing UUIDs reused, 0 new NV election/race, Chapman rc 08dfb911 pid NOT NULL, 5 new + Chapman ids present ✅
- **ME-RECONCILE:** d92aa73a + aa63d55d exactly 2 active each, 0 new ME election/race ✅
- **UT-REKEY:** FIPS-49 offices md5 = `4d8bbfb221d4babca6e9f7201bce391e` (byte-identical to the 165-02 pre-migration baseline); Moore→4902 / Maloy→4903 / Kennedy→4904 is_incumbent=true; Owens 0 active rows ✅
- **AK-FIELD:** 1 jungle race, exactly 15 active, primary_party NULL ✅
- **PROVISIONAL:** AK/HI/NH/RI/DE/VT/WY 10 races marked; NM/NE/WV/ID/MT/ND/SD 13 races not ✅
- **COLLISION-BAND:** all 14 D-04 floors honored (NV-1≥74, NV-2≥51, NV-4≥79, ME≥3, NM 26/51/82, NE-3≥60, NH-1≥33, MT-2≥85, AK≥5, DE≥48, VT≥6) ✅
- **HEADSHOT:** 117 banded challengers = 8 uploaded + 109 pinned honest-skips ✅
- **UNSOURCED:** 0 (race-scoped — the Trevor Lee polluted-band legacy rows correctly excluded) ✅
- **COVERAGE:** all banded new candidates ≥1 stance or pinned (18 stance-skip pins) ✅
- **UUID-COVERAGE (extra block):** Pingree + McAdams/Crosby/Udell/Larsen/Gray/Jackley all ≥1 stance ✅
- **Coordinate smoke:** 17/17 states surface the correct single House race with challenger-inclusive fields, 0 NULL pids; **UT sample resolves via pinned G5200V26 boundaries** on 'UT 2026 Statewide General'; NV/ME on their pre-existing election names ✅

## STANDING for Phase 166 (consolidated gate MUST inherit)
- **NV-RECONCILE + ME-RECONCILE** (0 new NV/ME elections; the 6 reused race UUIDs; Chapman pid NOT NULL)
- **UT-REKEY** (FIPS-49 offices NOTOUCH md5 `4d8bbfb221d4babca6e9f7201bce391e`; incumbent placement 4902/4903/4904; Owens 0 rows) — until the Jan-2027 promotion phase re-keys offices (spec ≥ 2027-01-03)
- 18 stance-skip pins + 109 headshot pins (this file + 165-verify.sql are the canonical pin lists)

## Phase-scope note
Phase 165 closes the milestone's seeding scope: Phases 161–165 = all 178 v2.22 Wave-3 districts seeded, stanced (0 unsourced), and gated. Ready for /gsd-verify-work.

## Self-Check: PASSED
165-verify.sql exit 0, all 15 criteria PASS; 165-coordinate-smoke.ts 17/17 GREEN.
