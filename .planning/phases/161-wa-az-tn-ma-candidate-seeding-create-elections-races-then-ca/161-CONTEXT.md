# Phase 161: WA + AZ + TN + MA Candidate Seeding (create elections + races, then candidates) - Context

**Gathered:** 2026-07-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Seed the full 2026 US House ballot field for the four largest remaining delegations — **WA (10) + AZ (9) + TN (9) + MA (9) = 37 districts, 100% late-primary** (the entire phase is provisional-field work; every district seeds its full qualified field marked `PROVISIONAL:`, culled later by Phase 167). The anchor seeding phase for USHC3-02/03/04/05.

Work: author `essentials.elections` + `essentials.races` for WA/AZ/TN (MA **reuses** its 9 pre-existing scaffolded races via `existing_race_id`), create new candidate records (**~183 ceiling**: TN 73 / WA 60 / AZ 32 / MA 18 — the heaviest stance workload of any seeding phase to date), wire `race_candidates`, headshots per new candidate, and federal-24 sourced stances (0-unsourced). Every district surfaces its field on `/elections` for an in-district coordinate — **except TN districts the correspondence audit scores severe, which are seeded but not surfaced** (see D-01).

Pure data — no backend code (v2.22 milestone constraint). Consumes the Phase-160 field table's `seeding_phase=161` slice as the authoritative input.

**Out of scope:** the other 141 Wave-3 districts (Phases 162–165), the post-primary cull (Phase 167, date-gated), the TN/MO/AL/LA/UT polygon refresh / dual-map design (own phase — see Deferred), challenger `finance_summary`, Senate races.

</domain>

<decisions>
## Implementation Decisions

### TN redistricted map handling (operator-confirmed after pushback discussion)
- **D-01:** TN races wire to the **existing CD-numbered district rows** (old 2024-TIGER polygons). Rationale locked in discussion: the seeded candidate/race/stance data is keyed to the NEW map (official May-29 qualified list) and stays correct — only the address→race polygon join is stale, and it self-corrects when polygons refresh (zero rework). Importing new polygons now would instead falsify the reps feed (sitting incumbents represent the OLD districts until Jan 2027; both feeds share one polygon).
- **D-01a (audit FIRST):** the phase **opens** with a TN old-vs-new district correspondence audit — one research task comparing old/new maps per district, scoring boundary-shift severity, shipped as a phase artifact. This runs before any TN wiring.
- **D-01b (gate severe):** TN districts the audit scores **severe** (expected: the Memphis area — old TN-9 was dismantled; Cohen `redistricted`) are **seeded but NOT surfaced** (races + candidates + stances land, but the race is withheld from `/elections` — planner picks the mechanism, e.g., race left unattached/inactive until polygon refresh) rather than serving actively-wrong lookups.
- **D-01c (dual-map committed, not backlogged):** the cross-state polygon-refresh / dual-map design (TN + MO + AL + LA + UT) is committed as **its own phase that MUST land before Phase 165** (UT's court-ordered full re-key forces the design anyway) and well before Nov-3. It likely needs backend query changes, so it sits outside this pure-data milestone's seeding phases.

### State ordering & AZ urgency
- **D-02:** **AZ runs first, end-to-end** (races → records → headshots → stances → push), with a **hard target of full AZ coverage live before its Jul-21 primary** (18 days out at context time — the earliest civic moment in the milestone; 32 new records is achievable). Then **WA → TN → MA**: WA (Aug-4 top-two) and TN (Aug-6) next, MA last (Sep-1 primary, latest moment, smallest load, races already scaffolded). The TN correspondence audit (D-01a) runs up-front in parallel, not blocked behind AZ/WA.

### Pipeline structure (~183 records)
- **D-03:** **Per-state vertical slices** — one seed plan + one stance plan per state (AZ, WA, TN, MA), pushing stances **per state as each completes** (never one mega-push). Plus the TN audit plan up front and a closing 37-district phase mini-gate. Matches the proven 159 MI/VA pattern; a mid-phase interruption strands no unpushed work.
- **D-03a:** within each state, stance research runs **incumbents + evidenced majors first, fringe filers last** — costless ordering that minimizes discarded work if a primary date arrives mid-phase.

### Fringe-candidate search depth
- **D-04:** **Standard uniform search effort for all ~183 candidates.** No reduced fast-path for fringe (false-skip risk — the 159 lesson: 21/25 header-only CSVs without search trails were FALSE skips) and no elevated tier for WA's top-two (the RCV over-indulgence principle is specifically about ranked-choice communities — AK/ME in Phase 165). The honest-skip mechanism absorbs the thin tail: genuinely thin candidates yield fewer sourced topics plus pinned skips, each with a **written search trail**.

### Carried forward (locked — do not re-litigate)
- Full provisional field seeded NOW marked `PROVISIONAL:`; only the cull (Phase 167) is date-gated.
- Full federal-24 sourced stances per candidate; 0-unsourced gate floor; chairs-not-polarity; never party-inferred; honest-skip (per-topic or whole-record) only with a written search trail, whole-record skips gate-pinned; mandatory primary-source verification pass before every push.
- `race_candidates`: non-null `politician_id`, `candidate_status='active'`, incumbents `is_incumbent=true`; NEVER party on the candidate card (`races.primary_party` only); NEVER `office_id IS NULL` on a House race.
- external_id `-(state_fips*10000 + cd*100 + seq)`; FIPS: WA=53, AZ=04, TN=47, MA=25; collision bands pre-audited in `160-negative-id-audit.csv` — re-verify 0 collisions per state before authoring.
- Incumbents reuse existing records (identity by `(district_type='NATIONAL_LOWER', geo_id)` join, never computed external_id); zero duplicate `full_name` per state.
- MA: reuse the 9 `existing_race_id` races; Clark (MA-5) + Pressley (MA-7) `race_candidates` rows already exist — do not duplicate. MA independent filing stays open to **Aug-25** (`filing_open_deadline` on all 9 rows): seed declared-so-far now (only news-evidenced independents, e.g., Milleron MA-1); Phase 167 catches late filers.
- Stance agents at **3-concurrency max**, first-wave output validation, exact 1–5 scale texts embedded per topic (`_TOPIC_SCALE_FULL.txt`); headshots via find-headshots conventions — trust the auto-guard's first-name-mismatch rejection (Bouchard lesson).
- Migrations idempotent (NOT EXISTS guards); pure-data changes need no deploy.

### Claude's Discretion
- Exact plan count/splitting (e.g., whether TN's 73-record stance slice splits into two plans for checkpoint safety), gate assertion set (clone prior seeding-phase verify SQL style), the severe-district withholding mechanism (D-01b), per-state elections/races migration authoring details, and the TN audit's severity rubric — researcher/planner decide within the conventions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase-160 outputs (the authoritative input — this phase's slice)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p161.csv` — the 37-row field table (19 columns): full qualified field per district, `new_records_needed`, incumbent pid/external_id/stance-count, `existing_race_id` (MA), `ballot_system`, `filing_open_deadline`.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-FIELD-TABLE.md` — human view: TN redistricting flag, MA Aug-25 filing window, per-state new-record counts, pre-existing-race reuse table (§8), Phase-167 cluster table (§9 — AZ Jul-21 / WA Aug-4 / TN Aug-6 / MA Sep-1).
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv` — incumbent → `politician_id` map + top-up tiers, all 37 districts.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-race-preexistence-audit.csv` — MA's 9 `existing_race_id` values + the 2 pre-wired candidates.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv` — per-state safe external_id sub-bands.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-02-SUMMARY.md` — WA/AZ/TN/MA field-resolution provenance: TN redistricting details (HB 7003/SB 7001, May-7-2026), AZ SoS Cloudflare wall (use raw wikitext + FEC API), MA declared-so-far pattern, source URLs per state.

### Milestone scope & methodology (locked)
- `.planning/ROADMAP.md` §Phase 161 — goal + 4 success criteria; anchor-phase note.
- `.planning/REQUIREMENTS.md` — USHC3-02/03/04/05.
- `.planning/STATE.md` §"v2.22 Execution Methodology" — prod ref `kxsdzaojfaibhuzmclfq`, Path-B surfacing, race_candidates shape, FIPS table, stance pipeline, fetch-wall intel.

### Pipeline templates (prior seeding phases to mirror)
- `.planning/phases/159-mi-candidate-seeding-verification-date-gated-primary-aug-4-2/` — 159-01/159-03 seed SUMMARYs (create-races + provisional-field pattern this phase copies) + 159-02/159-04 stance SUMMARYs (skip-pin format, search-trail standard).
- `.planning/phases/155-*/`, `156-*/`, `157-*/` SUMMARYs — Wave-2 seed → headshot → stance → gate pipeline; reusable scripts `_merge.ts`, `_push_uuid.ts` (new NULL-external_id), `_push.ts` (existing).
- `backend/data/stance-research/*/_TOPIC_SCALE_FULL.txt` — federal-24 topic set + exact 1–5 scale texts (embed per agent prompt).

### Skills
- `.claude/skills/` research-stances + find-headshots — pipeline rules, wrong-person guard.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_merge.ts` / `_push_uuid.ts` / `_push.ts` (backend/data/stance-research pipeline) — per-candidate CSV → validate → merge → push; `_push_uuid.ts` for new candidates (NULL external_id path).
- Prior seeding migrations (159-01 MI mig 1146/1147, 157 NJ, 156 OH/GA/NC) — elections+races+politicians+race_candidates authoring shape to clone per state.
- Prior phase verify SQL (156 gate, 158 coordinate gate) — mini-gate template for the 37-district close.
- `backend/src/lib/db.js` `pool` — canonical query path when MCP Supabase tokens expire; scripts live inside `backend/`; cwd resets between Bash calls → `cd /c/EV-Accounts/backend &&` in the same compound command.

### Established Patterns
- Path-B surfacing: `/elections` reads `races` + `race_candidates`; geography via `office_id → districts.geo_id` + `ST_Covers` — pure data, no code.
- Provisional-field convention: `PROVISIONAL:` marker (FL Phase-151 / MI+VA Phase-159 precedent).
- Diagnostic-before-write: re-run collision + duplicate checks per state at plan time even though 160 pre-audited.

### Integration Points
- Phase 166 gate asserts across all 178 districts — this phase's 37 must satisfy the same assertions.
- Phase 167's AZ cluster (Jul-21) prunes AZ primary losers first — AZ seeding landing before Jul-21 (D-02) maximizes pre-primary value and gives 167 a clean field to cull.
- The deferred dual-map/polygon-refresh phase (D-01c) must exist before Phase 165 (UT re-key) — planner should surface this as a roadmap insertion when planning 161, not wait for 165.
- A parallel session works Phases 177/178 (Hillsboro/Tigard OR) in this repo — no collisions expected (no Oregon data touched here).

</code_context>

<specifics>
## Specific Ideas

- **Operator pushback that shaped D-01 (verbatim):** "wait. if we defer it, aren't you just getting bad data? Shouldn't this come first?" — resolution: the *audit* comes first, severe districts are never surfaced wrong, and the polygon/dual-map fix is a committed scheduled phase (before 165), not a vague backlog item. The seeded data itself is new-map-correct and needs zero rework on refresh.
- TN specifics: new map enacted May 7, 2026 (HB 7003/SB 7001); qualifying extended to May 15; official May-29 qualified-candidate list is the field source; TN-9 Cohen `nominee_status=redistricted` (withdrew citing the new map).
- Open seats in this phase's slice: AZ-1 Schweikert (gov run), AZ-5 Biggs (gov run), WA-4 Newhouse (retired), TN-6 Rose (gov run), TN-9 Cohen (redistricted), MA-6 Moulton (Senate run vs Markey).
- AZ minor-party candidates with conflicting party labels recorded generically as (IND) in the field table — don't overclaim a ballot line.
- WA rows: `ballot_system=top-two`; withdrawn candidates already excluded per official VoteWA status.

</specifics>

<deferred>
## Deferred Ideas

- **Cross-state district polygon refresh / dual-map design (TN, MO, AL, LA, UT)** — own phase, committed to land **before Phase 165** and well before Nov-3 (D-01c). Needs a design that keeps the reps feed on current-representation boundaries (until Jan 2027) while elections resolve on 2026 boundaries — likely a backend query change, outside the pure-data milestone constraint. Also un-gates any TN districts withheld under D-01b.
- **Partial-incumbent stance top-up** — reported by the 160 diagnostic, out of v2.22 scope (154 D-02 carried forward).
- **Challenger `finance_summary`** — out of scope per REQUIREMENTS.md; record no-FEC-ID rather than retry.
- **MA late-filing independents** (window open to Aug-25) — Phase 167's MA cluster (Sep-1 primary week) reconciles.
- **v2.21 tail** — 159-05/06 MI+VA cull+gate (≥ Aug-5), PA independents (≥ Aug-10), FL Phase 153 (≥ Aug-18) — calendar-gated, separate.

</deferred>

---

*Phase: 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca*
*Context gathered: 2026-07-03*
