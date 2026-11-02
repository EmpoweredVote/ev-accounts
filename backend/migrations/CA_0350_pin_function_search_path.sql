BEGIN;

-- =============================================================================
-- CA_0350: pin search_path on the twelve functions the advisor flags
-- =============================================================================
-- Created 2026-11-02 with Chris Andrews. Steward slot CA_0350. Clears the
-- Supabase security advisor's WARN `function_search_path_mutable` (12), as
-- pulled 2026-11-02.
--
-- WHAT THIS DOES
-- ALTER FUNCTION ... SET search_path = '' on twelve functions. With no pinned
-- path, a function resolves unqualified names through whatever search_path its
-- CALLER has set, so a caller who can create objects in an earlier schema can
-- substitute their own. With '' nothing resolves except pg_catalog (always
-- searched) and fully qualified names.
--
-- WHY NO BODY CHANGES
-- Every body was read live on 2026-11-02 before writing this. All twelve already
-- schema-qualify every table, type and extension function they use
-- (essentials.*, inform.*, treasury.*, extensions.unaccent, extensions.similarity).
-- What is left unqualified is pg_catalog only (lower, regexp_replace, format,
-- generate_series, to_jsonb, jsonb operators). extensions.unaccent(text) finds
-- its dictionary with search_path '' — tested in a scratch function first.
--
-- ONE COST, MEASURED
-- A SET clause stops Postgres inlining a small SQL function. is_live_candidate
-- sits in the address-search query (districtQueries.ts) and eight other reads.
-- Measured against every essentials.race_candidates row: 37 ms inlined, 25 ms
-- with the pinned path — no regression. candidate_name_key backs the unique
-- index race_candidates_race_name_key_uniq; its output is unchanged (gate b).
--
-- VALUES THIS OVERWRITES
-- proconfig was NULL on all twelve. To undo: ALTER FUNCTION ... RESET search_path.
--
-- Idempotent: ALTER FUNCTION ... SET is safe to re-run.
-- =============================================================================

-- (pre) Capture what the read functions return BEFORE the change, so the gate can
-- prove the pinned path changes no answer.
CREATE TEMP TABLE _ca0350_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM essentials.office_holders_as_of(current_date))                      AS holders_today,
  (SELECT md5(string_agg(essentials.candidate_name_key(full_name), '|' ORDER BY id))
     FROM essentials.race_candidates)                                                       AS name_keys,
  (SELECT count(*) FILTER (WHERE essentials.is_live_candidate(candidate_status, result))
     FROM essentials.race_candidates)                                                       AS live_candidates,
  (SELECT md5(string_agg(user_id::text || topic_id::text || disposition, '|'
                         ORDER BY user_id, topic_id))
     FROM inform.compass_answer_dispositions)                                               AS dispositions,
  (SELECT count(*) FROM treasury.detect_forked_entities())                                  AS forked;

ALTER FUNCTION essentials.office_holders_as_of(date)                 SET search_path = '';
ALTER FUNCTION essentials.refresh_readrank_pipeline_counters()       SET search_path = '';
ALTER FUNCTION essentials.is_live_candidate(text, text)              SET search_path = '';
ALTER FUNCTION essentials.candidate_name_key(text)                   SET search_path = '';
ALTER FUNCTION treasury.require_fiscal_year_start_month()            SET search_path = '';
ALTER FUNCTION treasury.guard_alias_is_not_an_entity()               SET search_path = '';
ALTER FUNCTION treasury.detect_forked_entities()                     SET search_path = '';
ALTER FUNCTION treasury.frozen_verdict(bigint, text, bigint, text)   SET search_path = '';
ALTER FUNCTION inform.season_pin_is_immutable()                      SET search_path = '';
ALTER FUNCTION inform.compass_answer_disposition(uuid, uuid, numeric) SET search_path = '';
ALTER FUNCTION inform.gold_labels_append_only()                      SET search_path = '';
ALTER FUNCTION inform.certifications_immutable()                     SET search_path = '';

DO $$
DECLARE
  b      record;
  v_n    bigint;
  v_txt  text;
  v_msg  text;
  v_ok   boolean;
  v_fns  text[] := ARRAY[
    'essentials.office_holders_as_of(date)', 'essentials.refresh_readrank_pipeline_counters()',
    'essentials.is_live_candidate(text,text)', 'essentials.candidate_name_key(text)',
    'treasury.require_fiscal_year_start_month()', 'treasury.guard_alias_is_not_an_entity()',
    'treasury.detect_forked_entities()', 'treasury.frozen_verdict(bigint,text,bigint,text)',
    'inform.season_pin_is_immutable()', 'inform.compass_answer_disposition(uuid,uuid,numeric)',
    'inform.gold_labels_append_only()', 'inform.certifications_immutable()'];
  v_fn   text;
BEGIN
  -- (a) all twelve carry the pinned path.
  FOREACH v_fn IN ARRAY v_fns LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE oid = v_fn::regprocedure
                     AND 'search_path=""' = ANY (proconfig)) THEN
      RAISE EXCEPTION 'CA_0350: % has no pinned search_path', v_fn;
    END IF;
  END LOOP;

  -- (b) the read functions give the same answers as before.
  SELECT * INTO b FROM _ca0350_before;
  SELECT count(*) INTO v_n FROM essentials.office_holders_as_of(current_date);
  IF v_n <> b.holders_today THEN
    RAISE EXCEPTION 'CA_0350: office_holders_as_of returned % rows, % before', v_n, b.holders_today;
  END IF;
  SELECT md5(string_agg(essentials.candidate_name_key(full_name), '|' ORDER BY id))
    INTO v_txt FROM essentials.race_candidates;
  IF v_txt IS DISTINCT FROM b.name_keys THEN
    RAISE EXCEPTION 'CA_0350: candidate_name_key output changed';
  END IF;
  SELECT count(*) FILTER (WHERE essentials.is_live_candidate(candidate_status, result))
    INTO v_n FROM essentials.race_candidates;
  IF v_n <> b.live_candidates THEN
    RAISE EXCEPTION 'CA_0350: is_live_candidate admits %, % before', v_n, b.live_candidates;
  END IF;
  SELECT md5(string_agg(user_id::text || topic_id::text || disposition, '|' ORDER BY user_id, topic_id))
    INTO v_txt FROM inform.compass_answer_dispositions;
  IF v_txt IS DISTINCT FROM b.dispositions THEN
    RAISE EXCEPTION 'CA_0350: compass_answer_disposition output changed';
  END IF;
  SELECT count(*) INTO v_n FROM treasury.detect_forked_entities();
  IF v_n <> b.forked THEN
    RAISE EXCEPTION 'CA_0350: detect_forked_entities returned %, % before', v_n, b.forked;
  END IF;
  SELECT (f).* INTO v_ok FROM (SELECT treasury.frozen_verdict(1, 'x', 1, 'x') AS f) t;
  IF v_ok IS NOT TRUE THEN
    RAISE EXCEPTION 'CA_0350: frozen_verdict(1,x,1,x) is not a pass';
  END IF;

  -- (c) the writer runs. Inside a subtransaction that is always thrown away, so this
  --     migration changes no counter.
  BEGIN
    PERFORM essentials.refresh_readrank_pipeline_counters();
    RAISE EXCEPTION 'CA_0350_PROBE_UNWIND';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'CA_0350_PROBE_UNWIND' THEN RAISE; END IF;
  END;

  -- (d) each guard trigger still fires and still refuses. Each probe makes the write
  --     its guard exists to stop; the guard's own message is the pass. If a write ever
  --     got through, the trailing RAISE unwinds it and the gate fails.
  v_msg := NULL;
  BEGIN
    UPDATE treasury.data_sources SET fiscal_year_start_month = NULL
     WHERE id = (SELECT id FROM treasury.data_sources ORDER BY id LIMIT 1);
    RAISE EXCEPTION 'CA_0350_NO_GUARD';
  EXCEPTION WHEN OTHERS THEN v_msg := SQLERRM;
  END;
  IF v_msg NOT LIKE 'fiscal_year_start_month is required%' THEN
    RAISE EXCEPTION 'CA_0350: require_fiscal_year_start_month did not refuse (got: %)', v_msg;
  END IF;

  v_msg := NULL;
  BEGIN
    UPDATE treasury.municipality_aliases a
       SET alias_name = m.name, state = m.state, entity_type = m.entity_type
      FROM treasury.municipalities m
     WHERE m.id = a.municipality_id
       AND a.ctid = (SELECT ctid FROM treasury.municipality_aliases LIMIT 1);
    RAISE EXCEPTION 'CA_0350_NO_GUARD';
  EXCEPTION WHEN OTHERS THEN v_msg := SQLERRM;
  END;
  IF v_msg NOT LIKE '%is already a municipality name%' THEN
    RAISE EXCEPTION 'CA_0350: guard_alias_is_not_an_entity did not refuse (got: %)', v_msg;
  END IF;

  v_msg := NULL;
  BEGIN
    UPDATE inform.season_questions sq SET topic_revision_id = gen_random_uuid()
      FROM inform.seasons s
     WHERE s.id = sq.season_id AND s.status <> 'draft'
       AND sq.ctid = (SELECT q.ctid FROM inform.season_questions q
                        JOIN inform.seasons s2 ON s2.id = q.season_id
                       WHERE s2.status <> 'draft' LIMIT 1);
    RAISE EXCEPTION 'CA_0350_NO_GUARD';
  EXCEPTION WHEN OTHERS THEN v_msg := SQLERRM;
  END;
  IF v_msg NOT LIKE 'PIN_IMMUTABLE%' THEN
    RAISE EXCEPTION 'CA_0350: season_pin_is_immutable did not refuse (got: %)', v_msg;
  END IF;

  v_msg := NULL;
  BEGIN
    DELETE FROM inform.stance_gold_labels
     WHERE id = (SELECT id FROM inform.stance_gold_labels ORDER BY id LIMIT 1);
    RAISE EXCEPTION 'CA_0350_NO_GUARD';
  EXCEPTION WHEN OTHERS THEN v_msg := SQLERRM;
  END;
  IF v_msg NOT LIKE 'stance_gold_labels is append-only%' THEN
    RAISE EXCEPTION 'CA_0350: gold_labels_append_only did not refuse (got: %)', v_msg;
  END IF;

  v_msg := NULL;
  BEGIN
    DELETE FROM inform.reliability_certifications
     WHERE ctid = (SELECT ctid FROM inform.reliability_certifications LIMIT 1);
    RAISE EXCEPTION 'CA_0350_NO_GUARD';
  EXCEPTION WHEN OTHERS THEN v_msg := SQLERRM;
  END;
  IF v_msg NOT LIKE 'reliability_certifications rows are never changed%' THEN
    RAISE EXCEPTION 'CA_0350: certifications_immutable did not refuse (got: %)', v_msg;
  END IF;

  RAISE NOTICE 'CA_0350 OK — search_path pinned on 12 functions; office_holders_as_of (% today), candidate_name_key, is_live_candidate (%), compass_answer_disposition, detect_forked_entities and frozen_verdict answer exactly as before; refresh_readrank_pipeline_counters runs; all five guard triggers still refuse.',
    b.holders_today, b.live_candidates;
END $$;

COMMIT;
