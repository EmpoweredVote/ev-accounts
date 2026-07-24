-- Migration 1389: Seat 20 directly-cited current officeholders across 10 Collin County, TX cities
-- (Phase 218 Plan 02 — vacancies-missing-people)
--
-- Depends on: migrations 088/090 (structural office rows) + 1388 (6 missing office rows added by
-- Phase 218 Plan 01: Blue Ridge Place 5, Lowry Crossing Place 5-8, Weston Place 5).
--
-- Cities (alphabetical): Anna, Blue Ridge, Fairview (Town), Josephine, Lowry Crossing, Parker,
-- Plano, Princeton, Van Alstyne, Weston.
--
-- Every DO block is idempotency-guarded on `o.politician_id IS NULL` — safe to re-run; a
-- re-run seats ZERO additional people once applied once.
--
-- D-05 (antipartisan): party = NULL / party_short_name = NULL on every INSERT — all TX general-law
-- municipal offices are nonpartisan.
-- D-06: no inform.politician_answers / compass-stance rows are created by this migration.
--
-- Deviation note (documented in 218-02-SUMMARY.md): Plano Council Member Place 7 (Shun Thomas) is
-- ALREADY SEATED by migration 091 (applied 2026-05, pre-dates this phase) — confirmed via live DB
-- precheck. Its DO block below is included for completeness against the plan's 20-office list but
-- is expected to no-op (RAISE NOTICE only, no INSERT) on every run, including the first.
--
-- Deviation note #2 (Rule 1 bug fix, documented in 218-02-SUMMARY.md): 6 of the 20 target offices
-- (Anna Place 3/5, Fairview Seat 2/6, Josephine Place 5, Parker Mayor) already had a pre-existing
-- `essentials.politicians` row for the exact same person (office_id set, but `offices.politician_id`
-- was never back-filled) — leftover discovery-pipeline candidate rows from the May 2026 election
-- cycle (5 of the 6 are linked to `essentials.race_candidates`; Josephine's Gary Chappell orphan
-- additionally carries a real `politician_images` headshot). A naive INSERT would have created a
-- true duplicate-officeholder row per office. Those 6 DO blocks below therefore UPDATE the existing
-- orphan row in place (preserving its id, and therefore its race_candidates/photo linkage) instead
-- of inserting a new one; the other 14 DO blocks use a plain INSERT since no such orphan exists for
-- their office_id.
--
-- Lowry Crossing Ward 4 note: the city's own site has no published "first" vs "second" Ward-4-seat
-- distinction (Place 4 / Place 8 are our internal DB slugs only, not city-published labels) — the
-- Hijazen->Place4 / Simpson->Place8 assignment below is a best-effort, low-impact assumption
-- (both are equally well-cited as current Ward 4 members; only the specific row is unresolved).
-- Flagged for Plan 03/05 re-verify if a future source clarifies seniority/original-vacancy order.

BEGIN;

-- =============================================================================
-- ANNA (geo_id 4803300)
-- =============================================================================

-- Anna Council Member Place 3 — Jessica Walden
-- Source: directory.tml.org/profile/city/1286 (TML City Officials Directory); corroborated via
-- WebSearch of annatexas.gov/319/City-Council. Won the May 2, 2026 contested race vs. Mike Olivarez.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4803300' AND o.title = 'Council Member Place 3'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Anna Place 3 already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse a pre-existing candidate-pipeline politician row for this office_id if one exists
    -- (discovered live: a May-2026 discovery-pipeline candidate row for Jessica Walden already
    -- carried office_id set, but offices.politician_id was never back-filled) — avoids a duplicate.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'Jessica' AND p.last_name = 'Walden'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        valid_from = '2026-05-01', valid_to = '2029-05-01', term_date_precision = 'month',
        urls = COALESCE(urls, ARRAY['https://www.annatexas.gov/319/City-Council']),
        data_source = COALESCE(data_source, 'annatexas.gov')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: Jessica Walden (Anna Place 3) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'Jessica', 'Walden', 'Jessica', 'Jessica Walden',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2026-05-01', '2029-05-01', 'month',
        NULL,
        ARRAY['https://www.annatexas.gov/319/City-Council'],
        'annatexas.gov'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: Jessica Walden (Anna Place 3) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

-- Anna Council Member Place 5 — Elden Baker (retained, now Mayor Pro Tem)
-- Source: directory.tml.org/profile/city/1286.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4803300' AND o.title = 'Council Member Place 5'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Anna Place 5 already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse a pre-existing candidate-pipeline politician row for this office_id if one exists.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'Elden' AND p.last_name = 'Baker'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        valid_from = '2026-05-01', valid_to = '2029-05-01', term_date_precision = 'month',
        urls = COALESCE(urls, ARRAY['https://www.annatexas.gov/319/City-Council']),
        data_source = COALESCE(data_source, 'annatexas.gov')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: Elden Baker (Anna Place 5) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'Elden', 'Baker', 'Elden', 'Elden Baker',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2026-05-01', '2029-05-01', 'month',
        NULL,
        ARRAY['https://www.annatexas.gov/319/City-Council'],
        'annatexas.gov'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: Elden Baker (Anna Place 5) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

-- =============================================================================
-- BLUE RIDGE (geo_id 4808872)
-- Live-verified all 3 rows to 2026-07-23 blueridgecity.com/council fetch (Phase 218 Plan 01);
-- all three explicitly cited "term through May 2028".
-- Zero-photo city (documented milestone-wide) — no headshot expected (Plan 04).
-- =============================================================================

-- Blue Ridge Mayor — Rhonda Williams (retained)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4808872' AND o.title = 'Mayor'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Blue Ridge Mayor already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Rhonda', 'Williams', 'Rhonda', 'Rhonda Williams',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2028-05-01', 'month',
      ARRAY['mayor@blueridgecity.com'],
      ARRAY['https://blueridgecity.com/council'],
      'blueridgecity.com'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Rhonda Williams (Blue Ridge Mayor) — %', v_politician_id;
  END IF;
END $$;

-- Blue Ridge Council Member Place 1 — David Apple (retained)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4808872' AND o.title = 'Council Member Place 1'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Blue Ridge Place 1 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'David', 'Apple', 'David', 'David Apple',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2028-05-01', 'month',
      ARRAY['council1@blueridgecity.com'],
      ARRAY['https://blueridgecity.com/council'],
      'blueridgecity.com'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: David Apple (Blue Ridge Place 1) — %', v_politician_id;
  END IF;
END $$;

-- Blue Ridge Council Member Place 5 — Keith Chitwood (new office row from Plan 01, genuine 5th seat)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4808872' AND o.title = 'Council Member Place 5'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Blue Ridge Place 5 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Keith', 'Chitwood', 'Keith', 'Keith Chitwood',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2028-05-01', 'month',
      ARRAY['council5@blueridgecity.com'],
      ARRAY['https://blueridgecity.com/council'],
      'blueridgecity.com'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Keith Chitwood (Blue Ridge Place 5) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- FAIRVIEW (Town of Fairview) (geo_id 4825224) — SQL lookup uses 'Council Member Seat N'
-- =============================================================================

-- Fairview Council Member Seat 2 — Joe Boggs (new; Gregg Custer not seeking re-election)
-- Source: directory.tml.org/profile/city/466.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825224' AND o.title = 'Council Member Seat 2'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Fairview Seat 2 already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse a pre-existing candidate-pipeline politician row for this office_id if one exists.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'Joe' AND p.last_name = 'Boggs'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        valid_from = '2026-05-01', valid_to = '2029-05-01', term_date_precision = 'month',
        urls = COALESCE(urls, ARRAY['https://directory.tml.org/profile/city/466']),
        data_source = COALESCE(data_source, 'directory.tml.org')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: Joe Boggs (Fairview Seat 2) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'Joe', 'Boggs', 'Joe', 'Joe Boggs',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2026-05-01', '2029-05-01', 'month',
        NULL,
        ARRAY['https://directory.tml.org/profile/city/466'],
        'directory.tml.org'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: Joe Boggs (Fairview Seat 2) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

-- Fairview Council Member Seat 6 — Lakia Works (retained, won contested race vs. Riyad)
-- Source: directory.tml.org/profile/city/466.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825224' AND o.title = 'Council Member Seat 6'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Fairview Seat 6 already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse a pre-existing candidate-pipeline politician row for this office_id if one exists.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'Lakia' AND p.last_name = 'Works'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        valid_from = '2026-05-01', valid_to = '2029-05-01', term_date_precision = 'month',
        urls = COALESCE(urls, ARRAY['https://directory.tml.org/profile/city/466']),
        data_source = COALESCE(data_source, 'directory.tml.org')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: Lakia Works (Fairview Seat 6) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'Lakia', 'Works', 'Lakia', 'Lakia Works',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2026-05-01', '2029-05-01', 'month',
        NULL,
        ARRAY['https://directory.tml.org/profile/city/466'],
        'directory.tml.org'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: Lakia Works (Fairview Seat 6) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

-- =============================================================================
-- JOSEPHINE (geo_id 4838068)
-- =============================================================================

-- Josephine Council Member Place 5 — Gary Chappell (continuing incumbent; office row was added
-- between May and July 2026 by someone else — see Plan 01 SUMMARY — this migration only seats him)
-- Source: directory.tml.org/profile/city/994; corroborated via WebSearch of TML + Josephine council page.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 5'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Josephine Place 5 already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse the pre-existing candidate-pipeline politician row for this office_id (this one already
    -- carries a real headshot in essentials.politician_images — preserving its id keeps that photo
    -- linked; do NOT insert a new row, which would orphan the photo). Its existing valid_from/valid_to
    -- (2024-05-01 / 2026-11-01) are left untouched rather than overwritten with this migration's
    -- best-guess 2027-05-01 sibling-convention date, since the existing row's dates may reflect a
    -- prior, more specific finding — only fields this migration can assert with confidence (party,
    -- active/incumbent/vacant/appointed flags, data_source) are updated.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'Gary' AND p.last_name = 'Chappell'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        urls = COALESCE(urls, ARRAY['https://directory.tml.org/profile/city/994']),
        data_source = COALESCE(data_source, 'cityofjosephinetx.com')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: Gary Chappell (Josephine Place 5) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'Gary', 'Chappell', 'Gary', 'Gary Chappell',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2024-05-01', '2027-05-01', 'month',
        NULL,
        ARRAY['https://directory.tml.org/profile/city/994'],
        'cityofjosephinetx.com'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: Gary Chappell (Josephine Place 5) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

-- =============================================================================
-- LOWRY CROSSING (geo_id 4844308)
-- Ward-mapped: Place 4 = 1st Ward 4 winner (pre-existing office row); Place 5-8 = the 2nd member
-- of Wards 1/2/3 + the 2nd Ward 4 winner (all 4 are new office rows added by Plan 01).
-- LOCKED mapping per Plan 01 SUMMARY: Place5=Madrid(Ward1), Place6=Rios(Ward2), Place7=Cash(Ward3).
-- Zero-photo city (documented milestone-wide) — no headshot expected (Plan 04).
-- =============================================================================

-- Lowry Crossing Council Member Place 4 — Muhanad "G" Hijazen
-- Ward 4, 1st (pre-existing) seat. Both Hijazen and Simpson are confirmed current Ward 4 members
-- per the live 2026-07-23 lowrycrossingtexas.org/operations/city_council.php fetch (Plan 01); the
-- city itself publishes no first/second distinction between the two Ward 4 seats — this specific
-- Place4-vs-Place8 row assignment is a low-impact assumption (see migration header note + SUMMARY).
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 4'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Lowry Crossing Place 4 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Muhanad', 'Hijazen', 'G', 'Muhanad "G" Hijazen',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2027-05-01', 'month',
      ARRAY['ghijazen@lowrycrossingtexas.org'],
      ARRAY['https://www.lowrycrossingtexas.org/operations/city_council.php'],
      'lowrycrossingtexas.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Muhanad "G" Hijazen (Lowry Crossing Place 4) — %', v_politician_id;
  END IF;
END $$;

-- Lowry Crossing Council Member Place 5 — Chris Madrid (Ward 1, 2nd member; DB-gap continuing incumbent)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 5'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Lowry Crossing Place 5 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Chris', 'Madrid', 'Chris', 'Chris Madrid',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2024-05-01', '2027-05-01', 'month',
      ARRAY['cmadrid@lowrycrossingtexas.org'],
      ARRAY['https://www.lowrycrossingtexas.org/operations/city_council.php'],
      'lowrycrossingtexas.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Chris Madrid (Lowry Crossing Place 5) — %', v_politician_id;
  END IF;
END $$;

-- Lowry Crossing Council Member Place 6 — Agur Rios (Ward 2, 2nd member; DB-gap continuing incumbent)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 6'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Lowry Crossing Place 6 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Agur', 'Rios', 'Agur', 'Agur Rios',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2024-05-01', '2027-05-01', 'month',
      NULL,
      ARRAY['https://www.lowrycrossingtexas.org/operations/city_council.php'],
      'lowrycrossingtexas.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Agur Rios (Lowry Crossing Place 6) — %', v_politician_id;
  END IF;
END $$;

-- Lowry Crossing Council Member Place 7 — Cindy Cash (Ward 3, 2nd member; DB-gap continuing incumbent)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 7'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Lowry Crossing Place 7 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Cindy', 'Cash', 'Cindy', 'Cindy Cash',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2024-05-01', '2027-05-01', 'month',
      ARRAY['ccash@lowrycrossingtexas.org'],
      ARRAY['https://www.lowrycrossingtexas.org/operations/city_council.php'],
      'lowrycrossingtexas.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Cindy Cash (Lowry Crossing Place 7) — %', v_politician_id;
  END IF;
END $$;

-- Lowry Crossing Council Member Place 8 — Ollie Simpson
-- Ward 4, 2nd seat (new office row from Plan 01). See Place 4 note above re: assumption.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 8'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Lowry Crossing Place 8 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Ollie', 'Simpson', 'Ollie', 'Ollie Simpson',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2027-05-01', 'month',
      ARRAY['osimpson@lowrycrossingtexas.org'],
      ARRAY['https://www.lowrycrossingtexas.org/operations/city_council.php'],
      'lowrycrossingtexas.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Ollie Simpson (Lowry Crossing Place 8) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- PARKER (geo_id 4855152) — city does NOT publish Place numbers (positional assignment,
-- preserved from the original migration's convention; do not fabricate a new mapping).
-- =============================================================================

-- Parker Mayor — Lee Pettle (won 3-candidate race vs. Marcus Arias, Melissa Tierce)
-- Source: directory.tml.org/profile/city/1765.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4855152' AND o.title = 'Mayor'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Parker Mayor already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse a pre-existing candidate-pipeline politician row for this office_id if one exists.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'Lee' AND p.last_name = 'Pettle'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        valid_from = '2026-05-01', valid_to = '2029-05-01', term_date_precision = 'month',
        urls = COALESCE(urls, ARRAY['https://directory.tml.org/profile/city/1765']),
        data_source = COALESCE(data_source, 'directory.tml.org')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: Lee Pettle (Parker Mayor) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'Lee', 'Pettle', 'Lee', 'Lee Pettle',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2026-05-01', '2029-05-01', 'month',
        NULL,
        ARRAY['https://directory.tml.org/profile/city/1765'],
        'directory.tml.org'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: Lee Pettle (Parker Mayor) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

-- Parker Council Member Place 3 — Buddy Pilgrim (now Mayor Pro Tem; won at-large top-2-of-4 race)
-- Source: directory.tml.org/profile/city/1765.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4855152' AND o.title = 'Council Member Place 3'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Parker Place 3 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Buddy', 'Pilgrim', 'Buddy', 'Buddy Pilgrim',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2029-05-01', 'month',
      NULL,
      ARRAY['https://directory.tml.org/profile/city/1765'],
      'directory.tml.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Buddy Pilgrim (Parker Place 3) — %', v_politician_id;
  END IF;
END $$;

-- Parker Council Member Place 5 — Billy Barron (won same at-large top-2-of-4 race as Place 3)
-- Source: directory.tml.org/profile/city/1765.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4855152' AND o.title = 'Council Member Place 5'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Parker Place 5 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Billy', 'Barron', 'Billy', 'Billy Barron',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2029-05-01', 'month',
      NULL,
      ARRAY['https://directory.tml.org/profile/city/1765'],
      'directory.tml.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Billy Barron (Parker Place 5) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- PLANO (geo_id 4858016)
-- =============================================================================

-- Plano Council Member Place 7 — Shun Thomas
-- NOTE: this office was ALREADY SEATED by migration 091_plano_politicians.sql (applied 2026-05,
-- pre-dates Phase 218 — confirmed via live DB precheck 2026-07-24). This DO block is included for
-- completeness against the plan's target-office list but is expected to be a pure no-op on every
-- run (the politician_id IS NULL guard will simply not match, printing the skip notice below).
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4858016' AND o.title = 'Council Member Place 7'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Plano Place 7 already seated (migration 091, pre-dates Phase 218) — skipping (idempotent, expected)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Shun', 'Thomas', 'Shun', 'Shun Thomas',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-02-09', '2027-05-01', 'month',
      ARRAY['shunthomas@plano.gov'],
      ARRAY['https://www.plano.gov/1358/Councilmember-Shun-Thomas'],
      'plano.gov'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Shun Thomas (Plano Place 7) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- PRINCETON (geo_id 4859576)
-- =============================================================================

-- Princeton Council Member Place 4 — Jaisen Rutledge
-- Seat vacated mid-term when Ryan Gerfers resigned (health reasons); May 2, 2026 special election
-- (4 candidates) went to a runoff; Rutledge won the June 13, 2026 runoff 293-245 over Jan Goria;
-- certified by City Council June 23, 2026.
-- Source: Princeton Herald "City council runoff results FINAL" (2026-06-13); Princeton Herald
-- "Runoff required for Place 4 council seat" (2026-05-07); princetontx.gov "City Council Highlights"
-- newsflash (2026-06-23) confirming certification.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4859576' AND o.title = 'Council Member Place 4'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Princeton Place 4 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Jaisen', 'Rutledge', 'Jaisen', 'Jaisen Rutledge',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-06-23', '2027-05-01', 'month',
      NULL,
      NULL,
      'princetontx.gov'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Jaisen Rutledge (Princeton Place 4) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- VAN ALSTYNE (geo_id 4874924) — term_date_precision='day' per established Van Alstyne convention.
-- =============================================================================

-- Van Alstyne Mayor — Jim Atchison (retained, won 399-71 over Kevin Soucie)
-- Source: KTEN "VAN ALSTYNE, Texas (KTEN) - Mayor Jim Atchison is returning..."; Ballotpedia
-- candidate pages for both Atchison and Soucie.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4874924' AND o.title = 'Mayor'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Van Alstyne Mayor already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Jim', 'Atchison', 'Jim', 'Jim Atchison',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-03', '2029-05-01', 'day',
      NULL,
      NULL,
      'cityofvanalstyne.us'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Jim Atchison (Van Alstyne Mayor) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- WESTON (geo_id 4877740)
-- =============================================================================

-- Weston Council Member Place 5 — Marla Johnston (new office row from Plan 01; genuine 6th aldermanic
-- seat). Live-verified 2026-07-23 (Plan 01) still current: "Term Expires Nov 2026" — matching the same
-- 2-year cohort as fellow aldermen Jeff Metzger and Mike Hill.
-- Source: westontexas.com/page/Mayor_Aldermen (live-fetched 2026-07-23); cross-referenced against
-- migration 098's original May-2026 comment header naming her as the DB-gap 6th alderman.
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4877740' AND o.title = 'Council Member Place 5'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Weston Place 5 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Marla', 'Johnston', 'Marla', 'Marla Johnston',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2024-11-01', '2026-11-01', 'month',
      NULL,
      ARRAY['https://westontexas.com/page/Mayor_Aldermen'],
      'westontexas.com'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Marla Johnston (Weston Place 5) — %', v_politician_id;
  END IF;
END $$;

COMMIT;
