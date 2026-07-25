-- =============================================================================
-- Migration 1408: Personal emails B — Parker, Saint Paul, Weston, Lowry Crossing,
-- Lucas (Phase 220 Plan 05 — Contact Data Backfill, Wave 2)
--
-- Seeds published PERSONAL email addresses (D-02) for the second batch of
-- personal-email cities, transcribed verbatim from 220-RESEARCH.md's Per-City
-- Sourcing Table (Groups 2 and 3). Like sibling migration 1407, every row
-- matches on BOTH (geo_id, office title) AND the officeholder's full_name
-- (p.full_name = v.full_name) — never title alone — so a stale/mismatched DB
-- occupant safely no-ops instead of being misattributed (D-05, threat register
-- T-220-07).
--
-- KNOWN-POSSIBLE-SKIPS: NONE. Unlike 1407 (which found 5 rows where a May-2026
-- election reseating was recorded only as a name-only race_candidates row,
-- never repointing offices.politician_id), this authoring session
-- cross-checked every row below against the actual seating migrations already
-- applied for these 5 cities (090/097/098 initial seed, 1389/1390 Phase-219
-- reconcile) and found every RESEARCH-sourced full_name already matches the
-- currently-seated DB politician for that office. All 34 rows below are
-- expected to match on first apply (most are already-present no-ops; see
-- per-city notes).
--
-- PARKER (4855152) — "Place 3" AMBIGUITY RESOLVED. 220-RESEARCH.md flagged
-- Parker's Place 3 occupant as ambiguous (two fetches disagreed on page
-- ordering) and separately named a "Place 6 (Mayor Pro Tem) Buddy Pilgrim".
-- Cross-referencing migration 090 ("6 seats: Mayor + Place 1-5" — Parker has
-- NO Place 6 office at all) and migration 1389 ("Parker Council Member Place
-- 3 — Buddy Pilgrim (now Mayor Pro Tem)") resolves this: Buddy Pilgrim IS the
-- Place 3 occupant; RESEARCH's "Place 6" label was a mislabel carried from the
-- live page fetch, not a second office. The row below seeds
-- (Place 3, 'Buddy Pilgrim', bpilgrim@parkertexas.us) — matched on the DB's
-- own authoritative title+name pairing, not RESEARCH's ambiguous label, so a
-- wrong guess would safely no-op rather than corrupt data.
--
-- LOWRY CROSSING (4844308) — MIXED TLD PRESERVED EXACTLY. Ward 1-3 members use
-- lowrycrossingtexas.ORG; Ward 4 (Hijazen = Place 4, Simpson = Place 8) use
-- lowrycrossingtexas.COM. Migrations 098/1389 already seeded ALL 9 Lowry
-- Crossing seats with emails, but seeded Hijazen and Simpson with the WRONG
-- (.org) TLD at that time — this migration's Hijazen/Simpson rows use the
-- RESEARCH-confirmed .com address and will be APPENDED alongside the
-- pre-existing .org entry (this migration only appends per D-07; it does not
-- delete the earlier .org entry — that cleanup is out of this data-only
-- migration's scope, tracked as a deferred item in 220-05-SUMMARY.md). Only
-- Agur Rios (Place 6) previously had a NULL email and gets one seeded fresh.
--
-- SAINT PAUL (4864220) — CURRENT ROSTER CONFIRMED. Migrations 098/1390 already
-- reflect the CURRENT Seat 3/4 occupants (Greg Pierson, Kristen Bewley), not
-- the stale cached-search snapshot (Justin Graham, J.T. Trevino-as-alderman)
-- that RESEARCH's Pitfall/roster-reshuffle note warned about — full_name
-- matching on the DB's actual stored names (not the stale snapshot names)
-- means this migration is inherently safe here.
--
-- WESTON (4877740) — Mayor Pro Tem title ambiguity (Metzger vs. Roach) does
-- NOT affect email seeding (matched by full_name, not title/role label).
--
-- CASE-INSENSITIVE IDEMPOTENCY GUARD: this migration's "already present"
-- check uses lower()-normalized comparison (rather than 1407's exact-string
-- array containment) because several already-seeded DB addresses differ from
-- RESEARCH's transcribed casing only by letter case (e.g. DB has
-- 'jt.trevino@stpaultexas.us', RESEARCH transcribes 'JT.trevino@...';
-- DB has 'junderhill@lucastexas.us', RESEARCH transcribes 'JUnderhill@...').
-- Case-insensitive matching prevents seeding a redundant near-duplicate
-- casing variant of an address that is already functionally present, while
-- still being a true idempotency guard (re-running this migration adds zero
-- new rows either way).
--
-- SEEDED (verbatim local-part/domain, transcribed from 220-RESEARCH.md
-- §"Per-City Sourcing Table", Groups 2 and 3):
--   Parker (4855152) — all 6 seats, domain parkertexas.us:
--     Mayor                        Lee Pettle              lpettle@parkertexas.us
--     Council Member Place 1       Roxanne Bogdan          rbogdan@parkertexas.us
--     Council Member Place 2       Colleen Halbert         chalbert@parkertexas.us
--     Council Member Place 3       Buddy Pilgrim           bpilgrim@parkertexas.us  [ambiguity resolved, see above]
--     Council Member Place 4       Darrel Sharpe           dsharpe@parkertexas.us
--     Council Member Place 5       Billy Barron            bbarron@parkertexas.us
--     [publiccomments@parkertexas.us EXCLUDED — generic catch-all, D-02]
--   Saint Paul (4864220) — all 6 seats, domain stpaultexas.us:
--     Mayor                        J.T. Trevino            JT.trevino@stpaultexas.us
--     Council Member Place 1       Larry Nail              larry.nail@stpaultexas.us
--     Council Member Place 2       David Dryden            david.dryden@stpaultexas.us
--     Council Member Place 3       Greg Pierson            greg.pierson@stpaultexas.us
--     Council Member Place 4       Kristen Bewley          kristen.bewley@stpaultexas.us
--     Council Member Place 5       Robert Simmons          robert.simmons@stpaultexas.us
--   Weston (4877740) — all 6 seats, domain westontexas.com:
--     Mayor                        Matthew Marchiori       mmarchiori@westontexas.com
--     Council Member Place 1       Patti Harrington        pharrington@westontexas.com
--     Council Member Place 2       Brian M. Roach          broach@westontexas.com
--     Council Member Place 3       Jeff Metzger            jmetzger@westontexas.com
--     Council Member Place 4       Mike Hill               mhill@westontexas.com
--     Council Member Place 5       Marla Johnston          mjohnston@westontexas.com
--     [cityhall@westontexas.com / TownHall@westontexas.com EXCLUDED — generic catch-all, D-02]
--   Lowry Crossing (4844308) — all 9 seats (Mayor + 4 wards x 2), MIXED TLD:
--     Mayor                        Pat Kelly               pkelly@lowrycrossingtexas.org
--     Council Member Place 1       Scott Pitchure          spitchure@lowrycrossingtexas.org
--     Council Member Place 2       Tammy Hodges            thodges@lowrycrossingtexas.org
--     Council Member Place 3       Eusebio "Joe" Trujillo III  etrujillo@lowrycrossingtexas.org
--     Council Member Place 4       Muhanad "G" Hijazen     ghijazen@lowrycrossingtexas.COM
--     Council Member Place 5       Chris Madrid            cmadrid@lowrycrossingtexas.org
--     Council Member Place 6       Agur Rios               agur@lowrycrossingtexas.org
--     Council Member Place 7       Cindy Cash              ccash@lowrycrossingtexas.org
--     Council Member Place 8       Ollie Simpson           osimpson@lowrycrossingtexas.COM
--   Lucas (4845012) — all 7 seats, domain lucastexas.us:
--     Mayor                        Dusty Kuykendall        dkuykendall@lucastexas.us
--     Council Member Place 1       Jonathan Underhill      JUnderhill@lucastexas.us
--     Council Member Place 2       Rebecca Orr             rOrr@lucastexas.us
--     Council Member Place 3       Chris Bierman           cbierman@lucastexas.us
--     Council Member Place 4       Phil Lawrence           plawrence@lucastexas.us
--     Council Member Place 5       Debbie Fisher           dfisher@lucastexas.us
--     Council Member Place 6       Neil Peterson           npeterson@lucastexas.us
--
-- D-02 guard: every address above is a personal mailbox, never a generic
-- catch-all (info@ / council@ / cityhall@ / townhall@ / publiccomments@ /
-- contact@).
--
-- Idempotent (D-07): each row is appended to
-- essentials.politicians.email_addresses ONLY IF (a) the office's title
-- matches, (b) the CURRENTLY ACTIVE politician's full_name matches the
-- RESEARCH-sourced name exactly, and (c) no case-insensitive match of the
-- email already exists in the array. Re-running this migration is net-zero.
-- Only email_addresses is touched — no party, no other column.
--
-- Sources: 220-RESEARCH.md §"Per-City Sourcing Table" Group 2 (Parker, Saint
-- Paul, Weston) and Group 3 (Lowry Crossing, Lucas) rows — each cross-checked
-- against the exact page(s) cited there (parkertexas.us/76/City-Council,
-- stpaultexas.us/local_government/elected_officials/seats_1-5.php + mayor.php,
-- westontexas.com/page/Mayor_Aldermen, lowrycrossingtexas.org/operations/
-- city_council.php, lucastexas.us/164/City-Council) and against this
-- codebase's own prior seating migrations (090, 097, 098, 1389, 1390) for
-- office-title/full_name ground truth.
-- =============================================================================

BEGIN;

UPDATE essentials.politicians p
SET email_addresses = array_append(COALESCE(p.email_addresses, ARRAY[]::text[]), v.email)
FROM (VALUES
  -- Parker (4855152) — 6 seats
  ('4855152', 'Mayor',                  'Lee Pettle',                    'lpettle@parkertexas.us'),
  ('4855152', 'Council Member Place 1', 'Roxanne Bogdan',                'rbogdan@parkertexas.us'),
  ('4855152', 'Council Member Place 2', 'Colleen Halbert',               'chalbert@parkertexas.us'),
  ('4855152', 'Council Member Place 3', 'Buddy Pilgrim',                 'bpilgrim@parkertexas.us'),
  ('4855152', 'Council Member Place 4', 'Darrel Sharpe',                 'dsharpe@parkertexas.us'),
  ('4855152', 'Council Member Place 5', 'Billy Barron',                  'bbarron@parkertexas.us'),
  -- Saint Paul (4864220) — 6 seats
  ('4864220', 'Mayor',                  'J.T. Trevino',                  'JT.trevino@stpaultexas.us'),
  ('4864220', 'Council Member Place 1', 'Larry Nail',                    'larry.nail@stpaultexas.us'),
  ('4864220', 'Council Member Place 2', 'David Dryden',                  'david.dryden@stpaultexas.us'),
  ('4864220', 'Council Member Place 3', 'Greg Pierson',                  'greg.pierson@stpaultexas.us'),
  ('4864220', 'Council Member Place 4', 'Kristen Bewley',                'kristen.bewley@stpaultexas.us'),
  ('4864220', 'Council Member Place 5', 'Robert Simmons',                'robert.simmons@stpaultexas.us'),
  -- Weston (4877740) — 6 seats
  ('4877740', 'Mayor',                  'Matthew Marchiori',             'mmarchiori@westontexas.com'),
  ('4877740', 'Council Member Place 1', 'Patti Harrington',              'pharrington@westontexas.com'),
  ('4877740', 'Council Member Place 2', 'Brian M. Roach',                'broach@westontexas.com'),
  ('4877740', 'Council Member Place 3', 'Jeff Metzger',                  'jmetzger@westontexas.com'),
  ('4877740', 'Council Member Place 4', 'Mike Hill',                     'mhill@westontexas.com'),
  ('4877740', 'Council Member Place 5', 'Marla Johnston',                'mjohnston@westontexas.com'),
  -- Lowry Crossing (4844308) — 9 seats, MIXED TLD (Ward 4 = .com)
  ('4844308', 'Mayor',                  'Pat Kelly',                     'pkelly@lowrycrossingtexas.org'),
  ('4844308', 'Council Member Place 1', 'Scott Pitchure',                'spitchure@lowrycrossingtexas.org'),
  ('4844308', 'Council Member Place 2', 'Tammy Hodges',                  'thodges@lowrycrossingtexas.org'),
  ('4844308', 'Council Member Place 3', 'Eusebio "Joe" Trujillo III',    'etrujillo@lowrycrossingtexas.org'),
  ('4844308', 'Council Member Place 4', 'Muhanad "G" Hijazen',           'ghijazen@lowrycrossingtexas.com'),
  ('4844308', 'Council Member Place 5', 'Chris Madrid',                  'cmadrid@lowrycrossingtexas.org'),
  ('4844308', 'Council Member Place 6', 'Agur Rios',                     'agur@lowrycrossingtexas.org'),
  ('4844308', 'Council Member Place 7', 'Cindy Cash',                    'ccash@lowrycrossingtexas.org'),
  ('4844308', 'Council Member Place 8', 'Ollie Simpson',                 'osimpson@lowrycrossingtexas.com'),
  -- Lucas (4845012) — 7 seats
  ('4845012', 'Mayor',                  'Dusty Kuykendall',              'dkuykendall@lucastexas.us'),
  ('4845012', 'Council Member Place 1', 'Jonathan Underhill',            'JUnderhill@lucastexas.us'),
  ('4845012', 'Council Member Place 2', 'Rebecca Orr',                   'rOrr@lucastexas.us'),
  ('4845012', 'Council Member Place 3', 'Chris Bierman',                 'cbierman@lucastexas.us'),
  ('4845012', 'Council Member Place 4', 'Phil Lawrence',                 'plawrence@lucastexas.us'),
  ('4845012', 'Council Member Place 5', 'Debbie Fisher',                 'dfisher@lucastexas.us'),
  ('4845012', 'Council Member Place 6', 'Neil Peterson',                 'npeterson@lucastexas.us')
) AS v(geo_id, title, full_name, email)
JOIN essentials.governments g ON g.geo_id = v.geo_id
JOIN essentials.chambers ch ON ch.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = ch.id AND o.title = v.title
WHERE p.id = o.politician_id
  AND p.is_active = true
  AND p.full_name = v.full_name
  AND NOT EXISTS (
    SELECT 1 FROM unnest(COALESCE(p.email_addresses, ARRAY[]::text[])) AS existing(addr)
    WHERE lower(existing.addr) = lower(v.email)
  );

COMMIT;
