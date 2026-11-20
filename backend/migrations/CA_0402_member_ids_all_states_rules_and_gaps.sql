-- CA_0402_member_ids_all_states_rules_and_gaps.sql
-- Make room for every state's member ids, remove 8 wrong Open States ids, and list legislators with no member id.
--
-- Created 2026-11-19 with Chris Andrews. Steward slot CA_0402. Asked 2026-11-19: "lets get member ids for other
-- states and figure out a way we can make sure we get them when we update people". Follows CA_0401.
--
-- WHAT THIS CHANGES
-- 1. id_type CHECK (leg_id_map_id_type_chk): the national types stay listed; any state's own id is allowed as
--    '<two-letter state>-<name>' (mn-lrl, ga-member …), so a new state needs a loader, not a migration.
-- 2. Deletes 8 essentials.legislative_politician_id_map rows (source 'openstates-committees', match_method 'name',
--    written 2026-03-05). Each put a California SENATOR's Open States id on an ASSEMBLY member with a related name.
--    Shown by the seat match of 2026-11-19 (sync-member-ids.ts): data.openstates.org/people/current/ca.csv names
--    the person each id belongs to, at the Senate seat that person holds in our records. Deleted rows (id,
--    politician_id, holder, id_value, verified_at) — the id's true owner in brackets:
--      53ca23c0-a24c-4be1-aeb2-43435d1b0506  8566674a-3a3b-4c88-bba0-c9f42e4ff810  Alexandra M. Macedo  ocd-person/cb6cc457-59f8-4dd8-aeb5-691c3795ffb7  2026-03-05 19:19:24  [Lena Gonzalez]
--      5fd5f53e-0c95-4e02-a0ee-f013f5a8bc30  0649630c-bd6d-40fe-8f66-e026e6f6c83e  Catherine Stefani    ocd-person/cb0f6477-568f-49db-aba3-f88e7bccbefc  2026-03-05 19:01:31  [Susan Rubio]
--      fed532db-f933-41c5-aead-7a9fe067a755  21940b7c-2424-47e9-a649-077b0f827c2c  Gregg Hart           ocd-person/66bd4b32-5536-4bae-ab55-08c0b70ca5fd  2026-03-05 19:07:59  [Henry Stern]
--      a1396d94-3fca-4316-86e3-ac31839bbb15  5ad32852-789e-4013-995b-6f0aa6a5a5d4  Jeff Gonzalez        ocd-person/37f2dc9f-d788-4f71-b794-093c8816333b  2026-03-05 19:01:31  [Lola Smallwood-Cuevas]
--      8048d8cc-40a4-4a34-a1fe-9372b21ed842  6730d01a-e87e-4177-9a2b-876b9c494774  Liz Ortega           ocd-person/bd78b1b9-6d92-4c67-a1f4-0548575f3aa5  2026-03-05 18:58:02  [Laura Richardson]
--      69eead70-b889-4b9c-a02e-b3d830efe782  bd4dc076-4bdd-4e10-be2c-80d998b17c50  Patrick J. Ahrens    ocd-person/e725b91e-1f7f-4510-a9cc-0b9a39d283c3  2026-03-05 19:01:31  [Ben Allen]
--      04f781aa-7143-4659-8ef3-ef3bbb8c75ac  ed32efa5-b455-4323-a12f-5fe79bc4ffd6  Phillip Chen         ocd-person/a76028df-5730-47b0-b617-1565621def41  2026-03-05 19:04:35  [Bob Archuleta]
--      b1af3a2d-32e9-466b-a605-800b274591c9  8c61cd23-68fb-4f1c-8a3c-60da74c86a64  Steve Bennett        ocd-person/fb1c2c06-108c-41bf-9f08-44a9f8e0cb08  2026-03-05 19:25:46  [Suzette Valladares]
--    The correct rows are written afterwards by sync-member-ids.ts (seat match), not here.
--    NOT touched: 2 rows on duplicate person records (Tony Strickland b156be63…, Caroline Menjivar 27a358cd…, both
--    source 'cicero' with no office term) — the seated twin needs a merge, which moves the ids with it.
-- 3. New view essentials.legislator_member_id_gaps: every sitting state legislator with no trusted Open States id.
--    It is the check that a roster change got its ids: run sync-member-ids.ts until it holds only people the
--    script reports as problems.
--
-- LOCKS. Brief ACCESS EXCLUSIVE on a ~4.8k-row table; lock_timeout 3s.
--
-- ROLLBACK: drop view essentials.legislator_member_id_gaps; restore the CA_0401 CHECK (its list plus every
--   '<st>-…' type then present); re-insert the 8 rows above from this header only if they were somehow right.
--
-- STATUS: NOT APPLIED.

BEGIN;
set local lock_timeout = '3s';

ALTER TABLE essentials.legislative_politician_id_map
  DROP CONSTRAINT leg_id_map_id_type_chk,
  ADD CONSTRAINT leg_id_map_id_type_chk CHECK (
    id_type IN ('legiscan', 'bioguide', 'openstates', 'onboard', 'legistar')
    OR id_type ~ '^[a-z]{2}-[a-z]+(-[a-z]+)*$');

DO $$
DECLARE n int;
BEGIN
  DELETE FROM essentials.legislative_politician_id_map
   WHERE id_type = 'openstates' AND match_method = 'name' AND source = 'openstates-committees'
     AND (id, politician_id, id_value) IN (
       ('53ca23c0-a24c-4be1-aeb2-43435d1b0506'::uuid, '8566674a-3a3b-4c88-bba0-c9f42e4ff810'::uuid, 'ocd-person/cb6cc457-59f8-4dd8-aeb5-691c3795ffb7'),
       ('5fd5f53e-0c95-4e02-a0ee-f013f5a8bc30'::uuid, '0649630c-bd6d-40fe-8f66-e026e6f6c83e'::uuid, 'ocd-person/cb0f6477-568f-49db-aba3-f88e7bccbefc'),
       ('fed532db-f933-41c5-aead-7a9fe067a755'::uuid, '21940b7c-2424-47e9-a649-077b0f827c2c'::uuid, 'ocd-person/66bd4b32-5536-4bae-ab55-08c0b70ca5fd'),
       ('a1396d94-3fca-4316-86e3-ac31839bbb15'::uuid, '5ad32852-789e-4013-995b-6f0aa6a5a5d4'::uuid, 'ocd-person/37f2dc9f-d788-4f71-b794-093c8816333b'),
       ('8048d8cc-40a4-4a34-a1fe-9372b21ed842'::uuid, '6730d01a-e87e-4177-9a2b-876b9c494774'::uuid, 'ocd-person/bd78b1b9-6d92-4c67-a1f4-0548575f3aa5'),
       ('69eead70-b889-4b9c-a02e-b3d830efe782'::uuid, 'bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid, 'ocd-person/e725b91e-1f7f-4510-a9cc-0b9a39d283c3'),
       ('04f781aa-7143-4659-8ef3-ef3bbb8c75ac'::uuid, 'ed32efa5-b455-4323-a12f-5fe79bc4ffd6'::uuid, 'ocd-person/a76028df-5730-47b0-b617-1565621def41'),
       ('b1af3a2d-32e9-466b-a605-800b274591c9'::uuid, '8c61cd23-68fb-4f1c-8a3c-60da74c86a64'::uuid, 'ocd-person/fb1c2c06-108c-41bf-9f08-44a9f8e0cb08'));
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 8 THEN RAISE EXCEPTION 'CA_0402: expected to delete 8 wrong Open States rows, deleted %', n; END IF;
END $$;

CREATE VIEW essentials.legislator_member_id_gaps WITH (security_invoker = true) AS
SELECT DISTINCT p.id AS politician_id, p.full_name, upper(d.state) AS state, d.district_type, d.label AS district
  FROM essentials.office_current_holder och
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = och.politician_id
 WHERE d.district_type IN ('STATE_UPPER', 'STATE_LOWER')
   AND NOT EXISTS (
     SELECT 1 FROM essentials.legislative_politician_id_map m
      WHERE m.politician_id = p.id AND m.id_type = 'openstates' AND m.match_method IN ('seat', 'id_crosswalk', 'manual'));

COMMENT ON VIEW essentials.legislator_member_id_gaps IS
  'Sitting state legislators with no trusted Open States id. Filled by scripts/member-ids/sync-member-ids.ts '
  '(seat match). Run it after any roster change; what stays here is what the script reports as a problem.';

REVOKE ALL ON essentials.legislator_member_id_gaps FROM PUBLIC, anon, authenticated;
GRANT SELECT ON essentials.legislator_member_id_gaps TO ev_api;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM essentials.legislative_politician_id_map
              WHERE id_type = 'openstates' AND source = 'openstates-committees'
                AND id_value = 'ocd-person/cb0f6477-568f-49db-aba3-f88e7bccbefc') THEN
    RAISE EXCEPTION 'CA_0402: Susan Rubio''s id is still on Catherine Stefani';
  END IF;
  IF (SELECT count(*) FROM essentials.legislator_member_id_gaps) < 4000 THEN
    RAISE EXCEPTION 'CA_0402: gaps view should list most legislators before the sync (got %)',
      (SELECT count(*) FROM essentials.legislator_member_id_gaps);
  END IF;
END $$;

COMMIT;
