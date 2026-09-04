-- CC_0068_lomita_final_three_headshots.sql
--
-- The last three Lomita headshots: James Gazeley, Barry Waite, Cindy Segawa.
-- Apply AFTER CC_0063 (which creates Segawa) and CC_0065.
--
-- Objects uploaded by backend/scripts/_tmp-lomita-final-three.py (gitignored) BEFORE this
-- migration, each re-fetched from the CDN and fully DECODED after the PUT.
--
-- With this, all ten seated members of Lomita and La Mirada render, and the "LA County cities
-- that block automated access" thread from the 2026-09-03 audit is closed.
--
-- ── 🔴 THE MISTAKE THIS MIGRATION EXISTS TO CORRECT ──────────────────────────────────────
--
-- CC_0065 recorded, as a measured ceiling:
--
--     "SBCCOG publishes its board at 152x190, under the same floor that stopped the city's
--      own files, so it is not an escape from the ceiling."
--
-- ⚠ THAT WAS THE SIZE THE BOARD PAGE *DISPLAYED*, NOT THE SIZE OF THE FILE. Gazeley's file
--   on the same host is 731x1024 — and it is not a different sitting, it is the very
--   photograph the city serves shrunk to 150x200. A rendered size is not a file size.
--   Reading one as a ceiling wrote off a portrait that was available all along.
--
--   This is the same error class as reading a resize parameter as a limit (Torrance's
--   `?dimension=userprofile`, 2026-09-03). Both times the number came from how a page chose
--   to show an image. **Measure the file at its origin, never the element on the page.**
--
-- ⚠ A CDN WILL LIE IN THE OTHER DIRECTION TOO. barrywaite.org serves through an image CDN
--   that returns ANY size requested: `?resize=1200` yields a 1200x1600 image that is an 8x
--   upscale of a 150x200 original, with no new detail in it. Only the ORIGIN server answered
--   honestly (276x400). A reported dimension is not evidence of resolution.
--
-- ⚠ AND A HOST CAN START BLOCKING MID-SWEEP. Partway through, lomitacity.com began 403-ing
--   the downloader, so five "this file does not exist" results were really "you are being
--   blocked". A positive control on a file known to exist failed too, which is the only
--   reason it was caught. **Re-run a known-good fetch before believing a run of misses.**
--
-- ── WHAT EACH ROW GETS ──────────────────────────────────────────────────────────────────
--
--   GAZELEY  731x1024 -> kept 731x914, 0.82x DOWNSCALE. Replaces a 3.99x enlargement of the
--            same photograph. Source: cdn.southbaycities.org, SBCCOG, where Lomita's seat is
--            his. Identity: full name in the file path, and pixel-identical to the sitting on
--            his own city council card. Two independent bindings.
--
--   WAITE    276x400 -> kept 276x345, 2.17x. From barrywaite.org, his own site.
--            ⚠ IT IS CASUAL — open collar, outdoors — where every colleague is a studio
--              portrait. That is a deliberate trade, made by the operator on 2026-09-04:
--              a legible face beat a formal pose rendered as mush at 3.99x. If the register
--              matters more later, the city file is still there; this is reversible.
--            Identity: face-matched against the city portrait, whose filename is his name.
--
--   SEGAWA   🔴 SHIPS BELOW THE GATE, DELIBERATELY AND ON THE RECORD.
--            150x200 -> kept 150x188, 3.99x. The floor is 220px; this clears the 4.5x
--            enlargement ceiling but NOT the crop-height floor. It will render soft — this is
--            the same file the original audit called mush and refused.
--
--            The operator chose it on 2026-09-04 over two alternatives:
--              * leaving her blank (she is the Mayor and rendered nothing at all), and
--              * an official California Assembly photograph (muratsuchi.asmdc.org,
--                2022-10-20) of a three-person breakfast meeting, in which her face is sharp
--                and needs NO enlargement (0.98x) but which is visibly a restaurant snapshot,
--                with another diner in frame.
--
--            🔴 THE FLOOR WAS NOT LOWERED. The importer carries a named per-person override
--               for her alone, so this exception stays visible and countable instead of
--               quietly widening a gate for everyone. Do not generalise it.
--
-- ── SEARCH EXHAUSTED FOR SEGAWA ─────────────────────────────────────────────────────────
-- No Ballotpedia page. No SCAG profile (she sits on no regional body). No SBCCOG page —
-- Gazeley is Lomita's delegate and Waite only the alternate, which is exactly why those two
-- had a better file and she does not. The FY2026-27 adopted budget lists her among the city
-- officials and carries no portrait. The newsletter archive stops at Spring 2022 and is event
-- photography. The unedited WordPress originals behind the city's edit suffixes are 150x210
-- at best. **Do not re-run this search without a genuinely new lead.**
--
-- ── ROLLBACK ────────────────────────────────────────────────────────────────────────────
--   Gazeley -> .../politician_photos/e258ed0d-24fe-40a0-96d7-6ab22618aa71/default.jpeg
--   Waite   -> .../politician_photos/b943ec10-59a6-47b4-a3df-52b9747df53b/default.jpeg
--   Segawa  -> NULL
--   photo_origin_url was NULL on all three beforehand.

BEGIN;

UPDATE essentials.politicians p
   SET photo_custom_url = v.cdn,
       photo_origin_url = v.origin
  FROM (VALUES
    ('e258ed0d-24fe-40a0-96d7-6ab22618aa71',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/e258ed0d-24fe-40a0-96d7-6ab22618aa71.jpg',
     'https://cdn.southbaycities.org/wp-content/uploads/2021/08/01185008/James-Gazeley.jpg'),
    ('b943ec10-59a6-47b4-a3df-52b9747df53b',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/b943ec10-59a6-47b4-a3df-52b9747df53b.jpg',
     'https://barrywaite.org/wp-content/uploads/2021/08/1d529-barrypic-for-prof-e1629839996747.png'),
    ('c1193f7e-6891-4f59-9466-f001ac5ad49e',
     'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/c1193f7e-6891-4f59-9466-f001ac5ad49e.jpg',
     'https://lomitacity.com/wp-content/uploads/2021/10/ALM.jpeg')
  ) AS v(pid, cdn, origin)
 WHERE p.id = v.pid::uuid
   AND p.photo_custom_url_manual_override IS NOT TRUE;

DO $$
DECLARE
  v_n   int;
  v_bad text;
BEGIN
  -- 1. All three repointed, each URL ending in its own row's uuid.
  SELECT count(*) INTO v_n
    FROM essentials.politicians
   WHERE id IN ('e258ed0d-24fe-40a0-96d7-6ab22618aa71',
                'b943ec10-59a6-47b4-a3df-52b9747df53b',
                'c1193f7e-6891-4f59-9466-f001ac5ad49e')
     AND photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/' || id::text || '.jpg';
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'expected 3 rows repointed to their own uuid, found %', v_n;
  END IF;

  -- 2. 🔴 END STATE, NOT DELTA: every seated member of BOTH cities now renders, and none is
  --    left on the <uuid>/default.jpeg importer path that produced the county's wrong-person
  --    images. This is the assertion that closes the whole thread.
  SELECT string_agg(p.full_name || ' (' || d.geo_id || ')', '; ' ORDER BY p.full_name)
    INTO v_bad
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id IN ('0642468', '0640032')
     AND (coalesce(p.photo_custom_url, '') = ''
          OR p.photo_custom_url LIKE '%/politician_photos/' || p.id::text || '/default.jpeg');
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'expected every Lomita/La Mirada member to render off the audit prefix; still short: %', v_bad;
  END IF;

  -- 3. Ten seated members, ten distinct photos. Guards against two people sharing a file --
  --    the Hermosa Beach failure, where one portrait was offered to three different members.
  SELECT count(*) INTO v_n
    FROM (SELECT p.photo_custom_url
            FROM essentials.districts d
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_current_holder och ON och.office_id = o.id
            JOIN essentials.politicians p ON p.id = och.politician_id
           WHERE d.geo_id IN ('0642468', '0640032')
           GROUP BY p.photo_custom_url HAVING count(*) > 1) dup;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'a photo URL is shared by more than one member (% duplicate url(s))', v_n;
  END IF;

  RAISE NOTICE 'Lomita final three: Gazeley 0.82x from SBCCOG, Waite 2.17x from his own site, Segawa 3.99x below the 220px floor by operator decision; all 10 Lomita + La Mirada members now render, 10 distinct files, none left on default.jpeg';
END $$;

COMMIT;
