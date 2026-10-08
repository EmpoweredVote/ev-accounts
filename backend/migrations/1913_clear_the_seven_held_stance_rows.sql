-- 1913_clear_the_seven_held_stance_rows.sql
-- The seven rows that migrations 1909 (California) and 1911 (Virginia) HELD for the operator,
-- now cleared on the operator's instruction. Four re-seats, two carries, one blank.
--
-- A held row is one where the carry gate said: this chair was read against a SEASON 1 rung, and
-- the rung AT THAT NUMBER no longer says the same thing in Season 2. A citation repair may not
-- move a chair, so those rows were left alone and named. Clearing them means doing the thing a
-- repair is not allowed to do -- reading the evidence against the SEASON 2 ladder and seating it
-- where that ladder puts it, or blanking it when no rung on that ladder asks what the evidence
-- answers.
--
-- ══ THE SEVEN, AND WHAT READING SETTLED ══════════════════════════════════════════════════════
--   Amy J. Laufer      climate-change         3 -> 2   RE-SEAT   public investment, not permitting
--   David W. Marsden   climate-change         3 -> 2   RE-SEAT   a $20M/yr grant fund
--   Brian Gutierrez    economic-development   4 -> 2   RE-SEAT   local business, no incentives
--   Brian Gutierrez    homelessness-response  3 -> 2   RE-SEAT   demands MORE funding
--   Hugo Soto-Martinez homelessness-response  2 -> 2   CARRY     re-grounded on the funding axis
--   Raul Campillo      homelessness           4 -> 4   CARRY     the enacted text dissolved it
--   Saddam A. Salim    voting-rights          2 -> 0   BLANK     the rung changed AXIS
--
-- ══ 🔑 THE INSERTED-RUNG PROBE WAS RUN FIRST, AS THE RULE REQUIRES ════════════════════════════
-- A uniform shift across a topic would mean Season 2 INSERTED a rung and these numbers are a
-- renumbering rather than a chair move. Across all five topics touched here, every production
-- row holding a non-zero answer in BOTH seasons maps to the SAME number (climate-change 4->4 x11,
-- 5->5 x6, 1->1; economic-development 2->2 x5, 1->1; homelessness 2->2, 3->3; voting-rights
-- 4->4 x6). There is no insertion anywhere here: Season 2 rewrote the rung TEXT in place and
-- kept the numbering. So every value change below is a real chair move, made deliberately.
--
-- ══ 🔴 READING THE ENACTED TEXT DISSOLVED ONE HOLD AND CORRECTED THE ROW THAT MADE IT ═════════
-- Campillo was held because Season 1 rung 4 required jurisdictions "to maintain basic shelter
-- options" and Season 2 drops that clause -- the clause his evidence was said to turn on. His
-- evidence was a Wikipedia sentence saying the ordinance he voted for "allowed police to remove
-- homeless encampments when shelter beds were available". The ordinance itself (SDMC 63.0401-
-- 63.0406, O-21674) says something stronger: 63.0404(a) prohibits camping on ANY public
-- property, and 63.0404(b)-(c) ban it AT ALL TIMES REGARDLESS OF SHELTER in parks, open space,
-- waterways, within two blocks of a school or shelter, and at transit hubs. The shelter
-- condition in 63.0405(b) limits only CRIMINAL CITATIONS under subsection (a). The hold rested
-- on a clause that is not the hinge of the ordinance, and the chair stays at 4.
-- 🔑 This is exactly what "read the enacted text, not the news summary" is for.
--
-- ══ ⚠ WHAT THIS MIGRATION DOES NOT CLAIM ══════════════════════════════════════════════════════
-- Three of the four re-seats rest on a candidate's own survey or issue statement and one on a
-- bill a member chief-patroned. None rests on a roll call, and Marsden's SB 457 DID NOT PASS --
-- it was continued to 2025 in Finance and Appropriations (12-Y 3-N) and went no further. Chief
-- patronage establishes the member's own position, which is what a chair records; it does not
-- establish an enacted law, and the reasoning below says so on the row.
--
-- Season 1 is CLOSED and IMMUTABLE: every write here is forward, into Season 2. None of these
-- seven keys has a Season 2 answer or context row yet, so every write is an INSERT.
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local.

DO $pre$
DECLARE n integer;
BEGIN
  -- 1. all seven must still sit at the Season 1 chair they were read at, with no Season 2 row
  WITH k(pid, tid, s1val) AS (VALUES
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 4),
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 3),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 2),
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 4)
  )
  SELECT count(*) INTO n FROM k
    JOIN inform.politician_answers a1 ON a1.politician_id = k.pid AND a1.topic_id = k.tid
     AND a1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND a1.value = k.s1val
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a2
                      WHERE a2.politician_id = k.pid AND a2.topic_id = k.tid
                        AND a2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194')
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c2
                      WHERE c2.politician_id = k.pid AND c2.topic_id = k.tid
                        AND c2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194');
  IF n <> 7 THEN
    RAISE EXCEPTION 'migration 1913: expected 7 held rows at their Season 1 chair with no Season 2 row, found %', n;
  END IF;

  -- 2. the Season 2 rungs these chairs are being seated against must still say what was read.
  --    If the ladder moved under this file, stop rather than write a chair against a stale rung.
  WITH want(tkey, val, frag) AS (VALUES
    ('climate-change',        2, '%subsidies, tax credits, and public investment%'),
    ('climate-change',        3, '%cutting permitting red tape%'),
    ('homelessness-response', 2, '%increasing public funding%'),
    ('homelessness-response', 3, '%no major new spending%'),
    ('homelessness',          4, '%graduated warnings and civil penalties%'),
    ('economic-development',  2, '%small and local businesses%'),
    ('voting-rights',         2, '%non-photo identification%')
  )
  SELECT count(*) INTO n FROM want w
    JOIN inform.compass_topics t ON t.topic_key = w.tkey
    JOIN inform.season_questions q ON q.topic_id = t.id
     AND q.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = q.topic_revision_id
     AND r.value = w.val AND lower(r.text) LIKE lower(w.frag);
  IF n <> 7 THEN
    RAISE EXCEPTION 'migration 1913: % of 7 Season 2 rungs still read as this file assumes', n;
  END IF;
END
$pre$;


INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
VALUES
  -- Amy J. Laufer / climate-change  (RE-SEAT 3 -> 2)
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid,
     'Re-seated 2026-10-08 (migration 1913), clearing a row migration 1911 held for the operator. ⚠ THIS MOVES A CHAIR, 3 to 2, which a citation repair may never do; it is written as a re-seat and the move is recorded here so the next reader sees it rather than inferring it. WHY THE OLD NUMBER COULD NOT STAND: the chair of 3 was read against Season 1 rung 3, ''invest in clean energy while gradually reducing reliance on fossil fuels''. Season 2 rewrote the rung at that number into ''Speed up clean energy by cutting permitting red tape and upgrading the grid'' -- a deregulation rung, which is not what she said. Season 2 orders this ladder by MECHANISM, and the public-investment rung is 2. THE EVIDENCE, from her own 2019 Candidate Connection answers on the page already cited: ''Climate change is a fact, and we need to be doing all that we can to protect future generations. We need to be investing in renewable energy infrastructure both to protect the environment as well as to stimulate economic growth by creating new jobs.'' She asks for investment -- not mandates and firm deadlines (rung 1), not permitting reform (rung 3). ⚠ The 2019 survey is the only one she completed; the same page states she did not complete the 2023 or 2025 surveys, so there is no later filing to govern.',
     ARRAY['https://ballotpedia.org/Amy_Laufer#Campaign_themes']::text[]),
  -- David W. Marsden / climate-change  (RE-SEAT 3 -> 2)
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid,
     'Re-seated 2026-10-08 (migration 1913), clearing a row migration 1911 held for the operator. ⚠ THIS MOVES A CHAIR, 3 to 2. WHY: the chair of 3 was read against Season 1 rung 3, ''invest in clean energy while gradually reducing reliance on fossil fuels''; Season 2 rewrote that number into ''Speed up clean energy by cutting permitting red tape and upgrading the grid''. His record is spending, not deregulation, and the Season 2 spending rung is 2. THE EVIDENCE: the LIS member pages already cited list him as CHIEF PATRON of SB 457, ''Driving Decarbonization Program and Fund'', in both the 2024 and the 2025 session, and the bill summary now cited gives its substance -- grants covering 70 percent of the non-utility cost of installing an electric vehicle charging station in a historically economically disadvantaged or rural community and 50 percent elsewhere, capped at $20 million a fiscal year. A public grant fund for clean-energy infrastructure is Season 2 rung 2. ⚠ READ THE ENACTED TEXT: SB 457 DID NOT PASS. It was reported from Agriculture, Conservation and Natural Resources with a substitute (15-Y 0-N), rereferred to Finance and Appropriations, and continued to 2025 there (12-Y 3-N); the 2025 page shows no action after that. Chief patronage establishes HIS position, which is what a chair records -- it does not establish a law, and this row must not be read as one. ⚠ The prior reasoning also leaned on Boysko''s SB 409 as showing ''the Northern Virginia Democratic caucus orientation''. Another member''s bill proves nothing about this member; that inference is dropped.',
     ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S80C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S80C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB457']::text[]),
  -- Saddam Azlan Salim / voting-rights  (BLANK -- the rung changed axis)
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid,
     'Blanked 2026-10-08 (migration 1913), clearing a row migration 1911 held for the operator. 🔴 THE RUNG DID NOT CHANGE WORDING, IT CHANGED AXIS, and no Season 2 rung asks what this evidence answers. Season 1 rung 2 was ''expand early voting periods and make mail-in voting available to all voters without requiring an excuse''. Every Season 2 rung on this topic asks a single different question -- what IDENTIFICATION a voter must show -- running from ''Require no identification to vote'' through ''Require documentary proof of citizenship to register''. THE EVIDENCE was SB 315, ''Voter registration; registration of DMV customers, updates to existing registration'', which he chief-patroned in 2024 and again in 2025. That is about how a voter gets onto the roll, not about what a voter must produce in order to vote. Reading both member pages end to end, SB 315 is his only election bill in either session. Inferring an identification stance from a registration-access bill would be reading the chair off the member''s party rather than off his record, which is the defect this whole audit exists to remove. This is a blank, not a deletion, and not a judgement that he has no position -- re-research against an identification bill or a floor vote is owed.',
     ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S127C', 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S127C']::text[]),
  -- Brian Gutierrez / economic-development  (RE-SEAT 4 -> 2)
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid,
     'Re-seated 2026-10-08 (migration 1913), clearing a row migration 1909 held for the operator. ⚠ THIS MOVES A CHAIR, 4 to 2. WHY THE OLD NUMBER WAS AFFIRMATIVELY WRONG: Season 2 rung 4 reads ''Offer large tax breaks and infrastructure to attract major employers, but keep limits and pass on deals that cost too much'', and he proposes no incentive, no abatement and no recruitment of a major employer anywhere on the cited page. THE EVIDENCE, his own issue stance under ''Economy'' on the BallotReady profile already cited: ''I will work to create a streamlined process for new businesses to generate new revenue for our city. I will also work to promote our downtown area that includes Glendora Avenue and Plaza West Covina to create a vibrant, family friendly shopping experience.'' Easier permitting for new businesses plus promotion of the city''s existing commercial districts is Season 2 rung 2, ''Help small and local businesses grow, but don''t offer subsidies to attract large outside companies''. ⚠ Rung 2''s second clause is a negative he never states; it is the nearest rung on a single-choice ladder, not a quotation of him. ⚠ Rung 1 would have him attract business by investing in public services instead; his infrastructure answer is about street and sidewalk repair for safety, not about attracting employers.',
     ARRAY['https://www.ballotready.org/people/brian-gutierrez']::text[]),
  -- Brian Gutierrez / homelessness-response  (RE-SEAT 3 -> 2)
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e47ec98-46af-4e77-ae81-04d1311b4543'::uuid,
     'Re-seated 2026-10-08 (migration 1913), clearing a row migration 1909 held for the operator. ⚠ THIS MOVES A CHAIR, 3 to 2. 🔴 WHY IT HAD TO MOVE: Season 2 rewrote rung 3 into its opposite. Season 1 rung 3 was ''Invest in outreach, shelter, and mental health services while enforcing reasonable public space rules''; Season 2 rung 3 is ''Maintain current housing and service programs at today''s funding level, with no major new spending''. Leaving the chair at 3 would have asserted a status-quo position his own words contradict. Season 2 also rebuilt this ladder on a single FUNDING axis. THE EVIDENCE, his own issue stance on the BallotReady profile already cited: ''I will demand the county finally provide Measure H funding that will allow us to help our homeless, especially those in need of mental health services.'' Demanding more public money for services is rung 2, ''Expand housing and support services by increasing public funding''. ⚠ The same statement ends ''those who don''t want help will be asked to leave like the law allows'' -- an ENFORCEMENT position. The Season 2 homelessness-response ladder no longer asks about enforcement at all; that sentence belongs to the separate `homelessness` topic and does not qualify the funding reading. ⚠ Rung 1 would need him to be building a dedicated permanent funding stream; Measure H already exists and he is demanding his city''s share of it.',
     ARRAY['https://www.ballotready.org/people/brian-gutierrez']::text[]),
  -- Hugo Soto-Martinez / homelessness-response  (CARRY at 2, re-grounded)
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e47ec98-46af-4e77-ae81-04d1311b4543'::uuid,
     'Citation repaired 2026-10-08 (migration 1913), clearing a row migration 1909 held for the operator. THE CHAIR DOES NOT MOVE; the ground under it does. The hold was right on its own terms: Season 1 rung 2 was about enforcement SEQUENCING (''use enforcement only after services are offered'') and the row''s evidence -- removing the Echo Park Lake fence, opposing the 2021 sweep -- is entirely about enforcement, which the Season 2 rung at that number no longer asks about. Reading the same cited page for the FUNDING axis Season 2 does ask about lands on the same number. THE EVIDENCE, FROM THE PAGE ALREADY CITED: in August 2023 he voted against a four-year package of raises and bonuses for rank-and-file police officers, arguing it ''would pull money away from mental health clinicians, homeless outreach workers and many other city needs''; in May 2024 he dissented again from a budget that cut nearly every city department except the LAPD. Choosing homeless services over police pay in a budget fight is a position for increasing public funding of those services -- Season 2 rung 2, ''Expand housing and support services by increasing public funding''. ⚠ Rung 1 would require a dedicated, permanent funding stream; the cited page shows no such commitment. ⚠ The prior reasoning cited two council files (CF 23-1054, CF 23-0844) that do not appear on the cited page; rather than carry an uncited claim forward they are dropped.',
     ARRAY['https://en.wikipedia.org/wiki/Hugo_Soto-Martinez']::text[]),
  -- Raul Campillo / homelessness  (CARRY at 4 -- the enacted text dissolved the hold)
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid,
     'Citation repaired 2026-10-08 (migration 1913), clearing a row migration 1909 held for the operator. THE CHAIR DOES NOT MOVE. The hold reasoned that Season 1 rung 4 prohibited encampments ''while requiring jurisdictions to maintain basic shelter options'', that Season 2 rung 4 drops that clause, and that his evidence turned on exactly the dropped clause. 🔑 READING THE ENACTED TEXT DISSOLVED THE HOLD. The ordinance he voted for is San Diego Municipal Code sections 63.0401 through 63.0406, added by O-21674 and effective 2023-07-29. Section 63.0404(a) makes it unlawful to camp or maintain an encampment on ANY public property; 63.0404(b) and (c) make it unlawful AT ALL TIMES, REGARDLESS OF THE AVAILABILITY OF SHELTER, in parks, open space, waterways, within two blocks of a school or of a shelter, and at transit hubs; 63.0406 requires a written Notice of Clean-Up giving at least 24 hours before abatement. The shelter condition appears only in 63.0405(b), as a limit on CRIMINAL CITATIONS under subsection (a). So the clause Season 2 dropped is not the clause his vote turns on, and a prohibition on encampments on public property enforced through graduated notice is Season 2 rung 4. ⚠ WHAT THE OLD SUMMARY GOT WRONG: the previous reasoning described the ordinance as allowing removal ''when shelter beds are available'', which is the news-summary version and understates it -- precisely the failure the rule against seating from a summary exists to catch. ⚠ Rung 5, ''banning public camping and sleeping with criminal penalties'', overstates it the other way: 63.0405(b) forbids a criminal citation under subsection (a) between 9:00 p.m. and 5:30 a.m. or when no shelter is available to the person. His vote is the 5-4 of 2023-06-13; the Times of San Diego report now cited names him among the five.',
     ARRAY['https://en.wikipedia.org/wiki/Raul_Campillo', 'https://docs.sandiego.gov/municode/MuniCodeChapter06/Ch06Art03Division04.pdf', 'https://timesofsandiego.com/politics/2023/06/14/councils-ban-on-homeless-tent-encampments-draws-strong-reactions/']::text[]);


INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, value)
VALUES
  -- Amy J. Laufer / climate-change            RE-SEAT 3 -> 2
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 2),
  -- David W. Marsden / climate-change         RE-SEAT 3 -> 2
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid, 2),
  -- Saddam Azlan Salim / voting-rights        BLANK
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '2a18c152-67a0-4380-a381-cb8795110a7c'::uuid, 0),
  -- Brian Gutierrez / economic-development    RE-SEAT 4 -> 2
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, 'af855dba-96f3-4fa0-beb7-43c5edb3f499'::uuid, 2),
  -- Brian Gutierrez / homelessness-response   RE-SEAT 3 -> 2
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e47ec98-46af-4e77-ae81-04d1311b4543'::uuid, 2),
  -- Hugo Soto-Martinez / homelessness-response CARRY at 2
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '0e47ec98-46af-4e77-ae81-04d1311b4543'::uuid, 2),
  -- Raul Campillo / homelessness              CARRY at 4
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '6958fa99-e317-45d7-8076-d11a0a78c897'::uuid, 4);


DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND reasoning LIKE '%(migration 1913)%';
  IF n <> 7 THEN
    RAISE EXCEPTION 'migration 1913: wrote % reasoning rows, expected 7', n;
  END IF;

  -- every one of the seven must now sit at exactly the value this file intends
  WITH expected(pid, tid, val) AS (VALUES
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2),
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 0),
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 2),
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 2),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 2),
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 4)
  )
  SELECT count(*) INTO n FROM expected x
    JOIN inform.politician_answers a ON a.politician_id = x.pid AND a.topic_id = x.tid
     AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   WHERE a.value = x.val;
  IF n <> 7 THEN
    RAISE EXCEPTION 'migration 1913: % of 7 rows sit at the intended value', n;
  END IF;

  -- exactly one row may have been blanked, and it must be Salim''s
  SELECT count(*) INTO n FROM inform.politician_context c
    JOIN inform.politician_answers a ON a.politician_id = c.politician_id
     AND a.topic_id = c.topic_id AND a.season_id = c.season_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE '%(migration 1913)%' AND a.value = 0;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1913: % rows written at 0, expected exactly 1', n;
  END IF;

  -- Season 1 untouched: no Season 1 row names this migration, and all seven Season 1 chairs
  -- still stand where they stood. A re-seat writes FORWARD; it never edits the closed season.
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND reasoning LIKE '%migration 1913%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1913: % Season 1 rows altered, expected 0', n;
  END IF;

  WITH s1(pid, tid, val) AS (VALUES
    ('80b9fe48-9f8c-4585-91ab-4d0ed1bc2229'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('8db8b2e3-9160-4c14-9b47-707a7a27e4ab'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3),
    ('74ea1eb3-d4db-4dbe-882a-88ccecade1e5'::uuid, 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid, 2),
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid, 4),
    ('22fc2cdc-2f51-4d81-8814-4b54b2bc6582'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 3),
    ('6c795b3b-d59d-4667-b79e-8a2e27e0c283'::uuid, '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'::uuid, 2),
    ('84ba4a09-a90f-4ad4-9fa3-995961bd839c'::uuid, '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid, 4)
  )
  SELECT count(*) INTO n FROM s1
    JOIN inform.politician_answers a ON a.politician_id = s1.pid AND a.topic_id = s1.tid
     AND a.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
   WHERE a.value = s1.val;
  IF n <> 7 THEN
    RAISE EXCEPTION 'migration 1913: % of 7 Season 1 chairs are unchanged, expected 7', n;
  END IF;

  -- the work this file builds on must be intact
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (reasoning LIKE '%(migration 1908)%' OR reasoning LIKE '%(migration 1909)%');
  IF n <> 166 THEN
    RAISE EXCEPTION 'migration 1913: CA migrations 1908+1909 now show % rows, expected 166', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND reasoning LIKE '%(migration 1911)%';
  IF n <> 110 THEN
    RAISE EXCEPTION 'migration 1913: VA migration 1911 now shows % rows, expected 110', n;
  END IF;

  -- no row written here may be left without a citation
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND reasoning LIKE '%(migration 1913)%'
     AND coalesce(array_length(sources,1),0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1913: % rows written with no source, expected 0', n;
  END IF;
END
$post$;
