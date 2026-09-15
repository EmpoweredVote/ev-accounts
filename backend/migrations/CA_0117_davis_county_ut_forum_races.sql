BEGIN;

-- =============================================================================
-- CA_0117: Davis County (UT) — four 2026 primary races and their nine candidates
-- =============================================================================
-- Created 2026-09-15. Sibling of CA_0116 (Brown County IN), same reason.
--
-- WHAT THIS ADDS
-- Four races under the existing 2026 Utah Primary
-- (02dee6b2-76cd-4aa3-a365-6ee362f8a719, UT, 2026-06-23), plus the seven
-- candidates not already in the corpus and the candidacies linking all nine.
--
-- WHY IT EXISTS
-- on-the-record holds a 132-minute LWV Davis County candidate forum covering all
-- four offices in one evening (meeting 2026-06-01-lwv-candidate-forum-davis-county-ut,
-- fully processed to stage 7, 12 labels, all named, NONE linked). It cannot publish:
-- publish.py::_reconcile_event_races refuses a 'forum' resolving to zero races, and
-- resolves only through essentials.race_candidates.politician_id. Blocked since
-- 2026-06-28. Policy is COVERAGE FOLLOWS CONTENT — see CA_0116.
--
-- WHO IS WHO. Every candidate label self-introduces on tape, and each was matched to
-- the certified field rather than to the pipeline's guesses:
--   Commission Seat A  John Adams · Scott Fletcher · Kendalyn Harris
--   Commission Seat B  Susan Lee · Lorene Kamalu (incumbent)
--   Clerk              Jona Whitesides · Brian McKenzie (incumbent)
--   Sheriff            Jon Atkin · Aaron Perry
-- Two labels never said their own names and were identified from unmistakable
-- biography, not by elimination: the Seat A speaker describes "12 years of service
-- in Bountiful" and that "in Bountiful we own our own power department" (Kendalyn
-- Harris, former Bountiful mayor); the sheriff speaker describes starting his career
-- at the Davis County Sheriff's Office and serving as "correction chief at Weber
-- County" (Aaron Perry, former Weber County chief deputy).
-- Results, 2026-06-23 (standard.net, fetched 2026-09-15): Harris 42.77% over
-- Fletcher 31.16% and Adams 26.07%; Lee 50.89% over Kamalu 49.11%; Atkin 51.12%
-- over Perry 48.88%; McKenzie 62.57% over Whitesides 37.43%.
--
-- 🔴 THE PIPELINE'S OWN NAMES ARE WRONG AND MUST NOT BE COPIED IN.
-- transcript_named.json currently calls SPEAKER_10 "Nikki Nelson" and SPEAKER_07
-- "Ken Lyn", both from the LLM layer (unverified tier). SPEAKER_10 is Lorene Kamalu;
-- Nikki Nelson is the LEAGUE MODERATOR on SPEAKER_03. SPEAKER_07 is Jon Atkin.
-- Nikki Nelson and Angie Sterner (SPEAKER_11) are League of Women Voters moderators
-- and SPEAKER_09 is the pledge — none of the three is a candidate and none gets a
-- row here.
--
-- 🔴 TWO CANDIDATES ALREADY EXIST AND THEIR slug IS NULL.
-- Lorene Kamalu e0f84fbf-342d-48e9-be4f-d992635b5811 and Brian McKenzie
-- 150b9f2d-bdaa-4d86-801a-44db8f182c72, both data_source 'ut-county-davis',
-- both is_incumbent=true, both with ZERO race edges and ZERO quotes — orphan rows,
-- the same shape CA_0116 found for Andy Bond. But unlike Bond THEY HAVE NO SLUG, so
-- a slug-only guard would not see them and would mint duplicates. The candidacies
-- below therefore match the existing pair BY ID and create only the other seven.
-- Their is_incumbent=true is left alone: both genuinely hold the office they were
-- defending.
--
-- WHY THE SHERIFF RACE HAS primary_party NULL WHILE THE OTHER THREE ARE Republican
-- Three are evidenced on tape — Fletcher "the endorsed candidate of the Davis County
-- Republican Party" (Seat A), Lee "the endorsed candidate from the Republican party
-- convention" (Seat B), Whitesides "the Davis County Republican Party endorsed
-- candidate" (Clerk). No sheriff candidate names a party, and the Standard-Examiner
-- result coverage does not state one. It is very probably the Republican primary,
-- but "very probably" is not a fact to write into a column that reads as one.
--
-- result is left NULL on all nine for the reason given in CA_0116: every populated
-- result in this database cites a certified canvass, and only press coverage is in
-- hand. The Utah certified canvass would fill all nine at once.
-- =============================================================================

-- The four races. No natural unique key on (election_id, position_name), so each
-- insert is guarded by NOT EXISTS.
INSERT INTO essentials.races (election_id, position_name, primary_party, seats)
SELECT '02dee6b2-76cd-4aa3-a365-6ee362f8a719', v.position_name, v.primary_party, 1
  FROM (VALUES
    ('Davis County Commission Seat A', 'Republican'),
    ('Davis County Commission Seat B', 'Republican'),
    ('Davis County Clerk',             'Republican'),
    ('Davis County Sheriff',           NULL)
  ) AS v(position_name, primary_party)
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.races r
    WHERE r.election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
      AND r.position_name = v.position_name
 );

-- The seven candidates who are not already in the corpus. is_incumbent is set
-- explicitly because essentials.politicians defaults it to TRUE, and every one of
-- these seven is a challenger. Slug + source follow the county-local pattern.
INSERT INTO essentials.politicians
  (full_name, first_name, last_name, party, source, slug, is_incumbent, is_active)
SELECT v.full_name, v.first_name, v.last_name, v.party,
       'ut_primary_2026', v.slug, false, true
  FROM (VALUES
    ('John Adams',       'John',     'Adams',      'Republican', 'john-adams-davis-county-ut'),
    ('Scott Fletcher',   'Scott',    'Fletcher',   'Republican', 'scott-fletcher-davis-county-ut'),
    ('Kendalyn Harris',  'Kendalyn', 'Harris',     'Republican', 'kendalyn-harris'),
    ('Susan Lee',        'Susan',    'Lee',        'Republican', 'susan-lee-davis-county-ut'),
    ('Jona Whitesides',  'Jona',     'Whitesides', 'Republican', 'jona-whitesides'),
    ('Jon Atkin',        'Jon',      'Atkin',      NULL,         'jon-atkin'),
    ('Aaron Perry',      'Aaron',    'Perry',      NULL,         'aaron-perry-davis-county-ut')
  ) AS v(full_name, first_name, last_name, party, slug)
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p WHERE p.slug = v.slug
 );

-- The nine candidacies. politician_id is the column publish.py resolves through, so
-- a row without it leaves the forum exactly as blocked as before. The two incumbents
-- are matched by ID because their slug is NULL.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name,
   is_incumbent, candidate_status, source)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name,
       v.is_incumbent, 'active', 'ut_primary_2026'
  FROM (VALUES
    ('Davis County Commission Seat A', 'john-adams-davis-county-ut',     NULL, false),
    ('Davis County Commission Seat A', 'scott-fletcher-davis-county-ut', NULL, false),
    ('Davis County Commission Seat A', 'kendalyn-harris',                NULL, false),
    ('Davis County Commission Seat B', 'susan-lee-davis-county-ut',      NULL, false),
    ('Davis County Commission Seat B', NULL, 'e0f84fbf-342d-48e9-be4f-d992635b5811', true),
    ('Davis County Clerk',             'jona-whitesides',                NULL, false),
    ('Davis County Clerk',             NULL, '150b9f2d-bdaa-4d86-801a-44db8f182c72', true),
    ('Davis County Sheriff',           'jon-atkin',                      NULL, false),
    ('Davis County Sheriff',           'aaron-perry-davis-county-ut',    NULL, false)
  ) AS v(position_name, slug, politician_id, is_incumbent)
  JOIN essentials.races r
    ON r.election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
   AND r.position_name = v.position_name
  JOIN essentials.politicians p
    ON (v.slug IS NOT NULL AND p.slug = v.slug)
    OR (v.politician_id IS NOT NULL AND p.id = v.politician_id::uuid)
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = r.id AND rc.politician_id = p.id
 );

DO $$
DECLARE
  v_n int;
BEGIN
  -- Four races, each exactly once.
  SELECT count(*) INTO v_n FROM essentials.races
   WHERE election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
     AND position_name IN ('Davis County Commission Seat A',
                           'Davis County Commission Seat B',
                           'Davis County Clerk', 'Davis County Sheriff');
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'CA_0117: expected 4 Davis County races, found %', v_n;
  END IF;

  -- Nine candidacies, every one carrying a politician_id. Without that column
  -- publish.py resolves nothing and the forum stays blocked.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
     AND r.position_name LIKE 'Davis County %'
     AND rc.politician_id IS NOT NULL;
  IF v_n <> 9 THEN
    RAISE EXCEPTION 'CA_0117: expected 9 linked candidacies, found %', v_n;
  END IF;

  -- No duplicate minted for the two pre-existing orphans. This is the check that
  -- a slug-only guard would have failed, since both of their slugs are NULL.
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE data_source = 'ut-county-davis'
     AND full_name IN ('Lorene Kamalu', 'Brian McKenzie');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CA_0117: expected exactly 2 ut-county-davis rows for Kamalu and McKenzie, found % — a duplicate was minted', v_n;
  END IF;

  -- The seven challengers must not claim incumbency; the column defaults to TRUE.
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE source = 'ut_primary_2026' AND is_incumbent;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0117: % challenger(s) defaulted to is_incumbent=true', v_n;
  END IF;

  -- Exactly the two real incumbents are flagged as such on their candidacies.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
     AND r.position_name LIKE 'Davis County %' AND rc.is_incumbent;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CA_0117: expected 2 incumbent candidacies (Kamalu, McKenzie), found %', v_n;
  END IF;

  -- result stays NULL until a certified canvass backs it.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
     AND r.position_name LIKE 'Davis County %' AND rc.result IS NOT NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CA_0117: % result(s) recorded without a certified canvass', v_n;
  END IF;

  RAISE NOTICE 'CA_0117 OK — Davis County UT staged (4 races, 9 linked candidacies, 7 challengers created, Kamalu + McKenzie reused by id with is_incumbent untouched, sheriff primary_party NULL, result NULL pending certified canvass)';
END $$;

COMMIT;
