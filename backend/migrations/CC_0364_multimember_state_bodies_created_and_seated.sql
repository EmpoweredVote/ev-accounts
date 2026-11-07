-- CC_0364 — the seven 2026 state-executive voteboxes that fill ONE SEAT OF A MULTI-MEMBER BODY:
--           create all 37 seats of those seven bodies, SEAT EVERY CURRENT MEMBER, and record
--           the 11 winners Ballotpedia has called.
--
-- 🔴🔴 THE BLOCKER WAS A SEAT-NUMBERING DECISION, AND PRODUCTION HAD ALREADY MADE IT.
--   outstanding-state-exec-2026-11-06.json put these seven aside because creating one office
--   for "the seat up in 2026" leaves no way to tell it from the seats up in 2028. Arizona's
--   Corporation Commission answers that: ONE chamber, ONE shared STATE_EXEC district on the
--   state FIPS, and FIVE identical offices all titled "Commissioner" — no numbers anywhere —
--   with the 2026 contest recorded as ONE race carrying seats = 2. Every body here is built
--   that way, and every seat of every body is created so the chamber is whole.
--
-- 🔴🔴 district_type IS A ROUTING KEY, NOT A LABEL — and this nearly cost Michigan its board.
--   buildStatewideQuery admits NATIONAL_UPPER, NATIONAL_EXEC, STATE_EXEC, NATIONAL_JUDICIAL
--   and JUDICIAL by type. STATE_BOARD and STATE_BOARD_EDUCATION reach a voter ONLY through a
--   geofence join keyed on a particular mtfcc (X0003 Utah, X-CA-SBOE California, G5220 for DC),
--   because those boards are DISTRICTED. Michigan's State Board of Education is elected
--   statewide at large and has no polygon of its own, so filing it under the type whose NAME
--   fits would have made all eight members unreachable from every Michigan address, silently.
--   All seven bodies are STATE_EXEC, which is also what Arizona's commission already is.
--
-- 🔴 AN OFFICE WITH NO office_terms ROW RAISES THE DRIFT BASELINE, so this file seats people.
--   The unflagged essentials.offices_missing_terms baseline is 238 and must never be raised;
--   35 new offices left unseated would take it to 273. Every new office is created WITH its
--   current member seated and the post-verify asserts the baseline is still exactly 238.
--   ⚠ THE HOLDER IS NOT THE WINNER. 4 of the 11 winners are someone other than the sitting
--     member, and the people seated here are the SITTING ones.
--
-- WHAT IT WRITES:
--   7 chambers · 7 districts · 35 offices · 35 office_terms · 7 races · 61 politicians · 36 candidacies
--   2 offices MOVED into the OHA board chamber, and the 2 singleton chambers and 2 singleton
--   districts they leave behind DELETED.
--
--   HI OHA   9 seats · 3 filled · outgoing: Keoni Souza, Brickwood Galuteria, John Waihee IV · 🏆 Keoni Souza, Ikaika Anderson, Brickwood Galuteria
--   MI SBE   8 seats · 2 filled · outgoing: Judith Pritchett, Tiffany Tilley · 🏆 Judith Pritchett, Tiffany Tilley
--   MI MSU   8 seats · 2 filled · outgoing: Brianna Scott, Kelly Tebay · 🏆 Brianna Scott, Kelly Tebay
--   ND PSC   3 seats · 1 filled · outgoing: Sheri Haugen-Hoffart · 🏆 Sheri Haugen-Hoffart
--   OK CC    3 seats · 1 filled · outgoing: Todd Hiett · 🏆 Brad Boles
--   SD PUC   3 seats · 1 filled · outgoing: Gary Hanson · 🏆 Don Haggar
--   TX RRC   3 seats · 1 filled · outgoing: Jim Wright · 🏆 Jon Rosenthal
--
-- 🔴 EVERY RACE ATTACHES TO THE OFFICE OF THE MEMBER WHOSE SEAT WAS ACTUALLY UP. A race points
--   at one office, and that is what a December seating pass will replace. Arizona's existing
--   2-seat race hangs off an arbitrary one of its five offices; this file can do better because
--   every outgoing member is sourced:
--     · SD — the Commission's own home page: Gary Hanson, "Term Ends 2027"
--     · OK — the Commission's own Commissioner's Terms table: Todd Hiett, 01/11/2021-01/11/2027
--     · TX — Jim Wright, assumed 2021-01-01, term ends 2027-01-01. AP also calls this race and
--            labels the seat "Term Exp 2032" — the only seat label any source in this programme
--            publishes, and it is recorded in the race description rather than in a title,
--            because a label naming a term goes stale the next time the seat is filled.
--     · MI — Pritchett and Tilley (terms end 2027-01-01); Scott and Tebay (2027-01-01)
--     · ND — Sheri Haugen-Hoffart, who was re-elected
--     · HI — Souza, Galuteria and Waihee IV; the fourth at-large seat is Keli'i Akina's to 2028
--
-- 🔴 OHA'S BOARD WAS SPLIT ACROSS THREE CHAMBERS AND THIS FILE MAKES IT ONE. CC_0363 created
--   the Maui and Oahu Resident Trustee seats, and because its builder treated every statewide
--   office alike it gave each its own single-seat chamber and district. They are two of NINE
--   seats on one board. Both offices are MOVED (chamber_id and district_id repointed — the
--   office rows, their terms and their races are untouched, so nothing cascades), and the two
--   chambers and two districts they vacate are deleted. ⚠ offices.chamber_id and
--   offices.district_id have NO foreign key, so a delete here does not cascade and does not
--   error — it silently orphans. The gates below count the references before and after.
--   ⚠ An emptied district would also be a new DEAD_GEOGRAPHY bucket in the master-only address
--     reachability gate, so leaving them behind was not an option either.
--
-- 🔴 A CONTRADICTION BETWEEN A ROSTER AND AN AGGREGATOR, RESOLVED THE WAY CLAUDE.md SAYS.
--   OHA's own board page lists John D. Waihee IV as a sitting At-large Trustee. Ballotpedia,
--   read the same day, files the office under "Prior offices", "Years in office: 2000 - 2026",
--   and says "He left office on November 3, 2026". The chamber's own roster outranks every
--   aggregator, and election day is not a departure date. He is seated.
--
-- IDENTITY. 4 of the 65 people here already exist and are PINNED by uuid, each judged on what
--   that row already holds rather than on the name:
--     · Roger Victory  8a85a630 holds Senator @MI — and Ballotpedia's page for the MSU trustee
--       candidate IS that senator's page. KEPT.
--     · Jon Rosenthal  f5f63005 holds Representative @TX — and Ballotpedia's page for the
--       Railroad Commission winner IS that representative's page. KEPT. He wins a statewide
--       executive seat while sitting in the Texas House.
--     · Carmen Hulu Lindsey c669df3a and Kalei Akaka 3fa0ddec are CC_0363's rows, already
--       holding the two OHA seats this file moves.
--   🔴 "Adrian Akina (also known as Keali'i)" LOST the OHA at-large election. The sitting
--     at-large trustee is KELI'I Akina, who won in 2024 and holds the seat to 2028-11-07. One
--     letter apart, both Akinas, both OHA at-large, both on this page. They are two rows.
--   A second sweep on surname + first initial — wider than full-name equality, which cannot see
--   "Tiffany D. Tilley" against "Tiffany Tilley" — found only non-matches: Kanani Souza (HI
--   Representative), Joann Pritchett (WI Alder), Bobby Scott (VA), Dan/David/Deb Patterson,
--   Cabot/Carla/Clarke Nelson, Tom Craddick.
--
-- 🔴 NO TERM START IS INVENTED. 34 of the 35 terms are open-ended with start_precision
--   'unknown': no roster publishes when the member took the seat, and "first elected" is not a
--   term start. The one exception is sourced from the body's own page — Jill Kringstad,
--   "appointed to the Commission in Jan. 2025 by Governor Kelly Armstrong" — written
--   2025-01-01 at 'month' precision with how_started 'appointed'.
--
-- 🔴 WHICH SEAT WAS UP IS ASSERTED, NOT ASSUMED. 21 of the 37 seats publish a term-end year,
--   and a gate checks every one of them against the ballot column: a seat this contest filled
--   must end its term in 2027, and a seat it did not must end later. The other 16 publish no
--   year and are skipped rather than assumed.
--   ⚠ on_this_ballot means "a seat THIS contest filled", not "a seat that was up in 2026".
--     OHA's Maui and Oahu resident trustees were also on the 2026 ballot, in their own two
--     voteboxes, which CC_0363 already recorded. Do not give those two a term-end year here:
--     their old terms ended in 2027 and the gate would then correctly refuse the file.
--
-- SOURCING OF THE RESULTS is identical to CC_0359-CC_0363: Ballotpedia's winner flag matched
--   AP's call on 71 of 71 races where both name a winner while its vote counts ran up to 32%
--   short, so the flag is used and NO NUMBER IS. For the Texas Railroad Commission AP calls it
--   too, and the two agree: AP has Jon Rosenthal winner="X" at 52.51%, Ballotpedia 52.5%.
--
-- Applied to production 2026-11-07 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── 1. The seven bodies ───
CREATE TEMP TABLE body (
  bkey text PRIMARY KEY, st text NOT NULL, state_name text NOT NULL, fips text NOT NULL,
  gov_id uuid NOT NULL, election_id uuid NOT NULL, chamber_name text NOT NULL,
  chamber_formal text NOT NULL, district_label text NOT NULL, ocd text NOT NULL,
  official_count int NOT NULL, term_length text NOT NULL, website text NOT NULL,
  race_title text NOT NULL, race_seats int NOT NULL, race_desc text NOT NULL
) ON COMMIT DROP;
INSERT INTO body VALUES
  ('HI OHA', 'HI', 'Hawaii', '15',
   '05b03419-f890-4c7c-b03f-dcd26c3005ee'::uuid, 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'::uuid, 'Office of Hawaiian Affairs Board of Trustees',
   'Hawaii Office of Hawaiian Affairs Board of Trustees', 'Hawaii Office of Hawaiian Affairs Board of Trustees', 'ocd-division/country:us/state:hi',
   9, '4 years', 'https://www.oha.org/about/leadership/board-of-trustees/',
   'Office of Hawaiian Affairs At-large Trustee', 3, 'Three of the four at-large seats, held by Keoni Souza, Brickwood Galuteria and John Waihee IV. Souza and Galuteria were re-elected; Ikaika Anderson takes Waihee IV''s seat. The fourth at-large seat is Keli''i Akina''s and runs to 2028-11-07.'),
  ('MI SBE', 'MI', 'Michigan', '26',
   'a9c12923-c03c-407d-8b4f-30e4beca3d3f'::uuid, '03079314-238b-417b-a9e5-5e6d203e1594'::uuid, 'State Board of Education',
   'Michigan State Board of Education', 'Michigan State Board of Education', 'ocd-division/country:us/state:mi',
   8, '8 years', 'https://www.michigan.gov/mde/about-us/state-board',
   'Michigan State Board of Education', 2, 'Two of the eight seats, held by Judith Pritchett and Tiffany D. Tilley, both of whom assumed office on 2019-01-01 and whose terms end 2027-01-01. Both were re-elected.'),
  ('MI MSU', 'MI', 'Michigan', '26',
   'a9c12923-c03c-407d-8b4f-30e4beca3d3f'::uuid, '03079314-238b-417b-a9e5-5e6d203e1594'::uuid, 'Board of Trustees',
   'Michigan State University Board of Trustees', 'Michigan State University Board of Trustees', 'ocd-division/country:us/state:mi',
   8, '8 years', 'https://trustees.msu.edu/about/meet-the-trustees',
   'Michigan State University Board of Trustees', 2, 'Two of the eight seats, held by Brianna T. Scott and Kelly Tebay, whose terms end 2027-01-01. Both were re-elected.'),
  ('ND PSC', 'ND', 'North Dakota', '38',
   'cda06c83-809e-4239-9e7b-cc6b3db00fa1'::uuid, 'fce62fc6-28b4-4d99-821a-3c5e94bb2915'::uuid, 'Public Service Commission',
   'North Dakota Public Service Commission', 'North Dakota Public Service Commission', 'ocd-division/country:us/state:nd',
   3, '6 years', 'https://psc.nd.gov/commission',
   'North Dakota Public Service Commission', 1, 'One of the three seats, held by Sheri Haugen-Hoffart, who was re-elected.'),
  ('OK CC', 'OK', 'Oklahoma', '40',
   'a27cfee6-e675-448f-911e-eedfb17ce97d'::uuid, '5afd2125-3d75-4c6e-bcb0-9d3aaa296590'::uuid, 'Corporation Commission',
   'Oklahoma Corporation Commission', 'Oklahoma Corporation Commission', 'ocd-division/country:us/state:ok',
   3, '6 years', 'https://oklahoma.gov/occ/about/commissioners.html',
   'Oklahoma Corporation Commissioner', 1, 'One of the three seats, Todd Hiett''s, whose term the Commission''s own table ends on 2027-01-11. Brad Boles takes it.'),
  ('SD PUC', 'SD', 'South Dakota', '46',
   '29fbd5e8-ef43-456b-b89f-2d170062a3b8'::uuid, 'ac7ebe0d-b300-43ed-b107-d919822502df'::uuid, 'Public Utilities Commission',
   'South Dakota Public Utilities Commission', 'South Dakota Public Utilities Commission', 'ocd-division/country:us/state:sd',
   3, '6 years', 'https://puc.sd.gov/',
   'South Dakota Public Utilities Commission', 1, 'One of the three seats, Gary Hanson''s, whose term the Commission''s own page ends in 2027. Don Haggar takes it.'),
  ('TX RRC', 'TX', 'Texas', '48',
   '8aea8ed7-5abd-46f7-be0f-2bbbfe9fd2d9'::uuid, '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid, 'Railroad Commission',
   'Railroad Commission of Texas', 'Texas Railroad Commission', 'ocd-division/country:us/state:tx',
   3, '6 years', 'https://www.rrc.texas.gov/about-us/commissioners/',
   'Texas Railroad Commissioner', 1, 'One of the three seats, Jim Wright''s, who assumed office 2021-01-01 and whose term ends 2027-01-01. Jon Rosenthal takes it. AP calls this race too and labels the seat ''Term Exp 2032'' - the only seat label any source in this programme publishes.');

CREATE TEMP TABLE seat (
  skey text PRIMARY KEY, bkey text NOT NULL, title text NOT NULL, who text NOT NULL,
  on_this_ballot boolean NOT NULL, is_seat_up boolean NOT NULL, term_ends_year int,
  existing_office_id uuid, existing_chamber_id uuid,
  existing_district_id uuid, term_start date, start_precision text NOT NULL, how_started text NOT NULL
) ON COMMIT DROP;
INSERT INTO seat VALUES
  ('HI OHA#1', 'HI OHA', 'Office of Hawaiian Affairs At-large Trustee', 'Keoni Souza', true, true, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('HI OHA#2', 'HI OHA', 'Office of Hawaiian Affairs At-large Trustee', 'Brickwood Galuteria', true, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('HI OHA#3', 'HI OHA', 'Office of Hawaiian Affairs At-large Trustee', 'John Waihee IV', true, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('HI OHA#4', 'HI OHA', 'Office of Hawaiian Affairs At-large Trustee', 'Keli''i Akina', false, false, 2028, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('HI OHA#5', 'HI OHA', 'Office of Hawaiian Affairs Hawaii Island Resident Trustee', 'Kaiali''i Kahele', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('HI OHA#6', 'HI OHA', 'Office of Hawaiian Affairs Kauai and Niihau Resident Trustee', 'Dan Ahuna', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('HI OHA#7', 'HI OHA', 'Office of Hawaiian Affairs Molokai and Lanai Resident Trustee', 'Luana Alapa', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('HI OHA#8', 'HI OHA', 'Office of Hawaiian Affairs Maui Resident Trustee', 'Carmen Hulu Lindsey', false, false, NULL, 'b3284410-77ca-4223-9918-95fc9b18ec1f'::uuid, '71cfeb02-0dd6-45c6-8330-ebbdb3dfa66f'::uuid, '682e0a08-1eb5-4463-82ed-ccea39adfcd9'::uuid, NULL, 'unknown', 'unknown'),
  ('HI OHA#9', 'HI OHA', 'Office of Hawaiian Affairs Oahu Resident Trustee', 'Kalei Akaka', false, false, NULL, '54b50652-e113-4ee6-8cbe-af4a7ae800e4'::uuid, 'b54dec46-637e-4fe4-8cf2-5dcab6ef5f67'::uuid, 'd1d692b1-af5d-4105-bbf0-00411d6d9435'::uuid, NULL, 'unknown', 'unknown'),
  ('MI SBE#1', 'MI SBE', 'State Board of Education Member', 'Judith Pritchett', true, true, 2027, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI SBE#2', 'MI SBE', 'State Board of Education Member', 'Tiffany Tilley', true, false, 2027, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI SBE#3', 'MI SBE', 'State Board of Education Member', 'Marshall Bullock', false, false, 2029, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI SBE#4', 'MI SBE', 'State Board of Education Member', 'Ellen Cogen Lipton', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI SBE#5', 'MI SBE', 'State Board of Education Member', 'Tom McMillin', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI SBE#6', 'MI SBE', 'State Board of Education Member', 'Pamela Pugh', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI SBE#7', 'MI SBE', 'State Board of Education Member', 'Mitchell Robinson', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI SBE#8', 'MI SBE', 'State Board of Education Member', 'Nikki Snyder', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#1', 'MI MSU', 'Michigan State University Trustee', 'Brianna Scott', true, true, 2027, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#2', 'MI MSU', 'Michigan State University Trustee', 'Kelly Tebay', true, false, 2027, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#3', 'MI MSU', 'Michigan State University Trustee', 'Rebecca Bahar-Cook', false, false, 2033, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#4', 'MI MSU', 'Michigan State University Trustee', 'Mike Balow', false, false, 2033, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#5', 'MI MSU', 'Michigan State University Trustee', 'Dennis Denno', false, false, 2031, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#6', 'MI MSU', 'Michigan State University Trustee', 'Renee Knake Jefferson', false, false, 2031, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#7', 'MI MSU', 'Michigan State University Trustee', 'Sandy Pierce', false, false, 2029, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('MI MSU#8', 'MI MSU', 'Michigan State University Trustee', 'Rema Vassar', false, false, 2029, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('ND PSC#1', 'ND PSC', 'Public Service Commissioner', 'Sheri Haugen-Hoffart', true, true, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('ND PSC#2', 'ND PSC', 'Public Service Commissioner', 'Randy Christmann', false, false, NULL, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('ND PSC#3', 'ND PSC', 'Public Service Commissioner', 'Jill Kringstad', false, false, NULL, NULL, NULL, NULL, DATE '2025-01-01', 'month', 'appointed'),
  ('OK CC#1', 'OK CC', 'Corporation Commissioner', 'Todd Hiett', true, true, 2027, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('OK CC#2', 'OK CC', 'Corporation Commissioner', 'Kim David', false, false, 2029, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('OK CC#3', 'OK CC', 'Corporation Commissioner', 'Brian Bingman', false, false, 2031, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('SD PUC#1', 'SD PUC', 'Public Utilities Commissioner', 'Gary Hanson', true, true, 2027, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('SD PUC#2', 'SD PUC', 'Public Utilities Commissioner', 'Chris Nelson', false, false, 2029, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('SD PUC#3', 'SD PUC', 'Public Utilities Commissioner', 'Kristie Fiegen', false, false, 2031, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('TX RRC#1', 'TX RRC', 'Texas Railroad Commissioner', 'Jim Wright', true, true, 2027, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('TX RRC#2', 'TX RRC', 'Texas Railroad Commissioner', 'Christi Craddick', false, false, 2031, NULL, NULL, NULL, NULL, 'unknown', 'unknown'),
  ('TX RRC#3', 'TX RRC', 'Texas Railroad Commissioner', 'Wayne Christian', false, false, 2029, NULL, NULL, NULL, NULL, 'unknown', 'unknown');

-- ─── Pre-gates: nothing here may already exist, and every id must be the row it claims ───
DO $$ DECLARE txt text; n int; BEGIN
  SELECT count(*) INTO n FROM body;  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 bodies, found %', n; END IF;
  SELECT count(*) INTO n FROM seat;  IF n <> 37 THEN RAISE EXCEPTION 'expected 37 seats, found %', n; END IF;

  -- each body creates exactly official_count seats, and exactly one of them carries the race
  SELECT string_agg(b.bkey || ': ' || z.n || ' seats for official_count ' || b.official_count, '; ') INTO txt
    FROM body b JOIN LATERAL (SELECT count(*) AS n FROM seat s WHERE s.bkey = b.bkey) z ON true
   WHERE z.n <> b.official_count;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a body does not create its whole membership: %', txt; END IF;
  SELECT string_agg(b.bkey || ': ' || z.n || ' race attachment point(s)', '; ') INTO txt
    FROM body b JOIN LATERAL (SELECT count(*) AS n FROM seat s WHERE s.bkey = b.bkey AND s.is_seat_up) z ON true
   WHERE z.n <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race has no single office to attach to: %', txt; END IF;

  -- 🔴 WHICH SEAT WAS UP IS THE CLAIM A DECEMBER SEATING PASS WILL ACT ON, so it is checked
  --   against the term-end years the bodies publish rather than left as prose. A seat up in
  --   2026 ends its term in 2027; a seat that was not up ends later. 21 of the 37 seats publish
  --   a year and all 21 are checked; the rest publish none and are skipped, not assumed.
  SELECT string_agg(s.skey || ' (' || s.who || '): up=' || s.on_this_ballot || ' but the body says the term ends ' || s.term_ends_year, '; ') INTO txt
    FROM seat s WHERE s.term_ends_year IS NOT NULL
     AND ((s.on_this_ballot AND s.term_ends_year <> 2027) OR (NOT s.on_this_ballot AND s.term_ends_year <= 2027));
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seat is marked up against its own published term end: %', txt; END IF;
  SELECT string_agg(s.skey || ' carries the race but was not up in 2026', '; ') INTO txt
    FROM seat s WHERE s.is_seat_up AND NOT s.on_this_ballot;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race hangs off a seat that was not on the ballot: %', txt; END IF;
  SELECT string_agg(b.bkey || ': ' || z.n || ' seat(s) up for ' || b.race_seats || ' filled', '; ') INTO txt
    FROM body b JOIN LATERAL (SELECT count(*) AS n FROM seat s WHERE s.bkey = b.bkey AND s.on_this_ballot) z ON true
   WHERE z.n <> b.race_seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a body puts a different number of seats on the ballot than the race fills: %', txt; END IF;

  SELECT string_agg(b.bkey || ' -> government ' || b.gov_id, '; ') INTO txt
    FROM body b LEFT JOIN essentials.governments g ON g.id = b.gov_id WHERE g.id IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a government row does not exist: %', txt; END IF;
  SELECT string_agg(b.bkey || ' -> ' || coalesce(e.name, '(missing)') || ' ' || coalesce(e.state, '?'), '; ') INTO txt
    FROM body b LEFT JOIN essentials.elections e ON e.id = b.election_id
   WHERE e.id IS NULL OR e.election_date <> DATE '2026-11-03' OR e.state IS DISTINCT FROM b.st;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an election row is not the 2026-11-03 general of its state: %', txt; END IF;

  -- 🔴 the FIPS written as geo_id must be the one the state's own statewide districts use
  SELECT string_agg(b.bkey || ': this file says FIPS ' || b.fips || ' but ' || b.st || ' uses ' || d.geo_id, '; ') INTO txt
    FROM body b JOIN LATERAL (
      SELECT DISTINCT d2.geo_id FROM essentials.districts d2
       WHERE upper(d2.state) = b.st AND d2.district_type = 'STATE_EXEC' LIMIT 1) d ON true
   WHERE d.geo_id <> b.fips;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a FIPS disagrees with the state''s existing districts: %', txt; END IF;

  -- no chamber, district or office this file creates may already exist. 🔴 The office check
  -- ignores district_type on purpose: CC_0362 exists because a reconciliation that filtered on
  -- STATE_EXEC reported seats we DO hold as absent.
  SELECT string_agg(b.bkey || ' -> ' || c.name_formal || ' (' || c.id || ')', '; ') INTO txt
    FROM body b JOIN essentials.chambers c ON c.name_formal = b.chamber_formal;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a chamber this file creates already exists: %', txt; END IF;
  SELECT string_agg(b.bkey || ' -> ' || d.label || ' (' || d.id || ')', '; ') INTO txt
    FROM body b JOIN essentials.districts d ON d.label = b.district_label;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a district this file creates already exists: %', txt; END IF;
  SELECT string_agg(s.skey || ': ' || o.title || ' already exists as ' || d.district_type || ' ' || o.id, '; ') INTO txt
    FROM seat s JOIN body b ON b.bkey = s.bkey
    JOIN essentials.districts d ON upper(d.state) = b.st
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE s.existing_office_id IS NULL AND lower(o.title) = lower(s.title);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'this file would duplicate an office we already hold: %', txt; END IF;

  -- 🔴 BEFORE-IMAGE of the two offices this file MOVES. There is no history table: if the move
  --   is wrong the previous chamber_id and district_id exist nowhere, so they are asserted here
  --   and written into the header above.
  SELECT string_agg(s.skey || ': office ' || s.existing_office_id || ' is not where this file says', '; ') INTO txt
    FROM seat s LEFT JOIN essentials.offices o ON o.id = s.existing_office_id
   WHERE s.existing_office_id IS NOT NULL
     AND (o.id IS NULL OR o.chamber_id IS DISTINCT FROM s.existing_chamber_id
          OR o.district_id IS DISTINCT FROM s.existing_district_id OR o.title IS DISTINCT FROM s.title);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office to be moved is not the row this file describes: %', txt; END IF;
  SELECT count(*) INTO n FROM seat s WHERE s.existing_office_id IS NOT NULL;
  IF n <> 2 THEN RAISE EXCEPTION 'expected 2 offices to move, found %', n; END IF;
  -- each old chamber and district holds exactly that one office and nothing else points at them
  SELECT string_agg(s.skey || ': its old chamber holds ' || z.c || ' office(s) and its old district ' || z.d, '; ') INTO txt
    FROM seat s JOIN LATERAL (
      SELECT (SELECT count(*) FROM essentials.offices o2 WHERE o2.chamber_id = s.existing_chamber_id) AS c,
             (SELECT count(*) FROM essentials.offices o3 WHERE o3.district_id = s.existing_district_id) AS d) z ON true
   WHERE s.existing_office_id IS NOT NULL AND (z.c <> 1 OR z.d <> 1);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an old OHA chamber or district is not a singleton: %', txt; END IF;
  SELECT count(*) INTO n FROM seat s WHERE s.existing_chamber_id IS NOT NULL AND (
    EXISTS (SELECT 1 FROM essentials.discovered_sources x WHERE x.chamber_id = s.existing_chamber_id)
    OR EXISTS (SELECT 1 FROM essentials.source_outlets x WHERE x.chamber_id = s.existing_chamber_id)
    OR EXISTS (SELECT 1 FROM meetings.meetings x WHERE x.chamber_id = s.existing_chamber_id));
  IF n <> 0 THEN RAISE EXCEPTION '% old OHA chamber(s) are referenced by a source, outlet or meeting and cannot be deleted', n; END IF;
END $$;

-- ─── 2. Chambers, districts, offices ───
CREATE TEMP TABLE made_chamber (bkey text PRIMARY KEY, chamber_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  -- ⚠ chambers.slug is a GENERATED column and cannot be written; the rows join back on name_formal.
  INSERT INTO essentials.chambers (name, name_formal, government_id, policy_engagement_level,
                                   official_count, term_length, staggered_term, website_url)
  SELECT b.chamber_name, b.chamber_formal, b.gov_id, 'full', b.official_count, b.term_length, true, b.website
    FROM body b RETURNING id, name_formal)
INSERT INTO made_chamber SELECT b.bkey, ins.id FROM ins JOIN body b ON b.chamber_formal = ins.name_formal;

CREATE TEMP TABLE made_district (bkey text PRIMARY KEY, district_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.districts (district_type, state, geo_id, ocd_id, label, mtfcc, district_id,
                                    representation_basis, num_officials)
  SELECT 'STATE_EXEC', b.st, b.fips, b.ocd, b.district_label, '', '', 'residency', b.official_count
    FROM body b RETURNING id, label)
INSERT INTO made_district SELECT b.bkey, ins.id FROM ins JOIN body b ON b.district_label = ins.label;

CREATE TEMP TABLE made_office (skey text PRIMARY KEY, office_id uuid NOT NULL) ON COMMIT DROP;
WITH ins AS (
  INSERT INTO essentials.offices (title, chamber_id, district_id, representing_state, voting_powers,
                                  is_vacant, faces_retention_vote, is_appointed_position, description)
  SELECT s.title, mc.chamber_id, md.district_id, b.st, 'full', false, false, false, s.skey
    FROM seat s JOIN body b ON b.bkey = s.bkey
    JOIN made_chamber mc ON mc.bkey = s.bkey JOIN made_district md ON md.bkey = s.bkey
   WHERE s.existing_office_id IS NULL
  RETURNING id, description)
INSERT INTO made_office SELECT ins.description, ins.id FROM ins;
-- the seat key was carried in description only to join the rows back; it is not a voter-facing field
UPDATE essentials.offices o SET description = NULL FROM made_office mo WHERE o.id = mo.office_id;

-- 🔴 MOVE the two OHA offices. Only offices.chamber_id and offices.district_id change: the
--   office rows keep their ids, so their office_terms and races are untouched and nothing cascades.
UPDATE essentials.offices o
   SET chamber_id = mc.chamber_id, district_id = md.district_id
  FROM seat s JOIN made_chamber mc ON mc.bkey = s.bkey JOIN made_district md ON md.bkey = s.bkey
 WHERE o.id = s.existing_office_id;
INSERT INTO made_office SELECT s.skey, s.existing_office_id FROM seat s WHERE s.existing_office_id IS NOT NULL;

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM made_chamber;  IF n <> 7 THEN RAISE EXCEPTION 'only % chambers were created', n; END IF;
  SELECT count(*) INTO n FROM made_district; IF n <> 7 THEN RAISE EXCEPTION 'only % districts were created', n; END IF;
  SELECT count(*) INTO n FROM made_office;   IF n <> 37 THEN RAISE EXCEPTION 'only % of the 37 offices resolved', n; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id WHERE o.description IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) kept the seat key in description', n; END IF;
  -- the moved offices are now in the OHA board chamber and district, and still carry their own rows
  SELECT string_agg(s.skey || ': did not move', '; ') INTO txt
    FROM seat s JOIN essentials.offices o ON o.id = s.existing_office_id
    JOIN made_chamber mc ON mc.bkey = s.bkey JOIN made_district md ON md.bkey = s.bkey
   WHERE o.chamber_id <> mc.chamber_id OR o.district_id <> md.district_id;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office was not moved: %', txt; END IF;
  SELECT count(*) INTO n FROM seat s WHERE s.existing_office_id IS NOT NULL
     AND ((SELECT count(*) FROM essentials.office_terms t WHERE t.office_id = s.existing_office_id) <> 1
       OR (SELECT count(*) FROM essentials.races r WHERE r.office_id = s.existing_office_id) <> 1);
  IF n <> 0 THEN RAISE EXCEPTION '% moved office(s) lost their term or their race', n; END IF;
END $$;

-- the two singleton chambers and districts are now empty. An emptied district is a new
-- DEAD_GEOGRAPHY bucket in the master-only reachability gate, so they go.
DELETE FROM essentials.districts d
 WHERE d.id IN (SELECT s.existing_district_id FROM seat s WHERE s.existing_district_id IS NOT NULL)
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);
DELETE FROM essentials.chambers c
 WHERE c.id IN (SELECT s.existing_chamber_id FROM seat s WHERE s.existing_chamber_id IS NOT NULL)
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id);

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN essentials.districts d ON d.id = s.existing_district_id;
  IF n <> 0 THEN RAISE EXCEPTION '% emptied OHA district(s) survive and would read as DEAD_GEOGRAPHY', n; END IF;
  SELECT count(*) INTO n FROM seat s JOIN essentials.chambers c ON c.id = s.existing_chamber_id;
  IF n <> 0 THEN RAISE EXCEPTION '% emptied OHA chamber(s) survive', n; END IF;
  -- 🔴 offices.chamber_id and offices.district_id have NO foreign key, so a stale pointer is silent
  SELECT count(*) INTO n FROM essentials.offices o
   WHERE (o.chamber_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = o.chamber_id))
      OR (o.district_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = o.district_id));
  IF n <> 0 THEN RAISE EXCEPTION '% office(s) anywhere now point at a chamber or district that does not exist', n; END IF;
END $$;

-- ─── 3. The people this file must create ───
CREATE TEMP TABLE seed_people (
  full_name text PRIMARY KEY, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people VALUES
  ('Keoni Souza', 'Keoni', 'Souza',
   'https://ballotpedia.org/Keoni_Souza (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Brickwood Galuteria', 'Brickwood', 'Galuteria',
   'https://ballotpedia.org/Brickwood_Galuteria (Ballotpedia, read 2026-11-07); CC_0364'),
  ('John Waihee IV', 'John', 'Waihee IV',
   'https://ballotpedia.org/John_Waihee_IV (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Keli''i Akina', 'Keli''i', 'Akina',
   'https://ballotpedia.org/Keli''i_Akina (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Kaiali''i Kahele', 'Kaiali''i', 'Kahele',
   'https://ballotpedia.org/Kaiali''i_Kahele (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Dan Ahuna', 'Dan', 'Ahuna',
   'https://ballotpedia.org/Dan_Ahuna (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Luana Alapa', 'Luana', 'Alapa',
   'https://ballotpedia.org/Luana_Alapa (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Ikaika Anderson', 'Ikaika', 'Anderson',
   'https://ballotpedia.org/Ikaika_Anderson (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Adrian Akina', 'Adrian', 'Akina',
   'https://ballotpedia.org/Adrian_Akina (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Kanekoa Crabbe', 'Kanekoa', 'Crabbe',
   'https://ballotpedia.org/Kanekoa_Crabbe (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Judith Pritchett', 'Judith', 'Pritchett',
   'https://ballotpedia.org/Judith_Pritchett (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Tiffany Tilley', 'Tiffany', 'Tilley',
   'https://ballotpedia.org/Tiffany_Tilley (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Marshall Bullock', 'Marshall', 'Bullock',
   'https://ballotpedia.org/Marshall_Bullock (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Ellen Cogen Lipton', 'Ellen', 'Cogen Lipton',
   'https://ballotpedia.org/Ellen_Cogen_Lipton (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Tom McMillin', 'Tom', 'McMillin',
   'https://ballotpedia.org/Tom_McMillin (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Pamela Pugh', 'Pamela', 'Pugh',
   'https://ballotpedia.org/Pamela_Pugh (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Mitchell Robinson', 'Mitchell', 'Robinson',
   'https://ballotpedia.org/Mitchell_Robinson (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Nikki Snyder', 'Nikki', 'Snyder',
   'https://ballotpedia.org/Nikki_Snyder (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Terence Collins', 'Terence', 'Collins',
   'https://ballotpedia.org/Terence_Collins (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Bree Moeggenberg', 'Bree', 'Moeggenberg',
   'https://ballotpedia.org/Bree_Moeggenberg (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Mary Anne Hering', 'Mary Anne', 'Hering',
   'https://ballotpedia.org/Mary_Anne_Hering (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Charles Essner', 'Charles', 'Essner',
   'https://ballotpedia.org/Charles_Essner (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Christine Schwartz', 'Christine', 'Schwartz',
   'https://ballotpedia.org/Christine_Schwartz (Ballotpedia, read 2026-11-07); CC_0364'),
  ('William Mohr II', 'William', 'Mohr II',
   'https://ballotpedia.org/William_Mohr_II (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Wissam Charafeddine', 'Wissam', 'Charafeddine',
   'https://ballotpedia.org/Wissam_Charafeddine (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Kelli Monroe', 'Kelli', 'Monroe',
   'https://ballotpedia.org/Kelli_Monroe (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Jennifer Strickland', 'Jennifer', 'Strickland',
   'https://ballotpedia.org/Jennifer_Strickland (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Brianna Scott', 'Brianna', 'Scott',
   'https://ballotpedia.org/Brianna_Scott (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Kelly Tebay', 'Kelly', 'Tebay',
   'https://ballotpedia.org/Kelly_Tebay (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Rebecca Bahar-Cook', 'Rebecca', 'Bahar-Cook',
   'https://ballotpedia.org/Rebecca_Bahar-Cook (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Mike Balow', 'Mike', 'Balow',
   'https://ballotpedia.org/Mike_Balow (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Dennis Denno', 'Dennis', 'Denno',
   'https://ballotpedia.org/Dennis_Denno (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Renee Knake Jefferson', 'Renee', 'Knake Jefferson',
   'https://ballotpedia.org/Renee_Knake_Jefferson (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Sandy Pierce', 'Sandy', 'Pierce',
   'https://ballotpedia.org/Sandy_Pierce (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Rema Vassar', 'Rema', 'Vassar',
   'https://ballotpedia.org/Rema_Vassar (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Julie Maday', 'Julie', 'Maday',
   'https://ballotpedia.org/Julie_Maday (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Daniel Patterson', 'Daniel', 'Patterson',
   'https://ballotpedia.org/Daniel_Patterson (Ballotpedia, read 2026-11-07); CC_0364'),
  ('William White', 'William', 'White',
   'https://ballotpedia.org/William_White (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Yaz Ozbek', 'Yaz', 'Ozbek',
   'https://ballotpedia.org/Yaz_Ozbek (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Janet Sanger', 'Janet', 'Sanger',
   'https://ballotpedia.org/Janet_Sanger (Ballotpedia, read 2026-11-07); CC_0364'),
  ('John Sanger', 'John', 'Sanger',
   'https://ballotpedia.org/John_Sanger (Ballotpedia, read 2026-11-07); CC_0364'),
  ('John Anthony La Pietra', 'John Anthony', 'La Pietra',
   'https://ballotpedia.org/John_Anthony_La_Pietra (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Sheri Haugen-Hoffart', 'Sheri', 'Haugen-Hoffart',
   'https://ballotpedia.org/Sheri_Haugen-Hoffart (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Randy Christmann', 'Randy', 'Christmann',
   'https://ballotpedia.org/Randy_Christmann (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Jill Kringstad', 'Jill', 'Kringstad',
   'https://ballotpedia.org/Jill_Kringstad (Ballotpedia, read 2026-11-07); CC_0364'),
  ('John Pederson', 'John', 'Pederson',
   'https://ballotpedia.org/John_Pederson (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Todd Hiett', 'Todd', 'Hiett',
   'https://ballotpedia.org/Todd_Hiett (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Kim David', 'Kim', 'David',
   'https://ballotpedia.org/Kim_David (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Brian Bingman', 'Brian', 'Bingman',
   'https://ballotpedia.org/Brian_Bingman (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Brad Boles', 'Brad', 'Boles',
   'https://ballotpedia.org/Brad_Boles (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Rhonda Eastman', 'Rhonda', 'Eastman',
   'https://ballotpedia.org/Rhonda_Eastman (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Gary Hanson', 'Gary', 'Hanson',
   'https://ballotpedia.org/Gary_Hanson (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Chris Nelson', 'Chris', 'Nelson',
   'https://ballotpedia.org/Chris_Nelson (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Kristie Fiegen', 'Kristie', 'Fiegen',
   'https://ballotpedia.org/Kristie_Fiegen (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Don Haggar', 'Don', 'Haggar',
   'https://ballotpedia.org/Don_Haggar (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Frank Kloucek', 'Frank', 'Kloucek',
   'https://ballotpedia.org/Frank_Kloucek (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Jim Wright', 'Jim', 'Wright',
   'https://ballotpedia.org/Jim_Wright (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Christi Craddick', 'Christi', 'Craddick',
   'https://ballotpedia.org/Christi_Craddick (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Wayne Christian', 'Wayne', 'Christian',
   'https://ballotpedia.org/Wayne_Christian (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Bo French', 'Bo', 'French',
   'https://ballotpedia.org/Bo_French (Ballotpedia, read 2026-11-07); CC_0364'),
  ('Arthur DiBianca', 'Arthur', 'DiBianca',
   'https://ballotpedia.org/Arthur_DiBianca (Ballotpedia, read 2026-11-07); CC_0364');

-- 🔴 EMPTY ON PURPOSE. Both sweeps found no name this file seeds that an existing politician
--   already carries, so nothing is excused. The staleness gate below fires if a row is added
--   here that does not actually collide.
CREATE TEMP TABLE allowed_name_collisions (full_name text PRIMARY KEY) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇçʻ‘’',
                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc''''''')
  )
$f$;

CREATE TEMP TABLE pol_keys ON COMMIT DROP AS
SELECT id, full_name, first_name, last_name, is_active, source,
       pg_temp.namekey(full_name) AS k_full, pg_temp.namekey(first_name) AS k_first, pg_temp.namekey(last_name) AS k_last
  FROM essentials.politicians;
CREATE INDEX ON pol_keys (k_full);
CREATE INDEX ON pol_keys (k_first, k_last);
ANALYZE pol_keys;

DO $$ DECLARE txt text; n int; BEGIN
  -- 🔴 a detector that finds nothing is broken until a positive control passes
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Jon Rosenthal');
  IF n < 1 THEN RAISE EXCEPTION 'the name index cannot see a politician known to exist — the guard below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM pol_keys;
  IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows — it did not load the table', n; END IF;

  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ', active=' || p.is_active || ')' AS msg
      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'
      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)
     WHERE p.source IS DISTINCT FROM s.source AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  SELECT count(*) INTO n FROM allowed_name_collisions a JOIN seed_people s ON s.full_name = a.full_name
   WHERE NOT EXISTS (SELECT 1 FROM pol_keys p WHERE p.source IS DISTINCT FROM s.source
                       AND (p.k_full = pg_temp.namekey(s.full_name)
                         OR (p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name))));
  IF n <> 0 THEN RAISE EXCEPTION '% allowed collision(s) no longer collide — the allowance is stale', n; END IF;

  -- 🔴 the split must reconstruct the name EXACTLY. "ends with the surname" is not enough and
  --   has been proved insufficient three times: a compound surname contains its own tail, and
  --   "Keisha Sean Waites" still ends with "Waites" when the GIVEN name is corrupted.
  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s WHERE s.full_name <> s.first_name || ' ' || s.last_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;

  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://ballotpedia.org/%' OR s.source LIKE '%#%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is not a plain Ballotpedia page: %', txt; END IF;
END $$;

-- 🟢 the database's own DUPLICATE_POLITICIAN_NAME trigger agrees with the guard above. Opened
--    for this one statement and closed on the next line.
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true,
       EXISTS (SELECT 1 FROM seat st WHERE st.who = s.full_name)
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);
SET LOCAL essentials.allow_duplicate_name = 'off';

CREATE TEMP TABLE person (who text PRIMARY KEY, pid uuid NOT NULL) ON COMMIT DROP;
INSERT INTO person SELECT s.full_name, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;
INSERT INTO person VALUES
  ('Roger Victory', '8a85a630-0c68-498e-8e8f-631451fb59b1'::uuid),
  ('Jon Rosenthal', 'f5f63005-94a6-4170-b120-a421ea5a8f3b'::uuid),
  ('Carmen Hulu Lindsey', 'c669df3a-8d60-4456-a7db-6eb8488ecd63'::uuid),
  ('Kalei Akaka', '3fa0ddec-02d4-4b18-b7cf-696f725352a8'::uuid);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM person; IF n <> 65 THEN RAISE EXCEPTION 'only % of the 65 people resolved to exactly one row', n; END IF;
  -- every pinned row must still be the person this file names, and must not be archived
  SELECT string_agg(pe.who || ' is the row ' || p.full_name || ' (' || p.id || ')', '; ') INTO txt
    FROM person pe JOIN essentials.politicians p ON p.id = pe.pid
   WHERE pg_temp.namekey(p.full_name) <> pg_temp.namekey(pe.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned person is not who this file names: %', txt; END IF;
  SELECT string_agg(pe.who || ' is archived', '; ') INTO txt
    FROM person pe JOIN essentials.politicians p ON p.id = pe.pid WHERE NOT p.is_active;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file uses is archived: %', txt; END IF;
END $$;

-- ─── 4. Seat every current member ───
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT mo.office_id, pe.pid, s.term_start, NULL, s.start_precision, s.how_started,
       b.website || ' (the body''s own roster, read 2026-11-07) — CC_0364'
  FROM seat s JOIN body b ON b.bkey = s.bkey JOIN made_office mo ON mo.skey = s.skey
  JOIN person pe ON pe.who = s.who
 WHERE s.existing_office_id IS NULL;

DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.skey = s.skey
    JOIN essentials.office_terms t ON t.office_id = mo.office_id WHERE s.existing_office_id IS NULL;
  IF n <> 35 THEN RAISE EXCEPTION 'expected 35 new terms, found %', n; END IF;
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.skey = s.skey
    JOIN essentials.office_current_holder och ON och.office_id = mo.office_id
    JOIN person pe ON pe.who = s.who AND pe.pid = och.politician_id;
  IF n <> 37 THEN RAISE EXCEPTION 'only % of the 37 seats resolve to the member this file names', n; END IF;
END $$;

-- ─── 5. The races, each on the office whose seat was up ───
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT b.election_id, mo.office_id, b.race_title, NULL, b.race_seats, b.race_desc
  FROM body b JOIN seat s ON s.bkey = b.bkey AND s.is_seat_up JOIN made_office mo ON mo.skey = s.skey;

CREATE TEMP TABLE calls (
  bkey text NOT NULL, who text NOT NULL, result text NOT NULL, is_write_in boolean NOT NULL,
  is_incumbent boolean NOT NULL, PRIMARY KEY (bkey, who)
) ON COMMIT DROP;
INSERT INTO calls VALUES
  ('HI OHA', 'Keoni Souza', 'won', false, true),
  ('HI OHA', 'Ikaika Anderson', 'won', false, false),
  ('HI OHA', 'Brickwood Galuteria', 'won', false, true),
  ('HI OHA', 'John Waihee IV', 'lost', false, true),
  ('HI OHA', 'Adrian Akina', 'lost', false, false),
  ('HI OHA', 'Kanekoa Crabbe', 'lost', false, false),
  ('MI SBE', 'Judith Pritchett', 'won', false, true),
  ('MI SBE', 'Tiffany Tilley', 'won', false, true),
  ('MI SBE', 'Terence Collins', 'lost', false, false),
  ('MI SBE', 'Bree Moeggenberg', 'lost', false, false),
  ('MI SBE', 'Mary Anne Hering', 'lost', false, false),
  ('MI SBE', 'Charles Essner', 'lost', false, false),
  ('MI SBE', 'Christine Schwartz', 'lost', false, false),
  ('MI SBE', 'William Mohr II', 'lost', false, false),
  ('MI SBE', 'Wissam Charafeddine', 'lost', false, false),
  ('MI SBE', 'Kelli Monroe', 'lost', false, false),
  ('MI SBE', 'Jennifer Strickland', 'lost', true, false),
  ('MI MSU', 'Brianna Scott', 'won', false, true),
  ('MI MSU', 'Kelly Tebay', 'won', false, true),
  ('MI MSU', 'Julie Maday', 'lost', false, false),
  ('MI MSU', 'Roger Victory', 'lost', false, false),
  ('MI MSU', 'Daniel Patterson', 'lost', false, false),
  ('MI MSU', 'William White', 'lost', false, false),
  ('MI MSU', 'Yaz Ozbek', 'lost', false, false),
  ('MI MSU', 'Janet Sanger', 'lost', false, false),
  ('MI MSU', 'John Sanger', 'lost', false, false),
  ('MI MSU', 'John Anthony La Pietra', 'lost', false, false),
  ('ND PSC', 'Sheri Haugen-Hoffart', 'won', false, true),
  ('ND PSC', 'John Pederson', 'lost', false, false),
  ('OK CC', 'Brad Boles', 'won', false, false),
  ('OK CC', 'Rhonda Eastman', 'lost', false, false),
  ('SD PUC', 'Don Haggar', 'won', false, false),
  ('SD PUC', 'Frank Kloucek', 'lost', false, false),
  ('TX RRC', 'Jon Rosenthal', 'won', false, false),
  ('TX RRC', 'Bo French', 'lost', false, false),
  ('TX RRC', 'Arthur DiBianca', 'lost', false, false);

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM calls; IF n <> 36 THEN RAISE EXCEPTION 'expected 36 candidacies, found %', n; END IF;
  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 11 THEN RAISE EXCEPTION 'expected 11 winners, found %', n; END IF;
  -- 🔴 SEATS-AWARE: a multi-seat race holds exactly as many winners as the ballot filled
  SELECT string_agg(z.bkey || ': ' || z.w || ' winner(s) for ' || z.seats || ' seat(s)', '; ') INTO txt FROM (
    SELECT b.bkey, b.race_seats AS seats, count(*) FILTER (WHERE c.result = 'won') AS w
      FROM calls c JOIN body b ON b.bkey = c.bkey GROUP BY b.bkey, b.race_seats) z
   WHERE z.w <> z.seats;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a race does not hold one winner per seat: %', txt; END IF;
  SELECT string_agg(c.who || ' in ' || c.bkey, '; ') INTO txt
    FROM calls c LEFT JOIN person pe ON pe.who = c.who WHERE pe.pid IS NULL;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy resolves to no person: %', txt; END IF;
  -- every candidate flagged incumbent must actually sit on that body in this file
  SELECT string_agg(c.who || ' in ' || c.bkey, '; ') INTO txt FROM calls c
   WHERE c.is_incumbent <> EXISTS (SELECT 1 FROM seat s WHERE s.bkey = c.bkey AND s.who = c.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an incumbent flag disagrees with the body''s roster: %', txt; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, pl.id, pl.full_name, pl.first_name, pl.last_name, c.is_incumbent, 'active',
       c.is_write_in, 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0364',
       c.result, 'called',
       'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0364', now()
  FROM calls c
  JOIN seat s ON s.bkey = c.bkey AND s.is_seat_up
  JOIN made_office mo ON mo.skey = s.skey
  JOIN essentials.races r ON r.office_id = mo.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN person pe ON pe.who = c.who
  JOIN essentials.politicians pl ON pl.id = pe.pid;

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM body b JOIN seat s ON s.bkey = b.bkey AND s.is_seat_up
    JOIN made_office mo ON mo.skey = s.skey JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
   WHERE r.seats = b.race_seats;
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 new races carrying their seat counts, found %', n; END IF;
  SELECT count(*) INTO n FROM calls c
    JOIN seat s ON s.bkey = c.bkey AND s.is_seat_up JOIN made_office mo ON mo.skey = s.skey
    JOIN essentials.races r ON r.office_id = mo.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN person pe ON pe.who = c.who
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = pe.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called' AND rc.is_write_in = c.is_write_in
     AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-06';
  IF n <> 36 THEN RAISE EXCEPTION 'only % of the 36 candidacies hold their stated result', n; END IF;

  -- 🔴🔴 EVERY NEW OFFICE IS SEATED AND THE DRIFT BASELINE HAS NOT MOVED.
  SELECT count(*) INTO n FROM made_office mo
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = mo.office_id);
  IF n <> 0 THEN RAISE EXCEPTION '% of the 37 offices have no term and would raise the drift metric', n; END IF;
  SELECT count(*) INTO n FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id WHERE NOT o.is_vacant;
  IF n <> 238 THEN RAISE EXCEPTION 'the unflagged offices-missing-terms baseline moved to % — it was 238 and must never be raised', n; END IF;

  -- each body is WHOLE: official_count offices in its chamber, all on its one district
  SELECT string_agg(b.bkey || ': ' || z.n || ' offices for official_count ' || b.official_count, '; ') INTO txt
    FROM body b JOIN made_chamber mc ON mc.bkey = b.bkey
    JOIN LATERAL (SELECT count(*) AS n FROM essentials.offices o WHERE o.chamber_id = mc.chamber_id) z ON true
   WHERE z.n <> b.official_count;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a chamber is not whole: %', txt; END IF;
  SELECT count(*) INTO n FROM made_office mo JOIN essentials.offices o ON o.id = mo.office_id
    JOIN made_district md ON md.district_id = o.district_id;
  IF n <> 37 THEN RAISE EXCEPTION 'only % of the 37 offices sit on this file''s districts', n; END IF;

  -- 🔴 every district is STATE_EXEC on its state FIPS, which is what the statewide read path
  --   admits. An empty geo_id, or a board type, is a key no address can ever match.
  SELECT count(*) INTO n FROM made_district md JOIN essentials.districts d ON d.id = md.district_id
    JOIN body b ON b.bkey = md.bkey
   WHERE d.district_type <> 'STATE_EXEC' OR coalesce(d.geo_id, '') <> b.fips OR d.representation_basis <> 'residency';
  IF n <> 0 THEN RAISE EXCEPTION '% new district(s) are not statewide-reachable', n; END IF;

  -- only Jill Kringstad's term claims a start date, and no term is closed
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.skey = s.skey
    JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE s.existing_office_id IS NULL AND (t.term_end IS NOT NULL
     OR t.term_start IS DISTINCT FROM s.term_start OR t.start_precision <> s.start_precision);
  IF n <> 0 THEN RAISE EXCEPTION '% term(s) do not carry the start this file states', n; END IF;
  SELECT count(*) INTO n FROM seat s JOIN made_office mo ON mo.skey = s.skey
    JOIN essentials.office_terms t ON t.office_id = mo.office_id
   WHERE s.existing_office_id IS NULL AND t.term_start IS NOT NULL;
  IF n <> 1 THEN RAISE EXCEPTION 'expected exactly 1 sourced term start, found %', n; END IF;

  RAISE NOTICE 'CC_0364 OK — 7 bodies, 37 seats (35 created, 2 moved), 35 seated, 7 races, 36 candidacies, 61 people seeded.';
END $$;

COMMIT;
