# Roadmap: Empowered Accounts

## Milestones

- ✅ **v1.0 MVP** — Phases 1–8 (shipped 2026-02-28)
- ✅ **v1.1 XP & Progression** — Phases 9–11 (shipped 2026-03-04)
- ✅ **v1.2 CompassV2 Integration & Alpha Hardening** — Phases 12–16 (shipped 2026-03-07)
- ✅ **v1.3 Alpha Launch & Location Infrastructure** — Phases 17–26 (shipped 2026-03-15)
- ✅ **v1.4 Profile Hub & Verification Engine** — Phases 27–30 (shipped 2026-03-17)
- ✅ **v1.5 Partner Integration & Referrals** — Phases 31–33 (shipped 2026-03-19)
- 🔄 **v1.6 Platform Consolidation** — Phases 34–43 (in progress)
- ✅ **v1.7 Cross-App SSO** — Phases 44–48 (shipped 2026-04-02)
- ✅ **v1.8 Location Identity** — Phases 49–50 (shipped 2026-04-01)
- ✅ **v1.9 Roles** — Phases 51–58 (shipped 2026-04-06)
- ✅ **v2.0 Civic Account Experience** — Phases 60–65 (shipped 2026-05-10)
- ✅ **v2.1 Inform Account Tier** — Phases 66–68 (shipped 2026-05-09)
- ✅ **v2.2 TIGER District Geofencing** — Phases 69–71 (shipped 2026-05-10)
- ✅ **v2.3 US Senate Coverage** — Phases 72–74 (shipped 2026-05-21)
- ✅ **v2.4 2026 Senate Candidates** — Phases 75–76 (shipped 2026-05-22)
- ✅ **v2.5 City Officials Expansion** — Phases 77–78 (shipped 2026-06-02; Phases 79–80 rolled into v2.6)
- ✅ **v2.6 Data Quality & Elections** — Phases 87–90, 99 (shipped 2026-06-05)
- ✅ **v2.7 Source Integrity** — Phases 100–104 (shipped 2026-06-07)
- ✅ **v2.8 District of Columbia Coverage** — Phases 105–107 (shipped 2026-06-08)
- ✅ **v2.9 LA County Expansion** — Phase 108 (shipped 2026-06-08)
- ✅ **v2.10 Virginia Coverage + LA County Finance** — Phases 109–113 (shipped 2026-06-11)
- ✅ **v2.11 FEC Finance Completion + US House Geofencing** — Phases 114–116 (shipped 2026-06-12)
- ✅ **v2.12 MA Expansion** — Phases 117–118 (shipped 2026-06-15)
- ✅ **v2.13 MA City Council District Geofencing** — Phase 119 (shipped 2026-06-15)
- ✅ **v2.14 MA City Expansion Wave 2** — Phases 120–124 (shipped 2026-06-16)
- ✅ **v2.15 National House Rep Seeding (Tier 1)** — Phases 125–126 (shipped 2026-06-16)
- ✅ **v2.16 National House Rep Stances (Tier 2)** — Phases 127–131 (shipped 2026-06-18; FL/NY/PA/IL, 87 reps, 1,338 stances)
- ✅ **v2.17 National House Rep Stances (Tier 2 continuation)** — Phases 132–140 (shipped 2026-06-20; remaining 212 reps across 38 states, USHS-06..14)
- 🔄 **v2.18 State Leaders** — Phases 141–144 (in progress; elected Big 5 statewide execs, 209 offices, 50 states)

## Phases

<details open>
<summary>🔄 v2.18 State Leaders (Phases 141–144) — IN PROGRESS (209 elected Big 5 execs, 50 states; SEXR-01..05, SEXS-01..03)</summary>

### v2.18 State Leaders (Phases 141–144)

**Milestone goal:** Every US resident sees their state's elected Big 5 executives — Governor, Lt. Governor, Attorney General, Secretary of State, and Treasurer (whichever of the five their state actually elects) — in the representatives feed with sourced compass alignment, across all 50 states.

**Pure data milestone — no backend code changes.** `STATE_EXEC` is already enumerated in `essentialsService.ts` at both feed query sites (lines 669–716 and 1585–1598); seeding data makes execs appear automatically. The core challenges are scope (209 popularly elected offices, not 250) and evidence quality (exec actions differ from legislative floor votes; researcher prompt must be updated before any dispatch).

**True denominator: 209 elected offices across 50 states.** Breakdown: 50 Gov + 43 LtGov + 43 AG + 35 SoS + 38 Treasurer = 209. Remaining 41 = appointed/legislature-elected/abolished/nonexistent per the FEATURES.md matrix (each exception sourced). AZ Lt Governor is deferred (Prop 131 eff. Jan 2027) and documented as a known exclusion in the gate.

**Gap baseline at start (verified 2026-06-20):** 68 `STATE_EXEC` records across only 9 states (CA, IN, MA, MD, ME, OR, TX, UT, VA); 41 states empty; stance gaps in IN (AG/SoS/Treasurer), ME (all 4 records have 0 stances), TX (3 in-scope execs, some may lack stances). CA execs are fully stanced — never re-research them.

**Carry-forward execution methodology (for `/gsd-plan-phase`):**

- **In-scope filter:** `WHERE d.district_type = 'STATE_EXEC' AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id)` — scope to politician UUIDs, not external_id range (state exec external_ids are heterogeneous).
- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **Seed dedup key:** `(district_type='STATE_EXEC', state=XX, role_canonical)` on districts — never title string. Dry-run gap query must return 0 new rows for the 9 already-seeded states before any INSERT executes.
- **external_id scheme:** `-(state_fips * 10000 + office_seq)` per new state — verify 0 collisions against live negative IDs before authoring; document chosen scheme in migration header.
- **State code:** always uppercase 2-char postal abbreviation; include post-insert assertion (`upper(state) = state`) in every migration.
- **geo_id:** `'{state_fips}'` (string, e.g. `'48'` for TX) — never NULL or empty.
- **Stance reuse:** `_TOPIC_SCALE.txt` (25 topics, unchanged), `politician-stance-researcher` at **3-concurrency**, per-exec CSV → `_merge.ts` → external_id-keyed `_push.ts`; proxy-row review gate standard.
- **Office-type evidence guidance (SEXS-01, must precede first stance dispatch):** Governor: bill signings/vetoes/EOs; AG: filed lawsuits/amicus briefs/multistate coalitions (coalition counts ONLY when coalition has a published position directly on the topic); Treasurer: investment/divestment decisions (documented fund actions); SoS: specific election administration actions (not role description); Lt Gov: honest-partial if no independent record — never mirror Governor stances without independent sourcing.
- **Proxy-row drop rules (standing):** "overall record alignment", coalition membership without published topical platform, committee/office role description ≠ documented stance — all dropped before push.

---

#### Phase 141: Roster Lock + Seed (Records + Headshots)

**Goal:** Authoritative 209-office roster is locked, all missing elected Big 5 politician + office records are seeded across all 50 states, `role_canonical` is populated on every in-scope office, and every newly-seeded exec has a headshot.

**Depends on:** Nothing (first phase; roster lock is the gate for everything else)

**Requirements:** SEXR-01, SEXR-02, SEXR-03, SEXR-04

**Success Criteria** (what must be TRUE):

  1. A per-state table names which of the Big 5 offices are popularly elected vs. appointed/legislature-elected/nonexistent, with a cited source per non-elected exception and an officeholder name + verified URL per in-scope office — this roster is the source of truth that prevents phantom offices.
  2. All 41 previously-empty states have `STATE_EXEC` politician + office + district records for their in-scope elected Big 5; gaps in the 9 existing states (IN AG/SoS/Treasurer, UT AG/Treasurer, ME is only Gov, TX SoS is appointed so only Gov+LtGov+AG in scope) are filled or confirmed-correct; `SELECT COUNT(*) WHERE district_type='STATE_EXEC'` grows to ~208 in-scope records (plus pre-existing non-Big-5 officers untouched).
  3. `role_canonical` is populated (`governor`, `lt_governor`, `attorney_general`, `secretary_of_state`, `treasurer`) on every in-scope Big 5 office record, including backfill on pre-existing Big 5 records; role_canonical is correct for title-alias offices (FL CFO = `treasurer`, NY/TX Comptroller = `treasurer`, MA Secretary of the Commonwealth = `secretary_of_state`).
  4. Every newly-seeded exec has a headshot row in `essentials.politician_images` (column `url`), mirrored to the `politician_photos` Supabase Storage bucket per the migration-271 storage-mirror pattern (the `find-headshots` skill is not on disk; the pattern is inline in migration 271); no newly-seeded exec is headshot-free after this phase except documented honest-skips.

**Plans:** 12 plans across 3 waves (next migrations 946-957)

Wave 1 (existing-record handling, parallel):
- [x] 141-01-PLAN.md — verify-phase-141.sql gate + role_canonical backfill (8 states) + UT NULL external_id fix
- [x] 141-02-PLAN.md — IN SoS+Treasurer gap-seed (canonical-government trap) + IN role_canonical backfill

Wave 2 (41 empty-state seeds, parallel, 35 offices each):
- [x] 141-03-PLAN.md — seed batch A: AK, AL, FL, IL, MS, NC, NY, SD
- [x] 141-04-PLAN.md — seed batch B: AR, GA, HI, IA, MO, ND, OK, VT
- [x] 141-05-PLAN.md — seed batch C: CO, KS, MI, NE, NJ, OH, PA, WA
- [x] 141-06-PLAN.md — seed batch D: CT, KY, MN, NH, NV, RI, TN, WI, WV
- [x] 141-07-PLAN.md — seed batch E: AZ, DE, ID, LA, MT, NM, SC, WY

Wave 3 (headshots per batch, parallel; 141-12 runs the full gate):
- [x] 141-08-PLAN.md — headshots batch A + IN
- [x] 141-09-PLAN.md — headshots batch B
- [x] 141-10-PLAN.md — headshots batch C
- [x] 141-11-PLAN.md — headshots batch D
- [x] 141-12-PLAN.md — headshots batch E + full verify-phase-141.sql gate

---

#### Phase 142: Stance Research Wave 1 — Governors + AGs

**Goal:** The researcher prompt is updated with office-type evidence guidance before any dispatch, and all in-scope Governors (50) and Attorneys General (43) that currently lack stances have sourced compass stances, each backed by a real fetched source URL.

**Depends on:** Phase 141 (politician UUIDs must exist before stance push)

**Requirements:** SEXS-01, SEXS-02 (partial — Governors + AGs)

**Success Criteria** (what must be TRUE):

  1. The stance researcher prompt (skill/agent prompt) includes office-type-specific evidence guidance for all five exec office types (Gov, LtGov, AG, SoS, Treasurer) before the first research agent is dispatched; the guidance distinguishes bill signings/vetoes from amicus briefs from investment decisions.
  2. Every in-scope Governor and AG that lacked stances at wave start has ≥1 sourced compass stance in `inform.politician_answers`; previously-stanced execs (CA Gov Newsom, CA AG Bonta, etc.) are not touched.
  3. Every answer row for this wave has a paired `inform.politician_context` row carrying a real, fetched source URL — **zero unsourced rows** at wave close.
  4. Topics with no documentable evidence for a given exec are honest-skipped; no stance is inferred from party affiliation or "overall record alignment"; AG stances from multistate coalition membership are accepted only when the coalition has a published position directly on that topic.

**Plans:** TBD

---

#### Phase 143: Stance Research Wave 2 — SoS + Treasurer + Lt Gov

**Goal:** All in-scope Secretaries of State (35), Treasurers (38, including FL CFO / NY/TX Comptrollers), and Lieutenant Governors (43) that lack stances have sourced compass stances, closing the full SEXS-02 requirement across all 209 in-scope execs.

**Depends on:** Phase 141 (UUIDs must exist); Phase 142 recommended to be complete first so proxy-row calibration from Wave 1 carries forward, but technically independent if Wave 2 is authored after SEXS-01 prompt update lands

**Requirements:** SEXS-02 (completing — SoS + Treasurer + Lt Gov)

**Success Criteria** (what must be TRUE):

  1. Every in-scope SoS, Treasurer, and Lt Governor that lacked stances at wave start has ≥1 sourced compass stance in `inform.politician_answers`; previously-stanced execs are not touched.
  2. Every answer row for this wave has a paired `inform.politician_context` row carrying a real, fetched source URL — **zero unsourced rows** at wave close.
  3. Lt Governor honest-partials are correctly modeled: thin records produce honest-partial (4–8 topics), not zero stances; no Lt Gov stance mirrors the same-state Governor without independent sourcing.
  4. Treasurer stances are sourced from investment/divestment decisions or documented fund actions — not from budget overview page descriptions; SoS stances are sourced from specific election administration actions — not from "SoS administers elections" role descriptions.

**Plans:** TBD

---

#### Phase 144: Phase Gate — Feed Surfacing + Consolidated Verification

**Goal:** A read-only, labeled-assertion SQL gate confirms every elected Big 5 office is filled, zero unsourced stance rows exist for STATE_EXEC politicians, and state-code accessibility holds; feed surfacing is smoke-tested for at least 3 newly-seeded states.

**Depends on:** Phases 141, 142, and 143 (all seed + stance work must be complete)

**Requirements:** SEXR-05, SEXS-03

**Success Criteria** (what must be TRUE):

  1. `backend/scripts/verify-phase-141-144.sql` runs read-only against production, and every labeled assertion PASSES: all ~208 in-scope offices have a seeded politician, per-state counts match the known election matrix (ME=1, TN=1, NJ=2, AK=2, HI=2, WY=3, MD=3, TX=3, VA=3, and the known 4- and 5-office states), AZ Lt Gov is noted as deferred (not a miss), 0 answer rows lack a paired context row with a real source URL.
  2. All `STATE_EXEC` districts have an uppercase two-letter state code (`state = upper(state)`) and a non-empty `geo_id` — the gate asserts `COUNT(*) WHERE district_type='STATE_EXEC' AND (state != upper(state) OR geo_id IS NULL OR geo_id = '') = 0`.
  3. `GET /representatives/me` returns the correct newly-seeded exec for users with a stored state code in at least 3 states that had zero STATE_EXEC records before this milestone (smoke test — no backend code change required).

**Plans:** TBD

---

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 141. Roster Lock + Seed | 12/12 | Complete   | 2026-06-21 |
| 142. Stance Wave 1 (Gov + AG) | 0/TBD | Not started | - |
| 143. Stance Wave 2 (SoS + Treasurer + LtGov) | 0/TBD | Not started | - |
| 144. Phase Gate | 0/1 | Not started | - |

</details>

---

<details>
<summary>✅ v2.17 National House Rep Stances (Tier 2 continuation) (Phases 132–140) — SHIPPED 2026-06-20 (212 reps, 211 covered + 1 documented honest-skip, 0 unsourced; USHS-06..14)</summary>

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

**Goal:** A single read-only, labeled-assertion SQL script confirms all 212 in-scope US House reps (across all 38 states) have sourced stance coverage with zero unsourced rows — the consolidated proof that v2.17 is complete. — ✅ COMPLETE 2026-06-20 (1 plan; verify-phase-132-140.sql, all USHS-06..14 PASS; 211/212 covered + McDowell −37006 honest-skip, 0 unsourced).

**Depends on:** Phases 132–139 (all eight waves must be complete before the consolidated gate is meaningful)

**Requirements:** USHS-14

**Success Criteria** (what must be TRUE):

  1. `backend/scripts/verify-phase-132-140.sql` (following the `verify-phase-127-131.sql` pattern) runs read-only and every labeled assertion PASSES against production.
  2. The script asserts all 212 in-scope reps (`external_id BETWEEN -56999 AND -1000`, the v2.17 set) have ≥1 stance, and that **zero** answer rows lack a paired `inform.politician_context` row with a real source URL.
  3. Per-state coverage counts are asserted (covered = in-scope for each of the 38 states), surfacing any rep that was missed. (Refinement: OH+NC is 28/29 — McDowell NC-6 −37006 is the one documented Phase-132 honest-skip; USHS-14a pins the sole gap to exactly −37006.)

**Plans:**
- [x] 140-01-PLAN.md — verify-phase-132-140.sql authored + run; all USHS-06..14 assertions PASS (211/212 covered + McDowell honest-skip, 0 unsourced)

</details>

---

<details>
<summary>✅ v2.9 LA County Expansion (Phase 108) — SHIPPED 2026-06-08</summary>

- [x] Phase 108: LA County City Officials (5/5 plans) — completed 2026-06-08
  - Wave 1: 14 Tier 1 partial cities gap-filled with Census FIPS geo_ids
  - Wave 2: Beverly Hills (6), Santa Monica (10), LA City Controller + Clerk
  - Wave 3: 10 new cities from scratch — 52 new politicians
  - Wave 4: Phase gate SQL (8 assertions) + representatives-me smoke test

Full details: `.planning/milestones/v2.9-ROADMAP.md`

</details>

<details>
<summary>✅ v2.8 District of Columbia Coverage (Phases 105–107) — SHIPPED 2026-06-08</summary>

- [x] Phase 105: DC Infrastructure + Official Records (2/2 plans) — completed 2026-06-07
- [x] Phase 106: DC Stance Research (3/3 plans) — completed 2026-06-08
- [x] Phase 107: DC Finance (1/1 plans) — completed 2026-06-08

Full details: `.planning/milestones/v2.8-ROADMAP.md`

</details>

<details>
<summary>✅ v2.7 Source Integrity (Phases 100–104) — SHIPPED 2026-06-07</summary>

- [x] **Phase 100: Source Coverage Audit** — Audit report + prioritized target list (completed 2026-06-05)
- [x] **Phase 101: Federal Senate Remediation** — All 100 senator stances sourced or deleted (completed 2026-06-06)
- [x] **Phase 102: Federal House Remediation** — All US House rep stances sourced or deleted (completed 2026-06-06)
- [x] **Phase 103: State Remediation — CA + MD** — CA legislators sourced or deleted; MD officials researched from scratch (completed 2026-06-07)
- [x] **Phase 104: Local Remediation — City Officials** — All city official stances sourced or deleted; MASTER-DELETION-LOG.md (20 entries) finalizes QUAL-02 for v2.7 (completed 2026-06-07)

</details>

<details>
<summary>✅ v1.0 MVP (Phases 1–8) — SHIPPED 2026-02-28</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-02-24
- [x] Phase 2: Auth Routes and Account Core (2/2 plans) — completed 2026-02-25
- [x] Phase 3: Alpha Enrollment (3/3 plans) — completed 2026-02-25
- [x] Phase 4: Compass Routes (3/3 plans) — completed 2026-02-26
- [x] Phase 5: Empower Flow (2/2 plans) — completed 2026-02-27
- [x] Phase 6: Gems, Roles, and Social Graph (3/3 plans) — completed 2026-02-27
- [x] Phase 7: Admin Tool and Calibration Cron (3/3 plans) — completed 2026-02-27
- [x] Phase 8: Public Candidate Pages (2/2 plans) — completed 2026-02-28

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 XP & Progression (Phases 9–11) — SHIPPED 2026-03-04</summary>

- [x] Phase 9: XP Schema & Core (2/2 plans) — completed 2026-03-04
- [x] Phase 10: XP API (2/2 plans) — completed 2026-03-04
- [x] Phase 11: Admin Tool XP View (1/1 plan) — completed 2026-03-04

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

<details>
<summary>✅ v1.2 CompassV2 Integration & Alpha Hardening (Phases 12–16) — SHIPPED 2026-03-07</summary>

- [x] Phase 12: Alpha Hardening (2/2 plans) — completed 2026-03-06
- [x] Phase 13: CompassV2 Backend Compatibility (4/4 plans) — completed 2026-03-06
- [x] Phase 14: Compass Admin Backend (3/3 plans) — completed 2026-03-06
- [x] Phase 15: Compass Admin React UI (5/5 plans) — completed 2026-03-07
- [x] Phase 16: v1.2 Gap Closure (1/1 plan) — completed 2026-03-07

Full details: `.planning/milestones/v1.2-ROADMAP.md`

</details>

<details>
<summary>✅ v1.3 Alpha Launch & Location Infrastructure (Phases 17–26) — SHIPPED 2026-03-15</summary>

- [x] Phase 17: Live Alpha Deployment (3/3 plans) — completed 2026-03-10
- [x] Phase 18: CompassV2 API Contract (4/4 plans) — completed 2026-03-10
- [x] Phase 19: Location Schema & RPCs (3/3 plans) — completed 2026-03-12
- [x] Phase 20: Location Endpoints & Validation (5/5 plans) — completed 2026-03-14
- [x] Phase 21: empowered_profiles Politician Schema (2/2 plans) — completed 2026-03-14
- [x] Phase 22: Multi-Currency Gem System (2/2 plans) — completed 2026-03-14
- [x] Phase 23: Central Profile Page + Admin Tier Promotion (3/3 plans) — completed 2026-03-14
- [x] Phase 24: Public Auth Hub (2/2 plans) — completed 2026-03-14
- [x] Phase 25: Deployment Runbook Completion (1/1 plan) — completed 2026-03-15
- [x] Phase 26: v1.3 Tech Debt Closure (1/1 plan) — completed 2026-03-15

Full details: `.planning/milestones/v1.3-ROADMAP.md`

</details>

<details>
<summary>✅ v1.4 Profile Hub & Verification Engine (Phases 27–30) — SHIPPED 2026-03-17</summary>

- [x] Phase 27: Verification Rating Schema (1/1 plan) — completed 2026-03-15
- [x] Phase 28: VQ Confirmation Flow (2/2 plans) — completed 2026-03-15
- [x] Phase 29: Admin Controls & Integration Verification (2/2 plans) — completed 2026-03-15
- [x] Phase 30: Profile Hub UI (2/2 plans) — completed 2026-03-16

Full details: `.planning/milestones/v1.4-ROADMAP.md`

</details>

<details>
<summary>✅ v1.5 Partner Integration & Referrals (Phases 31–33) — SHIPPED 2026-03-19</summary>

- [x] Phase 31: Referral Dashboard Card (1/1 plan) — completed 2026-03-19
- [x] Phase 32: CompassV2 Integration Guide (1/1 plan) — completed 2026-03-19
- [x] Phase 33: Essentials Integration Guide (1/1 plan) — completed 2026-03-19

Full details: `.planning/milestones/v1.5-ROADMAP.md`
