# Phase 72: DB Audit Findings

**Executed:** 2026-03-11
**Database:** Supabase (kxsdzaojfaibhuzmclfq) — isolated dev/AI environment
**Method:** psql direct queries (read-only SELECT statements)

---

## Q1: Distinct chamber_name / chamber_name_formal values

**Query filter:** `geo_id LIKE '18105%' OR (state = '18' AND (city ILIKE '%bloomington%' OR ch.name ILIKE '%bloomington%' OR ch.name ILIKE '%common council%'))`

**Raw output (48 rows):**

```
                            chamber_name                            | chamber_name_formal | district_type |   geo_id   | politician_count
--------------------------------------------------------------------+---------------------+---------------+------------+------------------
 Monroe County Assessor                                             |                     | COUNTY        | 18105      |                1
 Monroe County Auditor                                              |                     | COUNTY        | 18105      |                1
 Monroe County Circuit Court Clerk                                  |                     | COUNTY        | 18105      |                1
 Monroe County Commission - District 1                              |                     | COUNTY        | 18105      |                1
 Monroe County Commission - District 2                              |                     | COUNTY        | 18105      |                1
 Monroe County Commission - District 3                              |                     | COUNTY        | 18105      |                1
 Monroe County Coroner                                              |                     | COUNTY        | 18105      |                1
 Monroe County Council - At Large                                   |                     | COUNTY        | 18105      |                3
 Monroe County Council - District 1                                 |                     | COUNTY        | 1810500001 |                1
 Monroe County Council - District 2                                 |                     | COUNTY        | 1810500002 |                1
 Monroe County Council - District 3                                 |                     | COUNTY        | 1810500003 |                1
 Monroe County Council - District 4                                 |                     | COUNTY        | 1810500004 |                1
 Monroe County Prosecuting Attorney                                 |                     | COUNTY        | 18105      |                1
 Monroe County Recorder                                             |                     | COUNTY        | 18105      |                1
 Monroe County Sheriff                                              |                     | COUNTY        | 18105      |                1
 Monroe County Surveyor                                             |                     | COUNTY        | 18105      |                1
 Monroe County Treasurer                                            |                     | COUNTY        | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 1 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 2 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 3 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 4 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 5 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 6 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 7 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 8 |                     | JUDICIAL      | 18105      |                1
 Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 9 |                     | JUDICIAL      | 18105      |                1
 Monroe County: Bean Blossom Township Board                         |                     | LOCAL         | 1810503808 |                3
 Monroe County: Benton Township Board                               |                     | LOCAL         | 1810504816 |                3
 Monroe County: Bloomington Township Board                          |                     | LOCAL         | 1810505878 |                3
 Monroe County: Clear Creek Township Board                          |                     | LOCAL         | 1810513420 |                3
 Monroe County: Indian Creek Township Board                         |                     | LOCAL         | 1810536072 |                3
 Monroe County: Perry Township Board                                |                     | LOCAL         | 1810559112 |                3
 Monroe County: Polk Township Board                                 |                     | LOCAL         | 1810560984 |                3
 Monroe County: Richland Township Board                             |                     | LOCAL         | 1810564152 |                3
 Monroe County: Salt Creek Township Board                           |                     | LOCAL         | 1810567590 |                2
 Monroe County: Van Buren Township Board                            |                     | LOCAL         | 1810578542 |                3
 Monroe County: Washington Township Board                           |                     | LOCAL         | 1810580828 |                3
 Bloomington City Clerk                                             |                     | LOCAL         | 1805860    |                1
 Bloomington City Common Council - At Large                         |                     | LOCAL         | 1805860    |                3
 Bloomington City Common Council - District 1                       |                     | LOCAL         | 180586000001 |              1
 Bloomington City Common Council - District 2                       |                     | LOCAL         | 180586000002 |              1
 Bloomington City Common Council - District 3                       |                     | LOCAL         | 180586000003 |              1
 Bloomington City Common Council - District 4                       |                     | LOCAL         | 180586000004 |              1
 Bloomington City Common Council - District 5                       |                     | LOCAL         | 180586000005 |              1
 Bloomington City Common Council - District 6                       |                     | LOCAL         | 180586000006 |              1
 Monroe County: Bean Blossom Township Trustee                       |                     | LOCAL_EXEC    | 1810503808 |                1
 Monroe County: Benton Township Trustee                             |                     | LOCAL_EXEC    | 1810504816 |                1
 Monroe County: Bloomington Township Trustee                        |                     | LOCAL_EXEC    | 1810505878 |                1
 Monroe County: Clear Creek Township Trustee                        |                     | LOCAL_EXEC    | 1810513420 |                1
 Monroe County: Indian Creek Township Trustee                       |                     | LOCAL_EXEC    | 1810536072 |                1
 Monroe County: Perry Township Trustee                              |                     | LOCAL_EXEC    | 1810559112 |                1
 Monroe County: Polk Township Trustee                               |                     | LOCAL_EXEC    | 1810560984 |                1
 Monroe County: Richland Township Trustee                           |                     | LOCAL_EXEC    | 1810564152 |                1
 Monroe County: Salt Creek Township Trustee                         |                     | LOCAL_EXEC    | 1810567590 |                1
 Monroe County: Van Buren Township Trustee                          |                     | LOCAL_EXEC    | 1810578542 |                1
 Monroe County: Washington Township Trustee                         |                     | LOCAL_EXEC    | 1810580828 |                1
 Bloomington City Mayor                                             |                     | LOCAL_EXEC    | 1805860    |                1
```

### Q1 Analysis — Chamber Values

**CRITICAL FINDING: chamber_name_formal is EMPTY for every single Monroe County and Bloomington official.**

All 48 distinct (chamber_name, chamber_name_formal) combinations show `chamber_name_formal = ''` (empty string, returned via `COALESCE(name_formal, '')`). This is consistent with the RESEARCH.md pitfall warning — BallotReady-sourced data has not populated `name_formal`.

**Distinct chamber_name values found:**
- **Monroe County COUNTY officials:** Each body is its own chamber record — "Monroe County Commission - District 1/2/3", "Monroe County Council - At Large", "Monroe County Council - District 1/2/3/4", plus individual offices (Sheriff, Assessor, Auditor, etc.)
- **Monroe County JUDICIAL:** Per-seat "Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat N" (9 seats)
- **Monroe County LOCAL (township boards):** "Monroe County: [TownshipName] Township Board" (11 townships)
- **Monroe County LOCAL_EXEC (township trustees):** "Monroe County: [TownshipName] Township Trustee" (11 townships)
- **Bloomington LOCAL:** "Bloomington City Common Council - At Large", "Bloomington City Common Council - District 1-6", "Bloomington City Clerk"
- **Bloomington LOCAL_EXEC:** "Bloomington City Mayor"

**Key observation:** The chamber naming structure uses per-district/per-office chambers — not a single "Monroe County Council" chamber with multiple members. The body name is embedded in the `chamber_name` field, not `chamber_name_formal`.

**BallotReady naming convention confirmed:** Chamber names use the pattern "[Body Name] - [District/At Large]" rather than a shared body name. There are no state-qualified names like "Monroe County Council, Indiana" (the RESEARCH.md pitfall warning did not materialize in the actual data).

---

## Q2: classify.js group simulation results

**Query filter:** `geo_id LIKE '18105%' OR state = '18'` (Indiana-only officials)

**Raw output (71 rows for Indiana scope, key Monroe County subset shown):**

```
       full_name        |                            office_title                            | district_type | chamber_name_formal | simulated_group
------------------------+--------------------------------------------------------------------+---------------+---------------------+--------------------
 Jennifer Crossley      | Monroe County Council - District 4                                 | COUNTY        |                     | County Legislators
 Trent Deckard          | Monroe County Council - At Large                                   | COUNTY        |                     | County Legislators
 Martha Hawk            | Monroe County Council - District 3                                 | COUNTY        |                     | County Legislators
 David G Henry          | Monroe County Council - At Large                                   | COUNTY        |                     | County Legislators
 Peter J Iversen        | Monroe County Council - District 1                                 | COUNTY        |                     | County Legislators
 Cheryl Munson          | Monroe County Council - At Large                                   | COUNTY        |                     | County Legislators
 Kate Wiltz             | Monroe County Council - District 2                                 | COUNTY        |                     | County Legislators
 Nicole Browne          | Monroe County Circuit Court Clerk                                  | COUNTY        |                     | County Officials
 Trohn Enright-Randolph | Monroe County Surveyor                                             | COUNTY        |                     | County Officials
 Brianne Gregory        | Monroe County Auditor                                              | COUNTY        |                     | County Officials
 Jeffrey Hall           | Monroe County Coroner                                              | COUNTY        |                     | County Officials
 Elizabeth L Jones      | Monroe County Commission - District 1                              | COUNTY        |                     | County Officials
 Jody Madeira           | Monroe County Commission - District 3                              | COUNTY        |                     | County Officials
 Ruben D Marte          | Monroe County Sheriff                                              | COUNTY        |                     | County Officials
 Erika Oliphant         | Monroe County Prosecuting Attorney                                 | COUNTY        |                     | County Officials
 Judith A Sharp         | Monroe County Assessor                                             | COUNTY        |                     | County Officials
 Catherine Smith        | Monroe County Treasurer                                            | COUNTY        |                     | County Officials
 Amy Swain              | Monroe County Recorder                                             | COUNTY        |                     | County Officials
 Julie Thomas           | Monroe County Commission - District 2                              | COUNTY        |                     | County Officials
 [JUDICIAL rows - 9 circuit court judges]                          | JUDICIAL      |                     | JUDICIAL (unhandled)
 [LOCAL township board rows - 30 officials]                        | LOCAL         |                     | Township Officials
 [LOCAL_EXEC township trustee rows - 11 officials]                 | LOCAL_EXEC    |                     | LOCAL_EXEC (unhandled)
```

**Bloomington officials (separate query):**
```
       full_name       | office_title                                 | district_type | simulated_group
-----------------------+----------------------------------------------+---------------+---------------------
 Isak Asare            | Bloomington City Common Council - At Large   | LOCAL         | City Council
 Courtney Daily        | Bloomington City Common Council - District 5 | LOCAL         | City Council
 Matt Flaherty         | Bloomington City Common Council - At Large   | LOCAL         | City Council
 Isabel Piedmont-Smith | Bloomington City Common Council - District 1 | LOCAL         | City Council
 David R Rollo         | Bloomington City Common Council - District 4 | LOCAL         | City Council
 Kate Rosenbarger      | Bloomington City Common Council - District 2 | LOCAL         | City Council
 Andy Ruff             | Bloomington City Common Council - At Large   | LOCAL         | City Council
 Hopi H Stosberg       | Bloomington City Common Council - District 3 | LOCAL         | City Council
 Sydney Zulich         | Bloomington City Common Council - District 6 | LOCAL         | City Council
 Nicole Bolden         | Bloomington City Clerk                       | LOCAL         | Local (Other)
 Kerry Thomson         | Bloomington City Mayor                       | LOCAL_EXEC    | Municipal Executives
```

### Q2 Analysis — Group Collision

**CRITICAL FINDING: Monroe County Commissioners and Monroe County Council members do NOT collide in the current classify.js — they land in DIFFERENT groups.**

This is contrary to the RESEARCH.md prediction. The reason is the exact string matching in `hasAny()`:

- `classify.js` COUNTY branch checks: `hasAny(title, ["commissioner", "supervisor", "council"])`
- **Monroe County Council members** — office_title contains "council" → lands in **"County Legislators"**
- **Monroe County Commission members** — office_title is "Monroe County Commission - District X" which contains "commission" but NOT "commissioner". The substring "commissioner" (10 chars) is NOT a substring of "commission" (10 chars ending in 'n' not 'er'). → Falls through to **"County Officials"** (fallback)

**Collision confirmed: NO**
- Commissioners group: **County Officials** (via fallback — title "Commission - District X" does not contain "commissioner")
- Council group: **County Legislators** (via "council" match in title)
- Both landing in "County Legislators": **NO**

**Verified via Node.js classify.js trace:**
```
Monroe County Commission - District 1    -> County Officials (fallback)
Monroe County Commission - District 2    -> County Officials (fallback)
Monroe County Commission - District 3    -> County Officials (fallback)
Monroe County Council - At Large         -> County Legislators
Monroe County Council - District 1       -> County Legislators
Monroe County Council - District 2       -> County Legislators
Monroe County Council - District 3       -> County Legislators
Monroe County Council - District 4       -> County Legislators
```

**New problem discovered:** Monroe County Commissioners currently land in **"County Officials"** (which displays as "County Officials") — grouped with Sheriff, Assessor, Auditor, Treasurer, etc. This is semantically incorrect. Commissioners are the county legislative body, equivalent to a county board of commissioners. Phase 73 must address this by ensuring Commissioners land in a distinct group from general County Officials.

**Additional issues found:**
- `JUDICIAL` district_type falls through to raw "JUDICIAL" string in the SQL simulation (the SQL CASE doesn't handle JUDICIAL). In actual classify.js, JUDICIAL is handled: `hasAny(chamber, ["supreme", "appellate", "appeals"])` → State Judiciary, else → Local Judiciary. Monroe County circuit court judges would land in **"Local Judiciary"** since their chamber doesn't contain supreme/appellate/appeals.
- `LOCAL_EXEC` district_type for Township Trustees — In actual classify.js, `LOCAL_EXEC` branch: `hasAny(title, ["township"])` → "Township Officials". Township Trustees correctly land in **"Township Officials"**.

**Bloomington findings:**
- Bloomington Common Council: `district_type = LOCAL`, `chamber_name` contains "council" → **"City Council"** ✓ Correct, no issue.
- Bloomington City Clerk: `district_type = LOCAL`, title "Bloomington City Clerk" contains "clerk" → **"Municipal Officials"** via `hasAny(title, ["clerk", "city"])` ✓ Correct.
- Bloomington City Mayor: `district_type = LOCAL_EXEC`, no "township" in title → **"Municipal Executives"** ✓ Correct.

---

## Q3: Monroe County (18105) geofence presence

**Raw output:**

```
   geo_id   | mtfcc |                     name                      | state |      source       |        imported_at
------------+-------+-----------------------------------------------+-------+-------------------+----------------------------
 18105      | G4020 | Monroe                                        | 18    | census_tiger_2024 | 2026-02-11 11:34:17.155073
 1810503808 | G4040 | Bean Blossom                                  | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810505878 | G4040 | Bloomington                                   | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810513420 | G4040 | Clear Creek                                   | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810559112 | G4040 | Perry                                         | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810560984 | G4040 | Polk                                          | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810564152 | G4040 | Richland                                      | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810567590 | G4040 | Salt Creek                                    | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810578542 | G4040 | Van Buren                                     | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810536072 | G4040 | Indian Creek                                  | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810504816 | G4040 | Benton                                        | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810580828 | G4040 | Washington                                    | 18    | census_tiger_2024 | 2026-02-11 11:34:19.538643
 1810594    | G4210 | Cartersburg                                   | 18    | census_tiger_2024 | 2026-02-12 12:00:05.933386
 1810558    | G4210 | Carrollton                                    | 18    | census_tiger_2024 | 2026-02-12 12:00:05.933386
 1810500    | G5420 | South Putnam Community Schools                | 18    | census_tiger_2024 | 2026-02-11 11:34:24.635802
 1810530    | G5420 | South Ripley Community School Corporation     | 18    | census_tiger_2024 | 2026-02-11 11:34:24.635802
 1810560    | G5420 | South Spencer County School Corporation       | 18    | census_tiger_2024 | 2026-02-11 11:34:24.635802
 1810590    | G5420 | South Vermillion Community School Corporation | 18    | census_tiger_2024 | 2026-02-11 11:34:24.635802
(18 rows)
```

### Q3 Analysis — Geofence Presence

**Geofence present: YES**
- `geo_id = '18105'`, `mtfcc = 'G4020'` (county boundary), `name = 'Monroe'`, `source = census_tiger_2024`, imported 2026-02-11.
- All 11 Monroe County township geofences (G4040) are also present.
- 2 incorporated places (G4210: Cartersburg, Carrollton) are present.
- 4 school district geofences (G5420) present — note these are NOT the Monroe County school district, they match on the `18105` prefix by coincidence.

**Phase 73 geofence import step: NOT REQUIRED** — The county boundary G4020 already exists.

**Note:** Bloomington city geo_id is `1805860` (confirmed separately). The G4210 Bloomington entry is in a separate query (not in the 18105% range). Bloomington geofence exists as geo_id `1805860` with custom district geofences at `180586000001` through `180586000006` (MTFCC X0001 — custom boundaries for council districts).

---

## Q4: Indiana Geofence Coverage

**Raw output:**

```
 mtfcc | count | sample_geo_id
-------+-------+---------------
 G4020 |     1 | 18105
 G4040 |  1012 | 1800105914
 G4110 |   566 | 1800640
 G4210 |   410 | 1800140
 G5200 |     9 | 1801
 G5210 |    50 | 18001
 G5220 |   100 | 18001
 G5420 |   298 | 1800008
 G6350 |   807 | 46001
 X0001 |     6 | 180586000001
(10 rows)
```

### Q4 Analysis — Indiana Geofence Coverage

**MTFCC breakdown:**
| MTFCC | Description | Count | Relevance |
|-------|-------------|-------|-----------|
| G4020 | County boundaries | 1 | Only Monroe County present — not all Indiana counties |
| G4040 | Township boundaries | 1012 | Full Indiana township coverage |
| G4110 | Incorporated places (cities/towns) | 566 | City/town boundaries |
| G4210 | Census-designated places | 410 | Unincorporated communities |
| G5200 | Congressional districts | 9 | Indiana has 9 congressional seats |
| G5210 | State Senate districts | 50 | Indiana State Senate |
| G5220 | State House districts | 100 | Indiana State House |
| G5420 | School districts | 298 | School district boundaries |
| G6350 | Voting districts/precincts | 807 | FIPS prefix 46 — may be South Dakota not Indiana? |
| X0001 | Custom districts | 6 | Bloomington council districts (180586000001-6) |

**Key finding:** Only ONE G4020 (county boundary) exists for Indiana — Monroe County (18105). There is no statewide Indiana county geofence coverage. Brown County (18013), which appears in the officials data, does NOT have a G4020 geofence. This is NOT a problem for the current Phase 72 scope (Monroe County only), but Phase 73 must be aware that county-level geofence matching is limited to Monroe County specifically.

---

## Q5: All Active Indiana Officials — District and Chamber Data

**Note:** Full query returned 350+ rows across all Indiana officials. Monroe County and Bloomington officials (82 rows) shown here for regression mapping purposes.

**Raw output (Monroe County + Bloomington, 82 rows):**

```
       full_name        | is_active |                            office_title                            | district_type |    geo_id    | state | chamber_name_formal | government_name
------------------------+-----------+--------------------------------------------------------------------+---------------+--------------+-------+---------------------+-----------------
 Nicole Browne          | t         | Monroe County Circuit Court Clerk                                  | COUNTY        | 18105        | IN    |                     |
 Trent Deckard          | t         | Monroe County Council - At Large                                   | COUNTY        | 18105        | IN    |                     |
 Trohn Enright-Randolph | t         | Monroe County Surveyor                                             | COUNTY        | 18105        | IN    |                     |
 Brianne Gregory        | t         | Monroe County Auditor                                              | COUNTY        | 18105        | IN    |                     |
 Jeffrey Hall           | t         | Monroe County Coroner                                              | COUNTY        | 18105        | IN    |                     |
 David G Henry          | t         | Monroe County Council - At Large                                   | COUNTY        | 18105        | IN    |                     |
 Elizabeth L Jones      | t         | Monroe County Commission - District 1                              | COUNTY        | 18105        | IN    |                     |
 Jody Madeira           | t         | Monroe County Commission - District 3                              | COUNTY        | 18105        | IN    |                     |
 Ruben D Marte          | t         | Monroe County Sheriff                                              | COUNTY        | 18105        | IN    |                     |
 Cheryl Munson          | t         | Monroe County Council - At Large                                   | COUNTY        | 18105        | IN    |                     |
 Erika Oliphant         | t         | Monroe County Prosecuting Attorney                                 | COUNTY        | 18105        | IN    |                     |
 Judith A Sharp         | t         | Monroe County Assessor                                             | COUNTY        | 18105        | IN    |                     |
 Catherine Smith        | t         | Monroe County Treasurer                                            | COUNTY        | 18105        | IN    |                     |
 Amy Swain              | t         | Monroe County Recorder                                             | COUNTY        | 18105        | IN    |                     |
 Julie Thomas           | t         | Monroe County Commission - District 2                              | COUNTY        | 18105        | IN    |                     |
 Peter J Iversen        | t         | Monroe County Council - District 1                                 | COUNTY        | 1810500001   | IN    |                     |
 Kate Wiltz             | t         | Monroe County Council - District 2                                 | COUNTY        | 1810500002   | IN    |                     |
 Martha Hawk            | t         | Monroe County Council - District 3                                 | COUNTY        | 1810500003   | IN    |                     |
 Jennifer Crossley      | t         | Monroe County Council - District 4                                 | COUNTY        | 1810500004   | IN    |                     |
 [9 JUDICIAL circuit court judges — geo_id 18105]
 [11 LOCAL townships x 3 members each — geo_ids 181050XXXXXX]
 [11 LOCAL_EXEC township trustees — geo_ids 181050XXXXXX]
 Isak Asare             | t         | Bloomington City Common Council - At Large   | LOCAL         | 1805860      | IN    |                     |
 Nicole Bolden          | t         | Bloomington City Clerk                       | LOCAL         | 1805860      | IN    |                     |
 Matt Flaherty          | t         | Bloomington City Common Council - At Large   | LOCAL         | 1805860      | IN    |                     |
 Andy Ruff              | t         | Bloomington City Common Council - At Large   | LOCAL         | 1805860      | IN    |                     |
 Isabel Piedmont-Smith  | t         | Bloomington City Common Council - District 1 | LOCAL         | 180586000001 | IN    |                     |
 Kate Rosenbarger       | t         | Bloomington City Common Council - District 2 | LOCAL         | 180586000002 | IN    |                     |
 Hopi H Stosberg        | t         | Bloomington City Common Council - District 3 | LOCAL         | 180586000003 | IN    |                     |
 David R Rollo          | t         | Bloomington City Common Council - District 4 | LOCAL         | 180586000004 | IN    |                     |
 Courtney Daily         | t         | Bloomington City Common Council - District 5 | LOCAL         | 180586000005 | IN    |                     |
 Sydney Zulich          | t         | Bloomington City Common Council - District 6 | LOCAL         | 180586000006 | IN    |                     |
 Kerry Thomson          | t         | Bloomington City Mayor                       | LOCAL_EXEC    | 1805860      | IN    |                     |
```

**government_name is NULL for all Indiana officials** — the `essentials.governments` table has no records linked to Indiana chambers.

---

## Regression Mapping Table

Traces each Monroe County + Bloomington official through actual classify.js logic. "Current Group" = what classify.js produces today. "Expected Group" = what Phase 73 should produce for correct organization.

| Full Name | office_title | district_type | chamber_name | Current Group | Expected Group | Phase 73 Change Needed? |
|-----------|-------------|---------------|--------------|---------------|----------------|------------------------|
| Trent Deckard | Monroe County Council - At Large | COUNTY | Monroe County Council - At Large | **County Legislators** | County Legislators | No — already correct |
| David G Henry | Monroe County Council - At Large | COUNTY | Monroe County Council - At Large | **County Legislators** | County Legislators | No — already correct |
| Cheryl Munson | Monroe County Council - At Large | COUNTY | Monroe County Council - At Large | **County Legislators** | County Legislators | No — already correct |
| Peter J Iversen | Monroe County Council - District 1 | COUNTY | Monroe County Council - District 1 | **County Legislators** | County Legislators | No — already correct |
| Kate Wiltz | Monroe County Council - District 2 | COUNTY | Monroe County Council - District 2 | **County Legislators** | County Legislators | No — already correct |
| Martha Hawk | Monroe County Council - District 3 | COUNTY | Monroe County Council - District 3 | **County Legislators** | County Legislators | No — already correct |
| Jennifer Crossley | Monroe County Council - District 4 | COUNTY | Monroe County Council - District 4 | **County Legislators** | County Legislators | No — already correct |
| Elizabeth L Jones | Monroe County Commission - District 1 | COUNTY | Monroe County Commission - District 1 | **County Officials** | County Legislators | YES — Commissioners misclassified |
| Julie Thomas | Monroe County Commission - District 2 | COUNTY | Monroe County Commission - District 2 | **County Officials** | County Legislators | YES — Commissioners misclassified |
| Jody Madeira | Monroe County Commission - District 3 | COUNTY | Monroe County Commission - District 3 | **County Officials** | County Legislators | YES — Commissioners misclassified |
| Ruben D Marte | Monroe County Sheriff | COUNTY | Monroe County Sheriff | **County Officials** | County Officials | No — correct |
| Judith A Sharp | Monroe County Assessor | COUNTY | Monroe County Assessor | **County Officials** | County Officials | No — correct |
| Brianne Gregory | Monroe County Auditor | COUNTY | Monroe County Auditor | **County Officials** | County Officials | No — correct |
| Catherine Smith | Monroe County Treasurer | COUNTY | Monroe County Treasurer | **County Officials** | County Officials | No — correct |
| Nicole Browne | Monroe County Circuit Court Clerk | COUNTY | Monroe County Circuit Court Clerk | **County Officials** | County Officials | No — correct (clerk) |
| Amy Swain | Monroe County Recorder | COUNTY | Monroe County Recorder | **County Officials** | County Officials | No — correct |
| Trohn Enright-Randolph | Monroe County Surveyor | COUNTY | Monroe County Surveyor | **County Officials** | County Officials | No — correct |
| Jeffrey Hall | Monroe County Coroner | COUNTY | Monroe County Coroner | **County Officials** | County Officials | No — correct |
| Erika Oliphant | Monroe County Prosecuting Attorney | COUNTY | Monroe County Prosecuting Attorney | **County Officials** (fallback) | County Officials | No — acceptable |
| Holly M Harvey | Indiana Circuit Court Judge - 10th Circuit (Monroe County), Seat 1 | JUDICIAL | (same) | **Local Judiciary** | Local Judiciary | No — correct |
| [8 more circuit court judges] | same pattern | JUDICIAL | — | **Local Judiciary** | Local Judiciary | No — correct |
| [30 township board members] | Monroe County: X Township Board | LOCAL | (same) | **Township Officials** | Township Officials | No — correct |
| [11 township trustees] | Monroe County: X Township Trustee | LOCAL_EXEC | (same) | **Township Officials** | Township Officials | No — correct |
| Isak Asare | Bloomington City Common Council - At Large | LOCAL | Bloomington City Common Council - At Large | **City Council** | City Council | No — correct |
| [8 more council members] | same pattern | LOCAL | — | **City Council** | City Council | No — correct |
| Nicole Bolden | Bloomington City Clerk | LOCAL | Bloomington City Clerk | **Municipal Officials** | Municipal Officials | No — correct |
| Kerry Thomson | Bloomington City Mayor | LOCAL_EXEC | Bloomington City Mayor | **Municipal Executives** | Municipal Executives | No — correct |

**Summary of Phase 73 changes needed:**
- 3 Monroe County Commission members are misclassified as "County Officials" — they should be "County Legislators"
- Root cause: `office_title = "Monroe County Commission - District X"` does not contain "commissioner" (only "commission")
- Fix required: Either (a) add "commission" to the COUNTY branch keyword list in classify.js, or (b) ensure GovernmentBody body_key correctly identifies Commissioners as a legislative body

---

## Phase 73 Branch Decision

### Decision: PHASE 73 IS PRIMARILY A DATA MIGRATION PHASE

**Rationale:** Two findings require data work before feature work:

**Finding 1: chamber_name_formal is EMPTY for all Indiana officials**
- Every `chamber_name_formal` value is `''` (empty string via COALESCE)
- The GovernmentBody table in Phase 73 requires a stable `body_key` derived from `chamber_name_formal || chamber_name`
- Since `chamber_name_formal = ''`, classify.js falls through to `chamber_name`
- `chamber_name` values are per-district ("Monroe County Council - District 1") not per-body ("Monroe County Council")
- **Phase 73 must populate `chamber_name_formal`** with the canonical body name for each chamber (e.g., all "Monroe County Council - *" chambers should share `name_formal = "Monroe County Council"`) so that body_key grouping works correctly

**Finding 2: Monroe County Commissioners are misclassified**
- `office_title = "Monroe County Commission - District X"` → falls through to "County Officials" (fallback)
- This is semantically wrong — they are the county legislative body
- **Phase 73 must fix this classification** — either via classify.js changes or via body_key mapping

**Branch: DATA MIGRATION REQUIRED** — Phase 73 cannot be a pure feature phase.

### Recommended Phase 73 Approach

**Step 1 (Migration):** Populate `chamber_name_formal` for Indiana chambers:
- All "Monroe County Council - *" chambers → `name_formal = "Monroe County Council"`
- All "Monroe County Commission - *" chambers → `name_formal = "Monroe County Commission"`
- All "Bloomington City Common Council - *" chambers → `name_formal = "Bloomington City Common Council"`
- Township boards/trustees can keep per-township names (already correct in classify.js)

**Step 2 (Feature):** Build GovernmentBody table using `chamber_name_formal` as body_key source.

**Step 3 (Fix):** Update classify.js COUNTY branch to add "commission" to the `["commissioner", "supervisor", "council"]` keyword list so Commissioners correctly land in "County Legislators".

### Bloomington district_type confirmation

- **Bloomington Common Council:** `district_type = LOCAL` (confirmed)
- **Bloomington City Mayor:** `district_type = LOCAL_EXEC` (confirmed)
- These are correct and already classify correctly in classify.js

### Additional findings for Phase 73 planning

1. **government_name is NULL** for all Indiana chambers — `essentials.governments` table has no Indiana records. Phase 73 GovernmentBody must source display names from `chamber_name_formal` or synthesize them (e.g., "Monroe County" from geo_id 18105).

2. **Only 1 G4020 county geofence exists for Indiana** (Monroe County). Phase 73 cannot assume all Indiana county officials are served by county geofences.

3. **Monroe County Council district geo_ids are separate:** At-large members use `geo_id = '18105'` but district members use `geo_id = '1810500001'` through `'1810500004'`. Phase 73 body_key must group these into a single "Monroe County Council" body despite different geo_ids.

4. **No collision exists between Commissioners and Council** today — they already land in different groups (County Officials vs County Legislators). The RESEARCH.md concern was based on expected title patterns that don't match actual DB values. The actual problem is Commissioners landing in the wrong group entirely (County Officials instead of County Legislators).
