-- CC_0295 — retire the two duplicate Indiana statewide-executive offices.
--
-- 🔴 THIS IS A PREREQUISITE, NOT A SIDE QUEST. It ships with the address-search de-duplication
-- fix in the same PR and must be applied FIRST. Without it that fix makes every Indiana address
-- show two Secretaries of State and two Treasurers.
--
-- ─── WHAT WAS FOUND, AND HOW ─────────────────────────────────────────────────────────────
-- `/api/essentials/address-search` de-duplicates its rows on `COALESCE(p.id, o.id)` — the
-- PERSON when a seat is held. That collapses two seats held by one person into one row, which
-- is the bug being fixed alongside this. Measured against prod, switching that key to `o.id`
-- added exactly four rows nationwide:
--
--   Waterville ME  + Flavia DeBrito, Maine House 64   ← a real second seat, correctly restored
--   Brewer ME      + Dani O'Halloran, Maine House 20  ← ditto
--   S Portland ME  + Elyse Tipton, Mayor              ← ditto (she is also a councillor)
--   Indianapolis   + Diego Morales, Secretary of State AND Daniel Elliott, Treasurer
--                                                     ← NOT real. Two office rows, one seat each.
--
-- ⚠ **THE READ-PATH DE-DUP WAS HIDING A DATA DEFECT, AND THAT IS WHY NOBODY FOUND IT.** The
-- duplicate offices are four years old and have never been visible to a voter, because the same
-- person holds both copies and the collapse picked one. Fixing the query is what exposed them.
-- ▶ A de-duplication that keys on the wrong column does not just lose rows — it silently
--   launders the rows it keeps.
--
-- ─── THE TWO DUPLICATES, AND WHICH COPY IS CANONICAL ─────────────────────────────────────
-- Indiana carries a generic statewide-executive district (`97db28b9…`, label "Indiana",
-- `geo_id = ''`) holding THIRTEEN offices — Comptroller, Commissioner of Labor, Director of
-- Agriculture, Director of Natural Resources, Insurance Commissioner, Secretary of Education,
-- four Utility Regulatory Commissioners, the URC Chairman, and these two. Eleven of the
-- thirteen exist only there and are untouched by this migration.
--
-- Two of them ALSO exist on per-office districts carrying Indiana's real FIPS `geo_id = '18'`:
--
--   | seat               | duplicate (retired here)              | canonical (kept)                      |
--   | ------------------ | ------------------------------------- | ------------------------------------- |
--   | Secretary of State | d6c85c1d… on district 97db28b9 (`''`) | a700ee79… on district b5dcc836 (`18`) |
--   | Treasurer          | 4100a245… on district 97db28b9 (`''`) | c72433ad… on district 12f30bad (`18`) |
--
-- 🟢 **THE TIE-BREAK IS MEASURED, NOT PREFERRED: the `geo_id = '18'` copies each carry a RACE;
-- the `geo_id = ''` copies carry none.** The election system already treats the FIPS-keyed
-- offices as the real ones, so those are the seats a ballot resolves to, and retiring the other
-- copy cannot orphan an election. Both copies hold exactly one `office_terms` row apiece, and
-- every one of the four is a phase-2 backfill from the dropped `offices.politician_id` column
-- (ADR 0002), created 2026-07-26 — so no research or hand-curation is being discarded.
--
-- ─── PRECEDENT ───────────────────────────────────────────────────────────────────────────
-- This is `CC_0103`'s class A, two rows late: *"the holder already held the real version of the
-- same seat, so the row was a duplicate of a better row."* `CC_0103` and `CC_0104` retired 671
-- Indiana offices between them, but both selected on `indiana_discovery` placeholder occupancy.
-- These two carry ordinary backfilled terms, so neither pass could see them.
-- ⚠ **A CLEANUP SCOPED BY HOW A ROW WAS CREATED CANNOT FIND A DUPLICATE CREATED ANOTHER WAY.**
--
-- ─── WHAT THIS DELETES, AND WHAT IT DOES NOT ─────────────────────────────────────────────
-- Deletes 2 offices and, by cascade, their 2 backfilled terms.
-- Deletes NO people — Diego Morales and Daniel Elliott keep their canonical seats and every
-- source, finance link and stance answer attached to them, because those FKs are to the PERSON.
-- Deletes NO districts: `97db28b9…` keeps its other eleven offices, so removing it would orphan
-- them (`essentials.districts` has no inbound FKs — a delete does not complain).
-- Touches NO vacancy flags and NO races.
--
-- ⚠ Daniel Elliott the Indiana Treasurer is a DIFFERENT PERSON from Daniel Elliott the Kentucky
-- state representative, who also exists and is untouched. Named here because the two look like
-- one duplicate in any by-name query and are not.
--
-- ─── ⚠ A THIRD INDIANA DUPLICATE, FOUND BY THIS MIGRATION'S OWN GATE AND LEFT ALONE ─────
-- The post-verify below first asserted "no duplicated Indiana STATE_EXEC title survives" and
-- FAILED on the dry run with `Comptroller x2`. That is a real third duplicate, and the gate
-- found it only because it was written broader than the two rows this migration came for.
--
--   22565e22… on the shared `geo_id = ''` district — HELD by Elise M. Nieshalla, 1 term, 0 races
--   5b86a68f… on `geo_id = '18'` ("Indiana Comptroller")  — UNSEATED, 0 terms, 1 race
--
-- 🔴 **IT IS SPLIT THE OTHER WAY**: the race-carrying canonical copy is the EMPTY one. So it
-- cannot be retired like the two above — deleting the held copy would unseat Indiana's sitting
-- Comptroller, and deleting the empty one would orphan her race. The fix is a MERGE: move the
-- term onto the `geo_id = '18'` office, then retire the duplicate.
--
-- 🟢 **IT DOES NOT BLOCK THE ADDRESS-SEARCH FIX, AND THAT WAS MEASURED, NOT ASSUMED.** Under the
-- current key `COALESCE(p.id, o.id)` the two rows key on a politician id and an office id
-- respectively; under the proposed key `o.id` they key on two office ids. **Different under
-- both**, so Indiana addresses already return two Comptroller rows today — one named, one the
-- nameless `id: null` row every unseated office emits — and will return exactly the same two
-- afterwards. The key change neither causes this nor fixes it.
--
-- ▶ LEFT FOR ITS OWN CHANGE, deliberately, because the merge lowers `offices_missing_terms`
--   unflagged from 239 to 238 (that empty office is unflagged-and-unseated, so it sits INSIDE
--   the baseline) and because it forces the question this migration dodges: which district
--   shape is canonical for Indiana's statewide executives, the shared `geo_id = ''` row or a
--   per-office `geo_id = '18'` row? Eleven other offices still hang off the shared one.
--   Lowering the baseline is sanctioned (CLAUDE.md: "Lower this number whenever a change
--   shrinks it") but it is not a read-path fix's business to do it in passing.
--
-- ─── MEASUREMENT ─────────────────────────────────────────────────────────────────────────
-- `offices_missing_terms` does not move (both deleted offices HAVE terms, so neither was in it):
-- 297 / 58 / 239 before and after. Indiana statewide-exec offices 15 → 13.

BEGIN;

CREATE TEMP TABLE _dup (
  seat        text NOT NULL,
  office_id   uuid PRIMARY KEY,
  keep_office uuid NOT NULL
) ON COMMIT DROP;

INSERT INTO _dup (seat, office_id, keep_office) VALUES
  ('Secretary of State', 'd6c85c1d-e4c9-42ed-b041-c13462442a6d', 'a700ee79-427e-44b5-a3d8-abab6ba77062'),
  ('Treasurer',          '4100a245-c5c0-43a7-9277-7121b2381d99', 'c72433ad-f67f-49da-8454-cae599301d5a');

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_txt text;
BEGIN
  -- every id resolves, and the pair really is (same government, same chamber, same title)
  SELECT count(*) INTO n FROM _dup x
    JOIN essentials.offices od ON od.id = x.office_id
    JOIN essentials.offices ok ON ok.id = x.keep_office
   WHERE od.chamber_id = ok.chamber_id
     AND od.title = ok.title
     AND od.title = x.seat
     AND od.id <> ok.id;
  IF n <> 2 THEN
    RAISE EXCEPTION 'CC_0295: % of 2 duplicate pairs resolve as same-chamber same-title pairs', n;
  END IF;

  -- 🔴 THE TIE-BREAK, ASSERTED: the kept copy carries race(s), the retired copy carries none.
  -- If this ever flips, the wrong row is about to be deleted.
  SELECT count(*) INTO bad FROM _dup x
   WHERE (SELECT count(*) FROM essentials.races r WHERE r.office_id = x.keep_office) = 0
      OR (SELECT count(*) FROM essentials.races r WHERE r.office_id = x.office_id) > 0;
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0295: the race tie-break does not hold for % pair(s) - the canonical copy '
                    'is the one the elections system already points at, so re-read before deleting', bad;
  END IF;

  -- both copies are held by the SAME person — that is what makes one a duplicate rather than a
  -- second real seat, and it is the whole premise of this migration.
  SELECT count(*) INTO bad FROM _dup x
   WHERE (SELECT och.politician_id FROM essentials.office_current_holder och WHERE och.office_id = x.office_id)
      IS DISTINCT FROM
         (SELECT och.politician_id FROM essentials.office_current_holder och WHERE och.office_id = x.keep_office);
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0295: % pair(s) are held by DIFFERENT people - those are not duplicates, '
                    'they are two seats, and deleting one would unseat somebody', bad;
  END IF;

  -- the retired copies carry exactly one term each, and it is a phase-2 backfill
  SELECT count(*) INTO n FROM _dup x
    JOIN essentials.office_terms t ON t.office_id = x.office_id
   WHERE t.source LIKE 'backfill from essentials.offices.politician_id%';
  IF n <> 2 THEN
    RAISE EXCEPTION 'CC_0295: expected 2 backfilled terms on the retired copies, found % - a term '
                    'that is not a backfill may carry hand-curated information', n;
  END IF;

  -- nothing else points at the rows being removed
  SELECT count(*) INTO bad FROM _dup x
    JOIN essentials.races r ON r.office_id = x.office_id;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0295: % race(s) point at a retired office', bad; END IF;

  -- 🟢 the district survives with its other offices: this deletes OFFICES, never a district
  SELECT count(*) INTO n FROM essentials.offices o
   WHERE o.district_id = '97db28b9-6b56-4427-a6e3-82645d0d6ad5';
  IF n <> 13 THEN
    RAISE EXCEPTION 'CC_0295: the shared Indiana statewide-exec district holds % offices, '
                    'expected 13 - re-read it before removing any', n;
  END IF;
END $$;

-- ─── Retire them. Offices only; the terms cascade. ──────────────────────────────────────
DELETE FROM essentials.offices o USING _dup x WHERE o.id = x.office_id;

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_unflagged int; v_total int; v_txt text;
BEGIN
  -- the duplicates are gone and their terms went with them
  SELECT count(*) INTO bad FROM essentials.offices o
   WHERE o.id IN ('d6c85c1d-e4c9-42ed-b041-c13462442a6d','4100a245-c5c0-43a7-9277-7121b2381d99');
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0295: % duplicate office(s) survive', bad; END IF;

  SELECT count(*) INTO bad FROM essentials.office_terms t
   WHERE t.office_id IN ('d6c85c1d-e4c9-42ed-b041-c13462442a6d','4100a245-c5c0-43a7-9277-7121b2381d99');
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0295: % orphaned term(s) survive', bad; END IF;

  -- 🔴 AND BOTH PEOPLE ARE STILL SEATED, on the canonical copy. Deleting the wrong row, or both,
  -- would unseat a sitting state officer and nothing else here would have noticed.
  SELECT count(*) INTO n FROM essentials.office_current_holder och
   WHERE och.office_id IN ('a700ee79-427e-44b5-a3d8-abab6ba77062','c72433ad-f67f-49da-8454-cae599301d5a')
     AND och.politician_id IS NOT NULL;
  IF n <> 2 THEN
    RAISE EXCEPTION 'CC_0295: % of 2 canonical Indiana seats are held, expected both', n;
  END IF;

  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id IN ('35269bd5-4f5b-42dc-8226-3a04c2f55b80',  -- Diego Morales
                '085e88aa-edfd-435e-90bb-d84c5912efde')  -- Daniel Elliott (IN Treasurer)
     AND is_active AND is_incumbent;
  IF n <> 2 THEN RAISE EXCEPTION 'CC_0295: % of 2 officers are still active incumbents', n; END IF;

  -- 🔴 THE POINT OF THE WHOLE MIGRATION: no Indiana statewide-exec seat is duplicated any more,
  -- so the address-search fix shipping beside it cannot show a voter two Secretaries of State.
  SELECT string_agg(x.title || ' x' || x.n, ', ' ORDER BY x.title) INTO v_txt FROM (
    SELECT o.title, count(*)::text AS n
      FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
      JOIN essentials.governments g ON g.id = c.government_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE g.name = 'State of Indiana' AND d.district_type = 'STATE_EXEC'
       AND o.title NOT ILIKE 'Candidate for%'
     GROUP BY o.title HAVING count(*) > 1) x;
  -- ⚠ `Comptroller x2` is EXPECTED and is deliberately NOT fixed here — see the note below.
  -- The four Utility Regulatory Commissioners are genuine: Indiana's URC seats five people.
  IF v_txt IS DISTINCT FROM 'Comptroller x2, Utility Regulatory Commissioner x4' THEN
    RAISE EXCEPTION 'CC_0295: duplicated Indiana STATE_EXEC titles are [%], expected '
                    '[Comptroller x2, Utility Regulatory Commissioner x4]', coalesce(v_txt,'none');
  END IF;

  -- the shared district kept its other eleven
  SELECT count(*) INTO n FROM essentials.offices o
   WHERE o.district_id = '97db28b9-6b56-4427-a6e3-82645d0d6ad5';
  IF n <> 11 THEN
    RAISE EXCEPTION 'CC_0295: the shared Indiana district now holds % offices, expected 11', n;
  END IF;

  -- 🔴 repo-wide: no seat anywhere is duplicated AND held by one person. This is the exact
  -- condition that makes the address-search de-dup fix safe to ship.
  SELECT count(*) INTO bad FROM (
    SELECT o.chamber_id, o.title
      FROM essentials.offices o
      JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE o.title NOT ILIKE 'Candidate for%' AND och.politician_id IS NOT NULL
     GROUP BY o.chamber_id, o.title
    HAVING count(*) > 1 AND count(DISTINCT och.politician_id) = 1) y;
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0295: % seat(s) are still duplicated under a single holder - the '
                    'address-search de-dup fix would surface each as two rows to a voter', bad;
  END IF;

  -- the global invariant and the drift metric, neither of which this should touch
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant AND och.politician_id IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0295: % office(s) are seated AND flagged', bad; END IF;

  SELECT count(*) FILTER (WHERE NOT o.is_vacant), count(*) INTO v_unflagged, v_total
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'CC_0295: unflagged offices_missing_terms is %, expected the 239 baseline', v_unflagged;
  END IF;
  IF v_total <> 297 THEN
    RAISE EXCEPTION 'CC_0295: total offices_missing_terms is %, expected 297 unchanged - both '
                    'deleted offices HELD a term, so neither was ever in this view', v_total;
  END IF;

  RAISE NOTICE 'CC_0295 OK - 2 duplicate Indiana statewide-exec offices retired, both officers '
               'still seated on the canonical copy; missing_terms unchanged at 297/58/239';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: A DE-DUPLICATION THAT KEYS ON THE WRONG COLUMN LAUNDERS THE ROWS IT KEEPS.
-- These two duplicates were four years old and had never once been shown to a voter, because
-- the read path collapsed on the PERSON and quietly picked one. Nothing was broken on screen,
-- so nothing was ever reported. They surfaced only when the key was corrected and the row count
-- went up by two in a state that had no business gaining anybody.
-- ▶ When you fix a de-duplication, diff the ROWS, not the count — and read every row the fix
--   adds. The ones that should not be there are the finding.
