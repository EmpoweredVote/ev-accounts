# Phase 112: VA Delegate Stances — Research

**Researched:** 2026-06-10
**Domain:** Stance data ingestion — Virginia House of Delegates (100 delegates)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** 10 plan files × 10 delegates each. One migration per plan: migrations 331–340 (sequential, psql-applied like Phase 111 waves 326–330).
- **D-02:** Migration numbering: next free after Phase 111's waves (326–330) is 331. Always verify with `SELECT MAX(version) FROM supabase_migrations.schema_migrations` — note that psql-applied wave migrations do NOT register there (max shows 325 at time of context). Cross-check against the highest-numbered file in `supabase/migrations/` to determine the true next free number.
- **D-03:** Group delegates geographically across 10 waves. Researcher must fetch all 100 delegate names+UUIDs+district numbers from the DB, map them to regions, and define the 10 wave compositions explicitly in RESEARCH.md before planning begins.
- **D-04:** Suggested regional split (researcher confirms with actual district data):
  - Waves 1–2: Western / Southwest VA (rural, Republican-heavy, thinner web presence)
  - Waves 3–4: Central / Piedmont VA (mixed)
  - Waves 5–6: Hampton Roads / Coastal VA (mixed)
  - Waves 7–8: Richmond metro (mixed, some high-profile)
  - Waves 9–10: Northern Virginia / NoVA (Democratic-heavy, more online presence, higher expected yield)
- **D-05:** Researcher must produce the full delegate roster table (full_name, UUID, district, region assignment) in RESEARCH.md before any plan is written.
- **D-06:** Attempt all 44 live topics for every delegate. City-level topics are skipped by the agent via honest-skip mechanism — no special pre-filtering needed.
- **D-07:** HARD RULE — do not guess. Do not assign any stance value without a real fetched source URL. Zero rows for a delegate is valid.
- **D-08:** No sourcing-free answers. Every value written to the CSV must have at least one URL in source_url_1 that the agent actually fetched successfully.
- **D-09:** Party affiliation must never be used to infer a stance value. Always require direct evidence from the politician's own record.
- **D-10:** Expected yield: low-profile / rural delegates may yield 0–6 stances; high-profile / NoVA / Richmond delegates may yield 10–20.
- **D-11:** Sequential dispatch — ONE `politician-stance-researcher` agent at a time.
- **D-12:** WebFetch only. No WebSearch, no Playwright.
- **D-13:** VAST-05 invariant: every `inform.politician_answers` row must have a paired `inform.politician_context` row with `sources` array containing at least one non-empty URL.
- **D-14:** `pool.query()` for all DB writes.
- **D-15:** Live topics fetched fresh from DB before each wave.

### Claude's Discretion

None specified.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VAST-03 | Sourced stances for all 100 VA House delegates (honest-skip where no documentable evidence) | Full 100-delegate roster verified in DB; 10-wave composition defined; source strategy per region documented |
| VAST-05 | Every new stance paired with `inform.politician_context` containing at least one real source URL | Migration template Pattern 4 from Phase 111 carries forward; DO $$ ASSERT unsourced_count = 0 per wave |
</phase_requirements>

---

## Summary

Phase 112 closes VAST-03 and extends VAST-05 coverage to VA House delegates. All 100 delegate records are confirmed in the DB (migration 319, external_ids -5120001 through -5120100) with zero existing stance rows — this is a clean greenfield research run.

The work follows the exact same pattern established in Phase 111 (VA senators): dispatch `politician-stance-researcher` agents one at a time, produce dated CSVs, write a numbered migration (next free: 331), apply via psql, verify with SQL assertions. The SKILL.md orchestrator handles all research mechanics.

VA House delegates hold state-scope positions. The applicable topic list excludes city-level topics (same skip list as senators). With 100 delegates across 10 geographic waves of 10 delegates each, the key insight is that the VA House has a wider spectrum of web presence than the Senate — Southwest VA delegates (HD-43–50) may yield 0–3 stances via Ballotpedia alone, while Northern VA delegates (HD-1–15) may yield 15–25. Honest-skip is expected to be more prevalent here than in Phase 111.

**Key geographic finding:** The external_id mapping runs in geographic order: external_id -5120001 = HD-1 = Patrick A. Hope (Arlington, NoVA), and the districts count up through Northern VA (HD-1–30), then Shenandoah/Central (HD-31–55), then Hampton Roads (HD-56–75), then Richmond metro and Southside Hampton Roads (HD-76–100). This is the **inverse** of the D-04 regional split suggestion — the lower-numbered external_ids are the high-yield NoVA delegates. The wave composition below adjusts accordingly: Waves 1–2 cover Western/Southwest (HD-37–55), Waves 3–4 cover Shenandoah/Central (HD-31–42), Waves 5–6 cover Hampton Roads/Coastal (HD-56–75), Waves 7–8 cover Richmond metro/Southside (HD-76–100), Waves 9–10 cover Northern Virginia (HD-1–30). This front-loads the harder (lower-yield) regions and saves the higher-yield NoVA delegates for the final waves when the pattern is fully established.

**One notable entry:** external_id -5120020 maps to `full_name = "Vacant"` for HD-20. This seat is vacant as of the DB record. The research agent should skip this record — no research is possible for a vacant seat. The migration for Wave 9 should include a header comment documenting HD-20 as a documented skip (vacant seat, no politician to research).

**Primary recommendation:** Mirror Phase 111 plan structure exactly — pre-flight task → 10 sequential research agents → CSV review → migration SQL → psql apply → verify. Use 10 plan files with migrations 331–340.

---

## DB State (Verified 2026-06-10)

| Property | Value | Source |
|----------|-------|--------|
| VA delegate records | 100 (including 1 vacant seat) | [VERIFIED: DB query `WHERE external_id BETWEEN -5120100 AND -5120001`] |
| External ID range | -5120001 to -5120100 | [VERIFIED: DB query] |
| Existing stance rows | 0 | [VERIFIED: DB query `COUNT(*)` on `inform.politician_answers` join] |
| Unsourced stances | 0 | [VERIFIED: DB query — no rows to violate VAST-05] |
| Live compass topics | 44 | [VERIFIED: DB query `SELECT COUNT(*) FROM inform.compass_topics WHERE is_live = true`] |
| `schema_migrations` MAX(version) | 325 | [VERIFIED: DB query] |
| Highest migration file on disk | 330 (`20260609000005_330_va_senators_wave5_stances.sql`) | [VERIFIED: `ls supabase/migrations/ \| sort \| tail -5`] |
| Next free migration number | 331 | [VERIFIED: 330 is highest file; 331 is first free] |
| Vacant seat | HD-20 (`full_name = "Vacant"`, external_id -5120020) | [VERIFIED: DB query] |

**Migration number determination:** `SELECT MAX(version)` returns 325 because psql-applied wave migrations 326–330 do NOT insert into `supabase_migrations.schema_migrations`. The true next free number is 331, confirmed by the highest file on disk (330). Always pre-flight with BOTH `SELECT MAX(version)` AND `ls supabase/migrations/ | sort | tail -1` before writing the wave migration filename.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stance value research | Research agent (WebFetch) | Human review | Five-Chairs method requires real URL evidence per VAST-05 |
| CSV staging | File system (`backend/data/stance-research/`) | — | Source of truth before DB push; never lost even if DB push fails |
| DB ingestion | Database (inform schema) | `pool.query()` | Non-public schema, no PostgREST; direct postgres required |
| Source verification | Research agent | Migration DO $$ block | VAST-05: ASSERT unsourced_count = 0 per wave |
| Migration numbering | File system + psql | — | Sequential files 331–340 applied in order |
| Vacant seat handling | Migration header comment | — | HD-20 documented as skip, no rows expected |

---

## Standard Stack

No new packages required. All tooling already installed.

### Core (already present)
| Tool | Purpose | Notes |
|------|---------|-------|
| `research-stances` SKILL.md | Orchestrate `politician-stance-researcher` agents | `.claude/skills/research-stances/SKILL.md` |
| `politician-stance-researcher` agent | WebFetch-only stance research per delegate | Uses Five-Chairs, produces CSV |
| `pool.query()` + `tsx` | DB upsert for inform schema | Never PostgREST for non-public schemas |
| `psql` via session pooler | Apply numbered migration SQL files | `aws-0-*.pooler.supabase.com:5432` |

### CSV Output Format
```
full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3
```
- `quote_text` and `quote_deidentified` columns included if agent produces them
- Parse with `csv-parse/sync`, never by splitting on commas
- Names with commas (e.g., "Robert S. Bloxom, Jr.") must be RFC-4180 quoted in CSV

## Package Legitimacy Audit

No new packages installed in this phase. N/A.

---

## Full VA House Delegate Roster (Verified 2026-06-10)

All 100 delegate records confirmed in DB. Organized by district number (HD-1 through HD-100), with region assignment for wave grouping. External_id = `-(5120000 + district_number)`.

### Northern Virginia (HD-1 – HD-30) — Waves 9–10

Democratic-heavy. High online presence, active press coverage, multiple Ballotpedia pages with detailed policy sections. Expected yield: 12–22 stances per delegate.

| HD | full_name | UUID | external_id | Region |
|----|-----------|------|-------------|--------|
| 1 | Patrick A. Hope | af6e165b-4668-449b-97a5-6b25c01c572a | -5120001 | NoVA |
| 2 | Adele Y. McClure | 8461412e-6413-4f44-ae5e-b7c8e7f736a5 | -5120002 | NoVA |
| 3 | Alfonso H. Lopez | 5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba | -5120003 | NoVA |
| 4 | Charniele L. Herring | 51f5dd85-abb6-4f50-bcb9-e5e6b82376b7 | -5120004 | NoVA |
| 5 | R. Kirk McPike | b85d17af-a823-413c-b79c-aa4e7cfab730 | -5120005 | NoVA |
| 6 | Richard C. Sullivan, Jr. | 1964984f-1751-4ac7-ae94-69e50b0c2968 | -5120006 | NoVA |
| 7 | Karen Keys-Gamarra | c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e | -5120007 | NoVA |
| 8 | Irene Shin | 98023fc8-d83b-43ba-b7e1-5bd132122bbe | -5120008 | NoVA |
| 9 | Karrie K. Delaney | b17426e3-d363-44fd-a2b7-a04f54f6d7cb | -5120009 | NoVA |
| 10 | Dan Helmer | 090cebbd-19b5-41ed-9c9a-5f537cdb5470 | -5120010 | NoVA |
| 11 | Gretchen M. Bulova | 1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0 | -5120011 | NoVA |
| 12 | Holly M. Seibold | 4a5090f7-8d76-40c1-b2f4-c2ed038e6687 | -5120012 | NoVA |
| 13 | Marcus B. Simon | c490eece-71f4-4051-975d-8fa5ed5f652b | -5120013 | NoVA |
| 14 | Vivian E. Watts | b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264 | -5120014 | NoVA |
| 15 | Laura Jane Cohen | a1a470c9-1b16-4e98-999c-4106422cc52c | -5120015 | NoVA |
| 16 | Paul E. Krizek | cd70f416-c844-41db-9ff4-c528e04a72be | -5120016 | NoVA |
| 17 | Garrett McGuire | d701fee4-4d0a-44e8-9639-e8696c304b41 | -5120017 | NoVA |
| 18 | Kathy KL Tran | f224a300-8b54-4b57-b988-5c340667f99b | -5120018 | NoVA |
| 19 | Rozia A. Henson, Jr. | c01e3771-7930-479e-b1a0-710d58424660 | -5120019 | NoVA |
| 20 | **Vacant** | a8996e30-a386-45b5-8157-5d39b56a726f | -5120020 | NoVA — SKIP |
| 21 | Josh Thomas | c566a41d-28e7-45cb-9eea-c9501878f2a7 | -5120021 | NoVA |
| 22 | Elizabeth R. Guzman | cea4db8b-acb5-4ebb-be09-e731d4412249 | -5120022 | NoVA |
| 23 | Margaret Angela Franklin | eaf0ce8c-b937-469f-b3a6-f9b1599610b4 | -5120023 | NoVA |
| 24 | Luke E. Torian | 87aa078a-ab94-4b17-86fc-6301d47a5824 | -5120024 | NoVA |
| 25 | Briana D. Sewell | 77ce6e63-7379-4c8a-9038-5c708510d6cc | -5120025 | NoVA |
| 26 | JJ Singh | c85b90a2-e81b-41a8-a74a-90d03018a443 | -5120026 | NoVA |
| 27 | Atoosa R. Reaser | b8856cc7-d711-436d-96b3-f0cbd352350a | -5120027 | NoVA |
| 28 | David A. Reid | 5061959c-b625-4b7a-b17f-a1291c50d001 | -5120028 | NoVA |
| 29 | Fernando J. Martinez | b754aca0-a0b6-43fc-a1f0-ecdc84a41d75 | -5120029 | NoVA |
| 30 | John C McAuliff | 9ec8ec01-2b15-42ae-8a52-cc77930be151 | -5120030 | NoVA |

### Shenandoah / Central / Piedmont (HD-31 – HD-42) — Waves 3–4

Mixed party, includes Shenandoah Valley and some Piedmont delegates. Moderate web presence. Expected yield: 5–12 stances.

| HD | full_name | UUID | external_id | Region |
|----|-----------|------|-------------|--------|
| 31 | Delores Oates | 11b44fd4-cbc4-415e-b567-c63f657fceab | -5120031 | Central |
| 32 | William D. Wiley | c5490995-b962-4b20-ab8d-56ba1ba8d54b | -5120032 | Central |
| 33 | Justin L. Pence | e345c9d6-4e28-4416-86de-24ab84c803f9 | -5120033 | Central |
| 34 | Tony O. Wilt | 742d2c42-b277-4859-9269-1abc55affbe2 | -5120034 | Central |
| 35 | Chris Runion | f3908370-f489-4a77-96f3-b19bf983618e | -5120035 | Central |
| 36 | Ellen H. McLaughlin | 94a1f084-689c-4774-8d36-fff2212af94d | -5120036 | Central |
| 37 | Terry L. Austin | 3049ed75-9743-42f4-8c9e-037a41f9bdc3 | -5120037 | Central |
| 38 | Sam Rasoul | 307597bd-3a05-41ad-a991-a7325ece5b5f | -5120038 | Central |
| 39 | Will P. Davis | 7b11e4bb-330b-4fb6-999e-b72974f3549c | -5120039 | Central |
| 40 | Joseph P. McNamara | 61e69826-c7d3-492b-a319-d2a34a33f92e | -5120040 | Central |
| 41 | Lily V. Franklin | f4257ee4-57c8-47dd-81ed-4abfa71a2e24 | -5120041 | Central |
| 42 | Jason S. Ballard | 03b1536c-8724-4e7e-a9ae-e07dcd07aba5 | -5120042 | Central |

### Western / Southwest VA (HD-43 – HD-55) — Waves 1–2

Republican-heavy. Rural, minimal online presence beyond Ballotpedia stubs and lis.virginia.gov floor votes. Expected yield: 0–6 stances. Honest-skip expected to dominate.

| HD | full_name | UUID | external_id | Region |
|----|-----------|------|-------------|--------|
| 43 | James W. Morefield | df51bc00-8a69-4bd0-9418-e61a3cfe248b | -5120043 | Southwest |
| 44 | Israel D. O'Quinn | 36673ec0-1045-4a98-8074-12d6deed5cc8 | -5120044 | Southwest |
| 45 | Terry G. Kilgore | 84257075-047c-46d3-ab7b-ed0e0ae0dd56 | -5120045 | Southwest |
| 46 | Mitchell Cornett | 3b10a611-77d2-48e2-bf45-40b7bdacdd51 | -5120046 | Southwest |
| 47 | Wren M. Williams | 38cb6796-1539-48ac-92e6-00068aa5e339 | -5120047 | Southwest |
| 48 | Eric J. Phillips | 7da511ee-1e98-4620-8852-a0f32dd45078 | -5120048 | Southwest |
| 49 | Madison Whittle | 4b4e3a27-dbf6-4984-a8a8-eeda9f972612 | -5120049 | Southwest |
| 50 | Thomas C. Wright, Jr. | ff50eaf3-0f12-455e-85b2-bc37f1e542db | -5120050 | Southwest |
| 51 | Eric Zehr | e5da439f-17bd-4337-ade5-eb7e5c9d48d4 | -5120051 | Southwest |
| 52 | Wendell S. Walker | f830ca33-179a-4981-8b89-0b02155e374b | -5120052 | Southwest |
| 53 | Timothy P. Griffin | 8123c0d7-aaf6-4abe-bb8d-5d835463f733 | -5120053 | Southwest |
| 54 | Katrina E. Callsen | 13a9c6b7-d781-415b-b44f-3f8ca06aa763 | -5120054 | Southwest |
| 55 | Amy J. Laufer | 80b9fe48-9f8c-4585-91ab-4d0ed1bc2229 | -5120055 | Southwest |

### Hampton Roads / Coastal / Piedmont East (HD-56 – HD-75) — Waves 5–6

Mixed party. Hampton Roads is a major metro area with decent press coverage. Expected yield: 6–15 stances.

| HD | full_name | UUID | external_id | Region |
|----|-----------|------|-------------|--------|
| 56 | Thomas A. Garrett, Jr. | e8228875-8fed-4f62-8184-22c5bb0093e1 | -5120056 | Hampton Roads |
| 57 | May Nivar | 191ee4e1-1514-4567-8fd4-8308e3b88bb0 | -5120057 | Hampton Roads |
| 58 | Rodney T. Willett | e39d94c7-99d5-4c1d-b8d9-11736637b1eb | -5120058 | Hampton Roads |
| 59 | Hyland F. Fowler, Jr. | 7639d181-586e-40a4-8d95-204c56ede118 | -5120059 | Hampton Roads |
| 60 | Scott A. Wyatt | d918e6be-5933-4b24-aada-84cbc461c207 | -5120060 | Hampton Roads |
| 61 | Michael J. Webert | 28714014-4c7e-427e-8190-fcc21875377a | -5120061 | Hampton Roads |
| 62 | Karen Fleming Hamilton | 11074d6c-4c9c-4b9e-9606-42eae7a6537c | -5120062 | Hampton Roads |
| 63 | Phillip A. Scott | 597a4057-4ccc-43f6-bf97-bcc701d7e637 | -5120063 | Hampton Roads |
| 64 | Stacey A. Carroll | ac78bc55-8fe9-4efb-a0ea-179842b6c44e | -5120064 | Hampton Roads |
| 65 | Joshua G. Cole | e2542ec1-213a-403b-bcda-e956a9384dcb | -5120065 | Hampton Roads |
| 66 | Nicole Cole | dcc9683b-f463-490f-aa9a-8b2ff2f7d6bb | -5120066 | Hampton Roads |
| 67 | Hillary Pugh Kent | 982ad606-8fc5-4d99-9275-c24b09c65c0c | -5120067 | Hampton Roads |
| 68 | M. Keith Hodges | 95cdc29b-18d1-45e1-84c3-ba601f5bec40 | -5120068 | Hampton Roads |
| 69 | Mark C. Downey | aefff366-6345-45fc-b52d-0e4ceb64d121 | -5120069 | Hampton Roads |
| 70 | Shelly A. Simonds | c25726d9-566e-4283-b35c-c608b921599f | -5120070 | Hampton Roads |
| 71 | Jessica L. Anderson | a0dfdf20-b736-4a1c-84c1-194a6625358e | -5120071 | Hampton Roads |
| 72 | R. Lee Ware | af619400-b4b0-48f4-ba87-69a5ddd53301 | -5120072 | Hampton Roads |
| 73 | Leslie Chambers Mehta | 92067acf-38bb-45cd-8897-b0694a75028a | -5120073 | Hampton Roads |
| 74 | Mike A. Cherry | c7f94731-2162-4fb7-803a-a2ff7443a9a1 | -5120074 | Hampton Roads |
| 75 | Lindsey Dougherty | 56001e27-1129-4e5c-88da-7a1cc18e83b0 | -5120075 | Hampton Roads |

### Richmond Metro / Southside Hampton Roads (HD-76 – HD-100) — Waves 7–8

Mixed-Democratic. Richmond is a high-press-coverage metro. Southside Hampton Roads has several prominent Black Democrats with long legislative records. Expected yield: 8–18 stances.

| HD | full_name | UUID | external_id | Region |
|----|-----------|------|-------------|--------|
| 76 | Debra D. Gardner | 08284136-be31-4d86-bf77-73c900026ade | -5120076 | Richmond |
| 77 | Charles H. Schmidt, Jr. | bf2a6480-5ac9-421c-b14d-710b86fc89c1 | -5120077 | Richmond |
| 78 | Betsy B. Carr | a1e1e5e6-661e-4bea-b29a-06eeb2dcba14 | -5120078 | Richmond |
| 79 | Rae C. Cousins | f9d4ebeb-9dc9-40d4-8318-da7042c42f48 | -5120079 | Richmond |
| 80 | Destiny L. LeVere Bolling | 26f9a670-60df-4826-8d48-d48629341718 | -5120080 | Richmond |
| 81 | Delores L. McQuinn | 980c9e90-4249-4a48-a777-5f37dd4d52b1 | -5120081 | Richmond |
| 82 | Kimberly Pope Adams | 107f5361-ddf4-4b26-a638-f5582430a0a5 | -5120082 | Richmond |
| 83 | Howard Otto Wachsmann, Jr. | 2c5f6685-d9f0-4134-a296-1ec2ee473a7c | -5120083 | Richmond |
| 84 | Nadarius E. Clark | 213b64d3-ee2f-4021-8eb4-39f36b79e036 | -5120084 | Richmond |
| 85 | Marcia S. Price | 0bac7849-1edb-46b4-b139-dcc759c0d626 | -5120085 | Richmond |
| 86 | Virgil Gene Thornton, Sr. | 02431c17-8c47-401b-ba36-efb3a1a331a9 | -5120086 | Richmond |
| 87 | Jeion A. Ward | c1e6a404-33c1-4a0d-9ff8-6e01890024c8 | -5120087 | Richmond |
| 88 | Don Scott | 407ffdf5-dc46-4081-b883-1cda1cfbbaa0 | -5120088 | Richmond |
| 89 | Karen Robins Carnegie | a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c | -5120089 | Richmond |
| 90 | James A. Leftwich, Jr. | 01f1abf8-84c8-4cbc-8ff7-4d900bc6c3a6 | -5120090 | Richmond |
| 91 | C. E. Hayes, Jr. | 52c621b5-2795-47cf-a7eb-8a815b3790d2 | -5120091 | Richmond |
| 92 | Bonita G. Anthony | fe47cdc4-c16b-446c-b674-82fdc074370d | -5120092 | Richmond |
| 93 | Jackie Hope Glass | 57517048-31a9-4974-bb5a-f82c3563a514 | -5120093 | Richmond |
| 94 | Phil M. Hernandez | e9cd8a4e-9e2b-4962-be21-7a2f68a650ba | -5120094 | Richmond |
| 95 | Alex Q. Askew | 9e843c9d-bd2e-431f-969f-63372d0274ca | -5120095 | Richmond |
| 96 | Kelly K. Convirs-Fowler | e65fba41-a46c-407c-86b3-810f1c8ecf38 | -5120096 | Richmond |
| 97 | Michael Feggans | c0117cd0-b340-4652-996c-5f7e5ba3d3c0 | -5120097 | Richmond |
| 98 | Andrew Rice | bf40d5f0-e1d6-4582-b319-46f4b7e0a541 | -5120098 | Richmond |
| 99 | Anne Ferrell H. Tata | 4eac03a8-a742-4dd9-8cdb-4f466df2fd24 | -5120099 | Richmond |
| 100 | Robert S. Bloxom, Jr. | 573ef077-c62f-45d3-9a5c-189d1c5308bf | -5120100 | Richmond |

---

## 10 Wave Compositions

**Geographic ordering:** Waves 1–2 front-load the hardest (lowest-yield) delegates, saving the highest-yield NoVA delegates for Waves 9–10 when the pattern is fully proven. Each wave covers 10 delegates (except Wave 2 which covers 13 Southwest delegates to close out that region cleanly).

**Note on HD-20 (Vacant):** The research agent dispatched for HD-20 should be skipped entirely — the DB record has `full_name = "Vacant"` with no actual politician. The wave 9 plan should document this as a deliberate skip with no research needed.

### Wave 1: Southwest VA Part 1 (HD-43 – HD-52)
**Migration:** 331
**External ID range:** -5120052 to -5120043
**Expected yield:** 0–6 stances per delegate; honest-skip likely dominant

| HD | full_name | UUID |
|----|-----------|------|
| 43 | James W. Morefield | df51bc00-8a69-4bd0-9418-e61a3cfe248b |
| 44 | Israel D. O'Quinn | 36673ec0-1045-4a98-8074-12d6deed5cc8 |
| 45 | Terry G. Kilgore | 84257075-047c-46d3-ab7b-ed0e0ae0dd56 |
| 46 | Mitchell Cornett | 3b10a611-77d2-48e2-bf45-40b7bdacdd51 |
| 47 | Wren M. Williams | 38cb6796-1539-48ac-92e6-00068aa5e339 |
| 48 | Eric J. Phillips | 7da511ee-1e98-4620-8852-a0f32dd45078 |
| 49 | Madison Whittle | 4b4e3a27-dbf6-4984-a8a8-eeda9f972612 |
| 50 | Thomas C. Wright, Jr. | ff50eaf3-0f12-455e-85b2-bc37f1e542db |
| 51 | Eric Zehr | e5da439f-17bd-4337-ade5-eb7e5c9d48d4 |
| 52 | Wendell S. Walker | f830ca33-179a-4981-8b89-0b02155e374b |

### Wave 2: Southwest VA Part 2 (HD-53 – HD-55) + Central/Shenandoah Part 1 (HD-37 – HD-42)
**Migration:** 332
**External ID range:** -5120055 to -5120053 + -5120042 to -5120037
**Note:** 9 delegates — fills wave with beginning of Central region for cleaner split
**Expected yield:** 0–8 stances per delegate

| HD | full_name | UUID |
|----|-----------|------|
| 53 | Timothy P. Griffin | 8123c0d7-aaf6-4abe-bb8d-5d835463f733 |
| 54 | Katrina E. Callsen | 13a9c6b7-d781-415b-b44f-3f8ca06aa763 |
| 55 | Amy J. Laufer | 80b9fe48-9f8c-4585-91ab-4d0ed1bc2229 |
| 37 | Terry L. Austin | 3049ed75-9743-42f4-8c9e-037a41f9bdc3 |
| 38 | Sam Rasoul | 307597bd-3a05-41ad-a991-a7325ece5b5f |
| 39 | Will P. Davis | 7b11e4bb-330b-4fb6-999e-b72974f3549c |
| 40 | Joseph P. McNamara | 61e69826-c7d3-492b-a319-d2a34a33f92e |
| 41 | Lily V. Franklin | f4257ee4-57c8-47dd-81ed-4abfa71a2e24 |
| 42 | Jason S. Ballard | 03b1536c-8724-4e7e-a9ae-e07dcd07aba5 |

### Wave 3: Central / Shenandoah Part 2 (HD-31 – HD-36) + Piedmont East (HD-56 – HD-59)
**Migration:** 333
**External ID range:** -5120036 to -5120031 + -5120059 to -5120056
**Note:** 10 delegates
**Expected yield:** 4–10 stances per delegate

| HD | full_name | UUID |
|----|-----------|------|
| 31 | Delores Oates | 11b44fd4-cbc4-415e-b567-c63f657fceab |
| 32 | William D. Wiley | c5490995-b962-4b20-ab8d-56ba1ba8d54b |
| 33 | Justin L. Pence | e345c9d6-4e28-4416-86de-24ab84c803f9 |
| 34 | Tony O. Wilt | 742d2c42-b277-4859-9269-1abc55affbe2 |
| 35 | Chris Runion | f3908370-f489-4a77-96f3-b19bf983618e |
| 36 | Ellen H. McLaughlin | 94a1f084-689c-4774-8d36-fff2212af94d |
| 56 | Thomas A. Garrett, Jr. | e8228875-8fed-4f62-8184-22c5bb0093e1 |
| 57 | May Nivar | 191ee4e1-1514-4567-8fd4-8308e3b88bb0 |
| 58 | Rodney T. Willett | e39d94c7-99d5-4c1d-b8d9-11736637b1eb |
| 59 | Hyland F. Fowler, Jr. | 7639d181-586e-40a4-8d95-204c56ede118 |

### Wave 4: Hampton Roads Part 1 (HD-60 – HD-69)
**Migration:** 334
**External ID range:** -5120069 to -5120060
**Expected yield:** 5–13 stances per delegate

| HD | full_name | UUID |
|----|-----------|------|
| 60 | Scott A. Wyatt | d918e6be-5933-4b24-aada-84cbc461c207 |
| 61 | Michael J. Webert | 28714014-4c7e-427e-8190-fcc21875377a |
| 62 | Karen Fleming Hamilton | 11074d6c-4c9c-4b9e-9606-42eae7a6537c |
| 63 | Phillip A. Scott | 597a4057-4ccc-43f6-bf97-bcc701d7e637 |
| 64 | Stacey A. Carroll | ac78bc55-8fe9-4efb-a0ea-179842b6c44e |
| 65 | Joshua G. Cole | e2542ec1-213a-403b-bcda-e956a9384dcb |
| 66 | Nicole Cole | dcc9683b-f463-490f-aa9a-8b2ff2f7d6bb |
| 67 | Hillary Pugh Kent | 982ad606-8fc5-4d99-9275-c24b09c65c0c |
| 68 | M. Keith Hodges | 95cdc29b-18d1-45e1-84c3-ba601f5bec40 |
| 69 | Mark C. Downey | aefff366-6345-45fc-b52d-0e4ceb64d121 |

### Wave 5: Hampton Roads Part 2 (HD-70 – HD-75) + Richmond Metro Part 1 (HD-76 – HD-79)
**Migration:** 335
**External ID range:** -5120075 to -5120070 + -5120079 to -5120076
**Note:** 10 delegates
**Expected yield:** 6–15 stances per delegate

| HD | full_name | UUID |
|----|-----------|------|
| 70 | Shelly A. Simonds | c25726d9-566e-4283-b35c-c608b921599f |
| 71 | Jessica L. Anderson | a0dfdf20-b736-4a1c-84c1-194a6625358e |
| 72 | R. Lee Ware | af619400-b4b0-48f4-ba87-69a5ddd53301 |
| 73 | Leslie Chambers Mehta | 92067acf-38bb-45cd-8897-b0694a75028a |
| 74 | Mike A. Cherry | c7f94731-2162-4fb7-803a-a2ff7443a9a1 |
| 75 | Lindsey Dougherty | 56001e27-1129-4e5c-88da-7a1cc18e83b0 |
| 76 | Debra D. Gardner | 08284136-be31-4d86-bf77-73c900026ade |
| 77 | Charles H. Schmidt, Jr. | bf2a6480-5ac9-421c-b14d-710b86fc89c1 |
| 78 | Betsy B. Carr | a1e1e5e6-661e-4bea-b29a-06eeb2dcba14 |
| 79 | Rae C. Cousins | f9d4ebeb-9dc9-40d4-8318-da7042c42f48 |

### Wave 6: Richmond Metro Part 2 (HD-80 – HD-89)
**Migration:** 336
**External ID range:** -5120089 to -5120080
**Expected yield:** 8–18 stances per delegate

| HD | full_name | UUID |
|----|-----------|------|
| 80 | Destiny L. LeVere Bolling | 26f9a670-60df-4826-8d48-d48629341718 |
| 81 | Delores L. McQuinn | 980c9e90-4249-4a48-a777-5f37dd4d52b1 |
| 82 | Kimberly Pope Adams | 107f5361-ddf4-4b26-a638-f5582430a0a5 |
| 83 | Howard Otto Wachsmann, Jr. | 2c5f6685-d9f0-4134-a296-1ec2ee473a7c |
| 84 | Nadarius E. Clark | 213b64d3-ee2f-4021-8eb4-39f36b79e036 |
| 85 | Marcia S. Price | 0bac7849-1edb-46b4-b139-dcc759c0d626 |
| 86 | Virgil Gene Thornton, Sr. | 02431c17-8c47-401b-ba36-efb3a1a331a9 |
| 87 | Jeion A. Ward | c1e6a404-33c1-4a0d-9ff8-6e01890024c8 |
| 88 | Don Scott | 407ffdf5-dc46-4081-b883-1cda1cfbbaa0 |
| 89 | Karen Robins Carnegie | a7128ce9-6e6d-40ef-9f54-b7dc2e51ad3c |

### Wave 7: Richmond / Southside Hampton Roads Part 3 (HD-90 – HD-100)
**Migration:** 337
**External ID range:** -5120100 to -5120090
**Note:** 11 delegates — slightly larger wave to keep remaining waves at 10
**Expected yield:** 5–15 stances per delegate (HD-95–100 = Hampton Roads / Coastal Plain)

| HD | full_name | UUID |
|----|-----------|------|
| 90 | James A. Leftwich, Jr. | 01f1abf8-84c8-4cbc-8ff7-4d900bc6c3a6 |
| 91 | C. E. Hayes, Jr. | 52c621b5-2795-47cf-a7eb-8a815b3790d2 |
| 92 | Bonita G. Anthony | fe47cdc4-c16b-446c-b674-82fdc074370d |
| 93 | Jackie Hope Glass | 57517048-31a9-4974-bb5a-f82c3563a514 |
| 94 | Phil M. Hernandez | e9cd8a4e-9e2b-4962-be21-7a2f68a650ba |
| 95 | Alex Q. Askew | 9e843c9d-bd2e-431f-969f-63372d0274ca |
| 96 | Kelly K. Convirs-Fowler | e65fba41-a46c-407c-86b3-810f1c8ecf38 |
| 97 | Michael Feggans | c0117cd0-b340-4652-996c-5f7e5ba3d3c0 |
| 98 | Andrew Rice | bf40d5f0-e1d6-4582-b319-46f4b7e0a541 |
| 99 | Anne Ferrell H. Tata | 4eac03a8-a742-4dd9-8cdb-4f466df2fd24 |
| 100 | Robert S. Bloxom, Jr. | 573ef077-c62f-45d3-9a5c-189d1c5308bf |

### Wave 8: NoVA Part 1 (HD-17 – HD-30) — 14 delegates (includes higher-traffic suburban NoVA)
**Migration:** 338
**External ID range:** -5120030 to -5120017
**Note:** 14 delegates (includes HD-20 Vacant — skip with header comment)
**Expected yield:** 10–20 stances per delegate; HD-20 = 0 (vacant — skip)

| HD | full_name | UUID | Note |
|----|-----------|------|------|
| 17 | Garrett McGuire | d701fee4-4d0a-44e8-9639-e8696c304b41 | |
| 18 | Kathy KL Tran | f224a300-8b54-4b57-b988-5c340667f99b | |
| 19 | Rozia A. Henson, Jr. | c01e3771-7930-479e-b1a0-710d58424660 | |
| 20 | **Vacant** | a8996e30-a386-45b5-8157-5d39b56a726f | **SKIP — vacant seat** |
| 21 | Josh Thomas | c566a41d-28e7-45cb-9eea-c9501878f2a7 | |
| 22 | Elizabeth R. Guzman | cea4db8b-acb5-4ebb-be09-e731d4412249 | |
| 23 | Margaret Angela Franklin | eaf0ce8c-b937-469f-b3a6-f9b1599610b4 | |
| 24 | Luke E. Torian | 87aa078a-ab94-4b17-86fc-6301d47a5824 | |
| 25 | Briana D. Sewell | 77ce6e63-7379-4c8a-9038-5c708510d6cc | |
| 26 | JJ Singh | c85b90a2-e81b-41a8-a74a-90d03018a443 | |
| 27 | Atoosa R. Reaser | b8856cc7-d711-436d-96b3-f0cbd352350a | |
| 28 | David A. Reid | 5061959c-b625-4b7a-b17f-a1291c50d001 | |
| 29 | Fernando J. Martinez | b754aca0-a0b6-43fc-a1f0-ecdc84a41d75 | |
| 30 | John C McAuliff | 9ec8ec01-2b15-42ae-8a52-cc77930be151 | |

**Planner note for Wave 8:** Dispatch only 13 research agents (skip HD-20 Vacant entirely). Document in migration header: "HD-20 is a vacant seat per `essentials.politicians.full_name = 'Vacant'`; no research possible; 0 rows expected." Wave 8 is the largest wave by delegate count (14 slots, 13 researched) — consider splitting into 8a/8b if parallel research agent timing becomes an issue.

**Revised split option (recommended):** Move HD-17 through HD-20 to a separate 8a wave and HD-21 through HD-30 to wave 8b proper. This keeps each wave to 10 or fewer researched delegates.

### Wave 9 (8a recommended split): NoVA Core (HD-1 – HD-10)
**Migration:** 339
**External ID range:** -5120010 to -5120001
**Expected yield:** 12–22 stances per delegate (most prominent NoVA delegates)

| HD | full_name | UUID |
|----|-----------|------|
| 1 | Patrick A. Hope | af6e165b-4668-449b-97a5-6b25c01c572a |
| 2 | Adele Y. McClure | 8461412e-6413-4f44-ae5e-b7c8e7f736a5 |
| 3 | Alfonso H. Lopez | 5b7f3c42-b1a2-4dbc-870b-7f1a96a7f4ba |
| 4 | Charniele L. Herring | 51f5dd85-abb6-4f50-bcb9-e5e6b82376b7 |
| 5 | R. Kirk McPike | b85d17af-a823-413c-b79c-aa4e7cfab730 |
| 6 | Richard C. Sullivan, Jr. | 1964984f-1751-4ac7-ae94-69e50b0c2968 |
| 7 | Karen Keys-Gamarra | c0baa6ca-b02d-4bbe-8d90-5f36d31cba1e |
| 8 | Irene Shin | 98023fc8-d83b-43ba-b7e1-5bd132122bbe |
| 9 | Karrie K. Delaney | b17426e3-d363-44fd-a2b7-a04f54f6d7cb |
| 10 | Dan Helmer | 090cebbd-19b5-41ed-9c9a-5f537cdb5470 |

### Wave 10 (8b + phase gate): NoVA Fairfax / Prince William (HD-11 – HD-16) + Phase Gate
**Migration:** 340
**External ID range:** -5120016 to -5120011
**Note:** 6 researched delegates + HD-20 vacant skip + phase gate SQL
**Expected yield:** 12–22 stances per delegate

| HD | full_name | UUID |
|----|-----------|------|
| 11 | Gretchen M. Bulova | 1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0 |
| 12 | Holly M. Seibold | 4a5090f7-8d76-40c1-b2f4-c2ed038e6687 |
| 13 | Marcus B. Simon | c490eece-71f4-4051-975d-8fa5ed5f652b |
| 14 | Vivian E. Watts | b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264 |
| 15 | Laura Jane Cohen | a1a470c9-1b16-4e98-999c-4106422cc52c |
| 16 | Paul E. Krizek | cd70f416-c844-41db-9ff4-c528e04a72be |

**Wave 10 plan also includes the phase gate SQL** (run after migration 340 applied):
```sql
-- Phase 112 gate — run after all 10 waves applied
SELECT COUNT(DISTINCT pa.politician_id) AS delegates_with_stances
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -5120100 AND -5120001;
-- Target: all delegates with documentable stances (not a fixed number — honest-skip allowed)

SELECT COUNT(*) AS unsourced
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE p.external_id BETWEEN -5120100 AND -5120001
  AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
-- Must return 0 (VAST-05 invariant)
```

---

## Wave Summary Table

| Wave | Plan File | Migration | Delegates | HD Range | Region | Migration SQL Scope |
|------|-----------|-----------|-----------|----------|--------|---------------------|
| 1 | 112-01 | 331 | 10 | HD-43–52 | Southwest | -5120052 to -5120043 |
| 2 | 112-02 | 332 | 9 | HD-53–55 + HD-37–42 | Southwest + Central | -5120055 to -5120053 + -5120042 to -5120037 |
| 3 | 112-03 | 333 | 10 | HD-31–36 + HD-56–59 | Central + Piedmont East | -5120036 to -5120031 + -5120059 to -5120056 |
| 4 | 112-04 | 334 | 10 | HD-60–69 | Hampton Roads Part 1 | -5120069 to -5120060 |
| 5 | 112-05 | 335 | 10 | HD-70–75 + HD-76–79 | Hampton Roads + Richmond | -5120075 to -5120070 + -5120079 to -5120076 |
| 6 | 112-06 | 336 | 10 | HD-80–89 | Richmond Metro | -5120089 to -5120080 |
| 7 | 112-07 | 337 | 11 | HD-90–100 | Richmond/S.Hampton Roads | -5120100 to -5120090 |
| 8 | 112-08 | 338 | 13 (skip HD-20) | HD-17–30 | NoVA Outer Suburbs | -5120030 to -5120017 |
| 9 | 112-09 | 339 | 10 | HD-1–10 | NoVA Core | -5120010 to -5120001 |
| 10 | 112-10 | 340 | 6 + phase gate | HD-11–16 | NoVA Fairfax/PW | -5120016 to -5120011 |

**Total researched delegates:** 99 (100 minus HD-20 Vacant)
**Total migrations:** 10 (331–340)

---

## Architecture Patterns

### System Architecture Diagram

```
[Research Agents: WebFetch only — ONE at a time]
     |
     v
[CSV files: backend/data/stance-research/YYYY-MM-DD-112-va-delegates-waveN.csv]
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
[Numbered SQL migration 331–340: records all upserts for reproducibility]
     |
     v
[Phase gate SQL: unsourced_count = 0 for full -5120100..-5120001 range]
```

### Recommended Project Structure
```
backend/data/stance-research/
├── 2026-06-XX-112-va-delegates-wave1.csv   # HD-43 through HD-52 (Southwest)
├── 2026-06-XX-112-va-delegates-wave2.csv   # HD-53–55 + HD-37–42 (SW + Central)
├── ...
└── 2026-06-XX-112-va-delegates-wave10.csv  # HD-11–16 (NoVA Fairfax/PW)
supabase/migrations/
├── 20260610000001_331_va_delegates_wave1_stances.sql
├── 20260610000002_332_va_delegates_wave2_stances.sql
├── ...
└── 20260610000010_340_va_delegates_wave10_stances.sql
```

### Pattern 1: Sequential Agent Dispatch (Phase 111 established)
**What:** ONE `politician-stance-researcher` agent per delegate, wait for completion.
**When to use:** Always — parallel agents exhaust WebFetch quota immediately.
**Reference:** SKILL.md STEP 1, user memory `feedback_stance_research_one_at_a_time.md`.

### Pattern 2: Pre-flight Topics Snapshot (Phase 111 Pattern 2)
**What:** Fetch live topics + stance texts fresh from DB, embed in every agent prompt.
**When to use:** Once per wave pre-flight — don't reuse across waves.

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

### Pattern 3: UUID Pre-flight Fetch Per Wave (Phase 111 Pattern 3)
**What:** Fetch politician UUIDs for the wave's external_id range before writing migration SQL.

```bash
# Example for Wave 1 (HD-43–52, external_id -5120052 to -5120043)
cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(
  'SELECT id, full_name, external_id FROM essentials.politicians WHERE external_id BETWEEN -5120052 AND -5120043 ORDER BY external_id DESC'
);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

### Pattern 4: Migration Template (Phase 111 Pattern 4 — adapted for delegates)

```sql
-- Migration 331: VA House Delegate stances — Wave 1 (HD-43 through HD-52)
-- Phase 112-01: VA Delegate Stances
-- Requirements: VAST-03, VAST-05
-- Source: backend/data/stance-research/YYYY-MM-DD-112-va-delegates-wave1.csv
-- HD-20 Vacant: documented skip — no rows written for this seat
-- Applied: NOT YET (write-only)

BEGIN;

-- politician_answers upserts
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES
  ('<uuid>', (SELECT id FROM inform.compass_topics WHERE topic_key = '<topic_key>'), <value>),
  ...
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- politician_context upserts
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES
  ('<uuid>', (SELECT id FROM inform.compass_topics WHERE topic_key = '<topic_key>'),
   'Reasoning here (single-quote-escaped: '' for apostrophes)',
   ARRAY(SELECT u FROM unnest(ARRAY['<url1>', '<url2>', '<url3>']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ...
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification: scoped to THIS WAVE's external_id range
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120052 AND -5120043;
  RAISE NOTICE 'VA delegates with stances in Wave 1: %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120052 AND -5120043
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances Wave 1: %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
```

**CRITICAL:** Use `pc.politician_id IS NULL` NOT `pc.id IS NULL` — `inform.politician_context` has a composite PK (`politician_id`, `topic_id`) with NO standalone `id` column. Using `pc.id IS NULL` will cause a compile error.

### Pattern 5: Phase Gate SQL

```sql
-- Phase 112 gate — run after all 10 waves applied
SELECT COUNT(DISTINCT pa.politician_id) AS delegates_with_stances
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
WHERE p.external_id BETWEEN -5120100 AND -5120001;
-- Target: all delegates where evidence was found (not a fixed number — honest-skip applies)

SELECT COUNT(*) AS unsourced
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE p.external_id BETWEEN -5120100 AND -5120001
  AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
-- Must return 0 (VAST-05 invariant)
```

### Anti-Patterns to Avoid
- **Parallel agent dispatch:** Never run more than 1 agent at a time.
- **Party inference:** Never assign a value because a delegate is Republican or Democrat.
- **PostgREST for inform schema:** Always use `pool.query()`.
- **`pc.id IS NULL` in verification:** `inform.politician_context` has no standalone `id` column — use `pc.politician_id IS NULL`.
- **Researching the Vacant seat (HD-20):** Do not dispatch an agent for `full_name = "Vacant"` (external_id -5120020). Document as deliberate skip in migration header.
- **Hardcoding topic list:** Always fetch live from DB; topic set can grow between waves.
- **Reusing migration number:** The highest file is 330. Next free is 331. Always verify before writing filename.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stance research | Custom scraper | `research-stances` SKILL + `politician-stance-researcher` agent | Rate-limit rules, Five-Chairs framing, CSV format already built |
| CSV parsing | Split on commas | `csv-parse/sync` | Quote columns (names with commas like "Thomas C. Wright, Jr.") contain commas and embedded quotes |
| DB write | Supabase JS `from('politician_answers')` | `pool.query()` BEGIN/COMMIT | inform schema not in PostgREST exposed list |
| Topic list | Hardcoded array | Live DB query | Topic set grows; hardcoded list goes stale between waves |
| Politician UUIDs | Hardcoded | Pre-flight query per wave | UUIDs are DB-assigned; hardcoding causes FK violations |

---

## Source Strategy for VA House Delegates

### By Region

**NoVA delegates (HD-1–30) — Tier 1 sources are reliable:**
- `ballotpedia.org/[First_Last]` — usually has detailed policy sections for NoVA delegates
- `house.virginia.gov/member/[district]` — official delegate page, constituent priorities
- `lis.virginia.gov/cgi-bin/legp604.exe?ses=252&typ=mbr&mbr=H[district]` — floor votes and bill sponsorship
- `vpap.org/officials/[slug]` — VPAP has good coverage of NoVA districts
- Wikipedia for prominent delegates (Hope, Herring, Watts, Simon)
- Press: Fairfax Times, InsideNOVA.com, Virginia Mercury, Washington Post (VA politics desk)
- Vote Smart / votesmart.org for VIF questionnaire responses

**Southwest VA delegates (HD-43–55) — limited coverage, use all available sources:**
- `ballotpedia.org/[First_Last]` — often minimal; try anyway
- `lis.virginia.gov` floor votes — most reliable source for documented positions
- `vpap.org/officials/[slug]` — sometimes has useful context
- Official campaign websites (check web.archive.org if current site is down)
- Southwest Times, Bristol Herald Courier, Roanoke Times for regional press

**Central / Shenandoah (HD-31–42):**
- Same pattern as Southwest but with Valley-specific press: Harrisonburg's Daily News-Record, Staunton News Leader
- `ballotpedia.org` often has moderate detail for this region

**Hampton Roads (HD-56–75):**
- Pilot Online (pilotonline.com) — major Hampton Roads paper
- Daily Press (dailypress.com) for Peninsula coverage
- `ballotpedia.org` has good coverage for established delegates
- VPAP and lis.virginia.gov as always

**Richmond Metro (HD-76–100):**
- Richmond Times-Dispatch — excellent coverage of Richmond-area delegates
- `ballotpedia.org` reliable for Richmond delegates
- Virginia Mercury for policy-specific coverage
- Black delegates (McQuinn, Ward, Scott, etc.) often have NAACP voter guides, HRC endorsements — these are Tier 2 sources for relevant topics

### Agent URL Fetch Pattern (in order)
```
1. https://ballotpedia.org/[First_Last]
2. https://lis.virginia.gov/cgi-bin/legp604.exe?ses=252&typ=mbr&mbr=H[district_number]
3. https://house.virginia.gov/member/[district_number]  (or equivalent path)
4. https://vpap.org/officials/[slug]  (try lowercase hyphenated name)
5. Wikipedia: https://en.wikipedia.org/wiki/[First_Last]
6. Official delegate .gov page (often linked from house.virginia.gov)
```

### Notes on Specific Delegates
- **Israel D. O'Quinn (HD-44):** Long-serving Southwest VA Republican. Ballotpedia + lis.virginia.gov most reliable. [ASSUMED]
- **Terry G. Kilgore (HD-45):** Very senior delegate, was Speaker pro tempore. Should have more Ballotpedia depth than typical Southwest delegate. [ASSUMED]
- **Don Scott (HD-88):** House Minority Leader / Speaker of the House. High-profile; excellent Ballotpedia and press coverage. [ASSUMED]
- **Charniele L. Herring (HD-4):** House Minority Leader emeritus; well-documented. [ASSUMED]
- **Patrick A. Hope (HD-1):** Long-serving Arlington delegate; extensive press record. [ASSUMED]
- **Sam Rasoul (HD-38):** Roanoke delegate, ran for governor 2021; strong web presence despite Western VA location. [ASSUMED]
- **Karen Keys-Gamarra (HD-7):** Former school board member at-large (Fairfax County); newer delegate. [ASSUMED]

---

## Common Pitfalls

### Pitfall 1: Agent Produces Empty CSV (Rate Limit)
**What goes wrong:** Agent launched; WebFetch quota exhausted; CSV is only a header row.
**Why it happens:** Previous agent was still processing when next was dispatched.
**How to avoid:** One agent at a time. Verify CSV gained new rows before next dispatch.
**Warning signs:** Agent completes in under 2 minutes; CSV contains only the header line.

### Pitfall 2: `pc.id IS NULL` Instead of `pc.politician_id IS NULL`
**What goes wrong:** Verification DO $$ block fails to compile; psql apply errors.
**Why it happens:** `inform.politician_context` uses a composite PK (`politician_id`, `topic_id`) — there is NO standalone `id` column. Copying old migration patterns without checking this.
**How to avoid:** Always use `pc.politician_id IS NULL` in LEFT JOIN checks.
**Warning signs:** `psql` error "column pc.id does not exist".

### Pitfall 3: Researching the Vacant Seat (HD-20)
**What goes wrong:** Agent dispatched for external_id -5120020; wastes time, may hallucinate content.
**Why it happens:** The DB has a placeholder row with `full_name = "Vacant"` to maintain the 100-record count; easy to include in a range query without noticing.
**How to avoid:** Wave 8 plan must explicitly skip HD-20. Document in migration header: "HD-20 is vacant per DB record."
**Warning signs:** Agent prompt contains "Vacant" as the politician name.

### Pitfall 4: Migration Number Conflict
**What goes wrong:** File named `20260610XXXXXX_330_...` conflicts with already-applied Wave 5 senator migration.
**Why it happens:** `SELECT MAX(version)` returns 325 (psql-applied migrations 326–330 not in `schema_migrations`). Developer uses 325+1=326 as next free — wrong.
**How to avoid:** ALWAYS check both `SELECT MAX(version)` AND `ls supabase/migrations/ | sort | tail -1`. The true next free is 331 (last file is 330).
**Warning signs:** `psql` error "duplicate key value violates unique constraint 'schema_migrations_pkey'" — but only if `schema_migrations` tracks it; psql-applied migrations may not surface this error. Check file listing first.

### Pitfall 5: Honest-Skip Inflation with value=3 Neutral
**What goes wrong:** Agent writes value=3 "neutral" for every topic with thin evidence.
**Why it happens:** Agent feels pressure to produce output; value=3 feels "safe."
**How to avoid:** Agent prompt must include: "Skip any topic where you cannot find sufficient evidence. Do NOT infer from party affiliation. Zero rows for a delegate is a valid and acceptable outcome."
**Warning signs:** Many value=3 stances with thin reasoning and non-specific source URLs (party homepage, Wikipedia disambiguation page).

### Pitfall 6: CSV Names With Commas Parsed Incorrectly
**What goes wrong:** "Thomas C. Wright, Jr." appears as two CSV fields; migration SQL uses wrong name.
**Why it happens:** CSV parsing via string split instead of RFC-4180 parser.
**How to avoid:** ALWAYS use `csv-parse/sync` to read CSVs. Never split on commas.
**Warning signs:** Migration SQL has `Thomas C. Wright` as name with stray ` Jr."` in the next column.

### Pitfall 7: Mixed External_ID Range in Wave DO $$ Block
**What goes wrong:** Wave 2 DO $$ block uses a contiguous range like `-5120055 AND -5120037` which accidentally includes SW delegates not in Wave 2 (because Wave 1 already applied HD-43–52).
**Why it happens:** Wave 2 covers a non-contiguous set of external_ids (-5120055 to -5120053 AND -5120042 to -5120037). A simple BETWEEN clause would span the gap.
**How to avoid:** For non-contiguous waves, use `IN (specific external_id list)` or two separate BETWEEN clauses connected with OR in the DO $$ verification block.
**Wave 2 specific fix:**
```sql
WHERE p.external_id IN (-5120053, -5120054, -5120055, -5120037, -5120038, -5120039, -5120040, -5120041, -5120042)
```

---

## Topic Scope for VA House Delegates

**44 live topics total** (verified 2026-06-10). State-scope delegates use all topics EXCEPT the city-level skip list.

**City-level topics to skip (SKILL.md defined — applied via honest-skip, no pre-filtering needed):**
- transportation-priorities, economic-development, homelessness-response, residential-zoning
- city-sanitation, local-immigration, rent-regulation, growth-and-development
- local-environment, public-safety-approach, jail-capacity
- All `judicial-*` topics

**Applicable topics for VA delegates (~22–25 state-eligible topics):**
abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change, data-centers, deportation, fossil-fuels, healthcare, homelessness, housing, immigration, medicare/aid, misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers, social-security, tariffs, taxes, trans-athletes, ukraine-support, voting-rights

Note: `data-centers` is applicable at state level (VA has major data center legislation in Loudoun County, directly relevant for NoVA delegates). `redistricting` is applicable at state level.

**Expected yield per region:**
- Southwest VA (Waves 1–2): 0–6 stances (honest-skip dominant)
- Central/Shenandoah (Waves 2–3): 3–10 stances
- Hampton Roads (Waves 4–5): 5–13 stances
- Richmond Metro (Waves 6–7): 8–18 stances
- NoVA (Waves 8–10): 12–22 stances

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | SQL assertions in migration DO $$ blocks + manual phase gate |
| Config file | None |
| Quick run | `psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM inform.politician_answers pa JOIN essentials.politicians p ON p.id = pa.politician_id WHERE p.external_id BETWEEN -5120100 AND -5120001"` |
| Full suite | Phase gate 2-query SQL (count + unsourced=0) after Wave 10 applied |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VAST-03 | Delegates with documentable stances appear in `inform.politician_answers` | SQL | `SELECT COUNT(DISTINCT politician_id) FROM inform.politician_answers pa JOIN essentials.politicians p ON p.id = pa.politician_id WHERE p.external_id BETWEEN -5120100 AND -5120001` — target: > 0 (honest-skip means total will be < 99) | ❌ Wave 1 pre-flight |
| VAST-05 | Every stance paired with context row + real source URL | SQL | `SELECT COUNT(*) FROM ... LEFT JOIN inform.politician_context pc ... WHERE pc.politician_id IS NULL OR array_length(pc.sources,1) = 0` — must return 0 | ❌ Wave 1 pre-flight |

### Sampling Rate
- Per wave: DO $$ ASSERT block in migration SQL
- Phase gate: 2-query SQL check after Wave 10 applied

### Wave 0 Gaps
None — no test files needed. All verification is SQL-assertion-based, matching established pattern from Phases 103/106/108/111.

---

## Security Domain

No security-sensitive changes. This phase writes to `inform.politician_answers` and `inform.politician_context` — both are public-read, admin-write via existing RLS (already enforced). No auth changes, no new endpoints, no PII. ASVS not applicable.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js + tsx | DB pre-flight scripts | ✓ | v24.13.0 | — |
| psql | Migration apply | ✓ (assumed from Phase 111) | — | Supabase dashboard SQL editor |
| DATABASE_URL (session pooler) | pool.query() + psql | ✓ | aws-0-*.pooler.supabase.com:5432 | — |
| WebFetch tool | Research agents | ✓ | — | — |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SW VA delegates (HD-43–55) have thin Ballotpedia coverage; 0–6 stances expected | Wave compositions, Source Strategy | If coverage is richer than expected, researcher wastes time with honest-skips that aren't necessary — acceptable false conservative |
| A2 | NoVA delegates (HD-1–16) have 12–22 stances documentable | Wave compositions, Source Strategy | If coverage is thinner (newer delegates, first term), researcher produces honest-skips — acceptable |
| A3 | Don Scott (HD-88) is House Speaker/Minority Leader with high coverage | Source Strategy notes | If wrong, researcher still checks Ballotpedia before concluding — acceptable fallback |
| A4 | `data-centers` topic is applicable for VA delegates (especially NoVA) | Topic Scope | If topic is scoped city-only, agent will honest-skip it anyway — no harm |
| A5 | Waves 2 and 3 involve non-contiguous external_id ranges that require IN() clause in DO $$ block | Common Pitfalls, Migration Template | If planner uses BETWEEN, the DO $$ check will over-count or under-count delegates |

---

## Open Questions

1. **Waves 2, 3, 5 non-contiguous ranges in DO $$ verification**
   - What we know: Waves 2, 3, and 5 each cover delegates from two different geographic sub-ranges that aren't contiguous in external_id space
   - What's unclear: Whether the planner will notice this and use IN() vs BETWEEN
   - Recommendation: Document explicitly in the pitfalls section (done above, Pitfall 7) and provide example SQL

2. **Wave 8 size (13 researched delegates — larger than other waves)**
   - What we know: HD-17 to HD-30 minus HD-20 Vacant = 13 delegates
   - What's unclear: Whether a 13-delegate wave is too large for a single plan
   - Recommendation: Split into Wave 8a (HD-17–23, 6 delegates) and Wave 8b (HD-24–30, 7 delegates) if timing is a concern. Wave count would shift to 11 plans with migrations 331–341.

3. **HD-20 Vacant seat**
   - What we know: DB record has `full_name = "Vacant"` and `external_id = -5120020`
   - What's unclear: Whether this seat will be filled during Phase 112 execution (special election possible)
   - Recommendation: Plan 8 must check this record at pre-flight time and skip if still vacant

---

## Sources

### Primary (HIGH confidence)
- DB query (2026-06-10) — 100 VA delegate records: verified, external_id range -5120001..-5120100, 0 existing stances, 1 vacant seat (HD-20)
- DB query (2026-06-10) — live topic count: 44
- DB query (2026-06-10) — `SELECT MAX(version)` = 325; disk file audit = 330 as highest
- SKILL.md (`.claude/skills/research-stances/SKILL.md`) — orchestration pattern, dispatch rules, CSV format
- Phase 111 RESEARCH.md — established migration template, DO $$ verification pattern, `pc.politician_id IS NULL` (not `pc.id IS NULL`)
- Phase 111 111-01-PLAN.md — reference plan structure: pre-flight → sequential agents → migration → apply → verify
- STATE.md (2026-06-10) — confirms Phase 111 complete, migration sync, DB state

### Secondary (MEDIUM confidence)
- Phase 111 senator roster + wave batching — wave composition strategy carried forward
- CONTEXT.md D-04 regional guidance — verified against actual district names; NoVA is HD-1–30 (inverse of "higher district numbers = rural")

### Tertiary (LOW confidence)
- Named delegate web presence estimates — [ASSUMED] from general knowledge of VA politics; actual yield will vary

---

## Metadata

**Confidence breakdown:**
- DB state (roster, migration number, topic count): HIGH — verified via live queries
- Standard stack: HIGH — same tooling as Phase 111; no new packages
- Architecture: HIGH — direct carry-forward from Phase 111
- Wave compositions: HIGH — computed from actual DB data
- Source strategy: MEDIUM — VPAP + Ballotpedia + lis.virginia.gov confirmed patterns; delegate-specific coverage estimates [ASSUMED]
- Pitfall: HIGH — Pitfalls 1/2/3/4 from direct Phase 111 experience; Pitfall 7 is a new Phase 112-specific hazard from non-contiguous wave ranges

**Research date:** 2026-06-10
**Valid until:** 2026-07-10 (stable — delegate records don't change; topic set grows slowly)
