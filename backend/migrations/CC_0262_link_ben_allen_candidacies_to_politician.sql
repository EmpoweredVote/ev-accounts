-- CC_0262_link_ben_allen_candidacies_to_politician.sql
--
-- Links BOTH Ben Allen candidacy rows to the politician row that is the same man, and lets
-- his real headshot through to the ballot pages.
--
--   7e051229-78ac-4d73-842c-a570c108b4a5  Ben Allen  2026 LA County Primary  (result 'advanced')
--   5b8e2394-e438-48d2-875d-d54bd9319f3f  Ben Allen  CA 2026 Statewide General (2026-11-03)
--     -> politician 4486f856-118b-475c-83f0-078581a7b268  "Benjamin Allen"
--
-- 🔴 THE EVIDENCE IS A DOCUMENT, NOT A NAME AND A FACE. CC_0261 deliberately refused to make
-- this link on the strength of "visibly the same man plus a press summary". It is made here
-- because the California Secretary of State says so in her own certified notices:
--
--   * Notice to Candidates, Insurance Commissioner, June 2 2026 Primary (Shirley N. Weber,
--     21 March 2026, elections.cdn.sos.ca.gov/statewide-elections/2026-primary/insurance.pdf)
--     lists "Ben Allen - Democratic", website www.benallenca.com, and gives his BALLOT
--     DESIGNATION -- the candidate's own sworn statement of occupation -- as
--     "California State Senator".
--   * Our politician row holds exactly that seat: Senator, California State Senate District
--     24, office_terms open since 2022-12-05.
--   * The general-election row was already sourced from the SOS Official Certified List of
--     Candidates of 8/27/2026, the document that records who advanced.
--
-- So the link rests on the office, stated by the candidate under penalty of perjury and
-- published by the state, matching the office we independently record him holding. The
-- photograph agrees, but the photograph is not the evidence.
--
-- ⚠ EXACTLY ONE CANDIDATE FOR THE LINK. There is ONE politician row whose name is Ben or
-- Benjamin Allen (same_name_rows = 1), and it held NO race_candidates rows before this, so
-- nothing fans out and no second person can be displaced. Asserted in the guard below.
--
-- ▶ WHAT THIS CHANGES BEYOND A PICTURE, STATED PLAINLY BECAUSE IT IS THE POINT OF THE CAUTION:
-- Benjamin Allen carries 13 researched compass answers (12 in closed Season 1, 1 in open
-- Season 2 -- both PUBLISHED, neither draft). Linking does not create or alter a single one,
-- but it does make them reachable from the Insurance Commissioner race rather than only from
-- his profile. That is correct -- he is that candidate, and a voter looking at that race
-- should see what he holds -- and it is exactly the consequence that made CC_0261 stop and
-- ask for a document first.
-- It also leaves politicians.is_incumbent = true (he holds SD-24, which is a fact about that
-- seat) while race_candidates.is_incumbent stays FALSE on both rows (he is not the sitting
-- Insurance Commissioner). Those two flags answer different questions and both are already
-- right; neither is touched.
--
-- 🔴 AND IT GIVES HIM A BETTER PICTURE ON BOTH PAGES. electionService selects
-- COALESCE(rc.photo_url, pi.url). The general row had NO photo at all, so linking alone gives
-- it his 600x750 public-domain headshot through the lateral join. The primary row holds the
-- 200x300 Ballotpedia thumbnail CC_0261 mirrored, which would WIN over the better image -- so
-- this NULLs it and lets the COALESCE fall through. That is the "null it and let it fall
-- through" option CC_0259's footer argued about, applied in the one case where it is
-- unambiguous: we hold a better photograph OF THE SAME PERSON.
-- ⚠ ca/candidates/7e051229-...jpg is then unreferenced. It is LEFT IN PLACE: deleting storage
-- is irreversible, the object is harmless, and if this link is ever reverted it is wanted again.
--
-- ▶ NOT DONE HERE: race_candidates.occupational_designation is NULL on both rows while the SOS
-- notice gives "California State Senator". Populating ballot designations is a separate pass
-- over every candidate, not a one-row exception.
-- ▶ Jane Kim, the other November candidate, is likewise unlinked. No politician row was looked
-- for; that is its own sourcing job.
--
-- Idempotent: re-running changes nothing.

BEGIN;

-- Guard: the politician must be the one this migration researched, must still hold exactly one
-- default image, and must be the ONLY Ben/Benjamin Allen. Each candidacy row must be an
-- unlinked (or already-correctly-linked) 'Ben Allen'. Anything else REFUSES.
DO $$
DECLARE v_name text; v_active bool; v_images int; v_namesakes int; r record;
        v_rc_name text; v_rc_pol uuid;
BEGIN
  SELECT p.full_name, p.is_active,
         (SELECT count(*) FROM essentials.politician_images pi
           WHERE pi.politician_id = p.id AND pi.type = 'default')
    INTO v_name, v_active, v_images
    FROM essentials.politicians p
   WHERE p.id = '4486f856-118b-475c-83f0-078581a7b268'::uuid;

  IF v_name IS NULL THEN
    RAISE EXCEPTION 'CC_0262: the politician row does not exist';
  END IF;
  IF v_name <> 'Benjamin Allen' THEN
    RAISE EXCEPTION 'CC_0262: politician resolves to "%", expected "Benjamin Allen"', v_name;
  END IF;
  IF NOT v_active THEN
    RAISE EXCEPTION 'CC_0262: Benjamin Allen is not active - refusing to link a candidacy to him';
  END IF;
  IF v_images <> 1 THEN
    RAISE EXCEPTION 'CC_0262: Benjamin Allen has % default images, expected 1 - the ballot '
                    'pages would inherit an ambiguous photo', v_images;
  END IF;

  -- The wrong-person guard: if a second Ben/Benjamin Allen has appeared, the name no longer
  -- identifies anyone and this migration's reasoning no longer holds.
  SELECT count(*) INTO v_namesakes FROM essentials.politicians p
   WHERE (p.first_name ILIKE 'Ben%' AND p.last_name ILIKE 'Allen')
      OR p.full_name IN ('Ben Allen', 'Benjamin Allen');
  IF v_namesakes <> 1 THEN
    RAISE EXCEPTION 'CC_0262: % politician rows now match Ben/Benjamin Allen, expected 1 - '
                    'the link is no longer unambiguous, REFUSING', v_namesakes;
  END IF;

  FOR r IN SELECT unnest(ARRAY['7e051229-78ac-4d73-842c-a570c108b4a5',
                               '5b8e2394-e438-48d2-875d-d54bd9319f3f']::uuid[]) AS rc_id LOOP
    SELECT rc.full_name, rc.politician_id INTO v_rc_name, v_rc_pol
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v_rc_name IS NULL THEN
      RAISE EXCEPTION 'CC_0262: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_rc_name <> 'Ben Allen' THEN
      RAISE EXCEPTION 'CC_0262: row % is "%", expected "Ben Allen"', r.rc_id, v_rc_name;
    END IF;
    IF v_rc_pol IS NOT NULL
       AND v_rc_pol <> '4486f856-118b-475c-83f0-078581a7b268'::uuid THEN
      RAISE EXCEPTION 'CC_0262: row % is already linked to %, REFUSING to repoint it',
        r.rc_id, v_rc_pol;
    END IF;
  END LOOP;
END $$;

-- 1. the link itself
UPDATE essentials.race_candidates rc
SET politician_id = '4486f856-118b-475c-83f0-078581a7b268'::uuid
WHERE rc.id IN ('7e051229-78ac-4d73-842c-a570c108b4a5'::uuid,
                '5b8e2394-e438-48d2-875d-d54bd9319f3f'::uuid)
  AND rc.politician_id IS DISTINCT FROM '4486f856-118b-475c-83f0-078581a7b268'::uuid;

-- 2. let the better photograph through: COALESCE(rc.photo_url, pi.url) must reach pi.url
UPDATE essentials.race_candidates rc
SET photo_url = NULL
WHERE rc.id = '7e051229-78ac-4d73-842c-a570c108b4a5'::uuid
  AND rc.photo_url IS NOT NULL;

-- post-verify: both rows linked, both now RENDER his 600x750, and nothing else moved.
DO $$
DECLARE n_linked int; n_render int; n_images int; n_offsite int; n_other int;
BEGIN
  SELECT count(*) INTO n_linked FROM essentials.race_candidates rc
   WHERE rc.id IN ('7e051229-78ac-4d73-842c-a570c108b4a5'::uuid,
                   '5b8e2394-e438-48d2-875d-d54bd9319f3f'::uuid)
     AND rc.politician_id = '4486f856-118b-475c-83f0-078581a7b268'::uuid;
  IF n_linked <> 2 THEN
    RAISE EXCEPTION 'CC_0262: expected 2 linked candidacy rows, found %', n_linked;
  END IF;

  -- what the page will actually serve, computed the way electionService computes it
  SELECT count(*) INTO n_render
    FROM essentials.race_candidates rc
    LEFT JOIN LATERAL (
      SELECT pi.url FROM essentials.politician_images pi
       WHERE pi.politician_id = rc.politician_id AND pi.type = 'default' LIMIT 1
    ) pi ON rc.politician_id IS NOT NULL
   WHERE rc.id IN ('7e051229-78ac-4d73-842c-a570c108b4a5'::uuid,
                   '5b8e2394-e438-48d2-875d-d54bd9319f3f'::uuid)
     AND COALESCE(rc.photo_url, pi.url) =
         'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/4486f856-118b-475c-83f0-078581a7b268-headshot.jpg';
  IF n_render <> 2 THEN
    RAISE EXCEPTION 'CC_0262: expected both ballot pages to serve his headshot, found %', n_render;
  END IF;

  -- he must still have exactly one default image, and no OTHER politician may own these rows
  SELECT count(*) INTO n_images FROM essentials.politician_images pi
   WHERE pi.politician_id = '4486f856-118b-475c-83f0-078581a7b268'::uuid AND pi.type = 'default';
  IF n_images <> 1 THEN
    RAISE EXCEPTION 'CC_0262: Benjamin Allen now has % default images', n_images;
  END IF;

  SELECT count(*) INTO n_other FROM essentials.race_candidates rc
   WHERE rc.politician_id = '4486f856-118b-475c-83f0-078581a7b268'::uuid
     AND rc.id NOT IN ('7e051229-78ac-4d73-842c-a570c108b4a5'::uuid,
                       '5b8e2394-e438-48d2-875d-d54bd9319f3f'::uuid);
  IF n_other <> 0 THEN
    RAISE EXCEPTION 'CC_0262: % unexpected candidacy row(s) now point at him', n_other;
  END IF;

  -- and CC_0261's property still holds: nothing we publish renders off-site
  SELECT count(*) INTO n_offsite
    FROM essentials.race_candidates rc
   WHERE NULLIF(rc.photo_url, '') IS NOT NULL
     AND rc.result IS DISTINCT FROM 'not_nominated'
     AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0262: % live ballot row(s) render off-site', n_offsite;
  END IF;

  RAISE NOTICE 'CC_0262 OK - both Ben Allen candidacies linked; both ballot pages serve his headshot';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: A PHOTOGRAPH AND A NAME ARE NOT EVIDENCE OF IDENTITY. A BALLOT DESIGNATION IS.
-- CC_0261 had the face, the name and a press summary and was right to refuse. What settled it
-- was the candidate's own sworn occupation on a state-published certified list -- "California
-- State Senator" -- matching the seat we independently record him holding. When linking a
-- candidacy to a person, look for the field where the CANDIDATE states who they are.
-- ⚠ AND SAY WHAT ELSE THE LINK CARRIES. This one moved 13 published compass answers into view
-- on a live November race. That was the right outcome and it was still the thing to check
-- before writing, not after.
-- ───────────────────────────────────────────────────────────────────────────────────────────
