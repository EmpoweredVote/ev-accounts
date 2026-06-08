# Phase 106: DC Stance Research - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 106 researches and records sourced stances for all 27 DC officials seeded in Phase 105. Output is `inform.politician_answers` + `inform.politician_context` rows in SQL migrations. Three requirement groups map to three plans: Mayor/Council/AG (DCST-01), SBOE (DCST-02), Shadow Senators + EHN gap-fill (DCST-03).

No new schema changes. No API changes. Depends entirely on politician + district records created in Phase 105.

**Requirements in scope:** DCST-01, DCST-02, DCST-03
**Out of scope:** DC finance (Phase 107), geofencing updates, Elections Central.

</domain>

<decisions>
## Implementation Decisions

### Plan Structure

- **D-01:** 3 plans, one per requirement group:
  - **106-01** — Mayor Bowser + 13 DC Council members + AG Schwalb (DCST-01), 15 politicians
  - **106-02** — 9 DC SBOE members (DCST-02)
  - **106-03** — Shadow Senators (Paul Strauss, Ankit Jain) + EHN gap-fill (DCST-03)
- **D-03:** Execution order within each plan: research ALL politicians in the batch first (sequentially, one stance agent at a time per rate-limit rule), then write all migrations in a single executor pass.

### Topic Scope

- **D-04:** All 44 live compass topics are in scope for ALL politicians — Mayor, Council, AG, SBOE, and Shadow Senators. The 8 topics listed in DCST-01 are a required minimum, not a ceiling.
- **D-05:** Same topic scope for all 15 Plan 1 politicians — no differentiation by seniority or role.
- **D-06:** Every stance entry MUST have at least one real fetched URL in `politician_context`. Nothing inferred from party affiliation or directional assumption. Skip > infer for any topic without real evidence.

### SBOE Depth Floor

- **D-07:** SBOE members already have politician records in the DB (Phase 105). If a researcher finds zero documentable stances for a given SBOE member, write no migration for that politician — the politician row remains with no stances. A blank stance profile is acceptable and honest; do NOT invent stances to fill the gap.

### EHN + Shadow Senator Handling

- **D-08:** EHN is a gap-fill, not a full re-research. Plan 3 executor must first query her existing `inform.politician_answers` + `inform.politician_context` rows, then research only the topic_keys that are missing or have no `politician_context` source URL. Do not overwrite existing sourced stances.
- **D-09:** Paul Strauss and Ankit Jain (Shadow Senators) get the full 44-topic research pass. They are likely low-coverage (few documented positions) — that's fine. Skip any topic without real evidence.

### Research Agent Rules (carry-forward from prior phases)

- **D-10:** One stance researcher agent at a time. Never parallel. Running parallel agents burns the WebSearch/Playwright rate-limit quota, producing no usable output.
- **D-11:** Five-chairs framing — each value (1–5) is a named chair with distinct substantive text. Match documented positions to the exact stance text; do NOT assign based on party expectation or directional assumption.
- **D-12:** Full live topic JSON (id, topic_key, question_text, stances with value+text) must be fetched fresh from the DB and embedded in every agent prompt. Never hardcode the topic list.

### Claude's Discretion

- Migration file granularity: Plans produce one migration file per plan (batch pattern: 289, 290, 291), not one per politician. This matches all prior phases (103, 104, 279) and is strictly more reliable (atomic, less migration clutter). Original D-02 sketch specified per-politician files; batch is the correct implementation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements + Roadmap
- `.planning/REQUIREMENTS.md` — DCST-01/02/03 exact requirement text and out-of-scope list
- `.planning/ROADMAP.md` §Phase 106 — goal, depends-on, requirements list

### Stance Research Pattern
- `.claude/skills/research-stances/SKILL.md` — orchestration pattern: topic resolution query, agent dispatch rules (one at a time), FIVE-CHAIRS framing, CSV format, migration write pattern. MUST read before planning.

### DC Politician Records (for FK lookups by executor)
- `supabase/migrations/20260607000004_286_dc_official_records_council_mayor.sql` — Mayor Bowser (-600001) + 13 Council members (-600002 to -600014); office district_id FKs
- `supabase/migrations/20260607000005_287_dc_official_records_ag_shadow_ehn.sql` — AG Schwalb (-600015), Paul Strauss (-600016), Ankit Jain (-600017), EHN (-600030)
- `supabase/migrations/20260607000006_288_dc_official_records_sboe.sql` — SBOE members (-600019 to -600027): Patterson (at-large), Williams–Johnson-Law (Ward 1–8)

### Prior Stance Phase Patterns
- `.planning/phases/105-dc-infrastructure-official-records/105-CONTEXT.md` — D-12 external ID ranges; all 27 politician records confirmed complete with photo_origin_url
- `supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql` — most recent stance migration pattern (city official stance upserts with politician_context source rows)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.claude/skills/research-stances/SKILL.md` — complete orchestration workflow; handles topic resolution, agent dispatch, CSV collection, migration generation
- `supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql` — stance upsert pattern: `INSERT INTO inform.politician_answers ... ON CONFLICT (politician_id, topic_id) DO UPDATE` + matching `inform.politician_context` INSERT

### Established Patterns
- **`ON CONFLICT (politician_id, topic_id) DO UPDATE`** on `inform.politician_answers` — idempotent stance upserts, safe to re-run
- **`politician_context` row per stance** — each stance entry needs a matching `politician_context` row with `sources TEXT[]` containing at least one real URL
- **EHN pre-flight query** — before writing 106-03, executor must run: `SELECT pa.topic_id, t.topic_key, pc.sources FROM inform.politician_answers pa JOIN inform.compass_topics t ON t.id = pa.topic_id LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id WHERE pa.politician_id = (SELECT id FROM essentials.politicians WHERE full_name ILIKE '%Eleanor%Norton%')`

### Integration Points
- `inform.politician_answers` → FK to `inform.compass_topics.id` and `essentials.politicians.id`
- `inform.politician_context` → paired with `politician_answers`; `sources TEXT[]` column holds URLs
- Politician IDs resolved at runtime via `external_id` — never hardcode UUIDs in migrations

</code_context>

<specifics>
## Specific Ideas

- **EHN external_id = -600030** — verified in Phase 105 (bioguide_id = 'N000147' also on record). Use this for FK resolution in 106-03 migration.
- **SBOE at-large member = Jacque Patterson (-600019)** → `dc-sboe-at-large` district; Ward 1–8 SBOE members are -600020 to -600027.
- **Topic count note**: As of 2026-06-02, there are 44 live topics. Fetch live from DB — this number grows.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope.

</deferred>

---

*Phase: 106-DC Stance Research*
*Context gathered: 2026-06-07*
