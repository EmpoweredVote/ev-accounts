-- CA_0355: correct two draft Season 3 voting-rights reasoning texts.
--
-- PR #1289 (fb658dacc) found that the PA House votes on SB 224 PN 1171 (2023-10-18) and SB 1 PN 385 (2023-05-22)
-- were on versions with no voter-ID text (House Journals 2023-10-18 pp. 1412-1417, 2023-05-03 p. 345), and that the
-- SB 1 Senate roll call (Senate Journal 2023-01-11 p. 91) prints Boscola as a Yea. Two seated rows repeat the old facts:
--   Mandy Steele (rung 2): said SB 224's "printed ID part (PN 1171)" cures a missing mail-ballot ID.
--   Lisa M. Boscola (rung 4): said "PA SB 1 (2023) nay".
-- Reasoning text only. Value, sources, evidence tier and review rows are unchanged; neither seat changes.
-- Guarded on the exact old text, so it is idempotent and refuses a row someone else has since edited.

CREATE TEMP TABLE reasoning_fix (politician_id uuid PRIMARY KEY, old_text text NOT NULL, new_text text NOT NULL) ON COMMIT DROP;
INSERT INTO reasoning_fix VALUES
  ('897344a1-148f-4d99-b09a-4cbed4582fca'::uuid, 'Her Yes on House amendment A02365 to SB 224 (2023-10-04, RCS No. 572), an amendment on the ID provision itself that at the polls accepts, alone, a non-photo document such as a utility bill or bank statement, or a signed affirmation, sits on rung 2, ''Do not require photo ID to cast a ballot. Accept other proof.'' Her Yes votes on SB 224 final passage (2023), SB 1 (2023) and HB 1396 (2025) are on broad, direction-only bills and cannot seat or supersede it; SB 224''s printed ID part (PN 1171) also only cures a missing mail-ballot ID. Her 2022 survey answer backs no-excuse mail voting and says nothing about ID, so it is off this question.', 'Her Yes on House amendment A02365 to SB 224 (2023-10-04, RCS No. 572), an amendment on the ID provision itself that at the polls accepts, alone, a non-photo document such as a utility bill or bank statement, or a signed affirmation, sits on rung 2, ''Do not require photo ID to cast a ballot. Accept other proof.'' Her Yes votes on SB 224 final passage (2023) and SB 1 (2023) were on versions with no voter-ID text, because the House removed it before those votes, and her HB 1396 (2025) votes are on a broad, direction-only bill, so none can seat or supersede it. Her 2022 survey answer backs no-excuse mail voting and says nothing about ID, so it is off this question.'),
  ('5160d735-3e19-45b2-a155-c11d6ce3b796'::uuid, 'Yea on Senate final passage of PA SB 735 (2021, PN 952), a single-subject joint resolution passed 30-20 (not lopsided). Its printed text requires a voter not voting in person to ''provide proof of a valid identification with his or her ballot'' and states no sworn path in place of the ID, which meets rung 4 branch (b) (a copy of ID with each mail ballot); the in-person ''valid identification'' is any government ID, not stated photo, so branch (a) is not met, and exceptions left to later law (''unless otherwise provided for by law'') stay at 4. Her other records are gated: PA HB 1300 (2021) nay, PA SB 1 (2023) nay and PA SB 106 (2021) yea are direction-only bills; her PA HB 934 (2011) nay is a No and seats nothing. Her 2012 statements (support deterring fraud; offered an amendment to delay the ID law) meet no rung, and a chair-shaped record wins over a statement. The mail-voting and 2026 joint statements are adjacent.', 'Yea on Senate final passage of PA SB 735 (2021, PN 952), a single-subject joint resolution passed 30-20 (not lopsided). Its printed text requires a voter not voting in person to ''provide proof of a valid identification with his or her ballot'' and states no sworn path in place of the ID, which meets rung 4 branch (b) (a copy of ID with each mail ballot); the in-person ''valid identification'' is any government ID, not stated photo, so branch (a) is not met, and exceptions left to later law (''unless otherwise provided for by law'') stay at 4. Her other records are gated: PA HB 1300 (2021) nay, PA SB 1 (2023) yea and PA SB 106 (2021) yea are direction-only bills; her PA HB 934 (2011) nay is a No and seats nothing. Her 2012 statements (support deterring fraud; offered an amendment to delay the ID law) meet no rung, and a chair-shaped record wins over a statement. The mail-voting and 2026 joint statements are adjacent.');

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context c JOIN reasoning_fix f USING (politician_id)
   WHERE c.season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND c.topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'
     AND c.topic_revision_id = '1ed871b0-fceb-4f8c-ab02-92ea1d6d3e4c' AND c.reasoning IN (f.old_text, f.new_text);
  IF n <> 2 THEN RAISE EXCEPTION 'pre-flight: expected 2 rows holding the old or new text, found %', n; END IF;
END $$;

UPDATE inform.politician_context c SET reasoning = f.new_text, updated_at = now()
  FROM reasoning_fix f
 WHERE c.politician_id = f.politician_id AND c.reasoning = f.old_text
   AND c.season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND c.topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

DO $$
DECLARE n int; v int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context c JOIN reasoning_fix f USING (politician_id)
   WHERE c.season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND c.topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'
     AND c.reasoning = f.new_text;
  IF n <> 2 THEN RAISE EXCEPTION 'post-verify: expected 2 corrected rows, found %', n; END IF;
  SELECT count(*) INTO v FROM inform.politician_answers a JOIN reasoning_fix f USING (politician_id)
   WHERE a.season_id = '7b3a066c-815d-43b2-a6a0-6a3029778075' AND a.topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'
     AND ((a.politician_id = '897344a1-148f-4d99-b09a-4cbed4582fca' AND a.value = 2) OR (a.politician_id = '5160d735-3e19-45b2-a155-c11d6ce3b796' AND a.value = 4));
  IF v <> 2 THEN RAISE EXCEPTION 'post-verify: seats moved (expected Steele 2, Boscola 4), found % matching', v; END IF;
END $$;
