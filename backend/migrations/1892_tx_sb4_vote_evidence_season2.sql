-- 1892_tx_sb4_vote_evidence_season2.sql
-- Put 6 Texas Deportation Priorities rows onto recorded-vote evidence in Season 2. 6 context rows and
-- 6 answer rows UPDATED in the OPEN season. Nothing inserted, nothing deleted. SEASON 1 IS NOT
-- TOUCHED. **2 of the 6 move from blank (value 0) to chair 4.** Dyson, Nichols and Shofner unchanged.
--
-- 🔴🔴 WHY THIS EXISTS: MIGRATION 1890'S SWEEP HAD A SCOPE ERROR. It swept the filed records of all
-- nine members blanked by migration 1888 -- but **only for the 89th Legislature**. The Texas removal
-- statute is **SB 4 of the 88th Legislature's FOURTH CALLED SESSION**:
--   "prohibitions on the illegal entry into or illegal presence in this state by a person who is an
--    alien, the enforcement of those prohibitions and certain related orders ... and **authorizing or
--    requiring under certain circumstances THE REMOVAL of persons who violate those prohibitions**;
--    creating criminal offenses." -- signed 2023-12-18, effective 2024-03-05.
-- It is already in this audit's SOUND set. One more session would have found it. ▶ **Sweep every
-- session a member actually served, not the current one.**
--
-- ✅ THE RECORDED FLOOR VOTES -- the strongest evidence anywhere in this audit, and the reason two
-- blanks are wrong:
--   * **HOUSE, Record 35, 2023-11-14, passage to third reading: 83 ayes / 60 nays.** Aye: **Hull**,
--     **Cody Harris**, **Dennis Paul**, **Cody Vasut**.
--   * **SENATE, 2023-11-09, third reading and final passage: 17 ayes / 11 nays.** Aye: **Phil King**.
--   🔑 Both journals were parsed with pypdf and each parse **recovered the journal's own stated
--   totals exactly** (83/60; 17/11 with 3 absent-excused). That match is the check that the correct
--   vote was read -- a first attempt at the Senate page grabbed an **18/10** tally belonging to a
--   DIFFERENT bill printed on the same page. Anchor on the bill's own third-reading heading.
--   🔑 The House Journal never spells either Harris out, only "Harris, C.J." and "Harris, C.E."
--   (Cody Harris and Caroline Harris Davila). **BOTH voted aye**, so the attribution to Cody Harris
--   holds whichever initial is his -- the collision did not have to be resolved.
--
-- 🔴 **LACEY HULL and PHIL KING WERE BLANKED BY MIGRATION 1888 AND SHOULD NOT HAVE BEEN.** Both
-- voted for the enacted removal statute. The blanks were honest given what had been examined -- they
-- said so, and said the rows were re-researchable -- but they were wrong, and this corrects them.
-- ⚖ **King's row deliberately does NOT restore his original reasoning**, which rested on his
-- chairing a committee on homeland and border security. A chairmanship is a role, not a position; it
-- is not cited here. A recorded vote is.
--
-- ✅ FOUR ROWS KEEP CHAIR 4 BUT MOVE OFF DEAD BILLS:
--   * **John McQueeney** -> **his own words, twice.** "We must also continue to give our Judges
--     greater authority to deport illegal aliens" (Texas Scorecard, 2024-05-20) and "working with the
--     federal government to deport criminal illegal aliens" (Fort Worth Report questionnaire,
--     2026-02-17). ⚠ He took office in 2025, so SB 4 says nothing about him.
--   * **Cody Harris**, **Dennis Paul**, **Cody Vasut** -> from coauthoring bills that DIED in the
--     89th to a recorded vote on an ENACTED statute. Paul and Vasut are also on its cosponsor list.
--     Vasut advertises it on his own campaign biography.
--
-- ✅ ASSERTED UNCHANGED, so the shape of this edit is checkable from the file:
--   * **Paul Dyson** stays BLANK -- 93 filed bills with nothing about removal, a statement hunt that
--     found nothing, and he took office in 2025 so SB 4 does not reach him. Best-evidenced blank here.
--   * **Robert Nichols** stays BLANK. 🔴🔴 He was **ABSENT-EXCUSED** on SB 4 -- the Senate Journal
--     records that he "was granted leave of absence for today on account of family business."
--     **AN EXCUSED ABSENCE IS NOT A POSITION AND IS NOT CITED AS ONE.** His blank rests on the
--     absence of evidence, never on the absence of a vote; treating a missing vote as evidence is
--     precisely the load-bearing-absence defect this whole audit exists to remove.
--   * **Joanne Shofner** stays at chair 4 on HB 2390. "Deport" appears zero times on her entire
--     Ballotpedia page including her own candidate-written survey, and she took office in 2025.
--
-- ⚠ ONE SOURCE NOT READ: theeagle.com's "Meet the Candidate" questionnaire for Dyson returned
-- HTTP 429. It is the one unexamined item across the nine.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  -- the two being seated must still be blank, in both value and prose
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND a.value=0
     AND c.reasoning LIKE 'Blank in Season 2%'
     AND a.politician_id IN ('02288122-6afb-46c4-ae9f-a712152b1a73','457620ac-d32b-434f-ad00-d860a5615e6d');
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1892: expected 2 blank row(s) to seat, found % -- state has moved', n;
  END IF;

  -- the four being re-sourced must already be at chair 4
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND value=4
     AND politician_id IN ('f920022b-4aa0-47ae-a5ae-c2edf3e17044','c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606');
  IF n <> 4 THEN
    RAISE EXCEPTION 'migration 1892: expected 4 row(s) already at chair 4, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND value=4
     AND politician_id IN ('02288122-6afb-46c4-ae9f-a712152b1a73','457620ac-d32b-434f-ad00-d860a5615e6d','f920022b-4aa0-47ae-a5ae-c2edf3e17044','c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606','933d4df6-d2ac-4d2c-82b9-a7676bf2c269','1ea8b603-7f4d-40e5-b8c7-0ba19af17717','e1b7592e-6f9a-411a-96c3-19f1ccc23435');
  IF n <> 9 THEN
    RAISE EXCEPTION 'migration 1892: expected 9 Season 1 chair-4 rows, found %', n;
  END IF;
END $$;

UPDATE inform.politician_context c
   SET reasoning = v.reasoning, sources = v.sources, updated_at = now()
  FROM (VALUES
  -- Lacey Hull (S2 blank -> chair 4)
  ('02288122-6afb-46c4-ae9f-a712152b1a73',$r$Hull voted for SB 4 of the 88th Legislature’s fourth called session — "prohibitions on the illegal entry into or illegal presence in this state by a person who is an alien, the enforcement of those prohibitions and certain related orders ... and authorizing or requiring under certain circumstances the removal of persons who violate those prohibitions; creating criminal offenses." It was signed on 2023-12-18 with an effective date of 2024-03-05. The House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays (Record 35), and Hull is recorded in the aye column; she is also named in the House Journal among the members who seconded the motion for the previous question on its passage. Authorising state officers to arrest people for unlawful entry or presence and state judges to order their removal reaches undocumented people generally rather than only those convicted of serious violent crimes, and it sorts by immigration and criminal status rather than by how long someone has lived here — which places this at deporting everyone without legal status, starting with those who have criminal records. It is not a mass-deportation programme directed at long-settled families and workers, so it does not reach the top rung. This replaces a blank: the earlier research had examined only her filed bills from the following session, which are about real property, voter registration, bail and the border region, and had found nothing about removal. The recorded vote is the evidence that was missing.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4$r$,$r$https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A3975$r$]::text[]),
  -- Phil King (S2 blank -> chair 4)
  ('457620ac-d32b-434f-ad00-d860a5615e6d',$r$King voted for SB 4 of the 88th Legislature’s fourth called session — "prohibitions on the illegal entry into or illegal presence in this state by a person who is an alien, the enforcement of those prohibitions and certain related orders ... and authorizing or requiring under certain circumstances the removal of persons who violate those prohibitions; creating criminal offenses." It was signed on 2023-12-18 with an effective date of 2024-03-05. The Senate read it a third time and passed it finally on 2023-11-09 by 17 ayes to 11 nays, and King is recorded in the aye column. Authorising state officers to arrest people for unlawful entry or presence and state judges to order their removal reaches undocumented people generally rather than only those convicted of serious violent crimes, and it sorts by immigration and criminal status rather than by how long someone has lived here — which places this at deporting everyone without legal status, starting with those who have criminal records. It is not a mass-deportation programme directed at long-settled families and workers, so it does not reach the top rung. This replaces a blank, and it deliberately does not restore the original reasoning, which rested on his chairing a committee on homeland and border security. A committee chairmanship is a role, not a position, and it is not cited here. The recorded vote is.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4$r$,$r$https://journals.senate.texas.gov/sjrnl/884/pdf/88S4SJ11-09-F.PDF$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A1345$r$]::text[]),
  -- John McQueeney (S2 chair 4 -> chair 4)
  ('f920022b-4aa0-47ae-a5ae-c2edf3e17044',$r$McQueeney has stated the position himself, twice. Asked what should be done about the southern border, he answered: "we must continue to pass and enforce laws like Senate Bill 4 which allows Texas law enforcement to arrest illegal immigrants. We must also continue to give our Judges greater authority to deport illegal aliens" (Texas Scorecard, 2024-05-20). Asked again two years later, he said Texas must take "decisive action to secure the border", including "working with the federal government to deport criminal illegal aliens" (Fort Worth Report candidate questionnaire, 2026-02-17). Endorsing broader judicial authority to deport people without legal status rules out the rungs limited to those convicted of serious violent crimes or to recent arrivals, and naming people with criminal records as the priority for federal cooperation is the sequencing this rung describes. He does not call for a mass-deportation programme reaching long-settled families and workers. He also coauthored HB 5580 in the following session, which would have required sheriff agreements with federal immigration authorities; it did not pass.$r$,ARRAY[$r$https://texasscorecard.com/local/runoff-preview-mcqueeney-and-bean-square-off-for-house-district-97/$r$,$r$https://fortworthreport.org/2026/02/16/john-mcqueeney-republican-candidate-for-texas-house-district-97/$r$,$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB5580$r$]::text[]),
  -- Cody Harris (S2 chair 4 -> chair 4)
  ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1',$r$Harris voted for SB 4 of the 88th Legislature’s fourth called session — "prohibitions on the illegal entry into or illegal presence in this state by a person who is an alien, the enforcement of those prohibitions and certain related orders ... and authorizing or requiring under certain circumstances the removal of persons who violate those prohibitions; creating criminal offenses." It was signed on 2023-12-18 with an effective date of 2024-03-05. The House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays (Record 35), and Harris is recorded in the aye column. Authorising state officers to arrest people for unlawful entry or presence and state judges to order their removal reaches undocumented people generally rather than only those convicted of serious violent crimes, and it sorts by immigration and criminal status rather than by how long someone has lived here — which places this at deporting everyone without legal status, starting with those who have criminal records. It is not a mass-deportation programme directed at long-settled families and workers, so it does not reach the top rung. In the following session he also coauthored HB 2361, which would have provided for agreements between local law enforcement agencies and federal immigration authorities, and HB 1832, which would have raised penalties for unlawful entry and reentry by people with prior criminal convictions; neither passed. The recorded vote on an enacted statute is the stronger evidence and is why this chair stands.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4$r$,$r$https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A3580$r$]::text[]),
  -- Dennis Paul (S2 chair 4 -> chair 4)
  ('a80b2deb-e005-4115-b5c0-2a050fa6a1ec',$r$Paul cosponsored and voted for SB 4 of the 88th Legislature’s fourth called session — "prohibitions on the illegal entry into or illegal presence in this state by a person who is an alien, the enforcement of those prohibitions and certain related orders ... and authorizing or requiring under certain circumstances the removal of persons who violate those prohibitions; creating criminal offenses." It was signed on 2023-12-18 with an effective date of 2024-03-05. He appears on the bill’s House cosponsor list, and when the House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays (Record 35) he is recorded in the aye column. Authorising state officers to arrest people for unlawful entry or presence and state judges to order their removal reaches undocumented people generally rather than only those convicted of serious violent crimes, and it sorts by immigration and criminal status rather than by how long someone has lived here — which places this at deporting everyone without legal status, starting with those who have criminal records. It is not a mass-deportation programme directed at long-settled families and workers, so it does not reach the top rung. In the following session he also coauthored HB 2361, on agreements between local law enforcement agencies and federal immigration authorities, which did not pass. Asked separately about immigration in a candidate questionnaire, his own answer was about stopping crossings and ending sanctuary cities rather than about removal, so this chair rests on the legislation he cosponsored and voted for.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4$r$,$r$https://capitol.texas.gov/BillLookup/Sponsors.aspx?LegSess=884&Bill=SB4$r$,$r$https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF$r$]::text[]),
  -- Cody Vasut (S2 chair 4 -> chair 4)
  ('2f3450e1-7b1c-4ca0-ae62-581bbc2cf606',$r$Vasut cosponsored and voted for SB 4 of the 88th Legislature’s fourth called session — "prohibitions on the illegal entry into or illegal presence in this state by a person who is an alien, the enforcement of those prohibitions and certain related orders ... and authorizing or requiring under certain circumstances the removal of persons who violate those prohibitions; creating criminal offenses." It was signed on 2023-12-18 with an effective date of 2024-03-05. He appears on the bill’s House cosponsor list, and when the House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays (Record 35) he is recorded in the aye column. He also lists it on his own campaign biography as an accomplishment, describing it as "the strongest border security legislation in the nation" and saying he "successfully defended" it "against points of order" — a procedural defence the House Journal is consistent with, since he is named among the members who seconded the motion for the previous question on its passage. Authorising state officers to arrest people for unlawful entry or presence and state judges to order their removal reaches undocumented people generally rather than only those convicted of serious violent crimes, and it sorts by immigration and criminal status rather than by how long someone has lived here — which places this at deporting everyone without legal status, starting with those who have criminal records. It is not a mass-deportation programme directed at long-settled families and workers, so it does not reach the top rung.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4$r$,$r$https://capitol.texas.gov/BillLookup/Sponsors.aspx?LegSess=884&Bill=SB4$r$,$r$https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF$r$,$r$https://www.votevasut.com/bio$r$]::text[])
) AS v(pid, reasoning, sources)
 WHERE c.politician_id = v.pid::uuid
   AND c.topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'
   AND c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

UPDATE inform.politician_answers a
   SET value = v.value, updated_at = now()
  FROM (VALUES
  -- Lacey Hull
  ('02288122-6afb-46c4-ae9f-a712152b1a73',4),
  -- Phil King
  ('457620ac-d32b-434f-ad00-d860a5615e6d',4),
  -- John McQueeney
  ('f920022b-4aa0-47ae-a5ae-c2edf3e17044',4),
  -- Cody Harris
  ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1',4),
  -- Dennis Paul
  ('a80b2deb-e005-4115-b5c0-2a050fa6a1ec',4),
  -- Cody Vasut
  ('2f3450e1-7b1c-4ca0-ae62-581bbc2cf606',4)
) AS v(pid, value)
 WHERE a.politician_id = v.pid::uuid
   AND a.topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'
   AND a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND value=4 AND politician_id IN ('02288122-6afb-46c4-ae9f-a712152b1a73','457620ac-d32b-434f-ad00-d860a5615e6d','f920022b-4aa0-47ae-a5ae-c2edf3e17044','c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606');
  IF n <> 6 THEN
    RAISE EXCEPTION 'migration 1892: expected 6 rows at chair 4, found %', n;
  END IF;

  -- no seated row may still be arguing that it is a blank
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id IN ('02288122-6afb-46c4-ae9f-a712152b1a73','457620ac-d32b-434f-ad00-d860a5615e6d','f920022b-4aa0-47ae-a5ae-c2edf3e17044','c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606')
     AND reasoning LIKE 'Blank in Season 2%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1892: % seated row(s) still carry blank prose', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id IN ('02288122-6afb-46c4-ae9f-a712152b1a73','457620ac-d32b-434f-ad00-d860a5615e6d','f920022b-4aa0-47ae-a5ae-c2edf3e17044','c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606')
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1892: % row(s) have empty sources', n;
  END IF;

  -- 🔴 Dyson and Nichols stay blank, prose intact
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND a.value=0
     AND c.reasoning LIKE 'Blank in Season 2%'
     AND a.politician_id IN ('933d4df6-d2ac-4d2c-82b9-a7676bf2c269','1ea8b603-7f4d-40e5-b8c7-0ba19af17717');
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1892: expected 2 row(s) still blank with blank prose, found %', n;
  END IF;

  -- 🔴 Shofner untouched at chair 4
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND value=4 AND politician_id IN ('e1b7592e-6f9a-411a-96c3-19f1ccc23435');
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1892: Shofner is no longer at chair 4';
  END IF;

  -- 🔴 Season 1 untouched
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND value=4
     AND politician_id IN ('02288122-6afb-46c4-ae9f-a712152b1a73','457620ac-d32b-434f-ad00-d860a5615e6d','f920022b-4aa0-47ae-a5ae-c2edf3e17044','c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606','933d4df6-d2ac-4d2c-82b9-a7676bf2c269','1ea8b603-7f4d-40e5-b8c7-0ba19af17717','e1b7592e-6f9a-411a-96c3-19f1ccc23435');
  IF n <> 9 THEN
    RAISE EXCEPTION 'migration 1892: Season 1 changed -- % of 9 still at chair 4', n;
  END IF;
END $$;

COMMIT;
