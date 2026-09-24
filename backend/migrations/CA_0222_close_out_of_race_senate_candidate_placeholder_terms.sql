-- CA_0222_close_out_of_race_senate_candidate_placeholder_terms.sql
--
-- Slot CA_0222 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- The follow-up sweep CA_0216 (PR #700) asked for. CA_0216 closed the migration-196 "Candidate for U.S.
-- Senate — <State>" placeholder terms of Derek Dooley and Zach Wahls, the only two whose FEC record had
-- gone dark. This closes the ones the FEC signal missed: SIXTEEN more 2026 Senate candidates who are out
-- of the race but still hold a principal campaign committee and 2025-26 totals, so nothing in FEC says
-- the campaign ended. Each is confirmed below from the state's own election authority.
--
-- Every one of these terms came from the migration-1459 backfill: open-ended, term_start NULL,
-- start_precision 'unknown'. An open term reports its holder as the current occupant for ever, so
-- today all sixteen still resolve as live Senate candidates — address search with candidates on lists
-- them for every address in the state, and the FEC auto-match queue and run-fec-finance-summary.ts
-- still pick them up.
--
-- Same shape as CA_0216, which was applied and merged on 2026-09-24. What differs is called out.
--
-- ===========================================================================================
-- TARGETS (resolved by full_name + external_id + office title; UUIDs are environment-specific)
-- ===========================================================================================
--
--   person            party  state  last day     how         FEC ID      Form 2 received
--   Steve Marshall    R      AL     2026-05-19   defeated    S6AL00450   2025-05-29
--   Dakarai Larriett  D      AL     2026-06-16   defeated    S6AL00427   2025-04-01
--   Gary Crockett     D      LA     2026-06-27   defeated    S6LA00680*  2026-02-26
--   John Fleming      R      LA     2026-06-27   defeated    S6LA00318   2024-12-13
--   Graham Platner    D      ME     2026-07-10   withdrew    S6ME00373   2025-08-18
--   David Williams    R      VA     2026-08-04   defeated    S6VA00200   2025-11-17
--   Kim Farington     R      VA     2026-08-04   defeated    S6VA00143   2024-11-21
--   Alex Vindman      D      FL     2026-08-18   defeated    S6FL00855   2026-01-27
--   Jim Priest        D      OK     2026-08-25   defeated    S6OK04197   2026-01-06
--   Janak Joshi       R      CO     2026-04-11†  defeated    S6CO00440   2025-07-07
--   David Roth        D      ID     2026-09-01   withdrew    S6ID00138   2025-03-14
--   Seth Moulton      D      MA     2026-09-01   defeated    S6MA00296   2025-10-16   keeps MA-6 House seat
--   Haley M. Stevens  D      MI     2026-08-04   defeated    S6MI00426   2025-04-22   keeps MI-11 House seat
--   Mallory McMorrow  D      MI     2026-08-04   defeated    S6MI00392   2025-04-02
--   Angie Craig       DFL    MN     2026-08-11   defeated    S6MN00499   2025-04-29   keeps MN-2 House seat
--   Royce White       R      MN     2026-08-11   defeated    S4MN00502   2024-11-22
--
--   † the one date NOT taken from a state record — see Colorado below.
--   * Crockett has no politician_sources row in prod; S6LA00680 is the only FEC candidate by that name
--     in Louisiana for 2026 (DEM). It is cited for the start date only, and no link is written here.
--
-- ===========================================================================================
-- EVIDENCE (checked 2026-09-24, all from state election authorities; Wikipedia was the lead only)
-- ===========================================================================================
--
-- Alabama — Secretary of State; party-certified primary results (sos.alabama.gov/alabama-votes/voter/
--   election-information/2026). May 19 primary, June 16 runoff.
--   Marshall: finished THIRD in the Republican primary 2026-05-19 and missed the runoff —
--     Barry Moore 189,067 / Jared Hudson 123,672 / Steve Marshall 118,361 (office "Senator").
--     sos.alabama.gov/sites/default/files/05-29-2026/GOP%20Results.xlsx; the party's runoff
--     certification (RepublicanPartyCertificationofCandidates2026PrimaryRunoff.pdf) names Hudson and
--     Moore only. Moore is the nominee.
--   Larriett: second in the Democratic primary 2026-05-19 (Everett Wess 132,373 / Larriett 96,307),
--     then lost the runoff 2026-06-16 — Wess 49,396 / Larriett 41,065.
--     .../election-2026/2026%20Democratic%20Primary%20Runoff%20Election%20Results.xlsx;
--     CertificationofResults-DemocraticParty-PrimaryRunoff.pdf names Wess.
--
-- Louisiana — Secretary of State, voterportal.sos.la.gov (ElectionResults Data blobs 20260516 and
--   20260627; ElectionDates marks both "ResultsOfficial": "1"). 2026 is the first year of CLOSED party
--   primaries for U.S. Senate: a first party primary 2026-05-16 and a second (runoff) 2026-06-27.
--   Crockett: "U. S. Senator -- Democratic Party". Runoff place on 05-16 (Jamie Davis 163,549 /
--     Crockett 90,791 / Nick Albares 90,498), then lost 06-27 — Davis 156,789 / Crockett 39,423
--     ("Defeated", race 70156).
--   Fleming: "U. S. Senator -- Republican Party". Runoff place on 05-16 (Julia Letlow 179,903 /
--     Fleming 113,437 / Bill Cassidy 99,496), then lost 06-27 — Letlow 180,002 / Fleming 136,591
--     ("Defeated", race 70157).
--
-- Maine — Secretary of State. Platner WON the Democratic primary 2026-06-09 (156,084 of 222,405;
--   "US Senate DEM - FINAL.xlsx"), then withdrew as the nominee. The SOS list "2026 Post Primary
--   Withdrawals & Replacement Candidates — Updated 9.22.26" records: US, D, Graham C. Platner, Date
--   Withdrawn 7/10/2026; replacement Troy D. Jackson (Allagash), received 7/27/2026. The SOS "2026
--   General Candidate List - FINAL" names Jackson (D) and Collins (R) and not Platner.
--   Last day = the withdrawal date.
--
-- Virginia — Department of Elections, enr.elections.virginia.gov "2026 August Republican Primary"
--   (API isOfficialResults = true, asOf 2026-08-18). The primary was 2026-08-04, not June: the 2026
--   primaries moved to August. Office "Member, United States Senate", summed from the precinct CSV:
--     Bert Mizusawa 124,271 / David E. Williams 69,725 / Kim Farington 47,357. Mizusawa is the nominee.
--
-- Florida — Division of Elections, results.elections.myflorida.com "August 18, 2026 Primary Election,
--   Democratic Primary, Official Results", United States Senator: Angie Nixon 705,835 / Alex Vindman
--   553,138. The candidate tracking system (dos.elections.myflorida.com/candidates, account 90509)
--   shows Vindman "Defeated" in the primary and "Eliminated" for the general.
--
-- Oklahoma — State Election Board, results.okelections.gov (both pages headed "Official Results").
--   Democratic primary 2026-06-16: N'Kiyla Jasmine Thomas 76,330 / Jim Priest 40,290 (+3 others);
--   runoff primary 2026-08-25: Thomas 79,229 / Priest 50,249.
--
-- Colorado — Secretary of State. Joshi never reached the ballot. The "2026 Official Primary Election
--   Candidate List" ("reflects the state ballot content certified to the counties on May 1") lists
--   only Mark Baisley for the Republican U.S. Senate nomination; the petition-candidate list shows no
--   Joshi petition (Hickenlooper is the only Senate petitioner); the September 4 general list omits
--   him. coloradosos.gov/pubs/elections/vote/files/2026/2026PrimaryCandidateListOfficial.xlsx,
--   .../2026PrimaryPetitionCandidates.xlsx. With no petition, the only route was 30% at the party's
--   state assembly, which he did not get.
--   † term_end 2026-04-11 is the date of the Colorado GOP state assembly (CSU Pueblo). That date comes
--   from Colorado Public Radio and county-party notices: the state party's site returns 403 and
--   publishes no assembly results, and the SOS does not record assembly votes. It is the day the
--   candidacy ended; the SOS certification (2026-05-01) is only the day that became official. If a
--   reviewer prefers a state-recorded date, 2026-05-01 is the one to use — the span is the only change.
--
-- Idaho — Secretary of State. Roth WON the Democratic primary 2026-05-19 (Roth 29,534 / Brad Moore
--   14,863 / Nickolas Bonds 3,344; canvass report archive.voteidaho.gov/results/2026/primary/
--   canvass_report_2026_primary.pdf, certified 2026-06-09), then withdrew. The SOS candidate-filing
--   portal (run.voteidaho.gov; api-run.voteidaho.gov FiledCandidates, isFinalList true) shows his
--   "11/03/2026 - 2026 GENERAL" filing as filingStatus "Withdrawn", withdrawalDate 2026-09-01. No
--   replacement Democrat filed. (He ANNOUNCED his exit on 2026-07-28; the filing date is used.)
--
-- Massachusetts — Secretary of the Commonwealth, electionstats.state.ma.us election 172905 "2026 U.S.
--   Senate Democratic Primary", 2026-09-01: Edward J. Markey 580,628 / Seth W. Moulton 314,198.
--   Moulton was not on the MA-6 House primary ballot (Dan Koh won it).
--
-- Michigan — Bureau of Elections. The BOE public candidate report for the 2026 GENERAL
--   (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) lists Abdul
--   El-Sayed as the Democratic U.S. Senate nominee, and neither Stevens nor McMorrow; the PRI report
--   shows all three qualified by petition. The Board of State Canvassers certified the 2026-08-04
--   primary and its list of nominees on 2026-08-24. mielections.us (the vote totals) was unreachable
--   from here, so the statewide counts are NOT taken from a state source.
--   McMorrow announced she was leaving the race in July (news only), but filed no withdrawal: she
--   stayed on the printed ballot (Oakland County official candidate list: withdrawal date blank) and
--   received votes, so her candidacy ended on primary day like Stevens'.
--   Stevens was not on the MI-11 House primary ballot.
--
-- Minnesota — Secretary of State, electionresultsfiles.sos.mn.gov/20260811/ussenate.txt, certified by
--   the State Canvassing Board 2026-08-18. U.S. Senator, 2026-08-11 State Primary:
--     DFL: Peggy Flanagan 411,853 / Angie Craig 274,920.   R: Michele Tafoya 211,813 / Royce White 45,374.
--   Craig was not on the MN-2 House primary ballot.
--
-- ===========================================================================================
-- WHAT THIS WRITES
-- ===========================================================================================
--
-- 1. office_terms: close each term and give it a start.
--      term_end   = the LAST day of the candidacy, inclusive (current_office_holders tests
--                   term_end >= CURRENT_DATE; office_terms_no_overlap uses daterange(..., '[]')):
--                   the day of the contest the candidate lost, or the withdrawal date.
--      how_ended  = 'defeated' for a lost contest.
--                   For a withdrawal it is left NULL: the office_terms_how_ended_check vocabulary
--                   (term_expired/resigned/defeated/retired/died/recalled/removed/redistricted/unknown)
--                   describes leaving a seat and has no word for withdrawing a candidacy, and 'unknown'
--                   would be false — the reason is known and is written into source. Same call CA_0216
--                   made for how_started.
--      term_start = the receipt date of the candidate's first FEC Form 2 (Statement of Candidacy) for
--                   the 2026 election — a recorded day, not an estimate (FEC /v1/filings/?form_type=F2;
--                   the docquery PDF path carries the same date). start_precision 'day'. Without a
--                   start, a closed term still answers office_holders_as_of() for every date before
--                   the loss — the CA_0171 defect.
--      how_started is left NULL, as in CA_0216.
--
--    🔴 NOT via essentials.vacate_office(): it sets offices.is_vacant + vacant_since, and a candidacy
--    placeholder is not a seat (CA_0216, 1824). The sixteen placeholder offices are KEPT, each still
--    holding its one (now closed) term, so offices_missing_terms does not move.
--
-- 2. politicians.is_incumbent, stated explicitly (CLAUDE.md), and a guarded no-op on every row today.
--    🔴 THREE are sitting U.S. Representatives: Moulton (MA-6), Stevens (MI-11), Craig (MN-2). Only the
--    Senate-candidacy term closes; the House term is not touched and is_incumbent stays TRUE. The other
--    thirteen hold no other modelled seat, so false. The checks use EXISTS over office_current_holder,
--    never a count of a politician-rooted join: that join returns one row per office held, and these
--    three hold two until this runs (the CA_0204 pre-flight trap). The history checks are scoped to the
--    placeholder office for the same reason — a House member is rightly returned for the House seat.
--
-- 3. politicians.finance_summary = NULL where it still holds the Senate-campaign snapshot. Once the term
--    closes, run-fec-finance-summary.ts (the only writer; its roster is CURRENT NATIONAL_* offices of
--    ACTIVE politicians) never visits these people again, so the value has no owner. Guarded on the
--    exact stale total_raised, so a value written later is never erased. Crockett has none already.
--    For the three Representatives the job DOES still visit them after this — as House members, from
--    their confirmed fec_house IDs — so the next run refills the column from the committee of the
--    seat they hold. The Senate snapshot is dropped either way: under the job's "sought seat wins" rule
--    it is only right while the Senate campaign is live.
--
-- 4. race_candidates: ONE row. Roth's "U.S. Senate Idaho" 2026-11-03 general row still reads 'active';
--    the SOS filing portal says Withdrawn. Set to 'withdrawn' (Platner's Maine general row is the
--    precedent), guarded on the row still being 'active'. Nothing else in race_candidates is touched.
--    No frontend renders finance_summary (CA_0216); contributions rows are untouched.
--
-- NOT CHANGED, on purpose (all as CA_0216):
--   - offices.is_vacant / vacant_since.
--   - transparent_motivations.politician_sources: every fec_senate row stays 'confirmed'. The ID is
--     still that person's; fecAdapter reads principal committees only.
--   - politicians.is_active: unchanged (true for fourteen; Crockett and Fleming were already false).
--     Whether a former candidate stays findable is a product call; closing the term already removes
--     them from every office-rooted and address-rooted read.
--   - race_candidates, apart from Roth's general row: the stale primary-only rows ('filed' or 'active'
--     after the primary) are reported in the PR, not fixed.
--
-- Dry run: the whole body wrapped BEGIN; ... ROLLBACK; against prod, applied TWICE in one transaction
-- to prove the re-run is a no-op, then the rollback confirmed by re-reading the rows.

BEGIN;

-- ---------------------------------------------------------------------------
-- Targets. external_id is NULL for Crockett, Williams and Farington, hence IS NOT DISTINCT FROM.
-- Names alone are not unique (two Steve Marshalls, two John Flemings, two Jim Priests), so the office
-- title and the term are part of the key.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE ca0222_close ON COMMIT DROP AS
SELECT v.person, p.id AS politician_id, t.id AS term_id, o.id AS office_id,
       v.fec_id, v.term_start::date AS term_start, v.term_end::date AS term_end, v.how_ended,
       v.stale_total_raised::numeric AS stale_total_raised, v.keeps_house_seat, v.expect_active, v.why
FROM (VALUES
  ('Steve Marshall', -400101::bigint, 'Candidate for U.S. Senate — Alabama', 'S6AL00450',
   '2025-05-29', '2026-05-19', 'defeated', '1298351.43', false, true,
   'finished third in the Republican primary 2026-05-19 and missed the runoff, Moore 189,067 / Hudson 123,672 / '
   'Marshall 118,361 (AL SOS 05-29-2026 GOP Results.xlsx; party runoff certification names Hudson and Moore)'),
  ('Dakarai Larriett', -400103::bigint, 'Candidate for U.S. Senate — Alabama', 'S6AL00427',
   '2025-04-01', '2026-06-16', 'defeated', '154254.02', false, true,
   'lost the Democratic primary runoff 2026-06-16, Wess 49,396 / Larriett 41,065 (AL SOS 2026 Democratic '
   'Primary Runoff Election Results.xlsx; party certification names Wess)'),
  ('Gary Crockett', NULL::bigint, 'Candidate for U.S. Senate — Louisiana', NULL,
   '2026-02-26', '2026-06-27', 'defeated', NULL, false, false,
   'lost the Democratic second party primary 2026-06-27, Davis 156,789 / Crockett 39,423 (LA SOS voterportal '
   '20260627 race 70156, official); FEC candidate S6LA00680, not linked in politician_sources'),
  ('John Fleming', -400119::bigint, 'Candidate for U.S. Senate — Louisiana', 'S6LA00318',
   '2024-12-13', '2026-06-27', 'defeated', '11286638.83', false, false,
   'lost the Republican second party primary 2026-06-27, Letlow 180,002 / Fleming 136,591 (LA SOS voterportal '
   '20260627 race 70157, official)'),
  ('Graham Platner', -400120::bigint, 'Candidate for U.S. Senate — Maine', 'S6ME00373',
   '2025-08-18', '2026-07-10', NULL, '21050419.38', false, true,
   'won the Democratic primary 2026-06-09, then WITHDREW as nominee 2026-07-10; Troy D. Jackson named '
   '2026-07-27 (ME SOS 2026 Post Primary Withdrawals & Replacement Candidates, updated 9.22.26)'),
  ('David Williams', NULL::bigint, 'Candidate for U.S. Senate — Virginia', 'S6VA00200',
   '2025-11-17', '2026-08-04', 'defeated', '97044.76', false, true,
   'lost the Republican primary 2026-08-04, Mizusawa 124,271 / Williams 69,725 / Farington 47,357 '
   '(VA ELECT enr.elections.virginia.gov 2026 August Republican Primary, official)'),
  ('Kim Farington', NULL::bigint, 'Candidate for U.S. Senate — Virginia', 'S6VA00143',
   '2024-11-21', '2026-08-04', 'defeated', '144778.14', false, true,
   'lost the Republican primary 2026-08-04, Mizusawa 124,271 / Williams 69,725 / Farington 47,357 '
   '(VA ELECT enr.elections.virginia.gov 2026 August Republican Primary, official)'),
  ('Alex Vindman', -400107::bigint, 'Candidate for U.S. Senate — Florida', 'S6FL00855',
   '2026-01-27', '2026-08-18', 'defeated', '16273862.45', false, true,
   'lost the Democratic primary 2026-08-18, Nixon 705,835 / Vindman 553,138 (FL DOS results.elections.myflorida.com, '
   'official; candidate tracking: Defeated / Eliminated)'),
  ('Jim Priest', -66000114::bigint, 'Candidate for U.S. Senate — Oklahoma', 'S6OK04197',
   '2026-01-06', '2026-08-25', 'defeated', '370493.38', false, true,
   'lost the Democratic runoff primary 2026-08-25, Thomas 79,229 / Priest 50,249 (OK State Election Board '
   'results.okelections.gov 20260825, Official Results)'),
  ('Janak Joshi', -400106::bigint, 'Candidate for U.S. Senate — Colorado', 'S6CO00440',
   '2025-07-07', '2026-04-11', 'defeated', '485987.2', false, true,
   'did not reach the Republican primary ballot: CO SOS 2026 Official Primary Election Candidate List '
   '(certified 2026-05-01) names only Baisley, and no Joshi petition was filed; eliminated at the CO GOP state '
   'assembly 2026-04-11 (assembly date per Colorado Public Radio, not a state record)'),
  ('David Roth', -400111::bigint, 'Candidate for U.S. Senate — Idaho', 'S6ID00138',
   '2025-03-14', '2026-09-01', NULL, '14626.74', false, true,
   'won the Democratic primary 2026-05-19 (29,534), then WITHDREW 2026-09-01 (ID SOS candidate-filing portal, '
   '2026 GENERAL filing: Withdrawn, withdrawalDate 2026-09-01); no replacement filed'),
  ('Seth Moulton', -200206::bigint, 'Candidate for U.S. Senate — Massachusetts', 'S6MA00296',
   '2025-10-16', '2026-09-01', 'defeated', '6213102.88', true, true,
   'lost the Democratic primary 2026-09-01, Markey 580,628 / Moulton 314,198 (MA electionstats 172905); '
   'keeps the MA-6 House seat'),
  ('Haley M. Stevens', -26011::bigint, 'Candidate for U.S. Senate — Michigan', 'S6MI00426',
   '2025-04-22', '2026-08-04', 'defeated', '11884632.43', true, true,
   'lost the Democratic primary 2026-08-04 (MI BOE 2026 GENERAL candidate report names El-Sayed as nominee; '
   'BSC certified 2026-08-24); keeps the MI-11 House seat'),
  ('Mallory McMorrow', -400123::bigint, 'Candidate for U.S. Senate — Michigan', 'S6MI00392',
   '2025-04-02', '2026-08-04', 'defeated', '11386720.36', false, true,
   'lost the Democratic primary 2026-08-04, still on the ballot with no withdrawal filed (MI BOE 2026 GENERAL '
   'candidate report names El-Sayed as nominee; BSC certified 2026-08-24)'),
  ('Angie Craig', -27002::bigint, 'Candidate for U.S. Senate — Minnesota', 'S6MN00499',
   '2025-04-29', '2026-08-11', 'defeated', '12746617.68', true, true,
   'lost the DFL primary 2026-08-11, Flanagan 411,853 / Craig 274,920 (MN SOS 20260811 ussenate.txt, '
   'canvassed 2026-08-18); keeps the MN-2 House seat'),
  ('Royce White', -400128::bigint, 'Candidate for U.S. Senate — Minnesota', 'S4MN00502',
   '2024-11-22', '2026-08-11', 'defeated', '661620.48', false, true,
   'lost the Republican primary 2026-08-11, Tafoya 211,813 / White 45,374 (MN SOS 20260811 ussenate.txt, '
   'canvassed 2026-08-18)')
) AS v(person, ext, title, fec_id, term_start, term_end, how_ended, stale_total_raised,
       keeps_house_seat, expect_active, why)
JOIN essentials.politicians  p ON p.full_name = v.person AND p.external_id IS NOT DISTINCT FROM v.ext
JOIN essentials.office_terms t ON t.politician_id = p.id
JOIN essentials.offices      o ON o.id = t.office_id AND o.title = v.title;

-- Counts the post-verify compares against, taken before anything is written.
CREATE TEMP TABLE ca0222_baseline ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.offices_missing_terms) AS missing_terms,
       (SELECT count(*) FROM essentials.office_terms t JOIN essentials.offices o ON o.id = t.office_id
         WHERE o.title LIKE 'Candidate for%' AND t.term_end IS NULL) AS open_placeholders,
       (SELECT count(*) FROM essentials.office_terms t JOIN ca0222_close c ON c.term_id = t.id
         WHERE t.term_end IS NULL) AS open_targets;

DO $$
DECLARE n int; d int;
BEGIN
  SELECT count(*), count(DISTINCT politician_id) INTO n, d FROM ca0222_close;
  IF n <> 16 OR d <> 16 THEN
    RAISE EXCEPTION 'PRE: resolved % target term rows for % people, expected 16 / 16 — a name, external_id or '
                    'office title changed', n, d;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record; n int;
BEGIN
  FOR r IN SELECT * FROM ca0222_close LOOP
    -- The placeholder holds exactly this one term. A second row means a successor or a duplicate
    -- appeared since authoring — review before closing.
    SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = r.office_id;
    IF n <> 1 THEN
      RAISE EXCEPTION 'PRE: % office % holds % term rows, expected exactly 1', r.person, r.office_id, n;
    END IF;

    -- Untouched (the open 1459 backfill row) or already closed by THIS migration. Anything else is a
    -- hand edit made since authoring; do not overwrite it.
    IF NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
       WHERE t.id = r.term_id
         AND (   (t.term_end IS NULL AND t.term_start IS NULL AND t.start_precision = 'unknown')
              OR (t.term_end = r.term_end AND t.term_start = r.term_start AND t.start_precision = 'day'
                  AND t.how_ended IS NOT DISTINCT FROM r.how_ended AND t.source LIKE '%CA_0222%'))
    ) THEN
      RAISE EXCEPTION 'PRE: % term % is neither the open 1459 backfill row nor the CA_0222-closed row — '
                      'someone changed it; review', r.person, r.term_id;
    END IF;

    -- is_incumbent follows from the seats held. EXISTS, never a counted politician-rooted join over
    -- office_current_holder: that join returns one row per office the person holds (CLAUDE.md).
    IF r.keeps_house_seat THEN
      IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                       JOIN essentials.offices o ON o.id = och.office_id
                       JOIN essentials.districts d ON d.id = o.district_id
                      WHERE och.politician_id = r.politician_id AND och.office_id <> r.office_id
                        AND d.district_type = 'NATIONAL_LOWER') THEN
        RAISE EXCEPTION 'PRE: % is expected to keep a current U.S. House seat and holds none', r.person;
      END IF;
    ELSIF EXISTS (SELECT 1 FROM essentials.office_current_holder och
                   WHERE och.politician_id = r.politician_id AND och.office_id <> r.office_id) THEN
      RAISE EXCEPTION 'PRE: % holds another current office — is_incumbent may need to stay true', r.person;
    END IF;

    -- The confirmed FEC link is the person the evidence is about. (Crockett has none; see header.)
    IF r.fec_id IS NOT NULL AND NOT EXISTS (
         SELECT 1 FROM transparent_motivations.politician_sources ps
          WHERE ps.essentials_politician_id = r.politician_id AND ps.source_system = 'fec_senate'
            AND ps.external_id = r.fec_id AND ps.research_status = 'confirmed') THEN
      RAISE EXCEPTION 'PRE: % has no confirmed fec_senate source %', r.person, r.fec_id;
    END IF;

    -- A future term_end would leave the row reporting as current and achieve nothing.
    IF r.term_end >= CURRENT_DATE OR r.term_start >= r.term_end THEN
      RAISE EXCEPTION 'PRE: % span % .. % is not a closed span in the past', r.person, r.term_start, r.term_end;
    END IF;

    -- Not flagged vacant now, and must not be after (a candidacy placeholder is not a seat).
    IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = r.office_id AND (is_vacant OR vacant_since IS NOT NULL)) THEN
      RAISE EXCEPTION 'PRE: % office % is flagged vacant — unexpected for a candidacy placeholder',
                      r.person, r.office_id;
    END IF;

    -- is_active is not written; say what it is so the post-verify can prove it did not move.
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = r.politician_id AND is_active = r.expect_active) THEN
      RAISE EXCEPTION 'PRE: % is_active is not %', r.person, r.expect_active;
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Close each term, with a sourced start. Guarded on term_end IS NULL: a re-run touches 0 rows and
--    cannot overwrite a date corrected by hand.
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms t
   SET term_start      = c.term_start,
       start_precision = 'day',
       term_end        = c.term_end,
       how_ended       = c.how_ended,
       source          = t.source || ' | candidacy closed by CA_0222 on 2026-09-24: ' || c.why
                                  || '; start = FEC Form 2 receipt ' || c.term_start
  FROM ca0222_close c
 WHERE t.id = c.term_id
   AND t.term_end IS NULL;

-- ---------------------------------------------------------------------------
-- 2. is_incumbent, explicitly: true only for someone who keeps a House seat (guarded no-op today).
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET is_incumbent = c.keeps_house_seat
  FROM ca0222_close c
 WHERE p.id = c.politician_id
   AND p.is_incumbent IS DISTINCT FROM c.keeps_house_seat;

-- ---------------------------------------------------------------------------
-- 3. Drop the ownerless Senate-campaign finance_summary — only the exact stale value.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET finance_summary = NULL
  FROM ca0222_close c
 WHERE p.id = c.politician_id
   AND p.finance_summary IS NOT NULL
   AND c.stale_total_raised IS NOT NULL
   AND (p.finance_summary->>'total_raised')::numeric = c.stale_total_raised;

-- ---------------------------------------------------------------------------
-- 4. Roth's Idaho general row: withdrawn, per the SOS filing portal. Guarded on 'active'.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET candidate_status = 'withdrawn',
       source           = coalesce(rc.source, '') || ' | withdrawn per ID SOS candidate-filing portal (withdrawalDate '
                                    || '2026-09-01), CA_0222',
       updated_at       = now()
  FROM ca0222_close c, essentials.races ra, essentials.elections e
 WHERE c.person = 'David Roth'
   AND rc.politician_id = c.politician_id
   AND ra.id = rc.race_id AND e.id = ra.election_id
   AND ra.position_name = 'U.S. Senate Idaho' AND e.election_date = '2026-11-03'
   AND rc.candidate_status = 'active';

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record; b record; n int;
BEGIN
  FOR r IN SELECT * FROM ca0222_close LOOP
    IF NOT EXISTS (
      SELECT 1 FROM essentials.office_terms
       WHERE id = r.term_id AND term_start = r.term_start AND start_precision = 'day'
         AND term_end = r.term_end AND how_ended IS NOT DISTINCT FROM r.how_ended AND source LIKE '%CA_0222%'
    ) THEN
      RAISE EXCEPTION 'POST: % term % did not close to % .. % / %', r.person, r.term_id,
                      r.term_start, r.term_end, coalesce(r.how_ended, 'NULL');
    END IF;

    -- THE POINT: the candidacy no longer resolves as current. A House member keeps the House seat.
    IF EXISTS (SELECT 1 FROM essentials.office_current_holder
                WHERE office_id = r.office_id AND politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: % still resolves as the current holder of the placeholder', r.person;
    END IF;
    IF r.keeps_house_seat THEN
      IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                       JOIN essentials.offices o ON o.id = och.office_id
                       JOIN essentials.districts d ON d.id = o.district_id
                      WHERE och.politician_id = r.politician_id AND d.district_type = 'NATIONAL_LOWER') THEN
        RAISE EXCEPTION 'POST: % lost the U.S. House seat', r.person;
      END IF;
    ELSIF EXISTS (SELECT 1 FROM essentials.office_current_holder WHERE politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: % still resolves as a current office holder', r.person;
    END IF;

    -- History answers inside the span and not outside it. Scoped to THIS office: a House member is
    -- rightly returned for the House seat on every one of these dates.
    IF NOT EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_end) h
                    WHERE h.office_id = r.office_id AND h.politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) lost % — the last day of the candidacy', r.term_end, r.person;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_start) h
                    WHERE h.office_id = r.office_id AND h.politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) lost % — the first day of the candidacy', r.term_start, r.person;
    END IF;
    IF EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_end + 1) h WHERE h.office_id = r.office_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) still returns the % placeholder the day after', r.term_end + 1, r.person;
    END IF;
    IF EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_start - 1) h WHERE h.office_id = r.office_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) returns the % placeholder before the candidacy began', r.term_start - 1, r.person;
    END IF;

    -- The placeholder office is kept, holds its one (closed) term, and is NOT flagged vacant.
    SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = r.office_id;
    IF n <> 1 THEN
      RAISE EXCEPTION 'POST: % office % holds % term rows, expected 1', r.person, r.office_id, n;
    END IF;
    IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = r.office_id AND (is_vacant OR vacant_since IS NOT NULL)) THEN
      RAISE EXCEPTION 'POST: % office % was flagged vacant', r.person, r.office_id;
    END IF;

    -- Politician row: is_incumbent as stated, snapshot gone, is_active untouched.
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                    WHERE id = r.politician_id AND is_incumbent = r.keeps_house_seat
                      AND finance_summary IS NULL AND is_active = r.expect_active) THEN
      RAISE EXCEPTION 'POST: % politician row not in the expected state (is_incumbent %, finance_summary NULL, '
                      'is_active %)', r.person, r.keeps_house_seat, r.expect_active;
    END IF;

    -- The FEC link is untouched.
    IF r.fec_id IS NOT NULL AND NOT EXISTS (
         SELECT 1 FROM transparent_motivations.politician_sources ps
          WHERE ps.essentials_politician_id = r.politician_id AND ps.source_system = 'fec_senate'
            AND ps.external_id = r.fec_id AND ps.research_status = 'confirmed') THEN
      RAISE EXCEPTION 'POST: % confirmed fec_senate source % changed', r.person, r.fec_id;
    END IF;
  END LOOP;

  -- Roth's general row is withdrawn; the rest of the Idaho general roster is untouched.
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                   JOIN ca0222_close c ON c.politician_id = rc.politician_id AND c.person = 'David Roth'
                   JOIN essentials.races ra ON ra.id = rc.race_id
                   JOIN essentials.elections e ON e.id = ra.election_id
                  WHERE ra.position_name = 'U.S. Senate Idaho' AND e.election_date = '2026-11-03'
                    AND rc.candidate_status = 'withdrawn') THEN
    RAISE EXCEPTION 'POST: Roth''s Idaho general race_candidates row is not withdrawn';
  END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id JOIN essentials.elections e ON e.id = ra.election_id
   WHERE ra.position_name = 'U.S. Senate Idaho' AND e.election_date = '2026-11-03' AND rc.candidate_status = 'active';
  IF n <> 4 THEN
    RAISE EXCEPTION 'POST: % active Idaho general Senate candidates, expected 4 (Risch, Achilles, Fleming, Loesby)', n;
  END IF;

  -- Nothing else moved: exactly the targets that were open are now closed, and no office lost its term.
  SELECT * INTO b FROM ca0222_baseline;
  SELECT count(*) INTO n FROM essentials.office_terms t JOIN essentials.offices o ON o.id = t.office_id
   WHERE o.title LIKE 'Candidate for%' AND t.term_end IS NULL;
  IF n <> b.open_placeholders - b.open_targets THEN
    RAISE EXCEPTION 'POST: % open "Candidate for" terms, expected % - %', n, b.open_placeholders, b.open_targets;
  END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms;
  IF n <> b.missing_terms THEN
    RAISE EXCEPTION 'POST: offices_missing_terms moved % -> % — closing a term must not orphan an office',
                    b.missing_terms, n;
  END IF;

  SELECT count(*) INTO n FROM ca0222_close;
  RAISE NOTICE 'CA_0222 applied: % of % candidacy terms closed this run (the rest were already closed); open '
               '"Candidate for" terms % -> %', b.open_targets, n, b.open_placeholders,
               b.open_placeholders - b.open_targets;
END $$;

COMMIT;
