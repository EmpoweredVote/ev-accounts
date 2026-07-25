-- Migration 1390: Deeper D-04 re-verify + seat the 7 flagged-uncertain Collin County, TX offices
-- (Phase 218 Plan 03 — vacancies-missing-people)
--
-- Depends on: migrations 088/090 (structural office rows) + 1389 (Plan 02's 20 directly-cited seats).
-- None of the 7 offices below were touched by 1389.
--
-- These 7 offices were flagged in 218-RESEARCH.md for a MANDATORY deeper D-04 re-verify (city site
-- direct fetch -> official election canvass -> second independent source) before locking, because the
-- original RESEARCH citation for each was either single-source (TML directory only) or WebSearch
-- synthesis rather than a direct fetch:
--   - Fairview Council Member Seat 4 (geo_id 4825224) — A1, TML-directory-only in RESEARCH.
--   - Van Alstyne Council Member Place 6 (geo_id 4874924) — A2, no direct election-result citation.
--   - Nevada Mayor / Place 1 / Place 2 (geo_id 4850760) — A3, WebSearch-synthesis only.
--   - Lucas Council Member Place 1 / Place 2 (geo_id 4845012) — A4, inferred Place<->Seat mapping.
--
-- Deeper D-04 re-verify performed live (2026-07-24), recorded in 218-03-SUMMARY.md with full citations:
--   - Fairview Seat 4: re-fetched fairviewtexas.org/government/mayor-town-council/ (live official town
--     roster) AND the Collin County official canvass PDF (May 2, 2026 Joint General and Special
--     Election, Summary Results Report) — John Stanley 384 votes (52.10%) defeated Ricardo Doi 353
--     (47.90%). Triple-confirmed (TML + live town site + county canvass).
--   - Van Alstyne Place 6: re-fetched the city's own live council roster (cityofvanalstyne.us/council,
--     backed by its membershipware people-API) — official bio text reads "Zach Williams was elected to
--     City Council Place 6 in 2026," directly confirming an ELECTION win (not a resignation/appointment
--     replacing Angelica Pena, as A2 worried).
--   - Nevada Mayor/Place 1/Place 2: direct single-page fetch of cityofnevadatx.org/government/
--     city_council.php (the direct fetch A3 asked for, superseding the earlier WebSearch synthesis) —
--     staff directory table lists "Donald Deering Mayor", "Mike Laye Council Member - Place 1", "Paul
--     Baker Council Member - Place 2" verbatim. Note: city's own listing spells the first name "Mike"
--     (not "Michael") — used as authoritative.
--   - Lucas Place 1/Place 2: the Collin County official canvass PDF (May 2, 2026 Joint General and
--     Special Election) explicitly lists "City Council, Seat 1 - City of Lucas: Jonathan Underhill 505
--     votes (85.74%)" and "City Council, Seat 2 - City of Lucas: Rebecca B. Orr 396 votes (63.56%)" —
--     proving (not just inferring) that the DB's Place 1/Place 2 rows map positionally to the site's
--     Seat 1/Seat 2 labels, exactly as A4's RESEARCH inference guessed.
--
-- Result: all 7 flagged offices are SEAT decisions (deeper search found a confirmed cited incumbent
-- for every one) — zero DOCUMENTED VACANCY decisions needed this migration.
--
-- LANDMINE HELD: Lucas office titles remain 'Council Member Place 1' / 'Council Member Place 2' in
-- this migration — NOT renamed to 'Seat N', even though the canvass confirms the site's "Seat"
-- terminology. Seat the confirmed people into the existing Place-titled DB rows only.
--
-- D-05 (antipartisan): party = NULL / party_short_name = NULL on every INSERT/UPDATE.
-- D-06: no inform.politician_answers / compass-stance rows are created by this migration.
--
-- Reuse note (Rule 1 pattern from Plan 02, re-applied here): a live-DB precheck (218-03) found 2 of
-- the 7 target offices already had a matching-name orphan `essentials.politicians` row from the same
-- May-2026 discovery-pipeline cohort (office_id set, offices.politician_id never back-filled, source=
-- 'election_results_2026_05_02', each linked to one essentials.race_candidates row): Fairview Seat 4
-- (John Stanley) and Lucas Place 2 (Rebecca Orr). Both DO blocks below UPDATE the existing orphan row
-- in place (preserving its id and race_candidates linkage) instead of inserting a duplicate. The other
-- 5 offices have no such orphan and use a plain INSERT.

BEGIN;

-- =============================================================================
-- FAIRVIEW (Town of Fairview) (geo_id 4825224) — SQL lookup uses 'Council Member Seat N'
-- =============================================================================

-- Fairview Council Member Seat 4 — John Stanley (new; Larry Little not seeking re-election)
-- Sources: directory.tml.org/profile/city/466; fairviewtexas.org/government/mayor-town-council/
-- (live-fetched 2026-07-24, official town roster: "John Stanley, Seat Four"); Collin County official
-- canvass (May 2, 2026 Joint General and Special Election, Town Council Seat 4 - Town of Fairview:
-- Stanley 384 votes / 52.10% def. Ricardo Doi 353 / 47.90%).
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825224' AND o.title = 'Council Member Seat 4'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Fairview Seat 4 already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse the pre-existing candidate-pipeline politician row for this office_id (May-2026 discovery
    -- pipeline row, source='election_results_2026_05_02', linked to a race_candidates row) rather than
    -- inserting a duplicate.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'John' AND p.last_name = 'Stanley'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        valid_from = '2026-05-01', valid_to = '2029-05-01', term_date_precision = 'month',
        urls = COALESCE(urls, ARRAY['https://fairviewtexas.org/government/mayor-town-council/']),
        data_source = COALESCE(data_source, 'fairviewtexas.org')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: John Stanley (Fairview Seat 4) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'John', 'Stanley', 'John', 'John Stanley',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2026-05-01', '2029-05-01', 'month',
        ARRAY['JStanley@FairviewTexas.org'],
        ARRAY['https://fairviewtexas.org/government/mayor-town-council/'],
        'fairviewtexas.org'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: John Stanley (Fairview Seat 4) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

-- =============================================================================
-- VAN ALSTYNE (geo_id 4874924) — term_date_precision='day' per established Van Alstyne convention.
-- =============================================================================

-- Van Alstyne Council Member Place 6 — Zach Williams (elected 2026, replacing stubbed Angelica Pena)
-- Sources: directory.tml.org/profile/city/524; cityofvanalstyne.us/council (live-fetched 2026-07-24,
-- official city roster bio: "Zach Williams was elected to City Council Place 6 in 2026").
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4874924' AND o.title = 'Council Member Place 6'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Van Alstyne Place 6 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Zach', 'Williams', 'Zach', 'Zach Williams',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-02', '2029-05-01', 'day',
      NULL,
      ARRAY['https://www.cityofvanalstyne.us/council'],
      'cityofvanalstyne.us'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Zach Williams (Van Alstyne Place 6) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- NEVADA (geo_id 4850760) — all 3 ran unopposed; direct city-site fetch supersedes RESEARCH's
-- earlier WebSearch synthesis. Documented zero-photo city (no headshot expected, Plan 04).
-- =============================================================================

-- Nevada Mayor — Donald Deering
-- Source: cityofnevadatx.org/government/city_council.php (live-fetched 2026-07-24, direct staff
-- directory table: "Donald Deering Mayor mayor@cityofnevadatx.org").
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4850760' AND o.title = 'Mayor'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Nevada Mayor already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Donald', 'Deering', 'Donald', 'Donald Deering',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2028-05-01', 'month',
      ARRAY['mayor@cityofnevadatx.org'],
      ARRAY['https://www.cityofnevadatx.org/government/city_council.php'],
      'cityofnevadatx.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Donald Deering (Nevada Mayor) — %', v_politician_id;
  END IF;
END $$;

-- Nevada Council Member Place 1 — Mike Laye (city's own listing spells it "Mike", not "Michael")
-- Source: cityofnevadatx.org/government/city_council.php (live-fetched 2026-07-24).
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4850760' AND o.title = 'Council Member Place 1'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Nevada Place 1 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Mike', 'Laye', 'Mike', 'Mike Laye',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2028-05-01', 'month',
      ARRAY['councilman1@cityofnevadatx.org'],
      ARRAY['https://www.cityofnevadatx.org/government/city_council.php'],
      'cityofnevadatx.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Mike Laye (Nevada Place 1) — %', v_politician_id;
  END IF;
END $$;

-- Nevada Council Member Place 2 — Paul Baker
-- Source: cityofnevadatx.org/government/city_council.php (live-fetched 2026-07-24).
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4850760' AND o.title = 'Council Member Place 2'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Nevada Place 2 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Paul', 'Baker', 'Paul', 'Paul Baker',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2028-05-01', 'month',
      ARRAY['councilman2@cityofnevadatx.org'],
      ARRAY['https://www.cityofnevadatx.org/government/city_council.php'],
      'cityofnevadatx.org'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Paul Baker (Nevada Place 2) — %', v_politician_id;
  END IF;
END $$;

-- =============================================================================
-- LUCAS (geo_id 4845012) — LANDMINE: title stays 'Council Member Place N', NEVER renamed to 'Seat N'.
-- Place<->Seat positional mapping (Place1=Seat1, Place2=Seat2) proven (not just inferred) by the
-- Collin County official canvass below.
-- =============================================================================

-- Lucas Council Member Place 1 — Jonathan Underhill (won Seat 1 per canvass; replaces Tim Johnson,
-- who was not seeking re-election)
-- Sources: lucastexas.us/164/City-Council; Collin County official canvass (May 2, 2026 Joint General
-- and Special Election, "City Council, Seat 1 - City of Lucas": Underhill 505 votes / 85.74% def.
-- Richard Alan 84 / 14.26%).
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845012' AND o.title = 'Council Member Place 1'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Lucas Place 1 already seated or office not found — skipping (idempotent)';
  ELSE
    INSERT INTO essentials.politicians (
      first_name, last_name, preferred_name, full_name,
      party, party_short_name,
      is_active, is_incumbent, is_vacant, is_appointed,
      office_id, valid_from, valid_to, term_date_precision,
      email_addresses, urls, data_source
    ) VALUES (
      'Jonathan', 'Underhill', 'Jonathan', 'Jonathan Underhill',
      NULL, NULL,
      true, true, false, false,
      v_office_id, '2026-05-01', '2029-05-01', 'month',
      ARRAY['junderhill@lucastexas.us'],
      NULL,
      'lucastexas.us'
    ) RETURNING id INTO v_politician_id;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
    RAISE NOTICE 'Inserted: Jonathan Underhill (Lucas Place 1) — %', v_politician_id;
  END IF;
END $$;

-- Lucas Council Member Place 2 — Rebecca Orr (won Seat 2 per canvass; replaces Brian Stubblefield,
-- who was not seeking re-election)
-- Sources: lucastexas.us/164/City-Council; Collin County official canvass (May 2, 2026 Joint General
-- and Special Election, "City Council, Seat 2 - City of Lucas": Rebecca B. Orr 396 votes / 63.56% def.
-- John Awezec 227 / 36.44%).
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845012' AND o.title = 'Council Member Place 2'
    AND o.politician_id IS NULL;

  IF v_office_id IS NULL THEN
    RAISE NOTICE 'Lucas Place 2 already seated or office not found — skipping (idempotent)';
  ELSE
    -- Reuse the pre-existing candidate-pipeline politician row for this office_id (May-2026 discovery
    -- pipeline row, source='election_results_2026_05_02', linked to a race_candidates row) rather than
    -- inserting a duplicate.
    SELECT p.id INTO v_politician_id
    FROM essentials.politicians p
    WHERE p.office_id = v_office_id AND p.first_name = 'Rebecca' AND p.last_name = 'Orr'
    LIMIT 1;

    IF v_politician_id IS NOT NULL THEN
      UPDATE essentials.politicians SET
        party = NULL, party_short_name = NULL,
        is_active = true, is_incumbent = true, is_vacant = false, is_appointed = false,
        valid_from = '2026-05-01', valid_to = '2029-05-01', term_date_precision = 'month',
        urls = COALESCE(urls, NULL),
        email_addresses = COALESCE(email_addresses, ARRAY['rorr@lucastexas.us']),
        data_source = COALESCE(data_source, 'lucastexas.us')
      WHERE id = v_politician_id;
      RAISE NOTICE 'Updated existing candidate row: Rebecca Orr (Lucas Place 2) — %', v_politician_id;
    ELSE
      INSERT INTO essentials.politicians (
        first_name, last_name, preferred_name, full_name,
        party, party_short_name,
        is_active, is_incumbent, is_vacant, is_appointed,
        office_id, valid_from, valid_to, term_date_precision,
        email_addresses, urls, data_source
      ) VALUES (
        'Rebecca', 'Orr', 'Rebecca', 'Rebecca Orr',
        NULL, NULL,
        true, true, false, false,
        v_office_id, '2026-05-01', '2029-05-01', 'month',
        ARRAY['rorr@lucastexas.us'],
        NULL,
        'lucastexas.us'
      ) RETURNING id INTO v_politician_id;
      RAISE NOTICE 'Inserted: Rebecca Orr (Lucas Place 2) — %', v_politician_id;
    END IF;

    UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  END IF;
END $$;

COMMIT;
