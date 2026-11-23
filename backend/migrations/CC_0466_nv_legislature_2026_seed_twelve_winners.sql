-- CC_0466 — Nevada Assembly and Senate: create the twelve 2026 winners we do not hold, and LINK
-- the thirteenth, who already exists.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE BLOCKER SAYS "NO RECORD IN THIS RACE". IT NEVER SAYS "NO RECORD ANYWHERE".
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `derive-seating-wave.mjs` reports THIRTEEN `winner_no_record` blockers for Nevada, and this
-- file creates TWELVE people. The thirteenth is DANIELLE GALLANT, State Senate District 20,
-- who already exists as 6cffc86c-7d40-4fd9-8690-51d6d33ff1e4: she is the sitting ASSEMBLY
-- DISTRICT 23 member moving up to the Senate, and her `race_candidates` row simply carries a
-- NULL `politician_id`. Seeding her would have put a second row on the board for a serving
-- official, and `CLAUDE.md`'s rule is one row per person.
--
-- ▶ The blocker is computed from the winner's own race row. A person can be absent from that
--   race and present in the table, which is exactly Jennifer Balkcom's shape in CC_0352 — found
--   there the same way, by sweeping the whole table before creating anybody.
--
-- ⚠ HER ASSEMBLY SEAT IS IN THE SAME WAVE. AD23's 2026 winner is Denise Daniels Fanning, so
--   CC_0467 both closes Gallant's Assembly term and opens her Senate one. The two writes touch
--   different offices, so the `office_terms` exclusion constraint is not engaged either way
--   round.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE SWEEP THAT FOUND HER, AND FOUND NOBODY ELSE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Measured against production 2026-11-23, over the WHOLE `essentials.politicians` table and not
-- the Nevada races:
--
--   • matched on (first_name, last_name) and on full_name, case-insensitively — ONE hit,
--     Danielle Gallant;
--   • swept again on surname alone across all fifteen surnames, including the archived
--     (`is_active = false`) rows the duplicate-name guard cannot see — the only neighbours are
--     unrelated people (Annie/James/Joey/Paul/Zach Andrews, 40 Millers, Maria and Victor
--     Davila, Nelson Esparza, Chris and Donna Gallant, Aileen/Tony/Tyron Hampton, fourteen
--     Butlers). None is a Nevada legislator;
--   • Bywaters, Eady, Pereszlenyi, Spica, Spotleson and Fanning return NOTHING at all.
--
-- 🔴 THE GUARD KEYS ON (first_name, last_name), SO A FULL NAME SPLIT DIFFERENTLY IS INVISIBLE TO
--    IT. That is why the surname sweep was run as well, and why "Daniels Fanning" was searched
--    as a surname in its own right as well as "Fanning".
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 EVERY ONE OF THE THIRTEEN WAS CHECKED AGAINST THE BODY'S OWN ROSTER, NOT A NAME SEARCH
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `https://www.leg.state.nv.us/App/Legislator/A/{Assembly,Senate}/Current/<district>` — the
-- Legislature's own member pages, fetched 2026-11-23 (HTTP 200 on all thirteen). The site has
-- already rolled to `Session/84th2027`, so each page is the chamber's own statement of who holds
-- that district NOW. District, chamber and party below are read from those pages:
--
--   AD1   Alexis E. Esparza          Democratic   AD23  Denise Daniels Fanning  Republican
--   AD2   Kamilah A.. Bywaters       Democratic   AD29  Alex J. Pereszlenyi     Democratic
--   AD4   Eileen Eady                Democratic   AD35  Joe Spica               Democratic
--   AD7   C.H. (Cameron (C.H.)) Miller Democratic AD40  Julie A. Butler         Republican
--   AD9   Ryan Hampton               Democratic   AD41  Vinny Spotleson         Democratic
--   AD13  Daniel J. Andrews          Democratic   SD20  Danielle Gallant        Republican
--   AD15  Miguel D&#225;vila         Democratic
--
-- ⚠ THE ROSTER AND AP DISAGREE ON THREE RENDERINGS, AND ONLY ONE OF THEM IS A SPELLING.
--   • AD15 — the Legislature writes `D&#225;vila`, which is **Dávila**; AP writes "Davila".
--     🔴 THE CHAMBER'S OWN PUBLICATION OUTRANKS THE AGGREGATOR ON HOW A MEMBER'S NAME IS SPELT,
--     so the row created below carries **Miguel Dávila** and AP's spelling travels in its
--     `source`. This repo already holds `Cecelia González` with her accent, so the convention is
--     not new. ⚠ The page writes the accent as a numeric entity, so a reader that does not
--     decode them manufactures a disagreement — and so does writing the decoded name out in the
--     wrong encoding, which is how this cross-check first reported five mismatches instead of
--     two.
--   • AD7 and AD2 are NOT spelling disagreements. The Legislature renders AD7 by the preferred
--     name "C.H." with "Cameron" in its own parentheses, and AD2 carries a stray double full
--     stop ("Kamilah A.."). Both rows below keep the form our `race_candidates` already hold,
--     which is also AP's, because a preferred name and a typo are not claims about spelling.
--
-- ⚠ "DENISE DANIELS FANNING" IS SPLIT (Denise | Fanning) AND THE SPLIT IS A JUDGEMENT. The
--   Legislature prints the full name without telling us where the surname starts. The split kept
--   here is the one our own `race_candidates` row already uses, which is what the duplicate-name
--   guard reads; `full_name` carries all three words. If the chamber later sorts her under
--   "Daniels Fanning", the surname moves and the full name does not.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT THIS FILE OVERWRITES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 THIRTEEN `race_candidates.politician_id` VALUES, AND THE VALUE OVERWRITTEN IS **NULL** ON
--    ALL THIRTEEN. That is a measurement, not an inference: the UPDATE below is guarded
--    `WHERE politician_id IS NULL`, and assertion 2 refuses unless all thirteen moved. No other
--    column of `race_candidates` is touched — not `is_incumbent`, which is correctly FALSE on
--    all thirteen (none of them held the seat they won; Gallant held AD23, not SD20), not
--    `result`, not `source`.
--
-- 🔴 THE TWELVE NEW ROWS CARRY EXPLICIT IDs rather than `gen_random_uuid()`. Two reasons, and
--    the second is the load-bearing one:
--      • the file records exactly which rows it created, so they are reversible by id;
--      • CC_0467's selection digest is computed over these ids. `office_pending_winner` reads
--        the winner's `politician_id`, so the digest CHANGES the moment this file commits. With
--        generated ids, CC_0467 could not be written until this one had been applied — and a
--        pin derived after the fact is a pin nobody rehearsed.
--
-- 🔴 NOBODY IS SEATED HERE AND NO TERM IS WRITTEN. A winner who has not taken office is not an
--    officeholder. `essentials.politicians` no longer carries `is_incumbent` at all (CA_0378),
--    so there is no flag on these rows to get wrong; incumbency is read from `office_terms` via
--    `isIncumbentSql()`.

BEGIN;

CREATE TEMP TABLE cc0466_people (
  seat       text,
  office_id  uuid,
  person_id  uuid,
  full_name  text,
  first_name text,
  last_name  text,
  party      text,
  create_row boolean
) ON COMMIT DROP;

INSERT INTO cc0466_people VALUES
  ('Assembly District 1',  'b86066ac-2856-404f-97b4-a0819b388765', 'e7945f1f-901f-42c6-aa26-24df1d75ec07', 'Alexis Elizabeth Esparza', 'Alexis', 'Esparza',     'Democratic', true),
  ('Assembly District 2',  'fdd01e46-03b4-494c-9eef-ff5ce11d8c6a', '1ef65d9d-663b-4e0c-b2f6-99080588aef7', 'Kamilah Bywaters',        'Kamilah','Bywaters',    'Democratic', true),
  ('Assembly District 4',  'b83c9282-c492-4e70-9d3a-22fd88c3f8a9', 'cf10bc97-9e95-4999-ae4b-150efd546516', 'Eileen Eady',             'Eileen', 'Eady',        'Democratic', true),
  ('Assembly District 7',  '1e8cf3e9-619e-4dfe-bbb8-3bfa68acee2f', '7fa43c49-867d-4469-b338-970fb2121217', 'Cameron Miller',          'Cameron','Miller',      'Democratic', true),
  ('Assembly District 9',  '211e3941-ef3e-43dc-ba84-daa06750556f', 'd7fc5a2d-7512-4db8-ae39-6dfc5e540244', 'Ryan Hampton',            'Ryan',   'Hampton',     'Democratic', true),
  ('Assembly District 13', '8c332f48-e372-4dc7-aacf-77fb32fc1e0b', '23d205ae-9a2c-4ff9-a669-8e9e96818ec2', 'Daniel Andrews',          'Daniel', 'Andrews',     'Democratic', true),
  ('Assembly District 15', '5ea69a06-2f2e-4ccf-9162-a0b547d2aea8', '40d42063-72d1-49e3-a927-3766c5d3364a', 'Miguel Dávila',           'Miguel', 'Dávila',      'Democratic', true),
  ('Assembly District 23', 'd9caa623-92e8-4a55-9b0a-9a868aa9d1bd', '35bff896-c959-4b6d-b886-d052655db8ea', 'Denise Daniels Fanning',  'Denise', 'Fanning',     'Republican', true),
  ('Assembly District 29', '4739e270-01dc-46ca-bfda-72a3abf48bbb', '0192e29f-f555-4537-9d6f-7a38c56aa3dd', 'Alex J. Pereszlenyi',     'Alex',   'Pereszlenyi', 'Democratic', true),
  ('Assembly District 35', '78273ecf-398a-4c99-861b-cc820bd5a6c3', 'b8b63078-c451-4956-8c73-6eed933d1358', 'Joe Spica',               'Joe',    'Spica',       'Democratic', true),
  ('Assembly District 40', '9c57c7bb-9d58-4ee9-9b27-81870e159cef', '37fbc68b-ec78-47cb-8a57-cf748ee08401', 'Julie A. Butler',         'Julie',  'Butler',      'Republican', true),
  ('Assembly District 41', 'c2fd147e-f146-4f8f-8c78-0caf74aaa3e9', 'd6515b86-0c09-4dfe-af25-fd2d7885ad6e', 'Vinny Spotleson',         'Vinny',  'Spotleson',   'Democratic', true),
  -- 🔴 THE ONE THAT IS LINKED, NOT CREATED.
  ('State Senate District 20', '75e754bb-48c4-4224-a252-0694a1f7176a', '6cffc86c-7d40-4fd9-8690-51d6d33ff1e4', 'Danielle Gallant', 'Danielle', 'Gallant', 'Republican', false);

-- The thirteen winner rows this file links, found through the race rather than by name.
CREATE TEMP TABLE cc0466_rc ON COMMIT DROP AS
SELECT rc.id AS race_candidate_id, pp.seat, pp.person_id, pp.create_row,
       rc.politician_id AS politician_id_before, rc.full_name AS rc_full_name
  FROM cc0466_people pp
  JOIN essentials.races r      ON r.office_id = pp.office_id
  JOIN essentials.elections e  ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won';

CREATE TEMP TABLE cc0466_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.politicians)    AS politicians,
       (SELECT count(*) FROM essentials.office_terms)   AS terms,
       (SELECT count(*) FROM essentials.race_candidates) AS race_candidates;

DO $$
DECLARE n bigint;
BEGIN
  -- P1 — exactly thirteen winner rows, one per seat, and every one of them unlinked.
  SELECT count(*) INTO n FROM cc0466_rc;
  IF n <> 13 THEN
    RAISE EXCEPTION 'P1: % winner rows matched the thirteen seats, expected 13. The data moved '
                    'under this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0466_rc WHERE politician_id_before IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % of the thirteen winner rows already carry a politician_id. This file '
                    'would overwrite a link it has not recorded.', n;
  END IF;

  -- P2 — this file has not already been applied. Asked before P3, because after an apply the
  -- twelve rows exist and P3 would report "somebody beat me to these names" when what happened
  -- is that this file ran twice.
  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN cc0466_people pp ON pp.person_id = p.id AND pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the twelve new politician ids already exist. Applied before.', n;
  END IF;

  -- P3 — 🔴 NOBODY WITH THESE NAMES IS ALREADY IN THE TABLE. The duplicate-name guard's own
  --    predicate, (first_name, last_name), run over the WHOLE table including archived rows —
  --    because an archived duplicate is still a duplicate and `is_active` does not hide it from
  --    this check.
  SELECT count(*) INTO n
    FROM cc0466_people pp
    JOIN essentials.politicians p ON lower(p.first_name) = lower(pp.first_name)
                                 AND lower(p.last_name)  = lower(pp.last_name)
   WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % existing politician row(s) already carry one of the twelve names. '
                    'ONE ROW PER PERSON — read the row before creating a second.', n;
  END IF;

  -- P4 — the one we are linking is the one we think it is, by id and by name.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = '6cffc86c-7d40-4fd9-8690-51d6d33ff1e4'
     AND full_name = 'Danielle Gallant' AND is_active;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P4: the existing Danielle Gallant row is not where this file expects it.';
  END IF;
END $$;

-- ─── 1. The twelve people we do not hold ─────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, party, is_active, source)
SELECT pp.person_id, pp.full_name, pp.first_name, pp.last_name, pp.party, true,
       'Nevada Legislature''s own member page for ' || pp.seat || ', '
         || 'https://www.leg.state.nv.us/App/Legislator/A/'
         || CASE WHEN pp.seat LIKE 'Assembly%' THEN 'Assembly' ELSE 'Senate' END
         || '/Current/' || regexp_replace(pp.seat, '\D', '', 'g')
         || ', read 2026-11-23. The site has rolled to Session/84th2027 and names this person as '
         || 'the CURRENT member of that district, which is the chamber''s own statement and '
         || 'outranks any aggregator. Winner of the 2026-11-03 general election; the result is '
         || 'recorded in race_candidates from AP''s per-state feed, cross-read against the '
         || 'Secretary of State''s results behind silverstateelection.nv.gov. Created by CC_0466; '
         || 'NOT seated here.'
         || CASE WHEN pp.last_name = 'Dávila'
                 THEN ' ⚠ AP renders this surname "Davila" without the accent; the Legislature '
                      || 'writes "D&#225;vila" and the chamber''s spelling is the one kept.'
                 ELSE '' END
  FROM cc0466_people pp
 WHERE pp.create_row;

-- ─── 2. The thirteen winner rows get their person ────────────────────────────────────────────
-- 🔴 GUARDED `IS NULL`. The pre-image recorded above says every one of the thirteen was NULL;
--    this guard makes the file unable to overwrite anything else even if that stopped being
--    true between writing and applying.
UPDATE essentials.race_candidates rc
   SET politician_id = c.person_id
  FROM cc0466_rc c
 WHERE rc.id = c.race_candidate_id
   AND rc.politician_id IS NULL;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0466_before;

  -- 1. Twelve people created, and exactly twelve, repo-wide.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians + 12 THEN
    RAISE EXCEPTION '1: politicians went % -> %, a delta of %, expected 12.',
      b.politicians, n, n - b.politicians;
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN cc0466_people pp ON pp.person_id = p.id AND pp.create_row
   WHERE p.full_name = pp.full_name AND p.is_active AND p.source LIKE '%CC_0466%';
  IF n <> 12 THEN
    RAISE EXCEPTION '1: % of the twelve new rows read back correctly.', n;
  END IF;

  -- 2. All thirteen winner rows are linked, and to the right person.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc JOIN cc0466_rc c ON c.race_candidate_id = rc.id
   WHERE rc.politician_id = c.person_id;
  IF n <> 13 THEN
    RAISE EXCEPTION '2: % of 13 winner rows carry the intended politician_id.', n;
  END IF;

  -- 3. 🔴 THE ACCENT SURVIVED THE ROUND TRIP. An encoding fault on the way in or the way out
  --    looks exactly like missing content, and this surname is the one place in the file where
  --    that would be silent.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = '40d42063-72d1-49e3-a927-3766c5d3364a'
     AND full_name = 'Miguel Dávila' AND last_name = 'Dávila';
  IF n <> 1 THEN
    RAISE EXCEPTION '3: the AD15 row does not read back as "Miguel Dávila". The accent was lost '
                    'somewhere between this file and the column.';
  END IF;

  -- 4. Danielle Gallant is still ONE row. The whole point of treating her differently.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE lower(first_name) = 'danielle' AND lower(last_name) = 'gallant';
  IF n <> 1 THEN
    RAISE EXCEPTION '4: % Danielle Gallant rows exist, expected 1.', n;
  END IF;

  -- 5. NOBODY WAS SEATED. This file creates people; CC_0467 writes terms.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms THEN
    RAISE EXCEPTION '5: office_terms moved % -> %. This file seats nobody.', b.terms, n;
  END IF;

  -- 6. No candidacy was created or removed — thirteen existing rows were linked, that is all.
  SELECT count(*) INTO n FROM essentials.race_candidates;
  IF n <> b.race_candidates THEN
    RAISE EXCEPTION '6: race_candidates moved % -> %.', b.race_candidates, n;
  END IF;

  -- 7. 🔴 THE WAVE CAN NOW SEE ALL 52 WINNERS. This is the measurement CC_0467's P5 depends on,
  --    taken here while the pre-image is still in hand.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
   WHERE lower(d.state) = 'nv' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03'
     AND (win.value ->> 'id') IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '7: % Nevada legislative winner(s) still have no person record.', n;
  END IF;

  RAISE NOTICE 'CC_0466 OK: 12 politicians created, 1 linked (Danielle Gallant, already held), '
               '13 race_candidates rows moved from NULL to a person, 0 terms written.';
END $$;

COMMIT;
