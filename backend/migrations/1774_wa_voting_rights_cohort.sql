-- 1774_wa_voting_rights_cohort.sql
-- 11 rows on `voting-rights` at chair 4, for the members who sponsored BOTH HB 1584 and HB 1585
-- (Marshall R-2 prime on both). Chosen as a House Republican instrument: after migration 1773 the 29
-- uncovered were 11 Senate R, 8 House D, 7 House R and 3 Senate D, and the Senate Republican pool had
-- just produced four duds and nine blanks.
--
-- ── why chair 4, and why it takes TWO instruments ────────────────────────────────────────────────
-- Chair 4 is "require photo ID for voting AND regularly update voter rolls to remove inactive
-- registrations" — a compound, and neither bill satisfies both halves alone:
--   · HB 1584 supplies the photo ID half. It ends vote by mail for nonabsentee voters and requires
--     valid photo identification to vote in person.
--   · HB 1585 supplies the roll-maintenance half, in its strongest form: every county auditor must
--     check every registered voter against department of licensing citizenship records, notice the
--     voter twice, and CANCEL the registration 14 days out if proof is not produced.
-- Same compound-chair pattern as residential-zoning chair 4 in migration 1769: instrument A and
-- instrument B each supply one named mechanism, and only members holding BOTH are seated.
--
-- ── chair 5 refuted on its own terms, which is the part to keep ──────────────────────────────────
-- Chair 5 — "mandate in-person voting with STRICT photo ID and eliminate mail-in voting EXCEPT FOR
-- MILITARY OVERSEAS" — is the obvious reading for a bill that abolishes vote by mail, and it fails on
-- two of its three limbs:
--   · HB 1584 §1 says the legislature intends to keep "providing ballot access to those who most need
--     it by allowing for limited absentee voting", and the act mails an absentee ballot to "each voter
--     who qualifies", including residents of health care facilities. That is broader than military and
--     overseas voters, so the third limb fails.
--   · The ID list it accepts includes STUDENT and EMPLOYER identification cards, and tribal cards
--     without an address or expiration date. That is a photo ID requirement, but not a "strict" one.
-- 🔑 So the cohort sits at chair 4 while holding a position on mail voting that chair 4 does not
-- mention at all. Under the rule set in migration 1771, that is incompleteness, not contradiction:
-- chair 4's two mechanisms are both things these members voted to require, and nothing in the record
-- cuts against either. Contrast migration 1773, where chair 3's own named mechanism was worked
-- against by the instrument and the operator blanked the rows.
-- 🔴 FOR THE LADDER OWNER: a bill ending vote by mail statewide lands at chair 4 because chair 5
-- bundles "strict" and "except for military overseas" into a single option. The tightening end of
-- this ladder cannot distinguish "photo ID and roll purges" from "abolish mail voting". Logged in
-- COMPASS-LADDER-TROUBLE-SPOTS.md.
--
-- ── the other three chairs ───────────────────────────────────────────────────────────────────────
--   · chair 1 (automatic registration, online voting) and chair 2 (expand early voting, mail-in for
--     all without excuse) are refuted in the opposite direction — HB 1584 repeals universal vote by
--     mail and HB 1585 cancels registrations;
--   · chair 3 ("standardize voter ID requirements while ENSURING FREE IDS are available to all
--     eligible citizens") is refuted by HB 1585's proof list — a United States passport, certificate
--     of naturalization, consular report of birth abroad, or certified birth certificate. Every one
--     costs money and the act funds none of them.
--
-- ── per-member screen: 2 flagged, both read, nobody moved ────────────────────────────────────────
--   · Marshall's other primary voting instrument IS HB 1585, which is the second instrument here.
--   · Eslick's HB 2726 authorizes a parks district sales tax "that can be imposed with voter
--     approval" — the screen fired on the word "voter". A tax bill, not a voting-rights instrument.
--     Sixth confirmed over-fire of a first-cut keyword in this sweep.
BEGIN;

CREATE TEMP TABLE vr_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e1538de2-4e22-44cc-a50f-02fe7e2e9f2e' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Carolyn Eslick already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e1538de2-4e22-44cc-a50f-02fe7e2e9f2e' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Carolyn Eslick already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4546a3b3-4544-43bf-bf0f-eb56871fa1a2' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Corry already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4546a3b3-4544-43bf-bf0f-eb56871fa1a2' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Corry already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a9a04d0e-04a6-46c2-b8ce-cebfdd272b19' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jenny Graham already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a9a04d0e-04a6-46c2-b8ce-cebfdd272b19' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jenny Graham already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0f598558-61ab-4010-a0fd-e7c54f688a1a' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim Walsh already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0f598558-61ab-4010-a0fd-e7c54f688a1a' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim Walsh already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5f02b7a6-a6a3-408f-8e9b-ea678c75b92d' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joel McEntire already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5f02b7a6-a6a3-408f-8e9b-ea678c75b92d' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joel McEntire already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ecee999d-6aa9-420c-8da0-249ea31d4078' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Kevin Waters already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='ecee999d-6aa9-420c-8da0-249ea31d4078' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Kevin Waters already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7db875e2-7a94-4676-bfef-fd6aec93b7c7' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Marshall already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7db875e2-7a94-4676-bfef-fd6aec93b7c7' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Marshall already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0e37790d-e8e6-411d-aecb-3fddb8c53a61' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Michael Keaton already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0e37790d-e8e6-411d-aecb-3fddb8c53a61' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Michael Keaton already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Volz already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Volz already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='78c2d2cf-5520-490b-a45f-348baad3c59e' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Stephanie Barnard already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='78c2d2cf-5520-490b-a45f-348baad3c59e' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Stephanie Barnard already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='6f2a7dc4-888d-49a0-be12-a7600d976c87' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Travis Couture already has a voting-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='6f2a7dc4-888d-49a0-be12-a7600d976c87' AND topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Travis Couture already has a voting-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND value=4;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: voting-rights chair 4 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND topic_key='voting-rights' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: voting-rights topic is not live/active'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('4546a3b3-4544-43bf-bf0f-eb56871fa1a2','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('0f598558-61ab-4010-a0fd-e7c54f688a1a','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('5f02b7a6-a6a3-408f-8e9b-ea678c75b92d','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('ecee999d-6aa9-420c-8da0-249ea31d4078','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('7db875e2-7a94-4676-bfef-fd6aec93b7c7','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Prime sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('0e37790d-e8e6-411d-aecb-3fddb8c53a61','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('78c2d2cf-5520-490b-a45f-348baad3c59e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']),
('6f2a7dc4-888d-49a0-be12-a7600d976c87','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
 $r$Co-sponsor of HB 1584, which would end vote by mail for nonabsentee voters and restore in-person voting at polling places and voting centers, requiring "valid photo identification, such as a driver's license, state identification card, student identification card, tribal identification card, or employer identification card" to vote in person; and of HB 1585, which would require every county auditor to check each registered voter's proof of citizenship against department of licensing records and to cancel the registration of any voter who has not demonstrated it 14 days before the general election.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('4546a3b3-4544-43bf-bf0f-eb56871fa1a2','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('0f598558-61ab-4010-a0fd-e7c54f688a1a','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('5f02b7a6-a6a3-408f-8e9b-ea678c75b92d','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('ecee999d-6aa9-420c-8da0-249ea31d4078','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('7db875e2-7a94-4676-bfef-fd6aec93b7c7','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('0e37790d-e8e6-411d-aecb-3fddb8c53a61','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('78c2d2cf-5520-490b-a45f-348baad3c59e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4),
('6f2a7dc4-888d-49a0-be12-a7600d976c87','d1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM vr_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 11 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +11', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 11 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +11', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int; c4 int; primes int;
BEGIN
  -- content: BOTH mechanisms of the compound chair must be present in the reasoning, plus both
  -- sources. A row citing only one instrument cannot support chair 4 and must fail here.
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND a.politician_id IN ('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','0f598558-61ab-4010-a0fd-e7c54f688a1a','5f02b7a6-a6a3-408f-8e9b-ea678c75b92d','ecee999d-6aa9-420c-8da0-249ea31d4078','7db875e2-7a94-4676-bfef-fd6aec93b7c7','0e37790d-e8e6-411d-aecb-3fddb8c53a61','0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','78c2d2cf-5520-490b-a45f-348baad3c59e','6f2a7dc4-888d-49a0-be12-a7600d976c87')
     AND (a.value <> 4
          OR c.reasoning !~ 'valid photo identification'
          OR c.reasoning !~ 'cancel the registration'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1584.pdf' = ANY(c.sources))
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1585.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % row(s) wrong chair, missing one of the two mechanisms, or missing an instrument', bad; END IF;

  SELECT count(*) INTO c4 FROM inform.politician_answers
   WHERE topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND value=4 AND politician_id IN ('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','0f598558-61ab-4010-a0fd-e7c54f688a1a','5f02b7a6-a6a3-408f-8e9b-ea678c75b92d','ecee999d-6aa9-420c-8da0-249ea31d4078','7db875e2-7a94-4676-bfef-fd6aec93b7c7','0e37790d-e8e6-411d-aecb-3fddb8c53a61','0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','78c2d2cf-5520-490b-a45f-348baad3c59e','6f2a7dc4-888d-49a0-be12-a7600d976c87');
  IF c4 <> 11 THEN RAISE EXCEPTION 'guard 2: chair-4 count is %, expected 11', c4; END IF;

  SELECT count(*) INTO primes FROM inform.politician_context
   WHERE topic_id='d1792200-1d3b-4955-a0b7-0e6980d7a7b2' AND politician_id IN ('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','0f598558-61ab-4010-a0fd-e7c54f688a1a','5f02b7a6-a6a3-408f-8e9b-ea678c75b92d','ecee999d-6aa9-420c-8da0-249ea31d4078','7db875e2-7a94-4676-bfef-fd6aec93b7c7','0e37790d-e8e6-411d-aecb-3fddb8c53a61','0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','78c2d2cf-5520-490b-a45f-348baad3c59e','6f2a7dc4-888d-49a0-be12-a7600d976c87') AND reasoning LIKE 'Prime sponsor of %';
  IF primes <> 1 THEN RAISE EXCEPTION 'guard 2: % prime-sponsor row(s), expected 1', primes; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'voting-rights: 11 at chair 4 from HB 1584 + HB 1585; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
