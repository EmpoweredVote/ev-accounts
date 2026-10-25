-- CC_0274_nevada_oregon_2026_general_candidates.sql
--
-- Nevada and Oregon 2026 General. Six unlinked rows between them, two variant hits, and BOTH
-- variant hits are refusals. Creates 5, leaves 1 unlinked, links nothing.
--
-- ═══ 🔴🔴 THE MOST EXPENSIVE NEAR-MISS THIS PROGRAMME HAS FOUND ═══
--
--   JOHN T. KENNEDY -- candidate for **Secretary of State of NEVADA**
--     matched "John Kennedy" (ffe3816f) -- **United States Senator for LOUISIANA**,
--     carrying **26 compass answers** and a photograph.
--
-- Exactly one active namesake, which is the signal that justified dozens of links across this
-- programme. Linking would have published a sitting U.S. Senator's face and 26 researched
-- positions on a Nevada Secretary of State ballot page, two weeks before an election.
-- 🔴 Caught by the cheapest test we have: compare the election's state with the state of the seat
-- the matched person holds. NV against LA. One join.
-- This is the SIXTH confirmed cross-state wrong person (after Cheryl Williams/TX, Amanda
-- Campbell/TX, Ed Delgado/WI, Mike Murphy/KS, Tony Rodriguez/FL) and by far the costliest had it
-- gone through. He is CREATED as his own person below; the names differ ("John T. Kennedy" vs
-- "John Kennedy") so nothing collides.
--
-- ═══ ⚠ ONE LEFT UNLINKED -- BEAVERTON POSITION MISMATCH ═══
--
--   JOHN DUGGER -- seeks **Beaverton City Council Position 1**
--     matched "John Dugger" (11427932) -- holds **Council Member (Position 5), Beaverton, OR**,
--     with **16 compass answers** and a photograph.
--
-- Exact name, same city, same council body, different numbered seat. Unlike the Copland refusal
-- in CC_0272 there is no residency contradiction here -- Beaverton positions are at-large, not
-- geographic, so one person CAN stand for a different numbered seat. That makes this genuinely
-- undetermined rather than refuted.
-- ▶ REFUSED ANYWAY, because the downside is asymmetric: 16 answers and a face on a live ballot
-- page if wrong, against one page missing a profile if right. The same arithmetic that refused
-- Sarmiento and Smith III.
-- ▶ WHAT WOULD SETTLE IT: the Beaverton candidate filing naming the incumbent's position, or any
-- Beaverton source explaining why a sitting Position 5 councillor is standing for Position 1.
-- ⚠ NOT CREATED EITHER -- his full_name matches the existing row exactly, so creating would
-- assert "different person" as falsely as linking would assert "same". Unlinked is the finding.
--
-- ═══ CREATED -- 5 ═══
--   Adriana Guzman Fralick  Attorney General of Nevada        (no match)
--   Brad Barnhill           Secretary of State of Nevada      (no match)
--   John T. Kennedy         Secretary of State of Nevada      (match refused, see above)
--   Antonio Pirog           Beaverton City Council Position 1 (no match)
--   Marvin Rydberg          Beaverton City Council Position 1 (no match)
--
-- Idempotent: re-running inserts nothing.

BEGIN;

CREATE TEMP TABLE _new AS
SELECT rc.id AS rc_id, rc.full_name,
       btrim(regexp_replace(btrim(regexp_replace(rc.full_name,'\s+(Jr\.?|Sr\.?|I{2,3}|IV)$','','i')),'\s+\S+$','')) AS first_name,
       regexp_replace(btrim(regexp_replace(rc.full_name,'\s+(Jr\.?|Sr\.?|I{2,3}|IV)$','','i')),'^.*\s','') AS last_name,
       NULL::uuid AS new_id
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id=rc.race_id
JOIN essentials.elections e ON e.id=r.election_id
WHERE e.state IN ('NV','OR') AND e.election_date >= current_date
  AND rc.politician_id IS NULL
  AND rc.id <> '16a7cb03-0f8b-4b0b-9289-72c0bb3f66b1'::uuid;   -- John Dugger, left unlinked

DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _new;
  IF n <> 5 THEN RAISE EXCEPTION 'CC_0274: expected 5 to create, found %', n; END IF;

  SELECT count(*) INTO bad FROM _new WHERE coalesce(btrim(first_name),'')='' OR coalesce(btrim(last_name),'')='';
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0274: % split to an empty name part', bad; END IF;

  -- 🔴 no collisions on either key. John T. Kennedy must NOT collide with the Louisiana senator;
  -- if he does, the name rendering changed and this migration's reasoning needs re-reading.
  SELECT count(*) INTO bad FROM _new nw
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE (lower(p.first_name)=lower(nw.first_name) AND lower(p.last_name)=lower(nw.last_name))
                     OR lower(p.full_name)=lower(nw.full_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0274: % of the 5 collide with an existing person - REFUSING', bad;
  END IF;

  -- the Louisiana senator must still be who this migration thinks he is
  PERFORM 1 FROM essentials.politicians WHERE id='ffe3816f-4923-4e10-b71c-8b2590a8f377'::uuid
                                          AND full_name='John Kennedy';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0274: the refused John Kennedy row is not the one that was examined';
  END IF;
END $$;

DO $$
DECLARE r record; v_id uuid;
BEGIN
  FOR r IN SELECT * FROM _new ORDER BY full_name LOOP
    INSERT INTO essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'nv-or-2026-general CC_0274 (state candidate list; no office asserted)')
    RETURNING id INTO v_id;
    UPDATE _new SET new_id = v_id WHERE rc_id = r.rc_id;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc SET politician_id = nw.new_id
FROM _new nw WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

DO $$
DECLARE n_make int; n_left int; n_bad int; n_ken int;
BEGIN
  SELECT count(*) INTO n_make FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id=rc.id WHERE rc.politician_id = nw.new_id;
  IF n_make <> 5 THEN RAISE EXCEPTION 'CC_0274: expected 5 created+linked, found %', n_make; END IF;

  SELECT count(*) INTO n_bad FROM _new nw JOIN essentials.politicians p ON p.id=nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true
      OR p.external_id IS NOT NULL;
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0274: % new row(s) have wrong flags', n_bad; END IF;

  -- 🔴 the Louisiana senator must hold NO Nevada candidacy
  SELECT count(*) INTO n_ken FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.elections e ON e.id=r.election_id
   WHERE rc.politician_id='ffe3816f-4923-4e10-b71c-8b2590a8f377'::uuid AND e.state='NV';
  IF n_ken <> 0 THEN
    RAISE EXCEPTION 'CC_0274: the Louisiana senator picked up % Nevada candidacy row(s)', n_ken;
  END IF;

  -- exactly one NV/OR row left unlinked, and it must be Dugger
  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.state IN ('NV','OR') AND e.election_date >= current_date AND rc.politician_id IS NULL;
  IF n_left <> 1 THEN RAISE EXCEPTION 'CC_0274: % NV/OR rows unlinked, expected 1', n_left; END IF;
  SELECT count(*) INTO n_bad FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id JOIN essentials.elections e ON e.id=r.election_id
   WHERE e.state IN ('NV','OR') AND e.election_date >= current_date AND rc.politician_id IS NULL
     AND rc.full_name <> 'John Dugger';
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0274: the remaining unlinked NV/OR row is not Dugger'; END IF;

  RAISE NOTICE 'CC_0274 OK - 5 created, Kennedy refused and created separately, Dugger unlinked';
END $$;

DROP TABLE _new;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE RULE, RESTATED BECAUSE THIS IS THE CLOSEST IT HAS COME:
-- A U.S. SENATOR WAS ONE JOIN AWAY FROM A NEVADA BALLOT PAGE. "John T. Kennedy" seeking Nevada
-- Secretary of State had exactly one active namesake -- a sitting Louisiana senator with 26
-- researched positions and a face. Nothing about the name was ambiguous; everything about the
-- STATE was. Compare the election's state with the state of the matched person's seat, every
-- single time, before anything else.
-- ▶ OPERATOR RULING 2026-10-20, recorded here because it unblocks Washington: a candidate who
-- LOSES A PRIMARY KEEPS THEIR PERSON RECORD. We hold onto the information; they are simply not
-- presented as a candidate or an incumbent. So the 70 WA `not_nominated` rows are IN SCOPE for
-- creation with is_incumbent=false, not excluded from it.
-- ───────────────────────────────────────────────────────────────────────────────────────────
