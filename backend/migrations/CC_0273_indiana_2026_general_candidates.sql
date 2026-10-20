-- CC_0273_indiana_2026_general_candidates.sql
--
-- Indiana 2026 General. All 13 unlinked rows are Monroe County township and town races.
-- The handoff flagged Indiana as the odd cohort -- 10 variant hits against 13 live candidates --
-- and said to work it BY HAND as a linking job rather than a creation sweep. That was right:
-- 8 of the 13 already exist.
--
--   LINK    8   CREATE  4   LEAVE UNLINKED  1
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ TIER 1 -- THE MATCHED PERSON HOLDS THE VERY SEAT SOUGHT ═══
-- The strongest office evidence available: not a district that contains the seat, THE SEAT.
--
--   Victoria Streiff -> "Vic Streiff" (5fbd1c3f) -- holds **Monroe County: Polk Township Board**,
--     is_incumbent true, source 'ballotready'. She seeks **Polk Township Board**. Vic/Victoria is
--     the diminutive this programme nearly lost Tom Umberg to, caught here by the explicit list.
--
-- ═══ TIER 2 -- EXACT OR NEAR-EXACT NAME ON A BARE ROW, SAME COUNTY ═══
-- Seven rows. Every existing row is BARE: no office, no term, no candidacy, no answers, no image,
-- source NULL, all created 2026-05-22 in the same bulk import as the rest of Monroe County.
-- Linking a bare row cannot misattribute anything, and creating a second row would be the
-- duplicate the house rule forbids. This is the weakest tier that is still worth doing, exactly
-- as in CC_0271 tier E.
--     Ashlie Kehrberg     -> 134ab481  (exact)
--     Elaine Thomsen      -> 7a19913a  (exact)
--     Joann Calabrese     -> 6bd9abf1  (exact)
--     Kat Reynolds        -> 0a6552a5  (exact)
--     Susan Hingle        -> 82c4e1f8  (exact)
--     Dustin Cole Dillard -> 2abb4229  "Dustin Dillard"  (middle name dropped)
--     Sharon A. Green     -> 8d947641  "Sharon Green"    (middle initial dropped)
--
-- 🔴 THREE OF THEM HAVE AN ARCHIVED TWIN AND IT IS LEFT ALONE. Kehrberg (55d5a2fd), Dillard
-- (cbab6044) and Calabrese (f28debd0) each have a second row with the SAME name and
-- is_active=false. Every link below targets the ACTIVE row; the guard refuses an archived target
-- outright. Linking to an archived row would resurrect someone deliberately retired.
--
-- ═══ 🔴 ONE LEFT UNLINKED, AND IT IS THE INTERESTING ONE ═══
--   WILLIAM E. SMITH III -- Van Buren Township Board -- NOT LINKED, NOT CREATED.
-- The match looks like the best in the cohort: "William E Smith" (fe15ab1f) holds **Monroe
-- County: Van Buren Township Board**, is_incumbent true, source 'ballotready', and carries an
-- IMAGE. Same board, exact seat. By tier 1 it should link.
-- ⚠ IT IS REFUSED BECAUSE OF THE SUFFIX. "III" is not a rendering difference like the accent on
-- Rascón or the missing full stop on Herb W Morgan -- a generational suffix exists precisely to
-- distinguish a father from a son, so dropping it is not a spelling variant, it is a different
-- claim. Two readings fit: the roster dropped the suffix from the incumbent, or the son is
-- standing for the seat his father holds.
-- 🔴 AND THERE IS A SECOND ACTIVE NAMESAKE: "William (will) E. Smith" (affd5337), bare. Three
-- rows, one name, and nothing says which is the candidate.
-- ▶ Because the incumbent row carries an image, a wrong link publishes a wrong FACE on a ballot
-- page -- the defect class this whole programme exists to remove. Unlinked is the honest state.
-- ▶ WHAT WOULD SETTLE IT: the Monroe County certified candidate list, which prints suffixes, or
-- the Van Buren Township Board roster naming its current member with or without the III.
--
-- ═══ CREATED -- 4 ═══
--   Andrew Henry     Ellettsville Town Council Ward 4   -- no match at all
--   Marv Ulmet       Ellettsville Town Council Ward 5   -- no match at all
--   Steven E. Webb   Clear Creek Township Board         -- no match at all
--   R. Shannon Reed  Clear Creek Township Board         -- matched only "R. Reed", a bare row
--     whose first name is an INITIAL. An initial-only first name matches every first name
--     beginning with that letter -- the same false-positive shape that paired Andrea Lee Anderson
--     with "A. Dane Anderson" in CC_0268. Not evidence. He gets his own row; the names differ, so
--     nothing collides.
--
-- ▶ WHAT THIS CARRIES: nothing but connections. Not one of the 8 linked rows has an image or a
-- compass answer, and every candidacy row has photo_url NULL. No photograph appears and no stance
-- moves into view. Indiana's value here is that 8 duplicate people were NOT created.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _link (rc_id uuid PRIMARY KEY, cand text NOT NULL, pol_id uuid NOT NULL) ON COMMIT DROP;
INSERT INTO _link VALUES
 ('d1c67151-beb0-4cc6-8161-943453b7f1f8','Victoria Streiff',   '5fbd1c3f-46f2-4532-89d0-ac971c60c1c8'),
 ('93b53e23-899d-4de2-9573-a9b79eee3ed4','Ashlie Kehrberg',    '134ab481-bae4-4cbe-a3f2-2e4d2fbccd6c'),
 ('f1bbd4c8-0ad6-4f37-9bdf-f24be1f77a33','Elaine Thomsen',     '7a19913a-7a83-4eb2-b53c-dc83f28f4f25'),
 ('959b9b45-10e8-4332-9a4f-88d6d4f3a513','Joann Calabrese',    '6bd9abf1-de73-4de7-bf47-9ad7ccde63eb'),
 ('0ddf355c-bcdd-411d-99b3-bf8e2464e957','Kat Reynolds',       '0a6552a5-4cb2-42c8-a660-672bfc025423'),
 ('455ac12f-0286-4c0b-a6ce-36d674a96709','Susan Hingle',       '82c4e1f8-c7ce-4049-92ff-13f822d635cf'),
 ('3712b62b-db59-4c28-a2c9-577e254cde14','Dustin Cole Dillard','2abb4229-a032-49bd-baab-4bc4335de347'),
 ('f9069091-02c1-4edf-86f2-5000a3d6e0a1','Sharon A. Green',    '8d947641-0bd6-4d7b-9a9e-bbd4bddad860');

DO $$
DECLARE r record; v text; v_pid uuid; v_act bool;
BEGIN
  FOR r IN SELECT * FROM _link LOOP
    SELECT p.full_name, p.is_active INTO v, v_act FROM essentials.politicians p WHERE p.id = r.pol_id;
    IF v IS NULL THEN RAISE EXCEPTION 'CC_0273: politician % missing', r.pol_id; END IF;
    IF NOT v_act THEN
      RAISE EXCEPTION 'CC_0273: % is ARCHIVED - three of these names have an archived twin and '
                      'linking one would resurrect a retired row', v;
    END IF;
    SELECT rc.full_name, rc.politician_id INTO v, v_pid
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v IS DISTINCT FROM r.cand THEN
      RAISE EXCEPTION 'CC_0273: row % is "%", expected "%"', r.rc_id, v, r.cand;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> r.pol_id THEN
      RAISE EXCEPTION 'CC_0273: row % already linked to %', r.rc_id, v_pid;
    END IF;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc SET politician_id = l.pol_id
FROM _link l WHERE rc.id = l.rc_id AND rc.politician_id IS DISTINCT FROM l.pol_id;

-- ── create the four with no match
CREATE TEMP TABLE _new AS
SELECT rc.id AS rc_id, rc.full_name,
       btrim(regexp_replace(btrim(regexp_replace(rc.full_name,'\s+(Jr\.?|Sr\.?|I{2,3}|IV)$','','i')),'\s+\S+$','')) AS first_name,
       regexp_replace(btrim(regexp_replace(rc.full_name,'\s+(Jr\.?|Sr\.?|I{2,3}|IV)$','','i')),'^.*\s','') AS last_name,
       NULL::uuid AS new_id
FROM essentials.race_candidates rc
WHERE rc.id IN ('f1ca566d-b318-4e28-800f-df3e92377a61'::uuid,   -- Andrew Henry
                'cba1d805-a632-4347-bad7-0cd82a0eb6d8'::uuid,   -- Marv Ulmet
                '85090c44-1a91-4380-b711-e70c56cb7b99'::uuid,   -- Steven E. Webb
                '1b4ee390-14c0-47f0-bf95-ee82c9eec0eb'::uuid);  -- R. Shannon Reed

DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _new;
  IF n <> 4 THEN RAISE EXCEPTION 'CC_0273: expected 4 to create, found %', n; END IF;
  SELECT count(*) INTO bad FROM _new WHERE coalesce(btrim(first_name),'')='' OR coalesce(btrim(last_name),'')='';
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0273: % split to an empty name part', bad; END IF;
  SELECT count(*) INTO bad FROM _new nw
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE (lower(p.first_name)=lower(nw.first_name) AND lower(p.last_name)=lower(nw.last_name))
                     OR lower(p.full_name)=lower(nw.full_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0273: % of the 4 collide with an existing person - the dedupe pass '
                    'missed them, REFUSING to create duplicates', bad;
  END IF;
END $$;

DO $$
DECLARE r record; v_id uuid;
BEGIN
  FOR r IN SELECT * FROM _new ORDER BY full_name LOOP
    INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'indiana-2026-general CC_0273 (Monroe County candidate list; no office asserted)')
    RETURNING id INTO v_id;
    UPDATE _new SET new_id = v_id WHERE rc_id = r.rc_id;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc SET politician_id = nw.new_id
FROM _new nw WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

DO $$
DECLARE n_link int; n_make int; n_left int; n_arch int; n_bad int;
BEGIN
  SELECT count(*) INTO n_link FROM essentials.race_candidates rc
    JOIN _link l ON l.rc_id=rc.id WHERE rc.politician_id = l.pol_id;
  IF n_link <> 8 THEN RAISE EXCEPTION 'CC_0273: expected 8 linked, found %', n_link; END IF;

  SELECT count(*) INTO n_make FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id=rc.id WHERE rc.politician_id = nw.new_id;
  IF n_make <> 4 THEN RAISE EXCEPTION 'CC_0273: expected 4 created+linked, found %', n_make; END IF;

  SELECT count(*) INTO n_bad FROM _new nw JOIN essentials.politicians p ON p.id=nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true
      OR p.external_id IS NOT NULL;
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0273: % new row(s) have wrong flags', n_bad; END IF;

  -- 🔴 the three archived twins must still be archived
  SELECT count(*) INTO n_arch FROM essentials.politicians
   WHERE id IN ('55d5a2fd-d10e-4f2b-a951-9e839202985a'::uuid,
                'cbab6044-23aa-4a65-ae2c-5c52bf3534b4'::uuid,
                'f28debd0-0451-4db4-9ff3-1f200d4ef6bc'::uuid)
     AND is_active = false;
  IF n_arch <> 3 THEN
    RAISE EXCEPTION 'CC_0273: an archived twin was reactivated (% still archived of 3)', n_arch;
  END IF;

  -- exactly one Indiana row left unlinked, and it must be Smith
  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.state='IN' AND e.election_date >= current_date AND rc.politician_id IS NULL;
  IF n_left <> 1 THEN RAISE EXCEPTION 'CC_0273: % IN rows unlinked, expected 1', n_left; END IF;
  SELECT count(*) INTO n_bad FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.state='IN' AND e.election_date >= current_date AND rc.politician_id IS NULL
     AND rc.full_name <> 'William E. Smith III';
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0273: the remaining unlinked IN row is not Smith III'; END IF;

  RAISE NOTICE 'CC_0273 OK - 8 linked, 4 created, Smith III left unlinked, archived twins intact';
END $$;

DROP TABLE _new;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: A GENERATIONAL SUFFIX IS NOT A SPELLING VARIANT.
-- This programme has accepted an accent (Rascón/Rascon), a missing full stop (Herb W. Morgan),
-- a dropped middle initial and a diminutive (Tom/Thomas) as the SAME person. "III" is none of
-- those: its only job is to distinguish a father from a son, so dropping it changes who is being
-- named. William E. Smith III matched the strongest evidence in the cohort -- the incumbent of
-- the exact seat -- and is still refused, because the one thing the names disagree about is the
-- one thing that distinguishes two people.
-- ⚠ AND AN INITIAL-ONLY FIRST NAME IS NOT A MATCH. "R. Reed" matches every Reed whose first name
-- starts with R. Same false-positive shape as "A. Dane Anderson" in CC_0268.
-- 🟢 THE HANDOFF'S CALL WAS RIGHT: Indiana was 10 variant hits against 13 candidates, and treating
-- it as a creation sweep would have made 8 duplicate people. Work a cohort that dense by hand.
-- ───────────────────────────────────────────────────────────────────────────────────────────
