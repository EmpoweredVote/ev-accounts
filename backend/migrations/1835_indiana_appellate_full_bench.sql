-- 1835_indiana_appellate_full_bench.sql
--
-- Seat the rest of the Court of Appeals of Indiana. We modelled 11 of its 15 seats, and two of those
-- 11 had no holder at all, so six of the court's fifteen judges were invisible to Essentials.
--
-- ROSTER, taken from each judge's own page under in.gov/courts/appeals/judges/. The district comes
-- from the header block on that page ("(Third District)"), which is the court's own statement of it.
--
--   ⚠ NOT from prose. Judge DeBoer's page also contains the phrase "Third District Representative on
--   the Appellate Practice Section Council" — a BAR ASSOCIATION role. Her court district is the
--   FOURTH. A body-text match would have filed her under District 3.
--
--   D1  Weissmann   2020-09-14  day    "appointed ... by Governor Eric J. Holcomb on September 14, 2020"
--   D2  Kenworthy   2022-12     month  "appointed her to the Court of Appeals in December 2022"
--   D3  Mathias     2000        year   "In 2000, he was appointed to the Court of Appeals."
--   D3  Tavitas     2018-08-06  day    "began her service on August 6, 2018"
--   D4  DeBoer      2024-10-15  day    "sworn in at a private ceremony on October 15, 2024 and
--                                       officially began her duties as judge on that date"
--                                       — in.gov/courts/appeals/news/2024-1114/
--   D5  Vaidik      2000-02     month  "appointed to the Court of Appeals in February 2000"
--
-- Dates are recorded at the precision the source gives, per ADR 0002 — a month-precision start is
-- Jan/Feb 1 with start_precision='month', not a guessed day.
--
-- STRUCTURAL CHECK THAT MADE THIS SAFE: the 15 judges divide 3/3/3/3/3 across the five districts,
-- and the nine we already held all matched their district. A district holding 2 or 4 would have meant
-- the roster was misread; the post-verify below asserts 3-per-district so it can never land wrong.
--
-- FOUR NEW SEATS, TWO REFILLS
--   New offices: D1 (Weissmann), D3 (Mathias), D3 (Tavitas), D5 (Vaidik).
--   Existing offices, holder retired and successor never recorded:
--     Kirsch's D2 seat, term closed 2021-09-23 -> Kenworthy
--     Riley's  D4 seat, term closed 2024-08-30 -> DeBoer
--   Reusing those two is right rather than creating more: each district has exactly THREE seats, so a
--   fourth D2/D4 office would assert a seat that does not exist.
--
--   ⚠ WE DO NOT MODEL SEAT LINEAGE. essentials.offices carries no seat number, so assigning a judge
--   to one of a district's offices is by DISTRICT MEMBERSHIP only. DeBoer genuinely is Riley's
--   successor (Riley retired 2024-08-30; DeBoer was appointed to replace her). For Kenworthy the
--   claim is only that she holds a District 2 seat — the 14-month gap after Kirsch is left as an
--   UNWRITTEN vacancy rather than asserted as a span, because no source for its start was read.
--
-- ⚠ NAME COLLISION, CHECKED. A politician "Terri DeBoer" already exists and is NOT Mary A. DeBoer.
-- Matching on last name alone would have seated the wrong person, so every insert below keys on slug.
--
-- LABELS. The remaining "(Retain X?)" parentheticals are dropped, finishing what 1834 started for the
-- two stale ones. They are retention questions from a past ballot import, districts.label ships to the
-- API as district_label, and leaving seven seats reading "(Retain Bailey?)" beside eight reading plain
-- would be incoherent. The label becomes the seat, matching offices.title.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. The six judges. Keyed on slug; none of these six existed.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (full_name, first_name, middle_initial, last_name, party, slug,
                                    is_active, is_incumbent)
SELECT v.full_name, v.fn, v.mi, v.ln, 'Nonpartisan', v.slug, true, true
FROM (VALUES
        ('Leanna K Weissmann',  'Leanna',    'K', 'Weissmann', 'leanna-k-weissmann'),
        ('Dana J Kenworthy',    'Dana',      'J', 'Kenworthy', 'dana-j-kenworthy'),
        ('Paul D Mathias',      'Paul',      'D', 'Mathias',   'paul-d-mathias'),
        ('Elizabeth F Tavitas', 'Elizabeth', 'F', 'Tavitas',   'elizabeth-f-tavitas'),
        ('Mary A DeBoer',       'Mary',      'A', 'DeBoer',    'mary-a-deboer'),
        ('Nancy H Vaidik',      'Nancy',     'H', 'Vaidik',    'nancy-h-vaidik')
     ) AS v(full_name, fn, mi, ln, slug)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.slug = v.slug);

-- ---------------------------------------------------------------------------
-- 2. Four new districts + offices, then seat all six judges.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  -- ⚠ essentials.chambers is duplicated per seat: ELEVEN rows named 'Indiana Court of Appeals',
  -- one per office. searchBodies groups by ch.slug so they already collapse into a single body;
  -- the new offices reuse the lowest-id row rather than minting four more duplicates.
  c_chamber CONSTANT uuid := (SELECT id FROM essentials.chambers
                               WHERE slug = 'indiana-court-of-appeals'
                               ORDER BY id::text LIMIT 1);
  c_desc CONSTANT text := 'State Appellate Court judges are responsible for hearing cases on appeal '
    || 'from lower courts to determine if the law was interpreted and/or applied correctly. Judges '
    || 'in this position are seeking to retain their current seat.';
  r          record;
  v_district uuid;
  v_office   uuid;
  v_pol      uuid;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      -- slug,                  district, geo_id,    mtfcc,   existing office (NULL = create),        start,             precision
      ('leanna-k-weissmann',  1, '1800001', 'X0029', NULL::uuid,                                      DATE '2020-09-14', 'day'),
      ('dana-j-kenworthy',    2, '1800002', 'X0029', '866639f0-aa9b-4c44-94aa-03612953e18f'::uuid,    DATE '2022-12-01', 'month'),
      ('paul-d-mathias',      3, '1800003', 'X0029', NULL::uuid,                                      DATE '2000-01-01', 'year'),
      ('elizabeth-f-tavitas', 3, '1800003', 'X0029', NULL::uuid,                                      DATE '2018-08-06', 'day'),
      ('mary-a-deboer',       4, '18',      NULL,    '26fa7e2e-138f-4c8a-b6af-a3704b8209d3'::uuid,    DATE '2024-10-15', 'day'),
      ('nancy-h-vaidik',      5, '18',      NULL,    NULL::uuid,                                      DATE '2000-02-01', 'month')
    ) AS v(slug, dist, geo_id, mtfcc, office_id, term_start, precision)
  LOOP
    SELECT id INTO v_pol FROM essentials.politicians WHERE slug = r.slug;
    IF v_pol IS NULL THEN
      RAISE EXCEPTION 'politician % missing', r.slug;
    END IF;

    v_office := r.office_id;

    IF v_office IS NULL THEN
      -- Idempotence: a rerun must not create a second seat for the same judge.
      SELECT o.id INTO v_office
        FROM essentials.offices o
        JOIN essentials.office_terms t ON t.office_id = o.id AND t.politician_id = v_pol
       WHERE o.title LIKE 'Indiana Appeals Court Judge - District%';

      IF v_office IS NULL THEN
        INSERT INTO essentials.districts
          (ocd_id, label, district_type, district_id, subtype, state, num_officials,
           mtfcc, geo_id, is_judicial, has_unknown_boundaries, retention, representation_basis)
        VALUES
          ('ocd-division/country:us/state:in',
           'Indiana Appeals Court Judge - District ' || r.dist,
           'JUDICIAL', r.dist::text, 'District', 'IN', 0,
           r.mtfcc, r.geo_id, true, false, true, 'residency')
        RETURNING id INTO v_district;

        INSERT INTO essentials.offices
          (chamber_id, district_id, title, representing_state, description, seats,
           normalized_position_name, partisan_type, is_appointed_position, is_vacant,
           faces_retention_vote, voting_powers)
        VALUES
          (c_chamber, v_district,
           'Indiana Appeals Court Judge - District ' || r.dist,
           'IN', c_desc, 1,
           'State Appellate Court Justice - Retention', 'nonpartisan', true, false,
           true, 'full')
        RETURNING id INTO v_office;
      END IF;
    END IF;

    PERFORM essentials.seat_officeholder(
      v_office, v_pol, r.term_start,
      'in.gov/courts/appeals/judges/ (court''s own judge page); migration 1835',
      'appointed', r.precision, 'retired');
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Drop the remaining stale retention parentheticals (1834 did the first two).
-- ---------------------------------------------------------------------------
UPDATE essentials.districts
   SET label = regexp_replace(label, '\s*\(Retain .+\?\)$', '')
 WHERE state = 'IN' AND district_type = 'JUDICIAL'
   AND label LIKE 'Indiana Appeals Court Judge - District%'
   AND label ~ '\(Retain .+\?\)$';

-- ---------------------------------------------------------------------------
-- 4. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_offices int; n_held int; n_labels int; bad text;
BEGIN
  SELECT count(*) INTO n_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.state = 'IN' AND d.district_type = 'JUDICIAL'
     AND o.title LIKE 'Indiana Appeals Court Judge - District%';
  IF n_offices <> 15 THEN
    RAISE EXCEPTION 'expected 15 Court of Appeals seats, found %', n_offices;
  END IF;

  -- Every seat filled, by 15 DISTINCT judges.
  SELECT count(DISTINCT och.politician_id) INTO n_held
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.state = 'IN' AND d.district_type = 'JUDICIAL'
     AND o.title LIKE 'Indiana Appeals Court Judge - District%'
     AND och.politician_id IS NOT NULL;
  IF n_held <> 15 THEN
    RAISE EXCEPTION 'expected 15 distinct sitting judges, found %', n_held;
  END IF;

  -- THE STRUCTURAL INVARIANT: exactly three judges per district, all five districts.
  SELECT string_agg(t.district_id || '=' || t.c::text, ' ' ORDER BY t.district_id) INTO bad
    FROM (SELECT d.district_id, count(*) AS c
            FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.state = 'IN' AND d.district_type = 'JUDICIAL'
             AND o.title LIKE 'Indiana Appeals Court Judge - District%'
           GROUP BY d.district_id) AS t(district_id, c)
   WHERE t.c <> 3;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'districts not 3 seats each: %', bad;
  END IF;

  -- Geography: Districts 1-3 on their own polygons, 4 and 5 statewide.
  IF EXISTS (
    SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.state = 'IN' AND d.district_type = 'JUDICIAL'
       AND o.title LIKE 'Indiana Appeals Court Judge - District%'
       AND ((d.district_id IN ('1','2','3') AND d.geo_id <> '180000' || d.district_id)
         OR (d.district_id IN ('4','5')     AND d.geo_id <> '18'))
  ) THEN
    RAISE EXCEPTION 'a Court of Appeals seat is pointed at the wrong geography';
  END IF;

  -- No retention parenthetical survives anywhere on this bench.
  SELECT count(*) INTO n_labels
    FROM essentials.districts
   WHERE state='IN' AND district_type='JUDICIAL'
     AND label LIKE 'Indiana Appeals Court Judge%' AND label ~ '\(Retain ';
  IF n_labels > 0 THEN
    RAISE EXCEPTION '% appellate label(s) still carry a retention question', n_labels;
  END IF;

  RAISE NOTICE 'OK: 15 Court of Appeals seats, 15 distinct judges, 3 per district, labels clean';
END $$;

COMMIT;
