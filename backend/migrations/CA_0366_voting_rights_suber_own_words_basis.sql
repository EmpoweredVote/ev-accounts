-- CA_0366: move Benjamin Suber's draft Season 3 voting-rights seat onto the evidence it now rests on.
--
-- Ruling W4-R6 (Chris Andrews, 2026-11-06; .planning/.../stage5/remaining-states/rulings-w4.md): a Yes on Mississippi
-- SB 2576 (2024) reprints the photo-ID law and shows direction only. Suber's approved seat (rung 4, batch ms-01) rested
-- on that vote. His re-code (ms-02 follow-up, Opus) keeps rung 4 on his own words: his 2019 iVoterGuide answer
-- 'Strongly Disagree' to 'People should be able to vote without photo identification' (DH1). The batch writer could
-- not carry this: the verifier treats a same-value row as 'unchanged' and writes nothing, so he was held out of ms-02.
-- Own-words seats on voting-rights are approved like any other row since the topic's blind check passed (2026-10-31).
--
-- Changes: politician_context.reasoning (replaced) and .sources (iVoterGuide page added first); two verified snippets
-- from the iVoterGuide page added to politician_context_evidence (batch_id 'ca-0366'). politician_answers.value (4),
-- the three LegiScan evidence rows and topic_research_outcomes are unchanged.
-- Guarded on the exact old text, so it is idempotent and refuses a row someone else has since edited.
--
-- OLD VALUES (overwritten here):
--   reasoning: He voted Yes on Senate final passage of SB 2576 (2024-03-13, 40-10), a single-subject bill that requires 'current and valid photo identification' at the polls; a voter without it gets an affidavit ballot counted only if photo ID is shown within five days (a cure), with an exemption only for a named group (religious objection). That is rung 4: 'Require ID before a ballot counts: photo ID at the polls.' His HB 1510 (2022) and SB 2588 (2026) votes ask citizenship papers only of flagged applicants and meet no rung; his iVoterGuide answer ('Strongly Disagree' that people should be able to vote without photo ID) points the same way.
--   sources:   ["https://legiscan.com/MS/rollcall/HB1510/id/1180308","https://legiscan.com/MS/rollcall/SB2576/id/1408760","https://legiscan.com/MS/rollcall/SB2588/id/1667666"]

BEGIN;

DO $$
DECLARE n int; v int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND topic_revision_id = '1ed871b0-fceb-4f8c-ab02-92ea1d6d3e4c'
     AND reasoning IN ('He voted Yes on Senate final passage of SB 2576 (2024-03-13, 40-10), a single-subject bill that requires ''current and valid photo identification'' at the polls; a voter without it gets an affidavit ballot counted only if photo ID is shown within five days (a cure), with an exemption only for a named group (religious objection). That is rung 4: ''Require ID before a ballot counts: photo ID at the polls.'' His HB 1510 (2022) and SB 2588 (2026) votes ask citizenship papers only of flagged applicants and meet no rung; his iVoterGuide answer (''Strongly Disagree'' that people should be able to vote without photo ID) points the same way.', 'On his 2019 iVoterGuide questionnaire he answered ''Strongly Disagree'' to ''People should be able to vote without photo identification'', which the digest reads as rejecting voting without photo ID (DH1): ''Require ID before a ballot counts: photo ID at the polls'' (rung 4). His records do not conflict: his Yes on SB 2576 (2024) is a reprint of the photo-ID law that shows direction only (W4-R6), and his Yes votes on SB 2588 (2026) and HB 1510 (2022) are flagged-only citizenship bills that meet no rung.');
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected 1 context row holding the old or new text, found %', n; END IF;
  SELECT count(*) INTO v FROM inform.politician_answers WHERE politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND value = 4;
  IF v <> 1 THEN RAISE EXCEPTION 'pre-flight: expected his answer at rung 4, found % matching', v; END IF;
END $$;

UPDATE inform.politician_context
   SET reasoning = 'On his 2019 iVoterGuide questionnaire he answered ''Strongly Disagree'' to ''People should be able to vote without photo identification'', which the digest reads as rejecting voting without photo ID (DH1): ''Require ID before a ballot counts: photo ID at the polls'' (rung 4). His records do not conflict: his Yes on SB 2576 (2024) is a reprint of the photo-ID law that shows direction only (W4-R6), and his Yes votes on SB 2588 (2026) and HB 1510 (2022) are flagged-only citizenship bills that meet no rung.',
       sources = ARRAY['https://ivoterguide.com/candidate/44684/race/6982/election/716', 'https://legiscan.com/MS/rollcall/HB1510/id/1180308', 'https://legiscan.com/MS/rollcall/SB2576/id/1408760', 'https://legiscan.com/MS/rollcall/SB2588/id/1667666']::text[],
       updated_at = now()
 WHERE politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND reasoning = 'He voted Yes on Senate final passage of SB 2576 (2024-03-13, 40-10), a single-subject bill that requires ''current and valid photo identification'' at the polls; a voter without it gets an affidavit ballot counted only if photo ID is shown within five days (a cure), with an exemption only for a named group (religious objection). That is rung 4: ''Require ID before a ballot counts: photo ID at the polls.'' His HB 1510 (2022) and SB 2588 (2026) votes ask citizenship papers only of flagged applicants and meet no rung; his iVoterGuide answer (''Strongly Disagree'' that people should be able to vote without photo ID) points the same way.';

INSERT INTO inform.politician_context_evidence (politician_id, topic_id, season_id, source_url, snippet, snippet_index, verified_at, batch_id)
SELECT '50f3fe33-f53a-46e0-9533-eca6533b11a5', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', '7b3a066c-815d-43b2-a6a0-6a3029778075', 'https://ivoterguide.com/candidate/44684/race/6982/election/716', s.snippet, s.idx, now(), 'ca-0366'
  FROM (VALUES ('safety. Strongly Disagree OTHER IMPORTANT ISSUES People should be able to vote without photo identification. Strongly Disagree If you are not already receiving our updates, stay current with important election', 4), ('Dist. 8 candidate - Benjamin A. Suber English My Voter Guide Insights and Articles About Us Take Action Donate My Voter Guide Insights and Articles Take Action About Us Donate', 5)) AS s(snippet, idx)
 WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context_evidence e
                    WHERE e.politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND e.topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND e.season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND e.source_url = 'https://ivoterguide.com/candidate/44684/race/6982/election/716' AND e.snippet = s.snippet);

DO $$
DECLARE n int; v int; e int; l int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context WHERE politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075'
     AND reasoning = 'On his 2019 iVoterGuide questionnaire he answered ''Strongly Disagree'' to ''People should be able to vote without photo identification'', which the digest reads as rejecting voting without photo ID (DH1): ''Require ID before a ballot counts: photo ID at the polls'' (rung 4). His records do not conflict: his Yes on SB 2576 (2024) is a reprint of the photo-ID law that shows direction only (W4-R6), and his Yes votes on SB 2588 (2026) and HB 1510 (2022) are flagged-only citizenship bills that meet no rung.' AND sources = ARRAY['https://ivoterguide.com/candidate/44684/race/6982/election/716', 'https://legiscan.com/MS/rollcall/HB1510/id/1180308', 'https://legiscan.com/MS/rollcall/SB2576/id/1408760', 'https://legiscan.com/MS/rollcall/SB2588/id/1667666']::text[];
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: expected 1 corrected context row, found %', n; END IF;
  SELECT count(*) INTO v FROM inform.politician_answers WHERE politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND value = 4;
  IF v <> 1 THEN RAISE EXCEPTION 'post-verify: seat moved (expected rung 4), found % matching', v; END IF;
  SELECT count(*) INTO e FROM inform.politician_context_evidence WHERE politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND source_url = 'https://ivoterguide.com/candidate/44684/race/6982/election/716';
  IF e <> 2 THEN RAISE EXCEPTION 'post-verify: expected 2 iVoterGuide snippets, found %', e; END IF;
  SELECT count(*) INTO l FROM inform.politician_context_evidence WHERE politician_id = '50f3fe33-f53a-46e0-9533-eca6533b11a5' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND source_url LIKE 'https://legiscan.com/%';
  IF l <> 3 THEN RAISE EXCEPTION 'post-verify: expected the 3 LegiScan snippets untouched, found %', l; END IF;
END $$;

COMMIT;
