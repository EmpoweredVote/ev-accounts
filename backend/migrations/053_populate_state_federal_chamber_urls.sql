-- 053_populate_state_federal_chamber_urls.sql
-- Populate website_url for state and federal chambers

-- === FEDERAL ===

-- Congress
UPDATE essentials.chambers SET website_url = 'https://www.senate.gov/'
WHERE name_formal = 'United States Senate';

UPDATE essentials.chambers SET website_url = 'https://www.house.gov/'
WHERE name_formal = 'United States House of Representatives';

-- President & VP
UPDATE essentials.chambers SET website_url = 'https://www.whitehouse.gov/'
WHERE name_formal = 'President of the United States';

UPDATE essentials.chambers SET website_url = 'https://www.whitehouse.gov/administration/vice-president/'
WHERE name_formal = 'Vice President of the United States';

-- Cabinet departments
UPDATE essentials.chambers SET website_url = 'https://www.state.gov/'
WHERE name_formal = 'United States Secretary of State';

UPDATE essentials.chambers SET website_url = 'https://home.treasury.gov/'
WHERE name_formal = 'United States Secretary of the Treasury';

UPDATE essentials.chambers SET website_url = 'https://www.defense.gov/'
WHERE name_formal = 'United States Secretary of Defense';

UPDATE essentials.chambers SET website_url = 'https://www.justice.gov/'
WHERE name_formal = 'United States Attorney General';

UPDATE essentials.chambers SET website_url = 'https://www.doi.gov/'
WHERE name_formal = 'United States Secretary of the Interior';

UPDATE essentials.chambers SET website_url = 'https://www.usda.gov/'
WHERE name_formal = 'United States Secretary of Agriculture';

UPDATE essentials.chambers SET website_url = 'https://www.commerce.gov/'
WHERE name_formal = 'United States Secretary of Commerce';

UPDATE essentials.chambers SET website_url = 'https://www.dol.gov/'
WHERE name_formal = 'United States Secretary of Labor';

UPDATE essentials.chambers SET website_url = 'https://www.hhs.gov/'
WHERE name_formal = 'United States Secretary of Health and Human Services';

UPDATE essentials.chambers SET website_url = 'https://www.hud.gov/'
WHERE name_formal = 'United States Secretary of Housing and Urban Development';

UPDATE essentials.chambers SET website_url = 'https://www.transportation.gov/'
WHERE name_formal = 'United States Secretary of Transportation';

UPDATE essentials.chambers SET website_url = 'https://www.energy.gov/'
WHERE name_formal = 'United States Secretary of Energy';

UPDATE essentials.chambers SET website_url = 'https://www.ed.gov/'
WHERE name_formal = 'United States Secretary of Education';

UPDATE essentials.chambers SET website_url = 'https://www.va.gov/'
WHERE name_formal = 'United States Secretary of Veterans Affairs';

UPDATE essentials.chambers SET website_url = 'https://www.dhs.gov/'
WHERE name_formal = 'United States Secretary of Homeland Security';

-- Cabinet-level officials
UPDATE essentials.chambers SET website_url = 'https://www.epa.gov/'
WHERE name_formal = 'United States Administrator of the Environmental Protection Agency';

UPDATE essentials.chambers SET website_url = 'https://www.sba.gov/'
WHERE name_formal = 'United States Administrator of the Small Business Administration';

UPDATE essentials.chambers SET website_url = 'https://ustr.gov/'
WHERE name_formal = 'United States Trade Representative';

UPDATE essentials.chambers SET website_url = 'https://www.dni.gov/'
WHERE name_formal = 'United States Director of National Intelligence';

UPDATE essentials.chambers SET website_url = 'https://www.whitehouse.gov/omb/'
WHERE name_formal = 'United States Director of the Office of Management and Budget';

UPDATE essentials.chambers SET website_url = 'https://www.whitehouse.gov/ostp/'
WHERE name_formal = 'United States Director of the Office of Science and Technology Policy';

UPDATE essentials.chambers SET website_url = 'https://usun.usmission.gov/'
WHERE name_formal = 'United States Ambassador to the United Nations';

UPDATE essentials.chambers SET website_url = 'https://www.whitehouse.gov/cea/'
WHERE name_formal = 'United States Chair of the Council of Economic Advisers';

UPDATE essentials.chambers SET website_url = 'https://www.whitehouse.gov/administration/chief-of-staff/'
WHERE name_formal = 'United States White House Chief of Staff';

-- Supreme Court
UPDATE essentials.chambers SET website_url = 'https://www.supremecourt.gov/'
WHERE name_formal = 'Supreme Court of the United States';

-- === INDIANA STATE ===

-- Legislature
UPDATE essentials.chambers SET website_url = 'https://iga.in.gov/chambers/senate'
WHERE name LIKE '%Indiana%Senate%' AND name_formal = '';

UPDATE essentials.chambers SET website_url = 'https://iga.in.gov/chambers/house'
WHERE name LIKE '%Indiana%House%' AND name_formal = '';

-- Courts
UPDATE essentials.chambers SET website_url = 'https://www.in.gov/courts/supreme/'
WHERE name_formal = 'Indiana Supreme Court';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/courts/appeals/'
WHERE name_formal = 'Indiana Court of Appeals';

-- Constitutional officers
UPDATE essentials.chambers SET website_url = 'https://www.in.gov/sos/'
WHERE name_formal = 'Indiana Secretary of State';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/auditor/'
WHERE name_formal = 'Indiana State Auditor';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/tos/'
WHERE name_formal = 'Indiana State Treasurer';

-- State agencies
UPDATE essentials.chambers SET website_url = 'https://www.in.gov/doe/'
WHERE name_formal = 'Indiana Secretary of Education';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/isda/'
WHERE name_formal = 'Indiana Director of Agriculture';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/dnr/'
WHERE name_formal = 'Indiana Director of Natural Resources';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/dol/'
WHERE name_formal = 'Indiana Commissioner of Labor';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/iurc/'
WHERE name_formal = 'Indiana Utility Regulatory Commission';

UPDATE essentials.chambers SET website_url = 'https://www.in.gov/idoi/'
WHERE name_formal = 'Indiana Insurance Commissioner';
