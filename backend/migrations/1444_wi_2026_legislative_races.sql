-- 1422_wi_2026_legislative_races.sql
-- WI 2026 legislative races: 220 Aug-11 partisan-primary races + 116 Nov-3 general
-- race shells, across all 17 Senate districts and 99 Assembly districts up this cycle.
-- GENERATED -- do not hand-edit; regenerate (see PROVENANCE).
--
-- PRECONDITIONS: 1441 (creates the 'WI 2026 Partisan Primary' election) and 1443
--   (creates the 132 legislative offices). Inserts ZERO rows without both.
--
-- Wisconsin elects ALL 99 Assembly seats every 2 years and HALF the Senate; 2026 is the
--   ODD-numbered Senate cycle, so districts 1,3,..,33 (17 seats) are up and the 16
--   even-numbered seats are NOT. Verified against the WEC report, which contains office
--   sections for exactly those 17 Senate districts and all 99 Assembly districts.
--
-- PROVENANCE: WEC "Ballot Access Report" 6.9.2026 (printed 6/8/2026), parsed and
--   self-validated -- every office section's row count was reconciled against its own
--   printed "Office Subtotal", all 116 sections accounted for, and every ballot-qualified
--   row resolved to a known party. 258 rows carried status Approve and 8 Challenged.
--   NOTE: two office headers (AD 47, AD 70) fall on PDF page breaks and are prefixed with
--   a form-feed; a naive ^Office parse silently drops them.
--
-- The 8 Challenged rows were resolved at the WEC's 6/9/2026 meeting. Veronica Diaz
--   (AD 21, Republican) was the ONLY successful challenge statewide -- disqualified for 10
--   out-of-district signatures plus missing paperwork -- and is NOT seeded. The other 7
--   were approved: Russell Antonio Goodwin, Sr. (AD 12) explicitly (201 valid signatures,
--   challenge by primary opponent Jordan Roman not sustained), and Polce (SD 11), Guerreo
--   (AD 9), Disher (AD 71), Tataje (AD 51), Castaneda (AD 76) and Henderson (AD 90) on the
--   strength of two concurring reports that Diaz was the only challenge sustained.
--   Each is tagged in race_candidates.source so they stay auditable.
--   Sources: Wisconsin Examiner + Urban Milwaukee, 2026-06-09/10.
--   Jon Aleckson (AD 50) was challenged separately on 6/10 (extension office) and
--   approved with 292 valid signatures -- WEC June 10 memo, Recommended Motion #1.
--
-- ANTIPARTISAN: party lives on races.primary_party (which ballot the voter requests).
--   Never written to race_candidates, and not written to the new politician rows.
--
-- INCUMBENTS: 97 of the 256 primary candidates are sitting members seeking
--   re-election. Those REUSE the politician rows seeded by 1443 (external_id -5505xxx /
--   -5506xxx) so their photo and email carry onto the election card, rather than creating
--   duplicates. race_candidates.full_name keeps the BALLOT name where it differs from the
--   roster name -- e.g. Robert Wittke (AD 63) is "Bob Wittke" in the roster, Nate
--   Gustafson (AD 55) is "Gus Gustafson". Same people; matched on unique surname within
--   the district. New challenger records use -5507001..-5507159.
--
-- 19 of the 116 seats have NO incumbent on the ballot, reconciling exactly with the
--   WEC noncandidacy list (17 filings) plus AD 50 and AD 56, whose incumbents filed
--   neither noncandidacy nor nomination papers and so triggered a 72-hour extension.
--   Includes AD 33 -- Assembly Speaker Robin Vos is not seeking re-election.
--
-- The 9 candidates below are ballot-qualified but do NOT appear in a partisan primary
--   (Wisconsin independents and non-ballot-status designations go straight to November).
--   They are NOT seeded here: the general races have no candidates yet, and adding only
--   these would render a general race that looks like an unopposed independent. Attach
--   them together with the party nominees after 2026-08-11:
--     ASM D36: Shena Chapman (Independent)
--     ASM D51: Nathan Tataje (American Solidarity)
--     ASM D53: Rachael Dowling (Independent)
--     ASM D60: Tiffany Brault (Independent)
--     ASM D69: Josh Kelley (Independent)
--     ASM D95: Paul Michael Weber (Independent)
--     SEN D1: Mark Becker (Independent)
--     SEN D9: Christian Ellis (Independent)
--     SEN D15: Christopher Dean (Serving People Not Politicians)
--
-- General races are candidate-less on purpose (same rationale as 1441): the primary has
--   not happened. ElectionsView hides candidate-less races, so they stay invisible until
--   nominees are attached.
BEGIN;

-- ── 1. 220 partisan-primary races (office x ballot party) ──
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, v.position_name, v.primary_party, 1,
       'WEC Ballot Access Report 6.9.2026; ballot-qualified filers only'
FROM (VALUES
    ('55001'::text, 'STATE_LOWER'::text, 'Assembly District 1'::text, 'Democratic'::text),
    ('55001', 'STATE_LOWER', 'Assembly District 1', 'Republican'),
    ('55002', 'STATE_LOWER', 'Assembly District 2', 'Democratic'),
    ('55002', 'STATE_LOWER', 'Assembly District 2', 'Republican'),
    ('55003', 'STATE_LOWER', 'Assembly District 3', 'Republican'),
    ('55004', 'STATE_LOWER', 'Assembly District 4', 'Democratic'),
    ('55004', 'STATE_LOWER', 'Assembly District 4', 'Republican'),
    ('55005', 'STATE_LOWER', 'Assembly District 5', 'Democratic'),
    ('55005', 'STATE_LOWER', 'Assembly District 5', 'Republican'),
    ('55005', 'STATE_LOWER', 'Assembly District 5', 'Wisconsin Green'),
    ('55006', 'STATE_LOWER', 'Assembly District 6', 'Democratic'),
    ('55006', 'STATE_LOWER', 'Assembly District 6', 'Republican'),
    ('55007', 'STATE_LOWER', 'Assembly District 7', 'Democratic'),
    ('55007', 'STATE_LOWER', 'Assembly District 7', 'Republican'),
    ('55008', 'STATE_LOWER', 'Assembly District 8', 'Democratic'),
    ('55008', 'STATE_LOWER', 'Assembly District 8', 'Republican'),
    ('55009', 'STATE_LOWER', 'Assembly District 9', 'Democratic'),
    ('55009', 'STATE_LOWER', 'Assembly District 9', 'Republican'),
    ('55010', 'STATE_LOWER', 'Assembly District 10', 'Democratic'),
    ('55010', 'STATE_LOWER', 'Assembly District 10', 'Wisconsin Green'),
    ('55011', 'STATE_LOWER', 'Assembly District 11', 'Democratic'),
    ('55011', 'STATE_LOWER', 'Assembly District 11', 'Republican'),
    ('55012', 'STATE_LOWER', 'Assembly District 12', 'Democratic'),
    ('55013', 'STATE_LOWER', 'Assembly District 13', 'Democratic'),
    ('55013', 'STATE_LOWER', 'Assembly District 13', 'Republican'),
    ('55014', 'STATE_LOWER', 'Assembly District 14', 'Democratic'),
    ('55014', 'STATE_LOWER', 'Assembly District 14', 'Republican'),
    ('55015', 'STATE_LOWER', 'Assembly District 15', 'Democratic'),
    ('55015', 'STATE_LOWER', 'Assembly District 15', 'Republican'),
    ('55016', 'STATE_LOWER', 'Assembly District 16', 'Democratic'),
    ('55016', 'STATE_LOWER', 'Assembly District 16', 'Republican'),
    ('55017', 'STATE_LOWER', 'Assembly District 17', 'Democratic'),
    ('55017', 'STATE_LOWER', 'Assembly District 17', 'Republican'),
    ('55018', 'STATE_LOWER', 'Assembly District 18', 'Democratic'),
    ('55018', 'STATE_LOWER', 'Assembly District 18', 'Republican'),
    ('55019', 'STATE_LOWER', 'Assembly District 19', 'Democratic'),
    ('55019', 'STATE_LOWER', 'Assembly District 19', 'Republican'),
    ('55020', 'STATE_LOWER', 'Assembly District 20', 'Democratic'),
    ('55020', 'STATE_LOWER', 'Assembly District 20', 'Republican'),
    ('55021', 'STATE_LOWER', 'Assembly District 21', 'Democratic'),
    ('55021', 'STATE_LOWER', 'Assembly District 21', 'Republican'),
    ('55022', 'STATE_LOWER', 'Assembly District 22', 'Democratic'),
    ('55022', 'STATE_LOWER', 'Assembly District 22', 'Republican'),
    ('55023', 'STATE_LOWER', 'Assembly District 23', 'Democratic'),
    ('55023', 'STATE_LOWER', 'Assembly District 23', 'Republican'),
    ('55024', 'STATE_LOWER', 'Assembly District 24', 'Democratic'),
    ('55024', 'STATE_LOWER', 'Assembly District 24', 'Republican'),
    ('55025', 'STATE_LOWER', 'Assembly District 25', 'Democratic'),
    ('55025', 'STATE_LOWER', 'Assembly District 25', 'Republican'),
    ('55026', 'STATE_LOWER', 'Assembly District 26', 'Democratic'),
    ('55026', 'STATE_LOWER', 'Assembly District 26', 'Republican'),
    ('55027', 'STATE_LOWER', 'Assembly District 27', 'Republican'),
    ('55028', 'STATE_LOWER', 'Assembly District 28', 'Democratic'),
    ('55028', 'STATE_LOWER', 'Assembly District 28', 'Republican'),
    ('55029', 'STATE_LOWER', 'Assembly District 29', 'Democratic'),
    ('55029', 'STATE_LOWER', 'Assembly District 29', 'Republican'),
    ('55030', 'STATE_LOWER', 'Assembly District 30', 'Democratic'),
    ('55030', 'STATE_LOWER', 'Assembly District 30', 'Republican'),
    ('55031', 'STATE_LOWER', 'Assembly District 31', 'Democratic'),
    ('55031', 'STATE_LOWER', 'Assembly District 31', 'Republican'),
    ('55032', 'STATE_LOWER', 'Assembly District 32', 'Democratic'),
    ('55032', 'STATE_LOWER', 'Assembly District 32', 'Republican'),
    ('55033', 'STATE_LOWER', 'Assembly District 33', 'Democratic'),
    ('55033', 'STATE_LOWER', 'Assembly District 33', 'Republican'),
    ('55034', 'STATE_LOWER', 'Assembly District 34', 'Democratic'),
    ('55034', 'STATE_LOWER', 'Assembly District 34', 'Republican'),
    ('55035', 'STATE_LOWER', 'Assembly District 35', 'Democratic'),
    ('55035', 'STATE_LOWER', 'Assembly District 35', 'Republican'),
    ('55036', 'STATE_LOWER', 'Assembly District 36', 'Republican'),
    ('55037', 'STATE_LOWER', 'Assembly District 37', 'Democratic'),
    ('55037', 'STATE_LOWER', 'Assembly District 37', 'Republican'),
    ('55038', 'STATE_LOWER', 'Assembly District 38', 'Democratic'),
    ('55038', 'STATE_LOWER', 'Assembly District 38', 'Republican'),
    ('55039', 'STATE_LOWER', 'Assembly District 39', 'Democratic'),
    ('55039', 'STATE_LOWER', 'Assembly District 39', 'Republican'),
    ('55040', 'STATE_LOWER', 'Assembly District 40', 'Democratic'),
    ('55040', 'STATE_LOWER', 'Assembly District 40', 'Republican'),
    ('55041', 'STATE_LOWER', 'Assembly District 41', 'Democratic'),
    ('55041', 'STATE_LOWER', 'Assembly District 41', 'Republican'),
    ('55042', 'STATE_LOWER', 'Assembly District 42', 'Democratic'),
    ('55042', 'STATE_LOWER', 'Assembly District 42', 'Republican'),
    ('55043', 'STATE_LOWER', 'Assembly District 43', 'Democratic'),
    ('55043', 'STATE_LOWER', 'Assembly District 43', 'Republican'),
    ('55044', 'STATE_LOWER', 'Assembly District 44', 'Democratic'),
    ('55044', 'STATE_LOWER', 'Assembly District 44', 'Republican'),
    ('55045', 'STATE_LOWER', 'Assembly District 45', 'Democratic'),
    ('55045', 'STATE_LOWER', 'Assembly District 45', 'Republican'),
    ('55046', 'STATE_LOWER', 'Assembly District 46', 'Democratic'),
    ('55046', 'STATE_LOWER', 'Assembly District 46', 'Republican'),
    ('55047', 'STATE_LOWER', 'Assembly District 47', 'Democratic'),
    ('55047', 'STATE_LOWER', 'Assembly District 47', 'Republican'),
    ('55048', 'STATE_LOWER', 'Assembly District 48', 'Democratic'),
    ('55048', 'STATE_LOWER', 'Assembly District 48', 'Republican'),
    ('55049', 'STATE_LOWER', 'Assembly District 49', 'Democratic'),
    ('55049', 'STATE_LOWER', 'Assembly District 49', 'Republican'),
    ('55050', 'STATE_LOWER', 'Assembly District 50', 'Democratic'),
    ('55050', 'STATE_LOWER', 'Assembly District 50', 'Republican'),
    ('55051', 'STATE_LOWER', 'Assembly District 51', 'Democratic'),
    ('55051', 'STATE_LOWER', 'Assembly District 51', 'Republican'),
    ('55052', 'STATE_LOWER', 'Assembly District 52', 'Democratic'),
    ('55052', 'STATE_LOWER', 'Assembly District 52', 'Republican'),
    ('55053', 'STATE_LOWER', 'Assembly District 53', 'Democratic'),
    ('55053', 'STATE_LOWER', 'Assembly District 53', 'Republican'),
    ('55054', 'STATE_LOWER', 'Assembly District 54', 'Democratic'),
    ('55054', 'STATE_LOWER', 'Assembly District 54', 'Republican'),
    ('55055', 'STATE_LOWER', 'Assembly District 55', 'Democratic'),
    ('55055', 'STATE_LOWER', 'Assembly District 55', 'Republican'),
    ('55056', 'STATE_LOWER', 'Assembly District 56', 'Democratic'),
    ('55056', 'STATE_LOWER', 'Assembly District 56', 'Republican'),
    ('55057', 'STATE_LOWER', 'Assembly District 57', 'Democratic'),
    ('55057', 'STATE_LOWER', 'Assembly District 57', 'Republican'),
    ('55058', 'STATE_LOWER', 'Assembly District 58', 'Democratic'),
    ('55058', 'STATE_LOWER', 'Assembly District 58', 'Republican'),
    ('55059', 'STATE_LOWER', 'Assembly District 59', 'Democratic'),
    ('55059', 'STATE_LOWER', 'Assembly District 59', 'Republican'),
    ('55060', 'STATE_LOWER', 'Assembly District 60', 'Republican'),
    ('55061', 'STATE_LOWER', 'Assembly District 61', 'Democratic'),
    ('55061', 'STATE_LOWER', 'Assembly District 61', 'Republican'),
    ('55062', 'STATE_LOWER', 'Assembly District 62', 'Democratic'),
    ('55062', 'STATE_LOWER', 'Assembly District 62', 'Republican'),
    ('55063', 'STATE_LOWER', 'Assembly District 63', 'Democratic'),
    ('55063', 'STATE_LOWER', 'Assembly District 63', 'Republican'),
    ('55064', 'STATE_LOWER', 'Assembly District 64', 'Democratic'),
    ('55064', 'STATE_LOWER', 'Assembly District 64', 'Republican'),
    ('55065', 'STATE_LOWER', 'Assembly District 65', 'Democratic'),
    ('55065', 'STATE_LOWER', 'Assembly District 65', 'Republican'),
    ('55066', 'STATE_LOWER', 'Assembly District 66', 'Democratic'),
    ('55066', 'STATE_LOWER', 'Assembly District 66', 'Republican'),
    ('55067', 'STATE_LOWER', 'Assembly District 67', 'Democratic'),
    ('55067', 'STATE_LOWER', 'Assembly District 67', 'Republican'),
    ('55068', 'STATE_LOWER', 'Assembly District 68', 'Democratic'),
    ('55068', 'STATE_LOWER', 'Assembly District 68', 'Republican'),
    ('55069', 'STATE_LOWER', 'Assembly District 69', 'Democratic'),
    ('55069', 'STATE_LOWER', 'Assembly District 69', 'Republican'),
    ('55070', 'STATE_LOWER', 'Assembly District 70', 'Democratic'),
    ('55070', 'STATE_LOWER', 'Assembly District 70', 'Republican'),
    ('55071', 'STATE_LOWER', 'Assembly District 71', 'Democratic'),
    ('55071', 'STATE_LOWER', 'Assembly District 71', 'Republican'),
    ('55072', 'STATE_LOWER', 'Assembly District 72', 'Democratic'),
    ('55072', 'STATE_LOWER', 'Assembly District 72', 'Republican'),
    ('55073', 'STATE_LOWER', 'Assembly District 73', 'Democratic'),
    ('55073', 'STATE_LOWER', 'Assembly District 73', 'Republican'),
    ('55074', 'STATE_LOWER', 'Assembly District 74', 'Democratic'),
    ('55074', 'STATE_LOWER', 'Assembly District 74', 'Republican'),
    ('55075', 'STATE_LOWER', 'Assembly District 75', 'Democratic'),
    ('55075', 'STATE_LOWER', 'Assembly District 75', 'Republican'),
    ('55076', 'STATE_LOWER', 'Assembly District 76', 'Democratic'),
    ('55076', 'STATE_LOWER', 'Assembly District 76', 'Republican'),
    ('55077', 'STATE_LOWER', 'Assembly District 77', 'Democratic'),
    ('55077', 'STATE_LOWER', 'Assembly District 77', 'Republican'),
    ('55078', 'STATE_LOWER', 'Assembly District 78', 'Democratic'),
    ('55078', 'STATE_LOWER', 'Assembly District 78', 'Republican'),
    ('55079', 'STATE_LOWER', 'Assembly District 79', 'Democratic'),
    ('55079', 'STATE_LOWER', 'Assembly District 79', 'Republican'),
    ('55080', 'STATE_LOWER', 'Assembly District 80', 'Democratic'),
    ('55080', 'STATE_LOWER', 'Assembly District 80', 'Republican'),
    ('55081', 'STATE_LOWER', 'Assembly District 81', 'Democratic'),
    ('55081', 'STATE_LOWER', 'Assembly District 81', 'Republican'),
    ('55082', 'STATE_LOWER', 'Assembly District 82', 'Democratic'),
    ('55082', 'STATE_LOWER', 'Assembly District 82', 'Republican'),
    ('55083', 'STATE_LOWER', 'Assembly District 83', 'Republican'),
    ('55084', 'STATE_LOWER', 'Assembly District 84', 'Republican'),
    ('55085', 'STATE_LOWER', 'Assembly District 85', 'Democratic'),
    ('55085', 'STATE_LOWER', 'Assembly District 85', 'Republican'),
    ('55086', 'STATE_LOWER', 'Assembly District 86', 'Democratic'),
    ('55086', 'STATE_LOWER', 'Assembly District 86', 'Republican'),
    ('55087', 'STATE_LOWER', 'Assembly District 87', 'Democratic'),
    ('55087', 'STATE_LOWER', 'Assembly District 87', 'Republican'),
    ('55088', 'STATE_LOWER', 'Assembly District 88', 'Democratic'),
    ('55088', 'STATE_LOWER', 'Assembly District 88', 'Republican'),
    ('55089', 'STATE_LOWER', 'Assembly District 89', 'Democratic'),
    ('55089', 'STATE_LOWER', 'Assembly District 89', 'Republican'),
    ('55090', 'STATE_LOWER', 'Assembly District 90', 'Democratic'),
    ('55090', 'STATE_LOWER', 'Assembly District 90', 'Republican'),
    ('55091', 'STATE_LOWER', 'Assembly District 91', 'Democratic'),
    ('55091', 'STATE_LOWER', 'Assembly District 91', 'Republican'),
    ('55092', 'STATE_LOWER', 'Assembly District 92', 'Democratic'),
    ('55092', 'STATE_LOWER', 'Assembly District 92', 'Republican'),
    ('55093', 'STATE_LOWER', 'Assembly District 93', 'Democratic'),
    ('55093', 'STATE_LOWER', 'Assembly District 93', 'Republican'),
    ('55094', 'STATE_LOWER', 'Assembly District 94', 'Democratic'),
    ('55094', 'STATE_LOWER', 'Assembly District 94', 'Republican'),
    ('55095', 'STATE_LOWER', 'Assembly District 95', 'Democratic'),
    ('55095', 'STATE_LOWER', 'Assembly District 95', 'Republican'),
    ('55096', 'STATE_LOWER', 'Assembly District 96', 'Democratic'),
    ('55096', 'STATE_LOWER', 'Assembly District 96', 'Republican'),
    ('55097', 'STATE_LOWER', 'Assembly District 97', 'Republican'),
    ('55098', 'STATE_LOWER', 'Assembly District 98', 'Democratic'),
    ('55098', 'STATE_LOWER', 'Assembly District 98', 'Republican'),
    ('55099', 'STATE_LOWER', 'Assembly District 99', 'Republican'),
    ('55001', 'STATE_UPPER', 'State Senate District 1', 'Republican'),
    ('55003', 'STATE_UPPER', 'State Senate District 3', 'Democratic'),
    ('55005', 'STATE_UPPER', 'State Senate District 5', 'Democratic'),
    ('55005', 'STATE_UPPER', 'State Senate District 5', 'Republican'),
    ('55007', 'STATE_UPPER', 'State Senate District 7', 'Democratic'),
    ('55007', 'STATE_UPPER', 'State Senate District 7', 'Republican'),
    ('55009', 'STATE_UPPER', 'State Senate District 9', 'Republican'),
    ('55011', 'STATE_UPPER', 'State Senate District 11', 'Democratic'),
    ('55011', 'STATE_UPPER', 'State Senate District 11', 'Republican'),
    ('55013', 'STATE_UPPER', 'State Senate District 13', 'Democratic'),
    ('55013', 'STATE_UPPER', 'State Senate District 13', 'Republican'),
    ('55015', 'STATE_UPPER', 'State Senate District 15', 'Democratic'),
    ('55015', 'STATE_UPPER', 'State Senate District 15', 'Republican'),
    ('55017', 'STATE_UPPER', 'State Senate District 17', 'Democratic'),
    ('55017', 'STATE_UPPER', 'State Senate District 17', 'Republican'),
    ('55019', 'STATE_UPPER', 'State Senate District 19', 'Democratic'),
    ('55019', 'STATE_UPPER', 'State Senate District 19', 'Republican'),
    ('55021', 'STATE_UPPER', 'State Senate District 21', 'Democratic'),
    ('55021', 'STATE_UPPER', 'State Senate District 21', 'Republican'),
    ('55023', 'STATE_UPPER', 'State Senate District 23', 'Democratic'),
    ('55023', 'STATE_UPPER', 'State Senate District 23', 'Republican'),
    ('55025', 'STATE_UPPER', 'State Senate District 25', 'Democratic'),
    ('55025', 'STATE_UPPER', 'State Senate District 25', 'Republican'),
    ('55027', 'STATE_UPPER', 'State Senate District 27', 'Democratic'),
    ('55029', 'STATE_UPPER', 'State Senate District 29', 'Democratic'),
    ('55029', 'STATE_UPPER', 'State Senate District 29', 'Republican'),
    ('55031', 'STATE_UPPER', 'State Senate District 31', 'Democratic'),
    ('55031', 'STATE_UPPER', 'State Senate District 31', 'Republican'),
    ('55033', 'STATE_UPPER', 'State Senate District 33', 'Democratic'),
    ('55033', 'STATE_UPPER', 'State Senate District 33', 'Republican')
  ) AS v(geo_id, district_type, position_name, primary_party)
JOIN essentials.elections el ON el.name = 'WI 2026 Partisan Primary'
JOIN essentials.districts d ON d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = 'wi'
JOIN essentials.offices o ON o.district_id = d.id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
   WHERE r.election_id = el.id AND r.office_id = o.id
     AND coalesce(r.primary_party,'') = v.primary_party
);

-- ── 2. 116 general-election race shells (primary_party NULL, no candidates yet) ──
INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id, v.position_name, NULL, 1,
       'Nominees attached after the 2026-08-11 primary, together with the independents who bypass it'
FROM (VALUES
    ('55001'::text, 'STATE_LOWER'::text, 'Assembly District 1'::text),
    ('55002', 'STATE_LOWER', 'Assembly District 2'),
    ('55003', 'STATE_LOWER', 'Assembly District 3'),
    ('55004', 'STATE_LOWER', 'Assembly District 4'),
    ('55005', 'STATE_LOWER', 'Assembly District 5'),
    ('55006', 'STATE_LOWER', 'Assembly District 6'),
    ('55007', 'STATE_LOWER', 'Assembly District 7'),
    ('55008', 'STATE_LOWER', 'Assembly District 8'),
    ('55009', 'STATE_LOWER', 'Assembly District 9'),
    ('55010', 'STATE_LOWER', 'Assembly District 10'),
    ('55011', 'STATE_LOWER', 'Assembly District 11'),
    ('55012', 'STATE_LOWER', 'Assembly District 12'),
    ('55013', 'STATE_LOWER', 'Assembly District 13'),
    ('55014', 'STATE_LOWER', 'Assembly District 14'),
    ('55015', 'STATE_LOWER', 'Assembly District 15'),
    ('55016', 'STATE_LOWER', 'Assembly District 16'),
    ('55017', 'STATE_LOWER', 'Assembly District 17'),
    ('55018', 'STATE_LOWER', 'Assembly District 18'),
    ('55019', 'STATE_LOWER', 'Assembly District 19'),
    ('55020', 'STATE_LOWER', 'Assembly District 20'),
    ('55021', 'STATE_LOWER', 'Assembly District 21'),
    ('55022', 'STATE_LOWER', 'Assembly District 22'),
    ('55023', 'STATE_LOWER', 'Assembly District 23'),
    ('55024', 'STATE_LOWER', 'Assembly District 24'),
    ('55025', 'STATE_LOWER', 'Assembly District 25'),
    ('55026', 'STATE_LOWER', 'Assembly District 26'),
    ('55027', 'STATE_LOWER', 'Assembly District 27'),
    ('55028', 'STATE_LOWER', 'Assembly District 28'),
    ('55029', 'STATE_LOWER', 'Assembly District 29'),
    ('55030', 'STATE_LOWER', 'Assembly District 30'),
    ('55031', 'STATE_LOWER', 'Assembly District 31'),
    ('55032', 'STATE_LOWER', 'Assembly District 32'),
    ('55033', 'STATE_LOWER', 'Assembly District 33'),
    ('55034', 'STATE_LOWER', 'Assembly District 34'),
    ('55035', 'STATE_LOWER', 'Assembly District 35'),
    ('55036', 'STATE_LOWER', 'Assembly District 36'),
    ('55037', 'STATE_LOWER', 'Assembly District 37'),
    ('55038', 'STATE_LOWER', 'Assembly District 38'),
    ('55039', 'STATE_LOWER', 'Assembly District 39'),
    ('55040', 'STATE_LOWER', 'Assembly District 40'),
    ('55041', 'STATE_LOWER', 'Assembly District 41'),
    ('55042', 'STATE_LOWER', 'Assembly District 42'),
    ('55043', 'STATE_LOWER', 'Assembly District 43'),
    ('55044', 'STATE_LOWER', 'Assembly District 44'),
    ('55045', 'STATE_LOWER', 'Assembly District 45'),
    ('55046', 'STATE_LOWER', 'Assembly District 46'),
    ('55047', 'STATE_LOWER', 'Assembly District 47'),
    ('55048', 'STATE_LOWER', 'Assembly District 48'),
    ('55049', 'STATE_LOWER', 'Assembly District 49'),
    ('55050', 'STATE_LOWER', 'Assembly District 50'),
    ('55051', 'STATE_LOWER', 'Assembly District 51'),
    ('55052', 'STATE_LOWER', 'Assembly District 52'),
    ('55053', 'STATE_LOWER', 'Assembly District 53'),
    ('55054', 'STATE_LOWER', 'Assembly District 54'),
    ('55055', 'STATE_LOWER', 'Assembly District 55'),
    ('55056', 'STATE_LOWER', 'Assembly District 56'),
    ('55057', 'STATE_LOWER', 'Assembly District 57'),
    ('55058', 'STATE_LOWER', 'Assembly District 58'),
    ('55059', 'STATE_LOWER', 'Assembly District 59'),
    ('55060', 'STATE_LOWER', 'Assembly District 60'),
    ('55061', 'STATE_LOWER', 'Assembly District 61'),
    ('55062', 'STATE_LOWER', 'Assembly District 62'),
    ('55063', 'STATE_LOWER', 'Assembly District 63'),
    ('55064', 'STATE_LOWER', 'Assembly District 64'),
    ('55065', 'STATE_LOWER', 'Assembly District 65'),
    ('55066', 'STATE_LOWER', 'Assembly District 66'),
    ('55067', 'STATE_LOWER', 'Assembly District 67'),
    ('55068', 'STATE_LOWER', 'Assembly District 68'),
    ('55069', 'STATE_LOWER', 'Assembly District 69'),
    ('55070', 'STATE_LOWER', 'Assembly District 70'),
    ('55071', 'STATE_LOWER', 'Assembly District 71'),
    ('55072', 'STATE_LOWER', 'Assembly District 72'),
    ('55073', 'STATE_LOWER', 'Assembly District 73'),
    ('55074', 'STATE_LOWER', 'Assembly District 74'),
    ('55075', 'STATE_LOWER', 'Assembly District 75'),
    ('55076', 'STATE_LOWER', 'Assembly District 76'),
    ('55077', 'STATE_LOWER', 'Assembly District 77'),
    ('55078', 'STATE_LOWER', 'Assembly District 78'),
    ('55079', 'STATE_LOWER', 'Assembly District 79'),
    ('55080', 'STATE_LOWER', 'Assembly District 80'),
    ('55081', 'STATE_LOWER', 'Assembly District 81'),
    ('55082', 'STATE_LOWER', 'Assembly District 82'),
    ('55083', 'STATE_LOWER', 'Assembly District 83'),
    ('55084', 'STATE_LOWER', 'Assembly District 84'),
    ('55085', 'STATE_LOWER', 'Assembly District 85'),
    ('55086', 'STATE_LOWER', 'Assembly District 86'),
    ('55087', 'STATE_LOWER', 'Assembly District 87'),
    ('55088', 'STATE_LOWER', 'Assembly District 88'),
    ('55089', 'STATE_LOWER', 'Assembly District 89'),
    ('55090', 'STATE_LOWER', 'Assembly District 90'),
    ('55091', 'STATE_LOWER', 'Assembly District 91'),
    ('55092', 'STATE_LOWER', 'Assembly District 92'),
    ('55093', 'STATE_LOWER', 'Assembly District 93'),
    ('55094', 'STATE_LOWER', 'Assembly District 94'),
    ('55095', 'STATE_LOWER', 'Assembly District 95'),
    ('55096', 'STATE_LOWER', 'Assembly District 96'),
    ('55097', 'STATE_LOWER', 'Assembly District 97'),
    ('55098', 'STATE_LOWER', 'Assembly District 98'),
    ('55099', 'STATE_LOWER', 'Assembly District 99'),
    ('55001', 'STATE_UPPER', 'State Senate District 1'),
    ('55003', 'STATE_UPPER', 'State Senate District 3'),
    ('55005', 'STATE_UPPER', 'State Senate District 5'),
    ('55007', 'STATE_UPPER', 'State Senate District 7'),
    ('55009', 'STATE_UPPER', 'State Senate District 9'),
    ('55011', 'STATE_UPPER', 'State Senate District 11'),
    ('55013', 'STATE_UPPER', 'State Senate District 13'),
    ('55015', 'STATE_UPPER', 'State Senate District 15'),
    ('55017', 'STATE_UPPER', 'State Senate District 17'),
    ('55019', 'STATE_UPPER', 'State Senate District 19'),
    ('55021', 'STATE_UPPER', 'State Senate District 21'),
    ('55023', 'STATE_UPPER', 'State Senate District 23'),
    ('55025', 'STATE_UPPER', 'State Senate District 25'),
    ('55027', 'STATE_UPPER', 'State Senate District 27'),
    ('55029', 'STATE_UPPER', 'State Senate District 29'),
    ('55031', 'STATE_UPPER', 'State Senate District 31'),
    ('55033', 'STATE_UPPER', 'State Senate District 33')
  ) AS v(geo_id, district_type, position_name)
JOIN essentials.elections el ON el.name = 'WI 2026 Statewide General'
JOIN essentials.districts d ON d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = 'wi'
JOIN essentials.offices o ON o.district_id = d.id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.races r
   WHERE r.election_id = el.id AND r.office_id = o.id AND r.primary_party IS NULL
);

-- ── 3. 159 new challenger politician rows (no party stored) ──
INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, is_active)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true
FROM (VALUES
    (-5507001::bigint, 'Renee A. Paplham'::text, 'Renee'::text, 'Paplham'::text),
    (-5507002, 'Alicia Saunders', 'Alicia', 'Saunders'),
    (-5507003, 'Alexia Unertl', 'Alexia', 'Unertl'),
    (-5507004, 'Justin Schumacher', 'Justin', 'Schumacher'),
    (-5507005, 'David Schupbach', 'David', 'Schupbach'),
    (-5507006, 'Shirley Hinze', 'Shirley', 'Hinze'),
    (-5507007, 'Lee Whiting', 'Lee', 'Whiting'),
    (-5507008, 'Ismael Luna', 'Ismael', 'Luna'),
    (-5507009, 'Angel Sanchez', 'Angel', 'Sanchez'),
    (-5507010, 'Mimi Reza', 'Mimi', 'Reza'),
    (-5507011, 'Samuel Guerreo', 'Samuel', 'Guerreo'),
    (-5507012, 'Robert Longwell-Grice', 'Robert', 'Longwell-Grice'),
    (-5507013, 'Shandowlyon Reaves', 'Shandowlyon', 'Reaves'),
    (-5507014, 'Jordan Roman', 'Jordan', 'Roman'),
    (-5507015, 'David Sanchez', 'David', 'Sanchez'),
    (-5507016, 'Amy Zimmerman', 'Amy', 'Zimmerman'),
    (-5507017, 'Mike Morgan', 'Mike', 'Morgan'),
    (-5507018, 'AmyRose Murphy', 'AmyRose', 'Murphy'),
    (-5507019, 'Stephen Tryon', 'Stephen', 'Tryon'),
    (-5507020, 'Alciro Deacon', 'Alciro', 'Deacon'),
    (-5507021, 'Charlene Abughrin', 'Charlene', 'Abughrin'),
    (-5507022, 'Joel Richmond', 'Joel', 'Richmond'),
    (-5507023, 'Bridget Maniaci', 'Bridget', 'Maniaci'),
    (-5507024, 'Yasmine B. Outlaw', 'Yasmine', 'Outlaw'),
    (-5507025, 'Kyle Cleary', 'Kyle', 'Cleary'),
    (-5507026, 'David Liners', 'David', 'Liners'),
    (-5507027, 'Daniel J. Bukiewicz', 'Daniel', 'Bukiewicz'),
    (-5507028, 'Dylan Pfaffenbach', 'Dylan', 'Pfaffenbach'),
    (-5507029, 'Dana Glasstein', 'Dana', 'Glasstein'),
    (-5507030, 'Aleaner Pabonnie', 'Aleaner', 'Pabonnie'),
    (-5507031, 'Matt Brown', 'Matt', 'Brown'),
    (-5507032, 'Christopher Able', 'Christopher', 'Able'),
    (-5507033, 'Tyler Schneekloth', 'Tyler', 'Schneekloth'),
    (-5507034, 'John Belanger', 'John', 'Belanger'),
    (-5507035, 'James Brotz', 'James', 'Brotz'),
    (-5507036, 'Robin Lillesve', 'Robin', 'Lillesve'),
    (-5507037, 'Chris Danou', 'Chris', 'Danou'),
    (-5507038, 'Kevin Knoke', 'Kevin', 'Knoke'),
    (-5507039, 'John Perryman', 'John', 'Perryman'),
    (-5507040, 'Greg Miller', 'Greg', 'Miller'),
    (-5507041, 'Maria Elena Bisabarros', 'Maria', 'Bisabarros'),
    (-5507042, 'Rick Bailey', 'Rick', 'Bailey'),
    (-5507043, 'Rick Stacey', 'Rick', 'Stacey'),
    (-5507044, 'Steve Wicklund', 'Steve', 'Wicklund'),
    (-5507045, 'Merlin Van Buren', 'Merlin', 'Buren'),
    (-5507046, 'Elizabeth McCrank', 'Elizabeth', 'McCrank'),
    (-5507047, 'LaToya Bates', 'LaToya', 'Bates'),
    (-5507048, 'Steve Rydzewski', 'Steve', 'Rydzewski'),
    (-5507049, 'Terri Wenkman', 'Terri', 'Wenkman'),
    (-5507050, 'Michael Skivington', 'Michael', 'Skivington'),
    (-5507051, 'Julie Helmer', 'Julie', 'Helmer'),
    (-5507052, 'Zach Commons', 'Zach', 'Commons'),
    (-5507053, 'Keith F. Miller', 'Keith', 'Miller'),
    (-5507054, 'Paul McGraw', 'Paul', 'McGraw'),
    (-5507055, 'Ron Woodman', 'Ron', 'Woodman'),
    (-5507056, 'Jocelyn Jordan', 'Jocelyn', 'Jordan'),
    (-5507057, 'John Donohue', 'John', 'Donohue'),
    (-5507058, 'Sandy Bakk', 'Sandy', 'Bakk'),
    (-5507059, 'Mark Kjorlie', 'Mark', 'Kjorlie'),
    (-5507060, 'John Rindy', 'John', 'Rindy'),
    (-5507061, 'Josh Mittness', 'Josh', 'Mittness'),
    (-5507062, 'Bill Oemichen', 'Bill', 'Oemichen'),
    (-5507063, 'Bryna Caves', 'Bryna', 'Caves'),
    (-5507064, 'Jon Aleckson', 'Jon', 'Aleckson'),
    (-5507065, 'Ben Gruber', 'Ben', 'Gruber'),
    (-5507066, 'Reive Pullen', 'Reive', 'Pullen'),
    (-5507067, 'Becky Nichols', 'Becky', 'Nichols'),
    (-5507068, 'David Daniels', 'David', 'Daniels'),
    (-5507069, 'Tim Paterson', 'Tim', 'Paterson'),
    (-5507070, 'Alex Corrigan', 'Alex', 'Corrigan'),
    (-5507071, 'Grace Abitz', 'Grace', 'Abitz'),
    (-5507072, 'Shawna Riley', 'Shawna', 'Riley'),
    (-5507073, 'Anthony W. Phillips', 'Anthony', 'Phillips'),
    (-5507074, 'Joey Marschall', 'Joey', 'Marschall'),
    (-5507075, 'Dylan Testin', 'Dylan', 'Testin'),
    (-5507076, 'Bill Lorge', 'Bill', 'Lorge'),
    (-5507077, 'Kevin Krentz', 'Kevin', 'Krentz'),
    (-5507078, 'Ed Delgado', 'Ed', 'Delgado'),
    (-5507079, 'Dennis D. Degenhardt', 'Dennis', 'Degenhardt'),
    (-5507080, 'Christopher D. Bossert', 'Christopher', 'Bossert'),
    (-5507081, 'Bernie Newman', 'Bernie', 'Newman'),
    (-5507082, 'Jack Holzman', 'Jack', 'Holzman'),
    (-5507083, 'Bradley Petersen', 'Bradley', 'Petersen'),
    (-5507084, 'Marty Ryan', 'Marty', 'Ryan'),
    (-5507085, 'Ben Brist', 'Ben', 'Brist'),
    (-5507086, 'Brian Bock', 'Brian', 'Bock'),
    (-5507087, 'Lawanda Chambers', 'Lawanda', 'Chambers'),
    (-5507088, 'Mike Bellagio', 'Mike', 'Bellagio'),
    (-5507089, 'Eddie Phanichkul', 'Eddie', 'Phanichkul'),
    (-5507090, 'Ed Hibsch', 'Ed', 'Hibsch'),
    (-5507091, 'Valerie Kretchmer', 'Valerie', 'Kretchmer'),
    (-5507092, 'Gina Cefalu Paulick', 'Gina', 'Paulick'),
    (-5507093, 'Indiana Thompson', 'Indiana', 'Thompson'),
    (-5507094, 'Elisha King', 'Elisha', 'King'),
    (-5507095, 'Roger Halls', 'Roger', 'Halls'),
    (-5507096, 'Stephanie Stuve Bodeen', 'Stephanie', 'Bodeen'),
    (-5507097, 'Jeff Disher', 'Jeff', 'Disher'),
    (-5507098, 'Christine Maltese', 'Christine', 'Maltese'),
    (-5507099, 'Frank Kostka', 'Frank', 'Kostka'),
    (-5507100, 'Paul Johnson', 'Paul', 'Johnson'),
    (-5507101, 'Scott Harbridge', 'Scott', 'Harbridge'),
    (-5507102, 'Keith Mogel', 'Keith', 'Mogel'),
    (-5507103, 'Isaia Ben-Ami', 'Isaia', 'Ben-Ami'),
    (-5507104, 'Dina Nina Martinez-Rutherford', 'Dina', 'Martinez-Rutherford'),
    (-5507105, 'Juliana Bennett', 'Juliana', 'Bennett'),
    (-5507106, 'Zoe Sullivan', 'Zoe', 'Sullivan'),
    (-5507107, 'Tony Castañeda', 'Tony', 'Castañeda'),
    (-5507108, 'Nina Chat', 'Nina', 'Chat'),
    (-5507109, 'Jane McCormick', 'Jane', 'McCormick'),
    (-5507110, 'Henry Johnson', 'Henry', 'Johnson'),
    (-5507111, 'John Fons', 'John', 'Fons'),
    (-5507112, 'Simran Arora', 'Simran', 'Arora'),
    (-5507113, 'Mark S. Maier', 'Mark', 'Maier'),
    (-5507114, 'Rico Camacho', 'Rico', 'Camacho'),
    (-5507115, 'Bryson Reyes', 'Bryson', 'Reyes'),
    (-5507116, 'John Kroll', 'John', 'Kroll'),
    (-5507117, 'Andy Wuethrich', 'Andy', 'Wuethrich'),
    (-5507118, 'Bob Look', 'Bob', 'Look'),
    (-5507119, 'Brandy Tollefson', 'Brandy', 'Tollefson'),
    (-5507120, 'Bobby R. Lindsey', 'Bobby', 'Lindsey'),
    (-5507121, 'Jessica Henderson', 'Jessica', 'Henderson'),
    (-5507122, 'Bruce Stabenow', 'Bruce', 'Stabenow'),
    (-5507123, 'Mel M. Marin', 'Mel', 'Marin'),
    (-5507124, 'Jeremiah Fredrickson', 'Jeremiah', 'Fredrickson'),
    (-5507125, 'Michael Ayala', 'Michael', 'Ayala'),
    (-5507126, 'Keith Purnell', 'Keith', 'Purnell'),
    (-5507127, 'Cedric Schnitzler', 'Cedric', 'Schnitzler'),
    (-5507128, 'Jim Green', 'Jim', 'Green'),
    (-5507129, 'Matt Philibert', 'Matt', 'Philibert'),
    (-5507130, 'Barbara Bittner', 'Barbara', 'Bittner'),
    (-5507131, 'Jacob VandenPlas', 'Jacob', 'VandenPlas'),
    (-5507132, 'Katie Baney', 'Katie', 'Baney'),
    (-5507133, 'Nic Cravillion', 'Nic', 'Cravillion'),
    (-5507134, 'Robyn Vining', 'Robyn', 'Vining'),
    (-5507135, 'Mike Roberts', 'Mike', 'Roberts'),
    (-5507136, 'Mike Moeller', 'Mike', 'Moeller'),
    (-5507137, 'Amy Binsfeld', 'Amy', 'Binsfeld'),
    (-5507138, 'Steven J. Doelder', 'Steven', 'Doelder'),
    (-5507139, 'Adam Duda', 'Adam', 'Duda'),
    (-5507140, 'Sandy Wiedmeyer', 'Sandy', 'Wiedmeyer'),
    (-5507141, 'Ellen Schutt', 'Ellen', 'Schutt'),
    (-5507142, 'Nick Polce', 'Nick', 'Polce'),
    (-5507143, 'Sasha Ripley', 'Sasha', 'Ripley'),
    (-5507144, 'Scott Fleming', 'Scott', 'Fleming'),
    (-5507145, 'Jenna Jacobson', 'Jenna', 'Jacobson'),
    (-5507146, 'Lisa Rose White', 'Lisa', 'White'),
    (-5507147, 'Corrine Hendrickson', 'Corrine', 'Hendrickson'),
    (-5507148, 'Emily Daniels Tseffos', 'Emily', 'Tseffos'),
    (-5507149, 'Trevor Jung', 'Trevor', 'Jung'),
    (-5507150, 'Jim Croft', 'Jim', 'Croft'),
    (-5507151, 'Jeff Foster', 'Jeff', 'Foster'),
    (-5507152, 'Richard Pulcher', 'Richard', 'Pulcher'),
    (-5507153, 'Romaine Robert Quinn', 'Romaine', 'Quinn'),
    (-5507154, 'Charly Ray', 'Charly', 'Ray'),
    (-5507155, 'Angie Sapik', 'Angie', 'Sapik'),
    (-5507156, 'Erik Severson', 'Erik', 'Severson'),
    (-5507157, 'Gillian Battino', 'Gillian', 'Battino'),
    (-5507158, 'Michele Magadance Skinner', 'Michele', 'Skinner'),
    (-5507159, 'Mike Van Someren', 'Mike', 'Someren')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id
);

-- ── 4. 256 race_candidates on the primary races ──
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT r.id, p.id, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active',
       CASE WHEN v.was_challenged
            THEN 'WEC Ballot Access Report 6.9.2026: status Challenged, approved at the 6/9/2026 WEC meeting (Diaz AD-21 was the only challenge sustained)'
            ELSE 'WEC Ballot Access Report 6.9.2026 (approved filers only)' END
FROM (VALUES
    ('55001'::text, 'STATE_LOWER'::text, 'Democratic'::text, -5507001::bigint, 'Renee A. Paplham'::text, 'Renee'::text, 'Paplham'::text, false, false),
    ('55001', 'STATE_LOWER', 'Republican', -5506001, 'Joel Kitchens', 'Joel', 'Kitchens', true, false),
    ('55002', 'STATE_LOWER', 'Democratic', -5507002, 'Alicia Saunders', 'Alicia', 'Saunders', false, false),
    ('55002', 'STATE_LOWER', 'Republican', -5506002, 'Shae Sortwell', 'Shae', 'Sortwell', true, false),
    ('55003', 'STATE_LOWER', 'Republican', -5506003, 'Ron Tusler', 'Ron', 'Tusler', true, false),
    ('55004', 'STATE_LOWER', 'Democratic', -5507003, 'Alexia Unertl', 'Alexia', 'Unertl', false, false),
    ('55004', 'STATE_LOWER', 'Republican', -5506004, 'David Steffen', 'David', 'Steffen', true, false),
    ('55005', 'STATE_LOWER', 'Democratic', -5507004, 'Justin Schumacher', 'Justin', 'Schumacher', false, false),
    ('55005', 'STATE_LOWER', 'Republican', -5506005, 'Joy Goeben', 'Joy', 'Goeben', true, false),
    ('55005', 'STATE_LOWER', 'Wisconsin Green', -5507005, 'David Schupbach', 'David', 'Schupbach', false, false),
    ('55006', 'STATE_LOWER', 'Democratic', -5507006, 'Shirley Hinze', 'Shirley', 'Hinze', false, false),
    ('55006', 'STATE_LOWER', 'Republican', -5506006, 'Elijah Behnke', 'Elijah', 'Behnke', true, false),
    ('55007', 'STATE_LOWER', 'Democratic', -5506007, 'Karen Kirsch', 'Karen', 'Kirsch', true, false),
    ('55007', 'STATE_LOWER', 'Republican', -5507007, 'Lee Whiting', 'Lee', 'Whiting', false, false),
    ('55008', 'STATE_LOWER', 'Democratic', -5506008, 'Sylvia Ortiz-Velez', 'Sylvia', 'Ortiz-Velez', true, false),
    ('55008', 'STATE_LOWER', 'Democratic', -5507008, 'Ismael Luna', 'Ismael', 'Luna', false, false),
    ('55008', 'STATE_LOWER', 'Republican', -5507009, 'Angel Sanchez', 'Angel', 'Sanchez', false, false),
    ('55009', 'STATE_LOWER', 'Democratic', -5506009, 'Priscilla A. Prado', 'Priscilla', 'Prado', true, false),
    ('55009', 'STATE_LOWER', 'Democratic', -5507010, 'Mimi Reza', 'Mimi', 'Reza', false, false),
    ('55009', 'STATE_LOWER', 'Republican', -5507011, 'Samuel Guerreo', 'Samuel', 'Guerreo', false, true),
    ('55010', 'STATE_LOWER', 'Democratic', -5506010, 'Darrin Madison', 'Darrin', 'Madison', true, false),
    ('55010', 'STATE_LOWER', 'Wisconsin Green', -5507012, 'Robert Longwell-Grice', 'Robert', 'Longwell-Grice', false, false),
    ('55011', 'STATE_LOWER', 'Democratic', -5506011, 'Sequanna Taylor', 'Sequanna', 'Taylor', true, false),
    ('55011', 'STATE_LOWER', 'Republican', -5507013, 'Shandowlyon Reaves', 'Shandowlyon', 'Reaves', false, false),
    ('55012', 'STATE_LOWER', 'Democratic', -5506012, 'Russell Antonio Goodwin, Sr.', 'Russell', 'Goodwin', true, true),
    ('55012', 'STATE_LOWER', 'Democratic', -5507014, 'Jordan Roman', 'Jordan', 'Roman', false, false),
    ('55013', 'STATE_LOWER', 'Democratic', -5507015, 'David Sanchez', 'David', 'Sanchez', false, false),
    ('55013', 'STATE_LOWER', 'Democratic', -5507016, 'Amy Zimmerman', 'Amy', 'Zimmerman', false, false),
    ('55013', 'STATE_LOWER', 'Republican', -5507017, 'Mike Morgan', 'Mike', 'Morgan', false, false),
    ('55014', 'STATE_LOWER', 'Democratic', -5506014, 'Angelito Tenorio', 'Angelito', 'Tenorio', true, false),
    ('55014', 'STATE_LOWER', 'Republican', -5507018, 'AmyRose Murphy', 'AmyRose', 'Murphy', false, false),
    ('55015', 'STATE_LOWER', 'Democratic', -5507019, 'Stephen Tryon', 'Stephen', 'Tryon', false, false),
    ('55015', 'STATE_LOWER', 'Republican', -5506015, 'Adam Neylon', 'Adam', 'Neylon', true, false),
    ('55016', 'STATE_LOWER', 'Democratic', -5506016, 'Kalan Haywood', 'Kalan', 'Haywood', true, false),
    ('55016', 'STATE_LOWER', 'Republican', -5507020, 'Alciro Deacon', 'Alciro', 'Deacon', false, false),
    ('55017', 'STATE_LOWER', 'Democratic', -5506017, 'Supreme Moore Omokunde', 'Supreme', 'Omokunde', true, false),
    ('55017', 'STATE_LOWER', 'Republican', -5507021, 'Charlene Abughrin', 'Charlene', 'Abughrin', false, false),
    ('55018', 'STATE_LOWER', 'Democratic', -5506018, 'Margaret Arney', 'Margaret', 'Arney', true, false),
    ('55018', 'STATE_LOWER', 'Republican', -5507022, 'Joel Richmond', 'Joel', 'Richmond', false, false),
    ('55019', 'STATE_LOWER', 'Democratic', -5506019, 'Ryan Clancy', 'Ryan', 'Clancy', true, false),
    ('55019', 'STATE_LOWER', 'Democratic', -5507023, 'Bridget Maniaci', 'Bridget', 'Maniaci', false, false),
    ('55019', 'STATE_LOWER', 'Republican', -5507024, 'Yasmine B. Outlaw', 'Yasmine', 'Outlaw', false, false),
    ('55020', 'STATE_LOWER', 'Democratic', -5506020, 'Christine M. Sinicki', 'Christine', 'Sinicki', true, false),
    ('55020', 'STATE_LOWER', 'Republican', -5507025, 'Kyle Cleary', 'Kyle', 'Cleary', false, false),
    ('55021', 'STATE_LOWER', 'Democratic', -5507026, 'David Liners', 'David', 'Liners', false, false),
    ('55021', 'STATE_LOWER', 'Democratic', -5507027, 'Daniel J. Bukiewicz', 'Daniel', 'Bukiewicz', false, false),
    ('55021', 'STATE_LOWER', 'Republican', -5507028, 'Dylan Pfaffenbach', 'Dylan', 'Pfaffenbach', false, false),
    ('55022', 'STATE_LOWER', 'Democratic', -5507029, 'Dana Glasstein', 'Dana', 'Glasstein', false, false),
    ('55022', 'STATE_LOWER', 'Republican', -5506022, 'Paul Melotik', 'Paul', 'Melotik', true, false),
    ('55023', 'STATE_LOWER', 'Democratic', -5506023, 'Deb Andraca', 'Deb', 'Andraca', true, false),
    ('55023', 'STATE_LOWER', 'Republican', -5507030, 'Aleaner Pabonnie', 'Aleaner', 'Pabonnie', false, false),
    ('55024', 'STATE_LOWER', 'Democratic', -5507031, 'Matt Brown', 'Matt', 'Brown', false, false),
    ('55024', 'STATE_LOWER', 'Republican', -5506024, 'Dan Knodl', 'Dan', 'Knodl', true, false),
    ('55025', 'STATE_LOWER', 'Democratic', -5507032, 'Christopher Able', 'Christopher', 'Able', false, false),
    ('55025', 'STATE_LOWER', 'Republican', -5506025, 'Paul Tittl', 'Paul', 'Tittl', true, false),
    ('55026', 'STATE_LOWER', 'Democratic', -5506026, 'Joe Sheehan', 'Joe', 'Sheehan', true, false),
    ('55026', 'STATE_LOWER', 'Republican', -5507033, 'Tyler Schneekloth', 'Tyler', 'Schneekloth', false, false),
    ('55026', 'STATE_LOWER', 'Republican', -5507034, 'John Belanger', 'John', 'Belanger', false, false),
    ('55026', 'STATE_LOWER', 'Republican', -5507035, 'James Brotz', 'James', 'Brotz', false, false),
    ('55027', 'STATE_LOWER', 'Republican', -5506027, 'Lindee Brill', 'Lindee', 'Brill', true, false),
    ('55028', 'STATE_LOWER', 'Democratic', -5507036, 'Robin Lillesve', 'Robin', 'Lillesve', false, false),
    ('55028', 'STATE_LOWER', 'Republican', -5506028, 'Rob Kreibich', 'Rob', 'Kreibich', true, false),
    ('55029', 'STATE_LOWER', 'Democratic', -5507037, 'Chris Danou', 'Chris', 'Danou', false, false),
    ('55029', 'STATE_LOWER', 'Republican', -5506029, 'Treig Pronschinske', 'Treig', 'Pronschinske', true, false),
    ('55030', 'STATE_LOWER', 'Democratic', -5507038, 'Kevin Knoke', 'Kevin', 'Knoke', false, false),
    ('55030', 'STATE_LOWER', 'Republican', -5506030, 'Shannon Zimmerman', 'Shannon', 'Zimmerman', true, false),
    ('55031', 'STATE_LOWER', 'Democratic', -5507039, 'John Perryman', 'John', 'Perryman', false, false),
    ('55031', 'STATE_LOWER', 'Republican', -5506031, 'Tyler August', 'Tyler', 'August', true, false),
    ('55032', 'STATE_LOWER', 'Democratic', -5507040, 'Greg Miller', 'Greg', 'Miller', false, false),
    ('55032', 'STATE_LOWER', 'Republican', -5506032, 'Amanda Nedweski', 'Amanda', 'Nedweski', true, false),
    ('55033', 'STATE_LOWER', 'Democratic', -5507041, 'Maria Elena Bisabarros', 'Maria', 'Bisabarros', false, false),
    ('55033', 'STATE_LOWER', 'Democratic', -5507042, 'Rick Bailey', 'Rick', 'Bailey', false, false),
    ('55033', 'STATE_LOWER', 'Republican', -5507043, 'Rick Stacey', 'Rick', 'Stacey', false, false),
    ('55033', 'STATE_LOWER', 'Republican', -5507044, 'Steve Wicklund', 'Steve', 'Wicklund', false, false),
    ('55034', 'STATE_LOWER', 'Democratic', -5507045, 'Merlin Van Buren', 'Merlin', 'Buren', false, false),
    ('55034', 'STATE_LOWER', 'Republican', -5506034, 'Rob Swearingen', 'Rob', 'Swearingen', true, false),
    ('55035', 'STATE_LOWER', 'Democratic', -5507046, 'Elizabeth McCrank', 'Elizabeth', 'McCrank', false, false),
    ('55035', 'STATE_LOWER', 'Republican', -5506035, 'Calvin Callahan', 'Calvin', 'Callahan', true, false),
    ('55036', 'STATE_LOWER', 'Republican', -5506036, 'Jeffrey L. Mursau', 'Jeffrey', 'Mursau', true, false),
    ('55037', 'STATE_LOWER', 'Democratic', -5507047, 'LaToya Bates', 'LaToya', 'Bates', false, false),
    ('55037', 'STATE_LOWER', 'Republican', -5506037, 'Mark Born', 'Mark', 'Born', true, false),
    ('55037', 'STATE_LOWER', 'Republican', -5507048, 'Steve Rydzewski', 'Steve', 'Rydzewski', false, false),
    ('55038', 'STATE_LOWER', 'Democratic', -5507049, 'Terri Wenkman', 'Terri', 'Wenkman', false, false),
    ('55038', 'STATE_LOWER', 'Republican', -5506038, 'William Penterman', 'William', 'Penterman', true, false),
    ('55039', 'STATE_LOWER', 'Democratic', -5507050, 'Michael Skivington', 'Michael', 'Skivington', false, false),
    ('55039', 'STATE_LOWER', 'Republican', -5506039, 'Alex Dallman', 'Alex', 'Dallman', true, false),
    ('55040', 'STATE_LOWER', 'Democratic', -5506040, 'Karen DeSanto', 'Karen', 'DeSanto', true, false),
    ('55040', 'STATE_LOWER', 'Republican', -5507051, 'Julie Helmer', 'Julie', 'Helmer', false, false),
    ('55041', 'STATE_LOWER', 'Democratic', -5507052, 'Zach Commons', 'Zach', 'Commons', false, false),
    ('55041', 'STATE_LOWER', 'Republican', -5506041, 'Tony Kurtz', 'Tony', 'Kurtz', true, false),
    ('55042', 'STATE_LOWER', 'Democratic', -5506042, 'Maureen McCarville', 'Maureen', 'McCarville', true, false),
    ('55042', 'STATE_LOWER', 'Republican', -5507053, 'Keith F. Miller', 'Keith', 'Miller', false, false),
    ('55043', 'STATE_LOWER', 'Democratic', -5506043, 'Brienne Brown', 'Brienne', 'Brown', true, false),
    ('55043', 'STATE_LOWER', 'Republican', -5507054, 'Paul McGraw', 'Paul', 'McGraw', false, false),
    ('55044', 'STATE_LOWER', 'Democratic', -5506044, 'Ann Roe', 'Ann', 'Roe', true, false),
    ('55044', 'STATE_LOWER', 'Republican', -5507055, 'Ron Woodman', 'Ron', 'Woodman', false, false),
    ('55045', 'STATE_LOWER', 'Democratic', -5506045, 'Clinton Anderson', 'Clinton', 'Anderson', true, false),
    ('55045', 'STATE_LOWER', 'Republican', -5507056, 'Jocelyn Jordan', 'Jocelyn', 'Jordan', false, false),
    ('55046', 'STATE_LOWER', 'Democratic', -5506046, 'Joan Fitzgerald', 'Joan', 'Fitzgerald', true, false),
    ('55046', 'STATE_LOWER', 'Republican', -5507057, 'John Donohue', 'John', 'Donohue', false, false),
    ('55047', 'STATE_LOWER', 'Democratic', -5506047, 'Randy Udell', 'Randy', 'Udell', true, false),
    ('55047', 'STATE_LOWER', 'Republican', -5507058, 'Sandy Bakk', 'Sandy', 'Bakk', false, false),
    ('55048', 'STATE_LOWER', 'Democratic', -5506048, 'Andrew Hysell', 'Andrew', 'Hysell', true, false),
    ('55048', 'STATE_LOWER', 'Republican', -5507059, 'Mark Kjorlie', 'Mark', 'Kjorlie', false, false),
    ('55049', 'STATE_LOWER', 'Democratic', -5507060, 'John Rindy', 'John', 'Rindy', false, false),
    ('55049', 'STATE_LOWER', 'Republican', -5506049, 'Travis Tranel', 'Travis', 'Tranel', true, false),
    ('55050', 'STATE_LOWER', 'Democratic', -5507061, 'Josh Mittness', 'Josh', 'Mittness', false, false),
    ('55050', 'STATE_LOWER', 'Democratic', -5507062, 'Bill Oemichen', 'Bill', 'Oemichen', false, false),
    ('55050', 'STATE_LOWER', 'Democratic', -5507063, 'Bryna Caves', 'Bryna', 'Caves', false, false),
    ('55050', 'STATE_LOWER', 'Republican', -5507064, 'Jon Aleckson', 'Jon', 'Aleckson', false, false),
    ('55051', 'STATE_LOWER', 'Democratic', -5507065, 'Ben Gruber', 'Ben', 'Gruber', false, false),
    ('55051', 'STATE_LOWER', 'Republican', -5506051, 'Todd Novak', 'Todd', 'Novak', true, false),
    ('55052', 'STATE_LOWER', 'Democratic', -5506052, 'Lee Snodgrass', 'Lee', 'Snodgrass', true, false),
    ('55052', 'STATE_LOWER', 'Republican', -5507066, 'Reive Pullen', 'Reive', 'Pullen', false, false),
    ('55053', 'STATE_LOWER', 'Democratic', -5507067, 'Becky Nichols', 'Becky', 'Nichols', false, false),
    ('55053', 'STATE_LOWER', 'Republican', -5507068, 'David Daniels', 'David', 'Daniels', false, false),
    ('55054', 'STATE_LOWER', 'Democratic', -5506054, 'Lori Palmeri', 'Lori', 'Palmeri', true, false),
    ('55054', 'STATE_LOWER', 'Republican', -5507069, 'Tim Paterson', 'Tim', 'Paterson', false, false),
    ('55055', 'STATE_LOWER', 'Democratic', -5507070, 'Alex Corrigan', 'Alex', 'Corrigan', false, false),
    ('55055', 'STATE_LOWER', 'Republican', -5506055, 'Nate Gustafson', 'Nate', 'Gustafson', true, false),
    ('55056', 'STATE_LOWER', 'Democratic', -5507071, 'Grace Abitz', 'Grace', 'Abitz', false, false),
    ('55056', 'STATE_LOWER', 'Democratic', -5507072, 'Shawna Riley', 'Shawna', 'Riley', false, false),
    ('55056', 'STATE_LOWER', 'Republican', -5507073, 'Anthony W. Phillips', 'Anthony', 'Phillips', false, false),
    ('55057', 'STATE_LOWER', 'Democratic', -5507074, 'Joey Marschall', 'Joey', 'Marschall', false, false),
    ('55057', 'STATE_LOWER', 'Republican', -5507075, 'Dylan Testin', 'Dylan', 'Testin', false, false),
    ('55057', 'STATE_LOWER', 'Republican', -5507076, 'Bill Lorge', 'Bill', 'Lorge', false, false),
    ('55057', 'STATE_LOWER', 'Republican', -5507077, 'Kevin Krentz', 'Kevin', 'Krentz', false, false),
    ('55057', 'STATE_LOWER', 'Republican', -5507078, 'Ed Delgado', 'Ed', 'Delgado', false, false),
    ('55058', 'STATE_LOWER', 'Democratic', -5507079, 'Dennis D. Degenhardt', 'Dennis', 'Degenhardt', false, false),
    ('55058', 'STATE_LOWER', 'Republican', -5507080, 'Christopher D. Bossert', 'Christopher', 'Bossert', false, false),
    ('55058', 'STATE_LOWER', 'Republican', -5507081, 'Bernie Newman', 'Bernie', 'Newman', false, false),
    ('55059', 'STATE_LOWER', 'Democratic', -5507082, 'Jack Holzman', 'Jack', 'Holzman', false, false),
    ('55059', 'STATE_LOWER', 'Republican', -5507083, 'Bradley Petersen', 'Bradley', 'Petersen', false, false),
    ('55060', 'STATE_LOWER', 'Republican', -5507084, 'Marty Ryan', 'Marty', 'Ryan', false, false),
    ('55061', 'STATE_LOWER', 'Democratic', -5507085, 'Ben Brist', 'Ben', 'Brist', false, false),
    ('55061', 'STATE_LOWER', 'Democratic', -5507086, 'Brian Bock', 'Brian', 'Bock', false, false),
    ('55061', 'STATE_LOWER', 'Democratic', -5507087, 'Lawanda Chambers', 'Lawanda', 'Chambers', false, false),
    ('55061', 'STATE_LOWER', 'Republican', -5506061, 'Bob Donovan', 'Bob', 'Donovan', true, false),
    ('55062', 'STATE_LOWER', 'Democratic', -5506062, 'Angelina M. Cruz', 'Angelina', 'Cruz', true, false),
    ('55062', 'STATE_LOWER', 'Republican', -5507088, 'Mike Bellagio', 'Mike', 'Bellagio', false, false),
    ('55063', 'STATE_LOWER', 'Democratic', -5507089, 'Eddie Phanichkul', 'Eddie', 'Phanichkul', false, false),
    ('55063', 'STATE_LOWER', 'Republican', -5506063, 'Robert Wittke', 'Robert', 'Wittke', true, false),
    ('55064', 'STATE_LOWER', 'Democratic', -5506064, 'Tip McGuire', 'Tip', 'McGuire', true, false),
    ('55064', 'STATE_LOWER', 'Republican', -5507090, 'Ed Hibsch', 'Ed', 'Hibsch', false, false),
    ('55065', 'STATE_LOWER', 'Democratic', -5506065, 'Ben DeSmidt', 'Ben', 'DeSmidt', true, false),
    ('55065', 'STATE_LOWER', 'Republican', -5507091, 'Valerie Kretchmer', 'Valerie', 'Kretchmer', false, false),
    ('55066', 'STATE_LOWER', 'Democratic', -5506066, 'Greta Neubauer', 'Greta', 'Neubauer', true, false),
    ('55066', 'STATE_LOWER', 'Republican', -5507092, 'Gina Cefalu Paulick', 'Gina', 'Paulick', false, false),
    ('55067', 'STATE_LOWER', 'Democratic', -5507093, 'Indiana Thompson', 'Indiana', 'Thompson', false, false),
    ('55067', 'STATE_LOWER', 'Republican', -5506067, 'David Armstrong', 'David', 'Armstrong', true, false),
    ('55068', 'STATE_LOWER', 'Democratic', -5507094, 'Elisha King', 'Elisha', 'King', false, false),
    ('55068', 'STATE_LOWER', 'Republican', -5506068, 'Rob Summerfield', 'Rob', 'Summerfield', true, false),
    ('55069', 'STATE_LOWER', 'Democratic', -5507095, 'Roger Halls', 'Roger', 'Halls', false, false),
    ('55069', 'STATE_LOWER', 'Republican', -5506069, 'Karen Hurd', 'Karen', 'Hurd', true, false),
    ('55070', 'STATE_LOWER', 'Democratic', -5507096, 'Stephanie Stuve Bodeen', 'Stephanie', 'Bodeen', false, false),
    ('55070', 'STATE_LOWER', 'Republican', -5506070, 'Nancy VanderMeer', 'Nancy', 'VanderMeer', true, false),
    ('55071', 'STATE_LOWER', 'Democratic', -5506071, 'Vinnie Miresse', 'Vinnie', 'Miresse', true, false),
    ('55071', 'STATE_LOWER', 'Republican', -5507097, 'Jeff Disher', 'Jeff', 'Disher', false, true),
    ('55072', 'STATE_LOWER', 'Democratic', -5507098, 'Christine Maltese', 'Christine', 'Maltese', false, false),
    ('55072', 'STATE_LOWER', 'Republican', -5506072, 'Scott Krug', 'Scott', 'Krug', true, false),
    ('55073', 'STATE_LOWER', 'Democratic', -5506073, 'Angela Stroud', 'Angela', 'Stroud', true, false),
    ('55073', 'STATE_LOWER', 'Republican', -5507099, 'Frank Kostka', 'Frank', 'Kostka', false, false),
    ('55074', 'STATE_LOWER', 'Democratic', -5507100, 'Paul Johnson', 'Paul', 'Johnson', false, false),
    ('55074', 'STATE_LOWER', 'Republican', -5507101, 'Scott Harbridge', 'Scott', 'Harbridge', false, false),
    ('55074', 'STATE_LOWER', 'Republican', -5506074, 'Chanz Green', 'Chanz', 'Green', true, false),
    ('55075', 'STATE_LOWER', 'Democratic', -5507102, 'Keith Mogel', 'Keith', 'Mogel', false, false),
    ('55075', 'STATE_LOWER', 'Republican', -5506075, 'Duke Tucker', 'Duke', 'Tucker', true, false),
    ('55076', 'STATE_LOWER', 'Democratic', -5507103, 'Isaia Ben-Ami', 'Isaia', 'Ben-Ami', false, false),
    ('55076', 'STATE_LOWER', 'Democratic', -5507104, 'Dina Nina Martinez-Rutherford', 'Dina', 'Martinez-Rutherford', false, false),
    ('55076', 'STATE_LOWER', 'Democratic', -5507105, 'Juliana Bennett', 'Juliana', 'Bennett', false, false),
    ('55076', 'STATE_LOWER', 'Democratic', -5507106, 'Zoe Sullivan', 'Zoe', 'Sullivan', false, false),
    ('55076', 'STATE_LOWER', 'Democratic', -5507107, 'Tony Castañeda', 'Tony', 'Castañeda', false, true),
    ('55076', 'STATE_LOWER', 'Republican', -5507108, 'Nina Chat', 'Nina', 'Chat', false, false),
    ('55077', 'STATE_LOWER', 'Democratic', -5506077, 'Renuka Mayadev', 'Renuka', 'Mayadev', true, false),
    ('55077', 'STATE_LOWER', 'Republican', -5507109, 'Jane McCormick', 'Jane', 'McCormick', false, false),
    ('55078', 'STATE_LOWER', 'Democratic', -5506078, 'Shelia Stubbs', 'Shelia', 'Stubbs', true, false),
    ('55078', 'STATE_LOWER', 'Republican', -5507110, 'Henry Johnson', 'Henry', 'Johnson', false, false),
    ('55079', 'STATE_LOWER', 'Democratic', -5506079, 'Lisa Subeck', 'Lisa', 'Subeck', true, false),
    ('55079', 'STATE_LOWER', 'Republican', -5507111, 'John Fons', 'John', 'Fons', false, false),
    ('55080', 'STATE_LOWER', 'Democratic', -5506080, 'Mike Bare', 'Mike', 'Bare', true, false),
    ('55080', 'STATE_LOWER', 'Republican', -5507112, 'Simran Arora', 'Simran', 'Arora', false, false),
    ('55081', 'STATE_LOWER', 'Democratic', -5506081, 'Alex Joers', 'Alex', 'Joers', true, false),
    ('55081', 'STATE_LOWER', 'Republican', -5507113, 'Mark S. Maier', 'Mark', 'Maier', false, false),
    ('55082', 'STATE_LOWER', 'Democratic', -5507114, 'Rico Camacho', 'Rico', 'Camacho', false, false),
    ('55082', 'STATE_LOWER', 'Republican', -5507115, 'Bryson Reyes', 'Bryson', 'Reyes', false, false),
    ('55083', 'STATE_LOWER', 'Republican', -5506083, 'Dave Maxey', 'Dave', 'Maxey', true, false),
    ('55084', 'STATE_LOWER', 'Republican', -5506084, 'Chuck Wichgers', 'Chuck', 'Wichgers', true, false),
    ('55085', 'STATE_LOWER', 'Democratic', -5507116, 'John Kroll', 'John', 'Kroll', false, false),
    ('55085', 'STATE_LOWER', 'Republican', -5506085, 'Patrick Snyder', 'Patrick', 'Snyder', true, false),
    ('55086', 'STATE_LOWER', 'Democratic', -5507117, 'Andy Wuethrich', 'Andy', 'Wuethrich', false, false),
    ('55086', 'STATE_LOWER', 'Republican', -5506086, 'John Spiros', 'John', 'Spiros', true, false),
    ('55087', 'STATE_LOWER', 'Democratic', -5507118, 'Bob Look', 'Bob', 'Look', false, false),
    ('55087', 'STATE_LOWER', 'Republican', -5506087, 'Brent Jacobson', 'Brent', 'Jacobson', true, false),
    ('55088', 'STATE_LOWER', 'Democratic', -5507119, 'Brandy Tollefson', 'Brandy', 'Tollefson', false, false),
    ('55088', 'STATE_LOWER', 'Republican', -5506088, 'Ben Franklin', 'Ben', 'Franklin', true, false),
    ('55089', 'STATE_LOWER', 'Democratic', -5506089, 'Ryan Spaude', 'Ryan', 'Spaude', true, false),
    ('55089', 'STATE_LOWER', 'Republican', -5507120, 'Bobby R. Lindsey', 'Bobby', 'Lindsey', false, false),
    ('55090', 'STATE_LOWER', 'Democratic', -5506090, 'Amaad Rivera-Wagner', 'Amaad', 'Rivera-Wagner', true, false),
    ('55090', 'STATE_LOWER', 'Republican', -5507121, 'Jessica Henderson', 'Jessica', 'Henderson', false, true),
    ('55091', 'STATE_LOWER', 'Democratic', -5506091, 'Jodi Emerson', 'Jodi', 'Emerson', true, false),
    ('55091', 'STATE_LOWER', 'Republican', -5507122, 'Bruce Stabenow', 'Bruce', 'Stabenow', false, false),
    ('55092', 'STATE_LOWER', 'Democratic', -5507123, 'Mel M. Marin', 'Mel', 'Marin', false, false),
    ('55092', 'STATE_LOWER', 'Democratic', -5507124, 'Jeremiah Fredrickson', 'Jeremiah', 'Fredrickson', false, false),
    ('55092', 'STATE_LOWER', 'Republican', -5506092, 'Clint Moses', 'Clint', 'Moses', true, false),
    ('55093', 'STATE_LOWER', 'Democratic', -5506093, 'Christian Phelps', 'Christian', 'Phelps', true, false),
    ('55093', 'STATE_LOWER', 'Republican', -5507125, 'Michael Ayala', 'Michael', 'Ayala', false, false),
    ('55094', 'STATE_LOWER', 'Democratic', -5506094, 'Steve Doyle', 'Steve', 'Doyle', true, false),
    ('55094', 'STATE_LOWER', 'Republican', -5507126, 'Keith Purnell', 'Keith', 'Purnell', false, false),
    ('55095', 'STATE_LOWER', 'Democratic', -5506095, 'Jill Billings', 'Jill', 'Billings', true, false),
    ('55095', 'STATE_LOWER', 'Republican', -5507127, 'Cedric Schnitzler', 'Cedric', 'Schnitzler', false, false),
    ('55096', 'STATE_LOWER', 'Democratic', -5506096, 'Tara Johnson', 'Tara', 'Johnson', true, false),
    ('55096', 'STATE_LOWER', 'Republican', -5507128, 'Jim Green', 'Jim', 'Green', false, false),
    ('55097', 'STATE_LOWER', 'Republican', -5506097, 'Cindi Duchow', 'Cindi', 'Duchow', true, false),
    ('55098', 'STATE_LOWER', 'Democratic', -5507129, 'Matt Philibert', 'Matt', 'Philibert', false, false),
    ('55098', 'STATE_LOWER', 'Republican', -5506098, 'Jim Piwowarczyk', 'Jim', 'Piwowarczyk', true, false),
    ('55099', 'STATE_LOWER', 'Republican', -5506099, 'Barbara Dittrich', 'Barbara', 'Dittrich', true, false),
    ('55001', 'STATE_UPPER', 'Republican', -5507130, 'Barbara Bittner', 'Barbara', 'Bittner', false, false),
    ('55001', 'STATE_UPPER', 'Republican', -5507131, 'Jacob VandenPlas', 'Jacob', 'VandenPlas', false, false),
    ('55001', 'STATE_UPPER', 'Republican', -5507132, 'Katie Baney', 'Katie', 'Baney', false, false),
    ('55001', 'STATE_UPPER', 'Republican', -5507133, 'Nic Cravillion', 'Nic', 'Cravillion', false, false),
    ('55003', 'STATE_UPPER', 'Democratic', -5505003, 'Tim Carpenter', 'Tim', 'Carpenter', true, false),
    ('55005', 'STATE_UPPER', 'Democratic', -5507134, 'Robyn Vining', 'Robyn', 'Vining', false, false),
    ('55005', 'STATE_UPPER', 'Republican', -5507135, 'Mike Roberts', 'Mike', 'Roberts', false, false),
    ('55007', 'STATE_UPPER', 'Democratic', -5505007, 'Chris J. Larson', 'Chris', 'Larson', true, false),
    ('55007', 'STATE_UPPER', 'Republican', -5507136, 'Mike Moeller', 'Mike', 'Moeller', false, false),
    ('55009', 'STATE_UPPER', 'Republican', -5507137, 'Amy Binsfeld', 'Amy', 'Binsfeld', false, false),
    ('55011', 'STATE_UPPER', 'Democratic', -5507138, 'Steven J. Doelder', 'Steven', 'Doelder', false, false),
    ('55011', 'STATE_UPPER', 'Democratic', -5507139, 'Adam Duda', 'Adam', 'Duda', false, false),
    ('55011', 'STATE_UPPER', 'Republican', -5507140, 'Sandy Wiedmeyer', 'Sandy', 'Wiedmeyer', false, false),
    ('55011', 'STATE_UPPER', 'Republican', -5507141, 'Ellen Schutt', 'Ellen', 'Schutt', false, false),
    ('55011', 'STATE_UPPER', 'Republican', -5507142, 'Nick Polce', 'Nick', 'Polce', false, true),
    ('55013', 'STATE_UPPER', 'Democratic', -5507143, 'Sasha Ripley', 'Sasha', 'Ripley', false, false),
    ('55013', 'STATE_UPPER', 'Republican', -5505013, 'John Jagler', 'John', 'Jagler', true, false),
    ('55015', 'STATE_UPPER', 'Democratic', -5505015, 'Mark Spreitzer', 'Mark', 'Spreitzer', true, false),
    ('55015', 'STATE_UPPER', 'Republican', -5507144, 'Scott Fleming', 'Scott', 'Fleming', false, false),
    ('55017', 'STATE_UPPER', 'Democratic', -5507145, 'Jenna Jacobson', 'Jenna', 'Jacobson', false, false),
    ('55017', 'STATE_UPPER', 'Democratic', -5507146, 'Lisa Rose White', 'Lisa', 'White', false, false),
    ('55017', 'STATE_UPPER', 'Democratic', -5507147, 'Corrine Hendrickson', 'Corrine', 'Hendrickson', false, false),
    ('55017', 'STATE_UPPER', 'Republican', -5505017, 'Howard Marklein', 'Howard', 'Marklein', true, false),
    ('55019', 'STATE_UPPER', 'Democratic', -5507148, 'Emily Daniels Tseffos', 'Emily', 'Tseffos', false, false),
    ('55019', 'STATE_UPPER', 'Republican', -5505019, 'Rachael Ann Cabral-Guevara', 'Rachael', 'Cabral-Guevara', true, false),
    ('55021', 'STATE_UPPER', 'Democratic', -5507149, 'Trevor Jung', 'Trevor', 'Jung', false, false),
    ('55021', 'STATE_UPPER', 'Republican', -5507150, 'Jim Croft', 'Jim', 'Croft', false, false),
    ('55023', 'STATE_UPPER', 'Democratic', -5507151, 'Jeff Foster', 'Jeff', 'Foster', false, false),
    ('55023', 'STATE_UPPER', 'Democratic', -5507152, 'Richard Pulcher', 'Richard', 'Pulcher', false, false),
    ('55023', 'STATE_UPPER', 'Republican', -5507153, 'Romaine Robert Quinn', 'Romaine', 'Quinn', false, false),
    ('55025', 'STATE_UPPER', 'Democratic', -5507154, 'Charly Ray', 'Charly', 'Ray', false, false),
    ('55025', 'STATE_UPPER', 'Republican', -5507155, 'Angie Sapik', 'Angie', 'Sapik', false, false),
    ('55025', 'STATE_UPPER', 'Republican', -5507156, 'Erik Severson', 'Erik', 'Severson', false, false),
    ('55027', 'STATE_UPPER', 'Democratic', -5505027, 'Dianne Hesselbein', 'Dianne', 'Hesselbein', true, false),
    ('55029', 'STATE_UPPER', 'Democratic', -5507157, 'Gillian Battino', 'Gillian', 'Battino', false, false),
    ('55029', 'STATE_UPPER', 'Republican', -5505029, 'Cory Tomczyk', 'Cory', 'Tomczyk', true, false),
    ('55031', 'STATE_UPPER', 'Democratic', -5505031, 'Jeff Smith', 'Jeff', 'Smith', true, false),
    ('55031', 'STATE_UPPER', 'Republican', -5507158, 'Michele Magadance Skinner', 'Michele', 'Skinner', false, false),
    ('55033', 'STATE_UPPER', 'Democratic', -5507159, 'Mike Van Someren', 'Mike', 'Someren', false, false),
    ('55033', 'STATE_UPPER', 'Republican', -5505033, 'Chris Kapenga', 'Chris', 'Kapenga', true, false)
  ) AS v(geo_id, district_type, primary_party, external_id, full_name, first_name, last_name,
          is_incumbent, was_challenged)
JOIN essentials.elections el ON el.name = 'WI 2026 Partisan Primary'
JOIN essentials.districts d ON d.geo_id = v.geo_id AND d.district_type = v.district_type AND d.state = 'wi'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.races r ON r.election_id = el.id AND r.office_id = o.id
                       AND r.primary_party = v.primary_party
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
   WHERE rc.race_id = r.id AND lower(rc.full_name) = lower(v.full_name)
);

-- ── 5. Post-verify gate ──
DO $$
DECLARE n_prim int; n_gen int; n_cand int; n_unlinked int; n_badparty int; n_inc int;
BEGIN
  SELECT count(*) INTO n_prim FROM essentials.races r
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.state='wi'
     AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF n_prim <> 220 THEN
    RAISE EXCEPTION 'primary legislative races: got %, want 220 (is 1443 applied?)', n_prim;
  END IF;

  SELECT count(*) INTO n_gen FROM essentials.races r
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Statewide General' AND d.state='wi'
     AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF n_gen <> 116 THEN
    RAISE EXCEPTION 'general legislative races: got %, want 116', n_gen;
  END IF;

  SELECT count(*) INTO n_cand FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.state='wi'
     AND d.district_type IN ('STATE_UPPER','STATE_LOWER');
  IF n_cand <> 256 THEN
    RAISE EXCEPTION 'legislative primary candidates: got %, want 256', n_cand;
  END IF;

  -- every candidate must carry a politician_id
  SELECT count(*) INTO n_unlinked FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.state='wi'
     AND d.district_type IN ('STATE_UPPER','STATE_LOWER') AND rc.politician_id IS NULL;
  IF n_unlinked <> 0 THEN RAISE EXCEPTION '% legislative candidates unlinked', n_unlinked; END IF;

  -- antipartisan: no party may leak onto the new challenger rows
  SELECT count(*) INTO n_badparty FROM essentials.politicians
   WHERE external_id BETWEEN -5507159 AND -5507001 AND party IS NOT NULL;
  IF n_badparty <> 0 THEN RAISE EXCEPTION '% challenger rows carry a party', n_badparty; END IF;

  SELECT count(*) INTO n_inc FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id=rc.race_id
    JOIN essentials.elections e ON e.id=r.election_id
    JOIN essentials.offices o ON o.id=r.office_id
    JOIN essentials.districts d ON d.id=o.district_id
   WHERE e.name='WI 2026 Partisan Primary' AND d.state='wi'
     AND d.district_type IN ('STATE_UPPER','STATE_LOWER') AND rc.is_incumbent;
  IF n_inc <> 97 THEN
    RAISE EXCEPTION 'incumbent candidates: got %, want 97', n_inc;
  END IF;

  RAISE NOTICE 'WI legislative races verify PASSED: 220 primary + 116 general races, 256 candidates, 0 unlinked.';
END $$;

COMMIT;
