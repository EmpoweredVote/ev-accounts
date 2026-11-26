-- Migration CA_PENDING_local_record_storage_bucket: the private bucket that keeps the council record's source copies
--
-- WHY: the weekly council-record run saves a copy of every vote document it reads (the clerk's Memorandum, the
--   formal Minutes) and of item texts, then re-reads a saved copy for its control check (spec D6). It writes to the
--   Storage bucket `local-record-sources` (backend/src/lib/localRecord/refresh.ts, BUCKET). Nothing created that
--   bucket, so the first real run would fail on its first upload.
-- WHAT: bucket `local-record-sources`. Private. Only the two content types the code uploads (store.ts TYPES):
--   application/pdf (Memorandum, Minutes) and text/plain (item text). No size limit of its own (the project-wide
--   upload limit applies). Objects are <city scope>/<kind>/<sha256>.<ext>. No policies on storage.objects for this
--   bucket, so only the service role (the weekly job) can read or write it. Never public: the public record links to
--   the city's own document URL, not to this copy. Follows CA_0382 (legiscan-datasets).
-- Creates only; overwrites no value. Idempotent (ON CONFLICT DO NOTHING; the gate re-checks an existing bucket).
-- Slot: named CA_PENDING until a CA number is reserved. Not applied by this commit.
--
-- ROLLBACK (empty the bucket first in the dashboard, or delete its storage.objects rows):
--   delete from storage.buckets where id = 'local-record-sources';

begin;

insert into storage.buckets (id, name, public, allowed_mime_types)
values ('local-record-sources', 'local-record-sources', false, array['application/pdf', 'text/plain'])
on conflict (id) do nothing;

do $$
declare b record;
begin
  select public, allowed_mime_types into b from storage.buckets where id = 'local-record-sources';
  if not found then raise exception 'local_record_storage_bucket: bucket local-record-sources missing'; end if;
  if b.public then raise exception 'local_record_storage_bucket: bucket local-record-sources is PUBLIC; it must be private'; end if;
  if b.allowed_mime_types is distinct from array['application/pdf', 'text/plain'] then
    raise exception 'local_record_storage_bucket: unexpected allowed_mime_types %', b.allowed_mime_types;
  end if;
  -- No policy may open this bucket to anon or authenticated users.
  if exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and (coalesce(qual, '') || coalesce(with_check, '')) like '%local-record-sources%'
  ) then
    raise exception 'local_record_storage_bucket: a storage.objects policy mentions local-record-sources; the bucket must stay service-role only';
  end if;
end $$;

commit;
