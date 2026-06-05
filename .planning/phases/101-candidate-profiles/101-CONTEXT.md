# Phase 101: Federal Senate Remediation - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Ensure every US Senator stance in `inform.politician_answers` is backed by a real primary source URL or has been permanently deleted. Stances already exist from v2.3 (Phase 74); this phase is URL remediation — not fresh data creation for all 100 senators.

**What this phase delivers:**
- Senator-specific weak-source triage query → target list of senators who need re-research
- Full research-stances re-run for senators with unsourced or weak-sourced stances only
- Updated `inform.politician_context.sources` rows with real primary source URLs
- Deletion of any stance where no real URL can be found after a single research pass
- Deletion log (QUAL-02) committed to repo

**What this phase does NOT do:**
- Re-research senators whose stances already have real (non-homepage) source URLs
- Remediate House, CA, or city official stances (Phases 102–104)
- Address the 5 MD officials with zero stances (Phase 103 STAX-02 scope)

</domain>

<decisions>
## Implementation Decisions

### D-01: Weak-Source Scope
- **Triage query first.** Plan 01 runs a senator-specific weak-source query — filter `inform.politician_context` rows for senators (join through `essentials.offices → essentials.districts WHERE district_type = 'NATIONAL_UPPER'`) where all non-blank sources match the homepage-only pattern `^https?://[^/]+/?$`. Produces a senator target list with counts.
- **Upgrade or delete — no middle ground.** For each homepage-only URL found: find the specific bill vote record, press release, floor speech, or statement. If a real specific URL can be found, upgrade the context row. If not, delete the stance (and log it per QUAL-02). Keeping the homepage URL as-is does not satisfy QUAL-01.
- **Scope is dynamic.** The planner uses the triage output to scope Plan 02+ — don't assume count before the query runs.

### D-02: Research Approach
- **Use research-stances skill for affected senators only** — senators identified in the triage (unsourced + weak-sourced stances). Not all 100 senators.
- **Full re-research, not URL-patch-only.** Run research-stances as a fresh pass. If new research finds a different sourced value than the existing value, the new sourced value wins. The point of remediation is accuracy — a sourced correction is better than a retained but unsupported value.
- **Stance scale:** Pass full topic stance texts (values 1–5 with text) from the DB into every researcher agent prompt. Never use hardcoded scale descriptions. Fetch live from `inform.compass_stances` per `research-stances` SKILL.md Step 0.
- **One at a time.** Run research-stances for one senator batch at a time — no parallel launches. (Rate limit protection — established pattern.)

### D-03: Plan Structure
- **Plan 01 = triage only.** Run weak-source query filtered to NATIONAL_UPPER senators. Output: senator names, politician IDs, affected topic counts. Commit as a data file or script output.
- **Plan 02+ = research + migration + deletion log.** Planner decides batching based on triage count:
  - ≤ 10 senators: 1 plan (research + migration)
  - 11–25 senators: 2 plans (A–M, N–Z) mirroring Phase 74 batching
  - 26+ senators: 3 plans
- **QUAL-02 deletion log** goes in the final plan of this phase. Format: `politician full_name, topic_key, former value, reason ("no evidence found" or "value incorrect and no correcting source found")`.

### D-04: Deletion Threshold
- **Delete if no real URL found — regardless of value.** Even if the stance value seems "obviously correct" given the senator's party or public record, it must have a real primary source URL after re-research. No exceptions — this upholds the Chair methodology.
- **Single research pass.** One research-stances run per batch. If a topic comes back with no evidence, flag for deletion. No retry loop, no separate manual verification step.
- **No "directional keep."** Do not retain a stance because the value aligns with the senator's party. Party inference is explicitly forbidden by the feedback rules.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Audit Results (scope the work)
- `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` — Sourced definition (4-rule check), weak-sources note (107 rows, homepage-only pattern), tier breakdown showing 1 unsourced federal stance
- `.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv` — 15 politicians with unsourced stances; Deb Fischer is the only Federal row (1 unsourced stance out of 20)

### Phase Requirements and Goal
- `.planning/ROADMAP.md` §"Phase 101: Federal Senate Remediation" — goal statement, success criteria (4 SQL-level checks), requirements FEDX-01, QUAL-01, QUAL-02

### Methodology Rules (locked patterns)
- `.planning/STATE.md` §"v2.7 Source Integrity Patterns (established 2026-06-05)" — Chair methodology, deletion log format, sourced definition, "Phase 100 gates all remediation" rule
- `.planning/STATE.md` §"v2.3 Senator Records Patterns (from 73-01)" — bioguide pre-verification, DB full_name check (e.g., "Adam B. Schiff"), appointed senator flags

### Research Tooling
- `.claude/skills/research-stances/SKILL.md` — How to invoke research-stances; Step 0 (topic resolution — fetch live stance texts from DB); rate limit rule (one at a time)

### Audit Script (query patterns)
- `backend/scripts/run-source-coverage-audit.ts` — Query E (weak-source query) as the template for the Plan 01 senator-specific triage query; uses `pool.query()` (inform schema not in PostgREST)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/scripts/run-source-coverage-audit.ts` — Query E is the weak-source filter (`LIKE '%://%' AND url NOT LIKE '%://%/%'` pattern). Plan 01 triage script adapts this, filtered to `district_type = 'NATIONAL_UPPER'` senators.
- `backend/scripts/gen_migration.py` (or direct SQL migration) — prior senator stance migrations (174–176) as the template for UPDATE/DELETE migration SQL.

### Established Patterns
- **`pool.query()` for all inform schema reads/writes** — `inform.*` is not in the PostgREST exposed schema list. All queries must go through `pg.Pool`. Never use `supabaseAdmin.schema('inform')`.
- **Migration number**: Last applied depends on what's been run since Phase 100. Planner must verify `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing the next migration number.
- **Deletion is a migration** — deleted stances are removed via SQL DELETE in a migration file, not via API. The deletion log is a separate markdown/CSV file committed alongside the migration.
- **DISTINCT ON(politician_id) in tier subquery** — when joining politicians to districts to identify senators, use DISTINCT ON to avoid multi-office Cartesian inflation (senators may have multiple office rows).

### Integration Points
- `inform.politician_answers` + `inform.politician_context` — the two tables being modified. Every `politician_answers` row for a senator that remains after this phase must have a paired `politician_context` row with at least one real URL.
- `essentials.offices → essentials.districts WHERE district_type = 'NATIONAL_UPPER'` — the join path to identify senators. Used in triage query and success-criteria SQL.

</code_context>

<specifics>
## Specific Ideas

- **Triage script should output two things:** (1) total weak-source senator count, (2) list of senator names + politician_ids + affected topic keys. This lets the planner size Plan 02+ correctly and gives the researcher the exact scope.
- **research-stances output for remediation:** When running research-stances for an existing senator, the CSV output may include unchanged stances (same value, better source) or changed stances (different value with source). Both are valid outputs — the migration should UPSERT both `politician_answers.value` and `politician_context.sources` rather than only updating one table.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 101-federal-senate-remediation*
*Context gathered: 2026-06-05*
