-- 1833_indiana_appellate_successions.sql
--
-- Two Indiana Court of Appeals seats were still showing judges who have left the court.
-- Migration 1832 gave Districts 1-3 real geography, which made this visible rather than harmless:
-- Terry Crone was District 3's ONLY judge in our data, so every voter in the northern third of
-- Indiana was being shown a judge who retired in 2024.
--
-- SEAT: Indiana Appeals Court Judge - District 3  (office 6334ade6-…)
--   Terry A. Crone retired 2024-11-05.
--     "Judge Terry A. Crone will retire from the Court of Appeals of Indiana on November 5, 2024."
--     — Court of Appeals of Indiana press release, 2024-09-03,
--       https://www.in.gov/courts/appeals/news/2024-0903/
--   Stephen E. Scheele took the seat 2025-01-08.
--     "In December 2024, Governor Eric Holcomb appointed Stephen E. 'Sam' Scheele to represent
--      Indiana's 3rd (northern) District in the Court of Appeals of Indiana. Judge Scheele's
--      service began on January 8, 2025."
--     — https://www.in.gov/courts/appeals/judges/stephen-scheele/
--   ⚠ THE SEAT WAS GENUINELY VACANT 2024-11-06 .. 2025-01-07. Both dates are sourced, so this is
--     written as a real vacancy (vacate_office) and not smoothed over by back-dating Scheele to
--     Crone's last day. Handing the seat straight across would assert two months of service that
--     did not happen.
--
-- SEAT: Indiana Appeals Court Judge - District 5  (office 6d35b799-…)
--   Paul A. Felix took the seat 2023-07-28.
--     "Paul A. Felix was appointed to the Court of Appeals by Governor Holcomb and began his
--      service on July 28, 2023." — https://www.in.gov/courts/appeals/judges/paul-felix/
--   Margret G. Robb's last day is therefore 2023-07-27, which is what seat_officeholder writes.
--   ⚠ SOURCE CONFLICT, RESOLVED IN FAVOUR OF THE COURT. Ballotpedia gives Robb's exit as
--     2023-08-02, which cannot be true of this seat if her successor began 2023-07-28 — one seat
--     cannot hold two judges (office_terms' exclusion constraint agrees). The court's own page is
--     primary for Felix's start, so the predecessor's close is derived from it rather than from
--     the conflicting secondary date. No independent claim about Robb's last day is made here.
--
-- WHAT IS DELIBERATELY NOT DONE
--   * politicians.is_active / is_incumbent on Crone and Robb are NOT touched. Occupancy is the
--     dated term row; caching "current" in a column is precisely what ADR 0002 removed. Closing
--     the term is the whole fix — Crone remains a real person, and is in fact still a certified
--     senior judge.
--   * The other 8 sitting COA judges (Vaidik, Mathias, Tavitas, Weissmann, Kenworthy, DeBoer and
--     the rest) are still absent from essentials entirely; we model 11 of the court's 15 seats.
--     That is a seeding gap, not a succession error, and is out of scope here.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. The two successors. Neither existed: a search for 'scheele'/'felix' returned
--    only FEC committee junk and one unrelated Maria Felix.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (full_name, first_name, middle_initial, last_name, party, slug,
                                    is_active, is_incumbent)
SELECT v.full_name, v.first_name, v.mi, v.last_name, 'Nonpartisan', v.slug, true, true
FROM (VALUES
        ('Stephen E Scheele', 'Stephen', 'E', 'Scheele', 'stephen-e-scheele'),
        ('Paul A Felix',      'Paul',    'A', 'Felix',   'paul-a-felix')
     ) AS v(full_name, first_name, mi, last_name, slug)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.slug = v.slug
);

-- ---------------------------------------------------------------------------
-- 2. District 3 — Crone out 2024-11-05, seat vacant, Scheele in 2025-01-08.
-- ---------------------------------------------------------------------------
SELECT essentials.vacate_office(
         '6334ade6-aa93-47be-99df-925480e02a00'::uuid,
         DATE '2024-11-06',
         'in.gov/courts/appeals/news/2024-0903 (retirement press release); migration 1833',
         'retired');

SELECT essentials.seat_officeholder(
         '6334ade6-aa93-47be-99df-925480e02a00'::uuid,
         (SELECT id FROM essentials.politicians WHERE slug = 'stephen-e-scheele'),
         DATE '2025-01-08',
         'in.gov/courts/appeals/judges/stephen-scheele; migration 1833',
         'appointed', 'day', 'retired');

-- seat_officeholder does NOT clear the vacancy flag vacate_office set — the seat is filled again.
UPDATE essentials.offices
   SET is_vacant = false, vacant_since = NULL
 WHERE id = '6334ade6-aa93-47be-99df-925480e02a00'::uuid;

-- ---------------------------------------------------------------------------
-- 3. District 5 — Felix in 2023-07-28; this closes Robb at 2023-07-27. No gap.
-- ---------------------------------------------------------------------------
SELECT essentials.seat_officeholder(
         '6d35b799-27bc-406d-a1fd-6a59bda85943'::uuid,
         (SELECT id FROM essentials.politicians WHERE slug = 'paul-a-felix'),
         DATE '2023-07-28',
         'in.gov/courts/appeals/judges/paul-felix; migration 1833',
         'appointed', 'day', 'retired');

-- ---------------------------------------------------------------------------
-- 4. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_d3 text; v_d5 text;
  v_crone_end date; v_robb_end date;
  n_vacant int; n_gap int;
BEGIN
  SELECT p.full_name INTO v_d3
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = '6334ade6-aa93-47be-99df-925480e02a00';
  SELECT p.full_name INTO v_d5
    FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE och.office_id = '6d35b799-27bc-406d-a1fd-6a59bda85943';

  IF v_d3 IS DISTINCT FROM 'Stephen E Scheele' THEN
    RAISE EXCEPTION 'District 3 seat holder is %, expected Stephen E Scheele', coalesce(v_d3, '(none)');
  END IF;
  IF v_d5 IS DISTINCT FROM 'Paul A Felix' THEN
    RAISE EXCEPTION 'District 5 seat holder is %, expected Paul A Felix', coalesce(v_d5, '(none)');
  END IF;

  -- The predecessors' terms must be CLOSED on the sourced days, not merely superseded.
  SELECT t.term_end INTO v_crone_end
    FROM essentials.office_terms t
   WHERE t.office_id = '6334ade6-aa93-47be-99df-925480e02a00'
     AND t.politician_id = '2a054186-d76d-4e50-81f8-2f4e9dd9e871';
  SELECT t.term_end INTO v_robb_end
    FROM essentials.office_terms t
   WHERE t.office_id = '6d35b799-27bc-406d-a1fd-6a59bda85943'
     AND t.politician_id = 'c7670a65-abc2-43af-8375-eeb212a25e71';

  IF v_crone_end IS DISTINCT FROM DATE '2024-11-05' THEN
    RAISE EXCEPTION 'Crone term_end is %, expected 2024-11-05', coalesce(v_crone_end::text, 'NULL');
  END IF;
  IF v_robb_end IS DISTINCT FROM DATE '2023-07-27' THEN
    RAISE EXCEPTION 'Robb term_end is %, expected 2023-07-27', coalesce(v_robb_end::text, 'NULL');
  END IF;

  -- Neither seat may be left flagged vacant now that both are filled.
  SELECT count(*) INTO n_vacant FROM essentials.offices
   WHERE id IN ('6334ade6-aa93-47be-99df-925480e02a00','6d35b799-27bc-406d-a1fd-6a59bda85943')
     AND (is_vacant OR vacant_since IS NOT NULL);
  IF n_vacant > 0 THEN
    RAISE EXCEPTION '% filled seat(s) still flagged vacant', n_vacant;
  END IF;

  -- The District 3 vacancy is a real span in the record, not a silent handover: Crone's term must
  -- end strictly before Scheele's begins.
  SELECT count(*) INTO n_gap
    FROM essentials.office_terms a, essentials.office_terms b
   WHERE a.office_id = '6334ade6-aa93-47be-99df-925480e02a00'
     AND b.office_id = a.office_id
     AND a.politician_id = '2a054186-d76d-4e50-81f8-2f4e9dd9e871'
     AND b.politician_id = (SELECT id FROM essentials.politicians WHERE slug='stephen-e-scheele')
     AND b.term_start > a.term_end + 1;
  IF n_gap <> 1 THEN
    RAISE EXCEPTION 'expected a recorded vacancy gap between Crone and Scheele, found %', n_gap;
  END IF;

  RAISE NOTICE 'OK: D3 Scheele (Crone closed 2024-11-05, vacant to 2025-01-07), D5 Felix (Robb closed 2023-07-27)';
END $$;

COMMIT;
