# Phase 103: State Remediation — CA + MD - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Two parallel tracks in one phase:

**Track A — CA remediation (STAX-01):** Every CA state politician (CA Assembly, CA Senate, statewide executives like governor) stance in `inform.politician_answers` must be sourced or deleted. Triage-first: run a fresh query across ALL CA politicians in the DB before any research. Includes weak-source detection (homepage-only URLs), not just unsourced stances.

**Track B — MD fresh research (STAX-02):** Five Maryland executive branch officials (Wes Moore, Aruna Miller, Anthony G. Brown, Brooke Lierman, Dereck E. Davis) have zero stances. Research all live compass topics from scratch using Chair methodology. Every added stance requires a real primary source URL.

**What this phase delivers:**
- Plan 01: CA triage query — all CA politicians (unsourced + weak-source detection), produces target list
- Plan 02: CA research + migration + deletion log — remediate CA target list (sourced or deleted)
- Plan 03: MD research (all 5 officials, all live topics) + migration + deletion log appendix

**Known CA scope (Phase 100 target list — unsourced only):**
- Gavin Newsom (4 unsourced stances)
- Katy Hall (3), Tracy Miller (3)
- Candice B. Pierucci (1), Cody Harris (1), Juan Carrillo (1), Lisa Calderon (1), Mike Braun (1), Roland Gutierrez (1)
- Additional weak-sourced CA politicians will be surfaced by Plan 01 triage — scope is dynamic

**Known MD scope (Phase 100 confirmed IDs):**
| Full Name (DB) | Politician ID |
|---|---|
| Wes Moore | 21e534c8-c0c0-42f5-b52b-5eb2f246d632 |
| Aruna Miller | ea9fc2d6-3b26-469a-978c-e8c846d2d49a |
| Anthony G. Brown | 60329719-1d5b-4bb4-8295-38ea18f6f378 |
| Brooke Lierman | b26fb5d2-90eb-4108-8ce5-838df719473d |
| Dereck E. Davis | 75378a96-8886-46eb-b0c1-37cbe2579265 |

**What this phase does NOT do:**
- Remediate city official stances (Phase 104)
- Add politicians not already in the DB (MD officials are the only exception per milestone definition)
- Re-research CA politicians whose stances already have real (non-homepage) source URLs
- Touch Federal (Phases 101/102 complete)

</domain>

<decisions>
## Implementation Decisions

### D-01: CA Triage Scope
- **Full triage of all CA politicians in DB** — Plan 01 runs a fresh query for every politician whose office maps to a CA district (Assembly: district type STATE_LOWER for CA; Senate: STATE_UPPER for CA; statewide: governor etc.). Filter is state-level, not just "Assembly + Senate" strictly.
- **Dual detection: unsourced + weak-source.** Query must catch both: (1) politicians with unsourced stances (missing context row, empty sources array, blank URLs) AND (2) politicians with ALL sources matching homepage-only pattern `^https?://[^/]+/?$`. Mirrors Phase 101/102 dual-scope approach.
- **Scope is dynamic.** Plan 02 sizing comes from the triage output. The 9 known politicians from Phase 100 are a floor, not a ceiling.

### D-02: CA Politician Scope
- **All CA state politicians** in the DB — not just CA Assembly + CA Senate strictly. Statewide executives (e.g., Gavin Newsom as governor) are included. The triage query captures any politician with an office record tied to a CA district.

### D-03: Plan Structure
- **3 plans:**
  - Plan 01: CA triage query only (like Phase 101/102 Plan 01)
  - Plan 02: CA research + migration + deletion log (planner sizes batching from triage output)
  - Plan 03: MD research (5 officials, all live topics, 1 at a time) + migration + deletion log appendix
- **Planner may split Plan 02** if CA triage reveals >25 target politicians (mirror Phase 101's 11–25 → 2-plan threshold). This is planner discretion based on triage output.

### D-04: MD Research Approach
- **All live compass topics** — run research-stances for each MD official covering every topic in `inform.compass_topics WHERE is_live = true`. The planner must query this live count before writing the research plan (user noted there may be 44 topics, not the original 21 — verify against DB).
- **No stances yet = no deletion** — MD officials have zero existing stances. Any topic with no evidence found simply gets no stance row. No deletion log entries needed for MD (deletion log format is for removing EXISTING stances only).
- **Sequential only** — one MD official at a time, one research-stances call at a time. Rate limit protection established in Phases 101/102.

### D-05: Source Update Policy
- **Append new URLs to existing sources, never replace.** When a CA politician already has a context row with existing sources (even homepage-only weak ones), migration must ARRAY_CAT the new real URLs onto the existing array: `UPDATE inform.politician_context SET sources = sources || ARRAY['new_url'] WHERE ...`. Preserves prior source history while adding the better primary source.
- **Exception:** If the existing sources array is empty or NULL (true unsourced), use a plain INSERT or UPSERT to set sources to the new URL array.

### D-06: Deletion and Research Rules (carried from Phases 101/102)
- **Delete if no real URL found — regardless of value.** Even if the stance value seems obviously correct, it must have a real primary source URL after one research pass. No "directional keeps."
- **Single research pass.** One research-stances run per batch. No retry loops. If a topic returns no evidence, flag for deletion.
- **No party inference.** Never infer a stance from party affiliation — a locked pattern from v2.7 methodology.
- **QUAL-02 deletion log format:** `politician full_name, topic_key, former value, reason ("no evidence found" or "value incorrect and no correcting source found")`. Plan 02 produces the CA log; Plan 03 does NOT need MD entries (no existing stances to delete).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit Results (scope the work)
- `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` — Sourced definition (4-rule check), weak-sources note (107 rows, homepage-only pattern), MD officials section (5 names + IDs + confirmed 0 stances)
- `.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv` — 15 politicians with unsourced stances; CA state rows provide the floor for Plan 01 triage

### Phase Requirements and Goal
- `.planning/ROADMAP.md` §"Phase 103: State Remediation — CA + MD" — goal statement, requirements STAX-01, STAX-02, QUAL-01, QUAL-02
- `.planning/REQUIREMENTS.md` §STAX, §QUAL — requirement definitions including STAX-02 clarification ("stances do not yet exist; research and add full stance coverage")

### Prior Phase Patterns (established methodology)
- `.planning/phases/101-candidate-profiles/101-CONTEXT.md` — D-01 through D-04: triage-first pattern, weak-source scope, plan sizing thresholds (≤10 / 11–25 / 26+), deletion threshold, single-pass rule
- `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` §"Sourced Definition" — 4-rule sourced standard, locked for all v2.7 phases 101–104
- `.planning/STATE.md` §"v2.7 Source Integrity Patterns" — Chair methodology, deletion log format, sourced definition, rate limit rule

### Audit Query Patterns
- `backend/scripts/run-source-coverage-audit.ts` — Query E (weak-source filter) as template for Plan 01 CA triage. Plan 01 adapts by adding a CA-district join (state = 'CA' or district_type IN ('STATE_LOWER','STATE_UPPER') filtered by CA jurisdiction).

### Research Tooling
- `.claude/skills/research-stances/SKILL.md` — How to invoke research-stances; Step 0 (topic resolution — fetch live stance texts from DB, NOT hardcoded descriptions); rate limit rule (one at a time, max 2 parallel)

### Migration Patterns
- Prior senator/candidate stance migrations (174–176, 197–198) — templates for UPDATE/DELETE SQL structure
- `backend/scripts/gen_migration.py` (or direct SQL) — migration file generation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/scripts/run-source-coverage-audit.ts` — Query E is the weak-source filter (`url ~ '^https?://[^/]+/?$'` pattern). Plan 01 CA triage script adapts this, adding a CA-jurisdiction filter via district join.
- Phase 102 triage script (in 102-TRIAGE-REPORT.md) — dual-scope query pattern (unsourced + weak-source in one pass) is the direct template for the CA triage.

### Established Patterns
- **`pool.query()` for all inform schema reads/writes** — `inform.*` is not in the PostgREST exposed schema list. Never use `supabaseAdmin.schema('inform')`.
- **Migration number:** Planner must verify `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing the next migration number. Last applied: migration 269 (Phase 102 context).
- **Deletion is a migration** — deleted stances are removed via SQL DELETE in a migration file. The deletion log (CSV or markdown) is committed alongside the migration.
- **DISTINCT ON (politician_id) in tier subquery** — join politicians to districts to identify CA legislators; use DISTINCT ON to avoid multi-office Cartesian inflation.
- **Source append:** `UPDATE inform.politician_context SET sources = sources || ARRAY['url'] WHERE politician_id = $1 AND topic_id = $2` — use ARRAY_CAT not overwrite.

### Integration Points
- `inform.politician_answers` + `inform.politician_context` — the two tables being modified
- `essentials.offices → essentials.districts WHERE district_type IN ('STATE_LOWER','STATE_UPPER') AND state = 'CA'` — join path for CA legislator identification in triage query
- For MD officials: identify by politician_id (IDs confirmed in Phase 100 audit report above)
- `inform.compass_topics WHERE is_live = true` — query live topic count before building MD research plan (may be more than 21 — user noted ~44)

</code_context>

<specifics>
## Specific Ideas

- **CA triage script should output two artifacts:** (1) executive summary (total CA politicians, unsourced count, weak-source count), (2) CSV with politician full_name, politician_id, unsourced_count, weak_source_count. Lets the planner size Plan 02 correctly.
- **MD official IDs are confirmed in Phase 100 audit** — use those UUIDs directly when building the MD research plan. Don't re-query by full_name (middle initial variants caused issues in Phase 100 execution).
- **Topic count for MD:** Verify `SELECT COUNT(*) FROM inform.compass_topics WHERE is_live = true` before writing Plan 03. User indicated the count may be 44 rather than the original 21 — research-stances must cover whatever the live count is.
- **Source append for CA remediation:** research-stances may return the same value with a better source URL. The migration should UPDATE both `politician_answers.value` (if changed) AND `politician_context.sources` (append), rather than only touching one table.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 103-state-remediation-ca-md*
*Context gathered: 2026-06-05*
