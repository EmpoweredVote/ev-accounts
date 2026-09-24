-- CA_0274_race_candidates_last_name_bare_surname.sql
-- Drop a leading middle initial from essentials.race_candidates.last_name ("Justin J. Pearson": last_name 'J. Pearson').
--
-- WHY: race_candidates keeps its own first_name / last_name copy, and CA_0267 (PR #764) fixed only the politicians
-- copy. Surname matchers read this column too -- the roster migrations dedup a certified name against the race's
-- existing rows on rc.last_name (CA_0269: "rc.last_name = x.last_name"; CA_0253 / CA_0254 do the same on the
-- politicians side), scripts/link-monroe-candidates-to-politicians.sql joins rc.last_name to p.last_name, and CompassV2
-- sorts the candidate list (GET /compass/politicians?include_candidates=true -> compassService.getCandidates) on
-- last_name. With 'J. Pearson' in the column, none of them sees "Pearson", and a certified-roster pass can seed him twice.
--
-- MEASURED 2026-09-24: 110 rows match last_name ~ '^[A-Z]\. ', all candidate_status 'active', all with first_name set,
-- and full_name = first_name || ' ' || last_name on every one. 109 are linked to a politician.
--    94  linked, and the politician's last_name already equals the text after the initial (CA_0267 fixed that copy).
--    15  linked, the politician's last_name is the bare surname, but this copy also carries a suffix or a nickname:
--         6 CA_0267 suffix / nickname rows (Beccia III, Foddrill Sr., Ward III, Ambrose II, Kerr Jr., "Jim" McDermott)
--         9 seated House members seeded with a bare surname and no middle_initial (Bishop Jr., Bresnahan Jr.,
--           Conaway Jr., Kean Jr., Onder Jr., Timmons IV; "Rick" Crawford, "Hank" Johnson Jr., "Chuck" Fleischmann)
--     1  unlinked: John A. Mirisch (source discovery_cron, 2026-05-10 02:00Z). discoveryService.ts split at the first
--        space until bceee96f (2026-05-09 22:24 PDT, deployed after this row); it takes the last token now.
--   The other writers were one-shot: the 2026 U.S. House seed migrations (generators scripts/15x-16x-*-generate.mts,
--   whose nameParts() split at the first space). No live writer produces this shape today -- see the PR.
--
-- WHAT (110 rows, per id, each target written out below): last_name := the bare surname, which is
-- splitPersonName(full_name).last (scripts/lib/split-person-name.ts) and, for all 109 linked rows, the linked
-- politician's last_name.
--    95 'initial'   'J. Pearson'             -> 'Pearson'
--    11 'suffix'    'D. Bishop, Jr.'         -> 'Bishop'      (II, III, IV, Jr., Sr.)
--     4 'nickname'  'A. "Rick" Crawford'     -> 'Crawford'    (one, Hank Johnson, also carries Jr.)
--   The initial, suffix and nickname are DROPPED from this copy, not moved: race_candidates has no middle_initial,
--   name_suffix or preferred_name column, and full_name keeps all three. That is the corpus convention for this table:
--   of the 380 other rows whose full_name reads "First X. Last", 359 already store the initial nowhere but full_name;
--   28 of 46 suffix rows and 34 of 41 nickname rows drop them from last_name the same way.
--   full_name is NOT changed. first_name is NOT changed. politician_id is NOT changed. No INSERT, no DELETE.
--   The race_candidate_mirror_data trigger fires only on politician_id / photo_url / website_url, so it does not run.
--
-- HELD (1 row, not touched): 505e28df 'J Bowman' (Jay J Bowman, KY). The same shape without the period; the linked
--   politician b1baf884 carries it too ('J Bowman'), as does one other active politician (Bob J Stevenson). Fix both
--   tables together in a follow-up, so the two copies do not disagree. The gate below checks the wider shape
--   ^[A-Z]\.? and lists this row.
--
-- EFFECT ON READERS (all read-only; none needs a code change):
--   electionService RACE_SELECT / getCandidateById -> essentials ElectionsView renders full_name (unchanged), and
--   orders candidates by a seeded shuffle, not by name. CandidateProfile renders full_name first; first + last only if
--   full_name were empty. compassService.getCandidates -> CompassV2: getPolName() renders full_name (unchanged);
--   useFilteredPoliticians' last-name tiebreak now files "Pearson" under P, not J; CombinedPage's compare label
--   (first + last) reads "Justin Pearson". candidate_name_key(full_name) -- the (race_id, name) unique index -- reads
--   full_name only, so it does not change.
--
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews, who ran it). Dry run (BEGIN ... ROLLBACK)
--   twice before, revert confirmed each time; a control with one row forced wrong made the gate raise. Apply:
--   UPDATE 110, gate passed, COMMIT. Verified after: 1 row matches ^[A-Z]\.? (the held J Bowman); 0 listed linked rows
--   disagree with the politician's last_name.
-- ROLLBACK: for each id in _r, set last_name := old_last.
-- IDEMPOTENT: the UPDATE is guarded on last_name = old_last AND full_name = full_name as measured; a re-run changes
--   nothing and the gate still passes.

BEGIN;

CREATE TEMP TABLE _r (id uuid PRIMARY KEY, old_last text, new_last text, kind text, linked boolean,
                      first_name text, full_name text) ON COMMIT DROP;
INSERT INTO _r VALUES
  ('b1fc7c56-3d8c-4d4c-abe3-69153f662c10'::uuid, $$A. McKenzie$$, $$McKenzie$$, 'initial', true, $$Abena$$, $$Abena A. McKenzie$$),
  ('f996989c-a01e-4a2d-bd77-1f3dda1cb5fe'::uuid, $$J. Hamadeh$$, $$Hamadeh$$, 'initial', true, $$Abraham$$, $$Abraham J. Hamadeh$$),
  ('481c27a8-a4ae-4fbf-b2be-a2fa852b1b4e'::uuid, $$D. Austill$$, $$Austill$$, 'initial', true, $$Adam$$, $$Adam D. Austill$$),
  ('0aff4c63-5e1a-49c7-b478-e6e447d5000f'::uuid, $$P. McDowell$$, $$McDowell$$, 'initial', true, $$Addison$$, $$Addison P. McDowell$$),
  ('87c7fc49-b43b-4b3f-bc3d-ede77cb5cfbf'::uuid, $$S. Grijalva$$, $$Grijalva$$, 'initial', true, $$Adelita$$, $$Adelita S. Grijalva$$),
  ('47663992-4712-4634-b21c-9916d4b08251'::uuid, $$S. Adams$$, $$Adams$$, 'initial', true, $$Alma$$, $$Alma S. Adams$$),
  ('f9074a16-0c11-4add-b2ee-216b8b576189'::uuid, $$J. Koontz$$, $$Koontz$$, 'initial', true, $$Andrew$$, $$Andrew J. Koontz$$),
  ('e5df5e51-9ac7-43d5-9397-df2c90845453'::uuid, $$R. Garbarino$$, $$Garbarino$$, 'initial', true, $$Andrew$$, $$Andrew R. Garbarino$$),
  ('5030c691-fcc9-4b85-be40-6fa30202f4ad'::uuid, $$S. Clyde$$, $$Clyde$$, 'initial', true, $$Andrew$$, $$Andrew S. Clyde$$),
  ('be81329a-6a1b-4346-b908-1401c73efbdc'::uuid, $$R. Mavalwalla$$, $$Mavalwalla$$, 'initial', true, $$Bajun$$, $$Bajun R. Mavalwalla$$),
  ('52a2a073-0fab-4ad2-ab8c-5c67486b2b7e'::uuid, $$G. Thompson$$, $$Thompson$$, 'initial', true, $$Bennie$$, $$Bennie G. Thompson$$),
  ('301eebdf-23a5-410a-b268-48d946ab1bbd'::uuid, $$A. Knox$$, $$Knox$$, 'initial', true, $$Berton$$, $$Berton A. Knox$$),
  ('029dbb34-6be9-42f0-8944-c5bab7d864a1'::uuid, $$F. Boyle$$, $$Boyle$$, 'initial', true, $$Brendan$$, $$Brendan F. Boyle$$),
  ('1efb0e8a-c8d8-4ccd-b4d7-d2c30e2789dc'::uuid, $$K. Fitzpatrick$$, $$Fitzpatrick$$, 'initial', true, $$Brian$$, $$Brian K. Fitzpatrick$$),
  ('95d944e9-2292-43ee-ac34-69bf40ee0f53'::uuid, $$P. O'Gorman$$, $$O'Gorman$$, 'initial', true, $$Brian$$, $$Brian P. O'Gorman$$),
  ('1428f652-3d3e-4152-812f-1a28809638e5'::uuid, $$H. Nolen$$, $$Nolen$$, 'initial', true, $$Byron$$, $$Byron H. Nolen$$),
  ('c46c5d69-e191-411e-a1a3-c8904aca64b8'::uuid, $$E. Henderson$$, $$Henderson$$, 'initial', true, $$Carl$$, $$Carl E. Henderson$$),
  ('61e76b24-801e-4a32-b68a-a74eaec0f7e5'::uuid, $$E. Bowen$$, $$Bowen$$, 'initial', true, $$Carlton$$, $$Carlton E. Bowen$$),
  ('57b421f4-7209-4b8d-8d4d-368e21b905de'::uuid, $$D. Miller$$, $$Miller$$, 'initial', true, $$Carol$$, $$Carol D. Miller$$),
  ('162e9ada-b7c4-4dcb-9cf4-910cb07f1b2d'::uuid, $$J. "Chuck" Fleischmann$$, $$Fleischmann$$, 'nickname', true, $$Charles$$, $$Charles J. "Chuck" Fleischmann$$),
  ('386a2238-8798-416f-945d-0eb5e65a36fe'::uuid, $$D. Chung$$, $$Chung$$, 'initial', true, $$Chris$$, $$Chris D. Chung$$),
  ('63e832df-348e-4891-97d5-faf4ede64ab0'::uuid, $$B. Monday$$, $$Monday$$, 'initial', true, $$Christopher$$, $$Christopher B. Monday$$),
  ('feb17bcd-4b7a-4b65-91ac-661c6bcdfc32'::uuid, $$H. Smith$$, $$Smith$$, 'initial', true, $$Christopher$$, $$Christopher H. Smith$$),
  ('198c5cce-0f22-4c7f-b29d-ef983e301c5b'::uuid, $$R. Deluzio$$, $$Deluzio$$, 'initial', true, $$Christopher$$, $$Christopher R. Deluzio$$),
  ('ba5402a4-ed44-43bc-a4f9-c56ea2fe6439'::uuid, $$J. Oshel$$, $$Oshel$$, 'initial', true, $$Cody$$, $$Cody J. Oshel$$),
  ('6580a912-2089-445d-9945-04a64aa0f8bc'::uuid, $$J. Taylor$$, $$Taylor$$, 'initial', true, $$David$$, $$David J. Taylor$$),
  ('cda6b6cd-92f6-4685-9150-64784eb588a3'::uuid, $$P. Joyce$$, $$Joyce$$, 'initial', true, $$David$$, $$David P. Joyce$$),
  ('1c88b017-a03e-4918-aec5-7f10ce3f810a'::uuid, $$R. Ambrose II$$, $$Ambrose$$, 'suffix', true, $$David$$, $$David R. Ambrose II$$),
  ('690d3476-11a2-40bb-8ae3-e7a9578ddd2f'::uuid, $$S. Kerr, Jr.$$, $$Kerr$$, 'suffix', true, $$David$$, $$David S. Kerr, Jr.$$),
  ('8cd4e4b5-5d65-4786-89c7-fb8010c10a62'::uuid, $$W. Blomstrom$$, $$Blomstrom$$, 'initial', true, $$David$$, $$David W. Blomstrom$$),
  ('3d1550ba-e7e4-4acc-a513-4de0fd2ad452'::uuid, $$K. Ross$$, $$Ross$$, 'initial', true, $$Deborah$$, $$Deborah K. Ross$$),
  ('613f4f59-ac9c-4714-809b-f92252b53163'::uuid, $$C. Ramirez$$, $$Ramirez$$, 'initial', true, $$Delia$$, $$Delia C. Ramirez$$),
  ('58136f99-7ef9-404a-b91a-4101404ba3b4'::uuid, $$R. Hill$$, $$Hill$$, 'initial', true, $$DeVante$$, $$DeVante R. Hill$$),
  ('4aa10c13-4a7f-43bd-93e5-2fe53bfecc07'::uuid, $$L. Jackson$$, $$Jackson$$, 'initial', true, $$DeVelle$$, $$DeVelle L. Jackson$$),
  ('617b0efa-f9d7-4ea0-af43-bef7c1884f24'::uuid, $$G. Davis$$, $$Davis$$, 'initial', true, $$Donald$$, $$Donald G. Davis$$),
  ('ff7ad38a-f749-44ab-949c-15f50c5bb599'::uuid, $$C. Chico$$, $$Chico$$, 'initial', true, $$Douglas$$, $$Douglas C. Chico$$),
  ('b3cfa12f-0e81-4c70-9cbc-4fd6cd4bc879'::uuid, $$H. Feller$$, $$Feller$$, 'initial', true, $$Edwin$$, $$Edwin H. Feller$$),
  ('8e1aea9e-9ce0-4f51-b05f-fed5c3959d7a'::uuid, $$A. "Rick" Crawford$$, $$Crawford$$, 'nickname', true, $$Eric$$, $$Eric A. "Rick" Crawford$$),
  ('f93568a1-0cdf-441d-b430-fc3a0516db4f'::uuid, $$D. Lucas$$, $$Lucas$$, 'initial', true, $$Frank$$, $$Frank D. Lucas$$),
  ('0bbd9ffd-d2e0-4bfa-b2f9-9ee6589697a5'::uuid, $$J. Grossi$$, $$Grossi$$, 'initial', true, $$Gary$$, $$Gary J. Grossi$$),
  ('17912055-5354-452b-92ff-b00a87da63f5'::uuid, $$A. Goetzman$$, $$Goetzman$$, 'initial', true, $$Gregory$$, $$Gregory A. Goetzman$$),
  ('cfa6c596-4d43-4fcf-b0a1-50a96fb925cf'::uuid, $$F. Murphy$$, $$Murphy$$, 'initial', true, $$Gregory$$, $$Gregory F. Murphy$$),
  ('ae1cb92d-753e-4b53-aee1-26f26fa41d14'::uuid, $$W. Meeks$$, $$Meeks$$, 'initial', true, $$Gregory$$, $$Gregory W. Meeks$$),
  ('0542a00c-ac3c-4477-8e12-e8e5425a54f0'::uuid, $$S. Jeffries$$, $$Jeffries$$, 'initial', true, $$Hakeem$$, $$Hakeem S. Jeffries$$),
  ('eedf86c7-9c9d-4938-8cea-fca6807a84c8'::uuid, $$C. "Hank" Johnson, Jr.$$, $$Johnson$$, 'nickname', true, $$Henry$$, $$Henry C. "Hank" Johnson, Jr.$$),
  ('b8902bee-0772-494e-9756-e4aefcbbe88f'::uuid, $$J. Ward, III$$, $$Ward$$, 'suffix', true, $$Henry$$, $$Henry J. Ward, III$$),
  ('9ad0ac2c-84d7-4ffd-bbff-8fc7fae5f8c1'::uuid, $$C. Conaway, Jr.$$, $$Conaway$$, 'suffix', true, $$Herbert$$, $$Herbert C. Conaway, Jr.$$),
  ('144689c1-b0c5-4140-94e4-c899780cb23a'::uuid, $$H. Garcia$$, $$Garcia$$, 'initial', true, $$Hernan$$, $$Hernan H. Garcia$$),
  ('441f4b68-b4f2-4a2c-9e3e-6930f469475d'::uuid, $$J. Scholten$$, $$Scholten$$, 'initial', true, $$Hillary$$, $$Hillary J. Scholten$$),
  ('6f017a10-98e4-47c0-a23f-35eca564be75'::uuid, $$A. Himes$$, $$Himes$$, 'initial', true, $$James$$, $$James A. Himes$$),
  ('663331f9-61ad-4724-bc91-50c4a6f71b26'::uuid, $$A. Johnson$$, $$Johnson$$, 'initial', true, $$James$$, $$James A. Johnson$$),
  ('c6e718bb-241c-4645-8ac1-1fcfec2f5f59'::uuid, $$C. "Jim" McDermott$$, $$McDermott$$, 'nickname', true, $$James$$, $$James C. "Jim" McDermott$$),
  ('f1e7aaf6-c404-4ce7-b3fa-f83d8b06f315'::uuid, $$D. Hooper$$, $$Hooper$$, 'initial', true, $$James$$, $$James D. Hooper$$),
  ('77c015ef-ff0e-417f-8a10-3f1e6d2ce583'::uuid, $$E. Clyburn$$, $$Clyburn$$, 'initial', true, $$James$$, $$James E. Clyburn$$),
  ('8c4289e2-81d5-465d-9bcb-36dc6d63fcfb'::uuid, $$N. Tokuda$$, $$Tokuda$$, 'initial', true, $$Jill$$, $$Jill N. Tokuda$$),
  ('a0af900d-5e77-49c6-b134-de887852799f'::uuid, $$A. Beccia III$$, $$Beccia$$, 'suffix', true, $$John$$, $$John A. Beccia III$$),
  ('b3b88e1c-340c-48ea-bd71-3cda9a391740'::uuid, $$A. Mirisch$$, $$Mirisch$$, 'initial', false, $$John$$, $$John A. Mirisch$$),
  ('533aaff9-78c4-4b70-9b2a-b042c4904649'::uuid, $$B. Larson$$, $$Larson$$, 'initial', true, $$John$$, $$John B. Larson$$),
  ('50f96010-94a8-43c6-ac8a-fa688fc9fe7c'::uuid, $$B. Williams$$, $$Williams$$, 'initial', true, $$John$$, $$John B. Williams$$),
  ('969f5c91-c9a3-43a7-b649-dd4714737c66'::uuid, $$C. Hughs$$, $$Hughs$$, 'initial', true, $$John$$, $$John C. Hughs$$),
  ('3371e8a8-4d4a-4226-8729-b4015656779b'::uuid, $$E. Foddrill Sr.$$, $$Foddrill$$, 'suffix', true, $$John$$, $$John E. Foddrill Sr.$$),
  ('b13ea454-fdb7-46c2-93fd-581a8fb54b47'::uuid, $$P. Roco$$, $$Roco$$, 'initial', true, $$John$$, $$John P. Roco$$),
  ('7bbaf355-4466-42d0-b9b8-8da80dee904b'::uuid, $$R. Moolenaar$$, $$Moolenaar$$, 'initial', true, $$John$$, $$John R. Moolenaar$$),
  ('f56dc4ce-c96d-4c16-814a-7573df486b34'::uuid, $$W. Mannion$$, $$Mannion$$, 'initial', true, $$John$$, $$John W. Mannion$$),
  ('a116bab5-db84-4b1c-85b6-6d7bdc9f988b'::uuid, $$M. Williams$$, $$Williams$$, 'initial', true, $$Jomo$$, $$Jomo M. Williams$$),
  ('3ad782d3-4c80-4b90-b1a7-54c0fe798fa6'::uuid, $$L. Jackson$$, $$Jackson$$, 'initial', true, $$Jonathan$$, $$Jonathan L. Jackson$$),
  ('6095fb1b-307d-4674-8267-a13cfd1df2b3'::uuid, $$D. Hinders$$, $$Hinders$$, 'initial', true, $$Jordan$$, $$Jordan D. Hinders$$),
  ('e4f7e55e-5bef-4a19-a90a-bb05d1ab4c47'::uuid, $$D. Morelle$$, $$Morelle$$, 'initial', true, $$Joseph$$, $$Joseph D. Morelle$$),
  ('55f5e4a9-8f04-41f6-92e9-5af22abca6b2'::uuid, $$E. Neal$$, $$Neal$$, 'initial', true, $$Joyce$$, $$Joyce E. Neal$$),
  ('5273ca75-fe58-48d4-b6a4-55d1d4f3663c'::uuid, $$J. Pearson$$, $$Pearson$$, 'initial', true, $$Justin$$, $$Justin J. Pearson$$),
  ('dac08768-41c8-417c-b5cb-b06ce5ea138e'::uuid, $$B. Goodenough$$, $$Goodenough$$, 'initial', true, $$Keith$$, $$Keith B. Goodenough$$),
  ('8fd19d08-d687-4f5f-b7bc-7600fafa0d60'::uuid, $$T. Reeves$$, $$Reeves$$, 'initial', true, $$Latonya$$, $$Latonya T. Reeves$$),
  ('8eeb769b-17f6-4fe2-bff2-0f0f523c2e21'::uuid, $$C. McClain$$, $$McClain$$, 'initial', true, $$Lisa$$, $$Lisa C. McClain$$),
  ('76a7334b-53d6-477d-86f8-25110dfb4a8c'::uuid, $$D. Bivings$$, $$Bivings$$, 'initial', true, $$Martell$$, $$Martell D. Bivings$$),
  ('7378ca3c-8010-4d75-92bc-6c34b01b29ab'::uuid, $$E. Miller$$, $$Miller$$, 'initial', true, $$Mary$$, $$Mary E. Miller$$),
  ('13bdc18a-3447-49b1-a348-2e39728b8677'::uuid, $$D. Klein$$, $$Klein$$, 'initial', true, $$Matthew$$, $$Matthew D. Klein$$),
  ('92f64364-8540-4348-8536-969df4f1c176'::uuid, $$L. Miller$$, $$Miller$$, 'initial', true, $$Max$$, $$Max L. Miller$$),
  ('b7b147d9-39d5-43a9-b173-22fd2ce317cd'::uuid, $$A. Salazar$$, $$Salazar$$, 'initial', true, $$Melanie$$, $$Melanie A. Salazar$$),
  ('5bbafc33-968f-4ee4-8273-c8f87af6520c'::uuid, $$A. Stansbury$$, $$Stansbury$$, 'initial', true, $$Melanie$$, $$Melanie A. Stansbury$$),
  ('de23b3cd-8c16-4d1d-9ff0-1b03a818ab71'::uuid, $$A. Rulli$$, $$Rulli$$, 'initial', true, $$Michael$$, $$Michael A. Rulli$$),
  ('5d180a96-5a8c-46d0-9c2d-81a6f83d8e83'::uuid, $$K. Simpson$$, $$Simpson$$, 'initial', true, $$Michael$$, $$Michael K. Simpson$$),
  ('bcb2fc87-0f7c-47ae-b9c4-224f68274a0e'::uuid, $$R. Stoddard$$, $$Stoddard$$, 'initial', true, $$Michael$$, $$Michael R. Stoddard$$),
  ('201b4162-799a-41b8-b959-ef9708f91b55'::uuid, $$R. Turner$$, $$Turner$$, 'initial', true, $$Michael$$, $$Michael R. Turner$$),
  ('752c452c-53c7-48eb-a58b-4dbdea861c13'::uuid, $$A. Langworthy$$, $$Langworthy$$, 'initial', true, $$Nicholas$$, $$Nicholas A. Langworthy$$),
  ('c7a69ad4-2349-40d1-b478-5e9f634bffe7'::uuid, $$R. Morlan$$, $$Morlan$$, 'initial', true, $$Oliver$$, $$Oliver R. Morlan$$),
  ('44fb6bc9-ddf9-4fe2-834d-0694c5b449b4'::uuid, $$A. Gosar$$, $$Gosar$$, 'initial', true, $$Paul$$, $$Paul A. Gosar$$),
  ('6922fcca-65d6-47aa-9ab4-879d3001fbd8'::uuid, $$G. Baker$$, $$Baker$$, 'initial', true, $$Richard$$, $$Richard G. Baker$$),
  ('ef952bf3-4047-4470-9608-9d1460e728c1'::uuid, $$W. Allen$$, $$Allen$$, 'initial', true, $$Rick$$, $$Rick W. Allen$$),
  ('4d8674ef-7b42-4788-83cb-a621883ad4d1'::uuid, $$M. Moore$$, $$Moore$$, 'initial', true, $$Riley$$, $$Riley M. Moore$$),
  ('1fbf44bb-d34b-4c7b-a297-e5144e6c6a85'::uuid, $$E. Latta$$, $$Latta$$, 'initial', true, $$Robert$$, $$Robert E. Latta$$),
  ('0a4e2a13-8854-4aa9-9bac-97dec4d93c89'::uuid, $$F. Onder, Jr.$$, $$Onder$$, 'suffix', true, $$Robert$$, $$Robert F. Onder, Jr.$$),
  ('defe8a28-e8ba-4ea2-af8e-abe70395e9cb'::uuid, $$M. Moesinger$$, $$Moesinger$$, 'initial', true, $$Robert$$, $$Robert M. Moesinger$$),
  ('4a8ddecd-6aa2-481c-96d8-f7a2f3793f19'::uuid, $$P. Bresnahan, Jr.$$, $$Bresnahan$$, 'suffix', true, $$Robert$$, $$Robert P. Bresnahan, Jr.$$),
  ('a6e722a3-6e97-4217-beed-f8be54f24727'::uuid, $$P. Henri$$, $$Henri$$, 'initial', true, $$Robert$$, $$Robert P. Henri$$),
  ('cd4e98a2-20de-4a56-a353-9ae492ee6eb2'::uuid, $$L. DeLauro$$, $$DeLauro$$, 'initial', true, $$Rosa$$, $$Rosa L. DeLauro$$),
  ('6be06520-8be0-42d5-a3d8-1c58815d2ada'::uuid, $$D. Bishop, Jr.$$, $$Bishop$$, 'suffix', true, $$Sanford$$, $$Sanford D. Bishop, Jr.$$),
  ('e2efe693-a73f-4d41-964e-06fba9b82ef3'::uuid, $$M. Brown$$, $$Brown$$, 'initial', true, $$Shontel$$, $$Shontel M. Brown$$),
  ('0472a5d7-a98a-42b2-90d2-c98a051e29e5'::uuid, $$I. Bice$$, $$Bice$$, 'initial', true, $$Stephanie$$, $$Stephanie I. Bice$$),
  ('4f9e4cb2-374c-467f-940b-11d6fd3467ce'::uuid, $$L. Lee$$, $$Lee$$, 'initial', true, $$Summer$$, $$Summer L. Lee$$),
  ('c4694185-0fc6-461e-a00e-a3328219efd8'::uuid, $$K. DelBene$$, $$DelBene$$, 'initial', true, $$Suzan$$, $$Suzan K. DelBene$$),
  ('f7e030fa-78d1-4554-9872-65c4cb1e635f'::uuid, $$A. Loecken$$, $$Loecken$$, 'initial', true, $$Thomas$$, $$Thomas A. Loecken$$),
  ('98488d58-1fa8-4b49-b121-631a86fda73f'::uuid, $$E. Davis$$, $$Davis$$, 'initial', true, $$Thomas$$, $$Thomas E. Davis$$),
  ('413a0655-ac51-4117-9223-992f85632b1d'::uuid, $$H. Kean, Jr.$$, $$Kean$$, 'suffix', true, $$Thomas$$, $$Thomas H. Kean, Jr.$$),
  ('9d7d6a57-4664-4396-9f7b-80b790de8c48'::uuid, $$J. Smith$$, $$Smith$$, 'initial', true, $$Thomas$$, $$Thomas J. Smith$$),
  ('36233f7c-05e1-4fc5-b706-604500c09e4b'::uuid, $$R. Suozzi$$, $$Suozzi$$, 'initial', true, $$Thomas$$, $$Thomas R. Suozzi$$),
  ('3ff9e303-88ae-4b46-9535-8b74330891ed'::uuid, $$M. Kennedy$$, $$Kennedy$$, 'initial', true, $$Timothy$$, $$Timothy M. Kennedy$$),
  ('64571ceb-61a7-4bb6-95d9-bc0cf6f937d8'::uuid, $$J. Prieto$$, $$Prieto$$, 'initial', true, $$Tony$$, $$Tony J. Prieto$$),
  ('13df77bc-1085-4900-a4f4-493db117f919'::uuid, $$P. Foushee$$, $$Foushee$$, 'initial', true, $$Valerie$$, $$Valerie P. Foushee$$),
  ('6764fe06-b6e4-47cb-9a27-5fa4426404d2'::uuid, $$R. Timmons IV$$, $$Timmons$$, 'suffix', true, $$William$$, $$William R. Timmons IV$$),
  ('9eb406f5-f758-47a2-ac96-567f14002cd5'::uuid, $$D. Clarke$$, $$Clarke$$, 'initial', true, $$Yvette$$, $$Yvette D. Clarke$$);

-- Held: the no-period variant of the shape; its politician row carries it too. Not touched.
CREATE TEMP TABLE _held (id uuid PRIMARY KEY, last_name text) ON COMMIT DROP;
INSERT INTO _held VALUES
  ('505e28df-2e97-475a-9d0e-2ba52a659db0'::uuid, $$J Bowman$$);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _r;
  IF v_n <> 110 THEN RAISE EXCEPTION 'PRE: % rows listed, expected 110', v_n; END IF;
  SELECT count(*) INTO v_n FROM _r WHERE kind = 'initial';
  IF v_n <> 95 THEN RAISE EXCEPTION 'PRE: % initial rows, expected 95', v_n; END IF;
  SELECT count(*) INTO v_n FROM _r WHERE kind = 'suffix';
  IF v_n <> 11 THEN RAISE EXCEPTION 'PRE: % suffix rows, expected 11', v_n; END IF;
  SELECT count(*) INTO v_n FROM _r WHERE kind = 'nickname';
  IF v_n <> 4 THEN RAISE EXCEPTION 'PRE: % nickname rows, expected 4', v_n; END IF;
  SELECT count(*) INTO v_n FROM _held;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: % held rows, expected 1', v_n; END IF;

  -- every listed row is still as measured (or already in its target state from a previous run of this file),
  -- with first_name and full_name as measured
  SELECT count(*) INTO v_n FROM _r JOIN essentials.race_candidates rc ON rc.id = _r.id
   WHERE rc.full_name = _r.full_name AND rc.first_name = _r.first_name
     AND rc.last_name IN (_r.old_last, _r.new_last)
     AND (rc.politician_id IS NOT NULL) = _r.linked;
  IF v_n <> 110 THEN RAISE EXCEPTION 'PRE: % of 110 rows in their measured or target state', v_n; END IF;

  -- the list is the whole population: nothing matches the shape (period or not) outside _r and _held
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
   WHERE rc.last_name ~ '^[A-Z]\.? ' AND rc.id NOT IN (SELECT id FROM _r) AND rc.id NOT IN (SELECT id FROM _held);
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows match ^[A-Z]\.? outside the listed and held sets -- re-measure', v_n; END IF;

  -- the targets are sane: the old value starts with one initial and a period, the target has no initial left, is one
  -- word, and is a substring of the old value
  SELECT count(*) INTO v_n FROM _r
   WHERE old_last !~ '^[A-Z]\. ' OR new_last ~ '^[A-Z]\.? ' OR new_last !~ '^\S+$'
      OR position(new_last IN old_last) = 0;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % rows with a malformed target', v_n; END IF;

  -- each linked row's target is its politician's surname, so the two copies agree afterwards
  SELECT count(*) INTO v_n FROM _r JOIN essentials.race_candidates rc ON rc.id = _r.id
    JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE p.last_name = _r.new_last;
  IF v_n <> 109 THEN RAISE EXCEPTION 'PRE: % of 109 linked targets equal the politician''s last_name', v_n; END IF;
END $$;

-- ─── Drop the initial (and the suffix / nickname) from last_name ─────────────────────────────────
UPDATE essentials.race_candidates rc
   SET last_name  = _r.new_last,
       updated_at = now()
  FROM _r
 WHERE rc.id = _r.id
   AND rc.last_name = _r.old_last
   AND rc.full_name = _r.full_name;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _r JOIN essentials.race_candidates rc ON rc.id = _r.id
   WHERE rc.last_name = _r.new_last AND rc.first_name = _r.first_name AND rc.full_name = _r.full_name;
  IF v_n <> 110 THEN RAISE EXCEPTION 'POST: % of 110 rows in their target state', v_n; END IF;

  -- no row carries the shape, except the held set
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
   WHERE rc.last_name ~ '^[A-Z]\.? ' AND rc.id NOT IN (SELECT id FROM _held);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % rows still match ^[A-Z]\.? outside the held set', v_n; END IF;

  -- the held row is untouched
  SELECT count(*) INTO v_n FROM _held JOIN essentials.race_candidates rc ON rc.id = _held.id
   WHERE rc.last_name = _held.last_name;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: % of 1 held rows untouched', v_n; END IF;

  -- linked rows agree with the politician copy
  SELECT count(*) INTO v_n FROM _r JOIN essentials.race_candidates rc ON rc.id = _r.id
    JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE p.last_name = rc.last_name;
  IF v_n <> 109 THEN RAISE EXCEPTION 'POST: % of 109 linked rows agree with the politician''s last_name', v_n; END IF;

  RAISE NOTICE 'CA_0274 applied: 110 race_candidates last_names reduced to the bare surname; 1 no-period row held';
END $$;

COMMIT;
