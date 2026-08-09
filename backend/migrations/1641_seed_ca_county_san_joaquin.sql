-- 1641_seed_ca_county_san_joaquin.sql
--
-- CA county wave: San Joaquin County. 5 countywide elected officials, 800,965 residents.
-- Wave total: 12 counties, 60 seats, 20.88M residents.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- sjgov.org is NOT bot-walled -- plain fetches work, so every holder below was read off the
-- department's own page, one at a time, on 2026-08-09:
--   Assessor-Recorder-County Clerk  /department/assessor  ("Steve J. Bestolarides")
--   County Auditor-Controller       /department/aud       ("Jeffery M. Woltkamp, CPA")
--   District Attorney               /department/da        ("Ron Freitas", 42nd DA; July 2026 news)
--   Sheriff                         sjsheriff.org         ("Sheriff Patrick Withrow")
--   Treasurer-Tax Collector         /department/ttc       ("Phonxay Keokham, CPA")
--
-- 🔴 THE ACFR TRICK DOES NOT WORK HERE. San Joaquin publishes audited financial statements
-- prepared by CLA, not a full ACFR: there is no introductory section, so no "Listing of Principal
-- Officials" and no directory of county officials (contrast Kern 1638 and Ventura 1639). The
-- county-authoritative substitute is the REGISTRAR OF VOTERS: the certified Statement of Votes
-- Cast for 2026-06-02 names the countywide contests exactly, and its qualified-candidate list
-- carries each incumbent's ballot designation.
--
-- Cross-check of three of the five, from a second county document: the June 2026 candidate list
-- (CFMR009, printed 2026-05-04) shows Bestolarides designated "San Joaquin County Assessor-
-- Recorder-County Clerk", Woltkamp "San Joaquin County Auditor-Controller", and Keokham
-- "San Joaquin County Treasurer-Tax Collector" -- each paired with the office this file seats them
-- in, with no row shift. Recording that agreement because Fresno's did NOT agree (migration 1633).
--
-- TITLES for the first, second and fifth are the SOV's contest names. District Attorney and
-- Sheriff take their department's own name, because those two offices were not on any 2026 ballot:
--
-- 🔴🔴 THE WAVE'S BLANKET ASSUMPTION IS FALSE FOR THIS COUNTY. Every prior migration in this wave
-- notes "all countywide seats were on the 2026-06-02 ballot; winners take office January 2027".
-- San Joaquin runs TWO cycles. The 2026 SOV's table of contents lists Assessor-Recorder-County
-- Clerk, County Auditor-Controller and Treasurer-Tax Collector -- and NO District Attorney and NO
-- Sheriff. That is not an omission by a single-candidate cancellation either: the SOV's own
-- "Resolution to Appoint Candidates in Lieu of Election" (R-26-46, adopted 2026-04-28) covers only
-- two Board of Education trustee areas. So the DA and Sheriff terms simply do not expire in
-- January 2027. Ballotpedia puts the DA's term end at 2029-01-08, which would mean a one-time
-- extension moving those two offices to the presidential cycle; the MECHANISM is not confirmed
-- against a county document and is not asserted here. What IS county-sourced: they were not up
-- in 2026. Re-check the other three after January 2027; leave these two alone until 2028.
--
-- ── TERM STARTS (occupancy, not current term) ─────────────────────────────────────────────────
--   Bestolarides  2015-08-25  day    APPOINTED by the Board to complete Kenneth Blakemore's term
--                                    after Blakemore retired. Source is a primary STATE document:
--                                    CA State Board of Equalization Letter To Assessors
--                                    No. 2015/048, 2015-11-06, "NEW SAN JOAQUIN COUNTY ASSESSOR"
--                                    (boe.ca.gov/proptaxes/pdf/lta15048.pdf), read as a PDF. He
--                                    was then elected in 2018 and 2022 -- occupancy runs from the
--                                    appointment, not from either election.
--   Withrow       2019-01-07  day    His own office: "Sheriff Withrow was elected Sheriff on
--                                    June 5th, 2018, and was sworn into office on January 7th,
--                                    2019" (sjsheriff.org/sheriffs-of-san-joaquin-county).
--   Keokham       2018-01-01  year   Elected 2018-06-05 as the county's 18th Treasurer-Tax
--                                    Collector (his county bio). But he was ALREADY certifying
--                                    the county's treasury balance over his own name and
--                                    letterhead on the 2018-07-31 and 2018-08-31 monthly
--                                    portfolio reports -- five months before the January the
--                                    election calendar implies. Same shape as Ventura's Burgh
--                                    (migration 1639): elected in June to an office already
--                                    vacant, so occupancy starts that summer. No document names
--                                    the day, so YEAR precision with the corpus' 01-01
--                                    placeholder. The stored day is a placeholder, not a claim.
--   Freitas       2023-01-01  month  Elected 2022-06-07 outright; sworn in early January 2023.
--   Woltkamp      2023-01-01  month  Elected 2022-06-07 outright; assumed office January 2023.
--
-- 🔴 FREITAS AND WOLTKAMP ARE MONTH, NOT DAY, ON PURPOSE. Both are widely reported as taking
-- office 2023-01-02, and the county's own press-release URL for Freitas is dated 2023/01/03 --
-- but that press release is no longer served (the path now redirects to the DA home page), so no
-- primary document could be read for the day. Ventura's rule applies: a repeated date stays
-- unsourced until a primary carries it, and a day is never promoted by analogy with a peer.
--
-- external_id from the reserved county band -(62000000 + county FIPS * 1000 + seq) => -62077001..5.
-- Pre-flight: 0 external_id collisions. Surname sweep over Bestolarides/Woltkamp/Freitas/Withrow/
-- Keokham found exactly one unrelated person -- "Adam Withrow" (external_id -66000022, no office)
-- -- a different first name, so a new row is created and nothing is deduped into.
--
-- Idempotent. Party left NULL -- these offices are nonpartisan.

BEGIN;

CREATE TEMP TABLE _seed (
  title text, ext_id bigint,
  full_name text, first_name text, last_name text, mid text,
  term_start date, precision text, how_started text
) ON COMMIT DROP;

INSERT INTO _seed VALUES
  ('Assessor-Recorder-County Clerk', -62077001,'Steve J. Bestolarides','Steve','Bestolarides','J','2015-08-25','day','appointed'),
  ('County Auditor-Controller',      -62077002,'Jeffery M. Woltkamp','Jeffery','Woltkamp','M','2023-01-01','month','elected'),
  ('District Attorney',              -62077003,'Ron Freitas','Ron','Freitas',NULL,'2023-01-01','month','elected'),
  ('Sheriff',                        -62077004,'Patrick Withrow','Patrick','Withrow',NULL,'2019-01-07','day','elected'),
  ('Treasurer-Tax Collector',        -62077005,'Phonxay Keokham','Phonxay','Keokham',NULL,'2018-01-01','year','elected');

-- 🔴 RENUMBER REPAIR. This file was written, dry-run and APPLIED as 1640, then renumbered when
-- another session pushed 1640_seed_tarrant_county_full_ballot.sql to origin/master mid-flight.
-- The number is only a filename label to a human, but it is also embedded in `source` text that
-- was already written to prod, so repoint those rows. Guarded and idempotent; a no-op on a fresh
-- database. This is the third drift CLAUDE.md warns about when renumbering.
UPDATE essentials.politicians
   SET source = replace(source, 'migration 1640 — San Joaquin', 'migration 1641 — San Joaquin')
 WHERE source LIKE 'migration 1640 — San Joaquin%';

UPDATE essentials.office_terms
   SET source = replace(source, 'migration 1640 — San Joaquin', 'migration 1641 — San Joaquin')
 WHERE source LIKE 'migration 1640 — San Joaquin%';

-- Refuse to run if any external_id already belongs to somebody else (see migration 1631).
DO $$
DECLARE v_bad text;
BEGIN
  SELECT string_agg(p.external_id::text || ' is already ' || p.full_name || ' (wanted ' || s.full_name || ')', '; ')
    INTO v_bad FROM _seed s JOIN essentials.politicians p ON p.external_id = s.ext_id
   WHERE p.full_name IS DISTINCT FROM s.full_name;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'external_id collision -- refusing to seed: %', v_bad;
  END IF;
END $$;

INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT 'San Joaquin County, California, US', 'County', 'CA', '06077'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.geo_id='06077' AND g.type='County');

-- Scoped by district_type: geo_id is not unique and is not always a FIPS.
UPDATE essentials.districts d
   SET government_id = g.id
  FROM essentials.governments g
 WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06077'
   AND g.geo_id='06077' AND g.type='County'
   AND d.government_id IS DISTINCT FROM g.id;

-- chambers.slug is GENERATED ALWAYS from name_formal -- do not insert it.
INSERT INTO essentials.chambers (name, name_formal, government_id, official_count, policy_engagement_level)
SELECT 'Countywide Elected Officials', 'San Joaquin County Countywide Elected Officials', g.id,
       (SELECT count(*) FROM _seed), 'full'
  FROM essentials.governments g
 WHERE g.geo_id='06077' AND g.type='County'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers ch
                    WHERE ch.name_formal='San Joaquin County Countywide Elected Officials');

INSERT INTO essentials.politicians
       (external_id, full_name, first_name, last_name, middle_initial, source, is_incumbent, is_active)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.mid,
       'migration 1641 — San Joaquin County department pages + Registrar of Voters 2026-06-02 Statement of Votes Cast, read 2026-08-09',
       true, true
  FROM _seed s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = s.ext_id);

INSERT INTO essentials.offices (chamber_id, district_id, title, seats, representing_state, is_vacant)
SELECT ch.id, d.id, s.title, 1, 'CA', false
  FROM _seed s
  JOIN essentials.chambers ch ON ch.name_formal='San Joaquin County Countywide Elected Officials'
  JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06077'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id=d.id AND o.title=s.title);

DO $$
DECLARE r record; v_office_id uuid; v_pid uuid;
BEGIN
  FOR r IN SELECT * FROM _seed LOOP
    SELECT o.id INTO v_office_id
      FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
     WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06077' AND o.title=r.title;
    IF v_office_id IS NULL THEN RAISE EXCEPTION 'No office for %', r.title; END IF;

    SELECT p.id INTO v_pid FROM essentials.politicians p WHERE p.external_id=r.ext_id;
    IF v_pid IS NULL THEN RAISE EXCEPTION 'No politician for %', r.full_name; END IF;

    PERFORM essentials.seat_officeholder(
      v_office_id, v_pid, r.term_start,
      'migration 1641 — San Joaquin County department pages + Registrar of Voters 2026-06-02 Statement of Votes Cast, read 2026-08-09',
      r.how_started, r.precision);
  END LOOP;
END $$;

DO $$
DECLARE v_offices integer; v_seated integer; v_wrong text; v_gov integer;
BEGIN
  SELECT count(*) INTO v_offices
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06077';
  IF v_offices <> 5 THEN RAISE EXCEPTION 'Expected 5 San Joaquin offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id=o.district_id
    JOIN essentials.office_current_holder och ON och.office_id=o.id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06077'
     AND och.politician_id IS NOT NULL;
  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated holders, found %', v_seated; END IF;

  SELECT string_agg(x.msg, '; ') INTO v_wrong FROM (
    SELECT o.title || ': seated ' || p.full_name || ', expected ' || s.full_name AS msg
      FROM _seed s
      JOIN essentials.districts d ON d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06077'
      JOIN essentials.offices o ON o.district_id=d.id AND o.title=s.title
      JOIN essentials.office_current_holder och ON och.office_id=o.id
      JOIN essentials.politicians p ON p.id=och.politician_id
     WHERE p.full_name IS DISTINCT FROM s.full_name) x;
  IF v_wrong IS NOT NULL THEN RAISE EXCEPTION 'WRONG PERSON SEATED: %', v_wrong; END IF;

  SELECT count(*) INTO v_gov
    FROM essentials.districts d JOIN essentials.governments g ON g.id=d.government_id
   WHERE d.district_type='COUNTY' AND lower(d.state)='ca' AND d.geo_id='06077'
     AND g.geo_id='06077' AND g.type='County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'San Joaquin district not linked to its government row (%)', v_gov; END IF;
END $$;

COMMIT;
