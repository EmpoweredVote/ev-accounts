-- 1564_retire_fabricated_source_stances.sql
--
-- APPLIED 2026-08-06, operator-approved. Retire 298 stance rows whose evidence does not exist, and strip the fabricated
-- citations from a further 90 rows that keep a real source.
--
--   Findings:  data/stance-retirement/2026-08-06-fabricated-sweep-COMPLETE.md
--   Rollback:  data/stance-retirement/2026-08-06-migration-1564-rollback.json — every retired row
--              verbatim (politician, topic, value, reasoning, sources) so each can be reinserted.
--   Evidence:  fabricated-article-sweep-*.json (per-URL verdicts) · navonly-classification.json
--              (per-survivor read verdicts) · 2026-08-06-control-rederivation.json
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT IS BEING REMOVED
-- ---------------------------------------------------------------------------------------------------
-- 119 distinct cited URLs that were never published. Each one: HTTP 404 on a LIVE host,
-- zero Wayback captures of the exact path, and >= 5 archived sibling PAGES in the same section or month.
-- The sweep covered 13,705 of 13,705 eligible cited URLs (100%).
--
-- The sibling control counts real pages, not archived URLs: crawler asset paths, section indexes and
-- inline-JS artifacts were excluded and all 59 controls re-derived. That downgraded one finding
-- (audacy.com) out of this set. lynch.house.gov/issues/technology is also excluded as UNPROVEN — its
-- whole /issues section is gone and its control is contaminated by soft-404s.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY 298 ROWS AND NOT ALL 388
-- ---------------------------------------------------------------------------------------------------
--   * 141 rows are SOLE-SOURCED: removing the fabricated citations leaves no citation at all.
--   * 157 rows keep only citations that are not coverage. Every surviving page was FETCHED AND
--     READ against the 2026-08-04 ruling ("does this page state a position attributable to this
--     person"). They fail in four ways:
--       - GONE: 36 of 108 survivors are 404 or dead domains. The three largest are the Carson,
--         Alhambra and Lynn agenda/minutes indexes — 62 rows rest on pages that no longer exist.
--       - INDEX pages: agendas, minutes, archives.
--       - SEARCH-RESULT URLs cited as sources (commonwealthbeacon.org/?s=…). A query is not a source.
--       - SUBSTANTIVE BUT NOT ABOUT THIS PERSON: actonmass.org bill pages and bare
--         malegislature.gov/Bills/<id> pages carry real prose and name no citing legislator.
--   * 79 rows keep a real, readable co-source that names the politician -> citation STRIPPED, row KEPT.
--   * 11 rows keep a survivor that could not be read (bot-walled congress.gov / ontheissues) ->
--     KEPT. A server answered, so absence is not shown. We retire on demonstrated absence only.
--
-- 🔴 A STRUCTURAL RULE WAS NOT ENOUGH. Classifying survivors by path depth put NAV_ONLY at 42 and this
-- migration at 183 rows. Reading them put it at 157 and 298. lynnma.gov/city-council/minutes
-- (19 rows) is depth-2 and is an index; wikipedia.org/wiki/Ed_Markey is depth-2 and is substantive.
--
-- ⚠ FOUR APPARENT RE-POINTS WERE WITHDRAWN AND ARE RETIRED HERE INSTEAD. Four citations are corrupted
-- slugs of real live pages (/issues/health-care -> /issues/health, /issues/criminal-justice ->
-- /criminal-injustice, and two Moulton slugs). Re-pointing them was tested and REJECTED: the target
-- pages do not carry the rows' claims (bail 0, "Justice Guarantee" 0, Gideon 0, Medicare 0, CHIPS 0,
-- deepfake 0, disinformation 0). Re-pointing would have manufactured support — the willametteweek rule.
--
-- ---------------------------------------------------------------------------------------------------
-- BLAST RADIUS — CHIPS MUST BE FLIPPED IN essentials/src/lib/coverage.js IN THE SAME BATCH
-- ---------------------------------------------------------------------------------------------------
--   City of Carson    34 of 34 answers  -> ZERO
--   City of Lynn MA   30 of 30          -> ZERO
--   City of Alhambra  19 of 19          -> ZERO   (invisible to the structural rule: all 19 rows on one 404 index)
--   City of Waltham   5 of 5            -> ZERO
--   Commonwealth of Massachusetts 161 of 2,675 · Somerville 30 of 85 · Medford 3 of 10 · others low.
-- 69 politicians are touched; those emptied to zero answers have last_stances_researched_at nulled
-- (rule 1494/1507/1508), computed here rather than hard-coded.
--
-- ⚠ 4 of the 298 retired rows are ORPHAN CONTEXT — reasoning with no answer behind it (Bryant Acosta 3,
-- David B. Walgren 1), part of the ~546-row orphan class that is still undiagnosed corpus-wide. So
-- context falls by 298 while answers fall by 294. Both are asserted separately below; the
-- orphan count is computed at run time, not hard-coded.

BEGIN;

CREATE TEMP TABLE fab_urls(url text PRIMARY KEY);
INSERT INTO fab_urls(url) VALUES
    ('https://actonmass.org/bills/racially-inclusive-education/'),
    ('https://actonmass.org/bills/rent-control/'),
    ('https://actonmass.org/bills/the-roe-act/'),
    ('https://actonmass.org/bills/universal-childcare/'),
    ('https://actonmass.org/legislators/aaron-michlewitz'),
    ('https://actonmass.org/legislators/adrianne-ramos/'),
    ('https://actonmass.org/legislators/angelo-puppolo/'),
    ('https://actonmass.org/legislators/bud-williams/'),
    ('https://actonmass.org/legislators/carole-fiola/'),
    ('https://actonmass.org/legislators/daniel-donahue'),
    ('https://actonmass.org/legislators/dawne-shand/'),
    ('https://actonmass.org/legislators/james-arena-derosa/'),
    ('https://actonmass.org/legislators/james-oday/'),
    ('https://actonmass.org/legislators/karen-spilka'),
    ('https://actonmass.org/legislators/kate-hogan'),
    ('https://actonmass.org/legislators/kenneth-gordon/'),
    ('https://actonmass.org/legislators/kevin-honan'),
    ('https://actonmass.org/legislators/mark-montigny'),
    ('https://actonmass.org/legislators/richard-wells/'),
    ('https://actonmass.org/legislators/ronald-mariano'),
    ('https://actonmass.org/legislators/sam-montano'),
    ('https://actonmass.org/legislators/tackey-chan/'),
    ('https://actonmass.org/legislators/thomas-stanley/'),
    ('https://actonmass.org/legislators/tricia-farley-bouvier/'),
    ('https://actonmass.org/legislators/william-brownsberger/'),
    ('https://actonmass.org/legislators/william-driscoll'),
    ('https://carsonca.gov/government/mayor'),
    ('https://commonwealthbeacon.org/housing/mbta-communities-zoning-medford/'),
    ('https://governor.maryland.gov/priorities/environment/'),
    ('https://kamlager-dove.house.gov/issues/health-care'),
    ('https://kamlager-dove.house.gov/issues/lgbtq'),
    ('https://kamlager-dove.house.gov/issues/technology'),
    ('https://ladowntownnews.com/features/fighting-corruption-fraud-and-waste-bryant-acosta-runs-for-mayor-alongside-around-40-other-candidates'),
    ('https://marylandmatters.org/2021/04/10/police-accountability-act-signed/'),
    ('https://marylandmatters.org/2023/04/healthcare-expansion/'),
    ('https://marylandmatters.org/2023/05/voting-rights-maryland/'),
    ('https://marylandmatters.org/2023/childcare-moore/'),
    ('https://marylandmatters.org/2023/moore-clean-energy-buildings/'),
    ('https://marylandmatters.org/2024/01/moore-fy2025-budget/'),
    ('https://mass.gov/info-details/mbta-communities-compliance-status'),
    ('https://moulton.house.gov/issues/jobs-economy'),
    ('https://moulton.house.gov/issues/national-security'),
    ('https://moulton.house.gov/issues/technology'),
    ('https://oag.ca.gov/news/press-releases/attorney-general-bonta-joins-bipartisan-coalition-urging-congress-pass-legislation-support-workforce'),
    ('https://oag.ca.gov/news/press-releases/attorney-general-bonta-joins-nationwide-fight-underscore-need-preventive-healthcare-access'),
    ('https://oag.ca.gov/news/press-releases/attorney-general-bonta-leads-coalition-22-states-support-increased-access-birth-control'),
    ('https://onyourballot.vote411.org/m/candidate-detail.do?id=72262938'),
    ('https://pressley.house.gov/issues/climate'),
    ('https://pressley.house.gov/issues/criminal-justice'),
    ('https://pressley.house.gov/issues/democracy'),
    ('https://pressley.house.gov/issues/seniors'),
    ('https://pressley.house.gov/issues/technology'),
    ('https://theeastsiderla.com/news/government_and_politics/colter-carlisle-l-a-city-council-district-13-candidate'),
    ('https://theeastsiderla.com/news/government_and_politics/maria-lou-calanche-l-a-city-council-district-1-candidate'),
    ('https://www.bostonglobe.com/2021/01/21/metro/mariano-elected-house-speaker/'),
    ('https://www.bostonglobe.com/2022/04/14/metro/mayors-push-mbta-service-restoration/'),
    ('https://www.bostonglobe.com/2023/09/26/metro/massachusetts-tax-relief-package-governor-healey/'),
    ('https://www.cbsnews.com/news/murkowski-ukraine-aid/'),
    ('https://www.dailybreeze.com/2017/03/03/carson-city-council-immigration-resolution-trust-act/'),
    ('https://www.dailybreeze.com/2019/11/15/carson-development-projects-city-council/'),
    ('https://www.dailybreeze.com/2020/06/18/amazon-warehouse-carson-city-council-approval/'),
    ('https://www.dailybreeze.com/2022/06/15/carson-city-budget-adopted-council/'),
    ('https://www.dailybreeze.com/2022/08/20/carson-utility-tax-measure-budget-davis-holmes/'),
    ('https://www.dailybreeze.com/2022/09/15/carson-housing-element-rhna-compliance-council/'),
    ('https://www.dailybreeze.com/2022/11/03/carson-amazon-local-hiring-policy-davis-holmes/'),
    ('https://www.dailybreeze.com/2023/02/14/carson-transit-transportation-silver-line-sbccog/'),
    ('https://www.dailybreeze.com/2023/03/22/carson-refinery-pollution-city-response-davis-holmes/'),
    ('https://www.dailybreeze.com/2023/04/10/carson-mixed-use-development-dignity-sports-park-corridor/'),
    ('https://www.dailybreeze.com/2023/05/12/carson-city-council-homelessness-encampment-response/'),
    ('https://www.dailybreeze.com/2023/06/07/carson-lasd-contract-public-safety-budget/'),
    ('https://www.govtrack.us/congress/members/ayanna_pressley/P000617'),
    ('https://www.latimes.com/socal/daily-pilot/news/story/carson-economic-development-council'),
    ('https://www.lynnjournal.com/2022/09/mayor-nicholson-economic-development-downtown'),
    ('https://www.lynnjournal.com/2022/10/lynn-council-economic-development'),
    ('https://www.lynnjournal.com/2022/10/lynn-homelessness-task-force-council'),
    ('https://www.lynnjournal.com/2022/10/nicholson-homelessness-task-force-lynn'),
    ('https://www.lynnjournal.com/2022/11/lynn-city-council-tif-economic-development'),
    ('https://www.lynnjournal.com/2022/11/lynn-council-economic-development-tif'),
    ('https://www.lynnjournal.com/2023/02/mayor-nicholson-supports-mbta-communities-zoning'),
    ('https://www.lynnjournal.com/2023/03/lynn-city-council-housing-zoning-vote'),
    ('https://www.lynnjournal.com/2023/03/lynn-council-housing-vote'),
    ('https://www.lynnjournal.com/2023/03/nicholson-environmental-justice-lynn'),
    ('https://www.lynnjournal.com/2023/04/nicholson-waterfront-development-plans'),
    ('https://www.lynnjournal.com/2023/05/lynn-council-development-votes'),
    ('https://www.lynnjournal.com/2023/05/nicholson-ferry-service-lynn-boston'),
    ('https://www.lynnjournal.com/2025/02/lynn-council-immigrant-protections-resolution'),
    ('https://www.lynnjournal.com/2025/02/nicholson-defends-immigrant-community-ice-enforcement'),
    ('https://www.lynnma.gov/news/complete-streets-grant'),
    ('https://www.lynnma.gov/news/downtown-development-updates'),
    ('https://www.lynnma.gov/news/homelessness-services-update'),
    ('https://www.lynnma.gov/news/lynn-harbor-cleanup-waterfront'),
    ('https://www.lynnma.gov/news/lynn-waterfront-master-plan'),
    ('https://www.lynnma.gov/news/mayor-nicholson-announces-housing-development-initiative'),
    ('https://www.markey.senate.gov/news/press-releases/markey-introduces-supreme-court-ethics-recusal-transparency-act'),
    ('https://www.markey.senate.gov/news/press-releases/markey-jayapal-introduce-transgender-bill-of-rights'),
    ('https://www.markey.senate.gov/news/press-releases/markey-nadler-introduce-judiciary-act'),
    ('https://www.markey.senate.gov/news/press-releases/markey-statement-on-inflation-reduction-act-passage'),
    ('https://www.markey.senate.gov/news/press-releases/markey-statement-on-supreme-court-dobbs-decision'),
    ('https://www.markey.senate.gov/news/press-releases/markey-statement-on-supreme-court-loper-bright-decision'),
    ('https://www.markey.senate.gov/news/press-releases/markey-supports-bipartisan-safer-communities-act'),
    ('https://www.markey.senate.gov/news/press-releases/markey-votes-to-pass-american-rescue-plan'),
    ('https://www.markey.senate.gov/news/press-releases/markey-votes-to-pass-infrastructure-investment-and-jobs-act'),
    ('https://www.markey.senate.gov/news/press-releases/senators-markey-booker-introduce-algorithmic-accountability-act'),
    ('https://www.markey.senate.gov/news/press-releases/senators-markey-whitehouse-reintroduce-disclose-act'),
    ('https://www.medfordma.org/departments/planning-development/housing/'),
    ('https://www.medfordma.org/departments/planning-development/zoning/'),
    ('https://www.precinctreporter.com/2022/10/carson-environmental-justice-mayor/'),
    ('https://www.sgvtribune.com/2019/03/19/alhambra-adopts-welcoming-city-resolution/'),
    ('https://www.sgvtribune.com/2020/06/15/alhambra-council-debates-police-reform/'),
    ('https://www.sgvtribune.com/2021/08/alhambra-development-valley-boulevard/'),
    ('https://www.sgvtribune.com/2022/05/alhambra-mental-health-co-responder-program/'),
    ('https://www.sgvtribune.com/2022/11/16/alhambra-city-council-approves-housing-element-update/'),
    ('https://www.sgvtribune.com/2023/09/12/sgv-cities-ramp-up-homelessness-response/'),
    ('https://www.slc.gov/council/completed-projects/connect-slc-a-city-wide-transportation-plan/'),
    ('https://www.somervillema.gov/departments/economic-development'),
    ('https://www.somervillema.gov/departments/programs/office-immigrant-services-and-integration'),
    ('https://www.somervillema.gov/departments/programs/somerville-by-design'),
    ('https://www.somervillema.gov/departments/somerville-heart-program'),
    ('https://www.somervillema.gov/departments/somerville-homeless-coalition');

CREATE TEMP TABLE retire_rows(politician_id uuid, topic_id uuid);
INSERT INTO retire_rows(politician_id, topic_id) VALUES
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('94de05c6-d1bc-4cd5-ae9a-7c292ec8149e','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('1ce3f260-d267-4569-993b-47f8dd8b0842','9db07b16-1076-4b7d-ad89-ebe7b51f4336'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','92730f69-ae57-401c-8ad1-2d07834a895d'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','48cc9585-ec22-4f53-8d42-6839828dd36f'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','00b95a6a-75db-4521-b523-3326bba938de'),
    ('6f66ea3f-d5a3-4a51-96be-58aa0097bfc0','d1618b9c-0b9e-45af-b986-bb33d270b8e4'),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','00b95a6a-75db-4521-b523-3326bba938de'),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('9cf147de-64e0-4116-b461-95933e18c423','92730f69-ae57-401c-8ad1-2d07834a895d'),
    ('9cf147de-64e0-4116-b461-95933e18c423','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('9cf147de-64e0-4116-b461-95933e18c423','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('9cf147de-64e0-4116-b461-95933e18c423','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('9cf147de-64e0-4116-b461-95933e18c423','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
    ('9cf147de-64e0-4116-b461-95933e18c423','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('9cf147de-64e0-4116-b461-95933e18c423','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','00b95a6a-75db-4521-b523-3326bba938de'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','d1618b9c-0b9e-45af-b986-bb33d270b8e4'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('28a703f8-8316-4d3c-bfc0-3dcd77eab96c','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','92730f69-ae57-401c-8ad1-2d07834a895d'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','00b95a6a-75db-4521-b523-3326bba938de'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','00b95a6a-75db-4521-b523-3326bba938de'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','00b95a6a-75db-4521-b523-3326bba938de'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','00b95a6a-75db-4521-b523-3326bba938de'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','92730f69-ae57-401c-8ad1-2d07834a895d'),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('9b754d96-e0e7-4f6b-b3ae-e0d1c12ef1bf','00b95a6a-75db-4521-b523-3326bba938de'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','00b95a6a-75db-4521-b523-3326bba938de'),
    ('c7c8d91f-156b-42ea-93f1-7dac0c4080a4','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('a4320764-6ba2-4563-9a58-abb1333c2f40','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('ac0d1a12-af8e-4464-9cb7-4ed2b549cbbe','7687de4f-4d0b-462a-b803-bdfb23b16b42'),
    ('ac0d1a12-af8e-4464-9cb7-4ed2b549cbbe','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('f22187bb-dc57-4088-bb19-8bc39bcb95c9','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('f22187bb-dc57-4088-bb19-8bc39bcb95c9','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('f22187bb-dc57-4088-bb19-8bc39bcb95c9','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('f22187bb-dc57-4088-bb19-8bc39bcb95c9','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('f22187bb-dc57-4088-bb19-8bc39bcb95c9','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('27441d13-d90b-48e8-bb35-3b7da5d24c6e','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('27441d13-d90b-48e8-bb35-3b7da5d24c6e','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('27441d13-d90b-48e8-bb35-3b7da5d24c6e','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('e4df4fce-9289-43db-8568-e316a73ae931','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('e4df4fce-9289-43db-8568-e316a73ae931','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('e4df4fce-9289-43db-8568-e316a73ae931','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('abad7f66-e2d3-4edf-a35f-2170c2bd4cbb','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('f6d52199-b1d1-48d3-9972-66b8d229acdc','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('f6d52199-b1d1-48d3-9972-66b8d229acdc','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('f6d52199-b1d1-48d3-9972-66b8d229acdc','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('d1b1bc73-575f-444e-a2f8-46c04b07d3f8','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('d1b1bc73-575f-444e-a2f8-46c04b07d3f8','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('d1b1bc73-575f-444e-a2f8-46c04b07d3f8','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('d1b1bc73-575f-444e-a2f8-46c04b07d3f8','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('d1b1bc73-575f-444e-a2f8-46c04b07d3f8','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('1581974b-2a8c-4439-acae-377bc06e1788','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('3cb334b2-fa31-46e4-8dcc-5fec75dd0fe5','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('258b185a-5b28-45a0-9e7f-a05a58080197','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('258b185a-5b28-45a0-9e7f-a05a58080197','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('258b185a-5b28-45a0-9e7f-a05a58080197','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('258b185a-5b28-45a0-9e7f-a05a58080197','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('258b185a-5b28-45a0-9e7f-a05a58080197','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('258b185a-5b28-45a0-9e7f-a05a58080197','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7','48cc9585-ec22-4f53-8d42-6839828dd36f'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','92730f69-ae57-401c-8ad1-2d07834a895d'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('9cf147de-64e0-4116-b461-95933e18c423','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','d1618b9c-0b9e-45af-b986-bb33d270b8e4'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','00b95a6a-75db-4521-b523-3326bba938de'),
    ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('ea8ed274-32d6-499d-a787-7ad1f0624280','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('90602902-b178-4709-a74b-68b30fe45394','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','1935979c-b290-42e4-baa5-8cb0138b4ffa'),
    ('3d9354a8-e7ee-4381-b91a-a40d0a2e8d3a','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('baddd174-93ea-47b6-9cbd-c48fc3acf2f6','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('90602902-b178-4709-a74b-68b30fe45394','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('90602902-b178-4709-a74b-68b30fe45394','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('90602902-b178-4709-a74b-68b30fe45394','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('90602902-b178-4709-a74b-68b30fe45394','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','9db07b16-1076-4b7d-ad89-ebe7b51f4336'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('41ced04d-7403-4170-a267-c339191e6fcd','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('8242a03d-6801-4b91-aed9-918a603b4a21','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('8242a03d-6801-4b91-aed9-918a603b4a21','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('8242a03d-6801-4b91-aed9-918a603b4a21','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('9b11117c-d064-404b-8c89-0042f417c576','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('9b11117c-d064-404b-8c89-0042f417c576','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('9b11117c-d064-404b-8c89-0042f417c576','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('9b11117c-d064-404b-8c89-0042f417c576','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('1e5429d3-c4b2-4a1f-913f-483833565e93','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('1e5429d3-c4b2-4a1f-913f-483833565e93','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('1e5429d3-c4b2-4a1f-913f-483833565e93','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('ce379255-f87e-4856-9e2c-dda38c976bdc','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('5b2a514f-ea4b-4476-bf45-0d221a138d3a','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('5b2a514f-ea4b-4476-bf45-0d221a138d3a','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('a79ac715-57a6-4a18-82a0-0b8a5ed60464','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','44905f3b-e105-4f6c-afc7-5d223813dbac'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('073a3e12-55bb-4c88-9bd9-3333b93f40cd','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('13f3e9dc-67fc-4115-99a5-77c4647f1b3c','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('cb506153-5bd5-4b43-b982-58d07c9611e4','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('cb506153-5bd5-4b43-b982-58d07c9611e4','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('cb506153-5bd5-4b43-b982-58d07c9611e4','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('3c43a3fa-9c89-4278-8d36-f5e4e5000d64','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('bc02a2c7-2033-40a3-89f6-e50d95ac1e4e','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('b9c5dd29-eeb5-4903-af31-d4ab09041b0a','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('6d30fb7c-99cb-4705-86bc-c3d13ffd44d4','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('6d30fb7c-99cb-4705-86bc-c3d13ffd44d4','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('6d30fb7c-99cb-4705-86bc-c3d13ffd44d4','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('a24baf50-54d3-4319-9bfb-f354c3f5ca03','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('a24baf50-54d3-4319-9bfb-f354c3f5ca03','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('c0ba9af7-714c-44c7-a3e4-abf735fb0ad9','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('ddb4ff9a-d17a-4db7-9d70-b326aaf72e05','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('bd6f9a13-40d9-4b6c-a1ef-64dc010c1f91','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('bd6f9a13-40d9-4b6c-a1ef-64dc010c1f91','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('e48dc9c7-8359-486c-8044-cbae730490e2','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('e48dc9c7-8359-486c-8044-cbae730490e2','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('f8fc0768-f42d-426c-b580-b053cb802f3f','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('f8fc0768-f42d-426c-b580-b053cb802f3f','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('94051951-ca12-452e-bfa3-854dbce765eb','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('94051951-ca12-452e-bfa3-854dbce765eb','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('9c897f77-6567-4a07-a810-c3fb11f2e50c','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('9c897f77-6567-4a07-a810-c3fb11f2e50c','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('d4aa5f35-7491-450d-9c7e-ada82378504d','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('d4aa5f35-7491-450d-9c7e-ada82378504d','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('1f6e314e-c34f-43dd-b599-ff8d4c2caee9','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('1f6e314e-c34f-43dd-b599-ff8d4c2caee9','b9ccee94-ad96-4f10-b655-889d8e5abe92'),
    ('a4320764-6ba2-4563-9a58-abb1333c2f40','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
    ('a4320764-6ba2-4563-9a58-abb1333c2f40','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('3eab65f7-083a-49c6-9944-1a20a5373538','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('42550273-382a-481f-afc9-ccdf32329bf6','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('28d25ed6-6a0f-428e-8b42-85a448ffb0c2','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('ab208b92-9067-4f3d-9791-60b404793b3a','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('73a1f2f1-9112-4820-b853-8a8542c72d85','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('ac0d1a12-af8e-4464-9cb7-4ed2b549cbbe','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('ac0d1a12-af8e-4464-9cb7-4ed2b549cbbe','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('ac0d1a12-af8e-4464-9cb7-4ed2b549cbbe','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('1d731710-7e7e-4685-ade7-f34bce70c088','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('1d731710-7e7e-4685-ade7-f34bce70c088','4938766b-b45a-46e3-93bd-b8b30651271a'),
    ('1d731710-7e7e-4685-ade7-f34bce70c088','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('1d731710-7e7e-4685-ade7-f34bce70c088','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('13eea214-867a-4a66-ae1a-c0f9916ac833','4938766b-b45a-46e3-93bd-b8b30651271a');

CREATE TEMP TABLE strip_rows(politician_id uuid, topic_id uuid);
INSERT INTO strip_rows(politician_id, topic_id) VALUES
    ('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
    ('8b183a30-3afb-4d9e-aa40-aa2ad2c674aa','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','48cc9585-ec22-4f53-8d42-6839828dd36f'),
    ('167d272b-fc1b-4a72-a44d-dfa1a9a42fcf','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('ab975fdf-b4f1-4955-94a4-97681a2a8d08','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','48cc9585-ec22-4f53-8d42-6839828dd36f'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','c5ab4eab-702f-49b8-9277-8ea53f3835c6'),
    ('5fdefd59-b543-4221-b6ed-b33532f9bd5f','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('e96eddbe-4a4a-4499-8102-636f0cfac10e','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','00b95a6a-75db-4521-b523-3326bba938de'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('9b3772d3-3602-457a-82e7-479b5e557b13','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('71aa11da-0fa1-49d2-bcbd-3bce7d0bad2b','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('6e3c30f5-52be-48b0-b5b4-383e5d745c57','7bad33eb-e93e-4d94-8822-97212d49bde5'),
    ('cc873a93-cb47-405a-93b0-bb2848fdd57e','24e9212c-b011-422a-865c-093e35050901'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','af2fdfd6-02c4-49df-b09c-cf8536f4773f'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','666bf03d-81fc-4138-ab15-69ae734c9023'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','92730f69-ae57-401c-8ad1-2d07834a895d'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','e5e48f0e-8f3a-40e1-8080-889fea389603'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','6674d87e-999d-433a-aab7-3f626f59fd5f'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','d1618b9c-0b9e-45af-b986-bb33d270b8e4'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','4559b513-0fd8-4ed1-babd-f3b554162f40'),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4'),
    ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
    ('15c27efb-0402-4a3a-bfad-9df152874046','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
    ('15c27efb-0402-4a3a-bfad-9df152874046','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('15c27efb-0402-4a3a-bfad-9df152874046','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('15c27efb-0402-4a3a-bfad-9df152874046','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('15c27efb-0402-4a3a-bfad-9df152874046','92730f69-ae57-401c-8ad1-2d07834a895d'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('913143ad-c39b-4dde-9a93-8252a98b0181','eb3d1247-0de1-4b7f-baec-7259861efd53'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('8ee72aa5-b7a0-422f-817d-a330f29dd2b1','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('ee861f58-dabf-429f-97ee-32591bdd3650','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('c70bd1f2-6ba2-446e-a40c-d07f446db214','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('afb64fe5-b2a7-4c47-b113-5200ed26182a','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('90602902-b178-4709-a74b-68b30fe45394','0bc588c6-39e1-4084-b5de-cac909b8b762'),
    ('90602902-b178-4709-a74b-68b30fe45394','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('90602902-b178-4709-a74b-68b30fe45394','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('90602902-b178-4709-a74b-68b30fe45394','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('a3131d21-f3ad-4483-ac6d-13c9c7ecdd74','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
    ('c0dad47a-8ac9-4ae5-9990-d5f1e16e0c71','ba59337e-30e2-4aba-a39a-426b3366eb27'),
    ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),
    ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
    ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('21e534c8-c0c0-42f5-b52b-5eb2f246d632','a22215c3-6693-4bc2-b248-01aebba14570'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','4559b513-0fd8-4ed1-babd-f3b554162f40'),
    ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('2b1a645a-72ce-4c0f-80ec-17565a2d6d10','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('98291d86-d42d-49d0-a5b2-d689a8154b15','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('98291d86-d42d-49d0-a5b2-d689a8154b15','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('98291d86-d42d-49d0-a5b2-d689a8154b15','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('37e88d74-8fdf-4a66-8685-989248512b29','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('7cbdb829-4836-49e9-afb2-cb8035afc6bf','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
    ('7cbdb829-4836-49e9-afb2-cb8035afc6bf','669cac97-66a6-4087-b036-936fbe62efb3'),
    ('7cbdb829-4836-49e9-afb2-cb8035afc6bf','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),
    ('a2c6adc7-7689-49b9-964f-8f2aeb243a83','666bf03d-81fc-4138-ab15-69ae734c9023'),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','9d45acaf-1ba4-4cb8-95e1-5ed985223b91'),
    ('a2c6adc7-7689-49b9-964f-8f2aeb243a83','cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),
    ('a2c6adc7-7689-49b9-964f-8f2aeb243a83','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
    ('faf86b5b-5add-4afb-a8e2-96b3e8be4b78','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','4559b513-0fd8-4ed1-babd-f3b554162f40'),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','c267e137-0ff9-4e7d-9d13-e3cea1756cd0'),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','1fab5edf-6151-4da0-9704-a7f2113ba54c'),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','abb99d95-cbb1-4617-8f8b-f220ef6028ca'),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','6674d87e-999d-433a-aab7-3f626f59fd5f'),
    ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464','87d20824-a6e9-407b-983c-65440084a0ab');

DO $$
DECLARE
  v_n int; v_ans_before bigint; v_ctx_before bigint; v_nulled int; v_cohort uuid[];
  v_orphans int;
BEGIN
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  -- ---- guards on the pre-state ----
  SELECT count(*) INTO v_n FROM fab_urls;
  IF v_n <> 119 THEN RAISE EXCEPTION '1564: expected 119 fabricated urls, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM retire_rows;
  IF v_n <> 298 THEN RAISE EXCEPTION '1564: expected 298 retire rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM strip_rows;
  IF v_n <> 90 THEN RAISE EXCEPTION '1564: expected 90 strip rows, found %', v_n; END IF;

  -- Every targeted row must still exist and still cite a fabricated url. A row that has been edited
  -- since the classification is out of scope and must stop the migration, not be retired blind.
  SELECT count(*) INTO v_n FROM retire_rows r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id
                        AND pc.sources && (SELECT array_agg(url) FROM fab_urls));
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % retire rows no longer cite a fabricated url — re-review', v_n; END IF;

  SELECT count(*) INTO v_n FROM strip_rows s
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = s.politician_id AND pc.topic_id = s.topic_id
                        AND pc.sources && (SELECT array_agg(url) FROM fab_urls));
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % strip rows no longer cite a fabricated url — re-review', v_n; END IF;

  -- The whole affected set must be exactly retire + strip: no row citing a fabricated url may be
  -- unaccounted for. This is what catches a stale classification artifact.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM fab_urls)
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM retire_rows)
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM strip_rows);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % affected rows are in neither list — classification is stale', v_n; END IF;

  -- 🔴 CROSS-CHECK THE STRUCTURAL HALF IN SQL. Sole-sourced is derivable without reading anything:
  -- after removing the fabricated urls no citation survives. If SQL disagrees with the read
  -- classification, the artifact is stale and nothing should be deleted.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM fab_urls)
     AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM fab_urls));
  IF v_n <> 141 THEN
    RAISE EXCEPTION '1564: SQL says % sole-sourced rows, classification says 141', v_n; END IF;

  -- Every sole-sourced row must be in the retire list (never merely stripped to an empty citation set).
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM fab_urls)
     AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM fab_urls))
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM retire_rows);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % sole-sourced rows are not being retired', v_n; END IF;

  -- 🔴 ORPHAN CONTEXT ROWS ARE IN SCOPE AND THE ANSWER COUNT WILL NOT MATCH THE ROW COUNT BECAUSE OF
  -- THEM. Some rows are voter-facing reasoning with no answer behind it (the ~546-row orphan class,
  -- still undiagnosed corpus-wide). Deleting one removes a context row but no answer, so asserting
  -- "answers fell by exactly <rows>" fails — the first dry run of this migration failed on exactly that,
  -- which is the guard doing its job. Count them here and hold both totals to their true values rather
  -- than relaxing the check.
  SELECT count(*) INTO v_orphans
    FROM retire_rows r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id);
  RAISE NOTICE '1564: % of 298 retire rows are orphan context (no answer behind them)', v_orphans;

  SELECT array_agg(DISTINCT politician_id) INTO v_cohort FROM retire_rows;

  -- ---- retire ----
  DELETE FROM inform.politician_answers pa USING retire_rows r
   WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id;

  DELETE FROM inform.politician_context pc USING retire_rows r
   WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id;

  -- ---- strip the fabricated citations from the rows that keep a real source ----
  UPDATE inform.politician_context pc
     SET sources = ARRAY(SELECT s FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM fab_urls))
    FROM strip_rows sr
   WHERE pc.politician_id = sr.politician_id AND pc.topic_id = sr.topic_id;

  -- ---- null the timestamp for politicians emptied to zero answers ----
  UPDATE essentials.politicians p
     SET last_stances_researched_at = NULL
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  GET DIAGNOSTICS v_nulled = ROW_COUNT;
  RAISE NOTICE '1564: nulled last_stances_researched_at for % emptied politicians', v_nulled;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s IN (SELECT url FROM fab_urls);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % fabricated citations survived', v_n; END IF;

  -- Context falls by every retired row; answers fall by every retired row THAT HAD ONE.
  IF v_ctx_before - (SELECT count(*) FROM inform.politician_context) <> 298 THEN
    RAISE EXCEPTION '1564: context rows did not fall by exactly 298'; END IF;
  IF v_ans_before - (SELECT count(*) FROM inform.politician_answers) <> 298 - v_orphans THEN
    RAISE EXCEPTION '1564: answers fell by %, expected % (298 rows less % orphans)',
      v_ans_before - (SELECT count(*) FROM inform.politician_answers), 298 - v_orphans, v_orphans; END IF;

  -- 🔴 Stripping must never leave a row with no citation at all — that would be a silently
  -- unsourced voter-facing stance, which is worse than a retired one.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
    JOIN strip_rows sr ON sr.politician_id = pc.politician_id AND sr.topic_id = pc.topic_id
   WHERE coalesce(array_length(pc.sources, 1), 0) = 0;
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % stripped rows were left with zero citations', v_n; END IF;

  -- No emptied politician may retain a research timestamp.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % emptied politicians still carry a timestamp', v_n; END IF;

  RAISE NOTICE '1564: retired 298 rows, stripped citations from 90 rows, % politicians emptied',
    (SELECT count(*) FROM unnest(v_cohort) c(id)
      WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = c.id));
END $$;

COMMIT;
