BEGIN;

-- =============================================================================
-- CC_0042: repaint the Education Lens pink
-- =============================================================================
-- Created 2026-09-01 with Chris Cantrell. Chris's call: the Education Lens is
-- pink. It was seeded '#7A4FA3', a purple.
--
-- WHY THIS COLOUR. The active lens chip paints the lens colour as a BACKGROUND
-- under white text (CombinedPage -> LensSwitcher), so contrast against white is
-- the constraint that matters, and the floor is WCAG AA for normal text (4.5:1 —
-- chips are 12px bold, which does not qualify as "large"). Measured:
--
--     local     #5A9A6E   3.34 : 1  vs white
--     federal   #1E3A5F  11.50 : 1
--     judicial  #C2440A   5.09 : 1
--     education #7A4FA3   6.04 : 1   (the purple being replaced)
--     education #C2185B   5.87 : 1   <-- this
--
-- #C2185B passes AA on white, lands between judicial and the old purple so the
-- switcher row stays visually even, and is hue-separated from judicial's burnt
-- orange (#C2440A) so the two chips never read as the same colour at a glance.
--
-- The dark theme needs no value here: src/lib/lensColors.js lightens any lens
-- colour that fails contrast against the dark page background (#131416) at read
-- time. It was written as a function precisely so a future DB row would be
-- handled without a code change — federal sits at 1.60:1 raw and is corrected
-- the same way. #C2185B is 3.14:1 raw and gets the same treatment.
--
-- SCOPE: one column on one row. No topic membership, no auto_district_types, no
-- is_active change. The lens already holds the right eight topics in the right
-- order and already auto-applies on SCHOOL and STATE_BOARD_EDUCATION.
--
-- ⚠ THE LENS STAYS INVISIBLE UNTIL SEASON 2 OPENS, AND THAT IS DELIBERATE. All
-- eight of its topics are Season-2-only, so under the open Season 1 they are not
-- in the promoted set. Every consumer filters lens topics against the loaded
-- topics — resolveCalibrateLens returns null, the switcher drops the chip — so
-- the lens appears on its own when the season opens. There is no flag to flip
-- and nothing to remember.
-- =============================================================================

UPDATE inform.compass_lenses
   SET color = '#C2185B'
 WHERE key = 'education';

DO $$
DECLARE
  v_color text;
  v_topics int;
BEGIN
  SELECT l.color, count(lt.topic_id)
    INTO v_color, v_topics
    FROM inform.compass_lenses l
    LEFT JOIN inform.compass_lens_topics lt ON lt.lens_id = l.id
   WHERE l.key = 'education'
   GROUP BY l.color;

  IF v_color IS NULL THEN
    RAISE EXCEPTION 'CC_0042: no lens with key=education — nothing was repainted';
  END IF;
  IF v_color <> '#C2185B' THEN
    RAISE EXCEPTION 'CC_0042: education lens colour is %, expected #C2185B', v_color;
  END IF;
  -- Guards the blast radius: this migration must not have touched membership.
  IF v_topics <> 8 THEN
    RAISE EXCEPTION 'CC_0042: education lens holds % topics, expected 8', v_topics;
  END IF;

  RAISE NOTICE 'CC_0042 OK: education lens is #C2185B and still holds 8 topics.';
END $$;

COMMIT;
