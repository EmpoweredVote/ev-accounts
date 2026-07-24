-- =============================================================================
-- Migration 1407: Personal emails A — Frisco (Places 1,2,3,5,6 only — Place 4
-- OMITTED, see below), Princeton, Prosper, Allen, Fairview, Celina
-- (Phase 220 Plan 04 — Contact Data Backfill, Wave 2)
--
-- Seeds published PERSONAL email addresses (D-02) for the first batch of
-- personal-email cities, transcribed verbatim from 220-RESEARCH.md's Per-City
-- Sourcing Table. Unlike migration 1406's seat/role aliases (which attach
-- safely to the OFFICE regardless of incumbent), these are PERSONAL addresses
-- that must attach to the CORRECT CURRENT officeholder — so every row below
-- matches on BOTH (geo_id, office title) AND the officeholder's full_name
-- (p.full_name = v.full_name), not title alone. If the politician currently
-- seated in essentials.politicians doesn't match the RESEARCH-sourced name,
-- the row matches zero rows and is SKIPPED — never misattributed to the wrong
-- person (D-05, threat register T-220-01 / T-220-07).
--
-- FRISCO PLACE 4 — OMITTED FROM THIS MIGRATION (per 220-PREFLIGHT.md).
-- Migration 1409 (applied 2026-07-24, ahead of this migration) already
-- corrected Frisco Place 4's seating (Jared Elad, reversing mig 1404's
-- Ponangi error) and seeded his sourced email jelad@friscotexas.gov. This
-- migration's VALUES list below contains NO Frisco Place 4 row at all —
-- structurally impossible for this migration to touch that office. This
-- migration seeds Frisco's other 6 seats only (Mayor + Places 1,2,3,5,6).
--
-- KNOWN NAME-MISMATCH SKIPS (documented, not fabricated — see 220-04-SUMMARY.md).
-- This authoring session has no Supabase MCP / DB access, but the migration
-- history shows these 5 seats' May-2026-election results were recorded as
-- name-only essentials.race_candidates rows (migrations 100/1389/1390)
-- WITHOUT a corresponding seating-correction migration re-pointing
-- offices.politician_id — so the pre-existing (stale) officeholder is very
-- likely still the seated politician_id as of this writing. The full_name
-- guard below means these 5 rows will legitimately match zero rows and be
-- skipped rather than misattributed, mirroring the Frisco-Place-4 Pitfall-3
-- pattern but out of scope for this data-only contact migration to fix
-- (reseating requires its own sourced/certified migration, same idiom as mig
-- 1409):
--   - Frisco Mayor:      DB likely still Jeff Cheney (term nominally expired
--     2026-05-01); RESEARCH sources current Mayor as Mark Hill
--     (mhill@friscotexas.gov) — row will skip if so.
--   - Frisco Place 6:    DB likely still Brian Livingston (term nominally
--     expired 2026-05-01); RESEARCH sources Brittany Colberg
--     (bcolberg@friscotexas.gov) — row will skip if so.
--   - Celina Place 4:    DB likely still Wendie Wigginton (flagged "not
--     running" in migration 096); RESEARCH sources Shea B. Scott
--     (sbscott@celina-tx.gov) — row will skip if so.
--   - Celina Place 5:    DB likely still Mindy Koehne (flagged "not running"
--     in migration 096); RESEARCH sources Shane R. Lambert
--     (rlambert@celina-tx.gov) — row will skip if so.
--   - Prosper Place 5:   DB likely still Jeff Hodges; RESEARCH sources Doug
--     Charles (dcharles@prospertx.gov, sworn in 2026-05-12 per migration 096's
--     own header note) — row will skip if so.
-- The apply-script's gates report actual vs. expected coverage distinguishing
-- these 5 known-possible skips from the rest; a skip here is expected and
-- should NOT be treated as a migration bug.
--
-- SEEDED (verbatim, transcribed from 220-RESEARCH.md §"Per-City Sourcing
-- Table", Groups 1 and 2):
--   Frisco (4827684) — 6 of 7 seats (Place 4 omitted, see above):
--     Mayor                        Mark Hill            mhill@friscotexas.gov
--     Council Member Place 1       Ann Anderson         aanderson@friscotexas.gov
--     Council Member Place 2       Burt Thakur          bthakur@friscotexas.gov
--     Council Member Place 3       Angelia Pelham       apelham@friscotexas.gov
--     Council Member Place 5       Laura Rummel         lrummel@friscotexas.gov
--     Council Member Place 6       Brittany Colberg     bcolberg@friscotexas.gov
--   Princeton (4859576) — all 8 seats, domain is princetontx.US (NOT .gov):
--     Mayor                        Eugene Escobar Jr.   eescobar@princetontx.us
--     Council Member Place 1       Terrance Johnson     tjohnson@princetontx.us
--     Council Member Place 2       Cristina Todd        ctodd@princetontx.us
--     Council Member Place 3       Bryan Washington     BWashington@princetontx.us
--     Council Member Place 4       Jaisen Rutledge      jrutledge@princetontx.us
--     Council Member Place 5       Steven Deffibaugh    SDeffibaugh@princetontx.us
--     Council Member Place 6       Ben Long             blong@princetontx.us
--     Council Member Place 7       Carolyn David-Graves cgraves@princetontx.us
--   Prosper (4859696) — all 7 seats (Place 2/3 exceptions preserved verbatim):
--     Mayor                        David F. Bristol     dbristol@prospertx.gov
--     Council Member Place 1       Marcus E. Ray        mray@prospertx.gov
--     Council Member Place 2       Craig Andres         craig_andres@prospertx.gov
--     Council Member Place 3       Amy Bartley          Abartley@prospertx.gov
--     Council Member Place 4       Chris Kern           ckern@prospertx.gov
--     Council Member Place 5       Doug Charles         dcharles@prospertx.gov  [see NOTE — stale seat, will skip]
--     Council Member Place 6       Cameron Reeves       creeves@prospertx.gov
--   Allen (4801924) — all 7 seats, domain is allentx.gov (NOT cityofallen.org):
--     Mayor                        Chris Schulmeister   cschulmeister@allentx.gov
--     Council Member Place 1       Michael Schaeffer    michael.schaeffer@allentx.gov
--     Council Member Place 2       Tommy Baril          tommy.baril@allentx.gov
--     Council Member Place 3       Ken Cook             ken.cook@allentx.gov
--     Council Member Place 4       Amy Gnadt            amy.gnadt@allentx.gov
--     Council Member Place 5       Carl Clemencich      carl.clemencich@allentx.gov
--     Council Member Place 6       Ben Trahan           ben.trahan@allentx.gov
--   Fairview (4825224) — all 7 seats, domain is FairviewTexas.org, 'Seat' not 'Place':
--     Mayor                        John Hubbard         Mayor@FairviewTexas.org
--     Council Member Seat 1        Rich Connelly        RConnelly@FairviewTexas.org
--     Council Member Seat 2        Joe Boggs            JBoggs@FairviewTexas.org
--     Council Member Seat 3        Jill Hawkins         JHawkins@FairviewTexas.org
--     Council Member Seat 4        John Stanley         JStanley@FairviewTexas.org  [already seeded by mig 1390 — idempotent no-op here]
--     Council Member Seat 5        Pat Sheehan          PSheehan@FairviewTexas.org
--     Council Member Seat 6        Lakia Works          LWorks@FairviewTexas.org
--   Celina (4813684) — 5 of 7 seats currently matchable (Places 4/5 stale, see
--   above), domain is celina-tx.gov (HYPHEN):
--     Mayor                        Ryan Tubbs           rtubbs@celina-tx.gov
--     Council Member Place 1       Philip Ferguson      pferguson@celina-tx.gov
--     Council Member Place 2       Eddie Cawlfield      ecawlfield@celina-tx.gov
--     Council Member Place 3       Andy Hopkins         ahopkins@celina-tx.gov
--     Council Member Place 4       Shea B. Scott        sbscott@celina-tx.gov   [see NOTE — stale seat, will skip]
--     Council Member Place 5       Shane R. Lambert     rlambert@celina-tx.gov  [see NOTE — stale seat, will skip]
--     Council Member Place 6       Brandon Grumbles     bgrumbles@celina-tx.gov
--
-- D-02 guard: every address above is a personal mailbox, never a generic
-- catch-all (info@ / council@ / cityhall@ / contact@).
--
-- Idempotent (D-07): each row is appended to
-- essentials.politicians.email_addresses ONLY IF (a) the office's title
-- matches, (b) the CURRENTLY ACTIVE politician's full_name matches the
-- RESEARCH-sourced name exactly, and (c) the email isn't already present
-- (array_append + NOT @> guard, NULL array coalesced to empty first).
-- Re-running this migration is net-zero. Only email_addresses is touched —
-- no party, no other column.
--
-- Sources: 220-RESEARCH.md §"Per-City Sourcing Table" Group 1 (Frisco,
-- Princeton, Prosper) and Group 2 (Allen, Fairview, Celina) rows — each
-- cross-checked against the exact page(s) cited there
-- (friscotexas.gov/directory.aspx?did=38, princetontx.gov individual bio
-- pages, prospertx.gov/directory.aspx?did=20, cityofallen.org/917/... resolving
-- to allentx.gov, fairviewtexas.org/government/mayor-town-council/,
-- celina-tx.gov/Directory.aspx?did=4).
-- =============================================================================

BEGIN;

UPDATE essentials.politicians p
SET email_addresses = array_append(COALESCE(p.email_addresses, ARRAY[]::text[]), v.email)
FROM (VALUES
  -- Frisco (4827684) — Place 4 OMITTED (see header; handled by mig 1409)
  ('4827684', 'Mayor',                  'Mark Hill',              'mhill@friscotexas.gov'),
  ('4827684', 'Council Member Place 1', 'Ann Anderson',           'aanderson@friscotexas.gov'),
  ('4827684', 'Council Member Place 2', 'Burt Thakur',            'bthakur@friscotexas.gov'),
  ('4827684', 'Council Member Place 3', 'Angelia Pelham',         'apelham@friscotexas.gov'),
  ('4827684', 'Council Member Place 5', 'Laura Rummel',           'lrummel@friscotexas.gov'),
  ('4827684', 'Council Member Place 6', 'Brittany Colberg',       'bcolberg@friscotexas.gov'),
  -- Princeton (4859576) — 8 seats, .us domain
  ('4859576', 'Mayor',                  'Eugene Escobar Jr.',     'eescobar@princetontx.us'),
  ('4859576', 'Council Member Place 1', 'Terrance Johnson',       'tjohnson@princetontx.us'),
  ('4859576', 'Council Member Place 2', 'Cristina Todd',          'ctodd@princetontx.us'),
  ('4859576', 'Council Member Place 3', 'Bryan Washington',       'BWashington@princetontx.us'),
  ('4859576', 'Council Member Place 4', 'Jaisen Rutledge',        'jrutledge@princetontx.us'),
  ('4859576', 'Council Member Place 5', 'Steven Deffibaugh',      'SDeffibaugh@princetontx.us'),
  ('4859576', 'Council Member Place 6', 'Ben Long',               'blong@princetontx.us'),
  ('4859576', 'Council Member Place 7', 'Carolyn David-Graves',   'cgraves@princetontx.us'),
  -- Prosper (4859696) — 7 seats
  ('4859696', 'Mayor',                  'David F. Bristol',       'dbristol@prospertx.gov'),
  ('4859696', 'Council Member Place 1', 'Marcus E. Ray',          'mray@prospertx.gov'),
  ('4859696', 'Council Member Place 2', 'Craig Andres',           'craig_andres@prospertx.gov'),
  ('4859696', 'Council Member Place 3', 'Amy Bartley',            'Abartley@prospertx.gov'),
  ('4859696', 'Council Member Place 4', 'Chris Kern',             'ckern@prospertx.gov'),
  ('4859696', 'Council Member Place 5', 'Doug Charles',           'dcharles@prospertx.gov'),
  ('4859696', 'Council Member Place 6', 'Cameron Reeves',         'creeves@prospertx.gov'),
  -- Allen (4801924) — 7 seats, allentx.gov domain
  ('4801924', 'Mayor',                  'Chris Schulmeister',     'cschulmeister@allentx.gov'),
  ('4801924', 'Council Member Place 1', 'Michael Schaeffer',      'michael.schaeffer@allentx.gov'),
  ('4801924', 'Council Member Place 2', 'Tommy Baril',            'tommy.baril@allentx.gov'),
  ('4801924', 'Council Member Place 3', 'Ken Cook',               'ken.cook@allentx.gov'),
  ('4801924', 'Council Member Place 4', 'Amy Gnadt',              'amy.gnadt@allentx.gov'),
  ('4801924', 'Council Member Place 5', 'Carl Clemencich',        'carl.clemencich@allentx.gov'),
  ('4801924', 'Council Member Place 6', 'Ben Trahan',             'ben.trahan@allentx.gov'),
  -- Fairview (4825224) — 7 seats, FairviewTexas.org domain, 'Seat' not 'Place'
  ('4825224', 'Mayor',                  'John Hubbard',           'Mayor@FairviewTexas.org'),
  ('4825224', 'Council Member Seat 1',  'Rich Connelly',          'RConnelly@FairviewTexas.org'),
  ('4825224', 'Council Member Seat 2',  'Joe Boggs',              'JBoggs@FairviewTexas.org'),
  ('4825224', 'Council Member Seat 3',  'Jill Hawkins',           'JHawkins@FairviewTexas.org'),
  ('4825224', 'Council Member Seat 4',  'John Stanley',           'JStanley@FairviewTexas.org'),
  ('4825224', 'Council Member Seat 5',  'Pat Sheehan',            'PSheehan@FairviewTexas.org'),
  ('4825224', 'Council Member Seat 6',  'Lakia Works',            'LWorks@FairviewTexas.org'),
  -- Celina (4813684) — 7 seats, celina-tx.gov (HYPHEN) domain
  ('4813684', 'Mayor',                  'Ryan Tubbs',             'rtubbs@celina-tx.gov'),
  ('4813684', 'Council Member Place 1', 'Philip Ferguson',        'pferguson@celina-tx.gov'),
  ('4813684', 'Council Member Place 2', 'Eddie Cawlfield',        'ecawlfield@celina-tx.gov'),
  ('4813684', 'Council Member Place 3', 'Andy Hopkins',           'ahopkins@celina-tx.gov'),
  ('4813684', 'Council Member Place 4', 'Shea B. Scott',          'sbscott@celina-tx.gov'),
  ('4813684', 'Council Member Place 5', 'Shane R. Lambert',       'rlambert@celina-tx.gov'),
  ('4813684', 'Council Member Place 6', 'Brandon Grumbles',       'bgrumbles@celina-tx.gov')
) AS v(geo_id, title, full_name, email)
JOIN essentials.governments g ON g.geo_id = v.geo_id
JOIN essentials.chambers ch ON ch.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = ch.id AND o.title = v.title
WHERE p.id = o.politician_id
  AND p.is_active = true
  AND p.full_name = v.full_name
  AND NOT (COALESCE(p.email_addresses, ARRAY[]::text[]) @> ARRAY[v.email]::text[]);

COMMIT;
