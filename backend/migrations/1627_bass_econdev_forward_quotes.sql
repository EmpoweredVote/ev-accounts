-- 1627_bass_econdev_forward_quotes.sql
--
-- Karen Bass looked absent from both of LA Mayor's new economic-development questions. She was not.
-- The forward-looking material existed; it had been trimmed away or never curated.
--
-- 1. FIXES A TRIM (b2d1f06d, downtown). The stored quote kept the RECORD half of her debate answer
--    ("we have a strategy that is working", "that's why I did the adaptive reuse ordinance") and cut
--    the FORWARD half four sentences early. Exactly inverted from what a Read & Rank quote is. The
--    replacement is a single contiguous run from the same answer (meeting f2cf80ef, seg 364,
--    t=4651), verified word-for-word against the transcript, with ONE leading ellipsis because the
--    run begins mid-sentence at "That is why we have to deal with…" — "That is why" points back at
--    the record clause and would mislead if kept. No interior elisions, nothing reordered. The
--    closing "And my number one obligation is to keep our city safe" is dropped at a genuine
--    sentence boundary: it states no position and is the one office-holder-flavoured clause.
--    "long -term" → "long-term" is an ASR spacing repair, i.e. transcription fidelity, not an edit.
--
--    Worth recording: under the old EDITORIAL rule ("one claim per quote") the original trim was
--    arguably defensible. Under the rule adopted 2026-08-08 ("one position per quote — but draw it
--    fully… err toward including the how") it is not. This is that rule catching a real defect.
--
-- 2. ADDS TWO FILM/TV QUOTES, both written Q&A where she was asked this question directly
--    (`answered-this-question` directness — the most directly comparable level, §5).
--
-- Both new rows and the fixed row need NO de-identification: the proposed blind text is identical to
-- canonical in every case. On downtown that is a consequence of the fix — every incumbency vector
-- lived in the record half the trim now drops.
--
-- All three attach to the questions created in 1626 and are inserted as DRAFTS. Selecting the live
-- quote stays a human step.
--
-- Bass's Compass value on economic-development is 3 ("targeted incentives for specific industries
-- with community benefit agreements"); the editor notes state how each quote sits against it.
--
-- HOUSE-CAP NOTE: this leaves Bass with 4 economic-development drafts, over the ≤2 per
-- (politician, topic) house cap. The cap predates the question model. This topic now legitimately
-- carries TWO questions, so 2 drafts per question is the sensible reading and the cap should
-- become per (politician, question). Flagged rather than silently exceeded.

BEGIN;

-- 1. Fix the trim -------------------------------------------------------------------------------
UPDATE essentials.quotes SET
    quote_text = '…we have to deal with the street homelessness that is there. There needs to be massive intervention there. And then, of course, there is the convention center. And the convention center is a long-term investment that we have to make in our city because the more people you have downtown, whether it''s a convention or people coming downtown for concerts, is the way to make the city more safe and downtown more safe.',
    deidentified_text = '…we have to deal with the street homelessness that is there. There needs to be massive intervention there. And then, of course, there is the convention center. And the convention center is a long-term investment that we have to make in our city because the more people you have downtown, whether it''s a convention or people coming downtown for concerts, is the way to make the city more safe and downtown more safe.',
    editor_note = 'Selected because it is the only forward-looking part of her downtown answer: the earlier half recites what she has already done, which is record rather than a position. Trimmed to the contiguous run beginning "we have to deal with…" — the leading ellipsis marks the cut of "That is why", which pointed back at that record. Treating the convention center as a long-term investment the city must make, alongside intervention on street homelessness, sits with her Compass position of targeted public investment in specific sectors rather than broad incentives.',
    question_id = (SELECT id FROM essentials.readrank_questions
                    WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
                      AND question_text = 'How should Los Angeles respond to the decline of its downtown core?')
  WHERE id = 'b2d1f06d-d6c2-4f6b-9b20-cba5886ba953';

-- 2. Film / TV — TheWrap, 2026-05-20 (recommended primary) ---------------------------------------
INSERT INTO essentials.quotes
  (id, politician_id, topic_key, quote_text, deidentified_text, source_name, source_url,
   editor_note, readrank_selected, question_id)
VALUES
  (gen_random_uuid(),
   '21c9e711-fb18-4afb-884f-08acd2b598ba',
   'economic-development',
   'I''m open to looking at any special condition. There''s a lot of stuff in the city that happens because it''s always happened for no particular reason, or maybe it made sense 25 years ago, and makes no sense right now. Unfortunately, those things kind of have to come up, as opposed to there''s some magic list somewhere that I could just say I''m eliminating all these things. I''m open to eliminating or changing or waiving whatever is in the way.',
   'I''m open to looking at any special condition. There''s a lot of stuff in the city that happens because it''s always happened for no particular reason, or maybe it made sense 25 years ago, and makes no sense right now. Unfortunately, those things kind of have to come up, as opposed to there''s some magic list somewhere that I could just say I''m eliminating all these things. I''m open to eliminating or changing or waiving whatever is in the way.',
   'TheWrap',
   'https://www.thewrap.com/media-platforms/politics/karen-bass-reelection-interview-la-film-production/',
   'Selected because she was asked directly whether she would wipe the slate clean on city red tape for filming, and this is her whole answer — verbatim, with no edits and no record in it. It carries a real mechanism rather than a goal: she declines wholesale elimination in favour of removing obstacles case by case as they surface. That preference for targeted, sector-specific intervention over a blanket approach matches her Compass position on economic development.',
   false,
   (SELECT id FROM essentials.readrank_questions
     WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
       AND question_text = 'What should Los Angeles do to keep film and television production from leaving?')),

-- 3. Film / TV — The Hollywood Reporter, 2026-05-22 (alternate) -----------------------------------
  (gen_random_uuid(),
   '21c9e711-fb18-4afb-884f-08acd2b598ba',
   'economic-development',
   'To me it''s important to address it on all levels. So locally continuing to look for ways to cut the costs for production and to make it easier to film, to produce here. And part of that is eliminating the red tape.',
   'To me it''s important to address it on all levels. So locally continuing to look for ways to cut the costs for production and to make it easier to film, to produce here. And part of that is eliminating the red tape.',
   'The Hollywood Reporter',
   'https://www.hollywoodreporter.com/news/politics-news/l-a-mayor-karen-bass-interview-runaway-production-1236603948/',
   'Selected as the alternate to the TheWrap answer: she was asked what her plan is for runaway production and answered on the city''s own levers — cutting production costs and removing red tape. Trimmed at a sentence boundary before "So we''ve already done a lot of that", which turns to record and states no further position. Locating the city''s role in cost and permitting rather than in broad subsidy is consistent with her Compass position of targeted sector support.',
   false,
   (SELECT id FROM essentials.readrank_questions
     WHERE race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
       AND question_text = 'What should Los Angeles do to keep film and television production from leaving?'));

-- Guards ----------------------------------------------------------------------------------------
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM essentials.quotes q
    JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = '9e888818-c50b-4c61-a106-a0839ff2479d' AND rq.origin = 'moderator'
     AND q.politician_id = '21c9e711-fb18-4afb-884f-08acd2b598ba';
  IF n <> 3 THEN
    RAISE EXCEPTION 'Aborting: expected 3 Bass quotes on the two new questions, found %.', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.quotes
   WHERE id = 'b2d1f06d-d6c2-4f6b-9b20-cba5886ba953'
     AND quote_text LIKE '%massive intervention%'
     AND quote_text NOT LIKE '%adaptive reuse%';
  IF n <> 1 THEN
    RAISE EXCEPTION 'Aborting: the downtown trim did not apply as expected.';
  END IF;

  SELECT count(*) INTO n FROM essentials.quotes
   WHERE politician_id = '21c9e711-fb18-4afb-884f-08acd2b598ba'
     AND topic_key = 'economic-development' AND readrank_selected;
  IF n <> 0 THEN
    RAISE EXCEPTION 'Aborting: these are drafts; none should be live. Found % live.', n;
  END IF;
END $$;

COMMIT;
