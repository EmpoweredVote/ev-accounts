-- =============================================================================
-- Migration 1406: Seat/role-alias emails — Blue Ridge, Nevada, Melissa
-- (Phase 220 Plan 03 — Contact Data Backfill, Wave 2)
--
-- Seeds published seat/role-alias emails (D-02) for the three Collin-milestone
-- cities whose council publishes an alias attached to the OFFICE, not the
-- person — safe to seed regardless of any future incumbent change, unlike a
-- personal address. Reference model: McKinney's existing District#@ / mayor@
-- pattern (migration 093), already present and NOT re-seeded here.
--
-- SEEDED (verbatim, transcribed from 220-RESEARCH.md §Per-City Sourcing Table,
-- Group 3 rows):
--   Blue Ridge (4808872) — 6 seats:
--     Mayor Rhonda Williams          -> mayor@blueridgecity.com
--     Council Member Place 1 (Apple) -> council1@blueridgecity.com
--     Council Member Place 2 (Braly) -> council2@blueridgecity.com
--     Council Member Place 3 (Sissom)-> council3@blueridgecity.com
--     Council Member Place 4 (Mattingly) -> council4@blueridgecity.com
--     Council Member Place 5 (Chitwood) -> council5@blueridgecity.com
--   Nevada (4850760) — 6 seats:
--     Mayor Donald Deering            -> mayor@cityofnevadatx.org
--     Council Member Place 1 (Laye)   -> councilman1@cityofnevadatx.org
--     Council Member Place 2 (Baker)  -> councilman2@cityofnevadatx.org
--     Council Member Place 3 (Wilson) -> councilman3@cityofnevadatx.org
--     Council Member Place 4 (Laughter) -> councilman4@cityofnevadatx.org
--     Council Member Place 5 (Little) -> councilman5@cityofnevadatx.org
--   Melissa (4847496) — 7 seats:
--     Mayor Jay Northcut               -> mayor@cityofmelissa.com
--     Council Member Place 1 (Taylor)  -> place1@cityofmelissa.com
--     Council Member Place 2 (Hendrickson) -> place2@cityofmelissa.com
--     Council Member Place 3 (Conklin) -> place3@cityofmelissa.com
--     Council Member Place 4 (Armstrong) -> place4@cityofmelissa.com
--     Council Member Place 5 (Ackerman) -> cackerman@cityofmelissa.com
--       (PERSONAL address — breaks the placeN@ shape; seeded verbatim as
--       RESEARCH gives it, not a fabricated placeN@ substitute)
--     Council Member Place 6 (Lehr)    -> place6@cityofmelissa.com
--
-- NOT SEEDED: McKinney (4845744) — its District#@/mayor@ aliases are already
-- present (baseline, migration 093); referenced above as the pattern model
-- only, not re-applied.
--
-- D-02 guard: no generic city-wide catch-all (info@ / council@ (bare) /
-- cityhall@ / contact@) is ever seeded here — every alias above is either
-- seat-numbered (councilN@ / councilmanN@ / placeN@) or role-scoped (mayor@),
-- or (Melissa Place 5) a confirmed personal address.
--
-- Idempotent (D-07): each seat's alias is appended to
-- essentials.politicians.email_addresses ONLY IF not already present
-- (array_append + a NOT (... @> ARRAY[...]) guard, NULL array coalesced to
-- empty first). Re-running this migration is net-zero. Only email_addresses
-- is touched — no party, no other column.
--
-- Sources: 220-RESEARCH.md §"Per-City Sourcing Table" Group 3 rows —
-- blueridgecity.com/council, cityofnevadatx.org/government/city_council.php,
-- cityofmelissa.com/202/City-Council (each cross-checked against
-- cityofnevadatx.org/contact_us/index.php / blueridgecity.com/contact-us /
-- cityofmelissa.com FormCenter for the corresponding web_form_url, seeded
-- separately by migration 1405).
-- =============================================================================

BEGIN;

UPDATE essentials.politicians p
SET email_addresses = array_append(COALESCE(p.email_addresses, ARRAY[]::text[]), v.email)
FROM (VALUES
  -- Blue Ridge (4808872)
  ('4808872', 'Mayor',                    'mayor@blueridgecity.com'),
  ('4808872', 'Council Member Place 1',   'council1@blueridgecity.com'),
  ('4808872', 'Council Member Place 2',   'council2@blueridgecity.com'),
  ('4808872', 'Council Member Place 3',   'council3@blueridgecity.com'),
  ('4808872', 'Council Member Place 4',   'council4@blueridgecity.com'),
  ('4808872', 'Council Member Place 5',   'council5@blueridgecity.com'),
  -- Nevada (4850760)
  ('4850760', 'Mayor',                    'mayor@cityofnevadatx.org'),
  ('4850760', 'Council Member Place 1',   'councilman1@cityofnevadatx.org'),
  ('4850760', 'Council Member Place 2',   'councilman2@cityofnevadatx.org'),
  ('4850760', 'Council Member Place 3',   'councilman3@cityofnevadatx.org'),
  ('4850760', 'Council Member Place 4',   'councilman4@cityofnevadatx.org'),
  ('4850760', 'Council Member Place 5',   'councilman5@cityofnevadatx.org'),
  -- Melissa (4847496)
  ('4847496', 'Mayor',                    'mayor@cityofmelissa.com'),
  ('4847496', 'Council Member Place 1',   'place1@cityofmelissa.com'),
  ('4847496', 'Council Member Place 2',   'place2@cityofmelissa.com'),
  ('4847496', 'Council Member Place 3',   'place3@cityofmelissa.com'),
  ('4847496', 'Council Member Place 4',   'place4@cityofmelissa.com'),
  ('4847496', 'Council Member Place 5',   'cackerman@cityofmelissa.com'),
  ('4847496', 'Council Member Place 6',   'place6@cityofmelissa.com')
) AS v(geo_id, title, email)
JOIN essentials.governments g ON g.geo_id = v.geo_id
JOIN essentials.chambers ch ON ch.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = ch.id AND o.title = v.title
WHERE p.id = o.politician_id
  AND p.is_active = true
  AND NOT (COALESCE(p.email_addresses, ARRAY[]::text[]) @> ARRAY[v.email]::text[]);

COMMIT;
