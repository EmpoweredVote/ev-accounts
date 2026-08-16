-- 1790_cal_access_track_a.sql
-- Cal-Access bucket B, Track A: the money. Verified against the OFFICIAL Cal-Access filer record.
--
-- Spec: docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md
-- Decisions, with the official name and basis for every link:
--   backend/data/cal-access-bucket-b/track-a-decisions.json
--
-- confirm-cal-access.ts linked committees on the LAST TOKEN of full_name and confirmed its own
-- guesses in the same pass (7,836 of 7,853 "confirmed"). Migration 1789 cleared bucket A, where that
-- token was not even the surname. This is the money half of what remained: the top 50 links by
-- displayed dollars, which carry 94.4% of all cal_access money on active politicians.
--
-- Each link needing evidence was resolved by fetching its Cal-Access filer record and reading the
-- OFFICIAL registered committee name -- the field the script should have used. Keep when that name
-- carries both the politician's surname and their given name (or a diminutive); purge otherwise,
-- including when no official record could be retrieved. That is the operator's prove-it-right posture.
--
-- ⚠ The filer records could NOT be fetched by a script: Cal-Access sits behind Incapsula, which
-- refuses a freshly launched Chromium and returns an EMPTY BODY with a 200 rather than an error.
-- See backend/scripts/cal-access-bucket-b/02-fetch-filers.ts for the full failure ladder.
--
-- KEEP  32 links  $26451393.94
-- PURGE 18 links  $12683421.80
BEGIN;

CREATE TEMP TABLE ta_purge (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO ta_purge (sid) VALUES
  ('c606976f-3ff4-4a62-8a15-eb4ebb8f67bf'),
  ('73675efb-df18-44b6-b1d6-a10d6eb71d95'),
  ('75059cb6-ac16-4706-a178-6b9290339a25'),
  ('1d26c460-e4a9-4541-96d3-ee045528cef9'),
  ('5eafec21-7750-4ee9-92df-6a7656636980'),
  ('48c4f2b0-21fd-4f57-88ac-1a33e8e707e0'),
  ('ba76f45a-db9d-4cce-8d52-901f4637e276'),
  ('6b1d0259-7f33-45a0-9bfe-5873b140398c'),
  ('717bf9d7-cf89-4d1a-afed-45f9e2bca344'),
  ('008f08bb-1e46-4b73-b6e4-0c741288b059'),
  ('b4e7f4a9-6baf-4445-89d1-f8f60ba26c33'),
  ('b3d96eab-43ff-481e-b584-013fa66026b7'),
  ('7724acd3-9ead-46ce-a137-39b2dbbc9580'),
  ('fea6f36a-5f9a-4b2c-baca-7df686ffdc33'),
  ('ddc2d41d-b744-4ede-9b18-1a99b8cd9bfb'),
  ('46bee92f-daad-4ecd-b72e-450cd1e69239'),
  ('cb2d5dde-0f18-43ed-94ff-3ad4bf307fd0'),
  ('1584f6a8-5c5e-4226-9f97-dcc58bdb2b43');

CREATE TEMP TABLE ta_keep (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO ta_keep (sid) VALUES
  ('1cb0d3a3-3b72-476e-83c5-6b064c4ebe71'),
  ('cace3a89-9917-4b0b-baab-68d2e47d93ac'),
  ('fb5c6993-e79c-4ce3-9315-2903c8f8728d'),
  ('5ad98135-09c5-4734-bed7-2e32adab677a'),
  ('317f1a37-a5e0-4e7e-ac34-65d9ee78e4ac'),
  ('a272c665-5d0c-4f49-ba53-86f7aea3a660'),
  ('15b441bd-7cdc-4bbf-941d-5bdef3f39bc4'),
  ('3939a6ac-f857-449a-a2a2-8078d4ac2aba'),
  ('e282085e-1694-4f91-8409-c86f22b7137d'),
  ('fd2a073f-b8f2-4e25-8020-eb0ccf077881'),
  ('8f026ae3-66b3-4eb6-ab71-ef55eca84f99'),
  ('7cce31b0-626a-404a-9d92-442d74c74ecc'),
  ('ef39d0c9-7cc0-47a2-80e8-16bb2156159d'),
  ('41594a69-60be-4e3f-ab09-26333889cc0f'),
  ('613ae1d1-5b8f-4d81-9020-f7b1dda03451'),
  ('5e6744e1-ceb4-4866-b80a-785794ee0ef8'),
  ('562048e9-2b21-4594-8fb1-10156519cd63'),
  ('87a46523-c61e-403c-a2c8-f2d367654784'),
  ('f6a69ced-47da-4bbd-b941-9999d725852f'),
  ('4bdf42d7-7b54-4747-b3a6-7f35ed7b73a2'),
  ('5e5d5dc3-9ad9-4980-9697-905daf27068e'),
  ('6127f32b-66d8-4697-87b5-16c0b7c0a961'),
  ('b35cfc8b-1701-4df4-bc9b-8dd8935ac1b4'),
  ('bf413d3c-d9e4-436a-a395-5e8924f72d90'),
  ('69658a9e-d85e-4be6-a4c6-fb2af585acd9'),
  ('c7758875-29cb-4940-88e4-d9d22c5e675d'),
  ('5cf16f26-902f-4dc6-bd01-bd61912c44be'),
  ('d40629eb-00b9-406d-b4d5-08752a9bea20'),
  ('98c696ec-49aa-46e4-ae45-a4838bd97c57'),
  ('f82e52f3-07a3-463b-8469-86c3f8fd7279'),
  ('f121660a-9406-44b3-8b88-46bde393ecd7'),
  ('b56532ec-c180-442c-9274-440acc45972e');

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM ta_purge;
  IF n <> 18 THEN RAISE EXCEPTION 'pre-check: purge set is %, expected 18', n; END IF;
  SELECT count(*) INTO n FROM ta_keep;
  IF n <> 32 THEN RAISE EXCEPTION 'pre-check: keep set is %, expected 32', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ta_purge p ON p.sid = ps.id
   WHERE ps.source_system <> 'cal_access';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % purge target(s) are not cal_access links', n; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ta_purge p ON p.sid = g.politician_source_id;
  IF d <> 12683421.80 THEN RAISE EXCEPTION 'pre-check: purge set displays %, expected 12683421.80', d; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ta_keep k ON k.sid = g.politician_source_id;
  IF d <> 26451393.94 THEN RAISE EXCEPTION 'pre-check: keep set displays %, expected 26451393.94', d; END IF;
END $$;

-- Money, by INLINE literal ids. IN (SELECT ... FROM <temp table>) seq-scans contributions and times
-- out -- a fresh temp table has no statistics so the planner ignores the index. Killed the first
-- attempt at migration 1789.
DELETE FROM transparent_motivations.contributions
 WHERE politician_source_id IN (
   'c606976f-3ff4-4a62-8a15-eb4ebb8f67bf',
   '73675efb-df18-44b6-b1d6-a10d6eb71d95',
   '75059cb6-ac16-4706-a178-6b9290339a25',
   '1d26c460-e4a9-4541-96d3-ee045528cef9',
   '5eafec21-7750-4ee9-92df-6a7656636980',
   '48c4f2b0-21fd-4f57-88ac-1a33e8e707e0',
   'ba76f45a-db9d-4cce-8d52-901f4637e276',
   '6b1d0259-7f33-45a0-9bfe-5873b140398c',
   '717bf9d7-cf89-4d1a-afed-45f9e2bca344',
   '008f08bb-1e46-4b73-b6e4-0c741288b059',
   'b4e7f4a9-6baf-4445-89d1-f8f60ba26c33',
   'b3d96eab-43ff-481e-b584-013fa66026b7',
   '7724acd3-9ead-46ce-a137-39b2dbbc9580',
   'fea6f36a-5f9a-4b2c-baca-7df686ffdc33',
   'ddc2d41d-b744-4ede-9b18-1a99b8cd9bfb',
   '46bee92f-daad-4ecd-b72e-450cd1e69239',
   'cb2d5dde-0f18-43ed-94ff-3ad4bf307fd0',
   '1584f6a8-5c5e-4226-9f97-dcc58bdb2b43');

DELETE FROM transparent_motivations.contribution_summary_agg
 WHERE politician_source_id IN (
   'c606976f-3ff4-4a62-8a15-eb4ebb8f67bf',
   '73675efb-df18-44b6-b1d6-a10d6eb71d95',
   '75059cb6-ac16-4706-a178-6b9290339a25',
   '1d26c460-e4a9-4541-96d3-ee045528cef9',
   '5eafec21-7750-4ee9-92df-6a7656636980',
   '48c4f2b0-21fd-4f57-88ac-1a33e8e707e0',
   'ba76f45a-db9d-4cce-8d52-901f4637e276',
   '6b1d0259-7f33-45a0-9bfe-5873b140398c',
   '717bf9d7-cf89-4d1a-afed-45f9e2bca344',
   '008f08bb-1e46-4b73-b6e4-0c741288b059',
   'b4e7f4a9-6baf-4445-89d1-f8f60ba26c33',
   'b3d96eab-43ff-481e-b584-013fa66026b7',
   '7724acd3-9ead-46ce-a137-39b2dbbc9580',
   'fea6f36a-5f9a-4b2c-baca-7df686ffdc33',
   'ddc2d41d-b744-4ede-9b18-1a99b8cd9bfb',
   '46bee92f-daad-4ecd-b72e-450cd1e69239',
   'cb2d5dde-0f18-43ed-94ff-3ad4bf307fd0',
   '1584f6a8-5c5e-4226-9f97-dcc58bdb2b43');

UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'not_applicable',
       notes = coalesce(ps.notes,'') || ' | WRONG PERSON (migration 1790, 2026-08-16):'
               || ' checked against the official Cal-Access filer record; that committee does not name'
               || ' this politician. See backend/data/cal-access-bucket-b/track-a-decisions.json.',
       updated_at = now()
  FROM ta_purge p
 WHERE ps.id = p.sid;

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM transparent_motivations.contribution_summary_agg g JOIN ta_purge p ON p.sid = g.politician_source_id;
  IF n <> 0 THEN RAISE EXCEPTION 'guard: % agg row(s) still on purged links', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.contributions c
   WHERE c.politician_source_id IN (
     'c606976f-3ff4-4a62-8a15-eb4ebb8f67bf',
   '73675efb-df18-44b6-b1d6-a10d6eb71d95',
   '75059cb6-ac16-4706-a178-6b9290339a25',
   '1d26c460-e4a9-4541-96d3-ee045528cef9',
   '5eafec21-7750-4ee9-92df-6a7656636980',
   '48c4f2b0-21fd-4f57-88ac-1a33e8e707e0',
   'ba76f45a-db9d-4cce-8d52-901f4637e276',
   '6b1d0259-7f33-45a0-9bfe-5873b140398c',
   '717bf9d7-cf89-4d1a-afed-45f9e2bca344',
   '008f08bb-1e46-4b73-b6e4-0c741288b059',
   'b4e7f4a9-6baf-4445-89d1-f8f60ba26c33',
   'b3d96eab-43ff-481e-b584-013fa66026b7',
   '7724acd3-9ead-46ce-a137-39b2dbbc9580',
   'fea6f36a-5f9a-4b2c-baca-7df686ffdc33',
   'ddc2d41d-b744-4ede-9b18-1a99b8cd9bfb',
   '46bee92f-daad-4ecd-b72e-450cd1e69239',
   'cb2d5dde-0f18-43ed-94ff-3ad4bf307fd0',
   '1584f6a8-5c5e-4226-9f97-dcc58bdb2b43');
  IF n <> 0 THEN RAISE EXCEPTION 'guard: % contribution(s) still on purged links', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ta_purge p ON p.sid = ps.id
   WHERE ps.research_status = 'not_applicable' AND ps.notes LIKE '%WRONG PERSON (migration 1790%';
  IF n <> 18 THEN RAISE EXCEPTION 'guard: % of 18 purged links demoted with a note', n; END IF;

  -- The keeps are the entire point of doing evidence work. Assert they survived UNCHANGED -- a bug
  -- that widened the purge satisfies every check above.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ta_keep k ON k.sid = ps.id
   WHERE ps.research_status = 'confirmed';
  IF n <> 32 THEN RAISE EXCEPTION 'guard: % of 32 kept links still confirmed', n; END IF;
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ta_keep k ON k.sid = g.politician_source_id;
  IF d <> 26451393.94 THEN RAISE EXCEPTION 'guard: kept money is now %, expected 26451393.94 untouched', d; END IF;

  RAISE NOTICE 'cal_access Track A: 18 links purged, 32 kept';
END $$;

COMMIT;
