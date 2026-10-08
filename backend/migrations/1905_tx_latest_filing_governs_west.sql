-- 1905_tx_latest_filing_governs_west.sql
-- Royce West / redistricting, chair 2 -> 1. The last of the twelve rows migration 1903 held out.
--
-- ══ ⚖ THE RULE, AND WHY THIS ROW NEEDED IT ════════════════════════════════════════════════════
-- West is the only member of this cohort who filed BOTH shapes of redistricting commission:
--
--   86(R) SJR 56  ·  87(R) SJR 43   a seven-member commission APPOINTED by the Speaker, the
--                                   president of the Senate and the party caucuses -- rung 2,
--                                   "independent redistricting commissions with equal
--                                   representation from both major parties"
--   89(1) SJR 3   ·  89(2) SJR 2    a NONPARTISAN AGENCY draws fifteen commissioners AT RANDOM
--                                   from the majority, minority and independent categories of a
--                                   vetted pool; no elected official sits on the commission --
--                                   rung 1 under the ruling of 2026-10-08
--
-- Migration 1903 repaired him at chair 2 on the strength of the 2019 and 2021 bills, and
-- migration 1904 deliberately left him there while recording the tension, because his most
-- recent filing says something different from the one his chair rested on.
--
-- ⚖ OPERATOR RULING, 2026-10-08: **THE LATEST FILING GOVERNS THE CHAIR.** A member's position is
-- what they most recently put their name to, not the earliest thing they ever filed. West's
-- latest redistricting filing is SJR 2 of the second called session of the 89th -- August 2025,
-- filed while the chamber was sitting on the mid-decade congressional map he voted against --
-- and it is rung 1.
--
-- ══ 🔑 THE RULE WAS APPLIED TO THE WHOLE COHORT, NOT JUST TO WEST ═════════════════════════════
-- A rule applied to one row and not the rest leaves the same defect standing everywhere else, so
-- every written row was re-checked for filings that point at DIFFERENT rungs in DIFFERENT
-- sessions. Only two others have any such split and NEITHER moves:
--   * Brent Money / abortion -- 89(R) rungs [4,5], then 89(1) and 89(2) both rung 5. The latest
--     agrees with the chair already written.
--   * Gina Hinojosa / same-sex-marriage -- her rung-1 instrument is her OLDEST (86(R) HB 188,
--     housing discrimination on the basis of sexual orientation) and her later filings are a
--     broader band that CONTAINS rung 1. A band that contains the rung is not a conflict, so the
--     latest-filing rule does not disturb her; she remains held out for a separate decision.
-- Among the seven members whose commission bills were read for composition, West is the only one
-- whose sessions disagree: Johnson and Turner are rung 2 throughout, Goodwin, Miles and Morales
-- Shaw rung 1 throughout, and Bernal's single bill defines no commission at all.
--
-- ⚠ A CHECK THAT CAUGHT ITSELF, RECORDED BECAUSE THE TRAP IS THE POINT. The first pass of that
-- re-check keyed bills by NUMBER alone and reported Vikki Goodwin as having a rung-2 bill in
-- 89(1) -- "HB 241". Ann Johnson's HB 241 is the Texas Redistricting Commission, in 89(2);
-- GOODWIN'S 89(1) HB 241 IS A NATURAL GAS FLARING BILL, which matched only because its caption
-- names the "Railroad Commission of Texas". Texas renumbers every session and a bare bill number
-- is meaningless without one. Goodwin is rung 1 throughout and is unaffected.
--
-- ══ THE REST OF THE ROW IS UNCHANGED ══════════════════════════════════════════════════════════
-- The side was never in doubt: West voted against HB 4 in the Senate in the second called
-- session of the 89th, 18-11. What moves is the rung, and only the rung.
--
-- Redistricting rung text is byte-identical across the two seasons, so the carry gate is
-- satisfied; the guard below asserts it rather than assuming it.
-- Season 1 is CLOSED and IMMUTABLE: this is a forward write into Season 2.
-- No migration runner exists; this file records SQL applied by hand.

DO $pre$
DECLARE n integer;
BEGIN
  -- 1. migration 1903 wrote him a Season 2 row at chair 2, and it is still there and still 2
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
     AND c.season_id = a.season_id
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND a.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND a.politician_id = '1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid
     AND a.value = 2
     AND c.reasoning LIKE '%(migration 1903)%';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1905: expected West at Season 2 value 2 with migration 1903 reasoning, found %', n;
  END IF;

  -- 2. Season 1 still has him at 2, so the move is 2 -> 1 and not something else
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND politician_id = '1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid
     AND value = 2;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1905: expected West at Season 1 value 2, found %', n;
  END IF;

  -- 3. redistricting rungs 1 and 2 still say the same thing in both seasons
  SELECT count(*) INTO n
    FROM inform.compass_stance_revisions a
    JOIN inform.season_questions qa ON qa.topic_revision_id = a.topic_revision_id
     AND qa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
    JOIN inform.season_questions qb ON qb.topic_id = qa.topic_id
     AND qb.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
    JOIN inform.compass_stance_revisions b ON b.topic_revision_id = qb.topic_revision_id
     AND b.value = a.value
   WHERE qa.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND a.value IN (1, 2) AND a.text IS DISTINCT FROM b.text;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1905: redistricting rung 1 or 2 text changed between seasons (%)', n;
  END IF;
END
$pre$;

UPDATE inform.politician_context SET reasoning = 'Chair moved from 2 to 1 on 2026-10-08 (migration 1905). Migration 1903 repaired this row''s citation and kept it at 2; this moves it, on a rule rather than on new evidence. 🔑 WEST IS THE ONLY MEMBER OF THIS COHORT WHO FILED BOTH SHAPES OF COMMISSION. His SJR 56 (86R) and SJR 43 (87R) establish a seven-member Texas Redistricting Commission APPOINTED by the Speaker, the president of the Senate and the party caucuses -- rung 2 exactly, "independent redistricting commissions with equal representation from both major parties". His SJR 3 (89th, first called session) and SJR 2 (89th, second called session) do something different: a NONPARTISAN AGENCY appoints fifteen commissioners CHOSEN AT RANDOM, two at a time, from the majority, minority and independent categories of a vetted selection pool, and the legislature''s only role is a four-member select committee that approves or rejects the pool. No elected official sits on that commission. ⚖ TWO OPERATOR RULINGS SETTLE THIS ROW. First, 2026-10-08: rung 1''s "no elected officials involved at any level" means no elected official SERVES on the commission -- a veto over the applicant pool is involvement in the process, not membership -- which makes SJR 3 and SJR 2 rung 1. Second, 2026-10-08: THE LATEST FILING GOVERNS THE CHAIR. A member''s position is what they most recently put their name to. West''s latest redistricting filing is SJR 2, filed in August 2025 while the Senate was sitting on the mid-decade congressional map, and it is rung 1. 🔑 THE SIDE WAS NEVER IN DOUBT AND DOES NOT CHANGE: he voted against HB 4 in the Senate in that same called session, 18-11, against the 2025 map. What moves is the rung. ⚠ The earlier bills are not withdrawn or disowned and are kept in the sources below, because a reader should be able to see that this member''s filed position changed shape between 2021 and 2025 rather than take the latest one on trust.', sources = ARRAY['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=892&Bill=SJR2', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=891&Bill=SJR3', 'https://capitol.texas.gov/tlodocs/892/billtext/html/SJ00002I.htm', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=86R&Bill=SJR56', 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=SJR43', 'http://journals.senate.texas.gov/sjrnl/892/pdf/89S2SJ08-22-F.PDF', 'https://en.wikipedia.org/wiki/Royce_West'], updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
   AND politician_id = '1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid;

UPDATE inform.politician_answers SET value = 1, updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
   AND politician_id = '1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid;

DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
     AND c.season_id = a.season_id
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND a.topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND a.politician_id = '1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid
     AND a.value = 1
     AND c.reasoning LIKE '%(migration 1905)%';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1905: expected West at Season 2 value 1 with migration 1905 reasoning, found %', n;
  END IF;

  -- Season 1 must be untouched
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
     AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f'
     AND politician_id = '1ff93be4-a2d0-432b-af59-ef6ace1eb77b'::uuid
     AND value <> 2;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1905: Season 1 was altered (% rows)', n;
  END IF;
END
$post$;
