# Phase 160: Field Resolution + Stance-Gap Diagnostic - Context

**Gathered:** 2026-07-03
**Status:** Ready for planning

<domain>
## Phase Boundary

A **read-only, write-free diagnostic** across all 38 remaining states / 178 districts that gates every v2.22 seeding phase (161–165). It produces:

1. A per-state **primary-date classification** — `decided` vs `late-primary`, from a verified 2026 primary-date source per state — plus the per-state-cluster grouping Phase 167's date-gated plans are authored from.
2. A per-district **ballot-field table** — the confirmed Nov-3 general field for decided states (every incumbent-not-nominee race explicitly flagged and resolved from an official/results source), the full qualified pre-primary field for late-primary states (official filing/candidate lists, source URL cited per state).
3. An **incumbent → existing `politician_id` map** (keyed by `(NATIONAL_LOWER, geo_id)`, never computed external_id) with current federal-24 stance count per incumbent — all 178 districts.
4. A **collision-free negative `external_id` band verification** per state (`-(state_fips*10000 + cd*100 + seq)`, 0 collisions against live negative IDs).
5. A **per-state / per-district new-record enumeration** (challengers, open-seat, special-seated) — the authoritative input all five seeding phases consume so no phase creates a duplicate incumbent or surfaces a non-candidate.

Analog of Wave-1's Phase 148 and Wave-2's Phase 154. Writes NO production rows; output = diagnostic artifacts + a write-free `160-verify.sql` gate. Requirements: USHC3-01.

</domain>

<decisions>
## Implementation Decisions

### Research fan-out (the phase's dominant cost — 38 states of web research)
- **D-01:** Field-resolution research is dispatched to **per-state research agents at max 3 concurrent** (the proven stance-pipeline cap — 8–13 concurrent died on rate limits), **ordered by seeding-phase grouping**: Phase 161's states (WA, AZ, TN, MA) first, then 162's, … 165's last. Output lands in exactly the order the seeding phases consume it.
- **D-01a:** **Validate the first wave's output shape before continuing** — same first-wave-validation discipline as the stance pipeline. If the research template needs revision, fix it before dispatching the remaining 34 states.
- **D-01b:** DB-side diagnostics (incumbent map, stance-gap counts, external_id collision check, race pre-existence check — the 4 queries already written in STATE.md §Open Blockers) run **inline by the orchestrator first**, so each agent prompt carries its state's incumbent names/districts as grounding.
- **D-02 (walled sources):** Agents use **unwalled routes only** — official SoS/election-board candidate lists, r.jina.ai, raw wikitext, FEC API — and must **flag any district they cannot resolve with a real fetched source URL** rather than guessing. The **orchestrator runs a Playwright sweep over the flagged residue** at the end of each wave (Ballotpedia renders under Playwright; agent dispatch is not viable for walled sources, per the Phase-150 lesson). **No field row without a fetched source URL — ever.**

### Filing-not-closed states (new at this scale; 154 never faced it)
- **D-03:** States whose filing/qualifying period is still open at diagnostic time get **declared-so-far capture tagged `filing-open (deadline: YYYY-MM-DD)`** with the official deadline recorded per state. The owning seeding phase **re-pulls the final list at execution time if the deadline has passed by then**; if it still hasn't, it seeds declared-so-far marked `PROVISIONAL:` and Phase 167's reconciliation catches late filers. Never block the diagnostic or a seeding phase on a filing calendar.

### Nonstandard primary systems + RCV priority (operator emphasis)
- **D-04:** The two-bucket `decided` / `late-primary` classification stays, augmented with a per-state **`ballot_system` tag**: `standard` / `top-two` (WA) / `top-four-rcv` (AK) / `rcv-general` (ME) / LA's 2026 system resolved by research (LA changed its congressional election system for 2026 — verify from official LA SoS sources). For top-two/top-four states the "general field" = whoever advances, party-blind — the existing field-table shape handles this.
- **D-04a (RCV over-indulgence — operator principle):** **Empowered Vote most helps communities that rank their politicians** — ranking voters need to see many candidates quickly with context. RCV races (AK, ME; plus any discovered RCV jurisdiction) get **deliberately maximal thoroughness**: exhaustive field capture (the full top-four in AK, the complete RCV general field in ME, every candidate who will appear on the RCV ballot), verified against official lists with extra care. Flag these races **`rcv`** in the field table so the owning seeding phases (Phase 165 for AK and ME) prioritize maximum candidate-coverage depth there — minor candidates in RCV races are NOT low-priority. The evidence-only honest-skip bar is unchanged (never fabricate stances), but for RCV candidates the search effort goes further before any skip is pinned.

### Artifact packaging
- **D-05:** Mirror Phase 154's artifact shape exactly — one master **`160-field-table.csv`** + **`160-incumbent-map.csv`** (plus a `160-FIELD-TABLE.md` human view) — **with an added `seeding_phase` column (161–165)** so each downstream phase filters its slice. One canonical artifact, five clean views. Also carry `ballot_system`, `rcv`, `filing-open (deadline)`, and nominee-status taxonomy columns per D-03/D-04.

### Carried forward from Phase 154 / roadmap (locked, do not re-litigate)
- **Report-only, no top-up:** partial-stance incumbents are reported, not topped up — new-candidate/zero-stance-incumbent scope only (154 D-02, now in roadmap success criteria).
- **Inclusion bar:** every candidate officially ballot-qualified for the Nov-3 general (decided states) / officially filed-qualified (late-primary states); exclude primary-only also-rans and uncertified write-ins (154 D-03).
- **Vacancy/special-seated:** resolve current officeholder AND 2026 nominee from official/results sources, never from 2024 incumbency; post-v2.17 special-seated members = new-record needs, not stale-incumbent mappings; 7-value nominee-status taxonomy (154 D-04/D-04a; Phase-148 taxonomy).
- **Incumbent identity** by `(district_type='NATIONAL_LOWER', geo_id)` join — never computed external_id (mis-keys states).
- **Read-only:** no migrations, no INSERTs; output = artifacts + `160-verify.sql` asserting read-only facts.

### Claude's Discretion
- Field-resolution source choice per state (official SoS/board-of-elections results preferred over aggregators where reachable), exact research-agent prompt template, per-wave artifact merge mechanics, the exact `160-verify.sql` assertion set (clone `154-verify.sql` / `148-verify.sql` style), and the Phase-167 primary-date-cluster output format — researcher/planner decide, following the inherited Wave-1/Wave-2 conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope & methodology (locked)
- `.planning/REQUIREMENTS.md` — USHC3-01 owns this phase; USHC3-02..07 consume its output.
- `.planning/ROADMAP.md` §"v2.22 … Phases 160–167" — milestone goal, Phase 160 goal + success criteria, full carry-forward execution methodology (prod ref `kxsdzaojfaibhuzmclfq`; `race_candidates` shape; external_id scheme with per-state FIPS list; stance pipeline; fetch-walls; seeding groupings 161–165).
- `.planning/STATE.md` §"v2.22 Execution Methodology" + §"Open Blockers" — the 4 ready-to-run diagnostic queries (incumbent map + stance-gap, negative-ID scan, per-state race pre-existence, primary-date lookup) + phase dependency graph.

### Wave-2 analog (the template to mirror)
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-CONTEXT.md` — the decision set this phase inherits (D-02 report-only, D-03 inclusion bar, D-04/D-04a vacancy taxonomy).
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` + `154-incumbent-map.csv` — artifact shapes to mirror (add `seeding_phase`, `ballot_system`, `rcv`, filing-deadline columns per D-05).
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-01-PLAN.md` / `154-02-PLAN.md` + SUMMARYs — plan structure of the Wave-2 diagnostic.
- `backend/scripts/154-verify.sql` — write-free gate template; `160-verify.sql` follows its shape.
- `backend/scripts/diag-154-incumbent-stance-gap.ts` + `backend/scripts/diag-154-validate-field-table.py` — reusable diagnostic/validation script patterns.

### Wave-1 origin (patterns established there)
- `.planning/milestones/v2.20-ROADMAP.md` §"Phase 148" + `backend/scripts/148-verify.sql` — the original diagnostic pattern; 7-value nominee-status taxonomy; `races.office_id → offices.district_id → districts.geo_id` join (races has no direct geo_id).

### Stance scale (gap-diagnostic denominator)
- `backend/data/stance-research/*/_TOPIC_SCALE_FULL.txt` — the federal-24 topic set defining the stance-count denominator. (Confirm current vs live DB at plan time.)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/scripts/154-verify.sql` — write-free gate template (`DO $$ … RAISE EXCEPTION` assertion style); clone for `160-verify.sql`.
- `backend/scripts/diag-154-incumbent-stance-gap.ts` — incumbent-map + stance-gap query runner; re-point at the 38 Wave-3 states.
- `backend/scripts/diag-154-validate-field-table.py` — field-table CSV validator; extend for the new columns (`seeding_phase`, `ballot_system`, `rcv`, filing deadline).
- `backend/src/lib/db.js` `pool` + `import 'dotenv/config'` — canonical diagnostic-query path when MCP Supabase tokens expire (~1h); scripts must live inside `backend/` for `node_modules`; cwd resets between Bash calls → `cd /c/EV-Accounts/backend &&` in the same compound command.

### Established Patterns
- Incumbent identity resolved by `(district_type='NATIONAL_LOWER', geo_id)`, never computed external_id.
- Diagnostic phases are READ-ONLY: no migrations, no INSERTs; output = artifacts + verify SQL asserting read-only facts.
- Stance-gap filter: `LEFT JOIN inform.politician_answers` counting per `politician_id`.
- Fetch-wall bypasses: Ballotpedia renders under orchestrator Playwright; r.jina.ai for many news sites; raw wikitext for Wikipedia; FEC API (free key, 1000/hr) for candidate cross-checks.

### Integration Points
- Output feeds Phases 161 (WA+AZ+TN+MA), 162 (IN+MD+MN+MO), 163 (WI+CO+AL+SC+LA), 164 (KY+OR+CT+OK+AR+IA+KS+MS), 165 (17 small states) — each consumes its `seeding_phase` slice of the field table + incumbent map + new-record counts.
- Primary-date classification + clusters feed Phase 167's per-cluster date-gated reconciliation plans.
- A parallel session works Phases 177/178 (Hillsboro/Tigard OR) in this repo — avoid collisions on those phase dirs; Phase 160 only READS Oregon data (OR is a Phase-164 state), writes nothing.

</code_context>

<specifics>
## Specific Ideas

- **Operator principle (verbatim intent):** "Empowered Vote MOST helps communities that Rank their politician, as it allows them to see many candidates quickly with context. So if there is an area to over-indulge in our search, it's making sure we are very thorough to support RCV races." — drives D-04a; applies to AK (top-four RCV) and ME (RCV general), plus any RCV jurisdiction the research discovers.
- WA = top-two primary (Aug 4, 2026 expected — verify): general field is the two advancers regardless of party.
- LA changed its congressional election system for 2026 (closed party primaries replacing the former all-party November primary — verify exact 2026 mechanics from LA SoS as part of classification).
- Known special-attention districts from prior waves' carry-forwards: none of the 3 House vacancies (FL-20/GA-13/TX-23) are in Wave-3 states, but the research must still sweep Wave-3 states for post-v2.17 vacancies/special elections (154's VA-11 Walkinshaw lesson — special-seated members are new-record needs unless already seeded).

</specifics>

<deferred>
## Deferred Ideas

- **Partial-incumbent stance top-up** — reported by the diagnostic but out of scope for v2.22 (154 D-02 carried forward); future data-quality pass.
- **Challenger FEC `finance_summary`** — out of scope for v2.22 per REQUIREMENTS.md; record no-FEC-ID rather than retry.
- **RCV-aware product surfaces** (e.g., ranking-oriented compare UI for RCV races) — the RCV thoroughness principle (D-04a) is data-depth only in this milestone; any UI treatment is a future-milestone idea.
- **v2.21 tail** — 159-05/06 MI+VA cull+gate (≥ Aug-5), PA independents re-check (≥ Aug-10), Phase 153 FL re-check (≥ Aug-18) — calendar-gated, separate from this phase.

</deferred>

---

*Phase: 160-field-resolution-stance-gap-diagnostic*
*Context gathered: 2026-07-03*
