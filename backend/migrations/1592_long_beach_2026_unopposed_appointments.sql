-- 1592_long_beach_2026_unopposed_appointments.sql
--
-- Record the last two unrecorded rows on the 2026 LA County Primary election: Long Beach City Attorney
-- (Dawn McIntosh) and Long Beach City Prosecutor (Doug Haubert). Both `won`. 2 candidate rows.
--
--   Rollback: UPDATE essentials.race_candidates SET result=NULL, result_source=NULL,
--                    result_recorded_at=NULL
--              WHERE id IN ('27a82ca2-e12b-4e48-87f9-9d7428490eb0','d28db3a2-d2c9-4e0f-a7ef-4b63ab90e812');
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1592_long_beach_2026_unopposed_appointments.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY THESE TWO CONTESTS ARE ABSENT FROM THE CERTIFIED RESULTS -- AND WHY THAT MEANS `won`
-- ---------------------------------------------------------------------------------------------------
-- Neither contest appears anywhere in the LA County certified canvass. Long Beach reported a Mayor, a
-- City Auditor and five council districts and nothing else. The earlier reading of that silence was
-- that these seats simply were not up in 2026, which would have left both rows unrecordable. That was
-- WRONG, and the silence has a specific and documented cause.
--
-- Both seats WERE up. The Long Beach City Clerk's official candidate list for the June 2, 2026 Primary
-- Nominating Election (updated 2026-04-24) shows City Attorney and City Prosecutor among the offices,
-- and shows EXACTLY ONE candidate filed for each -- Dawn McIntosh (qualified 2026-03-03) and Doug
-- Haubert (qualified 2026-03-05). Every office on that list with two or more candidates does appear in
-- the certified results; only the two single-candidate offices do not.
--
-- The mechanism is Long Beach Municipal Code section 1.15.150: where at the close of nominations no
-- more than one person has been nominated for a city-wide office and no write-in papers have been
-- filed by the 81st day before the election, the City Council may appoint the sole nominee. The
-- Council did exactly that, in two parallel resolutions, each of which cancels only its own contest:
--
--   * City Attorney -- appoints Dawn A. McIntosh to a full four-year term commencing the third Tuesday
--     of December 2026 and cancels the June 2 Primary Nominating Election for City Attorney, while
--     expressly leaving the Mayor, City Auditor, CITY PROSECUTOR and council district elections
--     untouched.
--   * City Prosecutor -- appoints Douglas P. Haubert on the same terms and cancels the June 2 election
--     for City Prosecutor, expressly leaving the Mayor, City Auditor, CITY ATTORNEY and council
--     district elections untouched.
--
-- Each resolution certifies that only one candidate was nominated and that NO write-in nomination
-- papers were received for that office. Section 4 of each is the clause that settles the value here:
-- the appointee "shall qualify and take office and serve exactly as if elected at a municipal
-- election."
--
-- CARE WORTH REPEATING: the City Attorney resolution names the City Prosecutor election as still going
-- ahead, and vice versa. Reading either resolution alone would produce the confident, wrong conclusion
-- that the other contest was held and its result is missing. Both documents are needed.
--
-- `won` is the right value -- the vocabulary defines it as carrying the race and explicitly includes
-- unopposed. `lost` and `not_nominated` are both false: each was the sole nominee and each is taking
-- the office. There are no vote totals to cite because no vote was taken, which is why the citation is
-- the appointing resolution rather than a canvass.
--
-- Sources (all fetched 2026-08-07):
--   longbeach.gov/globalassets/city-clerk/media-library/documents/elections/2026/pne-060226-official-candidates-for-website
--   longbeach.gov/globalassets/city-clerk/media-library/documents/elections/2026/appointment-of-dawn-mcintosh-to-the-office-of-city-attorney
--   longbeach.gov/globalassets/city-clerk/media-library/documents/elections/2026/appointment-of-doug-haubert-to-the-office-of-city-prosecutor
-- ---------------------------------------------------------------------------------------------------

BEGIN;

UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Unopposed. Long Beach City Council resolution appointing Dawn A. McIntosh to the office of City Attorney for a full four-year term commencing the third Tuesday of December 2026, and cancelling the June 2 2026 Primary Nominating Election for City Attorney, adopted under Long Beach Municipal Code sec. 1.15.150 after the City Clerk certified that she was the only candidate nominated at the close of nominations on 2026-03-06 and that no write-in nomination papers were filed (longbeach.gov/globalassets/city-clerk/media-library/documents/elections/2026/appointment-of-dawn-mcintosh-to-the-office-of-city-attorney, fetched 2026-08-07). Section 4: the appointee serves "exactly as if elected at a municipal election". Corroborated by the City Clerk official candidate list for the June 2 2026 Primary Nominating Election, which lists her as the sole City Attorney filer. The contest therefore appears nowhere in the LA County certified canvass.'
 WHERE id = '27a82ca2-e12b-4e48-87f9-9d7428490eb0';  -- Dawn McIntosh, Long Beach City Attorney

UPDATE essentials.race_candidates SET result='won', result_recorded_at='2026-08-07T00:00:00Z',
  result_source='Unopposed. Long Beach City Council resolution appointing Douglas P. Haubert to the office of City Prosecutor for a full four-year term commencing the third Tuesday of December 2026, and cancelling the June 2 2026 Primary Nominating Election for City Prosecutor, adopted under Long Beach Municipal Code sec. 1.15.150 after the City Clerk certified that he was the only candidate nominated at the close of nominations on 2026-03-06 and that no write-in nomination papers were filed (longbeach.gov/globalassets/city-clerk/media-library/documents/elections/2026/appointment-of-doug-haubert-to-the-office-of-city-prosecutor, fetched 2026-08-07). Section 4: the appointee serves "exactly as if elected at a municipal election". Corroborated by the City Clerk official candidate list for the June 2 2026 Primary Nominating Election, which lists him as the sole City Prosecutor filer. The contest therefore appears nowhere in the LA County certified canvass.'
 WHERE id = 'd28db3a2-d2c9-4e0f-a7ef-4b63ab90e812';  -- Doug Haubert, Long Beach City Prosecutor

COMMIT;
