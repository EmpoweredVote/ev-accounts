# Phase 76: Candidate Stance Research — Research

**Researched:** 2026-05-21
**Domain:** Politician stance data — research-stances skill, inform schema ingestion for 43 Senate candidates + Armstrong/Husted gap-fill
**Confidence:** HIGH (DB queries confirmed candidate list, existing stances, and topic IDs; Phase 74 plans reviewed for patterns)

---

## Summary

Phase 76 adds stance data in `inform.politician_answers` and `inform.politician_context` for all 43 non-incumbent Senate candidates created in Phase 75 (external_ids -400101 through -400143), plus gap-fill stances for the two appointed incumbents Armstrong (OK) and Husted (OH) from 119th Congress 2nd session roll call evidence.

All 43 candidates are confirmed in the DB with zero existing stances — clean slate. Armstrong has 14 stances (16 missing from federal-30). Husted has 24 stances (6 missing from federal-30). The research-stances skill workflow is established from Phase 74 with patterns directly reusable.

The key difference from Phase 74 is that Senate candidates have sparse public records. Most have never voted in Congress. Research will rely on campaign websites, stated policy positions, endorsements, media coverage, and voting records from prior offices (House, governor, state legislature) rather than Senate roll call votes. The `/research-stances` skill handles this gracefully via WebFetch against Ballotpedia, ontheissues.org, and official sources — but the researcher agent will skip topics with genuinely thin evidence, producing 10-25 stances per candidate rather than 30.

**Primary recommendation:** 4 plans — research in 3 batches of roughly 15 candidates each (skill dispatches one at a time, so batching guides how many agents get spun per plan), plus 1 plan for Armstrong/Husted gap-fill and the SQL migration(s). Alternatively, combine migration work into the same plan as the last research batch.

---

## Candidate Inventory

All 43 candidates confirmed in `essentials.politicians` from migration 196. Zero have existing stances.

| external_id | UUID | Full Name | Party | State |
|-------------|------|-----------|-------|-------|
| -400101 | a9e04e1e-92d4-44e4-a411-b6fe4814290a | Steve Marshall | R | AL |
| -400102 | 3428e87f-dc47-4033-9f6a-6fe63ffc9fc9 | Barry Moore | R | AL |
| -400103 | 98480c0b-2b26-4098-a830-a2efd88fed29 | Dakarai Larriett | D | AL |
| -400104 | 6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba | Mary Peltola | D | AK |
| -400105 | a7307f34-90ca-4d29-8698-4898ed3de05c | Hallie Shoffner | D | AR |
| -400106 | 07a45a9b-7726-41bd-8f67-722b865345ec | Janak Joshi | R | CO |
| -400107 | a2fee754-f90c-47ff-a3b7-377d55992273 | Alex Vindman | D | FL |
| -400108 | 0ac89151-2b8d-4430-b9bd-3a80bef3413b | Angie Nixon | D | FL |
| -400109 | ce8d48a3-5137-4521-81cd-8a86c0999b37 | Mike Collins | R | GA |
| -400110 | b841a475-41b4-4f19-9ad1-13769b1f4eef | Derek Dooley | R | GA |
| -400111 | bc9ec968-d664-4987-8f9c-108f9ae51535 | David Roth | D | ID |
| -400112 | 965ffd53-89a8-46cc-adb1-16bf588ed1c3 | Juliana Stratton | D | IL |
| -400113 | a6f10769-ec53-456f-afbd-2a89d3ac84b2 | Don Tracy | R | IL |
| -400114 | bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1 | Ashley Hinson | R | IA |
| -400115 | db66036a-2a1f-4bcf-980e-2f29a336dc5f | Zach Wahls | D | IA |
| -400116 | b5cc94df-2ba3-4057-8abd-5760383b286b | Charles Booker | D | KY |
| -400117 | d6d297f5-5319-4be1-b938-6bcce63368e7 | Andy Barr | R | KY |
| -400118 | c79994ff-9e88-4318-97d9-d06b0ede183f | Julia Letlow | R | LA |
| -400119 | 8be7e981-77a6-4ef7-b8d7-891fd9cc26d8 | John Fleming | R | LA |
| -400120 | 7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7 | Graham Platner | D | ME |
| -400121 | 5ccb1f15-f285-470c-b86a-97f9e6b22dff | Seth Moulton | D | MA |
| -400122 | ec0cfeae-a512-4ce2-a8f2-a25b00112b9b | Abdul El-Sayed | D | MI |
| -400123 | 3bdf2b9e-7512-4cc6-93f5-252078fae92c | Mallory McMorrow | D | MI |
| -400124 | 3957855d-a78c-492d-b3b6-0f680c1f82c8 | Haley Stevens | D | MI |
| -400125 | ace0b96d-8ef8-4aca-8928-6848ae430da6 | Mike Rogers | R | MI |
| -400126 | 15bd3382-0d8a-4c3e-8ab9-ab324517882d | Peggy Flanagan | D | MN |
| -400127 | 0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff | Angie Craig | D | MN |
| -400128 | b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23 | Royce White | R | MN |
| -400129 | 4fd59af4-eca7-4cdc-9082-178278ce3dc8 | Scott Colom | D | MS |
| -400130 | 0f8bb5ea-8d89-4cfb-9291-04b54c128b82 | Kurt Alme | R | MT |
| -400131 | b6c3620e-1ac1-460c-acb4-74854d59b334 | Seth Bodnar | I | MT |
| -400132 | 79e1e32f-9b0d-4f8f-86f3-679185424596 | Dan Osborn | I | NE |
| -400133 | a4f51d46-c361-4b17-bd63-7932a01ee2c3 | Chris Pappas | D | NH |
| -400134 | ffb0dcac-385a-4df3-a441-cdbd0e713c1d | John Sununu | R | NH |
| -400135 | 1f7429f7-1ecd-4f44-abce-03c72d5cf664 | Roy Cooper | D | NC |
| -400136 | 867caca5-ab41-4e1b-b051-4a2cd95a335e | Michael Whatley | R | NC |
| -400137 | 56603da5-e7ad-48a9-8c77-259513869ed4 | Sherrod Brown | D | OH |
| -400138 | b1114b75-8ca1-494e-9251-e8faa84ff408 | Kevin Hern | R | OK |
| -400139 | ae7e8d67-e8a4-49a7-bb5c-715c99168374 | David Brock Smith | R | OR |
| -400140 | 238222f5-e5e0-4331-8540-ee904bbacb8a | Annie Andrews | D | SC |
| -400141 | 6b44e402-7ea5-4dad-b3dd-6066fab6c6f6 | Rachel Fetty Anderson | D | WV |
| -400142 | e2f59e14-a81d-45fe-86c0-c992a63d86cd | Harriet Hageman | R | WY |
| -400143 | f8869b74-2a0c-40b7-93b4-40f32eec7108 | James Byrd | D | WY |

**Pre-flight verification:** Zero existing stance rows confirmed for all 43 candidates via live DB query.

---

## Batching Strategy

**Constraint:** The `/research-stances` skill dispatches ONE agent at a time. Each agent handles one politician. For 43 candidates, the research phase is inherently sequential. The batch split determines how many politicians per plan, not parallelism.

**Candidate profile types by prior role:**
- **Former/current House members** (15): Barry Moore, Mary Peltola, Mike Collins, Ashley Hinson, Andy Barr, Julia Letlow, John Fleming, Seth Moulton, Haley Stevens, Mike Rogers, Angie Craig, Chris Pappas, Kevin Hern, Harriet Hageman — best-documented, will likely yield 20-30 stances each
- **High-profile statewide officials** (10): Steve Marshall (AG), Juliana Stratton (Lt. Gov), Roy Cooper (Gov), Peggy Flanagan (Lt. Gov), Sherrod Brown (former senator), John Sununu (former senator), Michael Whatley (RNC Chair), Abdul El-Sayed (public health), Alex Vindman — good documentation, 15-25 stances expected
- **State legislators/other** (12): Zach Wahls, Charles Booker, Mallory McMorrow, Angie Nixon, Don Tracy, Derek Dooley, David Brock Smith, Scott Colom, Dan Osborn, Seth Bodnar, Royce White, Kurt Alme — moderate documentation, 10-20 stances expected
- **Thin-record candidates** (6): Dakarai Larriett, Hallie Shoffner, Janak Joshi, David Roth, Graham Platner, Rachel Fetty Anderson, Annie Andrews, James Byrd — sparse public records, may hit minimum floor of 10 stances

**Recommended batching (4 plans):**

| Plan | Candidates | Count | Notes |
|------|-----------|-------|-------|
| 76-01 | AL-IA (Marshall through Wahls, -400101 to -400115) | 15 | Includes high-profile House members (Moore, Hinson), mixed record depth |
| 76-02 | KY-MN (Booker through White, -400116 to -400128) | 13 | Includes Moulton, El-Sayed, McMorrow, Stevens, Rogers, Flanagan, Craig — well-documented |
| 76-03 | MS-WY (Colom through Byrd, -400129 to -400143) | 15 | Includes Brown (former senator), Cooper (governor), Hern, Hageman — high quality; SQL migration for all 43 candidates |
| 76-04 | Armstrong (OK) + Husted (OH) gap-fill + migration for any delta rows | 2 | Targeted gap-fill using 119th Congress 2nd session roll call evidence; separate migration |

**Rationale:** Splitting into 3 research plans + 1 gap-fill plan keeps each plan to ~13-15 agents (manageable session length). Plan 76-03 writes the main candidate SQL migration. Plan 76-04 is a focused gap-fill with only 2 politicians.

**Alternative:** If 4 plans is too many, collapse 76-03 and 76-04 into one plan (15 candidates + 2 senators). This saves a plan but makes the final plan the heaviest. The phase spec says 2-4 plans so 4 is within scope.

---

## research-stances Skill Workflow

### Step-by-step for Phase 76

**STEP 0 — Topic resolution:** The skill fetches live topics from DB before each run. As of 2026-05-21 there are **44 live topics** (up from 43 in Phase 74 — `data-centers` was added). The skill's topic fetch is always fresh.

**STEP 1 — Dispatch agents (one at a time):** The skill spawns a `politician-stance-researcher` subagent per politician, sequential. Do NOT parallelize — rate limit on WebFetch.

**STEP 2 — Collect CSVs:** Skill writes output to `backend/data/stance-research/YYYY-MM-DD-[batch].csv`. Accept whatever filename the skill produces. One CSV per invocation (may be multiple per plan if researchers write separate files).

**STEP 3 — Present and approve:** Skill shows summary table. Choose **"Skip DB push"** for ALL research calls. Task 2 in each plan ingests via SQL migration (safer for idempotency).

**STEP 4 — SQL migration ingestion:** Write migration(s) using the Phase 74 pattern (see below).

### Critical invocation details

**`--topics` flag is MANDATORY** (Phase 74 pitfall #2). Without it, the skill's jurisdiction filter skips the 7 borderline-federal topics. For candidates, use the same 30-topic list as Phase 74:

```
abortion,ai-regulation,campaign-finance,childcare,civil-rights,climate-change,deportation,
fossil-fuels,healthcare,housing,immigration,medicare/aid,misinformation,redistricting,
religious-freedom,same-sex-marriage,school-vouchers,social-security,tariffs,taxes,
trans-athletes,ukraine-support,voting-rights,homelessness,homelessness-response,
public-safety-approach,economic-development,jail-capacity,judicial-criminal-justice,
judicial-interpretation
```

**New topic `data-centers`:** Added after Phase 74. This topic is local-city-level framing (data center siting decisions, local electricity costs) — skip for federal candidates, same as the other 14 city-level topics. Do NOT add it to the --topics list.

**Invocation format:**
```
/research-stances "Candidate Name 1, Candidate Name 2, ..."
  --topics abortion,ai-regulation,...[30-topic list]
```

Pass the full `--topics` string to every invocation. Skip DB push. Task 2 ingests via SQL.

### Push mechanism alternatives

Two patterns exist from Phase 74 work:

**Option A: SQL migration (preferred)** — Write a `BEGIN;...COMMIT;` migration with ON CONFLICT DO UPDATE upserts for both `inform.politician_answers` and `inform.politician_context`. Pattern from migrations 177-179 in Phase 74. Apply via psql. Idempotent.

**Option B: TypeScript push script** — Use `push-armstrong-ok.ts` or `push-dem-batches-13-15.ts` pattern: read CSV, call pool.query() per row with ON CONFLICT. More suitable for small targeted pushes.

For Phase 76, the **SQL migration pattern (Option A) is recommended** for the bulk of the 43 candidates, matching Phase 74 exactly. The Armstrong/Husted gap-fill in Plan 76-04 can use a targeted push script (Option B) since it's 2 politicians with < 25 rows total.

---

## Armstrong & Husted Gap Analysis

### Alan Armstrong (OK)

- **UUID:** `abbe5ec0-94fb-4230-bc7c-4b890e4e6387`
- **External ID:** -400064
- **Phase description external_id note:** Phase 76 description says -400061 for Armstrong, but the DB has -400061 for Husted and -400064 for Armstrong. Use UUID directly to avoid confusion.
- **Current stance count:** 14
- **Topics with stances:** `abortion, childcare, climate-change, deportation, fossil-fuels, healthcare, housing, immigration, medicare/aid, social-security, tariffs, taxes, ukraine-support, voting-rights`

**16 missing federal topics:**
```
ai-regulation, campaign-finance, civil-rights, economic-development,
homelessness, homelessness-response, jail-capacity, judicial-criminal-justice,
judicial-interpretation, misinformation, public-safety-approach, redistricting,
religious-freedom, same-sex-marriage, school-vouchers, trans-athletes
```

**119th Congress 2nd Session context:** Armstrong was appointed March 24, 2026. He cannot run for the full term by agreement. As of May 2026 he has been a senator for ~2 months, with very limited roll call vote history. Phase 76 spec says "at least one new stance from a 119th Congress 2nd session roll call that post-dates v2.3 ingestion."

**Approach:** For Armstrong's gap topics, use ontheissues.org, his statements and press releases as OK AG (2017-2026), any votes cast in his brief Senate tenure, and his public positions from the appointment process. The 119th Congress 2nd session started January 3, 2025 — Armstrong has only been in office since March 26, 2026, so Senate votes are limited. Use any vote he's participated in.

### Jon Husted (OH)

- **UUID:** `d5740b38-9b65-431a-9e33-645d432dec61`
- **External ID:** -400061
- **Current stance count:** 24
- **Topics with stances:** `abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change, deportation, economic-development, fossil-fuels, healthcare, immigration, medicare/aid, misinformation, public-safety-approach, redistricting, religious-freedom, same-sex-marriage, school-vouchers, social-security, tariffs, taxes, trans-athletes, ukraine-support, voting-rights`

**6 missing federal topics from the federal-30:**
```
homelessness, homelessness-response, housing, jail-capacity,
judicial-criminal-justice, judicial-interpretation
```

**119th Congress 2nd Session context:** Husted was appointed December 19, 2024 and has been a senator since early 2025. The 119th Congress 2nd session started January 3, 2025. Husted has a longer Senate voting record than Armstrong. He should have votes on housing, criminal justice bills, and judicial topics that post-date the Phase 74 ingestion date of 2026-05-21.

**Sources to check:** senate.gov vote records, roll call votes on omnibus bills, reconciliation votes, judicial nomination votes, housing/homelessness-related appropriations votes in 2025-2026.

### Phase description discrepancy on external_ids

The phase description states: "Armstrong (OK, external_id -400064) and Husted (OH, external_id -400061)." The DB confirms: Armstrong = -400064, Husted = -400061. This matches the phase description correctly. (An earlier note in this document was incorrect.) Always use UUIDs directly in migrations.

---

## Applicable Topics

The **30 federal-applicable topics** from Phase 74 apply unchanged to Senate candidates. Use the same `--topics` override string.

### Federal-30 topic list with IDs (from live DB + Phase 74 RESEARCH.md)

| # | topic_key | topic_id |
|---|-----------|----------|
| 1 | abortion | af2fdfd6-02c4-49df-b09c-cf8536f4773f |
| 2 | ai-regulation | 666bf03d-81fc-4138-ab15-69ae734c9023 |
| 3 | campaign-finance | 92730f69-ae57-401c-8ad1-2d07834a895d |
| 4 | childcare | c1ac1330-47f7-44ec-baf3-c913d926b97c |
| 5 | civil-rights | 0bc588c6-39e1-4084-b5de-cac909b8b762 |
| 6 | climate-change | f1e44d66-5d27-4b51-b54f-b7ace86f6a3c |
| 7 | deportation | 44905f3b-e105-4f6c-afc7-5d223813dbac |
| 8 | economic-development | eb3d1247-0de1-4b7f-baec-7259861efd53 |
| 9 | fossil-fuels | a22215c3-6693-4bc2-b248-01aebba14570 |
| 10 | healthcare | e8dad4a8-eb93-4931-91f5-d8fb5d7dd529 |
| 11 | homelessness | 4938766b-b45a-46e3-93bd-b8b30651271a |
| 12 | homelessness-response | 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f |
| 13 | housing | 669cac97-66a6-4087-b036-936fbe62efb3 |
| 14 | immigration | 4e2c69ce-591e-4197-9cd5-7aceff79d390 |
| 15 | jail-capacity | c267e137-0ff9-4e7d-9d13-e3cea1756cd0 |
| 16 | judicial-criminal-justice | 9db07b16-1076-4b7d-ad89-ebe7b51f4336 |
| 17 | judicial-interpretation | 448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee |
| 18 | medicare/aid | cab61e8a-64fe-4bbd-bc08-fe9914d0091b |
| 19 | misinformation | ddd65d64-9dc7-4208-a30f-59f4b9c0653d |
| 20 | public-safety-approach | e9ebefcd-c496-45e8-b816-a79f8442ba85 |
| 21 | redistricting | 48cc9585-ec22-4f53-8d42-6839828dd36f |
| 22 | religious-freedom | 6b9ba6d9-1001-43f5-b073-4d37130696fd |
| 23 | same-sex-marriage | c5ab4eab-702f-49b8-9277-8ea53f3835c6 |
| 24 | school-vouchers | 00b95a6a-75db-4521-b523-3326bba938de |
| 25 | social-security | 87d20824-a6e9-407b-983c-65440084a0ab |
| 26 | tariffs | 683c8084-2281-4920-a07c-18439b2dd413 |
| 27 | taxes | f7e5678d-dadd-4556-a2fc-446e24642ceb |
| 28 | trans-athletes | d1618b9c-0b9e-45af-b986-bb33d270b8e4 |
| 29 | ukraine-support | 24e9212c-b011-422a-865c-093e35050901 |
| 30 | voting-rights | d1792200-1d3b-4955-a0b7-0e6980d7a7b2 |

### Topics to SKIP for all candidates (14 local/judicial-role only)

From the skill's default guidance and the Phase 74 federal list analysis:
`city-sanitation, data-centers, growth-and-development, local-environment, local-immigration, rent-regulation, residential-zoning, transportation-priorities` (city-level)
`judicial-access-to-justice, judicial-bail-pretrial, judicial-government-deference, judicial-police-accountability, judicial-prosecution-priorities, judicial-transparency` (judicial-role only)

Note: `data-centers` is a new topic added since Phase 74. It is city-level framing and must be skipped for federal candidates.

---

## Phase 74 Patterns to Reuse

### SQL Migration Pattern (from migrations 177-179)

```sql
BEGIN;

-- ----- {CANDIDATE_FULL_NAME} / {TOPIC_KEY} -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('{CANDIDATE_UUID}', '{TOPIC_UUID}', {VALUE})
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('{CANDIDATE_UUID}', '{TOPIC_UUID}',
        $${REASONING_TEXT}$$,
        ARRAY['url1', 'url2']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
```

Key rules from Phase 74 that carry forward:
- Use `$$...$$` dollar-quoting for all reasoning text (avoids single-quote escaping)
- Strip empty source URLs from `ARRAY[]` (do NOT emit `ARRAY['url1', '', '']::text[]`)
- UTF-8 without BOM
- ON CONFLICT DO UPDATE on both tables
- Single `BEGIN;...COMMIT;` transaction per migration file
- Embed verification queries as SQL comments after `COMMIT;`

### CSV Format from research-stances skill

The skill produces CSVs with this format:
```
politician_id,topic_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3
```
- `politician_id` and `topic_id` are UUIDs (the candidate UUIDs from the DB are used by the researcher)
- `value` is numeric 1-5 (may include .5 increments)
- Sources in separate columns; the migration needs to filter empty ones

### TypeScript push script pattern (for gap-fill)

For Armstrong/Husted targeted gap-fill, the `push-armstrong-ok.ts` pattern works:
```typescript
// Read CSV, validate UUIDs, call pool.query() with ON CONFLICT
// Filter empty source_url columns before building ARRAY
// Script lives at backend/scripts/push-armstrong-ok-v2.ts (or similar)
```

### Migration numbers

- Migration 196: Phase 75 (candidates migration) — complete
- Next available: **197** (Phase 76's first migration)
- Phase 76 will consume: 197 (candidates stance migration) and possibly 198 (Armstrong/Husted gap-fill migration, if separate)

### Pre-flight check pattern

Before each batch, confirm zero existing stances for that batch's candidates:
```sql
SELECT COUNT(*) FROM inform.politician_answers
WHERE politician_id IN ('<uuid1>', '<uuid2>', ...);
-- MUST return 0 before proceeding with research
```

---

## Plan Structure Recommendation

### 4-plan structure (recommended)

**Plan 76-01: Batch 1 candidates (AL-IA, -400101 to -400115)**
- Research: 15 candidates via `/research-stances` with 30-topic list
- Skip DB push, collect CSV(s)
- Write migration 197 — bulk upsert for batch 1
- Apply migration, verify count, context pairing, no empty sources

**Plan 76-02: Batch 2 candidates (KY-MN, -400116 to -400128)**
- Research: 13 candidates via `/research-stances` with 30-topic list
- Skip DB push, collect CSV(s)
- Write migration 198 — bulk upsert for batch 2
- Apply migration

**Plan 76-03: Batch 3 candidates (MS-WY, -400129 to -400143)**
- Research: 15 candidates via `/research-stances` with 30-topic list
- Skip DB push, collect CSV(s)
- Write migration 199 — bulk upsert for batch 3
- Apply migration
- Run Phase 76 SC#1-3 checks (every candidate has >= 10 stances, no orphans)

**Plan 76-04: Armstrong & Husted gap-fill**
- Research: Armstrong with 16 missing topics (--topics ai-regulation,campaign-finance,civil-rights,economic-development,homelessness,homelessness-response,jail-capacity,judicial-criminal-justice,judicial-interpretation,misinformation,public-safety-approach,redistricting,religious-freedom,same-sex-marriage,school-vouchers,trans-athletes)
- Research: Husted with 6 missing topics (--topics homelessness,homelessness-response,housing,jail-capacity,judicial-criminal-justice,judicial-interpretation)
- Focus: source at least 1 row per senator from 119th Congress 2nd session (post-2026-05-21) roll call evidence
- Write migration 200 — upsert gap-fill rows
- Apply migration
- Verify SC#3: Armstrong has > 14 stances; SC#4: Husted has > 24 stances; both new rows have 119th Congress 2nd session source URL

### Alternative 3-plan structure

If 4 plans is too many, collapse batch 3 and gap-fill:
- Plan 76-01: AL-IA candidates (15) + migration 197
- Plan 76-02: KY-MN candidates (13) + migration 198
- Plan 76-03: MS-WY candidates (15) + migration 199 + Armstrong/Husted gap-fill + migration 200

The 3-plan alternative makes Plan 76-03 heavier (17 politicians, 2 migrations) but is within reason.

---

## Key Risks

### Risk 1: Sparse candidate records

**What:** Many candidates (first-time candidates, minor party challengers like Larriett, Shoffner, Joshi, Roth, Platner, Anderson, Byrd) have very thin public records. The researcher agent may find < 10 stances.

**Mitigation:** The phase success criterion says "no candidate has zero stances" and sets a lower floor for sparse records. Accept 10+ stances for well-known candidates, and a minimum-achievable count for those with genuinely thin records. The skill documents when it skips topics for insufficient evidence — this is expected behavior, not an error.

**Action in plans:** Verify each candidate has >= 1 stance row. Any candidate with 0 stances after the research call must be re-researched or manually investigated (look for campaign website, party questionnaires, endorsement questionnaires like LCV, NARAL, NRA ratings).

### Risk 2: Armstrong Senate tenure too short for roll call evidence

**What:** Armstrong was appointed March 24, 2026. He has been a senator for ~2 months. He may have cast very few roll call votes. The success criterion requires "at least one new stance from a 119th Congress 2nd session roll call that post-dates v2.3 ingestion" — v2.3 ended 2026-05-10, so any vote after May 10 qualifies.

**Mitigation:** Check senate.gov for Armstrong's full vote record. Even procedural votes (cloture, confirmation) can establish stances. If direct roll call evidence is thin, use Armstrong's public statements as AG (pre-Senate) for the 16 missing topics, while sourcing at least 1 stance from a Senate vote.

### Risk 3: Topic count floor vs. quality

**What:** Pushing for 30 topics on candidates with thin records risks low-quality or speculative stances. The skill already handles this by skipping thin-evidence topics, but researchers might "fill gaps" with weak evidence.

**Mitigation:** Enforce the same quality standard as senators: every stance must have a real, verified source URL. A candidate with 12 high-quality stances is better than one with 25 low-quality ones. The success criterion floor of 10 stances is the minimum, not a target.

### Risk 4: UUIDs resolved vs. external_ids

**What:** The researcher agent resolves politicians by name → DB lookup → UUID. For Phase 75 candidates, their names are in `essentials.politicians` but their `alternate_names` array may be empty. Researcher may fail to resolve some candidates by name if the name doesn't match exactly.

**Mitigation:** The skill's Step 4a ID resolution query uses `lower(p.full_name)` matching. If a candidate fails to resolve, the CSV still exists and can be manually pushed with the UUID substituted. Always pre-verify that the candidate is in the DB before starting research.

### Risk 5: Migration number drift during multi-plan execution

**What:** If other work (unrelated to Phase 76) adds migrations between plans, the migration numbers shift.

**Mitigation:** Always run `ls backend/migrations/ | sort -V | tail -5` before writing any migration file in a plan. Do not hardcode migration numbers into plan artifacts.

---

## Sources

### Primary (HIGH confidence)

- Live DB query — all 43 candidate UUIDs and external_ids confirmed from `essentials.politicians` + `essentials.offices`
- Live DB query — Armstrong (14 stances, 16 missing), Husted (24 stances, 6 missing) confirmed
- Live DB query — 44 live compass topics confirmed; `data-centers` is the new addition since Phase 74
- Phase 74 RESEARCH.md — federal-30 topic list with UUIDs; jurisdiction filtering rules; migration patterns
- Phase 74 PLAN files (74-01, 74-02, 74-03) — invocation patterns, --topics flag requirement, skip-DB-push pattern, migration structure

### Secondary (MEDIUM confidence)

- `backend/scripts/push-armstrong-ok.ts` — TypeScript push script pattern for targeted upserts
- `backend/scripts/push-dem-batches-13-15.ts` — Batch push script pattern for CSV-to-DB

---

## Metadata

**Confidence breakdown:**
- Candidate inventory: HIGH — confirmed from live DB query of migration 196
- Armstrong/Husted gap analysis: HIGH — live DB query of `inform.politician_answers`
- Federal-30 topic list: HIGH — same as Phase 74, IDs confirmed live
- research-stances skill workflow: HIGH — read SKILL.md + Phase 74 plans
- Migration patterns: HIGH — Phase 74 migrations 177-179 applied successfully
- Sparse candidate records risk: MEDIUM — expected behavior based on Phase 74 notes about thin-evidence skips

**Research date:** 2026-05-21
**Valid until:** 2026-09-01 (candidate set is stable post-Phase 75; topic list may grow but federal-30 is stable)
