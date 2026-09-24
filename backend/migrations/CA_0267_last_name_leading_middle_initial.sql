-- CA_0267_last_name_leading_middle_initial.sql
-- Move a leading middle initial out of essentials.politicians.last_name ("Jeffrey S. Gray": last_name 'S. Gray').
--
-- WHY: last_name is the surname column, and surname matchers read it -- CA_0253's roster dedup joins on
-- lower(last_name) + lower(first_name), the stance-research verifier (researchVerifier.ts) looks for last_name in the
-- page text, and chamber rosters sort on it (essentialsBodiesService.ts). With 'S. Gray' in the column, none of them
-- sees "Gray". The Jeff Gray duplicate (CA_0261, PR #759) was found only by comparing the last token of full_name.
--
-- MEASURED 2026-09-24: 89 rows match last_name ~ '^[A-Z]\. ', 81 of them active. Every one has middle_initial and
-- name_suffix empty. Two writers:
--   32 rows  the Utah roster loaders (data_source ut-city-* / ut-county-* / ut-school-*): scripts/load-ut-city-rosters.ts,
--            load-ut-county-rosters.ts and load-ut-school-rosters.ts split full_name at the FIRST space, and
--            upsertPolitician (scripts/lib/politician-upsert.ts) overwrites last_name on conflict. Fixed in the same PR
--            (splitPersonName + middle_initial/name_suffix in the upsert), so a re-run no longer undoes this file.
--   50 rows  hand-generated seed migrations with the same first-space split (data_source NULL): the 2026 U.S. House
--            candidate seeds 1111-1275 (NY FL MI WA TN MA MO MN KY OK UT AK WY; generators scripts/15x-16x-*-generate.mts)
--            and the state-exec seed 981 (John S. Rodgers, VT; scripts/gen-state-exec-seed.mjs). One-shot, already run.
--    7 rows  HELD, not people: cal_access_discovery rows (2026-05-22) whose "name" is a committee name ('J. MAC FOR
--            ANAHEIM', 'C. S. U. L. B. NO ON 9 COALITION', ...). All inactive, first_name ''. Not touched; the gate lists them.
--
-- WHAT (82 rows, per id, each target written out below):
--   76 'initial'   'S. Gray'            -> middle_initial 'S.', last_name 'Gray'
--    5 'suffix'    'S. Kerr, Jr.'       -> middle_initial 'S.', last_name 'Kerr', name_suffix 'Jr.'   (II, III, Jr., Sr.)
--    1 'nickname'  'C. "Jim" McDermott' -> middle_initial 'C.', last_name 'McDermott', preferred_name 'Jim'
--   The suffix and nickname rows follow the corpus convention (27 rows already keep the suffix in name_suffix;
--   'Eusebio "Joe" Trujillo III' keeps the nickname in preferred_name). They are FLAGGED for review in the PR: drop them
--   from _r to leave them as they are, and the gate still passes only if they are then added to _held.
--   middle_initial keeps the period, as in full_name and in 117 existing rows ('X.'; 247 others store 'X').
--   full_name is NOT changed. first_name is NOT changed. No INSERT, no DELETE.
--
-- EFFECT ON READERS: cards that render first_name + ' ' + last_name (essentials Results.jsx, PoliticianGrid.jsx) show
-- "Jeffrey Gray" instead of "Jeffrey S. Gray" -- the same as the ~360 rows that already store the initial apart.
-- full_name readers (FEC matcher parseDbName, campaign-finance search, profile headers) see no change.
--
-- DUPLICATES THIS EXPOSES (not merged here; each needs its own review):
--   Justin J. Pearson  5d56470c (TN-9 House candidate, ext -470907)  vs de50a88b (TN House member, ext -4720086)
--   Matthew D. Klein   5e86fb53 (MN-2 House candidate, ext -270204)  vs 4966792b 'Matt D. Klein' (MN Senate, -2732185)
--   Richard A. Hyer    05624287 (inactive, ut-city-ogden)             vs 11c6810e 'Richard Hyer' (active)
--
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews). Dry run (BEGIN ... ROLLBACK) twice before,
--   revert confirmed each time. Apply: UPDATE 82, gate passed, COMMIT. Verified after: 7 rows match ^[A-Z]\. (the held
--   committee-name rows, 0 active).
-- ROLLBACK: for each id in _r, set last_name := old_last and clear middle_initial (and name_suffix / preferred_name for
--   the suffix / nickname rows).
-- IDEMPOTENT: each UPDATE is guarded on last_name = old_last AND middle_initial empty; a re-run changes nothing and the
--   gate still passes.

BEGIN;

CREATE TEMP TABLE _r (id uuid PRIMARY KEY, old_last text, mi text, new_last text, suffix text, preferred text,
                      kind text, full_name text) ON COMMIT DROP;
INSERT INTO _r VALUES
  ('03822919-91c0-413e-b7a7-abace4741959'::uuid, $$A. McKenzie$$, 'A.', $$McKenzie$$, NULL, NULL, 'initial', $$Abena A. McKenzie$$),
  ('21abfb53-adcd-4aaa-8f5b-37ef03af9d13'::uuid, $$D. Austill$$, 'D.', $$Austill$$, NULL, NULL, 'initial', $$Adam D. Austill$$),
  ('12c17d9d-0ada-49b6-bb1b-007f0022904d'::uuid, $$J. Koontz$$, 'J.', $$Koontz$$, NULL, NULL, 'initial', $$Andrew J. Koontz$$),
  ('0ccfe038-c44a-4384-a3c3-68f3a031f094'::uuid, $$R. Mavalwalla$$, 'R.', $$Mavalwalla$$, NULL, NULL, 'initial', $$Bajun R. Mavalwalla$$),
  ('a706e6bc-bee5-4d1f-a6ff-2435778dd18d'::uuid, $$A. Knox$$, 'A.', $$Knox$$, NULL, NULL, 'initial', $$Berton A. Knox$$),
  ('72337e52-8606-452d-988c-f7f39879715f'::uuid, $$P. O'Gorman$$, 'P.', $$O'Gorman$$, NULL, NULL, 'initial', $$Brian P. O'Gorman$$),
  ('ae6bd84c-2899-459d-99f1-25c3bdb0d666'::uuid, $$H. Nolen$$, 'H.', $$Nolen$$, NULL, NULL, 'initial', $$Byron H. Nolen$$),
  ('52e8eaf2-b733-4607-bac6-458f9ba569e3'::uuid, $$E. Henderson$$, 'E.', $$Henderson$$, NULL, NULL, 'initial', $$Carl E. Henderson$$),
  ('6eccd92f-958a-4ee5-8eb6-f9ca48e41af2'::uuid, $$E. Bowen$$, 'E.', $$Bowen$$, NULL, NULL, 'initial', $$Carlton E. Bowen$$),
  ('c7a4b1af-d48b-4c5f-aaec-7b6de2ef45bc'::uuid, $$D. Chung$$, 'D.', $$Chung$$, NULL, NULL, 'initial', $$Chris D. Chung$$),
  ('0f92207f-fbdd-4b2c-9ecb-de1d9b2803f6'::uuid, $$B. Monday$$, 'B.', $$Monday$$, NULL, NULL, 'initial', $$Christopher B. Monday$$),
  ('581b1632-a709-4400-a6a7-9a1c1b463635'::uuid, $$J. Oshel$$, 'J.', $$Oshel$$, NULL, NULL, 'initial', $$Cody J. Oshel$$),
  ('1f8ef9d6-3b97-4a86-ac2e-09607b768bb9'::uuid, $$W. Blomstrom$$, 'W.', $$Blomstrom$$, NULL, NULL, 'initial', $$David W. Blomstrom$$),
  ('9dc1fb52-a1ce-4460-8631-acd690e4d23b'::uuid, $$R. Hill$$, 'R.', $$Hill$$, NULL, NULL, 'initial', $$DeVante R. Hill$$),
  ('09f5bde9-227e-4265-934e-553de289244c'::uuid, $$L. Jackson$$, 'L.', $$Jackson$$, NULL, NULL, 'initial', $$DeVelle L. Jackson$$),
  ('79ac3f12-0f2e-4d4c-98c8-c9126a59b49e'::uuid, $$C. Chico$$, 'C.', $$Chico$$, NULL, NULL, 'initial', $$Douglas C. Chico$$),
  ('5d1a1cad-512b-4e93-9191-67e8ff621f99'::uuid, $$H. Feller$$, 'H.', $$Feller$$, NULL, NULL, 'initial', $$Edwin H. Feller$$),
  ('bca66a6e-a4e0-4af9-8f4f-735f8eec9091'::uuid, $$J. Grossi$$, 'J.', $$Grossi$$, NULL, NULL, 'initial', $$Gary J. Grossi$$),
  ('48192f8e-a15b-4df1-bfe3-8121d3ec6efc'::uuid, $$A. Goetzman$$, 'A.', $$Goetzman$$, NULL, NULL, 'initial', $$Gregory A. Goetzman$$),
  ('8b38c7e4-e440-4576-9f1f-d7d33f7bb36f'::uuid, $$H. Garcia$$, 'H.', $$Garcia$$, NULL, NULL, 'initial', $$Hernan H. Garcia$$),
  ('163790d1-c6ce-4644-a223-9f81116e3f21'::uuid, $$A. Johnson$$, 'A.', $$Johnson$$, NULL, NULL, 'initial', $$James A. Johnson$$),
  ('353f5a81-a800-41d1-a8ac-f4a739b4c43f'::uuid, $$D. Hooper$$, 'D.', $$Hooper$$, NULL, NULL, 'initial', $$James D. Hooper$$),
  ('8347a145-9a4e-46bb-9776-6a910fb0cecc'::uuid, $$B. Williams$$, 'B.', $$Williams$$, NULL, NULL, 'initial', $$John B. Williams$$),
  ('73f84c5f-292e-43d5-93e8-7a1070e6c0c5'::uuid, $$C. Hughs$$, 'C.', $$Hughs$$, NULL, NULL, 'initial', $$John C. Hughs$$),
  ('cc69581a-c2ce-4ec8-8f1b-68604c985c47'::uuid, $$P. Roco$$, 'P.', $$Roco$$, NULL, NULL, 'initial', $$John P. Roco$$),
  ('aa4040bf-4468-460e-8cb4-5a1e2a53c34f'::uuid, $$S. Rodgers$$, 'S.', $$Rodgers$$, NULL, NULL, 'initial', $$John S. Rodgers$$),
  ('bc3a324b-7610-4d2c-a7c7-962e1e8676e6'::uuid, $$M. Williams$$, 'M.', $$Williams$$, NULL, NULL, 'initial', $$Jomo M. Williams$$),
  ('53e0fcdb-7721-468f-a4b3-30289f6bb972'::uuid, $$D. Hinders$$, 'D.', $$Hinders$$, NULL, NULL, 'initial', $$Jordan D. Hinders$$),
  ('f9e23754-bec5-4c57-8002-622d2354f78f'::uuid, $$E. Neal$$, 'E.', $$Neal$$, NULL, NULL, 'initial', $$Joyce E. Neal$$),
  ('5d56470c-fb82-42f7-82e3-d28bf74ace47'::uuid, $$J. Pearson$$, 'J.', $$Pearson$$, NULL, NULL, 'initial', $$Justin J. Pearson$$),
  ('27e19bcf-9501-48b5-bc08-34097fcefc70'::uuid, $$B. Goodenough$$, 'B.', $$Goodenough$$, NULL, NULL, 'initial', $$Keith B. Goodenough$$),
  ('9db5bd05-9729-4f95-ba18-df821898c3b8'::uuid, $$T. Reeves$$, 'T.', $$Reeves$$, NULL, NULL, 'initial', $$Latonya T. Reeves$$),
  ('c34c6995-360f-4cc3-82e5-5b8f6c352ae9'::uuid, $$D. Bivings$$, 'D.', $$Bivings$$, NULL, NULL, 'initial', $$Martell D. Bivings$$),
  ('5e86fb53-a6eb-4b35-82de-79706a66dc1a'::uuid, $$D. Klein$$, 'D.', $$Klein$$, NULL, NULL, 'initial', $$Matthew D. Klein$$),
  ('588ff26e-9bb2-44a9-b336-ba58563a2935'::uuid, $$A. Salazar$$, 'A.', $$Salazar$$, NULL, NULL, 'initial', $$Melanie A. Salazar$$),
  ('d6aef5fb-9c50-4d5d-98fb-07346286ab25'::uuid, $$R. Stoddard$$, 'R.', $$Stoddard$$, NULL, NULL, 'initial', $$Michael R. Stoddard$$),
  ('c22803be-0ada-4319-92df-49939cf7d2b8'::uuid, $$R. Morlan$$, 'R.', $$Morlan$$, NULL, NULL, 'initial', $$Oliver R. Morlan$$),
  ('a91374c7-51c6-4afb-a618-771a17bd67de'::uuid, $$G. Baker$$, 'G.', $$Baker$$, NULL, NULL, 'initial', $$Richard G. Baker$$),
  ('916b024d-e8e9-4c29-a59e-8cb814fb9200'::uuid, $$M. Moesinger$$, 'M.', $$Moesinger$$, NULL, NULL, 'initial', $$Robert M. Moesinger$$),
  ('395adcfb-3a6b-4e95-8283-34673b2d8918'::uuid, $$P. Henri$$, 'P.', $$Henri$$, NULL, NULL, 'initial', $$Robert P. Henri$$),
  ('06408eda-4984-4bd3-b7ca-463bdf8197d4'::uuid, $$A. Loecken$$, 'A.', $$Loecken$$, NULL, NULL, 'initial', $$Thomas A. Loecken$$),
  ('080dee20-81d1-45b3-a83d-c01442fb3cd6'::uuid, $$E. Davis$$, 'E.', $$Davis$$, NULL, NULL, 'initial', $$Thomas E. Davis$$),
  ('39f08a9e-bfc7-4c97-bdb6-6cc8599b683f'::uuid, $$J. Smith$$, 'J.', $$Smith$$, NULL, NULL, 'initial', $$Thomas J. Smith$$),
  ('e6dec5d3-f972-4902-8a29-dfc55f67244a'::uuid, $$J. Prieto$$, 'J.', $$Prieto$$, NULL, NULL, 'initial', $$Tony J. Prieto$$),
  ('5f1fb7ae-0287-4246-8d1c-d9caa23101fa'::uuid, $$A. Hales$$, 'A.', $$Hales$$, NULL, NULL, 'initial', $$Brett A. Hales$$),
  ('05624287-c90f-40be-bada-12a883040d60'::uuid, $$A. Hyer$$, 'A.', $$Hyer$$, NULL, NULL, 'initial', $$Richard A. Hyer$$),
  ('0f50e11e-d9e8-4bf0-954b-171f51ce3a0a'::uuid, $$M. Olson$$, 'M.', $$Olson$$, NULL, NULL, 'initial', $$Daniel M. Olson$$),
  ('48539bb2-f0bf-418d-97a6-df24f0d29507'::uuid, $$J. Shelton$$, 'J.', $$Shelton$$, NULL, NULL, 'initial', $$Donald J. Shelton$$),
  ('123eed02-02b2-406f-9697-8243715868b9'::uuid, $$T. McGuire$$, 'T.', $$McGuire$$, NULL, NULL, 'initial', $$Jason T. McGuire$$),
  ('8ebf87a6-789d-4e85-94b8-a000ad239963'::uuid, $$L. Johnson$$, 'L.', $$Johnson$$, NULL, NULL, 'initial', $$Kathie L. Johnson$$),
  ('d3aceb03-621e-44dd-9bb7-2091b18ab234'::uuid, $$R. Ramsey$$, 'R.', $$Ramsey$$, NULL, NULL, 'initial', $$Dawn R. Ramsey$$),
  ('fe8f7910-872f-4ff6-ba5d-8ccfb332294d'::uuid, $$S. Overson$$, 'S.', $$Overson$$, NULL, NULL, 'initial', $$Kristie S. Overson$$),
  ('9651210a-f006-4d74-ae2e-88eb682e8199'::uuid, $$J. Behm$$, 'J.', $$Behm$$, NULL, NULL, 'initial', $$Bryson J. Behm$$),
  ('3d02b6e5-29d1-4580-8e0a-4deeefca42f2'::uuid, $$L. Erickson$$, 'L.', $$Erickson$$, NULL, NULL, 'initial', $$David L. Erickson$$),
  ('179d492c-c0d5-44f8-8e86-e29da12106b2'::uuid, $$A. Beus$$, 'A.', $$Beus$$, NULL, NULL, 'initial', $$Kathryn A. Beus$$),
  ('a803ee67-702c-40a3-80a7-cab0cb163c46'::uuid, $$P. Gunnell$$, 'P.', $$Gunnell$$, NULL, NULL, 'initial', $$Nolan P. Gunnell$$),
  ('20cee08f-983b-4a24-aff5-ea513f4a7d55'::uuid, $$V. Sparks$$, 'V.', $$Sparks$$, NULL, NULL, 'initial', $$Kelly V. Sparks$$),
  ('8328c9ef-c1ac-4e35-9d0b-e40a84fc50b8'::uuid, $$B. Elliott$$, 'B.', $$Elliott$$, NULL, NULL, 'initial', $$Max B. Elliott$$),
  ('52ac97ce-e347-4d23-a81b-2b513e767b83'::uuid, $$E. Dotson$$, 'E.', $$Dotson$$, NULL, NULL, 'initial', $$Chad E. Dotson$$),
  ('d7169049-314d-4545-ad82-e7d2817bbab2'::uuid, $$A. Moreno$$, 'A.', $$Moreno$$, NULL, NULL, 'initial', $$Carlos A. Moreno$$),
  ('2a7076d5-734b-469c-be4a-ec3500d36fd5'::uuid, $$R. Wolbach$$, 'R.', $$Wolbach$$, NULL, NULL, 'initial', $$Gregory R. Wolbach$$),
  ('a783fdf5-e063-4377-96b7-e5ed40473a1f'::uuid, $$H. McCoy$$, 'H.', $$McCoy$$, NULL, NULL, 'initial', $$Alison H. McCoy$$),
  ('676158ff-ebd2-4713-ae9b-4e29163860c8'::uuid, $$J. Jensen$$, 'J.', $$Jensen$$, NULL, NULL, 'initial', $$Michael J. Jensen$$),
  ('09243212-2596-4c11-b495-383f9f0371b9'::uuid, $$J. Wimmer$$, 'J.', $$Wimmer$$, NULL, NULL, 'initial', $$Paul J. Wimmer$$),
  ('1ec4f7c5-e01d-490d-8d1e-0e30607a553a'::uuid, $$R. Davidson$$, 'R.', $$Davidson$$, NULL, NULL, 'initial', $$Aaron R. Davidson$$),
  ('6b16270a-c6c7-46be-9b9c-7def323dc4ef'::uuid, $$S. Gray$$, 'S.', $$Gray$$, NULL, NULL, 'initial', $$Jeffrey S. Gray$$),
  ('c9fd2316-e3b5-461d-b065-9f42f8298352'::uuid, $$W. Mann$$, 'W.', $$Mann$$, NULL, NULL, 'initial', $$Rodney W. Mann$$),
  ('6fafb9d5-e223-4c49-b02b-de565c6c547f'::uuid, $$F. Allred$$, 'F.', $$Allred$$, NULL, NULL, 'initial', $$Christopher F. Allred$$),
  ('855978c9-8966-4075-9570-39c34567c34a'::uuid, $$H. Harvey$$, 'H.', $$Harvey$$, NULL, NULL, 'initial', $$James H. Harvey$$),
  ('6ec1d0b8-5546-46ef-bd21-353a4c1a9315'::uuid, $$S. Wilson$$, 'S.', $$Wilson$$, NULL, NULL, 'initial', $$Ada S. Wilson$$),
  ('62620530-a12a-4298-8f3f-7e8f6b26258d'::uuid, $$B. Peterson$$, 'B.', $$Peterson$$, NULL, NULL, 'initial', $$Emily B. Peterson$$),
  ('62d7ed8f-56d4-445b-a866-f334a65e8394'::uuid, $$L. Beeson$$, 'L.', $$Beeson$$, NULL, NULL, 'initial', $$Sarah L. Beeson$$),
  ('cbea551f-160d-4ffe-866d-0a6aa8e4d26b'::uuid, $$M. Bateman$$, 'M.', $$Bateman$$, NULL, NULL, 'initial', $$Stacy M. Bateman$$),
  ('bd7217eb-ceab-4ec0-9a00-4069784a3558'::uuid, $$H. Lewis$$, 'H.', $$Lewis$$, NULL, NULL, 'initial', $$Jackson H. Lewis$$),
  ('2b00ec04-b748-40b6-8af4-52adbd72dedb'::uuid, $$F. Stevens$$, 'F.', $$Stevens$$, NULL, NULL, 'initial', $$Joani F. Stevens$$),
  ('96b97af6-475f-46dd-9c06-9e1a9fca0572'::uuid, $$W. Barnett$$, 'W.', $$Barnett$$, NULL, NULL, 'initial', $$Brian W. Barnett$$),
  ('d767b60e-f6e0-404f-8664-ffda3b393455'::uuid, $$C. "Jim" McDermott$$, 'C.', $$McDermott$$, NULL, 'Jim', 'nickname', $$James C. "Jim" McDermott$$),
  ('61bd888b-a452-48b1-8b94-75dd4580c031'::uuid, $$R. Ambrose II$$, 'R.', $$Ambrose$$, 'II', NULL, 'suffix', $$David R. Ambrose II$$),
  ('3ca720cb-e2bc-43e0-88c1-e1d7f387df3a'::uuid, $$S. Kerr, Jr.$$, 'S.', $$Kerr$$, 'Jr.', NULL, 'suffix', $$David S. Kerr, Jr.$$),
  ('167df0f4-63c8-4572-a762-9c6f08d67396'::uuid, $$J. Ward, III$$, 'J.', $$Ward$$, 'III', NULL, 'suffix', $$Henry J. Ward, III$$),
  ('86606bc2-a488-4957-a1da-97593aad6cdf'::uuid, $$A. Beccia III$$, 'A.', $$Beccia$$, 'III', NULL, 'suffix', $$John A. Beccia III$$),
  ('2652175a-efa0-45c4-b7e6-d88da20f43a8'::uuid, $$E. Foddrill Sr.$$, 'E.', $$Foddrill$$, 'Sr.', NULL, 'suffix', $$John E. Foddrill Sr.$$);

-- Held: cal_access_discovery committee-name rows, not people. Not touched.
CREATE TEMP TABLE _held (id uuid PRIMARY KEY, last_name text) ON COMMIT DROP;
INSERT INTO _held VALUES
  ('10d88bbd-da6b-402b-8c01-4369780c29c5'::uuid, $$C. FALLS, JUDGE BERNIE C. LAFORTEZA, JUDGE PAUL BACIGALUPO, JUDGE MICHAEL J. CONVEY, JUDGE TIMOTHY P. DILLON & JUDGE ALISON MACKENZIE; LA RECALLS COMMITTEE IN SUPPORT OF RECALLING JUDGE THOMAS$$),
  ('5897719e-3cfd-4bdc-80c9-8eeee87cd706'::uuid, $$C. VILL CAMP$$),
  ('5f261af4-22e4-48a0-9964-320b60290e07'::uuid, $$C. FALLS, JUDGE BERNIE C. LAFORTEZA, JUDGE PAUL BACIGALUPO, JUDGE MICHAEL J. CONVEY, JUDGE TIMOTHY P. DILLON & JUDGE ALISON MACKENZIE; LA RECALLS COMMITTEE IN SUPPORT OF RECALLING JUDGE THOMAS$$),
  ('5f9d2b81-6661-468a-9c3a-07513e98c4a6'::uuid, $$C. S. U. L. B. NO ON 9 COALITION$$),
  ('79fe9e87-ca3f-4b3d-94ef-7b11a17c80f7'::uuid, $$J. MAC FOR ANAHEIM$$),
  ('ed0711dc-5155-4447-ad62-c56e10c640f6'::uuid, $$L. KEMP FOR MONTECITO FIRE BOARD 2020; ROBERT$$),
  ('fd48a16e-d579-47c4-873f-d2ea98e226c9'::uuid, $$M. LUNA SCHOOLBOARD$$);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _r;
  IF v_n <> 82 THEN RAISE EXCEPTION 'PRE: % rows listed, expected 82', v_n; END IF;
  SELECT count(*) INTO v_n FROM _r WHERE kind = 'initial';
  IF v_n <> 76 THEN RAISE EXCEPTION 'PRE: % initial rows, expected 76', v_n; END IF;
  SELECT count(*) INTO v_n FROM _held;
  IF v_n <> 7 THEN RAISE EXCEPTION 'PRE: % held rows, expected 7', v_n; END IF;

  -- every listed row is still as measured (or already in its target state from a previous run of this file),
  -- and full_name still says what it said
  SELECT count(*) INTO v_n FROM _r JOIN essentials.politicians p ON p.id = _r.id AND p.full_name = _r.full_name
   WHERE (p.last_name = _r.old_last AND COALESCE(p.middle_initial, '') = ''
          AND COALESCE(p.name_suffix, '') = '' AND COALESCE(p.preferred_name, '') = '')
      OR (p.last_name = _r.new_last AND p.middle_initial = _r.mi
          AND p.name_suffix IS NOT DISTINCT FROM COALESCE(_r.suffix, p.name_suffix)
          AND p.preferred_name IS NOT DISTINCT FROM COALESCE(_r.preferred, p.preferred_name));
  IF v_n <> 82 THEN RAISE EXCEPTION 'PRE: % of 82 rows in their measured or target state', v_n; END IF;

  -- the list is the whole population: nothing matches the shape outside _r and _held
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.last_name ~ '^[A-Z]\. ' AND p.id NOT IN (SELECT id FROM _r) AND p.id NOT IN (SELECT id FROM _held);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows match ^[A-Z]\. outside the listed and held sets -- re-measure', v_n; END IF;

  -- the targets are sane: a one-letter initial with a period, a surname with no leading initial left in it
  SELECT count(*) INTO v_n FROM _r WHERE mi !~ '^[A-Z]\.$' OR new_last ~ '^[A-Z]\. ' OR new_last !~ '^\S+$'
     OR left(old_last, 3) <> mi || ' ';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows with a malformed target', v_n; END IF;
END $$;

-- ─── Move the initial (and the suffix / nickname where listed) ───────────────────────────────────
UPDATE essentials.politicians p
   SET last_name      = _r.new_last,
       middle_initial = _r.mi,
       name_suffix    = COALESCE(_r.suffix, p.name_suffix),
       preferred_name = COALESCE(_r.preferred, p.preferred_name)
  FROM _r
 WHERE p.id = _r.id
   AND p.last_name = _r.old_last
   AND COALESCE(p.middle_initial, '') = '';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _r JOIN essentials.politicians p ON p.id = _r.id
   WHERE p.last_name = _r.new_last AND p.middle_initial = _r.mi AND p.full_name = _r.full_name
     AND (_r.suffix IS NULL OR p.name_suffix = _r.suffix)
     AND (_r.preferred IS NULL OR p.preferred_name = _r.preferred);
  IF v_n <> 82 THEN RAISE EXCEPTION 'POST: % of 82 rows in their target state', v_n; END IF;

  -- no ACTIVE row carries the shape, except the held set (which is all inactive today)
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.is_active AND p.last_name ~ '^[A-Z]\. ' AND p.id NOT IN (SELECT id FROM _held);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % active rows still match ^[A-Z]\. outside the held set', v_n; END IF;
  -- and no row at all outside the held set
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.last_name ~ '^[A-Z]\. ' AND p.id NOT IN (SELECT id FROM _held);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows still match ^[A-Z]\. outside the held set', v_n; END IF;

  -- the held rows are untouched
  SELECT count(*) INTO v_n FROM _held JOIN essentials.politicians p ON p.id = _held.id
   WHERE p.last_name = _held.last_name AND COALESCE(p.middle_initial, '') = '';
  IF v_n <> 7 THEN RAISE EXCEPTION 'POST: % of 7 held rows untouched', v_n; END IF;

  RAISE NOTICE 'CA_0267 applied: 82 leading middle initials moved out of last_name; 7 committee-name rows held';
END $$;

COMMIT;
