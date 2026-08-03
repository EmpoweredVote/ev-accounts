-- Source discovery: outlet registry + discovered-items triage queue + sweep state.
-- Spec: on-the-record/docs/superpowers/specs/2026-08-02-source-discovery-design.md

create table if not exists essentials.source_outlets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null check (kind in ('youtube_channel','podcast_rss','web_page')),
  feed_url text not null unique,
  external_channel_id text,
  state char(2),
  chamber_id uuid references essentials.chambers(id) on delete set null,
  added_via text not null default 'manual' check (added_via in ('seed','flywheel','manual')),
  active boolean not null default true,
  last_polled_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists essentials.discovered_sources (
  id uuid primary key default gen_random_uuid(),
  source_key text not null unique,
  url text not null,
  title text,
  description_snippet text,
  channel_name text,
  channel_id text,
  channel_url text,
  outlet_id uuid references essentials.source_outlets(id) on delete set null,
  duration_seconds integer,
  published_at timestamptz,
  matched_politician_ids uuid[] not null default '{}',
  race_id uuid references essentials.races(id) on delete set null,
  chamber_id uuid references essentials.chambers(id) on delete set null,
  event_kind_guess text,
  source_tier_guess smallint,
  route text not null default 'ingest' check (route in ('ingest','quote_source')),
  confidence real,
  why text,
  discovered_via text not null check (discovered_via in ('watchlist','search','agent')),
  status text not null default 'pending'
    check (status in ('pending','auto_filtered','approved','rejected','ingested','superseded')),
  status_reason text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint rejected_needs_reason check (status <> 'rejected' or status_reason is not null)
);

create index if not exists discovered_sources_triage_idx
  on essentials.discovered_sources (status, race_id);
create index if not exists discovered_sources_created_idx
  on essentials.discovered_sources (created_at desc);

create table if not exists essentials.discovery_race_state (
  race_id uuid primary key references essentials.races(id) on delete cascade,
  last_swept_at timestamptz,
  last_alarm_at timestamptz
);
