-- CC_0492 — Oregon: create the 13 legislative winners we do not hold, and link the 2 we do.
--
-- 15 of the 75 Oregon legislative winners have no `politicians` row. This file settles all 15:
-- it creates 13 people and links 2 existing ones. It seats nobody and writes no term.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 `winner_no_record` MEANS "NO RECORD IN THIS RACE", NEVER "NO RECORD ANYWHERE"
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `derive-seating-wave.mjs` reports all 15 as `winner_no_record`, which is a fact about
-- `race_candidates.politician_id` and not about the person. Nevada: 1 of 13 already existed.
-- Maine: 18 of 77. Massachusetts: 3 of 21. **Oregon: 2 of 15.** `DATES.md` § OR reads the
-- blocker as "15 winners have no `politicians` row", which is true of the LINK and false of two
-- of the people.
--
-- The whole table was swept before anybody was created: on `(first_name, last_name)`, on
-- `full_name`, and by surname across every row including archived ones. Then every one of the
-- 15 was checked against the **300 sitting Oregon officeholders** this database holds, with the
-- two known matches planted in the same query as a positive control — a sweep that returns
-- "nothing found" and has never been seen finding anything is not a sweep.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 NEITHER LINK RESTS ON A NAME, AND THE MASSACHUSETTS GUARD WOULD HAVE FAILED ON ONE
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- **1. Jeff Helfrich** holds **State House District 52** and wins **State Senate District 26**.
--   Three independent facts, none of them his name:
--   • **His House seat is in this same wave and is won by a DIFFERENT person** — Hank Sanders,
--     created by this file. That is the chamber-switch pattern, visible in our own rows.
--   • **Or. Const. Art. IV Sec. 6(5) says a senatorial district is made of two representative
--     districts**, and the Legislature's own Chief Clerk publishes the pairing: Senate district
--     N comprises House districts 2N-1 and 2N. **SD 26 = HD 51 + HD 52.** So the seat he holds
--     is *inside* the seat he won, and that is arithmetic rather than a story. P6 computes it.
--   • The Oregon Legislature's own member page names him: *"Representative - Jeff Helfrich,
--     Republican - District 52"* (https://www.oregonlegislature.gov/helfrich, HTTP 200, read
--     2026-11-23; 11,699 characters of real page text, not a navigation shell).
--
--   ⚠ **AND THE MASSACHUSETTS GUARD — "the surname is unique in the table" — IS FALSE HERE.**
--     Two rows carry the surname Helfrich: Jeff (Oregon HD 52) and **Beth Helfrich (North
--     Carolina State House District 98)**, an unrelated person. The guard fails correctly, which
--     is exactly why the link is made on the structure instead. ▶ **A guard that held in one
--     state is not a guard; carry the reasoning, not the predicate.**
--
-- **2. Tammy Carpenter** holds **Director, Zone 7, Beaverton School District 48J** and wins
--   **State House District 27**. 🔴 **This one is linked on a DOCUMENT, because nothing
--   structural connects a school board seat to a House seat.**
--   • The Oregon Secretary of State's official **Voters' Pamphlet** for this election, Washington
--     County book, State Representative 27th District, Tammy Carpenter (Democrat, Progressive,
--     Working Families), prints her own filed statement:
--         **"Prior Governmental Experience: Beaverton School Board Member"**
--     (https://sos.oregon.gov/elections/Voters-Pamphlet/Documents/VP_G26-Book12_web.pdf, HTTP
--     200, 9,321,037 bytes, read 2026-11-23.) That is the candidate's own declaration, in the
--     state's own publication, naming the exact body whose seat she holds in our data.
--   • Exactly one row in the table is named Tammy Carpenter, and she holds exactly one open
--     Oregon seat, which is that school directorship. P7 asserts both.
--   ⚠ **THE PAMPHLET PRINTS TWO CANDIDATES SIDE BY SIDE AND A LINE-ORDER READ MIXES THEM.**
--     `pdftotext -layout` interleaves the two columns, so the "Prior Governmental Experience"
--     line sits among her opponent's sentences. The columns were separated by their own
--     terminators — each ends with "(This information furnished by …)" naming its own candidate,
--     hers at the left margin and G Mark Norman's indented. ▶ **Bound a PDF column by the
--     document's own structure, not by reading order.**
--
-- 🟢 **SHE WILL THEN HOLD TWO SEATS FROM 2027-01-11, AND THAT IS CORRECT.** Her Beaverton
--   directorship is not in this wave and nothing in this pass ends it, so `CC_0493` leaves it
--   open and gates on finding exactly one such seat. This is the Utah shape without the defect:
--   Doug Fiefia kept a House seat because its RESULT was missing; Tammy Carpenter keeps a school
--   seat because its TERM has not ended. ▶ **Do not tidy either one.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 EVERY NAME IN THIS FILE WAS CONFIRMED AGAINST THE STATE'S OWN RESULTS
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Our winners come from the AP race calls. Before anybody was created, all 75 were compared
-- candidate by candidate against the **Oregon Secretary of State's own results export** —
-- 75 contests parsed, 75 agree, 0 disagree, 0 missing, with one name deliberately corrupted
-- first and the comparison watched going red. See `CC_0493`'s header for the route.
--
-- ⚠ **THE TWO SOURCES SPELL MIDDLE INITIALS DIFFERENTLY, AND THE BALLOT NAME WINS.** The SoS
--   export strips the point — "Michael W Sugar", "Denise D Krause", "Myrna A Munoz" — where the
--   ballot name and the Voters' Pamphlet keep it. These rows are created under the name the
--   election recorded, with the point.
--
-- 🔴 `party` is deliberately NULL on all 13. Parties are not something this platform records
--    except where a one-party primary makes it load-bearing for the election itself.
--
-- Sources, read 2026-11-23:
--   https://www.oregonlegislature.gov/helfrich  and  …/house/Pages/RepresentativesAll.aspx
--     (the chamber's own roster — it carries Helfrich and Mannix and does NOT carry Virginia
--     Stapleton, which is how "she is not a sitting member" was settled rather than assumed)
--   https://www.oregonlegislature.gov/chief-clerk/Documents/House Districts To Senate
--     Districts.pdf  (the Chief Clerk's own House-to-Senate pairing)
--   https://sos.oregon.gov/elections/Voters-Pamphlet/Documents/VP_G26-Book12_web.pdf
--   https://results.oregonvotes.gov/ResultsExport.aspx  (the legislative results export)

BEGIN;

CREATE TEMP TABLE cc0492_people (
  seat       text,
  office_id  uuid,
  person_id  uuid,
  full_name  text,
  first_name text,
  last_name  text,
  create_row boolean
) ON COMMIT DROP;

INSERT INTO cc0492_people VALUES
  ('State House District 7',   'c2cb6564-dfe1-4732-80ca-f26306d79ce4', 'e7dac0ac-f294-43b8-9eb0-f5be4022b4b2', 'Kori Rodley',        'Kori',     'Rodley',     true),
  ('State House District 9',   'f087ae89-9f4b-40ca-b59f-809fc4c580ea', '00376832-25d0-4739-a185-3fa59e33bcd8', 'Claire Lynn',        'Claire',   'Lynn',       true),
  ('State House District 11',  '8a748e6d-201b-448a-95df-266bc58cbc8d', '39345779-a4ce-44af-8e15-48437813c282', 'Ken Jackola',        'Ken',      'Jackola',    true),
  ('State House District 17',  '256d18b4-8cc2-43b3-92e6-dbd55426df57', 'f7d052ae-c1b1-4811-b3da-2497f3370c75', 'Dan Farrington',     'Dan',      'Farrington', true),
  ('State House District 18',  'd24e2f76-4e10-47ee-9367-0d21c67e4a30', '1c71ea14-d757-479e-98a0-af3991ef0d79', 'Amanda Staehely',    'Amanda',   'Staehely',   true),
  ('State House District 21',  '2973f4b4-0011-4937-9b62-bd2f2aa496f9', 'ff302220-502e-43c8-8cde-be9198eab460', 'Michael Welsh',      'Michael',  'Welsh',      true),
  ('State House District 27',  '40e2b73e-4f5e-4f1a-919f-da47a9f5002d', 'b77caa26-b55a-4d98-a74c-cb210542b16e', 'Tammy Carpenter',    'Tammy',    'Carpenter',  false),
  ('State House District 40',  '986fe7c3-83d6-4794-b346-fb8184e35d37', '0b7f7f98-ce81-4122-8075-5d4adfb5c8ae', 'Michael W. Sugar',   'Michael',  'Sugar',      true),
  ('State House District 52',  'c8b17d79-a296-4432-9fb5-61ac085ccbb7', '193b32fc-7470-4447-81eb-548a24e4e4f0', 'Hank Sanders',       'Hank',     'Sanders',    true),
  ('State Senate District 3',  '01991c03-e4e2-43c1-85bd-40273f3a96d5', '7c4dbd78-ad57-492f-8961-b0e8073d8cc3', 'Denise D. Krause',   'Denise',   'Krause',     true),
  ('State Senate District 6',  '1dddd7a3-773a-493d-a446-9e8757f3fe16', '74cf44ee-4f35-43d5-b616-164a152c09e1', 'Jack Tibbetts',      'Jack',     'Tibbetts',   true),
  ('State Senate District 11', 'a8868a1e-4e24-4d08-adb4-7a9ef6d84e91', '6f831148-95eb-4b1f-ad76-ff66dac9c22a', 'Virginia Stapleton', 'Virginia', 'Stapleton',  true),
  ('State Senate District 15', 'a6c31021-d148-4237-b524-e704f7e82e84', '9ccb7b09-1345-4fe8-ab3e-f310a01ec5ae', 'Myrna A. Munoz',     'Myrna',    'Munoz',      true),
  ('State Senate District 16', 'a6f28a55-1d10-4b5b-9e7d-706ec4f97b9f', '104a0792-ed43-44ae-a11e-4b67101d629e', 'Courtney Bangs',     'Courtney', 'Bangs',      true),
  ('State Senate District 26', '3103a291-f637-4632-9164-89b042ea1ef0', '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c', 'Jeff Helfrich',      'Jeff',     'Helfrich',   false);

-- The 15 winner rows this file links, found through the RACE rather than by name.
CREATE TEMP TABLE cc0492_rc ON COMMIT DROP AS
SELECT rc.id AS race_candidate_id, pp.seat, pp.person_id, pp.create_row, pp.full_name,
       rc.full_name AS ballot_name, rc.politician_id AS politician_id_before
  FROM cc0492_people pp
  JOIN essentials.races r            ON r.office_id = pp.office_id
  JOIN essentials.elections e        ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won';

CREATE TEMP TABLE cc0492_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.politicians)     AS politicians,
       (SELECT count(*) FROM essentials.office_terms)    AS terms,
       (SELECT count(*) FROM essentials.race_candidates) AS race_candidates,
       (SELECT count(*) FROM essentials.office_terms
         WHERE politician_id = 'b77caa26-b55a-4d98-a74c-cb210542b16e'
           AND term_end IS NULL)                         AS carpenter_open_seats;

DO $$
DECLARE n bigint; sd int; hd int; lo int; hi int;
BEGIN
  -- P1 — exactly 15 winner rows, one per seat, and every one of them unlinked.
  SELECT count(*) INTO n FROM cc0492_people;
  IF n <> 15 THEN
    RAISE EXCEPTION 'P1: the file lists % people, expected 15.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0492_rc;
  IF n <> 15 THEN
    RAISE EXCEPTION 'P1: % winner rows matched the 15 seats, expected 15. The data moved under '
                    'this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0492_rc WHERE politician_id_before IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % of the 15 winner rows already carry a politician_id. This file would '
                    'overwrite a link it did not make.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0492_people WHERE create_row;
  IF n <> 13 THEN
    RAISE EXCEPTION 'P1: % rows are marked for creation, expected 13 (15 less the 2 sitting '
                    'officials).', n;
  END IF;

  -- 🔴 THE BALLOT NAME AND THE NAME THIS FILE WRITES MUST AGREE, EXACTLY. A person is created
  -- under the name the election recorded. ⚠ The Secretary of State's results export strips the
  -- point from a middle initial; the ballot name keeps it, and the ballot name is what is used.
  SELECT count(*) INTO n FROM cc0492_rc WHERE ballot_name IS DISTINCT FROM full_name;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % winner row(s) carry a ballot name this file does not reproduce '
                    'exactly.', n;
  END IF;

  -- P2 — this file has not already been applied. Asked before P3, because after an apply the 13
  -- new names ARE in the table and P3 would report them as collisions.
  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN cc0492_people pp ON pp.person_id = p.id WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 13 new politician ids already exist. Applied before.', n;
  END IF;

  -- P3 — 🔴 NOBODY WITH THESE NAMES IS ALREADY IN THE TABLE. This is the duplicate-name guard's
  -- own predicate, (first_name, last_name), run before the insert rather than after the fact.
  SELECT count(*) INTO n
    FROM cc0492_people pp
    JOIN essentials.politicians p
      ON p.first_name = pp.first_name AND p.last_name = pp.last_name
   WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % existing politician row(s) already carry one of the 13 names. ONE ROW '
                    'PER PERSON — read the row before creating a second.', n;
  END IF;

  -- P3b — ⚠ AND THE GUARD ABOVE IS BLIND TO A FULL NAME SPLIT DIFFERENTLY, so the same question
  -- is asked a second way, on `full_name`, across archived rows too.
  SELECT count(*) INTO n
    FROM cc0492_people pp
    JOIN essentials.politicians p ON lower(p.full_name) = lower(pp.full_name)
   WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3b: % existing politician row(s) carry one of the 13 full names, which the '
                    '(first_name, last_name) guard above did not see.', n;
  END IF;

  -- P4 — both link targets exist, are active, and already HOLD an Oregon office. A link to
  -- somebody with no Oregon seat is the Mark Harris shape.
  SELECT count(*) INTO n
    FROM cc0492_people pp
    JOIN essentials.politicians p ON p.id = pp.person_id
   WHERE NOT pp.create_row
     AND p.is_active
     AND EXISTS (SELECT 1 FROM essentials.office_terms t
                   JOIN essentials.offices o   ON o.id = t.office_id
                   JOIN essentials.districts d ON d.id = o.district_id
                  WHERE t.politician_id = p.id AND lower(d.state) = 'or'
                    AND t.term_end IS NULL);
  IF n <> 2 THEN
    RAISE EXCEPTION 'P4: only % of the 2 link targets are an active politician currently holding '
                    'an Oregon office.', n;
  END IF;

  -- P5 — 🔴🔴 THE CHAMBER SWITCHER IS LINKED ON A STRUCTURAL FACT, NOT ON HIS NAME. Jeff
  -- Helfrich must currently hold an Oregon HOUSE seat that is ITSELF in this file and won by a
  -- DIFFERENT person. That is what makes "he vacated his seat to run for the Senate" a
  -- measurement instead of a story.
  SELECT count(*) INTO n
    FROM cc0492_people pp
    JOIN essentials.office_terms t ON t.politician_id = pp.person_id AND t.term_end IS NULL
    JOIN essentials.offices o      ON o.id = t.office_id
    JOIN essentials.districts d    ON d.id = o.district_id
                                  AND d.district_type = 'STATE_LOWER' AND lower(d.state) = 'or'
    JOIN cc0492_people vacated     ON vacated.office_id = o.id
   WHERE pp.seat = 'State Senate District 26'
     AND vacated.person_id <> pp.person_id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'P5: % — Jeff Helfrich does not currently hold an Oregon House seat that is '
                    'in this file and won by somebody else, expected exactly 1 (House District '
                    '52, won by Hank Sanders). Without that, the link rests on the name alone.',
                    n;
  END IF;

  -- P6 — 🟢🟢 AND THE SEAT HE HOLDS SITS INSIDE THE SEAT HE WON, BY ARITHMETIC. Or. Const. Art.
  -- IV Sec. 6(5) speaks of "the two representative districts comprising the senatorial district",
  -- and the Chief Clerk's own mapping pairs House districts 2N-1 and 2N into Senate district N.
  -- SD 26 = HD 51 + HD 52. ⚠ THE MASSACHUSETTS GUARD ("the surname is unique in the table") IS
  -- FALSE HERE — Beth Helfrich holds North Carolina House District 98 — which is precisely why
  -- the link is made on this instead.
  SELECT (regexp_replace(pp.seat, '\D', '', 'g'))::int INTO sd
    FROM cc0492_people pp WHERE pp.seat = 'State Senate District 26';
  SELECT (regexp_replace(d.label, '\D', '', 'g'))::int INTO hd
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = '701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c' AND t.term_end IS NULL
     AND d.district_type = 'STATE_LOWER' AND lower(d.state) = 'or';
  -- ⚠ THE PAIRING IS COMPUTED ONCE AND READ BY BOTH THE CONDITION AND ITS MESSAGE. A control
  --   that changed only the condition printed "comprises House districts 51 and 52" while
  --   testing against 53 and 54 — a gate that restates its own expectation as a second copy of
  --   the formula can print a self-contradiction.
  lo := 2 * sd - 1;
  hi := 2 * sd;
  IF sd IS NULL OR hd IS NULL OR hd NOT IN (lo, hi) THEN
    RAISE EXCEPTION 'P6: Jeff Helfrich holds House district % and wins Senate district %, but an '
                    'Oregon senatorial district comprises House districts % and % (Art. IV Sec. '
                    '6(5), and the Chief Clerk''s own pairing). The seat he holds is not inside '
                    'the seat he won, so the chamber-switch reading is wrong.',
                    hd, sd, lo, hi;
  END IF;

  -- P7 — 🔴 TAMMY CARPENTER IS LINKED ON A DOCUMENT, AND THE DATA SIDE OF IT IS ASSERTED HERE.
  -- Exactly one row carries her name, and she holds exactly one open Oregon seat, which must be
  -- the Beaverton School District 48J directorship her Voters' Pamphlet statement names.
  SELECT count(*) INTO n FROM essentials.politicians WHERE full_name = 'Tammy Carpenter';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: % politician row(s) are named Tammy Carpenter, expected exactly 1. The '
                    'Voters'' Pamphlet ties the House District 27 candidate to "Beaverton School '
                    'Board Member"; with two candidates for that row it ties it to neither.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.office_terms t
    JOIN essentials.offices o   ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE t.politician_id = 'b77caa26-b55a-4d98-a74c-cb210542b16e' AND t.term_end IS NULL
     AND lower(d.state) = 'or' AND d.district_type = 'SCHOOL'
     AND d.label = 'Beaverton School District 48J';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P7: the Tammy Carpenter row holds % open Beaverton School District 48J '
                    'seat(s), expected 1. That seat IS the evidence for this link — her own '
                    'filed statement in the Secretary of State''s Voters'' Pamphlet gives her '
                    'prior governmental experience as "Beaverton School Board Member".', n;
  END IF;

  -- P8 — no person is used twice. 15 seats, 15 distinct people.
  SELECT count(*) INTO n FROM (
    SELECT person_id FROM cc0492_people GROUP BY person_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % person id(s) appear on more than one seat.', n;
  END IF;

  -- P9 — every one of the 15 seats is one of Oregon's pending legislative seats. A seat that
  -- has left the wave would be linked here and seated nowhere.
  SELECT count(*) INTO n
    FROM cc0492_people pp
    JOIN essentials.office_pending_winner w ON w.office_id = pp.office_id
                                           AND w.election_date = DATE '2026-11-03';
  IF n <> 15 THEN
    RAISE EXCEPTION 'P9: % of the 15 seats are still pending for this election, expected 15.', n;
  END IF;
END $$;

-- ─── 1. The 13 people we do not hold ─────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, source)
SELECT pp.person_id, pp.full_name, pp.first_name, pp.last_name, true,
       'Winner of the 2026-11-03 general election for ' || pp.seat || ', Oregon. The result and '
         || 'the ballot spelling are AP''s per-state results feed, confirmed candidate by '
         || 'candidate against the Oregon Secretary of State''s own legislative results export '
         || '(https://results.oregonvotes.gov/ResultsExport.aspx, "House and Senate.csv", read '
         || '2026-11-23): 75 contests parsed, 75 agree, 0 disagree, 0 missing, with one name '
         || 'deliberately corrupted first and the comparison watched going red. ⚠ THE SoS EXPORT '
         || 'STRIPS THE POINT FROM A MIDDLE INITIAL ("Michael W Sugar", "Denise D Krause", '
         || '"Myrna A Munoz"); this row carries the ballot name, with the point. The whole '
         || 'politicians table was swept three ways before this row was created — on '
         || '(first_name, last_name), on full_name, and by surname across every row including '
         || 'archived ones — and every winner was then checked against the 300 sitting Oregon '
         || 'officeholders this database holds, with two known matches planted in the same '
         || 'query as a positive control. No existing person matched. `party` is deliberately '
         || 'NULL: parties are not something this platform records except where a one-party '
         || 'primary makes it load-bearing. Created by CC_0492; NOT seated here.'
  FROM cc0492_people pp
 WHERE pp.create_row;

-- ─── 2. All 15 winner rows get their person ──────────────────────────────────────────────────
-- 🔴 GUARDED `IS NULL`, so this file cannot overwrite a link that appeared between writing and
--    applying.
UPDATE essentials.race_candidates rc
   SET politician_id = c.person_id
  FROM cc0492_rc c
 WHERE rc.id = c.race_candidate_id
   AND rc.politician_id IS NULL;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0492_before;

  -- 1. 13 people created, and exactly 13, repo-wide.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians + 13 THEN
    RAISE EXCEPTION '1: politicians went % -> %, a delta of %, expected 13.',
      b.politicians, n, n - b.politicians;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.politicians p JOIN cc0492_people pp ON pp.person_id = p.id
   WHERE pp.create_row AND p.full_name = pp.full_name AND p.first_name = pp.first_name
     AND p.last_name = pp.last_name AND p.is_active AND p.party IS NULL;
  IF n <> 13 THEN
    RAISE EXCEPTION '1: % of the 13 new rows read back correctly, with a NULL party.', n;
  END IF;

  -- 2. All 15 winner rows carry the intended person.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc JOIN cc0492_rc c ON c.race_candidate_id = rc.id
   WHERE rc.politician_id = c.person_id;
  IF n <> 15 THEN
    RAISE EXCEPTION '2: % of 15 winner rows carry the intended politician_id.', n;
  END IF;

  -- 3. 🟢 TAMMY CARPENTER'S SCHOOL BOARD SEAT IS UNTOUCHED. This file links her to a House seat;
  --    it does not end anything she already holds, and CC_0493 will not either. She holds two
  --    seats from 2027-01-11 and that is correct.
  SELECT count(*) INTO n FROM essentials.office_terms
   WHERE politician_id = 'b77caa26-b55a-4d98-a74c-cb210542b16e' AND term_end IS NULL;
  IF n <> b.carpenter_open_seats THEN
    RAISE EXCEPTION '3: Tammy Carpenter''s open terms went % -> %. This file links a winner row '
                    'and touches no term at all.', b.carpenter_open_seats, n;
  END IF;

  -- 4. This file seats nobody and creates no race_candidates row.
  SELECT count(*) INTO n FROM essentials.office_terms;
  IF n <> b.terms THEN
    RAISE EXCEPTION '4: office_terms moved % -> %. This file seats nobody.', b.terms, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.race_candidates;
  IF n <> b.race_candidates THEN
    RAISE EXCEPTION '5: race_candidates moved % -> %. This file links rows; it creates none.',
      b.race_candidates, n;
  END IF;

  -- 6. 🔴 NOT ONE OREGON LEGISLATIVE WINNER IS LEFT WITHOUT A PERSON RECORD. This is the claim
  --    CC_0493's P5 depends on, measured here from the view itself.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
   WHERE lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03' AND (win.value ->> 'id') IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % Oregon legislative winner(s) still have no person record.', n;
  END IF;

  -- 7. ⚠ AND THE SEAT COUNT DID NOT MOVE. Linking a winner must not add or remove a pending
  --    seat; if it did, the selection CC_0493 pins is not the one measured here.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03';
  IF n <> 75 THEN
    RAISE EXCEPTION '7: % Oregon legislative seats are pending, expected 75.', n;
  END IF;

  RAISE NOTICE 'CC_0492 OK: 13 Oregon legislative winners created and 2 linked — Jeff Helfrich, '
               'vacating House District 52 in this same wave for Senate District 26, which Art. '
               'IV Sec. 6(5) and the Chief Clerk''s pairing say CONTAINS House District 52; and '
               'Tammy Carpenter, tied to her Beaverton School District 48J directorship by her '
               'own filed statement in the Secretary of State''s Voters'' Pamphlet, not by her '
               'name. She keeps that school seat and will hold two from 2027-01-11, which is '
               'correct. ⚠ The Massachusetts guard "the surname is unique" is FALSE here — Beth '
               'Helfrich holds North Carolina House District 98. All 75 Oregon legislative '
               'winners now have a person record; no terms written.';
END $$;

COMMIT;
