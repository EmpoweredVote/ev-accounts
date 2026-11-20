-- CC_0457 — essentials.county_banner_candidates and essentials.county_banner_review:
-- where the national county banner sweep keeps what it found and what the operator decided.
--
-- Plan 2 of 4 of the county banner programme.
-- Design: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
-- Plan:   docs/superpowers/plans/2026-11-20-county-banner-review-surface.md
--
-- WHY THESE TABLES EXIST. The Nebraska pass kept 73 counties of review state in an artifact's
-- own database. There are 3,222 counties, the work runs across roughly 35 working sessions, and
-- the only resource that cannot be bought more of is the operator's attention. Review state that
-- lives outside this database cannot be read by the API, cannot be joined to the geofence
-- polygons that decided county membership, and cannot survive a page that loses its session —
-- which is exactly what happened on 2026-11-19, when a crop editor's write path failed on its
-- first call and 73 counties of cropping were recovered only because the page still held them in
-- memory.
--
-- WHAT ONE ROW ASSERTS.
--   county_banner_candidates: this photograph is a usable option for this county, it is located
--     either by our own polygon or by published evidence, and here is the page we read its
--     licence and its author from.
--   county_banner_review: this county has been swept (or has not), these are the sweep's own
--     counts, and this is what the operator decided — including deciding that nothing here is
--     good enough.
--
-- 🔴 TWO RULES ARE ENFORCED BY THE SCHEMA, NOT BY THE PAGE, BECAUSE THE PAGE IS NOT THE ONLY
-- CALLER.
--   1. A KEEP NAMES A CANDIDATE AND CARRIES A CROP. status = 'keep' requires chosen_title,
--      focus and vertical_anchor, all three. `focus` is the CSS object-position string that
--      slides the 6:1 desktop band inside the 1700x540 asset; vertical_anchor is where that
--      asset was cut out of the source, which is what mobile sees. A pipeline that carries the
--      filename and drops the focus silently re-centres every banner the operator cropped, and
--      the existing county tier shows what that costs: seven county banners in the Essentials
--      repo and NOT ONE carries a focus, while the operator moved the crop off centre in 57 of
--      73 Nebraska counties.
--   2. A COUNTY THAT NEEDS ANOTHER LOOK SHIPS BLANK. status = 'needs_another_look' requires
--      chosen_title IS NULL. Standing ruling, Chris Cantrell, 2026-11-19: "those choices I would
--      rather have blank than to use the provided options." This is the rule that makes the
--      method honest — the machine is allowed to find nothing, and is not allowed to settle. A
--      CHECK is the right home for it because a later pass reading this table must not be able
--      to treat a rejected option as a weak keep.
--
-- 🔴 WHAT A CHECK CANNOT HOLD, AND WHERE IT LIVES INSTEAD. caption_sighted says the operator
-- looked at a caption-located photograph themselves and agreed it is the place. Whether that is
-- REQUIRED depends on the located_by of the candidate named by chosen_title — a different table.
-- A CHECK cannot cross tables, so the gate lives in countyBannerReviewService.recordDecision and
-- has its own test. It is recorded here because this is where someone will look for it.
--
-- 🔴 THE TWO LANES ARE COUNTED SEPARATELY AND MUST NEVER BE SUMMED. geometry_candidates was
-- established by ST_Contains against our own county polygon. caption_candidates was established
-- by a published caption plus a second independent source plus the operator's own sight. They
-- are different kinds of claim and a total of the two would describe neither. Measured
-- 2026-11-19 on Delaware: 151 of 231 swept files (65%) carry no coordinates at all, so the
-- second lane is most of the corpus rather than an edge case.
--
-- source_page_url IS A LICENCE RECORD, NOT A LINK. A raw upload.wikimedia.org URL names no
-- author and states no terms, so it cannot evidence the licence we published under. The CHECK
-- refuses one.
--
-- NOTHING IS OVERWRITTEN AND NO ROW IS DELETED: neither table exists before this file, and this
-- file inserts nothing. Both are created empty and the post-verify gates that.

CREATE TABLE IF NOT EXISTS essentials.county_banner_candidates (
  geoid                text        NOT NULL,
  commons_title        text        NOT NULL,
  rank_position        int         NOT NULL,
  frame_url            text        NOT NULL,
  source_page_url      text        NOT NULL,
  width                int         NOT NULL,
  height               int         NOT NULL,
  licence              text        NOT NULL,
  author               text        NOT NULL,
  located_by           text        NOT NULL,
  lat                  double precision,
  lon                  double precision,
  caption_text         text,
  caption_source_url   text,
  confirming_source_url text,
  place_list_available boolean,
  created_at           timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT county_banner_candidates_pkey PRIMARY KEY (geoid, commons_title),
  CONSTRAINT county_banner_candidates_located_by_check
    CHECK (located_by IN ('geometry', 'caption')),
  -- A geometry row without coordinates is a row claiming a measurement nobody took.
  CONSTRAINT county_banner_candidates_geometry_has_point
    CHECK (located_by <> 'geometry' OR (lat IS NOT NULL AND lon IS NOT NULL)),
  -- A caption row carries all three legs of its evidence or it is not a caption row.
  CONSTRAINT county_banner_candidates_caption_has_evidence
    CHECK (located_by <> 'caption' OR (
             btrim(coalesce(caption_text, ''))          <> ''
         AND btrim(coalesce(caption_source_url, ''))    <> ''
         AND btrim(coalesce(confirming_source_url, '')) <> ''
    )),
  -- Attribution is a hard gate: a banner we cannot credit is a banner we cannot show. ''::text
  -- passes NOT NULL, so NOT NULL alone would let an uncreditable file through.
  CONSTRAINT county_banner_candidates_credited
    CHECK (btrim(author) <> '' AND btrim(licence) <> ''),
  -- The licence-capture rule, made structural.
  CONSTRAINT county_banner_candidates_source_is_description_page
    CHECK (source_page_url NOT LIKE '%upload.wikimedia.org%')
);

COMMENT ON TABLE essentials.county_banner_candidates IS
  'Usable banner options per county, from the Commons sweep (plan 1). One row per '
  '(county, file). located_by says how the location was established and the two values are '
  'different kinds of claim: ''geometry'' was measured against our own G4020 polygon, '
  '''caption'' was evidenced by a published caption, a second independent source and the '
  'operator''s own sight. Never count them together.';

COMMENT ON COLUMN essentials.county_banner_candidates.source_page_url IS
  'The FILE DESCRIPTION PAGE this file was licensed from (commons.wikimedia.org/wiki/File:...), '
  'never the raw upload URL. The upload URL names no author and states no terms, so it cannot '
  'evidence the licence we published under. A CHECK refuses one.';

COMMENT ON COLUMN essentials.county_banner_candidates.frame_url IS
  'Our own stored review frame: the FULL, UNCROPPED source downscaled to about 1100px. The '
  'vertical slack outside a 3.148:1 crop is the lever the operator moves, so a pre-cropped '
  'frame would throw the decision away before it was made.';

COMMENT ON COLUMN essentials.county_banner_candidates.place_list_available IS
  'Whether our own place polygons existed for this state when the caption was judged. Measured '
  '2026-11-20: 52 states have G4020 county polygons and only 32 have G4110 place polygons — '
  'Nebraska and Delaware have none. FALSE means the caption could not be checked against our '
  'own place list, which the review page must SAY rather than quietly applying a weaker test.';

CREATE INDEX IF NOT EXISTS county_banner_candidates_geoid_rank_idx
  ON essentials.county_banner_candidates (geoid, rank_position);

CREATE TABLE IF NOT EXISTS essentials.county_banner_review (
  geoid                text        PRIMARY KEY,
  state_usps           text        NOT NULL,
  county_name          text        NOT NULL,
  status               text        NOT NULL DEFAULT 'pending',
  chosen_title         text,
  vertical_anchor      numeric,
  focus                text,
  caption_sighted      boolean     NOT NULL DEFAULT false,
  swept                boolean     NOT NULL,
  files_swept          int         NOT NULL DEFAULT 0,
  categories_found     int         NOT NULL DEFAULT 0,
  category_errors      int         NOT NULL DEFAULT 0,
  geometry_candidates  int         NOT NULL DEFAULT 0,
  caption_candidates   int         NOT NULL DEFAULT 0,
  rejected             jsonb       NOT NULL DEFAULT '{}'::jsonb,
  decided_at           timestamptz,
  decided_by           text,
  imported_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT county_banner_review_status_check
    CHECK (status IN ('pending', 'keep', 'needs_another_look')),
  -- Rule 1: a keep names a candidate and carries a crop.
  CONSTRAINT county_banner_review_keep_is_complete
    CHECK (status <> 'keep' OR (
             chosen_title    IS NOT NULL
         AND focus           IS NOT NULL
         AND vertical_anchor IS NOT NULL
    )),
  -- Rule 2: the blank ruling. A county that needs another look ships blank.
  CONSTRAINT county_banner_review_blank_ships_blank
    CHECK (status <> 'needs_another_look' OR chosen_title IS NULL),
  CONSTRAINT county_banner_review_anchor_in_range
    CHECK (vertical_anchor IS NULL OR (vertical_anchor >= 0 AND vertical_anchor <= 1)),
  -- The chosen option must exist. MATCH SIMPLE leaves a NULL chosen_title unconstrained, which
  -- is what a 'pending' row needs. ON DELETE RESTRICT means a re-import cannot delete a chosen
  -- candidate out from under a decision the operator already made.
  CONSTRAINT county_banner_review_chosen_exists
    FOREIGN KEY (geoid, chosen_title)
    REFERENCES essentials.county_banner_candidates (geoid, commons_title)
    ON DELETE RESTRICT
);

COMMENT ON TABLE essentials.county_banner_review IS
  'One row per county: the sweep''s own accounting and the operator''s decision. '
  'geometry_candidates and caption_candidates are DIFFERENT KINDS OF CLAIM and must never be '
  'summed. Two rules are CHECK-enforced because the review page is not the only caller: a '
  '''keep'' names a candidate and carries focus + vertical_anchor, and a '
  '''needs_another_look'' names none (the blank ruling, Chris Cantrell 2026-11-19). A THIRD '
  'rule is NOT here and cannot be: caption_sighted is required only when the chosen candidate '
  'is located_by=''caption'', which is a fact in another table, so a CHECK cannot see it. That '
  'gate lives in countyBannerReviewService.recordDecision with its own test.';

COMMENT ON COLUMN essentials.county_banner_review.focus IS
  'The CSS object-position string, e.g. ''50% 30%'', that slides the 6:1 desktop band within the '
  '1700x540 asset. Stored as the STRING the operator produced and copied verbatim downstream — '
  'getBuildingImages reads it, and a consumer that carries only the src re-centres the banner.';

COMMENT ON COLUMN essentials.county_banner_review.vertical_anchor IS
  'Where the 3.148:1 asset was cut out of the full source, 0 = flush to the top, 1 = flush to '
  'the bottom. Governs what MOBILE sees (13:4, 96.9% of the asset), which is the frame the '
  'desktop band cannot certify: the Aberdeen "ROAD CLOSED" sign was invisible in the band and '
  'dominant on mobile.';

COMMENT ON COLUMN essentials.county_banner_review.swept IS
  'FALSE means nobody has looked at this county yet. A county never swept and a county with no '
  'photographs produce an identical empty candidate list and only this flag separates them. A '
  'sweep that lost a category to an error leaves this FALSE as well — see category_errors.';

CREATE INDEX IF NOT EXISTS county_banner_review_state_status_idx
  ON essentials.county_banner_review (state_usps, status);

ALTER TABLE essentials.county_banner_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE essentials.county_banner_review     ENABLE ROW LEVEL SECURITY;

-- Explicit, minimal grants. The importer and the admin API both connect as ev_api, and neither
-- deletes: a candidate that stops being a candidate is replaced by the upsert, and a decision is
-- changed rather than removed.
GRANT SELECT, INSERT, UPDATE ON essentials.county_banner_candidates TO ev_api;
GRANT SELECT, INSERT, UPDATE ON essentials.county_banner_review     TO ev_api;
GRANT ALL                    ON essentials.county_banner_candidates TO service_role;
GRANT ALL                    ON essentials.county_banner_review     TO service_role;

-- 🔴 THE GRANTS ABOVE DO NOT DESCRIBE WHAT THESE ROLES ACTUALLY HOLD, AND A GRANT BLOCK THAT
-- LISTS THREE PRIVILEGES READS LIKE IT DOES. Measured on prod 2026-11-20, immediately after
-- this file first applied: ev_api already held DELETE on both tables and `anon` and
-- `authenticated` already held SELECT. They come from ALTER DEFAULT PRIVILEGES on this schema —
--   r: {anon=r/postgres, authenticated=r/postgres, ev_api=arwd/postgres}
-- — which grants them on EVERY new table in `essentials` before any migration says a word. So
-- the GRANT lines above add nothing that was not already there, and the only reason this table
-- is not world-readable is the RLS block below.
--
-- ▶ That is why this repo's rule is "enable RLS and write the policies IN THE SAME MIGRATION".
-- The rule is not belt-and-braces; on this schema it is the only belt. A new table here that
-- skips RLS is readable by `anon` the moment it exists, and nothing errors.
--
-- These REVOKEs make the grant block above true rather than decorative. They are scoped to
-- these two tables and change nothing else.
REVOKE DELETE     ON essentials.county_banner_candidates FROM ev_api;
REVOKE DELETE     ON essentials.county_banner_review     FROM ev_api;
REVOKE ALL        ON essentials.county_banner_candidates FROM anon, authenticated;
REVOKE ALL        ON essentials.county_banner_review     FROM anon, authenticated;

DROP POLICY IF EXISTS county_banner_candidates_api ON essentials.county_banner_candidates;
CREATE POLICY county_banner_candidates_api
  ON essentials.county_banner_candidates
  FOR ALL TO ev_api
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS county_banner_candidates_service ON essentials.county_banner_candidates;
CREATE POLICY county_banner_candidates_service
  ON essentials.county_banner_candidates
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS county_banner_review_api ON essentials.county_banner_review;
CREATE POLICY county_banner_review_api
  ON essentials.county_banner_review
  FOR ALL TO ev_api
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS county_banner_review_service ON essentials.county_banner_review;
CREATE POLICY county_banner_review_service
  ON essentials.county_banner_review
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- Post-verify. Gates the SHAPE this file creates, not a total another session can move.
DO $$
DECLARE
  v_tables     int;
  v_cand_rls   boolean;
  v_rev_rls    boolean;
  v_cand_pol   int;
  v_rev_pol    int;
  v_cand_check int;
  v_rev_check  int;
  v_cand_rows  bigint;
  v_rev_rows   bigint;
BEGIN
  SELECT count(*) INTO v_tables
    FROM information_schema.tables
   WHERE table_schema = 'essentials'
     AND table_name IN ('county_banner_candidates', 'county_banner_review');
  IF v_tables <> 2 THEN
    RAISE EXCEPTION 'CC_0457: expected 2 tables, found %', v_tables;
  END IF;

  SELECT relrowsecurity INTO v_cand_rls FROM pg_class t
    JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname = 'essentials' AND t.relname = 'county_banner_candidates';
  SELECT relrowsecurity INTO v_rev_rls FROM pg_class t
    JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname = 'essentials' AND t.relname = 'county_banner_review';
  IF NOT v_cand_rls OR NOT v_rev_rls THEN
    RAISE EXCEPTION 'CC_0457: RLS is off (candidates=%, review=%)', v_cand_rls, v_rev_rls;
  END IF;

  SELECT count(*) INTO v_cand_pol FROM pg_policies
   WHERE schemaname = 'essentials' AND tablename = 'county_banner_candidates';
  SELECT count(*) INTO v_rev_pol FROM pg_policies
   WHERE schemaname = 'essentials' AND tablename = 'county_banner_review';
  IF v_cand_pol < 2 OR v_rev_pol < 2 THEN
    RAISE EXCEPTION 'CC_0457: expected 2 policies each, found candidates=%, review=%',
      v_cand_pol, v_rev_pol;
  END IF;

  SELECT count(*) INTO v_cand_check
    FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname = 'essentials' AND t.relname = 'county_banner_candidates'
     AND c.contype = 'c';
  IF v_cand_check < 5 THEN
    RAISE EXCEPTION 'CC_0457: expected at least 5 CHECKs on candidates, found %', v_cand_check;
  END IF;

  SELECT count(*) INTO v_rev_check
    FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
   WHERE n.nspname = 'essentials' AND t.relname = 'county_banner_review'
     AND c.contype = 'c';
  IF v_rev_check < 4 THEN
    RAISE EXCEPTION 'CC_0457: expected at least 4 CHECKs on review, found %', v_rev_check;
  END IF;

  -- This file inserts nothing. A non-empty table here means it was not what it claimed to be.
  SELECT count(*) INTO v_cand_rows FROM essentials.county_banner_candidates;
  SELECT count(*) INTO v_rev_rows  FROM essentials.county_banner_review;
  IF v_cand_rows <> 0 OR v_rev_rows <> 0 THEN
    RAISE EXCEPTION 'CC_0457: expected both tables empty, found candidates=%, review=%',
      v_cand_rows, v_rev_rows;
  END IF;

  RAISE NOTICE 'CC_0457 OK: 2 tables, RLS on both, % + % policies, % + % CHECKs, 0 rows',
    v_cand_pol, v_rev_pol, v_cand_check, v_rev_check;
END $$;
