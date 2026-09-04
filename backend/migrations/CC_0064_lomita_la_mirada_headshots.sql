-- CC_0064_lomita_la_mirada_headshots.sql
--
-- Six headshots for Lomita and La Mirada. Apply AFTER CC_0063, which creates Anthony A.
-- Otero and Ed Eng; two of the six rows below do not exist before it runs.
--
-- Objects were uploaded by backend/scripts/_tmp-lomita-lamirada-headshots.py (gitignored)
-- BEFORE this migration. Each was re-fetched from the CDN and fully DECODED after the PUT —
-- 🔴 a clean HTTP 200 can carry a truncated body, so the header is not the file.
--
-- ── WHERE THESE CAME FROM ────────────────────────────────────────────────────────────────
--
-- The 2026-09-03 LA County audit recorded Lomita and La Mirada as "block automated access"
-- and left six people short. They do not block a human. Both refuse `curl` and Node fetch at
-- the TLS handshake and serve a real Chrome session normally, so nothing was ever unreachable
-- — the wrong client was used. Every portrait below is the city's own published file.
--
--   La Mirada  https://www.lamirada.gov/city_hall/city_council.php     (5 portraits)
--   Lomita     https://lomitacity.com/city-council/                    (1 portrait)
--
-- ── IDENTITY ────────────────────────────────────────────────────────────────────────────
--
-- 🔴 A NAME MERELY NEAR AN IMAGE IS NOT IDENTITY. All five La Mirada files carry the member's
--    surname in the city's own image path (.../City Council/Otero...jpg, De Ruse...jpg,
--    Eng...jpg, Lewis...jpg, Bean...jpg). Bill Uphoff's carries his full name AND sits inside
--    his own member card. Six for six on name-in-path; nothing here rests on page proximity.
--
-- 🔴 LA MIRADA'S JOHN LEWIS IS NOT THE LATE REP. JOHN LEWIS OF GEORGIA. The audit found that
--    substitution on the `<uuid>/default.jpeg` importer path and blanked it, which is why his
--    row below is filling a BLANK rather than replacing anything. The new render was looked
--    at before upload: a white-haired attorney in his sixties, not the congressman.
--
-- ── WHAT EACH ROW DOES ──────────────────────────────────────────────────────────────────
--
--   Otero, Eng          BLANK -> first photo (both seated by CC_0063)
--   John Lewis          BLANK -> first correct photo (see above)
--   Bean                replaces a render built from a 207 px crop
--   Uphoff              replaces a `<uuid>/default.jpeg` row — the importer path that
--                       produced every not-a-person image in the county (4 bad in 38).
--                       Lomita replaced his portrait in June 2026 with a 2048x2560 file,
--                       AFTER the audit ran.
--   De Ruse             replaces an audit render of the same portrait. Kept anyway so all
--                       five La Mirada members share one provenance and one storage host;
--                       his old URL sat on `<ref>.storage.supabase.co` while every other row
--                       in the corpus uses `<ref>.supabase.co/storage/v1`.
--
-- ⚠ THE OTHER FOUR LOMITA MEMBERS ARE STILL SHORT, AND NOT BECAUSE OF A BLOCK. Segawa, Waite,
--   Waronek and Gazeley are published at 150x200. A 4:5 crop of that is 184-188 px tall,
--   under the 220 px floor, and would need a ~4x enlargement. That is a real ceiling in the
--   source, and no browser fixes it. Do not re-chase lomitacity.com for them.
--
-- ── ROLLBACK ────────────────────────────────────────────────────────────────────────────
--   Otero   -> NULL
--   Eng     -> NULL
--   Lewis   -> NULL
--   Bean    -> .../politician_photos/la_county/cities/la_mirada/michelle-velasquez-bean.jpg
--   Uphoff  -> .../politician_photos/c534692d-34fa-4bde-ae83-b27f7d2a6adc/default.jpeg
--   De Ruse -> https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/
--              politician_photos/la_county/2026-audit/5bc8e8fb-8784-4d4b-b4d6-e2416a593100.jpg
--   photo_origin_url was NULL on all six beforehand.

BEGIN;

-- 🔴 photo_custom_url IS WHAT A VOTER SEES. A politician_images row changes nothing.
UPDATE essentials.politicians p
   SET photo_custom_url = v.cdn,
       photo_origin_url = v.origin
  FROM (VALUES
    ('7d6f87b6-8769-4247-99a6-da1702909a1f',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/7d6f87b6-8769-4247-99a6-da1702909a1f.jpg',
     'https://www.lamirada.gov/Images/City%20Hall/City%20Council/Otero%20-%20Copy%20(3)%20-%20Copy%20-%20Copy%20-%20Copy.jpg'),
    ('5bc8e8fb-8784-4d4b-b4d6-e2416a593100',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/5bc8e8fb-8784-4d4b-b4d6-e2416a593100.jpg',
     'https://www.lamirada.gov/Images/City%20Hall/City%20Council/De%20Ruse%20-%20Copy%20-%20Copy.jpg'),
    ('1d74e26f-c565-420e-82be-f946098016fb',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/1d74e26f-c565-420e-82be-f946098016fb.jpg',
     'https://www.lamirada.gov/Images/City%20Hall/City%20Council/Eng%20-%20Copy.jpg'),
    ('753acd7a-1325-4883-80e7-c78466384cb2',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/753acd7a-1325-4883-80e7-c78466384cb2.jpg',
     'https://www.lamirada.gov/Images/City%20Hall/City%20Council/Lewis%20-%20Copy%20(4)%20-%20Copy%20-%20Copy.jpg'),
    ('cf6a072a-026b-4b95-9eb4-180be6480a95',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/cf6a072a-026b-4b95-9eb4-180be6480a95.jpg',
     'https://www.lamirada.gov/Images/City%20Hall/City%20Council/Bean%20-%20Copy%20(3)%20-%20Copy.jpg'),
    ('c534692d-34fa-4bde-ae83-b27f7d2a6adc',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/c534692d-34fa-4bde-ae83-b27f7d2a6adc.jpg',
     'https://lomitacity.com/wp-content/uploads/2026/06/Bill-Uphoff-Headshot-scaled.jpg')
  ) AS v(pid, cdn, origin)
 WHERE p.id = v.pid::uuid
   -- 🔴 Never silently overwrite a hand-picked photo. None of the six carries the flag today;
   --    if that changes before this is applied, the row falls out and the gate below fails.
   AND p.photo_custom_url_manual_override IS NOT TRUE;

DO $$
DECLARE
  v_n   int;
  v_bad text;
BEGIN
  -- 1. All six now point at the new prefix.
  SELECT count(*) INTO v_n
    FROM essentials.politicians
   WHERE id IN ('7d6f87b6-8769-4247-99a6-da1702909a1f',
                '5bc8e8fb-8784-4d4b-b4d6-e2416a593100',
                '1d74e26f-c565-420e-82be-f946098016fb',
                '753acd7a-1325-4883-80e7-c78466384cb2',
                'cf6a072a-026b-4b95-9eb4-180be6480a95',
                'c534692d-34fa-4bde-ae83-b27f7d2a6adc')
     AND photo_custom_url LIKE '%/la_county/2026-audit-b/%';
  IF v_n <> 6 THEN
    RAISE EXCEPTION 'expected 6 rows repointed to la_county/2026-audit-b, found %', v_n;
  END IF;

  -- 2. Each URL ends in that person's OWN uuid. Guards against a copy-paste that would give
  --    one voter another person's face — the exact failure this whole wave is cleaning up.
  SELECT string_agg(full_name, '; ')
    INTO v_bad
    FROM essentials.politicians
   WHERE photo_custom_url LIKE '%/la_county/2026-audit-b/%'
     AND photo_custom_url NOT LIKE '%/' || id::text || '.jpg';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'photo URL does not match the row uuid for: %', v_bad;
  END IF;

  -- 3. Exactly one seated member across both cities still renders nothing, and it is Cindy
  --    Segawa — created by CC_0063 with no photo, because Lomita publishes her at 150x200.
  --    🔴 A BLANK BEATS A LINK: she is left blank rather than shipped as a 4x enlargement.
  --    Waite, Waronek and Gazeley are NOT blank; they keep their existing (small) renders.
  SELECT string_agg(p.full_name, '; ' ORDER BY p.full_name)
    INTO v_bad
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id IN ('0642468', '0640032')
     AND coalesce(p.photo_custom_url, '') = '';
  IF v_bad IS DISTINCT FROM 'Cindy Segawa' THEN
    RAISE EXCEPTION 'expected Cindy Segawa to be the only blank across Lomita and La Mirada, found: %',
                    coalesce(v_bad, '(none)');
  END IF;

  RAISE NOTICE 'Lomita + La Mirada headshots: 6 repointed to la_county/2026-audit-b; 9 of 10 seated members render; Cindy Segawa left blank on purpose, and Waite, Waronek and Gazeley keep their small city renders';
END $$;

COMMIT;
