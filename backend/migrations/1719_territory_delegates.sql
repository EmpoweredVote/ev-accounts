-- 1719_territory_delegates.sql
--
-- ADR 0003's second instance: the six non-voting seats that U.S. territories and the District of
-- Columbia hold in the House of Representatives.
--
-- ⚠️ ADR 0003 CALLED THIS "a powers-only change". That was true of the SEAT and wrong about the DATA.
-- We held nothing at all for Puerto Rico, the U.S. Virgin Islands, Guam, American Samoa or the
-- Northern Mariana Islands — no politician, no office, no district, and no geometry. Only DC existed.
-- So five of the six are a full seed, and only DC is the powers-only flip the ADR imagined.
--
-- Roster oracle is the Clerk of the House member list (clerk.house.gov/xml/lists/MemberData.xml,
-- publish-date July 6, 2026, 119th Congress), all six sworn 2025-01-03:
--   AS  Aumua Amata Coleman Radewagen  (R)  Delegate               R000600
--   DC  Eleanor Holmes Norton          (D)  Delegate               N000147   <- already held
--   GU  James C. Moylan                (R)  Delegate               M001219
--   MP  Kimberlyn King-Hinds           (R)  Delegate               K000404
--   PR  Pablo José Hernández           (D)  Resident Commissioner  H001103
--   VI  Stacey E. Plaskett             (D)  Delegate               P000610
--
-- 🔴 AMERICAN SAMOA'S <statedistrict> IN THAT FILE IS "AQ00", NOT "AS00". Filtering on it silently
-- returned five of six and made American Samoa look like a vacancy — the seat of a sitting delegate.
-- Keyed on the <state postal-code> attribute instead. If you re-derive this list, do not filter on
-- statedistrict.
--
-- 🔴 UNLIKE MAINE'S TRIBAL SEATS, THESE ARE RESIDENCY-BASED. A San Juan address SHOULD return the
-- Resident Commissioner, so `representation_basis` stays 'residency' and each district carries a real
-- polygon. Only `voting_powers` differs from an ordinary House seat — which is exactly why ADR 0003
-- made powers and basis two axes instead of one flag. Polygons were loaded first by
-- scripts/load-territory-boundaries.mjs from Census TIGERweb, each verified to contain its own
-- capital before insert (Pago Pago and Saipan sit near the antimeridian, American Samoa in the
-- southern hemisphere — the cases a bad polygon would quietly ruin).
--
-- Delegate districts use the Census convention FIPS || '98' (DC was already '1198'): PR 7298,
-- VI 7898, GU 6698, AS 6098, MP 6998. ocd_id follows the shape already on the DC row
-- ('ocd-division/country:us/state:dc/cd:98'); the OCD project itself prefers `territory:` for these,
-- but internal consistency with the row we already have matters more, and ocd_id gates only the admin
-- dashboard, never address search.
--
-- 🔴 DC'S TWO SHADOW SENATORS ARE ALSO FLIPPED, and they are a different thing again: they hold no
-- seat in Congress at all. Leaving them 'full' would assert they vote in the Senate. Their notes say
-- plainly what they are.

DO $$
DECLARE
  c_norton  uuid := '4dbc8de1-9984-42a5-b2aa-5445bf0619b9';
  c_cdn     text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                    || 'politician_photos/';
  c_src     text := 'clerk.house.gov/xml/lists/MemberData.xml (119th Congress, published 2026-07-06), '
                    || 'checked 2026-08-12 (migration 1719, ADR 0003)';
  v_n       int;
  r         record;
BEGIN
  -- =========================================================================================
  -- 1. DC — the powers-only flip ADR 0003 anticipated
  -- =========================================================================================
  UPDATE essentials.offices SET
    voting_powers = 'non_voting',
    representation_note =
      'The District of Columbia elects a Delegate to the U.S. House of Representatives. The Delegate '
      || 'is a full member of the House in every respect except the decisive one: they may introduce '
      || 'legislation, debate, and vote in committee, but may not vote on final passage on the House '
      || 'floor. DC has no representation in the Senate. This is representation by residency — every '
      || 'resident of the District is represented by this seat.'
  WHERE id = '961cdb6e-1034-44d7-bbea-b5e82d61126a'
    AND (voting_powers IS DISTINCT FROM 'non_voting' OR representation_note IS NULL);

  UPDATE essentials.offices SET
    voting_powers = 'non_voting',
    representation_note =
      'A "shadow senator" is elected by District of Columbia voters to advocate for DC statehood and '
      || 'representation. The position is created by the District, not by the Senate: a shadow senator '
      || 'is NOT a member of the United States Senate, is not seated or sworn there, and has no vote '
      || 'of any kind in Congress.'
  WHERE id IN ('7e91aa8c-16d3-43ff-9eda-d8326f7ef489', '9569b15d-d233-49f6-89c7-221dd284e28c')
    AND (voting_powers IS DISTINCT FROM 'non_voting' OR representation_note IS NULL);

  -- =========================================================================================
  -- 2. The five territories — districts, seats, members
  -- =========================================================================================
  INSERT INTO essentials.districts (label, district_type, state, geo_id, ocd_id, mtfcc,
                                    representation_basis)
  SELECT 'Delegate District (at Large)', 'NATIONAL_LOWER', v.usps, v.geo, v.ocd, 'G5200', 'residency'
    FROM (VALUES
      ('pr', '7298', 'ocd-division/country:us/state:pr/cd:98'),
      ('vi', '7898', 'ocd-division/country:us/state:vi/cd:98'),
      ('gu', '6698', 'ocd-division/country:us/state:gu/cd:98'),
      ('as', '6098', 'ocd-division/country:us/state:as/cd:98'),
      ('mp', '6998', 'ocd-division/country:us/state:mp/cd:98')
    ) AS v(usps, geo, ocd)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.districts d
                      WHERE d.geo_id = v.geo AND d.district_type = 'NATIONAL_LOWER');

  INSERT INTO essentials.offices (district_id, title, representing_state, voting_powers,
                                  representation_note, is_appointed_position, is_vacant)
  SELECT d.id, v.title, upper(v.usps), 'non_voting', v.note, false, false
    FROM (VALUES
      ('pr', 'Resident Commissioner',
       'Puerto Rico elects a Resident Commissioner to the U.S. House of Representatives — the only '
       || 'such seat, and the only one serving a four-year term rather than two. The Resident '
       || 'Commissioner may introduce legislation, serve on and vote in committee, but may not vote on '
       || 'final passage on the House floor. Puerto Rico has no representation in the Senate, and its '
       || 'residents cannot vote for President. Every resident of Puerto Rico is represented by this '
       || 'seat.'),
      ('vi', 'Delegate, Virgin Islands',
       'The U.S. Virgin Islands elects a Delegate to the U.S. House of Representatives. The Delegate '
       || 'may introduce legislation, serve on and vote in committee, but may not vote on final '
       || 'passage on the House floor, and the territory has no representation in the Senate. Every '
       || 'resident of the Virgin Islands is represented by this seat.'),
      ('gu', 'Delegate, Guam',
       'Guam elects a Delegate to the U.S. House of Representatives. The Delegate may introduce '
       || 'legislation, serve on and vote in committee, but may not vote on final passage on the House '
       || 'floor, and the territory has no representation in the Senate. Every resident of Guam is '
       || 'represented by this seat.'),
      ('as', 'Delegate, American Samoa',
       'American Samoa elects a Delegate to the U.S. House of Representatives. The Delegate may '
       || 'introduce legislation, serve on and vote in committee, but may not vote on final passage on '
       || 'the House floor, and the territory has no representation in the Senate. American Samoa is '
       || 'also the only U.S. territory whose people are generally U.S. nationals rather than U.S. '
       || 'citizens at birth. Every resident is represented by this seat.'),
      ('mp', 'Delegate, Northern Mariana Islands',
       'The Commonwealth of the Northern Mariana Islands elects a Delegate to the U.S. House of '
       || 'Representatives. The Delegate may introduce legislation, serve on and vote in committee, '
       || 'but may not vote on final passage on the House floor, and the Commonwealth has no '
       || 'representation in the Senate. Every resident is represented by this seat.')
    ) AS v(usps, title, note)
    JOIN essentials.districts d ON lower(d.state) = v.usps AND d.district_type = 'NATIONAL_LOWER'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

  -- Members. Guarded on bioguide_id — a real federal identifier, unlike the synthetic external_id,
  -- and unlike a name: searching these surnames returns 308 rows, essentially all FEC ALLCAPS
  -- committee junk. A first+last check found none of the five (verified against Norton as a control,
  -- which the same query does find).
  INSERT INTO essentials.politicians
    (id, external_id, bioguide_id, full_name, first_name, last_name, party,
     is_active, is_incumbent, is_vacant, is_appointed, source, photo_origin_url)
  SELECT v.id, v.ext, v.bio, v.fullname, v.firstname, v.lastname, v.party,
         true, true, false, false, c_src,
         'https://bioguide.congress.gov/search/bio/' || v.bio
    FROM (VALUES
      ('2c15fc45-3e79-4061-b4b0-f1ca847e3fa4'::uuid, -9000060, 'R000600',
       'Aumua Amata Coleman Radewagen', 'Aumua Amata', 'Radewagen', 'Republican'),
      ('2871900f-ebd6-4171-8800-a0f2acb9cde0'::uuid, -9000066, 'M001219',
       'James C. Moylan', 'James', 'Moylan', 'Republican'),
      ('fe9e7931-3a5a-46a4-8e69-d2609bae9992'::uuid, -9000069, 'K000404',
       'Kimberlyn King-Hinds', 'Kimberlyn', 'King-Hinds', 'Republican'),
      ('2db199a9-f1e4-4d0f-969c-949414ead0fb'::uuid, -9000072, 'H001103',
       'Pablo José Hernández', 'Pablo', 'Hernández', 'Democratic'),
      ('2804ab49-5972-4c25-8e60-8331adbfa3c2'::uuid, -9000078, 'P000610',
       'Stacey E. Plaskett', 'Stacey', 'Plaskett', 'Democratic')
    ) AS v(id, ext, bio, fullname, firstname, lastname, party)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.bioguide_id = v.bio);

  -- Seat all five. Sworn 2025-01-03 per the Clerk; elected 2024-11-05. seat_officeholder takes one
  -- row at a time, so loop rather than trying to PERFORM it over a set.
  FOR r IN
    SELECT o.id AS office_id, p.id AS politician_id
      FROM essentials.politicians p
      JOIN essentials.districts d
        ON lower(d.state) = CASE p.bioguide_id
                              WHEN 'R000600' THEN 'as' WHEN 'M001219' THEN 'gu'
                              WHEN 'K000404' THEN 'mp' WHEN 'H001103' THEN 'pr'
                              WHEN 'P000610' THEN 'vi' END
       AND d.district_type = 'NATIONAL_LOWER'
      JOIN essentials.offices o ON o.district_id = d.id
     WHERE p.bioguide_id IN ('R000600','M001219','K000404','H001103','P000610')
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, DATE '2025-01-03', c_src, 'elected', 'day');
  END LOOP;

  -- Portraits: official Bioguide photos (public domain federal works), incl. Norton, who had none.
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT p.id, c_cdn || p.id::text || '-headshot.jpg', 'default', 'public_domain'
    FROM essentials.politicians p
   WHERE p.bioguide_id IN ('R000600','M001219','K000404','H001103','P000610','N000147')
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                      WHERE pi.politician_id = p.id AND pi.type = 'default');

  UPDATE essentials.politicians
     SET photo_origin_url = 'https://bioguide.congress.gov/search/bio/N000147'
   WHERE id = c_norton AND photo_origin_url IS NULL;

  -- =========================================================================================
  -- 3. post-verify
  -- =========================================================================================
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.district_type = 'NATIONAL_LOWER' AND lower(d.state) IN ('pr','vi','gu','as','mp','dc')
     AND o.voting_powers = 'non_voting';
  IF v_n <> 8 THEN
    RAISE EXCEPTION 'expected 8 non_voting seats (6 delegates + 2 DC shadow senators), found %', v_n;
  END IF;

  IF EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
              WHERE d.district_type = 'NATIONAL_LOWER'
                AND lower(d.state) IN ('pr','vi','gu','as','mp','dc')
                AND o.voting_powers <> 'full'
                AND (o.representation_note IS NULL OR length(o.representation_note) < 120)) THEN
    RAISE EXCEPTION 'a non-voting territory seat lacks a real explanation';
  END IF;

  -- All five new delegates are seated.
  SELECT count(*) INTO v_n
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
   WHERE p.bioguide_id IN ('R000600','M001219','K000404','H001103','P000610');
  IF v_n <> 5 THEN RAISE EXCEPTION 'expected 5 seated territory delegates, found %', v_n; END IF;

  -- 🔴 These are residency seats: each MUST have a polygon, or a resident gets no representative.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
    JOIN essentials.geofence_boundaries gp ON gp.geo_id = d.geo_id
   WHERE d.district_type = 'NATIONAL_LOWER' AND lower(d.state) IN ('pr','vi','gu','as','mp')
     AND public.ST_IsValid(gp.geometry) AND NOT public.ST_IsEmpty(gp.geometry);
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'expected 5 territory delegate districts with valid geometry, found %', v_n;
  END IF;

  -- And they stay residency-based — these are NOT membership seats.
  IF EXISTS (SELECT 1 FROM essentials.districts d
              WHERE d.district_type = 'NATIONAL_LOWER'
                AND lower(d.state) IN ('pr','vi','gu','as','mp','dc')
                AND d.representation_basis <> 'residency') THEN
    RAISE EXCEPTION 'a territory district was marked membership-basis';
  END IF;

  -- Portraits attached to the right people.
  SELECT count(*) INTO v_n
    FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
   WHERE p.bioguide_id IN ('R000600','M001219','K000404','H001103','P000610','N000147')
     AND position(p.id::text in pi.url) > 0;
  IF v_n <> 6 THEN
    RAISE EXCEPTION 'expected 6 portraits each embedding its own politician_id, found %', v_n;
  END IF;

  RAISE NOTICE 'territories: 5 delegate seats seeded + DC flipped; 8 non-voting seats explained';
END $$;
