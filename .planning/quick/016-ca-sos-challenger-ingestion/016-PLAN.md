---
phase: quick
plan: 016
type: research-then-execute
wave: 1
depends_on: []
files_modified:
  - backend/scripts/ingest-ca-sos-2026-challengers.ts
  - backend/scripts/seed-la-county-2026-primary-state-federal.sql
autonomous: false

must_haves:
  truths:
    - "GET /essentials/elections-by-address for a downtown LA address returns challenger candidates alongside incumbents for all race tiers"
    - "Challengers are stored in essentials.race_candidates with is_incumbent=false"
    - "Script is idempotent — re-run produces no duplicates"
  artifacts:
    - path: "backend/scripts/ingest-ca-sos-2026-challengers.ts"
      provides: "CA SoS 2026 primary challenger ingestion script"
      contains: "race_candidates.*is_incumbent.*false"
---

# Quick 016 — CA SoS 2026 Challenger Ingestion

## Goal

Add challenger candidates to the 2026 LA County Primary races. Incumbents are already seeded. This task sources challenger filings from the CA Secretary of State and loads them as `race_candidates` records.

---

## What was already built (session 2026-04-13)

### Geofences
- All 80 CA Assembly + 40 CA Senate district boundaries loaded into `essentials.geofence_boundaries` (TIGER/Line 2024, MTFCC G5210/G5220, state='CA')
- Script: `backend/scripts/load-ca-state-boundaries.ts`
- Old corrupt entries (state='06', swapped MTFCCs) deleted and replaced

### electionService.ts bug fixed
- The `ST_Covers` geofence join now includes MTFCC disambiguation:
  ```sql
  JOIN essentials.geofence_boundaries gb
    ON gb.geo_id = d.geo_id
    AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gb.mtfcc = d.mtfcc)
  ```
- Root cause: county FIPS codes (e.g. `06037` = LA County) share the same format as legislative district GEOIDs (e.g. `06037` = Assembly D37). Without MTFCC, the county polygon matched the wrong legislative districts across all of LA County.

### Race records seeded
16 new races added to the `2026 LA County Primary` election (id: `1ebca37f-cf96-47f4-bc2b-47ef266721fe`):

| Race | office_id | district_type |
|------|-----------|---------------|
| CA State Assembly District 54 | a2f330df-16cd-42be-bcd5-006e57cf1d69 | STATE_LOWER |
| CA State Senate District 26 | 111f6884-8eae-4447-9fbb-df0e281e0eb4 | STATE_UPPER |
| U.S. Representative District 34 | 4e1ab309-a5d2-4c98-9a0d-11034f4896b2 | NATIONAL_LOWER |
| LA County Sheriff | dd507d10-a106-42e6-a275-2385154aa072 | COUNTY |
| LA County Assessor | ada7f5e7-d955-4c14-ac0b-ff390d4bddae | COUNTY |
| LAUSD Board of Education District 2 | 013b6024-cbda-4746-8826-e33baa541081 | SCHOOL |
| LAUSD Board of Education District 4 | 6b906b77-f0f9-4ff9-b852-b0a11bfa4af6 | SCHOOL |
| LAUSD Board of Education District 6 | 0b95c93e-4b15-48c7-a21f-83155f7c5a24 | SCHOOL |
| CA Governor | NULL (statewide) | — |
| CA Lieutenant Governor | NULL | — |
| CA Attorney General | NULL | — |
| CA Secretary of State | NULL | — |
| CA State Treasurer | NULL | — |
| CA State Controller | NULL | — |
| CA Insurance Commissioner | NULL | — |
| CA Superintendent of Public Instruction | NULL | — |

### Incumbents seeded
All confirmed incumbents are in `essentials.race_candidates` with `politician_id` linked:
- Isaac G. Bryan (Assembly D54)
- Jimmy Gomez (CD-34)
- Robert Luna (Sheriff)
- Scott Schmerelson (LAUSD D2)
- Nick Melvoin (LAUSD D4)
- Kelly Gonez (LAUSD D6)
- Eleni Kounalakis (Lt. Gov)
- Rob Bonta (AG)
- Shirley N. Weber (Sec of State)
- Fiona Ma (Treasurer)
- Malia M. Cohen (Controller)
- Ricardo Lara (Insurance Commissioner)
- Tony Thurmond (Supt. of Public Instruction)

**Open seats (no incumbent seeded):**
- CA Governor — Newsom term-limited
- CA State Senate District 26 — Ben Allen potentially term-limited (verify with CA SoS)
- LA County Assessor — Jeff Prang term verification pending

---

## Key schema facts

```sql
-- elections table: id, name, election_date, election_type, jurisdiction_level, state
-- races table: id, election_id, office_id (nullable), position_name, primary_party (NULL for all CA races — top-2 jungle primary), seats
-- race_candidates: id, race_id, politician_id (nullable), full_name, first_name, last_name, is_incumbent, candidate_status ('active'|'withdrawn'|'filed'), source, external_id

-- Unique constraint on races (for CA/NULL primary_party — use partial index):
ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING

-- Statewide races (Governor, AG, etc.) use office_id IS NULL and are matched by election.state = 'CA'
-- District races use office_id → offices → districts → geofence_boundaries (ST_Covers)
```

**CRITICAL — CA uses top-2 jungle primary:**
- `primary_party = NULL` for ALL CA race records
- Do NOT use `ON CONFLICT (election_id, position_name, primary_party)` — this won't match the partial unique index
- Always use: `ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING`

---

## What this task needs to build

### Primary deliverable: `ingest-ca-sos-2026-challengers.ts`

The CA Secretary of State publishes candidate filing data for the June 2026 primary. The script should:

1. **Fetch/parse CA SoS filing data** — research the available format (HTML, CSV, or API). The SoS candidate search is at sos.ca.gov. Check if there's a bulk download or if it requires scraping.

2. **Match candidates to races** by position name + district number. The races already exist in the DB — the script maps filer → race, not filer → new race.

3. **Insert challengers** as `race_candidates` with:
   - `is_incumbent = false`
   - `candidate_status = 'active'` (or `'filed'` if not yet certified)
   - `source = 'ca_sos_2026'`
   - `external_id` = SoS filing ID if available
   - `politician_id` = linked if politician exists in `essentials.politicians`, NULL otherwise

4. **Idempotent** — `WHERE NOT EXISTS` on (race_id, external_id) or (race_id, full_name)

### Look at these existing scripts for patterns
- `backend/scripts/discover-indiana-candidates.ts` — candidate discovery from campaign finance (name parsing, idempotency, SAVEPOINT pattern)
- `backend/scripts/discover-cal-access-candidates.ts` — CA-specific campaign finance ingestion (already exists — check if it has useful overlap)
- `backend/scripts/importElectionData.ts` — the `--source indiana-sos` and `--source la-roster` handlers (race/candidate insert pattern)
- `backend/scripts/confirm-cal-access.ts` — CA Access confirmation flow

### Secondary: LAUSD board sub-district geofences
LAUSD board races (D2, D4, D6) currently appear for ANY address inside the LAUSD boundary because the offices are all linked to the LAUSD at-large district. Need sub-district geofences so a voter only sees their specific board race.

Source: LAUSD publishes board district shapefiles. Research where to get them (lausd.net or LA County GIS portal).

---

## Delivery note to Essentials team
`ESSENTIALS-NOTE-elections-state-federal-2026-04-13.md` — already written and in repo root. Contains full technical explanation of what was fixed and what's coming. Share this with the Essentials Claude instance.

---

## Verification query (run after ingestion to confirm)
```sql
SELECT
  COALESCE(d.district_type, 'STATEWIDE') AS tier,
  r.position_name,
  COUNT(rc.id) AS total_candidates,
  COUNT(rc.id) FILTER (WHERE rc.is_incumbent) AS incumbents,
  COUNT(rc.id) FILTER (WHERE NOT rc.is_incumbent) AS challengers
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.offices o ON o.id = r.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.candidate_status != 'withdrawn'
WHERE e.name = '2026 LA County Primary'
  AND r.position_name IN (
    'CA State Assembly District 54','CA State Senate District 26',
    'U.S. Representative District 34','LA County Sheriff','LA County Assessor',
    'LAUSD Board of Education District 2','LAUSD Board of Education District 4',
    'LAUSD Board of Education District 6','CA Governor','CA Lieutenant Governor',
    'CA Attorney General','CA Secretary of State','CA State Treasurer',
    'CA State Controller','CA Insurance Commissioner',
    'CA Superintendent of Public Instruction'
  )
GROUP BY d.district_type, r.position_name
ORDER BY d.district_type NULLS LAST, r.position_name;
```
