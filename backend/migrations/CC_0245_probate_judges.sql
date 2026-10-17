-- CC_0245_probate_judges.sql
--
-- Atlanta full seed, follow-up. Creates the TWO Probate Judge offices that CC_0240 and CC_0242
-- deliberately left out, and seats both. 2 offices, 2 people, 2 terms.
--
-- Roster: backend/data/seed-atlanta-2026/ROSTERS.md (open item 1, now closed)
-- Slot CC_0245 was RESERVED FROM THE ALLOCATOR before this file was named.
--
-- ---------------------------------------------------------------------------
-- 🔴 WHY THESE WERE MISSING, AND WHY THE REASON WAS SOUND BUT THE CONCLUSION WAS NOT.
--
-- CC_0240 and CC_0242 record that no Probate Judge contest appears in ANY Fulton or DeKalb
-- certified return 2020-2026, across 16 payloads, with a Baldwin positive control passing on the
-- same scan. **That finding stands and is correct**: under Georgia's nonpartisan election law an
-- unopposed candidate is declared elected and never reaches a ballot, so a certified return
-- enumerates CONTESTS, not OFFICES.
--
-- The error was stopping there. "Not on any ballot" is not "cannot be sourced" — it only means
-- the ELECTION record is silent. **The COURTS publish their own judges**, and both do:
--
--   Fulton County Probate Court   fultonprobatega.org, "Meet our Executive Team":
--                                 "Kenya M. Johnson, Chief Judge"
--   DeKalb County Probate Court   dekalbprobatega.com, in the judge's own first person:
--                                 "I am Bedelia C Hargrove, the Chief Probate Court Judge in
--                                  DeKalb County, Georgia"
--
-- ▶ When the election record is silent about an office, ask the OFFICE.
--
-- ⚠ Fulton's court also lists an ASSOCIATE Judge (Marian Parker). Only the elected Chief Judge is
--   seeded; an associate probate judgeship in Georgia is filled by appointment, not countywide
--   election, and this wave seeds elected offices only.
--
-- ---------------------------------------------------------------------------
-- 🔴 GA. CONST. ART. IX PUTS THE PROBATE JUDGE AMONG THE COUNTY OFFICERS.
--
-- That is why the Probate Judge is IN while the Chief Magistrate and the Superior/State Court
-- judges stay OUT (judicial branch, Ga. Const. Art. VI). The line is the constitution's, not
-- ours — `ga.md`, ruled 2026-09-01.
--
-- ---------------------------------------------------------------------------
-- ⚠ THIS CHANGES THE OFFICE COUNTS THAT CC_0240 AND CC_0242 ASSERT (11 each, now 12 each).
--    Those gates were correct when they ran and are point-in-time. This repo has no
--    schema_migrations table and no ordered runner — each migration is applied once, by hand,
--    and never replayed — so nothing re-runs them. A re-run WOULD now fail its count gate, and
--    that is the right behaviour: the count changed deliberately, and a gate that silently
--    tolerated it would be worth less.
--
-- 🔴 Both starts are 'unknown'. Neither court states an oath or election date, and neither judge
--    appears in any certified return. Tagged '| unverified CC_0245' so office_holders_as_of
--    cannot let an undated term answer every past date.
--
-- Idempotent. Dry-run with BEGIN; ... ROLLBACK; and confirm the rollback reverted.

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_f int; v_d int;
BEGIN
  SELECT count(*) INTO v_f FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'Fulton County, Georgia, US' AND c.name = 'Fulton County Elected Officials';
  SELECT count(*) INTO v_d FROM essentials.chambers c
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'DeKalb County, Georgia, US' AND c.name = 'DeKalb County Elected Officials';
  IF v_f <> 1 OR v_d <> 1 THEN
    RAISE EXCEPTION 'ATL-8 pre-flight: expected both county officer chambers from CC_0240/CC_0242, found Fulton % and DeKalb %', v_f, v_d;
  END IF;
END $$;

-- ─── 1. Two offices, on the existing countywide districts ────────────────────
-- 🔴 Every join pairs geo_id WITH mtfcc AND district_type: '13121' is also State House
--    District 121 (G5220) and '13089' is also State House District 89 (G5220).

CREATE TEMP TABLE pj_offices(gov text, chamber text, geo_id text) ON COMMIT DROP;
INSERT INTO pj_offices(gov, chamber, geo_id) VALUES
  ('Fulton County, Georgia, US', 'Fulton County Elected Officials', '13121'),
  ('DeKalb County, Georgia, US', 'DeKalb County Elected Officials', '13089');

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant, voting_powers)
SELECT c.id, d.id, 'Judge of Probate Court', 'GA', NULL, 1, false, 'full'
FROM pj_offices n
JOIN essentials.districts d
  ON d.geo_id = n.geo_id AND d.mtfcc = 'G4020' AND d.district_type = 'COUNTY' AND lower(d.state) = 'ga'
JOIN essentials.governments g ON g.name = n.gov
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = n.chamber
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.title = 'Judge of Probate Court');

-- ─── 2. Two people ───────────────────────────────────────────────────────────
-- ⚠ Fulton's judge is ANOTHER Johnson. She is a FULTON officeholder and shares no government
--   with DeKalb's three Johnsons, but a surname or full_name match across governments must not
--   merge her with any of them.

CREATE TEMP TABLE pj_people(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO pj_people(external_id, full_name, first_name, last_name) VALUES
  (-2767931::bigint, 'Kenya M. Johnson',    'Kenya',   'Johnson'),
  (-2767952::bigint, 'Bedelia C. Hargrove', 'Bedelia', 'Hargrove');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name,
       CASE WHEN n.external_id = -2767931 THEN
         'Fulton County Probate Court, the court''s own site fultonprobatega.org, "Meet our Executive Team", which lists her as Chief Judge. Read 2026-10-17 (CC_0245). 🔴 No Probate Judge contest appears in any Fulton certified return 2020-2026 — under Georgia''s nonpartisan election law an unopposed candidate is declared elected without reaching a ballot — so the COURT, not the election record, is the source'
       ELSE
         'DeKalb County Probate Court, the court''s own site dekalbprobatega.com, where the judge writes in the first person: "I am Bedelia C Hargrove, the Chief Probate Court Judge in DeKalb County, Georgia". Read 2026-10-17 (CC_0245). 🔴 No Probate Judge contest appears in any DeKalb certified return 2020-2026, for the same reason'
       END,
       true, true, '{}'::text[]
FROM pj_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 3. Two terms ────────────────────────────────────────────────────────────

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'elected',
       'Holder confirmed current by the Probate Court''s own website, read 2026-10-17 (CC_0245). The START of this occupancy is NOT established: the court states no oath or election date, and the judge appears in no certified return because Georgia declares an unopposed nonpartisan candidate elected without a ballot. Written open-ended at ''unknown'' precision rather than guessed. | unverified CC_0245 (2026-10-17): the HOLDER is verified and current; only the start date is unknown, so this term is excluded from office_holders_as_of, where an undated term would otherwise answer every past date'
FROM (VALUES
  ('Fulton County, Georgia, US', -2767931::bigint),
  ('DeKalb County, Georgia, US', -2767952::bigint)
) AS v(gov, external_id)
JOIN essentials.governments g ON g.name = v.gov
JOIN essentials.chambers c ON c.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = c.id AND o.title = 'Judge of Probate Court'
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_off int; v_people int; v_seated int; v_untag int; v_noninc int;
  v_fulton int; v_dekalb int; v_hist int; v_nogeom int;
BEGIN
  SELECT count(*) INTO v_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name IN ('Fulton County, Georgia, US','DeKalb County, Georgia, US')
     AND o.title = 'Judge of Probate Court';
  IF v_off <> 2 THEN RAISE EXCEPTION 'ATL-8 gate: expected 2 Probate Judge offices, found %', v_off; END IF;

  -- One per county, not two in one.
  SELECT count(*) FILTER (WHERE g.name LIKE 'Fulton%'), count(*) FILTER (WHERE g.name LIKE 'DeKalb%')
    INTO v_fulton, v_dekalb
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title = 'Judge of Probate Court';
  IF v_fulton <> 1 OR v_dekalb <> 1 THEN
    RAISE EXCEPTION 'ATL-8 gate: expected 1 Probate Judge per county, found Fulton % and DeKalb %', v_fulton, v_dekalb;
  END IF;

  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id IN (-2767931, -2767952);
  IF v_people <> 2 THEN RAISE EXCEPTION 'ATL-8 gate: expected 2 probate judges, found %', v_people; END IF;

  SELECT count(*) INTO v_noninc FROM essentials.politicians
   WHERE external_id IN (-2767931, -2767952)
     AND (is_incumbent IS DISTINCT FROM true OR is_active IS DISTINCT FROM true);
  IF v_noninc <> 0 THEN
    RAISE EXCEPTION 'ATL-8 gate: % probate judge(s) are not is_incumbent/is_active — they would be HIDDEN from address search', v_noninc;
  END IF;

  -- 🔴 count(och.politician_id), never count(*).
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.title = 'Judge of Probate Court'
     AND g.name IN ('Fulton County, Georgia, US','DeKalb County, Georgia, US');
  IF v_seated <> 2 THEN
    RAISE EXCEPTION 'ATL-8 gate: expected 2 SEATED probate judges, found % — an office with no term row is invisible', v_seated;
  END IF;

  -- 🔴 The failure mode CI cannot catch.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title = 'Judge of Probate Court'
     AND g.name IN ('Fulton County, Georgia, US','DeKalb County, Georgia, US')
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc);
  IF v_nogeom <> 0 THEN
    RAISE EXCEPTION 'ATL-8 gate: % probate judge office(s) sit on a district with NO polygon', v_nogeom;
  END IF;

  SELECT count(*) INTO v_untag FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title = 'Judge of Probate Court'
     AND g.name IN ('Fulton County, Georgia, US','DeKalb County, Georgia, US')
     AND ot.term_start IS NULL
     AND COALESCE(ot.source, '') NOT LIKE '%| unverified %';
  IF v_untag <> 0 THEN
    RAISE EXCEPTION 'ATL-8 gate: % undated probate term(s) are NOT tagged "| unverified "', v_untag;
  END IF;

  -- 🔴 THE TAG MUST BITE: neither undated judge may leak into history.
  -- ⚠ SCOPED TO THESE TWO GOVERNMENTS. Bibb and Muscogee already hold "Judge of Probate Court"
  --   offices from GA-4/GA-5 with REAL dates, and they answer 2015 correctly. An unscoped
  --   title-only query counts them and fails on correct data — it did, on the first run.
  SELECT count(*) INTO v_hist FROM essentials.office_holders_as_of(DATE '2015-06-01') h
    JOIN essentials.offices o ON o.id = h.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE o.title = 'Judge of Probate Court'
     AND g.name IN ('Fulton County, Georgia, US','DeKalb County, Georgia, US');
  IF v_hist <> 0 THEN
    RAISE EXCEPTION 'ATL-8 gate: office_holders_as_of(2015-06-01) returns % probate holder(s); expected 0', v_hist;
  END IF;

  RAISE NOTICE 'ATL-8 OK: 2 Probate Judge offices (1 per county), 2 people, 2 seated, both tagged-unverified, history clean';
END $$;
