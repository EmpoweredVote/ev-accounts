-- 1603_dedupe_repeated_citations.sql
--
-- Remove 4 duplicate citations: 4 rows each list the same URL twice in `sources`.
--   Rollback record: data/stance-retirement/2026-08-07-duplicate-citations-rollback.json
--
-- HOW THEY WERE FOUND. An over-broad duplicate assertion in 1602 -- corpus-wide where it should have
-- been scoped to the rows that migration touched -- failed its dry run at 4. That is the THIRD time
-- on this workstream an over-broad check has surfaced a real defect (1524, 1530). The rule those
-- established is: narrow the check AND fix what it found. 1602 narrowed it; this fixes it.
--
-- WHY IT MATTERS. `sources` is voter-facing: StanceAccordion and Citations.jsx render the array, so a
-- duplicate shows the same link to a voter twice. It is not a data-hygiene nicety.
--
-- 🔴 ORDER IS LOAD-BEARING, AND TWO OF THE FOUR PROVE IT. The duplicates are NOT all adjacent:
--   Markey/Tariffs      [ontheissues, wikipedia, ontheissues]  -> [ontheissues, wikipedia]
--   Quirk-Silva/Housing [AB956, AB670, AB670]                  -> [AB956, AB670]
--   Garland Barr/Fossil [ontheissues, ontheissues]             -> [ontheissues]
--   Rick Allen/Voting   [ontheissues, ontheissues]             -> [ontheissues]
-- A naive `SELECT DISTINCT` would reorder these arrays. The rebuild below keeps FIRST-OCCURRENCE
-- order via `WITH ORDINALITY` + `min(ord)`, the same technique 1549 used.
--
-- ⚠ TWO ROWS BECOME SINGLE-SOURCED, and that is a disclosure rather than a change: Garland Barr and
-- Rick Allen each cited ontheissues.org twice and nothing else, so the duplicate was MASKING that
-- those rows rest on one aggregator citation. Removing it does not weaken them -- it reveals what
-- they always were. Both keep a pathed per-person URL, so neither enters BARE_AGGREGATOR_DOMAIN or
-- BALLOTPEDIA_ONLY. They are worth a look in the re-research queue on their own merits.
-- (Garland Barr IS Andy Barr -- Garland Hale "Andy" Barr III -- so the Andy_Barr.htm path is correct
-- and this is not a wrong-person citation.)
--
-- ⚠ NO GATE COUNT MAY MOVE. Every gate predicate uses ANY/ALL over `sources`, which duplicates do
-- not affect, so classification is identical before and after. Asserted below by requiring the
-- DISTINCT set of sources per row to be unchanged -- the real safety property here.

BEGIN;

DO $$
DECLARE
  v_n            int;
  v_cites_before bigint;
  v_cites_after  bigint;
  v_rows_before  bigint;
  v_rows_after   bigint;
BEGIN
  SELECT count(*) INTO v_cites_before FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_rows_before  FROM inform.politician_context;

  -- Snapshot the DISTINCT source set of every affected row, so the repair can be proved to have
  -- changed multiplicity and nothing else.
  CREATE TEMP TABLE _dupe_1603 ON COMMIT DROP AS
    SELECT pc.politician_id, pc.topic_id,
           (SELECT array_agg(DISTINCT s) FROM unnest(pc.sources) s) AS distinct_before,
           cardinality(pc.sources) AS n_before
      FROM inform.politician_context pc
     WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s GROUP BY s HAVING count(*) > 1);

  SELECT count(*) INTO v_n FROM _dupe_1603;
  IF v_n <> 4 THEN RAISE EXCEPTION '1603: expected 4 rows with duplicate citations, found %', v_n; END IF;

  -- Each affected row must carry exactly ONE extra citation, or the arithmetic below is wrong.
  SELECT count(*) INTO v_n FROM _dupe_1603 d
   WHERE d.n_before - cardinality(d.distinct_before) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '1603: % rows have more than one extra citation', v_n; END IF;

  -- ---- the repair: rebuild each array keeping FIRST-OCCURRENCE order ----
  UPDATE inform.politician_context pc
     SET sources = (
       SELECT array_agg(u.s ORDER BY u.first_ord)
         FROM (SELECT s, min(ord) AS first_ord
                 FROM unnest(pc.sources) WITH ORDINALITY AS x(s, ord)
                GROUP BY s) u
     )
   FROM _dupe_1603 d
  WHERE pc.politician_id = d.politician_id AND pc.topic_id = d.topic_id;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s GROUP BY s HAVING count(*) > 1);
  IF v_n <> 0 THEN RAISE EXCEPTION '1603: % rows still hold a duplicate citation', v_n; END IF;

  -- THE SAFETY PROPERTY: multiplicity changed, membership did not. Compared as sorted sets so a
  -- legitimate order change cannot masquerade as equality failure, and vice versa.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
    JOIN _dupe_1603 d ON d.politician_id = pc.politician_id AND d.topic_id = pc.topic_id
   WHERE (SELECT array_agg(s ORDER BY s) FROM unnest(pc.sources) s)
      IS DISTINCT FROM (SELECT array_agg(s ORDER BY s) FROM unnest(d.distinct_before) s);
  IF v_n <> 0 THEN RAISE EXCEPTION '1603: % rows changed which sources they cite, not just how many', v_n; END IF;

  -- First-occurrence order specifically: Markey must still lead with ontheissues, Quirk-Silva with AB956.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = 'faf86b5b-5add-4afb-a8e2-96b3e8be4b78'
     AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413'
     AND sources[1] = 'https://www.ontheissues.org/Senate/Ed_Markey.htm'
     AND sources[2] = 'https://en.wikipedia.org/wiki/Ed_Markey'
     AND cardinality(sources) = 2;
  IF v_n <> 1 THEN RAISE EXCEPTION '1603: Markey array is not [ontheissues, wikipedia]'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = '1e29ce86-9e02-4079-b50d-bb0d039613a2'
     AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
     AND sources[1] = 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB956'
     AND sources[2] = 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB670'
     AND cardinality(sources) = 2;
  IF v_n <> 1 THEN RAISE EXCEPTION '1603: Quirk-Silva array is not [AB956, AB670] in that order'; END IF;

  -- Nothing emptied. EMPTY_SOURCES is zero-tolerance, and the 404 legitimate blanks must not move.
  SELECT count(*) INTO v_n FROM inform.politician_context WHERE cardinality(sources) = 0;
  IF v_n <> 404 THEN RAISE EXCEPTION '1603: empty-sources rows moved to %, expected 404', v_n; END IF;

  -- Exactly 4 citations removed, no rows added or lost.
  SELECT count(*) INTO v_cites_after FROM inform.politician_context pc, unnest(pc.sources) s;
  SELECT count(*) INTO v_rows_after  FROM inform.politician_context;
  IF v_cites_before - v_cites_after <> 4 THEN
    RAISE EXCEPTION '1603: citations fell by %, expected 4', v_cites_before - v_cites_after; END IF;
  IF v_rows_after <> v_rows_before THEN
    RAISE EXCEPTION '1603: context row count moved % -> %', v_rows_before, v_rows_after; END IF;

  RAISE NOTICE '1603: de-duplicated 4 rows; citations % -> %', v_cites_before, v_cites_after;
END $$;

COMMIT;
