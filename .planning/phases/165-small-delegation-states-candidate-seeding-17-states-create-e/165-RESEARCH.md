# Phase 165: Small-Delegation States (17 states) Candidate Seeding - Research

**Researched:** 2026-07-07
**Domain:** Pure-data election seeding (Postgres/Supabase) — fifth and final Wave-3 seeding phase, cloning the proven Phase-161/162/163/164 pipeline. Structurally the MOST HETEROGENEOUS seeding phase in the milestone: two "reconciliation" states with pre-existing races (NV, ME), one court-ordered-redistricting re-key state with a BINDING wiring contract (UT), one nonpartisan top-four-RCV state (AK), one RCV-general state already covered by the ME reconciliation, and 13 routine create-races-first states.
**Confidence:** HIGH on pipeline mechanics (proven 4 times); HIGH on the NV/ME/UT special-case handling (each has a dedicated, already-authored artifact — 160-06-SUMMARY.md, 160-field-table-p165.csv, 164.1-ut-wiring-contract.md — plus fresh live-DB verification this session); MEDIUM on a few late-primary states' exact candidate rosters (NH-2/MT/ND pending independents) which are explicitly time-boxed and re-verified at Phase 167.

## Summary

Phase 165 is **not** a uniform "17× create-elections-first" phase — it is three different seeding shapes layered on the same proven pipeline. **NV and ME already have pre-existing 2026 general-election races** (discovered in Phase 160's `160-race-preexistence-audit.csv` and reconfirmed live this session): NV's 4 races already carry 9 real candidates including all 4 incumbents (only 5 new candidates + 1 NULL-`politician_id` fix needed, zero new elections/races); ME's 2 races already carry the two incumbents' rows (only 2 new candidates needed: Ronald Russell for ME-1, Matthew Dunlap for ME-2). **UT requires the single most contract-bound seeding task in the milestone**: per the BINDING `164.1-ut-wiring-contract.md`, Phase 165 must author a brand-new `UT 2026 Statewide General` election + 4 races on UT's **existing** `NATIONAL_LOWER` offices (geo_ids 4901–4904, confirmed live untouched) and re-link Moore/Maloy/Kennedy's **existing** politician_ids onto their **new**-district race (Moore→4902, Maloy→4903, Kennedy→4904), leaving `essentials.offices` completely untouched until the Jan-2027 promotion phase. **AK is a nonpartisan top-four-RCV state** with no schema-level RCV support (no `ballot_system`/`rcv` DB column exists anywhere in `essentials.races`) — RCV is purely a field-breadth research discipline (capture the full 15-candidate declared field), and the race itself should likely be modeled `primary_party = NULL` (the same LA/CA jungle-primary convention Phase 163 already proved) since Alaska's primary is itself nonpartisan-blanket. The remaining **13 routine states** (NM, NE, WV, ID, HI, NH, RI, MT, DE, ND, SD, VT, WY = 21 districts) follow the vanilla create-elections-first pattern with zero redistricting concerns — live-verified this session: **0 pre-existing 2026-11-03 House races or elections for any of these 13 states.**

A fresh live external_id collision re-check (2026-07-07, this session) against `160-negative-id-audit.csv`'s predictions found **zero drift** for every district that actually matters to Phase 165 — every flagged collision (NV-1/2/4, NM-1/2/3, NE-3, ME-1/2, NH-1, MT-2, AK, DE, VT) reproduced exactly, confirming the audit's `safe_start_seq` values are still safe to use as-is. Two apparent "extra" collisions surfaced in NM's and MT's numeric bands (`Paul A. Cutler` at NM's cd=4 slot; `Stephanie Paice` at MT's cd=3 slot) but both sit in a `cd` slot that doesn't correspond to any real congressional district in those states (NM has only 3 districts, MT only 2) — noise, not real conflicts. DE's new-challenger band is the most dramatic collision: DE's FIPS-scoped range (-100001..-100099) collides with 26 old Wave-1 CA House members and Alabama statewide-exec IDs (a pre-`state_fips` sequential-numbering legacy from before the v2.20/v2.21 convention existed) — confirmed live, `safe_start_seq=48` is correct and mandatory.

**Primary recommendation:** Treat this phase as 4 tracks, not 17 uniform state-clones: (1) **NV+ME candidates-only reconciliation** (clone the OR-164-03 "existing-race reuse" generator pattern — zero elections/races writes), (2) **UT re-key** (a wholly new generator shape: create 1 election + 4 races on existing offices, re-link 3 existing incumbent pids to new geo_ids, seed the new open UT-1 field — follow `164.1-ut-wiring-contract.md` verbatim, never touch `essentials.offices`), (3) **AK RCV** (create-election-first, single at-large race, `primary_party=NULL` jungle-style modeling, 14 new + 1 incumbent-reuse records, maximal-thoroughness field per the standing RCV over-indulgence preference), (4) **13 routine states** (clone `162-mn-generate.mts` verbatim per state, grouped 2-4 states per plan by primary-date urgency, mirroring the 160-06 pairing pattern that already proved efficient for this exact 17-state group).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Election/race authoring (elections, races rows) | Database / Storage | — | Pure data via migration SQL; no service-layer writes |
| Race surfacing on `/elections` | API / Backend (read path) | Database | `electionService.ts` reads races+race_candidates+districts+geofence_boundaries; zero code changes this phase |
| Candidate record creation (politicians, race_candidates) | Database / Storage | — | Pure data via migration SQL |
| NV/ME existing-race reconciliation (dedup + fix-not-recreate) | Database / Storage | Research/analysis | Candidates-only writes onto pre-existing race UUIDs; no new elections/races |
| UT re-key (existing pid → new geo_id race) | Database / Storage | — | Pure data; `essentials.offices` explicitly NOT touched this phase (binding contract) |
| AK top-four-RCV field modeling | Database / Storage | API / Backend (read path) | Single nonpartisan race, `primary_party=NULL`, same read path as every other race — proven CA/LA jungle-primary convention, no schema change |
| Headshot ingestion | Backend script (offline) | Database / Storage | `backend/scripts/seed-*-house-headshots.py` pattern, outside request path |
| Stance research + push | Backend script (offline) | Database | `_merge.ts`/`_push.ts`/`_push_uuid.ts`; writes via `pool.query()`, never PostgREST |
| Consolidated read-only mini-gate (34-district) | Database (read-only) | — | `psql -v ON_ERROR_STOP=1 -f 165-verify.sql` against prod, clone of `164-verify.sql` |

No frontend/browser tier work exists in this phase (identical to 161/162/163/164).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC3-02 | Every candidate has exactly one `essentials.politicians` record; incumbents reuse; party normalized; collision-free external_ids | Per-State/Track breakdown below; live collision re-check (zero drift from `160-negative-id-audit.csv`) |
| USHC3-03 | Every race surfaces on `/elections` via `races`+`race_candidates`; elections/races authored first (except NV/ME reuse); never `office_id IS NULL` | NV/ME Reconciliation Track + UT Re-Key Track + 13-state create-races-first confirmation (0 pre-existing races live-verified) |
| USHC3-04 | Every newly-seeded candidate has a headshot (or documented honest-skip) | Pipeline Templates section — clone `seed-{ks,ar,ms,...}-house-headshots.py` verbatim with new `BANDS` entries |
| USHC3-05 | Every newly-seeded candidate has sourced federal-24 stances, 0-unsourced, honest-skip with search trail | Stance Scope section below |

## The Four Tracks (read this before planning)

### Track 1 — NV + ME: Candidates-Only Reconciliation (NO new elections/races)

**Both states already have live, pre-seeded 2026 general-election races** (discovered in `160-race-preexistence-audit.csv`, reconfirmed live 2026-07-07). This is the exact "existing-race reuse" shape as OR in Phase 164 (`164-03-PLAN.md`, `backend/scripts/164-or-generate.mts`) — clone that generator's structure, NOT the vanilla `162-mn-generate.mts` shape.

**NV** — election `'NV 2026 Statewide General'`, 4 pre-existing races (`existing_race_id` per district, carried in `160-field-table-p165.csv`), 9 real candidates already wired including all 4 incumbents. Live-verified 2026-07-07: **Lynn Chapman's `race_candidates` row still has `politician_id = NULL`** (confirmed present, `id=08dfb911-9ddc-4c0d-85a2-fb14884a9160`) — this is a **fix-not-recreate UPDATE**, not a new INSERT; do not create a duplicate Chapman politician record. New candidates needed (5, per `160-field-table-p165.csv`):
| District | New candidate | Party |
|----------|--------------|-------|
| NV-1 (3201) | Bobby Khan | No Political Party |
| NV-1 (3201) | Steven St John | No Political Party |
| NV-3 (3203) | Jon Kamerath | Independent American |
| NV-4 (3204) | Russell Best | Independent American |
| NV-4 (3204) | William Johnson | No Political Party |

**ME** — election `'2026 Maine General Election'` (a large, shared, multi-office statewide election row — NOT House-specific; do not scope by election name alone, scope by the 2 exact race UUIDs). Live-verified 2026-07-07: race `d92aa73a-...` (ME-1) has exactly 1 candidate (Pingree, incumbent); race `aa63d55d-...` (ME-2) has exactly 1 candidate (Paul LePage, `is_incumbent=false` — correct, since Golden retired and LePage is a challenger, not the sitting incumbent). New candidates needed (2):
| District | New candidate | Party | Notes |
|----------|--------------|-------|-------|
| ME-1 (2301) | Ronald Russell | Republican | Primary-race pid exists (no `politician_id` was ever set on that primary row) but no general `race_candidates` row — verify live at plan time whether a reusable politician record exists before creating new |
| ME-2 (2302) | Matthew Dunlap | Democratic | Beat Baldacci in the primary; same pid-reuse verification caveat |

**Both districts are `ballot_system=rcv-general`, `rcv=true`** (Maine's ranked-choice general) — per D-04a RCV over-indulgence, the field table's capture is already exhaustive (verified against official RCV tabulation results, per `160-06-SUMMARY.md`). No additional RCV research needed for ME; only the 2 missing `race_candidates` INSERTs.

**Pattern to clone:** `backend/scripts/164-or-generate.mts` (candidates-only onto pre-existing race UUIDs, `EXISTING_RACE_ID` map keyed by cd, no election/race INSERT, only an optional description `UPDATE`).

### Track 2 — UT: Court-Ordered Re-Key (the phase's highest-complexity task)

**`164.1-ut-wiring-contract.md` is BINDING** and must be followed verbatim — this research does not re-derive it, only summarizes for the planner. Live-verified 2026-07-07:
- `essentials.elections` has **no** `'UT 2026 Statewide General'` row yet (count=0) — must be created.
- The 4 UT `NATIONAL_LOWER` offices (geo_ids 4901–4904) exist and are **still keyed to the OLD incumbents** (4901→Moore, 4902→Maloy, 4903→Kennedy, 4904→Owens) — confirmed live via `essentials.offices`/`essentials.districts` join. This is CORRECT and EXPECTED per the contract; do not touch these office rows.
- UT's only existing 2026 races are the `'2026 Utah Primary'` (Jun-23) races, one per OLD district number, with real primary-candidate politician records already seeded (`sos_filing` source, several with `politician_photos` Storage URLs already uploaded).

**Binding wiring rule:** Create `'UT 2026 Statewide General'` (1 election) + 4 races on the **existing** offices for geo_ids 4901–4904 (do NOT create new offices/districts). Then wire `race_candidates`:
- **4902 race** ← Blake Moore (existing pid `e365a1d4-...`, `is_incumbent=true`) + new challengers Peter Crosby (D, existing primary pid — reuse, do not recreate), Daniel Cottam (Libertarian, new), Carlton E. Bowen (IAP, new), Robert M. Moesinger (Unaffiliated, new).
- **4903 race** ← Celeste Maloy (existing pid `a7983eb6-...`, `is_incumbent=true`) + Kent Udell (D, existing primary pid — reuse), Cassie Easley (new), Adonis Hooslyn (new), Ayden Scott (new), Michael R. Stoddard (new).
- **4904 race** ← Mike Kennedy (existing pid `9e3164d5-...`, `is_incumbent=true`) + Jonny Larsen (D, existing primary pid — reuse), Taylor Wright (new), Steven Burt (new).
- **4901 race** ← OPEN, no incumbent. Candidates: Riley Owen (R, new — no primary R field was seeded for UT-1, verify live), Ben McAdams (D, existing primary pid `b78f058c-...` — reuse), Jesse West (Libertarian, new), Elias Henry Montgomery (Unaffiliated, new).
- Burgess Owens (`cb87ddbb-...`) retired — **not** a candidate anywhere; his office (4904) stays keyed to him until Jan-2027, but he gets zero `race_candidates` rows this phase.

**Every UT primary-loser** (Farrell, Mohamed, Blouin, Lisonbee, Lyman — anyone in the Jun-23 primary rows NOT listed above as a Nov-3 nominee) gets **zero** new `race_candidates` rows; their existing primary-scoped rows are untouched.

**external_id scheme note:** UT incumbents currently have **no** external_id at all (`NULL` — confirmed via the field table's blank `incumbent_external_id` column and a live band check finding 0 rows in `-490499..-490101`). New UT challengers should still follow the standard `-(49*10000+cd*100+seq)` formula (FIPS UT=49) for consistency with the milestone convention, even though existing UT records use real UUIDs with no external_id. Zero collisions confirmed live in the UT band.

**Critical constraint (repeat because it is the single easiest way to break this phase):** Do NOT write `essentials.offices`, `essentials.geo_districts`, or `connect.user_districts`. Do NOT re-key the offices table. The reps feed intentionally continues showing OLD-map representation until the Jan-2027 promotion phase (spec'd in `164.1-06`) — this is correct, not a bug to fix in 165.

### Track 3 — AK: Nonpartisan Top-Four-RCV, Late-Primary

**No pre-existing race** (existing_race_id blank in field table; live-verified 0 pre-existing 2026-11-03 election/races for AK). Single at-large district (geo_id `0200`). Incumbent Nicholas Begich III (external_id `-2000`, legacy 4-digit scheme, `-partial-tier`, 9 existing stances). **15 candidates in the official Aug-2026-primary declared field** (`elections.alaska.gov/candidates/?election=26prim`), captured exhaustively per D-04a RCV over-indulgence (cross-verified against an independent source, exact candidate-count match required before Phase 160 accepted the field) — 14 new records + Begich's existing reuse.

**No `ballot_system`/`rcv` column exists anywhere in `essentials.races`** (confirmed — grepped the full backend codebase, only CSV research-metadata columns use those names). RCV in this codebase is a **research-thoroughness discipline, not a schema feature**: seed the full declared field as ordinary `race_candidates` rows; the eventual top-four narrowing and ranked tabulation are NOT modeled in the DB (matches how ME's already-decided RCV-general result was seeded — a flat `race_candidates` list, no ranking data).

**Modeling recommendation (new pattern for this phase, not yet used elsewhere in Wave 3):** Alaska's own primary is ALSO a nonpartisan blanket primary (all candidates, all parties, one ballot, top-four advance) — structurally the same "everyone on one ballot" shape Phase 163 proved for Louisiana's jungle primary. **Model AK's single race as `primary_party = NULL`** (clone the CA/LA jungle-primary convention: `essentials.races.primary_party` nullable with a dedicated unique index for `WHERE primary_party IS NULL`, confirmed live in Phase 163's research) rather than attempting to preserve each candidate's party as the race's `primary_party`. Candidate party (R/D/L/Nonpartisan/Undeclared) still lives per-candidate in research/provenance notes — never on the card (unchanged milestone invariant). This is a recommendation, not yet contract-bound like UT's; confirm with discuss-phase or note as Claude's Discretion if no CONTEXT.md exists yet.

Description should carry `'PROVISIONAL: pre-primary qualified field (top-four-RCV), cull >= <AK primary date>'` — AK's 2026 primary date should be re-verified at plan time (typically mid-August in recent AK cycles; the field table's `filing_open_deadline` column is blank for AK, meaning the qualifying window itself, not an independent-petition window, is what gates this — verify the exact Aug-2026 primary date from `elections.alaska.gov` before writing the description).

**D-04 collision sub-band:** AK-0's new-challenger band has 4 pre-existing collisions (seqs 1-4, live-confirmed) — **safe_start_seq=5**.

### Track 4 — 13 Routine Create-Races-First States (21 districts)

**NM(3) + NE(3) + WV(2) + ID(2) + HI(2) + NH(2) + RI(2) + MT(2) + DE(1) + ND(1) + SD(1) + VT(1) + WY(1) = 21 districts.** Live-verified 2026-07-07: **zero** pre-existing 2026-11-03 `essentials.races` or `essentials.elections` rows for any of these 13 states — clean create-races-first, identical shape to `162-mn-generate.mts`. No redistricting concerns for any of the 13 (none are in the committed 164.1 dual-map set of TN/MO/AL/LA/UT).

**Decided (per `160-field-table-p165.csv` `field_status`):** NM(3), NE(3), WV(2), ID(2), MT(2), ND(1), SD(1) = 14 districts — seed the confirmed Nov-3 general field, description NOT `PROVISIONAL:`.
**Late-primary (full qualified field marked `PROVISIONAL:`):** HI(2), NH(2), RI(2), DE(1), VT(1), WY(1) = 9 districts — note: AK (Track 3) is also late-primary, bringing the milestone-wide late-primary count for this phase to 10, matching `160-06-SUMMARY.md`'s "24 decided + 10 late-primary" split exactly.

**Per-state notes the planner needs:**

| State | FIPS | Districts | Status | Key fact |
|-------|------|-----------|--------|----------|
| NM | 35 | 3501-3503 | decided | Both incumbents renominated, only 1 new R challenger each district (Okpareke, Cunningham, Zamora) |
| NE | 31 | 3101-3103 | decided | NE-2 Bacon retired (open seat, 3 new records incl. R nominee Harding); NE-1/3 renominated. **NE independent-petition deadline is Aug-1, NOT Sept-1** (NRS 32-617(1) — a live statute-correction the 160 diagnostic already made; do not re-derive from a stale Sept assumption) |
| WV | 54 | 5401-5402 | decided | Both incumbents renominated, 2-3 new challengers each |
| ID | 16 | 1601-1602 | decided | Both incumbents renominated, 3-5 new challengers each (multi-party: Constitution, Libertarian, Independent) |
| HI | 15 | 1501-1502 | late-primary | Both incumbents renominated but face crowded same-party primaries (HI-1 has 5 D primary opponents for Case incl. state legislators; HI-2 has 4). Official HI filing-status grid (`olvr.hawaii.gov`) distinguishes `"In Primary"` (fully filed — IN) from `"Issued"` (picked up papers, never completed — EXCLUDE); several excluded candidates are named explicitly in the field-table notes (Della Au Belatti, Zachary Burd, etc.) — do not re-add them |
| NH | 33 | 3301-3302 | late-primary | NH-1 is OPEN (Pappas ran for Senate, confirmed via NH SoS cumulative filing — NOT on the NH-1 list) — 14 declared candidates (9D+5R), zero incumbent row; NH-2 Goodlander renominated + 5 new. NH's independent nomination-paper window stays open through **Sept-2** — 3 additional NH-2 independents (Black/Mahrou/Sykes) had filed intent-to-run but NOT yet qualified as of the 160 resolution date — EXCLUDE pending certification, defer to Phase 167 |
| RI | 44 | 4401-4402 | late-primary | Both incumbents renominated, filing deadline **2026-07-10** already closed by Phase 165 execution time in nearly every scenario — re-verify no late qualifiers slipped in |
| MT | 30 | 3001-3002 | decided | MT-1 Zinke retired (open seat, R won primary Flint 50.1%, D Forstag 37.3%) — 3 new records; MT-2 Downing renominated (confirmed NOT running for Senate, a live-verified correction of an initial concern) + 2 new. **2 independents (Persico MT-1, Eisenhauer MT-2) fell short of signature threshold per unofficial county tallies but MT's final certification deadline is Aug-20 — EXCLUDE pending official action, defer any late add to Phase 167** |
| DE | 10 | 1000 | late-primary | McBride (D) renominated unopposed + 1 new R (Earl Cooper). **DE's new-challenger external_id band collides with 26 legacy Wave-1 records (CA House members + AL statewide execs) — MUST use `safe_start_seq=48`, confirmed live** |
| ND | 38 | 3800 | decided | Fedorchak (R) renominated (won primary 72.9%) + 1 new D (Trygve Hammer, D-NPL rematch). Independent petition window open to Aug-31 (2 declared FEC filers not yet SoS-certified — EXCLUDE, defer to 167) |
| SD | 46 | 4600 | decided | Dusty Johnson ran for Governor instead (open seat) — 2 new records (Jackley R, Gronli D); SD's independent petition deadline (Apr-28) already passed, field is FINAL — no Phase-167 follow-up needed for SD's independents (unlike ND/MT/NE/NH) |
| VT | 50 | 5000 | late-primary | Balint (D) renominated + 3 new (2 R primary candidates Coester/Malloy running against each other for the R nomination — both should be seeded provisionally per the full-qualified-field rule — + Independent Adam Ortiz, confirmed present on VT's official qualified-candidates XLSX though absent from Wikipedia — trust the official source) |
| WY | 56 | 5600 | late-primary | Hageman retired (ran for Senate) — **14-candidate open R primary field** alone (Gray/Balow/Biteman/Chapman/Christensen/Dodson/Friess/Giralt/Rasner/Goodenough) + 2 D (Kinney, Del Real) + 1 Libertarian (Johnson) + 1 Independent (Workman) = 18 new records, the single largest new-record count of any district in this phase |

**External_id collision sub-bands (D-04, live-reconfirmed 2026-07-07, zero drift from `160-negative-id-audit.csv`):**

| District | FIPS | Colliding seqs | `safe_start_seq` |
|----------|------|-----------------|-------------------|
| NM-1 (3501) | 35 | 25 | 26 |
| NM-2 (3502) | 35 | 50 | 51 |
| NM-3 (3503) | 35 | 81 | 82 |
| NE-3 (3103) | 31 | 59 | 60 |
| NH-1 (3301) | 33 | 28-32 | 33 |
| MT-2 (3002) | 30 | 84 | 85 |
| AK (0200) | 2 | 1-4 | 5 |
| DE (1000) | 10 | 1-5, 7,9,...,47 (26 total) | 48 |
| VT (5000) | 50 | 1-5 | 6 |

All other districts in this phase (NV-3, all WV/ID/HI/RI/ND/SD/UT/NM-none-remaining/NE-1/NE-2/MT-1/WY) use the standard `seq` start of 1 — zero collisions confirmed live.

## Standard Stack

Zero new packages — identical to 161/162/163/164. All tooling reused verbatim: `pg`/`pool.query()` for all essentials/inform reads+writes, `psql -v ON_ERROR_STOP=1 -f` for migrations and the read-only verify gate, `psycopg2`+`requests`+`Pillow` (invoke via `py`) for the headshot pipeline, `node --import tsx`+`csv-parse/sync` for the `_merge.ts`/`_push.ts`/`_push_uuid.ts` stance pipeline, `.mts` one-off generator scripts for deterministic field→SQL migration generation.

**Migration numbering:** Live-verified 2026-07-07, highest existing migration file is `1249_unwithhold_la_2026_house_races.sql` — **next free number is 1250**. Re-verify via `ls backend/migrations | sort -n | tail` at plan-authoring/execution time (a parallel session on Phases 177/178 or the date-gated 164.1-07 MO wave may land migrations first).

## Package Legitimacy Audit

**N/A — this phase installs zero external packages.** All tooling is already installed and vetted in prior phases (148–164).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Onto-existing-race candidate wiring (NV/ME) | A migration that re-authors NV/ME's elections/races | Candidates-only INSERT onto the carried `existing_race_id` UUIDs, clone `164-or-generate.mts`'s `EXISTING_RACE_ID` map pattern | The races already exist and are correctly wired; re-authoring risks duplicate races (the exact MD-162/MA-161/OR-164 dedup lesson) |
| UT incumbent re-key | A new `essentials.offices` UPDATE, or new politician records for Moore/Maloy/Kennedy | Reuse their EXISTING pids via a `race_candidates` INSERT onto the NEW geo_id's race (candidacy ≠ office) | The binding contract's entire point is that office re-keying is a Jan-2027-only action; conflating candidacy with office assignment breaks the dual-map design |
| Nonpartisan/RCV race modeling (AK) | A new schema column, a multi-round race concept, or per-candidate ranking data | `essentials.races.primary_party = NULL` (already-proven CA/LA jungle-primary convention, Phase 163) | The schema already supports this exact shape (dedicated unique index for `primary_party IS NULL`); no migration needed; RCV tabulation itself is out of scope (not user-facing on `/elections`, which shows a flat candidate list) |
| Old-vs-new district boundary comparison for UT | A shapefile/GIS diff (already done in 164.1) | The already-authored `164.1-ut-wiring-contract.md` correspondence table | Redundant work — 164.1 already did the audit and wrote the binding contract; Phase 165 just executes it |

## Migration Numbering

**Next free migration number: `1250`** (verified live, 2026-07-07: highest existing file is `1249_unwithhold_la_2026_house_races.sql`). Re-verify at plan-authoring/execution time — do not assume 1250 is still free if other work has landed since this research date (163/164's precedent: migration numbers are not always strictly sequential/unique across parallel sessions in this repo).

## Recommended Plan Structure

Mirrors 163/164's per-track-then-per-state structure, adapted for this phase's 4 distinct tracks instead of a uniform state list:

1. **165-01: NV + ME candidates-only reconciliation** (Track 1 — 7 new records total: 5 NV + 2 ME, + the Chapman NULL-pid fix) — the cheapest, lowest-risk win, do first (mirrors 164-03's OR-reuse-first sequencing logic).
2. **165-02: UT re-key** (Track 2 — create 1 election + 4 races on existing offices, re-link 3 incumbent pids, seed ~13 new records across the 4 districts) — the highest-complexity single plan; follow `164.1-ut-wiring-contract.md` verbatim; consider a dedicated verification task confirming `essentials.offices` row counts/hashes are unchanged before/after (a NOTOUCH-style guard, borrowing the 164.1 D-10 convention).
3. **165-03: AK RCV** (Track 3 — create 1 election + 1 at-large race, `primary_party=NULL`, 14 new + Begich reuse) — re-verify AK's exact 2026 primary date before writing the PROVISIONAL description.
4. **165-04 through 165-0X: routine states**, grouped 2-4 per plan by geographic/civic-deadline pairing (mirrors the 160-06 field-resolution pairing that already proved efficient for this exact state set): e.g. NM+NE (both decided, 6 districts), WV+ID (both decided, 4 districts), HI+NH (both late-primary, complex fields, 4 districts), RI+DE+VT+WY (late-primary, tiny/at-large, 5 districts, WY's 18-candidate field is the outlier to budget extra time for), MT+ND+SD (decided, 4 districts, all three have open-independent-window caveats to note but not act on).
5. **165-0X+1 through 165-0Y: stance research plans**, one per state or paired states at planner's discretion, 3-concurrency max, 1 agent per district — WY's 18-candidate field and HI's crowded same-party primaries are the largest single-district stance loads in the phase and may warrant their own plan/checkpoint.
6. **165-final: Consolidated 34-district verify + coordinate-smoke** (clone `164-verify.sql`/`164-coordinate-smoke.ts`) — see Validation Architecture below for the specific NEW assertion blocks this gate needs (NV-RECONCILE, ME-RECONCILE, UT-REKEY, AK-JUNGLE, PROVISIONAL, COLLISION-BAND).

**Total estimated new candidate records:** ~110-130 (rough sum from the field table's `new_records_needed` columns; WY alone contributes 18, HI ~14, NH-1's open seat ~14, AK ~14 — exact count should be tallied by the planner from the full `160-field-table-p165.csv` + per-state staging CSVs before authoring). This is comparable in scale to Phase 163's 101 and Phase 164's ~100+, consistent with the milestone's per-phase granularity.

## Common Pitfalls

### Pitfall 1: Re-authoring NV or ME's elections/races
**What goes wrong:** Treating NV/ME identically to the other 15 states and running the vanilla `162-mn-generate.mts` create-election-first template, which would either fail on the elections `NOT EXISTS` guard (harmless but wasted) or, worse, create duplicate races if the generator's race-insert logic doesn't scope tightly enough.
**Why it happens:** 15 of the phase's 17 states DO need create-races-first, making it the "default" mental model; NV/ME are the exception.
**How to avoid:** Check `160-field-table-p165.csv`'s `existing_race_id` column FIRST for every state before choosing a generator template. Any non-empty value means clone `164-or-generate.mts` (candidates-only), not `162-mn-generate.mts`.
**Warning signs:** A migration that INSERTs into `essentials.elections` with a name matching `'NV 2026 Statewide General'` or `'2026 Maine General Election'` when those names already exist live.

### Pitfall 2: Touching `essentials.offices` for UT
**What goes wrong:** "Fixing" the reps-feed mismatch by updating UT's `offices.politician_id` to reflect the new map, since it looks like stale/wrong data.
**Why it happens:** The office rows genuinely DO show old-map incumbents (Moore on 4901 instead of 4902, etc.) — this looks like a bug to an agent unfamiliar with the dual-map design.
**How to avoid:** Trust `164.1-ut-wiring-contract.md`'s explicit rule: offices stay old-keyed until Jan-2027; only `race_candidates` (candidacy) reflects the new map. Never write `essentials.offices`, `essentials.geo_districts`, or `connect.user_districts` in this phase.
**Warning signs:** Any migration in this phase containing `UPDATE essentials.offices` or `UPDATE essentials.districts`.

### Pitfall 3: Recreating UT's already-existing primary-winner politician records
**What goes wrong:** Creating a NEW politician record for Ben McAdams, Peter Crosby, Kent Udell, or Jonny Larsen because their existing records were seeded via the primary (`sos_filing` source) and don't obviously look "reusable" from a Nov-3-election lens.
**Why it happens:** These candidates' existing rows are scoped to the OLD `'2026 Utah Primary'` election/races, not any general election — an agent generating fresh SQL might not think to look there first.
**How to avoid:** Before generating the UT migration, query `essentials.politicians` by full_name for every UT Nov-3 candidate; reuse any hit's `id` via a `race_candidates` INSERT rather than a fresh `politicians` INSERT. This is the same "fresh live check before generating SQL" discipline used for every other collision check in this milestone.
**Warning signs:** Duplicate `full_name` rows for any of Moore/Maloy/Kennedy/McAdams/Crosby/Udell/Larsen in `essentials.politicians`.

### Pitfall 4: Treating AK's/ME's `rcv=true` field-table flag as a DB schema requirement
**What goes wrong:** Searching for or attempting to add an `essentials.races.ballot_system` or `.rcv` column because the research CSV has those columns.
**Why it happens:** The CSV's columns look like they map 1:1 to a DB schema, but they don't — they're Phase-160 research-provenance metadata only.
**How to avoid:** Confirmed via full-codebase grep (2026-07-07): no `ballot_system`/`rcv`/`ranked_choice` column exists in any migration or schema file. RCV is handled entirely as a research-thoroughness discipline (capture every declared candidate); the DB stores a flat `race_candidates` list identical in shape to every other race.
**Warning signs:** A migration attempting `ALTER TABLE essentials.races ADD COLUMN ...`.

### Pitfall 5: Seeding MT/ND/NE/NH's pending-independent candidates as confirmed
**What goes wrong:** Adding Persico/Eisenhauer (MT), Neville/Tuttle (ND), Ahlman/Budke/Cohen (NE), or Black/Mahrou/Sykes (NH) to the general field because they're "already declared/campaigning" per news coverage.
**Why it happens:** These candidates have real news coverage and FEC paperwork, making them feel confirmed, but none had cleared their state's official certification/signature threshold as of the Phase 160 resolution date.
**How to avoid:** Follow the field table's explicit EXCLUDE notes for each (`NOTE-MT-PETITION-STATUS`, `NOTE-ND-PETITION-WINDOW`, `NOTE-NE-PETITION-WINDOW`, `NOTE-NH-2-PENDING-INDEPENDENTS`) — these candidates are Phase-167 concerns, re-checked after their respective certification deadlines pass (Aug-20 MT, Aug-31 ND, Aug-1 NE, Sep-2 NH).
**Warning signs:** A `race_candidates` row for any of these 8 named individuals appearing before their state's certification deadline has passed.

### Pitfall 6: Assuming DE's external_id band is clean because DE wasn't previously flagged in any Wave-3 phase
**What goes wrong:** Skipping the D-04 collision re-check for DE because it's a "fresh" state not touched by 161-164, assuming a clean band.
**Why it happens:** DE genuinely has zero Wave-3-specific redistricting/primary complications — it's easy to mentally file as "simple," which can lead to skipping the mandatory fresh collision check.
**How to avoid:** DE's collision is a LEGACY artifact from Wave 1 (CA House members + AL execs occupying the numeric range by coincidence of an old sequential-ID scheme, not anything DE-specific) — it would be invisible without running the actual query. Always run the fresh live collision check per district, regardless of how "clean" a state looks on paper.
**Warning signs:** A new DE politician record landing at external_id `-100001` through `-100047` (would silently collide with Kay Ivey, Adam Schiff, etc.'s existing rows — the `NOT EXISTS` idempotency guard would make the INSERT a silent no-op, masking the true new-record count).

## Stance Pipeline

Federal-24 topic set confirmed identical (`_TOPIC_SCALE_FULL.txt` exists per-state-cluster directory pattern; create `backend/data/stance-research/{nv,me,ut,ak,nm,ne,wv,id,hi,nh,ri,mt,de,nd,sd,vt,wy}-2026-house/` directories cloning the convention). 3-concurrency max on `politician-stance-researcher`, 1 agent per district (or per small-state pair for the tiniest at-large states), wave-based dispatch with first-wave output validation (161/162/163/164 pattern). 0-unsourced gate floor; chairs-not-polarity; honest-skip (per-topic or whole-record) with a written search trail; mandatory primary-source verification pass before every push; wipe `essentials.quotes` per pid before re-push on any quote correction. Push each state's batch to PROD as it completes (stance CSVs are gitignored → PROD is the durable store, the 161 resilience lesson).

**Incumbent stance scope:** Every incumbent in this phase's field table shows `incumbent_top_up_tier` of either `partial` or `zero` — ME's Pingree and Golden are BOTH `zero`-tier (0 existing stances). Per the standing "already-stanced incumbents skipped, zero-tier gets full research" principle (154 D-02, reused every phase since 162), **Pingree and Golden need full federal-24 stance research from scratch**, unlike this phase's other ~15 incumbents (all `partial`, no top-up). This is the ONLY zero-tier-incumbent stance work in Phase 165 — flag it explicitly in the plan so it isn't missed the way MD's 8 zero-tier incumbents nearly were skipped in Phase 162's early planning.

**Over-indulgence reminder (user standing preference):** AK and ME are RCV jurisdictions — per the project's standing preference, "over-indulge thoroughness for RCV races... search harder before any skip." Apply this not just to field-resolution (already done in 160) but to stance research depth for every AK/ME candidate in this phase.

## RCV/Jungle-Primary Reference (carried forward from Phase 163)

`essentials.races.primary_party` is nullable with a dedicated unique index `idx_races_election_position_no_party ON (election_id, position_name) WHERE primary_party IS NULL` — confirmed live in Phase 163's research (not re-verified this session, but no schema migrations affecting this table have landed since 163 per the migration list reviewed 2026-07-07). This is the mechanism to use for AK's nonpartisan-blanket race (Track 3) if the planner adopts this research's recommendation.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | AK's single race should be modeled `primary_party=NULL` (jungle-style), mirroring LA's Phase-163 convention | Track 3 | If wrong, AK candidates might need per-party grouping that doesn't fit the current single-race shape; low risk since `/elections` renders a flat candidate list either way — this is a modeling choice, not a data-loss risk |
| A2 | UT's new challengers should use the standard `-(49*10000+cd*100+seq)` formula despite existing UT records having no external_id at all | Track 2 | Low risk — external_id is a convenience key for idempotent re-runs, not a foreign key; if the convention is wrong, only the collision-check mechanics need adjusting, not the underlying candidate data |
| A3 | Ronald Russell (ME-1) and Matthew Dunlap (ME-2) need brand-new politician records rather than reusing a dormant primary-scoped pid | Track 1 | Medium — if either already has a politician record from the primary stage with `politician_id` populated on some other row, creating a duplicate would violate the 0-duplicate-full_name invariant; MUST re-verify live at plan/seed time before generating SQL (flagged explicitly in Pitfall 3 discipline, applied here too) |
| A4 | Migration number 1250 is free | Migration Numbering | Low risk — explicitly flagged to re-verify at plan-authoring time since another session (177/178, or the date-gated 164.1-07 MO wave) may land work first |
| A5 | AK's exact 2026 primary date (used for the PROVISIONAL cull-date description) is mid-August, consistent with recent AK cycles | Track 3 | Low-medium — a wrong cull date only affects the description string and Phase 167's scheduling assumption, not correctness of the seeded field itself; must re-verify against `elections.alaska.gov` before finalizing the description |

**If this table is empty:** N/A — see entries above; all are LOW-MEDIUM risk and none block planning, but A3 and A5 should be re-verified with a fresh live query/web check at plan-authoring time before SQL generation.

## Open Questions (RESOLVED)

*All 3 questions are operationally resolved via live-verification tasks embedded in the plans (plan-checker confirmed 2026-07-07): OQ1 → 165-01 Task 1 live pid lookup; OQ2 → 165-03 Task 1 live date check; OQ3 → handled as Claude's Discretion in 165-03 (`primary_party=NULL`, Phase-163 jungle precedent).*

1. **(RESOLVED in 165-01 Task 1)** **Do Ronald Russell (ME-1) and Matthew Dunlap (ME-2) already have dormant politician records from the primary stage?**
   - What we know: Both appeared as named candidates in ME's `'2026 Maine State Primary'` races (per `160-race-preexistence-audit.csv`), but their primary-stage rows show `candidate_pid` blank/NULL in that audit snapshot — unlike UT's primary candidates, who mostly DO have real pids.
   - What's unclear: Whether a pid was created for either of them at some later point between the audit snapshot (pre-2026-06-13) and now.
   - Recommendation: Run a live `SELECT * FROM essentials.politicians WHERE full_name ILIKE '%russell%' OR full_name ILIKE '%dunlap%'` scoped sensibly before generating the ME migration — reuse any hit, create fresh only if none found.

2. **(RESOLVED in 165-03 Task 1)** **AK's exact 2026 congressional primary date**
   - What we know: AK's primary is referenced generically as "26prim" in the source URL; the field table doesn't carry an explicit date the way CT/KS do.
   - What's unclear: The exact calendar date, needed for the PROVISIONAL description's cull-date reference.
   - Recommendation: Check `elections.alaska.gov` directly at plan/seed time (AK primaries have historically landed in mid-August).

3. **(RESOLVED — Claude's Discretion in 165-03: `primary_party=NULL`)** **Should the AK race truly be `primary_party=NULL`, or does the milestone want each candidate's declared party preserved as `races.primary_party` for research/audit purposes even if not surfaced?**
   - What we know: The schema supports `primary_party=NULL` cleanly (Phase 163 precedent); `race_candidates` never carries a party column regardless.
   - What's unclear: Whether `discuss-phase` (if run before planning) will confirm this framing or propose an alternative representation.
   - Recommendation: Flag as Claude's Discretion in the plan unless CONTEXT.md locks it; the choice has zero user-facing surfacing impact either way since candidate cards never show party.

## Environment Availability

Skipped — this phase has no external tool/service dependencies beyond what 161-164 already proved available (`psql`, `psycopg2`, `node --import tsx`, Supabase prod access). No new environment probes needed.

## Validation Architecture

Per project convention (`.planning/config.json`'s `workflow` block has no `nyquist_validation` key — treated as enabled), this section documents how Phase 165's claims get verified. Consistent with every prior Wave-3 seeding phase (161-164), the phase's own read-only SQL gate + coordinate-smoke script IS the validation architecture for this pure-data domain — there is no traditional unit/integration test framework applicable to one-off migration-generator scripts, so the "test framework" below is the gate script pair.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Read-only `psql -v ON_ERROR_STOP=1 -f {N}-verify.sql` assertion script + `node --import tsx {N}-coordinate-smoke.ts` (both cloned from `164-verify.sql`/`164-coordinate-smoke.ts`) |
| Config file | None — each phase authors its own verify.sql/coordinate-smoke.ts pair; no shared config |
| Quick run command | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/165-verify.sql` |
| Full suite command | Above + `node --import tsx scripts/165-coordinate-smoke.ts` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| USHC3-02 | 0 duplicate `full_name` per state; collision-free external_ids; incumbents reused | SQL assertion | `psql -f scripts/165-verify.sql` (CRITERION 1-2 blocks) | ❌ Wave 0 (author `165-verify.sql`) |
| USHC3-03 | 34 races, 0 NULL `office_id`; NV/ME reuse verified (no new elections); UT re-key verified (offices untouched) | SQL assertion | `psql -f scripts/165-verify.sql` (NV-RECONCILE, ME-RECONCILE, UT-REKEY, race-count blocks) | ❌ Wave 0 |
| USHC3-03 (surfacing) | A contested in-district coordinate per state surfaces the challenger-inclusive field | Coordinate smoke | `node --import tsx scripts/165-coordinate-smoke.ts` (17 positive samples, MIN_DISTRICTS=17) | ❌ Wave 0 (author `165-coordinate-smoke.ts`) |
| USHC3-04 | Every new candidate has a headshot row or pinned honest-skip | SQL assertion | `psql -f scripts/165-verify.sql` (`_img_skip` pin table block) | ❌ Wave 0 |
| USHC3-05 | 0 unsourced stance rows; whole-record skips pinned | SQL assertion | `psql -f scripts/165-verify.sql` (`_stance_skip` pin table block, 0-unsourced criterion) | ❌ Wave 0 |

### New Assertion Blocks This Gate Needs (beyond the standard 164-verify.sql template)

- **NV-RECONCILE block:** assert NV's 4 races are exactly the 4 `existing_race_id` UUIDs from the field table, no new NV election/race authored, Lynn Chapman's `race_candidates.politician_id` is NOT NULL (the fix landed), and exactly 5 new NV politicians exist in the NV band.
- **ME-RECONCILE block:** assert ME's 2 races (`d92aa73a...`, `aa63d55d...`) each have exactly 2 candidates (the pre-existing incumbent/challenger + the newly-added one), no new ME election authored.
- **UT-REKEY block:** assert `essentials.offices` rows for geo_ids 4901-4904 are UNCHANGED (a NOTOUCH-style row-count/hash guard, borrowing the 164.1 D-10 convention) — this is the single most important assertion in the entire phase gate, since a silent office write here would corrupt the dual-map design; assert Moore/Maloy/Kennedy's existing pids are `is_incumbent=true` on their NEW geo_id's race (4902/4903/4904 respectively), and Owens has 0 active `race_candidates` rows anywhere.
- **AK-FIELD block:** assert AK's single race has exactly 15 active `race_candidates` rows (14 new + Begich).
- **PROVISIONAL block:** assert AK + HI + NH + RI + DE + VT + WY (the 10 late-primary districts/states) carry `'PROVISIONAL:'` in their race description; the 7 decided states (NV, UT, NM, NE, WV, ID, MT, ND, SD — note ME is a reuse state with pre-existing description wording, handle separately) do not.
- **COLLISION-BAND block:** assert every new external_id in NM-1/2/3, NE-3, NH-1, MT-2, AK, DE, VT honored its `safe_start_seq` floor per the table in Track 4.

### Sampling Rate
- **Per task/plan commit:** the relevant state-scoped slice of `165-verify.sql` (or a lighter ad-hoc psql count query during generator-script iteration).
- **Per wave merge:** full `165-verify.sql` + `165-coordinate-smoke.ts`.
- **Phase gate:** Full suite green before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `backend/scripts/165-verify.sql` — does not exist yet; clone `164-verify.sql` and add the 6 new blocks above.
- [ ] `backend/scripts/165-coordinate-smoke.ts` — does not exist yet; clone `164-coordinate-smoke.ts`, extend `STATE_CONFIG`/`SAMPLES` to all 17 states (MIN_DISTRICTS=17), with UT pointing at the new `'UT 2026 Statewide General'` election and NV/ME pointing at their pre-existing election names.
- [ ] Per-state `.mts` generator scripts (Track-specific — see Recommended Plan Structure) — none exist yet for any of the 17 states.

## Security Domain

Skipped — pure-data seeding phase, no auth/session/access-control/input-validation/cryptography surface changes (identical posture to 161-164, which also omitted this section). The one concrete data-integrity control that matters — SQL-injection safety on free-text candidate names — is handled the same way as every prior phase: `sqlStr()` escaping on every free-text field before interpolation into generated migration SQL (see `162-mn-generate.mts`'s `sqlStr()` helper, cloned verbatim in every subsequent generator).

## Project Constraints (from CLAUDE.md / empowered-vote-primer.md)

**No `CLAUDE.md` file exists at the repository root** (`C:\EV-Accounts\CLAUDE.md` — confirmed absent this session; a `CLAUDE.md` exists only inside the unrelated `ui-ux-pro-max-skill/` subdirectory, out of scope for this phase). Constraints are instead fully inherited from 161-164's research and `.planning/STATE.md`'s "v2.22 Execution Methodology" (already summarized throughout this document): `pool.query()` for all essentials/inform reads+writes (never PostgREST); atomic multi-table writes via SECURITY DEFINER RPCs (N/A this phase — pure migration SQL, no RPC needed); PostGIS calls (in the coordinate-smoke script) use `public.ST_*` never `extensions.ST_*`; Render-only infra, no code changes this phase; migrations idempotent with `NOT EXISTS` guards; execute seeding plans INLINE, never via executor sub-agents (reserve agents for parallel stance research only, capped at 3 concurrent).

**Note on referenced skills:** Prior-phase plans (e.g. `164-01-PLAN.md`) reference `.claude/skills/find-headshots/SKILL.md` for the headshot wrong-person guard, but no `find-headshots` skill directory currently exists under `.claude/skills/` (only `compass-topic-builder/`, `research-stances/`, `ui-ux-pro-max/` are present, confirmed this session). The actual headshot pipeline is a plain Python script pattern (`backend/scripts/seed-*-house-headshots.py`, cloned per state with a `BANDS` dict) — not a Claude Skill invocation. The planner should reference the Python script pattern directly rather than a nonexistent skill path.

## Sources

### Primary (HIGH confidence — live prod queries, this session, 2026-07-07)
- `essentials.elections`/`essentials.races`/`essentials.offices`/`essentials.districts`/`essentials.politicians` — confirmed 0 pre-existing 2026-11-03 House races/elections for the 13 routine states + AK; confirmed NV's 4 pre-existing races + Lynn Chapman's still-NULL `politician_id`; confirmed ME's 2 pre-existing races each have exactly 1 candidate; confirmed UT's 4 offices exist and are still old-map-keyed with no `'UT 2026 Statewide General'` election yet
- External_id collision bands for all 17 states — live-queried, zero drift from `160-negative-id-audit.csv`'s predictions for every district that maps to a real congressional seat (2 apparent "extra" collisions in NM/MT bands are noise from non-existent `cd` slots)
- Full-codebase grep for `ballot_system`/`rcv`/`ranked_choice` — confirmed no such DB column exists anywhere; RCV is CSV-research-metadata only
- Migration directory listing — confirmed highest existing file is `1249_unwithhold_la_2026_house_races.sql`, next free = 1250
- `.claude/skills/` directory listing — confirmed `find-headshots` skill referenced by prior plans does not exist as a directory; only `compass-topic-builder/`, `research-stances/`, `ui-ux-pro-max/` present
- Root `CLAUDE.md` — confirmed absent

### Primary (HIGH confidence — prior-phase artifacts, directly reused)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p165.csv` — the 34-row field table (this phase's ground-truth candidate/nominee/ballot-system/filing-deadline data)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-06-SUMMARY.md` — the field-resolution research narrative (RCV over-indulgence execution, NV/ME/UT reconciliation discovery, UT redistricting discovery)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv` — collision counts + `safe_start_seq` per district
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-race-preexistence-audit.csv` — NV/ME/UT/MD/MA existing-race discovery (the source of the Track-1 finding)
- `.planning/phases/164.1-cross-state-district-polygon-refresh-dual-map-design-tn-mo-a/164.1-ut-wiring-contract.md` — the BINDING UT re-key contract
- `.planning/phases/164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r/164-01-PLAN.md`, `164-06-PLAN.md`, `164-13-PLAN.md`, `164-CONTEXT.md` — the plan/artifact/gate templates to clone
- `backend/scripts/162-mn-generate.mts` — the vanilla create-races-first generator template (Track 4)
- `backend/scripts/164-or-generate.mts` — the existing-race-reuse generator template (Track 1)
- `.planning/phases/163-wi-co-al-sc-la-candidate-seeding-create-elections-races-then/163-RESEARCH.md` — the jungle-primary (`primary_party=NULL`) schema pattern citation (Track 3 basis)

### Secondary (MEDIUM confidence — carried forward, not re-verified this session)
- `essentials.races.primary_party` nullable + dedicated unique index for `WHERE primary_party IS NULL` — verified live in Phase 163 (2026-07-05), not re-run this session but no relevant schema migrations have landed since (migration list reviewed).

### Tertiary (LOW confidence — flagged for the phase's own execution to firm up)
- Exact AK 2026 primary date — not found at source-URL granularity this session (see Open Question 2).
- Whether Ronald Russell/Matthew Dunlap already have dormant politician pids from ME's primary stage (see Open Question 1).

## Assumptions Log (see also inline table above)

Already presented above under "Assumptions Log" — not duplicated here.

## Metadata

**Confidence breakdown:**
- Standard stack / pipeline mechanics: HIGH — proven four times (161-164), zero new tooling
- NV/ME reconciliation track: HIGH — pre-existing races directly confirmed live this session, exact missing-candidate list matches the Phase-160 field table, generator template already exists and is proven (164-03)
- UT re-key track: HIGH on the mechanics (binding written contract + live-verified office state), MEDIUM on the exact per-district new-record roster (a few primary-loser vs. general-nominee distinctions should get one more live name-check pass at seed time, per Open Question 1's sibling caveat)
- AK RCV track: HIGH on field completeness (already exhaustively researched in 160 with cross-source verification), MEDIUM on the exact primary date and the `primary_party=NULL` modeling recommendation (a reasonable extension of the proven LA pattern, but not yet contract-bound like UT)
- 13 routine states: HIGH — zero redistricting, zero pre-existing races (all live-confirmed), field table already exhaustively researched per-district with named sources

**Research date:** 2026-07-07
**Valid until:** 7 days for anything touching live litigation/certification status (none flagged for this phase — no redistricting states are in Phase 165's group) or pending-certification independent candidates (MT Aug-20, ND Aug-31, NE Aug-1, NH Sep-2 — re-verify status if plan execution slips close to or past these dates); 30 days for everything else (pipeline mechanics, schema facts, NV/ME/UT/AK special-case structural findings).
