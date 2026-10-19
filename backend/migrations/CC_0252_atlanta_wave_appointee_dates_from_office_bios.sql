-- CC_0252_atlanta_wave_appointee_dates_from_office_bios.sql
--
-- Atlanta / Fulton County / DeKalb County wave — dates 3 of the 7 occupancies that CC_0248
-- left undated, taking the wave from 33/40 dated to 36/40.
--
-- 🔴🔴 CC_0248 SAID THESE NEEDED "APPOINTMENT RECORDS, A DIFFERENT SOURCE CLASS". THAT WAS
-- TOO STRONG, AND IT MISSED THIS FILE'S OWN LESSON.
-- CC_0248's footer concluded that the certified-return route was exhausted and that closing
-- these required a governor's order or a court order. The first half is true: a certified
-- return can only date someone who WON AN ELECTION FOR THAT SEAT, and every one of the seven
-- arrived off-ballot. The second half was wrong. GAP 3 of this wave already established the
-- answer — "WHEN THE ELECTION RECORD IS SILENT ABOUT AN OFFICE, ASK THE OFFICE" — and it was
-- what found both Probate Judges. It was never applied to the APPOINTEES.
-- Each of the three below states its own start date, in the office's own words, on the office's
-- own site. Two give a DAY.
--
-- ▶ The route that found them is the same RENDERED FETCH that recovered three headshots
--   (CC_0249-CC_0251): fultoncountytaxes.org 403s curl outright and only renders in a browser.
--
-- 🔴 how_started IS CORRECTED ON ALL THREE. CC_0241/CC_0243 wrote 'elected' for every seat in
-- the wave, which is false for an appointee. An appointment is exactly what makes these people
-- invisible to every election archive, so recording them as 'elected' hides the reason they
-- could not be dated and would send the next session back to the returns.
--
-- Precision: 'day' where the source states a day, 'day' for Ferdinand because the source states
-- January 1, 1997 explicitly. No date here is inferred from a term rule.

BEGIN;

CREATE TEMP TABLE _appointee_dates (
  term_id         uuid PRIMARY KEY,
  who             text NOT NULL,
  term_start      date NOT NULL,
  start_precision text NOT NULL,
  how_started     text NOT NULL,
  source          text NOT NULL
) ON COMMIT DROP;

INSERT INTO _appointee_dates (term_id, who, term_start, start_precision, how_started, source) VALUES

('8b8a3535-4131-4f98-9505-58d83b2ceb58'::uuid,
 'Arthur E. Ferdinand — Tax Commissioner, Fulton County',
 DATE '1997-01-01', 'day', 'appointed',
 'Appointed Tax Commissioner of Fulton County on 1997-01-01. The office''s own biography page states it directly: "On January 1, 1997, Dr. Ferdinand was appointed Tax Commissioner of Fulton County, and subsequently elected and re-elected to the position." (fultoncountytaxes.org, TC Biography, read 2026-10-18). This is why no certified return could date him — he arrived by APPOINTMENT and every subsequent return marks him "(I)". 🔴 The site returns HTTP 403 to curl and is reachable only by a RENDERED fetch; CC_0246 recorded that refusal but never tried a browser. Continuous occupancy is corroborated by the "(I)" marker in Fulton''s certified 2016 and 2020 generals and the SOS certified 2024 general. (CC_0252)'),

('25ba885b-c72b-4fb6-8770-4f6aae7fd9de'::uuid,
 'Ché Alexander — Clerk of Superior Court, Fulton County',
 DATE '2023-06-30', 'day', 'succeeded',
 'Sworn in on 2023-06-30 to serve the unexpired term of her predecessor. Her office''s own biography states: "propelled Ché to be sworn in as the Clerk of the Superior & Magistrate Courts of Fulton County on June 30, 2023, to fulfill the remaining term of her predecessor." (fultonclerk.org/338/Meet-Clerk-Ch-Alexander, read 2026-10-18). This closes the gap CC_0248 identified: Fulton''s certified 2020 general shows a DIFFERENT clerk, Cathelene "Tina" Robinson (I), and the Clerk was not on the 2022 ballot, so she could only have arrived mid-term. ⚠ how_started is ''succeeded'' rather than ''appointed'' because the source states the fact of succession and the swearing-in but does NOT name the appointing authority; Georgia fills such a vacancy by appointment, but that is not what this document says. (CC_0252)'),

('6284b03d-9c0f-49e2-bdcc-f90a3c2a2698'::uuid,
 'Melody M. Maddox — Sheriff, DeKalb County',
 DATE '2019-12-01', 'day', 'appointed',
 'Became Sheriff on 2019-12-01 by appointment to her predecessor''s unexpired term. The Sheriff''s Office''s own About page states: "In November 2019, then Sheriff Mann retired and appointed her to serve his unexpired term. Sheriff Maddox became the county''s 50th sheriff on December 1, 2019." (dekalbsheriff.org/about-us, read 2026-10-18). This explains the finding recorded in CC_0248''s corrected footer: DeKalb DID hold a Sheriff special in 2020 — "Sheriff (Special From March)", voted 2020-05-19 with a 2020-08-11 runoff — and she carries "(I)" in BOTH, because she already held the office. No election dates her. (CC_0252)');

-- Guard: all three must exist, be open-ended, and still be undated.
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM _appointee_dates d
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.office_terms t
      WHERE t.id = d.term_id AND t.term_end IS NULL AND t.term_start IS NULL);
  IF v_bad > 0 THEN
    RAISE EXCEPTION 'CC_0252: % of 3 target terms are missing, closed, or already dated', v_bad;
  END IF;
END $$;

-- The write. Strips the `| unverified <slot>` tag (CA_0171) so these become visible to
-- essentials.office_holders_as_of(date), and corrects how_started away from 'elected'.
UPDATE essentials.office_terms t
   SET term_start      = d.term_start,
       start_precision = d.start_precision,
       how_started     = d.how_started,
       source          = d.source
  FROM _appointee_dates d
 WHERE t.id = d.term_id
   AND t.term_start IS NULL;

-- Post-verify gate.
DO $$
DECLARE
  v_ok        int;
  v_unverif   int;
  v_elected   int;
  v_remaining int;
BEGIN
  SELECT count(*) INTO v_ok
    FROM _appointee_dates d
    JOIN essentials.office_terms t ON t.id = d.term_id
   WHERE t.term_start = d.term_start AND t.start_precision = d.start_precision;
  IF v_ok <> 3 THEN
    RAISE EXCEPTION 'CC_0252: expected 3 dated terms, found %', v_ok;
  END IF;

  SELECT count(*) INTO v_unverif
    FROM _appointee_dates d
    JOIN essentials.office_terms t ON t.id = d.term_id
   WHERE t.source LIKE '%| unverified %';
  IF v_unverif <> 0 THEN
    RAISE EXCEPTION 'CC_0252: % dated terms still carry the "| unverified" tag', v_unverif;
  END IF;

  SELECT count(*) INTO v_elected
    FROM _appointee_dates d
    JOIN essentials.office_terms t ON t.id = d.term_id
   WHERE t.how_started = 'elected';
  IF v_elected <> 0 THEN
    RAISE EXCEPTION 'CC_0252: % appointees are still recorded as how_started=elected', v_elected;
  END IF;

  -- The wave's undated count must fall from 7 to exactly 4.
  SELECT count(*) INTO v_remaining
    FROM essentials.governments g
    JOIN essentials.chambers ch ON ch.government_id = g.id
    JOIN essentials.offices o   ON o.chamber_id = ch.id
    JOIN essentials.office_terms t ON t.office_id = o.id AND t.term_end IS NULL
   WHERE g.geo_id IN ('1304000','13121','13089')
     AND t.politician_id IS NOT NULL
     AND t.term_start IS NULL;
  IF v_remaining <> 4 THEN
    RAISE EXCEPTION 'CC_0252: expected 4 undated occupancies left, found %', v_remaining;
  END IF;

  RAISE NOTICE 'CC_0252 OK — 3 appointees dated, 4 remain undated';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE 4 LEFT UNDATED, after asking every office directly:
--
--   Fulton Chairperson, Robb Pitts   — ⚠ NARROWED BUT NOT DATED. His own county page says
--                                      "Before being elected Chairman in 2017, Robb Pitts served
--                                      on the Board for twelve years." ELECTED IS NOT SEATED, and
--                                      whether that was the November 2017 special for John Eaves'
--                                      unexpired term or the regular cycle is unresolved — so the
--                                      year he took office is still open. ⚠ The same page prints
--                                      "Term: Jan. 01, 2023 until Dec. 31, 2026", which is his
--                                      CURRENT STATUTORY TERM, not his occupancy start; writing
--                                      that would be exactly the error this schema exists to stop.
--   DeKalb Clerk, Debra DeBerry      — her "Meet The Clerk" bio dates only her 2003 arrival as
--                                      CHIEF DEPUTY Clerk, a different office. It never says when
--                                      she became Clerk. (A web summary claims "Clerk since March
--                                      2011" from a 2019 press release; that is a LEAD, and the
--                                      PDF was not read, so it is not recorded here.)
--   Fulton Probate, Kenya M. Johnson — the court's "Meet our Executive Team" page is a bare
--                                      name-and-email list with no biographies at all.
--   DeKalb Probate, Bedelia Hargrove — her court's site carries no start date in any prose.
-- ───────────────────────────────────────────────────────────────────────────────────────────
