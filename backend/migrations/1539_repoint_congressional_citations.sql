-- 1539_repoint_congressional_citations.sql
--
-- Re-point 78 congressional citations to verified real targets. No chair, value or reasoning is
-- touched; only the `sources` array changes, one URL for one URL.
--   Rollback record: data/stance-retirement/2026-08-02-repoint-rollback.json
--   Review:          data/stance-retirement/2026-08-02-invented-domain-sweep.md
--   Targets:         data/stance-retirement/2026-08-02-repoint-targets.json
--
-- 🔴 REPAIR 1 — AN INVENTED HOSTNAME, NOT A DEAD LINK. `clark.house.gov` never existed: no DNS, and
-- Wayback has no capture of it across 9 probes and 3 query forms. Katherine Clark's real site is
-- katherineclark.house.gov, live and archived since 2014-01-25, and the cited PATH `/issues` returns
-- 200 there. So this is a composed hostname pointing at a page that genuinely exists elsewhere,
-- and it carried EVERY stance she has. The target was fetched and verified to name her.
--
-- ⚠ It was found only because a sweep control failed -- and the control was wrong, not the sweep:
-- `clark.house.gov` had been marked "expected ARCHIVED" from assumption, never verified.
--
-- REPAIR 2 — RETIRED BUT REAL. 8 subdomains stopped resolving because the member left the seat:
-- Schiff and Curtis to the Senate, Cardenas retired, Rubio to State, Vance to VP, Bass to LA Mayor,
-- Braun to Governor. The pages were real and Wayback holds them, so these are re-points to captures,
-- NOT retirements. Every capture was fetched with the `id_` modifier -- raw original bytes, no
-- injected Wayback banner, because the banner echoes the archived URL and "schiff.house.gov"
-- contains "schiff", which would have let the surname test pass on the toolbar instead of the page.
--
-- Verified to name the member: 31 of 31 URLs.

BEGIN;

-- Guard: the exact pre-state must still be in place, or these arrays no longer describe these rows.
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://bass.house.gov/media-center/press-releases/bass-votes-codify-supreme-court-marriage-equality-decision' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://bass.house.gov/media-center/press-releases/bass-vote…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises' = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1539: expected 2 rows citing https://schiff.house.gov/news/press-releases/rep-schiff-intr…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-hotels-to-housing-conversion-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/rep-schiff-intr…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-house-passage-of-the-build-back-better-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/congressman-sch…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://www.braun.senate.gov/news/press-releases/im-voting-no-senator-braun-on-84-billion-senate-bill-to-secure-other-countries-borders/' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://www.braun.senate.gov/news/press-releases/im-voting-n…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/issues/lgbtq-equality' = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1539: expected 2 rows citing https://schiff.house.gov/issues/lgbtq-equality…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act' = ANY(sources);
  IF v_n <> 3 THEN RAISE EXCEPTION '1539: expected 3 rows citing https://democracyreform-sarbanes.house.gov/newsroom/press-re…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/press-releases/c-rdenas-hayes-introduces-resolution-declaring-racism-public-health' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/media-center/press-releases/c-rde…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/environment-and-climate-change' = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION '1539: expected 2 rows citing https://cardenas.house.gov/issues/environment-and-climate-ch…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/6-encourage-clean-energy-alternatives-and-protect-our-environment' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/6-encourage-clean-energy-alternat…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/commitment-to-our-seniors' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/issues/commitment-to-our-seniors…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/immigration-and-diversity-' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/issues/immigration-and-diversity-…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/press-releases/c-rdenas-to-force-vote-on-comprehensive-immigration-reform-tomorrow' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/media-center/press-releases/c-rde…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/1-pass-responsible-comprehensive-immigration-reform' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/issues/1-pass-responsible-compreh…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/healthcare' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/issues/healthcare…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/press-releases/cardenas-votes-to-pass-historic-budget-resolution' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/media-center/press-releases/carde…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/in-the-news/univision-34_-al-punto-california-congressman-cardenas-on-the-inflation-reduction-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/media-center/in-the-news/univisio…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://cardenas.house.gov/…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-failure-to-pass-womens-health-protection-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/congressman-sch…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-supreme-court-decision-to-strike-down-roe-v-wade' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/congressman-sch…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/schiff-introduces-equal-health-care-for-all-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/schiff-introduc…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-landmark-bipartisan-bill-to-combat-fraudulent-ai-campaign-ads' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/rep-schiff-intr…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-statement-on-facebooks-deepfake-policy' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/rep-schiff-stat…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/schiff-demands-social-media-companies-take-action-in-advance-of-2024-election-to-address-spread-of-election-misinformation' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/schiff-demands-…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-passage-of-respect-for-marriage-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/congressman-sch…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-passage-of-respect-for-marriage-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://schiff.house.gov/news/press-releases/congressman-sch…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://curtis.house.gov/news/documentsingle.aspx?DocumentID=3344' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://curtis.house.gov/news/documentsingle.aspx?DocumentID…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://clark.house.gov/issues' = ANY(sources);
  IF v_n <> 43 THEN RAISE EXCEPTION '1539: expected 43 rows citing https://clark.house.gov/issues…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://www.vance.senate.gov/press-releases/vance-introduces-resolution-to-support-americas-law-enforcement-officers/' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://www.vance.senate.gov/press-releases/vance-introduces…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://www.rubio.senate.gov/public/index.cfm/2012/2/support-grows-for-religious-freedom-restoration-act-of-2012' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://www.rubio.senate.gov/public/index.cfm/2012/2/support…, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://rubio.senate.gov/public/index.cfm/2021/2/rubio-reintroduces-educational-opportunities-act' = ANY(sources);
  IF v_n <> 1 THEN RAISE EXCEPTION '1539: expected 1 rows citing https://rubio.senate.gov/public/index.cfm/2021/2/rubio-reint…, found %', v_n; END IF;
END $$;

-- Karen Ruth Bass / Same-Sex Marriage
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20221209120805/https://bass.house.gov/media-center/press-releases/bass-votes-codify-supreme-court-marriage-equality-decision']::text[]
 WHERE politician_id = '21c9e711-fb18-4afb-884f-08acd2b598ba' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
   AND sources = ARRAY['https://bass.house.gov/media-center/press-releases/bass-votes-codify-supreme-court-marriage-equality-decision']::text[];
-- Adam B. Schiff / Criminalization of Homelessness
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.adamschiff.com/plans/housing-and-homelessness-plan/', 'https://web.archive.org/web/20241207211842/https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises', 'https://web.archive.org/web/20241107103655/https://schiff.house.gov/news/press-releases/rep-schiff-introduces-hotels-to-housing-conversion-act']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a'
   AND sources = ARRAY['https://www.adamschiff.com/plans/housing-and-homelessness-plan/', 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises', 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-hotels-to-housing-conversion-act']::text[];
-- Adam B. Schiff / Childcare Affordability & Access
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.adamschiff.com/plans/affordability-agenda/', 'https://web.archive.org/web/20241107034430/https://schiff.house.gov/news/press-releases/congressman-schiff-on-house-passage-of-the-build-back-better-act', 'https://www.schiff.senate.gov/news/press-releases/news-sens-schiff-and-padilla-demand-trump-administration-reverse-funding-freeze-on-californias-critical-child-care-family-assistance-grant-programs/']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
   AND sources = ARRAY['https://www.adamschiff.com/plans/affordability-agenda/', 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-house-passage-of-the-build-back-better-act', 'https://www.schiff.senate.gov/news/press-releases/news-sens-schiff-and-padilla-demand-trump-administration-reverse-funding-freeze-on-californias-critical-child-care-family-assistance-grant-programs/']::text[];
-- Mike Braun / Ukraine - Russia Conflict
UPDATE inform.politician_context
   SET sources = ARRAY['https://thehill.com/homenews/senate/3495060-here-are-the-11-republican-senators-who-voted-against-the-ukraine-aid-bill/', 'https://web.archive.org/web/20241106232213/https://www.braun.senate.gov/news/press-releases/im-voting-no-senator-braun-on-84-billion-senate-bill-to-secure-other-countries-borders/']::text[]
 WHERE politician_id = 'a73e7a2a-48b0-4636-8fa4-5324ede65833' AND topic_id = '24e9212c-b011-422a-865c-093e35050901'
   AND sources = ARRAY['https://thehill.com/homenews/senate/3495060-here-are-the-11-republican-senators-who-voted-against-the-ukraine-aid-bill/', 'https://www.braun.senate.gov/news/press-releases/im-voting-no-senator-braun-on-84-billion-senate-bill-to-secure-other-countries-borders/']::text[];
-- Adam B. Schiff / Religious Freedom
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241106211925/https://schiff.house.gov/issues/lgbtq-equality', 'https://www.congress.gov/bill/117th-congress/house-bill/5', 'https://www.washingtonblade.com/2023/02/09/exclusive-adam-schiff-discusses-senate-run-and-new-bill-protecting-trans-youth/']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd'
   AND sources = ARRAY['https://schiff.house.gov/issues/lgbtq-equality', 'https://www.congress.gov/bill/117th-congress/house-bill/5', 'https://www.washingtonblade.com/2023/02/09/exclusive-adam-schiff-discusses-senate-run-and-new-bill-protecting-trans-youth/']::text[];
-- Tony Cardenas / Campaign Finance Reform
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/1', 'https://web.archive.org/web/20230624095732/https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act', 'https://ballotpedia.org/Tony_C%C3%A1rdenas']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'
   AND sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/1', 'https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act', 'https://ballotpedia.org/Tony_C%C3%A1rdenas']::text[];
-- Tony Cardenas / Civil Rights and Social Justice
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/40', 'https://web.archive.org/web/20241106220722/https://cardenas.house.gov/media-center/press-releases/c-rdenas-hayes-introduces-resolution-declaring-racism-public-health', 'https://www.govtrack.us/congress/bills/117/hr40']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'
   AND sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/40', 'https://cardenas.house.gov/media-center/press-releases/c-rdenas-hayes-introduces-resolution-declaring-racism-public-health', 'https://www.govtrack.us/congress/bills/117/hr40']::text[];
-- Tony Cardenas / Climate Change and Environmental Protection
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241128052016/https://cardenas.house.gov/issues/environment-and-climate-change', 'https://www.govtrack.us/congress/votes/117-2022/h420', 'https://gridalternatives.org/headquarters/news/congressman-c%C3%A1rdenas-returns-his-roots-passion-clean-energy']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'
   AND sources = ARRAY['https://cardenas.house.gov/issues/environment-and-climate-change', 'https://www.govtrack.us/congress/votes/117-2022/h420', 'https://gridalternatives.org/headquarters/news/congressman-c%C3%A1rdenas-returns-his-roots-passion-clean-energy']::text[];
-- Tony Cardenas / Fossil Fuel Policy
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241128052016/https://cardenas.house.gov/issues/environment-and-climate-change', 'https://web.archive.org/web/20201027200851/https://cardenas.house.gov/6-encourage-clean-energy-alternatives-and-protect-our-environment', 'https://scorecard.lcv.org/moc/tony-c%C3%A1rdenas']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'
   AND sources = ARRAY['https://cardenas.house.gov/issues/environment-and-climate-change', 'https://cardenas.house.gov/6-encourage-clean-energy-alternatives-and-protect-our-environment', 'https://scorecard.lcv.org/moc/tony-c%C3%A1rdenas']::text[];
-- Tony Cardenas / Medicare / Medicaid
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/118th-congress/house-bill/3421/cosponsors', 'https://www.congress.gov/bill/117th-congress/house-bill/1976/cosponsors', 'https://web.archive.org/web/20241128065753/https://cardenas.house.gov/issues/commitment-to-our-seniors']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
   AND sources = ARRAY['https://www.congress.gov/bill/118th-congress/house-bill/3421/cosponsors', 'https://www.congress.gov/bill/117th-congress/house-bill/1976/cosponsors', 'https://cardenas.house.gov/issues/commitment-to-our-seniors']::text[];
-- Tony Cardenas / State Redistricting and Gerrymandering
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/1', 'https://web.archive.org/web/20230624095732/https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act', 'https://ballotpedia.org/Tony_C%C3%A1rdenas']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
   AND sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/1', 'https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act', 'https://ballotpedia.org/Tony_C%C3%A1rdenas']::text[];
-- Tony Cardenas / Voting Rights and Electoral Integrity
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/1', 'https://web.archive.org/web/20230624095732/https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act', 'https://ballotpedia.org/Tony_C%C3%A1rdenas']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'
   AND sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/1', 'https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act', 'https://ballotpedia.org/Tony_C%C3%A1rdenas']::text[];
-- Tony Cardenas / Immigration and Treatment of Immigrants
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241128052017/https://cardenas.house.gov/issues/immigration-and-diversity-', 'https://web.archive.org/web/20190618141559/https://cardenas.house.gov/media-center/press-releases/c-rdenas-to-force-vote-on-comprehensive-immigration-reform-tomorrow']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'
   AND sources = ARRAY['https://cardenas.house.gov/issues/immigration-and-diversity-', 'https://cardenas.house.gov/media-center/press-releases/c-rdenas-to-force-vote-on-comprehensive-immigration-reform-tomorrow']::text[];
-- Tony Cardenas / Deportation Priorities
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20161207041404/https://cardenas.house.gov/issues/1-pass-responsible-comprehensive-immigration-reform', 'https://ontheissues.org/CA/Tony_Cardenas_Immigration.htm']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'
   AND sources = ARRAY['https://cardenas.house.gov/issues/1-pass-responsible-comprehensive-immigration-reform', 'https://ontheissues.org/CA/Tony_Cardenas_Immigration.htm']::text[];
-- Tony Cardenas / Healthcare Access
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/118th-congress/house-bill/3421/cosponsors', 'https://www.congress.gov/bill/117th-congress/house-bill/1976/cosponsors', 'https://web.archive.org/web/20241106202234/https://cardenas.house.gov/issues/healthcare']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
   AND sources = ARRAY['https://www.congress.gov/bill/118th-congress/house-bill/3421/cosponsors', 'https://www.congress.gov/bill/117th-congress/house-bill/1976/cosponsors', 'https://cardenas.house.gov/issues/healthcare']::text[];
-- Tony Cardenas / Taxation and Public Spending
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20250102063206/https://cardenas.house.gov/media-center/press-releases/cardenas-votes-to-pass-historic-budget-resolution', 'https://web.archive.org/web/20241217085821/https://cardenas.house.gov/media-center/in-the-news/univision-34_-al-punto-california-congressman-cardenas-on-the-inflation-reduction-act', 'https://www.govtrack.us/congress/members/tony_cardenas/412517']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
   AND sources = ARRAY['https://cardenas.house.gov/media-center/press-releases/cardenas-votes-to-pass-historic-budget-resolution', 'https://cardenas.house.gov/media-center/in-the-news/univision-34_-al-punto-california-congressman-cardenas-on-the-inflation-reduction-act', 'https://www.govtrack.us/congress/members/tony_cardenas/412517']::text[];
-- Tony Cardenas / Affordable Housing
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241227072544/https://cardenas.house.gov/', 'https://ballotpedia.org/Tony_Cardenas']::text[]
 WHERE politician_id = 'bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
   AND sources = ARRAY['https://cardenas.house.gov/', 'https://ballotpedia.org/Tony_Cardenas']::text[];
-- Adam B. Schiff / Reproductive Rights and Abortion Access
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241130120643/https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-failure-to-pass-womens-health-protection-act', 'https://web.archive.org/web/20241207205044/https://schiff.house.gov/news/press-releases/congressman-schiff-on-supreme-court-decision-to-strike-down-roe-v-wade', 'https://www.congress.gov/bill/118th-congress/house-bill/561']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND sources = ARRAY['https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-failure-to-pass-womens-health-protection-act', 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-supreme-court-decision-to-strike-down-roe-v-wade', 'https://www.congress.gov/bill/118th-congress/house-bill/561']::text[];
-- Adam B. Schiff / Civil Rights and Social Justice
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/5', 'https://web.archive.org/web/20241207200849/https://schiff.house.gov/news/press-releases/schiff-introduces-equal-health-care-for-all-act', 'https://web.archive.org/web/20241106211925/https://schiff.house.gov/issues/lgbtq-equality']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'
   AND sources = ARRAY['https://www.congress.gov/bill/117th-congress/house-bill/5', 'https://schiff.house.gov/news/press-releases/schiff-introduces-equal-health-care-for-all-act', 'https://schiff.house.gov/issues/lgbtq-equality']::text[];
-- Adam B. Schiff / Misinformation and the Role of Algorithms in Democracy
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241128045453/https://schiff.house.gov/news/press-releases/rep-schiff-introduces-landmark-bipartisan-bill-to-combat-fraudulent-ai-campaign-ads', 'https://web.archive.org/web/20241107080122/https://schiff.house.gov/news/press-releases/rep-schiff-statement-on-facebooks-deepfake-policy', 'https://web.archive.org/web/20241207211352/https://schiff.house.gov/news/press-releases/schiff-demands-social-media-companies-take-action-in-advance-of-2024-election-to-address-spread-of-election-misinformation']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'
   AND sources = ARRAY['https://schiff.house.gov/news/press-releases/rep-schiff-introduces-landmark-bipartisan-bill-to-combat-fraudulent-ai-campaign-ads', 'https://schiff.house.gov/news/press-releases/rep-schiff-statement-on-facebooks-deepfake-policy', 'https://schiff.house.gov/news/press-releases/schiff-demands-social-media-companies-take-action-in-advance-of-2024-election-to-address-spread-of-election-misinformation']::text[];
-- Adam B. Schiff / Same-Sex Marriage
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241106214001/https://schiff.house.gov/news/press-releases/congressman-schiff-on-passage-of-respect-for-marriage-act', 'https://www.congress.gov/bill/117th-congress/house-bill/8404', 'https://web.archive.org/web/20241106214007/https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-passage-of-respect-for-marriage-act']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
   AND sources = ARRAY['https://schiff.house.gov/news/press-releases/congressman-schiff-on-passage-of-respect-for-marriage-act', 'https://www.congress.gov/bill/117th-congress/house-bill/8404', 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-passage-of-respect-for-marriage-act']::text[];
-- Adam B. Schiff / Homelessness Response
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.adamschiff.com/plans/housing-and-homelessness-plan/', 'https://www.schiff.senate.gov/news/press-releases/news-sen-schiff-unveils-landmark-legislation-to-spur-new-housing-boom-address-housing-crisis/', 'https://web.archive.org/web/20241207211842/https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises']::text[]
 WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'
   AND sources = ARRAY['https://www.adamschiff.com/plans/housing-and-homelessness-plan/', 'https://www.schiff.senate.gov/news/press-releases/news-sen-schiff-unveils-landmark-legislation-to-spur-new-housing-boom-address-housing-crisis/', 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises']::text[];
-- John Curtis / Transgender Athletes
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241202174713/https://curtis.house.gov/news/documentsingle.aspx?DocumentID=3344', 'https://www.nbcnews.com/nbc-out/out-politics-and-policy/republicans-mountain-west-conference-transgender-volleyball-athlete-rcna181037', 'https://www.congress.gov/bill/119th-congress/senate-bill/9']::text[]
 WHERE politician_id = 'b87583fe-2348-4bf3-aba5-12f5f88d3606' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'
   AND sources = ARRAY['https://curtis.house.gov/news/documentsingle.aspx?DocumentID=3344', 'https://www.nbcnews.com/nbc-out/out-politics-and-policy/republicans-mountain-west-conference-transgender-volleyball-athlete-rcna181037', 'https://www.congress.gov/bill/119th-congress/senate-bill/9']::text[];
-- Katherine Clark / Childcare Affordability & Access
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Climate Change and Environmental Protection
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[];
-- Katherine Clark / Data Center Development & Energy Costs
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '4559b513-0fd8-4ed1-babd-f3b554162f40'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[];
-- Katherine Clark / Economic Development Incentives
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Growth and Development Pace
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Homelessness Response
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Bail and Pretrial Decisions
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://ballotpedia.org/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '1fab5edf-6151-4da0-9704-a7f2113ba54c'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://ballotpedia.org/Katherine_Clark']::text[];
-- Katherine Clark / Judicial & Prosecutorial Discretion
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'e5e48f0e-8f3a-40e1-8080-889fea389603'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Judicial Interpretation
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://ballotpedia.org/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://ballotpedia.org/Katherine_Clark']::text[];
-- Katherine Clark / Police Accountability
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Transparency in Legal Proceedings
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '6674d87e-999d-433a-aab7-3f626f59fd5f'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Environmental Protection vs. Development
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.lcv.org/congressional-scorecard/']::text[];
-- Katherine Clark / Local Immigration Enforcement
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Misinformation and the Role of Algorithms in Democracy
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Public Safety Approach
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Rent Regulation
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Residential Zoning
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'd4f18138-a2e0-4110-b925-7387d9d0d16d'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Transportation Priorities
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- Katherine Clark / Ukraine - Russia Conflict
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '24e9212c-b011-422a-865c-093e35050901'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://en.wikipedia.org/wiki/Katherine_Clark']::text[];
-- J.D. Vance / Public Safety Approach
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20241205150405/https://www.vance.senate.gov/press-releases/vance-introduces-resolution-to-support-americas-law-enforcement-officers/']::text[]
 WHERE politician_id = 'a809747d-3e53-4e9e-b3a1-6641dac2455c' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
   AND sources = ARRAY['https://www.vance.senate.gov/press-releases/vance-introduces-resolution-to-support-americas-law-enforcement-officers/']::text[];
-- Marco Rubio / Religious Freedom
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20230610205840/https://www.rubio.senate.gov/public/index.cfm/2012/2/support-grows-for-religious-freedom-restoration-act-of-2012']::text[]
 WHERE politician_id = '7c8e4442-e13e-485a-8993-b05ca110410d' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd'
   AND sources = ARRAY['https://www.rubio.senate.gov/public/index.cfm/2012/2/support-grows-for-religious-freedom-restoration-act-of-2012']::text[];
-- Marco Rubio / School Vouchers & Public Education Funding
UPDATE inform.politician_context
   SET sources = ARRAY['https://web.archive.org/web/20230704015116/https://rubio.senate.gov/public/index.cfm/2021/2/rubio-reintroduces-educational-opportunities-act']::text[]
 WHERE politician_id = '7c8e4442-e13e-485a-8993-b05ca110410d' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'
   AND sources = ARRAY['https://rubio.senate.gov/public/index.cfm/2021/2/rubio-reintroduces-educational-opportunities-act']::text[];
-- Katherine Clark / Reproductive Rights and Abortion Access
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Voting Rights and Electoral Integrity
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Immigration and Treatment of Immigrants
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Artificial Intelligence Oversight
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Campaign Finance Reform
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Civil Rights and Social Justice
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Deportation Priorities
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Fossil Fuel Policy
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/MA/Katherine_Clark.htm', 'https://katherineclark.house.gov/issues']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'
   AND sources = ARRAY['https://www.ontheissues.org/MA/Katherine_Clark.htm', 'https://clark.house.gov/issues']::text[];
-- Katherine Clark / Healthcare Access
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Criminalization of Homelessness
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Affordable Housing
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Jail Capacity and Incarceration Alternatives
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Access to Justice
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '9d45acaf-1ba4-4cb8-95e1-5ed985223b91'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Criminal Justice Approach
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Prosecution Priorities
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'abb99d95-cbb1-4617-8f8b-f220ef6028ca'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Medicare / Medicaid
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / State Redistricting and Gerrymandering
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Religious Freedom
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Same-Sex Marriage
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / School Vouchers & Public Education Funding
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Social Security
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / United States Tariff Policy
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Taxation and Public Spending
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];
-- Katherine Clark / Transgender Athletes
UPDATE inform.politician_context
   SET sources = ARRAY['https://katherineclark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[]
 WHERE politician_id = '7bf73fb2-1b31-412e-913d-835bfd3e326d' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'
   AND sources = ARRAY['https://clark.house.gov/issues', 'https://www.ontheissues.org/MA/Katherine_Clark.htm']::text[];

DO $$
DECLARE v_n int;
BEGIN
  -- 🔴 No re-pointed URL may survive anywhere in the table.
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://bass.house.gov/media-center/press-releases/bass-votes-codify-supreme-court-marriage-equality-decision' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://bass.house.gov/media-center/press-releases/bass-vote…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/rep-schiff-intr…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-hotels-to-housing-conversion-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/rep-schiff-intr…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-house-passage-of-the-build-back-better-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/congressman-sch…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://www.braun.senate.gov/news/press-releases/im-voting-no-senator-braun-on-84-billion-senate-bill-to-secure-other-countries-borders/' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://www.braun.senate.gov/news/press-releases/im-voting-n…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/issues/lgbtq-equality' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/issues/lgbtq-equality…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://democracyreform-sarbanes.house.gov/newsroom/press-re…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/press-releases/c-rdenas-hayes-introduces-resolution-declaring-racism-public-health' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/media-center/press-releases/c-rde…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/environment-and-climate-change' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/issues/environment-and-climate-ch…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/6-encourage-clean-energy-alternatives-and-protect-our-environment' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/6-encourage-clean-energy-alternat…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/commitment-to-our-seniors' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/issues/commitment-to-our-seniors…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/immigration-and-diversity-' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/issues/immigration-and-diversity-…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/press-releases/c-rdenas-to-force-vote-on-comprehensive-immigration-reform-tomorrow' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/media-center/press-releases/c-rde…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/1-pass-responsible-comprehensive-immigration-reform' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/issues/1-pass-responsible-compreh…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/issues/healthcare' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/issues/healthcare…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/press-releases/cardenas-votes-to-pass-historic-budget-resolution' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/media-center/press-releases/carde…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/media-center/in-the-news/univision-34_-al-punto-california-congressman-cardenas-on-the-inflation-reduction-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/media-center/in-the-news/univisio…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://cardenas.house.gov/' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://cardenas.house.gov/…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-failure-to-pass-womens-health-protection-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/congressman-sch…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-supreme-court-decision-to-strike-down-roe-v-wade' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/congressman-sch…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/schiff-introduces-equal-health-care-for-all-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/schiff-introduc…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-landmark-bipartisan-bill-to-combat-fraudulent-ai-campaign-ads' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/rep-schiff-intr…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/rep-schiff-statement-on-facebooks-deepfake-policy' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/rep-schiff-stat…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/schiff-demands-social-media-companies-take-action-in-advance-of-2024-election-to-address-spread-of-election-misinformation' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/schiff-demands-…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-passage-of-respect-for-marriage-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/congressman-sch…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-passage-of-respect-for-marriage-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://schiff.house.gov/news/press-releases/congressman-sch…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://curtis.house.gov/news/documentsingle.aspx?DocumentID=3344' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://curtis.house.gov/news/documentsingle.aspx?DocumentID…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://clark.house.gov/issues' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://clark.house.gov/issues…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://www.vance.senate.gov/press-releases/vance-introduces-resolution-to-support-americas-law-enforcement-officers/' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://www.vance.senate.gov/press-releases/vance-introduces…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://www.rubio.senate.gov/public/index.cfm/2012/2/support-grows-for-religious-freedom-restoration-act-of-2012' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://www.rubio.senate.gov/public/index.cfm/2012/2/support…', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://rubio.senate.gov/public/index.cfm/2021/2/rubio-reintroduces-educational-opportunities-act' = ANY(sources);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows still cite https://rubio.senate.gov/public/index.cfm/2021/2/rubio-reint…', v_n; END IF;

  -- Every target must now be present on the expected number of rows.
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20221209120805/https://bass.house.gov/media-center/press-releases/bass-votes-codify-supreme-court-marriage-equality-decision' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241207211842/https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises' = ANY(sources);
  IF v_n < 2 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 2', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241107103655/https://schiff.house.gov/news/press-releases/rep-schiff-introduces-hotels-to-housing-conversion-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241107034430/https://schiff.house.gov/news/press-releases/congressman-schiff-on-house-passage-of-the-build-back-better-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241106232213/https://www.braun.senate.gov/news/press-releases/im-voting-no-senator-braun-on-84-billion-senate-bill-to-secure-other-countries-borders/' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241106211925/https://schiff.house.gov/issues/lgbtq-equality' = ANY(sources);
  IF v_n < 2 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 2', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20230624095732/https://democracyreform-sarbanes.house.gov/newsroom/press-releases/221-house-democrats-co-sponsor-hr-1-the-for-the-people-act' = ANY(sources);
  IF v_n < 3 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 3', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241106220722/https://cardenas.house.gov/media-center/press-releases/c-rdenas-hayes-introduces-resolution-declaring-racism-public-health' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241128052016/https://cardenas.house.gov/issues/environment-and-climate-change' = ANY(sources);
  IF v_n < 2 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 2', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20201027200851/https://cardenas.house.gov/6-encourage-clean-energy-alternatives-and-protect-our-environment' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241128065753/https://cardenas.house.gov/issues/commitment-to-our-seniors' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241128052017/https://cardenas.house.gov/issues/immigration-and-diversity-' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20190618141559/https://cardenas.house.gov/media-center/press-releases/c-rdenas-to-force-vote-on-comprehensive-immigration-reform-tomorrow' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20161207041404/https://cardenas.house.gov/issues/1-pass-responsible-comprehensive-immigration-reform' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241106202234/https://cardenas.house.gov/issues/healthcare' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20250102063206/https://cardenas.house.gov/media-center/press-releases/cardenas-votes-to-pass-historic-budget-resolution' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241217085821/https://cardenas.house.gov/media-center/in-the-news/univision-34_-al-punto-california-congressman-cardenas-on-the-inflation-reduction-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241227072544/https://cardenas.house.gov/' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241130120643/https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-failure-to-pass-womens-health-protection-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241207205044/https://schiff.house.gov/news/press-releases/congressman-schiff-on-supreme-court-decision-to-strike-down-roe-v-wade' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241207200849/https://schiff.house.gov/news/press-releases/schiff-introduces-equal-health-care-for-all-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241128045453/https://schiff.house.gov/news/press-releases/rep-schiff-introduces-landmark-bipartisan-bill-to-combat-fraudulent-ai-campaign-ads' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241107080122/https://schiff.house.gov/news/press-releases/rep-schiff-statement-on-facebooks-deepfake-policy' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241207211352/https://schiff.house.gov/news/press-releases/schiff-demands-social-media-companies-take-action-in-advance-of-2024-election-to-address-spread-of-election-misinformation' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241106214001/https://schiff.house.gov/news/press-releases/congressman-schiff-on-passage-of-respect-for-marriage-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241106214007/https://schiff.house.gov/news/press-releases/congressman-schiff-on-senate-passage-of-respect-for-marriage-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241202174713/https://curtis.house.gov/news/documentsingle.aspx?DocumentID=3344' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://katherineclark.house.gov/issues' = ANY(sources);
  IF v_n < 43 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 43', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20241205150405/https://www.vance.senate.gov/press-releases/vance-introduces-resolution-to-support-americas-law-enforcement-officers/' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20230610205840/https://www.rubio.senate.gov/public/index.cfm/2012/2/support-grows-for-religious-freedom-restoration-act-of-2012' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE 'https://web.archive.org/web/20230704015116/https://rubio.senate.gov/public/index.cfm/2021/2/rubio-reintroduces-educational-opportunities-act' = ANY(sources);
  IF v_n < 1 THEN RAISE EXCEPTION '1539: target present on only % rows, expected >= 1', v_n; END IF;

  -- No row may be left sourceless by a substitution.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE (politician_id, topic_id) IN (('21c9e711-fb18-4afb-884f-08acd2b598ba','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','4938766b-b45a-46e3-93bd-b8b30651271a'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('a73e7a2a-48b0-4636-8fa4-5324ede65833','24e9212c-b011-422a-865c-093e35050901'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','92730f69-ae57-401c-8ad1-2d07834a895d'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','a22215c3-6693-4bc2-b248-01aebba14570'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('bda8ce6a-c704-45a1-85ed-fbcc6fecfb0c','669cac97-66a6-4087-b036-936fbe62efb3'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('b87583fe-2348-4bf3-aba5-12f5f88d3606','d1618b9c-0b9e-45af-b986-bb33d270b8e4'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','c1ac1330-47f7-44ec-baf3-c913d926b97c'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','4559b513-0fd8-4ed1-babd-f3b554162f40'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','eb3d1247-0de1-4b7f-baec-7259861efd53'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','1fab5edf-6151-4da0-9704-a7f2113ba54c'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','e5e48f0e-8f3a-40e1-8080-889fea389603'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','7bad33eb-e93e-4d94-8822-97212d49bde5'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','6674d87e-999d-433a-aab7-3f626f59fd5f'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','1935979c-b290-42e4-baa5-8cb0138b4ffa'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','b9ccee94-ad96-4f10-b655-889d8e5abe92'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','d4f18138-a2e0-4110-b925-7387d9d0d16d'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','ba59337e-30e2-4aba-a39a-426b3366eb27'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','24e9212c-b011-422a-865c-093e35050901'), ('a809747d-3e53-4e9e-b3a1-6641dac2455c','e9ebefcd-c496-45e8-b816-a79f8442ba85'), ('7c8e4442-e13e-485a-8993-b05ca110410d','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('7c8e4442-e13e-485a-8993-b05ca110410d','00b95a6a-75db-4521-b523-3326bba938de'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','af2fdfd6-02c4-49df-b09c-cf8536f4773f'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','4e2c69ce-591e-4197-9cd5-7aceff79d390'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','666bf03d-81fc-4138-ab15-69ae734c9023'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','92730f69-ae57-401c-8ad1-2d07834a895d'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','0bc588c6-39e1-4084-b5de-cac909b8b762'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','44905f3b-e105-4f6c-afc7-5d223813dbac'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','a22215c3-6693-4bc2-b248-01aebba14570'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','4938766b-b45a-46e3-93bd-b8b30651271a'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','669cac97-66a6-4087-b036-936fbe62efb3'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','9d45acaf-1ba4-4cb8-95e1-5ed985223b91'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','9db07b16-1076-4b7d-ad89-ebe7b51f4336'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','abb99d95-cbb1-4617-8f8b-f220ef6028ca'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','48cc9585-ec22-4f53-8d42-6839828dd36f'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','6b9ba6d9-1001-43f5-b073-4d37130696fd'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','c5ab4eab-702f-49b8-9277-8ea53f3835c6'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','00b95a6a-75db-4521-b523-3326bba938de'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','87d20824-a6e9-407b-983c-65440084a0ab'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','683c8084-2281-4920-a07c-18439b2dd413'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','f7e5678d-dadd-4556-a2fc-446e24642ceb'), ('7bf73fb2-1b31-412e-913d-835bfd3e326d','d1618b9c-0b9e-45af-b986-bb33d270b8e4'))
     AND (sources IS NULL OR cardinality(sources) = 0);
  IF v_n <> 0 THEN RAISE EXCEPTION '1539: % rows left with no sources', v_n; END IF;
END $$;

COMMIT;
