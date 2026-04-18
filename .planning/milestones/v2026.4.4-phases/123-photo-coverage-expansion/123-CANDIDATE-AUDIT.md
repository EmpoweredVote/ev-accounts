# Phase 123: Photo Gap Audit

**Audit date:** 2026-04-17
**Source:** Production DB (`kxsdzaojfaibhuzmclfq`) — `essentials.race_candidates` joined to `essentials.politician_images`
**Filter:** Linked candidates (`politician_id IS NOT NULL`), `candidate_status = 'active'`, no `type='default'` row in `politician_images`
**Scope:** All elections, all states (not limited to May 5, 2026 IN per D-01)

## Summary

**55 candidates missing a default headshot photo**

- 26 Indiana candidates (May 5, 2026 primary)
- 29 California candidates (June 2, 2026 election)
- 17 are Phase 120 Priority C deferred candidates (absorbed per D-03)

## Indiana Candidates (May 5, 2026)

| politician_id | full_name | slug | race |
|---|---|---|---|
| b407f620-d412-46b4-939a-d0967f8f80d2 | Ronald H Hutson | ronald-h-hutson | Bean Blossom Township Trustee |
| c096fd15-2656-4e1c-bf86-beb506d472d7 | Michelle Bright | michelle-bright-aac5852f-515b-4f7f-ac87-03691f0d6a1a | Benton Township Trustee |
| c8a73d2a-205d-482e-bc78-8c81d965a28c | Barbara E McKinney | barbara-e-mckinney | Bloomington Township Board |
| 15c278e1-20d8-4a2c-9575-2e130a0ec37f | Elizabeth Sensenstein | elizabeth-sensenstein | Bloomington Township Board |
| ca5f69c1-5fd3-4a27-8e58-f78b0a2d3d2d | Steven Hinds | steven-hinds | Clear Creek Township Trustee |
| 909d124c-63e0-4887-9987-15b78383d406 | Thelma K Jeffries | thelma-kelley-jeffries | Clear Creek Township Trustee |
| 8d4c84a6-d928-42c1-b9c6-6a1433a161da | Katrina W Ladwig | katrina-weimer-ladwig | Indian Creek Township Board |
| d5c43411-143e-4a1c-a5d4-4ea346f638b5 | Wendi Reynolds | wendi-reynolds | Indian Creek Township Board |
| 4e020b4f-662b-4f9e-adc1-6635311f6b6b | Roger L Taylor | roger-l-taylor | Indian Creek Township Board |
| c905324f-0568-48e9-931f-d42ddc657ec3 | Christopher R Reynolds | christopher-r-reynolds | Indian Creek Township Trustee |
| ec9aa60a-c57b-4bd9-b169-22c05b628f96 | Jack Davis | jack-davis-94a01ba3-2dac-4e54-bb11-3bf8fe7675b1 | Perry Township Board |
| 09ae2145-53d0-4def-a32b-0d18d020aed5 | Susie Hamilton | susie-hamilton | Perry Township Board |
| 0af9a347-846e-441e-b575-a187d8c0528f | Barbara Sturbaum | barbara-sturbaum | Perry Township Board |
| 4e663791-4b3a-4df3-8cd1-aff5a133d100 | Scott E Smith | scott-e-smith | Polk Township Trustee |
| 6caa511c-7051-4974-b86f-f112ca3ada2b | Jay M Thrasher | jay-m-thrasher | Richland Township Board |
| 53a867be-2009-4139-aca4-6371dd05cb6a | David B Willibey | david-b-willibey | Richland Township Board |
| d29e4645-d19f-4081-992d-fe66344a126c | Dawn Durnil | dawn-durnil | Richland Township Trustee |
| c2e83228-1f15-4fb6-a1a2-8b11714afe4c | Sean P Hall | sean-p-hall | Salt Creek Township Board |
| 3bf35f73-452e-4879-bff4-1bba4e515d8e | Joseph Hickman | joseph-hickman-3ad21119-b077-4a12-bb58-02a7d5573093 | Salt Creek Township Board |
| 6775a8e6-37cb-437b-923b-5f664f6b3b5d | Joan C Hall | joan-c-hall-995a5b4a-83bd-43e2-87ce-019eca4f964c | Salt Creek Township Trustee |
| a6926086-aa11-4f42-bcd7-bf74c1e1a540 | Amy Oliver | (no slug) | State Representative, District 062 |
| a41df72a-b1ee-43b6-8b41-02b4966503db | Rita M Barrow | rita-m-barrow | Van Buren Township Trustee |
| ad773a1b-a007-4b7f-a1fe-2091db751d0d | Jerry W Ayers | jerry-w-ayers | Washington Township Board |
| 664899b9-9002-410b-b42a-40dbaf050d12 | Kenny L Bryant | kenny-l-bryant | Washington Township Board |
| 15c77faa-dfb6-485e-8b83-4611727d1eb3 | Andy Spriggs | andy-spriggs | Washington Township Board |
| be355b0e-79a9-4af2-9926-d5bee7ae2515 | Mary Vandeventer | mary-vanderventer | Washington Township Trustee |

## California Candidates (June 2, 2026)

| politician_id | full_name | slug | race |
|---|---|---|---|
| 13eea214-867a-4a66-ae1a-c0f9916ac833 | Maria Lou Calanche | (no slug) | Los Angeles City Council District 1 |
| 50e1b55e-e3be-48f8-abf5-bb0c71bec68b | Raul Claros | (no slug) | Los Angeles City Council District 1 |
| 15cb5825-649a-4cc5-b14b-ccd4b4402c87 | Nelson Grande | (no slug) | Los Angeles City Council District 1 |
| 63a3e614-e8f3-4bf5-a4c9-d070a6c70ce4 | Sylvia Robledo | (no slug) | Los Angeles City Council District 1 |
| 1d731710-7e7e-4685-ade7-f34bce70c088 | Colter Carlisle | (no slug) | Los Angeles City Council District 13 |
| 5d7f84b4-e987-4be2-b3c5-64933e559bed | Dylan Kendall | (no slug) | Los Angeles City Council District 13 |
| 161fa300-f273-4d3b-8bd6-fcd5da9c8aeb | Rich Sarian | (no slug) | Los Angeles City Council District 13 |
| c4dc6557-0d64-4d7d-a66d-437bcf243419 | Phillip L. Crouch Jr. | (no slug) | Los Angeles City Council District 15 |
| 716d3f30-d9f9-4d83-ae6f-9022ae1a8d7b | Jordan Rivers | (no slug) | Los Angeles City Council District 15 |
| 64bf3436-995b-48c2-b727-3ad73d4f65d3 | C.R. Celona | (no slug) | Los Angeles City Council District 3 |
| 4632aaf1-6667-4e41-9763-c8b56ca7e702 | Timothy Gaspar | (no slug) | Los Angeles City Council District 3 |
| 2cea762f-17c0-42a4-a83f-678a2941c8c9 | Barri Worth Girvan | (no slug) | Los Angeles City Council District 3 |
| dcfb12a1-5753-4bc7-99ee-db7871a117f5 | Jon Rawlings | (no slug) | Los Angeles City Council District 3 |
| 6104bfbd-2ae6-422a-b64b-37946dae84e4 | Lehi White | (no slug) | Los Angeles City Council District 3 |
| 615e9ced-2773-4092-ad3b-610e90ed237c | Henry Mantel | (no slug) | Los Angeles City Council District 5 |
| c22ed715-4d29-4e03-8885-543bf32b525e | Morgan Oyler | (no slug) | Los Angeles City Council District 5 |
| 7c0d3bdd-a363-4d97-93a9-67034c6a0ead | Monica Rodriguez | (no slug) | Los Angeles City Council District 7 |
| f3a27837-9be8-4734-a672-d6ba6de4b045 | Jorge Hernandez Rosas | (no slug) | Los Angeles City Council District 9 |
| 92876cb7-9905-4be7-b349-2a4a4ff39846 | Estuardo Mazariegos | (no slug) | Los Angeles City Council District 9 |
| 93613d15-1098-423b-9e18-81f125ac2408 | Jorge Nuño | (no slug) | Los Angeles City Council District 9 |
| 100405fd-4ccc-427d-9ccd-962739d6d292 | Elmer Roldan | (no slug) | Los Angeles City Council District 9 |
| b02347bb-5637-4e19-980e-b0dcb6634fec | Martha Sánchez | (no slug) | Los Angeles City Council District 9 |
| a25fea2b-2328-42d7-bb78-5b134a469af1 | Jose Ugarte | (no slug) | Los Angeles City Council District 9 |
| 3c45e748-055e-4b28-8ae9-05378fe1ee9a | James Aldana | (no slug) | Los Angeles County Board of Supervisors District 1 |
| d32179cb-2d56-4ca0-b9eb-dc15569640c3 | Noel Almario | (no slug) | Los Angeles County Board of Supervisors District 1 |
| 95860909-eb07-4ed4-bea1-54081d92ce8d | David Argudo | (no slug) | Los Angeles County Board of Supervisors District 1 |
| 2209bc3f-c842-4e9b-afda-5c2a819cdb6f | Annabella Figueroa Mazariegos | (no slug) | Los Angeles County Board of Supervisors District 1 |
| 73f1625a-888d-434a-bb7c-af97198d9069 | Tonia Arey | (no slug) | Los Angeles County Board of Supervisors District 3 |
| d9710b1e-027c-4867-a2d9-57f92844a38d | Roxanne Hoge | (no slug) | Los Angeles County Board of Supervisors District 3 |

## Phase 120 Priority C Candidates (absorbed)

The following 17 candidates were deferred from Phase 120 (contested-race photo-only). They appear in the Indiana list above and are treated identically to the non-contested-race population.

| name | race |
|---|---|
| Barbara E McKinney | Bloomington Township Board |
| Elizabeth Sensenstein | Bloomington Township Board |
| Steven Hinds | Clear Creek Township Trustee |
| Thelma K Jeffries | Clear Creek Township Trustee |
| Katrina W Ladwig | Indian Creek Township Board |
| Wendi Reynolds | Indian Creek Township Board |
| Roger L Taylor | Indian Creek Township Board |
| Jack Davis | Perry Township Board |
| Susie Hamilton | Perry Township Board |
| Barbara Sturbaum | Perry Township Board |
| Jay M Thrasher | Richland Township Board |
| David B Willibey | Richland Township Board |
| Sean P Hall | Salt Creek Township Board |
| Joseph Hickman | Salt Creek Township Board |
| Jerry W Ayers | Washington Township Board |
| Kenny L Bryant | Washington Township Board |
| Andy Spriggs | Washington Township Board |

## Query Used

```sql
SELECT
  p.id AS politician_id,
  p.full_name,
  p.slug,
  r.position_name AS race,
  e.election_date,
  e.state,
  CASE WHEN pi.url IS NULL THEN true ELSE false END AS missing_photo
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.politicians p ON p.id = rc.politician_id
LEFT JOIN essentials.politician_images pi
  ON pi.politician_id = p.id AND pi.type = 'default'
WHERE rc.politician_id IS NOT NULL
  AND rc.candidate_status = 'active'
  AND pi.url IS NULL
ORDER BY e.state, e.election_date, r.position_name, p.last_name;
```
