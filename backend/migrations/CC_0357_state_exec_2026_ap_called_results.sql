-- CC_0357 — 2026-11-03 state executives: record the results AP has called.
--
-- WHAT: 53 candidacies across the 18 statewide-executive races AP covers, in the six
--       states we hold state-executive races for. 18 won, 35 lost.
--       AZ 11 rows / CA 8 / CO 13 / IN 4 / NV 10 / WI 7.
--
-- SOURCE: AP's public election-results feed, fetched 2026-11-05.
--   metadata.json  — the ballot, the incumbent of record, raceCallStatus, isCertified
--   progress.json  — 🔴 THE WINNER LIVES HERE, as winner:"X" on a candidate, beside
--                    votePct and calledAt. metadata.json is BALLOT ORDER and names nobody.
--   ⚠ The two files disagree about shape: metadata.json's "candidates" is an OBJECT MAP
--     keyed by candidateID; progress.json's "candidates" is an ARRAY. Indexing the array
--     as a map returns undefined for every candidate — a uniform empty answer that reads
--     like a race with no results rather than like a broken reader. It happened here and
--     was caught only because EVERY percentage came back blank at once.
--   The joined response for these 18 races is saved verbatim beside this file, at
--   backend/data/state-exec-2026-results/ap-2026-11-05.json, because a live feed is
--   overwritten in place.
--
-- 🔴 THIS FILE OVERWRITES 11 ROWS. THEIR PRIOR VALUES ARE RECORDED HERE AND NOWHERE ELSE.
--   All 11 are Arizona, all written by CA_0281 on 2026-09-24, and all read 'advanced'
--   with result_certainty NULL. 'advanced' there meant "won the primary, is on the
--   November ballot" — a fact about the PRIMARY, recorded against the November race row.
--   The November result supersedes it. The 11, each 'advanced' before this file:
--     AZ Attorney General      Warren Petersen          advanced -> lost
--     AZ Attorney General      Kris Mayes               advanced -> won
--     AZ Governor              Andy Biggs               advanced -> lost
--     AZ Governor              Katie Hobbs              advanced -> won
--     AZ Governor              Risa Lombardo            advanced -> lost
--     AZ Governor              Teri Hourihan            advanced -> lost
--     AZ Governor              Gertritrude Gonzalez     advanced -> lost
--     AZ Governor              Alice Novoa              advanced -> lost
--     AZ Secretary of State    Alexander Kolodin        advanced -> lost
--     AZ Secretary of State    Adrian Fontes            advanced -> won
--     AZ Secretary of State    Duwayne Collier          advanced -> lost
--   Their result_source was CA_0281's Arizona primary-canvass citation and their
--   result_recorded_at was 2026-09-24 23:23:15.77459+00. BOTH ARE REPLACED, deliberately:
--   a source and a timestamp describe the value they sit beside, so leaving either would
--   go on citing and dating a record that has been replaced. That is exactly the defect
--   CC_0354 had to repair on 155 rows.
--
-- 🔴 THE WINNER IS CROSS-CHECKED AGAINST THE PERCENTAGES. The pre-gate refuses to run if
--   the candidate marked 'won' is not AP's top vote-getter in that race. winner and
--   votePct are independent fields in the feed, so a transposition breaks their agreement.
--   Reading ballot order as a result got a House race exactly backwards once (CC_0356).
--   ⚠ It holds here because all 18 races are single-round and AP flags none as
--   rankedChoice. A ranked-choice or plurality contest can be called for someone who is
--   not top on first preferences; the generator refuses on rankedChoice for that reason.
--
-- NOT WRITTEN, each for a stated reason. These rows sit in an AP-covered race and keep
-- the value they already had:
--     AZ AG   Greg Roeberg          candidate_status=withdrawn; not on the ballot
--     AZ AG   Rodney Glassman       not_nominated — lost the primary
--     AZ Gov  David Schweikert      not_nominated — lost the primary
--     AZ Gov  Karrin Taylor Robson  candidate_status=withdrawn
--   ^ Roeberg and Taylor Robson are the only two rows in an AP-covered race that were
--     ALREADY NULL and stay NULL. Both read candidate_status=withdrawn, which is the
--     record of why, and a post-verify gate asserts that is still what they say.
--     AZ SoS  Gina Swoboda          not_nominated — lost the primary
--     WI Gov  Jamie Jo Carothers    not_nominated — not on the ballot
--     CO SoS  Alex Astley           🔴 won the Libertarian primary and then WITHDREW in
--                                   August 2026; the party's vacancy committee named Sean
--                                   Vadney, who reached the ballot by court order on
--                                   2026-09-04 (Vadney v Griswold, Denver District Court
--                                   2026CV33176). He is on no November ballot, so he gets
--                                   no November result. Recording 'withdrew' is a
--                                   different act with a different source and is NOT done
--                                   here. LEFT NULL DELIBERATELY — see NOTES.md.
--
-- NOT ON OUR SIDE AT ALL — AP ballot lines we hold no candidacy row for. Seeding is a
-- separate act and this file does not do it:
--     CO SoS  Sean Vadney (Lib)   1.51%      NV Gov  Danielle Ford (NPA)  2.80%
--     NV LG   Janine Hansen (IAP) 2.72%
-- ⚠ NV Governor holds TWO people called Ford — the winner Aaron Ford (Dem) and Danielle
--   Ford (NPA), who is not ours. Every pin below is an rc_id and every name is asserted,
--   so no last-name join decides anything. That is the TX-22 twin-brother hazard again.
--
-- NOT A PERSON: Nevada's "None of These Candidates" (AP candidateID 100013) appears on
--   all four NV ballots and is a ballot line, not a candidate. It gets no row. The
--   generator refuses if it is ever the winner — in Nevada it can be.
--
-- A CALL IS NOT A CANVASS: result_certainty is 'called' on all 53. AP reports
--   isCertified:false for all 18 and counting is live (California is at ~61% of the
--   expected vote). The 'certified' upgrade is a separate pass, per state.
--
-- 16 of our 34 state-executive races are NOT in this file, because AP's feed does not
-- carry those offices at all. AP's state-level coverage is Governor, Attorney General,
-- Secretary of State and Lieutenant Governor, and nothing else. The 16, measured:
--   Treasurer x6 (AZ CA CO IN NV WI) · Controller x2 (CA NV)
--   Superintendent of Public Instruction x2 (AZ CA) · Lieutenant Governor x2 (CO WI)
--   AZ Corporation Commissioner · AZ State Mine Inspector
--   CA Insurance Commissioner · IN Comptroller
-- CO and WI Lieutenant Governor run on the GOVERNOR'S TICKET, so AP publishes no separate
-- race for them; their result follows the Governor's, but from the ticket composition and
-- not from this feed, so it is not guessed here.
-- 🔴 AZ Corporation Commissioner elects TWO members. The top-vote-getter gate and the
--   one-winner gate in this file are both WRONG for it, and would pass quietly for
--   whichever single winner got recorded. Do not copy this file onto it.
-- They need a different source. See NOTES.md.
--
-- ⚠ RE-RUNNING THIS FILE RAISES AND ROLLS BACK. IT DOES NOT SILENTLY PASS.
--   The UPDATE is guarded (`result IS NULL OR result = 'advanced'`), so it would be a
--   no-op — but the overwrite pre-gate refuses first, because the pins now carry 'won'
--   and 'lost', which that gate reads as "someone wrote here after this file was built".
--   MEASURED, not assumed: the dry run was re-run against prod after applying and failed
--   with `a pinned row carries an unexpected prior result: ... Kris Mayes = won; ...`,
--   rolling back and changing nothing.
--   That is the safe outcome and it is left as is. A second apply of a hand-applied
--   migration is a mistake, and a loud refusal reports the mistake where a silent no-op
--   would hide it. Repairing it would mean adding an already-applied skip path to a file
--   that is already in production, where only one of the two paths could still be tested.

-- Applied to production 2026-11-05 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── The write list. Pinned by race_candidates.id so no name or join picks the target. ───
CREATE TEMP TABLE calls (
  rc_id      uuid PRIMARY KEY,
  race_id    uuid NOT NULL,
  seat       text NOT NULL,
  who        text NOT NULL,
  ap_cand_id text NOT NULL,
  result     text NOT NULL,
  vote_pct   numeric NOT NULL
) ON COMMIT DROP;

INSERT INTO calls (rc_id, race_id, seat, who, ap_cand_id, result, vote_pct) VALUES
 ('8e18026b-fbe1-4100-b8d3-ed7aa064fbaf'::uuid, '2fe605ce-d33b-41bc-8e8a-3621512501aa'::uuid,
  'AZ Attorney General',                     'Warren Petersen',           '101535',  'lost',   44.64),
 ('23e673fe-fbae-4d85-9537-6216908285cf'::uuid, '2fe605ce-d33b-41bc-8e8a-3621512501aa'::uuid,
  'AZ Attorney General',                     'Kris Mayes',                '101961',  'won',    55.36),
 ('895a426d-6c65-49fe-adc9-65bad6afab67'::uuid, 'cfe1d1c2-c515-4f0c-817a-60480e0ba7b5'::uuid,
  'AZ Governor',                             'Andy Biggs',                '52611',   'lost',    42.7),
 ('fcd85751-3fd7-4c63-9f2a-b3d2552ea23a'::uuid, 'cfe1d1c2-c515-4f0c-817a-60480e0ba7b5'::uuid,
  'AZ Governor',                             'Katie Hobbs',               '70987',   'won',    55.57),
 ('3d8d0a08-6380-4152-a6ff-15c68d04904c'::uuid, 'cfe1d1c2-c515-4f0c-817a-60480e0ba7b5'::uuid,
  'AZ Governor',                             'Risa Lombardo',             '178234',  'lost',    0.89),
 ('b3a0bcdf-c650-483d-a540-bb17835a8fd1'::uuid, 'cfe1d1c2-c515-4f0c-817a-60480e0ba7b5'::uuid,
  'AZ Governor',                             'Teri Hourihan',             '178235',  'lost',    0.83),
 ('7cd56736-fe34-4604-9fc3-345187ce048e'::uuid, 'cfe1d1c2-c515-4f0c-817a-60480e0ba7b5'::uuid,
  'AZ Governor',                             'Gertritrude Gonzalez',      '179624',  'lost',       0),
 ('74e7205a-5801-47fb-bda0-7e87c7df95e7'::uuid, 'cfe1d1c2-c515-4f0c-817a-60480e0ba7b5'::uuid,
  'AZ Governor',                             'Alice Novoa',               '179625',  'lost',       0),
 ('d0c18db4-9645-4abc-9057-c9872655a8f9'::uuid, 'de56ea84-ba75-4ee2-bf7d-b02dbfdd52f7'::uuid,
  'AZ Secretary of State',                   'Alexander Kolodin',         '101900',  'lost',   43.79),
 ('f509b4fb-487c-4d82-a431-e6b94e15054b'::uuid, 'de56ea84-ba75-4ee2-bf7d-b02dbfdd52f7'::uuid,
  'AZ Secretary of State',                   'Adrian Fontes',             '101959',  'won',     54.8),
 ('f0ed664a-d19e-4ac5-ad7e-7748950a5efa'::uuid, 'de56ea84-ba75-4ee2-bf7d-b02dbfdd52f7'::uuid,
  'AZ Secretary of State',                   'Duwayne Collier',           '178236',  'lost',    1.41),
 ('a7089508-0838-49d6-88ba-d83aa999eb5f'::uuid, '18c9dcc2-9e1c-4c4f-ad86-81b0bf93f1d9'::uuid,
  'CA Attorney General',                     'Rob Bonta',                 '105252',  'won',    64.01),
 ('a8ff0569-3c94-457f-8436-891eb6407ce2'::uuid, '18c9dcc2-9e1c-4c4f-ad86-81b0bf93f1d9'::uuid,
  'CA Attorney General',                     'Michael E. Gates',          '172480',  'lost',   35.99),
 ('489d991b-3491-4140-b8d9-007d633939fa'::uuid, 'bec5ef3b-095b-4d7d-9117-db81e407cb5e'::uuid,
  'CA Governor',                             'Xavier Becerra',            '94',      'won',    64.19),
 ('b9e15610-016d-4225-b8f5-77f68d155c4f'::uuid, 'bec5ef3b-095b-4d7d-9117-db81e407cb5e'::uuid,
  'CA Governor',                             'Steve Hilton',              '172439',  'lost',   35.81),
 ('cb84de45-619a-4219-a117-9a33e9c2d0c8'::uuid, '81e2139a-0d56-4280-8a44-8cbeebeb9c7b'::uuid,
  'CA Lieutenant Governor',                  'Fiona Ma',                  '105098',  'won',    64.02),
 ('77ae78a8-dbdc-43be-8dcc-77e5073248d7'::uuid, '81e2139a-0d56-4280-8a44-8cbeebeb9c7b'::uuid,
  'CA Lieutenant Governor',                  'Gloria Romero',             '172469',  'lost',   35.98),
 ('d4da5724-bfbb-4862-9d6b-ed246cd50934'::uuid, '5173cd38-b193-4bcc-bb30-7ef3a1303d91'::uuid,
  'CA Secretary of State',                   'Donald P. Wagner',          '105195',  'lost',   35.06),
 ('a3f67d9e-0d46-4d51-8b41-4db9232fca11'::uuid, '5173cd38-b193-4bcc-bb30-7ef3a1303d91'::uuid,
  'CA Secretary of State',                   'Shirley N. Weber',          '105428',  'won',    64.94),
 ('7a64fd31-482c-45a1-9409-7971fa20c615'::uuid, 'c1f6363c-c462-4de7-91de-0c821751e033'::uuid,
  'CO Attorney General',                     'Jena Griswold',             '104359',  'won',    58.16),
 ('e810ae66-c3ea-435d-a556-a4ca1a83eefa'::uuid, 'c1f6363c-c462-4de7-91de-0c821751e033'::uuid,
  'CO Attorney General',                     'Michael Allen',             '104624',  'lost',   41.84),
 ('76cf1677-477e-447c-98c3-3e951a52c585'::uuid, '341647e8-182d-4030-bfa7-924b74caf912'::uuid,
  'CO Governor',                             'Greg Lopez',                '67043',   'lost',     2.8),
 ('62ed05c7-ba9a-4ec9-bf5a-83c5965f21de'::uuid, '341647e8-182d-4030-bfa7-924b74caf912'::uuid,
  'CO Governor',                             'Eric Mulder',               '71796',   'lost',    1.59),
 ('094d2cfc-7063-467a-ad8b-5d642d334ec8'::uuid, '341647e8-182d-4030-bfa7-924b74caf912'::uuid,
  'CO Governor',                             'Phil Weiser',               '104361',  'won',    60.49),
 ('cb817dc8-a5fe-457b-9fed-abacca707faf'::uuid, '341647e8-182d-4030-bfa7-924b74caf912'::uuid,
  'CO Governor',                             'Victor Marx',               '174624',  'lost',   33.96),
 ('0a7453bc-f5fd-49b8-a918-9996a65ce7e5'::uuid, '341647e8-182d-4030-bfa7-924b74caf912'::uuid,
  'CO Governor',                             'Jeff Peckman',              '177913',  'lost',     0.2),
 ('2220b9c7-3f59-492f-be4e-25007934cabe'::uuid, '341647e8-182d-4030-bfa7-924b74caf912'::uuid,
  'CO Governor',                             'Stephen T. Hamilton',       '178822',  'lost',    0.63),
 ('1d735530-1ca5-4d29-a725-bef5a9b5b79e'::uuid, '341647e8-182d-4030-bfa7-924b74caf912'::uuid,
  'CO Governor',                             'Erik Underwood',            '178823',  'lost',    0.32),
 ('4afd08af-9028-4328-89b5-89f78730e51f'::uuid, '030fff92-9ffc-4d6b-9615-06477715e9a7'::uuid,
  'CO Secretary of State',                   'Amanda Campbell',           '102768',  'lost',    0.79),
 ('06ccb587-0fcc-4ae2-aade-2319c6d5ae62'::uuid, '030fff92-9ffc-4d6b-9615-06477715e9a7'::uuid,
  'CO Secretary of State',                   'James Wiley',               '168013',  'lost',   37.62),
 ('c8839191-9325-4ff8-958e-b4c202c894fe'::uuid, '030fff92-9ffc-4d6b-9615-06477715e9a7'::uuid,
  'CO Secretary of State',                   'Amanda Gonzalez',           '174625',  'won',    59.44),
 ('3ccdef2a-62f4-4aa2-a8cc-5a0089fde1f1'::uuid, '030fff92-9ffc-4d6b-9615-06477715e9a7'::uuid,
  'CO Secretary of State',                   'Celeste Landry',            '178824',  'lost',    0.64),
 ('3e9c137c-32c2-4ea2-ae4e-fad908d20d8c'::uuid, '1f66018e-0fa9-4719-8527-568e471c6369'::uuid,
  'IN Secretary of State',                   'Max Engling',               '162930',  'lost',    42.6),
 ('8effd903-9ccf-451e-a7d4-44e213c1d06b'::uuid, '1f66018e-0fa9-4719-8527-568e471c6369'::uuid,
  'IN Secretary of State',                   'Lauri Shillings',           '167505',  'lost',    1.99),
 ('8a4406a2-f473-4b44-9333-4caa2993a4a0'::uuid, '1f66018e-0fa9-4719-8527-568e471c6369'::uuid,
  'IN Secretary of State',                   'Beau Bayh',                 '177918',  'won',    51.81),
 ('5bb6c9fe-c171-4fb8-b8ed-04f0808de70d'::uuid, '1f66018e-0fa9-4719-8527-568e471c6369'::uuid,
  'IN Secretary of State',                   'Greg Ballard',              '178670',  'lost',     3.6),
 ('a6b55511-546f-468e-9cde-e81ff32149a2'::uuid, 'b5cfa5be-0eda-452b-b9e4-99b75f090ee1'::uuid,
  'NV Attorney General',                     'Adriana Guzman Fralick',    '132104',  'lost',   41.54),
 ('17541276-4a52-48b2-8c0c-5fd1fb651ade'::uuid, 'b5cfa5be-0eda-452b-b9e4-99b75f090ee1'::uuid,
  'NV Attorney General',                     'Nicole J. Cannizzaro',      '132242',  'won',    56.26),
 ('b62df252-ff7a-4b3d-b5ff-860966591b1e'::uuid, '7744880b-82b1-404a-9f48-58a505debcd5'::uuid,
  'NV Governor',                             'Joe Lombardo',              '70779',   'lost',   44.22),
 ('ddb26217-2129-48d2-b3f1-86eb70966678'::uuid, '7744880b-82b1-404a-9f48-58a505debcd5'::uuid,
  'NV Governor',                             'Aaron Ford',                '131963',  'won',    51.53),
 ('e816b82e-3128-41ec-adce-6fc4c6b996cc'::uuid, 'f45501be-ba2f-4e0e-b7d2-b55c187e32a9'::uuid,
  'NV Lieutenant Governor',                  'Sandra Jauregui',           '132349',  'won',    54.32),
 ('c9a3ced4-7162-45db-9c44-a2080f8413ed'::uuid, 'f45501be-ba2f-4e0e-b7d2-b55c187e32a9'::uuid,
  'NV Lieutenant Governor',                  'Stavros Anthony',           '132744',  'lost',   41.22),
 ('d56e1cc7-5ece-43b7-9217-ecaebde227af'::uuid, '717fee53-f871-41fd-a350-233c8da669f5'::uuid,
  'NV Secretary of State',                   'Jim Marchant',              '68854',   'lost',   39.47),
 ('5ac951b2-66d8-47a0-ac1c-dffd9a76bd23'::uuid, '717fee53-f871-41fd-a350-233c8da669f5'::uuid,
  'NV Secretary of State',                   'Cisco Aguilar',             '132749',  'won',    56.88),
 ('4c3420b9-668f-4d2f-a972-bb6867cc4a6d'::uuid, '717fee53-f871-41fd-a350-233c8da669f5'::uuid,
  'NV Secretary of State',                   'John T. Kennedy',           '132872',  'lost',    0.85),
 ('355c9cad-4b9c-407e-9bcd-7e8d47bd0492'::uuid, '717fee53-f871-41fd-a350-233c8da669f5'::uuid,
  'NV Secretary of State',                   'Brad Barnhill',             '166660',  'lost',    1.46),
 ('a934929f-0383-46f7-8057-1a8054ec7f0f'::uuid, '484b545c-8788-47c1-bf51-e54fb873e847'::uuid,
  'WI Attorney General',                     'Josh Kaul',                 '156768',  'won',    54.72),
 ('e65637e2-55e2-4aed-b6f4-5a730fb41cf7'::uuid, '484b545c-8788-47c1-bf51-e54fb873e847'::uuid,
  'WI Attorney General',                     'Eric Toney',                '175174',  'lost',   45.28),
 ('203dbef1-468e-4a30-aa67-fcb30286383a'::uuid, '59e866b1-a5bf-4141-9f06-689c1024a80b'::uuid,
  'WI Governor',                             'Thomas P. Tiffany',         '67975',   'lost',   45.92),
 ('5d2603f9-c225-4115-848e-04ef4d35b837'::uuid, '59e866b1-a5bf-4141-9f06-689c1024a80b'::uuid,
  'WI Governor',                             'David Crowley',             '156426',  'won',    54.08),
 ('e3660298-b093-48bc-aa63-8ca0982122d1'::uuid, '0bd931f4-01a4-43d0-aa15-58d6f48ff502'::uuid,
  'WI Secretary of State',                   'JoCasta Zamarripa',         '154331',  'won',    50.69),
 ('b174e49e-eb50-4c6c-b088-3277aa36b839'::uuid, '0bd931f4-01a4-43d0-aa15-58d6f48ff502'::uuid,
  'WI Secretary of State',                   'Jay Schroeder',             '154657',  'lost',   45.53),
 ('234fc459-d260-4417-a2f9-3cbe4fcda1a1'::uuid, '0bd931f4-01a4-43d0-aa15-58d6f48ff502'::uuid,
  'WI Secretary of State',                   'Pete Karas',                '178828',  'lost',    3.78);

-- ─── Snapshot every state-executive candidacy BEFORE writing. This is the only control
--     that can test what this file does NOT do. ───
CREATE TEMP TABLE before_rows ON COMMIT DROP AS
SELECT rc.id, rc.result, rc.result_certainty, rc.result_source, rc.result_recorded_at
  FROM essentials.race_candidates rc
  JOIN essentials.races r      ON r.id = rc.race_id
  JOIN essentials.elections e  ON e.id = r.election_id
  JOIN essentials.offices   o  ON o.id = r.office_id
  JOIN essentials.districts d  ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.district_type = 'STATE_EXEC';

-- ─── Pre-gates ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM before_rows;
  IF n <> 112 THEN RAISE EXCEPTION 'expected 112 state-executive candidacies in the snapshot, found %', n; END IF;

  SELECT count(*) INTO n FROM calls;
  IF n <> 53 THEN RAISE EXCEPTION 'expected 53 pinned rows, found %', n; END IF;

  SELECT count(DISTINCT race_id) INTO n FROM calls;
  IF n <> 18 THEN RAISE EXCEPTION 'expected 18 distinct races, found %', n; END IF;

  -- 1. every pin exists, IN THE RACE THIS FILE STATES
  SELECT count(*) INTO n
    FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id AND rc.race_id = c.race_id;
  IF n <> 53 THEN RAISE EXCEPTION 'only % of the 53 pinned rows exist in their stated race', n; END IF;

  -- 2. every pin still NAMES the person this file says it does
  SELECT string_agg(c.seat || ' ' || c.who || ' <> ' || coalesce(p.full_name,'(no politician row)'), '; ') INTO txt
    FROM calls c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id
    LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE p.full_name IS DISTINCT FROM c.who;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned id no longer names the expected candidate: %', txt; END IF;

  -- 3. the only prior value any pin may carry is 'advanced' — the 11 Arizona rows recorded
  --    in the header. Anything else means someone has written here since this was built.
  SELECT string_agg(c.seat || ' ' || c.who || ' = ' || rc.result, '; ') INTO txt
    FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result IS NOT NULL AND rc.result <> 'advanced';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned row carries an unexpected prior result: %', txt; END IF;

  SELECT count(*) INTO n FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result = 'advanced';
  IF n <> 11 THEN RAISE EXCEPTION 'expected exactly 11 rows to overwrite, found %', n; END IF;

  -- 4. 🔴 the winner must be AP's top vote-getter in that race
  SELECT string_agg(a.seat || ': ' || a.who || ' won on ' || a.vote_pct
                    || '% but ' || b.who || ' polled ' || b.vote_pct || '%', '; ') INTO txt
    FROM calls a JOIN calls b ON b.race_id = a.race_id AND b.vote_pct > a.vote_pct
   WHERE a.result = 'won';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the winner is not the top vote-getter: %', txt; END IF;

  -- 5. exactly one winner per race, across 18 distinct races
  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 18 THEN RAISE EXCEPTION 'expected 18 winners in this file, found %', n; END IF;
  SELECT count(*) INTO n FROM (SELECT race_id FROM calls WHERE result = 'won' GROUP BY race_id HAVING count(*) <> 1) z;
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) do not have exactly one winner in this file', n; END IF;

  -- 6. baseline: no state executive holds a called general-election result yet
  SELECT count(*) INTO n FROM before_rows WHERE result IN ('won','lost');
  IF n <> 0 THEN RAISE EXCEPTION 'expected 0 won/lost state-executive rows before this file, found %', n; END IF;
  SELECT count(*) INTO n FROM before_rows WHERE result_certainty = 'certified';
  IF n <> 0 THEN RAISE EXCEPTION 'expected 0 certified state-executive rows, found %', n; END IF;
END $$;

-- ─── The write ───
UPDATE essentials.race_candidates rc
   SET result             = c.result,
       result_certainty   = 'called',
       result_source      = 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0357)',
       result_recorded_at = now()
  FROM calls c
 WHERE rc.id = c.rc_id
   AND (rc.result IS NULL OR rc.result = 'advanced');

-- ─── Post-verify ───
DO $$
DECLARE n int; txt text;
BEGIN
  -- 1. exactly 53 rows differ from the snapshot, and every one of them is pinned
  SELECT count(*) INTO n
    FROM before_rows b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE (rc.result, rc.result_certainty, rc.result_source, rc.result_recorded_at)
         IS DISTINCT FROM (b.result, b.result_certainty, b.result_source, b.result_recorded_at);
  IF n <> 53 THEN RAISE EXCEPTION '% state-executive row(s) changed, expected exactly 53', n; END IF;

  SELECT count(*) INTO n
    FROM before_rows b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE (rc.result, rc.result_certainty, rc.result_source, rc.result_recorded_at)
         IS DISTINCT FROM (b.result, b.result_certainty, b.result_source, b.result_recorded_at)
     AND NOT EXISTS (SELECT 1 FROM calls c WHERE c.rc_id = b.id);
  IF n <> 0 THEN RAISE EXCEPTION '% changed row(s) are OUTSIDE the pinned set', n; END IF;

  -- 2. every pin holds exactly what this file said, with its citation and a fresh stamp
  SELECT count(*) INTO n
    FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result = c.result
     AND rc.result_certainty = 'called'
     AND rc.result_source = 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0357)'
     AND rc.result_recorded_at IS NOT NULL;
  IF n <> 53 THEN RAISE EXCEPTION 'only % of the 53 pinned rows hold their stated result', n; END IF;

  -- 3. nothing claims to be certified, and nothing is dated before the calls were made
  SELECT count(*) INTO n FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result_certainty <> 'called';
  IF n <> 0 THEN RAISE EXCEPTION '% pinned row(s) do not read called', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result_recorded_at < TIMESTAMPTZ '2026-11-04';
  IF n <> 0 THEN RAISE EXCEPTION '% pinned row(s) are dated before 2026-11-04', n; END IF;

  -- 4. the seven rows this file deliberately leaves alone are untouched
  SELECT count(*) INTO n
    FROM before_rows b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE b.id IN ('7036fc26-6025-4ffd-b1ad-f60fb5d8c8c8','90f95a3d-55af-40a3-90a1-2a312763ec7d',
                  '2b414878-e840-4250-906d-d7f74d6b350c','3de090e3-c2b1-417e-8186-58eec5a508e7',
                  'bff7ced2-9d64-419e-b34b-416fe1e8ece6','909f9c24-e025-4a02-a6a2-601f36d9d4b2',
                  '4c3994f3-06f6-4344-985d-072419744789')
     AND (rc.result, rc.result_source, rc.result_recorded_at)
         IS DISTINCT FROM (b.result, b.result_source, b.result_recorded_at);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 7 leave-alone rows was changed', n; END IF;

  -- 5. each of the 18 races now holds exactly one winner
  SELECT count(*) INTO n FROM (
    SELECT c.race_id FROM (SELECT DISTINCT race_id FROM calls) c
      JOIN essentials.race_candidates rc ON rc.race_id = c.race_id
     GROUP BY c.race_id
    HAVING count(*) FILTER (WHERE rc.result = 'won') <> 1) z;
  IF n <> 0 THEN RAISE EXCEPTION '% of the 18 races do not hold exactly one winner', n; END IF;

  -- and nobody in those races is left undecided EXCEPT three people named in the header:
  -- Alex Astley, who withdrew after winning the Libertarian primary, and two candidacies
  -- that already read candidate_status=withdrawn. NAMED, NOT COUNTED — a count of 3 would
  -- pass for any three people, and the first version of this gate expected Astley alone
  -- and was simply wrong about the other two. It named them, so the fix was exact.
  SELECT string_agg(DISTINCT coalesce(p.full_name,'(no politician row)'), '; ') INTO txt
    FROM (SELECT DISTINCT race_id FROM calls) c
    JOIN essentials.race_candidates rc ON rc.race_id = c.race_id
    LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE rc.result IS NULL;
  IF txt IS DISTINCT FROM 'Alex Astley; Greg Roeberg; Karrin Taylor Robson' THEN
    RAISE EXCEPTION 'the undecided rows in the 18 races are not the three expected people: %', coalesce(txt,'(none)');
  END IF;

  -- and the two besides Astley are undecided for a reason their own row states
  SELECT count(*) INTO n FROM essentials.race_candidates rc
   WHERE rc.id IN ('7036fc26-6025-4ffd-b1ad-f60fb5d8c8c8','3de090e3-c2b1-417e-8186-58eec5a508e7')
     AND rc.candidate_status = 'withdrawn' AND rc.result IS NULL;
  IF n <> 2 THEN RAISE EXCEPTION 'Roeberg/Taylor Robson no longer read withdrawn-and-undecided (% of 2)', n; END IF;

  -- 6. 🔴 SCOPED to this tier and this election. Repo-wide, "a loser and no winner" is the
  --    NORMAL shape of a primary, where the winner's row reads 'advanced' — CC_0356 found
  --    24 such races and none of them was in this election. A repo-wide version of this
  --    check is wrong, and failed CC_0356's first dry run for that reason.
  SELECT count(*) INTO n FROM (
    SELECT r.id FROM essentials.races r
      JOIN essentials.elections e  ON e.id = r.election_id
      JOIN essentials.offices   o  ON o.id = r.office_id
      JOIN essentials.districts d  ON d.id = o.district_id
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC'
     GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'lost') > 0
       AND count(*) FILTER (WHERE rc.result = 'won')  = 0) z;
  IF n <> 0 THEN RAISE EXCEPTION '% state-executive race(s) hold a loser and no winner', n; END IF;

  -- 7. the tier totals
  SELECT count(*) FILTER (WHERE rc.result = 'won') INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r      ON r.id = rc.race_id
    JOIN essentials.elections e  ON e.id = r.election_id
    JOIN essentials.offices   o  ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC';
  IF n <> 18 THEN RAISE EXCEPTION 'expected 18 state-executive winners, found %', n; END IF;

  SELECT count(*) FILTER (WHERE rc.result = 'lost') INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races r      ON r.id = rc.race_id
    JOIN essentials.elections e  ON e.id = r.election_id
    JOIN essentials.offices   o  ON o.id = r.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC';
  IF n <> 35 THEN RAISE EXCEPTION 'expected 35 state-executive losers, found %', n; END IF;

  RAISE NOTICE 'CC_0357 OK — 18 won, 35 lost across 18 races; 11 primary advanced rows superseded.';
END $$;

COMMIT;
