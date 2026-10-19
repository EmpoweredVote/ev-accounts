-- CC_0239_atlanta_incumbents.sql
--
-- Atlanta full seed, stage 3, OCCUPANCY half. Seats all 17 City of Atlanta officeholders.
-- Depends on CC_0238_atlanta_structure.sql.
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md
-- Slot CC_0239 was RESERVED FROM THE ALLOCATOR before this file was named.
--
-- ---------------------------------------------------------------------------
-- Sources, all on disk under backend/data/seed-atlanta-2026/_sources/ (untracked):
--   A  citycouncil.atlantaga.gov/council-members         the body's own roster
--   B  citycouncil.atlantaga.gov/council-members/<slug>  16 member pages, the change-check
--   C  Municipal Clerk, "2026 City of Atlanta Elected Officials" (PDF) — the CITY'S OWN RECORD
--   D  atlantaga.gov/.../mayor-dickens-inauguration      the only DATED oaths in the wave
--   F/G Georgia SOS certified returns, Fulton + DeKalb, 2025-11-04, certified 2025-11-21
--
-- ---------------------------------------------------------------------------
-- 🔴 is_incumbent IS SET EXPLICITLY on every insert. It defaults to false since CA_0188, and a
--    seated person inserted without it is HIDDEN from address search. check:occupancy fails an
--    INSERT that omits it.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 term_start IS THE START OF CONTINUOUS OCCUPANCY BY THAT PERSON, not the start of the
--    current term. Re-election does not restart it. Dickens was re-elected on 2025-11-04 with
--    85.03% and sworn again on 2026-01-05, but his occupancy begins at his FIRST oath,
--    2022-01-03 — the city's own inauguration page states both dates.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 TEN STARTS ARE 'unknown', AND THAT IS THE HONEST ANSWER — NOT A GAP TO BE FILLED.
--
-- CLAUDE.md: "If the start is genuinely unknown, write an open-ended term with
-- start_precision => 'unknown' ... not a guess." Two independent routes to these dates are
-- closed:
--
--   * The SOS portal carries NO Atlanta municipal election before 2025. The 2021-11-02 and
--     2013-11-05 payloads return HTTP 204 for BOTH Fulton and DeKalb, and the 2025-12-02
--     municipal runoff is absent too (it holds one State House contest statewide). So there is
--     no certified chain to walk back.
--   * The member biographies mostly carry no date language at all. ⚠ The year tokens that DO
--     appear on every member page (2020, 2022, 2026, 2027) are page furniture — budget and
--     calendar links — not biography. Reading them as term dates is precisely the trap.
--
-- ⚠ TWO OF THE TEN NEED A GAP CHECK BEFORE ANY LATER PASS DATES THEM. A re-election does not
--   restart an occupancy, but A RETURN AFTER A GAP DOES. Mary B. Norwood served at-large before
--   leaving the council and returned in District 8; Michael Julian Bond served at-large in the
--   1990s, left, and returned later. Dating either from their first-ever service would be wrong
--   by a decade and would be a false statement about a real person.
--
-- 🔴🔴 THE TEN ARE TAGGED '| unverified CC_0239'. THIS IS LOAD-BEARING.
--
-- essentials.office_holders_as_of(date) matches `term_start IS NULL OR term_start <= as_of`, so
-- an undated term answers EVERY past date — it would claim these people held office in 1990.
-- The function excludes `source LIKE '%| unverified %'` (note the trailing space), which is
-- exactly the guard CA_0171 added for this shape.
--
-- ✅ VERIFIED, NOT ASSUMED: essentials.current_office_holders does NOT filter on that tag, so
--    all ten remain CURRENT holders and stay visible to address search. The tag only stops
--    them answering historical dates. Both view definitions were read before this was written.
--
-- ---------------------------------------------------------------------------
-- ⚠ TWO COUNCILMEMBERS SHARE THE SURNAME BOND and are not the same person:
--   Michael Julian Bond (Post 1 At Large) and Kelsea Bond (District 2).
--   The duplicate-name guard keys on (first_name, last_name), so they do not collide — but a
--   later full_name or surname match MUST NOT merge them.
--
-- ✅ All 17 names were checked against production on (first_name, last_name) AND by full_name:
--    zero collisions. The negative is trustworthy because a POSITIVE CONTROL passed on the same
--    predicate — a seated Georgia senator was found by it.
--
-- Idempotent. Dry-run with BEGIN; ... ROLLBACK; and confirm the rollback reverted.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_off int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_off <> 17 THEN
    RAISE EXCEPTION 'ATL-2 pre-flight: expected 17 Atlanta offices from CC_0238, found % — apply CC_0238 first', v_off;
  END IF;
END $$;

-- ─── 1. Seventeen people ─────────────────────────────────────────────────────

CREATE TEMP TABLE atl_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO atl_people(external_id, full_name, first_name, last_name) VALUES
  (-2767901::bigint, 'Andre Dickens',            'Andre',    'Dickens'),
  (-2767902::bigint, 'Marci Collier Overstreet', 'Marci',    'Overstreet'),
  (-2767903::bigint, 'Michael Julian Bond',      'Michael',  'Bond'),
  (-2767904::bigint, 'Matt Westmoreland',        'Matt',     'Westmoreland'),
  (-2767905::bigint, 'Eshé Collins',             'Eshé',     'Collins'),
  (-2767906::bigint, 'Jason H. Winston',         'Jason',    'Winston'),
  (-2767907::bigint, 'Kelsea Bond',              'Kelsea',   'Bond'),
  (-2767908::bigint, 'Byron D. Amos',            'Byron',    'Amos'),
  (-2767909::bigint, 'Jason Dozier',             'Jason',    'Dozier'),
  (-2767910::bigint, 'Liliana Bakhtiari',        'Liliana',  'Bakhtiari'),
  (-2767911::bigint, 'Alex Wan',                 'Alex',     'Wan'),
  (-2767912::bigint, 'Thomas Worthy',            'Thomas',   'Worthy'),
  (-2767913::bigint, 'Mary B. Norwood',          'Mary',     'Norwood'),
  (-2767914::bigint, 'Dustin Hillis',            'Dustin',   'Hillis'),
  (-2767915::bigint, 'Andrea L. Boone',          'Andrea',   'Boone'),
  (-2767916::bigint, 'Wayne Martin',             'Wayne',    'Martin'),
  (-2767917::bigint, 'Antonio Lewis',            'Antonio',  'Lewis');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       'City of Atlanta, Georgia — the Municipal Clerk''s own record "2026 City of Atlanta Elected Officials", cross-checked against the Atlanta City Council members index and all 16 individual member pages, and against the Georgia Secretary of State certified return for the 2025-11-04 Municipal General (Fulton and DeKalb merged, certified 2025-11-21). 🔴 The Clerk''s PDF misprints District 10 as "Andreal L. Boone"; her own member page and the certified ballot both read "Andrea L. Boone", which is what is seeded. Read 2026-10-17 (CC_0239)',
       true, true, '{}'::text[]
FROM atl_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. Seventeen terms ──────────────────────────────────────────────────────
-- 🔴 The at-large Posts, the Council President and the Mayor ALL sit on the same citywide
--    district '1304000'/G4110, so a term CANNOT be joined through (geo_id, mtfcc) alone here —
--    five offices share that district. Every citywide row joins on the office TITLE as well.

CREATE TEMP TABLE atl_terms(
  geo_id text, mtfcc text, title text, external_id bigint,
  term_start date, start_precision text, how_started text, unverified boolean
) ON COMMIT DROP;

INSERT INTO atl_terms(geo_id, mtfcc, title, external_id, term_start, start_precision, how_started, unverified) VALUES
  -- 🟢 DATED FROM THE CITY'S OWN INAUGURATION PAGE, which records BOTH of his oaths:
  --    "took the oath of office to become the City of Atlanta's 61st mayor ... on January 3, 2022"
  --    and "was sworn into office again on Monday, January 5, 2026". The 2022 date is the start
  --    of continuous occupancy; the 2026 one is a re-election and does not restart it.
  ('1304000', 'G4110', 'Mayor',             -2767901::bigint, '2022-01-03'::date, 'day',   'elected', false),
  -- 🟢 New to THIS office on 2026-01-05. She previously held District 11, which is a different
  --    seat — occupancy is per office, and District 11 is now Wayne Martin's.
  ('1304000', 'G4110', 'Council President',  -2767902::bigint, '2026-01-05'::date, 'day',   'elected', false),
  -- 🟢 "Since first taking office in January 2018" — his own member page. Month precision: the
  --    page states the month, not the day, and the day is not invented.
  ('1304000', 'G4110', 'Council Member, Post 2 (At Large)', -2767904::bigint, '2018-01-01'::date, 'month', 'elected', false),
  -- 🟢 "has represented Atlanta's District 1 on the City Council since 2022" — his own page.
  --    Year precision: the page states a year, so 2022-01-01 at 'year'.
  ('atlanta-ga-council-1',  'X0077', 'Council Member, District 1',  -2767906::bigint, '2022-01-01'::date, 'year', 'elected', false),
  -- 🟢 "Kelsea was elected in November 2025" — her own page. Sworn at the 2026-01-05 inauguration.
  ('atlanta-ga-council-2',  'X0077', 'Council Member, District 2',  -2767907::bigint, '2026-01-05'::date, 'day',  'elected', false),
  -- 🟢 "currently serving his first term" — his own page. Won the 2025-12-02 runoff after leading
  --    the general on 27.13%. ⚠ That runoff is NOT in the SOS portal; source C seats him.
  ('atlanta-ga-council-7',  'X0077', 'Council Member, District 7',  -2767912::bigint, '2026-01-05'::date, 'day',  'elected', false),
  -- 🟢 New in 2025, won the 2025-12-02 runoff after leading the general on 33.18%. Same caveat.
  ('atlanta-ga-council-11', 'X0077', 'Council Member, District 11', -2767916::bigint, '2026-01-05'::date, 'day',  'elected', false),

  -- ── The eleven with NO sourced start. term_start NULL, precision 'unknown', tagged. ──
  -- ⚠ GAP CHECK OWED (returned to the council after leaving it):
  ('1304000', 'G4110', 'Council Member, Post 1 (At Large)', -2767903::bigint, NULL, 'unknown', 'elected', true),
  ('atlanta-ga-council-8',  'X0077', 'Council Member, District 8',  -2767913::bigint, NULL, 'unknown', 'elected', true),
  -- ── The rest: currently seated, start not stated by any available source. ──
  ('1304000', 'G4110', 'Council Member, Post 3 (At Large)', -2767905::bigint, NULL, 'unknown', 'elected', true),
  ('atlanta-ga-council-3',  'X0077', 'Council Member, District 3',  -2767908::bigint, NULL, 'unknown', 'elected', true),
  ('atlanta-ga-council-4',  'X0077', 'Council Member, District 4',  -2767909::bigint, NULL, 'unknown', 'elected', true),
  ('atlanta-ga-council-5',  'X0077', 'Council Member, District 5',  -2767910::bigint, NULL, 'unknown', 'elected', true),
  ('atlanta-ga-council-6',  'X0077', 'Council Member, District 6',  -2767911::bigint, NULL, 'unknown', 'elected', true),
  -- ⚠ His page says "first elected to the Atlanta City Council in 2017 and is serving his third
  --   term". FIRST ELECTED IS NOT A TERM START and fails both ways, so it is not used as one.
  ('atlanta-ga-council-9',  'X0077', 'Council Member, District 9',  -2767914::bigint, NULL, 'unknown', 'elected', true),
  -- ⚠ "serving her second term" is a term COUNT, not a date.
  ('atlanta-ga-council-10', 'X0077', 'Council Member, District 10', -2767915::bigint, NULL, 'unknown', 'elected', true),
  ('atlanta-ga-council-12', 'X0077', 'Council Member, District 12', -2767917::bigint, NULL, 'unknown', 'elected', true);

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started,
       CASE WHEN t.unverified THEN
         'City of Atlanta, Georgia — seat confirmed by the Municipal Clerk''s "2026 City of Atlanta Elected Officials", the council members index and the officeholder''s own member page, read 2026-10-17 (CC_0239). The START of this occupancy is NOT established: the Georgia SOS portal carries no Atlanta municipal election before 2025 (2021 and 2013 return HTTP 204 for both Fulton and DeKalb) and the member biography states no date. Written open-ended at ''unknown'' precision rather than guessed. | unverified CC_0239 (2026-10-17): the HOLDER is verified and current; only the start date is unknown, so this term is excluded from office_holders_as_of, where an undated term would otherwise answer every past date'
       ELSE
         'City of Atlanta, Georgia — seat and arrival both sourced, read 2026-10-17 (CC_0239). Dates come from the city''s own inauguration record (the mayor''s oaths of 2022-01-03 and 2026-01-05) and from each officeholder''s own member page where it states an arrival. term_start is the start of CONTINUOUS occupancy, so a re-election does not restart it. Seats confirmed against the Municipal Clerk''s "2026 City of Atlanta Elected Officials" and the SOS certified return for the 2025-11-04 Municipal General (Fulton and DeKalb merged, certified 2025-11-21)'
       END
FROM atl_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.mtfcc = t.mtfcc AND d.district_type = 'LOCAL' AND lower(d.state) = 'ga'
JOIN essentials.offices o ON o.district_id = d.id AND o.title = t.title
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id AND g.name = 'City of Atlanta, Georgia, US'
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_terms    int;
  v_seated   int;
  v_noninc   int;
  v_dup      int;
  v_untagged int;
  v_tagged   int;
  v_hist     int;
  v_leg      int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN -2767917 AND -2767901;
  IF v_people <> 17 THEN
    RAISE EXCEPTION 'ATL-2 gate: expected 17 Atlanta people, found %', v_people;
  END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_terms <> 17 THEN
    RAISE EXCEPTION 'ATL-2 gate: expected 17 Atlanta office_terms rows, found %', v_terms;
  END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*). office_current_holder LEFT JOINs from offices,
  --    so a vacancy is a NULL politician_id and count(*) would PASS VACUOUSLY.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_seated <> 17 THEN
    RAISE EXCEPTION 'ATL-2 gate: expected 17 SEATED Atlanta offices, found % — Atlanta has no vacancies', v_seated;
  END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians p
   WHERE p.external_id BETWEEN -2767917 AND -2767901
     AND (p.is_incumbent IS DISTINCT FROM true OR p.is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'ATL-2 gate: % Atlanta official(s) are not is_incumbent/is_active — they would be HIDDEN from address search', v_noninc;
  END IF;

  -- One person per office, one office per person, inside this wave.
  SELECT count(*) INTO v_dup FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'City of Atlanta, Georgia, US'
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'ATL-2 gate: % person(s) hold more than one Atlanta office', v_dup;
  END IF;

  -- 🔴 THE TAG GATE. Every undated term MUST carry '| unverified ', and every dated term must
  --    NOT. An untagged NULL start would answer every past date in office_holders_as_of.
  SELECT count(*) INTO v_untagged FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US'
     AND ot.term_start IS NULL
     AND COALESCE(ot.source, '') NOT LIKE '%| unverified %';
  IF v_untagged <> 0 THEN
    RAISE EXCEPTION 'ATL-2 gate: % Atlanta term(s) have a NULL term_start and are NOT tagged "| unverified " — each would answer EVERY past date in office_holders_as_of', v_untagged;
  END IF;

  SELECT count(*) INTO v_tagged FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US'
     AND COALESCE(ot.source, '') LIKE '%| unverified %';
  IF v_tagged <> 10 THEN
    RAISE EXCEPTION 'ATL-2 gate: expected exactly 10 tagged-unverified Atlanta terms, found % — a DATED term must not carry the tag, or it would vanish from history for no reason', v_tagged;
  END IF;

  -- 🔴 AND THE TAG MUST ACTUALLY BITE. Assert the behaviour, not just the string: an Atlanta
  --    address in 2015 must return at most the SEVEN dated holders, never the ten undated ones.
  SELECT count(*) INTO v_hist FROM essentials.office_holders_as_of(DATE '2015-06-01') h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_hist <> 0 THEN
    RAISE EXCEPTION 'ATL-2 gate: office_holders_as_of(2015-06-01) returns % Atlanta holder(s); expected 0. Nobody seated here began before 2018, so any answer means an undated term is leaking into history', v_hist;
  END IF;

  -- 🔴 CONTROL: the GA-2 legislature must still be here, or these counts mean nothing.
  SELECT count(*) INTO v_leg FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Georgia'
     AND c.name IN ('Georgia House of Representatives', 'Georgia State Senate');
  IF v_leg <> 236 THEN
    RAISE EXCEPTION 'ATL-2 gate CONTROL: expected 236 Georgia legislative offices, found % — wrong database', v_leg;
  END IF;

  RAISE NOTICE 'ATL-2 OK: 17 people, 17 terms, 17 seated, 0 vacancies, 7 dated + 10 tagged-unverified, history clean at 2015, control 236 legislative offices present';
END $$;
