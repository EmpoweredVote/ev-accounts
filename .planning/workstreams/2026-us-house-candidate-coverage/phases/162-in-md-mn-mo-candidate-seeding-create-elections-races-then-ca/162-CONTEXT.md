# Phase 162: IN + MD + MN + MO Candidate Seeding (create elections + races, then candidates) - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

> **Note:** Gray areas were framed and my recommendation ("My read") given for each; the operator was away at decision time, so all four areas below are locked to their recommended defaults. Every default is grounded in the Phase-161 precedent (same milestone, same pipeline) and the Phase-160 field-resolution findings. Re-open any of them at plan time if the operator wants to revisit.

<domain>
## Phase Boundary

Seed the full 2026 US House ballot field for **IN (9) + MD (8) + MN (8) + MO (8) = 33 districts** — the second Wave-3 seeding phase, continuing the USHC3-02/03/04/05 per-state pipeline established in Phase 161.

**Primary-status split (Phase-160 resolved):**
- **Decided (17 districts): IN (May-5 primary done) + MD (Jun-23 primary done)** — seed the confirmed Nov-3 general-ballot field (nominees + ballot-qualified minor-party/independent).
- **Late-primary (16 districts): MN (Aug-11) + MO (Aug-4)** — seed the **full qualified pre-primary field marked `PROVISIONAL:`** (multiple intra-party filers per district), culled later by Phase 167.

Work: author `essentials.elections` + `essentials.races` for IN/MN/MO (MD **reuses** its 8 pre-existing scaffolded races via `existing_race_id`), create new candidate records, wire `race_candidates`, headshots per new candidate, and federal-24 sourced stances (0-unsourced). Every district surfaces its field on `/elections` for an in-district coordinate — **except MO districts an old-vs-new-map correspondence audit scores severe, which are seeded but not surfaced** (see D-01), mirroring TN in Phase 161.

Pure data — no backend code (v2.22 milestone constraint). Consumes the Phase-160 field table's `seeding_phase=162` slice (`160-field-table-p162.csv`) as the authoritative input.

**Out of scope:** the other 145 Wave-3 districts (Phases 161/163/164/165), the post-primary cull (Phase 167, date-gated), the cross-state polygon refresh / dual-map design (Phase 164.1 — un-gates any withheld MO/TN districts), challenger `finance_summary`, Senate races.

</domain>

<decisions>
## Implementation Decisions

### MO redistricting handling — mirror the TN D-01 pattern from Phase 161
- **D-01:** **MO is redistricted for the 2026 cycle** — Phase 160 confirmed the 2025 GOP-drawn map IS in effect (MO Supreme Court upheld 4-3 on 2026-03-24; the pending referendum does not affect 2026). This is the **same stale-polygon situation as TN in Phase 161**: the DB holds old (pre-2025) MO district polygons, but the seeded candidate/race/stance data is keyed to the NEW map (official SoS filing list) and stays correct — only the address→race polygon join is stale, and it self-corrects on the Phase-164.1 polygon refresh (zero rework). MO races wire to the **existing CD-numbered district rows** (old polygons); importing new polygons now would falsify the reps feed (sitting incumbents represent the OLD districts until Jan 2027; both feeds share one polygon).
- **D-01a (audit FIRST):** the phase **opens** with an **MO old-vs-new district correspondence audit** — one research task comparing old/new maps per district, scoring boundary-shift severity, shipped as a phase artifact (clone the TN audit rubric from Phase 161's D-01a). Runs up front, in parallel with early seeding of the non-MO states.
- **D-01b (gate severe):** MO districts the audit scores **severe** (expected candidates: **MO-5** — Cleaver's Kansas City district was the 2025 remap's primary target, redrawn more Republican by adding rural counties; plus any adjacent MO-4/MO-6 that absorbed/shed large populations) are **seeded but NOT surfaced** (races + candidates + stances land, but the race is withheld from `/elections` — planner picks the mechanism, matching the 161 D-01b choice) rather than serving actively-wrong lookups. Non-severe MO districts surface normally.
- **D-01c (un-gate in 164.1):** MO is already in the committed Phase-164.1 cross-state polygon-refresh / dual-map set (TN + MO + AL + LA + UT), which MUST land before Phase 165 and well before Nov-3. That phase un-gates any MO districts withheld here. No new roadmap insertion needed — 164.1 already exists.

### IN-9 incumbent-flag bug — fix BEFORE any IN seeding
- **D-02:** A pre-existing IN-9 **primary** race (`7d3f0042-eb15-462b-bf14-df15244c5d16`, "2026 Indiana Primary", seeded from the March SoS excel) carries **5 mis-flagged `race_candidates` rows**: Erin Houchin (the true IN-9 incumbent) is flagged `is_incumbent=false`, and her 4 primary opponents (James H. Graham `037ad94f…`, Keil L. Roark `283b1fdd…`, Tim Peck `a9233775…`, Brad A. Meyer `926943ad…`) are flagged `is_incumbent=true`. A **dedicated first plan step** corrects `is_incumbent` on these 5 existing rows (Houchin→`true`, the 4 losers→`false`), verified by a re-query, **before** any IN general `races`/`race_candidates` are authored. Houchin's `politician_id` is `68568faf-1e0f-4ca2-89d9-bda625665712` — reuse it for the general race, never INSERT a new Houchin record.
- **D-02a:** Scope of the fix is **flag correction only** on the existing primary rows — do not delete the primary race or its rows (it is valid historical primary data). This prevents the stale flags from poisoning any incumbency-derived logic and satisfies the "zero duplicate incumbent" invariant.

### State ordering & urgency
- **D-03:** **MO runs first, end-to-end** (correspondence audit → races → records → headshots → stances → push) — it has the **earliest civic moment** (Aug-4 primary; independent petition deadline Jul-27) and the largest/most-urgent provisional field, and the redistricting audit must front-load anyway. Then **MN** (Aug-11 primary, second provisional field), then the **decided IN + MD** last (small fields, lowest urgency — primaries already resolved). Push stances **per state as each completes** (never one mega-push), matching Phase-161 D-03 and the proven 159 pattern.
- **D-03a:** within each state, stance research runs **incumbents + evidenced majors first, fringe filers last** — costless ordering that minimizes discarded work if a primary date arrives mid-phase (Phase-161 D-03a carried forward).

### MD reuse + open independent/minor window
- **D-04:** MD **reuses its 8 `existing_race_id` general races** (see `160-race-preexistence-audit.csv`) — do NOT author new MD `races`; the MA Phase-161 reuse pattern applies. Confirm at plan time whether any MD `race_candidates` rows already exist (like MA-5/MA-7 did) and do not duplicate them.
- **D-04a:** MD is `field_status=decided` (Jun-23 nominees final) **but** carries `filing_open_deadline=2026-08-03` — the unaffiliated/minor-party window is still open statewide. Seed the confirmed nominees + declared-so-far minor-party candidates NOW; re-pull MD after Aug-3, with **Phase 167's reconciliation catching any late-filed independents** (mirrors the MA Aug-25 window handling in 161). MO carries the same open-window nuance (petition deadline Jul-27) — its full field is already seeded provisionally, so the re-pull is a Phase-167 concern.

### Carried forward (locked — do not re-litigate; from Phase 161 / milestone standing standards)
- Full provisional field seeded NOW marked `PROVISIONAL:` for late-primary states (MN/MO); only the cull (Phase 167) is date-gated.
- Full federal-24 sourced stances per candidate; 0-unsourced gate floor; chairs-not-polarity; never party-inferred; honest-skip (per-topic or whole-record) only with a **written search trail**, whole-record skips gate-pinned; mandatory primary-source verification pass before every push.
- The **11 zero-tier incumbents flagged by Phase 160 are IN-SCOPE for stance research** (MD all 8 + IN Baird `499386`/Carson `499408`/Messmer `499413`) — they have 0 existing stances and must be fully stanced, unlike the higher-tier incumbents who are skipped via the diagnostic.
- `race_candidates`: non-null `politician_id`, `candidate_status='active'`, incumbents `is_incumbent=true`; NEVER party on the candidate card (`races.primary_party` only); NEVER `office_id IS NULL` on a House race.
- external_id band `-(state_fips*10000 + cd*100 + seq)` for new candidates; FIPS: **IN=18, MD=24, MN=27, MO=29**. **Re-verify 0 collisions per state before authoring** — the current `160-negative-id-audit.csv` covers only the small-delegation states (KY/OR/OK/… for Phases 164/165), NOT IN/MD/MN/MO, so the collision check for this group must be run fresh at plan time. Note existing incumbent external_ids use mixed legacy schemes (IN `-18001`, MD `-2440001`, MN `-27001`, MO `-29001`, plus positive SoS-sourced ids like `499386`) — new records get the standard band; reuse (never recompute) incumbent ids.
- Incumbents reuse existing records (identity by `(district_type='NATIONAL_LOWER', geo_id)` join, never computed external_id); zero duplicate `full_name` per state. Verified departures (open seats): **MD-5 Hoyer retired** (Boafo won the primary), **MN-2 Craig** filed for US Senate, **MO-6 Graves retired**.
- Stance agents at **3-concurrency max**, first-wave output validation, exact 1–5 scale texts embedded per topic (`_TOPIC_SCALE_FULL.txt`); headshots via find-headshots conventions — trust the auto-guard's first-name-mismatch rejection (Bouchard/Hancock lesson).
- Migrations idempotent (NOT EXISTS guards); pure-data changes need no deploy. Push each stance batch to PROD as it completes (stance CSVs are gitignored → PROD is the durable store; the 161 resilience lesson).

### Claude's Discretion
- Exact plan count/splitting (e.g., whether MO's or MN's provisional stance slice splits into two plans for checkpoint safety), gate assertion set (clone prior seeding-phase verify SQL style), the severe-district withholding mechanism (D-01b, match 161's choice), the MO correspondence audit's severity rubric (clone TN's), per-state elections/races migration authoring details, and where the IN-9 flag fix (D-02) lives in the plan graph — researcher/planner decide within the conventions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase-160 outputs (the authoritative input — this phase's slice)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p162.csv` — the 33-row field table (19 columns): full qualified field per district, `new_records_needed`, incumbent pid/external_id/stance-count, `existing_race_id` (MD), `nominee_status`, `ballot_system`, `filing_open_deadline`, the IN-9 bug NOTE.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-03-SUMMARY.md` — IN/MD/MN/MO field-resolution provenance: MO redistricting determination (2025 map upheld Mar-24), MD decided-with-open-window (Aug-3), MO petition deadline Jul-27, open-seat departures (Hoyer/Craig/Graves), MO SoS ASPX fetch-wall (use Wikipedia raw wikitext), IN-9 bug carried-not-propagated.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-race-preexistence-audit.csv` — MD's 8 `existing_race_id` values + the 5 mis-flagged IN-9 primary rows (D-02 fix targets).
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv` — incumbent → `politician_id` map + top-up tiers (incl. the 11 zero-tier incumbents), all 33 districts.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-FIELD-TABLE.md` — human view: per-state new-record counts, Phase-167 cluster table, open-window notes.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p162-{IN,MD,MN,MO}.csv` — per-state agent provenance.

### Phase-161 precedent (the pattern this phase mirrors — most decisions inherit from here)
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-CONTEXT.md` — TN D-01 redistricting pattern (D-01/D-01a/D-01b/D-01c — the direct template for MO here), per-state vertical slices (D-03), uniform search depth (D-04), MA existing-race reuse (the MD template).
- `.planning/phases/161-*/` seed + stance + gate SUMMARYs (once written) — the create-races → provisional-field → headshot → stance → mini-gate pipeline to clone; the TN correspondence-audit artifact + severity rubric to clone for MO.

### Milestone scope & methodology (locked)
- `.planning/ROADMAP.md` §Phase 162 — goal + 3 success criteria; §Phase 161 anchor note (USHC3-02/03/04/05 continuation); §Phase 164.1 (MO dual-map un-gate).
- `.planning/REQUIREMENTS.md` — USHC3-02/03/04/05.
- `.planning/STATE.md` §"v2.22 Execution Methodology" — prod ref `kxsdzaojfaibhuzmclfq`, Path-B surfacing, race_candidates shape, FIPS table, stance pipeline, fetch-wall intel.

### Pipeline templates (prior seeding phases to mirror)
- `.planning/phases/159-mi-candidate-seeding-verification-date-gated-primary-aug-4-2/` — 159-01/03 seed SUMMARYs (create-races + provisional-field) + 159-02/04 stance SUMMARYs (skip-pin format, search-trail standard).
- `.planning/phases/155-*/`, `156-*/`, `157-*/` SUMMARYs — Wave-2 pipeline; reusable scripts `_merge.ts`, `_push_uuid.ts` (new NULL-external_id path), `_push.ts` (existing).
- `backend/data/stance-research/*/_TOPIC_SCALE_FULL.txt` — federal-24 topic set + exact 1–5 scale texts (embed per agent prompt).

### Skills
- `.claude/skills/` research-stances + find-headshots — pipeline rules, wrong-person guard.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_merge.ts` / `_push_uuid.ts` / `_push.ts` (backend/data/stance-research pipeline) — per-candidate CSV → validate → merge → push; `_push_uuid.ts` for new candidates (NULL external_id path).
- Prior seeding migrations (159-01 MI, 157 NJ, 156 OH/GA/NC, and Phase-161 WA/AZ/TN) — elections+races+politicians+race_candidates authoring shape to clone per state.
- Prior phase verify SQL (156 gate, 158 coordinate gate, 161 mini-gate) — mini-gate template for the 33-district close.
- `backend/src/lib/db.js` `pool` — canonical query path when MCP Supabase tokens expire; scripts live inside `backend/`; cwd resets between Bash calls → `cd /c/EV-Accounts/backend &&` in the same compound command.
- Phase-161 TN correspondence-audit artifact + severity rubric — direct template for the MO audit (D-01a).

### Established Patterns
- Path-B surfacing: `/elections` reads `races` + `race_candidates`; geography via `office_id → districts.geo_id` + `ST_Covers` — pure data, no code.
- Provisional-field convention: `PROVISIONAL:` marker (FL Phase-151 / MI+VA Phase-159 / WA+AZ+TN Phase-161 precedent) for MN + MO.
- Redistricted-state pattern (TN Phase-161): wire to existing old-polygon district rows; seed new-map-correct data; withhold severe districts; un-gate on polygon refresh (164.1) — reused for MO.
- Diagnostic-before-write: re-run collision + duplicate checks per state at plan time even though 160 pre-audited (and note the negative-id-audit does NOT yet cover IN/MD/MN/MO).

### Integration Points
- Phase 166 gate asserts across all 178 districts — this phase's 33 must satisfy the same assertions.
- Phase 167's MO cluster (Aug-4) and MN cluster (Aug-11) prune primary losers; MO seeding landing before Jul-27/Aug-4 maximizes pre-primary civic value.
- Phase 164.1 (cross-state polygon refresh / dual-map, TN+MO+AL+LA+UT) un-gates any MO districts withheld under D-01b — already committed, no roadmap insertion needed.
- A parallel session works Phases 177/178 (Hillsboro/Tigard OR) in this repo — no collisions expected (no Oregon data touched here).

</code_context>

<specifics>
## Specific Ideas

- **MO redistricting specifics:** 2025 GOP-drawn map upheld by MO Supreme Court 4-3 on 2026-03-24; in effect for 2026; pending referendum does not affect this cycle. Primary target was MO-5 (Emanuel Cleaver, Kansas City) — expected severe boundary shift; Cleaver is still `renominated` and running under the new lines.
- **IN-9 bug specifics:** stale rows originate from the March SoS-excel primary seed (`source=sos_excel`, `election_name="2026 Indiana Primary"`); the true general race for IN-9 does not exist yet (phase creates it). Fix flags on the existing primary rows only.
- **Open seats in this slice:** MD-5 Hoyer (retired; Boafo won a 23-candidate primary at 32.84%), MN-2 Craig (US Senate run), MO-6 Graves (retired; listed Withdrawn on official roster).
- **MO-1 primary note:** Cori Bush is challenging incumbent Wesley Bell in the D primary (2024 rematch) — seed both as provisional D filers.
- **Fetch-wall intel:** MO SoS ASPX candidate pages render only nav boilerplate via curl/r.jina.ai → use Wikipedia raw wikitext (which cites the SoS list); MN's ASP.NET page DID render via r.jina.ai with the right GET params (source URL in the field table).
- MD unofficial-but-unambiguous Jun-23 results were used at field-resolution time (canvass finalizing, every district a clear plurality) — re-confirm final canvass at seed time if available.

</specifics>

<deferred>
## Deferred Ideas

- **Cross-state district polygon refresh / dual-map design (TN, MO, AL, LA, UT)** — Phase 164.1 (committed, before Phase 165). Un-gates MO districts withheld under D-01b. Needs a design that keeps the reps feed on current-representation boundaries (until Jan 2027) while elections resolve on 2026 boundaries — likely a backend query change, outside the pure-data milestone constraint.
- **Partial-incumbent stance top-up** — reported by the 160 diagnostic (higher-tier incumbents with some stances), out of v2.22 scope (154 D-02 carried forward). Note: the 11 **zero-tier** incumbents ARE in-scope (see Decisions).
- **Challenger `finance_summary`** — out of scope per REQUIREMENTS.md; record no-FEC-ID rather than retry.
- **MD late-filing independents** (unaffiliated/minor window open to Aug-3) and **MO late independents** (petition deadline Jul-27) — Phase 167's MO (Aug-4) / MN (Aug-11) clusters reconcile post-primary.
- **v2.21 tail** — 159-05/06 MI+VA cull+gate (≥ Aug-5), PA independents (≥ Aug-10), FL Phase 153 (≥ Aug-18) — calendar-gated, separate.

</deferred>

---

*Phase: 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca*
*Context gathered: 2026-07-04*
