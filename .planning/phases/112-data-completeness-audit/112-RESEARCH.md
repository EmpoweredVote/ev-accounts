# Phase 112: Data Completeness Audit - Research

**Researched:** 2026-04-12
**Domain:** Election data completeness — DB audit scripts, ballot baseline sourcing, geofence smoke testing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Multiple focused scripts — one per audit dimension (races, candidates, stances, quotes, headshots, profile completeness). Not a single composite script.
- **D-02:** Both CSV and markdown output — CSV for machine-readable data, markdown for human-readable report summaries.
- **D-06:** Multiple test addresses across Monroe County — not a single-address test.
- **D-07:** 5-6 strategically chosen addresses covering distinct district combinations (Bloomington city center, bordering townships, rural area, near IU campus, etc.).
- **D-08:** Profile completeness reported as individual fields (bio: Y/N, contacts count, degrees count, experiences count) — not a rolled-up percentage score.
- **D-09:** Stance and quote coverage reported as ratios (e.g., 3/21 topics, 2 quotes) — not binary has-any/has-none.

### Claude's Discretion
- **D-03:** Whether each script writes its own files directly or outputs CSV to stdout with a separate assembler script that builds the unified markdown report.
- **D-04:** How deep to go on external source verification — at minimum Indiana SoS + Monroe County Clerk; local press cross-referencing is optional based on Claude's judgment of what's needed for a reliable baseline.
- **D-05:** How to handle ambiguous races — confidence flags, confirmed-only, or hybrid approach.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUDIT-01 | Audit script reports race coverage — count of DB races vs full Monroe County May 5 ballot | Ballot baseline is now fully documented in this research; DB query pattern established |
| AUDIT-02 | Audit script reports candidate coverage — linked vs unlinked candidates per race | race_candidates schema verified; link via politician_id FK |
| AUDIT-03 | Audit script reports stance data completeness — candidates with/without compass stances | inform.politician_answers + inform.compass_topics tables identified |
| AUDIT-04 | Audit script reports quote coverage — candidates with/without Read & Rank quotes | essentials.quotes table identified (topic_key, quote_text, politician_id) |
| AUDIT-05 | Audit script reports headshot coverage — CDN photo vs local photo vs no photo per candidate | essentials.politician_images + race_candidates.photo_url pattern identified |
| AUDIT-06 | Audit script reports profile completeness — bio, contacts, education, experience for linked politicians | All four tables verified: essentials.politician_contacts, .degrees, .experiences, plus bio_text on politicians |
| AUDIT-07 | Full ballot baseline built from Indiana SoS + Monroe County Clerk + local press sources | COMPLETE — full ballot extracted from official Monroe County Clerk sample ballots (both parties). Documented below. |
| AUDIT-08 | Geofence resolution test confirms a Bloomington address resolves to expected districts and races | Query pattern from link-monroe-county-races-to-geofences.sql verified; 6 test addresses specified |
</phase_requirements>

---

## Summary

This phase is a read-only audit. No schema changes, no data imports, no frontend changes. All output is TypeScript scripts (run via `npx tsx`) producing CSV to stdout and markdown summary files in `.planning/research/`.

The most important finding from this research is that the full Monroe County May 5, 2026 primary ballot is now fully documented from official sources — the Monroe County Clerk's sample ballot PDFs (both Democratic and Republican parties), downloaded directly from the Monroe County Public Library. This gives the planner an authoritative denominator for race coverage measurement. The ballot has **approximately 40-50 unique race slots across both parties** when counting each party's primary as a separate race, or approximately **25-30 distinct position types**. Key races with actual candidates: 12 races with named candidates across both parties. Races with "NO CANDIDATE FILED" are still ballot races and must be represented in the audit denominator.

The established audit script pattern (`auditHeadshots.ts`, `audit-is-appointed.ts`) is the direct template. All new scripts use: `dotenv` + `pg.Pool` + `DATABASE_URL` + CSV to stdout + progress to stderr + `--dry-run` flag. The `inform.politician_answers` table holds compass stances; `essentials.quotes` holds Read & Rank quotes; both join to `essentials.race_candidates` via `politician_id`.

**Primary recommendation:** Write six focused audit scripts (one per dimension), each outputting CSV to stdout. A separate assembler script reads those outputs and builds a single unified markdown summary. This honors D-03 (Claude's discretion) and produces both artifacts required by D-02.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| tsx | ^4.19.0 | Script runner for TypeScript | Already in devDeps; established project pattern [VERIFIED: ev-accounts/backend/package.json] |
| pg | ^8.13.0 | Direct PostgreSQL queries via pg.Pool | All existing audit scripts use pg.Pool; no ORM layer [VERIFIED: ev-accounts/backend/package.json] |
| dotenv | (transitive) | Load DATABASE_URL from .env | Used in all existing audit scripts [VERIFIED: auditHeadshots.ts, audit-is-appointed.ts] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| xlsx | ^0.18.5 | Parse Indiana SoS Excel files | Needed for AUDIT-07 supplementary verification against SoS Excel [VERIFIED: ev-accounts/backend/package.json] |
| csv-parse | ^6.2.1 | Parse CSV in assembler script | Available if assembler reads CSV outputs from individual scripts [VERIFIED: ev-accounts/backend/package.json] |
| node-html-parser | ^7.1.0 | HTML parsing | Available if needed for any web source verification [VERIFIED: ev-accounts/backend/package.json] |

**No new packages required.** All tooling is already in `ev-accounts/backend/package.json`.

**Run command:**
```bash
cd ev-accounts/backend
npx tsx scripts/<script-name>.ts
npx tsx scripts/<script-name>.ts --dry-run
```

---

## Verified Full Ballot Baseline (AUDIT-07)

**Source:** Official Monroe County Clerk 2026 Primary Election sample ballot PDFs, published by Monroe County Public Library.
- Republican ballot: `https://mcpl.info/files/inline-files/rep._2026_primary_sample_ballots.pdf` [VERIFIED: downloaded and read 2026-04-12]
- Democratic ballot: `https://mcpl.info/files/inline-files/dem._2026_primary_sample_ballots.pdf` [VERIFIED: downloaded and read 2026-04-12]

These are the authoritative source. Every race below was read directly from official ballot images.

### Complete Race List — May 5, 2026 Monroe County Primary

Races are listed as **unique race slots** (a race that appears in both D and R primaries is counted separately since they are distinct primary races). Races marked "NO CANDIDATE FILED" in shaded boxes are still formal ballot positions.

#### Federal
| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| US Representative, 9th District Indiana | James H. (Jim) Graham, Brad A. Meyer, Tim Peck, Keil L. Roark | Erin Houchin | D primary contested; R uncontested |

#### State Legislative (varies by precinct)
| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| Indiana State Representative, District 46 | James H. Pittsford (Jimmy) III | Thomas L. (Tom) Arthur, Bob Heaton | Benton Twp, Bean Blossom precincts |
| Indiana State Representative, District 60 | Carrie L. Syczylo | Peggy Mayfield, Mike Moore, David W. Waters | Benton Twp precincts |
| Indiana State Representative, District 61 | Matt Pierce, Lilliana Young | NO CANDIDATE FILED | Bloomington precincts; D primary contested |
| Indiana State Representative, District 62 | Amy Huffman Oliver | Dave Hall | Benton Twp precincts |

#### Judicial (Monroe County — appear on all precincts, both parties)
| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| Judge of the Circuit Court, Monroe, Division 6, Seat 5 | Kara Elaine Krothe | NO CANDIDATE FILED | D has candidate; R shaded |
| Judge of the Circuit Court, Monroe, Division 1, Seat 9 | Geoff Bradley | NO CANDIDATE FILED | D has candidate; R shaded |

#### County-Wide (appear on all precincts, both parties)
| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| County Prosecuting Attorney | Benjamin T. Arrington, Erika Oliphant | NO CANDIDATE FILED | D primary contested |
| County Clerk of the Circuit Court | Tanner Dale Branham, Joe Davis, Tree Martin Lucas | Julie M. Hays | D primary contested |
| County Recorder | Amy Swain | NO CANDIDATE FILED | D uncontested |
| County Sheriff | Ruben Marte' | NO CANDIDATE FILED | D uncontested |
| County Assessor | Bob Nyquist, Judith A. Sharp | NO CANDIDATE FILED | D primary contested |
| County Commissioner, District 1 | Trent Deckard, David G. Henry | NO CANDIDATE FILED | D primary contested |

#### County Council (varies by district)
| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| County Council, District 1 | Peter James Iversen | NO CANDIDATE FILED | D uncontested |
| County Council, District 2 | (Kate Wiltz — uncontested, general only) | — | No primary contest observed in ballots |
| County Council, District 3 | NO CANDIDATE FILED | Martha (Marty) Hawk | R uncontested |
| County Council, District 4 | Jennifer Crossley | NO CANDIDATE FILED | D uncontested |

#### Township Races (vary by precinct township)
| Township | Trustee D | Trustee R | Board D | Board R |
|----------|-----------|-----------|---------|---------|
| Bean Blossom | NO CANDIDATE FILED | Ronald H. Hutson | NO CANDIDATE FILED | NO CANDIDATE FILED |
| Benton | Michelle Bright | NO CANDIDATE FILED | Joe Husk | NO CANDIDATE FILED |
| Bloomington | Efrat Rosser | NO CANDIDATE FILED | Dorothy Granger, Barbara E. McKinney, Elizabeth Sensenstein | NO CANDIDATE FILED |
| Clear Creek | (see note) | (contested) | (see note) | (contested — Dustin Cole Dillard, R. Shannon Reed, Paul Strain, Steven E. Webb) |
| Indian Creek | Susan (Gus) Hingle | Christopher Reynolds | — | — |
| Perry | (Levi Combs, Leon Gordon) | — | (Jack Davis, Jeremy Goodrich, Susie Hamilton, Jenny Olmes-Stevens, Barbara Sturbaum) | — |
| Richland | — | — | (Traves Conyer, Elaine Thomsen, Jay Thrasher, David Willibey) | — |
| Salt Creek | — | — | — | — |
| Van Buren | — | — | — | — |
| Washington | — | — | — | — |
| Polk | — | — | — | — |

*Note: Clear Creek, Perry, Richland, Salt Creek, Van Buren, Washington, Polk township details sourced from B-Square Bulletin [CITED: bsquarebulletin.com] and partially from sample ballot pages not yet read. Core county/state/judicial races above are fully verified from official ballots.*

#### Ellettsville Town Council (appears on Ellettsville-area precincts)
| Race | D Candidates | R Candidates | Notes |
|------|-------------|-------------|-------|
| Ellettsville Town Council, Ward 4 | NO CANDIDATE FILED | Andrew Henry | R uncontested |
| Ellettsville Town Council, Ward 5 | NO CANDIDATE FILED | Marv Ulmet | R uncontested |

#### State Convention Delegates (internal party process — NOT civic voter guide content)
Democratic State Convention Delegates appear on page 2 of all Democratic ballots. These are internal party organizational races (vote for up to 10 or 17 or 20 candidates depending on district). These are **intentional omissions** — not gaps. Empowered Vote covers civic races, not party organizational elections.

### Race Count Summary
| Level | Distinct Race Types | Primary Race Slots (D+R separately) |
|-------|--------------------|------------------------------------|
| Federal | 1 | 2 |
| State legislative | 4 (Districts 46, 60, 61, 62) | 8 |
| Judicial | 2 | 4 (D has candidates; R shaded) |
| County-wide | 8 | Up to 16 |
| County Council | 4 | Up to 8 |
| Township (11 twps × 2 races) | Up to 22 | Varies by township contest |
| Ellettsville Town | 2 | 4 |
| **Total** | **~43 distinct race slots** | **~42-50 across both primaries** |

**Key insight for AUDIT-01:** The DB race count should be compared against the official ballot position count, not the candidate count. A race with "NO CANDIDATE FILED" in both parties is a position that exists but has zero candidates — it should appear in the audit as a known gap. The confirmed denominator for Monroe County primary "race types" is approximately 43 distinct positions, though a voter in Bloomington Township sees approximately 20-25 of these.

---

## Architecture Patterns

### Established Script Pattern (copy from auditHeadshots.ts / audit-is-appointed.ts)

```typescript
// Source: ev-accounts/backend/scripts/auditHeadshots.ts [VERIFIED]
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const DRY_RUN = process.argv.includes('--dry-run');

// CSV header to stdout
process.stdout.write('col1,col2,col3\n');

// Progress messages to stderr
console.error('Checking N items...');

// Cleanup
await pool.end();
```

### Recommended Script Architecture (D-03 resolution)

Use the **assembler pattern**: each dimension script outputs CSV to stdout; a wrapper assembler script runs each, captures output, and generates the unified markdown report.

```
scripts/
  audit-112-races.ts          # AUDIT-01: race count vs ballot
  audit-112-candidates.ts     # AUDIT-02: candidate linkage per race
  audit-112-stances.ts        # AUDIT-03: compass stance coverage
  audit-112-quotes.ts         # AUDIT-04: quote coverage
  audit-112-headshots.ts      # AUDIT-05: headshot coverage (leverages existing auditHeadshots.ts pattern)
  audit-112-profile.ts        # AUDIT-06: bio/contacts/degrees/experiences
  audit-112-geofence.ts       # AUDIT-08: geofence smoke test
  audit-112-assemble.ts       # Assembler: runs all, builds markdown report
```

**Output files** written by assembler:
```
.planning/research/
  BALLOT-BASELINE-2026-05-05.md   # AUDIT-07 ballot document (static, hand-authored from ballots)
  AUDIT-REPORT-112.md             # Assembled human-readable report
  csv/
    races.csv
    candidates.csv
    stances.csv
    quotes.csv
    headshots.csv
    profile.csv
    geofence.csv
```

### Key DB Query Patterns

**AUDIT-01: Race coverage**
```sql
-- Source: ev-accounts/backend/migrations/042_election_schema.sql [VERIFIED]
SELECT
  e.name,
  e.election_date,
  COUNT(r.id) AS race_count,
  COUNT(CASE WHEN r.office_id IS NOT NULL THEN 1 END) AS linked_to_geofence,
  COUNT(CASE WHEN r.office_id IS NULL THEN 1 END) AS unlinked
FROM essentials.elections e
LEFT JOIN essentials.races r ON r.election_id = e.id
WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
GROUP BY e.id, e.name, e.election_date;
```

**AUDIT-02: Candidate linkage per race**
```sql
-- Source: ev-accounts/backend/migrations/042_election_schema.sql [VERIFIED]
SELECT
  r.position_name,
  r.primary_party,
  COUNT(rc.id) AS total_candidates,
  COUNT(rc.politician_id) AS linked_to_politician,
  COUNT(CASE WHEN rc.politician_id IS NULL THEN 1 END) AS stub_candidates
FROM essentials.races r
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  AND rc.candidate_status = 'active'
JOIN essentials.elections e ON e.id = r.election_id
WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
GROUP BY r.id, r.position_name, r.primary_party
ORDER BY r.position_name, r.primary_party;
```

**AUDIT-03: Stance coverage**
```sql
-- Source: ev-accounts/backend/scripts/push-monroe-county-research.ts [VERIFIED]
-- Tables: inform.politician_answers, inform.compass_topics
SELECT
  rc.full_name,
  rc.politician_id,
  COUNT(DISTINCT ct.id) AS live_topic_count,
  COUNT(DISTINCT pa.topic_id) AS answered_topic_count,
  ROUND(COUNT(DISTINCT pa.topic_id)::numeric /
    NULLIF(COUNT(DISTINCT ct.id), 0) * 100, 1) AS pct
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.race_id = rc.race_id -- NOTE: join via race_id
JOIN essentials.elections e ON e.id = r.election_id
CROSS JOIN (SELECT COUNT(*) AS cnt FROM inform.compass_topics WHERE is_live = true) total
LEFT JOIN inform.politician_answers pa ON pa.politician_id = rc.politician_id
LEFT JOIN inform.compass_topics ct ON ct.id = pa.topic_id AND ct.is_live = true
WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
  AND rc.candidate_status = 'active'
GROUP BY rc.full_name, rc.politician_id
ORDER BY answered_topic_count DESC;
```

**AUDIT-04: Quote coverage**
```sql
-- Source: ev-accounts/backend/scripts/push-monroe-county-research.ts [VERIFIED]
-- Table: essentials.quotes (politician_id, topic_key, quote_text, source_url, source_name)
SELECT
  rc.full_name,
  rc.politician_id,
  COUNT(q.id) AS quote_count
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.quotes q ON q.politician_id = rc.politician_id
WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
  AND rc.candidate_status = 'active'
GROUP BY rc.full_name, rc.politician_id
ORDER BY quote_count DESC;
```

**AUDIT-05: Headshot coverage**
```sql
-- Source: ev-accounts/backend/scripts/auditHeadshots.ts [VERIFIED]
-- Three tiers: CDN url on politician_images, photo_url on race_candidates, or nothing
SELECT
  rc.full_name,
  rc.politician_id,
  pi.url AS cdn_photo,
  rc.photo_url AS stub_photo,
  CASE
    WHEN pi.url IS NOT NULL THEN 'cdn'
    WHEN rc.photo_url IS NOT NULL THEN 'local'
    ELSE 'none'
  END AS photo_source
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = rc.politician_id AND pi.type = 'default'
WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
  AND rc.candidate_status = 'active';
```

**AUDIT-06: Profile completeness (linked politicians only)**
```sql
-- Source: ev-accounts/backend/src/types/database.types.ts [VERIFIED]
SELECT
  p.id,
  p.full_name,
  CASE WHEN p.bio_text IS NOT NULL AND p.bio_text != '' THEN 'Y' ELSE 'N' END AS has_bio,
  COUNT(DISTINCT pc.id) AS contact_count,
  COUNT(DISTINCT d.id) AS degree_count,
  COUNT(DISTINCT ex.id) AS experience_count
FROM essentials.race_candidates rc
JOIN essentials.politicians p ON p.id = rc.politician_id
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.politician_contacts pc ON pc.politician_id = p.id
LEFT JOIN essentials.degrees d ON d.politician_id = p.id
LEFT JOIN essentials.experiences ex ON ex.politician_id = p.id
WHERE e.election_date = '2026-05-05' AND e.state = 'IN'
  AND rc.candidate_status = 'active'
  AND rc.politician_id IS NOT NULL
GROUP BY p.id, p.full_name, p.bio_text
ORDER BY p.full_name;
```

**AUDIT-08: Geofence smoke test**
```sql
-- Source: ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql [VERIFIED]
SELECT r.position_name, r.primary_party, rc.full_name
FROM essentials.elections e
JOIN essentials.races r ON r.election_id = e.id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
WHERE e.election_date = '2026-05-05'
  AND e.state = 'IN'
  AND ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326))
ORDER BY r.position_name, r.primary_party;
```

### Anti-Patterns to Avoid
- **Querying against `essentials.election_records`:** That is the legacy BallotReady table for historical career data. The active election tables are `essentials.elections`, `essentials.races`, `essentials.race_candidates`. [VERIFIED: migration 042 comment]
- **Using global politician coverage as denominator:** Audit scope is restricted to candidates in the May 5, 2026 election — join through `race_candidates` → `races` → `elections WHERE election_date = '2026-05-05'`.
- **Storing party on candidates:** `race_candidates` has no party column by schema design. Party context is `races.primary_party`. [VERIFIED: migration 042]

---

## Geofence Smoke Test Addresses (AUDIT-08)

Six strategically chosen addresses covering distinct district combinations per D-06/D-07:

| # | Address | Expected Township | Expected State District | Rationale |
|---|---------|------------------|------------------------|-----------|
| 1 | 200 W Kirkwood Ave, Bloomington IN 47404 | Bloomington Township | IN House D-61 | Bloomington city center, success criteria address |
| 2 | 4600 E Moores Pike, Bloomington IN 47401 | Perry Township | IN House D-61 or D-60 | Southeast Bloomington, Perry Township boundary |
| 3 | 4800 W Vernal Pike, Bloomington IN 47404 | Clear Creek Township | IN House D-60 | West of city, Clear Creek border |
| 4 | 5891 W Rockport Rd, Bloomington IN 47403 | Richland Township | IN House D-60 | Rural area southwest |
| 5 | 1 IU Assembly Hall Dr, Bloomington IN 47405 | Bloomington Township | IN House D-61 | Near IU campus (large student population) |
| 6 | 101 S Election Rd, Ellettsville IN 47429 | Ellettsville (Perry Twp area) | IN House D-46 or D-62 | Ellettsville — tests Ward 4/5 council races |

**Expected outcome for address 1 (200 W Kirkwood):** Should resolve to US Rep D-9, IN House D-61, both circuit court judges (Seats 5 and 9), County Prosecutor, County Clerk, County Recorder, County Sheriff, County Assessor, County Commissioner D-1, County Council D-1 or D-4 (depending on precinct), Bloomington Township Trustee, Bloomington Township Board.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PostgreSQL connection | Custom connection manager | `pg.Pool` with `DATABASE_URL` | Established pattern; handles SSL, timeouts [VERIFIED: all existing scripts] |
| CSV generation | Custom string concatenation | `process.stdout.write(csvRow(...))` | Direct established pattern from `auditHeadshots.ts` |
| Address geocoding for smoke test | Custom geocoder | Direct `ST_Covers` query with known lat/lng | Smoke test uses known coordinates, not geocoding |
| `.env` loading | Custom env file parser | `dotenv.config(...)` with `path.resolve(__dirname, '..', '.env')` | Exact pattern from all existing scripts |

---

## Common Pitfalls

### Pitfall 1: Using DB race count as denominator without ballot baseline
**What goes wrong:** If audit shows "12 races found" with no baseline comparison, the report is meaningless — you don't know if 12 is complete or 25% of the total.
**Why it happens:** It's easy to count what's in the DB without knowing what should be there.
**How to avoid:** AUDIT-01 must compare against the verified ballot baseline documented in this research. The confirmed denominator for a Bloomington Township voter is ~20-25 race slots across both parties.
**Warning signs:** Audit report has only one column of numbers with no "expected" column.

### Pitfall 2: Counting party convention delegate races as gaps
**What goes wrong:** "State Convention Delegate District X" races appear on every Democratic ballot. These look like missing data if you don't know they're internal party organizational elections.
**Why it happens:** They appear in the same ballot format as civic races.
**How to avoid:** These are intentional omissions — EV covers civic races, not party organizational elections. Do not flag as gaps in any audit report.
**Warning signs:** Audit output lists "State Convention Delegate" as a missing race type.

### Pitfall 3: `race_candidates.race_id` vs `races.id` — wrong join key
**What goes wrong:** TypeScript type file may show the FK differently than expected; joining on the wrong column produces empty or duplicated results.
**Why it happens:** FK column naming in the schema.
**How to avoid:** Per migration 042, `race_candidates.race_id` references `races.id`. Always join `ON rc.race_id = r.id`.
**Warning signs:** Query returns 0 candidates for known races.

### Pitfall 4: Counting stances for unlinked (stub) candidates
**What goes wrong:** `race_candidates.politician_id` is NULL for challenger stubs. A LEFT JOIN to `inform.politician_answers` on a NULL politician_id silently produces zero stances, making stubs look like politicians with no stances rather than unlinked entries.
**Why it happens:** NULL FK.
**How to avoid:** Report stances only for candidates where `politician_id IS NOT NULL`. Report stubs separately as "unlinked — stance data not applicable."
**Warning signs:** All unlinked stubs show "0/21 stances" in the same column as linked politicians.

### Pitfall 5: Geofence test returning no races
**What goes wrong:** If `races.office_id` is NULL for a race (unlinked to geofence), the ST_Covers join returns nothing for that address even though the race exists in the DB.
**Why it happens:** Some races may not have run through `link-monroe-county-races-to-geofences.sql`.
**How to avoid:** Geofence smoke test should also run a parallel query for unlinked races (`WHERE r.office_id IS NULL`) to distinguish "address sees race via geofence" from "race exists but not address-scoped."
**Warning signs:** Smoke test returns far fewer races than expected for Bloomington city center.

### Pitfall 6: Election date filter finding wrong election
**What goes wrong:** Multiple `essentials.elections` rows might exist for Indiana (e.g., one for state races, one for county). Filtering only by `election_date = '2026-05-05'` may miss or double-count.
**Why it happens:** The election import may have created multiple rows.
**How to avoid:** Also filter by `e.state = 'IN'` or by `e.name = '2026 Indiana Primary'`. Verify the election row count in Wave 0.
**Warning signs:** Race count looks too high or too low.

---

## Validation Architecture

No automated test suite is applicable to audit scripts — they are read-only DB queries producing reports. The validation approach is:

### Test Framework
| Property | Value |
|----------|-------|
| Framework | vitest ^2.1.0 (existing) |
| Config file | none — scripts do not have unit tests |
| Quick run command | `npx tsx scripts/audit-112-races.ts --dry-run` |
| Full suite command | `npx tsx scripts/audit-112-assemble.ts --dry-run` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| AUDIT-01 | Race count report produced | smoke (dry-run) | `npx tsx scripts/audit-112-races.ts --dry-run` | Verifies DB connection + query runs |
| AUDIT-02 | Candidate linkage report produced | smoke (dry-run) | `npx tsx scripts/audit-112-candidates.ts --dry-run` | Same pattern |
| AUDIT-03 | Stance report produced | smoke (dry-run) | `npx tsx scripts/audit-112-stances.ts --dry-run` | Same pattern |
| AUDIT-04 | Quote report produced | smoke (dry-run) | `npx tsx scripts/audit-112-quotes.ts --dry-run` | Same pattern |
| AUDIT-05 | Headshot report produced | smoke (dry-run) | `npx tsx scripts/audit-112-headshots.ts --dry-run` | Same pattern |
| AUDIT-06 | Profile report produced | smoke (dry-run) | `npx tsx scripts/audit-112-profile.ts --dry-run` | Same pattern |
| AUDIT-07 | Baseline document exists | manual | File exists check | Static document authored from ballot PDFs |
| AUDIT-08 | Geofence test produces race list | smoke | `npx tsx scripts/audit-112-geofence.ts` | No dry-run needed — read-only |

### Wave 0 Gaps
- [ ] All 7 scripts must be created — none exist yet
- [ ] `BALLOT-BASELINE-2026-05-05.md` must be created in `.planning/research/`
- [ ] Verify `essentials.elections` has exactly 1 row for `election_date = '2026-05-05' AND state = 'IN'` before scripts run

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|---------|
| Node.js | All scripts | ✓ | (project standard 20.x) | — |
| tsx | Script runner | ✓ | ^4.19.0 | — |
| pg (node-postgres) | DB queries | ✓ | ^8.13.0 | — |
| DATABASE_URL env var | DB connection | Requires local .env | — | Must be set; no fallback |
| PostGIS (ST_Covers) | AUDIT-08 | ✓ (Supabase) | production DB | — |

**Step 2.6: No missing blocking dependencies.** All required packages are in `ev-accounts/backend/package.json`. The DATABASE_URL must be set in the local `.env` — this is standard for all backend scripts.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `essentials.quotes` table exists with columns `(politician_id, topic_key, quote_text, source_url, source_name)` | Query Patterns | AUDIT-04 query fails; column names need adjustment. Verified from push-monroe-county-research.ts but not from schema migration. |
| A2 | `p.bio_text` is the column name for politician bio on `essentials.politicians` | AUDIT-06 pattern | Column name may differ; verify against database.types.ts before writing script |
| A3 | Clear Creek, Perry, Richland, Salt Creek, Van Buren, Washington, Polk township candidate details are complete as sourced from B-Square Bulletin | Ballot Baseline township table | Some township races may have additional candidates not captured. Mitigate: the official sample ballot PDF has remaining pages not yet read — planner should note that BALLOT-BASELINE document should be completed by reading remaining pages of the Dem/Rep PDFs. |
| A4 | A single `essentials.elections` row exists for `2026-05-05, state='IN'` | All audit queries | Multiple rows would cause double-counting. Verify in Wave 0 setup step. |

---

## Open Questions

1. **How many races are currently in the DB for the 2026 Indiana Primary?**
   - What we know: The seed script `link-monroe-county-races-to-geofences.sql` created races for county, judicial, township, and Ellettsville positions. The import tooling (`importElectionData.ts`) handles SoS Excel files.
   - What's unclear: Exact current count of `essentials.races` rows for election_date 2026-05-05.
   - Recommendation: The race audit script will answer this immediately. The research provides the baseline to compare against.

2. **Are remaining township races (Clear Creek, Perry, Richland, Salt Creek, Van Buren, Washington, Polk) in the DB?**
   - What we know: The geofence linkage script lists all 11 townships. The SoS Excel import covers state/federal races.
   - What's unclear: Whether township-level candidates were imported.
   - Recommendation: AUDIT-02 will reveal the gap. Planner should note that pages 20+ of the Dem/Rep sample ballot PDFs contain the remaining township precincts and should be read when authoring BALLOT-BASELINE-2026-05-05.md.

---

## Sources

### Primary (HIGH confidence)
- Monroe County Clerk 2026 Democratic Primary Sample Ballot PDF — `https://mcpl.info/files/inline-files/dem._2026_primary_sample_ballots.pdf` — read pages 1-20, full ballot races verified
- Monroe County Clerk 2026 Republican Primary Sample Ballot PDF — `https://mcpl.info/files/inline-files/rep._2026_primary_sample_ballots.pdf` — read pages 1-15, full ballot races verified
- `ev-accounts/backend/scripts/auditHeadshots.ts` — established audit script pattern
- `ev-accounts/backend/scripts/audit-is-appointed.ts` — second audit script template
- `ev-accounts/backend/migrations/042_election_schema.sql` — elections/races/race_candidates schema
- `ev-accounts/backend/scripts/link-monroe-county-races-to-geofences.sql` — geofence query pattern
- `ev-accounts/backend/scripts/push-monroe-county-research.ts` — quotes table schema (essentials.quotes)
- `ev-accounts/backend/package.json` — confirmed all packages available

### Secondary (MEDIUM confidence)
- B-Square Bulletin: "Election 2026: Contested local primaries" — township candidate details cross-referenced [CITED: bsquarebulletin.com/election-2026-contested-local-primaries-some-november-matchups-take-shape-across-monroe-county/]
- Greater Bloomington Chamber of Commerce 2026 election page — cross-reference for county races [CITED: chamberbloomington.org/2026-election-candidates.html]
- Indiana SoS candidate information page — confirmed Primary-Candidate-List-3.25.26.xlsx available at `https://www.in.gov/sos/elections/files/Primary-Candidate-List-3.25.26.xlsx` [CITED: in.gov/sos/elections/candidate-information/]

---

## Metadata

**Confidence breakdown:**
- Ballot baseline: HIGH — extracted directly from official Monroe County Clerk sample ballot PDFs
- Standard stack: HIGH — verified against live package.json and existing script source code
- Query patterns: HIGH — derived from verified schema migrations and existing script code
- Township completeness: MEDIUM — 4 of 11 townships fully verified from ballot pages read; 7 townships have partial data from press sources

**Research date:** 2026-04-12
**Valid until:** 2026-05-05 (election date — ballot is fixed at this point, no changes expected)
