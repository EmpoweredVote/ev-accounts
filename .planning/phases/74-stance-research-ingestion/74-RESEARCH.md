# Phase 74: Stance Research + Ingestion — Research

**Researched:** 2026-05-19
**Domain:** Politician stance data — research, CSV ingestion, SQL migration into inform schema
**Confidence:** HIGH

---

## Summary

Phase 74 delivers stance data for all 100 US senators across approximately 30 applicable CompassV2
topics, writing rows to `inform.politician_answers` (value) and `inform.politician_context`
(reasoning + sources). The work splits cleanly into research (the `/research-stances` skill) and
ingestion (SQL migrations matching the Phase 73 pattern for senator records).

Four senators already have partial CSV data on disk — Cornyn and Cruz (18-19 topics each), Schiff
(13 topics, 12 applicable), and Padilla (10 topics, 5 applicable). These CSVs have never been
ingested because `inform.politician_answers` is currently empty. The 30-topic federal list has been
determined (23 clearly federal + 7 borderline-but-defensible). The optimal batch structure is 3
plans: existing CSVs + R senators A-La, R senators La-Z + D senators A-Lu, D senators M-Z +
Independents + gap-fill verification.

**Primary recommendation:** Use SQL migrations (not script runs) for ingestion of all stance data.
Research via `/research-stances` with explicit `--topics` override for the 30 federal topics. Three
plans covering ~33-35 senators each is the right granularity for one research session per plan.

---

## Federal Topic List (30 applicable to US Senators)

These are the 30 topics that apply to federal senators. The `/research-stances` skill must be
invoked with `--topics` listing all 30 explicitly, because 7 of them are default-skipped by the
skill for federal/state politicians.

### 23 Clearly Federal (no override needed)

| # | topic_key | topic_id | Federal Rationale |
|---|-----------|----------|-------------------|
| 1 | abortion | af2fdfd6-02c4-49df-b09c-cf8536f4773f | Federal constitutional question, Hyde Amendment |
| 2 | ai-regulation | 666bf03d-81fc-4138-ab15-69ae734c9023 | FTC oversight, NIST AI Safety Institute, federal AI bills |
| 3 | campaign-finance | 92730f69-ae57-401c-8ad1-2d07834a895d | FECA, Citizens United, federal election law |
| 4 | childcare | c1ac1330-47f7-44ec-baf3-c913d926b97c | CCDBG block grant, Child Tax Credit, Head Start |
| 5 | civil-rights | 0bc588c6-39e1-4084-b5de-cac909b8b762 | DOJ Civil Rights Division, federal enforcement |
| 6 | climate-change | f1e44d66-5d27-4b51-b54f-b7ace86f6a3c | EPA, Paris Agreement, IRA clean energy |
| 7 | deportation | 44905f3b-e105-4f6c-afc7-5d223813dbac | DHS/ICE federal enforcement priorities |
| 8 | fossil-fuels | a22215c3-6693-4bc2-b248-01aebba14570 | Federal drilling permits on federal land, EPA |
| 9 | healthcare | e8dad4a8-eb93-4931-91f5-d8fb5d7dd529 | ACA, CHIP, federal health policy |
| 10 | housing | 669cac97-66a6-4087-b036-936fbe62efb3 | HUD, Section 8, LIHTC, federal housing programs |
| 11 | immigration | 4e2c69ce-591e-4197-9cd5-7aceff79d390 | Federal immigration law, pathways to citizenship |
| 12 | medicare/aid | cab61e8a-64fe-4bbd-bc08-fe9914d0091b | Federal Medicare + Medicaid programs |
| 13 | misinformation | ddd65d64-9dc7-4208-a30f-59f4b9c0653d | Federal platform regulation bills, Section 230 |
| 14 | redistricting | 48cc9585-ec22-4f53-8d42-6839828dd36f | For the People Act, federal redistricting rules |
| 15 | religious-freedom | 6b9ba6d9-1001-43f5-b073-4d37130696fd | Federal RFRA, First Amendment |
| 16 | same-sex-marriage | c5ab4eab-702f-49b8-9277-8ea53f3835c6 | Federal Respect for Marriage Act |
| 17 | school-vouchers | 00b95a6a-75db-4521-b523-3326bba938de | Federal Title I, IDEA, federal education funding |
| 18 | social-security | 87d20824-a6e9-407b-983c-65440084a0ab | Federal SSA program |
| 19 | tariffs | 683c8084-2281-4920-a07c-18439b2dd413 | Federal trade policy, USMCA, Section 301 |
| 20 | taxes | f7e5678d-dadd-4556-a2fc-446e24642ceb | Federal tax law, IRS |
| 21 | trans-athletes | d1618b9c-0b9e-45af-b986-bb33d270b8e4 | Federal Title IX rules |
| 22 | ukraine-support | 24e9212c-b011-422a-865c-093e35050901 | Federal foreign aid appropriations |
| 23 | voting-rights | d1792200-1d3b-4955-a0b7-0e6980d7a7b2 | Federal Voting Rights Act, NVRA |

### 7 Borderline Federal (REQUIRE explicit `--topics` override)

The `/research-stances` skill's default guidance says to SKIP these for federal candidates. They
must be listed in `--topics` explicitly because senators vote on federal legislation in these areas.
Confirmed applicable: the Schiff and Padilla CSVs both used these topics successfully.

| # | topic_key | topic_id | Why Include Despite Local Framing |
|---|-----------|----------|----------------------------------|
| 24 | homelessness | 4938766b-b45a-46e3-93bd-b8b30651271a | McKinney-Vento Act, federal housing policy |
| 25 | homelessness-response | 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f | HUD Continuum of Care grants, federal strategy |
| 26 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85 | George Floyd Justice in Policing Act (S.3007), DOJ COPS grants |
| 27 | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53 | CHIPS Act, SBA, EDA, federal industrial policy |
| 28 | jail-capacity | c267e137-0ff9-4e7d-9d13-e3cea1756cd0 | First Step Act, federal prison reform |
| 29 | judicial-criminal-justice | 9db07b16-1076-4b7d-ad89-ebe7b51f4336 | Federal sentencing reform, criminal justice philosophy |
| 30 | judicial-interpretation | 448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee | Senators confirm federal judges; their philosophy matters |

### Topics Skipped (13 local-only or judicial-role only)

- city-sanitation, data-centers, growth-and-development, local-environment, local-immigration,
  rent-regulation, residential-zoning, transportation-priorities — all framed as city-level decisions
- judicial-access-to-justice, judicial-bail-pretrial, judicial-government-deference,
  judicial-police-accountability, judicial-prosecution-priorities, judicial-transparency —
  all framed as questions FOR judges/prosecutors, not legislators

---

## Architecture Patterns

### Recommended Project Structure

```
backend/
├── data/stance-research/
│   ├── 2026-05-18-tx-us-senate.csv        # Cornyn+Cruz (18+19 topics) — NOT yet ingested
│   ├── 2026-05-16-adam-schiff-13-topics.csv  # Schiff (13 topics) — NOT yet ingested
│   ├── 2026-05-16-alex-padilla-topoff.csv    # Padilla (10 topics, 5 applicable) — NOT ingested
│   ├── [plan 74-01 output CSVs]
│   ├── [plan 74-02 output CSVs]
│   └── [plan 74-03 output CSVs]
├── migrations/
│   ├── 177_senator_stances_batch1.sql      # Plan 74-01: existing CSVs + R senators A-La
│   ├── 178_senator_stances_batch2.sql      # Plan 74-02: R senators La-Z + D senators A-Lu
│   └── 179_senator_stances_batch3.sql      # Plan 74-03: D senators M-Z + I + gap-fill
└── scripts/
    ├── csv-to-json.mjs                     # Standard format converter (existing)
    └── push-stances-generic.mjs            # DB push script (existing, for ad-hoc use)
```

### Pattern 1: SQL Migration for Bulk Stance Ingestion

All stance data goes into SQL migrations — same pattern as Phase 73 senator records. Each migration
upserts both `inform.politician_answers` and `inform.politician_context` for every senator in scope.

```sql
-- Source: project pattern (migrations 175, 176)
BEGIN;

-- ============================================================
-- Migration 177: Senator stance data batch 1
-- ============================================================
-- Senators: [list]
-- Topics: 30 federal-applicable topics
-- ============================================================

-- politician_answers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES
  ('cc873a93-cb47-405a-93b0-bb2848fdd57e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4),  -- Murkowski / abortion
  ('cc873a93-cb47-405a-93b0-bb2848fdd57e', '666bf03d-81fc-4138-ab15-69ae734c9023', 3),  -- Murkowski / ai-regulation
  -- ... all rows for all senators in batch ...
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- politician_context
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES
  (
    'cc873a93-cb47-405a-93b0-bb2848fdd57e',
    'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    'Murkowski is one of few Republicans who has supported abortion rights...',
    ARRAY['https://ontheissues.org/...', 'https://en.wikipedia.org/...']
  ),
  -- ...
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

COMMIT;
```

**Key constraint:** `value` column is `NUMERIC(3,1)` with half-step constraint — valid values are
integers 1-5 (half-steps like 3.5 are valid but research rarely produces them; use integers).

### Pattern 2: Research Skill Invocation for Federal Senators

```
/research-stances "Lisa Murkowski, Dan Sullivan, Katie Britt, Tommy Tuberville, ..."
--topics abortion,ai-regulation,campaign-finance,childcare,civil-rights,climate-change,deportation,fossil-fuels,healthcare,housing,immigration,medicare/aid,misinformation,redistricting,religious-freedom,same-sex-marriage,school-vouchers,social-security,tariffs,taxes,trans-athletes,ukraine-support,voting-rights,homelessness,homelessness-response,public-safety-approach,economic-development,jail-capacity,judicial-criminal-justice,judicial-interpretation
```

The `--topics` flag is MANDATORY for senator research. Without it, the skill's default behavior
skips 7 of the 30 federal topics.

The skill dispatches ONE agent at a time (serialized). Budget ~15-20 minutes per senator for a
first-time full-coverage research run. A batch of 25-35 senators = 6-12 hours of research.

### Pattern 3: Existing CSV → SQL Conversion

**TX CSV format** (`politician_id,topic_id,topic_key,value,notes,source_url_1,source_url_2,source_url_3`):

This format has UUIDs already — convert directly to SQL INSERT. Do not use `csv-to-json.mjs`
(which expects `full_name,topic_key,value,reasoning,...`).

```sql
-- Cornyn: abortion (from 2026-05-18-tx-us-senate.csv row 1)
('2b022ce1-6272-40db-9332-015a057ec9f8', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
-- Source URL: https://www.ontheissues.org/Senate/John_Cornyn.htm
```

**Standard CSV format** (`full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3`):

```bash
# Convert to JSON, then generate SQL from JSON
node scripts/csv-to-json.mjs "Adam B. Schiff" 8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032 \
  backend/data/stance-research/2026-05-16-adam-schiff-13-topics.csv \
  /tmp/schiff-stances.json
```

**Padilla CSV format** (`politician_name,topic_key,value,reasoning,sources` — pipe-separated sources):

This format is a one-off. The `sources` column uses `|` as separator instead of three separate
columns. Parse manually or write inline SQL by reading the file. The 5 applicable topics can be
converted by hand (small set).

### Pattern 4: Gap-Fill Verification SQL

Run after all three migrations to confirm coverage:

```sql
-- Check: how many topics does each senator have?
SELECT
  p.full_name,
  COUNT(pa.topic_id) as topic_count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
WHERE c.name = 'U.S. Senate'
GROUP BY p.id, p.full_name
HAVING COUNT(pa.topic_id) < 30
ORDER BY COUNT(pa.topic_id) ASC;

-- Check: senators with zero stances
SELECT p.full_name
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.chambers c ON c.id = o.chamber_id
WHERE c.name = 'U.S. Senate'
AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id)
ORDER BY p.full_name;
```

---

## Batch Strategy: 3-Plan Split

The optimal split balances research volume (~33 senators per plan) and keeps ideologically similar
senators together (research efficiency — shared topics tend to have similar position clusters).

### Plan 74-01 (Migration 177)

**Scope:** Process 4 existing senator CSVs + research 24 new Republican senators

**Existing CSV senators (partial data → complete to 30 topics in this plan):**

| Senator | UUID | CSV File | Topics Have | Topics Need |
|---------|------|----------|-------------|-------------|
| John Cornyn | 2b022ce1-6272-40db-9332-015a057ec9f8 | 2026-05-18-tx-us-senate.csv | 18/30 | 12 more |
| Ted Cruz | a8bda21a-a5ca-4c15-9612-10fad5d5c9d6 | 2026-05-18-tx-us-senate.csv | 19/30 | 11 more |
| Adam B. Schiff | 8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032 | 2026-05-16-adam-schiff-13-topics.csv | 12/30 (1 topic non-federal) | 18 more |
| Alex Padilla | 2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f | 2026-05-16-alex-padilla-topoff.csv | 5/30 (5 of 10 are federal) | 25 more |

Cornyn's 12 missing topics: `ai-regulation, childcare, housing, misinformation, redistricting, homelessness, homelessness-response, public-safety-approach, economic-development, jail-capacity, judicial-interpretation, judicial-criminal-justice`

Cruz's 11 missing topics: `ai-regulation, childcare, housing, misinformation, homelessness, homelessness-response, public-safety-approach, economic-development, jail-capacity, judicial-interpretation, judicial-criminal-justice`

**New research senators (Republican A-La by last name — 24 senators):**

Armstrong (OK), Banks (IN), Barrasso (WY), Blackburn (TN), Boozman (AR), Britt (AL), Budd (NC),
Cassidy (LA), Collins (ME), Cotton (AR), Cramer (ND), Crapo (ID), Curtis (UT), Daines (MT),
Ernst (IA), Fischer (NE), Graham (SC), Grassley (IA), Hagerty (TN), Hawley (MO), Hoeven (ND),
Husted (OH), Hyde-Smith (MS), Johnson (WI)

**Migration 177 tasks:**
1. Convert TX CSV (Cornyn, Cruz — 37 rows already researched) to SQL
2. Convert Schiff CSV (12 applicable rows) to SQL
3. Convert Padilla CSV (5 applicable rows) to SQL
4. Run `/research-stances` for top-off topics: Cornyn (12), Cruz (11), Schiff (18), Padilla (25)
5. Run `/research-stances` for 24 new R senators (full 30 topics each)
6. Assemble migration 177 SQL from all above data

### Plan 74-02 (Migration 178)

**Scope:** Research remaining Republican senators + Democrat senators A-Lu

**Republican senators La-Y (22 senators):**

Kennedy (LA), Lankford (OK), Lee (UT), Marshall (KS), McConnell (KY), McCormick (PA),
Moody (FL), Moran (KS), Moreno (OH), Paul (KY), Ricketts (NE), Risch (ID), Rounds (SD),
Schmitt (MO), Scott Tim (SC), Scott Rick (FL), Sheehy (MT), Thune (SD), Tillis (NC),
Tuberville (AL), Wicker (MS), Young (IN)

**Democrat senators A-Lu (22 senators):**

Alsobrooks (MD), Baldwin (WI), Bennet (CO), Blumenthal (CT), Blunt Rochester (DE), Booker (NJ),
Cantwell (WA), Coons (DE), Cortez Masto (NV), Duckworth (IL), Durbin (IL), Fetterman (PA),
Gallego (AZ), Gillibrand (NY), Hassan (NH), Heinrich (NM), Hickenlooper (CO), Hirono (HI),
Kim (NJ), Kaine (VA), Kelly (AZ), Klobuchar (MN), Luján (NM)

**Migration 178 tasks:**
1. Run `/research-stances` for 22 R senators La-Y
2. Run `/research-stances` for 22 D senators A-Lu
3. Assemble migration 178 SQL (44 senators × ~30 topics = ~1,320 rows)

### Plan 74-03 (Migration 179)

**Scope:** Remaining Democrat + Independent senators + gap-fill verification

**Democrat senators M-Z (22 senators) + 2 Independents:**

Markey (MA), Merkley (OR), Murphy (CT), Ossoff (GA), Peters (MI), Reed (RI), Rosen (NV),
Sanders (VT, I), Schiff (CA) — wait, Schiff done in plan 1, Schumer (NY), Shaheen (NH),
Slotkin (MI), Smith (MN), Van Hollen (MD), Warnock (GA), Warner (VA), Warren (MA),
Welch (VT), Whitehouse (RI), Wyden (OR), King (ME, I), Padilla (CA) — Padilla done in plan 1,
Murray (WA)

**Exact D senators for Plan 3 (after Schiff + Padilla done in Plan 1):**
Markey, Merkley, Murphy, Ossoff, Peters, Reed, Rosen, Schumer, Shaheen, Slotkin, Smith,
Van Hollen, Warnock, Warner, Warren, Welch, Whitehouse, Wyden, Murray — 19 D senators
Plus King (ME, I) and Sanders (VT, I) = 21 senators total

**Gap-fill tasks:**
1. Run `/research-stances` for 21 D+I senators
2. Query DB for any senator with <30 topics, re-run `/research-stances` for missing topics
3. Assemble migration 179 SQL
4. Run verification query to confirm all 100 senators have ≥30 topic rows each

---

## Existing CSV Handling

### Confirmed Existing Senator CSV Files

| File | Senator(s) | Format | Topics | Ingestion Notes |
|------|-----------|--------|--------|-----------------|
| `2026-05-18-tx-us-senate.csv` | Cornyn (18), Cruz (19) | `politician_id,topic_id,topic_key,value,notes,source_url_1,...` | 37 rows total | Direct SQL — UUIDs already present |
| `2026-05-16-adam-schiff-13-topics.csv` | Schiff (13) | `full_name,topic_key,value,reasoning,source_url_1,...` | 13 rows, 12 federal-applicable | Use csv-to-json.mjs or manual SQL |
| `2026-05-16-alex-padilla-topoff.csv` | Padilla (10) | `politician_name,topic_key,value,reasoning,sources` (pipe-separated sources) | 10 rows, 5 federal-applicable | Manual SQL — custom format |

### TX CSV Conversion to SQL

The TX CSV uses `politician_id` and `topic_id` UUIDs directly. Convert each row to:
```sql
-- politician_answers row:
('2b022ce1-...', 'af2fdfd6-...', 5),   -- Cornyn / abortion / value=5
-- politician_context row:
('2b022ce1-...', 'af2fdfd6-...', 'reasoning text', ARRAY['url1', 'url2']),
```

The `notes` column in the TX CSV = `reasoning` in `politician_context`.

### Padilla CSV Conversion

The sources column uses `|` (pipe) separator. Parse by splitting on `|` to produce `ARRAY[...]`.
Only 5 rows are federal-applicable: `public-safety-approach, judicial-criminal-justice,
homelessness-response, economic-development, jail-capacity`. The other 5 (local-immigration,
judicial-police-accountability, transportation-priorities, rent-regulation, local-environment)
are NOT in the federal-30 and should NOT be ingested.

### SSTA-03 Interpretation

The requirement says "8 senators with partial data." The live DB has `inform.politician_answers`
completely empty. The 4 senators with CSV files (Cornyn, Cruz, Schiff, Padilla) are the "partial"
ones — their data exists on disk but is not yet in the DB. The "8" count was likely written
assuming additional CSV files would exist by now, or it overcounts.

**Treat SSTA-03 as:** Ensure these 4 senators reach full 30-topic coverage, with their existing
CSV data as the starting point. The `ON CONFLICT DO UPDATE` in the SQL migrations makes gap-fill
idempotent.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bulk DB writes | Custom Node pipeline | SQL migration with ON CONFLICT | Atomic, auditable, matches Phase 73 pattern |
| Politician ID lookup | Hardcode or guess UUIDs | essentials.politicians UUIDs from technical_context | Already verified |
| Topic ID lookup | Hardcode | topic_id values from compass-topics-reference.md | Already verified |
| Research 100 senators | Scraper | /research-stances skill | Handles WebFetch + approval flow |
| Conflict resolution | None | ON CONFLICT DO UPDATE | Both tables have PK on (politician_id, topic_id) |
| Conversion of TX CSV | csv-to-json.mjs | Direct SQL generation | TX format has UUIDs already; csv-to-json expects full_name format |

---

## Common Pitfalls

### Pitfall 1: Using inform.politicians Instead of essentials.politicians

**What goes wrong:** Inserting senator UUIDs into `politician_answers` that reference `inform.politicians` (only 2 LA politicians from early work) instead of `essentials.politicians` (where all 100 senators live).

**Why it happens:** Migration 026 created `politician_answers` with `REFERENCES inform.politicians(id)` — the code looks like senators should be in `inform.politicians`. But the live DB has NO FK on `politician_answers.politician_id` (confirmed from DB inspection and migration 062 comment: "the real politicians live in essentials.politicians which is what politician_answers.politician_id actually references").

**How to avoid:** Always use UUIDs from `essentials.politicians.id`. The provided senator UUID table in technical_context is correct. Verify with:
```sql
SELECT id, full_name FROM essentials.politicians WHERE full_name = 'Lisa Murkowski';
```

**Warning signs:** Stances insert but CompassV2 cannot find them when joining via politician office queries.

### Pitfall 2: Missing the --topics Override for 7 Borderline Topics

**What goes wrong:** Running `/research-stances` without `--topics` causes the skill to skip `economic-development, homelessness-response, public-safety-approach, jail-capacity, homelessness` for federal senators — leaving 7 of 30 topics unresearched and the coverage gap unfillable without a re-run.

**Why it happens:** The skill's default guidance says "City-level topics to SKIP for state/federal candidates" and lists those topics explicitly.

**How to avoid:** Every `/research-stances` invocation for senators MUST include the full 30-topic `--topics` list. The plan should include the exact `--topics` string to copy-paste.

**Warning signs:** Senators end up with only 23 topics (the clear-federal ones) instead of 30.

### Pitfall 3: value Column Is NUMERIC(3,1) with Half-Step Check

**What goes wrong:** Inserting `value = 3` as an integer works, but the CHECK constraint requires `(value * 2) = round(value * 2)` which means valid values are: 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5. Inserting 0 or 6 fails.

**Why it happens:** Migration 038 changed `value` from `INT` to `NUMERIC(3,1)` and added the half-step constraint.

**How to avoid:** Always use integer values 1-5 from research. The half-step values (1.5, 2.5 etc.) are valid but should only appear if research genuinely finds an in-between position.

**Warning signs:** `ERROR: new row for relation "politician_answers" violates check constraint "politician_answers_value_half_step"`.

### Pitfall 4: SQL Migrations Become Extremely Large

**What goes wrong:** 100 senators × 30 topics × 2 tables = 6,000 INSERT rows split across 3 migrations (~2,000 rows each). Each migration becomes a large file. Postgres handles this fine but editing is painful.

**Why it happens:** Stance data includes reasoning text (often 150-300 characters) and source arrays (2-3 URLs each). Each `politician_context` row is ~500 bytes of text.

**How to avoid:** Use the `VALUES (row1), (row2), ...` multi-row INSERT format (not individual INSERTs per row). Keep one migration file per plan. Validate row counts before applying.

**Warning signs:** File exceeds 1MB — still fine but check carefully.

### Pitfall 5: Schiff CSV Topic `transportation-priorities` Is Not in Federal-30

**What goes wrong:** Schiff's CSV includes `transportation-priorities` (the question asks "where should your city focus transportation investment" — local framing). If ingested as-is, the senator gets 1 non-applicable topic counting toward their 30.

**How to avoid:** When converting Schiff CSV, skip the `transportation-priorities` row. Schiff has 13 CSV topics → 12 applicable (all except transportation). He needs 18 more from new research.

### Pitfall 6: Padilla CSV Sources Are Pipe-Separated

**What goes wrong:** The Padilla topoff CSV uses a single `sources` column with pipe (`|`) separator instead of three separate `source_url_1, source_url_2, source_url_3` columns. Running `csv-to-json.mjs` on it produces wrong output (reads row[4], row[5], row[6] as separate fields, getting wrong columns).

**How to avoid:** Convert Padilla's 5 applicable rows to SQL manually. Parse the `sources` column by splitting on `|`.

---

## Code Examples

### Research Skill Invocation for Federal Senators

```bash
# Full 30-topic list for senator research — copy this exactly into skill invocation
# --topics must be comma-separated, no spaces
/research-stances "Lisa Murkowski, Dan Sullivan, Katie Britt, Tommy Tuberville, John Boozman, Tom Cotton, Ashley Moody, Rick Scott, Joni Ernst, Chuck Grassley, Mike Crapo, James Risch, Jim Banks, Todd Young, Roger Marshall, Jerry Moran, Mitch McConnell, Rand Paul, Bill Cassidy, John Kennedy, Susan M. Collins, Ron Johnson, Josh Hawley, Eric Schmitt" --topics abortion,ai-regulation,campaign-finance,childcare,civil-rights,climate-change,deportation,fossil-fuels,healthcare,housing,immigration,medicare/aid,misinformation,redistricting,religious-freedom,same-sex-marriage,school-vouchers,social-security,tariffs,taxes,trans-athletes,ukraine-support,voting-rights,homelessness,homelessness-response,public-safety-approach,economic-development,jail-capacity,judicial-criminal-justice,judicial-interpretation
```

### SQL Migration Structure

```sql
BEGIN;

-- ============================================================
-- Migration 177: Senator stance data — batch 1
-- Senators: [list]
-- Sourced: existing CSVs + /research-stances output YYYY-MM-DD
-- ============================================================

-- SECTION A: politician_answers
-- (all 30 topics × N senators = ~N×30 rows)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES
  -- Cornyn (John Cornyn — 2b022ce1-6272-40db-9332-015a057ec9f8)
  ('2b022ce1-6272-40db-9332-015a057ec9f8', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5),  -- abortion
  ('2b022ce1-6272-40db-9332-015a057ec9f8', '92730f69-ae57-401c-8ad1-2d07834a895d', 4),  -- campaign-finance
  -- ... all 30 topics for Cornyn ...
  -- Cruz (Ted Cruz — a8bda21a-a5ca-4c15-9612-10fad5d5c9d6)
  ('a8bda21a-a5ca-4c15-9612-10fad5d5c9d6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 4),  -- abortion
  -- ... all 30 topics for Cruz ...
  -- [continue for all senators in batch]
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET value = EXCLUDED.value;

-- SECTION B: politician_context
-- (same N×30 rows with reasoning + sources)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES
  (
    '2b022ce1-6272-40db-9332-015a057ec9f8',  -- Cornyn
    'af2fdfd6-02c4-49df-b09c-cf8536f4773f',  -- abortion
    'Cornyn is strongly anti-abortion with a 100% NRLC rating...',
    ARRAY['https://www.ontheissues.org/Senate/John_Cornyn.htm', 'https://en.wikipedia.org/wiki/John_Cornyn']
  ),
  -- ...
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

COMMIT;
```

### Verification Query

```sql
-- Run after each migration to confirm coverage
SELECT
  p.full_name,
  p.party,
  COUNT(pa.topic_id) AS topics_covered,
  30 - COUNT(pa.topic_id) AS topics_missing
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
WHERE c.name = 'U.S. Senate'
GROUP BY p.id, p.full_name, p.party
ORDER BY COUNT(pa.topic_id) ASC, p.full_name;

-- Expected after all 3 migrations:
-- All 100 rows showing topics_covered = 30, topics_missing = 0
```

### TX CSV to SQL Helper Logic

```javascript
// Node one-liner to preview TX CSV as SQL fragments
// Run in backend/ directory
import { readFileSync } from 'fs';
const csv = readFileSync('data/stance-research/2026-05-18-tx-us-senate.csv', 'utf8');
const rows = csv.split('\n').filter(l => l.trim() && !l.startsWith('politician_id'));
for (const row of rows) {
  const [politicianId, topicId, topicKey, value, notes, url1, url2] = row.split(',');
  const sources = [url1, url2].filter(Boolean).map(u => u.trim()).filter(u => u.startsWith('http'));
  console.log(`  ('${politicianId}', '${topicId}', ${value}),  -- ${topicKey}`);
}
```

---

## Senator UUID Quick Reference

For SQL migration authoring, senators are organized by plan batch below. Full UUID table is in
technical_context. Key UUIDs for existing CSV senators:

| Senator | UUID |
|---------|------|
| John Cornyn (TX-R) | 2b022ce1-6272-40db-9332-015a057ec9f8 |
| Ted Cruz (TX-R) | a8bda21a-a5ca-4c15-9612-10fad5d5c9d6 |
| Adam B. Schiff (CA-D) | 8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032 |
| Alex Padilla (CA-D) | 2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f |

All other senator UUIDs: see the senator table in `technical_context` above (100 senators, all verified in Phase 73).

---

## Open Questions

1. **SSTA-03 "8 senators" count**
   - What we know: Only 4 senators have existing CSV files (Cornyn, Cruz, Schiff, Padilla)
   - What's unclear: Whether the requirement anticipated 4 more CSVs would exist, or miscounted
   - Recommendation: Treat as 4. The gap-fill step in Plan 74-03 covers any partially-covered senators regardless.

2. **Research agent rate limits / session time**
   - What we know: The skill serializes agents (one at a time). Prior batches show dozens of politicians per session (2026-05-16 had 20+ CSVs in one day).
   - What's unclear: Whether 35 senators × 30 topics in one session is practical without timeout.
   - Recommendation: If a plan's research batch times out mid-run, break it into two skill invocations (A-L then M-Z) and merge CSVs before generating the migration SQL.

3. **Half-steps in research output**
   - What we know: `value` is NUMERIC(3,1). Some politicians may have genuine middle-ground positions.
   - What's unclear: Whether research agents ever output half-steps (1.5, 2.5, etc.) or always integers.
   - Recommendation: Accept whatever the research agent outputs if it passes the half-step constraint. Don't force integers.

---

## Sources

### Primary (HIGH confidence)

- Live DB inspection via technical_context — schema for `inform.politician_answers` (no FK, PK on politician_id+topic_id, NUMERIC value)
- `backend/migrations/026_inform_schema_repair_and_candidates.sql` — original table creation
- `backend/migrations/038_compass_additions.sql` — NUMERIC value column change
- `backend/migrations/062_topic_rewrite_fixups.sql` — confirms "real politicians live in essentials.politicians"
- `backend/scripts/csv-to-json.mjs` — standard CSV format definition and TOPIC_IDS map
- `backend/scripts/push-stances-generic.mjs` — upsert pattern, confirms ON CONFLICT keys
- `.claude/skills/research-stances/SKILL.md` — skill invocation pattern, --topics override, serial dispatch rule
- `backend/data/stance-research/compass-topics-reference.md` — all 43 topic definitions with IDs
- `backend/data/stance-research/2026-05-18-tx-us-senate.csv` — TX senator CSV format (37 rows)
- `backend/data/stance-research/2026-05-16-adam-schiff-13-topics.csv` — Schiff CSV (13 topics)
- `backend/data/stance-research/2026-05-16-alex-padilla-topoff.csv` — Padilla CSV (10 topics, pipe-sep)
- `backend/migrations/175_us_senators_ak_mo.sql`, `176_us_senators_mt_wy.sql` — Phase 73 migration pattern

---

## Metadata

**Confidence breakdown:**
- Federal topic list (30): HIGH — cross-verified against topic definitions, existing CSV practice, and skill guidance
- Batch strategy: HIGH — derived from actual senator counts (100), party breakdown (53R/45D/2I), and practical skill constraints
- Ingestion approach (SQL migrations): HIGH — matches Phase 73 pattern, confirmed by project convention
- Schema details (no FK, NUMERIC value): HIGH — from live DB inspection in technical_context
- Existing CSV coverage gaps: HIGH — computed from actual CSV content vs. federal-30 list
- SSTA-03 "8 senators" interpretation: MEDIUM — 4 confirmed, 4 ambiguous; gap-fill step handles either case

**Research date:** 2026-05-19
**Valid until:** 2026-06-19 (stable reference data; senator list changes only on election/death/appointment)
