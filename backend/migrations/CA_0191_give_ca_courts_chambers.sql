-- CA_0191_give_ca_courts_chambers.sql
--
-- Give California's three modelled courts a chamber each, so the essentials frontend files their judges
-- under the right tier and section. Follow-up to CA_0189 (which linked the same courts to geography).
--
-- WHY
-- ---
-- All 504 California JUDICIAL offices (LA Superior Court 473, Second District Court of Appeal 24, Supreme
-- Court 7) carry chamber_id NULL, so the address-search response has chamber_name, chamber_name_formal,
-- government_name and government_body_name all empty. The essentials frontend decides both the tier and the
-- section of a judge from those fields (src/lib/groupHierarchy.js):
--   * getTier: JUDICIAL + chamber_name containing 'supreme' / 'appeals' / 'appellate' / 'tax' -> State,
--     anything else -> Local.
--   * getAccordionKey: JUDICIAL -> government_body_name || chamber_name_formal || 'Courts'.
-- With every field empty, every California judge -- Supreme Court included -- lands in ONE section,
-- "Local › Courts › Judges". Measured 2026-09-23 against the live API and the frontend's own grouping code:
-- 200 S Spring St, Los Angeles -> 423 cards in that one section (LASC 408 + 2DCA 8 + Supreme Court 7);
-- Ventura -> 15 (2DCA + Supreme Court) under "Local"; San Francisco -> the 7 Supreme Court seats under "Local".
--
-- WHAT THIS DOES (decisions: operator Chris Andrews, 2026-09-23)
-- -------------------------------------------------------------
--   1. ONE CHAMBER PER COURT, three rows with fixed ids -- the Wisconsin / Texas / SCOTUS shape (Dane County
--      Circuit Court holds 17 offices, Wisconsin Supreme Court 7), not Indiana's one-chamber-per-office.
--        Supreme Court           under 'State of California'      e0f33bda  record_only
--        2nd District Court of Appeal under 'State of California' e0f33bda  record_only
--        LA Superior Court       under LA County 'County' row     4236875b  full
--   2. Set offices.chamber_id on all 504 offices, held or not. The 81 stale per-judge slots CA_0189 left
--      unlinked get the chamber too: it is a fact about the court, and it changes nothing a resident sees
--      (they have no geography, so no address reaches them).
--
-- NAMES -- two frontend rules decide them, not taste
-- --------------------------------------------------
--   * The TIER reads `name` (chamber_name). So `name` must carry 'supreme' for the Supreme Court and
--     'appellate' for the Court of Appeal ("Court of Appeal" alone contains neither 'appeals' nor
--     'appellate', and would fall to Local), and must carry none of supreme/appeals/appellate/tax for the
--     Superior Court.
--   * The SECTION HEADING reads `name_formal`, and groupIntoHierarchy CUTS A HEADING AT ITS FIRST COMMA
--     (`title: key.includes(',') ? stripSuffix(key) : key`, meant for "X County, State, US" government
--     names). So the official names cannot be headings: "Court of Appeal, Second Appellate District" would
--     render as "Court of Appeal", and "Superior Court of California, County of Los Angeles" as "Superior
--     Court of California". name_formal is therefore comma-free; the official 2DCA name is kept in `name`,
--     which is never used as a heading.
--   classifyCategory reads name_formal || name for the same keywords; name_formal carries them as well, so
--   the two readers agree.
--
-- GOVERNMENTS
-- -----------
--   * Supreme Court and Court of Appeal -> 'State of California' (e0f33bda, type STATE, geo '06'), which
--     already holds the Legislature, the Governor and the other statewide chambers. Indiana's two state
--     courts sit under 'State of Indiana' the same way.
--   * LA Superior Court -> 4236875b, NOT 841f214e. LA County has two government rows, both named
--     "Los Angeles County, California, US" on geo 06037:
--       841f214e type LOCAL  -- Board of Supervisors (5 offices) + 3 empty chambers. The ONLY California
--                               county row of type LOCAL.
--       4236875b type County -- the countywide COUNTY district 06037 (districts.government_id points here)
--                               and the countywide elected officers (DA, Sheriff, Assessor).
--     The Superior Court is countywide on 06037, and 'County' is the type all 25 other California county
--     rows use. (Address search shows the same thing either way -- judges are keyed by court name -- but
--     browse-by-government derives district_type from governments.type, see SIDE EFFECTS.)
--
-- policy_engagement_level -- the rule already in the data
-- -------------------------------------------------------
--   Retention courts are record_only (Indiana Supreme Court and Court of Appeals, SCOTUS); courts whose
--   judges run in contested elections are full (Indiana circuit courts, Wisconsin, Texas county courts).
--   California's justices stand for retention; LA Superior Court judges run in contested nonpartisan
--   elections. Today no screen distinguishes full from record_only; only 'none' changes the profile, to
--   "This is an administrative office", which is wrong for a judge -- so no court gets 'none'.
--
-- NO government_bodies ROW, ON PURPOSE
-- ------------------------------------
--   DISTRICT_JOINS joins government_bodies on (d.state, d.geo_id, body_key = name_formal). A body row is NOT
--   needed for the heading: without one, getAccordionKey falls back to chamber_name_formal. Without one the
--   section reads "<court> › Judges" with the court's website on the "Judges" sub-group; with one, the
--   sub-group label would repeat the court name. It would also add a join keyed on the name_formal STRING,
--   which a later rename breaks silently. (Indiana's state courts and SCOTUS do have body rows; this is a
--   deliberate difference.)
--
-- SIDE EFFECTS -- one expected, measured ABSENT in the dry run; reported, not changed
-- ------------------------------------------------------------------------------------
--   essentialsBrowseService.getPoliticiansByGovernmentList (POST /essentials/browse/by-government-list, and
--   the county bucket of GET /essentials/location-search/resolve) joins chambers by government_id and
--   matches governments.geo_id, so a chamber under LA County would put the LA Superior Court judges into the
--   LA County browse (06037), and the two state courts into any read for '06'. MEASURED: no change (06037
--   8 rows before and after, 06 132 rows, 0 judges either way), because that query also requires
--   `p.is_vacant = false` and all 422 held judges carry politicians.is_vacant NULL (CA_0183 did not set it).
--   ⚠ If anyone backfills is_vacant = false, those judges WILL appear there: the 408 LASC judges as
--   district_type COUNTY (that path derives district_type from governments.type; classifyBucket still files
--   them as judges by title) -- the Monroe County, Indiana shape -- and the state justices as district_type
--   '' (the path gives a STATE government's rows ''), which getTier files as Local. The NULL is not
--   specific to judges: 2,760 seated, active politicians carry it (measured 2026-09-23).
--
-- NOT CHANGED
-- -----------
--   No district, geography, office_terms, politician or race row. offices.is_appointed_position is true on
--   all 504 (the Judges tab defaults to the "Appointed" filter), faces_retention_vote stays false.
--   The LA section still holds 408 cards in one grid with no paging (essentials Results.jsx renders the
--   whole sub-group) -- a frontend question for the operator, not a data one.
--
-- No migration runner exists; this file records SQL applied by hand. No DELETE.
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews). Dry run x2 (identical output, rollback
--   confirmed reverted), repeated right before the apply; a double run in one transaction changed 0 rows the
--   second time; re-run inside BEGIN/ROLLBACK after the apply: INSERT 0, UPDATE 0, every gate passed.
--   check:reachability on prod after the apply: OK (UNREACHABLE 24/24, BAD_GEOMETRY 4/4, DEAD_GEOGRAPHY 17/17).
--   Live POST /api/essentials/candidates/search, grouped with the essentials frontend's own code
--   (groupIntoHierarchy + classifyBucket + matchesAppointedFilter, main f91cb9c4), Judges tab:
--     200 S Spring St, Los Angeles -> Local › Los Angeles County Superior Court 408
--                                     State › Supreme Court of California 7 (1 vacant)
--                                     State › California Court of Appeal (Second Appellate District) 8
--     501 Poli St, Ventura         -> State › Supreme Court of California 7, State › ... (Second Appellate District) 8
--     SF City Hall                 -> State › Supreme Court of California 7
--   Response sizes unchanged (489 / 77 / 80 rows): the change moves judges between sections, it adds none.
--
-- ROLLBACK:
--   UPDATE essentials.offices SET chamber_id = NULL
--    WHERE chamber_id IN ('441b1e14-9d4f-486e-b64e-89e923568178', '80fbe262-1000-4265-bb79-e2481098dc70',
--                         'f4be7fd4-6ce3-42b5-a8d7-a3d6553d87eb');
--   DELETE FROM essentials.chambers
--    WHERE id IN ('441b1e14-9d4f-486e-b64e-89e923568178', '80fbe262-1000-4265-bb79-e2481098dc70',
--                 'f4be7fd4-6ce3-42b5-a8d7-a3d6553d87eb');
-- IDEMPOTENT: the chambers insert on fixed ids (ON CONFLICT DO NOTHING, then the post-verify checks every
-- value), and the offices UPDATE is guarded on chamber_id IS NULL. A re-run changes nothing and every gate
-- still passes.

BEGIN;

-- The court -> chamber map this file writes. One place, read by every step and both gates.
CREATE TEMP TABLE ca0191_court ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('SUP',  'California Supreme Court %'::text, 7,
   '441b1e14-9d4f-486e-b64e-89e923568178'::uuid, 'e0f33bda-bfb5-4dd0-9816-576e6ce35fac'::uuid,
   'Supreme Court'::text, 'Supreme Court of California'::text,
   'record_only'::essentials.policy_engagement_level, 'https://supreme.courts.ca.gov/'::text),
  ('2DCA', 'CA 2nd DCA Division %', 24,
   '80fbe262-1000-4265-bb79-e2481098dc70', 'e0f33bda-bfb5-4dd0-9816-576e6ce35fac',
   'Court of Appeal, Second Appellate District', 'California Court of Appeal (Second Appellate District)',
   'record_only', 'https://appellate.courts.ca.gov/district-courts/2dca'),
  ('LASC', 'LA County Superior Court %', 473,
   'f4be7fd4-6ce3-42b5-a8d7-a3d6553d87eb', '4236875b-3909-4ae4-ae91-41ae21c07a45',
   'Superior Court', 'Los Angeles County Superior Court',
   'full', 'https://www.lacourt.ca.gov/')
) AS v(court, label_like, n_offices, chamber_id, government_id, name, name_formal, engagement, website_url);

-- Pre-image of the chambers this file must NOT touch, for the post-verify.
CREATE TEMP TABLE ca0191_other_chambers ON COMMIT DROP AS
SELECT c.id, c.government_id, c.name, c.name_formal, c.policy_engagement_level,
       (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.id) AS n_offices
  FROM essentials.chambers c
 WHERE c.government_id IN (SELECT government_id FROM ca0191_court)
   AND c.id NOT IN (SELECT chamber_id FROM ca0191_court);

-- ---------------------------------------------------------------------------
-- 0. Pre-flight. Refuse to run against a state this file was not written for.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_lasc int; n_coa int; n_sup int; n_other int; n_foreign_chamber int;
  n_gov int; n_dup_name int; n_id_clash int; n_body int;
BEGIN
  -- 0a. The 504 offices, one per district, split exactly as CA_0183/CA_0189 left them. A third label shape
  --     aborts instead of being skipped.
  SELECT count(*) FILTER (WHERE d.label LIKE 'LA County Superior Court %'),
         count(*) FILTER (WHERE d.label LIKE 'CA 2nd DCA Division %'),
         count(*) FILTER (WHERE d.label LIKE 'California Supreme Court %'),
         count(*) FILTER (WHERE d.label NOT LIKE 'LA County Superior Court %'
                            AND d.label NOT LIKE 'CA 2nd DCA Division %'
                            AND d.label NOT LIKE 'California Supreme Court %'),
         -- pre-image: every office is still chamberless or already on its target chamber (re-run)
         count(*) FILTER (WHERE o.chamber_id IS NOT NULL
                            AND o.chamber_id IS DISTINCT FROM (SELECT cc.chamber_id FROM ca0191_court cc
                                                                WHERE d.label LIKE cc.label_like))
    INTO n_lasc, n_coa, n_sup, n_other, n_foreign_chamber
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE d.state = 'CA' AND d.district_type = 'JUDICIAL';
  IF (n_lasc, n_coa, n_sup, n_other) IS DISTINCT FROM (473, 24, 7, 0) THEN
    RAISE EXCEPTION 'CA JUDICIAL offices are LASC=% COA=% SUP=% other=% (want 473/24/7/0)', n_lasc, n_coa, n_sup, n_other;
  END IF;
  IF n_foreign_chamber > 0 THEN
    RAISE EXCEPTION '% CA JUDICIAL office(s) already sit on a chamber this file does not write; someone else gave them one', n_foreign_chamber;
  END IF;

  -- 0b. Both parent governments are the rows the header describes.
  SELECT count(*) INTO n_gov
    FROM essentials.governments g
   WHERE (g.id = 'e0f33bda-bfb5-4dd0-9816-576e6ce35fac' AND g.name = 'State of California'
          AND g.type = 'STATE' AND g.state = 'CA' AND g.geo_id = '06')
      OR (g.id = '4236875b-3909-4ae4-ae91-41ae21c07a45' AND g.name = 'Los Angeles County, California, US'
          AND g.type = 'County' AND g.state = 'CA' AND g.geo_id = '06037');
  IF n_gov <> 2 THEN
    RAISE EXCEPTION 'parent governments: % of 2 match the expected id/name/type/geo', n_gov;
  END IF;

  -- 0c. No OTHER chamber already models one of these courts (a second copy would split its judges).
  SELECT count(*) INTO n_dup_name
    FROM essentials.chambers c
   WHERE c.id NOT IN (SELECT chamber_id FROM ca0191_court)
     AND (lower(c.name_formal) IN (SELECT lower(name_formal) FROM ca0191_court)
          OR lower(c.name_formal) IN ('court of appeal, second appellate district',
                                      'superior court of california, county of los angeles',
                                      'los angeles superior court', 'california supreme court'));
  IF n_dup_name > 0 THEN
    RAISE EXCEPTION '% existing chamber(s) already carry one of these court names', n_dup_name;
  END IF;

  -- 0d. A fixed id is either free or already exactly this file's row (re-run).
  SELECT count(*) INTO n_id_clash
    FROM essentials.chambers c
    JOIN ca0191_court cc ON cc.chamber_id = c.id
   WHERE (c.government_id, c.name, c.name_formal, c.policy_engagement_level, c.website_url)
         IS DISTINCT FROM (cc.government_id, cc.name, cc.name_formal, cc.engagement, cc.website_url);
  IF n_id_clash > 0 THEN
    RAISE EXCEPTION '% chamber id(s) this file uses already exist with different values', n_id_clash;
  END IF;

  -- 0e. No government_bodies row would join to these chambers (the header's choice is "no body row"; one
  --     added by someone else would change the heading and sub-group label the dry run measured).
  SELECT count(*) INTO n_body
    FROM essentials.government_bodies gvb
   WHERE gvb.state = 'CA' AND gvb.geo_id IN ('06', '06037', '06-appellate-district-2')
     AND gvb.body_key IN (SELECT name_formal FROM ca0191_court UNION ALL SELECT name FROM ca0191_court);
  IF n_body > 0 THEN
    RAISE EXCEPTION '% government_bodies row(s) already key on these court names', n_body;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. The three chambers.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.chambers (id, government_id, name, name_formal, policy_engagement_level, website_url)
SELECT chamber_id, government_id, name, name_formal, engagement, website_url
  FROM ca0191_court
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Put every office on its court's chamber. Only offices with no chamber yet (pre-flight 0a proved the
--    rest are already on the target).
-- ---------------------------------------------------------------------------
UPDATE essentials.offices o
   SET chamber_id = cc.chamber_id
  FROM essentials.districts d, ca0191_court cc
 WHERE o.district_id = d.id
   AND d.state = 'CA' AND d.district_type = 'JUDICIAL'
   AND d.label LIKE cc.label_like
   AND o.chamber_id IS NULL;

-- ---------------------------------------------------------------------------
-- 3. Post-verify. Any wrong count aborts.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  n_ch int; n_bad_ch int; n_null int; n_wrong int; n_stray int; n_other_changed int;
  n_tier_bad int; n_comma int; n_held int; n_held_bad int; n_held_body int;
  r record;
BEGIN
  -- 3a. The three chambers exist with exactly the decided values.
  SELECT count(*),
         count(*) FILTER (WHERE (c.government_id, c.name, c.name_formal, c.policy_engagement_level, c.website_url)
                                IS DISTINCT FROM (cc.government_id, cc.name, cc.name_formal, cc.engagement, cc.website_url))
    INTO n_ch, n_bad_ch
    FROM ca0191_court cc LEFT JOIN essentials.chambers c ON c.id = cc.chamber_id;
  IF n_ch <> 3 OR n_bad_ch > 0 THEN
    RAISE EXCEPTION 'chambers: % row(s), % with the wrong values (want 3, 0)', n_ch, n_bad_ch;
  END IF;

  -- 3b. Every CA JUDICIAL office is on its own court's chamber; none is left chamberless.
  SELECT count(*) FILTER (WHERE o.chamber_id IS NULL),
         count(*) FILTER (WHERE o.chamber_id IS DISTINCT FROM cc.chamber_id)
    INTO n_null, n_wrong
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN ca0191_court cc ON d.label LIKE cc.label_like
   WHERE d.state = 'CA' AND d.district_type = 'JUDICIAL';
  IF n_null > 0 OR n_wrong > 0 THEN
    RAISE EXCEPTION 'CA JUDICIAL offices: % chamberless, % on the wrong chamber (want 0, 0)', n_null, n_wrong;
  END IF;

  -- 3c. Per court, the chamber holds exactly its own offices and nothing else.
  FOR r IN
    SELECT cc.court, cc.n_offices AS want,
           count(o.id) AS got,
           count(o.id) FILTER (WHERE d.state IS DISTINCT FROM 'CA' OR d.district_type IS DISTINCT FROM 'JUDICIAL'
                                  OR d.label NOT LIKE cc.label_like) AS stray
      FROM ca0191_court cc
      LEFT JOIN essentials.offices o ON o.chamber_id = cc.chamber_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
     GROUP BY cc.court, cc.n_offices
  LOOP
    IF r.got <> r.want OR r.stray > 0 THEN
      RAISE EXCEPTION '% chamber holds % office(s), % stray (want %, 0)', r.court, r.got, r.stray, r.want;
    END IF;
  END LOOP;

  -- 3d. The other chambers under both governments are exactly as they were.
  SELECT count(*) INTO n_other_changed
    FROM ((SELECT id, government_id, name, name_formal, policy_engagement_level,
                  (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.id) AS n_offices
             FROM essentials.chambers c
            WHERE c.government_id IN (SELECT government_id FROM ca0191_court)
              AND c.id NOT IN (SELECT chamber_id FROM ca0191_court)
           EXCEPT SELECT * FROM ca0191_other_chambers)
          UNION ALL
          (SELECT * FROM ca0191_other_chambers
           EXCEPT SELECT id, government_id, name, name_formal, policy_engagement_level,
                         (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.id)
                    FROM essentials.chambers c
                   WHERE c.government_id IN (SELECT government_id FROM ca0191_court)
                     AND c.id NOT IN (SELECT chamber_id FROM ca0191_court))) x;
  IF n_other_changed > 0 THEN
    RAISE EXCEPTION '% other chamber row(s) under State of California / LA County changed', n_other_changed;
  END IF;

  -- 3e. The frontend contract the names were chosen for (see header). Tier keyword in `name`: present for
  --     SUP and 2DCA, absent for LASC. No comma in name_formal (the heading).
  SELECT count(*) FILTER (WHERE (cc.court IN ('SUP', '2DCA')) IS DISTINCT FROM (lower(c.name) ~ '(supreme|appeals|appellate|tax)')),
         count(*) FILTER (WHERE position(',' IN c.name_formal) > 0)
    INTO n_tier_bad, n_comma
    FROM ca0191_court cc JOIN essentials.chambers c ON c.id = cc.chamber_id;
  IF n_tier_bad > 0 OR n_comma > 0 THEN
    RAISE EXCEPTION 'frontend contract: % chamber(s) would land in the wrong tier, % heading(s) carry a comma', n_tier_bad, n_comma;
  END IF;

  -- 3f. What address search will now return for the HELD seats, through the same joins as
  --     districtQueries.ts DISTRICT_JOINS: 422 held (408 + 8 + 6), each with a chamber_name_formal and a
  --     government_name, and no government_body_name.
  SELECT count(*),
         count(*) FILTER (WHERE ch.name_formal IS NULL OR g.name IS NULL),
         count(*) FILTER (WHERE gvb.id IS NOT NULL)
    INTO n_held, n_held_bad, n_held_body
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active
    LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
    LEFT JOIN essentials.government_bodies gvb
      ON gvb.state = d.state AND gvb.geo_id = d.geo_id
     AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
   WHERE d.state = 'CA' AND d.district_type = 'JUDICIAL';
  IF n_held <> 422 OR n_held_bad > 0 OR n_held_body > 0 THEN
    RAISE EXCEPTION 'held CA judges: % (want 422), % without chamber/government, % with a body row (want 0, 0)',
      n_held, n_held_bad, n_held_body;
  END IF;

  RAISE NOTICE 'OK: 3 CA court chambers; offices SUP 7 / 2DCA 24 / LASC 473 on them; 422 held judges now carry chamber + government';
END $$;

COMMIT;
