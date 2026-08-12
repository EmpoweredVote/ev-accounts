-- 1718_maine_tribal_seats.sql
--
-- First implementation of ADR 0003 (docs/adr/0003-non-residency-representation.md): the two new
-- representation axes, and Maine's three reserved tribal House seats as their first instance.
--
-- ⚠️ TWO ROLES. The DDL block needs `postgres` (via the Supabase MCP) — `ev_api` has no CREATE on
-- `essentials`, so running this whole file over DATABASE_URL fails at the first ALTER. The DML block
-- below runs fine as `ev_api`. Applied in that order, separately.
--
-- WHAT MAINE ACTUALLY HAS. The Maine House seats three non-voting tribal representatives, one each
-- for the Penobscot Nation, the Passamaquoddy Tribe, and the Houlton Band of Maliseet Indians. They
-- may introduce bills, sit on committees and vote IN committee, but not on the floor. Naming here is
-- the legislature's own: `legislature.maine.gov/house/house/MemberProfiles/Details/1507` renders
-- title "Tribal Representative" and district "Non-Voting Tribal Member - Passamaquoddy Tribe";
-- Details/3140 is the same shape for the Houlton Band. Both checked 2026-08-12.
--
-- Filled: Aaron M. Dana (Passamaquoddy) and Brian Reynolds (Houlton Band of Maliseet).
-- Vacant: the Penobscot Nation seat. The Wabanaki nations withdrew their representatives in 2015;
-- the Maliseet seat sat empty seven years before being reclaimed in May 2025, and Penobscot has not
-- returned. That vacancy is the whole reason ADR 0003 chose to model these seats rather than omit
-- them: a nation declining to seat someone is a political act, and a model with no seat cannot record
-- the choice.
--
-- 🔴 GEO_ID IS NULL ON ALL THREE, DELIBERATELY. These constituencies are tribal MEMBERSHIP, not
-- residency, and we cannot know enrollment from a street address. A NULL geo_id cannot join
-- geofence_boundaries, so ST_Covers can never assign one of these seats to an address — which is the
-- binding rule in ADR 0003, enforced here by the absence of data rather than by hoping a future query
-- remembers. Census AIANNH geometry may later be attached for DISCOVERY, never for assignment.
--
-- 🔴 PARTY IS NULL, not 'Independent'. Open States normalizes these members to Independent, but these
-- seats are not filled through a partisan ballot at all, and CLAUDE.md's antipartisan rule says party
-- belongs to a ballot a voter requests. NULL says "no party applies to this seat"; 'Independent' would
-- assert a choice neither member made.
--
-- 🔴 TERM_END IS NULL ON BOTH, AND THAT IS A KNOWN RISK. Reporting indicates Dana serves through
-- September 2026 and Reynolds through October 2026, but neither official profile carries a term end
-- and we will not invent a date — so both are open-ended for now, which is exactly the shape that let
-- TX SD-22 render a departed member as sitting. A dated re-check todo accompanies this migration.
-- Start dates are recorded at the precision the sources actually support: Dana's sources CONFLICT on
-- the month (Wikipedia says he assumed office 2022-12-07, the Maine Monitor says October 2022), so his
-- start is 'year' precision; Reynolds' agree on May 2025, so his is 'month'. `how_started` is
-- 'unknown' for both — the tribes' own selection processes differ and we have not verified them.

-- ============================================================================================
-- DDL — run as postgres (Supabase MCP)
-- ============================================================================================

ALTER TABLE essentials.districts
  ADD COLUMN IF NOT EXISTS representation_basis text NOT NULL DEFAULT 'residency';

ALTER TABLE essentials.offices
  ADD COLUMN IF NOT EXISTS voting_powers text NOT NULL DEFAULT 'full',
  ADD COLUMN IF NOT EXISTS representation_note text;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'districts_representation_basis_check') THEN
    ALTER TABLE essentials.districts
      ADD CONSTRAINT districts_representation_basis_check
      CHECK (representation_basis IN ('residency', 'membership'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'offices_voting_powers_check') THEN
    ALTER TABLE essentials.offices
      ADD CONSTRAINT offices_voting_powers_check
      CHECK (voting_powers IN ('full', 'committee_only', 'non_voting'));
  END IF;

  -- "Broadly understood" as a constraint, not a hope: a seat with unusual powers must carry its
  -- explanation or it cannot exist. NOTE THE LIMIT — a CHECK cannot reference another table, so this
  -- enforces the POWERS half only. The membership half (basis <> 'residency' also requires a note) is
  -- enforced in the post-verify below and must be enforced by the read path; it is not a table
  -- constraint, and pretending otherwise would be worse than saying so.
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'offices_representation_note_required') THEN
    ALTER TABLE essentials.offices
      ADD CONSTRAINT offices_representation_note_required
      CHECK (voting_powers = 'full' OR representation_note IS NOT NULL);
  END IF;
END $$;

COMMENT ON COLUMN essentials.districts.representation_basis IS
  'What defines this constituency: ''residency'' (default; a place, resolved by polygon) or '
  '''membership'' (a polity one belongs to, e.g. an enrolled tribal member). MEMBERSHIP DISTRICTS '
  'MUST NEVER DRIVE ADDRESS ASSIGNMENT — enrollment is not inferable from an address. Any geometry on '
  'such a district is discovery-only. See docs/adr/0003-non-residency-representation.md.';

COMMENT ON COLUMN essentials.offices.voting_powers IS
  '''full'' (default), ''committee_only'' (may vote in committee but not on the floor, e.g. Maine '
  'tribal representatives), or ''non_voting'' (e.g. the PR Resident Commissioner and the territorial '
  'and DC delegates). Orthogonal to districts.representation_basis: PR differs from a full member on '
  'POWERS only, a Maine tribal representative differs on BOTH. ADR 0003.';

COMMENT ON COLUMN essentials.offices.representation_note IS
  'Voter-facing explanation of who this seat represents and what its holder can do. REQUIRED whenever '
  'voting_powers <> ''full'' (enforced) or representation_basis <> ''residency'' (enforced in '
  'migration post-verify and the read path). The read path MUST NOT render such a seat without it: an '
  'unexplained seat misleads in both directions. ADR 0003.';

-- ============================================================================================
-- DML — runs as ev_api
-- ============================================================================================

DO $$
DECLARE
  c_chamber   uuid := '5820521b-cd21-4bf1-9296-fd848230d542';  -- ME House, from State House District 29
  c_dana      uuid := 'ed5db0ed-0341-4036-836e-de3788aa3098';
  c_reynolds  uuid := '28304298-2b10-4d22-abd0-31cf69849270';
  c_cdn       text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                      || 'politician_photos/';
  c_src       text := 'legislature.maine.gov tribal member profiles, checked 2026-08-12 '
                      || '(migration 1718, ADR 0003)';
  v_d_pen     uuid;
  v_d_pas     uuid;
  v_d_mal     uuid;
  v_o_pen     uuid;
  v_o_pas     uuid;
  v_o_mal     uuid;
  v_n         int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE id = c_chamber) THEN
    RAISE EXCEPTION 'ME House chamber % not found', c_chamber;
  END IF;

  -- ---- districts: the three tribal constituencies ------------------------------------------
  INSERT INTO essentials.districts (label, district_type, state, representation_basis,
                                    has_unknown_boundaries)
  SELECT v.label, 'STATE_LOWER', 'me', 'membership', true
    FROM (VALUES
      ('Non-Voting Tribal Member - Penobscot Nation'),
      ('Non-Voting Tribal Member - Passamaquoddy Tribe'),
      ('Non-Voting Tribal Member - Houlton Band of Maliseet Indians')
    ) AS v(label)
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.districts d
      WHERE d.label = v.label AND lower(d.state) = 'me' AND d.district_type = 'STATE_LOWER');

  SELECT id INTO v_d_pen FROM essentials.districts
   WHERE label = 'Non-Voting Tribal Member - Penobscot Nation' AND lower(state) = 'me';
  SELECT id INTO v_d_pas FROM essentials.districts
   WHERE label = 'Non-Voting Tribal Member - Passamaquoddy Tribe' AND lower(state) = 'me';
  SELECT id INTO v_d_mal FROM essentials.districts
   WHERE label = 'Non-Voting Tribal Member - Houlton Band of Maliseet Indians' AND lower(state) = 'me';
  IF v_d_pen IS NULL OR v_d_pas IS NULL OR v_d_mal IS NULL THEN
    RAISE EXCEPTION 'tribal districts did not materialize (pen=%, pas=%, mal=%)',
                    v_d_pen, v_d_pas, v_d_mal;
  END IF;

  -- ---- offices: the three seats -------------------------------------------------------------
  INSERT INTO essentials.offices (district_id, chamber_id, title, representing_state,
                                  voting_powers, representation_note, is_appointed_position,
                                  is_vacant)
  SELECT v.did, c_chamber, 'Tribal Representative', 'ME', 'committee_only', v.note, false, v.vacant
    FROM (VALUES
      (v_d_pen,
       'A seat reserved for the Penobscot Nation in the Maine House of Representatives. Its holder '
       || 'is chosen by the Nation, not elected by residents of a geographic district, and may '
       || 'introduce bills, serve on committees and vote in committee, but not on the House floor. '
       || 'The Nation is not currently sending a representative — the Wabanaki nations withdrew '
       || 'their representatives in 2015 and this seat has not been reclaimed. This does not replace '
       || 'the district representative for anyone; it is additional representation.',
       true),
      (v_d_pas,
       'A seat reserved for the Passamaquoddy Tribe in the Maine House of Representatives. Its '
       || 'holder is chosen by the Tribe, not elected by residents of a geographic district, and may '
       || 'introduce bills, serve on committees and vote in committee, but not on the House floor. '
       || 'This does not replace the district representative for anyone; it is additional '
       || 'representation for tribal members.',
       false),
      (v_d_mal,
       'A seat reserved for the Houlton Band of Maliseet Indians in the Maine House of '
       || 'Representatives. Its holder is chosen by the Band, not elected by residents of a '
       || 'geographic district, and may introduce bills, serve on committees and vote in committee, '
       || 'but not on the House floor. This does not replace the district representative for anyone; '
       || 'it is additional representation for tribal members.',
       false)
    ) AS v(did, note, vacant)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = v.did);

  SELECT id INTO v_o_pen FROM essentials.offices WHERE district_id = v_d_pen;
  SELECT id INTO v_o_pas FROM essentials.offices WHERE district_id = v_d_pas;
  SELECT id INTO v_o_mal FROM essentials.offices WHERE district_id = v_d_mal;

  -- ---- the two members ----------------------------------------------------------------------
  -- Fixed ids so the portrait filenames, already uploaded, are known here. -232901/-232902 sit well
  -- clear of Maine's district-keyed band (-232001..-232151), which has no room for a non-numbered seat.
  INSERT INTO essentials.politicians
    (id, external_id, full_name, first_name, last_name, party, is_active, is_incumbent,
     is_vacant, is_appointed, office_id, source, photo_origin_url)
  -- Alias columns are fullname/firstname/lastname: FULL, FIRST and LAST are reserved words and a
  -- VALUES alias list using them is a syntax error.
  SELECT v.id, v.ext, v.fullname, v.firstname, v.lastname, NULL, true, true, false, false,
         v.office, c_src, v.origin
    FROM (VALUES
      (c_dana, -232901, 'Aaron M. Dana', 'Aaron', 'Dana', v_o_pas,
       'https://legislature.maine.gov/house/house/MemberProfiles/Details/1507'),
      (c_reynolds, -232902, 'Brian Reynolds', 'Brian', 'Reynolds', v_o_mal,
       'https://legislature.maine.gov/house/house/MemberProfiles/Details/3140')
    ) AS v(id, ext, fullname, firstname, lastname, office, origin)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.ext);

  -- ---- seat them ----------------------------------------------------------------------------
  PERFORM essentials.seat_officeholder(
    v_o_pas, c_dana, DATE '2022-01-01',
    c_src || '; sources conflict on the month he took the seat (2022-12-07 per Wikipedia, '
          || 'October 2022 per the Maine Monitor), so year precision',
    'unknown', 'year');

  PERFORM essentials.seat_officeholder(
    v_o_mal, c_reynolds, DATE '2025-05-01',
    c_src || '; Houlton Band reclaimed the seat in May 2025 after seven years vacant, so month '
          || 'precision',
    'unknown', 'month');

  -- ---- portraits (official Maine House profile photos, state works) -------------------------
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT v.pid, c_cdn || v.pid::text || '-headshot.jpg', 'default', 'public_domain'
    FROM (VALUES (c_dana), (c_reynolds)) AS v(pid)
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                      WHERE pi.politician_id = v.pid AND pi.type = 'default');

  -- ---- post-verify --------------------------------------------------------------------------
  -- Three seats, all committee_only, all explained.
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.representation_basis = 'membership';
  IF v_n <> 3 THEN RAISE EXCEPTION 'expected 3 ME membership seats, found %', v_n; END IF;

  IF EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
              WHERE d.representation_basis = 'membership'
                AND (o.voting_powers <> 'committee_only'
                     OR o.representation_note IS NULL
                     OR length(o.representation_note) < 80)) THEN
    RAISE EXCEPTION 'a membership seat is missing committee_only powers or a real explanation';
  END IF;

  -- The membership half of the note rule, which no CHECK can express across tables.
  IF EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
              WHERE d.representation_basis <> 'residency' AND o.representation_note IS NULL) THEN
    RAISE EXCEPTION 'a non-residency seat exists with no representation_note';
  END IF;

  -- 🔴 The binding rule: no membership district may carry geometry that could reach the address path.
  IF EXISTS (SELECT 1 FROM essentials.districts d
              WHERE d.representation_basis = 'membership' AND d.geo_id IS NOT NULL) THEN
    RAISE EXCEPTION 'a membership district has a geo_id — it could be assigned from an address';
  END IF;

  -- Occupancy: Dana and Reynolds seated, Penobscot genuinely empty and flagged.
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder
                  WHERE office_id = v_o_pas AND politician_id = c_dana) THEN
    RAISE EXCEPTION 'Passamaquoddy seat does not resolve to Dana';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder
                  WHERE office_id = v_o_mal AND politician_id = c_reynolds) THEN
    RAISE EXCEPTION 'Maliseet seat does not resolve to Reynolds';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder
                  WHERE office_id = v_o_pen AND politician_id IS NULL) THEN
    RAISE EXCEPTION 'Penobscot seat should resolve to nobody';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.offices WHERE id = v_o_pen AND is_vacant = true) THEN
    RAISE EXCEPTION 'Penobscot seat is not flagged vacant';
  END IF;
  -- No invented vacancy span for a date we do not know.
  SELECT count(*) INTO v_n FROM essentials.office_terms WHERE office_id = v_o_pen;
  IF v_n <> 0 THEN RAISE EXCEPTION 'Penobscot seat should have no term rows, has %', v_n; END IF;

  -- Party stays NULL on both: these seats are not filled through a partisan ballot.
  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE id IN (c_dana, c_reynolds) AND party IS NOT NULL) THEN
    RAISE EXCEPTION 'party should be NULL on a non-partisan tribal seat';
  END IF;

  -- Portraits attached to the right people.
  SELECT count(*) INTO v_n FROM essentials.politician_images pi
   WHERE pi.politician_id IN (c_dana, c_reynolds) AND pi.type = 'default'
     AND position(pi.politician_id::text in pi.url) > 0;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'expected 2 portraits each embedding its own politician_id, found %', v_n;
  END IF;

  -- Chamber totals: 151 districts + 3 tribal = 154 offices, 153 filled. This is the number
  -- roster-diff.mjs compares against Open States' 153 Maine House members.
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_LOWER';
  IF v_n <> 154 THEN RAISE EXCEPTION 'expected 154 ME House offices, found %', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_LOWER'
     AND och.politician_id IS NOT NULL;
  IF v_n <> 153 THEN RAISE EXCEPTION 'expected 153 seated ME House members, found %', v_n; END IF;

  -- Existing residency seats untouched: every one of the 151 numbered districts still 'residency'.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE lower(d.state) = 'me' AND d.district_type = 'STATE_LOWER'
     AND d.representation_basis = 'residency';
  IF v_n <> 151 THEN RAISE EXCEPTION 'expected 151 residency ME House districts, found %', v_n; END IF;

  RAISE NOTICE 'Maine tribal seats: 3 created, Dana + Reynolds seated, Penobscot vacant by choice';
END $$;
