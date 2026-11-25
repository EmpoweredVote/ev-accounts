-- CA_0420_essentials_citations.sql
-- Slot RESERVED from the allocator. Creates essentials.citations: one row per SOURCE behind one fact
-- about one record, with a link a reader can follow.
--
-- WHY. Every officeholder, district and map row carries a free-text `source` note, and the link is
-- buried in a sentence ("CA_0417 Indiana cities Wave A: https://…/officials, read 2026-11-24"). The
-- app cannot link to that, and one note cannot hold two sources, which real seats need: Muncie
-- District 4 is vacant on the strength of a city page AND a news report; Greenwood's roster rests on
-- the city page AND its GIS layer. Decision 2026-11-24 (Chris Andrews): a table, not a column.
--
-- SHAPE.
--   subject_type + subject_id  the record the source supports. Polymorphic, so there is NO foreign key;
--                              every migration that writes citations gates its own orphans at zero in its
--                              post-verify (see CA_0421 for the shape).
--   claim                      WHAT the source supports about that record. A source can be authoritative
--                              for one field and stale for another (backend/migrations/CLAUDE.md, "Sourcing
--                              a seat"), so a citation names the field it vouches for:
--                                holder     who holds the seat              (subject: office_term)
--                                vacancy    that the seat is empty          (subject: office)
--                                structure  the body's seats and offices    (subject: government)
--                                boundary   the shape of a district         (subject: geofence_boundary)
--                                name       a person's name or former name  (subject: politician)
--                                term_date  a term's start or end date      (subject: office_term)
--   url                        the page as published. For a page we could only read through the Wayback
--                              Machine, this is the ORIGINAL address and archive_url holds the snapshot.
--   archive_url                a dated copy that survives the city redesigning its site. Optional.
--   retrieved_on               the day we read it. Required: a citation with no date cannot be re-checked.
--   added_by                   the migration slot that wrote the row, e.g. 'CA_0421'.
--
-- ACCESS. Read by the API (ev_api) only; written by migrations. On `essentials`, ALTER DEFAULT
-- PRIVILEGES grants anon and authenticated SELECT and ev_api arwd on every new table before this file
-- says a word (measured on prod by CC_0457), so RLS is the only thing keeping this table private, and
-- the REVOKEs below make the grant block true rather than decorative.

BEGIN;

CREATE TABLE IF NOT EXISTS essentials.citations (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type  text        NOT NULL CHECK (subject_type IN
                  ('office_term', 'office', 'government', 'district', 'geofence_boundary', 'politician')),
  subject_id    uuid        NOT NULL,
  claim         text        NOT NULL CHECK (claim IN
                  ('holder', 'vacancy', 'structure', 'boundary', 'name', 'term_date')),
  url           text        NOT NULL CHECK (url ~ '^https?://[^ ]+$'),
  title         text,
  publisher     text,
  retrieved_on  date        NOT NULL,
  archive_url   text        CHECK (archive_url IS NULL OR archive_url ~ '^https?://[^ ]+$'),
  note          text,
  added_by      text        NOT NULL CHECK (added_by ~ '^(CA|CC|shared)_\d{4}$'),
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (subject_type, subject_id, claim, url)
);

CREATE INDEX IF NOT EXISTS citations_subject_idx ON essentials.citations (subject_type, subject_id);

COMMENT ON TABLE essentials.citations IS
  'Source links behind facts about essentials records: one row per source per claim per record. Polymorphic subject, no FK; writers gate orphans. CA_0420.';

ALTER TABLE essentials.citations ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON essentials.citations FROM PUBLIC, anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON essentials.citations FROM ev_api;
GRANT SELECT ON essentials.citations TO ev_api;
GRANT ALL    ON essentials.citations TO service_role;

DROP POLICY IF EXISTS citations_api_read ON essentials.citations;
CREATE POLICY citations_api_read ON essentials.citations FOR SELECT TO ev_api USING (true);

DROP POLICY IF EXISTS citations_service ON essentials.citations;
CREATE POLICY citations_service ON essentials.citations FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ─── Post-verify: the table is private and read-only to the API ──────────────
DO $$
DECLARE v_rls bool; v_bad text;
BEGIN
  SELECT relrowsecurity INTO v_rls FROM pg_class WHERE oid = 'essentials.citations'::regclass;
  IF NOT v_rls THEN RAISE EXCEPTION 'CA_0420: RLS is not enabled on essentials.citations'; END IF;

  SELECT string_agg(r || ':' || p, ', ') INTO v_bad
  FROM (VALUES ('anon','SELECT'), ('authenticated','SELECT'), ('anon','INSERT'), ('authenticated','INSERT'),
               ('ev_api','INSERT'), ('ev_api','UPDATE'), ('ev_api','DELETE')) AS t(r, p)
  WHERE has_table_privilege(r, 'essentials.citations', p);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CA_0420: roles still hold privileges they must not: %', v_bad; END IF;

  IF NOT has_table_privilege('ev_api', 'essentials.citations', 'SELECT') THEN
    RAISE EXCEPTION 'CA_0420: ev_api cannot read essentials.citations';
  END IF;

  RAISE NOTICE 'CA_0420 OK: essentials.citations created, RLS on, anon/authenticated none, ev_api SELECT only';
END $$;

COMMIT;
