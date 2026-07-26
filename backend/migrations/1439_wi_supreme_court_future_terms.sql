-- 1439_wi_supreme_court_future_terms.sql
-- ADR 0002 phase 4: the Wisconsin Supreme Court, seeded WITH DATED TERMS — including the
-- Bradley -> Taylor hand-off that starts 2026-08-01. Idempotent. Requires 1437 + 1438.
--
-- This is the case the whole ADR exists for. Chris Taylor was certified on 2026-04-07 but does
-- not take office until 2026-08-01. Before office_terms she was unrepresentable: migration 1433
-- had to seed only the circuit court and defer this body entirely. Now she is simply a term with
-- a future term_start, invisible until the date arrives, with nothing scheduled to make it happen.
--
-- ROUTING NEEDS NO NEW GEOMETRY. Verified against the live read matrix: a JUDICIAL district on
--   geo_id '55' matches the statewide G4000 polygon through essentialsService's final fallback
--   clause (G4000 is neither in the excluded mtfcc list nor X-prefixed, so it pairs with any
--   district_type) — the same route the existing WI STATE_EXEC and NATIONAL_UPPER districts take.
--   Tested for a Racine address: it returns both 'Wisconsin Supreme Court' (via G4000) and
--   'Racine County Circuit Court' (via G4020).
--
-- TERM DATES ARE DERIVED, NOT INVENTED. Wisconsin Supreme Court terms are exactly 10 years and
--   run August 1 -> July 31. Wikipedia/the court publish each seat's expiry year, so every
--   term_start is (expiry - 10 years) on August 1. That is arithmetic on a published fact, which
--   is why start_precision is 'day' here rather than the 'year' fudge 1438 had to use.
--     Karofsky      2020-08-01 .. 2030-07-31   (Chief Justice)
--     Ziegler       2017-08-01 .. 2027-07-31
--     Bradley       2016-08-01 .. 2026-07-31   <- ends in 6 days
--     Dallet        2018-08-01 .. 2028-07-31
--     Hagedorn      2019-08-01 .. 2029-07-31
--     Protasiewicz  2023-08-01 .. 2033-07-31
--     Crawford      2025-08-01 .. 2035-07-31
--     Taylor        2026-08-01 .. 2036-07-31   <- SAME OFFICE as Bradley
--   Rebecca Bradley was appointed in Oct 2015 but her CURRENT term began by election in 2016, so
--   how_started='elected' is correct for the term being recorded.
--
-- CHIEF JUSTICE goes in judge_details.court_role, not the office title — consistent with 1433's
--   treatment of the circuit court's chief judge. In Wisconsin the chief justice is chosen BY the
--   justices for a 2-year term; it is a role layered on an ordinary seat, not a separate office.
--   So all seven offices share the title 'Justice' and are guarded on politician_id (the
--   collegial pattern), because six of them are genuinely indistinguishable by title.
--
-- !! CREATES THE FIRST INTENTIONAL DIVERGENCE, and phase 3 has a DEADLINE because of it.
--    offices.politician_id still points at Rebecca Bradley, which is correct today. From
--    2026-08-01 essentials.current_office_holders will return Taylor while
--    offices.politician_id still says Bradley. Any read path still using the column will be
--    WRONG from that date. Phase 3 (moving read paths onto current_office_holders) must therefore
--    land before 2026-08-01 — six days. Until Aug 1 both agree, so applying this today is safe.
--    1438's zero-divergence assertion was a backfill check, not a standing invariant.
--
-- Court of Appeals District II (Anthony LoCoco, also starting 2026-08-01, covering Racine) is
--   deliberately NOT in this migration. It needs a 12-county union polygon under a custom
--   X-prefixed mtfcc, and essentialsService's X-prefix clause only pairs with LOCAL/COUNTY — never
--   JUDICIAL. Adding it needs a read-path change, so it belongs with phase 3 rather than being
--   forced in here behind a fake non-X mtfcc.
--
-- Names use the forms the court and Wikipedia publish; several justices have formal middle names
--   (Annette Kingsland Ziegler, Rebecca Grassl Bradley, Rebecca Frank Dallet) not used here.
-- Nonpartisan bench: party stays NULL, recorded positively via judge_details.election_type.
BEGIN;

-- ── 1. Chamber ──
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, term_length)
SELECT gen_random_uuid(), 'Supreme Court', 'Wisconsin Supreme Court',
       (SELECT id FROM essentials.governments WHERE geo_id = '55'), 7, '10 years'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Supreme Court'
     AND government_id = (SELECT id FROM essentials.governments WHERE geo_id = '55')
);

-- ── 2. Statewide JUDICIAL district (matches the G4000 polygon via the fallback clause) ──
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials, is_judicial)
SELECT '55', 'Wisconsin Supreme Court', 'JUDICIAL', 'WI', '', 7, true
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '55' AND district_type = 'JUDICIAL' AND label = 'Wisconsin Supreme Court'
);

-- ── 3. 8 politicians (7 sitting + Taylor, who is not yet seated) ──
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, v.is_incumbent, false, false
FROM (VALUES
    (-5530001::bigint, 'Jill Karofsky'::text,      'Jill'::text,    'Karofsky'::text,      true),
    (-5530002,         'Annette Ziegler',          'Annette',       'Ziegler',             true),
    (-5530003,         'Rebecca Bradley',          'Rebecca',       'Bradley',             true),
    (-5530004,         'Rebecca Dallet',           'Rebecca',       'Dallet',              true),
    (-5530005,         'Brian Hagedorn',           'Brian',         'Hagedorn',            true),
    (-5530006,         'Janet Protasiewicz',       'Janet',         'Protasiewicz',        true),
    (-5530007,         'Susan M. Crawford',        'Susan',         'Crawford',            true),
    -- Taylor is is_incumbent=false: certified, but does not hold the office until 2026-08-01.
    (-5530008,         'Chris Taylor',             'Chris',         'Taylor',              false)
  ) AS v(external_id, full_name, first_name, last_name, is_incumbent)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

-- ── 4. 7 offices — one per seat. Guarded on politician_id: six share the title 'Justice'. ──
--    offices.politician_id holds TODAY's occupant, so Bradley's seat points at Bradley.
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Justice', 'WI', false, false, 1
FROM (VALUES (-5530001::bigint),(-5530002),(-5530003),(-5530004),
             (-5530005),(-5530006),(-5530007)) AS v(external_id)
JOIN essentials.districts d
  ON d.geo_id='55' AND d.district_type='JUDICIAL' AND d.label='Wisconsin Supreme Court'
JOIN essentials.chambers c
  ON c.name='Supreme Court' AND c.government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id
);

-- ── 5. Terms for the 7 sitting justices, dated ──
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, how_ended, source)
SELECT o.id, p.id, v.term_start::date, v.term_end::date, 'day', 'elected',
       CASE WHEN v.term_end::date < '2036-01-01' THEN 'term_expired' ELSE NULL END,
       'Wisconsin Supreme Court published seat expiry years; 10-year terms running Aug 1 - Jul 31 (ADR 0002 phase 4, migration 1439)'
FROM (VALUES
    (-5530001::bigint, '2020-08-01'::text, '2030-07-31'::text),
    (-5530002,         '2017-08-01',       '2027-07-31'),
    (-5530003,         '2016-08-01',       '2026-07-31'),
    (-5530004,         '2018-08-01',       '2028-07-31'),
    (-5530005,         '2019-08-01',       '2029-07-31'),
    (-5530006,         '2023-08-01',       '2033-07-31'),
    (-5530007,         '2025-08-01',       '2035-07-31')
  ) AS v(external_id, term_start, term_end)
JOIN essentials.politicians p ON p.external_id = v.external_id
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.chambers c ON c.id = o.chamber_id AND c.name = 'Supreme Court'
                          AND c.government_id = (SELECT id FROM essentials.governments WHERE geo_id='55')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot
   WHERE ot.office_id = o.id AND ot.politician_id = p.id
);

-- ── 6. THE POINT: Taylor's future term, on Bradley's office ──
--    Non-overlapping with Bradley's [2016-08-01, 2026-07-31], so the exclusion constraint
--    accepts it: consecutive spans do not collide. Invisible to
--    current_office_holders until 2026-08-01, then automatic.
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, taylor.id, '2026-08-01'::date, '2036-07-31'::date, 'day', 'elected',
       'Elected 2026-04-07 (defeated Maria Lazar 905,157-600,044); 10-year term begins 2026-08-01, succeeding Rebecca Bradley who did not seek re-election (ADR 0002 phase 4)'
FROM essentials.politicians bradley
JOIN essentials.offices o ON o.politician_id = bradley.id
JOIN essentials.chambers c ON c.id = o.chamber_id AND c.name = 'Supreme Court'
                          AND c.government_id = (SELECT id FROM essentials.governments WHERE geo_id='55')
CROSS JOIN essentials.politicians taylor
WHERE bradley.external_id = -5530003
  AND taylor.external_id  = -5530008
  AND NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
     WHERE ot.office_id = o.id AND ot.politician_id = taylor.id
  );

-- ── 7. judge_details: nonpartisan for all 8; Chief Justice role for Karofsky ──
INSERT INTO essentials.judge_details (politician_id, court_role, election_type)
SELECT p.id, v.court_role, 'nonpartisan'
FROM (VALUES
    (-5530001::bigint, 'Chief Justice'::text),
    (-5530002, NULL), (-5530003, NULL), (-5530004, NULL),
    (-5530005, NULL), (-5530006, NULL), (-5530007, NULL), (-5530008, NULL)
  ) AS v(external_id, court_role)
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.judge_details jd WHERE jd.politician_id = p.id);

-- ── 8. Post-verify gate ──
DO $$
DECLARE
  n_off int; n_terms int; n_today int; n_aug1 int; n_overlap int;
  today_name text; aug1_name text;
BEGIN
  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id
     AND c.government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
   WHERE c.name='Supreme Court';
  IF n_off <> 7 THEN RAISE EXCEPTION 'Supreme Court offices: got %, want 7', n_off; END IF;

  SELECT count(*) INTO n_terms FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id=ot.office_id
    JOIN essentials.chambers c ON c.id=o.chamber_id
     AND c.government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
   WHERE c.name='Supreme Court';
  IF n_terms <> 8 THEN
    RAISE EXCEPTION 'Supreme Court terms: got %, want 8 (7 sitting + Taylor)', n_terms;
  END IF;

  -- exactly 7 justices sitting TODAY
  SELECT count(*) INTO n_today FROM essentials.current_office_holders ch
    JOIN essentials.offices o ON o.id=ch.office_id
    JOIN essentials.chambers c ON c.id=o.chamber_id
     AND c.government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
   WHERE c.name='Supreme Court';
  IF n_today <> 7 THEN RAISE EXCEPTION 'justices sitting today: got %, want 7', n_today; END IF;

  -- and exactly 7 on 2026-08-01, with the seat having changed hands
  SELECT count(*) INTO n_aug1 FROM essentials.office_holders_as_of('2026-08-01') a
    JOIN essentials.offices o ON o.id=a.office_id
    JOIN essentials.chambers c ON c.id=o.chamber_id
     AND c.government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
   WHERE c.name='Supreme Court';
  IF n_aug1 <> 7 THEN RAISE EXCEPTION 'justices on 2026-08-01: got %, want 7', n_aug1; END IF;

  SELECT pol.full_name INTO today_name
    FROM essentials.current_office_holders ch
    JOIN essentials.politicians pol ON pol.id=ch.politician_id
    JOIN essentials.offices o ON o.id=ch.office_id
    JOIN essentials.chambers c2 ON c2.id=o.chamber_id AND c2.name='Supreme Court'
                              AND c2.government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
   WHERE o.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5530003);
  IF today_name <> 'Rebecca Bradley' THEN
    RAISE EXCEPTION 'seat should still be Bradley today, got %', today_name;
  END IF;

  SELECT pol.full_name INTO aug1_name
    FROM essentials.office_holders_as_of('2026-08-01') a
    JOIN essentials.politicians pol ON pol.id=a.politician_id
    JOIN essentials.offices o ON o.id=a.office_id
    JOIN essentials.chambers c2 ON c2.id=o.chamber_id AND c2.name='Supreme Court'
                              AND c2.government_id=(SELECT id FROM essentials.governments WHERE geo_id='55')
   WHERE o.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5530003);
  IF aug1_name <> 'Chris Taylor' THEN
    RAISE EXCEPTION 'seat should be Taylor on 2026-08-01, got %', aug1_name;
  END IF;

  -- Taylor must NOT appear today
  SELECT count(*) INTO n_overlap FROM essentials.current_office_holders ch
   WHERE ch.politician_id=(SELECT id FROM essentials.politicians WHERE external_id=-5530008);
  IF n_overlap <> 0 THEN RAISE EXCEPTION 'Taylor is visible before 2026-08-01'; END IF;

  RAISE NOTICE 'WI Supreme Court verify PASSED: 7 seats, 8 terms, Bradley today -> Taylor on 2026-08-01, Taylor invisible until then.';
END $$;

COMMIT;
