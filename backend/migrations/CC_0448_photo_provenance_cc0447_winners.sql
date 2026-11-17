-- CC_0448 — fix the photo provenance on three of the five CC_0447 winners
--
-- WHAT THIS DOES
--   Corrects `politician_images.photo_license` and `politicians.photo_origin_url` on three
--   rows. It changes NO pixels: every image file stays exactly as it is. What was wrong was
--   the RECORD, not the picture.
--
-- 🔴 WHAT IT OVERWRITES — RECORDED HERE BECAUSE AN UPDATE IS FINAL
--   There is no history table for these columns. Old values, read from production 2026-11-17
--   and also kept in backend/data/house-2026-late-calls/photo-provenance-before.json:
--
--     Eileen Laubacher  image 23114ac3-693b-4b1e-a91d-49556338b9e9
--       photo_license    'press_use'  ->  'us_government_work'
--       photo_origin_url 'https://ballotpedia.org/Colorado%27s_4th_Congressional_District_election,_2026'
--                        ->  'https://www.navy.mil/Leadership/Flag-Officer-Biographies/BioDisplay/Article/2236454/rear-admiral-eileen-laubacher/'
--     Eric Jones        image 586acbbe-5b78-4f26-9db7-2d62cc1d5172
--       photo_license    'press_use'  ->  'unknown'
--       photo_origin_url 'https://ballotpedia.org/California%27s_4th_Congressional_District_election,_2026'
--                        ->  'https://ballotpedia.org/Eric_Jones_(California)'
--     Jay Obernolte     image b432a95d-dfbc-4a24-8b35-534f918aa1de
--       photo_license    NULL  ->  'public_domain'
--       photo_origin_url NULL  ->  'https://unitedstates.github.io/images/congress/original/O000019.jpg'
--
-- 🔴 A LICENCE IS READ, NEVER INFERRED FROM THE HOST — AND BALLOTPEDIA IS NOT A LICENSOR
--   All three rows were wrong in the same way: two claimed `press_use` on the authority of a
--   Ballotpedia page, and Ballotpedia cannot grant that. Its person photos are candidate-
--   submitted or taken from campaign sites, so the copyright was never Ballotpedia's to
--   license. A Ballotpedia origin is a POINTER TO THE REAL SOURCE, not a licence.
--
-- WHAT WAS READ, PER ROW
--   * LAUBACHER — the image is the official US Navy portrait. Verified by eye against the
--     navy.mil flag-officer biography for Rear Admiral Eileen Laubacher, which displays
--     media.defense.gov VIRIN 241219-N-N0101-001 at 2400x3000: the same photograph, our copy
--     being a smaller crop of it. Licence read at
--     https://www.war.gov/Contact/Help-Center/Article/Article/2762906/use-of-department-of-war-imagery/
--     (formerly defense.gov/Help-Center): "Department of War photographs and imagery, unless
--     otherwise noted, are in the public domain." Nothing on the bio page notes otherwise.
--     Recorded as `us_government_work` — the precise vocabulary item for a federal work.
--   * OBERNOLTE — the image is the official congressional portrait, a low-resolution crop of
--     the file the @unitedstates project serves for bioguide O000019 (verified by eye against
--     the 1536x1920 original). Licence read in that project's own README: "The photos of
--     members of Congress are from the Government Printing Office, which has assured us that
--     all photos are public domain." Recorded as `public_domain`, which is what all 317 other
--     rows in this database citing unitedstates.github.io already say. ⚠ The two values in
--     this migration therefore differ on purpose: `public_domain` follows an established
--     precedent for that exact source, `us_government_work` is the precise label where there
--     was no precedent to follow. Both say the same thing about reuse.
--   * JONES — 🔴 THE HONEST ANSWER IS `unknown`, AND THAT IS THE POINT OF THE VALUE.
--     The photograph is a candidate-submitted portrait published on his Ballotpedia candidate
--     page; our copy is the same photograph at a different crop, confirmed. Nobody publishes
--     an author or terms for it, and his campaign site carries a DIFFERENT portrait entirely.
--     So no licence was read, and `unknown` is what the record should say. An `unknown` is
--     findable by the query that looks for missing provenance; a guessed `press_use` is not,
--     and it tells the public they may reuse a photograph nobody cleared.
--     The origin moves from the ELECTION page to the CANDIDATE page, which is where the image
--     is actually published and which names him.
--
-- ⚠ WHAT THIS DELIBERATELY DOES NOT DO
--   It does not re-mirror anything. Laubacher's original is 2400x3000 and Obernolte's is
--   1536x1920, while the stored copies are 600x750 and 175x219 — Obernolte's is far below the
--   600x750 house standard. Replacing published pixels needs the operator's approval on a
--   contact sheet, which is a separate act from correcting a false licence claim.

BEGIN;

CREATE TEMP TABLE cc0448_fix (
  politician_id uuid PRIMARY KEY,
  image_id      uuid NOT NULL,
  full_name     text NOT NULL,
  old_license   text,
  new_license   text NOT NULL,
  new_origin    text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0448_fix VALUES
 ('09a94867-ea68-4a53-89cb-c89485119a9c','23114ac3-693b-4b1e-a91d-49556338b9e9','Eileen Laubacher',
  'press_use','us_government_work',
  'https://www.navy.mil/Leadership/Flag-Officer-Biographies/BioDisplay/Article/2236454/rear-admiral-eileen-laubacher/'),
 ('9e28793b-bb53-433c-be6f-44db5bf2e780','586acbbe-5b78-4f26-9db7-2d62cc1d5172','Eric Jones',
  'press_use','unknown',
  'https://ballotpedia.org/Eric_Jones_(California)'),
 ('18db5d61-6bce-4f55-ad45-bed01f329548','b432a95d-dfbc-4a24-8b35-534f918aa1de','Jay Obernolte',
  NULL,'public_domain',
  'https://unitedstates.github.io/images/congress/original/O000019.jpg');

DO $$
DECLARE v_n bigint; v_names text;
BEGIN
  -- Each pin must resolve to a real image row belonging to the named person.
  SELECT count(*) INTO v_n
    FROM cc0448_fix f
    JOIN essentials.politician_images pi ON pi.id = f.image_id AND pi.politician_id = f.politician_id
    JOIN essentials.politicians p        ON p.id = f.politician_id AND p.full_name = f.full_name;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0448 pre-check: % of 3 pins resolve to an image row belonging to the named person', v_n;
  END IF;

  -- The old licence must be what the header says it was, or the header is already wrong
  -- and the values recorded above cannot be trusted as the thing being overwritten.
  SELECT count(*), string_agg(f.full_name || ': ' || coalesce(pi.photo_license, 'NULL'), ', ')
    INTO v_n, v_names
    FROM cc0448_fix f
    JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license IS DISTINCT FROM f.old_license;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448 pre-check: % row(s) do not carry the licence this migration says it is overwriting: %', v_n, v_names;
  END IF;

  -- Each person must have exactly one image row, or "the" licence is ambiguous.
  SELECT count(*) INTO v_n FROM (
    SELECT f.politician_id FROM cc0448_fix f
      JOIN essentials.politician_images pi ON pi.politician_id = f.politician_id
     GROUP BY f.politician_id HAVING count(*) <> 1) x;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448 pre-check: % of the three people have more or fewer than one image row', v_n;
  END IF;
END $$;

UPDATE essentials.politician_images pi
   SET photo_license = f.new_license
  FROM cc0448_fix f
 WHERE pi.id = f.image_id;

UPDATE essentials.politicians p
   SET photo_origin_url = f.new_origin
  FROM cc0448_fix f
 WHERE p.id = f.politician_id;

-- Post-verify. Counting three rows says nothing about whether each row says the right thing.
DO $$
DECLARE v_n bigint; v_names text; v_url text;
BEGIN
  -- 1. every pinned row carries ITS OWN new licence and origin, matched per person
  SELECT count(*) INTO v_n
    FROM cc0448_fix f
    JOIN essentials.politician_images pi ON pi.id = f.image_id
    JOIN essentials.politicians p        ON p.id = f.politician_id
   WHERE pi.photo_license = f.new_license
     AND p.photo_origin_url = f.new_origin;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0448: only % of 3 rows carry both the licence and the origin this migration names for that person', v_n;
  END IF;

  -- 1b. 🔴🔴 THE ORIGIN MUST NAME THE PERSON IT BELONGS TO, AND THIS EXPECTATION IS WRITTEN
  --     HERE RATHER THAN READ FROM THE PIN TABLE. Assertion 1 compares each row against this
  --     migration's OWN declared origin, so a pin that is edited consistently agrees with
  --     itself and sails through: control C hands Laubacher's row Obernolte's URL and
  --     assertion 1 cannot see it. That is the identical defect CC_0447 found one migration
  --     earlier, wearing different clothes. ▶ A GATE THAT READS THE MIGRATION'S OWN
  --     DECLARATION IS NOT CHECKING A PAIRING. The tokens below come from each person's own
  --     identity — her surname, his bioguide id, his name in the page title — so the only way
  --     to satisfy them is to put the right URL on the right person.
  SELECT count(*), string_agg(p.full_name || ' -> ' || p.photo_origin_url, ' | ')
    INTO v_n, v_names
    FROM cc0448_fix f
    JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE NOT (
        (p.full_name = 'Eileen Laubacher'
           AND p.photo_origin_url LIKE '%navy.mil%'
           AND p.photo_origin_url ILIKE '%laubacher%')
     OR (p.full_name = 'Jay Obernolte'
           AND p.photo_origin_url LIKE '%unitedstates.github.io%'
           AND p.photo_origin_url LIKE '%O000019%')
     OR (p.full_name = 'Eric Jones'
           AND p.photo_origin_url LIKE '%ballotpedia.org%'
           AND p.photo_origin_url LIKE '%Eric_Jones%'));
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448: % row(s) carry an origin that does not name the person it is attached to: %', v_n, v_names;
  END IF;

  -- 2. 🔴 NOT ONE OF THE THREE MAY STILL CITE BALLOTPEDIA AS THE SOURCE OF A LICENCE.
  --    Jones keeps a Ballotpedia ORIGIN, which is correct — that is where the image is
  --    published — but his licence must be `unknown`, never a claim Ballotpedia cannot grant.
  SELECT count(*), string_agg(p.full_name, ', ') INTO v_n, v_names
    FROM cc0448_fix f
    JOIN essentials.politicians p        ON p.id = f.politician_id
    JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE p.photo_origin_url LIKE '%ballotpedia.org%'
     AND pi.photo_license NOT IN ('unknown', '');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448: % row(s) still claim a licence on the authority of a Ballotpedia page: %', v_n, v_names;
  END IF;

  -- 3. every licence written is in the controlled vocabulary CC_0328 fixed
  SELECT count(*) INTO v_n
    FROM cc0448_fix f
    JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.photo_license NOT IN ('cc0','cc_by_2.0','cc_by_3.0','cc_by_4.0','cc_by-sa',
                                  'cc_by-sa_2.0','cc_by-sa_3.0','cc_by-sa_4.0',
                                  'press_use','public_domain','us_government_work','unknown');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448: % row(s) carry a licence outside the controlled vocabulary', v_n;
  END IF;

  -- 4. no origin is left NULL or empty on these three
  SELECT count(*) INTO v_n
    FROM cc0448_fix f JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE coalesce(p.photo_origin_url, '') = '';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448: % of the three still have no photo_origin_url', v_n;
  END IF;

  -- 5. 🔴 NO PIXELS MOVED. The stored image URLs must be untouched by this migration; it
  --    corrects a record, and a changed URL would mean it had quietly republished a photo.
  SELECT count(*) INTO v_n
    FROM cc0448_fix f JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.url NOT LIKE '%supabase.co/storage/v1/object/public/politician_photos/%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448: % image url(s) no longer point at our own mirror', v_n;
  END IF;

  SELECT p.full_name || ' -> ' || pi.url INTO v_url
    FROM cc0448_fix f
    JOIN essentials.politician_images pi ON pi.id = f.image_id
    JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE pi.politician_id = '18db5d61-6bce-4f55-ad45-bed01f329548';
  IF v_url IS NULL THEN
    RAISE EXCEPTION 'CC_0448: Obernolte''s image row vanished';
  END IF;

  -- 6. NO SCOPE LEAK: nobody outside these three gained either of the new origins
  SELECT count(*) INTO v_n
    FROM essentials.politicians p
   WHERE p.photo_origin_url IN (SELECT new_origin FROM cc0448_fix)
     AND p.id NOT IN (SELECT politician_id FROM cc0448_fix);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0448: % person/people outside the three carry one of this migration''s origins', v_n;
  END IF;

  -- 7. the two CC_0447 winners this migration does NOT touch keep their provenance
  SELECT count(*) INTO v_n
    FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id
   WHERE p.full_name IN ('Paul LePage','David Rouzer')
     AND pi.photo_license IN ('cc_by-sa_3.0','public_domain');
  IF v_n < 2 THEN
    RAISE EXCEPTION 'CC_0448: LePage and Rouzer should still carry their existing licences; found % matching row(s)', v_n;
  END IF;

  RAISE NOTICE 'CC_0448 OK: 3 provenance records corrected, 0 pixels changed';
END $$;

COMMIT;
