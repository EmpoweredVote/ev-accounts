-- 1672_repoint_or_county_urls_waf_reviewed.sql
--
-- Repoints `official_web_url` for 9 more Oregon county districts — the ones the audit had flagged
-- `WAF blocked a probe`, reviewed and cleared. Data-only; no schema change. Third and largest of the
-- Oregon set after 1670 (12 clean repoints) and 1671 (6 scheme upgrades); brings Oregon to 27 of 36.
--
-- ── WHY THESE WERE FLAGGED, AND WHY THE FLAG WAS WRONG ─────────────────────────────────────────
-- The auditor marked a unit for a human read if ANY probe in it was WAF-blocked. That is too coarse:
-- a unit probes up to 16 candidates, and a block on a candidate that is being REJECTED anyway says
-- nothing about the destination being recommended. Checked per row, in all 9 cases:
--
--   * the recommended destination was itself VERIFIED, state-confirmed, with the governing body in
--     page PROSE (not merely navigation), and was NOT the blocked probe; and
--   * the blocked page was a GoDaddy parked-domain sales lander every time but three —
--     `polkcounty.org` (32 chars) and `unioncounty.net` (58 chars), both thin non-candidates, and
--     `currycountynm.gov`, which is Curry County NEW MEXICO.
--
-- So the caveat was an artefact of unit-scoped flagging, not evidence about these rows. The auditor
-- has been corrected to flag a block only when the blocked page IS the recommendation, or when
-- nothing verified at all — because in that second case the blocked page might have been the real
-- site, and the standing rule holds: a BLOCKED row is not a licence to repoint. Re-running these 9
-- under the corrected flag drops them from 9 human reads to 1.
--
-- ── 🔴 THE ONE THAT STILL WANTS A HUMAN GLANCE: JACKSON (41029) ─────────────────────────────────
-- Jackson is the row where the wrong answer came closest to winning. TWO destinations verified:
--
--   https://www.jacksoncountyor.gov/   own=true   "Jackson County, Oregon - Official Government Website"
--   https://www.jacksongov.org/Home    own=false  "HOME - Jackson County MO"          <- MISSOURI
--
-- Both name Jackson and both show a county governing body, so every entity marker passes on both.
-- The Missouri site was excluded by the rule that a state-confirmed destination outranks every
-- unconfirmed one outright — a rule added precisely because this row had previously been decided by
-- `score()`'s preference for `.gov`, i.e. by luck. The page titles settle it beyond argument, and
-- they are recorded here so nobody has to re-derive that. The gate below refuses jacksongov.org.
--
-- ── 🔴 SHERMAN COUNTY (41055) IS THE HIGHEST-VALUE ROW IN THE WHOLE OREGON SET ──────────────────
-- Its stored value, `http://www.sherman-county.com/`, is not merely stale — it is an expired-domain
-- squat serving 19,030 characters of gambling and pharma keywords, and it has been live on a county
-- government field this whole time. This is the Sierra County `.ws` failure repeating in another
-- state (1646). It is replaced here with `shermancountyor.gov`, which verified with Oregon named and
-- a governing body in prose. `shermancountyks.gov` — Sherman County KANSAS — was rejected on the way.
--
-- ── 🔴 SAME geo_id COLLISION AS 1670 AND 1671. SCOPE BY district_type. ─────────────────────────
-- `41007` is Clatsop County AND State House District 7 AND State Senate District 7. Across these 9
-- geo_ids there are 22 rows, only 9 of them counties; the 13 legislative rows carry
-- `official_web_url IS NULL` and nothing constrains that column, so an unscoped UPDATE would stamp a
-- county homepage onto them with no error. Every statement is scoped
-- `district_type = 'COUNTY' AND lower(state) = 'or'`.
--
-- Four of the nine also drop the old state-hosted namespace for a `<name>county.gov` /
-- `<name>countyor.gov` host, which is the same namespace move 1670 documented; Deschutes moves off a
-- `.org`, Union off a tourism `.org`, Sherman off the squat.
--
-- Idempotent: compare-and-swap on the exact value measured, so a second run matches 0 rows, and the
-- gate asserts END STATE rather than the delta.
--
-- Dry run:  BEGIN; \i this file  ... confirm the NOTICEs ... ROLLBACK;

BEGIN;

WITH repoint(geo_id, old_url, new_url) AS (
  VALUES
    ('41007', 'http://www.co.clatsop.or.us/',   'https://www.clatsopcounty.gov/'),
    ('41015', 'http://www.co.curry.or.us/',     'https://www.currycountyor.gov/'),
    ('41017', 'http://www.deschutes.org/',      'https://www.deschutescounty.gov/'),
    ('41019', 'http://www.co.douglas.or.us/',   'https://www.douglascountyor.gov/'),
    ('41029', 'http://www.co.jackson.or.us/',   'https://www.jacksoncountyor.gov/'),
    ('41033', 'http://www.co.josephine.or.us/', 'https://www.josephinecounty.gov/'),
    ('41053', 'http://www.co.polk.or.us/',      'https://www.polkcountyor.gov/'),
    ('41055', 'http://www.sherman-county.com/', 'https://www.shermancountyor.gov/'),
    ('41061', 'http://www.unioncounty.org',     'https://unioncountyor.gov/')
)
UPDATE essentials.districts d
   SET official_web_url = r.new_url
  FROM repoint r
 WHERE d.geo_id           = r.geo_id
   AND d.district_type    = 'COUNTY'        -- 🔴 without this, 41007 also matches two legislative rows
   AND lower(d.state)     = 'or'
   AND d.official_web_url = r.old_url;

-- ── POST-VERIFY GATE ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_expected CONSTANT int := 9;
  v_settled  int;
  v_leaked   int;
  v_bad      int;
  v_https    int;
  v_plain    int;
  v_row      record;
BEGIN
  -- 1. END STATE: all 9 hold exactly the intended value. Passes on a re-run.
  SELECT count(*) INTO v_settled
    FROM essentials.districts d
    JOIN (VALUES
      ('41007', 'https://www.clatsopcounty.gov/'),
      ('41015', 'https://www.currycountyor.gov/'),
      ('41017', 'https://www.deschutescounty.gov/'),
      ('41019', 'https://www.douglascountyor.gov/'),
      ('41029', 'https://www.jacksoncountyor.gov/'),
      ('41033', 'https://www.josephinecounty.gov/'),
      ('41053', 'https://www.polkcountyor.gov/'),
      ('41055', 'https://www.shermancountyor.gov/'),
      ('41061', 'https://unioncountyor.gov/')
    ) AS w(geo_id, url)
      ON w.geo_id = d.geo_id AND d.official_web_url = w.url
   WHERE d.district_type = 'COUNTY' AND lower(d.state) = 'or';

  IF v_settled <> v_expected THEN
    RAISE EXCEPTION 'expected % OR county rows to hold their new URL, found %', v_expected, v_settled;
  END IF;

  -- 2. 🔴 THE NEAR-MISSES. Every one of these verified against a real county governing body while
  --    being the WRONG STATE or an outright squat. None may ever be stored on an OR county row.
  SELECT count(*) INTO v_bad
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url IS NOT NULL
     AND (official_web_url ILIKE '%jacksongov.org%'        -- Jackson County MISSOURI
       OR official_web_url ILIKE '%shermancountyks%'        -- Sherman County KANSAS
       OR official_web_url ILIKE '%currycountynm%'          -- Curry County NEW MEXICO
       OR official_web_url ILIKE '%lincolncountync%'        -- Lincoln County NORTH CAROLINA
       OR official_web_url ILIKE '%in.gov/counties/grant%'  -- Grant County INDIANA
       OR official_web_url ILIKE '%douglascounty.us%'       -- MINNESOTA / WISCONSIN
       OR official_web_url ILIKE '%sherman-county.com%'     -- gambling squat
       OR official_web_url ILIKE '%unioncounty.org%'        -- tourism / chamber
       OR official_web_url ILIKE '%forsale.godaddy%'        -- parked
       OR official_web_url ILIKE '%forsale.dynadot%');
  IF v_bad <> 0 THEN
    RAISE EXCEPTION '% OR county row(s) hold a rejected destination', v_bad;
  END IF;

  -- 3. 🔴 COLLISION CHECK. Nothing leaked onto a legislative district sharing these geo_ids.
  SELECT count(*) INTO v_leaked
    FROM essentials.districts
   WHERE geo_id IN ('41007','41015','41017','41019','41029','41033','41053','41055','41061')
     AND district_type <> 'COUNTY'
     AND official_web_url IS NOT NULL;
  IF v_leaked <> 0 THEN
    RAISE EXCEPTION 'geo_id collision: % non-COUNTY district(s) acquired an official_web_url', v_leaked;
  END IF;

  -- 4. Progress, not a gate.
  SELECT count(*) INTO v_https
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'https://%';
  SELECT count(*) INTO v_plain
    FROM essentials.districts
   WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url LIKE 'http://%';

  RAISE NOTICE 'OK: % OR county rows repointed after clearing the WAF caveat.', v_expected;
  RAISE NOTICE 'Sherman County no longer serves a gambling squat.';
  RAISE NOTICE 'No leak onto the 13 legislative districts sharing these geo_ids.';
  RAISE NOTICE 'Oregon counties now: % on https, % still on http (of 36).', v_https, v_plain;

  FOR v_row IN
    SELECT geo_id, label, official_web_url
      FROM essentials.districts
     WHERE district_type = 'COUNTY' AND lower(state) = 'or' AND official_web_url IS NOT NULL
       AND (official_web_url ILIKE '%lakecountyor.org%'         -- tourism
         OR official_web_url ILIKE '%wallowa.co.or.us%'          -- NXDOMAIN
         OR official_web_url ILIKE '%wheelercountyoregon.gov%')  -- NXDOMAIN; do NOT auto-repoint
     ORDER BY geo_id
  LOOP
    RAISE NOTICE 'STILL BROKEN, left on purpose: % % -> %', v_row.geo_id, v_row.label, v_row.official_web_url;
  END LOOP;
  RAISE NOTICE 'Wheeler (41069) must NOT be auto-applied -- its only candidate is a same-name .com.';
END $$;

COMMIT;
