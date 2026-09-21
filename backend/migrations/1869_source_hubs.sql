-- Slice 2B: per-race-resolvable comparable-source hub registry + seed.
-- Spec: on-the-record/.claude/skills/superpowers/sdd/... (Slice 2B hub registry, held/gated).
-- A later task (Slice 2B Task 4) resolves applicable hubs per race and inserts discovered rows
-- with discovered_via='hub' -- see part B below for the required CHECK extension that unblocks it.

-- A. Registry table.
create table if not exists essentials.source_hubs (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  scope          text not null check (scope in ('global','state','local_type')),
  state          char(2),
  kind           text not null,
  poll_method    text not null check (poll_method in ('feed','scoped_search')),
  domain         text,
  query_template text,
  tos_bucket     text,
  active         boolean not null default true,
  added_via      text not null default 'manual' check (added_via in ('seed','flywheel','manual')),
  notes          text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- UPPERCASE-state invariant, matching the source_outlets convention (1552).
alter table essentials.source_hubs
  drop constraint if exists source_hubs_state_upper;
alter table essentials.source_hubs
  add constraint source_hubs_state_upper
  check (state is null or state = upper(state));

comment on column essentials.source_hubs.state is
  'Two-letter US state, UPPERCASE (e.g. ''TX''); NULL for global/local_type scope.';
comment on table essentials.source_hubs is
  'Slice 2B: registry of comparable-source hubs (debate/forum/questionnaire/guide/pamphlet) '
  'resolved per race by the hub lane. poll_method=feed hubs are also expected in '
  'essentials.source_outlets once a real feed URL is known (see part D below).';

-- B. REQUIRED -- extend discovered_sources.discovered_via to accept 'hub'.
-- Slice 2B's engine lane inserts discovered_sources rows with discovered_via='hub'; the existing
-- inline CHECK from 1551 only allows ('watchlist','search','agent'). Drop + re-add is idempotent;
-- if the drop is a no-op on some environment because the constraint name differs, the add below
-- still establishes the canonical name.
alter table essentials.discovered_sources
  drop constraint if exists discovered_sources_discovered_via_check;
alter table essentials.discovered_sources
  add constraint discovered_sources_discovered_via_check
  check (discovered_via in ('watchlist','search','agent','hub'));

comment on constraint discovered_sources_discovered_via_check on essentials.discovered_sources is
  'Slice 2B: hub lane inserts discovered_via=''hub''.';

-- C. Seed rows (idempotent per-name guard so re-running this file does not duplicate rows).

-- GLOBAL (scope='global', state=NULL).
insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via, notes)
select 'Ballotpedia', 'global', null, 'questionnaire', 'scoped_search', 'ballotpedia.org', 'ballotpedia', 'seed',
  'Candidate Connection; resolve per candidate (ballotpedia.org/<Candidate Name>)'
where not exists (select 1 from essentials.source_hubs where name = 'Ballotpedia' and scope = 'global');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via, notes)
select 'VOTE411', 'global', null, 'questionnaire', 'scoped_search', 'vote411.org', 'vote411-lwv', 'seed',
  'pointer-only -- LWV permission required; do NOT scrape (403). Record existence only.'
where not exists (select 1 from essentials.source_hubs where name = 'VOTE411' and scope = 'global');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via, notes)
select 'Vote Smart', 'global', null, 'questionnaire', 'scoped_search', 'votesmart.org', 'other', 'seed',
  'Political Courage Test'
where not exists (select 1 from essentials.source_hubs where name = 'Vote Smart' and scope = 'global');

-- PER-STATE (scope='state', state='XX' UPPERCASE).
insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'Arizona Citizens Clean Elections', 'state', 'AZ', 'debate', 'feed', null, 'govt', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Arizona Citizens Clean Elections' and scope = 'state' and state = 'AZ');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'Arizona PBS', 'state', 'AZ', 'forum', 'feed', null, 'public-media', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Arizona PBS' and scope = 'state' and state = 'AZ');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'KJZZ', 'state', 'AZ', 'forum', 'feed', null, 'public-media', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'KJZZ' and scope = 'state' and state = 'AZ');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'Oregon Voters'' Pamphlet', 'state', 'OR', 'pamphlet', 'scoped_search', 'oregonvotes.gov', 'govt', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Oregon Voters'' Pamphlet' and scope = 'state' and state = 'OR');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'OPB', 'state', 'OR', 'forum', 'feed', null, 'public-media', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'OPB' and scope = 'state' and state = 'OR');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'LAist', 'state', 'CA', 'forum', 'feed', null, 'public-media', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'LAist' and scope = 'state' and state = 'CA');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'Voter''s Edge California', 'state', 'CA', 'guide', 'scoped_search', 'votersedge.org', 'other', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Voter''s Edge California' and scope = 'state' and state = 'CA');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'Community Impact', 'state', 'TX', 'guide', 'feed', null, 'newspaper-or-tv-chain', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Community Impact' and scope = 'state' and state = 'TX');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'Utah Debate Commission', 'state', 'UT', 'debate', 'scoped_search', 'utahdebatecommission.org', 'other', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Utah Debate Commission' and scope = 'state' and state = 'UT');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, tos_bucket, added_via)
select 'KUER', 'state', 'UT', 'forum', 'feed', null, 'public-media', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'KUER' and scope = 'state' and state = 'UT');

-- LOCAL_TYPES (scope='local_type', state=NULL, poll_method='scoped_search',
-- query_template carries <locality> and <year> placeholders; domain NULL).
insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, query_template, tos_bucket, added_via)
select 'Local LWV candidate forum', 'local_type', null, 'forum', 'scoped_search', null,
  '"<locality>" League of Women Voters candidate forum <year>', 'vote411-lwv', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Local LWV candidate forum' and scope = 'local_type');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, query_template, tos_bucket, added_via)
select 'Local newspaper voter guide', 'local_type', null, 'guide', 'scoped_search', null,
  '"<locality>" newspaper voter guide candidates <year>', 'newspaper-or-tv-chain', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Local newspaper voter guide' and scope = 'local_type');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, query_template, tos_bucket, added_via)
select 'Local chamber candidate forum', 'local_type', null, 'forum', 'scoped_search', null,
  '"<locality>" chamber of commerce candidate forum <year>', 'other', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Local chamber candidate forum' and scope = 'local_type');

insert into essentials.source_hubs (name, scope, state, kind, poll_method, domain, query_template, tos_bucket, added_via)
select 'Government sample ballot / voter pamphlet', 'local_type', null, 'pamphlet', 'scoped_search', null,
  '"<locality>" sample ballot voter pamphlet <year>', 'govt', 'seed'
where not exists (select 1 from essentials.source_hubs where name = 'Government sample ballot / voter pamphlet' and scope = 'local_type');

-- D. feed-method hubs and essentials.source_outlets:
-- essentials.source_outlets.feed_url is NOT NULL UNIQUE, and no verified, canonical feed URL is
-- available here for the poll_method='feed' hubs seeded above (Arizona Citizens Clean Elections,
-- Arizona PBS, KJZZ, OPB, LAist, Community Impact, KUER). Fabricating a feed_url would make Slice-1
-- poll garbage, so this migration intentionally adds ZERO essentials.source_outlets rows. Those
-- outlets stay registered here (source_hubs, poll_method='feed') only; wiring their real feed_url
-- into source_outlets is a follow-up (the flywheel, or a human supplying a verified URL).

-- E. Post-verify gate.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'essentials' AND table_name = 'source_hubs'
  ) THEN
    RAISE EXCEPTION 'essentials.source_hubs missing after migration';
  END IF;

  IF (SELECT count(*) FROM essentials.source_hubs WHERE added_via = 'seed') < 1 THEN
    RAISE EXCEPTION 'essentials.source_hubs has no seeded rows after migration';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c
    JOIN pg_namespace n ON n.oid = c.connamespace
    WHERE n.nspname = 'essentials'
      AND c.conname = 'discovered_sources_discovered_via_check'
      AND pg_get_constraintdef(c.oid) LIKE '%''hub''%'
  ) THEN
    RAISE EXCEPTION 'discovered_sources_discovered_via_check does not permit ''hub'' after migration';
  END IF;
END $$;
