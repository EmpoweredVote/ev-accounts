---
phase: quick
plan: 017
type: execute
wave: 1
depends_on: ["016"]
files_modified:
  - backend/scripts/ingest-ca-sos-2026-challengers.ts
autonomous: true

must_haves:
  truths:
    - "All 16 races in the 2026 LA County Primary have their CA SoS certified challengers loaded"
    - "Script is idempotent -- re-run produces no duplicates (0 new inserts on second run)"
    - "Assembly District 54 data discrepancy is identified and resolved (SoS says Mark Gonzalez is AD-54 incumbent, Isaac Bryan is AD-55)"
    - "County-level challengers (Sheriff, Assessor) from lavote.gov are included"
  artifacts:
    - path: "backend/scripts/ingest-ca-sos-2026-challengers.ts"
      provides: "Complete CA SoS 2026 primary challenger data for all 16 races"
      contains: "race_candidates.*is_incumbent.*false"
  key_links:
    - from: "backend/scripts/ingest-ca-sos-2026-challengers.ts"
      to: "essentials.race_candidates"
      via: "pool.query INSERT"
      pattern: "INSERT INTO essentials.race_candidates"
---

# Quick 017 -- Import Verified 2026 LA County Primary Challengers (CA SoS Certified List)

## Goal

Add ALL certified challengers from the CA Secretary of State Official Certified List of Candidates (published 2026-03-26) to the 16 races in the `2026 LA County Primary` election. The existing ingestion script (`ingest-ca-sos-2026-challengers.ts`) currently only has Governor challengers from Calmatters. This task populates challengers for ALL remaining races using the authoritative SoS source, plus county-level challengers from lavote.gov.

Purpose: Voters querying `GET /essentials/elections-by-address` for LA County addresses should see the full competitive field for every race, not just incumbents.

Output: Updated `ingest-ca-sos-2026-challengers.ts` with complete challenger data; script run with `--commit`.

---

## Research Completed (pre-plan)

### Source: CA SoS Certified List of Candidates
- **URL:** http://elections.cdn.sos.ca.gov/statewide-elections/2026-primary/cert-list-candidates.pdf
- **Published:** 2026-03-26 (53-page PDF)
- **Covers:** All statewide, state legislative, and federal races

### Source: LA County Registrar-Recorder Candidate Filing Status
- **URL:** https://www.lavote.gov/Apps/CandidateList/Index?id=4338
- **Updated:** 2026-04-10
- **Covers:** County-level races (Sheriff, Assessor)

### LAUSD Board Finding
LAUSD Board of Education Districts 2, 4, and 6 are **NOT on the June 2, 2026 primary ballot**. They do not appear on either the CA SoS certified list or the LA County candidate filing list. LAUSD Board elections run on a different cycle. The existing race records and incumbents in the DB should be reviewed separately (out of scope for this task).

### Data Quality Issue: Assembly District 54 vs 55
The CA SoS Certified List shows:
- **Assembly District 54** incumbent: **Mark Gonzalez** (uncontested)
- **Assembly District 55** incumbent: **Isaac G. Bryan** (3 challengers: Ashley M. Brown, Keith G. Cascio, William "Billion" Campbell)

The DB currently has a race record named "CA State Assembly District 54" with Isaac G. Bryan seeded as incumbent. **This is wrong -- Bryan is District 55, not 54.** The script must flag this and the executor should:
1. Verify the DB race record's `office_id` links to the correct district geofence
2. If the office is actually AD-55's geofence but named "District 54", rename the race
3. If the office is AD-54's geofence, then the incumbent should be Mark Gonzalez, not Bryan

---

## Verified Challenger Data (from SoS PDF + lavote.gov)

### Statewide Races (SoS Certified)

**Governor (open seat -- Newsom term-limited, all are challengers):**
Already has 9 Calmatters challengers. SoS list has ~61 total candidates. Add the remaining SoS-certified candidates NOT already in DB. Key additions from SoS (not in Calmatters list):
- Akinyemi Agbede, Mohammad Arif, Larry Azevedo, Carolina Buhler, Louis A. De Barraicua, Sophia Edum-a-Sam, Derek Grasty, Joel E. Jacob, Gary Howard Kidgell, Matthew Chase Levy, Barack D. Obama Shaw, Thunder Parley, Raji Rab, Satish Rao, Scott P Shields, Erin "Zez" Zezulak, James Athans Jr., Patricia De Luca Basualdo, Randeep S. Dhillon, Rafael M. Hernandez, Alicia Olivia Lapp, Leo Naranjo IV, Tim Nelson, Gretha Solorzano, Leo Samuel Zacky, David Zickefoose, Tom Woodard, Ramsey Robinson, Naomi Bar-Lev, Joseph Cabrera, Elaine Culotti, LivingForGod AndCountry DeMott, Serge Fiankan, Lukasz Adam Filinski, Max Fomin, Don J. Grundmann, Jon Henderson, Lewis Herms, Dawit Kellel, Anne Komarovsk, Duane Terrence Loynes Jr., Amanda Martin, Brent Maupin, Daniel Mercuri, Mauro Alberto Orozco, Reza Safarnejad, Sam Sandak, Christine R. Sarmiento, Frederic C. Schultz, Margaret Trowe, Nancy D. Young

**Lieutenant Governor (no incumbent marker on SoS list -- Kounalakis running for Treasurer):**
Open seat. All are challengers:
- Josh Fryday, Janelle Kellman, Jeyson Lopez, Fiona Ma, Oliver Ma, Tim Myers, Abdur Rahman Sikder, Michael Tubbs, Ebie Lynch, David Collenberg, David Fennell, Gloria Romero, Skip Shelton, Alice Stek, Rakesh Christian, Sean Collinson

**Attorney General (Rob Bonta is incumbent*):**
- Michael E. Gates (challenger)
- Marjorie Mikels (challenger)

**Secretary of State (Shirley N. Weber is incumbent*):**
- Donald P. (Don) Wagner (challenger)
- Gary N. Blenner (challenger)
- Michael Feinstein (challenger)

**Controller (Malia M. Cohen is incumbent*):**
- Herb W Morgan (challenger)
- Meghann Adams (challenger)

**Treasurer (open seat -- no incumbent marked):**
All challengers:
- Anna M. Caballero, Eleni Kounalakis, Tony Vazquez, Jennifer Hawks, David Serpa, Glenn Turner

**Insurance Commissioner (open seat -- Ricardo Lara term-limited, not on SoS list):**
All challengers:
- Ben Allen, Steven Craig Bradford, Jane Kim, Patrick Wolff, Eric Thor Aarnio, Merritt Farren, Robert P Howell, Stacy A. Korsgaden, Sean Lee, Keith W. Davis, Eduardo "Lalo" Vargas

**Superintendent of Public Instruction (open seat -- Thurmond running for Governor):**
All challengers:
- Richard Barrera, Wendy Castaneda Leal, Nichelle M. Henderson, Frank Lara, Ainye Long, Gus Mattammal, Al Muratsuchi, Josh Newman, Anthony Rendon, Sonja Shaw

### District Races (SoS Certified)

**State Senate District 26 (open seat -- no incumbent marked):**
All challengers:
- Paul A. Bowers, Juan Camacho, Wendy Carrillo, Sara Hernandez, Maebe Pudlo, Sarah Rascon, Claudia Agraz, Sang "Sam Shin" Masog

**U.S. Representative District 34 (Jimmy Gomez is incumbent):**
- Arthur Dixon (challenger)
- Angela Gonzales-Torres (challenger)
- Robert George Lucero Jr. (challenger)
- Calvin Lee (challenger)
- Loren Colin (challenger)

**State Assembly District 54 (Mark Gonzalez is incumbent -- UNCONTESTED):**
No challengers to add. But see data quality issue above re: DB having wrong incumbent.

### County Races (lavote.gov)

**LA County Sheriff (Robert Luna is incumbent):**
Challengers:
- Mike Bornman, Karla Carranza, Brendan Corbett

**LA County Assessor (open seat -- only 1 candidate filed):**
- Stephen A. Adamus (sole candidate)

### School Board Races

**LAUSD Board D2, D4, D6:** NOT on June 2026 ballot. No action needed.

---

<objective>
Update `ingest-ca-sos-2026-challengers.ts` with the complete CA SoS Certified List challenger data for all 16 races, plus LA County Sheriff and Assessor challengers from lavote.gov. Run with `--commit` to load into production DB.

Purpose: Complete the challenger data for the 2026 LA County Primary so voters see the full competitive field.
Output: Updated script with ~100+ challenger entries; DB populated.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/scripts/ingest-ca-sos-2026-challengers.ts
@.planning/quick/016-ca-sos-challenger-ingestion/016-SUMMARY.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Investigate Assembly District 54 data discrepancy</name>
  <files>backend/scripts/ingest-ca-sos-2026-challengers.ts</files>
  <action>
  Query the DB to check the Assembly District 54 race record:

  ```sql
  SELECT r.id, r.position_name, r.office_id,
         o.title as office_title, d.geo_id, d.district_type, d.mtfcc,
         rc.full_name, rc.is_incumbent
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  LEFT JOIN essentials.offices o ON o.id = r.office_id
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
  WHERE e.name = '2026 LA County Primary'
    AND r.position_name LIKE '%Assembly%'
  ```

  Also check Assembly District 55:
  ```sql
  SELECT o.id, o.title, d.geo_id, d.district_number, d.district_type
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.title LIKE '%Assembly%54%' OR o.title LIKE '%Assembly%55%'
  ORDER BY o.title
  ```

  Based on findings:
  - If the race's office_id points to district 55's geofence, rename the race position_name from "CA State Assembly District 54" to "CA State Assembly District 55" and update the incumbent record's full_name/first_name/last_name if it says Isaac Bryan
  - If the race's office_id points to district 54's geofence, then the incumbent should be Mark Gonzalez. Update the incumbent candidate record and check if we also need an AD-55 race.
  - Log all findings for the summary.

  Do NOT proceed to Task 2 until this discrepancy is resolved. The resolution determines which challengers go where.
  </action>
  <verify>
  Run the query above again after any corrections. The race position_name should match the SoS certified list, and the incumbent should match the SoS incumbent marker.
  </verify>
  <done>Assembly district race record matches CA SoS certified data (correct district number, correct incumbent name).</done>
</task>

<task type="auto">
  <name>Task 2: Add all remaining challengers to ingestion script and run</name>
  <files>backend/scripts/ingest-ca-sos-2026-challengers.ts</files>
  <action>
  Update the CHALLENGERS array in `ingest-ca-sos-2026-challengers.ts` to include ALL certified candidates from the sources documented above. Use the existing `c()` helper function pattern.

  Important rules:
  - Source for statewide/state legislative/federal races: `'ca-sos-2026'`
  - Source for county races (Sheriff, Assessor): `'lavote-2026'`
  - Do NOT add candidates who are already marked as incumbents in the DB (they already exist as `is_incumbent=true` race_candidates)
  - Do NOT add Eric Swalwell (already in DB as withdrawn)
  - For the Governor race, the Calmatters-sourced challengers already in the array should be kept; add the remaining SoS-certified candidates that are NOT already in the array. Compare names carefully to avoid duplicates.
  - For Lt. Governor: Eleni Kounalakis is already seeded as incumbent. She is running for Treasurer in 2026, not seeking re-election as Lt. Gov. Check if she should remain as incumbent in the Lt. Gov race or be removed. If she's on the SoS Lt. Gov incumbent list, leave her; otherwise handle appropriately. (She is NOT on the Lt. Gov SoS list -- she's on the Treasurer list. So the Lt. Gov incumbent record may need to be set to is_incumbent=false or removed.)
  - For Fiona Ma: She is listed as Treasurer incumbent in the DB, but on the SoS Lt. Gov list (running for Lt. Gov, not re-running for Treasurer). Check how the DB handles this.
  - For Insurance Commissioner: Ricardo Lara (current incumbent) is NOT on the SoS list (term-limited). The DB may have him as incumbent. If so, he should be marked withdrawn or removed. All 11 candidates are challengers.
  - For Superintendent: Tony Thurmond (current incumbent) is NOT on the SoS Supt. list -- he's running for Governor. Same situation -- mark existing incumbent as withdrawn/not-seeking if present.
  - For LAUSD Board D2/D4/D6: Do NOT add any challengers -- these races are not on the June 2026 ballot. Add a comment in the script noting this finding.
  - For Assembly District 54: Depends on Task 1 resolution. If AD-54 is uncontested (Mark Gonzalez only), no challengers to add. If Bryan's race is now correctly labeled AD-55, add the 3 challengers (Ashley M. Brown, Keith G. Cascio, William "Billion" Campbell) to the AD-55 race.

  Update the script header comment to cite the CA SoS source URL and date (2026-03-26).

  After updating, run:
  ```bash
  cd backend && npx tsx scripts/ingest-ca-sos-2026-challengers.ts
  ```
  (dry-run first to verify), then:
  ```bash
  cd backend && npx tsx scripts/ingest-ca-sos-2026-challengers.ts --commit
  ```

  Run the verification query from the 016-PLAN to confirm all races have the expected candidate counts.
  </action>
  <verify>
  1. Dry-run shows all races found, no "RACE NOT FOUND" warnings
  2. `--commit` run succeeds with expected insert count
  3. Verification query shows challenger counts matching the SoS certified list for each race
  4. Second `--commit` run produces 0 inserts (idempotency confirmed)
  </verify>
  <done>
  All 16 races in the 2026 LA County Primary have their certified challengers loaded. Script is idempotent. Verification query shows correct incumbent/challenger counts per race matching the CA SoS certified list.
  </done>
</task>

</tasks>

<verification>
Run the verification query from 016-PLAN:

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
GROUP BY d.district_type, r.position_name
ORDER BY d.district_type NULLS LAST, r.position_name;
```

Expected approximate counts (active candidates, not withdrawn):
- CA Governor: ~60+ total (open seat)
- CA Lieutenant Governor: 16+ total (open seat -- verify Kounalakis handling)
- CA Attorney General: 3 total (1 incumbent + 2 challengers)
- CA Secretary of State: 4 total (1 incumbent + 3 challengers)
- CA State Controller: 3 total (1 incumbent + 2 challengers)
- CA State Treasurer: 6 total (open seat)
- CA Insurance Commissioner: 11 total (open seat)
- CA Superintendent: 10 total (open seat)
- State Senate D26: 8 total (open seat)
- U.S. Representative D34: 6 total (1 incumbent + 5 challengers)
- Assembly D54 or D55: depends on Task 1 resolution
- LA County Sheriff: 4 total (1 incumbent + 3 challengers)
- LA County Assessor: 1-2 total (depends on incumbent status)
- LAUSD Board D2/D4/D6: incumbents only (no challengers -- not on ballot)
</verification>

<success_criteria>
1. All statewide, state legislative, federal, and county challengers from the CA SoS Certified List and lavote.gov are in `essentials.race_candidates`
2. Assembly District 54/55 discrepancy is resolved with correct data
3. Incumbent status flags are accurate (no incumbent marked for open seats)
4. Script is idempotent (second run = 0 inserts)
5. LAUSD Board races are documented as not on June 2026 ballot
</success_criteria>

<output>
After completion, create `.planning/quick/017-import-verified-2026-la-county-primary-c/017-SUMMARY.md`
</output>
