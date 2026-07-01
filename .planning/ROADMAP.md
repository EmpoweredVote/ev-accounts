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
- ✅ **v2.18 State Leaders** — Phases 141–144 (shipped 2026-06-22; elected Big 5 statewide execs, 209 offices / 50 states, 199 stance-covered + 10 honest-skips, consolidated gate all-PASS)
- ✅ **v2.19 Local Civic Coverage** — Phases 145–147 (shipped 2026-06-23; Falls Church VA + Greene County MO + Springfield MO — 46 records / 118 stances / 46 headshots / 4 boundaries; inline-executed, formalized retroactively)
- ✅ **v2.20 2026 US House Candidate Coverage (Wave 1)** — Phases 148–152 (shipped 2026-06-30; CA 52 / TX 38 / FL 28 / NY 26 = 144 districts, 415 active candidates, federal-24 stances [0 unsourced], 0 dup-incumbent; consolidated gate 8/8 + coordinate smoke 4/4; USHC-01..06 closed. USHC-07/Phase 153 carried forward — time-gated ≥ 2026-08-18)
- 🔄 **v2.21 2026 US House Candidate Coverage (Wave 2)** — Phases 154–159 (planning 2026-06-30; PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / NJ 12 = 89 decided (Phase 158 gate ✅) + MI 13 & VA 11 = 24 primary-field-now + Aug-5 cull (Phase 159; both Aug-4 primaries) = 113 districts; federal-24-topic chairs-not-polarity stances + headshots, pure-data elections-feed surfacing; USHC2-01..06)

## Phases

### v2.21 2026 US House Candidate Coverage (Wave 2) — Phases 154–159 🔄 ACTIVE

**Milestone goal:** Every resident of the next 8 largest-delegation states (PA, IL, OH, GA, NC, MI, NJ, VA) can enter their address into Elections and see their 2026 US House race — the actual Nov-3 general-ballot field — each candidate with a headshot and chairs-not-polarity, evidence-only stances. Reuses the fully-proven v2.20 elections-feed pipeline.

**Scope:** The next 8 House delegations by size (all ≥ 11 seats) — **PA (17), IL (17), OH (15), GA (14), NC (14), MI (13), NJ (12), VA (11) = 113 districts**. Nov-3 general-ballot field (major-party nominees + ballot-qualified independents/third-party). New work = challengers + open-seat candidates; sitting incumbents are already stanced (v2.16/v2.17) and reuse their existing records. Wave 2 of a multi-milestone program; remaining ~178 districts (38 smaller-delegation states) → Wave 3+.

**PURE-DATA milestone — no backend code.** Surfacing is **Path B**: the elections feed (`getElectionsByCoordinate`, `electionService.ts`) reading `essentials.races` + `essentials.race_candidates`, geography inherited through `office_id → districts.geo_id` + PostGIS `ST_Covers`. Path A (Senate-style candidacy offices) is invisible to `/elections`. No empty-state UI work in this repo.

**Per-state work split (all 8 states need elections + races authored first — none have pre-seeded 2026 House races):**

All 8 Wave-2 states follow the TX+NY pattern from Phase 150: author `elections` + `races` rows first (if absent), then `race_candidates`. None of the 8 states have pre-seeded 2026 House races (unlike CA in v2.20, which was a turnkey race_candidates-only state). The Phase 154 diagnostic confirms existing incumbent `politician_id` maps per district and the stance-gap baseline so no seeding phase creates a duplicate incumbent.

**Carry-forward execution methodology (for `/gsd-plan-phase`):**

- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **Two highest-cost traps, prevented by Phase 154 (diagnostic-first):** (1) duplicate incumbent records — reuse the existing `politician_id` (already seeded in v2.15–v2.17), never INSERT a new politician row for a sitting rep; (2) lost-incumbent-primary — verify the nominee per district from a primary-results source (PA/IL/OH/GA/NC all held primaries by June 30), never derive from incumbency. (GA-13 is a known open seat/vacancy; verify current status.)
- **`race_candidates` insert shape:** `race_id` → the district race, `politician_id` (NON-NULL), `full_name`, `is_incumbent`, `candidate_status='active'`, `source`. **Never** `office_id IS NULL` on a House race. **Never** party on the candidate card — party lives on `races.primary_party` only (antipartisan invariant).
- **Elections + races authoring:** for each state, create one `essentials.elections` row (`election_date='2026-11-03'`, e.g. "PA 2026 Statewide General") and one `essentials.races` row per district (`office_id` = the existing `U.S. Representative` office for that district; **NEVER** `office_id IS NULL` on a House race).
- **external_id scheme for new challengers:** `-(state_fips * 10000 + cd * 100 + seq)` pattern (mirroring v2.20's Wave-1 allocation for TX/NY; verify 0 collisions against live negative IDs per state before any insert). PA fips=42, IL=17, OH=39, GA=13, NC=37, MI=26, NJ=34, VA=51.
- **Stance pipeline reuse:** **federal 24-topic** set (`_TOPIC_SCALE_FULL.txt` — adds social-security/tariffs/ukraine, drops 5 state-only), `politician-stance-researcher` at **3-concurrency**, per-candidate CSV → field-count-validated/canonical re-stringify → `_merge.ts` → push (`_push_uuid.ts` for new NULL-external_id challengers; `_push.ts` for existing external_id records). **Mandatory primary-source verification sub-step before every push** (re-fetch raw quotes via Playwright, delete polarity-inference). **0-unsourced gate**; honest-skip thin topics; whole-record honest-skip allowed + gate-pinned by id. Embed exact 1–5 stance texts per topic.
- **Fetch-walls:** Ballotpedia blank (Cloudflare) + long Wikipedia pages TOC-only → use Playwright / raw-wikitext / section anchors. FEC API: register a free key (api.data.gov/signup, 1000/hr) — one paginated per-state call (`?office=H&state={ST}&election_year=2026`).
- **MI timing note (D-01):** Michigan's 2026 congressional primary is **Aug 4, 2026** — after the build window. MI is therefore NOT seeded with the 7 decided states; it is a **date-gated final phase (159, execute ≥ Aug 4)** that seeds the REAL post-primary nominees (no provisional field, no prune). Phase 154 resolves MI only to the declared-field + incumbent-`politician_id`-map level. The 7 decided states (PA April / IL March / OH May / GA May / NC March / NJ June / VA June) all primaried before the build window.
- **VA special note:** VA-11 (Gerry Connolly retired March 2025 due to illness — seat vacant, special election may have run before Nov; verify current officeholder at plan time per D-04). VA statewide geofencing (SLDU/SLDL) is already in the DB from v2.10 — NATIONAL_LOWER VA district offices and geofences are present from v2.15.
- **NJ special note:** NJ-8 (Rob Menendez Jr.) and NJ incumbents — all NJ reps seeded in v2.15; verify against primary results. **NJ-11** — Mikie Sherrill vacated the seat after winning the NJ governorship (Nov 2025); resolve the current officeholder + 2026 nominee from official sources (D-04), no ghost incumbent.
- **Finance is best-effort / out of scope:** challenger `finance_summary` deferred; record no-FEC-ID rather than retry.

---

#### Phase 154: Field Resolution + Stance-Gap Diagnostic

**Goal:** The verified Nov-3 general-ballot field is locked for the **6 decided states** (PA/IL/OH/GA/NC/NJ = 89 districts), every district where the incumbent is NOT the 2026 nominee is explicitly flagged, and every district incumbent **across all 8 states (incl. MI + VA)** is mapped to its existing `politician_id` — so no seeding phase can create a duplicate incumbent or surface a non-candidate. **MI's AND VA's** *nominees* are deferred to date-gated Phase 159 (both 2026 congressional primaries are Aug 4, 2026 — VA moved its primary from June to Aug 4, verified in `154-RESEARCH.md`); MI + VA districts are resolved here only to the declared-field + incumbent-map level. See `154-CONTEXT.md` D-01..D-04 for the four locked decisions this phase implements.

**Depends on:** Nothing (first phase; diagnostic gates everything else — must run before any seeding)

**Requirements:** USHC2-01

**Success Criteria** (what must be TRUE):

  1. A per-district field table exists for all 113 districts listing each Nov-3 general-ballot candidate (the inclusion bar is **every candidate ballot-qualified for the Nov-3 general** — major-party nominees + ballot-qualified independents/third-party + certified write-ins; D-03). The 6 decided states (PA/IL/OH/GA/NC/NJ = 89) are marked `decided`; **MI (13) and VA (11) = 24 are marked `pending-primary (Aug-4)`** — their declared candidates are captured but nominees are resolved in date-gated Phase 159.
  2. Every district where the incumbent is NOT the 2026 nominee (lost-primary, retirement, open seat, vacancy, deceased, special-seated) is explicitly flagged — including GA-13 (open/vacancy), VA-11 (Connolly vacancy → Walkinshaw special-seated Sep 2025), NJ-11 (Sherrill vacated → NJ governor) — by resolving the **current officeholder AND the 2026 nominee from an official/results source, never derived from incumbency** (D-04). Any current member seated by a post-v2.17 special election (not yet in the DB) is enumerated as a new-record need, taxonomy-tagged; no ghost incumbent records.
  3. A stance-gap / existence diagnostic maps each district's sitting incumbent (all 8 states) to its existing `essentials.politicians` record (`politician_id`) and reports current stance count. Per D-02 the diagnostic only **reports** incumbents below the federal-24 threshold — partial incumbents are NOT topped up in Wave 2; only new candidates + zero-stance incumbents get stance research.
  4. The set of genuinely-new candidates needing records (challengers + open-seat/special-seated candidates) is enumerated per state and per district, distinct from incumbents/previously-seeded figures that reuse existing records; a per-state new-record count is produced as the authoritative input for each seeding phase (MI + VA counts are provisional until Phase 159).

**Plans:** 2/2 plans complete

Plans:
**Wave 1**
- [x] 154-01-PLAN.md — DB incumbent->politician_id map (all 8 states, by NATIONAL_LOWER+geo_id) + per-incumbent federal-24 stance-gap + vacancy/special-seat enumeration (incl. GA-14 Query-C check); emits 154-incumbent-map.csv (113 rows)

**Wave 2** *(blocked on 154-01)*
- [x] 154-02-PLAN.md — verified Nov-3 field table (89 decided + 24 pending-primary) with non-incumbent-nominee flags + the four special seats (GA-13/NJ-11/VA-11/GA-14); CSV validator + write-free 154-verify.sql baseline gate (asserts no MI/VA decided field)

---

#### Phase 155: PA + IL Candidate Seeding (create elections + races, then candidates)

**Goal:** Every PA and IL US House race surfaces its full Nov-3 candidate field on `/elections` for an in-district address — both states need `elections`/`races` rows authored first, then candidate records and `race_candidates` wired, headshots for newly-seeded candidates, and federal-24 chairs-not-polarity stances. PA (17) + IL (17) = 34 districts.

**Depends on:** Phase 154 (verified PA/IL field + incumbent `politician_id` map)

**Requirements:** USHC2-02, USHC2-03, USHC2-04, USHC2-05

> USHC2-02/03/04/05 are state-partitioned, cross-cutting requirements anchored here (the first seeding phase, where the per-state pipeline is established for Wave 2) and **continued** in Phases 156 (OH+GA+NC) and 157 (MI+NJ+VA). Phase 158's gate asserts full 113-district completion across all three seeding phases.

**Success Criteria** (what must be TRUE):

  1. An `essentials.elections` row exists for each of PA and IL (created if absent, mirroring "TX 2026 Statewide General" pattern, `election_date='2026-11-03'`) and one `essentials.races` row per district (all 17 PA + all 17 IL) with `office_id` pointing to the existing `U.S. Representative` office for that district — **never** `office_id IS NULL` on a House race.
  2. Every PA (17) and IL (17) district surfaces its full candidate field on `/elections` for an in-district test coordinate via `race_candidates`, each row `politician_id`-linked and `candidate_status='active'`; non-incumbent nominees in races where the incumbent retired/lost are the active candidates, not the previous incumbents; zero duplicate `full_name` per state for incumbent-reuse rows.
  3. Every newly-seeded PA/IL candidate has a headshot (Storage-mirrored 600×750 + `politician_images` row + `photo_origin_url`; free-license, wrong-person-guarded; documented honest-skips where no free portrait exists); no candidate card surfaces party (party reads from `races.primary_party`).
  4. Every PA/IL candidate lacking federal-24 stances has sourced chairs-not-polarity stances — each answer paired to an `inform.politician_context` row with a real fetched source URL, 0 unsourced, primary-source-verified before push, honest-skip (per-topic or whole-record) where evidence is thin; already-stanced incumbents skipped via the Phase 154 diagnostic.

**Plans:** 9 plans

Plans:
- [ ] 155-01-PLAN.md — Author PA + IL elections + races scaffold (2 elections, 34 races on existing offices)
- [ ] 155-02-PLAN.md — Author write-free 155-verify.sql per-state gate (USHC2-02/03/04/05 + decisions)
- [ ] 155-03-PLAN.md — PA reconciliation + new records + race_candidates wiring (17 districts)
- [ ] 155-04-PLAN.md — IL reconciliation (certified-general re-confirm) + records + race_candidates (17 districts)
- [ ] 155-05-PLAN.md — Shared PA/IL headshot pipeline + run PA new candidates
- [ ] 155-06-PLAN.md — Run shared headshot pipeline for IL new candidates
- [ ] 155-07-PLAN.md — Federal-24 chairs-not-polarity stances for new PA candidates (0 unsourced)
- [ ] 155-08-PLAN.md — Federal-24 chairs-not-polarity stances for new IL candidates (0 unsourced)
- [ ] 155-09-PLAN.md — Run consolidated 155-verify.sql green + PA/IL coordinate-surfacing smoke

---

#### Phase 156: OH + GA + NC Candidate Seeding (create elections + races, then candidates)

**Goal:** Every OH, GA, and NC US House race surfaces its full Nov-3 candidate field on `/elections` — all three states need `elections`/`races` rows authored first, then candidate records, race_candidates wiring, headshots, and federal-24 stances. OH (15) + GA (14) + NC (14) = 43 districts.

**Depends on:** Phase 154 (verified OH/GA/NC field + incumbent `politician_id` map); independent of Phase 155 (different states) but sequenced after it to inherit the validated pipeline.

**Requirements:** USHC2-02, USHC2-03, USHC2-04, USHC2-05 (continuation — OH + GA + NC portion; see Phase 155 anchor note)

**Success Criteria** (what must be TRUE):

  1. An `essentials.elections` row exists for each of OH, GA, and NC and one `essentials.races` row per district (15 OH + 14 GA + 14 NC) with `office_id` → the existing `U.S. Representative` office; every district surfaces its full candidate field on `/elections` for an in-district test coordinate via `race_candidates`, each row `politician_id`-linked.
  2. Every newly-seeded OH/GA/NC candidate has a headshot; incumbent-nominees reuse existing records (zero duplicate `full_name` per state); no party on candidate cards; GA-13 open-seat or current status is handled correctly (no ghost incumbent record created).
  3. Every OH/GA/NC candidate lacking federal-24 stances has sourced chairs-not-polarity stances — 0 unsourced, primary-source-verified before push, honest-skip where evidence is thin; already-stanced incumbents (all OH/GA/NC reps stanced in v2.17) skipped via the diagnostic.

**Plans:** 10 plans (4 waves)

Plans:
- [x] 156-01-PLAN.md — Author OH/GA/NC elections + 43 races (create-races-first; GA-13 vacancy office check)
- [x] 156-02-PLAN.md — Author write-free 156-verify.sql per-state gate (McDowell in-scope; GA-13 no-absence-pin)
- [x] 156-03-PLAN.md — OH records + race_candidates wiring (15 districts, seed-all minor lines)
- [x] 156-04-PLAN.md — GA records + wiring (GA-1/10/11 open/retired; GA-13 true vacancy Clark+Chavez)
- [x] 156-05-PLAN.md — NC records + wiring (14 districts, heavy third-party field; McDowell active incumbent)
- [x] 156-06-PLAN.md — Headshots for new OH/GA/NC candidates (shared pipeline, honest-skips pinned)
- [x] 156-07-PLAN.md — Federal-24 chairs-not-polarity stances for new OH candidates (0 unsourced)
- [x] 156-08-PLAN.md — Federal-24 stances for new GA candidates incl. GA-13 Clark/Chavez (0 unsourced)
- [x] 156-09-PLAN.md — Federal-24 stances for new NC candidates + NC-6 McDowell by external_id (0 unsourced)
- [x] 156-10-PLAN.md — Run consolidated 156-verify.sql green + OH/GA/NC coordinate smoke (GA-13 sample)

---

#### Phase 157: NJ Candidate Seeding (create elections + races, then candidates)

**Goal:** Every NJ US House race surfaces its full Nov-3 candidate field on `/elections` — NJ needs `elections`/`races` rows authored first, then candidates, race_candidates wiring, headshots, and federal-24 stances. NJ (12) districts. (MI **and VA** moved to date-gated Phase 159 — both 2026 congressional primaries are Aug 4, 2026; see Phase 154 CONTEXT D-01 and the verified VA-primary finding in `154-RESEARCH.md`.)

**Depends on:** Phase 154 (verified NJ field + incumbent `politician_id` map); independent of Phases 155/156 (different states) but sequenced after them to inherit the validated pipeline.

**Requirements:** USHC2-02, USHC2-03, USHC2-04, USHC2-05 (continuation — NJ portion; see Phase 155 anchor note)

**Success Criteria** (what must be TRUE):

  1. An `essentials.elections` row exists for NJ and one `essentials.races` row per district (all 12) with `office_id` → the existing `U.S. Representative` office; every district surfaces its full candidate field on `/elections` for an in-district test coordinate via `race_candidates`, each row `politician_id`-linked; NJ-11 (Sherrill vacated → NJ governor; special-seated member Mejia, not yet in DB) current-officeholder status is verified per the Phase 154 diagnostic (no stale officeholder wired as incumbent-nominee; special-seated members not yet in DB get new records).
  2. Every newly-seeded NJ candidate has a headshot; incumbent-nominees reuse existing records (zero duplicate `full_name`); no party on candidate cards.
  3. Every NJ candidate lacking federal-24 stances has sourced chairs-not-polarity stances — 0 unsourced, primary-source-verified before push, honest-skip where evidence is thin; already-stanced incumbents (all NJ reps stanced in v2.17) skipped via the diagnostic.

**Plans:** TBD

---

#### Phase 158: Coordinate Verification Gate

**Goal:** A consolidated read-only gate proves the milestone end-to-end across the **89 decided-state Wave-2 districts** (PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / NJ 12) — for each a test address resolves to its district and the House race displays the expected candidate field on `/elections`, with 0 unsourced stances and 0 duplicate-incumbent records. (MI's 13 + VA's 11 districts are seeded + verified in the date-gated Phase 159 — both primaries are Aug 4, 2026; the milestone's full 113-district completion is the union of this gate + Phase 159's MI+VA gate.)

**Depends on:** Phases 155, 156, 157 (the three decided-state seeding phases complete). MI + VA (Phase 159) are gated separately by date (≥ 2026-08-04).

**Requirements:** USHC2-06 (decided-state portion; MI + VA portion asserted by Phase 159)

**Success Criteria** (what must be TRUE):

  1. For a known in-district address in each decided-state (PA/IL/OH/GA/NC/NJ), `getElectionsByCoordinate` / `/api/essentials/elections-by-address` returns the resident's US House race with the full candidate field — and the assertion checks the CHALLENGER field is present, not just the incumbent (Pitfall-5 two-path guard inherited from v2.20).
  2. The gate asserts 0 unsourced stance rows across all newly-seeded decided-state candidates and 0 duplicate-incumbent `essentials.politicians` records across the 89 decided-state districts; any documented whole-record stance honest-skips are pinned by id in the gate script.
  3. Every `race_candidates` row across the 89 decided-state districts has a NON-NULL `politician_id` (so headshots + stances resolve) and no candidate card surfaces party (party reads from `races.primary_party`); the gate script asserts all 89 decided-state districts have at least one active `race_candidates` row.

**Plans:** 1 plan

Plans:
- [x] 158-01-PLAN.md — Author write-free 158-verify.sql consolidated 89-district gate + 158-coordinate-smoke.ts 6-state surfacing smoke (USHC2-06) — COMPLETE 2026-07-01 (gate 8/8 PASS exit 0 + smoke 6/6 GREEN; gsd-verifier 10/10; commit 7ac3b738)

---

#### Phase 159: MI + VA Primary-Field Coverage (seed NOW) + Post-Primary Cull (≥ 2026-08-05)

**Strategy change (2026-07-01):** Reframed from "wait until Aug 4, seed decided nominees" to **"seed the full pre-primary qualified field NOW so MI + VA primary voters (voting Aug 4) can understand their options, then cull losers ≥ Aug 5"** — applying FL's proven provisional-field pattern (Phase 151 seed → Phase 153 cull) to MI + VA. Rationale: the tool's mission is to serve voters *at* the civic moment; a primary is the highest-engagement moment and in safe seats *is* the deciding contest. FL already does this (181-candidate provisional field live); MI/VA were the un-principled exception. Operator opted for **full** coverage (records + headshots + full federal-24 sourced stances on every qualified candidate), accepting that stance work on primary losers is discarded at the cull.

**Goal:** Every Michigan **and Virginia** US House race surfaces its full pre-primary qualified candidate field (all parties) on `/elections` NOW — MI's and VA's `elections`/`races` rows authored/populated, candidate records + `race_candidates` wired for every ballot-qualified primary candidate, headshots, full federal-24 chairs-not-polarity stances — then a **post-primary cull sub-phase (≥ Aug 5)** prunes primary losers to `candidate_status='withdrawn'`/inactive and confirms advancing nominees, followed by the MI+VA verification gate. MI (13) + VA (11) = 24 districts.

**Depends on:** Phase 154 (verified MI + VA incumbent `politician_id` maps + declared fields). **Seeding is NOT date-gated — execute now.** Only the cull sub-phase (159-C) is date-gated ≥ 2026-08-05 (day after the Aug-4 MI & VA primaries). Independent of 155/156/157 in data terms; the decided-state gate (158) is already complete.

**Requirements:** USHC2-02, USHC2-03, USHC2-04, USHC2-05 (MI + VA portion — completes the state-partitioned set), USHC2-06 (MI + VA verification — completes the milestone gate)

**Success Criteria** (what must be TRUE):

  1. **(seed now)** An `essentials.elections` row exists for MI ("MI 2026 Statewide General", `election_date='2026-11-03'`) — VA's already exists — and one `essentials.races` row per district (all 13 MI + all 11 VA); every MI and VA district surfaces its **full pre-primary qualified field** on `/elections` for an in-district test coordinate via `race_candidates`, each row `politician_id`-linked and `candidate_status='active'`. Following FL's precedent, the qualified field attaches to the Nov-3 general race rows as a provisional field (no separate primary-election rows).
  2. **(seed now)** Candidates are the ballot-qualified primary field (all parties), sourced from MI SoS / VA Dept. of Elections candidate lists, never derived from incumbency; incumbent-candidates reuse existing records (zero duplicate `full_name`); **VA-11 Walkinshaw is REUSED via his existing record (external_id -5102011) — the earlier "gets a new record" note is SUPERSEDED by the CONTEXT/RESEARCH DB-confirmed fact that he already exists; creating a duplicate is forbidden**; MI-10 James + MI-11 Stevens VACATE (Gov/Senate runs) and get NO active row in their old seat; newly-seeded candidates have headshots (wrong-person-guarded; documented honest-skips); no party on candidate cards.
  3. **(seed now)** Every MI and VA candidate lacking federal-24 stances has sourced chairs-not-polarity stances — each answer paired to an `inform.politician_context` row with a real fetched source URL, 0 unsourced, primary-source-verified before push, honest-skip where evidence is thin; already-stanced incumbents skipped via the Phase 154 diagnostic.
  4. **(cull ≥ Aug 5, sub-phase 159-C)** After the Aug-4 primaries, each district's non-advancing candidates are set inactive (`candidate_status`), the advancing nominee(s) confirmed from official results, and the two-path prune verified — mirroring FL Phase 153. Discarded losers' stance rows may be retained (historical) or pruned per the FL-153 convention.
  5. **(gate)** A MI+VA verification gate (read-only, mirroring Phase 158) asserts: an in-district MI and VA address → the House race with the full field present (Pitfall-5 two-path guard); 0 unsourced; 0 duplicate-incumbent; all 13 MI + 11 VA districts have ≥1 active `race_candidates` row. Combined with Phase 158, the full 113-district milestone is proven.

**Plans:** 6 plans in 4 waves (planned 2026-07-01)
- [ ] 159-01-PLAN.md — 159-A MI seed: 1 election + 13 provisional races + full qualified field (~56 new records, James/Stevens vacate) [wave 1]
- [ ] 159-02-PLAN.md — 159-A MI headshots + federal-24 stances for new MI candidates [wave 2]
- [ ] 159-03-PLAN.md — 159-B VA candidates onto 11 existing races (~40 new, Walkinshaw reused) [wave 1]
- [ ] 159-04-PLAN.md — 159-B VA headshots + stances (new + 3 thin-incumbent top-ups) [wave 2]
- [ ] 159-05-PLAN.md — 159-C post-primary cull, DATE-GATED ≥ 2026-08-05 (two-path prune + indep reconcile) [wave 3, non-autonomous]
- [ ] 159-06-PLAN.md — 159-D MI+VA verification gate + coordinate smoke (union with 158 = 113 districts) [wave 4]

---

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 154. Field Resolution + Stance-Gap Diagnostic | 2/2 | Complete    | 2026-06-30 |
| 155. PA + IL Candidate Seeding (create races) | 0/? | Not started | - |
| 156. OH + GA + NC Candidate Seeding (create races) | 10/10 | Complete   | 2026-07-01 |
| 157. NJ Candidate Seeding (create races) | 6/6 | Complete | 2026-07-01 |
| 158. Coordinate Verification Gate (89 decided-state districts) | 1/1 | Complete ✅ | 2026-07-01 |
| 159. MI + VA Primary-Field Coverage (seed now) + Post-Primary Cull (≥ 2026-08-05) | 0/6 | Planned | - |

---

<details>
<summary>✅ v2.20 2026 US House Candidate Coverage (Wave 1) (Phases 148–152) — SHIPPED 2026-06-30 (CA 52 / TX 38 / FL 28 / NY 26 = 144 districts; 415 active candidates, federal-24 stances [0 unsourced], 0 dup-incumbent; consolidated gate 152-verify.sql 8/8 + 152-coordinate-smoke.ts 4/4; USHC-01..06 closed. USHC-07 + Phase 153 carried forward — FL post-primary re-check, time-gated ≥ 2026-08-18)</summary>

### v2.20 2026 US House Candidate Coverage (Wave 1) — Phases 148–153

**Milestone goal:** Every resident of the Wave-1 states (CA, TX, FL, NY) can enter their address into Elections and see their 2026 US House race — the actual Nov-3 general-ballot field — each candidate with a headshot and chairs-not-polarity, evidence-only stances. Senate shows "if available" from its own existing track.

**Scope:** The 4 largest House delegations — **CA (52), TX (38), FL (28), NY (26) = 144 districts**. Nov-3 general-ballot field (major-party nominees + ballot-qualified independents/third-party). New work = challengers + open-seat candidates; sitting incumbents are already stanced (v2.15–v2.17) and reuse their existing records. Wave 1 of a multi-milestone program; remaining ~291 districts → v2.21+.

**PURE-DATA milestone — no backend code.** Surfacing is **Path B**: the elections feed (`getElectionsByCoordinate`, `electionService.ts`) reading `essentials.races` + `essentials.race_candidates`, geography inherited through `office_id → districts.geo_id` + PostGIS `ST_Covers`. Research traced this live (file:line) and proved Path A (Senate-style candidacy offices) is **invisible** to `/elections` (0 races, 0 race_candidates) and the reps feed filters `is_incumbent=true` (excludes every challenger). No empty-state work in this repo — the "race not covered" message lives in the separate Essentials frontend repo; backend always returns `{elections:[]}`.

**Per-state work split (research-confirmed):**

- **CA** = insert `race_candidates` only — all 53 House `races` + offices + geofences are pre-seeded (turnkey; validates the pattern first). Template: `scripts/ingest-ca-sos-2026-challengers.ts`.
- **TX + NY** = author `elections` (if absent) + `races` rows first, then `race_candidates`. Both fields decided (TX March 3 + May 26 runoff; NY June 23). Precedents: `importElectionData.ts`, `seed-la-county-2026-primary-state-federal.sql`.
- **FL** = provisional field from the FL DoE tab-delimited download (`downloadcanlist.asp`), seed-now (qualifying closed → universe final); primary Aug 18 → prune losers in Phase 153.

CA/TX/NY are independent of each other once field resolution (Phase 148) is done.

**Carry-forward execution methodology (for `/gsd-plan-phase`):**

- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **Two highest-cost traps, prevented by Phase 148 (diagnostic-first):** (1) duplicate incumbent records (the v2.4 two-Andy-Barrs / migration-1074 failure) — reuse the existing `politician_id`, never INSERT a new politician row for a sitting rep; (2) lost-incumbent-primary assumption — NY-10 Goldman and NY-13 Espaillat both LOST 6/23; verify the nominee per district from a primary-results source, never derive from incumbency.
- **`race_candidates` insert shape:** `race_id` → the district race, `politician_id` (NON-NULL — NULL means no stances + no photo, PHOTO_LATERAL keys off it), `full_name`, `is_incumbent`, `candidate_status='active'`, `source`. **Never** `office_id IS NULL` on a House race (that is the statewide convention → matches every resident of the state). **Never** party on the candidate card — party lives on `races.primary_party` only (antipartisan invariant, enforced at query layer).
- **Stance pipeline reuse:** **federal 24-topic** set (`_TOPIC_SCALE_FULL.txt` — adds social-security/tariffs/ukraine, drops 5 state-only), `politician-stance-researcher` at **3-concurrency**, per-candidate CSV → field-count-validated/canonical re-stringify → `_merge.ts` → push (`_push_uuid.ts` for new NULL-external_id challengers; `_push.ts` for existing-external_id records). **Mandatory primary-source verification sub-step before every push** (re-fetch raw quotes via Playwright, delete polarity-inference; the prior 7-challenger pass deleted 16 inference rows). **0-unsourced gate**; honest-skip thin topics; whole-record honest-skip allowed + gate-pinned by id. Embed exact 1–5 stance texts per topic (never "5=progressive"). On any quote correction, wipe `essentials.quotes` for the pid then re-push.
- **Field-discovery fetch-walls:** Ballotpedia returns blank (Cloudflare) and long Wikipedia pages return TOC-only via WebFetch — use **Playwright** / raw-wikitext / section anchors. **Register a free FEC API key** (`api.data.gov/signup`, 1000/hr) — DEMO_KEY's 10/hr will stall the 144-district pull; one paginated per-state call (`?office=H&state={ST}&election_year=2026`), not per-district. FL: use the tab-delimited bulk download, bypasses the ASP SPA.
- **Two-path prune (Phase 153, FL only):** retire a primary loser via `essentials.politicians.is_active=false` (reps feed) **AND** `essentials.race_candidates.candidate_status='withdrawn'` (elections feed) — **never hard-DELETE** (preserves record/stances/headshot/FEC). Re-research advancing thin-stance winners against primary sources.
- **Finance is best-effort / out of scope:** challenger `finance_summary` deferred to v2.21+; record "no FEC ID" rather than retrying.

---

#### Phase 148: Field Resolution + Stance-Gap Diagnostic

**Goal:** The verified Nov-3 general-ballot field is locked for all 144 Wave-1 districts, every district where the incumbent is NOT the 2026 nominee is explicitly flagged, and every district incumbent is mapped to its existing `politician_id` — so no seeding phase can create a duplicate incumbent or surface a non-candidate.

**Depends on:** Nothing (first phase; diagnostic gates everything else — must run before any seeding)

**Requirements:** USHC-01

**Success Criteria** (what must be TRUE):

  1. A per-district field table exists for all 144 districts (CA 52 / TX 38 / FL 28 / NY 26) listing each Nov-3 general-ballot candidate (major-party nominees + ballot-qualified independents/third-party), with CA/TX/NY marked `decided` and FL marked `provisional` (qualified field, pre-Aug-18-primary).
  2. Every district where the incumbent is NOT the 2026 nominee (lost-primary, retirement, open seat) is explicitly flagged — including the known cases NY-10 (Goldman lost) and NY-13 (Espaillat lost), confirmed from a primary-results source, and CA top-two same-party generals confirmed from results (not assumed one-D-one-R).
  3. A stance-gap / existence diagnostic maps each district's sitting incumbent to its existing `essentials.politicians` record (`politician_id`) and reports its current stance count — so incumbent-nominees link to the existing record and any incumbent below the federal-24 threshold is surfaced for top-up.
  4. The set of genuinely-new candidates needing records (challengers + open-seat candidates) is enumerated per state, distinct from incumbents/previously-seeded figures that reuse existing records.

**Plans:** 2 plans, 2 waves

Plans:
**Wave 1**

- [x] 148-01-PLAN.md — DB incumbent->politician_id map + per-incumbent stance-gap counts/top-up tiers + vacancy enumeration (148-incumbent-map.csv)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 148-02-PLAN.md — verified Nov-3 field per district (Wikipedia/FEC) + non-incumbent-nominee flags + new-vs-reuse classification; assembles 148-FIELD-TABLE.md/.csv + 148-verify.sql

---

#### Phase 149: CA Candidate Seeding (race_candidates only — turnkey)

**Goal:** Every CA US House race surfaces its full Nov-3 candidate field on `/elections` for an in-district address — incumbent + challengers as `race_candidates` rows on the 53 pre-seeded races, each new candidate with a record, headshot, and federal-24 evidence-only stances. This is the lowest-friction state and validates the seed + headshot + stance pattern before the create-races states.

**Depends on:** Phase 148 (verified CA field + incumbent `politician_id` map)

**Requirements:** USHC-02, USHC-03, USHC-04, USHC-05

> USHC-02/03/04/05 are state-partitioned, cross-cutting requirements anchored here (the first seeding phase, where the pipeline is established) and **continued** in Phases 150 (TX+NY) and 151 (FL). Phase 152's gate asserts the full 144-district completion across all three seeding phases.

**Success Criteria** (what must be TRUE):

  1. Every CA US House race (all 52 districts) surfaces on `/elections` for an in-district test coordinate via `essentials.race_candidates` inserted on the existing race rows; each candidate row has a NON-NULL `politician_id` and `candidate_status='active'`, the incumbent flagged `is_incumbent=true`.
  2. Every CA incumbent-nominee links to its EXISTING `politician_id` (zero duplicate `full_name` within CA); only genuinely-new challengers/open-seat candidates get new `essentials.politicians` records, party normalized (Democratic, not Democrat).
  3. Every newly-seeded CA candidate has a headshot (Storage-mirrored 600×750 + `politician_images` row + `photo_origin_url`); no candidate card displays party (party reads from `races.primary_party`).
  4. Every CA candidate lacking them has sourced federal-24-topic chairs-not-polarity stances — each answer paired to an `inform.politician_context` row with a real fetched source URL, 0 unsourced, primary-source-verified before push, honest-skip (incl. documented whole-record skip) where evidence is thin; already-stanced incumbents skipped via the diagnostic.

**Plans:** 11/11 plans complete

Plans:
**Wave 1**
- [x] 149-01-PLAN.md — record reconciliation + race_candidates seed (38 new politicians + 104 rows) + Raul Ruiz CA-25 dedup
- [x] 149-02-PLAN.md — author 149-verify.sql gate (House-scoped, write-free, USHC-02/03/04/05 + D-04 assertions)

**Wave 2** *(blocked on 149-01)*
- [x] 149-03-PLAN.md — headshots for the 38 new CA candidates (find-headshots conventions)

**Wave 3** *(blocked on 149-01; stance batches, ≤3-concurrent research)*
- [x] 149-04-PLAN.md — stances CA-1..9
- [x] 149-05-PLAN.md — stances CA-10..18
- [x] 149-06-PLAN.md — stances CA-19..26 (incl. Ruiz canonical record)
- [x] 149-07-PLAN.md — stances CA-27..37 challengers/reuse (partials/done skipped per D-01)
- [x] 149-08-PLAN.md — stances CA-38..44 (open/redistricted seats + CA-40 R-vs-R)
- [x] 149-09-PLAN.md — stances CA-45..48
- [x] 149-10-PLAN.md — stances CA-49..52

**Wave 4** *(blocked on all)*
- [x] 149-11-PLAN.md — run 149-verify.sql green + coordinate-surfacing smoke (≥3 in-district CA House races)

---

#### Phase 150: TX + NY Candidate Seeding (create races, then candidates)

**Goal:** Every TX and NY US House race surfaces its full Nov-3 candidate field on `/elections` — differing from CA only in needing `elections`/`races` rows authored first. Both fields are decided (TX runoff + NY 6/23).

**Depends on:** Phase 148 (verified TX/NY field, incl. NY lost-incumbent flags); independent of Phase 149 (different states) but sequenced after it to inherit the validated CA pipeline.

**Requirements:** USHC-02, USHC-03, USHC-04, USHC-05 (continuation — TX + NY portion; see Phase 149 anchor note)

**Success Criteria** (what must be TRUE):

  1. An `essentials.elections` row exists per state (created if absent, mirroring "CA 2026 Statewide General", `election_date='2026-11-03'`) and one `essentials.races` row per district (`office_id` = that district's existing `U.S. Representative` office — NEVER `office_id IS NULL`).
  2. Every TX (38) and NY (26) district surfaces its full candidate field on `/elections` for an in-district test coordinate via `race_candidates`, each row `politician_id`-linked and `candidate_status='active'`; NY-10/NY-13 (and any other flagged) show the primary WINNER as the active candidate, the defeated incumbent absent from the active general field.
  3. Every newly-seeded TX/NY candidate has a headshot and federal-24 chairs-not-polarity stances (0 unsourced, primary-source-verified, honest-skip where thin); incumbent-nominees reuse existing records (zero duplicate `full_name` per state); no party on candidate cards.

**Plans:** 12 plans, 4 waves

Plans:
**Wave 1** *(scaffold + gate authoring; parallel)*
- [x] 150-01-PLAN.md — author 2 elections + 64 races (38 TX + 26 NY) on existing House offices (the create-races step CA did not need)
- [x] 150-02-PLAN.md — author 150-verify.sql gate (per-state TX/NY-scoped; USHC-02/03/04/05 + D-01/D-02/D-03/D-05; NY-partial exclusion)

**Wave 2** *(record reconciliation + race_candidates wiring; TX/NY parallel; blocked on 150-01)*
- [x] 150-03-PLAN.md — TX records + race_candidates (live D-03 dedup: Casar→TX-37 reuse, Allred new, Toth reuse; lost incumbents absent)
- [x] 150-04-PLAN.md — NY records + race_candidates (lost-primary winners Lander/Avila Chevalier; seed-all minor lines Cohen/Smullen; 24 incumbents reused)

**Wave 3** *(headshots + stances; <=3-concurrent research; blocked on Wave 2)*
- [ ] 150-05-PLAN.md — headshots for new TX candidates (shared seed-tx-ny-house-headshots.py)
- [ ] 150-06-PLAN.md — headshots for new NY candidates (reuse shared script)
- [ ] 150-07-PLAN.md — TX-1..10 federal-24 stances (zero incumbents + new challengers)
- [ ] 150-08-PLAN.md — TX-11..20 federal-24 stances
- [ ] 150-09-PLAN.md — TX-21..30 federal-24 stances (incl. TX-23 open seat)
- [ ] 150-10-PLAN.md — TX-31..38 federal-24 stances (incl. Casar -100335)
- [ ] 150-11-PLAN.md — NEW NY candidates federal-24 stances (NY partials left as-is per D-01)

**Wave 4** *(consolidated gate; blocked on all)*
- [ ] 150-12-PLAN.md — run 150-verify.sql green + 150-coordinate-smoke.ts (>=3 TX + >=3 NY in-district races surface with challenger)

---

#### Phase 151: FL Candidate Seeding (provisional qualified field)

**Goal:** Every FL US House race surfaces its full qualified Nov-3 field on `/elections` now — seeded provisionally from the FL DoE download (qualifying closed → universe final) so residents get upcoming-vote data before the Aug 18 primary; losers pruned in Phase 153.

**Depends on:** Phase 148 (FL qualified field marked provisional); independent of Phases 149/150 (different state) but sequenced after them.

**Requirements:** USHC-02, USHC-03, USHC-04, USHC-05 (continuation — FL portion; see Phase 149 anchor note)

**Success Criteria** (what must be TRUE):

  1. `essentials.elections` + one `races` row per FL district (all 28, `office_id` → the district House office; **FL-20's office created first — currently vacant, no office row**) + `race_candidates` for every qualified candidate exist, sourced/reconciled against the FL DoE `downloadcanlist.asp` tab-delimited field; every FL district surfaces its full field on `/elections` for an in-district test coordinate.
  2. Every newly-seeded FL candidate (155) has a `politician_id`-linked record (reuse existing for incumbents/cross-district redistricted, zero duplicate `full_name`). **Coverage depth is scoped by the records-now/stances-at-153 decision (CONTEXT D-01):** the **17 independent/NPA new candidates** (Nov-final, not pruned by the primary) get headshots + federal-24 chairs-not-polarity stances now (0 unsourced, primary-source-verified, honest-skip where thin); the **~138 partisan (R/D) primary candidates** get records only — their headshots + stances are deferred to Phase 153 once the field narrows to actual nominees. The 27 partial-stance incumbents are left as-is (zero-only top-up rule). No party on candidate cards.
  3. The FL field is recorded as `provisional` (multiple same-party candidates per district may be present pre-primary by design); the seed does NOT guess or pre-prune the general winner — Aug 18 reconciliation is deferred to Phase 153.

**Plans:** 6 plans, 4 waves — **COMPLETE 2026-06-29** (gate 13/13 PASS + smoke 4/4; gsd-verifier 8/8). 28 races/181 candidates/158 new records; 17 independents = 6 stanced (36 answers, 0 unsourced) + 11 honest-skip, 17 headshot-skip. 138 partisan + 27 incumbents records-only → Phase 153.
- [x] 151-01-PLAN.md — W1: author FL 2026 Statewide General election + create FL-20 office + 28 provisional races (description sentinel) — mig 1115
- [x] 151-02-PLAN.md — W1: author 151-verify.sql gate (single-state FL '12', provisional-aware, 17-independents-only stance scope, no per-party cap)
- [x] 151-03-PLAN.md — W2: live dedup reconciliation + insert 158 new records + wire all race_candidates (181 full provisional field, 3 reuse + Cherfilus-NEW) — mig 1116
- [x] 151-04-PLAN.md — W3: headshots for the 17 independent/NPA new candidates only (17/17 honest-skip)
- [x] 151-05-PLAN.md — W3: full-24 chairs-not-polarity stances for the 17 independents only (6 stanced/11 skip, 0 unsourced)
- [x] 151-06-PLAN.md — W4: run 151-verify.sql green + 151-coordinate-smoke.ts (FL-10 uncontested minActive=1)

---

#### Phase 152: Coordinate Verification Gate

**Goal:** A consolidated read-only gate proves the milestone end-to-end across all 144 districts — for each Wave-1 state a test address resolves to its district and the House race displays the expected candidate field on `/elections`, with 0 unsourced stances and 0 duplicate-incumbent records.

**Depends on:** Phases 149, 150, 151 (all three seeding phases complete; FL counts as provisional)

**Requirements:** USHC-06

**Success Criteria** (what must be TRUE):

  1. For a known in-district address in each Wave-1 state (CA/TX/FL/NY), `getElectionsByCoordinate` / `/api/essentials/elections-by-address` returns the resident's US House race with the full candidate field — and the assertion checks the CHALLENGER field is present, not just the incumbent (Pitfall-5 two-path confusion).
  2. The gate asserts 0 unsourced stance rows across all newly-seeded Wave-1 candidates and 0 duplicate-incumbent `essentials.politicians` records across the 144 districts; any documented whole-record stance honest-skips are pinned by id.
  3. Every `race_candidates` row across the 144 districts has a NON-NULL `politician_id` (so headshots + stances resolve) and no candidate card surfaces party (party reads from `races.primary_party`); FL rows are present and marked provisional.

**Plans:** 1/1 plans complete

Plans:
**Wave 1**

- [x] 152-01-PLAN.md — consolidated read-only milestone gate: author 152-verify.sql (8 USHC-06 assertions over all 144 districts) + 152-coordinate-smoke.ts (4-state coordinate surfacing)

---

#### Phase 153: FL Post-Primary Re-Check (time-gated — executes after Aug 18, 2026)

**Goal:** After the FL primary, the 28 FL districts are reconciled to final nominees via the two-path prune — losers retired (records preserved), advancing nominees confirmed, any new nominee given a record + headshot + stances — closing out the provisional FL coverage shipped in Wave 1.

**Depends on:** Phase 151 (provisional FL field seeded) AND the FL primary date — **DATE-GATED: planned now, executes/closes on or after 2026-08-18.** Phases 148–152 ship the live Wave-1 experience before this re-check.

**Requirements:** USHC-07

**Success Criteria** (what must be TRUE):

  1. Every FL primary loser is retired via BOTH paths — `essentials.politicians.is_active=false` AND `essentials.race_candidates.candidate_status='withdrawn'` — with NO hard-DELETE (record, stances, headshot, FEC preserved); the retired candidate no longer appears in either the reps feed or the active `/elections` field.
  2. Each FL district's advancing general-election nominee is confirmed against the certified Aug-18 results and remains the active `race_candidates` row; **every advancing partisan nominee (whose headshot + stances were deferred from Phase 151 per the records-now/stances-at-153 split) gets its headshot + primary-source-verified federal-24 chairs-not-polarity stances here** — this is the bulk stance work intentionally moved out of Phase 151. (The 17 independents + 27 incumbents already covered in 151 carry forward.)
  3. Advancing thin-stance winners are re-researched against primary sources; FL is re-marked `decided` (no longer provisional), and the Phase 152 gate (or its FL re-run) passes for the final FL field.

**Plans:** TBD

---

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 148. Field Resolution + Stance-Gap Diagnostic | 2/2 | Complete   | 2026-06-28 |
| 149. CA Candidate Seeding (race_candidates only) | 11/11 | Complete    | 2026-06-29 |
| 150. TX + NY Candidate Seeding (create races) | 12/12 | Complete   | 2026-06-29 |
| 151. FL Candidate Seeding (provisional) | 6/6 | Complete   | 2026-06-29 |
| 152. Coordinate Verification Gate | 1/1 | Complete    | 2026-06-30 |
| 153. FL Post-Primary Re-Check (date-gated Aug 18) | 0/? | Not started | - |

---

</details>

<details>
<summary>✅ v2.19 Local Civic Coverage (Phases 145–147) — SHIPPED 2026-06-23 (Falls Church VA / Greene County MO / Springfield MO; 46 records, 118 stances [0 unsourced], 46 headshots, 4 geofence boundaries; LCC-01..05 closed; inline-executed)</summary>

### v2.19 Local Civic Coverage (Phases 145–147)

> Executed **inline** (not GSD-phased) at user request, then formalized retroactively 2026-06-23. No plan directories — the per-jurisdiction deep-dive memory files are the build record. Git range `a488232a` → `ef1a364f`. Three sibling CA-city builds (Burbank/Norwalk/Bellflower, phases 154–156) and the Nevada work (phases 158–159, essentials team) are out of scope.

- **Phase 145 — Falls Church VA Coverage** ✅ — Alexandria-template independent city. 17 officials (7 council + 3 constitutional officers + 7 FCCPS school board) across 2 governments; coterminous school `G5420` geofence; 55 stances (10/17 stanced); 17 `.gov` headshots; `COVERAGE_STATES` purple chip. Migration 1047. Commits `a488232a`/`0d388c07`/`cf9adc6e`.
- **Phase 146 — Greene County MO Coverage** ✅ — LA-County-template county (FIPS 29077). 13 officials (commission + sheriff + prosecutor + county officers) on one `COUNTY` district; county `G4020` polygon imported from TIGERweb; 26 stances (5/13 stanced); 13 `greenecountymo.gov` headshots; `COVERAGE_COUNTIES` search-only. Migration 1048. Commits `448c3761`/`3d77073a`/`951b9310`.
- **Phase 147 — Springfield MO Coverage** ✅ — city + SPS R-XII school board (Greene County seat). 16 officials (9 council + 7 board); place `G4110` + school `G5420` boundaries; 37 stances (9/16 stanced); 16 headshots (clean-sourcing pass); `COVERAGE_STATES`. Migration 1049. Commits `dad06979`/`a3f9269b`/`ef1a364f`. Trap caught: `chambers.slug` collides with Springfield MA → scope chamber lookups by government name, never slug.

</details>

<details>
<summary>✅ v2.18 State Leaders (Phases 141–144) — SHIPPED 2026-06-22 (209 elected Big 5 execs / 50 states; 199 stance-covered + 10 honest-skips; 0 unsourced; SEXR-01..05, SEXS-01..03 closed)</summary>

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

**Plans:** 10 plans, 3 waves

Plans:

- [x] 142-01-PLAN.md — SEXS-01: extend politician-stance-researcher prompt with office-type evidence guidance (all 5 exec types)
- [x] 142-02-PLAN.md — Batch A (10): FL/NY/IL/PA/TX Gov+AG stances
- [x] 142-03-PLAN.md — Batch B (9): OH/GA/NC/MI Gov+AG + NJ Gov stances
- [x] 142-04-PLAN.md — Batch C (10): WA/AZ/MO/WI Gov+AG + TN Gov + IN AG stances
- [x] 142-05-PLAN.md — Batch D (10): CO/MN/SC/AL/LA Gov+AG stances
- [x] 142-06-PLAN.md — Batch E (10): KY/OK/CT/AR/MS Gov+AG stances
- [x] 142-07-PLAN.md — Batch F (10): NV/IA/KS/NM/NE Gov+AG stances
- [x] 142-08-PLAN.md — Batch G (10): ID/WV/RI/MT/VT Gov+AG stances
- [x] 142-09-PLAN.md — Batch H (11): HI/NH/AK/WY/ME Gov + DE/SD/ND Gov+AG stances
- [x] 142-10-PLAN.md — Phase-142 gate: verify-phase-142.sql (Gov+AG coverage + zero-unsourced)

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

**Scope (prod-verified 2026-06-21):** 103 in-scope unstanced execs = 37 Lt Gov + 32 SoS + 34 Treasurer. (No SEXS-01 prompt-update plan — the researcher prompt already carries all 5 office-type guidance from Phase 142-01.)

**Plans:** 11 plans, 2 waves — 10 state-grouped batches (largest-population-first, all of a state's SoS+Treas+LtGov in one batch, mutually independent) + per-phase gate

Wave 1 (batch research + push, parallel, depends_on []):

- [x] 143-01-PLAN.md — batch A (11): TX/FL/NY/PA LtGov+Treas + IL LtGov+SoS+Treas
- [x] 143-02-PLAN.md — batch B (10): OH(3) + GA LtGov+SoS + NC(3) + MI LtGov+SoS
- [x] 143-03-PLAN.md — batch C (11): NJ LtGov + WA(3) + AZ SoS+Treas + IN SoS+Treas (positive ids) + MO(3)
- [x] 143-04-PLAN.md — batch D (11): WI(3) + CO(3) + MN LtGov+SoS + SC(3)
- [x] 143-05-PLAN.md — batch E (9): AL(3) + LA(3) + KY(3)
- [x] 143-06-PLAN.md — batch F (11): OK LtGov+Treas + CT(3) + IA(3) + NV(3)
- [x] 143-07-PLAN.md — batch G (9): AR(3) + MS(3) + KS(3)
- [x] 143-08-PLAN.md — batch H (9): NM(3) + NE(3) + ID(3)
- [x] 143-09-PLAN.md — batch I (10): WV SoS+Treas + HI LtGov + MT LtGov+SoS + RI(3) + DE LtGov+Treas
- [x] 143-10-PLAN.md — batch J (12): SD(3) + ND(3) + AK LtGov + VT(3) + WY SoS+Treas

Wave 2 (gate, depends_on all 10 batches):

- [x] 143-11-PLAN.md — verify-phase-143.sql (SoS=35 / Treas=38 / LtGov=43 coverage + zero-unsourced)

---

#### Phase 144: Phase Gate — Feed Surfacing + Consolidated Verification

**Goal:** A read-only, labeled-assertion SQL gate confirms every elected Big 5 office is filled, zero unsourced stance rows exist for STATE_EXEC politicians, and state-code accessibility holds; feed surfacing is smoke-tested for at least 3 newly-seeded states.

**Depends on:** Phases 141, 142, and 143 (all seed + stance work must be complete)

**Requirements:** SEXR-05, SEXS-03

**Success Criteria** (what must be TRUE):

  1. `backend/scripts/verify-phase-141-144.sql` runs read-only against production, and every labeled assertion PASSES: all ~208 in-scope offices have a seeded politician, per-state counts match the known election matrix (ME=1, TN=1, NJ=2, AK=2, HI=2, WY=3, MD=3, TX=3, VA=3, and the known 4- and 5-office states), AZ Lt Gov is noted as deferred (not a miss), 0 answer rows lack a paired context row with a real source URL.
  2. All `STATE_EXEC` districts have an uppercase two-letter state code (`state = upper(state)`) and a non-empty `geo_id` — the gate asserts `COUNT(*) WHERE district_type='STATE_EXEC' AND (state != upper(state) OR geo_id IS NULL OR geo_id = '') = 0`.
  3. `GET /representatives/me` returns the correct newly-seeded exec for users with a stored state code in at least 3 states that had zero STATE_EXEC records before this milestone (smoke test — no backend code change required).

**Plans:** 1 plan (Wave 1)

Plans:

- [x] 144-01-PLAN.md — Consolidated v2.18 read-only SQL gate (verify-phase-141-144.sql): re-asserts 209 records / 199 stance coverage / 10 honest-skips / 0 unsourced / in-scope hygiene, plus SEXR-05 feed smoke-test for NC+WA+CO

---

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 141. Roster Lock + Seed | 12/12 | Complete   | 2026-06-21 |
| 142. Stance Wave 1 (Gov + AG) | 10/10 | ✅ Complete | 2026-06-21 |
| 143. Stance Wave 2 (SoS + Treasurer + LtGov) | 11/11 | ✅ Complete | 2026-06-21 |
| 144. Phase Gate | 1/1 | Complete   | 2026-06-22 |

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

</details>
