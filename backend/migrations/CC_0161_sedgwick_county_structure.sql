-- CC_0161 — KS-4 structure: the Sedgwick County government, three chambers, five commission
-- districts and ten offices.
--
-- THE OFFICE INVENTORY IS THE STATUTE'S, AND IT HAD TO BE.
--   KSA 19-101a(a)(6): a county "shall be subject to all acts of the legislature concerning
--   elections, election commissioners and officers and their duties as such officers and the
--   election of county officers."
-- ▶ A Kansas county CANNOT add or remove an elected county office by home rule. So the statute is
--   not merely the best source for the inventory — it is the only source that can be complete.
--
-- TEN OFFICES:
--   5  County Commissioner, districts 1-5        KSA 19-202   4y, staggered
--   1  County Clerk                              KSA 19-301   4y
--   1  County Treasurer                          KSA 19-501   4y
--   1  Register of Deeds                         KSA 19-1201  4y
--   1  Sheriff                                   KSA 19-801a  4y
--   1  District Attorney, 18th Judicial District KSA 22a-101  4y
--
-- 🔴 THE COUNTY'S OWN PAGE COULD NOT HAVE GIVEN THIS. /government/elected-and-appointed-officials/
-- lists Appraiser, Clerk, District Attorney, Election Commissioner, Register of Deeds, Sheriff and
-- Treasurer in ONE list with nothing marking which are elected. Two of those seven are appointed:
-- the Appraiser by the board (19-430) and the Election Commissioner by the SECRETARY OF STATE, in
-- counties over 125,000 (19-3419). The election office's own register is wider still — 744 rows
-- covering everything on a Sedgwick ballot, including statewide Court of Appeals judges and the
-- State Treasurer, plus 26 township clerks and 25 township treasurers.
--
-- Each exclusion has a statute behind it, not an org chart:
--   County Attorney   ABOLISHED in judicial districts 3, 10, 18 and 29 by KSA 22a-101(b)
--   County Appraiser  appointed by the board, KSA 19-430
--   County Surveyor   KSA 19-1401 REPEALED; 19-1401a makes it appointed
--   District Coroner  appointed by the board from medical-society nominees, KSA 22a-226
--   County Auditor    appointed by the district court, and only in counties of 40,000-60,000, 19-601
--   Election Commr.   appointed by the Secretary of State, KSA 19-3419
--
-- 🔴🔴 THE DISTRICT ATTORNEY IS NOT A COUNTY OFFICER, AND THE STATUTE SAYS SO IN WORDS.
-- KSA 4-219: "The county of Sedgwick shall constitute the 18th judicial district." KSA 22a-101(a)
-- declares the district attorney "an executive officer of the judicial district ... and in no event
-- shall said district attorney be deemed an officer of any county."
-- ▶ So the DA gets its OWN chamber, not a line in Countywide Elected Officials.
-- ⚠ Los Angeles County — the model for the rest of this migration — puts its DA in Countywide
-- Elected Officials. That is correct for CALIFORNIA, where the DA is a county officer. Copying it
-- here would be copying a fact rather than a pattern. The geography is still the county, because
-- the 18th judicial district is coterminous with it, so the DA hangs on the same county district row.
--
-- ⚠ THE COUNTY CLERK IS NOT THE ELECTION OFFICER HERE. In most Kansas counties the clerk runs
-- elections; in counties over 125,000 the Secretary of State appoints an Election Commissioner
-- instead (19-3419). The office description says so, because a voter reading "County Clerk" would
-- otherwise reasonably expect to contact them about a ballot.
--
-- GEOMETRY. Only the five commission districts need custom polygons: mtfcc X0071, loaded by
-- scripts/load-sedgwick-bocc-boundaries.mjs, whose vintage gate proves they are balanced on 2020
-- census counts to 0.16% total deviation and account for Sedgwick County's 2020 population EXACTLY.
-- The four countywide offices and the DA hang on TIGER county 20173 / G4020, already in production.
--
-- 🔴 THIS MIGRATION REFUSES TO RUN IF THOSE FIVE BOUNDARIES ARE ABSENT. An office on a district with
-- no polygon is invisible to every address search and NOTHING ERRORS — the one failure mode CI
-- cannot catch. The guard is first, before any write.
--
-- ⚠ THE COUNTY DISTRICT ROW ALREADY EXISTS and is REUSED, not duplicated. The KS-1 geography load
-- created `Sedgwick County` (COUNTY / G4020 / 20173 / state 'ks') with no government_id and no
-- offices. This migration attaches it to the new government rather than inserting a second row on
-- the same geometry.
--
-- STATE CASE: 'ks' lowercase, matching CC_0156's districts, CC_0159's Wichita rows and the existing
-- county row. ⚠ Kansas rows are MIXED in production — older federal and state-exec rows are 'KS'.
-- Reads must keep using lower(d.state); this migration does not touch those rows.
--
-- Idempotent: every insert is guarded by NOT EXISTS and the one UPDATE is guarded, so a second run
-- reports INSERT 0 / UPDATE 0 and the post-verify still passes.

BEGIN;

-- ── Guard: the geometry must exist before any office hangs off it ──────────────────────────────
DO $$
DECLARE
  v_bocc   int;
  v_county int;
  v_crow   int;
BEGIN
  SELECT count(*) INTO v_bocc
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0071' AND geo_id LIKE 'sedgwick-ks-commission-district-%';
  IF v_bocc <> 5 THEN
    RAISE EXCEPTION 'CC_0161: expected 5 X0071 commission boundaries, found %. Run '
                    'scripts/load-sedgwick-bocc-boundaries.mjs first — an office on a district '
                    'with no polygon is unreachable by any address and nothing errors.', v_bocc;
  END IF;

  SELECT count(*) INTO v_county
    FROM essentials.geofence_boundaries WHERE mtfcc = 'G4020' AND geo_id = '20173';
  IF v_county <> 1 THEN
    RAISE EXCEPTION 'CC_0161: TIGER county 20173 (Sedgwick County, G4020) is absent — the four '
                    'countywide offices and the district attorney have nothing to hang on';
  END IF;

  SELECT count(*) INTO v_crow
    FROM essentials.districts
   WHERE geo_id = '20173' AND mtfcc = 'G4020' AND district_type = 'COUNTY' AND lower(state) = 'ks';
  IF v_crow <> 1 THEN
    RAISE EXCEPTION 'CC_0161: expected exactly 1 Sedgwick County district row to reuse, found %. '
                    'Refusing to guess which one the countywide offices belong on.', v_crow;
  END IF;
END $$;

-- ── The government ─────────────────────────────────────────────────────────────────────────────
INSERT INTO essentials.governments (id, name, type, state, geo_id)
SELECT gen_random_uuid(), 'Sedgwick County, Kansas, US', 'County', 'KS', '20173'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Sedgwick County, Kansas, US');

-- ── The three chambers ─────────────────────────────────────────────────────────────────────────
-- ⚠ `slug` is a GENERATED column — btrim(regexp_replace(... lower(name_formal) ...)) — so it must
-- not appear in the insert list. The expected slugs fall out of name_formal:
--   sedgwick-county-board-of-county-commissioners
--   sedgwick-county-countywide-elected-officials
--   eighteenth-judicial-district-of-kansas
-- and the post-verify asserts all three, so a name_formal edit that changes a slug fails here.
INSERT INTO essentials.chambers
  (id, government_id, name, name_formal, official_count, term_length, election_frequency,
   staggered_term, policy_engagement_level, remarks)
SELECT gen_random_uuid(), g.id, v.name, v.name_formal, v.official_count, v.term_length,
       v.election_frequency, v.staggered_term, 'full', v.remarks
  FROM essentials.governments g
  CROSS JOIN (VALUES
    ('Board of County Commissioners',
     'Sedgwick County Board of County Commissioners',
     5, '4 years', '2 years', true,
     'Five members, one elected from and resident in each commissioner district (KSA 19-202(a),(b)). '
     'Terms are staggered so that no more than a simple majority is elected at any general election '
     '(19-202(c)): districts 1, 4 and 5 run in midterm years and districts 2 and 3 in presidential '
     'years. Terms run four years from the second Monday of January after the election (19-202(d)).'),
    ('Countywide Elected Officials',
     'Sedgwick County Countywide Elected Officials',
     4, '4 years', '4 years', false,
     'County Clerk (KSA 19-301), County Treasurer (19-501), Register of Deeds (19-1201) and Sheriff '
     '(19-801a), each elected countywide for four years in presidential-election years. '
     'ALL BUT THE TREASURER take office on the second Monday of January (25-313(a)); the TREASURER '
     'takes office on the SECOND TUESDAY IN OCTOBER of the year FOLLOWING the election (19-501).'),
    ('Eighteenth Judicial District',
     'Eighteenth Judicial District of Kansas',
     1, '4 years', '4 years', false,
     'KSA 4-219 makes Sedgwick County alone the 18th judicial district. The district attorney is '
     'held here rather than among the countywide officials because KSA 22a-101(a) declares the '
     'office "an executive officer of the judicial district" and says that "in no event shall said '
     'district attorney be deemed an officer of any county". 22a-101(b) abolished the office of '
     'county attorney in this district. The district also elects 30 district judges by division and '
     'one district magistrate judge; those seats are NOT yet seated.')
  ) AS v(name, name_formal, official_count, term_length, election_frequency, staggered_term, remarks)
 WHERE g.name = 'Sedgwick County, Kansas, US'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers c
                    WHERE c.government_id = g.id AND c.name = v.name);

-- ── The five commission districts ──────────────────────────────────────────────────────────────
INSERT INTO essentials.districts
  (id, label, district_type, state, mtfcc, geo_id, num_officials, government_id)
SELECT gen_random_uuid(),
       'Sedgwick County Commission District ' || n,
       'COUNTY', 'ks', 'X0071',
       'sedgwick-ks-commission-district-' || n,
       1,
       (SELECT id FROM essentials.governments WHERE name = 'Sedgwick County, Kansas, US')
  FROM generate_series(1, 5) AS n
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts d
    WHERE d.geo_id = 'sedgwick-ks-commission-district-' || n AND d.district_type = 'COUNTY');

-- ── Reuse the existing county district row for the countywide offices and the DA ───────────────
UPDATE essentials.districts d
   SET government_id = (SELECT id FROM essentials.governments WHERE name = 'Sedgwick County, Kansas, US'),
       num_officials = 5
 WHERE d.geo_id = '20173' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY' AND lower(d.state) = 'ks'
   AND d.government_id IS DISTINCT FROM
       (SELECT id FROM essentials.governments WHERE name = 'Sedgwick County, Kansas, US');

-- ── The five commission offices ────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, seats, representing_state, description)
SELECT gen_random_uuid(), c.id, d.id, 'County Commissioner, District ' || n, 1, 'KS',
       'One of the five members of the Board of County Commissioners, elected by and resident in '
       'District ' || n || '. The board "may transact all county business and perform all powers of '
       'local legislation and administration it deems appropriate", subject to the limits in KSA '
       '19-101a — among them that it may not affect the courts, and may not legislate on the '
       'election of county officers. Four-year term from the second Monday of January (KSA 19-202(d)).'
  FROM generate_series(1, 5) AS n
  JOIN essentials.districts d
    ON d.geo_id = 'sedgwick-ks-commission-district-' || n AND d.district_type = 'COUNTY'
  JOIN essentials.governments g ON g.name = 'Sedgwick County, Kansas, US'
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Board of County Commissioners'
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'County Commissioner, District ' || n);

-- ── The four countywide offices ────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, seats, representing_state, description)
SELECT gen_random_uuid(), c.id, d.id, v.title, 1, 'KS', v.description
  FROM essentials.districts d
  JOIN essentials.governments g ON g.name = 'Sedgwick County, Kansas, US'
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Countywide Elected Officials'
  CROSS JOIN (VALUES
    ('County Clerk',
     'Official secretary to the Board of County Commissioners: the clerk records and produces the '
     'written minutes of every commission meeting, and maintains the county''s tax rolls and budget '
     'records. Elected countywide for four years (KSA 19-301). ⚠ NOT the county election officer — '
     'Sedgwick County is over 125,000 people, so the Secretary of State appoints a separate Election '
     'Commissioner to run elections here (KSA 19-3419).'),
    ('County Treasurer',
     'Collects property taxes and administers motor-vehicle titling and registration for the county. '
     'Elected countywide for four years (KSA 19-501). ⚠ Unlike every other county officer, the '
     'treasurer''s term begins on the SECOND TUESDAY IN OCTOBER of the year FOLLOWING the election, '
     'not the second Monday of January — KSA 19-501 is the exception that KSA 25-313(a) allows for.'),
    ('Register of Deeds',
     'Records all real-estate transactions in the county — deeds, mortgages, oil and gas leases and '
     'platted additions to every municipality in the county — and files financing statements and '
     'security agreements on personal property. Elected countywide for four years (KSA 19-1201).'),
    ('Sheriff',
     'The county''s chief law-enforcement officer. KSA 19-813 makes it the sheriff''s duty "to keep '
     'and preserve the peace" in the county, to "quiet and suppress all affrays, riots and unlawful '
     'assemblies and insurrections", to serve process in civil and criminal cases, and to apprehend '
     'persons for felony or breach of the peace. Elected countywide for four years (KSA 19-801a).')
  ) AS v(title, description)
 WHERE d.geo_id = '20173' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY' AND lower(d.state) = 'ks'
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id AND o.title = v.title);

-- ── The district attorney ──────────────────────────────────────────────────────────────────────
INSERT INTO essentials.offices
  (id, chamber_id, district_id, title, seats, representing_state, description)
SELECT gen_random_uuid(), c.id, d.id, 'District Attorney, 18th Judicial District', 1, 'KS',
       'Prosecutes crime for the 18th judicial district, which KSA 4-219 makes coterminous with '
       'Sedgwick County. KSA 22a-104(a) puts on the district attorney the duty "to appear in the '
       'several courts of the judicial district ... and to prosecute or defend, on behalf of the '
       'people therein, all matters arising under the laws of this state", exercising district-wide '
       'the powers a county attorney holds elsewhere. Elected for four years, term beginning the '
       'second Monday in January (KSA 22a-101(a)). ⚠ This is NOT a county office: 22a-101(a) says '
       '"in no event shall said district attorney be deemed an officer of any county", and 22a-101(b) '
       'abolished the office of county attorney in this district.'
  FROM essentials.districts d
  JOIN essentials.governments g ON g.name = 'Sedgwick County, Kansas, US'
  JOIN essentials.chambers c ON c.government_id = g.id AND c.name = 'Eighteenth Judicial District'
 WHERE d.geo_id = '20173' AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY' AND lower(d.state) = 'ks'
   AND NOT EXISTS (
     SELECT 1 FROM essentials.offices o
      WHERE o.district_id = d.id AND o.title = 'District Attorney, 18th Judicial District');

-- ── Post-verify. Asserts the END STATE, so a re-run that inserts nothing still passes. ─────────
DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_offices int; v_nogeom int; v_dupes int; v_slug int;
  v_bocc int; v_wide int; v_da int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = 'Sedgwick County, Kansas, US';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'CC_0161: expected 1 Sedgwick government row, found %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US';
  IF v_ch <> 3 THEN RAISE EXCEPTION 'CC_0161: expected 3 chambers, found %', v_ch; END IF;

  -- `slug` is generated from name_formal, so this asserts the three slugs a reader would cite.
  SELECT count(*) INTO v_slug FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US'
     AND c.slug IN ('sedgwick-county-board-of-county-commissioners',
                    'sedgwick-county-countywide-elected-officials',
                    'eighteenth-judicial-district-of-kansas');
  IF v_slug <> 3 THEN
    RAISE EXCEPTION 'CC_0161: % of 3 chamber slugs match. slug is generated from name_formal, so a '
                    'name_formal edit silently changes the slug a reader cites.', v_slug;
  END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'COUNTY' AND geo_id LIKE 'sedgwick-ks-commission-district-%';
  IF v_dist <> 5 THEN RAISE EXCEPTION 'CC_0161: expected 5 commission districts, found %', v_dist; END IF;

  SELECT count(*) INTO v_offices
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US';
  IF v_offices <> 10 THEN RAISE EXCEPTION 'CC_0161: expected 10 Sedgwick offices, found %', v_offices; END IF;

  SELECT count(*) INTO v_bocc FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US' AND c.name = 'Board of County Commissioners';
  SELECT count(*) INTO v_wide FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US' AND c.name = 'Countywide Elected Officials';
  SELECT count(*) INTO v_da FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Sedgwick County, Kansas, US' AND c.name = 'Eighteenth Judicial District';
  IF v_bocc <> 5 OR v_wide <> 4 OR v_da <> 1 THEN
    RAISE EXCEPTION 'CC_0161: chamber split is %/%/% , expected 5 commissioners / 4 countywide / 1 DA',
                    v_bocc, v_wide, v_da;
  END IF;

  -- 🔴 The failure mode CI cannot catch: an office whose district has no polygon.
  SELECT count(*) INTO v_nogeom
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'Sedgwick County, Kansas, US'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'CC_0161: % Sedgwick office(s) sit on a district with no matching boundary', v_nogeom;
  END IF;

  -- No duplicate office titles inside the government.
  SELECT count(*) INTO v_dupes FROM (
    SELECT o.title FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
     WHERE g.name = 'Sedgwick County, Kansas, US'
     GROUP BY o.title HAVING count(*) > 1) t;
  IF v_dupes <> 0 THEN RAISE EXCEPTION 'CC_0161: % duplicated office title(s)', v_dupes; END IF;

  -- ⚠ The traps this migration exists to avoid: no office may be an APPOINTED administrator, and
  -- there must be no County Attorney — KSA 22a-101(b) abolished it in this judicial district.
  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.chambers c ON c.id = o.chamber_id
               JOIN essentials.governments g ON g.id = c.government_id
              WHERE g.name = 'Sedgwick County, Kansas, US'
                AND (o.title ILIKE '%county attorney%' OR o.title ILIKE '%appraiser%'
                     OR o.title ILIKE '%election commissioner%' OR o.title ILIKE '%coroner%'
                     OR o.title ILIKE '%surveyor%' OR o.title ILIKE '%county manager%'
                     OR o.title ILIKE '%auditor%')) THEN
    RAISE EXCEPTION 'CC_0161: an appointed or abolished office was created. The county''s own '
                    '"Elected and Appointed Officials" page lists both kinds in one list; only the '
                    'statute separates them.';
  END IF;

  RAISE NOTICE 'CC_0161 OK — Sedgwick County: 1 government, 3 chambers, 5 commission districts + the '
               'reused county row, 10 offices, every one on a district with geometry.';
END $$;

COMMIT;
