-- CC_0102_repoint_indiana_committee_sources.sql
-- Indiana debt 1, identity merge (class B). Slot RESERVED from the allocator.
--
-- Moves 55 candidate-committee sources in `transparent_motivations.politician_sources` from the
-- duplicate `indiana_discovery` person row onto the SEATED officeholder's row.
-- Creates nothing. Deletes nothing. Merges no person rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS REPAIRS A REGRESSION CC_0101 CAUSED, AND THE REGRESSION IS WORTH RECORDING.
--
-- CC_0101 deactivated the 587 orphan-only `indiana_discovery` people, which was right. The cost
-- was stated at the time as "these leave campaign-finance search", and the ruling accepted it on
-- that framing. The framing was too coarse. 55 of those rows are DUPLICATES OF SITTING INDIANA
-- LEGISLATORS, and each carried the only candidate-committee link that person had:
--
--     orphan rows carrying a committee source ............. 55 of 55
--     seated rows carrying one of their own ...............  1 of 55
--     => finance reachable ONLY via a deactivated row ..... 54
--
-- ▶ **A COST STATED AT THE LEVEL OF A COHORT CAN HIDE A DIFFERENT COST INSIDE IT.** "587 candidate
-- rows leave finance search" and "54 sitting legislators lose their finance link" are the same
-- sentence at two resolutions, and only the second one is decidable. State the sharper one.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- WHERE THE PAIRS COME FROM: a hand review of all 69 candidate pairs (Cantrell, 2026-09-12),
-- recorded on a private review page and read back from its store. 55 same, 13 different, 1 unsure.
-- 🔴 NO PAIR IN THIS FILE WAS DECIDED BY A RULE. The matcher that produced the candidates was
-- measured as both dirty and incomplete: it paired Frank Mrvan with his own SON, and it could not
-- see Elizabeth Brown / Liz Brown. Those two outcomes are in this list only because a person read
-- them — Mrvan excluded, Liz Brown included.
--
-- ⚠ THE FORD ROWS ARE THE REASON TO TRUST THE REVIEW OVER THE ANNOTATION. A note in the review
-- argued Jonathan Ford was the likelier match for J.D. Ford, reasoning from the initials. It is
-- wrong: J.D. Ford is JAMES Ford, senator for District 29, and JON Ford is a former senator for
-- District 38 who now heads the Office of Energy Development. The ruling took James and rejected
-- Jonathan. Two independent facts agree: this list separately pairs Gregory Goode with Greg Goode,
-- who holds District 38 now — and James Ford's committee is named "Friends to Elect JD Ford".
--
-- 🟢 AN INDEPENDENT CONTROL, FROM A FIELD THE MATCHER NEVER TOUCHED. Each source row's `notes`
-- carries the committee's own name. Across the 55 merges: 28 name the SEATED form and not the
-- orphan's ("MIKE BRAUN FOR INDIANA, INC." for the row called Michael Braun), 10 are surname-only
-- and carry no signal ("Barrett Election Committee"), and 2 carry the legal name against the
-- roster's informal one (Michael/Mike Aylesworth, Stephen/Steve Bartels). **NOT ONE committee name
-- points at a different person.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- ⚠ WHAT THIS DOES NOT DO. It does not merge the person rows, delete anything, or touch the 13
-- pairs ruled DIFFERENT or the 1 ruled UNSURE (Ronald Turpin — the orphan says State Senator, the
-- seat is an Allen County commissioner). Those orphan rows stay exactly as CC_0101 left them:
-- present, deactivated, and retired with the rest in step 2.
--
-- 🔴 `politician_sources.essentials_politician_id` is FK'd ON DELETE RESTRICT, so a person holding
-- a source cannot be deleted. That protection moves with the row: after this migration the
-- protection sits on the officeholder, where it belongs, and the emptied orphan row is free.
--
-- Idempotent: the UPDATE only moves rows still pointing at an orphan; a re-run moves 0.

BEGIN;

-- The 55 reviewed merges. orphan row (indiana_discovery) -> seated officeholder.
CREATE TEMP TABLE in_merge(orphan_name text, seated_name text) ON COMMIT DROP;
INSERT INTO in_merge VALUES
  ('Alexander Burton',          'Alex Burton'),
  ('Benjamin Smaltz',           'Ben Smaltz'),
  ('Bradford Barrett',          'Brad Barrett'),
  ('Christine Campbell',        'Chris Campbell'),
  ('Christopher May',           'Chris D May'),
  ('Christopher Garten',        'Chris Garten'),
  ('Christopher Jeter',         'Chris Jeter'),
  ('Christopher Judy',          'Chris Judy'),
  ('Charles Moseley',           'Chuck Moseley'),
  ('Daniel Dernulc',            'Dan Dernulc'),
  ('Daniel Lopez',              'Danny Lopez'),
  ('David Hall',                'Dave Hall'),
  ('Derek Molter',              'Derek R Molter'),
  ('Douglas Miller',            'Doug Miller'),
  ('Earl Lynn Harris',          'Earl Harris'),
  ('Edward Charbonneau',        'Ed Charbonneau'),
  ('Eddie Melton',              'Eddie Melton'),
  ('Elise Nieshalla',           'Elise M. Nieshalla'),
  ('Eric Koch',                 'Eric A Koch'),
  ('Eric Bassler',              'Eric S Bassler'),
  ('Gregory Goode',             'Greg Goode'),
  ('Gregory Taylor',            'Greg Taylor'),
  ('Gregory Porter',            'Gregory W Porter'),
  ('James Ford',                'J.D. Ford'),
  ('John Prescott',             'J.D. Prescott'),
  ('Jacob Teshka',              'Jake Teshka'),
  ('Jeffrey Raatz',             'Jeff Raatz'),
  ('James Lucas',               'Jim Lucas'),
  ('James Pressel',             'Jim Pressel'),
  ('La Jackson',                'La Keisha Jackson'),
  ('Elizabeth Brown',           'Liz Brown'),
  ('Loretta Rush',              'Loretta H Rush'),
  ('Mark Massa',                'Mark S Massa'),
  ('Matthew Commons',           'Matt Commons'),
  ('Matthew Hostettler',        'Matt Hostettler'),
  ('Matthew Lehman',            'Matt Lehman'),
  ('Miguel Andrade',            'Mike Andrade'),
  ('Michael Aylesworth',        'Mike Aylesworth'),
  ('Michael Braun',             'Mike Braun'),
  ('Michael Gaskill',           'Mike Gaskill'),
  ('Michael Speedy',            'Mike Speedy'),
  ('Mitchell Gore',             'Mitch Gore'),
  ('Randall Maxwell',           'Randy Maxwell'),
  ('Randall Novak',             'Randy Novak'),
  ('Robert Greene',             'Robb Greene'),
  ('Rodric Bray',               'Rodric D Bray'),
  ('Ronnie Alting',             'Ron Alting'),
  ('Shane Lindauer',            'Shane M Lindauer'),
  ('Stephen Bartels',           'Steve Bartels'),
  ('Theodore Rokita',           'Todd Rokita'),
  ('Vanessa Summers',           'Vanessa J Summers'),
  ('Victoria Wilburn',          'Victoria Garcia Wilburn'),
  ('Victoria Spartz',           'Victoria Spartz'),
  ('Wendy Chesser',             'Wendy Dant Chesser'),
  ('Zachary Payne',             'Zach Payne');

-- Resolve both sides to ids, and refuse anything that is not exactly 1:1.
-- 🔴 A name that matches two rows would attach a committee to the WRONG person, silently.
CREATE TEMP TABLE in_merge_ids ON COMMIT DROP AS
SELECT m.orphan_name, m.seated_name,
       (SELECT p.id FROM essentials.politicians p
         WHERE p.full_name = m.orphan_name AND p.source = 'indiana_discovery') AS orphan_id,
       (SELECT p2.id FROM essentials.politicians p2
         WHERE p2.full_name = m.seated_name
           AND EXISTS (SELECT 1 FROM essentials.office_current_holder och
                        JOIN essentials.offices o ON o.id = och.office_id
                       WHERE och.politician_id = p2.id AND o.district_id IS NOT NULL)) AS seated_id
FROM in_merge m;

-- The row count BEFORE the move, so the gate can prove nothing was created or destroyed.
-- ⚠ The first version of that gate compared a count to itself and could never fail.
CREATE TEMP TABLE in_src_before ON COMMIT DROP AS
SELECT count(*) AS n FROM transparent_motivations.politician_sources;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_rows int; v_null int; v_dupe int; v_srcs int; v_collide int;
BEGIN
  SELECT count(*) INTO v_rows FROM in_merge_ids;
  IF v_rows <> 55 THEN RAISE EXCEPTION 'CC_0102 pre-flight: % merge rows, expected 55', v_rows; END IF;

  -- Every name must resolve. A NULL here means a row moved or was renamed since the review.
  SELECT count(*) INTO v_null FROM in_merge_ids WHERE orphan_id IS NULL OR seated_id IS NULL;
  IF v_null <> 0 THEN
    RAISE EXCEPTION 'CC_0102 pre-flight: % pair(s) do not resolve to exactly one orphan and one seated row', v_null;
  END IF;

  -- No seated row may be the target of two merges, and no orphan may appear twice.
  SELECT count(*) INTO v_dupe FROM (
    SELECT seated_id FROM in_merge_ids GROUP BY seated_id HAVING count(*) > 1
    UNION ALL
    SELECT orphan_id FROM in_merge_ids GROUP BY orphan_id HAVING count(*) > 1) s;
  IF v_dupe <> 0 THEN RAISE EXCEPTION 'CC_0102 pre-flight: % id(s) appear in more than one merge', v_dupe; END IF;

  -- The sources to move. 0 means this already ran.
  SELECT count(*) INTO v_srcs
    FROM in_merge_ids m JOIN transparent_motivations.politician_sources s
      ON s.essentials_politician_id = m.orphan_id;
  IF v_srcs NOT IN (0, 55) THEN
    RAISE EXCEPTION 'CC_0102 pre-flight: % source row(s) on the orphans, expected 0 (re-run) or 55', v_srcs;
  END IF;

  -- 🔴 UNIQUE (essentials_politician_id, source_system, external_id). A collision would abort the
  -- whole migration; measured at 0 on 2026-09-12, and asserted rather than assumed.
  SELECT count(*) INTO v_collide
    FROM in_merge_ids m
    JOIN transparent_motivations.politician_sources s  ON s.essentials_politician_id = m.orphan_id
    JOIN transparent_motivations.politician_sources s2 ON s2.essentials_politician_id = m.seated_id
     AND s2.source_system = s.source_system AND s2.external_id = s.external_id;
  IF v_collide <> 0 THEN
    RAISE EXCEPTION 'CC_0102 pre-flight: % source row(s) would collide with one already on the seated row', v_collide;
  END IF;
END $$;

-- ─── The repoint ─────────────────────────────────────────────────────────────
-- ⚠ `notes` is NOT overwritten. All 55 rows already carry the discovery note naming the
-- committee, which is the corroboration described above; the provenance line is appended to it.

UPDATE transparent_motivations.politician_sources s
   SET essentials_politician_id = m.seated_id,
       notes = btrim(coalesce(s.notes, '')) || E'\n'
               || 'CC_0102 (2026-09-12): repointed from the duplicate indiana_discovery row "'
               || m.orphan_name || '" to the seated officeholder "' || m.seated_name
               || '". Identity confirmed by hand review of all 69 candidate pairs, not by a name rule.',
       updated_at = now()
  FROM in_merge_ids m
 WHERE s.essentials_politician_id = m.orphan_id;

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_on_seated int; v_on_orphan int; v_people int; v_total int; v_noted int; v_active int;
BEGIN
  SELECT count(*) INTO v_on_seated
    FROM in_merge_ids m JOIN transparent_motivations.politician_sources s
      ON s.essentials_politician_id = m.seated_id
   WHERE s.source_type = 'candidate_committee';
  IF v_on_seated < 55 THEN
    RAISE EXCEPTION 'CC_0102: % committee source(s) on the seated rows, expected at least 55', v_on_seated;
  END IF;

  SELECT count(*) INTO v_on_orphan
    FROM in_merge_ids m JOIN transparent_motivations.politician_sources s
      ON s.essentials_politician_id = m.orphan_id;
  IF v_on_orphan <> 0 THEN
    RAISE EXCEPTION 'CC_0102: % source row(s) still point at an orphan', v_on_orphan;
  END IF;

  -- Nothing was created or destroyed: this is a MOVE, so the table's total must be unchanged.
  SELECT count(*) INTO v_total FROM transparent_motivations.politician_sources;
  IF v_total <> (SELECT n FROM in_src_before) THEN
    RAISE EXCEPTION 'CC_0102: politician_sources held % rows before and % after -- a move must not change the total',
      (SELECT n FROM in_src_before), v_total;
  END IF;

  SELECT count(*) INTO v_noted
    FROM in_merge_ids m JOIN transparent_motivations.politician_sources s
      ON s.essentials_politician_id = m.seated_id
   WHERE s.notes LIKE '%CC_0102 (2026-09-12): repointed from%';
  IF v_noted <> 55 THEN
    RAISE EXCEPTION 'CC_0102: % repointed row(s) carry the provenance note, expected 55', v_noted;
  END IF;

  -- 🔴 The orphan PEOPLE are untouched: still present, still deactivated by CC_0101.
  SELECT count(*) INTO v_people FROM in_merge_ids m JOIN essentials.politicians p ON p.id = m.orphan_id;
  IF v_people <> 55 THEN RAISE EXCEPTION 'CC_0102: % orphan people present, expected 55', v_people; END IF;

  SELECT count(*) INTO v_active FROM in_merge_ids m JOIN essentials.politicians p ON p.id = m.orphan_id
   WHERE p.is_active OR p.is_incumbent;
  IF v_active <> 0 THEN
    RAISE EXCEPTION 'CC_0102: % orphan row(s) became active again -- this migration must not touch flags', v_active;
  END IF;

  RAISE NOTICE 'CC_0102 OK: 55 committee sources repointed to seated officeholders, 0 left on orphans, 0 people changed';
END $$;

COMMIT;
