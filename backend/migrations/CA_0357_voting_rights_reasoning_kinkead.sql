-- CA_0357: correct Emily Kinkead's draft Season 3 voting-rights reasoning.
--
-- Same error as CA_0355 (Steele, Boscola): PR #1289 (fb658dacc) found that the PA House votes on SB 1 PN 385
-- (2023-05-22) and SB 224 PN 1171 (2023-10-18) were on versions with no voter-ID text (House Journals 2023-05-03
-- p. 345 and 2023-10-18 pp. 1412-1417). Her reasoning said both had ID parts. Her seat (rung 2) rests on her own
-- words (2022 survey, I-Q3) and does not change. Reasoning text only; value, sources, review rows unchanged.
-- Guarded on the exact old text, so it is idempotent and refuses a row someone else has since edited.

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND politician_id = '46f9ef45-e45d-405d-b8bb-2b68b33dbb15' AND topic_revision_id = '1ed871b0-fceb-4f8c-ab02-92ea1d6d3e4c'
     AND reasoning IN ('Own words, 2022 WESA survey: ''I am opposed to voter ID requirements'' … ''it creates barriers to voting with no evidence that it solves any real problem'' - voter-ID requirements in general called a barrier (I-Q3), rung 2 (''Do not require photo ID to cast a ballot''). Her Yes votes on PA SB 1 (2023), SB 224 (2023) and HB 1396 (2025) are on broad direction-only bills and cannot conflict (I-Q4); she voted No on HB 1300 (2021). She also voted for SB 1 (2023, PN 385) and SB 224 (2023, PN 1171), broad bills whose ID parts would require proof of identification with each mail ballot. Review flag: statement-out-of-cycle.', 'Own words, 2022 WESA survey: ''I am opposed to voter ID requirements'' … ''it creates barriers to voting with no evidence that it solves any real problem'' - voter-ID requirements in general called a barrier (I-Q3), rung 2 (''Do not require photo ID to cast a ballot''). Her Yes votes on PA SB 1 (2023), SB 224 (2023) and HB 1396 (2025) are on broad direction-only bills and cannot conflict (I-Q4); she voted No on HB 1300 (2021). Those SB 1 and SB 224 votes were on versions with no voter-ID text, because the House removed it before the votes, so they say nothing about ID. Review flag: statement-out-of-cycle.');
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected 1 row holding the old or new text, found %', n; END IF;
END $$;

UPDATE inform.politician_context SET reasoning = 'Own words, 2022 WESA survey: ''I am opposed to voter ID requirements'' … ''it creates barriers to voting with no evidence that it solves any real problem'' - voter-ID requirements in general called a barrier (I-Q3), rung 2 (''Do not require photo ID to cast a ballot''). Her Yes votes on PA SB 1 (2023), SB 224 (2023) and HB 1396 (2025) are on broad direction-only bills and cannot conflict (I-Q4); she voted No on HB 1300 (2021). Those SB 1 and SB 224 votes were on versions with no voter-ID text, because the House removed it before the votes, so they say nothing about ID. Review flag: statement-out-of-cycle.', updated_at = now()
 WHERE season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND politician_id = '46f9ef45-e45d-405d-b8bb-2b68b33dbb15' AND reasoning = 'Own words, 2022 WESA survey: ''I am opposed to voter ID requirements'' … ''it creates barriers to voting with no evidence that it solves any real problem'' - voter-ID requirements in general called a barrier (I-Q3), rung 2 (''Do not require photo ID to cast a ballot''). Her Yes votes on PA SB 1 (2023), SB 224 (2023) and HB 1396 (2025) are on broad direction-only bills and cannot conflict (I-Q4); she voted No on HB 1300 (2021). She also voted for SB 1 (2023, PN 385) and SB 224 (2023, PN 1171), broad bills whose ID parts would require proof of identification with each mail ballot. Review flag: statement-out-of-cycle.';

DO $$
DECLARE n int; v int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context WHERE season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND politician_id = '46f9ef45-e45d-405d-b8bb-2b68b33dbb15' AND reasoning = 'Own words, 2022 WESA survey: ''I am opposed to voter ID requirements'' … ''it creates barriers to voting with no evidence that it solves any real problem'' - voter-ID requirements in general called a barrier (I-Q3), rung 2 (''Do not require photo ID to cast a ballot''). Her Yes votes on PA SB 1 (2023), SB 224 (2023) and HB 1396 (2025) are on broad direction-only bills and cannot conflict (I-Q4); she voted No on HB 1300 (2021). Those SB 1 and SB 224 votes were on versions with no voter-ID text, because the House removed it before the votes, so they say nothing about ID. Review flag: statement-out-of-cycle.';
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: expected 1 corrected row, found %', n; END IF;
  SELECT count(*) INTO v FROM inform.politician_answers WHERE season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND politician_id = '46f9ef45-e45d-405d-b8bb-2b68b33dbb15' AND value = 2;
  IF v <> 1 THEN RAISE EXCEPTION 'post-verify: seat moved (expected rung 2), found % matching', v; END IF;
END $$;
