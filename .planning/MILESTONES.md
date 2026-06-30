# Project Milestones: Empowered Accounts

## v2.20 2026 US House Candidate Coverage (Wave 1) (Shipped: 2026-06-30)

**Phases completed:** 5 phases (148–152), 32 plans. Git tag `v2.20`.

**Goal:** Every resident of the four largest-delegation states (CA, TX, FL, NY) can enter their address into Elections and see their 2026 US House race — the actual Nov-3 general-ballot field — each candidate with a headshot and chairs-not-polarity, evidence-only stances. Pure-data milestone (no backend code); surfacing via the elections feed (`races` + `race_candidates`, PostGIS `ST_Covers`).

**Key accomplishments:**

- **144 districts wired** across CA (52) / TX (38) / FL (28) / NY (26) — **415 active `race_candidates`**, 306 of them challengers/open-seat, surfacing on `/elections` for any in-district address. New challenger/open-seat records created; sitting incumbents reuse their existing `politician_id` (no duplicate-incumbent rows — the v2.4 two-Andy-Barrs trap, guarded by the Phase 148 diagnostic).
- **Federal 24-topic chairs-not-polarity stances, 0 unsourced** — every answer paired to a sourced `politician_context` row, mandatory primary-source verification pass before push, honest-skip (gate-pinned by id) where no documentable evidence.
- **Headshots** for newly-seeded candidates via the hardened find-headshots pipeline (free-license only, wrong-person guard); documented honest-skips where no free portrait exists.
- **Per-state seeding:** CA turnkey (`race_candidates` into 53 pre-seeded races, mig 1091); TX+NY authored `elections`+`races` first (migs 1109–1111); FL provisional field from the FL DoE bulk download (mig 1116), all marked `PROVISIONAL:` pending the Aug-18 primary.
- **Consolidated milestone gate (Phase 152):** `152-verify.sql` — 8 labeled all-144-district assertions PASS read-only against prod (scope 144, 0 NULL politician_id, 0 unsourced, 0 dup-incumbent, FL provisional, no party column); `152-coordinate-smoke.ts` — 4/4 states surface their House race with the challenger-inclusive field (Pitfall-5 two-path guard). gsd-verifier 8/8.

**Requirements:** USHC-01 through USHC-06 closed. **USHC-07 carried forward** to Phase 153 (FL post-primary reconciliation) — genuinely time-gated to ≥ 2026-08-18, not a quality gap.

**Known deferred items at close:** 23 (22 long-standing quick-tasks pre-dating this milestone + USHC-07/Phase-153 time-gated carry-forward; see STATE.md Deferred Items).

---

## v2.19 Local Civic Coverage (Shipped: 2026-06-23)

**Phases completed:** 3 phases (145–147), executed inline (no plan dirs), formalized retroactively

**Goal:** Full-stack local coverage for three new jurisdictions — Falls Church VA, Greene County MO, and Springfield MO — so each resident sees their full slate of locally-elected officials (city council, constitutional/county officers, school board) in the representatives feed, with sourced compass alignment, headshots, and the geofence + essentials-coverage plumbing that makes each jurisdiction discoverable. Pure data + coverage; no backend code in this repo.

**Key accomplishments:**

- Seeded **46 elected officials** across three jurisdictions on established blueprints — Falls Church VA (17: council + constitutional officers + FCCPS board, Alexandria template), Greene County MO (13: commission + sheriff + prosecutor + county officers, LA County template), Springfield MO (16: council + SPS R-XII board) — each on the correct government → chamber → district structure with collision-checked `-(geo_id || seq)` external_ids; appointed/shared offices correctly excluded.
- Imported **4 geofence boundaries** so every jurisdiction surfaces for a resident point — Falls Church coterminous school `G5420` (copied from the place polygon), Greene County `G4020` (Census TIGERweb `State_County` layer 1 — MO had zero county boundaries loaded), Springfield place `G4110` + school-district `G5420` (TIGERweb Places layer 4 + School layer 0, school fetched separately as non-coterminous). All verified `ST_Covers` at an in-jurisdiction point + a far negative control.
- Researched and ingested **118 evidence-only compass stances** (Falls Church 55 / Greene County 26 / Springfield 37), every answer paired to an `inform.politician_context` row with a real fetched source URL — **0 unsourced**. Honest blanks where the record is source-walled (ministerial officers, freshmen, a 429-rate-limited SPS questionnaire host) — never inferred from party. Local-governance topics; national topics correctly skipped.
- Imported **46 headshots** at 600×750, Storage-mirrored + `politician_images` rows — including a **clean-sourcing pass** on Springfield (rejected the default CivicEngage thumbnails' baked-in decorative ring; sourced SPS board from `sps.org/meet-the-board`, council from Springfield Daily Citizen press).
- Added **3 essentials coverage entries** (separate repo, Netlify deploy): Falls Church + Springfield as `COVERAGE_STATES` (landing chip + typeahead, purple `hasContext`), Greene County as `COVERAGE_COUNTIES` (search-only, `skip_overlap=1`). A Springfield resident now sees city + SPS + Greene County + Missouri-statewide officials together.

**Requirements:** 5/5 closed (LCC-01..05).

**Stats:**

- 3 jurisdictions, 46 records, 4 boundaries, 118 stances (0 unsourced), 46 headshots, 3 coverage entries
- Migrations 1047 (Falls Church) / 1048 (Greene County) / 1049 (Springfield)
- 9 commits in this repo (`a488232a` → `ef1a364f`) + 3 coverage commits in the essentials repo
- 3 phases (145–147), executed inline; 2 days (2026-06-22 → 2026-06-23)

**Execution note:** This milestone was executed informally (inline, at user request — not GSD-phased) right after v2.18 closed, then formalized retroactively. Phases 145–147 have no plan directories; the per-jurisdiction deep-dive memory files are the authoritative build record. Sibling CA-city builds (Burbank/Norwalk/Bellflower, phases 154–156) and the Nevada work (phases 158–159, essentials team) ran in the same window and are out of scope.

**Key lesson:** `essentials.chambers.slug` is a generated column that collides across same-named cities — "Springfield City Council" silently resolved to Springfield, **Massachusetts** until chamber lookups were scoped by unique government name instead of slug. Scope chamber lookups/guards by government name + chamber name, never slug.

**What's next:** Next milestone TBD — continue local civic coverage (more cities/counties) or pivot. CA cities (Burbank/Norwalk/Bellflower) remain available to fold into a future local-coverage milestone.

---

## v2.18 State Leaders (Shipped: 2026-06-22)

**Phases completed:** 4 phases (141–144), 34 plans

**Goal:** Full-stack coverage of every popularly-elected statewide "Big 5" executive (Governor, Lt. Governor, Attorney General, Secretary of State, Treasurer) across all 50 states — authoritative records, headshots, and sourced compass stances — with a consolidated production gate proving the whole milestone. Pure data milestone; no backend code (STATE_EXEC was already wired into the feed query).

**Key accomplishments:**

- Seeded an authoritative **209-office elected Big-5 roster across all 50 states** (gov 50 / lt-gov 43 / AG 43 / SoS 35 / treasurer 38), deduped on `(STATE_EXEC, state, role_canonical)` — never title string — with `role_canonical` populated, uppercase state codes, non-empty `geo_id`, and a documented `-(state_fips*100000+seq)` external_id scheme verified collision-free. Phantom/appointed/legislature-selected offices correctly excluded per the validated 50-state matrix.
- Imported **173+ headshots** for every newly-seeded exec via `essentials.politician_images.url`, including `.gov`-recovered images for hard cases (ID Treasurer Ellsworth, LA SoS Landry, MT SoS Jacobsen, SC SoS Hammond).
- Researched and ingested **sourced compass stances for 199 in-scope execs** (gov 50 / AG 42 / SoS 34 / treasurer 34 / lt-gov 39) with office-type evidence guidance (Gov=bill signings/vetoes/EOs, AG=lawsuits/amicus/coalitions, Treasurer=fund actions, SoS=election-admin, LtGov=honest-partial) — every answer paired to an `inform.politician_context` row with a real fetched source URL. **0 unsourced rows** at close; never inferred from party.
- Held the evidence-over-party standard rigorously across genuinely narrow-record offices: **10 documented whole-record honest-skips** (OH AG Wilson; SC SoS Hammond; treasurers Boozer-AL/Metcalf-KY/McRae-MS/Haeder-SD; lt-govs Cournoyer-IA/Kelly-NE/Tressel-OH/Pinnell-OK), each pinned by exact external_id in the gate so any future regression fails loudly. SSM=5 kept only on documented anti-recognition litigation/votes/amendments.
- Shipped a single consolidated read-only production gate `verify-phase-141-144.sql` — 11 labeled assertions (records, dedup, headshots, state-code hygiene, per-role coverage, the 10-id honest-skip pin, zero-unsourced, and a SEXR-05 feed-surfacing SQL simulation for NC/WA/CO) — all PASS, psql exit 0; gsd-verifier 6/6.

**Requirements:** 8/8 closed (SEXR-01..05, SEXS-01..03).

**Stats:**

- 4 phases (141–144), 34 plans, 45 commits
- 3 days (2026-06-20 → 2026-06-22)
- Git range: `feat(141-01)` → `docs(144)`

**Known deferred items at close:** 23 (22 historical quick-task dirs 001–022 + 1 stale Phase-109 verification gap — all pre-existing, none from v2.18; see STATE.md Deferred Items). Plus carry-forwards: AZ Lt Gov (Prop 131, eff. Jan 2027) and 3 House vacancies (FL-20/GA-13/TX-23) awaiting special elections.

**What's next:** v2.19+ — AZ Lt Gov seating (post-Jan 2027), House vacancy backfills, and continued stance/coverage expansion.

---

## v2.17 National House Rep Stances (Tier 2 continuation) (Shipped: 2026-06-20)

**Phases completed:** 9 phases (132–140), 45 plans

**Goal:** Extend sourced compass coverage to every remaining seeded US House rep — the 212 reps across the 38 states not covered by v2.16 (FL/NY/PA/IL) — completing the national US House stance layer. Researched largest-delegation-first in 8 waves (132–139) so coverage maximized early if interrupted, then a consolidated gate (140).

**Key accomplishments:**

- Researched and ingested sourced compass stances for **212 in-scope US House reps across 38 states** — 211 fully covered + 1 documented honest-skip (McDowell NC-6, brand-new freshman, no record) — each answer paired with an `inform.politician_context` row carrying a real fetched source URL. **0 unsourced rows** at close.
- Held the chair-philosophy / evidence-over-party standard throughout: every value matched to exact stance text and traced to a fetched URL; honest-skip per topic where no evidence; never inferred from party. Dropped ~23 caucus/committee-membership and "overall-record" proxy rows at review across phases 138–139, refining the rule that caucus membership counts only when the caucus has a published platform directly on that topic.
- Reused the v2.16 pipeline verbatim at **3-concurrency**: shared `_TOPIC_SCALE.txt` (25 federal topics), `politician-stance-researcher` agents → per-rep CSV → RFC-4180 `_merge.ts` (0-problem merges every batch) → external_id-keyed `_push.ts` (answers + context + quotes in one transaction, suffix-aware surname leak-check, 0 leaks across the milestone).
- Added a standing one-try-per-URL efficiency rule to every agent prompt after a 6.5-hour WebFetch stall in phase 137 — all subsequent agents finished in 1–6 min.
- Caught two roster traps by querying production before authoring (not assuming the obvious pattern): Indiana's non-contiguous in-scope set (137) and the at-large states' `-{fips}000` external_ids (139).
- Consolidated phase gate `backend/scripts/verify-phase-132-140.sql` — read-only labeled assertions for USHS-06..14, all PASS against production (per-wave coverage + 211/212 with the McDowell gap pinned to exactly -37006 + 0 unsourced).

**Requirements:** 9/9 closed (USHS-06..14).

**Carry-forward:** McDowell NC-6 awaits a documentable record (auto-fill later). FEC finance for these reps → FINA stream. Combined with v2.16, the full seeded national House layer (299 reps = 87 + 212) is now 298/299 covered.

**Stats:** ~85 commits (v2.16..HEAD) · 2026-06-18 → 2026-06-20 · git range `feat(132-*)` → `docs(140)`. Honest-skip/proxy discipline: 1 full rep skip + ~23 proxy rows dropped.

---

## v2.16 National House Rep Stances (Tier 2) (Shipped: 2026-06-18)

**Phases completed:** 5 phases (127–131), 9 plans

**Goal:** Give the newly-seeded US House reps sourced compass alignment so they appear with data in the representatives feed — bounded first chunk of the 4 largest delegations (FL 27, NY 26, PA 17, IL 17 = 87 reps).

**Key accomplishments:**

- Researched and ingested **1,338 sourced compass stances across 87 US House reps** (FL 394, NY 412, PA 262, IL 270), each with a paired `inform.politician_context` row carrying real fetched source URLs — **0 unsourced rows** at close.
- Held a strict evidence-over-party standard throughout: every value matched to exact stance text and traced to a fetched URL; honest-skip per topic where no evidence; never inferred from party. Agents verified the hard cases (Fitzpatrick moderate-R, Thompson/LaHood Respect-for-Marriage-Act votes, Sorensen deportation=4 via Laken Riley) rather than defaulting to party labels.
- Validated a reusable, token-efficient research pipeline at **3-concurrency** (premium tier): shared `_TOPIC_SCALE.txt` (25 federal topics = 44 live minus 11 city + judicial-*), `politician-stance-researcher` agents writing per-rep CSVs, external_id→UUID resolution, and a canonical re-parse(`relax_column_count`)/re-stringify CSV-repair step that absorbed every escaping artifact (quad-quotes, unwrapped quote/name fields, trailing commas) for 0-problem merges.
- Built the reusable external_id-keyed push (`backend/data/stance-research/pa-house-a/_push.ts`) — answers + context + quotes in one transaction with suffix-aware surname leak-check.
- Consolidated phase gate `backend/scripts/verify-phase-127-131.sql` — read-only labeled assertions for USHS-01..05, all PASS against production (87/87 covered, 0 unsourced).

**Requirements:** 5/5 closed (USHS-01..05).

**Carry-forward:** Remaining ~212 US House reps (all other states) → v2.17+; FEC finance for the newly-seeded reps → FINA stream. 3 genuine vacancies (FL-20/GA-13/TX-23) auto-fill on seed re-run.

**Stats:** ~25 commits · 2026-06-16 → 2026-06-18 · git range `feat(127-01)` → `docs(131)`.

---

## v2.15 National House Rep Seeding (Tier 1) (Shipped: 2026-06-16)

**Phases completed:** 2 phases, 4 plans

**Goal:** Turn the already-complete national congressional geofencing (Phase 116/v2.11) into a usable feature — every US resident's address resolves to their actual sitting US House representative.

**Key accomplishments:**

- Seeded the 299 missing US House representatives (politician + office records) from `unitedstates/congress-legislators`, FK-linked to existing `NATIONAL_LOWER` districts via `tiger_geoid` — linked reps went from 137 → 436 (Phase 125, migration 739).
- Built `backend/scripts/seed-national-house-reps.ts` — idempotent, reusable ingestion script (party normalized `Democrat→Democratic`, at-large/territory/vacancy handling) that re-runs cleanly to pick up newly-seated members.
- Headshots for all 299: 292 via the canonical `unitedstates.github.io` congress photos (migration 769) + 7 recent members via `find-headshots` from official 119th-Congress Wikimedia portraits, storage-mirrored (Phase 126).
- Consolidated phase gate `backend/scripts/verify-phase-125-126.sql` — all USHR-01..05 assertions pass; Path 0 verified across WY (at-large), NY, TX, OH, IL + DC.

**Requirements:** 5/5 closed (USHR-01..05).

**Known deferred items at close:** 23 pre-existing (see STATE.md Deferred Items) — 22 historical quick-tasks + 1 stale verification gap; none from v2.15.

**Carry-forward:** 3 genuine House vacancies (FL-20/GA-13/TX-23) auto-fill on a seed re-run after special elections; CA-29 has a stale Tony Cárdenas office (pre-existing v2.2 data) to clean up; stance research for the 299 new reps = Tier 2 (v2.16).

---

## v2.13 MA City Council District Geofencing (Shipped: 2026-06-15)

**Delivered:** Per-ward Path 0 city council geofencing for 6 MA cities — Boston, Worcester, Springfield, Lowell, Brockton, and Quincy. Each city's council district polygons imported into `geofence_boundaries` + `geo_districts`; `tiger_geoid` backfilled on all city council district rows; Path 0 verified and human-approved for all 6 cities.

**Phases completed:** 1 phase (119), 4 plans (119-01 through 119-04)

**Key accomplishments:**

- Boston (migration 659): 9 ward polygons (MTFCC X0013) + 2 citywide district rows tiger_geoid linked; MAGE-10 ✅
- Worcester (migration 660): 5 ward polygons (X0014) + 5 district rows re-linked; MAGE-11 ✅
- Springfield (migration 661): ward polygons + district re-link; MAGE-12 ✅
- Lowell (migration 662): ward polygons + district re-link; MAGE-13 ✅
- Brockton (migration 663): ward polygons + district re-link; MAGE-14 ✅
- Quincy (migration 664): ward polygons + district re-link; MAGE-15 ✅

**Stats:**

- 1 phase (119), 4 plans
- 6 migrations (659–664)
- MAGE-10..15 all pass; Path 0 human-approved for all 6 MA cities

**Git range:** `2fd8178a` → `bfdcd8cb`

**Requirements closed:** MAGE-10, MAGE-11, MAGE-12, MAGE-13, MAGE-14, MAGE-15

---

## v2.12 MA Expansion (Shipped: 2026-06-15)

**Delivered:** Full Massachusetts civic data expansion — sourced compass stance data for 71 city officials across 7 MA cities (Boston, Cambridge, Worcester, Springfield, Lowell, Brockton, Quincy) with 512 total stance rows, plus MA TIGER state legislative geofencing (200 MA district tiger_geoid backfills, Medford geo_id fix, Path 0 verified for MA state legislators).

**Phases completed:** 2 phases (117–118), 6 plans (117-01, 117-02, 117-03, 118-01, 118-02, 118-03)

**Key accomplishments:**

- Boston (migration 574): 14 officials, 162 stances — Mayor Wu + 4 At-Large + 9 District Councillors
- Cambridge (migration 575): 15 officials with data, 166 stances — Mayor Siddiqui + 9 Councillors + 5 School Committee; Hudson correct zero
- Worcester (migration 576): 11 officials, 86 stances — Mayor Petty + City Manager Nguyen + 9 Councillors
- Springfield (migration 577): 8 officials with stances, 35 stances; 6 newly-elected 2025 councillors correct zeros
- Lowell (migration 584): 11 officials, 21 stances — Mayor Rourke + City Manager Sheehan + 9 Councillors
- Brockton (migration 589): 3 officials, 13 stances — Mayor Sullivan + 2 Councillors with accessible record
- Quincy (migration 597): 9 officials, 29 stances — Mayor Koch + 8 Councillors; DiBona honest-skip
- MA TIGER Geofencing (migrations 619, 622): 200 MA state legislative districts tiger_geoid backfilled (160 STATE_LOWER + 40 STATE_UPPER); Medford geo_id corrected; Path 0 verified (Porter Square Cambridge → STATE_LOWER 25083 + STATE_UPPER 25D27); all MAGE-00..05 gates pass

**Stats:**

- 2 phases (117–118), 6 plans
- 9 migrations (574–577, 584, 589, 597, 619, 622)
- 512 stances, 71 officials with data, 200 MA state legislative districts geofencing-ready

**Git range:** `a200d403` → `c0e1c3eb`

**Requirements closed:** Phase 117 (7 MA cities, all gates pass) + Phase 118 (MAGE-00..05 pass, Path 0 live)

**Known patterns established:**

- `BEGIN;` in one `execute_sql` call + `COMMIT;` in another = silent rollback — use auto-commit for multi-chunk idempotent migrations
- MAGE-05 geo_id collision: geo_id '25017' is both Middlesex County (G4020) and 8th Bristol SLDL (G5220) — always add mtfcc IN ('G5210','G5220') filter when querying geofence_boundaries for state legislative layers
- PROJ_LIB on this machine: C:\Program Files\GDAL\projlib (not C:\OSGeo4W\share\proj as documented)
- Cambridge officials: query by district_id `cf3274f9-48c3-4e96-8273-3f6574add756`, not government_id (NULL on Cambridge districts)

---

## v2.11 FEC Finance Completion + US House Geofencing (Shipped: 2026-06-12)

**Delivered:** Full FEC finance coverage for sitting senators + 2026 candidates + all VA House reps; TIGER 2024 CD119 all 435 US House districts imported for national Path 0 geofencing.

**Phases completed:** 3 phases (114–116), 3 plans

**Key accomplishments:**

- FEC Script Fix (Phase 114): Fixed committee lookup fallback (`.committee_id` not `.id`), multi-cycle totals loop, DIRECT_FEC_ID_OVERRIDES for stale YAML entries; Ivey/Self/Warnock/Cruz/LaMalfa/Swalwell all financed
- Senate Candidate FEC (Phase 115): ~32 2026 Senate candidates researched; Strauss/Jain marked not_applicable
- US House TIGER (Phase 116): All 435 CD119 polygons imported (51-state per-state download after national ZIP 404); tiger_geoid backfilled on all NATIONAL_LOWER districts; Path 0 verified

**Stats:**

- 3 phases (114–116), 3 plans
- 435 US House geofence polygons live
- FEC NULL count: 40 → low single digits

**Git range:** `96e0a872` → `83b87196`

**Requirements closed:** FECF-01, FECF-02, FECF-03, FECF-04, FECF-05, UHGE-01, UHGE-02, UHGE-03

---

## v2.10 Virginia Coverage + LA County Finance (Shipped: 2026-06-11)

**Delivered:** Full Virginia civic data layer + LA County Finance closure — 100 House delegates + 11 federal House reps seeded, TIGER 2024 SLDL/SLDU polygons imported for VA Path 0 geofencing, sourced stances for 40 state senators + 68/100 delegates + 11 federal House reps, 11/11 FEC finance_summary populated, VPAP HTML-only documented; plus 192 LA City officials with CAL-ACCESS finance data.

**Phases completed:** 5 phases (109–113), 21 formal plans (Phase 110 informal)

**Key accomplishments:**

- LA County Finance: 192 LA City officials finance_summary via CAL-ACCESS/Socrata (8-assertion gate PASS); Netfile probed 26 cities — zero-contribution API gap documented; Patrice Lattimore appointed-official NULL documented
- VA Official Records + Geofencing: 100 House delegates (migration 319) + 11 federal reps (migration 311) + 3 state execs (316/317); TIGER 2024 SLDL (100 polygons) + SLDU (40 polygons) imported; tiger_geoid backfilled (migration 321) — VA Path 0 live
- VA State Senators: 40 senators researched — 35 with sourced stances (migrations 326–330); 5 honest-skips (Head/Hackworth/Mulchi/Cifers/Srinivasan); MA politician gap-fill bundled (migrations 359–371)
- VA Delegate Stances: 68/100 delegates with sourced stances (297 rows), 32 honest-skips across 10 waves (migrations 331–340); Wave 1 SW VA all 10 honest-skips; full NoVA sweep no skips
- VA Federal Stances + Finance: 11 VA House reps — 105 stance rows (migration 341); 11/11 FEC finance_summary; politician_sources crosswalk fix for 5 informal-name reps; VPAP vpap-documented

**Stats:**

- 5 phases (109–113), 21 formal plans
- 210 files changed (+69,917/−460 LOC)
- 4 days (2026-06-08 → 2026-06-11)

**Git range:** `734f6637` → `69a62534`

**Requirements closed:** VAIN-01, VAIN-02, VAIN-03, VAGE-01, VAGE-02, VAGE-03, VAST-02, VAST-03, VAST-04, VAST-05, VAFI-01, VAFI-02, LAFI-01, LAFI-02 (14/15 ✓)

**Known gaps:** VAST-01 (VA state executives) — deferred cross-team to Essentials Phase 106

---

## v2.9 LA County Expansion (Shipped: 2026-06-08)

**Delivered:** Complete LA County civic data layer — full elected governing bodies for 27 cities across 4 waves: gap-fill for 14 partial Tier 1 cities, Beverly Hills + Santa Monica structure completion + LA City Controller + Clerk, 10 new cities built from scratch, plus a phase gate SQL script (8 assertions) and smoke test confirming representatives-me surfaces all Phase 108 officials.

**Phases completed:** 1 phase (108), 5 plans
**Phase 109 (LA County Finance) deferred** to future milestone.

**Key accomplishments:**

- Wave 1 gap-fill: 14 Tier 1 partial LA County cities (Long Beach, Glendale, Pasadena, Burbank, Downey, El Monte, Inglewood, Lancaster, Norwalk, Palmdale, Pomona, Santa Clarita, Torrance, West Covina) now have complete elected governing bodies; Census FIPS geo_ids backfilled on all 14 city district rows for Path 0 geofencing
- Wave 2 structure completion: Beverly Hills 6 politicians (3 pre-existing + Mayor + Sharona Nazarian + Treasurer Howard Fisher), Santa Monica 10 politicians (6 pre-existing + 4 new council members), LA City Controller Kenneth Mejia + appointed City Clerk Patrice Lattimore — City Attorney office explicitly left vacant pending November 2026 runoff per RESEARCH.md Critical Finding 1
- Wave 3 new cities: 10 new `essentials.governments` rows + full chamber/district/politician/office stack — 52 new politicians across South Gate, Compton, Carson, Hawthorne, Whittier, Alhambra, Gardena, Culver City, West Hollywood, El Segundo; West Hollywood FIPS 0684410 verified via Census Geocoder API (corrected from inferred value 0684346)
- Phase gate + verification: `backend/scripts/verify-la-county-108.sql` (8 labeled assertions covering all 6 LAOF requirements) + `backend/scripts/smoke-la-representatives-me.ts`; Assertion 7 join bug (WR-07) caught in review and fixed in 108-05 gap plan

**Stats:**

- 1 phase (108), 5 plans
- 53 files changed (+11,813/−42 LOC)
- 1 day (2026-06-08)

**Git range:** `9427edb` → `641762c`

**Requirements closed:** LAOF-01, LAOF-02, LAOF-03, LAOF-04, LAOF-05, LAOF-06 (6/6 ✓)

**What's next:** Phase 109 (LA County Finance — CAL-ACCESS + Netfile) deferred to future milestone.

---

## v2.8 District of Columbia Coverage (Shipped: 2026-06-08)

**Delivered:** Complete DC civic data layer — government stub, 8 TIGER ward boundary polygons (geofencing), 19 district records, 27 politician + office records with photos, sourced stances for all researched officials, and FEC finance data for Eleanor Holmes Norton.

**Phases completed:** 3 phases (105–107), 6 plans

**Key accomplishments:**

- Seeded DC government stub, 8 CITY_COUNCIL ward districts + 9 SCHOOL_BOARD + 1 NATIONAL_LOWER, and imported DC ward boundaries from DC GIS MapServer (TIGER had no DC SLDL shapefile) into both `geofence_boundaries` and `geo_districts` with GIST index — DC users can now be geofenced to their ward via Path 0
- Seeded 27 DC politician + office records: Mayor Bowser, 13 DC Council members (Chairman + 8 ward + 4 at-large), AG Schwalb, Shadow Senators Strauss + Jain, EHN (with bioguide_id), all 9 SBOE members — every record has photo_origin_url
- Researched and ingested sourced stances for 14 DC Mayor/Council/AG officials (33 rows, migration 289); 9 SBOE members honestly skipped (JS-rendered site, zero documentable stances per D-07, migration 290); Jain 6 stances + EHN 18-stance gap-fill + Strauss honest skip (migration 291)
- FEC finance ingestion for Eleanor Holmes Norton via targeted `ehn-fec-finance.ts` script — YAML bioguide crosswalk, committee ID fallback for delegates; DC OCF assessed and documented as non-machine-readable (DCFI-02 closed with finding)

---

## v2.6 Elections Central (Shipped: 2026-06-04)

**Delivered:** Elections discovery page at `/elections` — users enter a street address and see all upcoming elections on their ballot, grouped by tier (Federal / State / Local), with race cards and candidate cards. Backed by a new `GET /api/essentials/elections-by-address` endpoint that geocodes the address, runs a PostGIS geofence join for district-matched races plus a statewide fallback, and returns a grouped elections → races → candidates hierarchy. Utah 2026 Primary (June 23) seeded as first major test data set via migration 267.

**Phases completed:** 99 (5 plans: backend endpoint, frontend component, data migration + verification, fix loop, ship declaration)

**Key accomplishments:**

- `GET /api/essentials/elections-by-address` endpoint — geocodes address via `geocodeAddress()`, two-query approach: PostGIS ST_Covers join for geofence-matched races + state-code join for statewide/at-large races; merges with dedup; returns `{ elections }` hierarchy; graceful 200 `{ elections: [] }` on geocoder failures
- `/elections` route in essentials app — redirects to `/results?prefilled=true&view=elections`; `fetchElectionsByAddress()` in api.jsx using `publicFetch` (public data, no auth required); `ElectionsView.jsx` renders tier-grouped (Federal/State/Local) race cards with candidate cards, UNOPPOSED badge, compass-compare link for stanced candidates, branch icon chips
- Migration 267: UT 2026 Primary — 1 election (June 23, 2026), 138 races, 171 candidates (19 linked to known politician UUIDs); `source = https://vote.utah.gov/2026-candidate-filings/`; all idempotent via ON CONFLICT
- Playwright browser verification (PASS): SLC test address returns Local (Salt Lake County Executive + Legislative), State (Senate D9, House D22, SBE D5), and Federal (US House D1) races; mobile 375px clean; zero JS errors

**Stats:**

- 3 phases (99-01 backend, 99-02 frontend, 99-03 migration/verify), 5 plans total
- 3/3 requirements closed (ELEC-01, ELEC-02, ELEC-03)
- No Wave 2 fixes required — Wave 1 verification passed clean

**Requirements closed:** ELEC-01, ELEC-02, ELEC-03

---

## v2.6 — Data Quality & Elections

**Shipped:** 2026-06-05
**Phases:** 87, 88, 89, 90, 99 (13 plans)
**Git range:** 3b4d16f → 7adc689 (132 commits, 229 files, +23,493/−1,047 LOC)
**Timeline:** 3 days (2026-06-02 → 2026-06-05)

### Delivered

- Stance accuracy audit covering all ~1,049 politicians — 255 flagged, 8 confirmed inversions corrected, party strings normalized
- Gap-fill ingestion: missing stances researched and ingested for all politicians with < 10 stances
- Campaign finance: `finance_summary` JSONB column on `essentials.politicians`; FEC ingestion for 209/258 federal politicians; surfaced on all API endpoints
- Elections Central: `/elections` page shipped with geofenced race data, antipartisan headers, address-based auto-fetch, Utah 2026 Primary seeded (138 races, 171 candidates)
- Code review fixes: 8 findings applied across Phase 99 (CR-01/02/03 + WR-01/03/04/05 + IN-02)

### Known Gaps

- FINA-02 partial: 49 federal politicians still have NULL finance_summary (44 no FEC ID, 5 persistent API timeouts)
- Phase 99 VALIDATION.md not written (Nyquist partial)

---

## v2.2 TIGER District Geofencing (Shipped: 2026-05-10)

**Delivered:** Full CA TIGER district geofencing pipeline — 1,147 polygon layers imported (assembly, senate, US house, school districts), cached per-user in PostGIS, with a zero-live-lookup Path 0 fast path in the representatives feed, a new Profile Location tab, and an operator recache CLI for redistricting events.

**Phases completed:** 69–71 (8 plans total)

**Key accomplishments:**

- TIGER 2024 schema — `essentials.geo_districts` (GIST-indexed point-in-polygon table with layer discriminator) + `connect.user_districts` (per-user cache), `resolve_user_districts` + `cache_user_districts` RPCs (SECURITY DEFINER, SET search_path='', coordinates never leave Postgres)
- Legislative import — 172 CA polygons: 80 CA Assembly, 40 CA Senate, 52 US House (CD119); `tiger_geoid` backfilled on all existing `essentials.districts` records for 3 CA layers
- Path 0 in `GET /representatives/me` — joins `connect.user_districts → essentials.districts` on `(tiger_geoid, district_type)` with no live PostGIS lookup; pre-Phase-70 users self-promote via Path 1.5 fire-and-forget backfill
- Geofencing fail-open into both location-write flows — Connected `POST /set-location` and Inform `PATCH /location-hint` both call `cache_user_districts`; `GET /api/account/districts` endpoint live for both tiers
- School district import — 975 CA polygons (346 unified, 517 elementary, 112 secondary); migration 093 extends default p_layers to 6 layers; `GET /api/account/school-district` endpoint
- Profile Location tab — tier-aware tab on `login.empowered.vote/profile`: `SchoolDistrictSection` (Google search links), City Council display (outside TIGER guard), recalibration controls; 6-layer caching via migration 094 overload fix

**Stats:**

- 49 files changed, ~16,450 insertions, 37 deletions
- 3 phases, 8 plans, 14/14 requirements (GEO-01–14)
- 2 days (2026-05-09 → 2026-05-10)

**Git range:** `e0b3c58` → `e796e28`

**What's next:** v2.0 completion (Phases 64–65) and v2.3 planning — run `/gsd:new-milestone`

---

## v1.9 Roles (Shipped: 2026-04-06)

**Delivered:** Delegated authority system — geo-scoped and resource-scoped roles, a full audit trail, role-gated contributor endpoints for compass stances / campaign management / essentials editing, and a contributor portal at `app.empowered.vote/contributor`.

**Phases completed:** 51–58 (19 plans total)

**Key accomplishments:**

- Role infrastructure: `feature_scope` + `jurisdiction_geoid` + `resource_id` columns on `public.user_roles`; `grant_role`/`revoke_role`/`get_user_roles` SECURITY DEFINER RPCs; 5 role types seeded; `public.role_audit_log` with full audit field set
- `requireRole()` middleware with NULL-safe jurisdiction check, Redis-backed caching, and `checkRole()` pure function tested across all NULL-scope and scope-match combinations
- Admin UI: grant/revoke modal with role-type dropdown, user typeahead, jurisdiction chips from stored districts; global role audit dashboard filterable by scope/jurisdiction/date
- Role-gated endpoints: `PUT /api/compass/stances/:politicianId` (compass_stance_editor + campaign_manager), `PATCH /api/essentials/politicians/:id` (essentials_data_editor), `GET /api/contributor/me`, `POST /api/roles/check`
- Jurisdiction scoping via live `offices→districts JOIN` — never filter on `home_jurisdiction_geoid` (NULL on all 2,577 `essentials.politicians` rows)
- Contributor portal (Phase 58): dashboard with role grant cards, Compass Editor (jurisdiction-scoped politician list + inline stance editor), Candidate Coordinator (single-politician stance editor), Essentials Editor (field-level bio editor with dirty state tracking)

**Stats:**

- 119 files changed, 18,316 insertions, 150 deletions
- ~62,000 lines of TypeScript (project-wide)
- 8 phases, 19 plans, 17/17 requirements
- 4 days (2026-04-02 → 2026-04-06)

**Git range:** `7eb7e29` → `2355754`

**What's next:** v2.0 — run `/gsd:new-milestone` to define scope

---

## v1.5 Partner Integration & Referrals (Shipped: 2026-03-19)

**Delivered:** Referral dashboard card with locked/waiting/active states, plus two canonical partner integration guides (CompassV2 and Essentials) that fully document auth, jurisdiction, and the Inform-baseline / Connected-enhanced access pattern.

**Phases completed:** 31–33 (3 plans total)

**Key accomplishments:**

- Referral dashboard card — locked (level < 2), waiting (invitee < level 2), and active (code + one-click copy) states; all three driven entirely by `GET /api/referral`; `requireConnected` middleware ensures Inform-tier users never trigger the fetch
- `docs/COMPASSV2-INTEGRATION.md` — 745-line ground-up integration guide: Auth Hub redirect flow, 16 endpoints with TypeScript shapes, tier access rules (Inform/Connected/Empowered), jurisdiction "never ask for address" as a first-class section, 8 inline anti-pattern blockquotes; `COMPASS_CONTRACT.md` hard-deleted
- `docs/ESSENTIALS-INTEGRATION.md` — 654-line integration reference: three-branch `detectUserState()` (no token / 401 / 200 with/without jurisdiction), "Inform is the unconditional baseline" framing, opt-in XP/gem awards as Connected enhancement, all 10 jurisdiction fields with TIGER/Line GEOID formats and production examples
- Integration guide format established as project standard: 10-section structure (quick ref → context → auth → reads → writes → profile → jurisdiction → migration → errors → checklist) with anti-patterns inline at point of relevance

**Stats:**

- 25 files changed (+4,624 / -760 lines across docs and planning)
- ~16,856 lines of TypeScript (no net TS growth — v1.5 was documentation + verification)
- 3 phases, 3 plans, 16 requirements
- 1 day (2026-03-19)

**Git range:** `bf63b22` → `fc3b008`

**What's next:** v1.6 — run `/gsd:new-milestone` to define scope (candidates: scoped roles system, VR admin dashboard, user-to-user compass compare, Essentials XP source provisioning)

---

## v1.4 Profile Hub & Verification Engine (Shipped: 2026-03-17)

**Delivered:** Full civic identity profile page for Alpha users — Verification Rating system with VQ integration, atomic VQ confirmation endpoint, CTC + VQ live smoke tests passed, and a Profile Hub UI showing tier/XP/gems/VR with feature hub cards.

**Phases completed:** 27–30 (7 plans total)

**Key accomplishments:**

- Verification Rating schema — `verification_rating` (INT default 60, max 150) + `vq_hold_until` on `connected_profiles`; server-side derived booleans `vq_hold_active` and `red_gem_quests_unlocked` on `GET /me`; 90 threshold unlocks Red Gem quests; rating 0 sets 30-day hold
- `POST /api/vq/confirm-stance` — atomic `confirm_vq_stance` SECURITY DEFINER RPC with deadlock-safe advisory locks (sorted UUID order), inline gem INSERT + balance UPDATE (no nested SECURITY DEFINER), ±VR adjustments with cap/floor, confirmed stance upsert to `inform.politician_answers`, and idempotent replay via `vq_confirmation_results` pre-check
- Admin VR override controls — `PATCH /api/admin/accounts/:userId/verification-rating` + AccountDetailPage inline editor with draft state, 0–150 range validation, status badges, and hold-clear toggle
- CTC + VQ integrations live smoke-tested on 2026-03-17 — CTC: total_xp 1996→2096, is_duplicate:false, replay confirmed; VQ: new_rating +3, gems_awarded:1, replayed:true on replay
- Profile Hub UI — full civic identity page: tier badge, Level, total XP, yellow/blue/red gem balances, Verification Rating (X/150 + hold warning); location address form → `POST /connect/set-location`; 6 feature hub cards (CTC, VQ, Essentials, Read & Rank, Empowered Compass, Treasury Tracker); Civic Spaces jurisdiction pills; dark mode toggle

**Stats:**

- 19 files changed (backend/admin scope)
- ~17,081 lines of TypeScript (backend/src + admin/src)
- 4 phases, 7 plans, 18 requirements
- 2 days (2026-03-15 → 2026-03-17)

**Git range:** `fd496d9` (feat(27-01): add verification_rating migration) → `3a9d99f`

**What's next:** v1.5 — CompassV2 frontend integration (Accounts side complete in v1.3; CompassV2 repo implements its side using `docs/COMPASS_CONTRACT.md`); Essentials overlay compass data endpoint; user-to-user compass compare (COMP-05)

---

## v1.3 Alpha Launch & Location Infrastructure (Shipped: 2026-03-15)

**Delivered:** Production Alpha live with all migrations deployed; encrypted location infrastructure with PostGIS jurisdiction resolution; three-currency gem system; universal Connected Account signup portal; 21 compass topics, 30 politicians, and 1,000+ stance records seeded to production.

**Phases completed:** 17–26 (26 plans total)

**Key accomplishments:**

- Live Alpha deployment: migrations 026–036 applied to production via SQL Editor; smoke test 4/4 pass; idempotent `applyMigrations.ts` + six-step `DEPLOY.md` cold-start runbook; Windows MINGW64 DNS workaround documented for future reference
- Location privacy infrastructure: `encrypted_lat`/`encrypted_lng` (pgcrypto via Supabase Vault) on `connected_profiles`; Indiana TIGER/Line 2024 PostGIS boundaries (5 types); `upsert_user_location` + `resolve_user_jurisdiction` SECURITY DEFINER RPCs; architecture test enforcing zero coordinate leakage at 0 violations; `POST /connect/set-location` + `GET /me/jurisdiction` API
- CompassV2 API contract: Bearer token auth on all routes (JWKS); NUMERIC(3,1) compass values with decimal support; `completed_onboarding` + structured `xp` object on `GET /me`; `docs/COMPASS_CONTRACT.md` external integration spec
- Multi-currency gem system: yellow/blue/red ledger with idempotency; `POST /api/gems/award` with per-key `permittedTypes`; balance-always-0 bug confirmed fixed via integration test; CTC migration path off direct RPC documented
- Central profile + admin tier promotion: public `GET /profile/:userId`; owner `GET /profile/me`; `Inform→Connected` promotion with `tier_promotion_log` audit trail; admin search-as-you-type, PromotionsPage, global history
- Public Auth Hub + production data: `accounts.empowered.vote` rebranded as universal Connected Account portal; tier-based post-login routing; `signup_with_invite` RPC; `?redirect=` with trusted-domain validation; partner onboarding docs for CTC + VQ; 21 compass topics + 30 politicians + 588 stance values + 500 reasoning rows seeded via `scripts/seedData.ts`

**Stats:**

- 145 files changed (27,343 insertions, 2,051 deletions)
- ~16,010 lines of TypeScript (backend/src + admin/src)
- 10 phases, 26 plans, 33 requirements
- 8 days (2026-03-08 → 2026-03-15)

**Git range:** `fix(account): read total_xp` → `chore(v1.3): final cleanup`

**What's next:** v1.4 — compass data visible to users, set-location UI in accounts portal, CTC + VQ integration verification, compass admin tooling

---

## v1.2 CompassV2 Integration & Alpha Hardening (Shipped: 2026-03-07)

**Delivered:** CompassV2 frontend compatibility, alpha hardening (clean types + JWT revocation + 90 clean tests), and a full compass admin backend + React UI — so the Inform pillar is fully seeded and manageable without touching the database, and real Alpha users can use CompassV2 against this backend.

**Phases completed:** 12–16 (15 plans total)

**Key accomplishments:**

- Regenerated Supabase types and achieved strict TypeScript compilation (0 errors) across backend + admin source tree; 90 architecture tests pass with 0 skips or TODO workarounds; JWT revocation verified end-to-end (blocklisted token rejected on next request, not just at expiry)
- CompassV2 reset flow: `DELETE /api/compass/answers/me` soft-deletes all responses via `reset_compass_answers` RPC; `GET /api/compass/answers` and batch read both filter deleted rows with `.is('deleted_at', null)` — full E2E verified in Phase 16 gap closure
- `GET /api/essentials/politicians` accessible without authentication (uses `supabaseAnon`); `POST /api/connect/compass-import` extended to accept `selected_topics` array stored in `connected_profiles.selected_topic_ids`
- Full compass admin backend: 12 new routes in `admin.ts`, 7 new service functions in `adminService.ts`, `admin_create_topic_with_stances` atomic Postgres RPC (two-pass validation, all-or-nothing), migration 029 with three admin RPCs; 102 total tests
- Compass admin React UI: Topics page (list, create modal, live toggle, stance editor), Politicians page (list, create, detail with per-topic answers and context), Categories page (list, create, topic assignment) — all backed by new admin endpoints
- Gap closure (Phase 16): `GET /admin/compass/topics/:id/stances` added to unblock stance editor; soft-delete filter corrected (`.is()` not `.eq()`); CategoriesPage response shape fixed; `adminCreateTopic` dead code removed; id types corrected to `string` (UUID)

**Stats:**

- 65 files modified (+11,179 / -208 lines)
- ~13,334 lines of TypeScript (backend/src + admin/src)
- 5 phases, 15 plans, 20 requirements
- 2 days (2026-03-06 → 2026-03-07)

**Git range:** Phase 12 start → `97f9c6f`

**What's next:** v1.3 — live Alpha deployment runbook (migrations 026–029 apply), CompassV2 frontend API contract updates (CV2-01 through CV2-05), and Alpha user onboarding

---

## v1.1 XP & Progression (Shipped: 2026-03-04)

**Delivered:** A unified XP and leveling system — append-only ledger, atomic award RPC, tiered level calculation, public XP profile endpoint, and admin ledger view — so any feature repo can award XP with idempotency guarantees.

**Phases completed:** 9–11 (5 plans total)

**Key accomplishments:**

- Built append-only `connect.xp_transactions` ledger with UNIQUE `idempotency_key`, `total_xp`/`current_level` denormalized on `connected_profiles`, and owner-read RLS — mirrors gem ledger pattern; all XP writes are atomic and impossible to double-award
- Implemented `calculate_level` as an IMMUTABLE SQL function with tiered thresholds (2k × 3 levels, 3k × 6, 4k × 20, 5k thereafter) computable from any total XP — plus a 12-test SQL verification suite covering all tier boundaries and RLS isolation
- Delivered `award_xp` SECURITY DEFINER RPC with advisory lock and idempotency pre-check — single atomic write path that updates ledger + profile columns in one transaction; duplicate key returns 200 with original transaction and is_duplicate flag
- Added `POST /api/xp/award` with service-key middleware and per-key source authorization: feature repos authenticate via `X-Service-Key`, per-key `permittedSources` prevents cross-feature XP injection, validated source types enforced at Zod layer
- Exposed XP across three endpoints: `GET /api/xp/:userId` (public level profile), `GET /api/xp/me/history` (auth-gated paginated ledger), and structured `{ total, level, xp_in_level, xp_to_next_level }` replacing the legacy integer on `GET /account/me`
- Added admin tool XP visibility: "Level X · Y XP" summary in account header card + full paginated XP History tab on AccountDetailPage with source, amount, metadata expand/collapse, and reverse-chronological ordering

**Stats:**

- 38 files modified (6,809 net insertions)
- ~11,131 lines of TypeScript (9,265 backend + 1,866 admin React)
- 3 phases, 5 plans
- 1 day (2026-03-04)

**Git range:** `a40c502` → `ab82fdb`

**What's next:** v1.2 — live Alpha deployment hardening (supabase gen types refresh, JWT logout security review, pre-existing TypeScript errors, architecture test debt cleanup)

---

## v1.0 MVP (Shipped: 2026-02-28)

**Delivered:** Complete three-tier civic account infrastructure (Inform → Connected → Empowered) with schema, auth, enrollment, compass, empowerment, social graph, admin tool, and public candidate pages.

**Phases completed:** 1–8 (18 plans total)

**Key accomplishments:**

- Built a 4-schema Supabase database with RLS on every table, SECURITY DEFINER RPCs for atomic empowerment/demotion, and split-visibility views that mask `tolerance_rating` and `legal_name` at the database layer — not the application layer
- Implemented JWT auth (JWKS, ES256) with tier-aware `GET /api/account/me` and field-level privacy enforced at both RLS and serialization layers; `tolerance_rating` never reaches non-owners at any layer
- Shipped invite-only Alpha enrollment: atomic invite claim via `FOR UPDATE` row lock, permanent invite chain, inviter Tolerance Rating adjustment RPC, and resumable Connect verification flow
- Built the full political compass: topic calibration with change history, role-filtered completeness scoring, politician comparison, and anonymous calibration import from localStorage with topic version mismatch handling
- Implemented atomic empowerment and demotion as Postgres RPC transactions — partial state is architecturally impossible; preflight validation returns specific failure reasons; consent records audit trail
- Delivered gem ledger, role system, and social graph: append-only gem ledger with advisory-lock atomicity, soft-revocable roles with tier eligibility, peer connection state machine, and `friends`-visibility RLS enforcement via accepted peer connection join
- Built the admin React UI with dashboard, account detail, invite tree (React Flow), and cron log; daily 2am UTC calibration lapse cron with day-25 warning, day-30 final warning, day-31 demotion, and `ON CONFLICT` idempotency
- Shipped public candidate pages: unauthenticated slug and ZIP lookup with `tolerance_rating` absence enforced at both RLS and serialization layers; demoted slugs return consistent inactive state and are never reassigned

**Stats:**

- 182 files created/modified
- ~10,200 lines of TypeScript (8,487 backend + 1,711 admin React)
- 8 phases, 18 plans
- 4 days (2026-02-24 → 2026-02-28)

**Git range:** `feat(01-01)` → `feat(08-02)`

**What's next:** v1.1 — Live deployment, real user Alpha cohort, post-MVP hardening (JWT logout security review, TypeScript pre-existing errors, pre-existing architecture test debt)

---
