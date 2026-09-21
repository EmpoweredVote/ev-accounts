-- 1889_tx_deportation_resource_six_season2.sql
-- Re-source the six Texas Deportation Priorities rows that migration 1888 deliberately left standing.
-- 6 context rows + 6 answer rows INSERTED in Season 2. Nothing updated, nothing deleted.
-- SEASON 1 IS NOT TOUCHED.
--
-- Migration 1888 blanked 9 of the 16 rows in this cohort and left 7 alone: Janie Lopez held on her
-- own platform, and these six each carried exactly one thin member-specific leg -- a vague "voiced
-- concern", a Wikipedia characterisation, an unquoted campaign platform, an unsourced Trump-agenda
-- association, a $6bn border-security appropriation, and an endorsement blurb about an unnamed bill.
-- Too thin for the chairs they held, but re-sourcing work rather than blanks. This is that work.
--
-- 🔴 EVERY URL CITED HERE WAS ACTUALLY FETCHED (HTTP 200) AND THE QUOTED TEXT WAS READ OFF THE
-- FETCHED BODY. No citation is a reconstructed slug -- that is the failure mode this corpus has paid
-- for repeatedly. Two candidate sources were FOUND AND DELIBERATELY DISCARDED, which is the part
-- worth keeping:
--   * Pierson's 2016 Fox News "O'Reilly Factor" appearance, where she speaks as the Trump campaign's
--     national spokesperson describing HIS policy ("Mr. Trump wants to prioritize this process").
--     A spokesperson relaying a principal's platform ten years ago is not her own position, and
--     seating a chair on it would reproduce the exact defect this audit exists to correct.
--   * Everything said by **Tricia McLaughlin**, a federal homeland-security official who speaks
--     about deportations constantly and is NOT Don McLaughlin. An identity trap with a live payload.
--
-- ✅ TWO ROWS NOW REST ON THE MEMBER'S OWN WORDS -- which is what this ladder needs and almost never
-- gets:
--   * **Mayes Middleton (chair 5 CONFIRMED, and now evidenced)**: *"We have to deport all illegal
--     immigrants. Not some. All."* -- KLTV, 2026-02-01. "Not some. All" explicitly rejects any
--     prioritised or partial removal, and that is exactly what separates rung 5 from rung 4. His
--     chair was previously seated on a Trump endorsement blurb praising an unnamed border bill plus
--     his "most conservative" record. The chair was right; the reasoning was not.
--   * **Jared Patterson (chair 4 CONFIRMED)**: *"We passed the strongest border security bill in the
--     country, where law enforcement can now collect and deport illegal immigrants from across the
--     state..."* -- FOX 4 Dallas-Fort Worth, 2024-01-21.
--
-- ⚖ TWO ROWS KEEP A CHAIR THAT NOW RESTS ON THE MEMBER'S OWN FILED LEGISLATION, and each says so in
-- its own reasoning rather than implying a statement exists:
--   * **Lois Kolkhorst (chair 4, re-sourced)**: coauthor of **SB 8 (89R)**, signed on 2025-03-19 --
--     the sheriff/287(g) ICE-agreement mandate, **ENACTED, effective 2026-01-01**. This replaces the
--     "$6 billion for border security" figure sourced only to her own senate profile page. SB 8 is
--     the instrument the audit already recorded as genuinely topical and sound (87 rows rest on it).
--   * **Katrina Pierson (chair 5 REFUTED -> chair 4)**: joint author of **HB 1832 (89R)**. 🔑 READ
--     THE ANALYSIS, NOT THE CAPTION: the caption says "illegal entry into or illegal presence", but
--     the committee's own bill analysis says it "seeks to ... increase the penalties for illegal
--     entry and reentry **for those with prior criminal**" convictions. It is explicitly
--     criminal-record-prioritised, which is rung 4's logic and the direct opposite of rung 5's
--     "including long-settled families and workers". Also coauthor of HB 2361 (local law enforcement
--     / ICE agreements). Neither bill passed, and the reasoning says so.
--
-- 🔴 TWO ROWS BECOME DATED, SOURCED BLANKS (value 0). Both are evidence OF ABSENCE, not merely
-- absence of evidence -- the member answers an immigration question directly, or publishes a full
-- immigration platform, and neither reaches any rung:
--   * **Don McLaughlin**: asked point-blank in an Oct 2024 candidate questionnaire what he would do
--     on border security and immigration reform, he answered at length and never said how far
--     removal should go. "Those who break the law face the appropriate consequences" does not
--     distinguish rung 2 from rung 4. His 89R filing record holds no removal instrument.
--   * **Jeffrey Barry**: his own issues page treats immigration purely as cartels, fentanyl,
--     trafficking and more patrols. He has **no authored immigration bill at all** in the 89th and
--     only two immigration-adjacent coauthorships, on real property and voter registration.
--
-- 🔑 THE LADDER WAS READ FROM `compass_stance_revisions` VIA THIS ROW'S OWN PIN, never from the
-- frozen `compass_topics.title` / `compass_stances.text`. Season 1's pin (673c3758) and Season 2's
-- (55c3167e) carry semantically identical rungs here -- wording polish only -- so no rung is being
-- carried across a re-scale.
--
-- ⚠ SIDE FINDING, RECORDED SO IT IS NOT LOST: **Dennis Paul**, blanked by migration 1888, is a
-- coauthor of **HB 2361** -- genuinely topical conduct that his Season 1 row never cited and that
-- this pass only surfaced because he appears on Pierson's coauthor list. The blank stands (it records
-- that the evidence ON RECORD reached no rung, and is re-researchable), but Paul belongs on the
-- re-source queue rather than being treated as closed. Others among 1888's nine may be the same;
-- only a filed-record sweep would show it.
--
-- 🔴 `stance sourcing` NEVER RUNS ON A PULL REQUEST (`if: github.event_name != 'pull_request'`), so
-- `npm run check:stance-sources` was run BY HAND from `backend/` before merge. Every source here is
-- path-bearing, so PRIMARY_SITE_NO_PATH cannot grow; none is a Ballotpedia citation.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id IN ('92169386-c7ca-4edb-8446-56b565ad8c02','4f6da77d-f516-4873-b705-3adeb23c1ffb','2db78ab9-242e-46cd-ba95-5c504a2c8892','2d902ae4-2c04-4ecc-b9a4-55dccc848c70','481d7dae-0a6f-4e54-917c-72a2c6be6731','f6e50487-d839-479d-8efd-9937a09f9ab4');
  IF n <> 6 THEN
    RAISE EXCEPTION 'migration 1889: expected 6 Season 1 chairs for this cohort, found %', n;
  END IF;

  -- the Season 1 chairs this migration's prose describes must be the chairs actually on record
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='92169386-c7ca-4edb-8446-56b565ad8c02' AND value=5;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Mayes Middleton is no longer at Season 1 chair 5';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='4f6da77d-f516-4873-b705-3adeb23c1ffb' AND value=4;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Jared Patterson is no longer at Season 1 chair 4';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='2db78ab9-242e-46cd-ba95-5c504a2c8892' AND value=4;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Lois Kolkhorst is no longer at Season 1 chair 4';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='2d902ae4-2c04-4ecc-b9a4-55dccc848c70' AND value=5;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Katrina Pierson is no longer at Season 1 chair 5';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='481d7dae-0a6f-4e54-917c-72a2c6be6731' AND value=4;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Don McLaughlin is no longer at Season 1 chair 4';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='f6e50487-d839-479d-8efd-9937a09f9ab4' AND value=4;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Jeffrey Barry is no longer at Season 1 chair 4';
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id IN ('92169386-c7ca-4edb-8446-56b565ad8c02','4f6da77d-f516-4873-b705-3adeb23c1ffb','2db78ab9-242e-46cd-ba95-5c504a2c8892','2d902ae4-2c04-4ecc-b9a4-55dccc848c70','481d7dae-0a6f-4e54-917c-72a2c6be6731','f6e50487-d839-479d-8efd-9937a09f9ab4');
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1889: Season 2 already holds % row(s) for this cohort/topic', n;
  END IF;

  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND topic_revision_id='55c3167e-3ad8-425d-a699-b2e91552d912';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Season 2 does not pin revision 55c3167e-3ad8-425d-a699-b2e91552d912 for Deportation Priorities';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, NULL, v.reasoning, v.sources
FROM (VALUES
  -- Mayes Middleton (S1 chair 5 -> chair 5)
  ('92169386-c7ca-4edb-8446-56b565ad8c02',$r$Middleton stated the position himself, while outlining his priorities as a candidate for attorney general: "We have to deport all illegal immigrants. Not some. All." He named backing federal deportation efforts as his top priority, and pledged to use the state ban on sanctuary cities to sue local officials for civil and criminal penalties and removal from office if they obstruct federal immigration operations (KLTV, 2026-02-01). "Not some. All" rules out any partial or prioritised removal, and that is precisely what separates this rung from deporting everyone without legal status while starting with those who have criminal records. In the 89th Legislature he also coauthored SB 8, the enacted requirement that sheriffs in larger counties seek 287(g) agreements with Immigration and Customs Enforcement, and SJR 1, a proposed constitutional amendment denying bail to people without legal status charged with a felony.$r$,ARRAY[$r$https://www.kltv.com/2026/02/02/republican-candidate-attorney-general-pledges-sanctuary-city-crackdowns-transgender-sports-ban/$r$,$r$https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=SB8$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A1350$r$]::text[]),
  -- Jared Patterson (S1 chair 4 -> chair 4)
  ('4f6da77d-f516-4873-b705-3adeb23c1ffb',$r$Patterson described the state’s removal authority approvingly and in his own words, claiming credit for it: "We passed the strongest border security bill in the country, where law enforcement can now collect and deport illegal immigrants from across the state, along with $6.6 billion in funding for border security" (FOX 4 Dallas-Fort Worth, 2024-01-21). Endorsing the collection and removal of undocumented immigrants generally and statewide rules out the rungs limited to people convicted of serious violent crimes or to recent arrivals. He does not describe a mass programme reaching long-settled families and workers, so this sits at deporting everyone without legal status, starting with those who have criminal records, rather than at the top rung. His filing record in the 89th Legislature contains no removal instrument, so this chair rests on the statement.$r$,ARRAY[$r$https://www.fox4news.com/news/texas-the-issue-is-republican-in-fighting$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A3655$r$]::text[]),
  -- Lois Kolkhorst (S1 chair 4 -> chair 4)
  ('2db78ab9-242e-46cd-ba95-5c504a2c8892',$r$Kolkhorst coauthored SB 8 of the 89th Legislature, signing on 2025-03-19 — "agreements between certain sheriffs and the United States Immigration and Customs Enforcement to enforce federal immigration law and a grant program to cover the costs of implementing those agreements", which requires sheriffs in counties above 100,000 people to seek a 287(g) agreement. It was enacted, effective 2026-01-01. Committing county jails statewide to cooperate in federal removal reaches everyone booked into them rather than only people convicted of serious violent crimes, and it sorts by criminal contact rather than by how long someone has lived here — which places her at deporting everyone without legal status, starting with those who have criminal records. This chair rests on that instrument and not on a statement of her own: no first-person statement about how far removal should go was found. Her other immigration-adjacent bills that session concern real property, voter registration and state employment, none of which is a removal instrument.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/Authors.aspx?LegSess=89R&Bill=SB8$r$,$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB8$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A1105$r$]::text[]),
  -- Katrina Pierson (S1 chair 5 -> chair 4)
  ('2d902ae4-2c04-4ecc-b9a4-55dccc848c70',$r$Pierson is a listed joint author of HB 1832 of the 89th Legislature, which raises criminal penalties for illegal entry into and reentry to the state. The committee’s own bill analysis states that it "seeks to ... increase the penalties for illegal entry and reentry for those with prior criminal" convictions, enhancing the penalty for reentry after a removal that followed a felony offence against the person. She also coauthored HB 2361, which would have provided for agreements between local law enforcement agencies and Immigration and Customs Enforcement to enforce federal immigration law. Neither bill passed. Together these place her at the enforcement end of this question, and because both are keyed to criminal conduct rather than to length of residence, they support deporting everyone without legal status starting with those who have criminal records — not a mass programme reaching long-settled families and workers, which the explicit prioritisation in her own bill argues against. This chair rests on her filed legislation rather than on a statement of her own.$r$,ARRAY[$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1832$r$,$r$https://capitol.texas.gov/tlodocs/89R/analysis/html/HB01832H.htm$r$,$r$https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2361$r$]::text[]),
  -- Don McLaughlin (S1 chair 4 -> blank)
  ('481d7dae-0a6f-4e54-917c-72a2c6be6731',$r$Blank in Season 2 — researched on 2026-09-21, and nothing on record reaches any rung of this ladder. Asked directly in an October 2024 candidate questionnaire what policies he would advocate on border security and immigration reform, McLaughlin answered at length: prioritise strong border security, and "common-sense immigration reform that strengthens legal immigration, respects the rule of law, and protects American jobs", by "securing the border first, streamlining the legal immigration process for those who wish to contribute to our economy, and ensuring that those who break the law face the appropriate consequences." That answers the question put to him without saying how far removal should go: "appropriate consequences" does not distinguish deporting only people convicted of serious crimes from deporting everyone without legal status. His filing record in the 89th Legislature contains no removal instrument either — his immigration-related filings concern a border security commission, real property, voter registration, bail for people charged with felonies, and land use in border counties. The sources on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://www.lmtonline.com/local/article/election-q-a-texas-house-district-80-don-19829550.php$r$,$r$https://www.lmtonline.com/local/article/texas-house-district-80-r-don-mclaughlin-jr-18663878.php$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A4655$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A4655$r$]::text[]),
  -- Jeffrey Barry (S1 chair 4 -> blank)
  ('f6e50487-d839-479d-8efd-9937a09f9ab4',$r$Blank in Season 2 — researched on 2026-09-21, and nothing on record reaches any rung of this ladder. Barry’s own campaign platform treats immigration entirely as interdiction at the border. Its single immigration section reads: "What crosses our southern border doesn’t stay there. Cartels and smugglers are moving fentanyl and trafficking human beings straight into our communities", and promises to "make border security a top priority by increasing our border security resources and putting more law enforcement on the front lines." The independent record of his issue stances adds only expanding the wall, increasing border patrols and strengthening ports of entry. None of that is a position on removing people who already live here. His filing record in the 89th Legislature includes no authored immigration bill at all, and only two immigration-adjacent coauthorships, on real property and on voter registration. The sources on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.$r$,ARRAY[$r$https://www.votejeffbarry.com/issues$r$,$r$https://www.ballotready.org/people/jeffrey-barry$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A4405$r$,$r$https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A4405$r$]::text[])
) AS v(pid, reasoning, sources);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, '55c3167e-3ad8-425d-a699-b2e91552d912'::uuid, NULL, v.value
FROM (VALUES
  -- Mayes Middleton
  ('92169386-c7ca-4edb-8446-56b565ad8c02',5),
  -- Jared Patterson
  ('4f6da77d-f516-4873-b705-3adeb23c1ffb',4),
  -- Lois Kolkhorst
  ('2db78ab9-242e-46cd-ba95-5c504a2c8892',4),
  -- Katrina Pierson
  ('2d902ae4-2c04-4ecc-b9a4-55dccc848c70',4),
  -- Don McLaughlin
  ('481d7dae-0a6f-4e54-917c-72a2c6be6731',0),
  -- Jeffrey Barry
  ('f6e50487-d839-479d-8efd-9937a09f9ab4',0)
) AS v(pid, value);

DO $$
DECLARE n int;
BEGIN
  -- every row landed, with the chair intended
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='92169386-c7ca-4edb-8446-56b565ad8c02' AND value=5;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Mayes Middleton did not land at chair 5';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='4f6da77d-f516-4873-b705-3adeb23c1ffb' AND value=4;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Jared Patterson did not land at chair 4';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='2db78ab9-242e-46cd-ba95-5c504a2c8892' AND value=4;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Lois Kolkhorst did not land at chair 4';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='2d902ae4-2c04-4ecc-b9a4-55dccc848c70' AND value=4;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Katrina Pierson did not land at chair 4';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='481d7dae-0a6f-4e54-917c-72a2c6be6731' AND value=0;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Don McLaughlin did not land at blank';
  END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id='f6e50487-d839-479d-8efd-9937a09f9ab4' AND value=0;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1889: Jeffrey Barry did not land at blank';
  END IF;

  -- every one carries a context row...
  SELECT count(*) INTO n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND c.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1889: % Season 2 answer(s) carry no context row', n;
  END IF;

  -- ...and every context row carries sources (EMPTY_SOURCES is zero-tolerance and PR-invisible)
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id IN ('92169386-c7ca-4edb-8446-56b565ad8c02','4f6da77d-f516-4873-b705-3adeb23c1ffb','2db78ab9-242e-46cd-ba95-5c504a2c8892','2d902ae4-2c04-4ecc-b9a4-55dccc848c70','481d7dae-0a6f-4e54-917c-72a2c6be6731','f6e50487-d839-479d-8efd-9937a09f9ab4')
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1889: % new row(s) shipped with empty sources', n;
  END IF;

  -- 🔴 Season 1 must be untouched: every one of these still holds its original non-blank chair
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND topic_id='44905f3b-e105-4f6c-afc7-5d223813dbac' AND politician_id IN ('92169386-c7ca-4edb-8446-56b565ad8c02','4f6da77d-f516-4873-b705-3adeb23c1ffb','2db78ab9-242e-46cd-ba95-5c504a2c8892','2d902ae4-2c04-4ecc-b9a4-55dccc848c70','481d7dae-0a6f-4e54-917c-72a2c6be6731','f6e50487-d839-479d-8efd-9937a09f9ab4') AND value <> 0;
  IF n <> 6 THEN
    RAISE EXCEPTION 'migration 1889: Season 1 changed -- % still non-blank, expected 6', n;
  END IF;
END $$;

COMMIT;
