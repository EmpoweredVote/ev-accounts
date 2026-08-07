-- 1587_la_county_2026_primary_post_dedupe_races.sql
--
-- Record the eight LA County city races that migration 1584 had to skip because their candidate rows
-- were duplicated. Migration 1586 merged the duplicates; these 29 rows can now be recorded safely.
--
--   Rollback: UPDATE essentials.race_candidates SET result=NULL, result_source=NULL,
--                    result_recorded_at=NULL WHERE id IN (<the 29 ids below>);
--
-- Source: LA County RR/CC certified results, June 2 2026 Statewide Direct Primary
--         (results.lavote.gov/text-results/4338, certified 2026-06-26, fetched 2026-08-07).
--
-- Rule per contest type, as established in migration 1584: GENERAL/REGULAR MUNICIPAL elections are
-- final (plurality, top N for N seats); PRIMARY NOMINATING elections need >50% or go to a November
-- runoff. Beverly Hills, Covina and Glendale are the former; Pomona is the latter.
--
-- ⚠️ Beverly Hills City Council elects THREE. Before migration 1586 this race held 22 rows for 12
-- people — Nazarian alone appeared five times. Recording winners against that would have produced
-- five winners for three seats, which is why 1584 skipped it rather than guessing.

-- Beverly Hills City Council — 3 seats, plurality.
UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF BEVERLY HILLS REGULAR MUNICIPAL ELECTION, Member of the City Council — three seats, top three elected.'
 WHERE id IN (
  '59eb1eb3-f44d-4eee-87c5-44276d9499db',  -- Sharona R. Nazarian  6,594  27.00%
  'ee2a9488-c579-478c-ad34-34c3e3f6c356',  -- Lester Friedman      3,607  14.77%
  'a328638b-ebcd-4acc-baa7-780a2ad336df'   -- Rebecca Pynoos       3,502  14.34%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF BEVERLY HILLS REGULAR MUNICIPAL ELECTION, Member of the City Council — finished outside the top three.'
 WHERE id IN (
  '14aaa067-84f7-4b66-b794-d418ddef4b78',  -- Andy Licht          3,284  13.44%
  '303a86c6-ad05-4e36-88c6-2764c4baab80',  -- Russell Stuart      2,480  10.15%
  '71103949-f4c3-4d14-b173-6e3afe9c07a8',  -- Ariel Rofeim        2,462  10.08%
  'c855b9e4-edeb-4a5f-9eba-6c4e5d0010a4',  -- Roger Tanenbaum       954   3.91%
  '81a6468a-1714-4a43-8d46-556e875ec7c8',  -- Barry Axelrod         504   2.06%
  '4ad25041-3182-4558-a16a-73fa34ce7ba9',  -- Andrew Kole           408   1.67%
  '6f65fb7a-3f8c-400e-b148-6ce80b3ed9da',  -- Jonathan Mariande     363   1.49%
  '6e8e877d-f9ee-4d5f-81a3-2a6340f0031d'   -- Clayton M. Saunders   268   1.10%
 );

-- John A. Mirisch: the ONLY Beverly Hills council row with no clerk_official origin — every copy of
-- him came from the discovery cron, and he appears nowhere in the certified 11-name field. A former
-- BH councilmember surfaced by an agent and never on the ballot.
UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Absent from the certified field for CITY OF BEVERLY HILLS REGULAR MUNICIPAL ELECTION, Member of the City Council in the LA County RR/CC official results for the June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). The contest is fully reported — 11 names summing to 100.00% — and none is Mirisch. This row originated solely from discovery_cron (no clerk_official counterpart).'
 WHERE id = 'b3b88e1c-340c-48ea-bd71-3cda9a391740';

-- Beverly Hills City Treasurer — unopposed.
UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF BEVERLY HILLS, City Treasurer: 6,653 votes, 100.00%, unopposed.'
 WHERE id = 'c5e81d51-22c9-4730-a47e-ad32261c228e';  -- Howard S. Fisher

-- Covina City Treasurer.
UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF COVINA GENERAL MUNICIPAL ELECTION, City Treasurer: Polzin 6,604 / 62.43%.'
 WHERE id = 'ae06be6c-9cf3-4aaa-aa90-204b01481df8';  -- Neil Polzin
UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF COVINA GENERAL MUNICIPAL ELECTION, City Treasurer: ballot name THOMAS "TJ" NASS, 3,974 / 37.57%.'
 WHERE id = 'd245a9fa-c6f2-4605-914c-c17c287c2ca8';  -- Thomas Nass

-- Glendale City Clerk and City Treasurer.
UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF GLENDALE GENERAL MUNICIPAL ELECTION: City Clerk — Abajian 22,806 / 59.94%; City Treasurer — Manoukian 25,429 / 69.24%.'
 WHERE id IN (
  'f7758769-c748-4318-bf17-3f1b115f9dad',  -- Suzie Abajian    City Clerk
  '8f7f2f27-1347-4379-84ae-43119e1cd94f'   -- Rafi Manoukian   City Treasurer
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF GLENDALE GENERAL MUNICIPAL ELECTION: City Clerk — Wolfson 15,243 / 40.06%; City Treasurer — Gevorkyan 11,297 / 30.76%.'
 WHERE id IN (
  '4a35558b-d003-4dea-b376-dd7a19ec20b2',  -- Susan Wolfson      City Clerk
  '11e7a15a-e401-4d8b-a0ca-d919c8b246a0'   -- David Gevorkyan    City Treasurer
 );

UPDATE essentials.race_candidates SET result='not_nominated', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Absent from the certified field for CITY OF GLENDALE GENERAL MUNICIPAL ELECTION, City Treasurer in the LA County RR/CC official results for the June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). That contest reports exactly two names, Manoukian and Gevorkyan, summing to 100.00%.'
 WHERE id = '36402a0d-47d3-4d44-a602-a2fdd9328451';  -- Ejmin Hakobyan

-- Pomona — PRIMARY NOMINATING, so >50% wins outright and anything less sends the top two to November.
UPDATE essentials.race_candidates SET result='runoff', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF POMONA PRIMARY NOMINATING ELECTION, Council District 2: no majority — Preciado 1,154 / 45.38% and Elizalde 840 / 33.03% advance to the November 3 2026 runoff.'
 WHERE id IN (
  'ee7b4e6f-3c09-4bf5-bb17-3bce1379d66b',  -- Victor Preciado   1,154  45.38%
  'c9c1b6b9-63c0-4866-89e5-4d14cd8bc170'   -- Jacky Elizalde      840  33.03%
 );

UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF POMONA PRIMARY NOMINATING ELECTION: District 3 — Garcia 1,681 / 71.87%; District 5 — Cobarrubias 2,458 / 50.12%. Both cleared 50% and are elected outright. District 5 is a 12-vote majority out of 4,904 cast.'
 WHERE id IN (
  '6cd50b00-a96c-47ca-ba64-0d17733febd7',  -- Nora Garcia         1,681  71.87%
  '92ce3693-5d5d-4dc1-90da-d7c526843d90'   -- Yvonne Cobarrubias  2,458  50.12%
 );

UPDATE essentials.race_candidates SET result='lost', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='LA County RR/CC certified results, June 2 2026 primary (results.lavote.gov/text-results/4338, fetched 2026-08-07). CITY OF POMONA PRIMARY NOMINATING ELECTION: D2 Zavala-Angulo 549 / 21.59%; D3 Cabrera 485 / 20.74%, Lopez 173 / 7.40%; D5 Rothman 2,446 / 49.88%.'
 WHERE id IN (
  'efd5bf64-e342-4cbd-943e-5b23c66d3869',  -- Samantha Zavala-Angulo  D2    549  21.59%
  'f601e0bc-6dce-45eb-a70c-e61513a224f7',  -- Veronica Cabrera        D3    485  20.74%
  'a0fcc3aa-8eb4-4321-b5c8-1355e27b6c76',  -- Rita Lopez              D3    173   7.40%
  'b27962ad-f120-4c80-beaa-9c7e631a2de2'   -- Elliott Rothman         D5  2,446  49.88%
 );
