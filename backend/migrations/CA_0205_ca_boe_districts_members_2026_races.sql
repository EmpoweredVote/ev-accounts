-- CA_0205_ca_boe_districts_members_2026_races.sql
-- California State Board of Equalization: put all four districts on their official boundaries,
-- seat the four sitting members, and seed the BOE-1, BOE-2 and BOE-4 races onto
-- 'CA 2026 Statewide General' (CA_0130 already seeded BOE-3).
--
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews, in chat, "merge + deploy + apply"). Code
--   first: PR #683 merged (6d2b876e) and live on ev-accounts-api (deploy dep-daq75u95efls738so540) BEFORE any data.
--   Dry run first as one BEGIN ... ROLLBACK (geofence insert + this file, twice): every gate passed, the second run
--   was a no-op, and prod was unchanged after. Negative controls: the loader STOPs on a districts-2/3 swap; this file
--   RAISEs without the geofences. Then the loader committed 4 X-CA-SBOE rows (guards passed again), and this file
--   applied with every gate passing; a re-run as ROLLBACK changed nothing. Verified after: offices_missing_terms
--   428 -> 427 (BOE-3 left, nothing added); check-address-reachability OK; live elections-by-address and
--   address-search return each district's race and member -- Sacramento BOE-1 / Gaines, San Francisco BOE-2 /
--   Lieber, Los Angeles BOE-3 / Vazquez, San Diego BOE-4 / Schaefer. Before the apply, Sacramento, San Francisco
--   and San Diego showed no BOE race, and no address showed any BOE member.
--
-- WHY. CA_0130 modelled BOE-3 alone, geofenced to LA County (BOE-3 IS LA County), and seated
-- nobody, so its office sat in essentials.offices_missing_terms: invisible. The other three
-- districts did not exist. None of the four sitting members was in essentials.politicians, and
-- Sally J. Lieber is on the BOE-2 ballot as the incumbent. BOE-1 and BOE-4 are NOT unions of
-- whole counties -- the SoS BOE page lists San Bernardino County under both (99% of its area is
-- in BOE-1, 1% in BOE-4) -- so each district needs its own polygon.
--
-- 1. BOUNDARIES (loaded by scripts/CA_0205-ca-boe-geofences.mts, not here -- 1.4 MB of geometry).
--    The 2021 Citizens Redistricting Commission map, from the State GIS service
--    services.gis.ca.gov/arcgis/rest/services/Government/CaliforniaDistricts/MapServer/3, as
--    geofence_boundaries geo_id '06-sboe-d1'..'06-sboe-d4', mtfcc 'X-CA-SBOE'. The loader's positive
--    controls: BOE-3 reproduces our LA County geofence (symdiff 0.00005) and BOE-2 the union of its
--    19 counties (0.00010); no overlaps; seven city anchors land in their published district. Its
--    negative control (districts 2 and 3 swapped) STOPs.
--    This migration refuses to run unless those four rows exist.
--
-- 2. DISTRICTS. BOE-1, 2, 4 are new STATE_BOARD districts on those geofences, same shape as
--    CA_0130's. BOE-3's district is REPOINTED from LA County ('06037', mtfcc '') to '06-sboe-d3' /
--    'X-CA-SBOE', so all four resolve the same way. Its race keeps working: the elections path
--    matches geo_id plus mtfcc, and the new polygon equals LA County.
--
-- 3. SEATED MEMBERS. Four new politicians rows, is_incumbent = true, party NULL (antipartisan),
--    each seated with essentials.seat_officeholder from the start of unbroken service:
--      BOE-1  Ted Gaines          2019-01-07   (re-elected 2022)
--      BOE-2  Sally J. Lieber     2023-01-02
--      BOE-3  Antonio Vazquez     2019-01-07   (re-elected 2022; "Tony Vazquez" kept as an alternate name)
--      BOE-4  Mike Schaefer       2019-01-07   (re-elected 2022)
--    Sources: BOE "List of Members 1879 - Present" (boe.ca.gov/members/Board-Members-Listing.pdf,
--    rev. 2023-01-30) lists the 2019-2022 term as Gaines / Cohen / Vazquez / Schaefer and the 2023-
--    term as Gaines / Lieber / Vazquez / Schaefer; the days are from the Wikipedia BOE membership table
--    ("assumed office January 7, 2019" / "January 2, 2023"), and both are the first Monday after
--    January 1, when a BOE term begins. BOE meeting documents from June 2026 show all four still
--    serving. Gaines, Vazquez and Schaefer are term-limited in 2026, so BOE-1, 3 and 4 are open.
--
-- 4. RACES. Three races, six candidates, from the SoS Official Certified List of Candidates,
--    8/27/2026 ("Board of Equalization Member District N"):
--      BOE-1  Nelson Esparza · Shannon Grove                 [open]
--      BOE-2  Sally J. Lieber (inc) · John Pimentel
--      BOE-4  Tom Umberg · Denis Bilodeau                    [open]
--    Lieber links to her new politicians row as the current holder. Everyone else is
--    politician_id NULL, as CA_0133 does for challengers -- including Grove and Umberg, who hold
--    State Senate seats today.
--
-- ORDER. Code first, then data. The officeholder address lookup maps geofence MTFCC to
--   district_type, and before this PR nothing mapped to STATE_BOARD; check-address-reachability.mjs
--   (which runs on master against LIVE prod) would report every seated BOE member unreachable. So:
--   (1) merge the PR that adds (X-CA-SBOE -> STATE_BOARD) to geoIdGuard.ts and districtQueries.ts,
--   and let it deploy; (2) run the geofence loader; (3) apply this file.
--
-- IDEMPOTENCY: districts on (district_type, state, label); offices on (district, title);
-- politicians on id; seat_officeholder is idempotent; races on (election_id, position_name);
-- candidates on (race_id, lower(full_name)); the BOE-3 repoint only touches the old geo_id.

BEGIN;

-- ─── 0. Precondition: the loader has run ────────────────────────────────────────────────
DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.geofence_boundaries
       WHERE mtfcc='X-CA-SBOE' AND geo_id IN ('06-sboe-d1','06-sboe-d2','06-sboe-d3','06-sboe-d4')) <> 4 THEN
    RAISE EXCEPTION 'the four X-CA-SBOE geofences are missing -- run scripts/CA_0205-ca-boe-geofences.mts first';
  END IF;
END $$;

-- ─── 1. Districts ───────────────────────────────────────────────────────────────────────
UPDATE essentials.districts
   SET geo_id='06-sboe-d3', mtfcc='X-CA-SBOE'
 WHERE district_type='STATE_BOARD' AND state='CA' AND label='California Board of Equalization District 3'
   AND geo_id='06037';

INSERT INTO essentials.districts (district_type, state, geo_id, label, mtfcc, district_id, ocd_id)
SELECT 'STATE_BOARD', 'CA', v.geo, v.label, 'X-CA-SBOE', '', v.ocd
FROM (VALUES
  ('06-sboe-d1', 'California Board of Equalization District 1', 'ocd-division/country:us/state:ca/sboe:1'),
  ('06-sboe-d2', 'California Board of Equalization District 2', 'ocd-division/country:us/state:ca/sboe:2'),
  ('06-sboe-d4', 'California Board of Equalization District 4', 'ocd-division/country:us/state:ca/sboe:4')
) AS v(geo, label, ocd)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.district_type='STATE_BOARD' AND d.state='CA' AND d.label=v.label
);

-- ─── 2. Offices (BOE-3's exists from CA_0130) ───────────────────────────────────────────
INSERT INTO essentials.offices
  (title, district_id, partisan_type, representing_state, seats, is_appointed_position, is_vacant, faces_retention_vote)
SELECT 'Board of Equalization District ' || v.n, d.id, NULL, 'CA', 1, false, false, false
FROM (VALUES ('1'), ('2'), ('4')) AS v(n)
JOIN essentials.districts d
  ON d.district_type='STATE_BOARD' AND d.state='CA' AND d.label='California Board of Equalization District ' || v.n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title='Board of Equalization District ' || v.n
);

-- ─── 3. The four sitting members ────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, first_name, last_name, full_name, party, is_active, is_incumbent, is_vacant,
                                    is_appointed, data_source, alternate_names)
SELECT v.id, v.f, v.l, v.n, NULL, true, true, false, false,
       'https://boe.ca.gov/members/Board-Members-Listing.pdf', v.alt
FROM (VALUES
  ('fc97cf9f-3695-4c2d-9219-9a9ff6378db4'::uuid, 'Ted',     'Gaines',   'Ted Gaines',      '{}'::text[]),
  ('049f5243-99f7-4a83-a2e5-fd8a471f1c73'::uuid, 'Sally',   'Lieber',   'Sally J. Lieber', ARRAY['Sally Lieber']::text[]),
  ('1788af2c-c571-449b-b8c1-9cc137ef4562'::uuid, 'Antonio', 'Vazquez',  'Antonio Vazquez', ARRAY['Tony Vazquez']::text[]),
  ('1aed88b9-6079-4f9c-a472-c6f89cf5db01'::uuid, 'Mike',    'Schaefer', 'Mike Schaefer',   '{}'::text[])
) AS v(id, f, l, n, alt)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id=v.id);

SELECT essentials.seat_officeholder(
         o.id, v.pid, v.ts,
         'CA_0205: BOE member since ' || v.ts::text || ' (unbroken). BOE List of Members 1879-Present '
           || '(boe.ca.gov/members/Board-Members-Listing.pdf, rev. 2023-01-30): ' || v.terms || '; day from the '
           || 'Wikipedia BOE membership table, the first Monday after January 1. Read 2026-09-23.',
         'elected', 'day')
FROM (VALUES
  ('1', 'fc97cf9f-3695-4c2d-9219-9a9ff6378db4'::uuid, DATE '2019-01-07', 'First District, terms 2019-2022 and 2023-'),
  ('2', '049f5243-99f7-4a83-a2e5-fd8a471f1c73'::uuid, DATE '2023-01-02', 'Second District, term 2023-'),
  ('3', '1788af2c-c571-449b-b8c1-9cc137ef4562'::uuid, DATE '2019-01-07', 'Third District, terms 2019-2022 and 2023-'),
  ('4', '1aed88b9-6079-4f9c-a472-c6f89cf5db01'::uuid, DATE '2019-01-07', 'Fourth District, terms 2019-2022 and 2023-')
) AS v(n, pid, ts, terms)
JOIN essentials.districts d
  ON d.district_type='STATE_BOARD' AND d.state='CA' AND d.label='California Board of Equalization District ' || v.n
JOIN essentials.offices o ON o.district_id=d.id AND o.title='Board of Equalization District ' || v.n;

-- ─── 4. Races (BOE-3's exists from CA_0130) ─────────────────────────────────────────────
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT '728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid, o.id, v.pos, NULL, 1
FROM (VALUES ('1', 'State Board of Equalization, 1st District'),
             ('2', 'State Board of Equalization, 2nd District'),
             ('4', 'State Board of Equalization, 4th District')) AS v(n, pos)
JOIN essentials.districts d
  ON d.district_type='STATE_BOARD' AND d.state='CA' AND d.label='California Board of Equalization District ' || v.n
JOIN essentials.offices o ON o.district_id=d.id AND o.title='Board of Equalization District ' || v.n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
  WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=v.pos
);

CREATE TEMP TABLE boe_cand_seed
  (position_name text, full_name text, first_name text, last_name text, is_incumbent boolean, politician_id uuid) ON COMMIT DROP;
INSERT INTO boe_cand_seed VALUES
  ('State Board of Equalization, 1st District', 'Nelson Esparza',  'Nelson', 'Esparza',  false, NULL::uuid),
  ('State Board of Equalization, 1st District', 'Shannon Grove',   'Shannon', 'Grove',   false, NULL::uuid),
  ('State Board of Equalization, 2nd District', 'Sally J. Lieber', 'Sally',  'Lieber',   true,  '049f5243-99f7-4a83-a2e5-fd8a471f1c73'::uuid),
  ('State Board of Equalization, 2nd District', 'John Pimentel',   'John',   'Pimentel', false, NULL::uuid),
  ('State Board of Equalization, 4th District', 'Tom Umberg',      'Tom',    'Umberg',   false, NULL::uuid),
  ('State Board of Equalization, 4th District', 'Denis Bilodeau',  'Denis',  'Bilodeau', false, NULL::uuid);

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, cs.politician_id, cs.full_name, cs.first_name, cs.last_name, cs.is_incumbent, 'active',
       'California Secretary of State Official Certified List of Candidates, 8/27/2026 (elections.cdn.sos.ca.gov/statewide-elections/2026-general/cert-list-candidates.pdf), Board of Equalization Member District N. Read 2026-09-23 (CA_0205).'
FROM boe_cand_seed cs
JOIN essentials.races r
  ON r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND r.position_name=cs.position_name
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id=r.id AND lower(rc.full_name)=lower(cs.full_name)
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad text;
BEGIN
  -- (1) four BOE districts, one office each, each on its own X-CA-SBOE geofence
  SELECT count(*) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id=d.id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id=d.geo_id AND gb.mtfcc=d.mtfcc
   WHERE d.district_type='STATE_BOARD' AND d.state='CA' AND d.mtfcc='X-CA-SBOE'
     AND d.geo_id = '06-sboe-d' || substring(d.label from '([0-9])$')
     AND o.title = 'Board of Equalization District ' || substring(d.label from '([0-9])$');
  IF v_n <> 4 THEN RAISE EXCEPTION 'BOE districts/offices on their geofences: expected 4, got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.districts d
   WHERE d.district_type='STATE_BOARD' AND d.state='CA';
  IF v_n <> 4 THEN RAISE EXCEPTION 'CA STATE_BOARD districts: expected 4, got %', v_n; END IF;

  -- (2) each office is held by its member, from the sourced day, and none is invisible any more
  SELECT string_agg(d.label, ', ') INTO v_bad
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id=d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
    LEFT JOIN essentials.office_terms t ON t.office_id=o.id AND t.politician_id=och.politician_id AND t.term_end IS NULL
   WHERE d.district_type='STATE_BOARD' AND d.state='CA'
     AND (och.politician_id IS DISTINCT FROM CASE substring(d.label from '([0-9])$')
                                               WHEN '1' THEN 'fc97cf9f-3695-4c2d-9219-9a9ff6378db4'::uuid
                                               WHEN '2' THEN '049f5243-99f7-4a83-a2e5-fd8a471f1c73'::uuid
                                               WHEN '3' THEN '1788af2c-c571-449b-b8c1-9cc137ef4562'::uuid
                                               WHEN '4' THEN '1aed88b9-6079-4f9c-a472-c6f89cf5db01'::uuid END
          OR t.term_start IS DISTINCT FROM CASE substring(d.label from '([0-9])$')
                                               WHEN '2' THEN DATE '2023-01-02' ELSE DATE '2019-01-07' END
          OR t.start_precision IS DISTINCT FROM 'day');
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'BOE seat(s) with the wrong holder or start: %', v_bad; END IF;
  IF EXISTS (SELECT 1 FROM essentials.offices_missing_terms m
               JOIN essentials.offices o ON o.id=m.office_id JOIN essentials.districts d ON d.id=o.district_id
              WHERE d.district_type='STATE_BOARD' AND d.state='CA') THEN
    RAISE EXCEPTION 'a BOE office is still in offices_missing_terms';
  END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE id IN ('fc97cf9f-3695-4c2d-9219-9a9ff6378db4','049f5243-99f7-4a83-a2e5-fd8a471f1c73',
                '1788af2c-c571-449b-b8c1-9cc137ef4562','1aed88b9-6079-4f9c-a472-c6f89cf5db01')
     AND is_active AND is_incumbent AND party IS NULL;
  IF v_n <> 4 THEN RAISE EXCEPTION 'BOE members active + incumbent + party NULL: expected 4, got %', v_n; END IF;

  -- (3) a point in each district reaches its member through the officeholder mapping
  --     (the SQL twin of (gp.mtfcc = 'X-CA-SBOE' AND d.district_type = 'STATE_BOARD'))
  SELECT string_agg(p.city || '->' || COALESCE(x.n, 'none'), ', ') INTO v_bad
    FROM (VALUES ('Sacramento','1',-121.4944,38.5816), ('San Francisco','2',-122.4194,37.7749),
                 ('Los Angeles','3',-118.2437,34.0522), ('San Diego','4',-117.1611,32.7157)) AS p(city, expect, lon, lat)
    LEFT JOIN LATERAL (
      SELECT string_agg(substring(d.label from '([0-9])$'), ',') AS n
        FROM essentials.geofence_boundaries gb
        JOIN essentials.districts d ON d.geo_id=gb.geo_id AND gb.mtfcc='X-CA-SBOE' AND d.district_type='STATE_BOARD'
        JOIN essentials.offices o ON o.district_id=d.id
        JOIN essentials.office_current_holder och ON och.office_id=o.id AND och.politician_id IS NOT NULL
       WHERE public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(p.lon, p.lat), 4326))
    ) x ON true
   WHERE x.n IS DISTINCT FROM p.expect;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'BOE points not reaching their member: %', v_bad; END IF;

  -- (4) the general carries all four BOE races, each on its own office, 8 candidates
  SELECT count(*) INTO v_n FROM essentials.races r
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid
     AND d.district_type='STATE_BOARD' AND d.state='CA' AND r.primary_party IS NULL AND r.seats=1
     AND r.position_name LIKE 'State Board of Equalization, ' || substring(d.label from '([0-9])$') || '__ District';
  IF v_n <> 4 THEN RAISE EXCEPTION 'BOE races on their offices: expected 4, got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND d.district_type='STATE_BOARD' AND d.state='CA';
  IF v_n <> 8 THEN RAISE EXCEPTION 'BOE candidates: expected 8, got %', v_n; END IF;

  -- (5) only Lieber is incumbent, linked to BOE-2's current holder; nobody else is linked
  SELECT count(*) INTO v_n FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id
   WHERE r.election_id='728d0074-8a8d-49e3-a68c-78ccdd15434f'::uuid AND d.district_type='STATE_BOARD' AND d.state='CA'
     AND (rc.is_incumbent OR rc.politician_id IS NOT NULL);
  IF v_n <> 1 THEN RAISE EXCEPTION 'BOE candidates linked or incumbent: expected 1 (Lieber), got %', v_n; END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
                   JOIN essentials.office_current_holder och ON och.office_id=r.office_id AND och.politician_id=rc.politician_id
                  WHERE r.position_name='State Board of Equalization, 2nd District' AND rc.is_incumbent
                    AND rc.full_name='Sally J. Lieber') THEN
    RAISE EXCEPTION 'Lieber is not linked as the BOE-2 current holder';
  END IF;

  -- (6) BOE-3's race still resolves for an LA point through the repointed district
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                   JOIN essentials.districts d ON d.geo_id=gb.geo_id AND d.mtfcc=gb.mtfcc
                   JOIN essentials.offices o ON o.district_id=d.id
                   JOIN essentials.races r ON r.office_id=o.id
                  WHERE r.position_name='State Board of Equalization, 3rd District'
                    AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(-118.2437, 34.0522), 4326))) THEN
    RAISE EXCEPTION 'BOE-3 race no longer resolves for a Los Angeles point';
  END IF;
END $$;

COMMIT;
