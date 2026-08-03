-- Source discovery v2, slice 0: run records (unattended-operation evidence)
-- + slice 1: 'web_rss' outlet kind (TV-station / news-site feeds).
-- Spec: on-the-record/docs/superpowers/specs/2026-08-03-source-discovery-v2-design.md
-- Column is trigger_kind, not trigger: TRIGGER is a Postgres keyword.
-- Named source_discovery_runs: essentials.discovery_runs already exists (migration 070, candidate-discovery run log).

create table if not exists essentials.source_discovery_runs (
  id uuid primary key default gen_random_uuid(),
  started_at timestamptz not null default now(),
  finished_at timestamptz,          -- null on a crashed run: itself a signal
  trigger_kind text not null check (trigger_kind in ('scheduled','manual','race')),
  items_examined integer not null default 0,
  classified integer not null default 0,
  inserted_pending integer not null default 0,
  inserted_auto_filtered integer not null default 0,
  spend_capped integer not null default 0,
  failure_count integer not null default 0,
  failures text                      -- newline-joined summaries, truncated
);

create index if not exists source_discovery_runs_started_idx
  on essentials.source_discovery_runs (started_at desc);

alter table essentials.source_outlets
  drop constraint if exists source_outlets_kind_check;
alter table essentials.source_outlets
  add constraint source_outlets_kind_check
  check (kind in ('youtube_channel','podcast_rss','web_page','web_rss'));
