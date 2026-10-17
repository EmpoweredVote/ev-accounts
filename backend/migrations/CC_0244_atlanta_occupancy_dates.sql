-- CC_0244_atlanta_occupancy_dates.sql
--
-- Atlanta full seed, follow-up. Dates NINE of the ten Atlanta occupancies that CC_0239 wrote
-- open-ended at 'unknown' precision, and upgrades a tenth from 'year' to 'month'.
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md
-- Slot CC_0244 was RESERVED FROM THE ALLOCATOR before this file was named.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 CC_0239 SAID THESE DATES WERE UNAVAILABLE. THAT WAS WRONG, AND IT WAS WRONG IN A
--    SPECIFIC, REPEATABLE WAY: A DETECTOR THAT FOUND ALMOST NOTHING WAS NEVER CONTROLLED.
--
-- CC_0239's header claims the member biographies "carry no date language at all" and that the
-- year tokens on each page are "budget and calendar links — not biography". Both claims came
-- from a regex sweep over the member pages that required the literal phrase `elected in YYYY`.
--
-- Michael Julian Bond's page reads: "elected to the Atlanta City Council **in 1993** to represent
-- District Three and **in 2009** to the Post One, At-Large seat". The pattern `elected in \d{4}`
-- does not match `elected to the Atlanta City Council in 1993`. The bios were there the whole
-- time, in the server HTML, and the sweep walked past them.
--
-- ▶ The sweep DID match Hillis ("first elected to the Atlanta City Council in 2017"), and that
--   single hit is what made the empty result look credible. **A detector that returns almost
--   nothing is a broken detector until a positive control passes** — and one incidental hit is
--   not a control, because it cannot distinguish "the pattern works" from "the pattern is too
--   narrow and got lucky once".
--
-- ---------------------------------------------------------------------------
-- 🟢 AND THE CERTIFIED CHAIN EXISTS AFTER ALL — IT IS JUST NOT AT THE SECRETARY OF STATE.
--
-- CC_0239 also claims "the SOS portal carries no Atlanta municipal election before 2025", which
-- is TRUE and was verified again here (2021 and 2013 return HTTP 204 for both counties; the
-- statewide 2021 payload holds one ballot item and no Atlanta contest). The error was treating
-- the SOS as the only certified source.
--
-- 🟢 **FULTON COUNTY PUBLISHES ITS OWN CERTIFIED RESULTS ARCHIVE, BACK TO 1979** — a searchable,
--    year-faceted index of official Election Summary and SOVC PDFs at
--    `fultoncountyga.gov/.../Registration-and-Elections/Search-Elections`, served from
--    `/-/media/Project/FultonCountyGa/remos/elections/`. Fulton runs Atlanta's municipal
--    elections, so this is the authoritative return.
--
--    Used here: the 2021-11-02 Municipal General and its 2021-11-30 runoff, and the
--    2017-11 General Municipal and its 2017-12 runoff.
--
-- ⚠ The archive is NOT complete. It holds no Atlanta Post 3 special for 2022, 2023 or 2024,
--   which is why one row below stays undated.
--
-- ---------------------------------------------------------------------------
-- 🔴 WHY 'month' AND NOT 'day'.
--
-- The certified returns fix the ELECTION, and Atlanta terms begin the following January. That
-- gives the month, not the day. The city's inauguration page records the MAYOR's oaths
-- (2022-01-03, 2026-01-05) but does not state that councilmembers were sworn on those same days,
-- so a day is not claimed for them. 'month' is what the evidence supports.
--
-- ⚠ TWO OF THESE ARE RETURNS AFTER A GAP, NOT CONTINUOUS SERVICE. A re-election does not restart
--   an occupancy, but a RETURN AFTER A GAP DOES — so for these two the current occupancy starts
--   in 2022 and the earlier service is deliberately NOT used:
--     * Alex Wan, District 6 — his own page: "previously represented ... District 6 ... for two
--       four-year terms from 2010-2018". He then LOST the 2017 Council President runoff to
--       Felicia Moore (Fulton's certified Dec 2017 return) and left the council. He carries no
--       "(I)" marker in the 2021 return, which is the independent confirmation of the gap.
--     * Mary B. Norwood, District 8 — at-large previously, then off the council, then elected to
--       District 8 in 2021 carrying no "(I)" marker. A DIFFERENT SEAT as well as a gap.
--   Dating either from their first-ever service would be wrong by over a decade.
--
-- Idempotent: each UPDATE is guarded on the row still being undated, so a re-run changes 0 rows.
-- Dry-run with BEGIN; ... ROLLBACK; and confirm the rollback reverted.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_terms int;
BEGIN
  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_terms <> 17 THEN
    RAISE EXCEPTION 'ATL-7 pre-flight: expected 17 Atlanta terms from CC_0239, found % — apply CC_0238/CC_0239 first', v_terms;
  END IF;
END $$;

-- ─── The dated arrivals ──────────────────────────────────────────────────────

CREATE TEMP TABLE atl_dates(
  title text, term_start date, start_precision text, note text
) ON COMMIT DROP;

INSERT INTO atl_dates(title, term_start, start_precision, note) VALUES
  -- Elected 2009 to THIS seat (his own member page); carried "(I)" in the 2021 certified return,
  -- which confirms the seat was already his. His 1993 District Three service is a different
  -- office and a gap, and is not used.
  ('Council Member, Post 1 (At Large)', '2010-01-01'::date, 'year',
   'elected 2009 to the Post One At-Large seat per his own member page; "(I)" in the 2021 certified return. Year precision: the page states a year. His earlier District Three service from 1993 is a DIFFERENT OFFICE and is not used'),

  -- 2021 cycle, Fulton certified. Won the 2021-11-30 runoff unless noted.
  ('Council Member, District 1',  '2022-01-01'::date, 'month',
   'won the Fulton-certified 2021-11-30 municipal runoff (Winston 3,090 v Nathan Clubb 2,803); no "(I)" marker in the 2021 general, so the seat was not his before. His own page says "since 2022"'),
  ('Council Member, District 3',  '2022-01-01'::date, 'month',
   'won the Fulton-certified 2021-11-30 municipal runoff (Amos 1,464 v Erika Estrada 1,419); no "(I)" marker in the 2021 general'),
  ('Council Member, District 4',  '2022-01-01'::date, 'month',
   'won the Fulton-certified 2021-11-30 municipal runoff, DEFEATING the incumbent (Dozier 2,614 v Cleta Winslow (I) 1,578)'),
  ('Council Member, District 5',  '2022-01-01'::date, 'month',
   'won the Fulton-certified 2021-11-30 municipal runoff; her own page says "In 2021, Liliana was elected to represent Atlanta City Council District 5"'),
  ('Council Member, District 6',  '2022-01-01'::date, 'month',
   'elected in the Fulton-certified 2021-11-02 municipal general carrying NO "(I)" marker. 🔴 A RETURN AFTER A GAP: his own page records two terms in this same district from 2010-2018, after which he lost the 2017 Council President runoff to Felicia Moore and left the council. The current occupancy starts in 2022, not 2010'),
  ('Council Member, District 8',  '2022-01-01'::date, 'month',
   'elected unopposed in the Fulton-certified 2021-11-02 municipal general (11,080 votes) carrying NO "(I)" marker. 🔴 A RETURN AFTER A GAP, AND TO A DIFFERENT SEAT: her earlier council service was at-large. The current occupancy starts in 2022'),
  ('Council Member, District 12', '2022-01-01'::date, 'month',
   'won the Fulton-certified 2021-11-30 municipal runoff, DEFEATING the incumbent (Lewis 2,686 v Joyce Sheperd (I) 1,807); his own page says "In 2021, Antonio ran for Councilman in Atlanta''s 12th District and was selected by the voters to serve"'),

  -- 2017 cycle, Fulton certified.
  ('Council Member, District 9',  '2018-01-01'::date, 'month',
   'won the Fulton-certified 2017-12 municipal runoff against Kwame Abernathy; carried "(I)" in the 2021 certified return. His own page says "first elected to the Atlanta City Council in 2017 and is serving his third term"'),
  ('Council Member, District 10', '2018-01-01'::date, 'month',
   'led and won the Fulton-certified 2017-11 General Municipal outright (no District 10 contest appears in the 2017-12 runoff return); carried "(I)" in the 2021 certified return');

-- 🔴 Guarded on the row still being undated, EXCEPT District 1, which CC_0239 wrote at 'year'
--    precision from "since 2022" and which the certified runoff now sharpens to 'month'.
UPDATE essentials.office_terms ot
   SET term_start      = d.term_start,
       start_precision = d.start_precision,
       source          = 'City of Atlanta, Georgia — arrival dated from the FULTON COUNTY certified results archive (fultoncountyga.gov Search-Elections, official Election Summary reports), cross-checked against the officeholder''s own member page. ' || d.note || '. term_start is the start of CONTINUOUS occupancy of THIS office, so a re-election does not restart it. Month precision: the certified return fixes the election and Atlanta terms begin the following January, which gives the month and not the day. Read 2026-10-17 (CC_0244, superseding CC_0239)'
  FROM atl_dates d,
       essentials.offices o,
       essentials.chambers c,
       essentials.governments g
 WHERE o.id = ot.office_id
   AND c.id = o.chamber_id
   AND g.id = c.government_id
   AND g.name = 'City of Atlanta, Georgia, US'
   AND o.title = d.title
   AND (ot.term_start IS NULL OR ot.start_precision = 'year');

-- ─── The one that stays undated, with its window recorded ────────────────────
-- 🔴 Eshé Collins, Post 3 At Large. She is ABSENT from the 2021 Post 3 ballot entirely — that
--    contest was won by Keisha Sean Waites in the 2021-11-30 runoff — and she carries "(I)" in
--    the 2025 certified return. So her occupancy began between January 2022 and November 2025.
--    Fulton's archive holds NO Atlanta Post 3 special for 2022, 2023 or 2024, and the SOS holds
--    none either. The window is real evidence and is recorded; the date is still not known, so
--    the term stays open-ended and tagged.

UPDATE essentials.office_terms ot
   SET source = 'City of Atlanta, Georgia — seat confirmed by the Municipal Clerk''s "2026 City of Atlanta Elected Officials" and her own member page. The START is bounded but NOT established: she is absent from the 2021 Post 3 ballot (won by Keisha Sean Waites in the Fulton-certified 2021-11-30 runoff) and carries the "(I)" incumbency marker in the 2025 certified return, so this occupancy began between January 2022 and November 2025. Fulton''s certified archive holds no Atlanta Post 3 special for 2022, 2023 or 2024, and the Secretary of State holds none either. Written open-ended rather than guessed. | unverified CC_0244 (2026-10-17): the HOLDER is verified and current; only the start date is unknown, so this term is excluded from office_holders_as_of, where an undated term would otherwise answer every past date'
  FROM essentials.offices o,
       essentials.chambers c,
       essentials.governments g
 WHERE o.id = ot.office_id
   AND c.id = o.chamber_id
   AND g.id = c.government_id
   AND g.name = 'City of Atlanta, Georgia, US'
   AND o.title = 'Council Member, Post 3 (At Large)'
   AND ot.term_start IS NULL;

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_dated   int;
  v_undated int;
  v_untag   int;
  v_tagged  int;
  v_seated  int;
  v_hist18  int;
  v_hist15  int;
  v_wan     date;
  v_norwood date;
BEGIN
  SELECT count(*) FILTER (WHERE ot.term_start IS NOT NULL),
         count(*) FILTER (WHERE ot.term_start IS NULL)
    INTO v_dated, v_undated
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_dated <> 16 OR v_undated <> 1 THEN
    RAISE EXCEPTION 'ATL-7 gate: expected 16 dated and 1 undated Atlanta term, found % and %', v_dated, v_undated;
  END IF;

  -- Every remaining undated term must still be tagged, and every DATED one must NOT be.
  SELECT count(*) INTO v_untag FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US'
     AND ot.term_start IS NULL
     AND COALESCE(ot.source, '') NOT LIKE '%| unverified %';
  IF v_untag <> 0 THEN
    RAISE EXCEPTION 'ATL-7 gate: % undated Atlanta term(s) are NOT tagged "| unverified "', v_untag;
  END IF;

  SELECT count(*) INTO v_tagged FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US'
     AND COALESCE(ot.source, '') LIKE '%| unverified %';
  IF v_tagged <> 1 THEN
    RAISE EXCEPTION 'ATL-7 gate: expected exactly 1 tagged-unverified Atlanta term (Post 3), found % — a DATED term must not keep the tag or it vanishes from history for no reason', v_tagged;
  END IF;

  -- 🔴 THE GAP ASSERTION. Wan and Norwood both served earlier and returned. If a later pass ever
  --    back-dates either to their first-ever service, this fires.
  SELECT ot.term_start INTO v_wan FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US' AND o.title = 'Council Member, District 6';
  SELECT ot.term_start INTO v_norwood FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US' AND o.title = 'Council Member, District 8';
  IF v_wan < DATE '2022-01-01' OR v_norwood < DATE '2022-01-01' THEN
    RAISE EXCEPTION 'ATL-7 gate: District 6 (%) or District 8 (%) is dated before 2022. Both are RETURNS AFTER A GAP — a return restarts occupancy, so neither may carry its pre-2018 service', v_wan, v_norwood;
  END IF;

  -- Nothing may have become unseated.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_seated <> 17 THEN
    RAISE EXCEPTION 'ATL-7 gate: expected 17 seated Atlanta offices, found %', v_seated;
  END IF;

  -- 🔴 HISTORY NOW ANSWERS, AND ANSWERS CORRECTLY. This is the payoff: at 2018-06-01 exactly the
  --    three people who had taken office by then must appear (Westmoreland, Hillis, Boone), and
  --    at 2015 still nobody.
  SELECT count(*) INTO v_hist18 FROM essentials.office_holders_as_of(DATE '2018-06-01') h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_hist18 <> 4 THEN
    RAISE EXCEPTION 'ATL-7 gate: office_holders_as_of(2018-06-01) returns % Atlanta holder(s); expected exactly 4 — Post 1 (held since 2010), Post 2, District 9 and District 10 (all from January 2018)', v_hist18;
  END IF;

  SELECT count(*) INTO v_hist15 FROM essentials.office_holders_as_of(DATE '2015-06-01') h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'City of Atlanta, Georgia, US';
  IF v_hist15 <> 1 THEN
    RAISE EXCEPTION 'ATL-7 gate: office_holders_as_of(2015-06-01) returns % Atlanta holder(s); expected exactly 1 (Post 1, held since 2010)', v_hist15;
  END IF;

  RAISE NOTICE 'ATL-7 OK: 16 dated + 1 tagged-unverified, 17 still seated, gaps held at 2022, history answers 1 at 2015 and 4 at 2018';
END $$;
