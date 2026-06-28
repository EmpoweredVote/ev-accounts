# Phase 142: Stance Research Wave 1 — Governors + AGs - Context

**Gathered:** 2026-06-21
**Status:** Planned (10 plans, 3 waves)

<domain>
## Phase Boundary

Two deliverables: (1) **SEXS-01** — extend the `politician-stance-researcher` prompt with office-type evidence guidance for all 5 exec types BEFORE any research dispatch; (2) **SEXS-02 (partial)** — research + push sourced compass stances for all **80 in-scope execs that currently LACK stances**: **43 Governors + 37 Attorneys General**. Reuses the v2.16/v2.17 stance pipeline VERBATIM.

**In scope:** the 43 unstanced Govs + 37 unstanced AGs (incl. the 4 existing-but-unstanced execs ME Gov, TX Gov, TX AG, IN AG). SEXS-01 prompt edit.

**Out of scope:** SoS / Treasurer / Lt Gov stances (→ Phase 143); feed-surfacing smoke-test + consolidated gate (→ Phase 144); the 13 previously-stanced Gov/AG execs (CA/MA/MD/OR/UT/VA) — the `NOT EXISTS (politician_answers)` filter excludes them automatically; appointed/legislature-selected AGs (AK/HI/NH/NJ/TN/WY have no in-scope AG).
</domain>

<decisions>
## Locked Decisions (NON-NEGOTIABLE for the executor)

### Scope (80 execs)
- **Exactly 80 unstanced execs:** 43 Governors + 37 AGs, per the prod-verified query in 142-RESEARCH.md §"In-Scope Set". Includes the existing-but-unstanced ME Gov / TX Gov / TX AG / IN AG. Re-run the defining query immediately before authoring/executing to catch roster drift.
- **Never touch a previously-stanced exec.** Push is external_id-keyed; IN_SCOPE Sets carry only the batch's exact ids.

### external_ids are IRREGULAR — use exact ids, NEVER the FIPS formula
- IN AG Rokita is **POSITIVE** `499453`; TX Gov `-100202` / TX AG `-100204`; AZ Gov `-400091` / AZ AG `-400092`; ME Gov `-230001`; WV AG `-5400002` (seq 2, not 3); AK Gov `-200008`. Each batch plan carries the literal ids from RESEARCH.

### Pipeline reuse (verbatim)
- Per-batch dir `backend/data/stance-research/{batch}/` with `_TOPIC_SCALE.txt` (25 federal topics, copy as-is) + `_merge.ts` (hand-edit ONLY `OUT` + `IN_SCOPE`; watch substring-clobber sed trap) + `_push.ts` (no edits).
- Quote-repair: collapse quad+ `""""`→`"""` ONLY — NEVER `"""`→`""`. Stray trailing `,"` artifact → `sed -i 's/,"$/,/'` per file.
- Push prefix MANDATORY: `set -a && source .env && set +a && node --import tsx .../_push.ts <csv>` (`_push.ts` does NOT load dotenv).
- Auto-push only when merge reports 0 problems AND 0 unsourced.

### Concurrency
- **≤3 concurrent** `politician-stance-researcher` agents (premium tier). NEVER mass-launch 8–13 (rate-limit empty-output trap). Validate the first triple; drop to 1–2 if 429s reappear.

### SEXS-01 target
- Edit `.claude/agents/politician-stance-researcher.md` (durable agent def) — NOT only the stale SKILL.md. Guidance covers all 5 office types (Gov/LtGov/AG/SoS/Treasurer) even though only Gov+AG are researched this wave.

### Calibration (LOCKED)
- **Zero-unsourced:** every answer row paired to a `politician_context` row with `sources[1] LIKE 'http%'`.
- **Never infer from party**; honest-skip topics with no evidence; honest-partial thin records.
- **Proxy-row review gate:** drop caucus/coalition-only rows lacking an on-topic published position (AGs: multistate-coalition membership counts ONLY when the coalition has a published position directly on that topic); isidewith.com is below the bar; SSM=5 requires a documented anti-recognition/constitutional-amendment vote/action.
- **Office-type evidence:** Gov = bill signings/vetoes/EOs/budget; AG = lawsuits/amicus/multistate-coalition-with-on-topic-position.

### Verification
- Per-batch + the Phase-142 gate key on **`(district_type='STATE_EXEC', role_canonical IN ('governor','attorney_general'))`** — NEVER external_id ranges (ids are non-contiguous). `politician_answers` has NO `created_at` → verify isolation via per-scope external_id counts, never the global row counter.
</decisions>

<plan_structure>
## Plan Structure (10 plans, 3 waves)

- **Wave 1 — 142-01:** SEXS-01 prompt update (gate for everything).
- **Wave 2 — 142-02..142-09 (8 batch plans, depends_on [142-01]):** research + merge + proxy-review + push, ≤3 concurrency, largest-population-first, Gov+AG grouped per state.
  - 142-02 batch A (10): FL/NY/IL/PA/TX
  - 142-03 batch B (9): OH/GA/NC/MI/NJ
  - 142-04 batch C (10): WA/AZ/TN/IN/MO/WI
  - 142-05 batch D (10): CO/MN/SC/AL/LA
  - 142-06 batch E (10): KY/OK/CT/AR/MS
  - 142-07 batch F (10): NV/IA/KS/NM/NE
  - 142-08 batch G (10): ID/WV/RI/MT/VT
  - 142-09 batch H (11): HI/NH/AK/WY/ME/DE/SD/ND
  - **Total = 80 execs (43 Gov + 37 AG).**
- **Wave 3 — 142-10 (depends_on all 8 batches):** `backend/scripts/verify-phase-142.sql` coverage + zero-unsourced gate.
</plan_structure>
