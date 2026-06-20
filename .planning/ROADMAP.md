# Roadmap: Empowered Accounts

## Milestones

- âœ… **v1.0 MVP** â€” Phases 1â€“8 (shipped 2026-02-28)
- âœ… **v1.1 XP & Progression** â€” Phases 9â€“11 (shipped 2026-03-04)
- âœ… **v1.2 CompassV2 Integration & Alpha Hardening** â€” Phases 12â€“16 (shipped 2026-03-07)
- âœ… **v1.3 Alpha Launch & Location Infrastructure** â€” Phases 17â€“26 (shipped 2026-03-15)
- âœ… **v1.4 Profile Hub & Verification Engine** â€” Phases 27â€“30 (shipped 2026-03-17)
- âœ… **v1.5 Partner Integration & Referrals** â€” Phases 31â€“33 (shipped 2026-03-19)
- ðŸ”„ **v1.6 Platform Consolidation** â€” Phases 34â€“43 (in progress)
- âœ… **v1.7 Cross-App SSO** â€” Phases 44â€“48 (shipped 2026-04-02)
- âœ… **v1.8 Location Identity** â€” Phases 49â€“50 (shipped 2026-04-01)
- âœ… **v1.9 Roles** â€” Phases 51â€“58 (shipped 2026-04-06)
- âœ… **v2.0 Civic Account Experience** â€” Phases 60â€“65 (shipped 2026-05-10)
- âœ… **v2.1 Inform Account Tier** â€” Phases 66â€“68 (shipped 2026-05-09)
- âœ… **v2.2 TIGER District Geofencing** â€” Phases 69â€“71 (shipped 2026-05-10)
- âœ… **v2.3 US Senate Coverage** â€” Phases 72â€“74 (shipped 2026-05-21)
- âœ… **v2.4 2026 Senate Candidates** â€” Phases 75â€“76 (shipped 2026-05-22)
- âœ… **v2.5 City Officials Expansion** â€” Phases 77â€“78 (shipped 2026-06-02; Phases 79â€“80 rolled into v2.6)
- âœ… **v2.6 Data Quality & Elections** â€” Phases 87â€“90, 99 (shipped 2026-06-05)
- âœ… **v2.7 Source Integrity** â€” Phases 100â€“104 (shipped 2026-06-07)
- âœ… **v2.8 District of Columbia Coverage** â€” Phases 105â€“107 (shipped 2026-06-08)
- âœ… **v2.9 LA County Expansion** â€” Phase 108 (shipped 2026-06-08)
- âœ… **v2.10 Virginia Coverage + LA County Finance** â€” Phases 109â€“113 (shipped 2026-06-11)
- âœ… **v2.11 FEC Finance Completion + US House Geofencing** â€” Phases 114â€”116 (shipped 2026-06-12)
- âœ… **v2.12 MA Expansion** â€” Phases 117â€”118 (shipped 2026-06-15)
- âœ… **v2.13 MA City Council District Geofencing** â€” Phase 119 (shipped 2026-06-15)
- ✅ **v2.14 MA City Expansion Wave 2** — Phases 120–124 (shipped 2026-06-16)
- ✅ **v2.15 National House Rep Seeding (Tier 1)** — Phases 125–126 (shipped 2026-06-16)
- ✅ **v2.16 National House Rep Stances (Tier 2)** — Phases 127–131 (shipped 2026-06-18; FL/NY/PA/IL, 87 reps, 1,338 stances)
- 🔄 **v2.17 National House Rep Stances (Tier 2 continuation)** — Phases 132–140 (active; remaining 212 reps across 38 states, USHS-06..14)

## Phases

### v2.17 National House Rep Stances (Tier 2 continuation) (Phases 132–140)

**Milestone goal:** Complete national US House stance coverage — give the remaining **212 seeded US House reps** (across all 38 not-yet-covered states) sourced compass alignment in the representatives feed, so every US resident's sitting House rep shows up with compass data, not just the 87 in FL/NY/PA/IL.

**Pure scale-out of the proven v2.16 pipeline — no new architecture, no research spike.** Researched largest-delegation-first in 8 multi-state waves (132–139) so coverage is maximized early if interrupted, then a consolidated phase gate (140).

**Carry-forward execution methodology (for `/gsd-plan-phase`):**

- **In-scope rep filter:** `essentials.politicians` rows with `external_id BETWEEN -56999 AND -1000 AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id)` — 212 reps total. **State derived from external_id:** `state_fips = floor((-external_id)/1000)`. Each wave phase filters its own disjoint set of state FIPS, so phases 132–139 touch non-overlapping rep sets.
- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **Reuse:** shared `_TOPIC_SCALE.txt` (25 federal topics = 44 live minus 11 city + judicial-*) fetched live and Read by each agent; `politician-stance-researcher` agent at **3-concurrency** (premium tier, validated v2.16); per-rep CSV → canonical re-parse(`relax_column_count`)/re-stringify → merge (absorbs quad-quote/unwrapped-quote/trailing-comma artifacts); external_id→UUID push (`backend/data/stance-research/pa-house-a/_push.ts` — answers + context + quotes in one txn, suffix-aware surname leak-check); gate pattern (`backend/scripts/verify-phase-127-131.sql`).
- **Stance rules (non-negotiable):** real fetched source URL per stance in `inform.politician_context`; honest-skip per topic where no evidence; **never infer from party**; embed the 1–5 stance scale texts per topic. Productive sources = Ballotpedia, OnTheIssues, Wikipedia, LCV scorecard; house.gov/congress.gov/govtrack/clerk.house.gov consistently 403 to WebFetch.

---

#### Phase 132: OH + NC House Rep Stances

**Goal:** All in-scope OH (15) + NC (14) US House reps = **29 reps** have sourced compass stances in the representatives feed, each backed by a real source URL.

**Depends on:** Nothing (independent wave; filters state_fips OH=39, NC=37)

**Requirements:** USHS-06

**Success Criteria** (what must be TRUE):

  1. Every in-scope OH and NC US House rep (29 total, `external_id` state_fips 39 and 37, no pre-existing answers) has ≥1 sourced compass stance in `inform.politician_answers`.
  2. Every answer row has a paired `inform.politician_context` row carrying a real, fetched source URL — **zero unsourced rows** at wave close.
  3. Topics with no documentable evidence for a given rep are honest-skipped and documented per rep; no value is inferred from party affiliation.

**Plans:** 4 plans

- [x] 132-01-PLAN.md — OH batch A (OH-1..OH-8, external_id -39001..-39008, 8 reps)
- [x] 132-02-PLAN.md — OH batch B (OH-9..OH-15, external_id -39009..-39015, 7 reps)
- [x] 132-03-PLAN.md — NC batch A (NC-1..NC-7, external_id -37001..-37007, 7 reps)
- [x] 132-04-PLAN.md — NC batch B (NC-8..NC-14, external_id -37008..-37014, 7 reps)

**Cross-cutting constraints:**

- Every politician_answers row written has a paired inform.politician_context row with a non-empty sources array of REAL fetched URLs
- No stance inferred from party affiliation — every value matches the exact stance text and traces to a fetched URL
- Live topics fetched fresh from inform.compass_topics; city + judicial-* topics skipped (25 federal topics in scope)
- Stance counts for all politicians OTHER than the 7 batch-B reps are unchanged

---

#### Phase 133: GA + MI House Rep Stances

**Goal:** All in-scope GA (13) + MI (13) US House reps = **26 reps** have sourced compass stances, each backed by a real source URL.

**Depends on:** Nothing (independent wave; filters state_fips GA=13, MI=26)

**Requirements:** USHS-07

**Success Criteria** (what must be TRUE):

  1. Every in-scope GA and MI US House rep (26 total, no pre-existing answers) has ≥1 sourced compass stance.
  2. Every answer row has a paired `inform.politician_context` row with a real fetched source URL — **zero unsourced rows**.
  3. No-evidence topics are honest-skipped and documented per rep; no party-inference.

**Plans:** 4 (133-01..04) — ✅ COMPLETE 2026-06-19. 26/26 reps, 379 sourced answers (GA 180 + MI 199), 0 unsourced. 2 honest-partials (Fuller GA-14, Jack GA-3).

---

#### Phase 134: NJ + WA + AZ House Rep Stances

**Goal:** All in-scope NJ (12) + WA (10) + AZ (9) US House reps = **31 reps** have sourced compass stances, each backed by a real source URL. — ✅ COMPLETE 2026-06-19 (6 plans 134-01..06; 31/31 reps, 409 sourced answers (NJ 158 + WA 138 + AZ 113), 0 unsourced).

**Depends on:** Nothing (independent wave; filters state_fips NJ=34, WA=53, AZ=04)

**Requirements:** USHS-08

**Success Criteria** (what must be TRUE):

  1. Every in-scope NJ, WA, and AZ US House rep (31 total, no pre-existing answers) has ≥1 sourced compass stance.
  2. Every answer row has a paired `inform.politician_context` row with a real fetched source URL — **zero unsourced rows**.
  3. No-evidence topics are honest-skipped and documented per rep; no party-inference.

**Plans:** TBD

---

#### Phase 135: TN + CO + MN + MO House Rep Stances

**Goal:** All in-scope TN (9) + CO (8) + MN (8) + MO (8) US House reps = **33 reps** have sourced compass stances, each backed by a real source URL.

**Depends on:** Nothing (independent wave; filters state_fips TN=47, CO=08, MN=27, MO=29)

**Requirements:** USHS-09

**Success Criteria** (what must be TRUE):

  1. Every in-scope TN, CO, MN, and MO US House rep (33 total, no pre-existing answers) has ≥1 sourced compass stance.
  2. Every answer row has a paired `inform.politician_context` row with a real fetched source URL — **zero unsourced rows**.
  3. No-evidence topics are honest-skipped and documented per rep; no party-inference.

**Plans:** 8 plans (all wave 1, mutually independent)
- [x] 135-01-PLAN.md — TN batch A: TN-1..TN-5 (5 reps) research + push
- [x] 135-02-PLAN.md — TN batch B: TN-6..TN-9 (4 reps) research + push (closes TN)
- [x] 135-03-PLAN.md — CO batch A: CO-1..CO-4 (4 reps) research + push
- [x] 135-04-PLAN.md — CO batch B: CO-5..CO-8 (4 reps) research + push (closes CO)
- [x] 135-05-PLAN.md — MN batch A: MN-1..MN-4 (4 reps) research + push
- [x] 135-06-PLAN.md — MN batch B: MN-5..MN-8 (4 reps) research + push (closes MN)
- [x] 135-07-PLAN.md — MO batch A: MO-1..MO-4 (4 reps) research + push
- [x] 135-08-PLAN.md — MO batch B: MO-5..MO-8 (4 reps) research + push (closes MO + Phase 135)

---

#### Phase 136: WI + AL + SC + KY House Rep Stances

**Goal:** All in-scope WI (8) + AL (7) + SC (7) + KY (6) US House reps = **28 reps** have sourced compass stances, each backed by a real source URL.

**Depends on:** Nothing (independent wave; filters state_fips WI=55, AL=01, SC=45, KY=21)

**Requirements:** USHS-10

**Success Criteria** (what must be TRUE):

  1. Every in-scope WI, AL, SC, and KY US House rep (28 total, no pre-existing answers) has ≥1 sourced compass stance.
  2. Every answer row has a paired `inform.politician_context` row with a real fetched source URL — **zero unsourced rows**.
  3. No-evidence topics are honest-skipped and documented per rep; no party-inference.

**Plans:** 8 plans (all wave 1, mutually independent)

Plans:
- [x] 136-01-PLAN.md — WI batch A (WI-1..WI-4, ext -55001..-55004)
- [x] 136-02-PLAN.md — WI batch B (WI-5..WI-8, ext -55005..-55008)
- [x] 136-03-PLAN.md — AL batch A (AL-1..AL-4, ext -1001..-1004)
- [x] 136-04-PLAN.md — AL batch B (AL-5..AL-7, ext -1005..-1007)
- [x] 136-05-PLAN.md — SC batch A (SC-1..SC-4, ext -45001..-45004)
- [x] 136-06-PLAN.md — SC batch B (SC-5..SC-7, ext -45005..-45007)
- [x] 136-07-PLAN.md — KY batch A (KY-1..KY-3, ext -21001..-21003)
- [x] 136-08-PLAN.md — KY batch B (KY-4..KY-6, ext -21004..-21006)

---

#### Phase 137: LA + CT + IN + OK + AR + IA House Rep Stances

**Goal:** All in-scope LA (6) + CT (5) + IN (5) + OK (5) + AR (4) + IA (4) US House reps = **29 reps** have sourced compass stances, each backed by a real source URL.

**Depends on:** Nothing (independent wave; filters state_fips LA=22, CT=09, IN=18, OK=40, AR=05, IA=19)

**Requirements:** USHS-11

**Success Criteria** (what must be TRUE):

  1. Every in-scope LA, CT, IN, OK, AR, and IA US House rep (29 total, no pre-existing answers) has ≥1 sourced compass stance.
  2. Every answer row has a paired `inform.politician_context` row with a real fetched source URL — **zero unsourced rows**.
  3. No-evidence topics are honest-skipped and documented per rep; no party-inference.

**Plans:** 6 plans (one per state, all wave 1, mutually independent)

- [x] 137-01-PLAN.md — LA House reps (LA-1..LA-6, 6 reps) research + push
- [x] 137-02-PLAN.md — CT House reps (CT-1..CT-5, 5 reps) research + push
- [x] 137-03-PLAN.md — IN House reps (IN-1,2,3,5,6, 5 reps, non-contiguous) research + push
- [x] 137-04-PLAN.md — OK House reps (OK-1..OK-5, 5 reps) research + push
- [x] 137-05-PLAN.md — AR House reps (AR-1..AR-4, 4 reps, single-thousands) research + push
- [x] 137-06-PLAN.md — IA House reps (IA-1..IA-4, 4 reps) research + push

---

#### Phase 138: KS + MS + NV + NE + NM House Rep Stances

**Goal:** All in-scope KS (4) + MS (4) + NV (4) + NE (3) + NM (3) US House reps = **18 reps** have sourced compass stances, each backed by a real source URL. — ✅ COMPLETE 2026-06-20 (5 plans 138-01..05; 18/18 reps, 233 sourced answers (KS 54 + MS 54 + NV 56 + NE 39 + NM 30), 0 unsourced).

**Depends on:** Nothing (independent wave; filters state_fips KS=20, MS=28, NV=32, NE=31, NM=35)

**Requirements:** USHS-12

**Success Criteria** (what must be TRUE):

  1. Every in-scope KS, MS, NV, NE, and NM US House rep (18 total, no pre-existing answers) has ≥1 sourced compass stance.
  2. Every answer row has a paired `inform.politician_context` row with a real fetched source URL — **zero unsourced rows**.
  3. No-evidence topics are honest-skipped and documented per rep; no party-inference.

**Plans:**
- [x] 138-01-PLAN.md — KS House reps (KS-1..KS-4, 4 reps, 54 sourced, 0 unsourced)
- [x] 138-02-PLAN.md — MS House reps (MS-1..MS-4, 4 reps, 54 sourced, 0 unsourced)
- [x] 138-03-PLAN.md — NV House reps (NV-1..NV-4, 4 reps, 56 sourced, 0 unsourced)
- [x] 138-04-PLAN.md — NE House reps (NE-1..NE-3, 3 reps, 39 sourced, 0 unsourced)
- [x] 138-05-PLAN.md — NM House reps (NM-1..NM-3, 3 reps, 30 sourced, 0 unsourced)

---

#### Phase 139: Single/Low-Rep States House Rep Stances

**Goal:** All in-scope reps in the 12 smallest-delegation states — HI/ID/MT/NH/RI/WV (2 each) + AK/DE/ND/SD/VT/WY (1 each, at-large) = **18 reps** — have sourced compass stances, each backed by a real source URL. — ✅ COMPLETE 2026-06-20 (3 plans 139-01..03; 18/18 reps, 192 sourced answers (HI+ID+MT 64 + NH+RI+WV 58 + at-large 70), 0 unsourced).

**Depends on:** Nothing (independent wave; filters state_fips HI=15, ID=16, MT=30, NH=33, RI=44, WV=54, AK=02, DE=10, ND=38, SD=46, VT=50, WY=56)

**Requirements:** USHS-13

**Success Criteria** (what must be TRUE):

  1. Every in-scope rep across the 12 single/low-rep states (18 total, no pre-existing answers) has ≥1 sourced compass stance.
  2. Every answer row has a paired `inform.politician_context` row with a real fetched source URL — **zero unsourced rows**.
  3. No-evidence topics are honest-skipped and documented per rep; no party-inference.

**Plans:**
- [x] 139-01-PLAN.md — HI + ID + MT House reps (6 reps, 64 sourced, 0 unsourced)
- [x] 139-02-PLAN.md — NH + RI + WV House reps (6 reps, 58 sourced, 0 unsourced)
- [x] 139-03-PLAN.md — AK + DE + ND + SD + VT + WY at-large reps (6 reps, 70 sourced, 0 unsourced)

---

#### Phase 140: Phase Gate Verification

**Goal:** A single read-only, labeled-assertion SQL script confirms all 212 in-scope US House reps (across all 38 states) have sourced stance coverage with zero unsourced rows — the consolidated proof that v2.17 is complete.

**Depends on:** Phases 132–139 (all eight waves must be complete before the consolidated gate is meaningful)

**Requirements:** USHS-14

**Success Criteria** (what must be TRUE):

  1. `backend/scripts/verify-phase-132-140.sql` (following the `verify-phase-127-131.sql` pattern) runs read-only and every labeled assertion PASSES against production.
  2. The script asserts all 212 in-scope reps (`external_id BETWEEN -56999 AND -1000`, the v2.17 set) have ≥1 stance, and that **zero** answer rows lack a paired `inform.politician_context` row with a real source URL.
  3. Per-state coverage counts are asserted (covered = in-scope for each of the 38 states), surfacing any rep that was missed. (Refinement: OH+NC is 28/29 — McDowell NC-6 −37006 is the one documented Phase-132 honest-skip; USHS-14a pins the sole gap to exactly −37006.)

**Plans:**
- [ ] 140-01-PLAN.md — author + run verify-phase-132-140.sql (USHS-06..14 labeled assertions)

---

<details>
<summary>âœ… v2.9 LA County Expansion (Phase 108) â€” SHIPPED 2026-06-08</summary>

- [x] Phase 108: LA County City Officials (5/5 plans) â€” completed 2026-06-08
  - Wave 1: 14 Tier 1 partial cities gap-filled with Census FIPS geo_ids
  - Wave 2: Beverly Hills (6), Santa Monica (10), LA City Controller + Clerk
  - Wave 3: 10 new cities from scratch â€” 52 new politicians
  - Wave 4: Phase gate SQL (8 assertions) + representatives-me smoke test

Full details: `.planning/milestones/v2.9-ROADMAP.md`

</details>

<details>
<summary>âœ… v2.8 District of Columbia Coverage (Phases 105â€“107) â€” SHIPPED 2026-06-08</summary>

- [x] Phase 105: DC Infrastructure + Official Records (2/2 plans) â€” completed 2026-06-07
- [x] Phase 106: DC Stance Research (3/3 plans) â€” completed 2026-06-08
- [x] Phase 107: DC Finance (1/1 plans) â€” completed 2026-06-08

Full details: `.planning/milestones/v2.8-ROADMAP.md`

</details>

<details>
<summary>âœ… v2.7 Source Integrity (Phases 100â€“104) â€” SHIPPED 2026-06-07</summary>

- [x] **Phase 100: Source Coverage Audit** â€” Audit report + prioritized target list (completed 2026-06-05)
- [x] **Phase 101: Federal Senate Remediation** â€” All 100 senator stances sourced or deleted (completed 2026-06-06)
- [x] **Phase 102: Federal House Remediation** â€” All US House rep stances sourced or deleted (completed 2026-06-06)
- [x] **Phase 103: State Remediation â€” CA + MD** â€” CA legislators sourced or deleted; MD officials researched from scratch (completed 2026-06-07)
- [x] **Phase 104: Local Remediation â€” City Officials** â€” All city official stances sourced or deleted; MASTER-DELETION-LOG.md (20 entries) finalizes QUAL-02 for v2.7 (completed 2026-06-07)

</details>

<details>
<summary>âœ… v1.0 MVP (Phases 1â€“8) â€” SHIPPED 2026-02-28</summary>

- [x] Phase 1: Foundation (2/2 plans) â€” completed 2026-02-24
- [x] Phase 2: Auth Routes and Account Core (2/2 plans) â€” completed 2026-02-25
- [x] Phase 3: Alpha Enrollment (3/3 plans) â€” completed 2026-02-25
- [x] Phase 4: Compass Routes (3/3 plans) â€” completed 2026-02-26
- [x] Phase 5: Empower Flow (2/2 plans) â€” completed 2026-02-27
- [x] Phase 6: Gems, Roles, and Social Graph (3/3 plans) â€” completed 2026-02-27
- [x] Phase 7: Admin Tool and Calibration Cron (3/3 plans) â€” completed 2026-02-27
- [x] Phase 8: Public Candidate Pages (2/2 plans) â€” completed 2026-02-28

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>âœ… v1.1 XP & Progression (Phases 9â€“11) â€” SHIPPED 2026-03-04</summary>

- [x] Phase 9: XP Schema & Core (2/2 plans) â€” completed 2026-03-04
- [x] Phase 10: XP API (2/2 plans) â€” completed 2026-03-04
- [x] Phase 11: Admin Tool XP View (1/1 plan) â€” completed 2026-03-04

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>âœ… v1.2 CompassV2 Integration & Alpha Hardening (Phases 12â€“16) â€” SHIPPED 2026-03-07</summary>

- [x] Phase 12: Alpha Hardening (2/2 plans) â€” completed 2026-03-06
- [x] Phase 13: CompassV2 Backend Compatibility (4/4 plans) â€” completed 2026-03-06
- [x] Phase 14: Compass Admin Backend (3/3 plans) â€” completed 2026-03-06
- [x] Phase 15: Compass Admin React UI (5/5 plans) â€” completed 2026-03-07
- [x] Phase 16: v1.2 Gap Closure (1/1 plan) â€” completed 2026-03-07

Full details: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>âœ… v1.3 Alpha Launch & Location Infrastructure (Phases 17â€“26) â€” SHIPPED 2026-03-15</summary>

- [x] Phase 17: Live Alpha Deployment (3/3 plans) â€” completed 2026-03-10
- [x] Phase 18: CompassV2 API Contract (4/4 plans) â€” completed 2026-03-10
- [x] Phase 19: Location Schema & RPCs (3/3 plans) â€” completed 2026-03-12
- [x] Phase 20: Location Endpoints & Validation (5/5 plans) â€” completed 2026-03-14
- [x] Phase 21: empowered_profiles Politician Schema (2/2 plans) â€” completed 2026-03-14
- [x] Phase 22: Multi-Currency Gem System (2/2 plans) â€” completed 2026-03-14
- [x] Phase 23: Central Profile Page + Admin Tier Promotion (3/3 plans) â€” completed 2026-03-14
- [x] Phase 24: Public Auth Hub (2/2 plans) â€” completed 2026-03-14
- [x] Phase 25: Deployment Runbook Completion (1/1 plan) â€” completed 2026-03-15
- [x] Phase 26: v1.3 Tech Debt Closure (1/1 plan) â€” completed 2026-03-15

Full details: `.planning/milestones/v1.3-ROADMAP.md`

</details>

<details>
<summary>âœ… v1.4 Profile Hub & Verification Engine (Phases 27â€“30) â€” SHIPPED 2026-03-17</summary>

- [x] Phase 27: Verification Rating Schema (1/1 plan) â€” completed 2026-03-15
- [x] Phase 28: VQ Confirmation Flow (2/2 plans) â€” completed 2026-03-15
- [x] Phase 29: Admin Controls & Integration Verification (2/2 plans) â€” completed 2026-03-15
- [x] Phase 30: Profile Hub UI (2/2 plans) â€” completed 2026-03-16

Full details: `.planning/milestones/v1.4-ROADMAP.md`

</details>

<details>
<summary>âœ… v1.5 Partner Integration & Referrals (Phases 31â€“33) â€” SHIPPED 2026-03-19</summary>

- [x] Phase 31: Referral Dashboard Card (1/1 plan) â€” completed 2026-03-19
- [x] Phase 32: CompassV2 Integration Guide (1/1 plan) â€” completed 2026-03-19
- [x] Phase 33: Essentials Integration Guide (1/1 plan) â€” completed 2026-03-19

Full details: `.planning/milestones/v1.5-ROADMAP.md`

</details>

### v1.6 Platform Consolidation (Phases 34â€“43)

---

#### Phase 34: Database Schema Migration

**Goal:** The ev-accounts Supabase project contains all EV-Backend tables with RLS enforced and grants correctly scoped â€” no application code changes yet, just schema parity.

**Dependencies:** None (pre-flight work; all subsequent phases depend on this)

**Requirements:** CONS-01, CONS-02, CONS-03, CONS-04

**Plans:** 3 plans

Plans:

- [x] 34-01-PLAN.md â€” Pre-flight verification: enumerate tables, detect user_id columns, capture row counts
- [x] 34-02-PLAN.md â€” RLS migrations for 5 public-read schemas (essentials, meetings, treasury, transparent_motivations, compass)
- [x] 34-03-PLAN.md â€” RLS migration for staging (authenticated-only read) + comprehensive verification

**Success Criteria:**

1. All six schemas (`essentials`, `staging`, `treasury`, `meetings`, `validation_quests`, `trivia`) exist in the ev-accounts Supabase project and are visible in the dashboard.
2. Row counts in ev-accounts match row counts in EV-Backend for every imported table (52 tables verified).
3. `SELECT * FROM pg_policies WHERE schemaname IN ('essentials','staging','treasury','meetings','validation_quests','trivia')` returns at least one policy per table â€” zero unprotected tables.
4. Service role and anon role GRANT statements are applied; a request authenticated as anon cannot read rows that require auth on any migrated table.

---

#### Phase 35: Politician Deduplication

**Goal:** `essentials.politicians` is the single source of truth for all politician records â€” compass answers, context, and VQ confirmation all reference the unified ID space with no data loss.

**Dependencies:** Phase 34 (essentials schema must exist and be populated)

**Requirements:** CONS-05, CONS-06, CONS-07

**Plans:** 2 plans

Plans:

- [x] 35-01-PLAN.md â€” Atomic migration: bridge table, FK reassignment, RPC rebuilds, DROP inform.politicians
- [x] 35-02-PLAN.md â€” Application code updates: schema switch to essentials + PostgREST fix

**Success Criteria:**

1. `public.politician_id_bridge` exists and contains one row per politician, mapping both the former `inform` ID and the `essentials` ID.
2. `GET /api/compass/politicians/:id/answers` returns correct stances after the FK migration â€” results match the pre-migration baseline.
3. `\dt inform.*` in psql returns no `politicians` table; all join paths through `inform.politician_answers` and `inform.politician_context` resolve against `essentials.politicians`.
4. The VQ confirmation RPC (`confirm_vq_stance`) completes without FK violation errors when called with valid `essentials.politicians` IDs.

---

#### Phase 36: Express Ports Wave 1 â€” Treasury and Meetings

**Goal:** Treasury and Meetings data is served by the ev-accounts Express API â€” the Go server is no longer the authoritative source for these routes.

**Dependencies:** Phase 34 (schemas and data must be in ev-accounts)

**Requirements:** CONS-08, CONS-09

**Plans:** 2 plans

Plans:

- [x] 36-01-PLAN.md â€” Treasury service layer and routes (5 public reads + 4 admin writes)
- [x] 36-02-PLAN.md â€” Meetings service layer and routes (5 public reads + 3 admin writes)

**Success Criteria:**

1. All Treasury endpoints (~9 routes) return well-formed responses designed from the Supabase schema when called against ev-accounts (Supabase-first design, not Go parity).
2. All Meetings endpoints (~8 routes) return correct data for public reads; admin write routes reject requests without a valid admin JWT.
3. A curl smoke test hitting each new route on the Render staging deployment returns HTTP 200 (or 201/204 where appropriate) with no 500 errors.
4. No Treasury or Meetings route requires the Go server to be running â€” ev-accounts handles all requests end-to-end.

---

#### Phase 37: Express Ports Wave 2 â€” Staging

**Goal:** The Staging review workflow runs entirely on ev-accounts â€” role-gated submission, review, and approval routes are operational and enforce the same access rules as the Go server.

**Dependencies:** Phase 34 (staging schema must exist); Phase 36 (establishes endpoint port pattern)

**Requirements:** CONS-10

**Plans:** 4 plans

Plans:

- [x] 37-01-PLAN.md â€” Migrations (staging_reviewer role + status defaults) + requireStagingReviewer middleware
- [x] 37-02-PLAN.md â€” Staging service: politician CRUD, review, lock, merge, auto-promotion
- [x] 37-03-PLAN.md â€” Staging service: stance + building photo CRUD, review, auto-promotion
- [x] 37-04-PLAN.md â€” Staging routes (18 handlers) + index.ts registration + smoke tests

**Success Criteria:**

1. All Staging endpoints (~15 routes) respond correctly; role-gated routes return 403 for requests without the required role claim.
2. A complete submission-to-approval flow can be executed end-to-end via the ev-accounts API with no Go server involvement.
3. The review workflow state machine (submit â†’ review â†’ approve/reject) transitions correctly and is reflected in database state after each step.

---

#### Phase 38: Express Ports Wave 3 â€” Essentials

**Goal:** Essentials address-to-politician lookup and all supporting routes are served by ev-accounts â€” including PostGIS-backed jurisdiction resolution using Census Geocoder â€” matching the Go server's public contract.

**Dependencies:** Phase 34 (essentials schema); Phase 35 (unified politician IDs); Phase 36/37 (endpoint port pattern established)

**Requirements:** CONS-11

**Plans:** 5 plans

Plans:

- [x] 38-01-PLAN.md â€” Schema investigation + Census Geocoder rewrite + env.ts update
- [x] 38-02-PLAN.md â€” Address-search endpoint + politicians list Go-parity rewrite
- [x] 38-03-PLAN.md â€” Politician detail endpoint (GET /politicians/:id)
- [x] 38-04-PLAN.md â€” Legislative subroutes (legislative, committees, bills, votes)
- [x] 38-05-PLAN.md â€” Entity routes (governments, chambers, districts) + index.ts registration

**Success Criteria:**

1. All Essentials core endpoints (~25 routes) respond with the same shape as Go equivalents.
2. The address-to-politician lookup flow â€” Census Geocoder â†’ PostGIS boundary match â†’ politician list â€” returns correct results for a known Indiana address.
3. Unauthenticated requests receive Inform-baseline responses; Connected users with jurisdiction receive enhanced responses â€” consistent with the ESSENTIALS-INTEGRATION.md contract.
4. `GET /api/essentials/politicians` returns all fields including the 9 `empowered_profiles` politician schema columns added in v1.3.

---

#### Phase 39: Compass Additions

**Goal:** The full compass feature set is complete â€” missing endpoints are implemented, the value range supports decimal stances, and CompassV2 can use every compass capability without hitting the Go server.

**Dependencies:** Phase 35 (unified politician IDs required for compare and batch politician answers)

**Requirements:** CONS-12, CONS-13

**Plans:** 3 plans

Plans:

- [x] 39-01-PLAN.md â€” Database migration: value range, verdicts table, updated RPCs
- [x] 39-02-PLAN.md â€” Public routes: compare, verdicts, batch politician answers
- [x] 39-03-PLAN.md â€” Admin compass routes at Go-compatible /api/compass/* paths

**Success Criteria:**

1. All missing compass endpoints are reachable: compare, verdicts, admin CRUD, and batch politician answers â€” each returns well-formed responses.
2. A compass response with `value = 0.5` and a response with `value = 5.5` both insert successfully; values outside the new range are rejected by the CHECK constraint.
3. Existing compass responses with integer values 1â€“5 remain valid after the constraint migration (no data loss).
4. The CompassV2 integration guide checklist passes end-to-end with no Go server dependency remaining for compass routes.

---

#### Phase 40: Frontend Auth Updates

**Goal:** All four frontend apps authenticate against ev-accounts using Bearer tokens and correct API URLs â€” cookie-based auth to the Go server is fully replaced.

**Dependencies:** Phase 36, Phase 37, Phase 38, Phase 39 (all endpoint ports must be complete before frontends switch targets)

**Requirements:** CONS-14, CONS-15, CONS-16, CONS-17

**Plans:** 5 plans

Plans:

- [x] 40-01-PLAN.md â€” Auth Hub redirect-after-login + re-auth banner
- [x] 40-02-PLAN.md â€” CompassV2 Bearer token migration (20+ files)
- [x] 40-03-PLAN.md â€” Essentials Bearer token migration + Sign In link
- [x] 40-04-PLAN.md â€” Read & Rank Bearer token migration + Treasury Tracker proxy update
- [x] 40-05-PLAN.md â€” Cutover runbook (three-party coordination)

**Status:** Complete â€” 2026-03-23

**Success Criteria:**

1. CompassV2 completes a full user session (login â†’ calibration â†’ compare) using `Authorization: Bearer` headers against the ev-accounts API URL with no cookie dependency.
2. Essentials app completes a full Inform-to-Connected flow using Bearer token auth against ev-accounts.
3. Read & Rank authenticates via Bearer token and all existing features function correctly.
4. Treasury Tracker loads public treasury data from the ev-accounts API URL; no requests reach the Go server's API URL.

---

#### Phase 41: VQ and Trivia Migration

**Goal:** Validation Quests and Civic Trivia databases are fully consolidated into ev-accounts â€” both apps point to the ev-accounts Supabase project and all FK references resolve against unified politician IDs.

**Dependencies:** Phase 34 (schemas exist); Phase 35 (essentials.politicians as FK target)

**Requirements:** CONS-18, CONS-19

**Plans:** 4 plans

Plans:

- [x] 41-01-PLAN.md â€” Pre-flight inspection: enumerate tables, row counts, FK gap analysis, Trivia connection model
- [x] 41-02-PLAN.md â€” trivia_service role creation + GET /api/trivia/leaderboard-profiles endpoint
- [x] 41-03-PLAN.md â€” RLS migration for validation_quests and trivia tables
- [x] 41-04-PLAN.md â€” Cutover: VQ anon key verified, CTC reconnected, smoke tests passed

**Success Criteria:**

1. `validation_quests` schema exists in ev-accounts with all imported tables; VQ's Render service `DATABASE_URL` points to ev-accounts and the VQ app connects successfully on startup.
2. `trivia` schema exists in ev-accounts; trivia politician foreign keys resolve against `essentials.politicians` with no FK violation errors.
3. A VQ confirmation flow (`POST /api/vq/confirm-stance`) completes successfully end-to-end after the migration with correct VR adjustments and gem awards.
4. RLS is active on all `validation_quests` and `trivia` tables; a smoke test confirms unauthenticated requests cannot access user-specific rows.

---

#### Phase 42: Decommission and DNS Cutover

**Goal:** EV-Backend is retired and `api.empowered.vote` resolves to the ev-accounts Express server â€” there is exactly one API for the entire Empowered Vote platform.

**Dependencies:** Phase 36, Phase 37, Phase 38, Phase 39, Phase 40, Phase 41 (all endpoints ported; all frontends updated; VQ/Trivia migrated)

**Requirements:** CONS-20, CONS-21, CONS-22

**Plans:** 2 plans

Plans:

- [ ] 42-01-PLAN.md â€” URL cleanup and decommission runbook creation
- [ ] 42-02-PLAN.md â€” Cutover execution (human-gated dashboard operations)

**Success Criteria:**

1. Go server request logs show zero traffic over a 24-hour monitoring window before cutover is initiated.
2. EV-Backend is scaled to zero on Render and the Go repo is archived on GitHub; the Go server does not respond to HTTP requests.
3. `api.empowered.vote` resolves to the ev-accounts server; `curl https://api.empowered.vote/api/health` returns `{"status":"ok"}` from the Express handler.
4. CORS headers on ev-accounts allow all production frontend origins; frontend env vars across all four apps point to `api.empowered.vote` with no lingering Go server URLs.

---

#### Phase 43: Integration Documentation

**Goal:** Chris Andrews' team has a single updated integration reference that accurately describes every API change made during the consolidation â€” auth model, unified politician IDs, new schemas, value range fix, and endpoint inventory.

**Dependencies:** Phase 42 (documentation reflects final state â€” only written after all changes are shipped)

**Requirements:** CONS-23

**Success Criteria:**

1. The integration doc covers all four fronts of change: auth model (Bearer token only), unified `essentials.politicians` ID format with bridge table note, compass value range (0.5â€“5.5), and new schema inventory (essentials, staging, treasury, meetings, validation_quests, trivia).
2. Each new or changed endpoint is listed with its method, path, auth requirement, and example request/response shape.
3. Anti-patterns from the migration are documented inline at the relevant section (e.g., "do not use the old Go server URL", "do not pass inform.politicians IDs â€” use essentials.politicians IDs").
4. A human reading only this doc can update a partner integration from Go-server state to ev-accounts state without needing to read source code.

---

### v1.7 Cross-App SSO (Phases 44â€“48)

---

#### Phase 44: Accounts API SSO Infrastructure

**Goal:** The ev-accounts API issues and reads the shared `ev_session` cookie â€” the foundation all other phases depend on. A user who logs in receives the cookie; any app can silently exchange it for fresh tokens; logout clears it everywhere.

**Dependencies:** None (all other v1.7 phases depend on this phase)

**Requirements:** SSO-01, SSO-02, SSO-03

**Plans:** 2 plans

Plans:

- [ ] 44-01-PLAN.md â€” Login cookie issuance: set httpOnly `ev_session` on `.empowered.vote` at login; `POST /api/auth/logout` clears cookie + revokes Supabase session
- [ ] 44-02-PLAN.md â€” `GET /api/auth/session` endpoint: CORS config for `*.empowered.vote`, cookie read, Supabase token exchange, 401 fast-fail on missing cookie

**Success Criteria:**

1. After `POST /api/auth/login`, the response includes `Set-Cookie: ev_session=...; Domain=.empowered.vote; HttpOnly; Secure; SameSite=Lax` with the Supabase refresh token as the cookie value.
2. `GET /api/auth/session` with a valid `ev_session` cookie returns `{ access_token, refresh_token }` (HTTP 200); without the cookie it returns HTTP 401 with no error body.
3. `POST /api/auth/logout` clears the `ev_session` cookie (Set-Cookie with Max-Age=0) and revokes the Supabase session â€” a subsequent `GET /api/auth/session` call returns 401.
4. `GET /api/auth/session` responds with correct CORS headers (`Access-Control-Allow-Origin: <requesting *.empowered.vote origin>`, `Access-Control-Allow-Credentials: true`) for requests from all EV app origins.

---

#### Phase 45: Profile Hub + CTC Silent SSO

**Goal:** Profile Hub and CTC automatically inherit an active session on load â€” a user already logged in at accounts.empowered.vote arrives at either app already authenticated without a re-login prompt. Logout at either app clears the shared cookie.

**Dependencies:** Phase 44 (session endpoint must exist before frontends can call it)

**Requirements:** SSO-04, SSO-05, SSO-06

**Plans:** 2 plans

Plans:

- [ ] 45-01-PLAN.md â€” Profile Hub (`app/src`): silent session check in AuthInitializer before rendering unauthenticated state; wire existing auth store to accept tokens from session exchange
- [ ] 45-02-PLAN.md â€” CTC (`C:\Project Test\frontend`): silent session check if no `ev_refresh_token` in localStorage; logout calls `POST /api/auth/logout` to clear shared cookie

**Success Criteria:**

1. A user authenticated at `accounts.empowered.vote` who navigates to `app.empowered.vote` (Profile Hub) in the same browser is shown their authenticated profile without a login prompt.
2. A user authenticated at `accounts.empowered.vote` who opens CTC in the same browser starts a game session as their authenticated user without re-entering credentials.
3. Logging out from CTC results in the `ev_session` cookie being cleared; a subsequent navigation to any EV app shows the unauthenticated (Inform-baseline) state.
4. If no shared session exists (cookie absent or expired), both apps render their unauthenticated state silently â€” no error message, no redirect loop.

---

#### Phase 46: Essentials + CompassV2 Silent SSO

**Goal:** Essentials and CompassV2 automatically inherit an active session on load using the same silent-check pattern â€” both apps degrade gracefully to Inform-baseline when no session exists.

**Dependencies:** Phase 44 (session endpoint must exist)

**Requirements:** SSO-07, SSO-08, SSO-11, SSO-12

**Plans:** 2 plans

Plans:

- [x] 46-01-PLAN.md â€” Essentials (`C:\Transparent Motivations\essentials`): silent session check in auth bootstrap; logout calls `POST /api/auth/logout`
- [x] 46-02-PLAN.md â€” CompassV2 (`C:\EV-CompassV2`): `git pull` first; silent session check in AuthInitializer / `publicFetch` flow; logout calls `POST /api/auth/logout`

**Success Criteria:**

1. A user authenticated at any EV app who navigates to Essentials receives Connected-enhanced responses (jurisdiction-aware politician list) without re-login.
2. A user authenticated at any EV app who opens CompassV2 loads their existing compass answers and calibration state without re-login.
3. Logging out from Essentials or CompassV2 clears the `ev_session` cookie; a subsequent navigation to any EV app shows the unauthenticated state.
4. Both apps degrade gracefully to full Inform-baseline functionality when no session exists â€” no error banner, no broken UI state.

---

#### Phase 47: Validation Quests Silent SSO

**Goal:** Validation Quests automatically inherits an active session using Supabase's native session API â€” a user already logged in elsewhere arrives at VQ with an active Supabase session initialized, without re-login.

**Dependencies:** Phase 44 (session endpoint must exist); VQ uses Supabase JS client directly, so the handoff mechanism is `supabase.auth.setSession()` rather than localStorage

**Requirements:** SSO-09, SSO-10

**Plans:** 2 plans

Plans:

- [ ] 47-01-PLAN.md â€” SSO session check: add isAuthChecking state, initSso() with GET /api/auth/session + setSession(), PrivateRoute gate
- [ ] 47-02-PLAN.md â€” Logout coordination: upgrade signOut() to POST /api/auth/logout before supabase.auth.signOut()

**Success Criteria:**

1. A user authenticated at any EV app who opens VQ has an active Supabase session (Supabase JS client reports `session !== null`) without re-entering credentials.
2. VQ's Supabase-native auth flows (RLS-gated queries, quest assignment reads) work correctly after SSO session initialization via `setSession()`.
3. Logging out from VQ clears the `ev_session` cookie; a subsequent visit to VQ or any other EV app shows the unauthenticated state.
4. If VQ calls `GET /api/auth/session` and receives a 401 (no cookie), VQ renders its unauthenticated state silently â€” no exception thrown, no error surfaced to the user.

---

#### Phase 48: Compliance + End-to-End Verification

**Goal:** The `ev_session` cookie is disclosed in the privacy policy as strictly necessary for authentication, and SSO works correctly end-to-end across all five apps in a real browser session.

**Dependencies:** Phases 44â€“47 (all apps must implement SSO before cross-app smoke test is meaningful)

**Requirements:** SSO-13

**Plans:** 2 plans

Plans:

- [ ] 48-01-PLAN.md â€” Privacy disclosure: add `ev_session` cookie documentation to privacy policy / cookie disclosure on `accounts.empowered.vote`; classify as strictly necessary (no consent banner required)
- [ ] 48-02-PLAN.md â€” Cross-app smoke test: manual E2E verification â€” login at accounts, confirm session inheritance at all five apps, confirm single-logout clears session everywhere

**Success Criteria:**

1. The privacy policy or cookie disclosure page on `accounts.empowered.vote` names the `ev_session` cookie, describes its purpose (session continuity across EV apps), its domain (`.empowered.vote`), and classifies it as strictly necessary â€” no opt-in banner displayed.
2. A single login at `accounts.empowered.vote` results in authenticated state at Profile Hub, CTC, Essentials, CompassV2, and Validation Quests without any additional login prompts.
3. A single logout from any one app results in unauthenticated state at all apps â€” the `ev_session` cookie is absent and `GET /api/auth/session` returns 401.
4. All five apps render their full Inform-baseline experience when no session is present â€” no broken pages, no error states, no redirect loops.

---

### v1.8 Location Identity (Phases 49â€“50)

---

#### Phase 49: Stored Jurisdiction & Cross-App Location Profile

**Goal:** Connected users' district GEO IDs are stored on `connected_profiles` at set-location time and returned on `/api/account/me` â€” every app that already calls `/account/me` can read the user's jurisdiction without asking for their address again. `home_address` is not stored for Connected tier.

**Dependencies:** None (builds on existing set-location flow and /account/me endpoint)

**Plans:** 3 plans

Plans:

- [ ] 49-01-PLAN.md â€” Schema: add 5 GEO ID columns + state + city to connected_profiles; migrate existing users via resolve_user_jurisdiction backfill
- [ ] 49-02-PLAN.md â€” Backend: update set-location to write GEO IDs; return jurisdiction object on /account/me; update /representatives/me to use stored GEO IDs directly
- [ ] 49-03-PLAN.md â€” Frontend updates: Read & Rank reads jurisdiction.state; CTC extends AccountProfile type; Essentials uses prefilled jurisdiction on load

**Success Criteria:**

1. After `POST /connect/set-location`, `connected_profiles` has all 5 district GEO IDs populated; `home_address` is NOT written for Connected tier.
2. `GET /api/account/me` returns a `jurisdiction` object with `congressional`, `state_senate`, `state_house`, `county`, `school_district`, `state`, and `city` fields for any Connected user with location on file.
3. `GET /api/essentials/representatives/me` reads stored GEO IDs directly â€” no geocoding, no Census API call â€” and returns the correct politician list.
4. Read & Rank and CTC each read `jurisdiction` from the `/account/me` response they already call â€” no new API endpoints required in either app.
5. All existing Connected users have jurisdiction columns populated after backfill (verified via SQL).

---

#### Phase 50: Precise Representatives for Pre-Phase-49 Users

**Goal:** `GET /essentials/representatives/me` returns the correct district-specific politicians for all Connected users â€” including those who set their location before Phase 49 shipped and have `encrypted_lat`/`encrypted_lng` but null geo_id columns. A new Path 1.5 decrypts stored coordinates via the existing `resolve_user_jurisdiction` RPC when geo_ids are absent, then writes them back so subsequent requests are fast. A one-time backfill covers all existing users.

**Dependencies:** Phase 49 (stored jurisdiction schema + `resolve_user_jurisdiction` RPC must exist)

**Plans:** 2 plans

Plans:

- [x] 50-01-PLAN.md â€” Add Path 1.5 to /representatives/me route
- [x] 50-02-PLAN.md â€” Backfill script for pre-Phase-49 users

**Success Criteria:**

1. `GET /essentials/representatives/me` for user `4e6dde8f-2bd0-4054-824f-4164744165ea` (Culver Blvd, LA) returns Karen Bass and Traci Park in the response body.
2. `X-Formatted-Address` header returns a street-level or ZIP-level string, not just "LOS ANGELES, CA".
3. After the first successful Path 1.5 call, the user's `connected_profiles` row has geo_ids populated (so future calls use Path 1 directly).
4. All existing Connected users with `encrypted_lat` set but null `congressional_geo_id` have geo_ids populated after the backfill.
5. Path ordering: geo_ids present â†’ Path 1 (fast), encrypted coords + no geo_ids â†’ Path 1.5 (decrypt+lookup+write), home_address only â†’ Path 2 (geocode), no location â†’ 204.

---

<details>
<summary>âœ… v1.9 Roles (Phases 51â€“58) â€” SHIPPED 2026-04-06</summary>

- [x] Phase 51: Essentials XP Source Provisioning (1/1 plans) â€” completed 2026-04-02
- [x] Phase 52: Role Schema + RPC Migration (1/1 plans) â€” completed 2026-04-02
- [x] Phase 53: Service Layer + requireRole Middleware (2/2 plans) â€” completed 2026-04-03
- [x] Phase 54: Admin UI â€” Grant/Revoke + Audit Dashboard (2/2 plans) â€” completed 2026-04-03
- [x] Phase 55: Compass Stance Editor + Campaign Manager Endpoints (4/4 plans) â€” completed 2026-04-03
- [x] Phase 56: Essentials Data Editor Endpoint (2/2 plans) â€” completed 2026-04-04
- [x] Phase 57: CTC + Civic Spaces Integration (2/2 plans) â€” completed 2026-04-04
- [x] Phase 58: Contributor Portal (5/5 plans) â€” completed 2026-04-06

Full details: `.planning/milestones/v1.9-ROADMAP.md`

</details>

#### Phase 59: Referral Code System âœ… COMPLETE (2026-04-08)

**Goal:** Level-gated invite quota system with social accountability â€” users earn invite capacity as they level up, admins can override per-user caps, and inviters bear partial accountability for invitee misconduct via Tolerance Rating adjustment and slot locking.

**Dependencies:** Existing invite_codes + invite_chains + invite claim flow (Phase 3); XP leveling (Phase 9); Tolerance Rating (Phase 3)

**Plans:** 4 plans

Plans:

- [x] 59-01-PLAN.md â€” Database migration: schema columns + quota RPCs (generate_invite_code_if_allowed, get_my_invitees, sanction_invitee)
- [x] 59-02-PLAN.md â€” Backend service layer + API routes (quota-aware /generate, /my-invitees, admin overrides, sanction integration)
- [x] 59-03-PLAN.md â€” App UI: expanded Referrals section on DashboardPage (quota display, code generation, invitee list)
- [x] 59-04-PLAN.md â€” Admin UI: invite cap override on AccountDetailPage + InviteOverridesPage list view

**Success Criteria:**

1. A level-3 user can generate invite codes up to their active invitee cap (3); a level-1 user cannot generate any (cap 0).
2. When an invitee is suspended, the inviter's slot is locked for 60 days (or until reinstatement), TR is adjusted, and the inviter receives an in-app notification.
3. Admins can set per-user invite cap overrides (including unlimited) from the AccountDetailPage and see all active overrides on a dedicated list page.
4. The DashboardPage Referrals section shows quota (active/cap), a generate button, new code display with copy, and a compact invitee list with standing/level/graduation/lock status.

---

### v2.0 Civic Account Experience (Phases 60â€“65)

---

#### Phase 60: Design Foundation

**Goal:** The shared design language for the Civic Account Experience exists as a component library â€” color tokens, atomic input/button/card components, progress bar, and nav shell are all implemented in `app/src` and ready for use in every subsequent phase.

**Dependencies:** None (all v2.0 phases depend on this phase)

**Requirements:** DSGN-01, DSGN-02, DSGN-03, DSGN-04, DSGN-05, DSGN-06

**Plans:** 4 plans

Plans:

- [x] 60-01-PLAN.md â€” Add ev-blue and ev-navy tokens to app/src and admin/src index.css; copy logo asset to app/public
- [x] 60-02-PLAN.md â€” Build AuthCard and AuthInput components (DSGN-02, DSGN-03)
- [x] 60-03-PLAN.md â€” Build PrimaryButton and SecondaryButton components (DSGN-04)
- [x] 60-04-PLAN.md â€” Build StepProgress and AppNav components (DSGN-05, DSGN-06)

**Success Criteria:**

1. `ev-blue` (`#3B82F6`) and `ev-navy` (`#020618`) color tokens are declared in `app/src/index.css` and resolve correctly in Tailwind v4 class names (e.g., `bg-ev-blue`, `text-ev-navy`); `ev-blue` is also added to `admin/src/index.css`.
2. An `AuthCard` component renders a dark rounded card with a visible border and consistent padding; swapping in `AuthCard` for any auth or onboarding screen requires no layout code in the consuming page.
3. An `AuthInput` component renders a labeled dark field with placeholder text, inline error message slot, and a blue focus ring on focus â€” matching the design spec.
4. `PrimaryButton` renders a full-width blue button and `SecondaryButton` renders a full-width dark button; both accept `disabled` and `onClick` props; neither button requires additional style overrides at usage sites.
5. `StepProgress` renders a "Step X of Y" label, a percentage-computed blue filled track, and accepts `step` and `total` numeric props; `AppNav` renders the logo mark and wordmark on the left and an optional right-slot for auth controls.

---

#### Phase 61: Auth Flow Restyle

**Goal:** Every screen in the auth sequence â€” welcome, signup, email confirmation, and login â€” uses the new design language and copy so that the first impression a prospective user has of the platform is trust-first and invitational, never coercive.

**Dependencies:** Phase 60 (AuthCard, AuthInput, PrimaryButton, AppNav, StepProgress must exist)

**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06

**Plans:** 5 plans

Plans:

- [x] 61-01-PLAN.md â€” Patch AuthInput to accept inputClassName prop (foundation for invite-code mono styling)
- [x] 61-02-PLAN.md â€” Build WelcomeScreen at /welcome with three options and invitational copy (AUTH-01)
- [x] 61-03-PLAN.md â€” Restyle LoginPage with AppNav + AuthCard + AuthInput + PrimaryButton (AUTH-06)
- [x] 61-04-PLAN.md â€” Restyle SignupPage form + check-email screen with StepProgress and alpha-trust copy (AUTH-02â€“05)
- [x] 61-05-PLAN.md â€” Backend: add display_name to signup_with_invite RPC + Zod schema (migration 071)

**Success Criteria:**

1. Navigating to `/welcome` shows a centered card with three clear options â€” Create account, Log in, and "Continue exploring" â€” and the copy uses invitational framing; no pressure language appears anywhere on the screen.
2. The signup page renders `AppNav`, `StepProgress` (Step 1 of 4), an `AuthCard` containing `AuthInput` fields for email, password, civic name, legal name, and invite code â€” five fields total; all use the dark input style with blue focus ring. The civic name (display_name) is stored on `connected_profiles` at account creation via migration 071.
3. The legal name field on signup displays inline copy explaining the invite-network identity model ("During Alpha, your identity is verified through our invite network â€” one person, one voice") and a "never shown publicly" note visible before the user types.
4. The invite code field displays a shield icon and an inline alpha-trust explanation; the check-email confirmation screen shows the user's email address with a magic-link explanation and a sign-in link.
5. The login page renders `AppNav`, an `AuthCard` with dark fields and a blue CTA, and an "Already have account? Sign In" link â€” matching the Figma design language throughout.

---

#### Phase 62: Onboarding Restyle

**Goal:** The three active onboarding steps â€” civic name, location, and you're connected â€” are visually consistent with the new design language and carry copy that frames civic participation as meaningful, not transactional. The old `WelcomeStep` is removed from the flow.

**Dependencies:** Phase 60 (AppNav, StepProgress, AuthCard, AuthInput, PrimaryButton must exist); Phase 61 (WelcomeScreen at `/welcome` must exist to absorb the removed WelcomeStep)

**Requirements:** ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05

**Plans:** 3 plans

Plans:

- [x] 62-01-PLAN.md â€” Restyle LocationStep with v2.0 chrome (AppNav + StepProgress 2/3 + AuthCard + 4 AuthInput fields); remove reveal gate and Learn More link; preserve isUpdate path for UpdateLocationPage
- [x] 62-02-PLAN.md â€” Restyle LocationCelebrationStep with green-checkmark badge + 3 milestone items; absorb POST /auth/complete-onboarding from PseudonymStep so onboarding terminates here
- [x] 62-03-PLAN.md â€” Simplify OnboardingPage to two-step flow with resumption useEffect; update SignupPage step counter 1-of-4 â†’ 1-of-3; delete WelcomeStep.tsx and PseudonymStep.tsx

**Success Criteria:**

1. The two active onboarding steps (`LocationStep`, `LocationCelebrationStep`) render the shared `AppNav` and `StepProgress` bar at the top; the step counter increments correctly: SignupPage=1/3, LocationStep=2/3, LocationCelebrationStep=3/3.
2. The civic name (`display_name`) is captured on SignupPage already (Phase 61); the legacy `PseudonymStep` is removed and onboarding does NOT re-prompt for a civic name.
3. The location step shows a pin icon, the label "Find your civic community", the copy "We use your location to connect you with your local civic space." with NO "Learn More" link, and four `AuthInput` fields for street, city, state, and ZIP visible immediately (no reveal gate); "Find my representatives" CTA + "Back" button below; no skip option.
4. The "You're connected" celebration step shows a green checkmark icon and three locked milestone items â€” "Your Connected Account is live", "Your civic community is located", "You're ready to participate" â€” with a "Go to dashboard" CTA that calls POST /auth/complete-onboarding and navigates to /.
5. The old `WelcomeStep` and `PseudonymStep` components are removed from the onboarding flow and from disk; new users entering onboarding land directly on the location step; `/welcome` is the only pre-entry value pitch screen.

---

#### Phase 63: Profile Page + Activity Feed

**Goal:** The profile page at `login.empowered.vote/profile` matches the new design â€” name, level, XP bar, gem icons, recent activity, invite section, and VR display are all rendered â€” and the backend delivers a real activity feed endpoint so the Recent Activity section shows live data.

**Dependencies:** Phase 60 (design tokens must exist for the profile reskin); no auth-flow dependency

**Requirements:** PROF-01, PROF-02, PROF-03, PROF-04, PROF-05, PROF-06, API-01, FIX-01

**Success Criteria:**

1. The profile page renders the user's display name as a large heading, a Level badge, and an XP progress bar showing the format "Level N â€” X / Y XP" with the bar correctly filled based on `xp_in_level` / `xp_to_next_level`.
2. The gems section displays three large colored gem icons (yellow, blue, red) with the numeric balance beneath each; balances update when the page is refreshed.
3. The Recent Activity section shows the last 4 XP transactions drawn from `GET /api/account/me/activity`, each displaying the activity name, date, and "+N XP" amount in teal; the section is absent or shows an empty state if the user has no XP history.
4. The invite section renders a locked state ("Reach level 2 to unlock your first referral code") for users below level 2, and an active state showing the invite code with a copy button for eligible users; Verification Rating is displayed as "X / 150" with explanatory copy.
5. `GET /api/account/me/activity` returns the last 20 XP transactions for the authenticated user with `source`, `amount`, `description`, and `created_at` per entry; requires Connected tier (non-Connected requests receive 403); generating a new invite code from the DashboardPage correctly sends `optional_name` in the request body.

---

#### Phase 64: InformLanding â€” SKIPPED (2026-05-10)

**Decision:** Skipped. `login.empowered.vote/profile` already serves as the platform explainer â€” more thorough than a separate landing page would be. Unauthenticated visitors to `app.empowered.vote/` continue to be redirected to `login.empowered.vote/login` via `AuthGuard` (existing behavior).

**Requirements:** LAND-01 through LAND-05 â€” superseded by existing profile page.

---

#### Phase 65: Dashboard Redesign â€” SKIPPED (2026-05-10)

**Decision:** Skipped. Users navigate directly to `login.empowered.vote/profile` â€” `app.empowered.vote` is no longer a primary user destination. The profile page already surfaces level, XP, gems, VR, and feature cards. No dashboard redesign needed.

---

### v2.1 Inform Account Tier (Phases 66â€“68)

---

#### Phase 66: Inform Profiles Backend Foundation

**Goal:** The `inform.inform_profiles` table exists and the gem-routing, location-hint, and balance-transfer contracts are enforced at the database and API layers â€” every subsequent phase can rely on this schema and these endpoints being correct.

**Dependencies:** None (all v2.1 phases depend on this phase; Phase 68 also depends on Phase 67 for the signup flow that creates inform_profiles rows)

**Requirements:** IBAK-01, IBAK-02, IBAK-03, IBAK-04, IBAK-05, IBAK-06

**Plans:** 3 plans

Plans:
Plans:

- [ ] 66-01-PLAN.md â€” Migrations 084 + 085: inform.inform_profiles table, trigger, backfill; signup_with_invite yellow gem transfer (IBAK-01, IBAK-02, IBAK-06)
- [ ] 66-02-PLAN.md â€” Migration 086 + gemService tier-branching: award_inform_yellow_gem RPC, Inform-tier yellow gem routing, 422 for blue/red (IBAK-04)
- [ ] 66-03-PLAN.md â€” requireInform middleware; GET /me inform_profile field; PATCH /account/location-hint upsert (IBAK-03, IBAK-05)

**Success Criteria:**

1. `inform.inform_profiles` exists with a row for every `public.users` entry â€” including rows for users who signed up before this migration ran (backfilled by the trigger or a one-time backfill script).
2. `GET /api/account/me` includes `inform_profile: { yellow_gem_balance, last_essentials_location }` in the response body for all authenticated users regardless of tier.
3. `POST /api/gems/award` with `gem_type: "yellow"` and an Inform-tier recipient increments `inform_profiles.yellow_gem_balance`; the same call with `gem_type: "blue"` or `"red"` returns HTTP 422.
4. `PATCH /api/account/location-hint` stores a JSON location payload in `inform_profiles.last_essentials_location`; requires auth; returns 403 for Connected-tier users (endpoint is Inform-only).
5. When a user completes Connected signup via `signup_with_invite`, their `inform_profiles.yellow_gem_balance` is atomically transferred to `connected_profiles.gem_balance_yellow` and the inform balance is set to 0 â€” no gems are lost or duplicated.

---

#### Phase 67: Login Hub + Inform Signup Flow

**Goal:** Any visitor to `login.empowered.vote` can create an Inform Account in under a minute â€” they see the login page with a clear "Create an Account" CTA, learn what Inform means before committing, and complete a three-field signup form that needs no invite code.

**Dependencies:** Phase 66 (inform_profiles DB trigger must exist so signup creates the row automatically)

**Requirements:** LHUB-01, LHUB-02, ISUP-01, ISUP-02, ISUP-03, ISUP-04

**Plans:** 3 plans

Plans:

- [ ] 67-01-PLAN.md â€” Login page: yellow "Create an Account" CTA + InformConstraintsModal (links to /signup/inform; secondary invite-code link to /signup)
- [ ] 67-02-PLAN.md â€” InformSignup.tsx page at /signup/inform: 3-field form (display name + email + password, no invite code); yellow "Check your email" success screen with Inform Account pill
- [ ] 67-03-PLAN.md â€” Backend: persist display_name to public.users on Inform path via pool.query() UPDATE in POST /api/auth/signup (non-fatal; no schema change)

**Success Criteria:**

1. An unauthenticated visitor to `login.empowered.vote` sees the login form and a visible "Create an Account" CTA without scrolling.
2. Clicking "Create an Account" opens a modal that accurately describes Inform Account capabilities â€” full Inform feature access, observable Connected/Empowered features (read-only), yellow gems only â€” with an "I have an invite code" link for users who want a Connected Account instead.
3. The signup form following the modal collects exactly three fields â€” display name, email, and password â€” with no invite code field present anywhere on the form.
4. After submission, a "Check your email" screen renders with yellow Inform Account theming (yellow accent color, "Inform Account" label) and shows the user's email address.
5. After email confirmation, the user is redirected to `login.empowered.vote/profile` and their session reflects an Inform-tier account (no `connected_profiles` row exists).

---

#### Phase 68: Yellow Inform Profile Page + Connected Explainer

**Goal:** An Inform user's profile page at `login.empowered.vote/profile` feels complete and personal â€” yellow-themed, showing their compass calibration and Essentials location, with Connected/Empowered tiles visible but clearly locked, and an invitational (never pressured) path toward Connected when they are ready.

**Dependencies:** Phase 66 (inform_profile data on /me); Phase 67 (Inform signup creates the account that lands here)

**Requirements:** IPRO-01, IPRO-02, IPRO-03, IPRO-04, IPRO-05, IPRO-06, CEXP-01, CEXP-02, CEXP-03

**Plans:** 2 plans

Plans:

- [ ] 68-01-PLAN.md â€” Create ConnectedExplainerModal.tsx: focused dialog explaining Connected tier (identity verification, Alpha invite codes) with "I have an invite code â†’" CTA to /signup
- [ ] 68-02-PLAN.md â€” Extend ProfilePage.tsx for Inform tier: type, compass fetch enablement, clickable Inform badge, locked Connect tiles, last-essentials-location display, IPRO-06 bottom section, modal wiring

**Success Criteria:**

1. An Inform-tier user viewing `login.empowered.vote/profile` sees a yellow-themed page â€” the "Inform Account" badge, gem display, and feature tile accents all use the `ev-yellow` (`#FED12E`) color token; the structural layout (wide desktop borders, tile grid) matches the existing Connected profile.
2. The profile header displays the user's display name, a yellow "Inform Account" pill, and their current yellow gem balance; clicking the pill opens the Connected Account explainer dialog.
3. The Compass tile shows the user's calibration count (e.g., "12 topics calibrated") or a prompt to start if count is 0; the Essentials tile shows the last searched location from `inform_profiles.last_essentials_location` or a "Explore Essentials" prompt if null.
4. Connected and Empowered feature tiles are rendered in an observable locked state â€” the tile names and icons are visible, a lock indicator is present, but the tiles are not interactive; tiles are not hidden.
5. The explainer dialog accurately describes what Connected Accounts are, how identity verification works in Alpha (invite network), and includes a clear "I have an invite code" CTA that links to the existing Connected signup flow.
6. A subtle "Connect your account" section appears at the page bottom with minimal visual prominence and copy framed as "when you're ready" â€” no urgency language, no repeated CTAs above the fold.

---

<details>
<summary>âœ… v2.2 TIGER District Geofencing (Phases 69â€“71) â€” SHIPPED 2026-05-10</summary>

- [x] Phase 69: TIGER Schema + Data Import (2/2 plans) â€” completed 2026-05-10
- [x] Phase 70: Geofencing Backend Integration (4/4 plans) â€” completed 2026-05-10
- [x] Phase 71: School Districts + Profile Display (2/2 plans) â€” completed 2026-05-10

Full details: `.planning/milestones/v2.2-ROADMAP.md`

</details>

### v2.3 US Senate Coverage (Phases 72â€“74)

---

#### Phase 72: Senate Infrastructure

**Goal:** All 50 US states have the district and government records needed to anchor senator office links â€” NATIONAL_UPPER districts and government stubs are in place for every state so Phase 73 can create offices without FK gaps.

**Dependencies:** None (foundation phase; Phase 73 depends on this)

**Requirements:** SINF-01, SINF-02

**Plans:** 1 plan expected

**Success Criteria:**

1. `SELECT COUNT(*) FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER'` returns exactly 50 â€” one row per US state, including the 45 new state entries added alongside the existing CA, IN, MA, ME, TX rows.
2. Every NATIONAL_UPPER district row has a valid `government_id` FK â€” `SELECT COUNT(*) FROM essentials.districts d LEFT JOIN essentials.governments g ON g.id = d.government_id WHERE d.district_type = 'NATIONAL_UPPER' AND g.id IS NULL` returns 0.
3. All 50 states have a row in `essentials.governments` â€” states that previously had no record have minimal stubs sufficient for the FK constraint (name + state abbreviation at minimum).
4. All migrations apply cleanly in sequence starting from migration 171 with no FK violations or constraint errors.

---

#### Phase 73: Senator Records

**Goal:** All 100 sitting 119th Congress US Senators exist as politician records with offices, district links, and photos â€” the data layer is complete so compass stances written in Phase 74 have valid FK targets and Essentials can surface senators in the representatives feed.

**Dependencies:** Phase 72 (NATIONAL_UPPER districts and government stubs must exist before offices can FK to them)

**Requirements:** SENA-01, SENA-02, SENA-03

**Plans:** 2 plans

Plans:

- [x] 73-01-PLAN.md â€” migration 175: insert 42 new senators (AKâ€“MS) + photo backfill for 4 existing CA/IN senators
- [x] 73-02-PLAN.md â€” migration 176: insert 48 new senators (MTâ€“WY, incl. 2 appointed) + photo backfill for 6 existing MA/ME/TX senators

**Success Criteria:**

1. `SELECT COUNT(*) FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_UPPER'` returns exactly 100 â€” two senators per state, all 50 states covered.
2. Every senator office row has a `district_id` that resolves to a `NATIONAL_UPPER` district â€” `SELECT COUNT(*) FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_UPPER' AND d.id IS NULL` returns 0.
3. `SELECT COUNT(*) FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_UPPER' AND (p.photo_origin_url IS NULL OR p.photo_origin_url = '')` returns 0 â€” every senator has a non-empty photo URL from the official Senate website or Wikipedia.
4. The 10 existing CA, IN, MA, ME, TX senators appear in the result set and have not been duplicated â€” total senator count remains exactly 100.

---

#### Phase 74: Stance Research + Ingestion

**Goal:** All 100 US Senators have sourced stance data across every applicable CompassV2 topic â€” users in any US state can open the compass compare view and see their senators' positions with citations, and the 8 existing senators with partial data have their gaps filled.

**Dependencies:** Phase 73 (all 100 senator politician records must exist before `inform.politician_answers` and `inform.politician_context` rows can reference them)

**Requirements:** SSTA-01, SSTA-02, SSTA-03

**Plans:** 2â€“3 plans expected (batched by party, state grouping, or alphabetically)

**Success Criteria:**

1. `SELECT COUNT(DISTINCT politician_id) FROM inform.politician_answers pa JOIN essentials.offices o ON o.politician_id = pa.politician_id JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_UPPER'` returns 100 â€” every senator has at least one stance record.
2. For each senator, `SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = <id>` returns >= 30 â€” all applicable federal-tier CompassV2 topics are covered; local-only topics (city council, school board) are intentionally excluded.
3. Every stance record has a paired context row: `SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id WHERE pc.id IS NULL AND pa.politician_id IN (SELECT DISTINCT politician_id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_UPPER')` returns 0.
4. Every context row has at least one source URL: `SELECT COUNT(*) FROM inform.politician_context WHERE politician_id IN (...senators...) AND (sources IS NULL OR array_length(sources, 1) = 0)` returns 0.
5. The 8 existing senators with partial stances (CA, IN, MA, ME, TX minus the 2 fully covered) show stance counts >= 30, matching the full coverage of newly added senators â€” no senator has a lower topic count than any other.

---

<details>
<summary>âœ… v2.4 2026 Senate Candidates (Phases 75â€“76) â€” SHIPPED 2026-05-22</summary>

- [x] Phase 75: Race Catalog + Candidate Records (1/1 plans) â€” completed 2026-05-22
- [x] Phase 76: Candidate Stance Research (4/4 plans) â€” completed 2026-05-22

Full details: `.planning/milestones/v2.4-ROADMAP.md` (to be created at milestone close)

</details>

### v2.5 City Officials Expansion (Phases 77â€“78) â€” SHIPPED 2026-06-02

---

#### Phase 77: City Infrastructure + Official Records

**Goal:** San Jose, San Diego, Berkeley, and Fremont each have a government stub, a full set of city council district seats, and politician + office records for every mayor, council member, and key appointed role â€” the data foundation needed for stance research in Phase 78.

**Dependencies:** None (foundation phase for v2.5; Phase 78 depends on this)

**Requirements:** CITY-01, CITY-02, CITY-03, CITY-04, CITY-05, CITY-06, CITY-07, CITY-08

**Status:** âœ… COMPLETE 2026-05-23

**Plans:** 2/2 plans complete

Plans:

- [x] 77-01-PLAN.md â€” Apply SJ government + officials + headshots (SD/Berkeley/Fremont already shipped in migrations 207â€“215)
- [x] 77-02-PLAN.md â€” Verify CITY-01 through CITY-08 across all 4 cities

**Planner note (2026-05-23):** Original 3-wave sketch consolidated into 2 plans because San Diego, Berkeley, and Fremont infrastructure was already applied in migrations 207â€“215 during prior work sessions. Only San Jose work remains. Wave structure in PLAN.md files reflects this: 77-01 (Wave 1, SJ work), 77-02 (Wave 2, verification across all 4 cities). District type uses LOCAL + LOCAL_EXEC (existing schema) rather than CITY_COUNCIL (which is not a valid enum value).

**Success Criteria:**

1. `SELECT name FROM essentials.governments WHERE name IN ('City of San Jose', 'City of San Diego', 'City of Berkeley', 'City of Fremont')` returns 4 rows â€” each city has exactly one government stub row, with no duplicates.
2. `SELECT COUNT(*) FROM essentials.districts WHERE district_type = 'CITY_COUNCIL' AND government_id IN (SELECT id FROM essentials.governments WHERE name IN ('City of San Jose', 'City of San Diego', 'City of Berkeley', 'City of Fremont'))` returns the correct total seat count across all 4 cities (San Jose 10 + San Diego 9 + Berkeley 8 + Fremont 7 = 34, or the verified current counts), with every district row FK'd to its city's government row.
3. Every new politician record has a corresponding office row in `essentials.offices` linked to the correct city council district (or a city-wide `CITY_COUNCIL` district for mayor and at-large seats) â€” `SELECT COUNT(*) FROM essentials.offices o LEFT JOIN essentials.districts d ON d.id = o.district_id WHERE o.politician_id IN (new city politicians) AND d.id IS NULL` returns 0.
4. `SELECT COUNT(*) FROM essentials.politicians WHERE id IN (new city politicians) AND (photo_origin_url IS NULL OR photo_origin_url = '')` returns 0 â€” every new official has a non-empty photo URL, or has a documented "no source found" entry noted in the migration comments.

---

#### Phase 78: City Stance Research

**Goal:** Every San Jose, San Diego, Berkeley, Sacramento, and Fremont official has sourced stance data across all 42 applicable CompassV2 topics (data-centers excluded for city officials) â€” users in those cities can open the compass compare view and see local officials' positions with citations, mirroring the SF officials pattern established in Phase 76. Fremont (CSTA-04) is pre-completed via migration 219 (56 stances); Sacramento is added as an informal 5th city extending CSTA-04 per CONTEXT.md D-01.

**Dependencies:** Phase 77 (politician records must exist in `essentials.politicians` before `inform.politician_answers` rows can reference them)

**Requirements:** CSTA-01, CSTA-02, CSTA-03, CSTA-04, CSTA-05 â€” all closed.

**Status:** COMPLETE 2026-06-02 â€” 591 stance rows across 4 cities. SD: 184 stances; Berkeley: 154 stances (migration 256); Fremont: 56 stances (migration 219); SJ: Matt Mahan only. CSTA-05 verified: 0 orphans.

---

<details>
<summary>âœ… v2.6 Data Quality & Elections (Phases 87â€“90, 99) â€” SHIPPED 2026-06-05</summary>

- [x] Phase 87: Stance Accuracy Audit + Agent Update (2/2 plans) â€” completed 2026-06-02
- [x] Phase 88: Stance Corrections + Party Normalization (5/5 plans) â€” completed 2026-06-03
- [x] Phase 89: Gap-fill Existing Politicians (3/3 plans) â€” completed 2026-06-04
- [x] Phase 90: Campaign Finance Schema + Ingestion + API (3/3 plans) â€” completed 2026-06-04
- [x] Phase 99: Elections Verification + Polish (6/4 plans) â€” completed 2026-06-05

Full details: `.planning/milestones/v2.6-ROADMAP.md`

</details>

### v2.7 Source Integrity (Phases 100â€“104)

---

#### Phase 100: Source Coverage Audit

**Goal:** The true scope of unsourced stances is known with precision â€” a DB audit report surfaces total stances, the % sourced, and tier breakdown; a ranked target list tells us exactly which politicians to tackle first.

**Depends on:** Nothing (this phase gates all remediation phases)
**Requirements:** SRCA-01, SRCA-02
**Plans:** 1/1 plans complete
Plans:

- [x] 100-01-PLAN.md â€” Build run-source-coverage-audit.ts; run against live DB; produce 100-AUDIT-REPORT.md (SRCA-01) and 100-TARGET-LIST.csv (SRCA-02)

**Success Criteria** (what must be TRUE):

1. A query-based audit report exists showing: total rows in `inform.politician_answers`, count and percentage of rows with at least one non-placeholder URL in the paired `inform.politician_context.sources[]`, broken down by politician tier (Federal / State / Local / City).
2. The definition of "sourced" is operationalized and documented â€” a stance counts as sourced only when its context row exists AND `sources` is non-null AND contains at least one URL that is not empty or a placeholder string.
3. A prioritized target list exists naming every politician with any unsourced stances, ranked federal â†’ state â†’ local â†’ city within tier, with a flag on politicians where the majority of stances are unsourced (likely requiring full re-research rather than spot remediation).
4. Politicians added in v2.3 (senators, 100 politicians), v2.4 (2026 candidates), v2.5 (city officials), and migration 269â€“271 (MD officials) are each explicitly represented in the report so their sourcing state is visible before remediation begins.

---

#### Phase 101: Federal Senate Remediation

**Goal:** Every US Senator stance is backed by a real primary source URL or has been permanently deleted â€” no senator has a stance row in the DB that cannot be traced to a specific Chair text.

**Depends on:** Phase 100 (target list required to scope this phase)
**Requirements:** FEDX-01, QUAL-01, QUAL-02
**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 101-01-PLAN.md â€” Senator-specific source triage: weak-source + unsourced query against NATIONAL_UPPER senators; outputs 101-TRIAGE-REPORT.md and 101-SENATOR-TARGETS.csv (scopes Plan 02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 101-02-PLAN.md â€” Research + migration + deletion log: run research-stances for flagged senators (one at a time), write migration 128 with UPSERTs and DELETEs, apply via psql, commit 101-DELETION-LOG.md and 101-VERIFICATION.md

**Success Criteria** (what must be TRUE):

1. `SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id WHERE pa.politician_id IN (senators) AND (pc.id IS NULL OR pc.sources IS NULL OR array_length(pc.sources,1) = 0)` returns 0 â€” every remaining senator stance has at least one source URL.
2. Every stance value added or retained during this phase was verified against the specific Chair text for that topic â€” the senator's known position matches the exact stance text, not just directional lean (QUAL-01 applied).
3. A deletion log entry exists for every stance deleted during this phase, recording: politician full_name, topic_key, former value, and reason ("no evidence found" or "value incorrect and no correcting source found") â€” QUAL-02 applied.
4. No senator has a source URL that is a placeholder, a Wikipedia disambiguation page, or a non-specific landing page â€” every URL links to a primary source (official statement, vote record, press release, floor speech).

---

#### Phase 102: Federal House Remediation

**Goal:** Every US House representative stance is backed by a real primary source URL or has been permanently deleted â€” no House rep has a stance row that cannot be traced to a specific Chair text.

**Depends on:** Phase 100 (target list scopes this phase); Phase 101 not required but typically sequential
**Requirements:** FEDX-02, QUAL-01, QUAL-02
**Plans:** 2/2 plans complete

Plans:

**Wave 1**

- [x] 102-01-PLAN.md â€” Build run-house-source-triage.ts covering NATIONAL_LOWER (expects 0 flagged) and deferred NATIONAL_UPPER candidates (Dooley/Shoffner/Alme â€” expects 3 flagged, 19 weak stances); outputs 102-TRIAGE-REPORT.md and 102-HOUSE-TARGETS.csv

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 102-02-PLAN.md â€” Research + migration + deletion log: run research-stances for the 3 deferred candidates (one at a time), write migration 269 with UPSERTs and DELETEs, apply via psql, commit 102-DELETION-LOG.md and 102-VERIFICATION.md (closes Phase 101 V2=19 deferred issue)

**Success Criteria** (what must be TRUE):

1. `SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id WHERE pa.politician_id IN (house reps) AND (pc.id IS NULL OR pc.sources IS NULL OR array_length(pc.sources,1) = 0)` returns 0 â€” every remaining House rep stance has at least one source URL.
2. Every stance value added or retained during this phase was verified against the specific Chair text for that topic â€” not directional inference (QUAL-01 applied).
3. A deletion log entry exists for every stance deleted during this phase, with politician full_name, topic_key, former value, and reason (QUAL-02 applied).
4. No House rep has a source URL that is a placeholder or non-specific page â€” every URL links to a primary source.

---

#### Phase 103: State Remediation â€” CA + MD

**Goal:** Every CA state legislator (Assembly + Senate) stance is sourced or deleted; all MD officials added in migrations 269â€“271 have brand-new, fully-sourced stance coverage researched from scratch.

**Depends on:** Phase 100 (target list scopes CA remediation; MD officials confirmed in DB)
**Requirements:** STAX-01, STAX-02, QUAL-01, QUAL-02
**Plans:** 3/3 plans complete

**Success Criteria** (what must be TRUE):

1. Every CA Assembly member and CA State Senator stance row has a paired `inform.politician_context` row with at least one real source URL, or the stance row has been deleted â€” zero unsourced CA state legislator stances remain.
2. Every MD official added in migrations 269â€“271 (MD executive branch) has stances researched and ingested from scratch using the Chair methodology â€” each stance paired with at least one real primary source URL in `inform.politician_context`.
3. Every stance value added or retained for CA legislators during this phase was verified against the specific Chair text (QUAL-01 applied); every MD stance added is likewise verified against Chair text, not inferred from party affiliation.
4. A deletion log entry exists for every CA legislator stance deleted during this phase, with politician full_name, topic_key, former value, and reason (QUAL-02 applied).

---

#### Phase 104: Local Remediation â€” City Officials

**Goal:** Every city official (SF, San Jose, San Diego, Berkeley, Fremont) stance is sourced or deleted; the complete deletion log for the entire v2.7 milestone is finalized and committed.

**Depends on:** Phase 100 (target list confirms city official sourcing state); Phases 101/102/103 deletion logs (MASTER-DELETION-LOG.md merges all four)
**Requirements:** STAX-03, QUAL-01, QUAL-02
**Plans:** 1/1 plans complete
Plans:

- [x] 104-01-PLAN.md â€” Research 2 weak-source city-official stances (Mahmood/abortion, Moreno/city-sanitation); migration 283; 104-DELETION-LOG.md; compile MASTER-DELETION-LOG.md (QUAL-02 final, v2.7 milestone)

**Success Criteria** (what must be TRUE):

1. Every SF, San Jose, San Diego, Berkeley, and Fremont city official stance row has a paired `inform.politician_context` row with at least one real source URL, or the stance has been deleted â€” zero unsourced city official stances remain.
2. Every stance value added or retained during this phase was verified against the specific Chair text for that topic (QUAL-01 applied).
3. The complete v2.7 deletion log is finalized â€” it covers every stance deleted across all remediation phases (101â€“104), with politician full_name, topic_key, former value, and reason per entry, and is committed to the repo or recorded in a migration comment (QUAL-02 final).
4. A final source-coverage query run after Phase 104 confirms the overall % sourced metric increased from the Phase 100 baseline â€” the milestone's core goal is measurably achieved.

---

### v2.8 District of Columbia Coverage (Phases 105â€“107)

---

#### Phase 105: DC Infrastructure + Official Records

**Goal:** DC government has a complete data foundation â€” government stub, all district records, ward boundary polygons for geofencing, and ~26 politician + office records with photos â€” so stance research and finance phases have valid FK targets and DC users can be geofenced to their ward.

**Depends on:** Nothing (foundation phase; Phases 106 and 107 depend on this)
**Requirements:** DCIN-01, DCIN-02, DCIN-03, DCIN-04, DCOF-01, DCOF-02, DCOF-03, DCOF-04
**Plans:** 2 plans

Plans:

- [ ] 105-01-PLAN.md â€” DCIN infrastructure: DC government stub, 19 district rows, TIGER ward import (geofence_boundaries + geo_districts), tiger_geoid backfill, RPC default extension (DCIN-01 through DCIN-04)
- [ ] 105-02-PLAN.md â€” DCOF official records: 27 DC politician + office records with photos (Mayor, Council, AG, Shadow Senators, EHN, SBOE) (DCOF-01 through DCOF-04)

**Success Criteria** (what must be TRUE):

1. `SELECT name FROM essentials.governments WHERE name = 'District of Columbia'` returns exactly 1 row â€” the DC government stub exists with no duplicates.
2. `SELECT district_type, COUNT(*) FROM essentials.districts WHERE government_id = (SELECT id FROM essentials.governments WHERE name = 'District of Columbia') GROUP BY district_type` shows 8 CITY_COUNCIL ward rows, 9 SCHOOL_BOARD rows, and 1 NATIONAL_LOWER row for the EHN at-large delegate seat â€” all FK'd to the DC government.
3. `SELECT COUNT(*) FROM essentials.geo_districts WHERE layer = 'dc_ward'` returns 8 â€” TIGER 2024 ward boundary polygons are imported with a GIST index; a point known to be in Ward 3 (e.g., Chevy Chase) resolves to the correct ward district via point-in-polygon lookup.
4. Every DC ward district has `tiger_geoid` populated so the `(tiger_geoid, district_type)` dual-column Path 0 join resolves DC users to their ward representative without a live PostGIS lookup.
5. `SELECT COUNT(*) FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE d.government_id = (SELECT id FROM essentials.governments WHERE name = 'District of Columbia') AND (p.photo_origin_url IS NULL OR p.photo_origin_url = '')` returns 0 â€” every DC official record has a non-empty photo URL.

---

#### Phase 106: DC Stance Research

**Goal:** Every DC elected official has sourced stances calibrated to the appropriate topic scope for their body â€” city-scoped topics for the Mayor, Council, and AG; education-focused topics for SBOE; DC statehood and voting rights focus for Shadow Senators and EHN â€” so DC users can compare their officials' positions in the compass.

**Depends on:** Phase 105 (all politician records must exist as FK targets)
**Requirements:** DCST-01, DCST-02, DCST-03
**Plans:** 3/3 plans complete

Plans:

- [x] 106-01-PLAN.md â€” Mayor Bowser + 13 DC Council members + AG Schwalb stance research + migration 289 (DCST-01)
- [x] 106-02-PLAN.md â€” 9 DC SBOE members stance research + migration 290 (DCST-02)
- [x] 106-03-PLAN.md â€” Shadow Senators (Strauss, Jain) full pass + EHN gap-fill + migration 291 (DCST-03)

**Cross-cutting constraints:**

- Every stance row written by this plan has a paired inform.politician_context row whose sources TEXT[] contains at least one real, non-placeholder URL

**Success Criteria** (what must be TRUE):

1. Every DC Council member, Mayor Bowser, and AG Schwalb has stance rows in `inform.politician_answers` for at least the 8 city-scope topics (housing, homelessness, climate, civil rights, childcare, immigration, taxes, voting), each paired with an `inform.politician_context` row containing at least one real source URL.
2. Every SBOE member has stance rows for at least the 3 education-scope topics (school vouchers, childcare, civil rights), each paired with a context row containing at least one real source URL.
3. Shadow Senators Paul Strauss and Michael D. Brown, and Eleanor Holmes Norton, each have stance rows for DC statehood / voting rights topics, each paired with a context row containing at least one real source URL; EHN's existing stances are verified and any gaps on applicable federal topics are filled.
4. `SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id WHERE pa.politician_id IN (DC officials) AND (pc.id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0)` returns 0 â€” zero unsourced DC official stances.

---

#### Phase 107: DC Finance

**Goal:** Eleanor Holmes Norton has FEC finance data on her politician record, and DC Mayor + Council members have DC OCF data populated where the OCF exposes machine-readable data â€” giving DC users the same finance transparency layer available for federal officials.

**Depends on:** Phase 105 (politician records must exist before finance_summary can be written to them)
**Requirements:** DCFI-01, DCFI-02
**Plans:** 1/1 plans complete
Plans:

- [x] 107-01-PLAN.md â€” EHN FEC ingestion script + DC OCF assessment/ingestion (DCFI-01, DCFI-02)

**Success Criteria** (what must be TRUE):

1. Eleanor Holmes Norton's `essentials.politicians.finance_summary` JSONB column is non-null and contains FEC data (total raised, total spent, cash on hand, cycle) fetched via the existing FEC ingestion script â€” `GET /api/essentials/politicians/:id` returns `finance_summary` for her record.
2. DC OCF data availability is assessed and documented â€” if machine-readable data is accessible, `finance_summary` is populated for Mayor Bowser and at least the DC Council members with available data; if OCF does not expose structured data, the assessment result is recorded and DCFI-02 is marked complete with the documented finding.
3. No DC official's `finance_summary` is populated with fabricated or placeholder data â€” every populated field comes from a fetched real source (FEC API or DC OCF), or the field is null with the gap documented.

---

<details>
<summary>âœ… v2.10 Virginia Coverage + LA County Finance (Phases 109â€“113) â€” SHIPPED 2026-06-11</summary>

- [x] Phase 109: LA County Finance (4/4 plans) â€” completed 2026-06-09
- [x] Phase 110: VA Official Records + Geofencing (no formal plans, tracked in STATE.md) â€” completed 2026-06-09
- [x] Phase 111: VA State Stances - Senators (5/5 plans) â€” completed 2026-06-10
- [x] Phase 112: VA Delegate Stances (10/10 plans) â€” completed 2026-06-11
- [x] Phase 113: VA Federal Stances + Finance (2/2 plans) â€” completed 2026-06-11

Full details: `.planning/milestones/v2.10-ROADMAP.md`

Known gap: VAST-01 (VA state executives) deferred cross-team to Essentials Phase 106.

---

#### Phase 109: LA County Finance

**Goal:** Every LA County city official seeded in Phase 108 has campaign finance data populated where accessible machine-readable sources exist.

**Depends on:** Phase 108 (politician records must exist as FK targets; finance_summary column already exists from v2.6)
**Requirements:** LAFI-01, LAFI-02
**Plans:** 4/4 plans complete
Plans:
**Wave 1**

- [x] 109-01-PLAN.md â€” Scaffold verify-la-county-109.sql SQL phase gate (LAFI-01 + LAFI-02 assertions)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 109-02-PLAN.md â€” LA City Socrata: extend seed script for Lattimore, ingest, write finance_summary for LA City officials (LAFI-01)
- [x] 109-03-PLAN.md â€” LA County Netfile: probe 26 cities, seed confirmed sources, ingest, write finance_summary (LAFI-02)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 109-04-PLAN.md â€” Phase gate: run verify SQL, API smoke tests, human sign-off (LAFI-01 + LAFI-02)

**Success Criteria** (what must be TRUE):

1. CAL-ACCESS data is assessed and ingested for LA City Mayor, all LA City Council members, the City Controller, and the City Clerk â€” each official's `finance_summary` JSONB column is populated with total raised, total spent, and cycle data, or the field is null with the gap documented.
2. Netfile is assessed for other LA County cities seeded in Phase 108; finance data is ingested for every city where machine-readable data is accessible â€” or a documented finding explains why each unavailable source was skipped (consistent with DC OCF pattern).
3. `GET /api/essentials/politicians/:id` returns `finance_summary` for all populated LA officials â€” no 500 errors, correct shape matches the existing FEC structure.
4. No `finance_summary` field contains fabricated or placeholder data â€” every populated entry is traceable to a fetched real source (CAL-ACCESS or Netfile), or the field is null.

---

#### Phase 110: VA Official Records + Geofencing

**Goal:** Virginia has a complete data foundation â€” 100 House delegates and 11 federal House reps committed to the DB, all officials have photos, and TIGER SLDL/SLDU polygon boundaries are imported so VA users can be geofenced to their delegate and senate districts via Path 0.

**Depends on:** Nothing (foundation phase; Phases 111-113 depend on this)
**Requirements:** VAIN-01, VAIN-02, VAIN-03, VAGE-01, VAGE-02, VAGE-03
**Plans:** 2 plans

Plans:

- [ ] 113-01-PLAN.md â€” Phase gate SQL scaffold (verify-va-federal-113.sql): VAST-04, VAST-05, VAFI-01, VAFI-02 assertions
- [ ] 113-02-PLAN.md â€” FEC finance ingestion for 11 VA House reps (VAFI-01) + VPAP assessment (VAFI-02)

**Success Criteria** (what must be TRUE):

1. SELECT on STATE_LOWER VA districts returns 100 â€” all VA House delegate records exist with correct office-to-district links.
2. SELECT on NATIONAL_LOWER VA districts returns 11 â€” all VA federal House rep records exist.
3. `SELECT COUNT(*) FROM essentials.geo_districts WHERE layer = 'va_sldl'` returns 100 and `SELECT COUNT(*) FROM essentials.geo_districts WHERE layer = 'va_sldu'` returns 40 â€” TIGER 2024 VA SLDL and SLDU boundary polygons are imported with GIST indexes.
4. tiger_geoid is backfilled on all VA STATE_LOWER and STATE_UPPER district records for dual-column Path 0 join â€” SELECT on NULL tiger_geoid for VA legislative districts returns 0.
5. Every new VA official (executives, senators, delegates, House reps) has a non-empty photo_origin_url â€” SELECT for NULL/empty photo returns 0.

---

#### Phase 111: VA State Stances - Senators

**Goal:** All 40 VA state senators have sourced stance data across applicable CompassV2 topics â€” every stance paired with a real source URL in politician_context.

**Note:** VAST-01 (state execs â€” Spanberger, Hashmi, Jones) is owned by Essentials Phase 106 per cross-team coordination (2026-06-09). Phase 111 covers senators only.

**Depends on:** Phase 110 (politician records must exist as FK targets)
**Requirements:** VAST-02, VAST-05
**Plans:** 5/5 plans complete

**Success Criteria** (what must be TRUE):

1. Every VA state senator has at least one stance record â€” SELECT COUNT(DISTINCT politician_id) for STATE_UPPER VA districts in inform.politician_answers returns 40.
2. SELECT on unsourced stances for VA senators returns 0 â€” every stance has a paired context row with at least one real source URL.
3. Every stance value is verified against the specific Chair text â€” never inferred from party affiliation; honest-skip applied where no documentable evidence exists.

---

#### Phase 112: VA Delegate Stances âœ… COMPLETE 2026-06-11

**Goal:** All 100 VA House delegates have sourced stance data across applicable CompassV2 topics â€” honest-skip applied where no documentable evidence exists, every retained stance backed by a real source URL.

**Depends on:** Phase 110 (delegate politician records must exist as FK targets)
**Requirements:** VAST-03 âœ…, VAST-05 âœ…
**Plans:** 10/10 plans executed
Plans:
**Wave 1**

- [x] 112-01-PLAN.md â€” Wave 1: Southwest VA HD-43â€“52 (migration 331)
- [x] 112-02-PLAN.md â€” Wave 2: Southwest HD-53â€“55 + Central HD-37â€“42 (migration 332, non-contiguous IN)
- [x] 112-03-PLAN.md â€” Wave 3: Central HD-31â€“36 + Piedmont East HD-56â€“59 (migration 333, non-contiguous IN)
- [x] 112-04-PLAN.md â€” Wave 4: Hampton Roads HD-60â€“69 (migration 334)
- [x] 112-05-PLAN.md â€” Wave 5: Hampton Roads HD-70â€“75 + Richmond HD-76â€“79 (migration 335, non-contiguous IN)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 112-06-PLAN.md â€” Wave 6: Richmond Metro HD-80â€“89 (migration 336) â€” completed 2026-06-10
- [x] 112-07-PLAN.md â€” Wave 7: Richmond/Southside Hampton Roads HD-90â€“100 (migration 337) â€” completed 2026-06-10
- [x] 112-08-PLAN.md â€” Wave 8: NoVA Outer Suburbs HD-17â€“30, HD-20 Vacant skip (migration 338) â€” completed 2026-06-10
- [x] 112-09-PLAN.md â€” Wave 9: NoVA Core HD-1â€“10 (migration 339) â€” completed 2026-06-10
- [x] 112-10-PLAN.md â€” Wave 10: NoVA Fairfax/PW HD-11â€“16 + phase gate (migration 340) â€” completed 2026-06-10

**Success Criteria** (what must be TRUE):

1. Delegates with at least one documentable stance appear in `inform.politician_answers` â€” delegates with zero public evidence are honestly skipped and not present in that table.
2. SELECT on unsourced stances for VA delegates returns 0 â€” every delegate stance that was written has at least one real source URL in inform.politician_context.
3. Every stance value is verified against the specific Chair text â€” never inferred from party affiliation; honest-skip documented where no evidence found.
4. Research is batched (one agent at a time, max 2 concurrent) â€” no mass parallel launches.

---

#### Phase 113: VA Federal Stances + Finance

**Goal:** All 11 VA federal House reps have sourced stances across applicable federal CompassV2 topics and FEC finance data populated; VPAP is assessed for VA state officials and finance data ingested where machine-readable.

**Depends on:** Phase 110 (VA federal House rep politician records must exist as FK targets)
**Requirements:** VAST-04, VAST-05, VAFI-01, VAFI-02
**Plans:** 2 plans âœ… COMPLETE 2026-06-11

Plans:

- [x] 113-01-PLAN.md â€” Phase gate SQL scaffold (verify-va-federal-113.sql): VAST-04, VAST-05, VAFI-01, VAFI-02 assertions
- [x] 113-02-PLAN.md â€” FEC finance ingestion for 11 VA House reps (VAFI-01) + VPAP assessment (VAFI-02)

**Success Criteria** (what must be TRUE):

1. All 11 VA federal House reps have stance rows in `inform.politician_answers` for applicable federal CompassV2 topics (minimum 20 topics per rep where evidence exists), each paired with an `inform.politician_context` row containing at least one real source URL.
2. SELECT on unsourced stances for VA federal reps returns 0 â€” every VA federal rep stance has a paired context row with at least one real source URL.
3. All 11 VA federal House reps have non-null `finance_summary` on `essentials.politicians` with FEC data (total raised, total spent, cash on hand, cycle) fetched via the existing FEC ingestion script.
4. VPAP (vpap.org) is assessed for VA Governor, Lt. Governor, AG, and state senators â€” finance data ingested where machine-readable structured data is accessible; non-machine-readable sources documented as findings (consistent with DC OCF pattern for VAFI-02).

</details>

<details>
<summary>✅ v2.11 FEC Finance Completion + US House Geofencing (Phases 114–116) — SHIPPED 2026-06-12</summary>

- [x] Phase 114: fec-script-fix-and-sitting-members (1/1 plan) — completed 2026-06-11
- [x] Phase 115: senate-candidate-fec-research (1/1 plan) — completed 2026-06-12
- [x] Phase 116: national-us-house-tiger (1/1 plan) — completed 2026-06-12

Full details: `.planning/milestones/v2.11-ROADMAP.md`

</details>

<details>
<summary>✅ v2.12 MA Expansion (Phases 117–118) — SHIPPED 2026-06-15</summary>

- [x] Phase 117: MA City Official Stances (3/3 plans) — completed 2026-06-14
  - Plan 01: Boston + Cambridge (migrations 574, 575)
  - Plan 02: Worcester + Springfield (migrations 576, 577)
  - Plan 03: Lowell + Brockton + Quincy (migrations 584, 589, 597)
- [x] Phase 118: MA TIGER Geofencing (3/3 plans) — completed 2026-06-15
  - Plan 01: tiger_geoid backfill for 200 MA state legislative districts (migration 619)
  - Plan 02: Medford geo_id fix + city tiger_geoid backfill (migration 622)
  - Plan 03: Phase gate — all MAGE-00..05 pass; Path 0 Porter Square verified

Full details: `.planning/milestones/v2.12-ROADMAP.md`

</details>

### v2.13 MA City Council District Geofencing (Phase 119)

---

#### Phase 119: MA City Council District Geofencing

**Goal:** Boston, Worcester, Springfield, Lowell, Brockton, and Quincy city council district-based councillors are geofenced via per-ward boundary polygons so a user's address resolves to their specific ward representative (not just the citywide district). Boston's existing X0013 boundaries get a tiger_geoid backfill; the other 5 cities get new per-ward district rows, city GIS ward boundary polygons imported into geofence_boundaries, politician–district re-linking, and tiger_geoid backfill.

**Depends on:** Phase 118 (MA TIGER geofencing infrastructure and tiger_geoid pattern established)
**Requirements:** MAGE-10, MAGE-11, MAGE-12, MAGE-13, MAGE-14, MAGE-15
**Plans:** 4 plans

Plans:

- [x] 119-01-PLAN.md — Boston tiger_geoid backfill (migration 659) ✅
- [x] 119-02-PLAN.md — Worcester boundary import script + migration 660 ✅ MAGE-11
- [x] 119-03-PLAN.md — Springfield/Lowell/Brockton/Quincy shared script + migrations 661-664 ✅ MAGE-12..15
- [x] 119-04-PLAN.md — Phase gate verification (8 assertions + Path 0 spot checks for all 6 cities) ✅ MAGE-10..15

**Success Criteria** (what must be TRUE):

1. Boston: all 9 district council district rows have `tiger_geoid` populated — Path 0 routes a user in District 3 (South Boston) to exactly the District 3 councillor row.
2. Worcester, Springfield, Lowell, Brockton, Quincy: per-ward district rows exist in `essentials.districts` (one per ward/district seat), each with a matching polygon in `essentials.geofence_boundaries`, and `tiger_geoid` backfilled — Path 0 routes a user to their ward-specific councillor.
3. At-large councillors in all 6 cities remain linked to the citywide district row (no regression).
4. Cambridge: unchanged (at-large council, no district rows needed).
5. `SELECT COUNT(*) FROM essentials.districts WHERE state = 'ma' AND mtfcc IS NOT NULL AND tiger_geoid IS NULL` returns 0 — no orphaned per-ward rows without a backfilled tiger_geoid.

### v2.14 MA City Expansion Wave 2 (Phases 120–124)

---

#### Phase 120: MA City Officials Seeding

**Goal:** All 7 new MA cities have complete district, politician, and office records in the database so every subsequent phase has valid FK targets for stance and geofencing work.

**Depends on:** Phase 119 (MA geofencing infrastructure established; migration numbering context)
**Requirements:** MAOF-01, MAOF-02, MAOF-03, MAOF-04, MAOF-05, MAOF-06, MAOF-07
**Plans:** 2 plans

Plans:

- [x] 120-01-PLAN.md — Newton tiger_geoid backfill (migration 687) + apply
- [x] 120-02-PLAN.md — Phase gate: 9 SQL assertions confirming MAOF-01..07 fulfilled

**Success Criteria** (what must be TRUE):

1. Newton: district rows committed; politician records for all council members and mayor; office rows linking politicians to districts; migration applied.
2. Somerville: same complete stack (districts, politicians, offices) committed and applied.
3. Lynn, Fall River, Waltham, Medford, New Bedford: same complete stack for each city, each in its own migration, all applied.
4.  returns > 0 for every city.
5. Zero politician records in this batch have NULL office links; zero district rows have NULL chamber_id.

---

#### Phase 121: Stance Research Wave 1 — Newton, Somerville, Medford

**Goal:** Newton, Somerville, and Medford officials have sourced stance + context rows so their representatives appear with compass alignment data in the representatives feed.

**Depends on:** Phase 120 (politician records must exist as FK targets)
**Requirements:** MAST-01, MAST-02, MAST-06
**Plans:** 2/2 plans complete

Plans:

- [x] 121-01-PLAN.md — Research Liz Mullane + migration 700 (MAST-06) — completed 2026-06-16
- [x] 121-02-PLAN.md — Phase gate SQL assertions + MAST-01/02/06 checkboxes

**Success Criteria** (what must be TRUE):

1. Newton: every official has at least one stance row, or an explicit honest-skip entry in the migration; every stance row has a paired  row with a non-placeholder source URL.
2. Somerville: same sourced stance + context coverage, honest-skip documented where no record found.
3. Medford: same sourced stance + context coverage; Chair methodology applied; no stance inferred from party affiliation.
4. Migration(s) applied to production;  (stance count per city) returns > 0 for all three cities.
5. No unsourced stance rows: zero  rows for these officials where  is NULL or contains only placeholder text.

---

#### Phase 122: Stance Research Wave 2 — Lynn, Fall River, Waltham, New Bedford

**Goal:** Lynn, Fall River, Waltham, and New Bedford officials have sourced stance + context rows, completing the full 7-city stance coverage for v2.14.

**Depends on:** Phase 120 (politician records); Phase 121 complete (wave 1 methodology validated)
**Requirements:** MAST-03, MAST-04, MAST-05, MAST-07
**Plans:** TBD

**Success Criteria** (what must be TRUE):

1. Lynn: all officials have sourced stances or documented honest-skips; every stance row has a real source URL in .
2. Fall River: same sourced stance + context coverage.
3. Waltham: same sourced stance + context coverage.
4. New Bedford: same sourced stance + context coverage; Chair methodology applied; no party-inference stances.
5. All 7 v2.14 cities combined: stance count increases from 0 to >= 1 per official with accessible public record; honest-skip log documents every skipped official with reason.

---

#### Phase 123: Ward Geofencing for All 7 Cities

**Goal:** All 7 new MA cities have ward/district boundary polygons imported into  and ;  backfilled on all per-ward district rows; Path 0 join resolves a user address in each city to their ward councillor.

**Depends on:** Phase 120 (district rows with correct geo_ids must exist before tiger_geoid backfill)
**Requirements:** MAGE-16, MAGE-17, MAGE-18, MAGE-19, MAGE-20, MAGE-21, MAGE-22
**Plans:** 4 plans

Plans:

- [x] 123-01-PLAN.md — Extend load-ma-ward-boundaries.ts + import ward polygons for all 7 cities (54 total)
- [x] 123-02-PLAN.md — Migrations 706-709: Newton/Somerville/Lynn (re-links) + Fall River (at-large, no re-links)
- [x] 123-03-PLAN.md — Migrations 710-712: Waltham (re-links) + Medford (at-large) + New Bedford (re-links)
- [x] 123-04-PLAN.md — Phase gate SQL (7 MAGE assertions) + Path 0 human verify for all 7 cities — human approved 2026-06-16

**Success Criteria** (what must be TRUE):

1. Newton (MAGE-16): ward polygons imported; tiger_geoid backfilled on district rows; Path 0 SQL assertion returns the correct ward councillor for a Newton ward address.
2. Somerville (MAGE-17): ward polygons imported; tiger_geoid backfilled; Path 0 verified.
3. Lynn (MAGE-18), Fall River (MAGE-19), Waltham (MAGE-20): ward polygons imported; tiger_geoid backfilled; Path 0 verified for each city.
4. Medford (MAGE-21), New Bedford (MAGE-22): ward polygons imported; tiger_geoid backfilled; Path 0 verified for each city.
5. tiger_geoid IS NULL returns 0 across all MA city council ward district rows after all backfills.

---

#### Phase 124: Phase Gate Verification

**Goal:** All 21 v2.14 requirements are verifiably closed via SQL assertions and Path 0 spot checks for each city, producing a phase gate script that serves as the permanent audit record.

**Depends on:** Phases 120–123 complete
**Requirements:** MAOF-01..07 (verified via SQL), MAST-01..07 (verified via SQL), MAGE-16..22 (verified via Path 0)
**Plans:** 1 plan

Plans:

- [ ] 124-01-PLAN.md — Write + run consolidated 44-assertion gate script; human-verify Path 0 for all 7 cities

**Success Criteria** (what must be TRUE):

1. A  script exists with labeled assertions covering all 7 cities across officials, stances, and geofencing.
2. Every MAOF assertion passes: district + politician + office counts match expected minimums for each city.
3. Every MAST assertion passes: stance count > 0 per city; zero unsourced stance rows (politician_context check).
4. Every MAGE assertion passes: geofence_boundaries polygon count > 0 per city; tiger_geoid backfill count = 0 orphans.
5. Path 0 human-verified for all 7 cities: a test address in each city returns the correct ward councillor via .

---

---

### v2.15 National House Rep Seeding (Tier 1) (Phases 125–126)

Geofencing is already complete (Phase 116/v2.11): 436 CD119 polygons + `tiger_geoid` on all 440 `NATIONAL_LOWER` rows. Only 137/435 House reps are seeded. This milestone fills the rep layer for the ~298 unseeded districts (≈40 states + IN/TX partials), FK-linked via `tiger_geoid`, sourced from `congress-legislators`. Stances = Tier 2 (v2.16+).

---

#### Phase 125: National House Rep Ingestion

**Goal:** Every sitting US House representative for the 50 states + DC delegate has a politician + office record FK-linked to the correct `NATIONAL_LOWER` district via `tiger_geoid`, sourced from `legislators-current.yaml` — completing the address→district→rep loop nationally.

**Depends on:** Phase 116 (national CD119 geofencing + `tiger_geoid` backfill — complete)
**Requirements:** USHR-01, USHR-02, USHR-03
**Plans:** 2 plans

Plans:

- [x] 125-01-PLAN.md — Built `seed-national-house-reps.ts`; generated migration 739 (299 matched reps; 4 excluded: dup DC + 3 vacancies) [USHR-01, USHR-03]
- [x] 125-02-PLAN.md — Applied migration 739; linked reps 137→436; idempotent; Path 0 verified; CA/VA/MA untouched [USHR-01, USHR-02, USHR-03]

**Success Criteria** (what must be TRUE):

1. An idempotent ingestion script fetches `legislators-current.yaml`, filters to current `type='rep'` terms for the 50 states + DC, and seeds politician + office records using the migration-311 pattern (shared US House chamber UUID).
2. Each seeded office links to the correct district via `tiger_geoid` (`FIPS + CD`, at-large `district 0` → suffix `00`); `representing_state` set; `politicians.office_id` backfilled.
3. Party normalized `Democrat→Democratic`; `Republican`/`Independent` pass through; no `'Democrat'` rows introduced.
4. Only currently-unseeded districts are touched (`LEFT JOIN offices WHERE politician_id IS NULL`); the 137 existing reps untouched; re-run is a no-op; zero orphan politicians (every new politician has a linked office).
5. Post-ingest, `NATIONAL_LOWER` districts with a linked rep ≈ 435 − live vacancies + DC delegate; per-state coverage matches the YAML roster.

---

#### Phase 126: Headshots + Phase Gate Verification

**Goal:** All newly-seeded House reps have headshots, and a consolidated SQL gate + Path 0 spot checks verifiably close all 5 USHR requirements, producing the permanent audit record.

**Depends on:** Phase 125 (politician records must exist)
**Requirements:** USHR-04, USHR-05
**Plans:** 2 plans

Plans:

- [x] 126-01-PLAN.md — Headshots: 292 canonical congress URLs (migration 769) + 7 official Wikimedia portraits storage-mirrored via find-headshots; 299/299 [USHR-04]
- [x] 126-02-PLAN.md — `verify-phase-125-126.sql` written + run; all USHR-01..05 assertions pass; Path 0 verified [USHR-05]

**Success Criteria** (what must be TRUE):

1. Every newly-seeded House rep has a `photo_origin_url` imported via `find-headshots`, or is logged as no-photo-found with reason.
2. A `verify-phase-125-126.sql` script exists with labeled assertions covering national rep coverage, party normalization, and orphan-politician checks.
3. Every YAML-listed current House rep (50 states + DC) resolves to a linked politician; zero `NATIONAL_LOWER` districts with a current member lack a rep.
4. Path 0 returns the correct rep for spot-check addresses across ≥5 states, including one at-large state and DC.
5. Zero orphan politicians (politician with no office) introduced by this milestone; party-normalization assertion passes (no `'Democrat'` rows among seeded reps).

---

---

### v2.16 National House Rep Stances (Tier 2) (Phases 127–131) — ✅ SHIPPED 2026-06-18

Bounded Tier 2 stance research for the 4 largest delegations — FL (27), NY (26), PA (17), IL (17) = 87 reps, 1,338 sourced answers, 0 unsourced. All USHS-01..05 closed; gate `backend/scripts/verify-phase-127-131.sql` PASS. Full detail archived → [milestones/v2.16-ROADMAP.md](milestones/v2.16-ROADMAP.md).

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-02-24 |
| 2. Auth Routes and Account Core | v1.0 | 2/2 | Complete | 2026-02-25 |
| 3. Alpha Enrollment | v1.0 | 3/3 | Complete | 2026-02-25 |
| 4. Compass Routes | v1.0 | 3/3 | Complete | 2026-02-26 |
| 5. Empower Flow | v1.0 | 2/2 | Complete | 2026-02-27 |
| 6. Gems, Roles, and Social Graph | v1.0 | 3/3 | Complete | 2026-02-27 |
| 7. Admin Tool and Calibration Cron | v1.0 | 3/3 | Complete | 2026-02-27 |
| 8. Public Candidate Pages | v1.0 | 2/2 | Complete | 2026-02-28 |
| 9. XP Schema & Core | v1.1 | 2/2 | Complete | 2026-03-04 |
| 10. XP API | v1.1 | 2/2 | Complete | 2026-03-05 |
| 11. Admin Tool XP View | v1.1 | 1/1 | Complete | 2026-03-06 |
| 12. Alpha Hardening | v1.2 | 2/2 | Complete | 2026-03-06 |
| 13. CompassV2 Backend Compatibility | v1.2 | 4/4 | Complete | 2026-03-06 |
| 14. Compass Admin Backend | v1.2 | 3/3 | Complete | 2026-03-06 |
| 15. Compass Admin React UI | v1.2 | 5/5 | Complete | 2026-03-07 |
| 16. v1.2 Gap Closure | v1.2 | 1/1 | Complete | 2026-03-07 |
| 17. Live Alpha Deployment | v1.3 | 3/3 | Complete | 2026-03-10 |
| 18. CompassV2 API Contract | v1.3 | 4/4 | Complete | 2026-03-10 |
| 19. Location Schema & RPCs | v1.3 | 3/3 | Complete | 2026-03-12 |
| 20. Location Endpoints & Validation | v1.3 | 5/5 | Complete | 2026-03-14 |
| 21. empowered_profiles Politician Schema | v1.3 | 2/2 | Complete | 2026-03-14 |
| 22. Multi-Currency Gem System | v1.3 | 2/2 | Complete | 2026-03-14 |
| 23. Central Profile Page + Admin Tier Promotion | v1.3 | 3/3 | Complete | 2026-03-14 |
| 24. Public Auth Hub (Login Rebrand + Signup Flow) | v1.3 | 2/2 | Complete | 2026-03-14 |
| 25. Deployment Runbook Completion | v1.3 | 1/1 | Complete | 2026-03-15 |
| 26. v1.3 Tech Debt Closure | v1.3 | 1/1 | Complete | 2026-03-15 |
| 27. Verification Rating Schema | v1.4 | 1/1 | Complete | 2026-03-15 |
| 28. VQ Confirmation Flow | v1.4 | 2/2 | Complete | 2026-03-15 |
| 29. Admin Controls & Integration Verification | v1.4 | 2/2 | Complete | 2026-03-15 |
| 30. Profile Hub UI | v1.4 | 2/2 | Complete | 2026-03-16 |
| 31. Referral Dashboard Card | v1.5 | 1/1 | Complete | 2026-03-19 |
| 32. CompassV2 Integration Guide | v1.5 | 1/1 | Complete | 2026-03-19 |
| 33. Essentials Integration Guide | v1.5 | 1/1 | Complete | 2026-03-19 |
| 34. Database Schema Migration | v1.6 | 3/3 | Complete | 2026-03-20 |
| 35. Politician Deduplication | v1.6 | 2/2 | Complete | 2026-03-20 |
| 36. Express Ports Wave 1 â€” Treasury + Meetings | v1.6 | 2/2 | Complete | 2026-03-20 |
| 37. Express Ports Wave 2 â€” Staging | v1.6 | 4/4 | Complete | 2026-03-20 |
| 38. Express Ports Wave 3 â€” Essentials | v1.6 | 5/5 | Complete | 2026-03-20 |
| 39. Compass Additions | v1.6 | 3/3 | Complete | 2026-03-20 |
| 40. Frontend Auth Updates | v1.6 | 5/5 | Complete | 2026-03-23 |
| 41. VQ and Trivia Migration | v1.6 | 4/4 | Complete | 2026-03-24 |
| 42. Decommission and DNS Cutover | v1.6 | 0/? | Pending | â€” |
| 43. Integration Documentation | v1.6 | 0/? | Pending | â€” |
| 44. Accounts API SSO Infrastructure | v1.7 | 2/2 | Complete | 2026-03-24 |
| 45. Profile Hub + CTC Silent SSO | v1.7 | 2/2 | Complete | 2026-03-24 |
| 46. Essentials + CompassV2 Silent SSO | v1.7 | 2/2 | Complete | 2026-03-24 |
| 47. Validation Quests Silent SSO | v1.7 | 2/2 | Complete | 2026-03-24 |
| 48. Compliance + End-to-End Verification | v1.7 | 2/2 | Complete | 2026-04-02 |
| 49. Stored Jurisdiction & Cross-App Location Profile | v1.8 | 3/3 | Complete | 2026-03-26 |
| 50. Precise Representatives for Pre-Phase-49 Users | v1.8 | 2/2 | Complete | 2026-04-01 |
| 51. Essentials XP Source Provisioning | v1.9 | 1/1 | Complete | 2026-04-02 |
| 52. Role Schema + RPC Migration | v1.9 | 1/1 | Complete | 2026-04-02 |
| 53. Service Layer + requireRole Middleware | v1.9 | 2/2 | Complete | 2026-04-03 |
| 54. Admin UI â€” Grant/Revoke + Audit Dashboard | v1.9 | 2/2 | Complete | 2026-04-03 |
| 55. Compass Stance Editor + Campaign Manager Endpoints | v1.9 | 4/4 | Complete | 2026-04-03 |
| 56. Essentials Data Editor Endpoint | v1.9 | 2/2 | Complete | 2026-04-04 |
| 57. CTC + Civic Spaces Integration | v1.9 | 2/2 | Complete | 2026-04-04 |
| 58. Contributor Portal | v1.9 | 5/5 | Complete | 2026-04-06 |
| 59. Referral Code System | â€” | 4/4 | Complete | 2026-04-08 |
| 60. Design Foundation | v2.0 | 4/4 | Complete | 2026-04-25 |
| 61. Auth Flow Restyle | v2.0 | 5/5 | Complete | 2026-04-25 |
| 62. Onboarding Restyle | v2.0 | 3/3 | Complete | 2026-04-25 |
| 63. Profile Page + Activity Feed | v2.0 | 2/2 | Complete | 2026-04-27 |
| 64. InformLanding | v2.0 | â€” | Skipped | â€” |
| 65. Dashboard Redesign | v2.0 | â€” | Skipped | â€” |
| 66. Inform Profiles Backend Foundation | v2.1 | 3/3 | Complete | 2026-04-27 |
| 67. Login Hub + Inform Signup Flow | v2.1 | 3/3 | Complete | 2026-04-27 |
| 68. Yellow Inform Profile Page + Connected Explainer | v2.1 | 2/2 | Complete | 2026-05-09 |
| 69. TIGER Schema + Data Import | v2.2 âœ… | 2/2 | Complete | 2026-05-10 |
| 70. Geofencing Backend Integration | v2.2 âœ… | 4/4 | Complete | 2026-05-10 |
| 71. School Districts + Profile Display | v2.2 âœ… | 2/2 | Complete | 2026-05-10 |
| 72. Senate Infrastructure | v2.3 | 1/1 | Complete | 2026-05-19 |
| 73. Senator Records | v2.3 | 2/2 | Complete | 2026-05-19 |
| 74. Stance Research + Ingestion | v2.3 âœ… | 3/3 | Complete | 2026-05-21 |
| 75. Race Catalog + Candidate Records | v2.4 âœ… | 1/1 | Complete | 2026-05-22 |
| 76. Candidate Stance Research | v2.4 âœ… | 4/4 | Complete | 2026-05-22 |
| 77. City Infrastructure + Official Records | v2.5 | 2/2 | Complete | 2026-05-28 |
| 78. City Stance Research | v2.5 | 6/6 | Complete | 2026-06-02 |
| 87. Stance Accuracy Audit + Agent Update | v2.6 | 2/2 | Complete | 2026-06-02 |
| 88. Stance Corrections + Party Normalization | v2.6 | 5/5 | Complete | 2026-06-03 |
| 89. Gap-fill Existing Politicians | v2.6 | 3/3 | Complete | 2026-06-04 |
| 90. Campaign Finance Schema + Ingestion + API | v2.6 | 3/3 | Complete | 2026-06-04 |
| 99. Elections Verification + Polish | v2.6 | 6/4 | Complete | 2026-06-05 |
| 100. Source Coverage Audit | v2.7 | 1/1 | Complete    | 2026-06-05 |
| 101. Federal Senate Remediation | v2.7 | 2/2 | Complete    | 2026-06-06 |
| 102. Federal House Remediation | v2.7 | 2/2 | Complete    | 2026-06-06 |
| 103. State Remediation â€” CA + MD | v2.7 | 3/3 | Complete    | 2026-06-07 |
| 104. Local Remediation â€” City Officials | v2.7 | 1/1 | Complete    | 2026-06-07 |
| 105. DC Infrastructure + Official Records | v2.8 | 2/2 | Complete | 2026-06-07 |
| 106. DC Stance Research | v2.8 | 3/3 | Complete    | 2026-06-08 |
| 107. DC Finance | v2.8 | 1/1 | Complete    | 2026-06-08 |
| 108. LA County City Officials | v2.9 | 5/5 | Complete | 2026-06-08 |
| 109. LA County Finance | v2.10 | 4/4 | Complete    | 2026-06-09 |
| 110. VA Official Records + Geofencing | v2.10 | â€” | Complete | 2026-06-09 |
| 111. VA State Stances - Senators | v2.10 | 5/5 | Complete | 2026-06-10 |
| 112. VA Delegate Stances | v2.10 | 10/10 | Complete | 2026-06-11 |
| 113. VA Federal Stances + Finance | v2.10 | 2/2 | Complete    | 2026-06-11 |
| 114. fec-script-fix-and-sitting-members | v2.11 | 1/1 | Complete | 2026-06-11 |
| 115. senate-candidate-fec-research | v2.11 | 1/1 | Complete    | 2026-06-12 |
| 116. national-us-house-tiger | v2.11 | 1/1 | Complete | 2026-06-12 |
| 117. ma-city-official-stances | v2.12 | 3/3 | Complete | 2026-06-14 |
| 118. ma-tiger-geofencing | v2.12 | 3/3 | Complete | 2026-06-15 |
| 119. MA City Council District Geofencing | v2.13 | 4/4 | Complete | 2026-06-15 |
| 120. MA City Officials Seeding | v2.14 | 2/2 | Complete ✅ | 2026-06-15 |
| 121. Stance Research Wave 1 (Newton/Somerville/Medford) | v2.14 | 2/2 | Complete   | 2026-06-16 |
| 122. Stance Research Wave 2 (Lynn/Fall River/Waltham/New Bedford) | v2.14 | 3/3 | Complete ✅ | 2026-06-16 |
| 123. Ward Geofencing — All 7 Cities | v2.14 | 4/4 | Complete ✅ | 2026-06-16 |
| 124. Phase Gate Verification | v2.14 | 1/1 | Complete ✅ | 2026-06-16 |
| 125. National House Rep Ingestion | v2.15 | 2/2 | Complete ✅ | 2026-06-16 |
| 126. Headshots + Phase Gate Verification | v2.15 | 2/2 | Complete ✅ | 2026-06-16 |
| 127. FL House Rep Stances | v2.16 | 2/2 | Complete   | 2026-06-17 |
| 128. NY House Rep Stances | v2.16 | 2/2 | Complete   | 2026-06-18 |
| 129. PA House Rep Stances | v2.16 | 2/2 | Complete | 2026-06-18 |
| 130. IL House Rep Stances | v2.16 | 2/2 | Complete | 2026-06-18 |
| 131. Phase Gate Verification | v2.16 | 1/1 | Complete | 2026-06-18 |
| 132. OH + NC House Rep Stances | v2.17 | 4/4 | Complete   | 2026-06-19 |
| 133. GA + MI House Rep Stances | v2.17 | 4/4 | Complete   | 2026-06-19 |
| 134. NJ + WA + AZ House Rep Stances | v2.17 | 6/6 | Complete   | 2026-06-19 |
| 135. TN + CO + MN + MO House Rep Stances | v2.17 | 8/8 | Complete   | 2026-06-20 |
| 136. WI + AL + SC + KY House Rep Stances | v2.17 | 8/8 | Complete   | 2026-06-20 |
| 137. LA + CT + IN + OK + AR + IA House Rep Stances | v2.17 | 6/6 | Complete   | 2026-06-20 |
| 138. KS + MS + NV + NE + NM House Rep Stances | v2.17 | 5/5 | Complete | 2026-06-20 |
| 139. Single/Low-Rep States House Rep Stances | v2.17 | 3/3 | Complete | 2026-06-20 |
| 140. Phase Gate Verification | v2.17 | 0/1 | Planned | - |
