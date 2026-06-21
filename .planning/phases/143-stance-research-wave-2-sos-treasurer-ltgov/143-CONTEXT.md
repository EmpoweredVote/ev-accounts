# Phase 143: Stance Research Wave 2 — SoS + Treasurer + Lt Gov - Context

**Gathered:** 2026-06-21
**Status:** Planned (11 plans, 2 waves)

<domain>
## Phase Boundary

One deliverable: **SEXS-02 (completing)** — research + push sourced compass stances for all **103 in-scope execs that currently LACK stances** across the three remaining Big-5 office types: **37 Lieutenant Governors + 32 Secretaries of State + 34 Treasurers**. Reuses the v2.16/v2.17/142 stance pipeline VERBATIM. There is **no SEXS-01 prompt-update plan** — the `politician-stance-researcher` agent prompt already carries Treasurer/SoS/LtGov office-type evidence guidance (landed in Phase 142-01).

**In scope:** the 103 unstanced execs per the prod-verified query below (LtGov 37 + SoS 32 + Treasurer 34), incl. positive-id IN SoS Morales (`642977`) + IN Treasurer Elliott (`688298`) and the title-alias offices (FL CFO, NY/TX Comptroller). Per-phase gate `verify-phase-143.sql`.

**Out of scope:** Gov/AG stances (done in Phase 142); the 13 previously-stanced Wave-2 execs (`NOT EXISTS (politician_answers)` excludes them automatically); AZ Lt Gov (Prop 131, deferred to Jan 2027 — not seeded, not a miss); appointed/legislature-selected offices (TX/PA/NY/FL/MI/MN/etc. SoS; GA/MI/MN/MT Treasurer; the LtGov-less states WV/WY/AZ); feed-surfacing smoke-test + consolidated all-209 gate (→ Phase 144).
</domain>

<decisions>
## Locked Decisions (NON-NEGOTIABLE for the executor)

### Scope (103 execs — prod-verified 2026-06-21)
- **Exactly 103 unstanced execs:** 37 LtGov + 32 SoS + 34 Treasurer. Re-run the defining query immediately before authoring/executing each batch to catch roster drift:
  ```sql
  SELECT o.role_canonical, d.state, p.external_id, p.full_name
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type='STATE_EXEC'
    AND o.role_canonical IN ('secretary_of_state','treasurer','lt_governor')
    AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id)
  ORDER BY o.role_canonical, d.state;
  ```
- **Never touch a previously-stanced exec.** Push is external_id-keyed; IN_SCOPE Sets carry only the batch's exact ids.

### external_ids are IRREGULAR — use exact ids, NEVER the FIPS formula
- IN SoS Morales is **POSITIVE** `642977`; IN Treasurer Elliott is **POSITIVE** `688298` (re-linked in Phase 141, never reseeded). TX LtGov Patrick `-100203` / TX Comptroller Hegar `-100205`; AZ SoS Fontes `-400093` / AZ Treasurer Yee `-400094`; FL CFO Ingoglia `-1200004`; NY Comptroller DiNapoli `-3600004`; WV SoS Warner `-5400003` / WV Treasurer Pack `-5400004` (no WV LtGov); WY SoS Gray `-5600002` / WY Treasurer Meier `-5600003` (no WY LtGov); AK LtGov Dahlstrom `-200009`. Each batch plan carries the literal ids.

### Office-type evidence (already in the researcher prompt — restate per dispatch)
- **Lt Governor:** LtGovs often have **no independent policy record** → produce an **honest-partial** (only topics with independent sourcing — bills authored as a prior legislator, their own public statements). **NEVER mirror the same-state Governor's stances** without independent personal sourcing.
- **Secretary of State:** score from **specific election-administration actions** (voter-roll purges, mail-ballot rule changes, voter-ID implementation, certification disputes) — NOT from "the SoS administers elections" role text.
- **Treasurer:** score from **investment/divestment decisions** and documented fund actions (e.g. divesting a state pension from fossil fuels/over a policy; ESG-investment policy) — NOT from a budget-overview page or "manages state funds" description. FL CFO and NY/TX Comptroller are functional treasurers — use their actual office title in the dispatch prompt.

### Pipeline reuse (verbatim)
- Per-batch dir `backend/data/stance-research/exec-w2-batch-{a..j}/` with `_TOPIC_SCALE.txt` (25 federal topics, copy as-is) + `_merge.ts` (hand-edit ONLY `OUT` + `IN_SCOPE`; watch substring-clobber sed trap — hand-edit, never sed) + `_push.ts` (no edits). Template: `backend/data/stance-research/gov-ag-batch-a/` (142) or `atlarge-house/`.
- Quote-repair: collapse quad+ `""""`→`"""` ONLY — NEVER `"""`→`""` (auto by `_merge.ts repair()`). Stray lone trailing `,"` artifact → `sed -i 's/,"$/,/'` per file.
- Push prefix MANDATORY: `set -a && source .env && set +a && node --import tsx .../_push.ts <csv>` (`_push.ts` does NOT load dotenv).
- Auto-push only when merge reports **0 problems AND 0 unsourced** (standing rule this milestone); still show the summary. No per-batch user gate.
- Per-scope coverage assert via `node scripts/verify-stance-coverage.mjs <count> <ext_ids...>`.

### Concurrency
- **≤3 concurrent** `politician-stance-researcher` agents (premium tier). NEVER mass-launch 8–13 (rate-limit empty-output trap). Validate the first triple; drop to 1–2 if 429s reappear. → [[feedback_stance_research_one_at_a_time]]

### Calibration (LOCKED)
- **Zero-unsourced:** every answer row paired to a `politician_context` row with `sources[1] LIKE 'http%'`.
- **Never infer from party**; honest-skip topics with no evidence; **honest-partial thin records (4–8 topics), not zero stances** for LtGovs with a usable record. → [[feedback_stance_no_assumption]]
- **LtGov honest-skip-of-whole-record is allowed** when a LtGov has NO independent sourceable record at all (like OH AG -3900003 in 142) — pin it belt-and-suspenders in the gate; never fabricate to hit a count.
- **Proxy-row review gate:** drop caucus/coalition-only rows lacking an on-topic published position; isidewith.com is below the bar; SSM=5 requires a documented anti-recognition / constitutional-amendment vote or action; embed the actual 1–5 stance texts per dispatch (never "5=progressive"). → [[feedback_stance_scale_embed_texts]]

### Verification
- Per-batch (`verify-stance-coverage.mjs`) + the Phase-143 gate (`verify-phase-143.sql`) key on **`(district_type='STATE_EXEC', role_canonical IN ('secretary_of_state','treasurer','lt_governor'))`** — NEVER external_id ranges. `politician_answers` has NO `created_at` → verify isolation via per-scope external_id counts, never the global row counter.
- **Gate coverage denominators (prod-verified 2026-06-21):** SoS = 35 (32 wave-2 + 3 pre-stanced); Treasurer = 38 (34 wave-2 + 4 pre-stanced); Lt Gov = 43 (37 wave-2 + 6 pre-stanced). Re-run the live diagnostic at gate-authoring time and pin any whole-record LtGov honest-skip to its exact external_id (USHS-14a pattern). Phase 144 remains the consolidated all-209 gate.
</decisions>

<plan_structure>
## Plan Structure (11 plans, 2 waves) — 10 state-grouped batches + gate

All of a state's in-scope SoS+Treasurer+LtGov ride in the SAME batch (one state closes per batch). Largest-population-first so calibration carries forward. **Batches are mutually independent (wave 1, depends_on []);** no SEXS-01 dependency (prompt already updated). Gate is wave 2.

- **Wave 1 — 143-01..143-10 (10 batch plans, depends_on []):** research ≤3 concurrency + merge + proxy-review + push.
  - 143-01 batch A (11): TX(LtGov+Treas) FL(LtGov+Treas) NY(LtGov+Treas) PA(LtGov+Treas) IL(LtGov+SoS+Treas)
  - 143-02 batch B (10): OH(3) GA(LtGov+SoS) NC(3) MI(LtGov+SoS)
  - 143-03 batch C (11): NJ(LtGov) WA(3) AZ(SoS+Treas) IN(SoS+Treas) MO(3)
  - 143-04 batch D (11): WI(3) CO(3) MN(LtGov+SoS) SC(3)
  - 143-05 batch E (9):  AL(3) LA(3) KY(3)
  - 143-06 batch F (11): OK(LtGov+Treas) CT(3) IA(3) NV(3)
  - 143-07 batch G (9):  AR(3) MS(3) KS(3)
  - 143-08 batch H (9):  NM(3) NE(3) ID(3)
  - 143-09 batch I (10): WV(SoS+Treas) HI(LtGov) MT(LtGov+SoS) RI(3) DE(LtGov+Treas)
  - 143-10 batch J (12): SD(3) ND(3) AK(LtGov) VT(3) WY(SoS+Treas)
  - **Total = 103 execs (37 LtGov + 32 SoS + 34 Treasurer).**
- **Wave 2 — 143-11 (depends_on all 10 batches):** `backend/scripts/verify-phase-143.sql` coverage (SoS 35 / Treas 38 / LtGov 43) + zero-unsourced gate, keyed on (STATE_EXEC, role_canonical IN the three Wave-2 roles).
</plan_structure>
