-- CC_0278_washington_2026_general_candidate_people.sql
--
-- Washington 2026 General, part 2 of 2. Creates 196 politician rows and links 197 candidacies.
-- Washington then reads 394 of 394, and the candidate->person programme is finished.
--
-- ═══ 🔴🔴 196 PEOPLE, 197 CANDIDACIES -- ONE PERSON FILED TWICE ═══
-- **JULIA PAYNE holds TWO rows**, both in Legislative District 6: Position 1 marked `withdrew`
-- and Position 2 marked `advanced`. Washington's own voters' pamphlet carries **exactly one**
-- Julia Payne (BallotID 1600273, LD6 State Representative Pos. 2, Democrat,
-- juliaforoffice.com, "I am a first-time candidate"). One person who filed for one position,
-- withdrew, and ran for the other. She gets ONE row and BOTH candidacies point at it.
--
-- 🔴 THIS IS THE FAILURE THE PRE-FLIGHT COLLISION CHECK CANNOT SEE, AND IT NEARLY SHIPPED.
-- The check asks "does this name already exist in `politicians`?" -- it compares the batch
-- against the TABLE. It cannot see a name repeated INSIDE the batch, because the first insert is
-- what creates the collision for the second. It reported ZERO collisions for this cohort and was
-- wrong. **The dry run caught it**: the loop inserted Julia Payne, then hit
-- `DUPLICATE_POLITICIAN_NAME` on her own freshly written row.
-- ▶ A BATCH MUST BE CHECKED AGAINST ITSELF AS WELL AS AGAINST THE TABLE. The gate below now does
-- both, and this is why dry-running is not a formality.
--
-- ⚠ AND NOTE WHAT DECIDES IT -- the house rule is "key the link on `rc_id`, not `full_name`,
-- because two candidates in different districts can share a name". That rule is not broken here;
-- it is applied. Two rows share a name **in the SAME district and the same chamber**, which no
-- two candidates can do unnoticed, and the Secretary of State's own pamphlet lists one of her.
-- 🔴 The gate therefore refuses any repeated name whose rows sit in DIFFERENT districts -- that
-- shape is two people and must never be collapsed into one row.
--
-- Run AFTER CC_0277, which links the 12 evidenced candidacies. This migration takes whatever
-- Washington rows are still unlinked, so applying it first would create people for the twelve.
-- Its first gate refuses unless exactly 197 remain, which is what CC_0277 leaves behind.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ WHAT THESE 197 ARE ═══
-- The whole WA cohort minus the twelve. Overwhelmingly state legislative: House Position 1 and
-- Position 2 and State Senator across the 49 legislative districts, plus a dozen county rows
-- (Assessor, and council seats in King and Kitsap).
--
-- 🔴 70 OF THEM LOST THE TOP-TWO PRIMARY AND 5 WITHDREW, AND THEY ARE IN SCOPE ON PURPOSE.
-- Operator ruling 2026-10-20: *"if someone loses the primary, we should hold onto their
-- information, just not as a candidate/incumbent."*
--   * The person is created exactly like any other: is_active, NOT is_incumbent, no office.
--   * 🔴 `result` and `candidate_status` are NOT touched. Those fields are what keep the row off
--     the ballot page -- `electionService` filters `not_nominated` -- and rewriting them to tidy
--     the cohort would publish losing candidates as if they were running.
-- ▶ The ruling changes WHO WE KEEP, never WHAT WE DISPLAY.
--
-- ═══ 🟢 THE DEDUPE PASS CAME BACK CLEAN, AND THAT IS A RESULT ═══
-- Run over all 209 unlinked rows against every politician row, active and archived, on
-- (last name + first name | diminutive | first initial) and again on the first-and-last token of
-- `full_name` to catch a differently split name, an accent or a missing full stop.
-- **16 variant hits. 12 became links in CC_0277. 4 were refused.** Of the 197 here,
-- **ZERO collide** on either key -- no exact name, no split difference, no accent, no
-- punctuation difference, no diminutive, no archived twin.
-- ⚠ THAT IS THE OUTPUT OF THE PASS, NOT A REASON TO SKIP IT. Indiana looked equally routine and
-- came back 10 hits against 13 candidates.
--
-- 🔴 FOUR OF THESE 197 ARE THE REFUSED WRONG-PERSON MATCHES, each positively disconfirmed by
-- their own voters'-pamphlet statement (the reasoning is in CC_0277's header):
--   Angela Taylor (House 2 Pos 2) · Eric W. Pratt (House 24 Pos 1) ·
--   Kathy Richardson (House 28 Pos 1) · Michael Alvarez Shepard (Senate 42)
-- ⚠ NOT ONE OF THEM TRIPS THE DUPLICATE-NAME GUARD, because each splits to a first_name the
-- existing row does not carry. **No escape hatch is opened in this migration** -- there is
-- nothing for it to excuse. That silence is the guard not looking, not the guard agreeing.
--
-- ⚠ TWO NAMES NEED THE SPLIT RULES AND BOTH ARE HANDLED:
--   * `Juan "Jerry" Garcia` -- the QUOTED NICKNAME is stripped from the first/last split and kept
--     verbatim in full_name, which is what the voter sees on the ballot. Unstripped, first_name
--     would be `Juan "Jerry"` -- a string no other row can ever equal, silently exempting him
--     from the duplicate guard. Garcia is among the commonest surnames we hold, so this is
--     exactly the row where the key must be right.
--   * `Luc Jasmin III` -- the generational suffix is excluded from last_name so the guard keys on
--     `Luc` / `Jasmin`. ⚠ The suffix STAYS in full_name: CC_0273 refused William E. Smith III
--     precisely because a suffix distinguishes two people, so it must never be dropped from the
--     displayed name.
--
-- ▶ WHAT EACH ROW ASSERTS: existence, and nothing else. `is_active=true`,
-- **`is_incumbent=FALSE` named explicitly** (CA_0188), `external_id` NULL, `party` NULL
-- (antipartisan -- it lives on `races.primary_party`), and NO office_terms row.
-- 🔴 MANY OF THEM DO HOLD OFFICE AND ARE STILL NOT SEATED HERE. The pamphlet shows city
-- councilmembers in Tacoma, Shoreline, Edmonds, Vancouver, Burien, Bothell, Moses Lake,
-- Ellensburg, Port Angeles, Aberdeen and Yakima, school directors in Puyallup, Peninsula and
-- Walla Walla, and a port commissioner. **We hold no politician row for any of them** -- the
-- dedupe pass found none -- because our Washington occupancy is the legislature plus a slice of
-- King County. Seating them from a candidate statement would be inventing occupancy from a
-- self-description; that is a seeding job with its own sources.
-- ▶ If those cities are seeded later, THESE are the people to seat, not rows to duplicate.
--
-- Idempotent: re-running inserts nothing.

BEGIN;

CREATE TEMP TABLE _new AS
WITH src AS (
  SELECT rc.id AS rc_id, rc.full_name,
         btrim(regexp_replace(rc.full_name, '\s*"[^"]*"\s*', ' ', 'g')) AS clean
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE e.state = 'WA' AND e.election_date >= current_date
    AND rc.politician_id IS NULL
)
SELECT rc_id, full_name,
       btrim(regexp_replace(
         btrim(regexp_replace(clean, '\s+(Jr\.?|Sr\.?|I{2,3}|IV)$', '', 'i')),
         '\s+\S+$', '')) AS first_name,
       regexp_replace(
         btrim(regexp_replace(clean, '\s+(Jr\.?|Sr\.?|I{2,3}|IV)$', '', 'i')),
         '^.*\s', '') AS last_name,
       NULL::uuid AS new_id
FROM src;

DO $$
DECLARE n int; bad int;
BEGIN
  SELECT count(*) INTO n FROM _new;
  IF n <> 197 THEN
    RAISE EXCEPTION 'CC_0278: expected 197 to create, found % - CC_0277 has probably not been '
                    'applied, and running this first would create people for its twelve '
                    'evidenced links. REFUSING', n;
  END IF;

  SELECT count(*) INTO bad FROM _new
   WHERE coalesce(btrim(first_name),'')='' OR coalesce(btrim(last_name),'')='';
  IF bad > 0 THEN RAISE EXCEPTION 'CC_0278: % split to an empty name part', bad; END IF;

  -- 🔴 the quoted nickname must be gone from the SPLIT and present in full_name
  PERFORM 1 FROM _new WHERE full_name = 'Juan "Jerry" Garcia'
                        AND first_name = 'Juan' AND last_name = 'Garcia';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0278: the quoted nickname was not stripped from the first/last split - '
                    'the duplicate guard would key on a string nothing can match';
  END IF;
  -- and the suffix must be gone from last_name but kept in full_name
  PERFORM 1 FROM _new WHERE full_name = 'Luc Jasmin III' AND last_name = 'Jasmin';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0278: the generational suffix handling changed';
  END IF;

  -- 🔴 no collisions on either key, active or archived. The pass measured ZERO; anything else
  -- means a name arrived that nobody read, and an unread collision is how a wrong person is made.
  SELECT count(*) INTO bad FROM _new nw
   WHERE EXISTS (SELECT 1 FROM essentials.politicians p
                  WHERE (lower(p.first_name)=lower(nw.first_name)
                     AND lower(p.last_name)=lower(nw.last_name))
                     OR lower(p.full_name)=lower(nw.full_name));
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0278: % of the 197 collide with an existing person - the dedupe pass '
                    'measured ZERO, so the data moved. REFUSING until each is read', bad;
  END IF;

  -- 🔴 the four refused wrong-person matches must be in this set, not linked somewhere
  SELECT count(*) INTO bad FROM _new
   WHERE full_name IN ('Angela Taylor','Eric W. Pratt','Kathy Richardson','Michael Alvarez Shepard');
  IF bad <> 4 THEN
    RAISE EXCEPTION 'CC_0278: expected the 4 refused rows among the 197, found % - if one has '
                    'been linked, the refusal has been overturned somewhere unrecorded', bad;
  END IF;

  -- 🔴🔴 CHECK THE BATCH AGAINST ITSELF. The collision check above compares the batch with the
  -- TABLE and is blind to a name repeated inside the batch -- the first insert is what creates
  -- the collision for the second.
  SELECT count(*) INTO bad FROM (
    SELECT full_name FROM _new GROUP BY full_name HAVING count(*) > 1) q;
  IF bad <> 1 THEN
    RAISE EXCEPTION 'CC_0278: expected exactly 1 name repeated within the batch (Julia Payne), '
                    'found % - each repeat is either one person filing twice or two people '
                    'sharing a name, and only reading them tells you which', bad;
  END IF;
  PERFORM 1 FROM _new GROUP BY full_name HAVING count(*) > 1 AND min(full_name) = 'Julia Payne';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0278: the repeated name is not Julia Payne';
  END IF;

  -- 🔴 AND A REPEAT IS ONLY ONE PERSON IF THE ROWS SIT IN THE SAME DISTRICT. Two candidates
  -- sharing a name across different districts is the ordinary case and must stay two rows.
  SELECT count(*) INTO bad FROM (
    SELECT nw.full_name
      FROM _new nw
      JOIN essentials.race_candidates rc ON rc.id = nw.rc_id
      JOIN essentials.races r  ON r.id = rc.race_id
      JOIN essentials.offices o ON o.id = r.office_id
     GROUP BY nw.full_name
    HAVING count(*) > 1 AND count(DISTINCT o.district_id) > 1) q;
  IF bad > 0 THEN
    RAISE EXCEPTION 'CC_0278: % repeated name(s) span more than one district - that shape is '
                    'TWO PEOPLE and must not be collapsed into one person row', bad;
  END IF;
END $$;

-- One politician per distinct name; a candidacy row per rc_id points at it.
DO $$
DECLARE r record; v_id uuid;
BEGIN
  FOR r IN SELECT DISTINCT full_name, first_name, last_name FROM _new ORDER BY full_name LOOP
    INSERT INTO essentials.politicians (full_name, first_name, last_name,
                                        is_active, is_incumbent, source)
    VALUES (r.full_name, r.first_name, r.last_name, true, false,
            'wa-2026-general CC_0278 (WA SoS certified candidate filings; no office asserted)')
    RETURNING id INTO v_id;
    UPDATE _new SET new_id = v_id WHERE full_name = r.full_name;
  END LOOP;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = nw.new_id
FROM _new nw
WHERE rc.id = nw.rc_id AND nw.new_id IS NOT NULL AND rc.politician_id IS NULL;

DO $$
DECLARE n_make int; n_left int; n_bad int; n_terms int; n_kept int; n_people int; n_payne int;
BEGIN
  SELECT count(*) INTO n_make FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id = rc.id WHERE rc.politician_id = nw.new_id;
  IF n_make <> 197 THEN RAISE EXCEPTION 'CC_0278: expected 197 candidacies linked, found %', n_make; END IF;

  -- 196 people for 197 candidacies, and the difference is Julia Payne's two LD6 filings
  SELECT count(DISTINCT new_id) INTO n_people FROM _new;
  IF n_people <> 196 THEN RAISE EXCEPTION 'CC_0278: expected 196 people created, found %', n_people; END IF;
  SELECT count(*) INTO n_payne FROM _new WHERE full_name = 'Julia Payne';
  IF n_payne <> 2 OR (SELECT count(DISTINCT new_id) FROM _new WHERE full_name = 'Julia Payne') <> 1 THEN
    RAISE EXCEPTION 'CC_0278: Julia Payne should be 2 candidacies on 1 person row';
  END IF;

  SELECT count(*) INTO n_bad FROM _new nw JOIN essentials.politicians p ON p.id = nw.new_id
   WHERE p.is_incumbent IS DISTINCT FROM false OR p.is_active IS DISTINCT FROM true
      OR p.external_id IS NOT NULL OR p.party IS NOT NULL;
  IF n_bad <> 0 THEN RAISE EXCEPTION 'CC_0278: % new row(s) assert more than existence', n_bad; END IF;

  SELECT count(*) INTO n_terms FROM essentials.office_terms ot
    JOIN _new nw ON nw.new_id = ot.politician_id;
  IF n_terms <> 0 THEN RAISE EXCEPTION 'CC_0278: % new person(s) hold an office term', n_terms; END IF;

  -- 🔴 the primary losers kept their candidacy fields. If this count moved, something rewrote
  -- `result` to tidy the cohort, and that would put losing candidates back on a ballot page.
  SELECT count(*) INTO n_kept FROM essentials.race_candidates rc
    JOIN _new nw ON nw.rc_id = rc.id WHERE rc.result = 'not_nominated';
  IF n_kept <> 70 THEN
    RAISE EXCEPTION 'CC_0278: expected 70 not_nominated rows untouched, found % - candidacy '
                    'fields must not be rewritten', n_kept;
  END IF;

  -- 🟢 Washington must now be complete
  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.state = 'WA' AND e.election_date >= current_date AND rc.politician_id IS NULL;
  IF n_left <> 0 THEN RAISE EXCEPTION 'CC_0278: % WA rows still unlinked, expected 0', n_left; END IF;

  RAISE NOTICE 'CC_0278 OK - 196 people created, 197 candidacies linked; Washington fully linked';
END $$;

DROP TABLE _new;
COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS SLICE ADDS: A SELF-DESCRIPTION IDENTIFIES A PERSON; IT DOES NOT SEAT THEM.
-- The voters' pamphlet told us that dozens of these 197 sit on city councils and school boards.
-- Not one is seated here, because "I am a Tacoma councilmember" is the candidate's own words
-- about themselves -- excellent for saying WHO they are, worth nothing as a record of WHO HOLDS
-- A SEAT. Occupancy comes from the body's own roster, with dates. Same family as "a certified
-- result is not a fact about who holds the seat" and "FIRST ELECTED IS NOT A TERM START".
-- ───────────────────────────────────────────────────────────────────────────────────────────
