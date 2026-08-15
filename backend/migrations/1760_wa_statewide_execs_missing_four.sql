-- 1760_wa_statewide_execs_missing_four.sql
-- Washington's four unseeded statewide elected executives: State Auditor,
-- Commissioner of Public Lands, Insurance Commissioner, and Superintendent of
-- Public Instruction. 4 districts + 4 chambers + 4 offices + 4 incumbents.
--
-- WHY THIS EXISTS. The Seattle deep seed (migs 1742-1753) seeded State of
-- Washington with 7 chambers: the two legislative ones and FIVE executives
-- (Governor, Lieutenant Governor, Attorney General, Secretary of State,
-- Treasurer). Washington elects NINE statewide executives. The gap was found on
-- 2026-08-15 while writing .planning/WA-GAPS.md and is visible in the product:
-- any WA address returned 5 statewide officials instead of 9.
--
-- SOURCES
--   Identity + party preference : the Secretary of State's CERTIFIED November 5,
--     2024 General Election results, one page per office —
--     results.vote.wa.gov/results/20241105/{state-auditor,
--     commissioner-of-public-lands, insurance-commissioner,
--     superintendent-of-public-instruction}.html (retrieved 2026-08-15).
--   Office bio pages : sao.wa.gov/about-sao/state-auditor-pat-mccarthy,
--     dnr.wa.gov/commissioner-public-lands-dave-upthegrove,
--     insurance.wa.gov/about-us/about-patty-kuderer,
--     ospi.k12.wa.us/about-ospi/superintendent-chris-reykdal.
--   Assumed-office dates : Ballotpedia — the same source the 147-legislator seed
--     (mig 1747) used for assumed-office dates, so precision is consistent.
--
-- PARTY. Washington is a PARTY-PREFERENCE state: the ballot line reads "Prefers
-- Democratic Party", which is a candidate's self-declaration, not a party
-- nomination. All three partisan winners declared Democratic preference.
--   !! Superintendent of Public Instruction is NONPARTISAN and its party is NULL
--   on purpose. This is not missing data, and the certified results prove it:
--   every other 2024 statewide race prints a party preference next to each name
--   ("Pat (Patrice) McCarthy (Prefers Democratic Party)"), while the SPI race
--   prints "Chris Reykdal" and "David Olson" with no party at all.
--   The value 'Democrat' matches the five WA executives already seeded. The 147
--   WA legislators use 'Democratic'/'Republican' instead, because they came from
--   the legislature's own web service. That inconsistency is pre-existing and is
--   NOT normalised here; party never displays in the product.
--
-- NAME. The certified results render the auditor as "Pat (Patrice) McCarthy".
-- Her own agency, and every heading on it, says "Pat McCarthy" — that is the
-- full_name, with "Patrice McCarthy" kept as an alias so the parenthetical form
-- is still findable.
--
-- NO RACE ROWS. None of the four is on the 2026 ballot. Washington elects its
-- statewide executives to four-year terms in presidential years; all four were
-- last elected 2024-11-05 and next stand in 2028. Consistent with this, the WA
-- 2026 election already in the DB (140 races, seeded from the SoS filed list)
-- contains no statewide executive contest.
--
-- DISTRICTS. Each executive gets its OWN STATE_EXEC district row, mirroring the
-- five that already exist: geo_id '53', mtfcc '' (empty string, not NULL),
-- state 'WA' UPPERCASE, district_id ''. STATE_EXEC is the one WA tier that uses
-- uppercase state — the legislative and local tiers use lowercase 'wa'.
--
-- role_canonical IS LEFT NULL. Only five canonical executive roles exist
-- anywhere in this database (governor, lt_governor, attorney_general, treasurer,
-- secretary_of_state). There is no established value for auditor, lands,
-- insurance or schools chief, and role_canonical feeds the partner CSV export —
-- inventing four new tokens here would put unreviewed vocabulary in a published
-- artifact. NULL matches the 83,401 offices that already carry no canonical role.
--
-- chambers.slug is a GENERATED column derived from name_formal — never inserted.
--
-- Idempotency: districts/chambers/offices have no usable unique index for these
-- keys, so every insert uses NOT EXISTS. politicians.external_id DOES have one,
-- so that insert uses ON CONFLICT DO NOTHING. External ids -5300006..-5300009
-- extend the existing -53000xx executive band (verified free 2026-08-15).

-- ─── STATE_EXEC district rows (4) ────────────────────────────────────────────

INSERT INTO essentials.districts
  (id, geo_id, label, district_type, state, mtfcc, district_id, representation_basis)
SELECT gen_random_uuid(), '53', v.label, 'STATE_EXEC', 'WA', '', '', 'residency'
FROM (VALUES
  ('Washington State Auditor'),
  ('Washington Commissioner of Public Lands'),
  ('Washington Insurance Commissioner'),
  ('Washington Superintendent of Public Instruction')
) AS v(label)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.label = v.label AND d.district_type = 'STATE_EXEC'
);

-- ─── Chambers (4) ────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, v.name, v.name_formal, 1, '4', false, 'full'::essentials.policy_engagement_level
FROM essentials.governments g
CROSS JOIN (VALUES
  ('State Auditor',                        'State Auditor of Washington'),
  ('Commissioner of Public Lands',         'Commissioner of Public Lands of Washington'),
  ('Insurance Commissioner',               'Insurance Commissioner of Washington'),
  ('Superintendent of Public Instruction', 'Superintendent of Public Instruction of Washington')
) AS v(name, name_formal)
WHERE g.geo_id = '53' AND g.type = 'STATE'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = v.name
  );

-- ─── Offices (4), one per chamber, on that chamber's own STATE_EXEC district ──

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'WA', false, false, 'full'
FROM essentials.governments g
JOIN essentials.chambers c ON c.government_id = g.id
JOIN (VALUES
  ('State Auditor',                        'State Auditor',                        'Washington State Auditor'),
  ('Commissioner of Public Lands',         'Commissioner of Public Lands',         'Washington Commissioner of Public Lands'),
  ('Insurance Commissioner',               'Insurance Commissioner',               'Washington Insurance Commissioner'),
  ('Superintendent of Public Instruction', 'Superintendent of Public Instruction', 'Washington Superintendent of Public Instruction')
) AS v(chamber_name, title, district_label) ON c.name = v.chamber_name
JOIN essentials.districts d
  ON d.label = v.district_label AND d.district_type = 'STATE_EXEC' AND d.geo_id = '53'
WHERE g.geo_id = '53' AND g.type = 'STATE'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.title = v.title
  );

-- ─── Incumbents (4) + their office terms ─────────────────────────────────────
-- Single statement by necessity: office_terms must resolve politician_id for
-- rows this same statement creates, so the politician insert is a data-modifying
-- CTE whose RETURNING output is unioned with any pre-existing rows.

WITH seed (ext_id, full_name, first_name, last_name, party, aliases,
           chamber_name, title, term_start, precision, bio_url) AS (
  VALUES
    (-5300006::bigint, 'Pat McCarthy'::text,     'Pat'::text,   'McCarthy'::text,   'Democrat'::text,
       ARRAY['Patrice McCarthy','Pat (Patrice) McCarthy']::text[],
       'State Auditor'::text, 'State Auditor'::text,
       DATE '2017-01-11', 'day'::text,
       'https://sao.wa.gov/about-sao/state-auditor-pat-mccarthy'::text),
    (-5300007, 'Dave Upthegrove', 'Dave',  'Upthegrove', 'Democrat', ARRAY[]::text[],
       'Commissioner of Public Lands', 'Commissioner of Public Lands',
       DATE '2025-01-13', 'day',
       'https://www.dnr.wa.gov/commissioner-public-lands-dave-upthegrove'),
    (-5300008, 'Patty Kuderer',   'Patty', 'Kuderer',    'Democrat', ARRAY[]::text[],
       'Insurance Commissioner', 'Insurance Commissioner',
       DATE '2025-01-15', 'day',
       'https://www.insurance.wa.gov/about-us/about-patty-kuderer'),
    -- NONPARTISAN office: party NULL is the correct value, not missing data.
    (-5300009, 'Chris Reykdal',   'Chris', 'Reykdal',    NULL,       ARRAY[]::text[],
       'Superintendent of Public Instruction', 'Superintendent of Public Instruction',
       DATE '2017-01-11', 'day',
       'https://ospi.k12.wa.us/about-ospi/superintendent-chris-reykdal')
),
ins AS (
  INSERT INTO essentials.politicians
    (external_id, full_name, first_name, last_name, party, party_short_name,
     alternate_names, photo_origin_url, is_incumbent, is_active, is_appointed, data_source)
  SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.party, NULL,
         s.aliases, s.bio_url, true, true, false,
         'Identity and party preference from the WA Secretary of State certified 2024 General Election results (results.vote.wa.gov/results/20241105); bio pages at sao.wa.gov, dnr.wa.gov, insurance.wa.gov, ospi.k12.wa.us; assumed-office dates from Ballotpedia. Retrieved 2026-08-15.'
  FROM seed s
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id, external_id
),
pol AS (
  SELECT id, external_id FROM ins
  UNION
  SELECT p.id, p.external_id FROM essentials.politicians p
  JOIN seed s ON s.ext_id = p.external_id
)
INSERT INTO essentials.office_terms
  (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, pol.id, s.term_start, NULL, s.precision, 'elected',
       'Identity and party preference from the WA Secretary of State certified 2024 General Election results (results.vote.wa.gov/results/20241105); bio pages at sao.wa.gov, dnr.wa.gov, insurance.wa.gov, ospi.k12.wa.us; assumed-office dates from Ballotpedia. Retrieved 2026-08-15.'
FROM seed s
JOIN essentials.governments g ON g.geo_id = '53' AND g.type = 'STATE'
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = s.chamber_name
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = s.title
JOIN pol ON pol.external_id = s.ext_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot
  WHERE ot.office_id = o.id AND ot.politician_id = pol.id
);
