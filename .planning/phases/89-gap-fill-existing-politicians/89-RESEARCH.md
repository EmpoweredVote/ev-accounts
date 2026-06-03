# Phase 89: Gap-fill Existing Politicians — Research

**Researched:** 2026-06-03
**Domain:** Politician stance data — audit, prioritization, and ingestion
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GAPF-01 | Audit all existing politicians for < 10 stances; produce a prioritized target list (sorted by politician prominence + coverage gap size) | SQL query documented; DB data collected; priority tier definitions below |
| GAPF-02 | Research and ingest missing stances for all identified targets; every new stance row paired with a context row containing at least one source URL | research-stances SKILL.md pattern applies; direct pool.query() upsert pattern documented |

</phase_requirements>

---

## Summary

Phase 89 is a pure data-quality phase: find politicians with sparse stance coverage, research additional stances where evidence exists, and ingest them. No schema changes, no API changes, no frontend changes. All work is SQL queries plus repeated invocations of the research-stances skill pattern.

The DB currently has 1,051 politicians with at least one stance row. Of those, **440 have fewer than 10 stances** — a significant gap. However, the distribution is highly skewed by evidence availability: 246 of these are Texas and Oregon state legislators, plus ~62 politicians with no office record at all. These are systematically evidence-poor (nonpartisan local officials, obscure state reps with no web presence). The genuinely addressable set — state legislators and federal candidates in states with media coverage — is a fraction of that 440 total.

The phase uses the same two-table upsert pattern established in every prior stance research phase: `inform.politician_answers` (value only) + `inform.politician_context` (reasoning + sources array). No migration number is needed unless the planner wraps ingestion in a numbered SQL migration file (prior phases used direct pool.query() upserts via the SKILL.md script). Last applied migration is 127.

**Primary recommendation:** Wave 1 SQL audit produces a prioritized CSV listing all 440 politicians with < 10 stances, annotated with tier and evidence-availability judgment. Wave 2 works through high-priority politicians one at a time using the research-stances skill, skipping any politician where the evidence-availability judgment is "no additional evidence plausibly available."

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Audit SQL query | Database | — | Pure read against `inform.politician_answers` + `essentials.politicians` |
| Gap-fill target list (GAPF-01 artifact) | Planning artifact | — | Markdown/CSV file produced by Wave 1; consumed by Wave 2 executor |
| Stance research (per politician) | Agent (research-stances skill) | — | WebFetch-based research; no API tier involvement |
| Stance ingestion | Database (direct pool.query()) | — | `inform.politician_answers` + `inform.politician_context`; inform schema not in PostgREST |
| Priority tier determination | Planning logic | — | Prominence + coverage gap scoring; done in Wave 1 |

---

## Current State (VERIFIED from live DB — 2026-06-03)

### Stance Coverage Summary

| Category | Count |
|----------|-------|
| Total politicians with any stances | 1,051 |
| Politicians with < 10 stances | **440** |
| Politicians with < 5 stances | 130 |
| Politicians with 5–9 stances | 310 |
| Politicians with >= 10 stances | 611 |
| Total politicians in essentials.politicians | 81,484 (vast majority have zero stances — Staging/other data) |

[VERIFIED: live DB query 2026-06-03]

### Distribution by District Type (< 10 stances)

| District Type | Count | Avg Stances | < 5 | 5–9 |
|---------------|-------|-------------|-----|-----|
| STATE_LOWER | 214 | 5.9 | 54 | 160 |
| LOCAL | 109 | 5.0 | 43 | 66 |
| no_office | 62 | 5.6 | 21 | 41 |
| STATE_UPPER | 32 | 6.3 | 8 | 24 |
| COUNTY | 10 | 7.1 | 2 | 8 |
| STATE_EXEC | 7 | 6.0 | 2 | 5 |
| LOCAL_EXEC | 5 | 7.8 | 0 | 5 |
| NATIONAL_UPPER | 2 | 6.0 | 0 | 2 |

[VERIFIED: live DB query 2026-06-03]

### State Distribution of STATE_LOWER/UPPER with < 10 Stances

| State | Count | Notes |
|-------|-------|-------|
| TX | 116 | Texas state legislators — nonpartisan elections, low media coverage |
| OR | 82 | Oregon state legislators — sparse web presence for many |
| CA | 22 | CA Assembly/Senate — higher evidence availability |
| MA | 20 | MA state reps — some previously researched at value=3 (MA cluster, see Phase 88) |
| UT | 6 | Utah state legislators |

[VERIFIED: live DB query 2026-06-03]

### Known Special Cases

**James Byrd (WY, Democratic, NATIONAL_UPPER — 5 stances):** Documented "evidence floor" case from Phase 76. All 5 stances sourced from a single WyoFile campaign announcement article. No additional sources found at time of Phase 76 research. This is a legitimate evidence gap, not a research error. Phase 89 should attempt a fresh search but document "no additional evidence available" if still only one source found.

**Derek Dooley (GA, Republican, NATIONAL_UPPER — 7 stances):** Post-Phase 88 correction target. Phase 88 applied correct values (all 7 at value=4) but sourced context rows from the wrong Wikipedia page (football coach). Migration 127 was applied on 2026-06-03 to fix source URLs. Confirm correction before adding stances.

[VERIFIED: live DB query 2026-06-03]

### Orphan Stances (stances without context rows)

4 politicians currently have at least one stance row with no paired `inform.politician_context` row:

| Politician | Party | Total Stances | Orphan Count |
|-----------|-------|---------------|--------------|
| Roger Niello | Republican | 14 | 6 |
| Pilar Schiavo | Democratic | 12 | 1 |
| Rick Chavez Zbur | Democratic | 12 | 1 |
| Sade Elhawary | Democratic | 10 | 1 |

[VERIFIED: live DB query 2026-06-03]

**Action:** These are not below the 10-stance floor (all have >= 10 stances) but they violate GAPF-02's requirement that every stance row has a paired context row. Phase 89 Wave 1 should flag these as a side-task: add missing context rows. This is a smaller fix than full gap-fill research — the values already exist, only reasoning + sources need to be added.

---

## Wave 1: Audit SQL

### The Core Query

The query that produces the GAPF-01 artifact:

```sql
-- All politicians with < 10 stances, with office context for prioritization
SELECT
  p.id,
  p.full_name,
  COALESCE(NULLIF(p.party, ''), 'Unknown') AS party,
  sc.stance_count,
  (SELECT o.title FROM essentials.offices o WHERE o.politician_id = p.id LIMIT 1) AS office_title,
  (SELECT d.district_type FROM essentials.offices o 
   JOIN essentials.districts d ON d.id = o.district_id 
   WHERE o.politician_id = p.id LIMIT 1) AS district_type,
  (SELECT d.state FROM essentials.offices o 
   JOIN essentials.districts d ON d.id = o.district_id 
   WHERE o.politician_id = p.id LIMIT 1) AS state
FROM (
  SELECT politician_id, COUNT(*) AS stance_count
  FROM inform.politician_answers
  GROUP BY politician_id
  HAVING COUNT(*) < 10
) sc
JOIN essentials.politicians p ON p.id = sc.politician_id
ORDER BY sc.stance_count ASC, p.full_name ASC;
```

Run via `pool.query()` in backend context (not PostgREST — `inform` schema not exposed).

[VERIFIED: query executed successfully against live DB 2026-06-03]

---

## Priority Tier Definitions

### Tier 1 — High Priority (research immediately)

Politicians where evidence is plausibly available AND prominence warrants it:

- **Federal candidates** (NATIONAL_UPPER, NATIONAL_LOWER) with < 10 stances — James Byrd (WY-D, 5 stances) and Derek Dooley (GA-R, 7 stances) are the two current cases
- **State-level politicians in high-evidence states** with < 10 stances — CA Assembly, CA State Senate members (22 politicians in this bucket); these legislators have extensive CalMatters, Sacramento Bee, and official vote record coverage
- **MA state legislators** with < 10 stances (20 politicians) — notably the ones outside the Phase 88 MA cluster investigation (those were already confirmed centrist). Check whether the remaining MA politicians with < 10 have evidence beyond what Phase 88 found.
- **State exec officials** with < 10 stances (7 politicians) — governors, AGs, treasurers have significant public records

### Tier 2 — Medium Priority (research if time allows)

- **OR state legislators** (82 politicians) — lower media coverage than CA/MA but Oregon has Ballotpedia profiles, OregonVotes.gov vote records, and news coverage. Many are below 5 stances. Worth attempting but expect ~40–50% "no additional evidence" rate.
- **TX state legislators** (116 politicians) — highly variable. Many TX state reps have minimal web presence. Expect high "no evidence" rate. Worth attempting for the larger-name legislators.
- **LOCAL with identifiable policy officials** — mayors and council members in cities with active local media (e.g., Sacramento, Berkeley, San Diego) may have enough coverage for 5–10 stances

### Tier 3 — Low Priority (document as "no additional evidence available")

- **no_office politicians** (62 in < 10 bucket) — these have stances but no office record. Their identity and role is unclear; research is likely to be fruitless or produce low-confidence matches.
- **LOCAL TX politicians** (hundreds of small-city council members in TX cities like Mansfield, Burleson, Weatherford) — nonpartisan local officials with minimal web presence. Documented evidence floor.
- **Unknown party + LOCAL/LOCAL_EXEC** — small-city nonpartisan officials with 1–4 stances are almost certainly evidence-floor cases. Document rather than research.

---

## Evidence-Availability Heuristic

A politician is **"plausibly available"** for gap-fill research if:

1. They hold a state or federal office (not local city council in a small city), OR
2. They hold a local office in a major city with active local journalism (SF, LA, San Diego, Oakland, Berkeley, Sacramento, San Jose, etc.), AND
3. They have a known party affiliation (not "Unknown" or "Nonpartisan") OR a well-documented policy record

A politician should be marked **"no additional evidence available"** if:
- They are a local/county official in a state without strong local journalism for that jurisdiction
- They are "Unknown" party with no office record
- The only available source is a single article from an obscure local paper and it doesn't cover policy topics
- Prior research found nothing beyond 1–5 stances after WebFetch attempts

**The James Byrd precedent:** During Phase 76, James Byrd (WY-D Senate candidate) was researched and only 5 stances could be sourced — all from one WyoFile article. This was documented as a legitimate evidence floor. Phase 89 should re-attempt Byrd (new sources may exist since the 2026 campaign has progressed) but should accept < 10 stances if no additional evidence is found.

[ASSUMED — evidence-availability heuristic is a planning judgment, not a DB-sourced fact]

---

## Standard Stack (Ingestion Pattern)

This phase uses no new libraries. All ingestion uses the existing pattern:

### Core Tables

```sql
-- Stance answer
inform.politician_answers (politician_id UUID, topic_id UUID, value NUMERIC)
-- Unique constraint: (politician_id, topic_id)

-- Source context  
inform.politician_context (politician_id UUID, topic_id UUID, reasoning TEXT, sources TEXT[])
-- Unique constraint: (politician_id, topic_id)
```

[VERIFIED: live DB schema query 2026-06-03]

### Upsert Pattern (from research-stances SKILL.md)

```typescript
// Source: SKILL.md Step 4b
// Upsert stance answer
await pool.query(`
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  VALUES ($1, $2, $3)
  ON CONFLICT (politician_id, topic_id)
  DO UPDATE SET value = EXCLUDED.value
`, [politician_id, topic_id, value]);

// Upsert context
await pool.query(`
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES ($1, $2, $3, $4)
  ON CONFLICT (politician_id, topic_id)
  DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
`, [politician_id, topic_id, reasoning, sources]);
```

[VERIFIED: SKILL.md Step 4b, confirmed pattern used in every prior stance phase]

### ID Resolution Pattern

```bash
# Resolve politician_id from full_name
cd backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT p.id as politician_id, p.full_name, t.id as topic_id, t.topic_key
  FROM essentials.politicians p
  CROSS JOIN inform.compass_topics t
  WHERE lower(p.full_name) = ANY(SELECT lower(n) FROM unnest(\$1::text[]) AS n)
    AND t.is_live = true
  ORDER BY p.full_name, t.created_at
\`, [process.argv.slice(2)]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Politician Name"
```

[VERIFIED: SKILL.md Step 4a]

---

## Migration Numbering

**Last applied migration:** 127 (`20260603000012_127_derek_dooley_source_corrections.sql`)

**Next available number:** 128

**Naming convention observed:**
```
20260603000001_116_jeff_gonzalez_inversion_correction.sql
20260603000012_127_derek_dooley_source_corrections.sql
```

Pattern: `YYYYMMDDHHMMSS_NNN_short_description.sql` where `NNN` is the sequential migration number.

**Note on migration vs direct ingestion:** Prior stance research phases (74, 76, 78) used direct `pool.query()` upserts via the SKILL.md script — NOT numbered SQL migration files. Phase 88 used numbered migration files because the corrections were single UPDATE statements that needed to be tracked in the Supabase migration history. For Phase 89, the planner should decide: if the gap-fill is large (many politicians, many stances), direct pool.query() upserts are faster and more flexible. If the gap-fill produces a discrete, reviewable set, a migration file is also acceptable. Both patterns are established and correct.

[VERIFIED: migration file listing 2026-06-03]

---

## Research-Stances Skill Usage

The `research-stances` skill (`/.claude/skills/research-stances/SKILL.md`) is the standard tool for Wave 2. Key operational constraints:

**Rate limit rule:** Dispatch ONE agent at a time. Never parallel. Prior phases that parallelized hit rate limit instantly and produced empty output.

**Tool rule:** Agents use WebFetch ONLY. Never WebSearch or Playwright (shared quota pool). Fetch URLs directly from Ballotpedia, ontheissues.org, official pages, Wikipedia, CalMatters, LA Times.

**Five-chairs framing:** The updated SKILL.md (as of Phase 87/88) includes the five-chairs block in every agent prompt. This prevents stance inversions.

**Topic resolution:** Always fetch live topics from DB before each research run. As of 2026-06-03 there are 44 live topics. The SKILL.md does this in Step 0.

**City-level topics to SKIP for state/federal politicians:**
`transportation-priorities, economic-development, homelessness-response, residential-zoning, city-sanitation, local-immigration, rent-regulation, growth-and-development, local-environment, public-safety-approach, jail-capacity, judicial-*`

**Applicable topics for federal politicians:** ~30 of 44 topics apply (local-tier topics excluded)

**Applicable topics for state legislators:** ~35 of 44 topics apply (hyperlocal city topics excluded, state-specific local topics may be included)

[VERIFIED: SKILL.md, confirmed by Phase 74/76/78 precedents]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stance research | Custom web scraper | research-stances SKILL.md with WebFetch | Rate limits, five-chairs framing baked in, proven pattern |
| ID resolution | Manual UUID lookup | SKILL.md Step 4a pool.query() pattern | Handles alternate_names, is idempotent |
| Stance upsert | Raw INSERT | ON CONFLICT DO UPDATE pattern | Prevents duplicate rows; safe to re-run |
| Context upsert | Separate INSERT/UPDATE | ON CONFLICT DO UPDATE pattern | Same reason |
| Priority scoring | Complex algorithm | Simple 3-tier heuristic (federal > state > local, with evidence-availability check) | Complexity not warranted; judgment matters more than automation |

---

## Architecture Patterns

### Data Flow

```
Wave 1 — Audit
  pool.query() audit SQL
    → 440 politicians with < 10 stances
    → Planner annotates with priority tier + evidence-availability
    → Produces: 89-GAP-FILL-AUDIT.md

Wave 2 — Research + Ingestion (per politician, serially)
  For each HIGH-priority politician:
    research-stances skill
      → WebFetch (Ballotpedia, official pages, news)
      → CSV written to backend/data/stance-research/
      → pool.query() upserts to inform.politician_answers
      → pool.query() upserts to inform.politician_context
  
  For each "no additional evidence" politician:
    → Document in 89-GAP-FILL-AUDIT.md with "no additional evidence available" status

Side-task — Orphan context fix (4 politicians):
  Niello, Schiavo, Zbur, Elhawary each have 1–6 stances missing context
    → For each orphan: fetch existing stance value, research source, add context row
```

### Recommended Project Structure (artifacts produced)

```
.planning/phases/89-gap-fill-existing-politicians/
├── 89-RESEARCH.md              (this file)
├── 89-GAP-FILL-AUDIT.md        (produced in Wave 1 — priority list)
└── 89-01-PLAN.md               (Wave 1: audit query + artifact)
    89-02-PLAN.md               (Wave 2: research + ingestion)

backend/data/stance-research/
└── YYYY-MM-DD-gap-fill-*.csv   (per-politician CSV files from Wave 2)
```

---

## Common Pitfalls

### Pitfall 1: Treating "440 politicians" as the addressable set

**What goes wrong:** Planner creates 440 tasks, executor hits "no evidence" for 300 of them, phase stalls.
**Why it happens:** The 440 includes TX/OR local politicians, nonpartisan officials, and no-office records where evidence doesn't exist.
**How to avoid:** Wave 1 audit must annotate each politician with evidence-availability judgment. Only "plausibly available" politicians get Wave 2 research tasks. The remaining are documented as "no additional evidence available."
**Warning signs:** Wave 2 agents returning 0–2 stances repeatedly; reasoning section citing only party affiliation.

### Pitfall 2: Party-inference fallback

**What goes wrong:** Agent can't find direct evidence, falls back to "as a Republican, they likely support..."
**Why it happens:** Five-chairs framing not enforced, or agent under-fetches evidence.
**How to avoid:** Agent prompt must include five-chairs block verbatim (SKILL.md template). Reject any reasoning containing "likely supports", "as a [party]", "given their party".
**Warning signs:** Stances clustered at value=4 for all R politicians or value=2 for all D politicians.

### Pitfall 3: Skipping context rows

**What goes wrong:** pool.query() upsert only inserts `politician_answers` row, skips `politician_context`.
**Why it happens:** Copy-paste error from an older pattern that didn't require context.
**How to avoid:** GAPF-02 explicitly requires context rows. Every stance INSERT must be paired. Use SKILL.md Step 4b exactly — it does both in sequence.
**Warning signs:** `SELECT COUNT(*) FROM inform.politician_context` not increasing proportionally with `politician_answers`.

### Pitfall 4: Using the Phase 87 audit as the gap-fill list

**What goes wrong:** Executor confuses the Phase 87 accuracy-flag list (politicians with suspicious stance distributions) with the Phase 89 gap-fill list (politicians with too few stances).
**Why it happens:** Both are "politicians that need work" but for opposite reasons.
**How to avoid:** Wave 1 runs a fresh SQL query: `HAVING COUNT(*) < 10`. Do not re-use the Phase 87 SQL (which required >= 15 stances and flagged high-variance politicians).
**Warning signs:** Trying to "correct" politicians like Alex Padilla (35 stances) instead of adding stances to politicians with 3–9.

### Pitfall 5: inform schema via PostgREST

**What goes wrong:** Code uses `supabaseAdmin.schema('inform').from('politician_answers').insert()` which fails silently.
**Why it happens:** The `inform` schema is NOT in the PostgREST exposed schema list.
**How to avoid:** All `inform.*` reads AND writes must use `pool.query()` (direct postgres). This is a project-wide invariant.
**Warning signs:** DB query confirms 0 rows inserted despite no error thrown.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Value 1=conservative, 5=progressive | Five-chairs framing: each value = specific named position, direction varies by topic | Phase 87/88 (SKILL.md updated) | Prevents inversions from directional assumption |
| Direct INSERT to inform.politician_answers | ON CONFLICT DO UPDATE upsert | Phase 74+ | Safe to re-run; handles partial research restarts |
| Batch ingestion via gen_migration.py | Direct pool.query() upserts via SKILL.md Step 4b | Phase 74+ | Faster, more flexible; migration files optional |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Priority tier definitions (Tier 1/2/3) are reasonable for evidence availability | Priority Tier Definitions | If TX or OR legislators have more evidence available than expected, Tier 3 designation under-counts the addressable set |
| A2 | Evidence-availability heuristic correctly identifies "plausibly available" politicians | Evidence-Availability Heuristic | Could lead to skipping politicians where evidence exists, or wasting time on ones where it doesn't |
| A3 | ~40–50% "no evidence" rate for OR state legislators | Priority Tier Definitions | Based on prior Phase 76 experience with non-CA state legislators; actual rate could differ |
| A4 | The orphan context rows for Niello, Schiavo, Zbur, Elhawary are each researchable | Current State — Orphan Stances | If no sources available for orphan topics, context rows cannot be added |

---

## Open Questions

1. **How many politicians in the "plausibly available" set?**
   - What we know: 440 total < 10 stances; CA (22) + MA (20) + federal (2) + state_exec (7) = ~51 clearly high-evidence politicians; OR (82) + TX (116) are partially addressable
   - What's unclear: How many of the OR/TX politicians have enough web presence for 5+ additional stances?
   - Recommendation: Wave 1 should categorize all 440 and produce a count per tier before Wave 2 begins. The planner should not pre-commit to a specific number of Wave 2 tasks.

2. **Should the orphan context fix be a separate plan or part of Wave 1?**
   - What we know: 4 politicians (Niello, Schiavo, Zbur, Elhawary) have stances without context rows
   - What's unclear: Whether these are covered by GAPF-02 (which says "every new stance row" — these are existing rows) or constitute a separate data-quality fix
   - Recommendation: Include orphan context fix in Wave 1 or Wave 2 plan as a side-task. It's small (4 politicians, 9 rows total) and clearly within the spirit of GAPF-02.

3. **Should gap-fill stances go in numbered migration files or direct pool.query() upserts?**
   - What we know: Prior research phases (74, 76, 78) used direct upserts; Phase 88 used numbered migrations
   - What's unclear: Whether the planner wants an auditable migration trail for gap-fill stances
   - Recommendation: Use direct pool.query() upserts (same as Phase 74/76/78). The CSV file provides the audit trail. Numbered migrations are overhead for 40–100+ individual politicians.

---

## Environment Availability

All dependencies are available — this phase uses only the existing backend stack:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (pool.query) | Stance ingestion | Yes | Supabase remote | — |
| backend/.env | DB connection | Yes | Present | — |
| node + tsx | Script execution | Yes | Node 24 | — |
| research-stances SKILL.md | Wave 2 agent dispatch | Yes | Updated post-Phase 87 | — |

---

## Validation Architecture

No automated test framework applies to this phase. All validation is:

1. **Wave 1 acceptance:** `SELECT COUNT(*) FROM inform.politician_answers GROUP BY politician_id HAVING COUNT(*) < 10` returns 0 for all politicians in the "high-priority" tier after Wave 2 completes.

2. **Context row check:** `SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id WHERE pc.politician_id IS NULL` returns 0.

3. **Source URL presence:** `SELECT COUNT(*) FROM inform.politician_context WHERE sources IS NULL OR array_length(sources, 1) = 0` returns 0 for all newly ingested rows.

4. **Audit artifact completeness:** `89-GAP-FILL-AUDIT.md` lists every politician in the 440-count set with either a tier assignment + evidence-availability judgment, or a post-fill confirmation.

---

## Security Domain

Not applicable. Phase 89 makes no changes to authentication, authorization, API endpoints, or user-facing code. Pure data ingestion into internal tables.

---

## Sources

### Primary (HIGH confidence)
- Live DB query (2026-06-03) — all stance counts, district distributions, orphan rows, migration numbers
- `.claude/skills/research-stances/SKILL.md` — ingestion pattern, tool rules, dispatch rules
- `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md` — audit SQL, methodology
- `.planning/phases/88-stance-corrections-party-normalization/88-VERIFICATION.md` — last migration (127), post-Phase-88 DB state

### Secondary (MEDIUM confidence)
- STATE.md v2.5 patterns section — migration numbering convention, pool.query() requirement for inform schema
- Phase 76 ROADMAP notes — James Byrd evidence floor precedent ("WY, D, at 5 stances — documented floor case (no evidence available)")

---

## Metadata

**Confidence breakdown:**
- Current DB state: HIGH — queried directly from live DB
- Ingestion pattern: HIGH — verified from SKILL.md + prior phases
- Priority tier definitions: MEDIUM — planning judgment, not mechanically derived
- Evidence availability estimates: LOW/MEDIUM — extrapolated from prior research experience

**Research date:** 2026-06-03
**Valid until:** 2026-07-03 (stable — DB schema won't change; only stance counts will grow as work proceeds)
