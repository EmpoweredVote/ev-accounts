# Architecture Patterns

**Domain:** Indiana Primary Election Readiness Audit — v2026.4.3
**Researched:** 2026-04-11
**Milestone:** v2026.4.3 Indiana Primary Election Readiness Audit
**Overall confidence:** HIGH — all findings from direct code inspection of the live codebase

---

## Existing Architecture Snapshot

The audit milestone operates entirely within the existing stack. No new services, schemas, or API
layers are required. The work is additive: audit scripts, SQL queries, and gap-report documents
that read from the existing schema.

### Repos touched by this milestone

| Repo | Role in audit | What changes |
|------|--------------|--------------|
| `ev-accounts` | Backend + audit scripts | New scripts in `backend/scripts/`; possibly new data via SQL |
| `essentials` | Voter-facing app being audited | No code changes (audit observes it, doesn't modify it) |
| `CompassV2` | Compass experience being audited | No code changes |
| `EV-readrank` | Read & Rank experience being audited | No code changes |

---

## Data Model: What the Audit Reads

### Election + Candidate Layer (`essentials` schema)

```
essentials.elections
  id, name, election_date, election_type, jurisdiction_level, state

essentials.races
  id, election_id, office_id (nullable), position_name, primary_party,
  seats, district_type, description

essentials.race_candidates
  id, race_id, politician_id (nullable — NULL for pure challengers),
  full_name, first_name, last_name,
  is_incumbent, candidate_status, source, photo_url
```

**Already populated for Monroe County 2026 Primary:**
- Election seeded via `seed-monroe-county-2026-primary.sql` (797 lines, idempotent)
- Races: county-wide offices, judicial, town council, township trustees, township advisory boards
- Incumbents linked via `link-monroe-candidates-to-politicians.sql` — `politician_id` set where match found
- All antipartisan constraints observed: `primary_party` lives on `races`, never on `race_candidates`

### Stance + Compass Layer (`inform` schema)

```
inform.politician_answers
  politician_id, topic_id, value (NUMERIC 3,1 — half-step scale)

inform.politician_context
  politician_id, topic_id, context_text, source_url (reasoning behind stance)

essentials.quotes
  id, politician_id, topic_key, quote_text, source_url, source_date
  (joined to inform.compass_topics via topic_key — migration 055)
```

**Existing Monroe County coverage (from `push-monroe-county-research.ts` and CSV files in `backend/data/stance-research/`):**
- `2026-04-10-monroe-county-commissioner.csv` — stances for Trent Deckard + David Henry
- `2026-04-10-monroe-county-commissioner-quotes.csv` — 40 quotes, 1 flagged
- Bloomington council batch CSVs for Beckwith, Bloomington council, Pierce, Thomson, Young
- These have been pushed to production via `push-monroe-county-research.ts`

### Politician Layer (`essentials` schema)

```
essentials.politicians
  id, first_name, last_name, slug, bio_text, bioguide_id, total_years_in_office,
  is_appointed (critical for elected/appointed filter)

essentials.politician_images
  politician_id, url, type (CDN-hosted headshots)

essentials.politician_contacts
  politician_id, contact_type, value
```

---

## Audit Query Architecture

All audit queries run as READ-ONLY scripts from `ev-accounts/backend/scripts/` using the existing
`pg.Pool` / `DATABASE_URL` pattern established by `auditHeadshots.ts` and `audit-is-appointed.ts`.

### Pattern: Standalone audit script

```typescript
// ev-accounts/backend/scripts/audit-<target>.ts
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

// Load .env relative to script location (established pattern)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL,
  max: 3,
  ssl: { rejectUnauthorized: false },
});

// READ-ONLY queries only — no UPDATE/INSERT/DELETE
// Output: structured text or CSV to stdout
// Progress: stderr

async function main() { ... }
main().finally(() => pool.end());
```

**Invocation:**
```bash
cd ev-accounts/backend
npx tsx scripts/audit-<target>.ts
npx tsx scripts/audit-<target>.ts > /tmp/audit-output.txt   # pipe to file
```

---

## Core Audit Queries

### 1. Race + Candidate Coverage

Answers: "How many races exist, how many have candidates, how many candidates are linked to politicians?"

```sql
-- Races with candidate counts, by tier
SELECT
  r.position_name,
  r.primary_party,
  electionService_inferDistrictType_logic AS district_type,
  COUNT(rc.id)            AS total_candidates,
  COUNT(rc.politician_id) AS linked_to_politician,
  COUNT(rc.id) - COUNT(rc.politician_id) AS unlinked_challengers
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
WHERE e.name = '2026 Indiana Primary'
  AND e.election_date = '2026-05-05'
  AND e.state = 'IN'
GROUP BY r.position_name, r.primary_party
ORDER BY r.position_name, r.primary_party;
```

### 2. Stance Data Completeness

Answers: "Which Monroe County primary candidates have compass stances? Which have zero?"

```sql
-- Candidates with/without compass stances
SELECT
  rc.full_name,
  r.position_name,
  p.id AS politician_id,
  COUNT(pa.topic_id) AS stance_count
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
WHERE e.name = '2026 Indiana Primary'
  AND e.state = 'IN'
GROUP BY rc.full_name, r.position_name, p.id
ORDER BY stance_count ASC, r.position_name;
```

### 3. Quote Coverage for Read & Rank

Answers: "Which candidates have quotes available for Read & Rank?"

```sql
-- Candidates with quote counts
SELECT
  rc.full_name,
  r.position_name,
  COUNT(q.id) AS quote_count
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.quotes q ON q.politician_id = rc.politician_id
WHERE e.name = '2026 Indiana Primary'
  AND e.state = 'IN'
GROUP BY rc.full_name, r.position_name
ORDER BY quote_count ASC, r.position_name;
```

### 4. Headshot Coverage for Monroe County Candidates

Answers: "Which candidates have photos? Which will show the initials avatar?"

```sql
-- Headshot availability per candidate
SELECT
  rc.full_name,
  r.position_name,
  rc.politician_id,
  CASE WHEN pi.url IS NOT NULL THEN 'CDN photo'
       WHEN rc.photo_url IS NOT NULL THEN 'local photo'
       ELSE 'no photo' END AS photo_status,
  pi.url AS cdn_url
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = rc.politician_id
WHERE e.name = '2026 Indiana Primary'
  AND e.state = 'IN'
ORDER BY photo_status, r.position_name;
```

### 5. Profile Completeness (bio, contacts, education)

Answers: "Do linked politicians have bio text and contacts populated?"

```sql
-- Profile field completeness for Monroe County incumbents
SELECT
  p.first_name || ' ' || p.last_name AS name,
  p.slug,
  CASE WHEN p.bio_text IS NOT NULL AND length(p.bio_text) > 50 THEN 'yes' ELSE 'no' END AS has_bio,
  COUNT(DISTINCT pc.id) AS contact_count,
  COUNT(DISTINCT d.id)  AS degree_count,
  COUNT(DISTINCT ex.id) AS experience_count
FROM essentials.race_candidates rc
JOIN essentials.elections e ON e.id = (
  SELECT r.election_id FROM essentials.races r WHERE r.id = rc.race_id
)
JOIN essentials.politicians p ON p.id = rc.politician_id
LEFT JOIN essentials.politician_contacts pc ON pc.politician_id = p.id
LEFT JOIN essentials.degrees d ON d.politician_id = p.id
LEFT JOIN essentials.experiences ex ON ex.politician_id = p.id
WHERE e.name = '2026 Indiana Primary'
  AND e.state = 'IN'
  AND rc.politician_id IS NOT NULL
GROUP BY p.id, p.first_name, p.last_name, p.slug, p.bio_text
ORDER BY name;
```

### 6. Geofence Coverage Check

Answers: "Can a Monroe County address resolve to the expected races via ST_Covers?"

```sql
-- Geofences covering a test address in Monroe County
-- (geocode first via Census Geocoder, then test point-in-polygon)
SELECT
  g.geo_id,
  g.mtfcc,
  d.district_type,
  ch.name AS chamber_name
FROM essentials.geofences g
JOIN essentials.districts d ON d.geofence_id = g.id
JOIN essentials.chambers ch ON ch.id = d.chamber_id
WHERE ST_Covers(
  g.geom,
  ST_SetSRID(ST_MakePoint(-86.5264, 39.1653), 4326)  -- Bloomington, IN center
)
ORDER BY d.district_type;
```

### 7. Electoral Race-to-Geofence Linkage

Answers: "Are races linked to offices? Are offices linked to geofenced districts?"

```sql
-- Race linkage audit
SELECT
  r.position_name,
  r.primary_party,
  r.office_id,
  o.title AS office_title,
  d.district_type,
  g.geo_id AS geofence_geo_id
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.offices o ON o.id = r.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.geofences g ON g.id = d.geofence_id
WHERE e.name = '2026 Indiana Primary'
  AND e.state = 'IN'
ORDER BY r.office_id IS NULL DESC, r.position_name;
```

---

## Competitive Benchmark Data Structure

Competitor analysis (BallotReady, VoteSmart, Vote411, Ballotpedia) is captured as a structured
document, not a database table. It informs the gap report but does not feed back into the schema.

### Where benchmark data lives

```
.planning/research/
  COMPETITOR-BENCHMARK.md   # Feature checklist × competitor matrix
  GAP-REPORT.md             # Tiered gap list (before-primary vs future)
```

### Benchmark schema (document format)

```markdown
## Monroe County Spot-Check Results

| Feature | EV Status | BallotReady | VoteSmart | Vote411 | Ballotpedia |
|---------|-----------|-------------|-----------|---------|-------------|
| Race list (county) | complete | ... | ... | ... | ... |
| Race list (township) | complete | ... | ... | ... | ... |
| Candidate photos | partial | ... | ... | ... | ... |
| Candidate bios | partial | ... | ... | ... | ... |
| Candidate stances | 2 of N | ... | ... | ... | ... |
| Q&A / voter guides | 0 | ... | ... | ... | ... |
| Sample ballot | none | ... | ... | ... | ... |
```

Competitive data is researcher-collected (manual spot-check), not scraped. It informs priorities
for the execution backlog but has no schema implications.

---

## Gap Report Location and Structure

Gap reports live in `.planning/` as planning documents, not as runtime database tables.

### Tiered gap report document

```
.planning/
  GAP-REPORT-v2026.4.3.md    # Tier 1 (before primary) vs Tier 2 (future)
```

### Gap report structure

```markdown
## Tier 1: Ship Before Primary (~2 weeks, by ~April 25)

### Data gaps
- [ ] Missing candidate headshots: [list]
- [ ] Missing stances for [position]: [candidates]
- [ ] Missing quotes for Read & Rank: [candidates]

### UX gaps
- [ ] Election Central does not show township board races
- [ ] Candidate profile for [name] shows empty profile (no bio/stances)

### Functionality gaps
- [ ] Geofence resolution for [address pattern] returns wrong district

## Tier 2: Future Improvements

- [ ] Voter guide Q&A integration (Vote411-style)
- [ ] Sample ballot PDF link
```

Gap items feed directly into phase plans for follow-on milestones. They are not stored in the
database.

---

## Component Boundaries

### What already exists (no changes needed for audit phase)

```
ev-accounts/backend/
  src/lib/electionService.ts      Fetches elections by geofence; inferDistrictType(); full race+candidate query
  src/lib/essentialsBrowseService.ts  Browse by location
  src/lib/compassService.ts       Politician stances (inform.politician_answers)
  src/routes/essentials.ts        /elections, /elections-by-address, /quotes endpoints
  src/routes/candidates.ts        /candidates/:slug, /candidates/:slug/answers

essentials/ (frontend)
  src/pages/CandidateProfile.jsx  Incumbent/challenger branching — uses politician data or raw candidate fields
  src/components/ElectionsView.jsx  Tier-grouped race display with countdown

CompassV2/
  src/pages/Compare.jsx           Politician stances as radar overlay
```

### What the audit milestone adds

```
ev-accounts/backend/scripts/
  audit-monroe-county-readiness.ts   NEW — composite READ-ONLY report
    • Race + candidate coverage
    • Stance completeness per candidate
    • Quote coverage per candidate
    • Headshot status per candidate
    • Profile field completeness (bio, contacts)
    • Geofence resolution test
    Output: structured text to stdout, pipe to .planning/ for archiving

.planning/research/
  COMPETITOR-BENCHMARK.md    NEW — manual spot-check matrix
  GAP-REPORT-v2026.4.3.md    NEW — tiered gap list
```

---

## Data Flow for the Audit

```
1. Run audit-monroe-county-readiness.ts
   → Reads: essentials.races, race_candidates, elections
   → Reads: inform.politician_answers (stance coverage)
   → Reads: essentials.quotes (quote coverage)
   → Reads: essentials.politician_images (headshot coverage)
   → Reads: essentials.politicians (bio, slug)
   → Reads: essentials.geofences (spatial query)
   → Output: structured text report (pipe to /tmp/ or .planning/)

2. Researcher runs manual spot-checks on competitor sites
   → Monroe County address entered on BallotReady, Vote411, VoteSmart, Ballotpedia
   → Results recorded in COMPETITOR-BENCHMARK.md

3. Gap analysis synthesizes audit output + benchmark
   → GAP-REPORT-v2026.4.3.md partitioned by Tier 1 / Tier 2
   → Tier 1 items become phase plans in subsequent milestone
```

---

## Integration Points with Existing CLI Tools

### Existing tools that inform the audit baseline

| Script | What it tells us |
|--------|-----------------|
| `seed-monroe-county-2026-primary.sql` | Canonical race + candidate list for 2026 primary — ground truth for completeness checks |
| `link-monroe-candidates-to-politicians.sql` | Shows which candidates have politician_id set — defines the "linked incumbent" population |
| `push-monroe-county-research.ts` | Shows which politicians already have stances/quotes pushed |
| `auditHeadshots.ts` | Existing headshot audit — can be filtered to Monroe County candidates |
| `audit-is-appointed.ts` | Pattern for READ-ONLY structured reporting (used as the code template) |
| `confirm-indiana.ts` | Shows Indiana-specific data classification patterns |

### New audit script vs existing tools

The new `audit-monroe-county-readiness.ts` is a **composite** audit that combines checks from
multiple existing tools into a single Monroe County-scoped run. It does not replace any existing
script; it adds a focused read-only report for the election context.

There is **no need** to modify `electionService.ts` or `candidateService.ts` for the audit — the
audit queries the database directly via `pg.Pool`, not via the Express service layer. This mirrors
the established `auditHeadshots.ts` / `audit-is-appointed.ts` pattern.

---

## Build Order for the Audit Milestone

| Step | Work | Location | Dependency |
|------|------|----------|-----------|
| 1 | Write `audit-monroe-county-readiness.ts` | `backend/scripts/` | Nothing (read-only DB queries) |
| 2 | Run script against production DB | — | Step 1 |
| 3 | Manual competitor spot-checks (BallotReady, Vote411, etc.) | researcher | Parallel with step 2 |
| 4 | Synthesize: write `COMPETITOR-BENCHMARK.md` | `.planning/research/` | Step 3 |
| 5 | Synthesize: write `GAP-REPORT-v2026.4.3.md` | `.planning/` | Steps 2 + 4 |
| 6 | Prioritize gap items into Tier 1 / Tier 2 | `.planning/` | Step 5 |
| 7 | Write phase plans for Tier 1 execution items | `.planning/phases/` | Step 6 |

Steps 2 and 3 are independent and can run in parallel. Steps 4 and 5 both depend on their inputs
completing. Step 7 is the deliverable that feeds subsequent milestone phases.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Modifying service layer for audit queries

**What:** Adding `getMonroeCountyAuditReport()` to `electionService.ts` or creating a new
`/api/admin/audit` endpoint.

**Why bad:** Audit queries are one-shot operational scripts. Putting them in the service layer
adds dead API surface that has no frontend consumer, requires auth middleware wiring, and pollutes
the production API.

**Instead:** Standalone `npx tsx scripts/audit-*.ts` scripts that connect directly via `pg.Pool`.
This is the established pattern in `auditHeadshots.ts` and `audit-is-appointed.ts`.

---

### Anti-Pattern 2: Storing competitive benchmark data in the database

**What:** Creating a `public.competitor_benchmarks` table and inserting BallotReady feature
comparisons as rows.

**Why bad:** Benchmark data is disposable research that becomes stale the moment competitors
update their products. It has no foreign keys to the application schema, no users querying it
at runtime, and no need for ACID guarantees.

**Instead:** Markdown table in `.planning/research/COMPETITOR-BENCHMARK.md`. Manually updated,
version-controlled in git alongside the milestone.

---

### Anti-Pattern 3: Gap report as a database table

**What:** `public.gap_items` table with severity, tier, status columns.

**Why bad:** Gap items are planning artifacts, not runtime data. They map to GitHub issues or
phase plans — not to anything a user sees. Storing them in Supabase adds schema complexity with
zero runtime value.

**Instead:** `GAP-REPORT-v2026.4.3.md` in `.planning/`. Individual gap items become phase plan
files in `.planning/phases/` when they enter the execution queue.

---

### Anti-Pattern 4: Running audit queries against the dev database

**What:** Pointing `DATABASE_URL` at `EV-Backend-Dev` for audit queries.

**Why bad:** The dev database does not have the full Monroe County seed data. Audit results
against dev would misrepresent actual coverage. The `audit-is-appointed.ts` precedent explicitly
runs against production.

**Instead:** Use the production `DATABASE_URL` (Supabase project `kxsdzaojfaibhuzmclfq`).

---

### Anti-Pattern 5: Inferring stance gaps from `politician_answers` count = 0

**What:** Treating zero rows in `inform.politician_answers` as "no stance data exists."

**Why bad:** A candidate with `politician_id = NULL` (unlinked challenger) has no
`politician_answers` rows by definition — not because stances are missing, but because no
politician record was linked. The audit must distinguish:
1. Unlinked challenger — `politician_id IS NULL` → stance data structurally impossible
2. Linked incumbent — `politician_id IS NOT NULL` AND `stance_count = 0` → genuine gap

**Instead:** Filter `WHERE rc.politician_id IS NOT NULL` when computing stance gaps. Report
unlinked challengers separately as a candidate-linkage gap, not a stance gap.

---

## Scalability Considerations

| Concern | Now | Notes |
|---------|-----|-------|
| Audit query performance | Fast — small dataset | Monroe County has ~100 candidates; all joins are indexed |
| Audit script runtime | ~5-10 seconds | Single DB connection, sequential reads |
| Gap report maintenance | Manual | One document per milestone — not intended to be automated |
| Competitor benchmark staleness | High | BallotReady/Vote411 update continuously; snapshot at time of audit only |

---

## Sources

All findings from direct code inspection — no external verification required for integration questions.

- `ev-accounts/backend/scripts/seed-monroe-county-2026-primary.sql` — ground-truth race/candidate structure
- `ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql` — candidate linking pattern
- `ev-accounts/backend/scripts/push-monroe-county-research.ts` — existing stance/quote push pattern
- `ev-accounts/backend/scripts/auditHeadshots.ts` — audit script pattern (Pool, dotenv, stdout, stderr)
- `ev-accounts/backend/scripts/audit-is-appointed.ts` — read-only audit pattern with structured output
- `ev-accounts/backend/src/lib/electionService.ts` — inferDistrictType(), election query shapes
- `ev-accounts/backend/src/lib/compassService.ts` — `inform.politician_answers` schema usage
- `ev-accounts/backend/migrations/026_inform_schema_repair_and_candidates.sql` — `politician_answers`, `politician_context` table definitions
- `ev-accounts/backend/migrations/042_election_schema.sql` — `elections`, `races`, `race_candidates` table definitions
- `ev-accounts/backend/migrations/038_compass_additions.sql` — `compass.quote_verdicts` and `essentials.quotes` FK
- `ev-accounts/backend/migrations/055_compass_topic_key.sql` — `essentials.quotes.topic_key` column (key join field)
- `.planning/PROJECT.md` — v2026.4.3 milestone goals
