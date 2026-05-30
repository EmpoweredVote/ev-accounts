# Phase 78: City Stance Research - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Research and ingest CompassV2 stance data (all 42 applicable topics, excluding `data-centers`) for every San Jose, San Diego, Berkeley, and Sacramento city official. Fremont stances are pre-completed (migration 219, 56 rows). After this phase, users in all 5 v2.5 cities can open the compass compare view and see their local officials' positions with source citations.

**City roster:**
- San Jose: 11 officials (1 mayor + 10 council members) — migrations 217/218/219 applied
- San Diego: 11 officials (1 mayor + 1 city attorney + 9 council members) — migrations 207/208/209 applied
- Berkeley: 10 officials (1 mayor + 1 city auditor + 8 council members) — migrations 213/214/215 applied
- Fremont: 7 officials — CSTA-04 PRE-COMPLETED via migration 219 (56 stances)
- Sacramento: 9 officials (1 mayor + 8 council members) — migrations 219/220 applied; headshots unapplied

</domain>

<decisions>
## Implementation Decisions

### Sacramento Scope
- **D-01:** Sacramento is included in Phase 78 despite not being in the original CSTA-01–05 requirements. Migrations 219/220 seeded Sacramento government structure and 9 officials informally on 2026-05-23. Add as a 5th stance research city.
- **D-02:** Sacramento headshots (`sac_headshots.sql`, currently unnumbered) must be applied as **Wave 0** — the first task in Phase 78 — before any stance research begins. Planner assigns the migration number by checking the live DB migration table.

### Wave Structure
- **D-03:** Phase 78 executes in 6 waves:
  - Wave 0: Apply Sacramento headshots (sac_headshots.sql → numbered migration)
  - Wave 1: San Jose stance research + migration (CSTA-01)
  - Wave 2: San Diego stance research + migration (CSTA-02)
  - Wave 3: Berkeley stance research + migration (CSTA-03)
  - Wave 4: Sacramento stance research + migration (new, unnamed requirement)
  - Wave 5: Context row audit across all 4 new cities (CSTA-05)
- **D-04:** Fremont (CSTA-04) is already closed — do not re-ingest or re-verify Fremont in this phase.

### Research Execution
- **D-05:** Research agents run **one city at a time** — never launch parallel research batches. Each city's migration must be applied and spot-checked before the next city's research begins.
- **D-06:** Topic scope: all 43 CompassV2 topics attempted for every official **except `data-centers`** (excluded for all city officials). Where no evidence exists, document "no evidence" — do not fabricate or skip silently.
- **D-07:** Minimum floor for thin-record officials: 5 stances. City council members with very limited public record still require at least 5 researched stances before their batch is considered complete.

### Migration Numbering
- **D-08:** Planner must check the live DB migration table at plan time to confirm the next available migration number. Last known applied: 220 (Sacramento officials). Do not pre-assign numbers in the plan.

### Context Audit (CSTA-05)
- **D-09:** CSTA-05 runs as a single final wave (Wave 5) after all 4 city stance batches are ingested — same approach as Phase 74's SSTA-02 audit. One SQL query pass checking for orphan `politician_answers` rows (no paired `politician_context` row) across all 4 new cities.

### Migration Pattern
- **D-10:** Each city stance migration uses `ON CONFLICT (politician_id, topic_id) DO UPDATE` on both `inform.politician_answers` and `inform.politician_context`. One migration file per city. Pattern mirrors migration 216 (SF) and 219 (Fremont).

### Claude's Discretion
- Specific SQL structure within each stance migration (topic UUID reference block, section organization) — follow the established pattern from migrations 216/219.
- Batch size within the research-stances skill invocation per city (agent decides based on official count).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Established Stance Migration Pattern
- `backend/migrations/216_sf_officials_stances.sql` — Canonical city stance migration pattern (SF, 20 officials, 366 rows). Topic UUID reference block, section structure, idempotency pattern, topic scope comment. Read this before writing any stance migration.
- `backend/migrations/219_fremont_officials_stances.sql` — Second city stance migration example (Fremont, 7 officials, 56 rows). Confirms minimal topic coverage for smaller officials.

### City Official Records (needed for politician IDs)
- `backend/migrations/218_sj_officials.sql` — San Jose: 11 politicians, external_ids -640010..-640001
- `backend/migrations/208_sd_officials.sql` — San Diego: 11 politicians, external_ids -650018..-650001
- `backend/migrations/214_berkeley_officials.sql` — Berkeley: 10 politicians, external_ids -680017..-680001
- `backend/migrations/220_sacramento_officials.sql` — Sacramento: 9 politicians, external_ids -660017..-660001

### Sacramento Headshots (Wave 0)
- `backend/migrations/sac_headshots.sql` — Unnumbered Sacramento headshot migration; apply as Wave 0 with planner-assigned migration number

### Phase Requirements
- `.planning/REQUIREMENTS.md` §City Stances (CSTA) — CSTA-01 through CSTA-05 requirements
- `.planning/ROADMAP.md` §Phase 78 — Wave structure, success criteria, dependencies

### Research Skill
- `.claude/skills/research-stances/` — research-stances skill; used to launch stance research agents for each city

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/migrations/216_sf_officials_stances.sql`: Full topic UUID reference block (all 43 topics with UUIDs) — copy this directly into each new city migration rather than looking up UUIDs independently
- `backend/migrations/219_fremont_officials_stances.sql`: Minimal city migration example — useful for smaller cities (Berkeley, Sacramento)
- `data/stance-research/2026-05-23-fremont-officials.csv`: Example of how stance research CSV output is structured before migration generation

### Established Patterns
- **`data-centers` excluded for city officials**: All prior city migrations exclude the `data-centers` topic. Never include it in city stance migrations.
- **No party values**: All city politicians have `party = NULL` (antipartisan design). Researchers must not infer or assign party affiliations.
- **`ON CONFLICT DO UPDATE` on both tables**: Both `inform.politician_answers` and `inform.politician_context` use upsert semantics — safe to re-run migrations.
- **Topic UUID lookup**: Use the reference block in migration 216 — UUIDs are stable and don't need re-querying.

### Integration Points
- `inform.politician_answers` ← stance values per politician per topic
- `inform.politician_context` ← paired context rows with `sources` text array (must have at least 1 non-empty URL)
- `essentials.politicians` ← source of politician IDs (look up by external_id range per city)

</code_context>

<specifics>
## Specific Ideas

- Sacramento is treated as a 5th Phase 78 city even though CSTA-01–05 don't formally cover it. The planner should add Sacramento as an unnumbered wave or note it as "CSTA-04b" — do not create a new formal CSTA requirement, just execute it.
- Fremont is **explicitly excluded** from Phase 78 work — CSTA-04 is already closed and migration 219 is already applied.

</specifics>

<deferred>
## Deferred Ideas

- Sacramento headshots as a formal CITY-0X requirement — not needed; Wave 0 handles this informally.
- Sacramento formal CSTA requirement number — deferred to roadmap update after Phase 78 completes.

</deferred>

---

*Phase: 78-city-stance-research*
*Context gathered: 2026-05-28*
