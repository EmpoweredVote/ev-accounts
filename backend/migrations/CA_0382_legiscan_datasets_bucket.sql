-- CA_0382_legiscan_datasets_bucket.sql
-- A private Storage bucket that keeps a copy of every LegiScan dataset ZIP our jobs download.
--
-- Created 2026-11-13 with Chris Andrews. Steward slot CA_0382.
--
-- WHY. On 2026-11-13 LegiScan paused our API key (until 19:42 UTC) for repeat downloads of datasets
-- that had not changed, and warned the next block may be longer or permanent. The weekly job
-- (ev-jobs-legiscan) downloaded each dataset and discarded the ZIP after loading it, so Stage 5
-- research scripts downloaded the same unchanged datasets again with the same key: of 19 recent
-- research downloads of sessions production also holds, 18 had the hash production already had.
-- With a kept copy, research reads ours (src/lib/legiscan/archive.ts writes it;
-- .planning/research/legiscan-cache/fetch.py reads it first).
--
-- WHAT THIS ADDS. Bucket `legiscan-datasets`: private, ZIP only, 500 MB per object (the project-wide
-- upload limit still applies on top; the US Congress dataset is ~63 MiB). Objects are
-- <ST>/<session_id>/<dataset_hash>.zip. No policies on storage.objects for this bucket, so only the
-- service role (the jobs, and research using the service key) can read or write it. Never public:
-- LegiScan data is CC BY 4.0, but the ZIPs are a working copy, not something we publish.
--
-- Creates only; overwrites no value.
--
-- STATUS: APPLIED to prod 2026-11-13 via apply-migration-file.mjs (operator approval: Chris Andrews, "Yes, apply it").
--   Dry run OK before, plus a tamper control (public = true fails the gate). Verified after with a control object
--   (ZZ/0/control.zip, then deleted): the service key uploads, lists and reads it; the publishable key lists
--   nothing and its read is refused.
--
-- ROLLBACK (empty the bucket first in the dashboard, or delete its storage.objects rows):
--   delete from storage.buckets where id = 'legiscan-datasets';

begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('legiscan-datasets', 'legiscan-datasets', false, 524288000, array['application/zip'])
on conflict (id) do nothing;

do $$
declare b record;
begin
  select public, file_size_limit, allowed_mime_types into b from storage.buckets where id = 'legiscan-datasets';
  if not found then raise exception 'CA_0382: bucket legiscan-datasets missing'; end if;
  if b.public then raise exception 'CA_0382: bucket legiscan-datasets is PUBLIC; it must be private'; end if;
  if b.allowed_mime_types is distinct from array['application/zip'] then
    raise exception 'CA_0382: unexpected allowed_mime_types %', b.allowed_mime_types;
  end if;
  -- No policy may open this bucket to anon or authenticated users.
  if exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and (coalesce(qual, '') || coalesce(with_check, '')) like '%legiscan-datasets%'
  ) then
    raise exception 'CA_0382: a storage.objects policy mentions legiscan-datasets; the bucket must stay service-role only';
  end if;
end $$;

commit;
