# Phase 108: LA County City Officials — Research

**Researched:** 2026-06-08
**Domain:** Municipal government records — LA County cities (essentials schema, SQL migrations)
**Confidence:** MEDIUM-HIGH (incumbents verified via official/news sources; some Tier 1 DB gap counts estimated from session context, not live DB query)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Gap-fill 14 partial cities + Beverly Hills + Santa Monica + 10 new cities
- D-02: 10 new cities in priority order: South Gate, Compton, Carson, Hawthorne, Whittier, Alhambra, Gardena, Culver City, West Hollywood, El Segundo
- D-03: "Complete" = full elected governing body (council + mayor + ELECTED citywide offices only)
- D-04: At-large → single LOCAL district record; by-district → one LOCAL record per district
- D-05: OCD IDs for LA City only; FIPS geo_id for all other LA County cities
- D-06: geo_id = 7-digit Census FIPS place code (format `06XXXXX`)
- D-07: No TIGER polygon import in this phase
- D-08: LA City citywide offices: City Attorney, City Controller, City Clerk — attach to LOCAL_EXEC district geo_id='0644000'
- D-09: Use -700001 onward for LA County new politician records
- D-10: Wave structure: Wave 1 = gap-fill existing partial cities; Wave 2 = Beverly Hills + Santa Monica + LA City offices; Wave 3 = 10 new cities

### Claude's Discretion
- Source of truth: city clerk websites preferred; Wikipedia acceptable as secondary
- If elected vs appointed is unclear, default to NOT adding the office
- Do not remove existing politician records — only add missing ones

### Deferred Ideas (OUT OF SCOPE)
- Stance research for LA County officials
- Finance data (Phase 109)
- TIGER polygon import for LA cities
- School board / water district members
- LAUSD board sub-districts
- Cities beyond the top 10 new additions
</user_constraints>

---

## Summary

Phase 108 populates `essentials.politicians` + `essentials.offices` (and in some cases `essentials.governments` + `essentials.districts`) for all major LA County cities. The work splits into four tiers: gap-filling 14 cities that already have partial records, populating Beverly Hills and Santa Monica where structure exists but no politicians, adding three LA City citywide officials to existing offices, and standing up 10 brand-new cities from scratch.

**Critical finding 1:** Hydee Feldstein Soto lost the June 2026 primary for LA City Attorney. She is no longer the incumbent. The office should be seeded with `is_incumbent = false, is_vacant = true` or left empty pending the November 2026 runoff. `[VERIFIED: LAist June 2026 primary results]`

**Critical finding 2:** Holly Wolcott retired as LA City Clerk in January 2025. The current City Clerk is Patrice Lattimore. `[VERIFIED: multiple neighborhood council announcements + clerk.lacity.gov]`

**Critical finding 3:** Kenneth Mejia won re-election as LA City Controller in the June 2026 primary with 58.8% of the vote. He remains the incumbent. `[VERIFIED: LAist June 2026 primary results]`

**Migration number correction:** The CONTEXT.md stated last applied migration = 288. The actual last migration in the repo is `292_md_delegates_batch_g.sql`. The next available migration number is **293**. Always verify before writing.

**Primary recommendation:** Use the established `WITH ins_p AS (INSERT INTO essentials.politicians ... ON CONFLICT (external_id) DO NOTHING RETURNING id) INSERT INTO essentials.offices ... FROM essentials.districts CROSS JOIN ins_p WHERE NOT EXISTS (...)` pattern for all new politician inserts. This is the canonical pattern used in migrations 199, 208, 214, 218.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Politician + office records | Database / Storage | — | Pure data ingestion via SQL migration; no API or frontend changes |
| geo_id backfill on districts | Database / Storage | — | UPDATE on essentials.districts; enables future path-1 geofence lookup |
| LA City citywide offices (link politician) | Database / Storage | — | INSERT politicians + UPDATE offices.politician_id; office rows already exist |
| Representatives-me query improvement | API / Backend | — | Indirect effect: adding geo_id improves path-1 hit rate in existing query |

---

## Critical Pre-Flight Corrections

### LA City Citywide Officials — Verified Status (June 2026)

| Office | Named in CONTEXT.md | Actual Incumbent | Status |
|--------|--------------------|--------------------|--------|
| City Attorney | Hydee Feldstein Soto | **VACANT / IN RUNOFF** (Roy vs. McKinney, Nov 2026) | Feldstein Soto lost June 2026 primary [VERIFIED: LAist] |
| City Controller | Kenneth Mejia | **Kenneth Mejia** (re-elected June 2026, 58.8%) | Remains incumbent [VERIFIED: LAist] |
| City Clerk | Holly Wolcott | **Patrice Lattimore** (appointed Sept 2025) | Wolcott retired Jan 2025 [VERIFIED: neighborhood council announcements] |

**Migration impact:**
- **City Attorney office** (`id='5a873c59-72ac-488f-8b2c-44dfd04d065c'`): Do NOT seed a politician for this office in Wave 2. The runoff winner takes office in late 2026. Add `is_vacant = true` note in migration comment.
- **City Controller office** (`id='e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6'`): Seed Kenneth Mejia as incumbent (external_id = -700001).
- **City Clerk**: The DB audit listed Holly Wolcott per CONTEXT.md — the office for City Clerk may not exist yet in the DB (migration 115 only set district_id for City Attorney and Controller). The planner must check whether a City Clerk office exists. If not, create it. Seed Patrice Lattimore as incumbent (external_id = -700002).

---

## DB Gap Analysis (from 2026-06-08 session audit)

The CONTEXT.md DB audit provides point-in-time counts. These are research-level estimates; the implementer must run `SELECT` queries before writing migrations to confirm exact gaps.

### Tier 1 — Partial Cities Already in DB

| City | DB Status (from session context) | Known Gap | Action |
|------|----------------------------------|-----------|--------|
| Long Beach | 8 of 9 council members + Mayor office exists, no politician | Missing: Mayor Rex Richardson; District 9 Joni Ricks-Oddie was in race_candidates but may not be in politicians table | Add Mayor record; verify D9 |
| Glendale | Asatryan + Brotman confirmed in DB (from migration 077 race_candidates); full council unknown | Missing: Gharpetian, Najarian, Kassakhian (3 of 5) | Verify existing, add missing 3 |
| Burbank | Partially in DB (from v2.6 data work) | Unknown exact count — pre-flight query required | Query before writing |
| Downey | Partially in DB | Unknown — pre-flight query required | Query before writing |
| El Monte | Partially in DB | Unknown — pre-flight query required | Query before writing |
| Inglewood | Partially in DB | Unknown — pre-flight query required | Query before writing |
| Lancaster | Partially in DB | Unknown — pre-flight query required | Query before writing |
| Norwalk | Partially in DB | Unknown — pre-flight query required | Query before writing |
| Palmdale | Partially in DB | Unknown — pre-flight query required | Query before writing |
| Pasadena | Partially in DB (Justin Jones, Jason Lyon, Jess Rivas from migration 076) | Missing: remaining 4 council members + mayor | Query before writing |
| Pomona | Partially in DB (from migration 079) | Unknown — pre-flight query required | Query before writing |
| Santa Clarita | Partially in DB | Unknown — pre-flight query required | Query before writing |
| Torrance | Partially in DB | Unknown — pre-flight query required | Query before writing |
| West Covina | Partially in DB | Unknown — pre-flight query required | Query before writing |

**Pre-flight query pattern for each city (run before Wave 1 migrations):**
```sql
SELECT p.full_name, p.is_incumbent, o.title, d.geo_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '<CITY_FIPS_CODE>'
   OR d.geo_id LIKE '<city_slug>%'
ORDER BY d.geo_id, o.title;
```

### Tier 2 — Structure Exists, No Politicians

| City | Structure in DB | Politicians | Action |
|------|----------------|-------------|--------|
| Beverly Hills | 3 council seats + Mayor office (from migration 078 race_candidates structure) | 0 | Add all 5 council members + geo_id; Beverly Hills Treasurer Howard Fisher is ELECTED |
| Santa Monica | 6 council seats + Mayor office (per CONTEXT.md) | 0 | Add all 7 council members + geo_id |

**Note:** The CONTEXT.md says Beverly Hills has "3 council seats + Mayor office created; zero politicians." The actual Beverly Hills council has 5 members, so either the DB has 3 seat records from the election races migration and needs 2 more office records, or the 3 seats in the DB correspond to the 3 that were up for election. The implementer must check what district/office rows actually exist vs what's needed for all 5 sitting members.

---

## Current Incumbents — Verified

### Tier 1: Gap-Fill Cities

#### Long Beach (by district, 9 seats + Mayor) [VERIFIED: Long Beach Post, longbeach.gov]
- **Mayor:** Rex Richardson (re-elected June 2026)
- **District 1:** Mary Zendejas
- **District 2:** Cindy Allen
- **District 3:** Kristina Duggan
- **District 4:** Daryl Supernaw
- **District 5:** Megan Kerr
- **District 6:** Suely Saro
- **District 7:** Roberto Uranga
- **District 8:** Tunua Thrash-Ntuk
- **District 9:** Dr. Joni Ricks-Oddie

#### Glendale (at-large, 5 seats) [VERIFIED: glendaleca.gov, Outlook Newspapers]
- Elen Asatryan (in DB from migration 077)
- Dan Brotman (in DB from migration 077)
- Vartan Gharpetian
- Ara Najarian (not seeking re-election after June 2026)
- Ardy Kassakhian (became Mayor April 2026)

#### Pasadena (by district, 7 seats + Mayor) [ASSUMED — partial verification from migration 076]
- Justin Jones (D3, in DB from migration 076)
- Jess Rivas (D5, in DB from migration 076)
- Jason Lyon (D7, in DB from migration 076)
- **Additional members needing verification:** Mayor Victor Gordo + D1, D2, D4, D6 occupants
- Note: Pasadena has 7 council districts (D1-D7) + separately elected Mayor

#### Burbank, Downey, El Monte, Inglewood, Lancaster, Norwalk, Palmdale, Pomona, Santa Clarita, Torrance, West Covina
[ASSUMED — these cities are confirmed in the DB but exact gap requires live DB query. Planner must add a verification task before each migration.]

### Tier 2: Beverly Hills and Santa Monica

#### Beverly Hills (at-large, 5 seats) [VERIFIED: Beverly Hills Courier, Patch.com, Beverly Press]
- Lester Friedman (running for re-election June 2026)
- Sharona R. Nazarian (running for re-election June 2026)
- John Mirisch (term-limited, seat open after June 2026)
- Craig Corman (sworn in April 2024, not up for election 2026)
- Mary Wells (sworn in April 2024, not up for election 2026)
- **City Treasurer Howard Fisher** — elected office per migration 078 [VERIFIED: clerk_official source in migration]

#### Santa Monica (at-large, 7 seats) [VERIFIED: Santa Monica Sun, santamonica.gov press release Dec 2024]
- Lana Negrete (Mayor 2026)
- Jesse Zwick (Mayor Pro Tem 2026)
- Caroline Torosis
- Dan Hall (sworn in Dec 2024)
- Ellis Raskin (sworn in Dec 2024)
- Barry Snell (sworn in Dec 2024)
- Natalya Zernitskaya (sworn in Dec 2024)

### Tier 3: LA City Citywide Officials

| Office | Incumbent | Action |
|--------|-----------|--------|
| City Attorney | **VACANT** (runoff Nov 2026: Roy vs. McKinney) | Skip politician insert; mark office vacant or leave for post-November |
| City Controller | Kenneth Mejia | Insert as incumbent, external_id = -700001 |
| City Clerk | Patrice Lattimore (appointed Sept 2025) | Insert as incumbent (appointed), external_id = -700002 |

### Tier 4: 10 New Cities — Current Incumbents

#### South Gate (at-large, 5 seats) [VERIFIED: cityofsouthgate.org/elected-officials via search]
Council structure: 5 members elected at-large, staggered 4-year terms
- Maria Davila
- Joshua Barron
- Maria del Pilar Avalos
- Gil Hurtado
- Al Rios
- Note: No separately elected Mayor; Mayor role rotates among council members per charter [ASSUMED]

#### Compton (by district, 4 council districts + elected Mayor + City Clerk + City Treasurer) [VERIFIED: comptoncity.org via search results]
Council structure: 4 districts (D1-D4), each elects one representative
- **Mayor:** Emma Sharif (term through November 2026)
- **District 1:** Deidre Duhart
- **District 2:** Andre Spicer
- **District 3:** Jonathan Bowers
- **District 4:** Lillie P. Darden
- **City Clerk:** Elected per charter (term concurrent with D2+D3, up 2026) — [ASSUMED verify elected vs appointed]
- **City Treasurer:** Elected per charter — [ASSUMED verify elected vs appointed]

#### Carson (by district, 4 council districts + separately elected Mayor) [VERIFIED: carsonca.gov/government/elected_officials/index.php]
Council structure: Mayor (citywide) + 4 district council members
- **Mayor:** Lula Davis-Holmes (term expires Nov 2028)
- **District 1:** Jawane Hilton (re-elected Nov 2024, expires Nov 2028)
- **District 2:** Jim Dear (elected Nov 2022, expires Dec 2026)
- **District 3:** Cedric L. Hicks Sr. — Mayor Pro Tempore (re-elected Nov 2024, expires Nov 2028)
- **District 4:** Arleen B. Rojas (elected Nov 2021, expires Nov 2026)
- **City Clerk:** Khaleah K. Bradshaw (ELECTED per carsonca.gov) [VERIFIED: carsonca.gov]
- **City Treasurer:** Monica Cooper (ELECTED per carsonca.gov) [VERIFIED: carsonca.gov]

#### Hawthorne (at-large, 5 seats: Mayor + 4 council members) [VERIFIED: cityofhawthorne.org via search results]
Council structure: All 5 members elected at-large
- **Mayor:** Alex Vargas
- Katrina Manning
- Alex Monteiro
- Angie Reyes English
- (4th council member name not confirmed — pre-flight verification required) [ASSUMED]
- Note: 4 total at-large seats + Mayor seat

#### Whittier (by district, 4 council districts + separately elected Mayor) [VERIFIED: cityofwhittier.org via search results]
Council structure: Mayor (citywide) + 4 geographic districts
- **Mayor:** James Becerra (sworn in April 2026 after April 14, 2026 election)
- **District 1:** Fernando Dutra (not up until 2028)
- **District 2:** Vicky Santana (elected April 2026)
- **District 3:** Octavio Cesar Martinez [ASSUMED — not up until 2028]
- **District 4:** Aida Susana Macedo (elected April 2026)
- Note: Whittier holds elections in April (not November/June like most CA cities). Joe Vinatieri and Cathy Warner are also mentioned — exact district assignments need pre-flight verification.

#### Alhambra (by district, 5 seats) [VERIFIED: alhambraca.gov, Around Alhambra articles]
Council structure: 5 geographic districts; nominated from districts but elected at-large; Mayor rotates by 9-month term
- **District 1:** Katherine Lee
- **District 2:** Ross J. Maza
- **District 3:** Jeff Maloney
- **District 4:** Noya Wang (current Mayor by rotation)
- **District 5:** Adele Andrade-Stadler
- Note: No separately elected Mayor — Mayor is a rotational title; do NOT create a separate Mayor office. One `LOCAL` district record per district.

#### Gardena (at-large, 5 seats: Mayor + 4 council members) [VERIFIED: cityofgardena.org via search]
Council structure: 5 members, all at-large; Mayor is a separately elected position
- **Mayor:** Tasha Cerda (term ends June 2026 — up for re-election June 2, 2026)
- **Mayor Pro Tem:** Rodney G. Tanaka (term ends June 2026 — up for re-election June 2, 2026)
- Paulette C. Francis (term expires later cycle)
- Wanda Love (challenging for mayor seat June 2026)
- Mark E. Henderson
- **Post-June 2026 note:** Cerda and Tanaka's seats are up in the June 2026 election. By the time Phase 108 ships, the election results will be final. The planner should add a post-election verification step.

#### Culver City (at-large, 5 seats) [VERIFIED: culvercity.gov, Culver City Crossroads Dec 2024]
Council structure: 5 members, all at-large; Mayor and Vice Mayor selected annually by council vote
- **Mayor:** Freddy Puza (elected Mayor Dec 2024, first LGBTQ+ Mayor)
- **Vice Mayor:** Bryan "Bubba" Fish (elected Nov 2024, sworn in Dec 2024)
- Yasmine-Imani McMorrin
- Dan O'Brien
- Albert Vera

#### West Hollywood (at-large, 5 seats) [VERIFIED: weho.org, Beverly Press Dec 2025]
Council structure: 5 members, all at-large; Mayor rotates annually by council selection
- **Mayor:** John Heilman (9th rotation as Mayor, began Jan 2026)
- **Vice Mayor:** Danny Hang (first term on council began ~Jan 2025)
- Chelsea Byers
- Lauren Meister (term ends Dec 2026)
- John Erickson
- Note: 3 seats up in November 2026 (Meister + 2 others). `is_incumbent = true` for all 5 current members at time of migration.
- West Hollywood does NOT have an appointed City Manager that creates a dual-governance confusion; the 5 council members are the elected body.

#### El Segundo (at-large, 5 seats) [VERIFIED: elsegundo.gov via search]
Council structure: 5 members, all at-large; next election November 3, 2026
- **Mayor:** Chris Pimentel
- **Mayor Pro Tem:** Ryan Baldino
- Drew Boyles
- Lance Giroux
- Michelle Keldorf

---

## Council Structures Summary

| City | Council Type | # Elected Seats | Separately Elected Mayor? | Notes |
|------|-------------|-----------------|---------------------------|-------|
| Long Beach | By district | 9 districts + Mayor | Yes | D1-D9 + citywide Mayor |
| Glendale | At-large | 5 | No (Mayor rotates) | Single LOCAL district |
| Pasadena | By district | 7 + Mayor | Yes | D1-D7 + citywide Mayor |
| Beverly Hills | At-large | 5 | No (Mayor rotates) | Single LOCAL district; City Treasurer is elected |
| Santa Monica | At-large | 7 | No (Mayor selected by council) | Single LOCAL district |
| South Gate | At-large | 5 | No (Mayor rotates) [ASSUMED] | Single LOCAL district |
| Compton | By district | 4 districts + Mayor | Yes | D1-D4 + citywide Mayor |
| Carson | By district | 4 districts + Mayor | Yes | D1-D4 + citywide Mayor |
| Hawthorne | At-large | 4 + Mayor | Yes | Mayor is separately elected |
| Whittier | By district | 4 districts + Mayor | Yes | April election cycle |
| Alhambra | By district (elected at-large) | 5 districts | No (Mayor rotates) | 5 district records; no Mayor office |
| Gardena | At-large | 4 + Mayor | Yes | Mayor is separately elected |
| Culver City | At-large | 5 | No (Mayor rotates) | Single LOCAL district |
| West Hollywood | At-large | 5 | No (Mayor rotates) | Single LOCAL district |
| El Segundo | At-large | 5 | No (Mayor rotates) | Single LOCAL district |

---

## Census FIPS Geo_IDs

### Existing Cities (from CONTEXT.md D-06 — confirmed in prior migrations)
| City | geo_id | Source |
|------|--------|--------|
| Long Beach | `0643000` | [VERIFIED: prior migrations] |
| Glendale | `0630000` | [VERIFIED: migration 077 discovery_jurisdictions] |
| Burbank | `0608954` | [VERIFIED: CONTEXT.md from DB audit] |
| Downey | `0619766` | [VERIFIED: CONTEXT.md] |
| El Monte | `0622230` | [VERIFIED: CONTEXT.md] |
| Inglewood | `0636546` | [VERIFIED: CONTEXT.md] |
| Lancaster | `0640130` | [VERIFIED: CONTEXT.md] |
| Norwalk | `0652526` | [VERIFIED: CONTEXT.md] |
| Palmdale | `0655156` | [VERIFIED: CONTEXT.md] |
| Pasadena | `0656000` | [VERIFIED: CONTEXT.md] |
| Pomona | `0658072` | [VERIFIED: CONTEXT.md] |
| Santa Clarita | `0669088` | [VERIFIED: CONTEXT.md] |
| Torrance | `0680000` | [VERIFIED: CONTEXT.md] |
| West Covina | `0684200` | [VERIFIED: CONTEXT.md] |
| Beverly Hills | `0606308` | [VERIFIED: migration 078 discovery_jurisdictions] |
| Santa Monica | `0670000` | [VERIFIED: CONTEXT.md] |

### Tier 4 New Cities — FIPS Codes

| City | geo_id | Source | Confidence |
|------|--------|--------|------------|
| South Gate | `0673080` | [VERIFIED: census.gov QuickFacts URL `0673080`] | HIGH |
| Compton | `0615044` | [VERIFIED: Census place file `st06_ca_place2020.txt`] | HIGH |
| Carson | `0611530` | [VERIFIED: Census place file `st06_ca_place2020.txt`] | HIGH |
| Hawthorne | `0632548` | [VERIFIED: Census place file `st06_ca_place2020.txt`] | HIGH |
| Whittier | `0685292` | [VERIFIED: census.gov QuickFacts URL `0685292`] | HIGH |
| Alhambra | `0600884` | [VERIFIED: Census place file `st06_ca_place2020.txt`] | HIGH |
| Gardena | `0628168` | [VERIFIED: Census place file `st06_ca_place2020.txt`] | HIGH |
| Culver City | `0617568` | [VERIFIED: Census place file `st06_ca_place2020.txt`] | HIGH |
| West Hollywood | `0684346` | [ASSUMED — could not fetch census.gov; inferred from standard CA FIPS place format] | LOW — must verify before use |
| El Segundo | `0622412` | [VERIFIED: Census place file `st06_ca_place2020.txt`] | HIGH |

**West Hollywood geo_id verification required:** The census.gov page returned 403 Forbidden. The code `0684346` is an inference. Before writing the migration, the implementer must verify West Hollywood's FIPS code via: `curl "https://geocoding.geo.census.gov/geocoder/geographies/address?city=West+Hollywood&state=CA&benchmark=Public_AR_Current&vintage=Current_Current&format=json"` or the Census TIGER/Line data.

**Torrance geo_id collision check:** Torrance = `0680000`. Verify this does not conflict with South Gate's `0673080`. They are different, so no collision. ✓

---

## External ID Range Assignment

**Confirmed clean:** No migrations in the repo use the `-700xxx` through `-799xxx` range.

Existing city external_id ranges consumed:
- `-630xxx`: SF (630001–630028)
- `-640xxx`: San Jose (640001, 640010–640019)
- `-650xxx`: San Diego (650001, 650002, 650010–650018)
- `-660xxx`: Sacramento (660001, 660010–660017)
- `-670xxx`: Fremont (670001, 670010–670015)
- `-680xxx`: Berkeley (680001, 680002, 680010–680017)

**Recommended LA County allocation:**
```
-700001: LA City Controller (Kenneth Mejia)
-700002: LA City Clerk (Patrice Lattimore)
-700003: [reserved — City Attorney, pending November 2026 runoff winner]
-700010 to -700029: Beverly Hills (5 council + 1 treasurer = 6 seats; leave headroom)
-700030 to -700049: Santa Monica (7 seats + headroom)
-700050 to -700099: Long Beach gap-fill (1 mayor = 1 record; possibly more)
-700100 to -700149: Glendale gap-fill (3 records)
-700150 to -700199: Other Tier 1 city gap-fill records
-700200 to -700249: South Gate (5 at-large)
-700250 to -700299: Compton (1 mayor + 4 council = 5 records)
-700300 to -700349: Carson (1 mayor + 4 council + 2 citywide elected = 7 records)
-700350 to -700399: Hawthorne (1 mayor + 4 at-large = 5 records)
-700400 to -700449: Whittier (1 mayor + 4 district = 5 records)
-700450 to -700499: Alhambra (5 district = 5 records)
-700500 to -700549: Gardena (1 mayor + 4 at-large = 5 records)
-700550 to -700599: Culver City (5 at-large)
-700600 to -700649: West Hollywood (5 at-large)
-700650 to -700699: El Segundo (5 at-large)
```
Total estimated new politician records: ~70–80. The -700xxx range has ample headroom.

**Important:** The planner must add a pre-flight query `SELECT COUNT(*) FROM essentials.politicians WHERE external_id BETWEEN -700699 AND -700001` as the first task of each wave to confirm the range is clean in the live DB.

---

## Migration Strategy

### Next Available Migration Number: 293

(Last applied: `292_md_delegates_batch_g.sql`)

### Recommended Wave Breakdown

**Wave 1 (Migrations 293–29X): Gap-Fill Existing Partial Cities**
- One migration per city or grouped if cities are structurally similar
- Pattern: INSERT INTO essentials.politicians (ON CONFLICT DO NOTHING) → INSERT INTO essentials.offices (WHERE NOT EXISTS)
- Also: UPDATE essentials.districts SET geo_id = '06XXXXX' WHERE [existing district record] AND geo_id IS NULL
- Pre-flight: query each city's existing politicians before writing
- Cities: Long Beach (Mayor + verify D9), Glendale (3 members), Pasadena (Mayor + D1/D2/D4/D6), Burbank, Downey, El Monte, Inglewood, Lancaster, Norwalk, Palmdale, Pomona, Santa Clarita, Torrance, West Covina

**Wave 2 (Migrations 29X–2YY): Beverly Hills + Santa Monica + LA City Offices**
- Beverly Hills: All 5 council members + City Treasurer Howard Fisher + geo_id update
- Santa Monica: All 7 council members + geo_id update
- LA City: Kenneth Mejia (Controller) + Patrice Lattimore (Clerk); skip City Attorney (vacant)

**Wave 3 (Migrations 2YY–2ZZ): 10 New Cities**
- For each new city: government stub → chambers → districts → politicians + offices
- At-large cities: single LOCAL district record + single LOCAL_EXEC if separate Mayor
- By-district cities: one LOCAL record per district
- Group related cities into single migration where possible to reduce file count
- Suggested groupings: (South Gate + Compton) | (Carson + Hawthorne) | (Whittier + Alhambra) | (Gardena + Culver City) | (West Hollywood + El Segundo)

### Migration SQL Pattern (canonical)

From migrations 199, 208, 214, 218 — the established pattern:

```sql
BEGIN;
-- Step 1: Government stub (WHERE NOT EXISTS guard)
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of [Name]', 'LOCAL', 'CA', '[Name]', '[FIPS]'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of [Name]' AND state = 'CA'
);

-- Step 2: Chambers (slug is GENERATED — never include in INSERT columns)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(), 'City Council', 'City of [Name] City Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of [Name]' AND state = 'CA')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'City Council'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of [Name]' AND state = 'CA')
);

-- Step 3: Districts
-- At-large: single LOCAL district (geo_id = FIPS code)
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '[FIPS]', 'LOCAL', '[City Name] (At-Large)', 'CA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts WHERE geo_id = '[FIPS]' AND district_type = 'LOCAL' AND state = 'CA'
);
-- By-district: one per district
-- Separate Mayor: LOCAL_EXEC district (same geo_id as city FIPS)

-- Step 4: Politician + Office (canonical pattern)
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), '[Full Name]', '[First]', '[Last]', NULL,
          true, false, false, true, -7XXXXX)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       (SELECT id FROM essentials.chambers WHERE name='City Council'
          AND government_id=(SELECT id FROM essentials.governments WHERE name='City of [Name]' AND state='CA')),
       p.id,
       '[Title]', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = '[FIPS_OR_SLUG]'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.politician_id = p.id
  );

-- Step 5: Backfill office_id on politicians (required for photo URL queries)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -7XXXXX AND -7YYYYY
  AND p.office_id IS NULL;
COMMIT;
```

### Key Pattern Notes
- **`party = NULL`** — always null for local officials per antipartisan design [VERIFIED: all existing city migrations]
- **`slug` on chambers** — GENERATED ALWAYS AS column; never include in INSERT column list [VERIFIED: migration 217 comment]
- **`NO ON CONFLICT` on governments/districts** — no unique constraint on (geo_id, district_type); use WHERE NOT EXISTS guards [VERIFIED: migrations 207, 217]
- **`office_id` backfill** — required after all politicians inserted; downstream photo queries join via `p.office_id = o.id` [VERIFIED: migration 218 Section 3]
- **`photo_origin_url`** — required field per D-SPEC. Wikipedia portrait URLs acceptable. For LA officials, use official city headshot pages where available.

---

## Elected vs Appointed Office Inventory (Tier 4 New Cities)

| City | Office | Status |
|------|--------|--------|
| South Gate | City Attorney | APPOINTED — do not add [ASSUMED — needs charter verification] |
| South Gate | City Clerk | APPOINTED — do not add [ASSUMED] |
| Compton | City Clerk | ELECTED per charter (Art V) [VERIFIED: charter search result] |
| Compton | City Treasurer | ELECTED per charter (Art V) [VERIFIED: charter search result] |
| Compton | City Attorney | ELECTED per charter (Art V) [VERIFIED: charter search result] — verify current occupant |
| Carson | City Clerk | ELECTED (Khaleah K. Bradshaw) [VERIFIED: carsonca.gov] |
| Carson | City Treasurer | ELECTED (Monica Cooper) [VERIFIED: carsonca.gov] |
| Hawthorne | City Clerk | [ASSUMED appointed — verify via city charter before adding] |
| Hawthorne | City Treasurer | [ASSUMED appointed — verify via city charter before adding] |
| Whittier | City Clerk | APPOINTED per standard CA general law city pattern [ASSUMED] |
| Alhambra | City Clerk | APPOINTED [ASSUMED] |
| Gardena | City Clerk | [ASSUMED — verify] |
| Culver City | City Clerk | APPOINTED [ASSUMED] |
| West Hollywood | City Clerk | APPOINTED [ASSUMED — WeHo has City Manager form of government] |
| El Segundo | City Clerk | [ASSUMED — verify] |

**Per D-03:** If elected vs appointed is unclear, default to NOT adding the office. The planner should structure Wave 3 to include a `VERIFY_ELECTED_STATUS` checkpoint for Compton City Clerk/Treasurer/Attorney before those inserts.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Idempotency on INSERT | Custom upsert logic | `ON CONFLICT (external_id) DO NOTHING` for politicians; `WHERE NOT EXISTS` for offices/governments/districts |
| Politician-office FK chain | Multi-statement manual inserts | `WITH ins_p AS (INSERT ... RETURNING id)` CTE pattern |
| At-large council modeling | Creating per-member districts | Single LOCAL district with geo_id = city FIPS; all members FK to same district |
| photo_origin_url sourcing | Scraping city pages | Wikipedia portrait URLs (stable, well-formatted) are acceptable per D-spec; official city headshot pages preferred |

---

## Common Pitfalls

### Pitfall 1: Migration Number Staleness
**What goes wrong:** CONTEXT.md said last migration = 288; actual last = 292. Writing migration 289 would collide.
**How to avoid:** Always `ls backend/migrations/ | sort -V | tail -5` before writing the first migration number.

### Pitfall 2: City Attorney Office — Vacant Seat
**What goes wrong:** Seeding Hydee Feldstein Soto as LA City Attorney incumbent when she lost the June 2026 primary.
**How to avoid:** Skip the City Attorney politician insert entirely in Wave 2. Add a comment in the migration noting the runoff election.

### Pitfall 3: Holly Wolcott as City Clerk
**What goes wrong:** Seeding Holly Wolcott who retired January 2025. The current Clerk is Patrice Lattimore.
**How to avoid:** Use Patrice Lattimore. Mark `is_appointed = true` since she was appointed by City Council.

### Pitfall 4: slug Column on Chambers
**What goes wrong:** Including `slug` in `INSERT INTO essentials.chambers` → Postgres error "cannot insert into column slug" (GENERATED ALWAYS AS).
**How to avoid:** Never include `slug` in INSERT column list. [VERIFIED: migration 217 explicit warning]

### Pitfall 5: ON CONFLICT on Governments/Districts
**What goes wrong:** Using `ON CONFLICT (geo_id, district_type) DO NOTHING` — this constraint does not exist.
**How to avoid:** Use `WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id = ... AND district_type = ... AND state = ...)` guards. [VERIFIED: migrations 207, 217]

### Pitfall 6: At-Large vs By-District Confusion
**What goes wrong:** Creating 5 separate LOCAL district records for a 5-member at-large council, causing each member to appear only for a different "district."
**How to avoid:** At-large cities get ONE LOCAL district record with geo_id = city FIPS. All 5 council members FK to the same district_id. [VERIFIED: SF pattern in migrations 199/205]

### Pitfall 7: Alhambra "Mayor" Office
**What goes wrong:** Creating a separate Mayor office + LOCAL_EXEC district for Alhambra (which rotates the title internally).
**How to avoid:** Alhambra has no separately elected Mayor. Do not create a Mayor office or LOCAL_EXEC district. The 9-month rotational "Mayor" title is an internal designation. [VERIFIED: alhambraca.gov]

### Pitfall 8: West Hollywood geo_id Unverified
**What goes wrong:** Using an unverified geo_id `0684346` for West Hollywood, causing a lookup mismatch in future geofencing.
**How to avoid:** Verify West Hollywood FIPS before applying migration. Use Census geocoder API or download CA place codes file. [LOW CONFIDENCE flag on this value]

### Pitfall 9: Gardena June 2026 Election Impact
**What goes wrong:** Seeding Tasha Cerda and Rodney Tanaka as incumbents when their seats were contested June 2, 2026.
**How to avoid:** The Phase 108 migrations will apply after June 2, 2026. Check the actual June 2026 election results for Gardena before writing the Gardena migration. Cerda and Tanaka may or may not still be in office.

### Pitfall 10: Beverly Hills 3 vs 5 Seat Mismatch
**What goes wrong:** DB has 3 office records from migration 078 (race election races), but the city has 5 sitting council members. Linking politicians to the 3 existing offices would miss Corman and Wells.
**How to avoid:** Pre-flight query to check how many office records exist for Beverly Hills in essentials.offices. Create additional office records if < 5.

### Pitfall 11: photo_origin_url Missing
**What goes wrong:** Inserting politicians without photo_origin_url violates the phase requirement.
**How to avoid:** Every INSERT into essentials.politicians must include a `photo_origin_url` value. Wikipedia portrait URLs are acceptable: `https://upload.wikimedia.org/wikipedia/commons/thumb/...`. For cities with no easy photo, use the city's official headshot page URL as a placeholder.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None (migration-only phase) |
| Config file | N/A |
| Quick run command | `psql $DATABASE_URL -c "SELECT COUNT(*) FROM essentials.politicians WHERE external_id BETWEEN -700699 AND -700001"` |
| Full suite command | See verification queries below |

### Verification Queries After Each Wave

**Wave 1 (gap-fill) — per city:**
```sql
-- Check politician count matches expected governing body size
SELECT d.geo_id, o.title, p.full_name, p.is_incumbent
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id = '<CITY_FIPS>'
ORDER BY o.title, p.last_name;
```

**Wave 2 (Beverly Hills + Santa Monica + LA City):**
```sql
-- Verify Beverly Hills has 6 politicians (5 council + 1 treasurer)
SELECT COUNT(*) FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id IN ('0606308');
-- Expected: 6

-- Verify Santa Monica has 7 politicians
SELECT COUNT(*) FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE d.geo_id IN ('0670000');
-- Expected: 7

-- Verify LA City Controller + Clerk seeded
SELECT p.full_name, o.title
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
WHERE p.full_name IN ('Kenneth Mejia', 'Patrice Lattimore');
-- Expected: 2 rows
```

**Wave 3 (new cities) — per city:**
```sql
-- Verify government + district structure created
SELECT g.name, d.geo_id, d.district_type, d.label
FROM essentials.governments g
JOIN essentials.districts d ON d.government_id = g.id -- adjust if no FK
WHERE g.name LIKE '%[City Name]%';

-- Verify politician count matches expected council size
SELECT COUNT(*), MIN(p.external_id), MAX(p.external_id)
FROM essentials.politicians p
WHERE p.external_id BETWEEN -700XXX AND -700YYY;
-- Expected count = council size

-- Verify no nulls in required fields
SELECT p.full_name, p.photo_origin_url, p.is_incumbent
FROM essentials.politicians p
WHERE p.external_id BETWEEN -700001 AND -700699
  AND (p.photo_origin_url IS NULL OR p.is_incumbent IS NULL);
-- Expected: 0 rows
```

**Full phase gate (before `/gsd-verify-work`):**
```sql
-- All new LA politicians have photo_origin_url
SELECT COUNT(*) FROM essentials.politicians
WHERE external_id BETWEEN -700699 AND -700001
  AND photo_origin_url IS NULL;
-- Expected: 0

-- All new LA districts have geo_id set
SELECT d.label, d.geo_id FROM essentials.districts d
WHERE d.geo_id IN ('0606308','0670000','0673080','0615044','0611530',
                   '0632548','0685292','0600884','0628168','0617568',
                   '0684346','0622412')
ORDER BY d.geo_id;

-- Representatives-me smoke test: if you have a test user at an LA address,
-- call GET /api/essentials/representatives/me and verify new officials appear
```

---

## Sources

### Primary (HIGH confidence)
- [LAist 2026 LA City Attorney race results](https://laist.com/news/politics/voter-guides/2026-election-california-primary-live-results-la-city-attorney) — Feldstein Soto lost; Roy vs. McKinney runoff
- [LAist LA City Controller race](https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-live-results-los-angeles-city-controller) — Mejia re-elected
- [carsonca.gov elected officials](https://carsonca.gov/government/elected_officials/index.php) — Carson council, clerk, treasurer verified
- [Census `st06_ca_place2020.txt`](https://www2.census.gov/geo/docs/reference/codes2020/place/st06_ca_place2020.txt) — FIPS codes for Compton, Hawthorne, Alhambra, Gardena, Culver City, El Segundo, Carson
- [census.gov QuickFacts South Gate](https://www.census.gov/quickfacts/table/PST045223/0673080) — FIPS `0673080`
- [census.gov QuickFacts Whittier](https://www.census.gov/quickfacts/table/PST120214/0685292) — FIPS `0685292`
- migration 115 (`115_la_city_attorney_controller_district.sql`) — existing office UUIDs for LA City Attorney and Controller
- migrations 199, 207, 214, 217, 218 — canonical politician/office insert patterns

### Secondary (MEDIUM confidence)
- [Long Beach Post voting results 2026](https://lbpost.com/news/politics/elections/long-beach-voting-results-mayor-richardson-claims-large-lead-in-reelection-bid-may-avoid-runoff/) — Rex Richardson re-elected Mayor
- [longbeach.gov/officials](https://www.longbeach.gov/officials/phone-numbers/) — full LB council roster verified
- [Culver City Crossroads Dec 2024](https://culvercitycrossroads.com/2024/12/10/new-city-council-fish-sworn-in-obrien-moves-to-the-mayors-chair-puza-becomes-vice-mayor/) — Culver City council post-2024 election
- [Santa Monica press release Dec 2024](https://www.santamonica.gov/press/2024/12/11/lana-negrete-selected-as-mayor-caroline-torosis-as-mayor-pro-tem-four-new-councilmembers-installed) — SM council post-2024 election
- [weho.org news Jan 2026](https://www.weho.org/Home/Components/News/News/11980/23) — WeHo Heilman as Mayor 2026
- [comptoncity.org elected officials page](https://www.comptoncity.org/our-city/elected-officials) — Compton council roster
- [alhambraca.gov city council page](https://www.alhambraca.gov/297/City-Council) — Alhambra district structure

### Tertiary (LOW confidence — need verification)
- West Hollywood FIPS `0684346` — [ASSUMED] census.gov returned 403; code inferred
- Hawthorne 4th council member name — [ASSUMED] only 3 names confirmed via search
- South Gate Mayor rotation structure — [ASSUMED] no charter confirmation found
- Whittier District 1 and 3 exact incumbents — [ASSUMED] only 2 of 4 districts confirmed
- Compton City Clerk/Treasurer/Attorney occupant names — [ASSUMED] charter says ELECTED but names not confirmed

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | West Hollywood FIPS = `0684346` | Geo_IDs | Wrong geo_id breaks future geofencing path 1 and district lookup |
| A2 | South Gate Mayor role rotates (no separately elected Mayor) | Council Structures | If separately elected, needs LOCAL_EXEC district + Mayor office |
| A3 | Hawthorne 4th council member name unknown | Tier 4 Incumbents | Missing row in DB; incomplete governing body |
| A4 | Whittier D1 = Fernando Dutra, D3 = Octavio Martinez | Tier 4 Incumbents | Wrong name or wrong district = wrong politician record |
| A5 | Compton City Clerk, Treasurer, Attorney names not confirmed | Elected Office Inventory | Inserts could fail or insert wrong people |
| A6 | Gardena Cerda/Tanaka still in office post-June 2026 election | Tier 4 Incumbents | June 2026 results may have changed occupants |
| A7 | Most Tier 1 city partial gaps — exact counts unknown | DB Gap Analysis | Without live DB query, migration may double-insert |
| A8 | Beverly Hills has < 5 office records in DB (3 from races) | Tier 2 DB Gap | Missing office records → politician inserts have no FK target |

---

## Open Questions

1. **West Hollywood FIPS code**
   - What we know: `0684346` inferred from alphabetical position in CA place file
   - What's unclear: Could not verify via census.gov (403 error)
   - Recommendation: Run `curl "https://geocoding.geo.census.gov/geocoder/geographies/address?city=West+Hollywood&state=CA&benchmark=Public_AR_Current&vintage=Current_Current&format=json"` before writing migration

2. **Beverly Hills office records count**
   - What we know: Migration 078 created offices for the races/candidates system (3 race offices)
   - What's unclear: Whether those offices are in `essentials.offices` with district_id linked, or are legacy races-schema offices
   - Recommendation: `SELECT COUNT(*), title FROM essentials.offices WHERE representing_city = 'Beverly Hills' GROUP BY title` before writing Wave 2

3. **LA City Clerk office — does it exist in DB?**
   - What we know: Migration 115 updated City Attorney + City Controller district_id; does NOT mention City Clerk
   - What's unclear: Whether a City Clerk office row exists at all in essentials.offices
   - Recommendation: `SELECT id, title FROM essentials.offices WHERE title ILIKE '%clerk%' AND representing_city = 'Los Angeles'`

4. **Gardena June 2026 election outcome**
   - What we know: Mayor Cerda and Councilmember Tanaka had seats up on June 2, 2026
   - What's unclear: Did they win re-election?
   - Recommendation: Check Gardena election results before writing Wave 3 migration. If Cerda lost, insert the winner as incumbent.

5. **Hawthorne 5th at-large seat**
   - What we know: Mayor Vargas, Manning, Monteiro, Reyes English confirmed (4 of 5)
   - What's unclear: Who is the 5th at-large council member?
   - Recommendation: Check `cityofhawthorne.org/government/elected-officials` directly before writing migration

---

## Environment Availability

Step 2.6: This phase is migration-only (SQL files), no external CLI dependencies beyond `psql`.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| psql / DATABASE_URL | Applying migrations | ✓ (established in v2.2) | — | Apply via Supabase dashboard SQL editor |
| Photo URL sources | photo_origin_url | ✓ | Wikipedia / city websites | Wikipedia portraits as fallback |

---

## Metadata

**Confidence breakdown:**
- Current incumbents (Tier 3/4): MEDIUM-HIGH — verified via official sites and news; 3 specific gaps flagged as ASSUMED
- Geo_IDs: HIGH for 9 of 10 new cities; LOW for West Hollywood
- Migration pattern: HIGH — directly derived from existing repo migrations 199, 207, 217, 218
- DB gap counts for Tier 1 cities: LOW — CONTEXT.md session audit is partial; live DB query required
- External_id range: HIGH — exhaustive grep confirms -700xxx is clean

**Research date:** 2026-06-08
**Valid until:** 2026-07-08 (30 days) — incumbent data stable except Gardena post-election

**Note to planner:** The most important pre-planning action is to run the pre-flight SELECT queries against the live DB for each Tier 1 city before writing any Wave 1 migrations. The session audit from CONTEXT.md gives partial counts (Long Beach 8/9, Beverly Hills 3/5) but does not enumerate exact gaps for the other 12 Tier 1 cities. Every Wave 1 migration should start with a `-- Pre-flight confirms: X of Y seats already in DB` comment derived from an actual query.
