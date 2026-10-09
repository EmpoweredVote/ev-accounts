-- CC_0207 — essentials.politician_merges: a retirement ledger for merged politician rows
--
-- WHY. `essentials.politicians` has exactly one archival column, `is_active`. Nothing records that
-- one row was folded into another. So when a duplicate is merged — which this repo already does,
-- via `backend/scripts/dedup-essentials-politicians.ts`, by re-routing every FK and then DELETING
-- the spare — the retired id simply stops resolving. Anything outside the foreign-key graph that
-- still holds it goes dead with no trace: an old CSV export, a bookmarked URL, a storage object
-- named `<uuid>-headshot.jpg`, a number written into a past migration's comment.
--
-- That is the one way merging can cost us history, and it is avoidable. The person's own record
-- survives a merge — terms, candidacies, answers and images are all re-routed to the canonical row
-- — but the MAPPING from the retired id to the surviving one is what nothing stores today.
--
-- 🔴 THIS TABLE IS THE RULE, NOT A CONVENIENCE. A merge migration writes here in the same
-- transaction that deletes the spare. If it did not, the delete would be the silent kind.
--
-- WHAT THIS IS NOT. It is not an archive of people. A person who leaves office is NOT merged and
-- NOT deleted: they keep their row, `is_active` goes false, their `office_terms` row is closed with
-- a `term_end`, and their answers stay attached to the seasons they were researched in. That is how
-- "who represented me in 2019" and "what did they say in season 1" keep working, and it is why a
-- returning candidate needs no re-research — the same row picks up a new `race_candidates` row.
-- This ledger is only for the case where TWO rows described ONE person and one of them must go.

BEGIN;

CREATE TABLE IF NOT EXISTS essentials.politician_merges (
  retired_id    uuid        PRIMARY KEY,
  canonical_id  uuid        NOT NULL REFERENCES essentials.politicians(id),
  retired_name  text        NOT NULL,
  migration     text        NOT NULL,
  merged_at     timestamptz NOT NULL DEFAULT now(),
  evidence      text        NOT NULL,
  moved         jsonb       NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT politician_merges_not_self CHECK (retired_id <> canonical_id),
  CONSTRAINT politician_merges_evidence_said CHECK (btrim(evidence) <> ''),
  CONSTRAINT politician_merges_migration_said CHECK (btrim(migration) <> '')
);

COMMENT ON TABLE essentials.politician_merges IS
  'One row per politician row retired by a merge. retired_id is deliberately NOT a foreign key: '
  'the row it names has been deleted, which is the whole point. canonical_id IS a foreign key, so '
  'the survivor can never be deleted out from under a mapping that points at it. Written in the '
  'same transaction as the delete — see CC_0207.';
COMMENT ON COLUMN essentials.politician_merges.retired_id IS
  'The politicians.id that no longer exists. Resolve an old id through this table before concluding '
  'it was never real.';
COMMENT ON COLUMN essentials.politician_merges.evidence IS
  'Why these were ruled one person, naming the sources checked. A merge with no stated evidence is '
  'the failure this table exists to make visible.';
COMMENT ON COLUMN essentials.politician_merges.moved IS
  'What was re-routed, as {"table": count}. Lets a reader see the merge dropped nothing without '
  'reconstructing it from the migration.';

-- Resolving a chain: if a canonical row is itself later merged away, follow the ledger forward.
CREATE INDEX IF NOT EXISTS politician_merges_canonical_idx
  ON essentials.politician_merges (canonical_id);

-- 🔴 DEFAULT-DENY RLS, NO POLICY. The schema-default SELECT grant makes every new base table in
-- `essentials` readable by anon and authenticated over the internet, and `check:rls-coverage`
-- fails on exactly that. This table is internal bookkeeping — it names rows that were deleted and
-- the evidence used to rule on a person's identity — so nothing outside the server should read it.
-- Pattern: 1891_source_hubs_rls_default_deny.sql.
ALTER TABLE essentials.politician_merges ENABLE ROW LEVEL SECURITY;

-- ⚠ ADOPTED, NOT MINE. `essentials.photo_restrictions` has been internet-readable with RLS off
-- since 07a48856c (the South Dakota portrait work). `check:rls-coverage` is path-filtered, so it
-- had not run on a PR that touched it, and it reports this table alongside the one added above.
-- Fixing it here rather than leaving the gate red for the next author. Verified safe: the only
-- reader is `backend/src/lib/photoRestriction.ts`, which connects as `ev_api`, and `ev_api` holds
-- `rolbypassrls` — so default-deny closes anon and authenticated without touching the API. The
-- frontend never queries `essentials.*` directly (CLAUDE.md).
ALTER TABLE essentials.photo_restrictions ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  v_cols int;
BEGIN
  IF to_regclass('essentials.politician_merges') IS NULL THEN
    RAISE EXCEPTION 'CC_0207: essentials.politician_merges was not created';
  END IF;

  SELECT count(*) INTO v_cols
    FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'politician_merges';
  IF v_cols <> 7 THEN
    RAISE EXCEPTION 'CC_0207: politician_merges has % columns, expected 7', v_cols;
  END IF;

  -- retired_id must NOT be a foreign key. If a later hand adds one, every merge breaks, because the
  -- row it names is gone by the time the ledger entry is written.
  IF EXISTS (
    SELECT 1 FROM pg_constraint c
     WHERE c.conrelid = 'essentials.politician_merges'::regclass
       AND c.contype = 'f'
       AND 'retired_id' = ANY (
             SELECT a.attname FROM pg_attribute a
              WHERE a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey))
  ) THEN
    RAISE EXCEPTION 'CC_0207: retired_id must not be a foreign key — the row it names is deleted';
  END IF;

  -- canonical_id MUST be one, so a survivor cannot be deleted while a mapping points at it.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c
     WHERE c.conrelid = 'essentials.politician_merges'::regclass
       AND c.contype = 'f'
       AND 'canonical_id' = ANY (
             SELECT a.attname FROM pg_attribute a
              WHERE a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey))
  ) THEN
    RAISE EXCEPTION 'CC_0207: canonical_id must be a foreign key to essentials.politicians';
  END IF;

  IF NOT (SELECT c.relrowsecurity FROM pg_class c
            WHERE c.oid = 'essentials.politician_merges'::regclass) THEN
    RAISE EXCEPTION 'CC_0207: row-level security is OFF — the table is internet-readable';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies
              WHERE schemaname = 'essentials' AND tablename = 'politician_merges') THEN
    RAISE EXCEPTION 'CC_0207: a policy exists — this table is default-deny and must have none';
  END IF;

  RAISE NOTICE 'CC_0207: essentials.politician_merges ready, RLS on, no policy';
END $$;

COMMIT;
