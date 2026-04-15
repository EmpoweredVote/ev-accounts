-- 068: Add la_county_netfile as valid data_source in contributions
--
-- The transparent_motivations.contributions table has a CHECK constraint
-- on the data_source column. This migration drops the existing constraint
-- and recreates it with la_county_netfile added.
--
-- Constraint before: fec | indiana | cal_access | la_socrata | community_verified
-- Constraint after:  fec | indiana | cal_access | la_socrata | community_verified | la_county_netfile
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
    'la_county_netfile'
  ));
