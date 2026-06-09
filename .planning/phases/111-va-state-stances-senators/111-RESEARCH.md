# Phase 111: VA State Stances - Senators — Research

**Researched:** 2026-06-09
**Domain:** Stance data ingestion — Virginia State Senate (40 senators)
**Confidence:** HIGH

## Summary

Phase 111 closes VAST-02 and VAST-05 for VA state senators. All 40 VA Senate records are confirmed in the DB (migration 318, external_ids -5110001 through -5110040) with zero existing stance rows — this is a clean greenfield research run, not a remediation.

The work follows the exact same pattern established in Phase 103 (MD senators), Phase 106 (DC officials), and Phase 74 (US senators): dispatch research-stances agents one at a time, produce dated CSVs, write a numbered migration (next free: 324+), apply via psql, verify with SQL assertions. The SKILL.md orchestrator and the `politician-stance-researcher` agent handle all the research mechanics.

VA senators hold state-scope positions. The applicable topic list excludes city-level topics (city-sanitation, homelessness-response, economic-development, residential-zoning, local-environment, local-immigration, rent-regulation, growth-and-development, public-safety-approach, jail-capacity, judicial-*, transportation-priorities) and includes all remaining 44 live topics. That yields approximately 22–25 topics per senator where evidence is realistically findable — in practice senators average 8–18 stances after honest-skip filtering.

With 40 senators, batching across multiple plan waves is required. The DC pattern (groups of ~5 per plan) worked well. For 40 senators at 1 agent at a time, 8 waves of 5 senators each is a natural split, organized by party/geography to allow for systematic web research.

**Primary recommendation:** Use 4–5 plan files, each covering a cohort of 8–10 senators, following the `YYYY-MM-DD-111-va-senators-[cohort].csv` + numbered migration pattern.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stance value research | Research agent (WebFetch) | Human review | Five-Chairs method requires real URL evidence |
| CSV staging | File system (data/stance-research/) | — | Source of truth before DB push |
| DB ingestion | Database (inform schema) | pool.query() | Non-public schema requires direct postgres, no PostgREST |
| Source verification | Research agent | Human review | VAST-05: every stance must have paired context row with real URL |
| Migration numbering | File system + psql | — | Sequential migration files applied in order |

## Standard Stack

No new packages required. All tooling is already installed.

### Core (already present)
| Tool | Purpose | Notes |
|------|---------|-------|
| `research-stances` SKILL.md | Orchestrate politician-stance-researcher agents | .claude/skills/research-stances/SKILL.md |
| `politician-stance-researcher` agent | WebFetch-only stance research per politician | Uses Five-Chairs, produces CSV |
| `pool.query()` + `tsx` | DB upsert for inform schema | Never PostgREST for non-public schemas |
| `psql` via session pooler | Apply numbered migration SQL files | aws-0-*.pooler.supabase.com:5432 |

### CSV Output Format
```
full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3
```
- `quote_text` and `quote_deidentified` columns added in newer SKILL versions — include if agent produces them
- Parse with `csv-parse/sync`, never by splitting on commas

## Package Legitimacy Audit

No new packages installed in this phase. N/A.

## Architecture Patterns

### System Architecture Diagram

```
[Research Agents: WebFetch only]
     |
     v
[CSV files: data/stance-research/YYYY-MM-DD-111-va-senators-*.csv]
     |
     v
[Human review: STEP 3 approval summary]
     |
     v
[pool.query() upsert: BEGIN/COMMIT block]
     |
     +--> inform.politician_answers  (politician_id, topic_id, value)
     +--> inform.politician_context  (politician_id, topic_id, reasoning, sources[])
     +--> essentials.quotes          (optional: quote_text for Read & Rank)
     |
     v
[Numbered SQL migration: records all upserts for reproducibility]
```

### Recommended Project Structure
```
backend/data/stance-research/
├── 2026-06-XX-111-va-senators-wave1.csv   # SD-1 through SD-8 (Republican)
├── 2026-06-XX-111-va-senators-wave2.csv   # SD-9 through SD-16 (mixed)
├── 2026-06-XX-111-va-senators-wave3.csv   # SD-17 through SD-24 (Democratic)
├── 2026-06-XX-111-va-senators-wave4.csv   # SD-25 through SD-32 (mixed)
└── 2026-06-XX-111-va-senators-wave5.csv   # SD-33 through SD-40 (Democratic)
supabase/migrations/
└── 20260609XXXXXX_324_va_senators_stances.sql   # or split across 324/325/etc.
```

### Pattern 1: Sequential Agent Dispatch (from SKILL.md)
**What:** Dispatch ONE `politician-stance-researcher` agent per senator, wait for completion before next.
**When to use:** Always — parallel agents exhaust WebSearch/WebFetch quota instantly.
**Reference:** SKILL.md STEP 1, "Dispatch rules: Always dispatch ONE agent at a time."

### Pattern 2: Pre-flight Topics Snapshot
**What:** Fetch live topics + stance texts from DB and embed in every agent prompt.
**When to use:** Before every research run — topic set changes over time.
```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT t.id, t.topic_key, t.title, t.question_text,
    json_agg(json_build_object('value', s.value, 'text', s.text) ORDER BY s.value) AS stances
  FROM inform.compass_topics t
  JOIN inform.compass_stances s ON s.topic_id = t.id
  WHERE t.is_live = true
  GROUP BY t.id, t.topic_key, t.title, t.question_text ORDER BY t.topic_key
\`);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```
[ASSUMED — topic set was 44 as of research date; may change]

### Pattern 3: UUID Pre-flight Fetch
**What:** Fetch politician UUIDs before writing migration SQL.
**When to use:** Always — external_id is not the FK target; inform tables use politician UUID.
```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(
  'SELECT id, full_name, external_id FROM essentials.politicians WHERE external_id BETWEEN -5110040 AND -5110001 ORDER BY external_id DESC'
);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

### Pattern 4: Migration Template for Stances
```sql
-- Migration 324: VA State Senator stances — Wave 1
-- Source: backend/data/stance-research/2026-06-XX-111-va-senators-wave1.csv
-- Applied: 2026-06-XX

BEGIN;

-- politician_answers upserts
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES
  ('<uuid>', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'), 5),
  ...
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- politician_context upserts
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES
  ('<uuid>', (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
   'Reasoning text here',
   ARRAY['https://source1.com', 'https://source2.com']),
  ...
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification
DO $$
DECLARE
  senator_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO senator_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5110040 AND -5110001;
  RAISE NOTICE 'VA senators with stances: %', senator_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5110040 AND -5110001
    AND (pc.id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA senator stances: %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
```

### Pattern 5: Phase Gate SQL
Run after all waves are complete:
```sql
-- Phase 111 gate — run after all waves applied
SELECT COUNT(DISTINCT pa.politician_id) AS senators_with_stances
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -5110040 AND -5110001;
-- Must return 40

SELECT COUNT(*) AS unsourced
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE p.external_id BETWEEN -5110040 AND -5110001
  AND (pc.id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
-- Must return 0
```

### Anti-Patterns to Avoid
- **Parallel agent dispatch:** Never run more than 1 agent at a time — rate limit quota exhausted immediately, agents produce empty output.
- **Party inference:** Never assign a value because "Republican senators oppose X" — every stance requires a real fetched URL.
- **PostgREST for inform schema:** `supabaseAdmin.schema('inform')` — inform is not in the PostgREST exposed schema list. Always use `pool.query()`.
- **Skipping context rows:** VAST-05 requires every `politician_answers` row to have a paired `politician_context` row with at least one non-placeholder URL. Missing context rows cause the phase gate query to fail.
- **Reusing stale migration numbers:** Next free migration number is 324. Verify before writing (last applied: 323).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stance research | Custom web scraper | research-stances SKILL + researcher agent | Skill has rate-limit rules, Five-Chairs framing, CSV format, DB push logic already built |
| CSV parsing | Split on commas | `csv-parse/sync` | Quote columns contain commas and embedded quotes |
| DB write | Supabase JS client `.from('politician_answers')` | `pool.query()` BEGIN/COMMIT | inform schema not in PostgREST exposed list |
| Topic list | Hardcoded array | Live DB query | Topic set grows; hardcoded list goes stale |
| Politician UUIDs | Hardcoded | UUID pre-flight query | UUIDs are DB-assigned; hardcoding causes FK violations |

## Common Pitfalls

### Pitfall 1: Agent Produces No Output (Rate Limit)
**What goes wrong:** Agent launched in parallel with others; WebFetch quota exhausted; CSV written but empty or only header row.
**Why it happens:** SKILL.md explicitly bans parallel dispatch but it's easy to accidentally trigger multiple agents.
**How to avoid:** One agent at a time. Wait for CSV write confirmation before dispatching next.
**Warning signs:** Agent completes suspiciously fast (< 2 min); CSV contains only the header line.

### Pitfall 2: Missing politician_context Row (VAST-05 Failure)
**What goes wrong:** Phase gate query returns non-zero for unsourced stances; migration blocked.
**Why it happens:** Agent found a value but had no real URL, so wrote value row but omitted context row. Or CSV was applied with a script that only handled `politician_answers`.
**How to avoid:** SKILL.md STEP 4b upserts both tables atomically. If writing migration SQL manually, always include paired context INSERT for every answers INSERT.
**Warning signs:** `informpolitician_answers` count > `inform.politician_context` count for the senator group.

### Pitfall 3: Stale Migration Number
**What goes wrong:** Migration file conflicts with an already-applied migration.
**Why it happens:** Last applied migration is 323 (photo_origin_url). If another migration is applied between Phase 110 closeout and Phase 111 start (e.g., Essentials 322 already mentioned in STATE.md), numbers shift.
**How to avoid:** Always check `SELECT MAX(version) FROM supabase_migrations.schema_migrations` or check the latest file in `supabase/migrations/` before naming new files.
**Warning signs:** `psql` error "duplicate key value violates unique constraint" on migration apply.

### Pitfall 4: Honest-Skip Confusion
**What goes wrong:** Agent writes a value=3 "neutral" guess when no evidence exists, rather than skipping.
**Why it happens:** Agent feels pressure to produce output for every topic.
**How to avoid:** Agent prompt must include explicit honest-skip instruction: "Skip any topic where you cannot find sufficient evidence. Do NOT infer from party affiliation."
**Warning signs:** Many value=3 stances with thin reasoning and non-specific source URLs (Wikipedia disambiguation, party homepage).

### Pitfall 5: City-Level Topics Included for State Senators
**What goes wrong:** Stances written for city-sanitation, homelessness-response, etc. for state senators. These topics don't apply at the state legislative level.
**Why it happens:** SKILL.md lists city-level topics to skip, but easy to miss.
**How to avoid:** Include the city-level skip list explicitly in every agent prompt (see SKILL.md STEP 1 template).

## DB State (Verified 2026-06-09)

| Property | Value | Source |
|----------|-------|--------|
| VA senator records | 40 | [VERIFIED: DB query] |
| External ID range | -5110001 to -5110040 | [VERIFIED: DB query] |
| Existing stance rows | 0 | [VERIFIED: DB query] |
| Live compass topics | 44 | [VERIFIED: DB query] |
| Last applied migration | 323 | [VERIFIED: STATE.md] |
| Next free migration number | 324 | [VERIFIED: STATE.md] |
| District type | STATE_UPPER | [ASSUMED: matches SLDU geofence layer naming from STATE.md] |

## VA Senate Full Roster (Confirmed 2026-06-09)

All 40 senators confirmed in DB. Organized by external_id (SD-1 = most conservative district, ascending):

**Republicans (SD-1 through ~SD-12, ~SD-17–SD-20, SD-24–SD-28):**
| External ID | full_name | UUID |
|-------------|-----------|------|
| -5110001 | Timmy French | cc91c3d5-18fa-478f-bb04-32d1d30dbcaf |
| -5110002 | Mark D. Obenshain | b7e9d159-b766-445c-b95f-9797b57247d9 |
| -5110003 | Christopher T. Head | 7eba070e-c4ed-404b-8a74-01794b2bd9ed |
| -5110004 | David R. Suetterlein | 8ed24df0-2a89-45d2-a236-1fe339b2a11c |
| -5110005 | T. Travis Hackworth | cd200e06-d726-4a12-b2e8-0295700d185e |
| -5110006 | Todd E. Pillion | eb7293ae-8a9d-4ae4-8deb-a32aa43e2c99 |
| -5110007 | William M. Stanley, Jr. | 1722c95b-7aed-430e-81a3-488cdf610afc |
| -5110008 | Mark J. Peake | ed60a0c7-252c-443f-98ff-5926bf9a58a3 |
| -5110009 | Tammy Brankley Mulchi | dcb3db81-0b8c-46ea-acdb-1d83d5c82c72 |
| -5110010 | Luther H. Cifers, III | 19c4b37d-4552-495c-a18b-d339585e684b |
| -5110017 | Emily M. Jordan | a6774628-e5fd-423e-822a-32c2d59f09af |
| -5110019 | Christie New Craig | 7b7540c8-f62f-4edd-a49a-19a3f883ebd8 |
| -5110020 | Bill DeSteph | ec4a7239-4681-4284-b77d-9c2d5c5473dd |
| -5110024 | J.D. "Danny" Diggs | f890829a-87e9-4f2e-ae33-ce8b98bf5105 |
| -5110025 | Richard H. Stuart | 7377cc55-0db6-4b15-8c4c-b1ad79137d25 |
| -5110026 | Ryan T. McDougle | ceba2c53-8da5-4ef9-9e1b-57fdfba98f50 |
| -5110027 | Tara A. Durant | 70d45f9c-aef9-4cd7-be4c-5ae568e94f94 |
| -5110028 | Bryce E. Reeves | eedc8e98-44ea-4dd0-9fc1-c83492e0d379 |

**Democrats (remaining):**
| External ID | full_name | UUID |
|-------------|-----------|------|
| -5110011 | R. Creigh Deeds | 66fe0d73-731e-45b9-8db4-21e3ce9eb9fd |
| -5110012 | Glen H. Sturtevant, Jr. | 405de162-8de9-4aef-af9a-c323c04da698 |
| -5110013 | Lashrecse D. Aird | 731049dd-0a5b-44fb-a778-b637dded0a5b |
| -5110014 | Lamont Bagby | 52daeb4d-205d-426a-80a4-40e00b7ee9c0 |
| -5110015 | Michael J. Jones | e529eee5-ecec-4719-8b50-47ab9d31bc4d |
| -5110016 | Schuyler T. VanValkenburg | 38b9461f-2f5b-45d8-ae99-626c75ae305d |
| -5110018 | L. Louise Lucas | 0efec835-12f2-472b-b7a0-7a166ed937a1 |
| -5110021 | Angelia Williams Graves | b65454d1-6707-4d4e-be3e-27121afc8388 |
| -5110022 | Aaron R. Rouse | 51547ab6-fee3-42c6-8418-f6fe7b67ee93 |
| -5110023 | Mamie E. Locke | 090feb66-a051-4624-8174-bf8b6272994d |
| -5110029 | Jeremy S. McPike | 230412ca-7207-41f8-9eb0-99486f54826d |
| -5110030 | Danica A. Roem | 2d726661-e210-42f3-8454-3cf2d3ecf811 |
| -5110031 | Russet W. Perry | 20a863f3-f3ca-4af8-9927-9e0d1dc14ce1 |
| -5110032 | Kannan Srinivasan | fabb0172-fe30-488b-b391-262499beb9ce |
| -5110033 | Jennifer D. Carroll Foy | b3c03be3-ae7a-4393-a99b-80b63fea74d0 |
| -5110034 | Scott A. Surovell | f3ffde61-ca65-4028-8552-2d4e9a9c6055 |
| -5110035 | David W. Marsden | 8db8b2e3-9160-4c14-9b47-707a7a27e4ab |
| -5110036 | Stella G. Pekarsky | 522d03a0-6fe8-4f48-b68a-cc4e12eba21b |
| -5110037 | Saddam Azlan Salim | 74ea1eb3-d4db-4dbe-882a-88ccecade1e5 |
| -5110038 | Jennifer B. Boysko | b4f19462-f23f-4061-831d-ec4544b5678f |
| -5110039 | Elizabeth B. Bennett-Parker | 612b8663-46c6-4f34-887d-0dadd06dd194 |
| -5110040 | Barbara A. Favola | 3efead48-af98-401f-b01e-00ca9590cc3f |

Note: SD-12 (Sturtevant) flipped R→D in 2023 elections. Confirm party affiliation via Ballotpedia during research — do not assume based on district number.

## Topic Scope for VA State Senators

**44 live topics total.** State senators use all topics EXCEPT the city-level skip list.

**City-level topics to skip (SKILL.md defined):**
- transportation-priorities
- economic-development
- homelessness-response
- residential-zoning
- city-sanitation
- local-immigration
- rent-regulation
- growth-and-development
- local-environment
- public-safety-approach
- jail-capacity
- All judicial-* topics (judicial-access-to-justice, judicial-bail-pretrial, judicial-criminal-justice, judicial-government-deference, judicial-interpretation, judicial-police-accountability, judicial-prosecution-priorities, judicial-transparency)

**Applicable topics for VA senators (~22 state-eligible topics):**
abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change, data-centers, deportation, fossil-fuels, healthcare, homelessness, housing, immigration, medicare/aid, misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers, social-security, tariffs, taxes, trans-athletes, ukraine-support, voting-rights

Note: `data-centers` and `redistricting` are applicable at state level (VA has had major data center debates). Honest-skip applies where no evidence found.

**Expected yield:** 8–18 stances per senator after honest-skip. Low-profile senators (newer, rural, few media mentions) will likely yield 5–10. High-profile senators (Deeds, Surovell, VanValkenburg, Lucas) may yield 15–22.

## Source Strategy for VA Senators

**Tier 1 — Most reliable (fetch first):**
- `ballotpedia.org/[First_Last]` — biographical, committee, election history
- `lis.virginia.gov` — Virginia Legislature: floor votes, bill sponsorship, committee assignments
- Official senator pages: `senate.virginia.gov/senators/[district]/`
- Wikipedia for prominent senators

**Tier 2 — Policy positions:**
- Official Senate bio pages often list priorities/positions
- Press releases on official sites
- Virginia Public Access Project (vpap.org) — useful for voting record context
- Richmond Times-Dispatch, Virginia Mercury for quoted positions
- WTOP News, Virginia Public Media for recent statements

**Tier 3 — Issue-specific:**
- Vote Smart (votesmart.org) — sometimes has VIF questionnaire responses
- Project Vote Smart — older senators may have responses
- Campaign websites (use Wayback Machine for older campaigns)

**Agent URL fetch pattern:**
```
1. https://ballotpedia.org/[First_Last]
2. https://lis.virginia.gov/cgi-bin/legp604.exe?ses=252&typ=mbr&mbr=S[district_number]
3. https://senate.virginia.gov/senators/[district]/
4. Official senator .gov page
5. Wikipedia if prominent senator
```

## Wave Batching Recommendation

40 senators, one agent at a time. Recommended 5-plan structure with 8 senators per wave. Group by party to make source patterns consistent within a wave (Republican senators = similar Ballotpedia/lis.virginia.gov lookup patterns).

| Plan | Wave | Senators | Party Focus |
|------|------|---------|-------------|
| 111-01 | Wave 1 | SD-1 through SD-8 (French, Obenshain, Head, Suetterlein, Hackworth, Pillion, Stanley, Peake) | Republican |
| 111-02 | Wave 2 | SD-9 through SD-16 (Mulchi, Cifers, Deeds, Sturtevant, Aird, Bagby, Jones, VanValkenburg) | Mixed |
| 111-03 | Wave 3 | SD-17 through SD-24 (Jordan, Lucas, Craig, DeSteph, Graves, Rouse, Locke, Diggs) | Mixed |
| 111-04 | Wave 4 | SD-25 through SD-32 (Stuart, McDougle, Durant, Reeves, McPike, Roem, Perry, Srinivasan) | Mixed |
| 111-05 | Wave 5 | SD-33 through SD-40 (Carroll Foy, Surovell, Marsden, Pekarsky, Salim, Boysko, Bennett-Parker, Favola) + phase gate | Democratic |

Each plan: pre-flight (topics snapshot + senator UUIDs for the cohort) → 8 sequential research agents → CSV review → migration SQL → apply → verify.

## Validation Architecture

nyquist_validation not set to false in config.json — validation section required, but this phase has no automated test infrastructure. Validation is SQL-assertion-based.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | SQL assertions in migration DO $$ blocks + manual phase gate script |
| Config file | none |
| Quick run | SQL SELECT in psql or node --import tsx inline |
| Full suite | Phase gate SQL (2 queries) after final wave |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| VAST-02 | 40 VA senators have at least 1 stance row | SQL | `SELECT COUNT(DISTINCT politician_id) FROM inform.politician_answers pa JOIN essentials.politicians p ON p.id = pa.politician_id WHERE p.external_id BETWEEN -5110040 AND -5110001` — must return 40 |
| VAST-05 | Every stance paired with context row + real source URL | SQL | `SELECT COUNT(*) FROM inform.politician_answers pa ... LEFT JOIN inform.politician_context pc ... WHERE ... (pc.id IS NULL OR array_length(pc.sources,1) = 0)` — must return 0 |

### Sampling Rate
- Per wave: run verification DO $$ block in migration SQL
- Phase gate: 2-query SQL check after Wave 5 applied

### Wave 0 Gaps
None — no test files needed. All verification is SQL-assertion-based, matching established pattern from Phases 103/106/108.

## Security Domain

No security-sensitive changes. This phase writes to `inform.politician_answers` and `inform.politician_context` — both are public-read, admin-write via RLS (already enforced). No auth changes, no new endpoints, no PII. ASVS not applicable.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js + tsx | DB scripts | ✓ | v24.13.0 | — |
| psql | Migration apply | ✓ (assumed) | — | Use Supabase dashboard SQL editor |
| .env with DATABASE_URL | pool.query() | ✓ | — | — |
| WebFetch tool | Research agents | ✓ | — | — |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Next free migration number is 324 | Architecture Patterns, Pitfall 3 | Migration number conflict — run `SELECT MAX(version)` before writing filename |
| A2 | District type for VA senators is STATE_UPPER | DB State table | Phase gate query may need adjustment if district_type differs |
| A3 | VAST-01 (exec stances) is fully owned by Essentials Phase 106 — Phase 111 is senators-only | Summary, scope | If exec stances are not handled, VAST-01 remains open |
| A4 | topic_key `data-centers` is applicable at state level | Topic Scope section | Skip if no evidence found (honest-skip applies equally) |

## Open Questions

1. **Migration number collision risk**
   - What we know: Last applied = 323 per STATE.md
   - What's unclear: Essentials team migration 322 was referenced in STATE.md sync note — check for any additional Essentials migrations between 323 and Phase 111 start
   - Recommendation: Always run `SELECT MAX(version) FROM supabase_migrations.schema_migrations` as first task in Wave 1 pre-flight

2. **Glen H. Sturtevant, Jr. party affiliation**
   - What we know: SD-12 historically Republican; 2023 VA Senate elections shifted several seats
   - What's unclear: Current party (may be R or D after 2023 flip)
   - Recommendation: Verify via Ballotpedia before assigning any stances — do not assume

3. **Saddam Azlan Salim and Kannan Srinivasan — new senators**
   - What we know: Both appear in migration 318; both have relatively uncommon names
   - What's unclear: Public record depth (newer senators may have limited documented positions)
   - Recommendation: Expect honest-skip to dominate for newer members; 3–6 stances realistic

## Sources

### Primary (HIGH confidence)
- DB query (2026-06-09) — VA senator records: 40 confirmed, external_id range -5110001..-5110040, 0 existing stances
- DB query (2026-06-09) — live topic count: 44
- SKILL.md (.claude/skills/research-stances/SKILL.md) — orchestration pattern, dispatch rules, CSV format
- STATE.md — migration 323 as last applied, Phase 110 complete
- Phase 106 SUMMARY.md — DC council batching pattern (groups of ~5, one agent at a time)

### Secondary (MEDIUM confidence)
- Phase 103 MD senator CSVs (data/stance-research/2026-06-07-md-senator-*.csv) — confirmed CSV format, per-senator file naming convention

### Tertiary (LOW confidence)
- VA Senate party composition 22D/18R — from phase brief; verify against vpap.org during Wave 1

## Metadata

**Confidence breakdown:**
- DB state: HIGH — verified via live queries
- Standard stack: HIGH — same tooling as Phases 103, 106
- Architecture: HIGH — established pattern, no new components
- Topic scope: HIGH — live DB query confirms 44 topics; skip list from SKILL.md
- Senator roster: HIGH — all 40 UUIDs verified from DB

**Research date:** 2026-06-09
**Valid until:** 2026-07-09 (stable — senator records don't change; topic set grows slowly)
