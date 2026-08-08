-- 1620_politicians_prefer_hosted_portrait.sql
--
-- Point politicians.photo_custom_url at the portrait we already host, wherever one exists and
-- the column is empty. 4,991 rows expected, 3,593 of them currently-seated officeholders.
--
-- WHY
--
-- Image resolution prefers photo_custom_url, then the source URL, and only then the images
-- table -- `COALESCE(photo_custom_url, photo_origin_url, '')` in this API and
-- `photo_origin_url || images[0].url` in ev-ui. Two consequences, both live today:
--
--   * 3,360 politicians have a source URL in photo_origin_url that beats the portrait we mirrored
--     into our own bucket. We hotlink somebody else's page instead of serving the cropped image
--     we already produced and pay to store.
--   * 1,631 have no photo_origin_url at all. Several API paths never consult politician_images,
--     so those endpoints return an empty photo string even though a portrait exists.
--
-- This is not a new diagnosis. Migration 1475 Part B fixed exactly this for 48 Wisconsin
-- profiles; the repair was applied to Wisconsin rather than to the class, and the rest of the
-- country was never swept. This migration does the class.
--
-- SAFETY
--
--   * Only fills photo_custom_url where it IS NULL. An existing value is never overwritten.
--   * Skips photo_custom_url_manual_override rows (migration 192 / D-08) -- a human chose those.
--   * Chooses one image deterministically: type='default' first, then lowest id. politician_images
--     carries no timestamp, so id is the only stable tiebreak. 200 politicians hold more than one
--     image and the extras are 'thumb'.
--   * Accepts BOTH bucket URL forms. `<ref>.storage.supabase.co/...` and
--     `<ref>.supabase.co/storage/v1/...` address the same storage; a predicate matching only the
--     first silently misses 1,631 of 5,723 hosted images.
--
-- Idempotent: the gate asserts an END STATE, so a second run updates nothing and still passes.

BEGIN;

-- One hosted portrait per politician, chosen deterministically.
CREATE TEMP TABLE _best_portrait ON COMMIT DROP AS
SELECT DISTINCT ON (pi.politician_id)
       pi.politician_id,
       pi.url
  FROM essentials.politician_images pi
 WHERE pi.url ~* '^https://[a-z0-9]+\.(storage\.supabase\.co|supabase\.co/storage/v1)/'
 ORDER BY pi.politician_id, (pi.type = 'default') DESC, pi.id;

CREATE UNIQUE INDEX ON _best_portrait (politician_id);

-- Pre-state, so the gate can prove nothing outside the intended set moved.
CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT p.id,
       p.photo_custom_url,
       coalesce(p.photo_custom_url_manual_override, false) AS manual_override
  FROM essentials.politicians p;

UPDATE essentials.politicians p
   SET photo_custom_url = b.url
  FROM _best_portrait b
 WHERE p.id = b.politician_id
   AND p.photo_custom_url IS NULL
   AND coalesce(p.photo_custom_url_manual_override, false) = false;

DO $$
DECLARE
  v_changed    integer;
  v_remaining  integer;
  v_clobbered  integer;
  v_override   integer;
  v_mismatch   integer;
BEGIN
  -- How many rows this run actually filled (0 on a re-run -- that is success, not failure).
  SELECT count(*) INTO v_changed
    FROM essentials.politicians p
    JOIN _before bf ON bf.id = p.id
   WHERE bf.photo_custom_url IS NULL
     AND p.photo_custom_url IS NOT NULL;

  -- END STATE: nothing eligible may be left unfilled.
  SELECT count(*) INTO v_remaining
    FROM essentials.politicians p
    JOIN _best_portrait b ON b.politician_id = p.id
   WHERE p.photo_custom_url IS NULL
     AND coalesce(p.photo_custom_url_manual_override, false) = false;
  IF v_remaining <> 0 THEN
    RAISE EXCEPTION '1620: % eligible politicians still have no photo_custom_url', v_remaining;
  END IF;

  -- An existing custom URL must never have been overwritten.
  SELECT count(*) INTO v_clobbered
    FROM essentials.politicians p
    JOIN _before bf ON bf.id = p.id
   WHERE bf.photo_custom_url IS NOT NULL
     AND p.photo_custom_url IS DISTINCT FROM bf.photo_custom_url;
  IF v_clobbered <> 0 THEN
    RAISE EXCEPTION '1620: % rows had an existing photo_custom_url overwritten', v_clobbered;
  END IF;

  -- A human-set override must never have been touched.
  SELECT count(*) INTO v_override
    FROM essentials.politicians p
    JOIN _before bf ON bf.id = p.id
   WHERE bf.manual_override
     AND p.photo_custom_url IS DISTINCT FROM bf.photo_custom_url;
  IF v_override <> 0 THEN
    RAISE EXCEPTION '1620: % manual-override rows were modified', v_override;
  END IF;

  -- Everything we filled must equal the chosen portrait, and therefore be a bucket URL.
  SELECT count(*) INTO v_mismatch
    FROM essentials.politicians p
    JOIN _before bf        ON bf.id = p.id
    JOIN _best_portrait b  ON b.politician_id = p.id
   WHERE bf.photo_custom_url IS NULL
     AND p.photo_custom_url IS DISTINCT FROM b.url;
  IF v_mismatch <> 0 THEN
    RAISE EXCEPTION '1620: % filled rows do not match the chosen portrait', v_mismatch;
  END IF;

  RAISE NOTICE '1620 OK: % rows filled, 0 remaining, 0 clobbered, 0 overrides touched',
    v_changed;
END $$;

COMMIT;
