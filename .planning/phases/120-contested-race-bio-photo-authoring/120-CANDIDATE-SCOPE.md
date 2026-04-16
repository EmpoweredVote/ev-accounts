# Phase 120: Contested-Race Candidate Scope

**Audit date:** 2026-04-16
**Source:** Production DB (`kxsdzaojfaibhuzmclfq`) — `essentials.race_candidates` joined to `essentials.elections` where `election_date = '2026-05-05' AND state = 'IN'`
**Filter:** Linked candidates (`politician_id IS NOT NULL`), `candidate_status = 'active'`, in races with 2+ active candidates (contested).
**Phase 117 note:** Per CONTEXT D-01/D-02, Phase 117 was planned but never executed — `117-FEASIBILITY.md` does not exist. This doc is the authoritative scope for Plan 02.

## Summary

**37 candidates in contested Monroe County May 5 races**
- 11 missing bios (`bio_text IS NULL`)
- 18 missing photos (no `politician_images` row with `type='default'`)
- 1 missing both (bio AND photo)
- 26 with at least one piece of content already in place

## Full Contested-Race Roster

| politician_id | full_name | slug | race | missing_bio | missing_photo |
|---|---|---|---|---|---|
| 06464416-e8f4-4df1-af4c-2d785863721e | Dorothy Granger | dorothy-granger | Bloomington Township Board | no | no |
| c8a73d2a-205d-482e-bc78-8c81d965a28c | Barbara E McKinney | barbara-e-mckinney | Bloomington Township Board | no | **yes** |
| 15c278e1-20d8-4a2c-9575-2e130a0ec37f | Elizabeth Sensenstein | elizabeth-sensenstein | Bloomington Township Board | no | **yes** |
| ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d | Steven Hinds | steven-hinds | Clear Creek Township Trustee | no | **yes** |
| 909d124c-63e0-4887-9987-15b78383d406 | Thelma K Jeffries | thelma-kelley-jeffries | Clear Creek Township Trustee | no | **yes** |
| 8d4c84a6-d928-42c1-b9c6-6a1433a161da | Katrina W Ladwig | katrina-weimer-ladwig | Indian Creek Township Board | no | **yes** |
| d5c43411-143e-4a1c-a5d4-4ea346f638b5 | Wendi Reynolds | wendi-reynolds | Indian Creek Township Board | no | **yes** |
| 4e020b4f-662b-4f9e-adc1-6635311f6b6b | Roger L Taylor | roger-l-taylor | Indian Creek Township Board | no | **yes** |
| da3a4550-4a3e-449b-b4ca-bbc9b15a11d7 | Bob Nyquist | (no slug) | Monroe County Assessor | **yes** | no |
| d3977ab4-22b8-4ac3-a14f-565bc2969f1a | Judith A Sharp | judith-a-sharp | Monroe County Assessor | no | no |
| 88c1b0f1-470e-4d96-8518-306c92d12021 | Tanner Dale Branham | (no slug) | Monroe County Clerk | **yes** | no |
| c0c45428-53c9-473e-ba4b-dc956d1868f2 | Joe Davis | (no slug) | Monroe County Clerk | **yes** | no |
| 609ee4ab-195b-4908-9463-9ff33c37688d | Tree Martin Lucas | (no slug) | Monroe County Clerk | **yes** | no |
| db4e6911-9dbb-430e-831c-08be094fd637 | Trent Deckard | trent-deckard | Monroe County Commissioner District 1 | no | no |
| 0be7d42f-9363-40ad-bbc5-733c862f4395 | David G Henry | david-g-henry | Monroe County Commissioner District 1 | no | no |
| 6ede6d42-2364-4e97-82dc-1ad850239d08 | Benjamin T. Arrington | (no slug) | Monroe County Prosecuting Attorney | **yes** | no |
| ed914571-dd22-4ab5-b764-92a1a465e980 | Erika Oliphant | erika-oliphant | Monroe County Prosecuting Attorney | no | no |
| ec9aa60a-c57b-4bd9-b169-22c05b628f96 | Jack Davis | jack-davis-94a01ba3-2dac-4e54-bb11-3bf8fe7675b1 | Perry Township Board | no | **yes** |
| 09ae2145-53d0-4def-a32b-0d18d020aed5 | Susie Hamilton | susie-hamilton | Perry Township Board | no | **yes** |
| 0af9a347-846e-441e-b575-a187d8c0528f | Barbara Sturbaum | barbara-sturbaum | Perry Township Board | no | **yes** |
| 6caa511c-7051-4974-b86f-f112ca3ada2b | Jay M Thrasher | jay-m-thrasher | Richland Township Board | no | **yes** |
| 53a867be-2009-4139-aca4-6371dd05cb6a | David B Willibey | david-b-willibey | Richland Township Board | no | **yes** |
| c2e83228-1f15-4fb6-a1a2-8b11714afe4c | Sean P Hall | sean-p-hall | Salt Creek Township Board | no | **yes** |
| 3bf35f73-452e-4879-bff4-1bba4e515d8e | Joseph Hickman | joseph-hickman-3ad21119-b077-4a12-bb58-02a7d5573093 | Salt Creek Township Board | no | **yes** |
| f84421ea-eb49-44c3-a6a7-a3cfaf5dc745 | Peggy Mayfield | peggy-mayfield | State Representative, District 060 | no | no |
| 533ae2ea-a474-4436-96b7-c2655242cefb | David Waters | (no slug) | State Representative, District 060 | **yes** | **yes** |
| 72dd5219-490f-48bb-986e-183a6098d602 | Matt Pierce | matt-pierce-35dd2d7b-0382-4676-b8a3-f853b9c544c4 | State Representative, District 061 | no | no |
| 1b5e218c-8fe0-48fe-b7af-52a2fbf1b0fc | Lilliana Young | (no slug) | State Representative, District 061 | **yes** | no |
| 037ad94f-d379-4f9c-baf1-a75742a46eac | James Graham | (no slug) | United States Representative, Ninth District | **yes** | no |
| 926943ad-ee64-4ddb-b9e7-6475a6a2d087 | Bradley Meyer | (no slug) | United States Representative, Ninth District | **yes** | no |
| a9233775-b8af-423e-aea6-734c2855e5ac | Timothy Peck | (no slug) | United States Representative, Ninth District | **yes** | no |
| 283b1fdd-3d89-4f82-a065-098324f2f967 | Keil Roark | (no slug) | United States Representative, Ninth District | **yes** | no |
| 3a65723a-7531-4712-8a7f-e4233a5aadfb | Theresa Oatman | theresa-oatman | Van Buren Township Board | no | no |
| 1c0afd7e-f476-4784-920f-f328a5c5d348 | John Wilson | john-wilson-4cb511c9-ab81-4d33-aa73-4b1242cc1815 | Van Buren Township Board | no | no |
| ad773a1b-a007-4b7f-a1fe-2091db751d0d | Jerry W Ayers | jerry-w-ayers | Washington Township Board | no | **yes** |
| 664899b9-9002-410b-b42a-40dbaf050d12 | Kenny L Bryant | kenny-l-bryant | Washington Township Board | no | **yes** |
| 15c77faa-dfb6-485e-8b83-4611727d1eb3 | Andy Spriggs | andy-spriggs | Washington Township Board | no | **yes** |

## Content Work Needed

### Priority A — Needs BOTH bio and photo (1 candidate)

| politician_id | name | race |
|---|---|---|
| 533ae2ea-a474-4436-96b7-c2655242cefb | David Waters | State Representative, District 060 |

### Priority B — Needs BIO only (10 candidates)

| politician_id | name | race |
|---|---|---|
| da3a4550-4a3e-449b-b4ca-bbc9b15a11d7 | Bob Nyquist | Monroe County Assessor |
| 88c1b0f1-470e-4d96-8518-306c92d12021 | Tanner Dale Branham | Monroe County Clerk |
| c0c45428-53c9-473e-ba4b-dc956d1868f2 | Joe Davis | Monroe County Clerk |
| 609ee4ab-195b-4908-9463-9ff33c37688d | Tree Martin Lucas | Monroe County Clerk |
| 6ede6d42-2364-4e97-82dc-1ad850239d08 | Benjamin T. Arrington | Monroe County Prosecuting Attorney |
| 1b5e218c-8fe0-48fe-b7af-52a2fbf1b0fc | Lilliana Young | State Representative, District 061 |
| 037ad94f-d379-4f9c-baf1-a75742a46eac | James Graham | United States Representative, Ninth District |
| 926943ad-ee64-4ddb-b9e7-6475a6a2d087 | Bradley Meyer | United States Representative, Ninth District |
| a9233775-b8af-423e-aea6-734c2855e5ac | Timothy Peck | United States Representative, Ninth District |
| 283b1fdd-3d89-4f82-a065-098324f2f967 | Keil Roark | United States Representative, Ninth District |

### Priority C — Needs PHOTO only (17 candidates)

| politician_id | name | race |
|---|---|---|
| c8a73d2a-205d-482e-bc78-8c81d965a28c | Barbara E McKinney | Bloomington Township Board |
| 15c278e1-20d8-4a2c-9575-2e130a0ec37f | Elizabeth Sensenstein | Bloomington Township Board |
| ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d | Steven Hinds | Clear Creek Township Trustee |
| 909d124c-63e0-4887-9987-15b78383d406 | Thelma K Jeffries | Clear Creek Township Trustee |
| 8d4c84a6-d928-42c1-b9c6-6a1433a161da | Katrina W Ladwig | Indian Creek Township Board |
| d5c43411-143e-4a1c-a5d4-4ea346f638b5 | Wendi Reynolds | Indian Creek Township Board |
| 4e020b4f-662b-4f9e-adc1-6635311f6b6b | Roger L Taylor | Indian Creek Township Board |
| ec9aa60a-c57b-4bd9-b169-22c05b628f96 | Jack Davis | Perry Township Board |
| 09ae2145-53d0-4def-a32b-0d18d020aed5 | Susie Hamilton | Perry Township Board |
| 0af9a347-846e-441e-b575-a187d8c0528f | Barbara Sturbaum | Perry Township Board |
| 6caa511c-7051-4974-b86f-f112ca3ada2b | Jay M Thrasher | Richland Township Board |
| 53a867be-2009-4139-aca4-6371dd05cb6a | David B Willibey | Richland Township Board |
| c2e83228-1f15-4fb6-a1a2-8b11714afe4c | Sean P Hall | Salt Creek Township Board |
| 3bf35f73-452e-4879-bff4-1bba4e515d8e | Joseph Hickman | Salt Creek Township Board |
| ad773a1b-a007-4b7f-a1fe-2091db751d0d | Jerry W Ayers | Washington Township Board |
| 664899b9-9002-410b-b42a-40dbaf050d12 | Kenny L Bryant | Washington Township Board |
| 15c77faa-dfb6-485e-8b83-4611727d1eb3 | Andy Spriggs | Washington Township Board |

### Already Complete — SKIP (9 candidates)

These candidates have both `bio_text` populated AND a `politician_images` row with `type='default'`. No content work required for this phase.

| politician_id | name | race |
|---|---|---|
| 06464416-e8f4-4df1-af4c-2d785863721e | Dorothy Granger | Bloomington Township Board |
| d3977ab4-22b8-4ac3-a14f-565bc2969f1a | Judith A Sharp | Monroe County Assessor |
| db4e6911-9dbb-430e-831c-08be094fd637 | Trent Deckard | Monroe County Commissioner District 1 |
| 0be7d42f-9363-40ad-bbc5-733c862f4395 | David G Henry | Monroe County Commissioner District 1 |
| ed914571-dd22-4ab5-b764-92a1a465e980 | Erika Oliphant | Monroe County Prosecuting Attorney |
| f84421ea-eb49-44c3-a6a7-a3cfaf5dc745 | Peggy Mayfield | State Representative, District 060 |
| 72dd5219-490f-48bb-986e-183a6098d602 | Matt Pierce | State Representative, District 061 |
| 3a65723a-7531-4712-8a7f-e4233a5aadfb | Theresa Oatman | Van Buren Township Board |
| 1c0afd7e-f476-4784-920f-f328a5c5d348 | John Wilson | Van Buren Township Board |

## Scope Note vs Original CONTEXT Estimate

CONTEXT.md framed this as "~5-10 candidates" based on the CONT-01/CONT-02 requirements which called out D-61 IN House, IN-9 US House, and "contested county offices." The audit reveals a wider contested-race universe including multiple township board races in Monroe County.

**Recommended scope decision for Plan 02:**
- **Minimum viable (pre-primary priority):** the 11 missing-bio candidates + the 1 missing-both. These are the profiles that currently render with no narrative context.
- **Stretch (if time allows):** photo-only gaps across the 17 township-level candidates.

Plan 02 may choose to narrow the scope to the highest-visibility races (county-level + US-9 + D-60/61) to stay within the ~5-10 candidate framing in CONTEXT.md, or broaden to the full 28-candidate content-needed list if time permits before May 1.

## Todd Young Note

CONT-02 explicitly called out Todd Young as missing a photo. The audit confirms Todd Young (`102b239c-0a3d-44b9-ae32-88d8179197e2`) already has both `bio_text` and a `politician_images` row hosted on Supabase CDN. No action needed — the CONTEXT.md assumption is stale.

## Query Used

```sql
SELECT
  p.id AS politician_id,
  p.full_name,
  p.slug,
  p.bio_text IS NULL AS missing_bio,
  pi.url IS NULL AS missing_photo,
  r.position_name AS race,
  r.primary_party
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON p.id = rc.politician_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = p.id AND pi.type = 'default'
WHERE e.election_date = '2026-05-05'
  AND e.state = 'IN'
  AND rc.politician_id IS NOT NULL
  AND rc.candidate_status = 'active'
  AND r.id IN (
    SELECT race_id FROM essentials.race_candidates
    WHERE candidate_status = 'active'
    GROUP BY race_id HAVING COUNT(*) > 1
  )
ORDER BY r.position_name, p.last_name;
```
