-- Fast-follows from review of 1532: state casing invariant + outlet poll index.
-- essentials.source_outlets.state follows the UPPERCASE convention
-- (like discovery_jurisdictions.state; NOT like essentials.districts.state).

alter table essentials.source_outlets
  add constraint source_outlets_state_upper
  check (state is null or state = upper(state));

comment on column essentials.source_outlets.state is
  'Two-letter US state, UPPERCASE (e.g. ''TX'').';

create index if not exists source_outlets_active_idx
  on essentials.source_outlets (last_polled_at)
  where active;
