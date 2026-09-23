-- CA_0185_clear_is_incumbent_on_former_officeholders.sql
-- Clear is_incumbent on 7 FORMER officeholders who hold no seat, and on 2 inactive scraped twins of two of them.
-- Part of the "active incumbent with no office_terms row" clean-up (CA_0180 - CA_0184).
-- House convention (CA_0156, CA_0180): a real former member stays ACTIVE with is_incumbent = false; no past term is
-- written, because the seats' current terms do not give a start date to close against.
--
-- EVIDENCE (fetched 2026-09-23):
--   Darin Mano -- Salt Lake City Council D5. Left 2026-01-05 (did not run in 2025); Erika Carlsen holds D5
--     (slc.gov/district5/council-member-bio; Ballotpedia "Mano left office on January 5, 2026").
--   Eva Lopez (Eva Lopez Chavez) -- Salt Lake City Council D4. Seat vacated 2026-05-12 after a residency
--     determination; Jennifer Napier-Pearce appointed and sworn in 2026-06-09 (slc.gov council statement and
--     2026-06-10 council blog post).
--   Fernando Dutra -- Whittier City Council D4. Lost 2026-04-14 to Aida Susie Macedo (67.64% to 25.94%); new members
--     seated 2026-04-28 (archived cityofwhittier.org election results page).
--   Octavio Cesar Martinez -- Whittier City Council D2 (elected April 2022). Lost 2026-04-14 to Vicky Santana; left
--     2026-04-28 (archived cityofwhittier.org council profiles).
--   George Dotson -- Inglewood City Council D1 from 2013. Lost the 2023-03-07 runoff to Gloria D. Gray, 33.91% to
--     66.09% (results.lavote.gov/text-results/4307). The CA SOS 2025 city roster that seeded his row was stale.
--   Jackie Goldberg -- LAUSD Board D5. Did not run in 2024; left December 2024; successor Karla Griego (Ballotpedia).
--   Mónica García -- LAUSD Board D2. Term-limited; left December 2022; successor Rocío Rivas (Ballotpedia).
--   Every seat above is held in this DB by the successor named (checked in the pre-flight below).
--   The inactive 'scraped' twins of Dutra (bf91e362) and Martinez (b8eeb27c) are already is_active = false but still
--   read is_incumbent = true; they are cleared too. Their committee links are left where they are (unreviewed).
--
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews). Dry run x2 repeated right before the apply;
--   verified after: 9 rows cleared with their notes.
--
-- ROLLBACK: UPDATE essentials.politicians SET is_incumbent = true,
--   notes = array(SELECT n FROM unnest(notes) n WHERE n NOT LIKE 'CA_0185 (2026-09-23)%')
--   WHERE EXISTS (SELECT 1 FROM unnest(notes) n WHERE n LIKE 'CA_0185 (2026-09-23)%');
-- IDEMPOTENT: guarded on is_incumbent = true; a re-run changes nothing and every gate still passes.

BEGIN;

CREATE TEMP TABLE _former (id uuid PRIMARY KEY, full_name text, active boolean, note text) ON COMMIT DROP;
INSERT INTO _former VALUES
  ('6d974766-da19-4ca4-b3b6-88952e1a0565', 'Darin Mano', true,
   'CA_0185 (2026-09-23): former Salt Lake City Council District 5 member; left 2026-01-05 (did not run in 2025); Erika Carlsen holds D5 (slc.gov). No seat here, so is_incumbent cleared.'),
  ('173107ec-6634-4d94-9953-1e6cc278d59e', 'Eva Lopez', true,
   'CA_0185 (2026-09-23): former Salt Lake City Council District 4 member (Eva Lopez Chavez); seat vacated 2026-05-12 after a residency determination; Jennifer Napier-Pearce sworn in 2026-06-09 (slc.gov). No seat here, so is_incumbent cleared.'),
  ('99929a73-8c32-4921-8c12-f5a0f5d4847d', 'Fernando Dutra', true,
   'CA_0185 (2026-09-23): former Whittier City Council District 4 member; lost 2026-04-14 to Aida Susie Macedo, who was seated 2026-04-28 (City of Whittier election results). No seat here, so is_incumbent cleared.'),
  ('bf91e362-ae5b-4229-9217-75ffc6b752ae', 'Fernando Dutra', false,
   'CA_0185 (2026-09-23): inactive scraped twin of 99929a73 (Fernando Dutra, former Whittier D4 member, left 2026-04-28); is_incumbent cleared.'),
  ('77fc9ed7-79ca-4f83-862c-fc35cf18203f', 'Octavio Cesar Martinez', true,
   'CA_0185 (2026-09-23): former Whittier City Council District 2 member (elected April 2022); lost 2026-04-14 to Vicky Santana, seated 2026-04-28 (City of Whittier). No seat here, so is_incumbent cleared.'),
  ('b8eeb27c-5863-4267-ab85-89094aefed32', 'Octavio Martinez', false,
   'CA_0185 (2026-09-23): inactive scraped twin of 77fc9ed7 (Octavio Cesar Martinez, former Whittier D2 member, left 2026-04-28); is_incumbent cleared.'),
  ('3e73448b-bd10-4e6b-bf2a-c9368cf64af9', 'George Dotson', true,
   'CA_0185 (2026-09-23): former Inglewood City Council District 1 member (from 2013); lost the 2023-03-07 runoff to Gloria D. Gray (results.lavote.gov 4307). The CA SOS 2025 roster that seeded this row was stale. No seat here, so is_incumbent cleared.'),
  ('92a8c2af-7365-4361-97a2-a16a189a046a', 'Jackie Goldberg', true,
   'CA_0185 (2026-09-23): former LAUSD Board District 5 member; did not run in 2024, left December 2024; successor Karla Griego (Ballotpedia). No seat here, so is_incumbent cleared.'),
  ('a123c59e-694b-43cc-af03-6610b645e6d2', 'Mónica García', true,
   'CA_0185 (2026-09-23): former LAUSD Board District 2 member; term-limited, left December 2022; successor Rocío Rivas (Ballotpedia). No seat here, so is_incumbent cleared.');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _former f JOIN essentials.politicians p ON p.id = f.id AND p.full_name = f.full_name AND p.is_active = f.active
   WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.politician_id = f.id)
     AND (p.is_incumbent OR f.note = ANY (p.notes));
  IF v_n <> 9 THEN RAISE EXCEPTION 'PRE: % of 9 rows are in their reviewed state (seatless, incumbent or already cleared)', v_n; END IF;

  -- the successors named above hold those seats in this DB
  SELECT count(*) INTO v_n FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    JOIN essentials.offices o ON o.id = och.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE (p.full_name = 'Erika Carlsen' AND d.label = 'Salt Lake City Council District 5')
      OR (p.full_name = 'Jennifer Napier-Pearce' AND d.label = 'Salt Lake City Council District 4')
      OR (p.full_name = 'Aida Susana Macedo' AND o.title = 'Council Member (District 4)')
      OR (p.full_name = 'Vicky Santana' AND o.title = 'Council Member (District 2)')
      OR (p.full_name = 'Gloria D. Gray' AND o.title = 'Council Member (District 1)');
  IF v_n <> 5 THEN RAISE EXCEPTION 'PRE: % of 5 successor seats found held', v_n; END IF;
END $$;

UPDATE essentials.politicians p
   SET is_incumbent = false, notes = COALESCE(p.notes, ARRAY[]::text[]) || f.note
  FROM _former f
 WHERE p.id = f.id AND p.is_incumbent;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM _former f JOIN essentials.politicians p ON p.id = f.id
   WHERE NOT p.is_incumbent AND p.is_active = f.active AND f.note = ANY (p.notes);
  IF v_n <> 9 THEN RAISE EXCEPTION 'POST: % of 9 rows cleared with their note', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE EXISTS (SELECT 1 FROM unnest(p.notes) n WHERE n LIKE 'CA_0185 (2026-09-23)%') AND p.id NOT IN (SELECT id FROM _former);
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % row(s) outside _former carry the note', v_n; END IF;
  RAISE NOTICE 'CA_0185 applied: 7 former officeholders and 2 inactive twins no longer read as incumbents';
END $$;

COMMIT;
