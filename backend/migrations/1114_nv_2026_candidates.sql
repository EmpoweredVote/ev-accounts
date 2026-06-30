-- Migration 1114: Seed Nov 3 2026 NV general-election candidates for statewide + US House races
--
-- Populates essentials.race_candidates for the 10 in-scope NV 2026 general-election races
-- seeded in Phase 167 (migration 1112): 6 STATE_EXEC (Governor, Lt. Governor, Attorney General,
-- Secretary of State, Treasurer, Controller) + 4 NATIONAL_LOWER (NV-01...NV-04).
--
-- Candidates are the verified Nov 3 general-election ballot, confirmed against NV SoS official
-- primary results (nvsos.gov/SOSelectionPages/results/2026StateWidePrimary/ElectionSummary.aspx)
-- and multiple AP-called news sources. Only CONFIRMED candidates are seeded -- evidence-only (D-04).
--
-- Incumbents are linked to their existing politician records (politician_id) so the feed shows
-- their photo/profile via COALESCE(rc.photo_url, pi.url). Cross-office links (D-02): Aaron Ford
-- (current AG running for Governor, politician_id b71cb940) and Nicole Cannizzaro (current NV
-- State Senator running for AG, politician_id 94b171c0) are linked by live-queried politician_id.
-- Carrie Buck (NV State Senator running for NV-01) has NO Phase-160 record -> NULL.
-- Teresa Benitez-Thompson (former Assembly, running for NV-02) has NO record -> NULL.
-- Challengers with no existing record have politician_id = NULL; headshots added in Plan 02 via
-- find-headshots. Party is intentionally NOT stored (antipartisan design -- D-06).
--
-- Race IDs resolved via Wave 0 live query against essentials.races (gen_random_uuid() in mig 1112):
--   Governor:         7744880b-82b1-404a-9f48-58a505debcd5
--   Lt. Governor:     f45501be-ba2f-4e0e-b7d2-b55c187e32a9
--   Attorney General: b5cfa5be-0eda-452b-b9e4-99b75f090ee1
--   Secretary of State: 717fee53-f871-41fd-a350-233c8da669f5
--   Treasurer:        1dc513cd-30d0-4eb6-9af6-917a8525c14e
--   Controller:       0180490c-b2e0-4b9b-9514-92382279fc9f
--   NV-01:            a5295941-38b1-4c7f-8edf-39097ad3fb0a
--   NV-02:            0c470cc0-5250-43f1-b7f7-57778cadacc6
--   NV-03:            79e7fb35-a73a-478c-847d-553e9ad11e7c
--   NV-04:            81eb1a27-b710-42c3-a27c-a2c0153c2820
--
-- Held back (not yet certified -- add after official certification):
--   * Governor independents (Battenberg et al.) -- declared but cert status unconfirmed (D-04)
--   * NV-01 independents (Bobby Khan, Steven St John, Anthony Thomas Jr., Victor Willert) -- same
-- Idempotent: skips a (race_id, full_name) pair that already exists.
-- NO schema_migrations INSERT (D-06; on-disk counter authoritative).

BEGIN;

-- ============================================================
-- SECTION 1: Statewide executive races (6 offices, STATE_EXEC)
-- All race_ids resolved via Wave 0 pre-check query against
-- essentials.races WHERE election = 'NV 2026 Statewide General'.
-- ============================================================
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT v.race_id::uuid, v.politician_id::uuid, v.full_name, v.first_name, v.last_name,
       v.is_incumbent, 'active', v.source
FROM (VALUES
  -- Governor of Nevada (race 7744880b)
  -- Joe Lombardo: sitting Governor (is_incumbent=true); politician_id f8e66045 (Phase 159, ext -3200001)
  ('7744880b-82b1-404a-9f48-58a505debcd5', 'f8e66045-33cc-4f0e-ae31-58f58e148f94', 'Joe Lombardo', 'Joe', 'Lombardo', true,
   'https://en.wikipedia.org/wiki/2026_Nevada_gubernatorial_election'),
  -- Aaron Ford: current AG (D-02 cross-office link) running for Governor; politician_id b71cb940 (Phase 159, ext -3200003)
  ('7744880b-82b1-404a-9f48-58a505debcd5', 'b71cb940-9a37-4935-8340-bf878c0ad288', 'Aaron Ford', 'Aaron', 'Ford', false,
   'https://en.wikipedia.org/wiki/2026_Nevada_gubernatorial_election'),

  -- Lieutenant Governor of Nevada (race f45501be)
  -- Stavros Anthony: sitting Lt. Governor (is_incumbent=true); politician_id 1997a34f (Phase 159, ext -3200002)
  ('f45501be-ba2f-4e0e-b7d2-b55c187e32a9', '1997a34f-1aba-4832-be59-37a8074fc26a', 'Stavros Anthony', 'Stavros', 'Anthony', true,
   'https://www.nbcnews.com/politics/2026-primary-elections/nevada-lieutenant-governor-results'),
  -- Sandra Jauregui: Assembly Majority Leader; no existing politician record -> NULL
  ('f45501be-ba2f-4e0e-b7d2-b55c187e32a9', NULL, 'Sandra Jauregui', 'Sandra', 'Jauregui', false,
   'https://www.nbcnews.com/politics/2026-primary-elections/nevada-lieutenant-governor-results'),

  -- Attorney General of Nevada -- OPEN SEAT (Aaron Ford ran for Gov; is_incumbent=false ALL)
  -- Nicole Cannizzaro: D-02 cross-office (current NV State Senator, Phase 160); politician_id 94b171c0
  ('b5cfa5be-0eda-452b-b9e4-99b75f090ee1', '94b171c0-e3b1-4c15-bc6c-27035a0dc831', 'Nicole Cannizzaro', 'Nicole', 'Cannizzaro', false,
   'https://www.reviewjournal.com/news/politics-and-government/nevada/cannizzaro-wins-democratic-attorney-general-primary-other-statewide-races-competitive-3836096/'),
  -- Adriana Guzman Fralick: no existing record -> NULL
  ('b5cfa5be-0eda-452b-b9e4-99b75f090ee1', NULL, 'Adriana Guzman Fralick', 'Adriana', 'Guzman Fralick', false,
   'https://www.reviewjournal.com/news/politics-and-government/nevada/cannizzaro-wins-democratic-attorney-general-primary-other-statewide-races-competitive-3836096/'),

  -- Secretary of State of Nevada (race 717fee53)
  -- Cisco Aguilar: sitting SoS (is_incumbent=true); politician_id dbf13dfe (Phase 159, ext -3200004)
  ('717fee53-f871-41fd-a350-233c8da669f5', 'dbf13dfe-703f-420a-8073-5ac2b564d80c', 'Cisco Aguilar', 'Cisco', 'Aguilar', true,
   'https://www.kolotv.com/2026/06/16/marchant-wins-gop-primary-nevada-secretary-state/'),
  -- Jim Marchant: no existing record -> NULL
  ('717fee53-f871-41fd-a350-233c8da669f5', NULL, 'Jim Marchant', 'Jim', 'Marchant', false,
   'https://www.kolotv.com/2026/06/16/marchant-wins-gop-primary-nevada-secretary-state/'),

  -- State Treasurer of Nevada (race 1dc513cd) -- OPEN SEAT (Conine term-limited, ran for AG, lost; NO row for Conine; is_incumbent=false ALL)
  -- Tya Mathis-Coleman: Deputy State Treasurer; no existing record -> NULL
  ('1dc513cd-30d0-4eb6-9af6-917a8525c14e', NULL, 'Tya Mathis-Coleman', 'Tya', 'Mathis-Coleman', false,
   'https://www.reviewjournal.com/news/politics-and-government/nevada/cannizzaro-wins-democratic-attorney-general-primary-other-statewide-races-competitive-3836096/'),
  -- Drew Johnson: policy analyst; no existing record -> NULL
  ('1dc513cd-30d0-4eb6-9af6-917a8525c14e', NULL, 'Drew Johnson', 'Drew', 'Johnson', false,
   'https://www.reviewjournal.com/news/politics-and-government/nevada/johnson-carter-treasurer-primary-stays-razor-thin-as-nevada-count-continues-3836538/'),

  -- State Controller of Nevada (race 0180490c)
  -- Andy Matthews: sitting Controller (is_incumbent=true); confirmed external_id=-3200006 (mig 1050); politician_id 07a8598f
  ('0180490c-b2e0-4b9b-9514-92382279fc9f', '07a8598f-666f-4ac5-b6ee-09cb9f815783', 'Andy Matthews', 'Andy', 'Matthews', true,
   'https://www.nvsos.gov/SOSelectionPages/results/2026StateWidePrimary/ElectionSummary.aspx'),
  -- Michael MacDougall: teacher; no existing record -> NULL
  ('0180490c-b2e0-4b9b-9514-92382279fc9f', NULL, 'Michael MacDougall', 'Michael', 'MacDougall', false,
   'https://thenevadaindependent.com/article/2026-nevada-primary-election-results-live-blog')

) AS v(race_id, politician_id, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND rc.full_name = v.full_name
);

-- ============================================================
-- SECTION 2: US House races (4 districts, NATIONAL_LOWER)
-- All race_ids resolved via Wave 0 pre-check query.
-- Note: NV-02 is an OPEN SEAT (Amodei retired); is_incumbent=false all candidates.
-- Lynn Chapman (IAP, NV-02) is confirmed on general ballot per 2news.com (2026-06-30).
-- NV-01 independents and Governor independents held back (D-04; see held-back comment above).
-- ============================================================
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT v.race_id::uuid, v.politician_id::uuid, v.full_name, v.first_name, v.last_name,
       v.is_incumbent, 'active', v.source
FROM (VALUES
  -- NV-01 (race a5295941) -- Dina Titus incumbent
  -- Dina Titus: sitting NV-01 Rep (is_incumbent=true); politician_id 786af5d2 (Phase 159, ext -32001)
  ('a5295941-38b1-4c7f-8edf-39097ad3fb0a', '786af5d2-9502-401c-a3ed-61de88e589e9', 'Dina Titus', 'Dina', 'Titus', true,
   'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Nevada'),
  -- Carrie Buck: NV State Senator (D-02 check ran: NO Phase-160 record found) -> NULL
  ('a5295941-38b1-4c7f-8edf-39097ad3fb0a', NULL, 'Carrie Buck', 'Carrie', 'Buck', false,
   'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Nevada'),

  -- NV-02 (race 0c470cc0) -- OPEN SEAT (Amodei retired; is_incumbent=false ALL)
  -- Lynn Chapman (IAP) confirmed on general ballot per 2news.com
  ('0c470cc0-5250-43f1-b7f7-57778cadacc6', NULL, 'David Flippo', 'David', 'Flippo', false,
   'https://www.pbs.org/newshour/politics/trump-backed-david-flippo-wins-nevada-republican-primary-for-u-s-house-seat'),
  -- Teresa Benitez-Thompson: former Assembly; D-02 check ran: NO record found -> NULL
  ('0c470cc0-5250-43f1-b7f7-57778cadacc6', NULL, 'Teresa Benitez-Thompson', 'Teresa', 'Benitez-Thompson', false,
   'https://www.2news.com/news/local/voters-decide-david-flippo-teresa-benitez-thompson-advance-to-november/article_ea56d1ef-11f7-47a1-9308-d0733e5d9558.html'),
  ('0c470cc0-5250-43f1-b7f7-57778cadacc6', NULL, 'Lynn Chapman', 'Lynn', 'Chapman', false,
   'https://www.2news.com/news/local/voters-decide-david-flippo-teresa-benitez-thompson-advance-to-november/article_ea56d1ef-11f7-47a1-9308-d0733e5d9558.html'),

  -- NV-03 (race 79e7fb35) -- Susie Lee incumbent
  -- Susie Lee: sitting NV-03 Rep (is_incumbent=true); politician_id 325c7cae (Phase 159, ext -32003)
  ('79e7fb35-a73a-478c-847d-553e9ad11e7c', '325c7cae-aae6-4d7b-9c03-e707c7423d3c', 'Susie Lee', 'Susie', 'Lee', true,
   'https://www.sanfordherald.com/news/national/candidates-notch-wins-in-nevada-u-s-house-primaries/article_ea45dd0b-74f8-5e3e-bff4-2d9b054992a5.html'),
  -- Marty O''Donnell: audio producer; no existing record -> NULL (apostrophe escaped)
  ('79e7fb35-a73a-478c-847d-553e9ad11e7c', NULL, 'Marty O''Donnell', 'Marty', 'O''Donnell', false,
   'https://www.sanfordherald.com/news/national/candidates-notch-wins-in-nevada-u-s-house-primaries/article_ea45dd0b-74f8-5e3e-bff4-2d9b054992a5.html'),

  -- NV-04 (race 81eb1a27) -- Steven Horsford incumbent
  -- Steven Horsford: sitting NV-04 Rep (is_incumbent=true); politician_id 7644cd40 (Phase 159, ext -32004)
  ('81eb1a27-b710-42c3-a27c-a2c0153c2820', '7644cd40-b5c1-494a-8e65-f3126fc7f9ee', 'Steven Horsford', 'Steven', 'Horsford', true,
   'https://www.thecentersquare.com/nevada/article_c1f7da4e-1714-4ce0-a97a-931ed2458904.html'),
  -- Cody Whipple: rancher; no existing record -> NULL
  ('81eb1a27-b710-42c3-a27c-a2c0153c2820', NULL, 'Cody Whipple', 'Cody', 'Whipple', false,
   'https://www.thecentersquare.com/nevada/article_c1f7da4e-1714-4ce0-a97a-931ed2458904.html')

) AS v(race_id, politician_id, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND rc.full_name = v.full_name
);

-- Verify per-race candidate counts after seeding.
SELECT r.position_name, d.district_type,
       count(rc.id) AS candidates,
       count(rc.politician_id) AS linked
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
JOIN essentials.offices o ON o.id = r.office_id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
WHERE e.name = 'NV 2026 Statewide General'
  AND d.district_type IN ('STATE_EXEC', 'NATIONAL_LOWER')
GROUP BY r.position_name, d.district_type
ORDER BY d.district_type, r.position_name;

COMMIT;
-- NO INSERT INTO schema_migrations -- on-disk counter is authoritative (D-06).
