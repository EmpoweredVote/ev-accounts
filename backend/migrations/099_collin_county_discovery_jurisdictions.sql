-- Migration 099: Collin County Discovery Jurisdictions
-- Seeds essentials.discovery_jurisdictions with all 23 confirmed-incorporated
-- Collin County cities so the weekly cron will find candidates from
-- collincountytx.gov (the actual domain — collincountyvotes.gov does not exist).
--
-- Copeville is excluded pending municipal incorporation verification.
-- Election date: 2026-05-02 — Texas Uniform Election Day May 2, 2026.
-- Confirmed by official Collin County Elections site and all major news sources.
-- Note: CONTEXT.md and earlier Phase 13 docs referenced 'May 3, 2026' but all
-- official sources (collincountytx.gov, NBC DFW, etc.) confirm May 2, 2026.
--
-- Deviation Rule 2 applied: No TX election row existed in essentials.elections
-- (Phase 12 seeded governments/offices only, not elections). This migration
-- seeds the election row first, then the 23 discovery_jurisdictions rows.

-- Step 1: Seed the TX May 2026 election row (required before discovery_jurisdictions)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES (
  '2026 Texas Municipal General',
  '2026-05-02',
  'general',
  'city',
  'TX'
)
ON CONFLICT (name, election_date, state) DO NOTHING;

-- Step 2: Seed 23 Collin County city rows into discovery_jurisdictions
INSERT INTO essentials.discovery_jurisdictions (
  jurisdiction_geoid, jurisdiction_name, state, election_date,
  source_url, allowed_domains
) VALUES
  -- Tier 1
  ('4863000', 'Plano',          'TX', '2026-05-02', 'https://www.plano.gov/1402/Elections',                    ARRAY['collincountytx.gov', 'co.collin.tx.us', 'plano.gov']),
  ('4845744', 'McKinney',       'TX', '2026-05-02', 'https://www.mckinneytexas.org/139/Elections',             ARRAY['collincountytx.gov', 'co.collin.tx.us', 'mckinneytexas.org']),
  ('4801924', 'Allen',          'TX', '2026-05-02', 'https://www.cityofallen.org',                             ARRAY['collincountytx.gov', 'co.collin.tx.us', 'cityofallen.org']),
  ('4827684', 'Frisco',         'TX', '2026-05-02', 'https://www.friscotexas.gov',                             ARRAY['collincountytx.gov', 'co.collin.tx.us', 'friscotexas.gov']),
  -- Tier 2
  ('4850100', 'Murphy',         'TX', '2026-05-02', 'https://www.murphytx.org',                                ARRAY['collincountytx.gov', 'co.collin.tx.us', 'murphytx.org']),
  ('4813684', 'Celina',         'TX', '2026-05-02', 'https://www.celinatx.gov/government/city-council',        ARRAY['collincountytx.gov', 'co.collin.tx.us', 'celinatx.gov']),
  ('4863276', 'Prosper',        'TX', '2026-05-02', 'https://www.prospertx.gov/479/May-2026-General-Election', ARRAY['collincountytx.gov', 'co.collin.tx.us', 'prospertx.gov']),
  ('4863500', 'Richardson',     'TX', '2026-05-02', 'https://www.cor.net/government/city-secretary/elections', ARRAY['collincountytx.gov', 'co.collin.tx.us', 'cor.net']),
  -- Tier 3
  ('4803300', 'Anna',           'TX', '2026-05-02', 'https://www.annatexas.gov/1015/Elections',                ARRAY['collincountytx.gov', 'co.collin.tx.us', 'annatexas.gov']),
  ('4847496', 'Melissa',        'TX', '2026-05-02', 'https://www.cityofmelissa.com/287/Elections',             ARRAY['collincountytx.gov', 'co.collin.tx.us', 'cityofmelissa.com']),
  ('4863432', 'Princeton',      'TX', '2026-05-02', 'https://www.princetontx.gov/294/Elections',               ARRAY['collincountytx.gov', 'co.collin.tx.us', 'princetontx.gov']),
  ('4845012', 'Lucas',          'TX', '2026-05-02', 'https://www.lucastexas.us',                               ARRAY['collincountytx.gov', 'co.collin.tx.us', 'lucastexas.us']),
  ('4841800', 'Lavon',          'TX', '2026-05-02', 'https://lavontx.gov/election-information/',               ARRAY['collincountytx.gov', 'co.collin.tx.us', 'lavontx.gov']),
  ('4825224', 'Fairview',       'TX', '2026-05-02', 'https://www.fairviewtexas.org',                           ARRAY['collincountytx.gov', 'co.collin.tx.us', 'fairviewtexas.org']),
  ('4875960', 'Van Alstyne',    'TX', '2026-05-02', 'https://cityofvanalstyne.us',                             ARRAY['collincountytx.gov', 'co.collin.tx.us', 'cityofvanalstyne.us']),
  ('4825488', 'Farmersville',   'TX', '2026-05-02', 'https://www.farmersvilletx.com',                          ARRAY['collincountytx.gov', 'co.collin.tx.us', 'farmersvilletx.com']),
  -- Tier 4
  ('4855152', 'Parker',         'TX', '2026-05-02', 'https://www.parkertexas.us/87/Elections-Elecciones',      ARRAY['collincountytx.gov', 'co.collin.tx.us', 'parkertexas.us']),
  ('4864220', 'Saint Paul',     'TX', '2026-05-02', 'https://www.stpaultexas.us',                              ARRAY['collincountytx.gov', 'co.collin.tx.us', 'stpaultexas.us']),
  ('4850760', 'Nevada',         'TX', '2026-05-02', 'https://cityofnevadatx.org',                              ARRAY['collincountytx.gov', 'co.collin.tx.us', 'cityofnevadatx.org']),
  ('4877740', 'Weston',         'TX', '2026-05-02', 'https://www.westontexas.com',                             ARRAY['collincountytx.gov', 'co.collin.tx.us', 'westontexas.com']),
  ('4844308', 'Lowry Crossing', 'TX', '2026-05-02', 'https://www.lowrycrossingtexas.org',                      ARRAY['collincountytx.gov', 'co.collin.tx.us', 'lowrycrossingtexas.org']),
  ('4838068', 'Josephine',      'TX', '2026-05-02', 'https://cityofjosephinetx.com',                           ARRAY['collincountytx.gov', 'co.collin.tx.us', 'cityofjosephinetx.com']),
  ('4808872', 'Blue Ridge',     'TX', '2026-05-02', 'https://blueridgecity.com',                               ARRAY['collincountytx.gov', 'co.collin.tx.us', 'blueridgecity.com'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;
