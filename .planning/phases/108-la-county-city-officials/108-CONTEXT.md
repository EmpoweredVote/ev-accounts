# Phase 108: LA County City Officials - Context

**Gathered:** 2026-06-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 108 populates politician + office records for all major LA County cities: completing existing partial cities to full governing bodies, adding Beverly Hills and Santa Monica (offices exist, no politicians), filling LA City's three empty citywide offices, and seeding the top 10 unstarted major cities. Census FIPS geo_ids are populated on district records for all covered cities to enable future geofencing.

**In scope:**
- **Gap-fill existing partial cities** — full council + mayor + elected citywide officers for: Long Beach, Glendale, Burbank, Downey, El Monte, Inglewood, Lancaster, Norwalk, Palmdale, Pasadena, Pomona, Santa Clarita, Torrance, West Covina
- **Beverly Hills + Santa Monica** — all council members + mayor (office structure already exists in DB, politicians missing)
- **LA City citywide offices** — City Attorney (Hydee Feldstein Soto), City Controller (Kenneth Mejia), City Clerk (Holly Wolcott) — offices exist, need politician records linked
- **Top 10 new cities** (not yet in DB at all): Carson, Compton, Culver City, West Hollywood, South Gate, Alhambra, Hawthorne, Whittier, Gardena, El Segundo
- **Census FIPS geo_ids** — populate `essentials.districts.geo_id` (6-digit FIPS place code) for every city covered in this phase
- **photo_origin_url** — populated for all new politician records
- **is_incumbent = true** — set for all current sitting officials

**Out of scope:** Stance research (future phase), finance data (Phase 109), TIGER polygon import / geofencing (separate effort), school board members, water district boards, LAUSD board sub-districts, cities not in the top ~25 major LA County list.

**Requirements in scope:** LAOF-01 through LAOF-06 (to be defined in REQUIREMENTS.md)

</domain>

<decisions>
## Implementation Decisions

### City Coverage

- **D-01:** Phase covers three tiers of work: (1) gap-fill for 14 partial cities already in DB, (2) Beverly Hills + Santa Monica (structure exists, no politicians), (3) 10 new cities (no DB records at all). Researcher should verify current council composition for all 14 partial cities — the DB snapshot from 2026-06-08 may be stale.

- **D-02:** The 10 new cities to add (in approximate priority order by population): South Gate (~94K), Compton (~96K), Carson (~92K), Hawthorne (~87K), Whittier (~86K), Alhambra (~83K), Gardena (~60K), Culver City (~39K), West Hollywood (~35K), El Segundo (~17K). This list can be adjusted by the researcher based on data availability.

- **D-03:** "Complete" means: every city gets its full elected governing body — all council members (whether at-large or by-district) + mayor + any OTHER citywide elected offices (city attorney, city clerk, city treasurer — but only where these are separately ELECTED positions, not appointed). Research the city charter for each new city to confirm which offices are elected vs appointed.

### Council Structure per City

- **D-04:** LA County cities use either at-large councils (all members run citywide) or by-district councils. The researcher must confirm the correct district structure per city. Use the existing pattern: at-large cities get a single `LOCAL` district record with multiple politician rows all pointing to the same office; by-district cities get one `LOCAL` district record per district.

- **D-05:** Use the OCD ID format for LA City (already established: `ocd-division/country:us/state:ca/place:los_angeles/council_district:N`). For other LA County cities, use the Census FIPS geo_id as the district geo_id (e.g., `0643000` for Long Beach), which is consistent with the existing Glendale/Long Beach pattern.

### Geo_ids

- **D-06:** Populate `essentials.districts.geo_id` with the 7-digit Census FIPS place code (format: `06XXXXX`) for every city district record. Known geo_ids from the DB audit: Long Beach=`0643000`, Glendale=`0630000`, Burbank=`0608954`, Downey=`0619766`, El Monte=`0622230`, Inglewood=`0636546`, Lancaster=`0640130`, Norwalk=`0652526`, Palmdale=`0655156`, Pasadena=`0656000`, Pomona=`0658072`, Santa Clarita=`0669088`, Torrance=`0680000`, West Covina=`0684200`, Beverly Hills=`0606308`, Santa Monica=`0670000`. Researcher confirms + fills in geo_ids for the 10 new cities.

- **D-07:** No TIGER polygon import in this phase. geo_id population enables future geofencing without requiring another DB pass; the actual `essentials.geo_districts` polygon import is a separate effort.

### LA City Citywide Officials

- **D-08:** Three LA City citywide offices already exist in the DB with no politicians linked. Add politician records for: City Attorney Hydee Feldstein Soto, City Controller Kenneth Mejia, City Clerk Holly Wolcott. These attach to the existing `LOCAL_EXEC` district for `geo_id = '0644000'`.

### External IDs

- **D-09:** Use a new negative external_id range for LA County additions. Established ranges: -400001 to -400143 (senators + 2026 candidates), -500xxx (SJ/SD city officials), -600xxx (DC officials). LA County new records should use `-700001` onward. Researcher verifies no existing LA County records already occupy the -700xxx range before assigning.

### Migration Structure

- **D-10:** Break into waves by work type. Suggested wave structure (planner decides final breakdown): Wave 1 = gap-fill existing partial cities; Wave 2 = Beverly Hills + Santa Monica + LA City offices; Wave 3 = 10 new cities. Each wave is a separate migration file(s). Migrations numbered starting from 289 (288 is the last confirmed applied).

### Claude's Discretion

- Source of truth for current incumbents: city clerk websites preferred; Wikipedia acceptable as secondary source. Official `.gov` or city website URLs preferred for `photo_origin_url`.
- If a city's elected positions are hard to verify (e.g., city attorney is appointed vs. elected is unclear), default to NOT adding the office rather than guessing.
- Politician records for existing partial cities: update `is_incumbent` if needed, but do NOT remove existing records — only add missing ones.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Prior Phase Patterns for City Officials
- `.planning/phases/105-dc-infrastructure-official-records/105-CONTEXT.md` — DC official records pattern (governments → districts → offices → politicians chain)
- `.planning/phases/107-dc-finance/107-CONTEXT.md` — external_id range convention (-600xxx for DC)

### DB Audit Results (2026-06-08 session)
- DB snapshot: LA City has 15 council members (CD1–CD15) + Mayor Bass. City Attorney/Controller/Clerk offices exist with no politicians.
- LA County BOS: all 5 supervisors present (Solis D1, Mitchell D2, Horvath D3, Hahn D4, Barger D5).
- Long Beach: 8 of 9 council members present; Mayor office exists with no politician.
- Beverly Hills (`0606308`): 3 council seats + Mayor office created; zero politicians.
- Santa Monica (`0670000`): 6 council seats + Mayor office created; zero politicians.
- Finance_summary: NULL for all LA politicians — no finance data at all.

### Existing Migration Examples for City Officials
- `backend/migrations/075_long_beach_candidates.sql` — Long Beach city candidates pattern
- `backend/migrations/076_pasadena_races_and_candidates.sql` — Pasadena pattern
- `backend/migrations/077_glendale_races_and_candidates.sql` — Glendale at-large council pattern

### Prior City Official Migrations (reference for structure)
- `backend/migrations/` — check migrations 073-082 for LA-area city patterns
- Latest migration applied: `288_dc_official_records_sboe.sql`. Next available: 289.

### External ID Ranges
- -400001 to -400143 consumed (senators + 2026 candidates)
- -500xxx consumed (SJ/SD city officials — v2.5)
- -600001 to -600030 consumed (DC officials — v2.8)
- **Use -700001 onward for Phase 108 LA County additions**

### Established Schema
- `essentials.governments` — stub row per city (government_id)
- `essentials.districts` — one per district (LOCAL or LOCAL_EXEC), `geo_id` = FIPS place code
- `essentials.offices` — one per seat/title (FK to district_id)
- `essentials.politicians` — one per sitting official (FK to office_id), `is_incumbent = true`, `is_active = true`, `photo_origin_url` required
- `essentials.geo_districts` — NOT touched in this phase (no polygon import)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `backend/migrations/077_glendale_races_and_candidates.sql` — at-large council city pattern (multiple politicians → single LOCAL district)
- `backend/migrations/284_dc_government_districts.sql` — government stub + district creation pattern from v2.8
- `backend/migrations/286_dc_official_records_council_mayor.sql` — bulk politician + office insert pattern

### Established Patterns
- **City structure**: `INSERT INTO essentials.governments` stub → `INSERT INTO essentials.districts` (district_type='LOCAL' or 'LOCAL_EXEC', geo_id=FIPS) → `INSERT INTO essentials.offices` (district_id FK) → `INSERT INTO essentials.politicians` (office_id FK, is_incumbent, is_active, photo_origin_url)
- **District.geo_id** for LA-area cities: use 7-digit FIPS place code (format `06XXXXX`) — NOT the OCD ID format. OCD IDs are only used for LA City council districts where they were already established.
- **`is_incumbent = true, is_active = true`** on all sitting officials at time of migration
- **`photo_origin_url`** required — use Wikipedia portrait URL or official city portrait if available

### Integration Points
- `GET /api/essentials/representatives/me` — serves politicians by user's district (path 0 via tiger_geoid; path 1 via FIPS geo_id join). Adding geo_id to districts in this phase improves path 1 hit rate for LA users.
- `essentials.geo_districts` — NOT touched. Future TIGER LA city polygon import will use the geo_ids we set here.

</code_context>

<specifics>
## Specific Ideas

- **LA City citywide offices**: Hydee Feldstein Soto (City Attorney), Kenneth Mejia (City Controller), Holly Wolcott (City Clerk) — researcher should verify these are still current as of 2026-06-08.
- **Long Beach Mayor**: Rex Richardson (took office 2022) — verify still incumbent.
- **Glendale 5th council member**: Glendale has 5 at-large council seats; researcher confirms who holds the 5th seat not yet in DB.
- **Beverly Hills**: 5-member at-large city council (no districts); Mayor is rotated among council members by vote. Researcher determines current Mayor designation if there's a formal one.
- **Santa Monica**: 7-member at-large council. Mayor and Mayor Pro Tem are selected by council vote.
- **West Hollywood**: Unique as an incorporated city with a LGBTQ+ cultural identity; 5-member at-large council + appointed City Manager. Verify which offices are elected.
- **El Segundo**: Small city (~17K) but notable proximity to LAX and tech corridor; 5-member at-large council.

</specifics>

<deferred>
## Deferred Ideas

- **Stance research for LA County officials** — zero stances exist for any LA County city official. This is a future phase (likely Phase 110 or similar), dependent on Phase 108 politician records existing as FK targets.
- **Finance data for LA County officials** — Phase 109 covers this. CAL-ACCESS for county/state officials, Netfile for city races.
- **TIGER polygon import for LA cities** — geofencing boundaries for LA city council districts would require shapefile import like v2.2 CA TIGER work. Separate effort, not this phase.
- **School board + water district members** — LA County has many special district boards. Out of scope for v2.9.
- **LAUSD board sub-districts** — currently all 3 LAUSD board races show for all LA users. Sub-district geofencing needs LAUSD boundary shapefiles. Tracked in v1.9 tech debt.
- **Cities beyond top 10** — the remaining ~60+ LA County incorporated cities (Bell, Bell Gardens, Commerce, Cudahy, Diamond Bar, Duarte, etc.) could be added in a future v2.10 milestone.

</deferred>

---

*Phase: 108-LA County City Officials*
*Context gathered: 2026-06-08*
