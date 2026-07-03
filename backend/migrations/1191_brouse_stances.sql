-- Migration 1191: Renee Brouse (Councilor, Sherwood OR) compass stances — AUDIT-ONLY (not registered in the ledger)
-- Evidence-only; 100% cited; chairs model (value 1-5); 1 cited stance; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live=true (no hardcoded topic UUIDs).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Brouse, present remotely, voted with the full council 7:0 at the October 28, 2025 special session to adopt Resolutions 2025-073/074/075, calling a January 13, 2026 special election on Charter amendments that require voter approval for annexations (except declared public-health emergencies) and bar any Type III-or-higher land use decision without at least one neighborhood meeting and one public hearing, expressly declaring these local procedures "shall not be preempted by state laws." During Council discussion of the citizen-involvement measure, Brouse pointed to its opening line -- "As a city that is of the people, by the people, and for the people, Sherwood is committed to hearing from the people" -- and said that language "gave her the most energy and drive to want to see this passed." After voters ratified the measures, she said in a Sherwood Sun piece that under the new voter-approved framework "growth will continue, but these measures ensure that how we grow reflects the voices of the people who live here," and that for large projects like Sherwood West "these measures don''t stop growth -- they guide it." Championing and voting for a voter-approval gate on annexations plus mandatory public hearings before major development, entrenched against state preemption, matches the growth-limits/voter-approval chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.sherwoodsun.org/whats-going-on-with-sherwood-west/']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'eb246bf6-039f-4ab6-9655-be849339fedd'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('growth-and-development', 1, 'Brouse, present remotely, voted with the full council 7:0 at the October 28, 2025 special session to adopt Resolutions 2025-073/074/075, calling a January 13, 2026 special election on Charter amendments that require voter approval for annexations (except declared public-health emergencies) and bar any Type III-or-higher land use decision without at least one neighborhood meeting and one public hearing, expressly declaring these local procedures "shall not be preempted by state laws." During Council discussion of the citizen-involvement measure, Brouse pointed to its opening line -- "As a city that is of the people, by the people, and for the people, Sherwood is committed to hearing from the people" -- and said that language "gave her the most energy and drive to want to see this passed." After voters ratified the measures, she said in a Sherwood Sun piece that under the new voter-approved framework "growth will continue, but these measures ensure that how we grow reflects the voices of the people who live here," and that for large projects like Sherwood West "these measures don''t stop growth -- they guide it." Championing and voting for a voter-approval gate on annexations plus mandatory public hearings before major development, entrenched against state preemption, matches the growth-limits/voter-approval chair.', ARRAY['https://www.sherwoodoregon.gov/wp-content/uploads/2025/12/10.28.2025-City-Council-Meeting-Minutes.pdf', 'https://www.sherwoodsun.org/whats-going-on-with-sherwood-west/']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'eb246bf6-039f-4ab6-9655-be849339fedd'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id — a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = 'eb246bf6-039f-4ab6-9655-be849339fedd';
  IF v_ext IS DISTINCT FROM -4167103 THEN
    RAISE EXCEPTION 'UUID eb246bf6-039f-4ab6-9655-be849339fedd does not belong to external_id -4167103 (Renee Brouse) — found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = 'eb246bf6-039f-4ab6-9655-be849339fedd';
  IF n <> 1 THEN
    RAISE EXCEPTION 'Expected % answers, found % — topic_key mismatch dropped rows', 1, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = 'eb246bf6-039f-4ab6-9655-be849339fedd';
  IF n <> 1 THEN
    RAISE EXCEPTION 'Expected % context rows, found % — answers/context VALUES lists diverged', 1, n;
  END IF;
END $$;

COMMIT;
