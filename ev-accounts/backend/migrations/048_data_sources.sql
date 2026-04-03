-- 048: Data source registry for attribution footnotes

-- 1. Create registry table
CREATE TABLE treasury.data_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Seed canonical sources
INSERT INTO treasury.data_sources (name, display_name, url) VALUES
  ('indiana-gateway',          'Indiana Gateway',          'https://gateway.ifionline.org'),
  ('bloomington-open-data',    'Bloomington Open Data',    'https://data.bloomington.in.gov'),
  ('ca-state-controller',      'CA State Controller',      'https://bythenumbers.sco.ca.gov'),
  ('la-city-open-data',        'LA City Open Data',        'https://data.lacity.org'),
  ('la-county-open-data',      'LA County Open Data',      'https://data.lacounty.gov'),
  ('west-hollywood-open-data', 'West Hollywood Open Data', 'https://www.weho.org/city-government/city-budget/open-checkbook');

-- 3. Add FK column to budgets
ALTER TABLE treasury.budgets
  ADD COLUMN data_source_id UUID REFERENCES treasury.data_sources(id);

-- 4. Normalize: map existing data_source text to data_source_id
-- Indiana Gateway (explicit + township/county disbursement reports)
UPDATE treasury.budgets SET data_source_id = (SELECT id FROM treasury.data_sources WHERE name = 'indiana-gateway')
WHERE data_source = 'Indiana Gateway'
   OR data_source LIKE '%Budget & Disbursements';

-- Bloomington Open Data
UPDATE treasury.budgets SET data_source_id = (SELECT id FROM treasury.data_sources WHERE name = 'bloomington-open-data')
WHERE data_source IN ('bloomington-open-data', 'data/checkbook-all.csv', 'Bloomington Annual Compensation', 'Bloomington Public Contracts');

-- CA State Controller
UPDATE treasury.budgets SET data_source_id = (SELECT id FROM treasury.data_sources WHERE name = 'ca-state-controller')
WHERE data_source LIKE 'CA State Controller%';

-- LA City Open Data
UPDATE treasury.budgets SET data_source_id = (SELECT id FROM treasury.data_sources WHERE name = 'la-city-open-data')
WHERE data_source IN ('LA City Budget & Expenditures', 'LA City Checkbook', 'LA City Payroll')
   OR data_source LIKE 'Socrata:%';

-- LA County Open Data
UPDATE treasury.budgets SET data_source_id = (SELECT id FROM treasury.data_sources WHERE name = 'la-county-open-data')
WHERE data_source LIKE 'ArcGIS:%';

-- West Hollywood Open Data
UPDATE treasury.budgets SET data_source_id = (SELECT id FROM treasury.data_sources WHERE name = 'west-hollywood-open-data')
WHERE data_source LIKE 'West Hollywood Demand Register%';
