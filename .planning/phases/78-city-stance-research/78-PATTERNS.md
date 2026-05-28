# Phase 78: City Stance Research - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 6 (4 city stance migrations + 1 headshot migration + 1 context audit query)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `backend/migrations/NNN_sj_stances.sql` | migration | batch (upsert) | `backend/migrations/219_fremont_officials_stances.sql` | exact |
| `backend/migrations/NNN_sd_stances.sql` | migration | batch (upsert) | `backend/migrations/216_sf_officials_stances.sql` | exact |
| `backend/migrations/NNN_berkeley_stances.sql` | migration | batch (upsert) | `backend/migrations/219_fremont_officials_stances.sql` | exact |
| `backend/migrations/NNN_sacramento_stances.sql` | migration | batch (upsert) | `backend/migrations/219_fremont_officials_stances.sql` | exact |
| `backend/migrations/NNN_sac_headshots.sql` | migration | batch (upsert) | `backend/migrations/sac_headshots.sql` | exact (verbatim copy + number) |
| CSTA-05 context audit (inline SQL, no file) | verification query | batch (read) | `backend/.planning/phases/74-stance-research-ingestion/74-03-PLAN.md` lines 503-520 | role-match |

**Migration numbering:** D-08 requires planner to check the live DB migration table at plan time. Last confirmed applied: 220. Do not pre-assign numbers here.

**Wave 0 note:** `sac_headshots.sql` header states it was "already applied via Supabase MCP on 2026-05-28". The planner must verify this before assigning Wave 0 — if already applied, Wave 0 becomes a no-op verification step only.

---

## Pattern Assignments

### City Stance Migration Files (all 4 cities share one pattern)

**Primary analog:** `backend/migrations/219_fremont_officials_stances.sql` (smaller cities: SJ 11 officials, Berkeley 10, Sacramento 9)
**Secondary analog:** `backend/migrations/216_sf_officials_stances.sql` (larger city: SD 11 officials)

---

#### Migration Header Pattern

Source: `backend/migrations/219_fremont_officials_stances.sql` lines 1-13

```sql
-- ============================================================================
-- Migration NNN: [City] Officials Stances — [N] Politicians
-- ============================================================================
-- Purpose: Insert/upsert stance data for [N] [City] city officials.
--
-- Politicians: [Name] ([Role]), [Name] ([Role]), ...
--
-- Stance count: [N] rows (politician_answers + politician_context)
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================
```

---

#### Topic UUID Reference Block (complete — 42 applicable topics)

Source: `backend/migrations/216_sf_officials_stances.sql` lines 14-57

**EXCLUDED for city officials:** `data-centers` (`4559b513-0fd8-4ed1-babd-f3b554162f40`) — never include in city stance migrations per D-06 and established convention.

```sql
-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial           1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities  abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2
-- [data-centers EXCLUDED — not applicable to city officials]
```

---

#### Politician UUID Reference Block (per-city section)

Source: `backend/migrations/219_fremont_officials_stances.sql` lines 31-38

Lookup pattern — planner must query the live DB by `external_id` range for each city to get UUIDs. Copy into each migration file as a comment block:

```sql
-- Politician UUID reference (essentials.politicians):
-- [Full Name]    [UUID from SELECT id FROM essentials.politicians WHERE external_id = N]
-- ...
```

**External ID ranges per city (from city official seed migrations):**

| City | Migration | ID Range | Officials |
|------|-----------|----------|-----------|
| San Jose | 218 | -640001 (Mayor Matt Mahan), -640010 to -640019 (D1–D10 council) | 11 |
| San Diego | 208 | -650001 (Mayor), -650002 (City Attorney), -650010 to -650018 (D1–D9 council) | 11 |
| Berkeley | 214 | -680001 (Mayor), -680002 (City Auditor), -680010 to -680017 (D1–D8 council) | 10 |
| Sacramento | 220 | -660001 (Mayor Kevin McCarty), -660010 to -660017 (D1–D8 council) | 9 |

**DB lookup to run before each city migration:**

```sql
SELECT id, full_name, external_id
FROM essentials.politicians
WHERE external_id BETWEEN [low] AND [high]
ORDER BY external_id;
```

---

#### Core INSERT/ON CONFLICT Pattern (per stance)

Source: `backend/migrations/219_fremont_officials_stances.sql` lines 47-55

Two consecutive INSERTs per stance — one for `politician_answers`, one for `politician_context`. Never batch into VALUES tuples; keep one INSERT per table per (politician, topic) pair.

```sql
-- ----- [Full Name] / [topic_key] -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('[politician_uuid]', '[topic_uuid]', [1.0-5.0])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('[politician_uuid]', '[topic_uuid]',
$$[Reasoning text — multi-sentence, evidence-based, sourced. No fabrication. "No evidence" documented explicitly.]$$,
ARRAY['[url1]', '[url2]']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
```

Key conventions from analogs:
- `value` is a float literal (e.g., `4.0`, `2.0`) — never an integer bare
- Reasoning uses `$$dollar-quoted strings$$` — never single-quoted (avoids escaping)
- `sources` is `ARRAY[...]::text[]` — at least 1 non-empty URL required per context row
- Both ON CONFLICT clauses are required — `politician_answers` updates `value`; `politician_context` updates `reasoning, sources`
- Migration 219 style: inline (no newline between VALUES and ON CONFLICT). Migration 216 style: newline-separated. Either is acceptable — use 219 style for consistency.

---

#### Per-Official Section Header

Source: `backend/migrations/219_fremont_officials_stances.sql` lines 42-44

```sql
-- ============================================================
-- [Full Name] ([Role, e.g. Mayor / District N])
-- ============================================================
```

---

#### Transaction Wrapper

Source: `backend/migrations/219_fremont_officials_stances.sql` lines 40 and 686

```sql
BEGIN;

[all inserts]

COMMIT;
```

No DO $$ assertion block needed in city stance migrations (that pattern is for Phase 74 senator success-criteria enforcement). City migrations use simple BEGIN/COMMIT.

---

### Sacramento Headshots Migration (Wave 0)

**Analog:** `backend/migrations/sac_headshots.sql` (the unnumbered source file)

**Critical note:** The `sac_headshots.sql` file header reads:
```
-- AUDIT ONLY — already applied via Supabase MCP on 2026-05-28
-- Do NOT apply via migration ledger.
```

This means the headshot data is already live in the DB. Wave 0 is a verification step — confirm `essentials.politician_images` has 9 rows for Sacramento politician UUIDs. If confirmed, Wave 0 is closed and no new migration file needs to be written for headshots.

**Pattern to verify (if needed):**

```sql
SELECT COUNT(*)
FROM essentials.politician_images
WHERE politician_id IN (
  SELECT id FROM essentials.politicians
  WHERE external_id BETWEEN -660017 AND -660001
);
-- Expect: 9
```

If 0 rows returned, the headshots were NOT applied and the planner must assign a migration number and apply `sac_headshots.sql` verbatim (removing the "AUDIT ONLY" header comment).

**INSERT pattern from sac_headshots.sql:**

```sql
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
VALUES
  (gen_random_uuid(), '[politician_uuid]',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/[politician_uuid]-headshot.jpg',
   'default', 'public_domain'),
  [...]
ON CONFLICT DO NOTHING;
```

---

### CSTA-05: Context Audit Query (Wave 5, no new file)

**Analog:** `backend/.planning/phases/74-stance-research-ingestion/74-03-PLAN.md` lines 503-520

This is a read-only diagnostic query run inline after all 4 city stance migrations are applied. No migration file is created. Adapted for city officials (district_type = 'LOCAL' or 'LOCAL_EXEC') rather than senators (district_type = 'NATIONAL_UPPER').

```sql
-- Orphan answers: politician_answers with no paired politician_context row
-- Scope: all 4 new cities (SJ + SD + Berkeley + Sacramento)
SELECT pa.politician_id, p.full_name, t.topic_key
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
JOIN inform.compass_topics t ON t.id = pa.topic_id
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE p.external_id IN (
  -- San Jose: -640001, -640010 to -640019
  -- San Diego: -650001, -650002, -650010 to -650018
  -- Berkeley: -680001, -680002, -680010 to -680017
  -- Sacramento: -660001, -660010 to -660017
  SELECT external_id FROM essentials.politicians
  WHERE (external_id BETWEEN -640019 AND -640001)
     OR (external_id BETWEEN -650018 AND -650001)
     OR (external_id BETWEEN -680017 AND -680001)
     OR (external_id BETWEEN -660017 AND -660001)
)
AND pc.id IS NULL;
-- Expect: 0 rows
```

Secondary audit — context rows with empty/null sources:

```sql
SELECT pa.politician_id, p.full_name, t.topic_key
FROM inform.politician_context pc
JOIN essentials.politicians p ON p.id = pc.politician_id
JOIN inform.compass_topics t ON t.id = pc.topic_id
WHERE p.external_id IN (
  SELECT external_id FROM essentials.politicians
  WHERE (external_id BETWEEN -640019 AND -640001)
     OR (external_id BETWEEN -650018 AND -650001)
     OR (external_id BETWEEN -680017 AND -680001)
     OR (external_id BETWEEN -660017 AND -660001)
)
AND (pc.sources IS NULL OR array_length(pc.sources, 1) = 0 OR pc.sources = '{}');
-- Expect: 0 rows
```

---

## Shared Patterns

### data-centers Exclusion
**Source:** `backend/migrations/216_sf_officials_stances.sql` header + `backend/migrations/219_fremont_officials_stances.sql` (Fremont includes data-centers for Raj Salwan — this is anomalous; the canonical city exclusion is from migration 216)
**Apply to:** All 4 city stance migrations
**Rule:** Never insert a `politician_answers` or `politician_context` row for topic UUID `4559b513-0fd8-4ed1-babd-f3b554162f40` in city-level migrations. Document the exclusion in the migration header: `-- Topic scope: 42 topics (all except data-centers)`

### party = NULL Constraint
**Source:** All city official seed migrations (208, 214, 218, 220)
**Apply to:** All research agents — researchers must not infer or assign party affiliations. City politicians are antipartisan in this system.

### Minimum 5 Stances Floor (D-07)
**Source:** CONTEXT.md §Research Execution D-07
**Apply to:** All research agents for all 4 cities
**Rule:** No city council member's batch is considered complete with fewer than 5 researched stances, regardless of public record availability.

### "No evidence" Documentation
**Source:** `backend/migrations/219_fremont_officials_stances.sql` — multiple context rows (e.g., Raj Salwan / residential-zoning, local-environment): reasoning explicitly states "No direct vote record is accessible" or "No evidence of..." and proceeds with inference from adjacent evidence.
**Apply to:** All 4 city stance migrations
**Rule:** Never silently skip a topic. If no direct evidence, write the reasoning as "No direct evidence found; based on [adjacent context]..." and include whatever adjacent source URLs exist.

### One-at-a-Time Research Dispatch (D-05)
**Source:** CONTEXT.md §Research Execution D-05 + research-stances SKILL.md line 78-81
**Apply to:** All research agents across all waves
**Rule:** "Always dispatch ONE agent at a time. Never run agents in parallel." Wait for each city's CSV output, review, then approve and generate migration before starting the next city.

---

## Politician Name Roster (for research agent prompts)

| City | Officials |
|------|-----------|
| **San Jose** (external_ids -640001, -640010 to -640019) | Matt Mahan (Mayor), Rosemary Kamei (D1), Pamela Campos (D2), Anthony Tordillos (D3), David Cohen (D4), Peter Ortiz (D5), Michael Mulcahy (D6), Bien Doan (D7), Domingo Candelas (D8), Pam Foley (D9), George Casey (D10) |
| **San Diego** (external_ids -650001, -650002, -650010 to -650018) | Todd Gloria (Mayor), Mara Elliott (City Attorney), Joe LaCava (D1), Jennifer Campbell (D2), Stephen Whitburn (D3), Henry Foster III (D4), Marni von Wilpert (D5), Kent Lee (D6), Raul Campillo (D7), Vivian Moreno (D8), Sean Elo-Rivera (D9) |
| **Berkeley** (external_ids -680001, -680002, -680010 to -680017) | Jesse Arreguin (Mayor), Jenny Wong (City Auditor), Rashi Kesarwani (D1), Terry Taplin (D2), Ben Bartlett (D3), Kate Harrison (D4), Cecilia Lunaparra (D5), Susan Wengraf (D6), Rigel Robinson (D7), Sophie Hahn (D8) |
| **Sacramento** (external_ids -660001, -660010 to -660017) | Kevin McCarty (Mayor), Lisa Kaplan (D1), Roger Dickinson (D2), Karina Talamantes (D3), Phil Pluckebaum (D4), Caity Maple (D5), Eric Guerra (D6), Rick Jennings II (D7), Mai Vang (D8) |

*Names from city official seed migrations 218 (SJ), 208 (SD), 214 (Berkeley), 220 (Sacramento). San Diego D3–D9 names confirmed from migration 208 comments — planner should verify current incumbents before dispatch.*

---

## No Analog Found

All files have close analogs. No gaps.

## Metadata

**Analog search scope:** `backend/migrations/` (migrations 208, 214, 216, 218, 219, 220, sac_headshots.sql), `.claude/skills/research-stances/SKILL.md`, `.planning/phases/74-stance-research-ingestion/74-03-PLAN.md`
**Files scanned:** 9
**Pattern extraction date:** 2026-05-28
