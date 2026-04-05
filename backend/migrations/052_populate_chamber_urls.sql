-- 052_populate_chamber_urls.sql
-- Populate website_url for Bloomington and Monroe County chambers

-- City of Bloomington
UPDATE essentials.chambers SET website_url = 'https://bloomington.in.gov/council'
WHERE name_formal = 'Bloomington Common Council';

UPDATE essentials.chambers SET website_url = 'https://bloomington.in.gov/mayor'
WHERE name_formal = 'City of Bloomington'
  AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Bloomington, Indiana, US')
  AND EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE o.chamber_id = essentials.chambers.id AND d.district_type = 'LOCAL_EXEC'
  );

UPDATE essentials.chambers SET website_url = 'https://bloomington.in.gov/clerk'
WHERE name_formal = 'City of Bloomington'
  AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Bloomington, Indiana, US')
  AND EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE o.chamber_id = essentials.chambers.id AND d.district_type = 'LOCAL'
  );

-- Monroe County
UPDATE essentials.chambers SET website_url = 'https://www.in.gov/counties/monroe/government/council/'
WHERE name_formal = 'Monroe County Council';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/counties/monroe/government/commissioners/'
WHERE name_formal = 'Monroe County Board of Commissioners';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/counties/monroe/'
WHERE name_formal = 'Monroe County Government';

-- Monroe County Circuit Court
UPDATE essentials.chambers SET website_url = 'https://www.in.gov/courts/circuit/monroe/'
WHERE name_formal = 'Monroe County Circuit Court';

-- MCCSC
UPDATE essentials.chambers SET website_url = 'https://www.mccsc.edu/'
WHERE name_formal = 'Monroe County Community School Corporation';
