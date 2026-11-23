-- CC_0482 — Massachusetts: create the 18 legislative winners we do not hold, and link the 3 we
-- already do.
--
-- 21 of the 199 Massachusetts legislative winners have no `politicians` row. This file settles
-- all 21: it creates 18 people and links 3 existing ones. It seats nobody and writes no term.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 `winner_no_record` MEANS "NO RECORD IN THIS RACE", NEVER "NO RECORD ANYWHERE"
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `derive-seating-wave.mjs` reports all 21 as `winner_no_record`, which is a fact about
-- `race_candidates.politician_id` and not about the person. Nevada: 1 of 13 already existed.
-- Maine: 18 of 77. **Massachusetts: 3 of 21.** The whole `politicians` table was swept before
-- anybody was created — twice, once by surname across every row including archived ones, and
-- once on `full_name` containing both the first and last name.
--
-- 🔴 **AND THE SWEEP IS NOT THE EVIDENCE. A FULL-NAME MATCH IS NOT AN IDENTITY** — this
--    repository has shipped Mark Harris as NC-8. Each of the three links below is made on a
--    structural fact that is independent of the name, and P4-P6 assert that fact rather than the
--    name:
--
--   • **Kate Lipper-Garabedian** holds the **32nd Middlesex District** (House) and wins the
--     **Fifth Middlesex District** (Senate). Her House seat is in this same wave and is won by a
--     DIFFERENT, newly created person (Leila Bhatti Migliorelli). That is the chamber-switch
--     pattern, visible in our own rows: a member vacates to run for the other chamber and a
--     newcomer takes the seat.
--   • **Erika Uyterhoeven** holds the **27th Middlesex District** (House) and wins the **Second
--     Middlesex District** (Senate). Her House seat is likewise won by a different person in this
--     wave (Ben Ewen-Campen).
--   • **Ben Ewen-Campen** holds a **Somerville Ward 3 city council seat** and wins the 27th
--     Middlesex District, a Somerville House seat. The surname is hyphenated and unique in the
--     table: exactly one row carries it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 ONE NAME WAS *NOT* LINKED, DELIBERATELY, AND THE DUPLICATE IS RECORDED RATHER THAN HIDDEN
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- The 34th Middlesex District is won by **"Will Mbah"**. The table already holds **"Wilfred N.
-- Mbah"** (id `9b11117c-d064-404b-8c89-0042f417c576`), a Somerville city councilor seeded from
-- the same batch as Ben Ewen-Campen — their `external_id`s are `-2562535003` and `-2562535008`.
-- The 34th Middlesex is a Somerville seat. **These are very probably the same person.**
--
-- 🔴 **"VERY PROBABLY" IS NOT EVIDENCE, AND THE NAMES DO NOT MATCH.** Somerville's own council
--    roster (https://www.somervillema.gov/departments/city-council and the councilor's own page,
--    both read 2026-11-23, HTTP 200) writes him **"Wilfred N. Mbah"** and **never once "Will"**.
--    The ballot name comes from AP cross-read against the Secretary of the Commonwealth's
--    candidate list, and that gives **"Will Mbah"**. No document consulted ties the two names to
--    one person.
--
-- ▶ **SO THIS FILE CREATES A NEW ROW AND RECORDS THE SUSPECTED DUPLICATE IN THE PERSON'S OWN
--   `source`.** The two errors are not symmetric: a duplicate person is a visible gap that
--   `reference_person_merge_policy` exists to resolve, and it is reversible by archiving one row;
--   a wrong link publishes a false claim about a named real person on a public page and is not.
--   **A merge is OWED on this row** the moment a document ties the ballot name to the councilor —
--   the councilor's own biography, a campaign filing giving his full name, or the General Court's
--   member roster once he is sworn.
--
-- 🔴 Do not resolve it by deleting either row. ONE ROW PER PERSON, ARCHIVE AND NEVER DELETE.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE DUPLICATE-NAME GUARD'S OWN BLIND SPOT, CHECKED SEPARATELY
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- 🔴 The guard keys on `(first_name, last_name)`, so an identical `full_name` **split
--    differently** is invisible to it. P3 asserts the guard's own predicate across all 18 new
--    people; the two sweeps above covered the shape the guard cannot see. Measured 2026-11-23:
--    **no collisions on either.**
--
-- ⚠ The `Lisa Lopez` search returned two archived `cal_access_discovery` rows whose `full_name`
--   is a California COMMITTEE name containing "LOPEZ". They are not people, they carry no
--   `first_name`, and they are not a collision.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ `party` IS DELIBERATELY NULL ON ALL 18
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- Ruling, 2026-11-23: "Parties are not something we celebrate anywhere on our platform." A NULL
-- party is finished work, not a follow-up. Massachusetts has no one-party primary that would make
-- it load-bearing for the election itself.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ THIS FILE CHANGES THE SEATING FILE'S DIGEST, AND IT CHANGES IT TWICE OVER
-- ─────────────────────────────────────────────────────────────────────────────────────────────
--
-- `office_pending_winner` renders a winner with no person record as a NULL id, so linking 21
-- winners moves `CC_0483`'s selection digest. 🔴 **AND IT DOES SOMETHING SUBTLER THAT CALIFORNIA
-- PAID FOR:** `is_reelection` is computed as
-- `(winner id IS NOT NULL AND holder IS NOT NULL AND holder = winner id)`. Before this file, the
-- two flagged-vacant seats — 1st Franklin and 17th Middlesex — have a NULL **winner** id, so the
-- expression is FALSE. After it, the winner id exists and the HOLDER is NULL, so the expression
-- would be **NULL** unless the selection closes it. ▶ `CC_0483` closes it, and its digest is
-- captured AFTER this file. See that file's header.

BEGIN;

CREATE TEMP TABLE cc0482_people (
  seat       text,
  office_id  uuid,
  person_id  uuid,
  full_name  text,
  first_name text,
  last_name  text,
  create_row boolean
) ON COMMIT DROP;

INSERT INTO cc0482_people VALUES
  ('13th Middlesex District', 'c60006bd-df90-4638-8bce-9a9e605a5bcb', 'a62c833d-6907-4d2f-8368-8276cf823aaf', 'Ravi Simon', 'Ravi', 'Simon', true),
  ('16th Essex District', 'e6c936c2-1f0e-4e1f-befe-5507d8ff430d', '45548a6b-c832-4d29-a504-6228cecc3981', 'Celina A. Reyes', 'Celina', 'Reyes', true),
  ('16th Middlesex District', 'd58c7412-efc9-45f1-bc9f-ffb2b1f463e4', '550b73be-a04f-436e-8822-d4e37cd16dda', 'Lorena G. Betts', 'Lorena', 'Betts', true),
  ('17th Middlesex District', 'b45625f8-4c85-4924-b850-f2ba0fdf0c24', '074c2289-b3bd-4226-ac37-b0f3487148d5', 'John M. Drinkwater', 'John', 'Drinkwater', true),
  ('18th Essex District', '2204deff-887e-4b97-b5ea-b9fdf12a0698', 'ffeb3bfa-b5b0-4233-8c3c-b4bfa4f8b207', 'Connor A. Murray', 'Connor', 'Murray', true),
  ('1st Barnstable District', '64c60932-fc4e-4a6f-8bf2-113235a9af89', '1ce2d80c-a338-405e-a0b1-da5c6532f69e', 'Christopher Lambton', 'Christopher', 'Lambton', true),
  ('1st Franklin District', '4965c918-2024-4b4c-aaf1-a8b4ca45bfea', '492b8b02-d778-4c83-ae81-ca8e0653ea81', 'Lora L. Wondolowski', 'Lora', 'Wondolowski', true),
  ('1st Worcester District', '2d5fc308-1e42-4e8f-afd6-786994849783', '4077926b-2e8c-471b-b0b2-f31a22da823f', 'Krista Suzanne Ferrante', 'Krista', 'Ferrante', true),
  ('20th Middlesex District', '3194a56e-8354-4732-a81b-7ad3edf14104', '76c1539f-1685-4bf8-a82d-4e484fabda1f', 'Joseph Markey', 'Joseph', 'Markey', true),
  ('22nd Middlesex District', 'c3fabd25-2cec-41ef-a0fd-d435b4adcb19', 'c2fe7514-acd3-4895-b85f-c29d028ecdb8', 'Daniel Ronald Darris-O''Connor', 'Daniel', 'Darris-O''Connor', true),
  ('27th Middlesex District', '93781fcf-0085-4c78-80a0-3362b58aff10', '073a3e12-55bb-4c88-9bd9-3333b93f40cd', 'Ben Ewen-Campen', 'Ben', 'Ewen-Campen', false),
  ('2nd Worcester District', '97832067-3c80-4588-afff-c648a0996c52', 'e59efb92-0508-4dbf-872e-6e593bca167b', 'Michael Joseph Nicholson', 'Michael', 'Nicholson', true),
  ('32nd Middlesex District', 'b385eb71-cc88-4bb8-ac40-b6189cb29c1a', '7a9eb321-7d47-4dd5-a5b2-b55553ccf96a', 'Leila Bhatti Migliorelli', 'Leila', 'Migliorelli', true),
  ('34th Middlesex District', '2842d56f-2608-4fcc-962d-51d14469f054', '5a09e976-abea-4ac5-bd5c-8a23fb6cb169', 'Will Mbah', 'Will', 'Mbah', true),
  ('3rd Barnstable District', 'd341c6c6-3e35-4493-8986-c98a7c9753c0', 'd3af6b44-ba3d-417d-a7dd-9cafb9b7e498', 'Jack Peter Richardson', 'Jack', 'Richardson', true),
  ('6th Norfolk District', 'b631df47-e792-4ee1-92c3-6b4b6b336e9b', 'b49fc9cf-1412-4613-949b-8880249933b7', 'Lisa R. Lopez', 'Lisa', 'Lopez', true),
  ('8th Bristol District', 'cc6a6617-56b2-4a21-814c-f8b297756fb2', 'f2288d95-37d5-4082-b30e-16eaf7f48c68', 'Jesse W. St. Gelais', 'Jesse', 'St. Gelais', true),
  ('9th Bristol District', '42f065a2-72d4-457a-8a95-dd154bef4af5', '825b684e-66c6-4358-8f50-63a3f2b6772d', 'Edward M. Pacheco', 'Edward', 'Pacheco', true),
  ('Fifth Middlesex District', '58c80f50-6a02-43d5-a17d-f467b351af24', '37e88d74-8fdf-4a66-8685-989248512b29', 'Kate Lipper-Garabedian', 'Kate', 'Lipper-Garabedian', false),
  ('Norfolk and Suffolk District', '1c0bce90-1351-4799-ad2b-46616829e304', '0fddf0ac-0c25-462c-8fad-0cf2180ebbf8', 'Persis S. Yu', 'Persis', 'Yu', true),
  ('Second Middlesex District', 'b1ed4e2a-4a9c-4b41-9e46-8500f608e026', '98291d86-d42d-49d0-a5b2-d689a8154b15', 'Erika Uyterhoeven', 'Erika', 'Uyterhoeven', false);

-- The 21 winner rows this file links, found through the RACE rather than by name.
CREATE TEMP TABLE cc0482_rc ON COMMIT DROP AS
SELECT rc.id AS race_candidate_id, pp.seat, pp.person_id, pp.create_row, pp.full_name,
       rc.full_name AS ballot_name, rc.politician_id AS politician_id_before
  FROM cc0482_people pp
  JOIN essentials.races r      ON r.office_id = pp.office_id
  JOIN essentials.elections e  ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.result = 'won';

CREATE TEMP TABLE cc0482_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.politicians)     AS politicians,
       (SELECT count(*) FROM essentials.office_terms)    AS terms,
       (SELECT count(*) FROM essentials.race_candidates) AS race_candidates,
       (SELECT count(*) FROM essentials.politicians
         WHERE id = '9b11117c-d064-404b-8c89-0042f417c576')                 AS wilfred_mbah;

DO $$
DECLARE n bigint;
BEGIN
  -- P1 — exactly 21 winner rows, one per seat, and every one of them unlinked.
  SELECT count(*) INTO n FROM cc0482_people;
  IF n <> 21 THEN
    RAISE EXCEPTION 'P1: the file lists % people, expected 21.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0482_rc;
  IF n <> 21 THEN
    RAISE EXCEPTION 'P1: % winner rows matched the 21 seats, expected 21. The data moved under '
                    'this file.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0482_rc WHERE politician_id_before IS NOT NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % of the 21 winner rows already carry a politician_id. This file would '
                    'overwrite a link it did not make.', n;
  END IF;

  SELECT count(*) INTO n FROM cc0482_people WHERE create_row;
  IF n <> 18 THEN
    RAISE EXCEPTION 'P1: % rows are marked for creation, expected 18 (21 less the 3 sitting '
                    'officials).', n;
  END IF;

  -- 🔴 THE BALLOT NAME AND THE NAME THIS FILE WRITES MUST AGREE, EXCEPT WHERE THE HEADER SAYS
  -- THEY DO NOT. Exactly one row may differ, and it must be the 34th Middlesex.
  SELECT count(*) INTO n FROM cc0482_rc WHERE ballot_name IS DISTINCT FROM full_name;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P1: % winner row(s) carry a ballot name this file does not reproduce '
                    'exactly. A person is created under the name the election recorded.', n;
  END IF;

  -- P2 — this file has not already been applied. Asked before P3, because after an apply the 18
  -- new names ARE in the table and P3 would report them as collisions.
  SELECT count(*) INTO n FROM essentials.politicians p
    JOIN cc0482_people pp ON pp.person_id = p.id WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P2: % of the 18 new politician ids already exist. Applied before.', n;
  END IF;

  -- P3 — 🔴 NOBODY WITH THESE NAMES IS ALREADY IN THE TABLE. This is the duplicate-name guard's
  -- own predicate, (first_name, last_name), run before the insert rather than after the fact.
  SELECT count(*) INTO n
    FROM cc0482_people pp
    JOIN essentials.politicians p
      ON p.first_name = pp.first_name AND p.last_name = pp.last_name
   WHERE pp.create_row;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P3: % existing politician row(s) already carry one of the 18 names. ONE ROW '
                    'PER PERSON — read the row before creating a second.', n;
  END IF;

  -- P4 — every one of the 3 link targets exists, is active, and already HOLDS a Massachusetts
  -- office. A link to somebody with no Massachusetts seat is the Mark Harris shape.
  SELECT count(*) INTO n
    FROM cc0482_people pp
    JOIN essentials.politicians p ON p.id = pp.person_id
   WHERE NOT pp.create_row
     AND p.is_active
     AND EXISTS (SELECT 1 FROM essentials.office_terms t
                   JOIN essentials.offices o   ON o.id = t.office_id
                   JOIN essentials.districts d ON d.id = o.district_id
                  WHERE t.politician_id = p.id AND lower(d.state) = 'ma'
                    AND (t.term_end IS NULL OR t.term_end >= CURRENT_DATE));
  IF n <> 3 THEN
    RAISE EXCEPTION 'P4: only % of the 3 link targets are an active politician currently holding '
                    'a Massachusetts office.', n;
  END IF;

  -- P5 — 🔴🔴 THE TWO CHAMBER SWITCHERS ARE LINKED ON A STRUCTURAL FACT, NOT ON THEIR NAMES.
  -- Each must currently hold a Massachusetts HOUSE seat that is ITSELF in this file, won by a
  -- DIFFERENT person. That is what makes "she vacated her seat to run for the Senate" a
  -- measurement instead of a story.
  SELECT count(*) INTO n
    FROM cc0482_people pp
    JOIN essentials.office_terms t   ON t.politician_id = pp.person_id
                                    AND (t.term_end IS NULL OR t.term_end >= CURRENT_DATE)
    JOIN essentials.offices o        ON o.id = t.office_id
    JOIN essentials.districts d      ON d.id = o.district_id AND d.district_type = 'STATE_LOWER'
                                    AND lower(d.state) = 'ma'
    JOIN cc0482_people vacated       ON vacated.office_id = o.id
   WHERE pp.seat IN ('Fifth Middlesex District', 'Second Middlesex District')
     AND vacated.person_id <> pp.person_id;
  IF n <> 2 THEN
    RAISE EXCEPTION 'P5: % of the 2 chamber switchers currently hold a Massachusetts House seat '
                    'that is in this file and won by somebody else, expected 2. Without that, '
                    'the link rests on the name alone.', n;
  END IF;

  -- P6 — 🔴 BEN EWEN-CAMPEN'S SURNAME IS UNIQUE IN THE TABLE. He is linked on an exact
  -- full-name match, so the match has to be the only one there is.
  SELECT count(*) INTO n FROM essentials.politicians WHERE last_name = 'Ewen-Campen';
  IF n <> 1 THEN
    RAISE EXCEPTION 'P6: % politician row(s) carry the surname Ewen-Campen, expected exactly 1. '
                    'An exact full-name match is only evidence while it is unique.', n;
  END IF;

  -- P7 — 🔴🔴 WILFRED N. MBAH IS NOT ONE OF THE LINK TARGETS, AND HIS ROW IS LEFT ALONE. The
  -- 34th Middlesex winner "Will Mbah" is created as a NEW person; see the header for why, and
  -- for the merge this owes.
  SELECT count(*) INTO n FROM cc0482_people
   WHERE person_id = '9b11117c-d064-404b-8c89-0042f417c576';
  IF n <> 0 THEN
    RAISE EXCEPTION 'P7: this file would link a winner to Wilfred N. Mbah. No document ties that '
                    'name to the ballot name "Will Mbah"; the duplicate is recorded instead.';
  END IF;

  -- P8 — no person is used twice. 21 seats, 21 distinct people.
  SELECT count(*) INTO n FROM (
    SELECT person_id FROM cc0482_people GROUP BY person_id HAVING count(*) > 1) q;
  IF n <> 0 THEN
    RAISE EXCEPTION 'P8: % person id(s) appear on more than one seat.', n;
  END IF;
END $$;

-- ─── 1. The 18 people we do not hold ─────────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, source)
SELECT pp.person_id, pp.full_name, pp.first_name, pp.last_name, true,
       'Winner of the 2026-11-03 general election for ' || pp.seat || ', Massachusetts. The '
         || 'result and the ballot spelling are AP''s per-state results feed, cross-read line by '
         || 'line against the Secretary of the Commonwealth''s own "2026 State Election '
         || 'Candidates" page '
         || '(https://www.sec.state.ma.us/divisions/elections/research-and-statistics/'
         || '2026-state-election-candidates.htm), both read 2026-11-13 and recorded by CC_0413. '
         || 'The whole politicians table was swept twice before this row was created — by '
         || 'surname across every row including archived ones, and on full_name containing both '
         || 'the first and last name — and no existing person matched. `party` is deliberately '
         || 'NULL: parties are not something this platform records except where a one-party '
         || 'primary makes it load-bearing. Created by CC_0482; NOT seated here.'
         || CASE WHEN pp.full_name = 'Will Mbah' THEN
              ' 🔴🔴 SUSPECTED DUPLICATE, RECORDED RATHER THAN RESOLVED: the table already holds '
                || '"Wilfred N. Mbah" (9b11117c-d064-404b-8c89-0042f417c576), a Somerville city '
                || 'councilor seeded in the same batch as Ben Ewen-Campen '
                || '(external_id -2562535003 and -2562535008), and the 34th Middlesex is a '
                || 'Somerville seat. They are very probably the same person. Somerville''s own '
                || 'council roster and the councilor''s own page (somervillema.gov, both read '
                || '2026-11-23) write him "Wilfred N. Mbah" and never "Will", and no document '
                || 'consulted ties the two names together — so a link would be an unevidenced '
                || 'claim about a named real person, while a duplicate is a visible, reversible '
                || 'gap. A MERGE IS OWED on this row as soon as a document ties the ballot name '
                || 'to the councilor: his own biography, a campaign filing giving his full name, '
                || 'or the General Court''s member roster once he is sworn. Archive, never '
                || 'delete.'
            ELSE '' END
  FROM cc0482_people pp
 WHERE pp.create_row;

-- ─── 2. All 21 winner rows get their person ──────────────────────────────────────────────────
-- 🔴 GUARDED `IS NULL`, so this file cannot overwrite a link that appeared between writing and
--    applying.
UPDATE essentials.race_candidates rc
   SET politician_id = c.person_id
  FROM cc0482_rc c
 WHERE rc.id = c.race_candidate_id
   AND rc.politician_id IS NULL;

DO $$
DECLARE n bigint; b record;
BEGIN
  SELECT * INTO b FROM cc0482_before;

  -- 1. 18 people created, and exactly 18, repo-wide.
  SELECT count(*) INTO n FROM essentials.politicians;
  IF n <> b.politicians + 18 THEN
    RAISE EXCEPTION '1: politicians went % -> %, a delta of %, expected 18.',
      b.politicians, n, n - b.politicians;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.politicians p JOIN cc0482_people pp ON pp.person_id = p.id
   WHERE pp.create_row AND p.full_name = pp.full_name AND p.first_name = pp.first_name
     AND p.last_name = pp.last_name AND p.is_active AND p.party IS NULL;
  IF n <> 18 THEN
    RAISE EXCEPTION '1: % of the 18 new rows read back correctly, with a NULL party.', n;
  END IF;

  -- 2. All 21 winner rows carry the intended person.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc JOIN cc0482_rc c ON c.race_candidate_id = rc.id
   WHERE rc.politician_id = c.person_id;
  IF n <> 21 THEN
    RAISE EXCEPTION '2: % of 21 winner rows carry the intended politician_id.', n;
  END IF;

  -- 3. 🔴🔴 WILFRED N. MBAH'S ROW IS UNTOUCHED AND STILL THERE, and the two Mbah rows are now
  --    two. That is the duplicate this file chose to record; it is not a repair.
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = '9b11117c-d064-404b-8c89-0042f417c576';
  IF n <> b.wilfred_mbah THEN
    RAISE EXCEPTION '3: the Wilfred N. Mbah row changed count % -> %. This file leaves it alone.',
      b.wilfred_mbah, n;
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians WHERE last_name = 'Mbah';
  IF n <> 2 THEN
    RAISE EXCEPTION '3: % politician row(s) carry the surname Mbah, expected 2 (Wilfred N. and '
                    'the newly created Will). If this is 1, the create did not happen; if it is '
                    'more, somebody else has been here.', n;
  END IF;

  SELECT count(*) INTO n
    FROM essentials.politicians WHERE full_name = 'Will Mbah' AND source LIKE '%SUSPECTED DUPLICATE%';
  IF n <> 1 THEN
    RAISE EXCEPTION '3: the Will Mbah row does not record the suspected duplicate in its source. '
                    'A duplicate nobody wrote down is a duplicate nobody will merge.';
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

  -- 6. 🔴 NOT ONE MASSACHUSETTS LEGISLATIVE WINNER IS LEFT WITHOUT A PERSON RECORD. This is the
  --    claim CC_0483's P5 depends on, measured here from the view itself.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    CROSS JOIN LATERAL jsonb_array_elements(w.winners) AS win(value)
   WHERE lower(d.state) = 'ma' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03' AND (win.value ->> 'id') IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION '6: % Massachusetts legislative winner(s) still have no person record.', n;
  END IF;

  -- 7. ⚠ AND THE SEAT COUNT DID NOT MOVE. Linking a winner must not add or remove a pending
  --    seat; if it did, the selection CC_0483 pins is not the one measured here.
  SELECT count(*) INTO n
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o   ON o.id = w.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma' AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
     AND w.election_date = DATE '2026-11-03';
  IF n <> 199 THEN
    RAISE EXCEPTION '7: % Massachusetts legislative seats are pending, expected 199.', n;
  END IF;

  RAISE NOTICE 'CC_0482 OK: 18 Massachusetts legislative winners created and 3 linked — Kate '
               'Lipper-Garabedian and Erika Uyterhoeven, each vacating a House seat in this same '
               'wave for a Senate seat, and Ben Ewen-Campen, whose surname is unique in the '
               'table. "Will Mbah" was created NEW, with the suspected duplicate '
               '(Wilfred N. Mbah, Somerville councilor) recorded in his source and a merge owed. '
               'All 199 legislative winners now have a person record; no terms written.';
END $$;

COMMIT;
