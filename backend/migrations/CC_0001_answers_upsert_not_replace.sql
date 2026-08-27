BEGIN;

-- ✅ APPLIED TO PRODUCTION 2026-08-26. Verified against the LIVE function after
-- applying: exactly 1 overload, signature unchanged
-- ("p_politician_id uuid, p_answers jsonb"), no DELETE statement, still upserts.
-- 33,164 answers / 33,818 context rows unchanged.
-- Re-ran the destructive case against the live function in a rolled-back txn:
--   single-topic save (the admin UI's payload) -> 41 -> 41 answers, 0 destroyed,
--     value written = 3. It was 41 -> 1, 40 destroyed, before this migration.
--   empty payload                              -> 41 of 41 answers remain.
--
-- ⚠ THE POST-VERIFY GATE REFUSED THE FIRST APPLY, CORRECTLY-ISH. Its DELETE
-- check matched the word inside this function's own comment ("No DELETE...")
-- and aborted a correct migration. Nothing was applied by that attempt — the
-- transaction rolled back and the live function was untouched. The gate now
-- strips -- comments and looks for the STATEMENT (delete\s+from), not the word.
--
-- 🔴 FIRST MIGRATION IN THE `CC_` NAMESPACE. `CA_` is historically MIXED —
-- Chris Andrews wrote CA_0001-0003/0011/0012/0015/0016, Chris Cantrell wrote
-- CA_0004-0010 and CA_0017-0019 — so it could not identify an author and is now
-- closed to new work. See CLAUDE.md. Nothing was retro-renamed: CA_0012 is
-- embedded in 44 compass_topic_revisions rows and a column comment.


-- =============================================================================
-- CC_0001: admin_update_politician_answers UPSERTS. It no longer deletes.
-- =============================================================================
-- 🔴 LIVE DATA-LOSS BUG. Not a seasons problem — this is true in production
-- today and has been for as long as the function has existed.
--
-- The function deletes every answer NOT present in the payload:
--
--     DELETE FROM inform.politician_answers
--      WHERE politician_id = p_politician_id
--        AND (v_topic_ids IS NULL OR topic_id != ALL(v_topic_ids));
--
-- The admin UI's per-topic Save button (admin/src/pages/admin/PoliticiansPage.tsx,
-- TopicAnswerRow.handleSave) sends ONE topic:
--
--     body: JSON.stringify({ answers: [{ topic_id: topic.id, value: selectedValue }] })
--
-- So saving a single stance deletes every OTHER stance that politician has.
-- MEASURED against prod in a rolled-back transaction, calling the real function
-- with the real payload shape: 41 answers before, 1 after. 40 destroyed by one
-- click. All 41 context rows were left behind, orphaned.
--
-- An empty payload is worse: array_agg over zero elements returns NULL, so
-- `v_topic_ids IS NULL` selects every row and wipes the politician entirely.
-- Reachable through PUT /admin/compass/politicians/:id/answers, whose Zod schema
-- is z.array(...) with no .min(1). (The other route, routes/admin.ts, is safe by
-- accident: adminService returns early on an empty array.)
--
-- WHY UPSERT-ONLY IS A FIX AND NOT A SEMANTIC CHANGE. Nothing asks for
-- delete-by-omission. Both docstrings say "Upsert politician answers". Both
-- callers send a partial set. No UI offers "remove this stance" through this
-- path — the contributor route has its own explicit clear-stance handler. The
-- DELETE is undocumented, unrequested, and contradicts the function's stated
-- purpose.
--
-- If a genuine "replace the whole set" operation is ever wanted, it should be a
-- separate function with a name that says so, and it should decide what happens
-- to the matching inform.politician_context rows — which this DELETE never did.
-- That omission is how ORPHAN_CONTEXT rows can appear at RUNTIME rather than
-- through a migration; CLAUDE.md obliges a migration deleting answers to make
-- that call.
--
-- ⚠ HAS IT ALREADY FIRED? Probably not at scale. The signature would be a
-- politician left with 1 answer and many orphaned context rows — a gap of 30-40
-- for a well-researched person. Measured 2026-08-26: 190 politicians carry more
-- context than answers, 654 rows in total, but the gaps run 1 to 9 and cluster
-- at 1. That is the known ORPHAN_CONTEXT population, not this. No politician
-- shows the large gap this bug would leave. Read as "no evidence of damage",
-- not as "proof of none".
--
-- Signature is UNCHANGED on purpose. CREATE OR REPLACE with a changed signature
-- is an OVERLOAD, not a replacement — an earlier draft of the seasons work added
-- a parameter and left the old broken body live for PostgREST to resolve to.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_update_politician_answers(
  p_politician_id uuid, p_answers jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_answer jsonb;
BEGIN
  -- No DELETE. This function sets the answers it is given and touches nothing
  -- else. Removing a stance is a separate, explicit operation.
  FOR v_answer IN SELECT * FROM jsonb_array_elements(p_answers)
  LOOP
    INSERT INTO inform.politician_answers (politician_id, topic_id, value)
    VALUES (
      p_politician_id,
      (v_answer->>'topic_id')::uuid,
      (v_answer->>'value')::numeric
    )
    ON CONFLICT (politician_id, topic_id) DO UPDATE
      SET value = EXCLUDED.value;
  END LOOP;
END;
$function$;

DO $$
DECLARE
  v_def   text;
  v_count int;
BEGIN
  SELECT count(*) INTO v_count
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public' AND p.proname = 'admin_update_politician_answers';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 admin_update_politician_answers, found % — a changed signature creates an OVERLOAD, leaving the old body live', v_count;
  END IF;

  SELECT pg_get_functiondef(p.oid) INTO v_def
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public' AND p.proname = 'admin_update_politician_answers';

  -- Strip -- comments before looking for a DELETE. The first version of this
  -- gate matched the word inside the body's own explanatory comment ("No
  -- DELETE...") and refused a correct migration. Look for the STATEMENT.
  -- The 'n' flag makes . stop at a newline and $ mean end-of-line, so this
  -- needs no backslash escapes inside a SQL string literal.
  IF regexp_replace(v_def, '--.*$', '', 'ng') ~* '\ydelete\s+from\y' THEN
    RAISE EXCEPTION 'admin_update_politician_answers still contains a DELETE statement';
  END IF;
  IF v_def !~* 'ON CONFLICT' THEN
    RAISE EXCEPTION 'admin_update_politician_answers no longer upserts';
  END IF;
  IF pg_get_function_identity_arguments(
       (SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname='public' AND p.proname='admin_update_politician_answers'))
     <> 'p_politician_id uuid, p_answers jsonb' THEN
    RAISE EXCEPTION 'signature changed — PostgREST callers would resolve elsewhere';
  END IF;

  RAISE NOTICE 'admin_update_politician_answers is upsert-only — no DELETE, signature unchanged';
END $$;

COMMIT;
