-- CC_0105_turpin_identity_merge.sql
-- Indiana debt 1, the last identity merge. Slot RESERVED from the allocator.
--
-- Repoints Ronald Turpin's candidate-committee source onto Ron Turpin, the seated Allen County
-- Commissioner for District 1. One row. Deletes nothing, merges no person row, touches no flag.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- THIS IS THE SINGLE `unsure` FROM THE CLASS B REVIEW, NOW RESOLVED.
--
-- The hand review of 69 candidate pairs (2026-09-12) returned 55 same, 13 different and ONE
-- unsure: Ronald Turpin. The doubt was an office mismatch — the orphan row's placeholder title
-- said `State Senator`, while the seated row holds `Commissioner, District 1` in Allen County.
--
-- ▶ RESOLVED BY THE PERSON WHO KNOWS THE JURISDICTION (Cantrell, 2026-09-12):
-- **"Ronald Turpin is Allen County Commissioner — not state senator."** Same man. The placeholder
-- title recorded an office he sought, which is what every title in that cohort records; it was
-- never evidence of a second person.
--
-- ⚠ THAT IS THE WHOLE LESSON OF THE OFFICE-MISMATCH SIGNAL. It was the one thing that made this
-- pair look different from the 55, and it turned out to be the cohort's defining property rather
-- than a discriminator. A signal shared by every row in a population cannot separate rows in it.
--
-- His orphan OFFICE is already gone (CC_0104 retired all 587). What is left is the finance link,
-- which CC_0102 deliberately did not move because the pair was unresolved.
--
-- Idempotent: a re-run moves 0.

BEGIN;

CREATE TEMP TABLE in_turpin ON COMMIT DROP AS
SELECT (SELECT p.id FROM essentials.politicians p
         WHERE p.full_name = 'Ronald Turpin' AND p.source = 'indiana_discovery') AS orphan_id,
       (SELECT p2.id FROM essentials.politicians p2
         JOIN essentials.office_current_holder och ON och.politician_id = p2.id
         JOIN essentials.offices o ON o.id = och.office_id
         JOIN essentials.chambers c ON c.id = o.chamber_id
         JOIN essentials.governments g ON g.id = c.government_id
        WHERE p2.full_name = 'Ron Turpin'
          AND g.name = 'Allen County, Indiana, US'
          AND o.title = 'Commissioner, District 1') AS seated_id;

DO $$
DECLARE v_o uuid; v_s uuid; v_src int; v_collide int;
BEGIN
  SELECT orphan_id, seated_id INTO v_o, v_s FROM in_turpin;
  IF v_o IS NULL THEN RAISE EXCEPTION 'CC_0105 pre-flight: the Ronald Turpin orphan row does not resolve'; END IF;
  IF v_s IS NULL THEN
    RAISE EXCEPTION 'CC_0105 pre-flight: Ron Turpin does not resolve to Allen County Commissioner District 1 -- the seat this merge is predicated on';
  END IF;
  IF v_o = v_s THEN RAISE EXCEPTION 'CC_0105 pre-flight: both names resolve to the same row'; END IF;

  SELECT count(*) INTO v_src FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = v_o;
  IF v_src NOT IN (0, 1) THEN
    RAISE EXCEPTION 'CC_0105 pre-flight: % source row(s) on the orphan, expected 1 (or 0 on a re-run)', v_src;
  END IF;

  -- UNIQUE (essentials_politician_id, source_system, external_id), as in CC_0102.
  SELECT count(*) INTO v_collide
    FROM transparent_motivations.politician_sources s
    JOIN transparent_motivations.politician_sources s2
      ON s2.essentials_politician_id = v_s
     AND s2.source_system = s.source_system AND s2.external_id = s.external_id
   WHERE s.essentials_politician_id = v_o;
  IF v_collide <> 0 THEN RAISE EXCEPTION 'CC_0105 pre-flight: the source would collide with one already on Ron Turpin'; END IF;
END $$;

CREATE TEMP TABLE in_before ON COMMIT DROP AS
SELECT count(*) AS n FROM transparent_motivations.politician_sources;

UPDATE transparent_motivations.politician_sources s
   SET essentials_politician_id = t.seated_id,
       notes = btrim(coalesce(s.notes, '')) || E'\n'
               || 'CC_0105 (2026-09-12): repointed from the duplicate indiana_discovery row '
               || '"Ronald Turpin" to the seated officeholder "Ron Turpin", Allen County '
               || 'Commissioner District 1. The class B review left this pair unsure because the '
               || 'placeholder title said State Senator; resolved by ruling — same man, and the '
               || 'title recorded an office sought.',
       updated_at = now()
  FROM in_turpin t
 WHERE s.essentials_politician_id = t.orphan_id;

DO $$
DECLARE v_on_seated int; v_on_orphan int; v_total int;
BEGIN
  SELECT count(*) INTO v_on_seated FROM transparent_motivations.politician_sources s, in_turpin t
   WHERE s.essentials_politician_id = t.seated_id;
  IF v_on_seated < 1 THEN RAISE EXCEPTION 'CC_0105: Ron Turpin holds % source(s), expected at least 1', v_on_seated; END IF;

  SELECT count(*) INTO v_on_orphan FROM transparent_motivations.politician_sources s, in_turpin t
   WHERE s.essentials_politician_id = t.orphan_id;
  IF v_on_orphan <> 0 THEN RAISE EXCEPTION 'CC_0105: % source(s) still on the orphan row', v_on_orphan; END IF;

  -- A move, not a create or a delete.
  SELECT count(*) INTO v_total FROM transparent_motivations.politician_sources;
  IF v_total <> (SELECT n FROM in_before) THEN
    RAISE EXCEPTION 'CC_0105: politician_sources went from % to %', (SELECT n FROM in_before), v_total;
  END IF;

  RAISE NOTICE 'CC_0105 OK: Turpin''s committee source repointed to the seated Allen County commissioner; nothing created or deleted';
END $$;

COMMIT;
