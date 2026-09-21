-- 1888_tx_deportation_instrument_blanks_season2.sql
-- Blank 9 Texas Deportation Priorities chairs in Season 2. They are seated in Season 1 on bills that
-- are not about removal. 9 context rows + 9 answer rows (value 0) INSERTED. Nothing updated, nothing
-- deleted. SEASON 1 IS NOT TOUCHED.
--
-- 🔴 WHAT IS WRONG WITH THEM. Every one rests on some combination of four instruments, none of which
-- is a removal instrument:
--   * **SB 17 / HB 17 (89R)** — "the purchase of or acquisition of title to real property by certain
--     aliens or foreign entities". 🔴 **HB 17 was LEFT PENDING IN COMMITTEE on 2025-04-02 and never
--     passed** (author Hefner; verified against capitol.texas.gov BillLookup). The 89(1) and 89(2)
--     HB 17s are property-tax notice bills. **No HB 17 in the 89th Legislature is about ICE.**
--   * **SB 16 / HB 5337 (89R)** — proof of citizenship to REGISTER TO VOTE.
--   * **SB 1 (87th, 2nd C.S.)** — the omnibus election-security law.
--   * **SB 14 (89R)** — regulatory reform.
-- ...topped up with party, caucus membership, the region represented, or a committee chairmanship.
--
-- 🔑 THE CO-AUTHORSHIP CLAIMS ARE TRUE — the coauthor lists were checked. A bad characterisation is
-- not a false claim. The defect is inferring a removal chair from a property bill and a voter
-- registration bill. Three rows go further and call HB 17 an enforcement bill outright ("immigration
-- enforcement legislation", "strengthening ICE cooperation"), which it is not.
--
-- 🔴 TWO ROWS RECORD THE ABSENCE AND SEAT THE CHAIR ANYWAY. **Paul Dyson**: "did not author or
-- co-author any direct deportation enforcement bill (HB 5580, HB 1491)" and sits on a committee that
-- "handles criminal law and civil procedure, not specifically immigration enforcement bills" — then
-- chair 4. **Dennis Paul**: "not among the most vocal deportation advocates" — then chair 4.
-- **Phil King** is seated partly on chairing the Homeland and Border Security Select Committee;
-- a chairmanship is a role, not a position (the Leigh Davis / Derek Tran / Steven Johnson precedent).
--
-- ⚖ A BLANK, NOT A REVERSAL. value 0 says the question has not been answered on this person. It does
-- NOT assert the opposite chair. Several of these members may well hold the position they were seated
-- at; what is missing is evidence, not plausibility.
--
-- 🔑 WHY BLANK AND NOT DELETE. Deleting a Season 2 row does not blank anyone — the read falls back to
-- Season 1, so the inferred chair would stay visible. A blank is value 0, which CC_0057 made
-- expressible and PR #350/#354 made safe to read.
--
-- 🔑 EVERY BLANK CARRIES THE SOURCES IT EXAMINED, copied from its own Season 1 row. `EMPTY_SOURCES`
-- is zero-tolerance in `npm run check:stance-sources`, it is what turned master red after migration
-- 1886, and that gate **never runs on a pull request** (`if: github.event_name != 'pull_request'`) —
-- so it was run by hand before merge. Carrying the examined pages forward is also the argument: a
-- bill page for a property statute cannot state a deportation position.
--
-- ⚠ SEVEN OF THE SIXTEEN IN THIS COHORT ARE DELIBERATELY NOT HERE. **Janie Lopez** holds — her own
-- campaign platform calls for banning sanctuary cities, which is a real enforcement position on her
-- own say-so. **Don McLaughlin, Jared Patterson, Jeffrey Barry, Katrina Pierson, Lois Kolkhorst** and
-- **Mayes Middleton** each carry exactly one thin member-specific leg (a vague "voiced concern", a
-- Wikipedia characterisation, an unquoted campaign platform, an unsourced Trump-agenda association, a
-- $6bn border-security appropriation, an endorsement blurb about an unnamed bill). Those are too thin
-- for the chairs they hold — two of them are at chair 5 — but they are re-sourcing work, not blanks.
-- Blanking a correct stance is worse than leaving a weak one: the previous pass's first cut of 31 was
-- 39% wrong.
--
-- ⚠ NOT IN THIS MIGRATION: the sibling rows on **Immigration and Treatment of Immigrants**, which has
-- the same defect. That topic is **Season 1 only** — the corpus's largest orphan (1,678 stances, not
-- pinned in Season 2 or 3) — so `politician_answers_pin_fkey` forbids a Season 2 row for it. Those
-- ride on the Season 3 return/retire/merge decision, not on a blank.
--
-- 🔑 THE LADDER REVISION DIFFERS BETWEEN SEASONS AND IT DOES NOT MATTER HERE. Deportation Priorities
-- pins 673c3758 in Season 1 and 55c3167e in Season 2. A blank asserts no rung, so nothing is being
-- carried across a re-scale; the Season 2 pin is used only because the FK requires the season's own.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND politician_id IN ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','e1b7592e-6f9a-411a-96c3-19f1ccc23435','f920022b-4aa0-47ae-a5ae-c2edf3e17044','02288122-6afb-46c4-ae9f-a712152b1a73','933d4df6-d2ac-4d2c-82b9-a7676bf2c269','457620ac-d32b-434f-ad00-d860a5615e6d','1ea8b603-7f4d-40e5-b8c7-0ba19af17717');
  IF n <> 9 THEN
    RAISE EXCEPTION 'migration 1888: expected 9 Season 1 chairs for this cohort, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND politician_id IN ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','e1b7592e-6f9a-411a-96c3-19f1ccc23435','f920022b-4aa0-47ae-a5ae-c2edf3e17044','02288122-6afb-46c4-ae9f-a712152b1a73','933d4df6-d2ac-4d2c-82b9-a7676bf2c269','457620ac-d32b-434f-ad00-d860a5615e6d','1ea8b603-7f4d-40e5-b8c7-0ba19af17717');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1888: Season 2 already holds % row(s) for this cohort/topic', n;
  END IF;

  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND topic_revision_id='55c3167e-3ad8-425d-a699-b2e91552d912';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1888: Season 2 does not pin revision 55c3167e-3ad8-425d-a699-b2e91552d912 for Deportation Priorities';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, NULL, v.reasoning, v.sources
FROM (VALUES
  -- Cody Harris (S1 chair 4)
  ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Cody Harris at chair 4 on HB 17 (real-property purchases by certain foreign nationals) and HB 5337 (proof of citizenship to register to vote), followed by a bare assertion that he supports deporting people without legal status. Harris's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/history.aspx?LegSess=89R&Bill=HB17$r$]::text[]),
  -- Cody Vasut (S1 chair 4)
  ('2f3450e1-7b1c-4ca0-ae62-581bbc2cf606',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Cody Vasut at chair 4 on HB 17 (real-property purchases by certain foreign nationals) together with membership of the Texas Freedom Caucus. Vasut's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/history.aspx?LegSess=89R&Bill=HB17$r$]::text[]),
  -- Dennis Paul (S1 chair 4)
  ('a80b2deb-e005-4115-b5c0-2a050fa6a1ec',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Dennis Paul at chair 4 on SB 17 (the foreign-land ban) and SB 14 (regulatory reform), together with "Republican caucus enforcement posture" — while the row itself records that he is "not among the most vocal deportation advocates". Paul's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB17$r$]::text[]),
  -- Joanne Shofner (S1 chair 4)
  ('e1b7592e-6f9a-411a-96c3-19f1ccc23435',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Joanne Shofner at chair 4 on HB 17, described as "immigration enforcement", together with being "in line with [the] Abbott/Trump Republican primary profile". Shofner's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=HB17$r$]::text[]),
  -- John McQueeney (S1 chair 4)
  ('f920022b-4aa0-47ae-a5ae-c2edf3e17044',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats John McQueeney at chair 4 on HB 5337 (proof of citizenship to register to vote) and HB 17 (real-property purchases by certain foreign nationals), reasoning from a voter-registration bill to a removal chair. McQueeney's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=HB5337$r$,$r$https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=HB17$r$]::text[]),
  -- Lacey Hull (S1 chair 4)
  ('02288122-6afb-46c4-ae9f-a712152b1a73',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Lacey Hull at chair 4 on HB 17, described as "strengthening ICE cooperation", together with being "a Houston-area Republican who has aligned with conservative immigration enforcement". Hull's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=HB17$r$]::text[]),
  -- Paul Dyson (S1 chair 4)
  ('933d4df6-d2ac-4d2c-82b9-a7676bf2c269',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Paul Dyson at chair 4 on HB 17 and a Judiciary committee seat — after the row itself records that he "did not author or co-author any direct deportation enforcement bill" and that the committee "handles criminal law and civil procedure, not specifically immigration enforcement bills". Dyson's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/Members/MemberInfo.aspx?Leg=89&Chamber=H&Code=A4475$r$,$r$https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=HB17$r$]::text[]),
  -- Phil King (S1 chair 4)
  ('457620ac-d32b-434f-ad00-d860a5615e6d',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Phil King at chair 4 on SB 16 (proof of citizenship to register to vote) and SB 17 (the foreign-land ban), together with his chairmanship of the Homeland and Border Security Select Committee. King's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB16$r$,$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB17$r$,$r$https://senate.texas.gov/member.php?d=10$r$]::text[]),
  -- Robert Nichols (S1 chair 4)
  ('1ea8b603-7f4d-40e5-b8c7-0ba19af17717',$r$Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats Robert Nichols at chair 4 on SB 1 (87th Legislature, 2nd Called Session — election security), SB 16 (proof of citizenship to register to vote) and SB 17 (the foreign-land ban). Nichols's co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=872&Bill=SB1$r$,$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB16$r$,$r$https://senate.texas.gov/member.php?d=3$r$]::text[])
) AS v(pid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, NULL, 0
FROM (VALUES
  -- Cody Harris (S1 chair 4 -> blank)
  ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1'),
  -- Cody Vasut (S1 chair 4 -> blank)
  ('2f3450e1-7b1c-4ca0-ae62-581bbc2cf606'),
  -- Dennis Paul (S1 chair 4 -> blank)
  ('a80b2deb-e005-4115-b5c0-2a050fa6a1ec'),
  -- Joanne Shofner (S1 chair 4 -> blank)
  ('e1b7592e-6f9a-411a-96c3-19f1ccc23435'),
  -- John McQueeney (S1 chair 4 -> blank)
  ('f920022b-4aa0-47ae-a5ae-c2edf3e17044'),
  -- Lacey Hull (S1 chair 4 -> blank)
  ('02288122-6afb-46c4-ae9f-a712152b1a73'),
  -- Paul Dyson (S1 chair 4 -> blank)
  ('933d4df6-d2ac-4d2c-82b9-a7676bf2c269'),
  -- Phil King (S1 chair 4 -> blank)
  ('457620ac-d32b-434f-ad00-d860a5615e6d'),
  -- Robert Nichols (S1 chair 4 -> blank)
  ('1ea8b603-7f4d-40e5-b8c7-0ba19af17717')
) AS v(pid);

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND value=0
     AND politician_id IN ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','e1b7592e-6f9a-411a-96c3-19f1ccc23435','f920022b-4aa0-47ae-a5ae-c2edf3e17044','02288122-6afb-46c4-ae9f-a712152b1a73','933d4df6-d2ac-4d2c-82b9-a7676bf2c269','457620ac-d32b-434f-ad00-d860a5615e6d','1ea8b603-7f4d-40e5-b8c7-0ba19af17717');
  IF n <> 9 THEN
    RAISE EXCEPTION 'migration 1888: expected 9 Season 2 blanks, found %', n;
  END IF;

  -- every blank must carry a context row explaining it...
  SELECT count(*) INTO n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND a.value=0 AND c.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1888: % blank(s) carry no context row explaining the blank', n;
  END IF;

  -- ...and that context row must carry the sources it examined (EMPTY_SOURCES is zero-tolerance)
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND politician_id IN ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','e1b7592e-6f9a-411a-96c3-19f1ccc23435','f920022b-4aa0-47ae-a5ae-c2edf3e17044','02288122-6afb-46c4-ae9f-a712152b1a73','933d4df6-d2ac-4d2c-82b9-a7676bf2c269','457620ac-d32b-434f-ad00-d860a5615e6d','1ea8b603-7f4d-40e5-b8c7-0ba19af17717')
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1888: % new blank(s) shipped with empty sources', n;
  END IF;

  -- 🔴 Season 1 must be untouched: same count, and no Season 1 chair turned into a blank
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND politician_id IN ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1','2f3450e1-7b1c-4ca0-ae62-581bbc2cf606','a80b2deb-e005-4115-b5c0-2a050fa6a1ec','e1b7592e-6f9a-411a-96c3-19f1ccc23435','f920022b-4aa0-47ae-a5ae-c2edf3e17044','02288122-6afb-46c4-ae9f-a712152b1a73','933d4df6-d2ac-4d2c-82b9-a7676bf2c269','457620ac-d32b-434f-ad00-d860a5615e6d','1ea8b603-7f4d-40e5-b8c7-0ba19af17717') AND value <> 0;
  IF n <> 9 THEN
    RAISE EXCEPTION 'migration 1888: Season 1 chairs changed -- % still non-blank, expected 9', n;
  END IF;
END $$;

COMMIT;
