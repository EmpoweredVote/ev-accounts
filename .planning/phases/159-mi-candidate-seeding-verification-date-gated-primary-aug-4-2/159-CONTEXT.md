# Phase 159: MI + VA Primary-Field Coverage (seed now) + Post-Primary Cull - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning
**Source:** Live operator decision session (strategy reframe) — see git commit reframing ROADMAP Phase 159

<domain>
## Phase Boundary

Seed the **full pre-primary ballot-qualified candidate field (all parties)** for all 13 Michigan + all 11 Virginia US House districts onto their Nov-3 general race rows **NOW** (before the Aug-4 primaries), so MI + VA primary voters can understand their options at the moment of highest civic engagement. Then, in a **date-gated cull sub-phase (≥ 2026-08-05)**, prune the primary losers to inactive and confirm the advancing nominees. Close with a MI+VA verification gate that (combined with Phase 158's 89-district gate) proves the full 113-district milestone.

**In scope:** MI (13) + VA (11) = 24 districts — elections/races authoring (MI only; VA races already scaffolded), full qualified candidate records + `race_candidates` wiring, headshots, full federal-24 chairs-not-polarity stances, post-primary cull, verification gate.

**Out of scope:** Challenger finance (`finance_summary`) → v2.22+; the remaining ~178 US House districts → future waves; FL (already has its 181-candidate provisional field live from v2.20; FL cull is the separate Phase 153, gated ≥ Aug-18).
</domain>

<decisions>
## Implementation Decisions (LOCKED — operator session 2026-07-01)

### Strategy reframe (the core decision)
- **Reframed from "wait until Aug-4, seed decided nominees" → "seed full pre-primary qualified field NOW + cull losers ≥ Aug-5."** Rationale: the product's mission is to serve voters *at* the civic moment; a primary is the highest-engagement moment and in safe seats *is* the deciding contest. Withholding until the nominee is known leaves the tool dark for Aug-4 primary voters.
- **Applies FL's proven pattern** (Phase 151 provisional seed → Phase 153 post-primary cull) to MI + VA. FL already runs this — 181-candidate provisional field live across 28 districts. MI/VA were the un-principled dark exception; this reframe removes the inconsistency.

### Coverage depth
- **FULL coverage** (operator's explicit choice over "field-now-stances-later"): every ballot-qualified candidate gets a record + headshot + **full federal-24 sourced stances**, not a stances-light listing. Operator explicitly accepts that stance research on primary losers is discarded at the Aug-5 cull.

### Data modeling (follow FL precedent, do NOT invent new patterns)
- The qualified field attaches to the **Nov-3 general race rows** as a provisional field (`election_date='2026-11-03'`), **NOT** separate primary-election rows. Matches FL's live model exactly.
- MI needs `essentials.elections` ("MI 2026 Statewide General") + 13 `essentials.races` rows authored first (TX/NY Phase-150 create-races pattern). **VA's election + 11 race rows already exist** (DB-confirmed: VA has 1 election dated 2026-11-03, 11 races, 0 candidates) — wire candidates onto existing scaffolding, do NOT duplicate.
- `race_candidates`: non-null `politician_id`, `candidate_status='active'`, incumbent `is_incumbent=true`; NEVER party on the candidate card (party lives on `races.primary_party`).

### Records & reuse
- **All 13 MI + 11 VA incumbents already exist** with `politician_id` + partial stances (DB-confirmed; see incumbent map below) — REUSE, never create duplicates.
- **VA-11 James Walkinshaw already exists** (external_id -5102011, 7 stances) — the stale roadmap note "Walkinshaw needs a new record" is OUTDATED; he was seeded post-154. Reuse his record.
- New records only for genuinely-new challengers (non-incumbent qualified primary candidates).
- **external_id scheme for new challengers:** `-(state_fips*10000 + cd*100 + seq)`; MI fips=26, VA fips=51. Verify 0 collisions per state before authoring (VA incumbents use a legacy `-51020xx` pattern — confirm the new `-51xxxx` band is clear).

### Stances
- Federal 24-topic set (`_TOPIC_SCALE_FULL.txt`), `politician-stance-researcher` at **3-concurrency max**, chairs-not-polarity, embed 1–5 stance texts per topic in every agent prompt.
- **0-unsourced is the non-negotiable gate floor** — every answer row paired to an `inform.politician_context` row with a real fetched source URL. Honest-skip thin topics; whole-record skip allowed + gate-pinned. Mandatory primary-source verification pass before every push.
- Incumbents already partially stanced — top-up only the gaps surfaced by the 154 diagnostic; several VA incumbents are thin (Vindman 1, Subramanyam 1, McGuire 2) and are top-up candidates.

### Cull sub-phase (159-C)
- **Date-gated ≥ 2026-08-05** (day after Aug-4 MI & VA primaries). This is the ONLY date-gated part; seeding is un-gated (do now).
- Prune non-advancing candidates to inactive `candidate_status`; confirm advancing nominee(s) from official MI SoS / VA Dept. of Elections results; verify the two-path prune (mirror FL Phase 153).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & state
- `.planning/ROADMAP.md` — Phase 159 section (reframed 2026-07-01): goal, success criteria, expected plan shape (159-A MI seed / 159-B VA seed / 159-C cull / 159-D gate)
- `.planning/STATE.md` — v2.21 Execution Methodology block + Roadmap Evolution (Phase 159 reframe entry) + the 3 diagnostic queries

### The FL pattern being copied (authoritative precedent)
- `.planning/phases/151-fl-candidate-seeding-provisional-qualified-field/` — provisional-field seed pattern (SUMMARY + PLANs)
- `.planning/phases/153-*` (if present) / STATE.md USHC-07 carry-forward — the two-path post-primary cull convention

### Phase 154 diagnostic (incumbent maps + scheme)
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — per-district incumbent pid + external_id + stance count (MI/VA rows; general_candidates column is a placeholder — the real qualified field is NOT yet captured and is this phase's research task)
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv`

### Prior Wave-2 seeding phases (pipeline pattern to inherit)
- `.planning/phases/155-*` (PA+IL anchor — create-races-then-candidates), `156-*` (OH+GA+NC), `157-*` (NJ) — SUMMARY.md files show the seed → headshot → stance → gate pipeline and the reusable scripts (`_merge.ts`, `_push_uuid.ts`, `_push.ts`, `_push_relaxed.ts`)

### Verification gate precedent
- `.planning/phases/158-coordinate-verification-gate/` — the read-only coordinate-verification gate to mirror for MI+VA (159-D)

### Project rules
- `./CLAUDE.md` and `.claude/skills/` (research-stances, find-headshots) — project-specific pipeline rules
</canonical_refs>

<specifics>
## Specific Facts (DB-confirmed 2026-07-01, prod ref kxsdzaojfaibhuzmclfq)

**Current DB state (NATIONAL_LOWER):**
| State | Districts | Active candidates | Elections | Note |
|-------|-----------|-------------------|-----------|------|
| FL | 28 | 181 | 1 (2026-11-03) | already provisional-seeded — NOT this phase |
| VA | 11 | 0 | 1 (2026-11-03) | races scaffolded, zero candidates wired |
| MI | 13 | 0 | 0 | fully dark — needs election+races authored |

**Primary dates (verified via web 2026-07-01):** MI = Aug 4, 2026; VA = Aug 4, 2026 (VA moved from June to Aug this cycle — confirmed via Ballotpedia); FL = Aug 18.

**MI incumbent map (all exist, reuse):** MI-1 Bergman -26001(11) · MI-2 Moolenaar -26002(16) · MI-3 Scholten -26003(14) · MI-4 Huizenga -26004(16) · MI-5 Walberg -26005(18) · MI-6 Dingell -26006(19) · MI-7 Barrett -26007(12) · MI-8 McDonald Rivet -26008(14) · MI-9 McClain -26009(16) · MI-10 James -26010(12) · MI-11 Stevens -26011(18) · MI-12 Tlaib -26012(16) · MI-13 Thanedar -26013(17). (external_id / stance-count)

**VA incumbent map (all exist, reuse):** VA-1 Wittman -5102001(13) · VA-2 Kiggans -5102002(12) · VA-3 Scott -5102003(14) · VA-4 McClellan -5102004(12) · VA-5 Cline -5102005(15) · VA-6 Griffith -5102006(15) · VA-7 Vindman -5102007(1, THIN) · VA-8 Beyer -5102008(13) · VA-9 McGuire -5102009(2, THIN) · VA-10 Subramanyam -5102010(1, THIN) · VA-11 Walkinshaw -5102011(7).

**Research task (the gap):** pull the full ballot-qualified Aug-4 primary candidate field (all parties, every district) for MI (MI SoS) + VA (VA Dept. of Elections / Ballotpedia), with per-candidate source URLs — this is what the planner needs to size records/stances and author `race_candidates`.
</specifics>

<deferred>
## Deferred Ideas

- **PA independents** (Aug-3 filing deadline) — separate post-Aug-10 date-gated re-check (Phase 155 carry-forward), NOT this phase.
- **FL post-primary cull** — Phase 153, gated ≥ Aug-18, separate carry-forward.
- **Challenger finance** — v2.22+.
- **Remaining ~178 districts** — future waves.
</deferred>

---

*Phase: 159-mi-va-primary-field-coverage*
*Context captured: 2026-07-01 from operator strategy-reframe session (no discuss-phase needed — decisions locked live)*
