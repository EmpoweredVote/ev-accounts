# Phase 104: Local Remediation — City Officials - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Ensure every city official stance (SF, San Jose, San Diego, Berkeley, Fremont) in `inform.politician_answers` is backed by a real primary source URL or has been permanently deleted. Additionally, compile the complete v2.7 milestone deletion log (QUAL-02 final) covering all remediation phases 101–104.

**Triage completed during discuss-phase (2026-06-07):** Only 2 city officials need remediation. Both have zero unsourced stances and exactly 1 weak-source stance (homepage-only URL) each. No standalone triage plan is needed — this context file is the triage record.

| Full Name | City | Politician ID | Topic Key | Former Value | Weak Source |
|-----------|------|---------------|-----------|-------------|-------------|
| Bilal Mahmood | SF | d3c5004c-9ca0-444e-96d9-107d4315abcb | abortion | 2.0 | https://bilalmahmood.com/ |
| Vivian Moreno | San Diego | 0b16443e-fec4-4f33-abbc-eb1331e3b42d | city-sanitation | 3.0 | https://www.vivianmorenosd.com |

**What this phase delivers:**
- Plan 01: Research both weak-source stances → migration (upgrade or delete) → 104-DELETION-LOG.md → MASTER-DELETION-LOG.md (v2.7 milestone complete)

**What this phase does NOT do:**
- Remediate Monica Rodriguez (external_id 695265, positive — not a v2.5 CA city official, confirmed out of scope)
- Remediate TX city officials (Chris Krupa Downs, Burt Thakur, Ryan Tubbs, Shun Thomas — null external_ids, confirmed out of scope for STAX-03)
- Add new politicians or stances beyond the 2 weak-source targets
- Re-research city officials whose stances already have real primary source URLs

</domain>

<decisions>
## Implementation Decisions

### D-01: Triage — Already Done
- Triage was run during discuss-phase (2026-06-07) using the v2.5 external_id cohort ranges:
  `external_id BETWEEN -689999 AND -630000 AND (external_id < -669999 OR external_id > -660000)`
- Result: 2 politicians, 0 unsourced stances, 2 weak-source-only stances. This is the definitive scope for Plan 01.
- No standalone triage plan. Plan 01 begins directly with research.

### D-02: Scope Boundary
- Authoritative city official identification: `essentials.politicians.external_id` ranges (v2.5 cohort). These IDs join directly into `inform.politician_answers` (shared UUID space between `essentials.politicians` and `inform.politician_answers.politician_id`).
- `inform.politicians` has no city officials — it only contains `STATE_LOWER` records. City officials are identified through `essentials.politicians` only.
- Out-of-scope confirmed: Monica Rodriguez (external_id 695265), Chris Krupa Downs, Burt Thakur, Ryan Tubbs, Shun Thomas. Do not include these in STAX-03 remediation.

### D-03: Plan Structure
- **1 combined plan.** Research both targets → migration → 104-DELETION-LOG.md → MASTER-DELETION-LOG.md.
- Run research-stances for Bilal Mahmood (topic: abortion) then Vivian Moreno (topic: city-sanitation). Sequential, one at a time.
- For each: if a real specific primary source URL is found → UPDATE `inform.politician_context.sources` (array_cat to add the real URL alongside the existing homepage URL). If not → DELETE the stance row + log it per QUAL-02.

### D-04: Research and Deletion Rules (carried from Phases 101–103)
- **Single research pass.** One research-stances run per politician. If a topic returns no specific URL, flag for deletion — no retry.
- **Delete if no real URL found, regardless of value.** No "directional keep." No party inference.
- **QUAL-01 applies:** Homepage-only URL is not a primary source. Research must find a bill vote, press release, public statement, campaign page position, or similar specific evidence. A generic homepage that happens to be the politician's website does not satisfy QUAL-01.
- **Source append (not replace):** If a real URL is found, array_cat it onto the existing `sources` array: `UPDATE inform.politician_context SET sources = sources || ARRAY['new_url'] WHERE politician_id = $1 AND topic_id = $2`. The existing homepage URL remains in the array — the real URL satisfies the sourced standard.
- **One research-stances agent at a time.** No parallel launches.

### D-05: QUAL-02 Final — Merged Master Log
- Phase 104 produces a **MASTER-DELETION-LOG.md** that consolidates all deletion entries from all four remediation phases into one file:
  - Phase 101: 1 deletion (Deb Fischer / ai-regulation) — source: `.planning/phases/101-candidate-profiles/101-DELETION-LOG.md`
  - Phase 102: 12 deletions (Dooley, Shoffner, Alme) — source: `.planning/phases/102-federal-house-remediation/102-DELETION-LOG.md`
  - Phase 103: 6 deletions (Gómez Reyes, Stern, Bonta) — source: `.planning/phases/103-state-remediation-ca-md/103-DELETION-LOG.md`
  - Phase 104: 0–2 deletions (pending research result)
- **File location:** `.planning/phases/104-local-remediation-city-officials/MASTER-DELETION-LOG.md`
- **Format:** Single unified table with columns `phase | politician full_name | topic_key | former value | reason`, preceded by a milestone summary row (total deletions across v2.7).
- **This file is the QUAL-02 canonical artifact** for the v2.7 Source Integrity milestone.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Triage Results (defines exact scope)
- `.planning/phases/104-local-remediation-city-officials/104-CONTEXT.md` §"Phase Boundary" table — 2 confirmed weak-source targets with politician_id, topic_key, value, and current weak source URL. This is the triage record.

### Phase Requirements and Goal
- `.planning/ROADMAP.md` §"Phase 104: Local Remediation — City Officials" — goal statement, success criteria (4 checks), requirements STAX-03, QUAL-01, QUAL-02
- `.planning/REQUIREMENTS.md` §STAX-03, §QUAL-01, §QUAL-02 — requirement definitions

### Prior Deletion Logs (needed to compile MASTER-DELETION-LOG.md)
- `.planning/phases/101-candidate-profiles/101-DELETION-LOG.md` — 1 deletion entry (Deb Fischer / ai-regulation)
- `.planning/phases/102-federal-house-remediation/102-DELETION-LOG.md` — 12 deletion entries (Dooley, Shoffner, Alme)
- `.planning/phases/103-state-remediation-ca-md/103-DELETION-LOG.md` — 6 deletion entries (Gómez Reyes, Stern, Bonta)

### Established Methodology (locked for all v2.7 phases)
- `.planning/STATE.md` §"v2.7 Source Integrity Patterns" — Chair methodology, deletion log format, sourced definition, "Phase 100 gates all remediation" rule
- `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` §"Sourced Definition" — 4-rule sourced standard, weak-sources note (homepage-only pattern), cohort scoping by external_id ranges (v2.5 ranges confirmed authoritative)

### Research Tooling
- `.claude/skills/research-stances/SKILL.md` — How to invoke research-stances; Step 0 (topic resolution — fetch live stance texts from DB); rate limit rule (one at a time)

### Audit Query Patterns
- `backend/scripts/run-source-coverage-audit.ts` — Query E (weak-source filter) as the template for final verification query; uses `pool.query()` (inform schema not in PostgREST)

</canonical_refs>

<code_context>
## Existing Code Insights

### Established Patterns
- **`pool.query()` for all inform schema reads/writes** — `inform.*` is not in the PostgREST exposed schema list. Never use `supabaseAdmin.schema('inform')`.
- **City official identification:** `essentials.politicians.external_id` ranges (v2.5 cohort). `essentials.politicians.id` = `inform.politician_answers.politician_id` (shared UUID space). `inform.politicians` table does NOT contain city officials (only `STATE_LOWER` records).
- **Source append:** `UPDATE inform.politician_context SET sources = sources || ARRAY['real_url'] WHERE politician_id = $1 AND topic_id = $2` — use array_cat, not overwrite.
- **Migration number:** Planner must verify `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing the next migration number. Last known applied: migration 282 (Phase 103 Plan 02). Check live DB — Phases 101–103 applied migrations 268, 269, 282; verify no gap.
- **Deletion is a migration** — deleted stances are removed via SQL DELETE in a migration file. The deletion log is a separate markdown file committed alongside.

### Integration Points
- `inform.politician_answers` + `inform.politician_context` — the two tables being modified
- `essentials.politicians` — join to identify city officials by external_id
- `inform.compass_topics WHERE is_live = true` — research-stances must fetch live topic texts per Step 0; Bilal Mahmood / abortion and Vivian Moreno / city-sanitation are the specific topics

</code_context>

<specifics>
## Specific Ideas

- **Triage query pattern (for final verification after migration):** Join `essentials.politicians` to `inform.politician_answers` and `inform.politician_context` filtered to the v2.5 external_id cohort. After migration, STAX-03 success = 0 rows with unsourced_count > 0 AND 0 rows with weak_source_only_count > 0. Run this exact query as the success-criteria proof.
- **MASTER-DELETION-LOG.md total (pre-Phase 104):** 19 deletions already logged across phases 101–103. Phase 104 adds 0–2 more. The milestone summary row should state the final count.
- **abortion topic for Bilal Mahmood:** SF city council member. A city-level abortion position may reference SF city resolutions, SF Board of Supervisors votes, or campaign statements. research-stances should search SF Board of Supervisors records and Mahmood's campaign site beyond the homepage.
- **city-sanitation for Vivian Moreno:** San Diego city council member (District 8). city-sanitation is a local city-level topic. Research should look for San Diego City Council vote records, press releases, and Moreno's official council page statements.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 104-local-remediation-city-officials*
*Context gathered: 2026-06-07*
