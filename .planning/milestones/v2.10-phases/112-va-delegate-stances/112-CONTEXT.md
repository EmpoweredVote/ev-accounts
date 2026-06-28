# Phase 112: VA Delegate Stances - Context

**Gathered:** 2026-06-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Research and ingest sourced stance data for all 100 VA House delegates (external_id -5120001 through -5120100) across all 44 live CompassV2 topics. Honest-skip applied where no documentable evidence exists. Every retained stance paired with a real source URL. Closes VAST-03; contributes to VAST-05.

This phase does NOT cover: VA state executives (VAST-01 — unassigned), VA state senators (Phase 111, complete), or VA federal House reps (Phase 113).

</domain>

<decisions>
## Implementation Decisions

### Wave / Plan Structure
- **D-01:** 10 plan files × 10 delegates each. One migration per plan: migrations 331–340 (sequential, psql-applied like Phase 111 waves 326–330).
- **D-02:** Migration numbering: next free after Phase 111's waves (326–330) is 331. Always verify with `SELECT MAX(version) FROM supabase_migrations.schema_migrations` — note that psql-applied wave migrations do NOT register there (max shows 325 at time of context). Cross-check against the highest-numbered file in `supabase/migrations/` to determine the true next free number.

### Wave Grouping
- **D-03:** Group delegates geographically across 10 waves. Researcher must fetch all 100 delegate names+UUIDs+district numbers from the DB, map them to regions, and define the 10 wave compositions explicitly in RESEARCH.md before planning begins.
- **D-04:** Suggested regional split (researcher confirms with actual district data):
  - Waves 1–2: Western / Southwest VA (rural, Republican-heavy, thinner web presence)
  - Waves 3–4: Central / Piedmont VA (mixed)
  - Waves 5–6: Hampton Roads / Coastal VA (mixed)
  - Waves 7–8: Richmond metro (mixed, some high-profile)
  - Waves 9–10: Northern Virginia / NoVA (Democratic-heavy, more online presence, higher expected yield)
- **D-05:** Researcher must produce the full delegate roster table (full_name, UUID, district, region assignment) in RESEARCH.md before any plan is written.

### Honest-Skip / Research Quality
- **D-06:** Attempt all 44 live topics for every delegate. No pre-filtered topic list. City-level topics (from SKILL.md skip list: transportation-priorities, economic-development, homelessness-response, residential-zoning, city-sanitation, local-immigration, rent-regulation, growth-and-development, local-environment, public-safety-approach, jail-capacity, all judicial-* topics) are skipped by the agent via the same honest-skip mechanism — no special pre-filtering needed.
- **D-07:** HARD RULE — do not guess. Do not assign any stance value without a real fetched source URL. Zero rows for a delegate is a valid and acceptable outcome. A delegate with no documentable public positions simply has no rows in `inform.politician_answers`. This is not a failure.
- **D-08:** No sourcing-free answers. Every value written to the CSV must have at least one URL in source_url_1 that the agent actually fetched successfully. If a delegate's page 404s or has no policy content, skip the topic.
- **D-09:** Party affiliation must never be used to infer a stance value. Always require direct evidence from the politician's own record.
- **D-10:** Expected yield: low-profile / rural delegates may yield 0–6 stances; high-profile / NoVA / Richmond delegates may yield 10–20. Both outcomes are correct. Do not pad.

### Execution Pattern (carried from Phase 111)
- **D-11:** Sequential dispatch — ONE `politician-stance-researcher` agent at a time. Wait for CSV write confirmation before dispatching next. Never run two agents in parallel.
- **D-12:** WebFetch only. No WebSearch, no Playwright. Both share a rate-limited quota pool.
- **D-13:** VAST-05 invariant: every `inform.politician_answers` row must have a paired `inform.politician_context` row with `sources` array containing at least one non-empty URL. Migration DO $$ block must ASSERT unsourced_count = 0 for each wave's external_id range.
- **D-14:** `pool.query()` for all DB writes. `inform` schema is NOT in the PostgREST exposed list — `supabaseAdmin.schema('inform')` fails at runtime.
- **D-15:** Live topics fetched fresh from DB before each wave (not hardcoded). Embed full topic+stance-text JSON in every agent prompt.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Skill + Agent
- `.claude/skills/research-stances/SKILL.md` — orchestration pattern, sequential dispatch rules, Five-Chairs framing, CSV format, DB push logic, city-level topic skip list
- Agent type: `politician-stance-researcher` (subagent_type param in Agent tool)

### Phase 111 Artifacts (established pattern)
- `.planning/phases/111-va-state-stances-senators/111-RESEARCH.md` — complete execution pattern: pre-flight queries, UUID fetch, migration template (Pattern 4), phase gate SQL, pitfall list, source strategy for VA politicians
- `.planning/phases/111-va-state-stances-senators/111-01-PLAN.md` — reference plan structure for a stance wave (pre-flight task → sequential agents → migration SQL → psql apply → verify)

### Requirements
- `.planning/ROADMAP.md` §Phase 112 — success criteria (VAST-03, VAST-05)
- `.planning/STATE.md` — v2.10 requirements table, migration sync notes, DB state as of Phase 111 close

### Memory (user preferences)
- `C:/Users/Chris/.claude/projects/C--EV-Accounts/memory/feedback_stance_research_one_at_a_time.md` — mass-launch hazard
- `C:/Users/Chris/.claude/projects/C--EV-Accounts/memory/feedback_stance_no_assumption.md` — no party inference
- `C:/Users/Chris/.claude/projects/C--EV-Accounts/memory/feedback_stance_scale_embed_texts.md` — embed stance texts in every agent prompt

### DB Patterns
- `backend/src/lib/db.js` — pool export used by all inline `node --import tsx` scripts
- `supabase/migrations/20260609000005_330_va_senators_wave5_stances.sql` — most recent stance migration; mirror header style and DO $$ verification block pattern

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `research-stances` SKILL.md: fully handles orchestration, CSV output, DB push — no custom code needed
- `politician-stance-researcher` agent: WebFetch-based per-politician research with Five-Chairs framing
- Phase 111 plan files: mirror the 4-task structure (pre-flight → sequential agents → migration SQL → psql apply)

### Established Patterns
- **Pre-flight query pattern**: `SELECT MAX(version) FROM supabase_migrations.schema_migrations` + topics snapshot + UUID fetch for the wave's external_id sub-range
- **Migration template**: BEGIN/COMMIT block; paired `politician_answers` + `politician_context` INSERTs; DO $$ ASSERT unsourced_count = 0 scoped to wave's external_id range
- **psql apply**: `psql "$DATABASE_URL" -f supabase/migrations/<file>.sql` — session pooler URL (aws-0-*.pooler.supabase.com:5432), not IPv6 direct host

### Integration Points
- `inform.politician_answers` (politician_id, topic_id, value) — FK to `essentials.politicians.id` and `inform.compass_topics.id`
- `inform.politician_context` (politician_id, topic_id, reasoning, sources[]) — composite PK, no standalone `id` column (use `pc.politician_id IS NULL` not `pc.id IS NULL` in verification queries)
- `essentials.politicians` external_id range for VA delegates: -5120001 to -5120100 (100 records confirmed)

</code_context>

<specifics>
## Specific Ideas

- Full delegate roster (all 100 names, UUIDs, district numbers, region assignments) must be produced in RESEARCH.md — this is the single most important pre-planning artifact for Phase 112.
- VPAP (vpap.org) is a strong Tier 1 source for VA delegates alongside Ballotpedia and lis.virginia.gov.
- Source URL fetch pattern for delegates: ballotpedia.org/[First_Last] → lis.virginia.gov/mbr query → house.virginia.gov/member page → vpap.org/officials/[slug] → official delegate .gov page
- Wave grouping by geography allows the researcher to write region-aware source strategy notes per wave (NoVA delegates have more press coverage; Western VA delegates may only have lis.virginia.gov floor votes).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 112-va-delegate-stances*
*Context gathered: 2026-06-10*
