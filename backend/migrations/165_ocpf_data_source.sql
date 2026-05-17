-- 165: Add ocpf as valid data_source in contributions
--
-- Constraint before: fec | indiana | cal_access | la_socrata | community_verified | la_county_netfile
-- Constraint after:  fec | indiana | cal_access | la_socrata | community_verified | la_county_netfile | in_monroe_county_local | ocpf
--
-- NOTE: in_monroe_county_local was added by quick-013 (Monroe County PDF OCR pipeline)
-- but was missing from the CHECK constraint rebuild. This migration adds both
-- in_monroe_county_local and ocpf together.
--
-- politician_sources.source_system has no CHECK constraint — no change needed.

ALTER TABLE transparent_motivations.contributions
  DROP CONSTRAINT chk_transparent_motivations_contributions_data_source;

ALTER TABLE transparent_motivations.contributions
  ADD CONSTRAINT chk_transparent_motivations_contributions_data_source
  CHECK (data_source IN (
    'fec',
    'indiana',
    'cal_access',
    'la_socrata',
    'community_verified',
    'la_county_netfile',
    'in_monroe_county_local',
    'ocpf'
  ));
