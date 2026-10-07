-- CC_0197 — recrop the Hochman, Connolly and Gaspar headshots (LA replenish, batch 2)
--
-- WHY. Second batch off .planning/todos/2026-10-07-la-headshot-replenish.md. All three rendered a
-- face too small to read: full-body or three-quarter-body frames where the head was 10-42% of the
-- picture instead of the 20-62% the house bar asks for.
--
--   Nathan Hochman   — District Attorney, LA County. Full-body official portrait between the flags
--                      and the county seal, head ~10% of frame. 1069x1200 -> 630x788, head 40.0%,
--                      eye line 30.5%. The SAME photograph: da.lacounty.gov's own file is also
--                      1069x1200 (checked at the origin), so there was nothing larger to fetch and
--                      this is a pure crop. photo_origin_url moves from the bio PAGE to the image
--                      file itself, which is what provenance should name.
--
--   Patrick Connolly — Judge, LA Superior Court. A DIFFERENT photograph, not a recrop: the live one
--                      was a three-quarter-body suit shot against a blurred skyline, 588x554 and
--                      nearly square, taken from LAist's judges voter guide. His campaign site
--                      publishes a judicial-robe studio portrait at 1080x1080 which crops to
--                      736x920, head 42.4%, eye line 28.8%. Operator compared the two faces on the
--                      proof sheet and approved the switch. ⚠ Identity rests on it being the single
--                      hero image of a single-candidate site (reelectjudgepatconnolly.com, titled
--                      "Re-Elect Judge Pat Connolly"); the file's alt text is only the filename,
--                      DSC_2550_pp.png, which is the opaque kind that hides an off-by-one. A second
--                      copy of the same shot sits there at 2000x1252 with far more empty backdrop.
--
--   Timothy Gaspar   — candidate, LA City Council District 3. Half-body with large out-of-focus
--                      signage behind him. 1011x1404 -> 840x1050, head 50.5%, eye line 26.7%. Pure
--                      crop of the file we already held; timgaspar.com publishes no better portrait
--                      (its only other picture of him is a transparent-background cut-out).
--
-- 🔴 WRITES BOTH FIELDS, which is the lesson CC_0196 paid for. The essentials browse grid
-- (PoliticianGrid.getImageData) reads the politician_images array FIRST and falls back to
-- politicians.photo_custom_url only when that array is empty; the backend read paths do the
-- reverse. Repointing one alone changes the API or the page, never both. The gate below requires
-- the pair to agree for every row.
--
-- No resampling: every output is a crop at native size, nothing enlarged. All three pass the
-- no-monochrome gate (chroma 20.9 / 14.8 / 44.7 — Connolly's is low because a black robe on a grey
-- seamless is a low-colour composition, not a greyscale file). Objects uploaded and read back
-- byte-identical before this ran.
--
-- photo_license is left as 'press_use' for Hochman and Gaspar: the underlying photograph is
-- unchanged, only the crop. Connolly's changes, because his photograph changes.
--
-- Rollback is one UPDATE per person; all old objects are still in the bucket:
--   Hochman  custom https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/83474f06-c501-416d-a870-65d75f0cec9d-headshot.jpg
--            origin https://da.lacounty.gov/about/meet-the-da                      licence press_use
--   Connolly custom https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/53fd1ed7-b8f2-4c0b-a973-3592e4457472-headshot.jpg
--            origin https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-county-judges   licence press_use
--   Gaspar   custom https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4632aaf1-6667-4e41-9763-c8b56ca7e702-headshot.jpg
--            origin https://timgaspar.com/                                         licence press_use
--
-- Idempotent: every UPDATE is guarded on the value it writes.

BEGIN;

-- ---------------------------------------------------------------- scalars
UPDATE essentials.politicians p
   SET photo_custom_url = v.new_url,
       photo_origin_url = v.new_origin,
       last_update_date = now()
  FROM (VALUES
    ('83474f06-c501-416d-a870-65d75f0cec9d'::uuid, 'Nathan Hochman',
     'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/83474f06-c501-416d-a870-65d75f0cec9d.jpg',
     'https://da.lacounty.gov/sites/default/files/pictures/DA-Hochman-Official.jpg'),
    ('53fd1ed7-b8f2-4c0b-a973-3592e4457472'::uuid, 'Patrick Connolly',
     'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/53fd1ed7-b8f2-4c0b-a973-3592e4457472.jpg',
     'https://images.squarespace-cdn.com/content/v1/699913920a2a9b56bfeab847/717ba75d-e9ec-4682-b307-8a43c53fb0bb/DSC_2550_pp.png'),
    ('4632aaf1-6667-4e41-9763-c8b56ca7e702'::uuid, 'Timothy Gaspar',
     'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/4632aaf1-6667-4e41-9763-c8b56ca7e702.jpg',
     'https://timgaspar.com/')
  ) AS v(id, who, new_url, new_origin)
 WHERE p.id = v.id
   AND p.full_name = v.who
   AND p.photo_custom_url IS DISTINCT FROM v.new_url;

-- ------------------------------------------------- the rows the GRID reads
UPDATE essentials.politician_images i
   SET url = v.new_url,
       photo_license = v.new_licence
  FROM (VALUES
    ('83474f06-c501-416d-a870-65d75f0cec9d'::uuid,
     'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/83474f06-c501-416d-a870-65d75f0cec9d.jpg',
     'press_use'),
    ('53fd1ed7-b8f2-4c0b-a973-3592e4457472'::uuid,
     'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/53fd1ed7-b8f2-4c0b-a973-3592e4457472.jpg',
     'Campaign portrait published by reelectjudgepatconnolly.com ("Re-Elect Judge Pat Connolly"), the site''s hero image. The site publishes no use policy.'),
    ('4632aaf1-6667-4e41-9763-c8b56ca7e702'::uuid,
     'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/4632aaf1-6667-4e41-9763-c8b56ca7e702.jpg',
     'press_use')
  ) AS v(id, new_url, new_licence)
 WHERE i.politician_id = v.id
   AND i.type = 'default'
   AND i.url IS DISTINCT FROM v.new_url;

DO $$
DECLARE
  r          record;
  v_expected text;
  v_seen     int := 0;
BEGIN
  FOR r IN
    SELECT p.id, p.full_name, p.photo_custom_url, p.photo_origin_url,
           coalesce(p.photo_custom_url_manual_override, false) AS override,
           (SELECT count(*) FROM essentials.politician_images i
             WHERE i.politician_id = p.id AND i.type = 'default')         AS n_default,
           (SELECT i.url FROM essentials.politician_images i
             WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1) AS default_url
      FROM essentials.politicians p
     WHERE p.id IN ('83474f06-c501-416d-a870-65d75f0cec9d',
                    '53fd1ed7-b8f2-4c0b-a973-3592e4457472',
                    '4632aaf1-6667-4e41-9763-c8b56ca7e702')
  LOOP
    v_seen := v_seen + 1;

    v_expected := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                  || 'politician_photos/la_city/2026-10-replenish/' || r.id || '.jpg';

    IF r.override THEN
      RAISE EXCEPTION 'CC_0197: % (%) carries photo_custom_url_manual_override — refusing to claim it',
        r.full_name, r.id;
    END IF;

    IF r.n_default <> 1 THEN
      RAISE EXCEPTION 'CC_0197: % (%) has % rows of type=default, expected exactly 1',
        r.full_name, r.id, r.n_default;
    END IF;

    IF r.photo_custom_url IS DISTINCT FROM v_expected THEN
      RAISE EXCEPTION 'CC_0197: % (%) has photo_custom_url %, expected %',
        r.full_name, r.id, coalesce(r.photo_custom_url, '<null>'), v_expected;
    END IF;

    -- 🔴 The grid reads the images row, the backend reads the scalar. Disagreement means the
    -- voter and the API are looking at different photographs. This is the CC_0196 lesson.
    IF r.default_url IS DISTINCT FROM r.photo_custom_url THEN
      RAISE EXCEPTION 'CC_0197: % (%) renders % in the grid but % through the API — they must agree',
        r.full_name, r.id, coalesce(r.default_url, '<null>'), coalesce(r.photo_custom_url, '<null>');
    END IF;

    -- Provenance must name a real source, never our own CDN: photo_origin_url answers
    -- "where did this come from", and pointing it at storage erases that answer.
    IF r.photo_origin_url IS NULL
       OR r.photo_origin_url LIKE '%kxsdzaojfaibhuzmclfq%' THEN
      RAISE EXCEPTION 'CC_0197: % (%) has photo_origin_url %, expected an external source',
        r.full_name, r.id, coalesce(r.photo_origin_url, '<null>');
    END IF;
  END LOOP;

  IF v_seen <> 3 THEN
    RAISE EXCEPTION 'CC_0197: matched % of the 3 expected politician rows', v_seen;
  END IF;

  RAISE NOTICE 'CC_0197: Hochman, Connolly and Gaspar repointed; grid and API agree for all three';
END $$;

COMMIT;
