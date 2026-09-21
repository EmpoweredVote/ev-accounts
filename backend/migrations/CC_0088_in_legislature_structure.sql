-- CC_0088_in_legislature_structure.sql
-- Knight Foundation program, wave IN-2 (structure half). Slot RESERVED from the allocator.
--
-- Indiana is the program's first PARTIALLY seated legislature, and IN-2 is therefore a REPAIR
-- and a seed in one wave. This migration:
--
--   1. creates the two real chambers -- Indiana has NEITHER today;
--   2. creates the 132 missing districts (88 House + 44 Senate);
--   3. REPOINTS the 18 existing offices onto the real chambers and normalises their titles;
--   4. creates the 132 missing offices;
--   5. DELETES the 18 emptied pseudo-chambers.
--
-- Creates NO people and NO terms -- CC_0089 does that, and the two are applied back to back.
--
-- 🔴 THE DEFECT BEING REPAIRED. Indiana's 18 seated legislators hang on 18 chambers named for a
-- single district each, every one with official_count 0, spread across 18 SEPARATE
-- 'State of Indiana' government rows. Measured 2026-09-10: count(DISTINCT chamber_id) over
-- Indiana's STATE_LOWER offices is 12 across 12 offices, and over STATE_UPPER is 6 across 6.
-- Swept across every state, INDIANA IS THE ONLY ONE where a legislative chamber count exceeds 2.
--
-- 🟢 NOTHING ELSE REFERENCES THE 18. The three tables carrying a chambers FK --
-- meetings.meetings, essentials.discovered_sources, essentials.source_outlets -- hold ZERO rows
-- against any of the 18 chamber ids. Their only referents are their own 18 offices, which step 3
-- moves first. The DELETE in step 5 is still guarded on emptiness rather than trusting that.
--
-- 🔴 THE HOST GOVERNMENT IS CHOSEN, NOT ASSUMED. There are TWENTY-TWO government rows named
-- 'State of Indiana', all type STATE, state IN, geo_id NULL -- indistinguishable by attribute.
-- Every other state in production has exactly ONE. e00dba00-b293-499c-ad67-6f52ab8f4d7c
-- is the only one carrying correctly modelled statewide chambers (Comptroller, Secretary of
-- State, Treasurer, Utility Regulatory Commission, with real official_counts), so it hosts the
-- legislature. ⚠ The other 21 rows are an import artefact and are DELIBERATELY LEFT ALONE:
-- consolidating governments is a larger repair than this wave, and half-doing it is worse than
-- scheduling it. After this migration, 17 of them hold no chamber at all.
--
-- 🔴 THE 132 NEW DISTRICTS MATCH THE CURRENT LOADER, NOT THE LEGACY 18. state is the LOWERCASE
-- abbreviation and the label is 'State House/Senate District N', which is what
-- scripts/load-state-tiger-boundaries.ts writes (line 719) and why GA, FL, CO and NC are all
-- lowercase. Indiana's legacy 18 are uppercase 'IN' from an older loader. Matching the CURRENT
-- loader keeps a future loader run on Indiana a NO-OP rather than a duplicate-maker.
-- ⚠ The legacy 18 are NOT case-normalised here. Live read paths compare d.state = $1
-- case-sensitively against an upper-cased argument; those queries filter to statewide
-- district_types and cannot see a STATE_LOWER row, but proving that for every caller is a bigger
-- claim than this wave needs. The split is recorded in .planning/knight-foundation/in.md.
--
-- 🔴 GEOMETRY IS NOT TOUCHED. All 150 polygons were already loaded (census_tiger_2024,
-- 2026-02-11/12) and were VINTAGE-PROVED 150/150 against the General Assembly's own
-- house_2021.kmz / senate_2021.kmz by scripts/verify-in-legislative-vintage.mjs, every district
-- tested at its own interior point, with SD-17/SD-18 swapped as a planted control.
--
-- 🔴 EVERY JOIN PAIRS geo_id WITH district_type. Indiana's sldl range runs 18001..18100 and its
-- sldu range 18001..18050, so '18046' is House District 46 AND Senate District 46. A LEFT JOIN
-- on geo_id alone reported 25 House and 18 Senate district rows when the true counts are 12 and 6.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded, every UPDATE is guarded on the current value,
-- and the DELETE is guarded on emptiness. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers Indiana does not have ───────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT 'e00dba00-b293-499c-ad67-6f52ab8f4d7c', 'Indiana House of Representatives', 'Indiana House of Representatives', 100
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND name = 'Indiana House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT 'e00dba00-b293-499c-ad67-6f52ab8f4d7c', 'Indiana State Senate', 'Indiana State Senate', 50
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND name = 'Indiana State Senate');

-- ─── 2. The 132 missing districts ────────────────────────────────────────────

CREATE TEMP TABLE in_new_districts(geo_id text, ocd_id text, label text, district_type text, mtfcc text)
  ON COMMIT DROP;
INSERT INTO in_new_districts(geo_id, ocd_id, label, district_type, mtfcc) VALUES
  ('18001', 'ocd-division/country:us/state:in/sldl:1', 'State House District 1', 'STATE_LOWER', 'G5220'),
  ('18002', 'ocd-division/country:us/state:in/sldl:2', 'State House District 2', 'STATE_LOWER', 'G5220'),
  ('18003', 'ocd-division/country:us/state:in/sldl:3', 'State House District 3', 'STATE_LOWER', 'G5220'),
  ('18004', 'ocd-division/country:us/state:in/sldl:4', 'State House District 4', 'STATE_LOWER', 'G5220'),
  ('18005', 'ocd-division/country:us/state:in/sldl:5', 'State House District 5', 'STATE_LOWER', 'G5220'),
  ('18006', 'ocd-division/country:us/state:in/sldl:6', 'State House District 6', 'STATE_LOWER', 'G5220'),
  ('18007', 'ocd-division/country:us/state:in/sldl:7', 'State House District 7', 'STATE_LOWER', 'G5220'),
  ('18008', 'ocd-division/country:us/state:in/sldl:8', 'State House District 8', 'STATE_LOWER', 'G5220'),
  ('18009', 'ocd-division/country:us/state:in/sldl:9', 'State House District 9', 'STATE_LOWER', 'G5220'),
  ('18010', 'ocd-division/country:us/state:in/sldl:10', 'State House District 10', 'STATE_LOWER', 'G5220'),
  ('18011', 'ocd-division/country:us/state:in/sldl:11', 'State House District 11', 'STATE_LOWER', 'G5220'),
  ('18012', 'ocd-division/country:us/state:in/sldl:12', 'State House District 12', 'STATE_LOWER', 'G5220'),
  ('18013', 'ocd-division/country:us/state:in/sldl:13', 'State House District 13', 'STATE_LOWER', 'G5220'),
  ('18014', 'ocd-division/country:us/state:in/sldl:14', 'State House District 14', 'STATE_LOWER', 'G5220'),
  ('18015', 'ocd-division/country:us/state:in/sldl:15', 'State House District 15', 'STATE_LOWER', 'G5220'),
  ('18016', 'ocd-division/country:us/state:in/sldl:16', 'State House District 16', 'STATE_LOWER', 'G5220'),
  ('18017', 'ocd-division/country:us/state:in/sldl:17', 'State House District 17', 'STATE_LOWER', 'G5220'),
  ('18018', 'ocd-division/country:us/state:in/sldl:18', 'State House District 18', 'STATE_LOWER', 'G5220'),
  ('18019', 'ocd-division/country:us/state:in/sldl:19', 'State House District 19', 'STATE_LOWER', 'G5220'),
  ('18020', 'ocd-division/country:us/state:in/sldl:20', 'State House District 20', 'STATE_LOWER', 'G5220'),
  ('18021', 'ocd-division/country:us/state:in/sldl:21', 'State House District 21', 'STATE_LOWER', 'G5220'),
  ('18022', 'ocd-division/country:us/state:in/sldl:22', 'State House District 22', 'STATE_LOWER', 'G5220'),
  ('18023', 'ocd-division/country:us/state:in/sldl:23', 'State House District 23', 'STATE_LOWER', 'G5220'),
  ('18024', 'ocd-division/country:us/state:in/sldl:24', 'State House District 24', 'STATE_LOWER', 'G5220'),
  ('18025', 'ocd-division/country:us/state:in/sldl:25', 'State House District 25', 'STATE_LOWER', 'G5220'),
  ('18026', 'ocd-division/country:us/state:in/sldl:26', 'State House District 26', 'STATE_LOWER', 'G5220'),
  ('18027', 'ocd-division/country:us/state:in/sldl:27', 'State House District 27', 'STATE_LOWER', 'G5220'),
  ('18028', 'ocd-division/country:us/state:in/sldl:28', 'State House District 28', 'STATE_LOWER', 'G5220'),
  ('18029', 'ocd-division/country:us/state:in/sldl:29', 'State House District 29', 'STATE_LOWER', 'G5220'),
  ('18030', 'ocd-division/country:us/state:in/sldl:30', 'State House District 30', 'STATE_LOWER', 'G5220'),
  ('18031', 'ocd-division/country:us/state:in/sldl:31', 'State House District 31', 'STATE_LOWER', 'G5220'),
  ('18032', 'ocd-division/country:us/state:in/sldl:32', 'State House District 32', 'STATE_LOWER', 'G5220'),
  ('18033', 'ocd-division/country:us/state:in/sldl:33', 'State House District 33', 'STATE_LOWER', 'G5220'),
  ('18034', 'ocd-division/country:us/state:in/sldl:34', 'State House District 34', 'STATE_LOWER', 'G5220'),
  ('18035', 'ocd-division/country:us/state:in/sldl:35', 'State House District 35', 'STATE_LOWER', 'G5220'),
  ('18036', 'ocd-division/country:us/state:in/sldl:36', 'State House District 36', 'STATE_LOWER', 'G5220'),
  ('18037', 'ocd-division/country:us/state:in/sldl:37', 'State House District 37', 'STATE_LOWER', 'G5220'),
  ('18038', 'ocd-division/country:us/state:in/sldl:38', 'State House District 38', 'STATE_LOWER', 'G5220'),
  ('18039', 'ocd-division/country:us/state:in/sldl:39', 'State House District 39', 'STATE_LOWER', 'G5220'),
  ('18040', 'ocd-division/country:us/state:in/sldl:40', 'State House District 40', 'STATE_LOWER', 'G5220'),
  ('18041', 'ocd-division/country:us/state:in/sldl:41', 'State House District 41', 'STATE_LOWER', 'G5220'),
  ('18042', 'ocd-division/country:us/state:in/sldl:42', 'State House District 42', 'STATE_LOWER', 'G5220'),
  ('18043', 'ocd-division/country:us/state:in/sldl:43', 'State House District 43', 'STATE_LOWER', 'G5220'),
  ('18044', 'ocd-division/country:us/state:in/sldl:44', 'State House District 44', 'STATE_LOWER', 'G5220'),
  ('18047', 'ocd-division/country:us/state:in/sldl:47', 'State House District 47', 'STATE_LOWER', 'G5220'),
  ('18048', 'ocd-division/country:us/state:in/sldl:48', 'State House District 48', 'STATE_LOWER', 'G5220'),
  ('18049', 'ocd-division/country:us/state:in/sldl:49', 'State House District 49', 'STATE_LOWER', 'G5220'),
  ('18050', 'ocd-division/country:us/state:in/sldl:50', 'State House District 50', 'STATE_LOWER', 'G5220'),
  ('18051', 'ocd-division/country:us/state:in/sldl:51', 'State House District 51', 'STATE_LOWER', 'G5220'),
  ('18052', 'ocd-division/country:us/state:in/sldl:52', 'State House District 52', 'STATE_LOWER', 'G5220'),
  ('18053', 'ocd-division/country:us/state:in/sldl:53', 'State House District 53', 'STATE_LOWER', 'G5220'),
  ('18054', 'ocd-division/country:us/state:in/sldl:54', 'State House District 54', 'STATE_LOWER', 'G5220'),
  ('18055', 'ocd-division/country:us/state:in/sldl:55', 'State House District 55', 'STATE_LOWER', 'G5220'),
  ('18056', 'ocd-division/country:us/state:in/sldl:56', 'State House District 56', 'STATE_LOWER', 'G5220'),
  ('18057', 'ocd-division/country:us/state:in/sldl:57', 'State House District 57', 'STATE_LOWER', 'G5220'),
  ('18058', 'ocd-division/country:us/state:in/sldl:58', 'State House District 58', 'STATE_LOWER', 'G5220'),
  ('18059', 'ocd-division/country:us/state:in/sldl:59', 'State House District 59', 'STATE_LOWER', 'G5220'),
  ('18064', 'ocd-division/country:us/state:in/sldl:64', 'State House District 64', 'STATE_LOWER', 'G5220'),
  ('18066', 'ocd-division/country:us/state:in/sldl:66', 'State House District 66', 'STATE_LOWER', 'G5220'),
  ('18067', 'ocd-division/country:us/state:in/sldl:67', 'State House District 67', 'STATE_LOWER', 'G5220'),
  ('18068', 'ocd-division/country:us/state:in/sldl:68', 'State House District 68', 'STATE_LOWER', 'G5220'),
  ('18069', 'ocd-division/country:us/state:in/sldl:69', 'State House District 69', 'STATE_LOWER', 'G5220'),
  ('18070', 'ocd-division/country:us/state:in/sldl:70', 'State House District 70', 'STATE_LOWER', 'G5220'),
  ('18071', 'ocd-division/country:us/state:in/sldl:71', 'State House District 71', 'STATE_LOWER', 'G5220'),
  ('18072', 'ocd-division/country:us/state:in/sldl:72', 'State House District 72', 'STATE_LOWER', 'G5220'),
  ('18073', 'ocd-division/country:us/state:in/sldl:73', 'State House District 73', 'STATE_LOWER', 'G5220'),
  ('18074', 'ocd-division/country:us/state:in/sldl:74', 'State House District 74', 'STATE_LOWER', 'G5220'),
  ('18075', 'ocd-division/country:us/state:in/sldl:75', 'State House District 75', 'STATE_LOWER', 'G5220'),
  ('18076', 'ocd-division/country:us/state:in/sldl:76', 'State House District 76', 'STATE_LOWER', 'G5220'),
  ('18077', 'ocd-division/country:us/state:in/sldl:77', 'State House District 77', 'STATE_LOWER', 'G5220'),
  ('18078', 'ocd-division/country:us/state:in/sldl:78', 'State House District 78', 'STATE_LOWER', 'G5220'),
  ('18079', 'ocd-division/country:us/state:in/sldl:79', 'State House District 79', 'STATE_LOWER', 'G5220'),
  ('18080', 'ocd-division/country:us/state:in/sldl:80', 'State House District 80', 'STATE_LOWER', 'G5220'),
  ('18081', 'ocd-division/country:us/state:in/sldl:81', 'State House District 81', 'STATE_LOWER', 'G5220'),
  ('18082', 'ocd-division/country:us/state:in/sldl:82', 'State House District 82', 'STATE_LOWER', 'G5220'),
  ('18083', 'ocd-division/country:us/state:in/sldl:83', 'State House District 83', 'STATE_LOWER', 'G5220'),
  ('18084', 'ocd-division/country:us/state:in/sldl:84', 'State House District 84', 'STATE_LOWER', 'G5220'),
  ('18085', 'ocd-division/country:us/state:in/sldl:85', 'State House District 85', 'STATE_LOWER', 'G5220'),
  ('18086', 'ocd-division/country:us/state:in/sldl:86', 'State House District 86', 'STATE_LOWER', 'G5220'),
  ('18087', 'ocd-division/country:us/state:in/sldl:87', 'State House District 87', 'STATE_LOWER', 'G5220'),
  ('18088', 'ocd-division/country:us/state:in/sldl:88', 'State House District 88', 'STATE_LOWER', 'G5220'),
  ('18089', 'ocd-division/country:us/state:in/sldl:89', 'State House District 89', 'STATE_LOWER', 'G5220'),
  ('18090', 'ocd-division/country:us/state:in/sldl:90', 'State House District 90', 'STATE_LOWER', 'G5220'),
  ('18091', 'ocd-division/country:us/state:in/sldl:91', 'State House District 91', 'STATE_LOWER', 'G5220'),
  ('18092', 'ocd-division/country:us/state:in/sldl:92', 'State House District 92', 'STATE_LOWER', 'G5220'),
  ('18093', 'ocd-division/country:us/state:in/sldl:93', 'State House District 93', 'STATE_LOWER', 'G5220'),
  ('18094', 'ocd-division/country:us/state:in/sldl:94', 'State House District 94', 'STATE_LOWER', 'G5220'),
  ('18095', 'ocd-division/country:us/state:in/sldl:95', 'State House District 95', 'STATE_LOWER', 'G5220'),
  ('18001', 'ocd-division/country:us/state:in/sldu:1', 'State Senate District 1', 'STATE_UPPER', 'G5210'),
  ('18002', 'ocd-division/country:us/state:in/sldu:2', 'State Senate District 2', 'STATE_UPPER', 'G5210'),
  ('18003', 'ocd-division/country:us/state:in/sldu:3', 'State Senate District 3', 'STATE_UPPER', 'G5210'),
  ('18004', 'ocd-division/country:us/state:in/sldu:4', 'State Senate District 4', 'STATE_UPPER', 'G5210'),
  ('18005', 'ocd-division/country:us/state:in/sldu:5', 'State Senate District 5', 'STATE_UPPER', 'G5210'),
  ('18006', 'ocd-division/country:us/state:in/sldu:6', 'State Senate District 6', 'STATE_UPPER', 'G5210'),
  ('18007', 'ocd-division/country:us/state:in/sldu:7', 'State Senate District 7', 'STATE_UPPER', 'G5210'),
  ('18008', 'ocd-division/country:us/state:in/sldu:8', 'State Senate District 8', 'STATE_UPPER', 'G5210'),
  ('18009', 'ocd-division/country:us/state:in/sldu:9', 'State Senate District 9', 'STATE_UPPER', 'G5210'),
  ('18010', 'ocd-division/country:us/state:in/sldu:10', 'State Senate District 10', 'STATE_UPPER', 'G5210'),
  ('18011', 'ocd-division/country:us/state:in/sldu:11', 'State Senate District 11', 'STATE_UPPER', 'G5210'),
  ('18012', 'ocd-division/country:us/state:in/sldu:12', 'State Senate District 12', 'STATE_UPPER', 'G5210'),
  ('18013', 'ocd-division/country:us/state:in/sldu:13', 'State Senate District 13', 'STATE_UPPER', 'G5210'),
  ('18014', 'ocd-division/country:us/state:in/sldu:14', 'State Senate District 14', 'STATE_UPPER', 'G5210'),
  ('18015', 'ocd-division/country:us/state:in/sldu:15', 'State Senate District 15', 'STATE_UPPER', 'G5210'),
  ('18016', 'ocd-division/country:us/state:in/sldu:16', 'State Senate District 16', 'STATE_UPPER', 'G5210'),
  ('18017', 'ocd-division/country:us/state:in/sldu:17', 'State Senate District 17', 'STATE_UPPER', 'G5210'),
  ('18018', 'ocd-division/country:us/state:in/sldu:18', 'State Senate District 18', 'STATE_UPPER', 'G5210'),
  ('18019', 'ocd-division/country:us/state:in/sldu:19', 'State Senate District 19', 'STATE_UPPER', 'G5210'),
  ('18020', 'ocd-division/country:us/state:in/sldu:20', 'State Senate District 20', 'STATE_UPPER', 'G5210'),
  ('18021', 'ocd-division/country:us/state:in/sldu:21', 'State Senate District 21', 'STATE_UPPER', 'G5210'),
  ('18022', 'ocd-division/country:us/state:in/sldu:22', 'State Senate District 22', 'STATE_UPPER', 'G5210'),
  ('18023', 'ocd-division/country:us/state:in/sldu:23', 'State Senate District 23', 'STATE_UPPER', 'G5210'),
  ('18024', 'ocd-division/country:us/state:in/sldu:24', 'State Senate District 24', 'STATE_UPPER', 'G5210'),
  ('18025', 'ocd-division/country:us/state:in/sldu:25', 'State Senate District 25', 'STATE_UPPER', 'G5210'),
  ('18026', 'ocd-division/country:us/state:in/sldu:26', 'State Senate District 26', 'STATE_UPPER', 'G5210'),
  ('18027', 'ocd-division/country:us/state:in/sldu:27', 'State Senate District 27', 'STATE_UPPER', 'G5210'),
  ('18028', 'ocd-division/country:us/state:in/sldu:28', 'State Senate District 28', 'STATE_UPPER', 'G5210'),
  ('18029', 'ocd-division/country:us/state:in/sldu:29', 'State Senate District 29', 'STATE_UPPER', 'G5210'),
  ('18030', 'ocd-division/country:us/state:in/sldu:30', 'State Senate District 30', 'STATE_UPPER', 'G5210'),
  ('18031', 'ocd-division/country:us/state:in/sldu:31', 'State Senate District 31', 'STATE_UPPER', 'G5210'),
  ('18032', 'ocd-division/country:us/state:in/sldu:32', 'State Senate District 32', 'STATE_UPPER', 'G5210'),
  ('18034', 'ocd-division/country:us/state:in/sldu:34', 'State Senate District 34', 'STATE_UPPER', 'G5210'),
  ('18035', 'ocd-division/country:us/state:in/sldu:35', 'State Senate District 35', 'STATE_UPPER', 'G5210'),
  ('18036', 'ocd-division/country:us/state:in/sldu:36', 'State Senate District 36', 'STATE_UPPER', 'G5210'),
  ('18038', 'ocd-division/country:us/state:in/sldu:38', 'State Senate District 38', 'STATE_UPPER', 'G5210'),
  ('18041', 'ocd-division/country:us/state:in/sldu:41', 'State Senate District 41', 'STATE_UPPER', 'G5210'),
  ('18042', 'ocd-division/country:us/state:in/sldu:42', 'State Senate District 42', 'STATE_UPPER', 'G5210'),
  ('18043', 'ocd-division/country:us/state:in/sldu:43', 'State Senate District 43', 'STATE_UPPER', 'G5210'),
  ('18045', 'ocd-division/country:us/state:in/sldu:45', 'State Senate District 45', 'STATE_UPPER', 'G5210'),
  ('18047', 'ocd-division/country:us/state:in/sldu:47', 'State Senate District 47', 'STATE_UPPER', 'G5210'),
  ('18048', 'ocd-division/country:us/state:in/sldu:48', 'State Senate District 48', 'STATE_UPPER', 'G5210'),
  ('18049', 'ocd-division/country:us/state:in/sldu:49', 'State Senate District 49', 'STATE_UPPER', 'G5210'),
  ('18050', 'ocd-division/country:us/state:in/sldu:50', 'State Senate District 50', 'STATE_UPPER', 'G5210');

INSERT INTO essentials.districts (geo_id, ocd_id, label, district_type, state, mtfcc)
SELECT n.geo_id, n.ocd_id, n.label, n.district_type, 'in', n.mtfcc
FROM in_new_districts n
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
  WHERE d.geo_id = n.geo_id AND d.district_type = n.district_type);

-- ─── 3. Repoint and retitle the 18 existing offices ──────────────────────────
-- Guarded on the current value, so a re-run is a no-op.

UPDATE essentials.offices o
SET chamber_id = c.id,
    title      = ch.title
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', 'Indiana House of Representatives', 'Representative'),
  ('STATE_UPPER', 'Indiana State Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type
JOIN essentials.chambers c
  ON c.government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND c.name = ch.chamber_name
WHERE d.id = o.district_id
  AND lower(d.state) = 'in'
  AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER')
  AND (o.chamber_id IS DISTINCT FROM c.id OR o.title IS DISTINCT FROM ch.title);

-- ─── 4. The 132 missing offices ──────────────────────────────────────────────

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'IN', 1, false, 'full'
FROM in_new_districts n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.district_type = n.district_type AND lower(d.state) = 'in'
JOIN (VALUES
  ('STATE_LOWER', 'Indiana House of Representatives', 'Representative'),
  ('STATE_UPPER', 'Indiana State Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type
JOIN essentials.chambers c
  ON c.government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND c.name = ch.chamber_name
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── 5. Delete the 18 emptied pseudo-chambers ────────────────────────────────
-- Guarded on holding no office. Step 3 moved all 18; if any still holds one, this deletes
-- nothing and the post-verify gate below fails loudly rather than silently orphaning an office.

DELETE FROM essentials.chambers c
WHERE (c.name LIKE 'Indiana House of Representatives - District%'
    OR c.name LIKE 'Indiana State Senate - District%')
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_house_chamber   int;
  v_senate_chamber  int;
  v_lower_districts int;
  v_upper_districts int;
  v_lower_offices   int;
  v_upper_offices   int;
  v_pseudo          int;
  v_distinct_ch     int;
  v_mistitled       int;
BEGIN
  SELECT count(*) INTO v_house_chamber FROM essentials.chambers
   WHERE government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND name = 'Indiana House of Representatives' AND official_count = 100;
  SELECT count(*) INTO v_senate_chamber FROM essentials.chambers
   WHERE government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND name = 'Indiana State Senate' AND official_count = 50;
  IF v_house_chamber <> 1 OR v_senate_chamber <> 1 THEN
    RAISE EXCEPTION 'IN-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_chamber, v_senate_chamber;
  END IF;

  SELECT count(*) FILTER (WHERE district_type = 'STATE_LOWER'),
         count(*) FILTER (WHERE district_type = 'STATE_UPPER')
    INTO v_lower_districts, v_upper_districts
  FROM essentials.districts WHERE lower(state) = 'in' AND district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_lower_districts <> 100 OR v_upper_districts <> 50 THEN
    RAISE EXCEPTION 'IN-2 structure: expected 100 House / 50 Senate districts, got % / %',
      v_lower_districts, v_upper_districts;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type = 'STATE_UPPER')
    INTO v_lower_offices, v_upper_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_lower_offices <> 100 OR v_upper_offices <> 50 THEN
    RAISE EXCEPTION 'IN-2 structure: expected 100 House / 50 Senate offices, got % / %',
      v_lower_offices, v_upper_offices;
  END IF;

  -- The whole point of the repair: two chambers, not 150.
  SELECT count(DISTINCT o.chamber_id) INTO v_distinct_ch
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_distinct_ch <> 2 THEN
    RAISE EXCEPTION 'IN-2 structure: Indiana legislative offices span % chambers, expected exactly 2', v_distinct_ch;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'in' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
    AND o.title <> CASE d.district_type WHEN 'STATE_LOWER' THEN 'Representative' ELSE 'Senator' END;
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'IN-2 structure: % Indiana legislative offices carry a non-standard title', v_mistitled;
  END IF;

  SELECT count(*) INTO v_pseudo FROM essentials.chambers
   WHERE name LIKE 'Indiana House of Representatives - District%'
      OR name LIKE 'Indiana State Senate - District%';
  IF v_pseudo <> 0 THEN
    RAISE EXCEPTION 'IN-2 structure: % pseudo-chambers survive -- one still holds an office', v_pseudo;
  END IF;

  RAISE NOTICE 'IN-2 structure OK: 2 chambers, 100+50 districts, 100+50 offices, 0 pseudo-chambers';
END $$;

COMMIT;
