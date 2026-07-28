-- Migration 1483: correct the primary name for WI Assembly District 55 (Nate Gustafson)
--
-- Found while running the correct-person guard for the WI legislature headshot import (mig 1482):
-- prod held full_name 'Gus Gustafson' / first_name 'Gus' for the sitting AD55 member, while the
-- Wisconsin Legislature's own roster and his member page both render 'Nate L. Gustafson'
-- (docs.legis.wisconsin.gov/2025/legislators/assembly/2736 — District 55, Omro, R).
--
-- 'Gus' is NOT a fabrication: he is publicly 'Nate "Gus" Gustafson', and the row's data_source is
-- 'openstates-v3-wi', which evidently captured the nickname as the given name. But his common public
-- name — Ballotpedia article title, Wikipedia article title, and the legislature's own roster display
-- ('Gustafson, Nate') — is Nate. prod's convention for this table is the COMMONLY USED name rather
-- than the formal one (it holds 'Clint Anderson' for Clinton M. Anderson, 'Dave Armstrong' for
-- David Armstrong), so the correct primary value is 'Nate Gustafson'.
--
-- So this migration:
--   * sets full_name / first_name to the common public name, and records the official middle initial
--   * PRESERVES 'Gus' in alternate_names so the nickname stays searchable (it is a real name he uses)
--   * sets full_name_manual_override = true, WITHOUT WHICH the openstates-v3-wi sync would simply
--     revert this to 'Gus' on the next run
--
-- Identity is not in doubt: district, surname and party all agree, and the seat is keyed through
-- essentials.office_current_holder, not by name.
--
-- Idempotent: guarded on the current wrong value, and alternate_names is only appended if absent.
-- Targeted by the stable external_id (-5506055), never by name.

UPDATE essentials.politicians
   SET full_name = 'Nate Gustafson',
       first_name = 'Nate',
       middle_initial = 'L',
       full_name_manual_override = true,
       alternate_names = CASE
         WHEN coalesce(alternate_names, '{}') @> ARRAY['Gus Gustafson']
           THEN alternate_names
         ELSE array_append(coalesce(alternate_names, '{}'), 'Gus Gustafson')
       END
 WHERE external_id = -5506055
   AND last_name = 'Gustafson'
   AND full_name <> 'Nate Gustafson';

-- Post-verify gate.
DO $$
DECLARE r record;
BEGIN
  SELECT full_name, first_name, middle_initial, last_name, full_name_manual_override, alternate_names
    INTO r
    FROM essentials.politicians
   WHERE external_id = -5506055;

  IF r IS NULL THEN
    RAISE EXCEPTION 'migration 1483: no politician with external_id = -5506055';
  END IF;
  IF r.full_name <> 'Nate Gustafson' OR r.first_name <> 'Nate' THEN
    RAISE EXCEPTION 'migration 1483: name not corrected (full_name=%, first_name=%)', r.full_name, r.first_name;
  END IF;
  IF r.middle_initial <> 'L' THEN
    RAISE EXCEPTION 'migration 1483: middle_initial not set (got %)', r.middle_initial;
  END IF;
  IF NOT r.full_name_manual_override THEN
    RAISE EXCEPTION 'migration 1483: full_name_manual_override not set — the openstates sync would revert this';
  END IF;
  IF NOT (r.alternate_names @> ARRAY['Gus Gustafson']) THEN
    RAISE EXCEPTION 'migration 1483: nickname not preserved in alternate_names (got %)', r.alternate_names;
  END IF;

  -- The seat must still resolve to exactly this person, i.e. the rename broke no occupancy join.
  IF (SELECT count(*)
        FROM essentials.offices o
        JOIN essentials.districts d ON d.id = o.district_id
        JOIN essentials.office_current_holder och ON och.office_id = o.id
        JOIN essentials.politicians p ON p.id = och.politician_id
       WHERE lower(d.state) = 'wi'
         AND d.district_type = 'STATE_LOWER'
         AND split_part(d.ocd_id, ':', 4)::int = 55
         AND p.external_id = -5506055) <> 1 THEN
    RAISE EXCEPTION 'migration 1483: AD55 no longer resolves to external_id -5506055';
  END IF;
END $$;
