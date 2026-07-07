-- 1202_seed_ma_2026_house_candidates.sql
-- Phase 161-08: MA CANDIDATES-ONLY seed onto the 9 PRE-EXISTING MA U.S. House races
--   (2026 Massachusetts General Election; races NOT created here -- reuse existing_race_id per
--   160-race-preexistence-audit.csv). 18 new MA politicians + 18 new active
--   race_candidates + 6 renominated-incumbent race_candidates rows (Neal/McGovern/Trahan/
--   Auchincloss/Lynch/Keating, reusing existing pids -- no new politician row for incumbents).
--   Clark (MA-5, pid 7bf73fb2-1b31-412e-913d-835bfd3e326d) and Pressley (MA-7, pid
--   c61baf45-dc2a-4d78-b4b7-21b1e9d79464) already have race_candidates rows -- NEVER re-inserted;
--   every race_candidates INSERT is guarded by NOT EXISTS on (race_id, politician_id).
--   MA-6 (Seth Moulton, retired) gets NO incumbent row -- open seat, full field is new.
--   Field source: 160-field-table-p161.csv MA rows (MA SoS dem-state-primary-candidates2026.htm),
--   declared-so-far independents only (Milleron MA-1 news-evidenced); MA independent filing stays
--   open to 2026-08-25 -- Phase 167 reconciles late filers.
--   ANTIPARTISAN INVARIANT: party is NEVER stored on race_candidates; races.primary_party untouched.
BEGIN;

-- Mark the 9 existing MA races PROVISIONAL (description-only; office_id/election_id untouched)
UPDATE essentials.races
SET description = 'PROVISIONAL: pre-primary field, cull >= 2026-09-02'
WHERE id IN ('3bfd0d89-cbb0-4bd4-952b-798214c29f84'::uuid,'e871b833-3601-48a6-8c1c-b3f9f2b5d5ca'::uuid,'f883b821-4648-4b97-85ee-167fc2542fa5'::uuid,'421a301b-eebb-4749-bd65-c3b5a056d687'::uuid,'df10ccfe-8841-41b5-a0de-f5ce182c7b21'::uuid,'4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid,'cc751102-b794-4484-88a3-37ca5c515307'::uuid,'e466ea3a-3b67-4fe5-8db4-688825793214'::uuid,'e9b035af-0037-45f5-95bf-6d4940b014b7'::uuid)
  AND (description IS NULL OR description NOT LIKE 'PROVISIONAL:%');

-- 18 new challenger/open-seat/declared-independent records (idempotent on external_id)
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250101, 'Jeromie Whalen', 'Jeromie', 'Whalen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250101);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250102, 'Nadia Milleron', 'Nadia', 'Milleron', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250102);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250301, 'Gary J. Grossi', 'Gary', 'J. Grossi', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250301);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250401, 'Jason Poulos', 'Jason', 'Poulos', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250401);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250402, 'Thomas Stalcup', 'Thomas', 'Stalcup', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250402);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250501, 'Tarik Samman', 'Tarik', 'Samman', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250501);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250502, 'Jonathan Paz', 'Jonathan', 'Paz', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250502);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250601, 'Bethany Andres-Beck', 'Bethany', 'Andres-Beck', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250601);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250602, 'John A. Beccia III', 'John', 'A. Beccia III', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250602);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250603, 'Jamie Belsito', 'Jamie', 'Belsito', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250603);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250604, 'Dan Koh', 'Dan', 'Koh', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250604);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250605, 'Mariah Lancaster', 'Mariah', 'Lancaster', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250605);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250606, 'Tram Nguyen', 'Tram', 'Nguyen', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250606);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250607, 'Micah Quinney Jones', 'Micah', 'Quinney Jones', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250607);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250801, 'Patrick Roath', 'Patrick', 'Roath', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250801);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250802, 'Robert Gerald Burke', 'Robert', 'Gerald Burke', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250802);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250901, 'Craig Swallow', 'Craig', 'Swallow', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250901);
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT -250902, 'R. Tyler MacAllister', 'R.', 'Tyler MacAllister', true
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -250902);

-- 18 new active race_candidates + 6 renominated-incumbent race_candidates
--   (NOT EXISTS on (race_id, politician_id) protects Clark/Pressley from duplication)
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3bfd0d89-cbb0-4bd4-952b-798214c29f84'::uuid, p.id, 'Jeromie Whalen', 'Jeromie', 'Whalen', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250101
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3bfd0d89-cbb0-4bd4-952b-798214c29f84'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3bfd0d89-cbb0-4bd4-952b-798214c29f84'::uuid, p.id, 'Nadia Milleron', 'Nadia', 'Milleron', false, 'active', 'Declared independent (news-evidenced, e.g. Milleron MA-1); provisional -- MA independent filing deadline 2026-08-25'
FROM essentials.politicians p
WHERE p.external_id = -250102
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3bfd0d89-cbb0-4bd4-952b-798214c29f84'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'f883b821-4648-4b97-85ee-167fc2542fa5'::uuid, p.id, 'Gary J. Grossi', 'Gary', 'J. Grossi', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250301
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'f883b821-4648-4b97-85ee-167fc2542fa5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '421a301b-eebb-4749-bd65-c3b5a056d687'::uuid, p.id, 'Jason Poulos', 'Jason', 'Poulos', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250401
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '421a301b-eebb-4749-bd65-c3b5a056d687'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '421a301b-eebb-4749-bd65-c3b5a056d687'::uuid, p.id, 'Thomas Stalcup', 'Thomas', 'Stalcup', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250402
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '421a301b-eebb-4749-bd65-c3b5a056d687'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df10ccfe-8841-41b5-a0de-f5ce182c7b21'::uuid, p.id, 'Tarik Samman', 'Tarik', 'Samman', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250501
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df10ccfe-8841-41b5-a0de-f5ce182c7b21'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'df10ccfe-8841-41b5-a0de-f5ce182c7b21'::uuid, p.id, 'Jonathan Paz', 'Jonathan', 'Paz', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250502
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'df10ccfe-8841-41b5-a0de-f5ce182c7b21'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid, p.id, 'Bethany Andres-Beck', 'Bethany', 'Andres-Beck', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250601
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid, p.id, 'John A. Beccia III', 'John', 'A. Beccia III', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250602
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid, p.id, 'Jamie Belsito', 'Jamie', 'Belsito', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250603
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid, p.id, 'Dan Koh', 'Dan', 'Koh', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250604
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid, p.id, 'Mariah Lancaster', 'Mariah', 'Lancaster', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250605
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid, p.id, 'Tram Nguyen', 'Tram', 'Nguyen', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250606
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid, p.id, 'Micah Quinney Jones', 'Micah', 'Quinney Jones', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250607
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '4a97bcde-4c8b-46b7-816e-9778b8ed17b5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'e466ea3a-3b67-4fe5-8db4-688825793214'::uuid, p.id, 'Patrick Roath', 'Patrick', 'Roath', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250801
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'e466ea3a-3b67-4fe5-8db4-688825793214'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'e466ea3a-3b67-4fe5-8db4-688825793214'::uuid, p.id, 'Robert Gerald Burke', 'Robert', 'Gerald Burke', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250802
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'e466ea3a-3b67-4fe5-8db4-688825793214'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'e9b035af-0037-45f5-95bf-6d4940b014b7'::uuid, p.id, 'Craig Swallow', 'Craig', 'Swallow', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250901
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'e9b035af-0037-45f5-95bf-6d4940b014b7'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'e9b035af-0037-45f5-95bf-6d4940b014b7'::uuid, p.id, 'R. Tyler MacAllister', 'R.', 'Tyler MacAllister', false, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.external_id = -250902
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'e9b035af-0037-45f5-95bf-6d4940b014b7'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3bfd0d89-cbb0-4bd4-952b-798214c29f84'::uuid, p.id, 'Richard Neal', 'Richard', 'Neal', true, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.id = 'a0cb697c-3158-4680-8e70-c154c3a15cc4'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3bfd0d89-cbb0-4bd4-952b-798214c29f84'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'e871b833-3601-48a6-8c1c-b3f9f2b5d5ca'::uuid, p.id, 'Jim McGovern', 'Jim', 'McGovern', true, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.id = 'ee4081d5-fc3e-4a8c-b39e-481ae20135d5'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'e871b833-3601-48a6-8c1c-b3f9f2b5d5ca'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'f883b821-4648-4b97-85ee-167fc2542fa5'::uuid, p.id, 'Lori Trahan', 'Lori', 'Trahan', true, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.id = 'b96758c6-2ea0-4698-8886-d574d34e366d'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'f883b821-4648-4b97-85ee-167fc2542fa5'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '421a301b-eebb-4749-bd65-c3b5a056d687'::uuid, p.id, 'Jake Auchincloss', 'Jake', 'Auchincloss', true, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.id = '41945b74-325e-4fa2-9cc9-edd11ead9ed3'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '421a301b-eebb-4749-bd65-c3b5a056d687'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'e466ea3a-3b67-4fe5-8db4-688825793214'::uuid, p.id, 'Stephen Lynch', 'Stephen', 'Lynch', true, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.id = '62b453da-3dea-4177-82ba-9e4b78eb7691'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'e466ea3a-3b67-4fe5-8db4-688825793214'::uuid AND rc.politician_id = p.id);
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT 'e9b035af-0037-45f5-95bf-6d4940b014b7'::uuid, p.id, 'Bill Keating', 'Bill', 'Keating', true, 'active', 'MA SoS dem-state-primary-candidates2026.htm, cross-checked Wikipedia 2026 MA US House elections'
FROM essentials.politicians p
WHERE p.id = '0d97085c-eca6-4530-9fc7-512ca05487b9'::uuid
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = 'e9b035af-0037-45f5-95bf-6d4940b014b7'::uuid AND rc.politician_id = p.id);

COMMIT;
