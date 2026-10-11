-- CC_0226 — the 214 live-row CAL-ACCESS sources whose committee carries the surname, but NOT at
-- the front. 204 are somebody else's and are detached. 10 are genuinely about the politician and
-- are deliberately left alone.
--
-- Slice 2 of the disputed-population audit; `CC_0223` was slice 1 (the no-surname bucket).
-- Worklist: `.planning/todos/2026-10-10-cal-access-disputed-source-audit.md`.
--
-- Applies with `DATABASE_URL` (`ev_api`) — DML only, no DDL.
--
--
-- ══ THE POPULATION, RE-MEASURED 2026-10-10 ═══════════════════════════════════════════════════
--
-- The worklist said 212 live. It is **214**: the 212 it counted are the mig-1792 provenance, and
-- two more on William Scott come from `confirm-cal-access.ts`. Same shape, same hazard, so they
-- are worked together rather than left as a remainder nobody would come back for.
--
-- The disputed total also moved 1,233 -> 1,231, because `CC_0225` retyped Gipson `1448127` and
-- the Newsom recall committee `1418587` to `ie_committee`. That reconciles exactly; not drift.
--
--   live rows (722 disputed)     508 start with the surname · 214 surname NOT leading · 0 no surname
--   inactive rows (509 disputed) 445 start with the surname ·  64 surname NOT leading · 0 no surname
--
-- 🟢 **All 214 carry ZERO contributions**, asserted below. Nothing publishes, nothing can be
-- stranded, and no voter sees any of this today. The exposure is the NEXT pass: a `disputed`
-- source on a live officeholder is what a later confirm sweep would promote. That is the
-- `CC_0220` hazard, and it is why a $0 bucket is still worth clearing.
--
--
-- ══ 🔴 WHAT THE MATCHER ACTUALLY HIT ═════════════════════════════════════════════════════════
--
-- Not one of the 204 is a near-miss. The surname matched something that is not a surname:
--
--   a PLACE          Menlo Park / Villa Park / Buena Park        -> Traci PARK (41)
--                    Santa Rosa                                  -> Miguel De La ROSA (18)
--                    San Gabriel Valley                          -> Jesse GABRIEL (12)
--                    Pleasant Hill / Signal Hill / Morgan Hill   -> Steve HILL (11)
--                    City of Lathrop · Santa Paula · King City · Indian Wells · Laguna Woods
--   a COMMON NOUN    recreation and parks districts              -> Grant PARKS (21)
--                    "law and order", "farm labor law"           -> Kaylee May LAW (12)
--                    Golden Gate / Golden Hills / Golden Valley  -> Crystal GOLDEN (3)
--   a FORENAME       Scott Peters, Scott Wiener, Scott Svonkin   -> William SCOTT (14)
--                    Anthony Phan, Anthony Portantino            -> Konstantine ANTHONY (11)
--                    Marshall Tuck · Bryan Marks · Marcus Lamb · Elias Acevedo
--   a DISTRICT       Peralta Community College District          -> Scarlet PERALTA (4)
--   ANOTHER PERSON   Bernard Parks · Gloria Negrete McLeod · March Fong Eu · Rocky Delgadillo
--                    Michelle PARK Steel (a middle name) · Karen Sylvester
--   a PARSE ARTIFACT `last_name` = "M.D" matched "DHAND M.D."    -> James Black M.D (1)
--
--
-- ══ 🔴🔴 THE TEST THAT SETTLED IT WAS JURISDICTION, NOT THE NAME ══════════════════════════════
--
-- Reading the committee name is necessary and NOT sufficient. Four rows read as genuine and were
-- disproved only by checking where the politician actually sits:
--
--   Eniko Gold is **Hidden** Hills; "BOSSE AND GOLD FOR COUNCIL 2020; **BEVERLY** HILLS UNITED"
--     is Lili Bosse's city, not hers.                                              -> detach
--   Doug Stewart is Mayor of **Malibu**; his committee is **San Mateo County** DCC. -> detach
--   Linda Freedman is Mayor of **Walnut**; "**REDLANDS** FOR FREEDMAN" is 60 miles off. -> detach
--   Pete Aguilar is a **US Representative**; "RILEY AND AGUILAR FOR **HESPERIA SCHOOL BOARD**".
--                                                                                   -> detach
--
-- 🟢 And the strongest instrument needed no network call at all: **the politician's OWN
-- committees, already in this corpus.** Compare the disputed committee against them.
--
--   Kyle Rohrbach  own `1448010 ROHRBACH FOR THOUSAND OAKS CITY COUNCIL 2022; KYLE`
--                  disputed `ENGLER, NEWMAN, AND ROHRBACH FOR THOUSAND OAKS CITY COUNCIL 2022`
--                  -> same city, same year, same race. KEEP.
--   Phil Brock     own `BROCK FOR CITY COUNCIL 2014 / 2018 / 2020; PHIL` (Santa Monica)
--                  disputed `...AND AGAINST BROCK ... RENTERS AND WORKERS FOR SANTA MONICA`
--                  -> KEEP. (His office row is MISSING from `office_current_holder`; see below.)
--   Penny Sylvester  `1425351 SYLVESTER FOR CVUSD SCHOOL BOARD 2024; KAREN` is ALREADY
--                  `not_applicable` — the corpus itself names the other Sylvester. Her two
--                  disputed CVUSD rows are Karen's.                                -> detach
--
-- ▶ **A committee name tells you whose a committee is NOT. Only the jurisdiction, or the
-- person's own filings, tells you whose it IS.**
--
--
-- ══ THE 10 THAT ARE GENUINELY ABOUT THE POLITICIAN, AND ARE NOT TOUCHED ═══════════════════════
--
-- Each names the right person in the right jurisdiction, and each is corroborated by that
-- politician's own committee in this corpus for the same seat.
--
--   1347821  OPPOSED TO NAZARIAN FOR ASSEMBLY 2012 (EdVoice IE)     Adrin Nazarian     OPPOSE
--   1322096  ...OPPOSING THE ELECTION OF MICHAEL KEEGAN ... 2009    Michael Keegan     OPPOSE
--   1444231  PRICE FOR MAYOR 2022 AND OPPOSING REX RICHARDSON       Rex Richardson     OPPOSE
--   1472886  ...AND AGAINST BROCK FOR CITY COUNCIL 2024             Phil Brock         OPPOSE
--   1253962  CHINESE AMERICANS FOR NEWSOM                           Gavin Newsom       support
--   1396278  LEON, BACA DEL RIO & ALTAMIRANO ... COMMERCE FORWARD   Ivan Altamirano    support
--   1416361  D'AMICO, LINDSEY HORVATH, AND LAUREN MEISTER ... 2019  Lindsey P. Horvath support
--   1423605  DEVINE, GHARPETIAN AND ASTORIAN ... GLENDALE           Vartan Gharpetian  support
--   1451076  ENGLER, NEWMAN, AND ROHRBACH ... THOUSAND OAKS 2022    Kyle Rohrbach      support
--   1474164  WILKE AND CHRIS RIZZOTTI ... BURBANK 2024              Chris Rizzotti     support
--
-- 🔴 **They stay `disputed`, and the post-verify ASSERTS that they did.** This migration is
-- pinned by what it refuses to change. Four of the ten are OPPOSE committees: publishing one as
-- the politician's own fundraising is a false statement about a real person, which is the whole
-- subject of ADR 0008. Now that `support_oppose` exists they are typable — but that is a
-- separate, evidenced step needing a Form 460/496 read, and all ten carry $0 so none would
-- publish anything today.
--
-- ⚠ **10 of 214 is 4.7%, not the "roughly one in five" the worklist estimated from a sample of
-- 18.** The estimate was a lead, not a measurement. Recorded so the inactive-64 slice is not
-- sized by it.
--
--
-- ══ WHAT THIS MIGRATION DOES NOT TOUCH ═══════════════════════════════════════════════════════
--
--   508 live-row sources whose committee STARTS with the surname — plausible, unverified, $0.
--    64 inactive-row sources of this same shape — same hazard, lower stakes, a separate slice.
--   445 inactive-row sources that start with the surname.
--   Every `needs_research` and `confirmed` row.
--
-- ⚠ **Two findings carried forward, both OUT OF SCOPE here and neither carrying money:**
--   · **Penny Sylvester** holds `SYLVESTER FOR DALY CITY COUNCIL 2020` and `...DC COUNCIL 2016`
--     as **CONFIRMED**, while `office_current_holder` seats her as **Mayor of Agoura Hills** —
--     350 miles apart. One of the two is wrong. $0, so nothing publishes, but a confirmed row is
--     a published attribution and this belongs in the confirmed-population audit.
--   · **Phil Brock** has NO row in `office_current_holder` though he is a sitting Santa Monica
--     council member — an occupancy gap, the `offices_missing_terms` class of defect.
--
--
-- ══ 🔴 WHY THE NOTE IS APPENDED AND NOT WRITTEN INTO THE JSON ════════════════════════════════
--
-- Measured: **212 of these 214 notes are ALREADY NOT VALID JSON.** Migration 1792 appended
-- `| UNVERIFIED ...` and `CA_0192` appended `| DISPUTED ...`, both after the closing brace. So
-- the append is this population's established convention, not a slip, and normalising 212 rows
-- is a different change from adjudicating them.
--
-- 🔴 That convention is what broke production today: `CC_0225` appended to four rows that a
-- `notes::jsonb` cast reads, and the campaign-finance endpoint returned HTTP 500 for four live
-- politicians. The reader is now guarded (PR #979 takes the JSON prefix before the first `} |`),
-- and these rows become `not_applicable`, which no read path parses. Appending here is therefore
-- safe AND consistent. ▶ **But `notes` is TEXT: never cast it without a guard.**

BEGIN;

DO $$
DECLARE
  v_cnt int;
  v_contrib0 bigint;
  n int;
BEGIN
  -- ── THE WORKLIST ──────────────────────────────────────────────────────────────────────────
  -- 44 live politicians and the exact number of foreign sources measured on each, 2026-10-10.
  CREATE TEMP TABLE _rows (pid uuid, who text, expected int) ON COMMIT DROP;
  INSERT INTO _rows VALUES
    ('d0977350-df68-4cfe-822e-816ba13f9213','Traci Park',41),
    ('810c320c-bde2-4c1b-8e47-0b003f6b3e3d','Grant Parks',21),
    ('f3a0a939-0bd3-4cc5-b613-7ef379372694','Miguel De La Rosa',18),
    ('0be41eea-1e14-4f67-87a9-752b573c252c','William Scott',14),
    ('f173ce9a-6941-4570-bd3f-97bc1157beaf','Jesse Gabriel',12),
    ('eb23af50-1ab2-4681-92a2-bc6c2ad633d4','Kaylee May Law',12),
    ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7','Konstantine Anthony',11),
    ('d94a4b34-28aa-4259-99cb-041b45d78a87','Steve Hill',11),
    ('ffaa618a-f72d-44e1-8fc9-7f889fab58ee','Bruce Lathrop',4),
    ('24866433-c285-4f4b-8cce-60bf4cce13d3','Jesus Rivera',4),
    ('60ba761c-1695-46af-b56f-7881a5b8df4a','Scarlet Peralta',4),
    ('06ba1b93-6bc5-4360-9f98-a006c60d2863','Ann Marshall',3),
    ('1ae14d1b-8749-4d09-9c14-9fe9aa9ab5ff','Crystal Golden',3),
    ('8bfc4fb1-527a-4cb8-b0c4-439a3a015857','Dandy De Paula',3),
    ('30f77168-39ca-437e-9d1e-36a9837523a3','John King',3),
    ('43b17d54-473e-46f8-add4-bf395e423ba1','Karen Ross',3),
    ('5cdd28b7-f8be-4968-bc1a-0e7928786980','Isaac G. Bryan',2),
    ('5604c5ae-d10d-4ca3-920d-dd3592278777','Lana Negrete',2),
    ('d5d51559-14e8-466e-85de-0d24de421905','Lori Woods',2),
    ('b4f9688b-add0-44d6-bab8-e923d17d105e','Mary N. Wells',2),
    ('cf6a072a-026b-4b95-9eb4-180be6480a95','Michelle Velasquez Bean',2),
    ('527baa04-a1ec-47e0-9fa9-f5ca47c540c7','Pat Wilson',2),
    ('8f5bfaa6-09c6-40b1-99d5-f12953fda21d','Penny Sylvester',2),
    ('a1e9b61d-96e0-47be-ae4f-dab05158e56b','Rachelle Marcus',2),
    ('21975878-739e-452b-8bf7-95919680462a','Robert Luna',2),
    ('59ef70e5-6123-4c46-bc5b-66a4114ce2d2','Annette C. Delgadillo',1),
    ('475b846d-bce8-43e0-bac8-bd65d58d9c46','Austin Bishop',1),
    ('376e56bf-5114-444f-8850-e96e4d0f7f67','Dean Francois',1),
    ('28413e59-5cf6-416f-89c2-85a13ffdccc5','Doug Stewart',1),
    ('90d759f2-9a58-43e4-8720-494924c7365e','Eniko Gold',1),
    ('97285c92-b664-4687-a1e4-6d88cf9c7fe4','Jacqui Irwin',1),
    ('3f6742b8-3fb8-43b9-b0e2-79114c5cce7d','James Black M.D',1),
    ('31409962-7388-40da-bb5c-07146fb353bd','Jim Roos',1),
    ('85169d37-0da8-44c6-9fb2-24e9ebf03bdf','Linda Freedman',1),
    ('6f3b9ac9-afde-4bef-9a18-31b8bef485da','Megan Kerr',1),
    ('cacdb3e3-f716-4914-9e32-a95cc632af42','Mike Fong',1),
    ('deea52f0-0422-4fc8-971a-27a2471e14f2','Pat Burns',1),
    ('822966a7-5f09-4151-ba43-630afbd676c2','Pete Aguilar',1),
    ('bb6b1993-83ba-46cc-b725-271cca6f206d','Salvador Melendez',1),
    ('0695e308-a400-426d-9f1b-4e674e5daf02','Sharon Kalani',1),
    ('09b98050-abe0-4c49-8f15-c22e54f5cb78','Shaunna Elias',1),
    ('e509b170-f6dc-461e-9946-8eb471968a81','Todd Rogers',1),
    ('f7826942-64bb-41bf-9588-407a2bc11e31','Tyron Hampton',1),
    ('a6ed5abd-297e-489d-b6d6-ebea5771b172','Wh Lane',1);

  -- The 10 that ARE about the politician. Named explicitly so the UPDATE cannot reach them, and
  -- so the post-verify can assert they survived.
  CREATE TEMP TABLE _keeps (ext text, who text, direction text) ON COMMIT DROP;
  INSERT INTO _keeps VALUES
    ('1347821','Adrin Nazarian',     'oppose'),
    ('1322096','Michael Keegan',     'oppose'),
    ('1444231','Rex Richardson',     'oppose'),
    ('1472886','Phil Brock',         'oppose'),
    ('1253962','Gavin Newsom',       'support'),
    ('1396278','Ivan Altamirano',    'support'),
    ('1416361','Lindsey P. Horvath', 'support'),
    ('1423605','Vartan Gharpetian',  'support'),
    ('1451076','Kyle Rohrbach',      'support'),
    ('1474164','Christopher John Rizzotti','support');

  -- The slice, derived by the SAME predicate the audit used — not a pasted id list, so the
  -- migration recomputes what it claims rather than trusting a transcription.
  -- 🔴 `notes` is TEXT and 212 of these are not valid JSON, so the committee name is read by
  --    regexp, never by a `::jsonb` cast. See the header.
  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT s.id, s.essentials_politician_id AS pid, s.external_id,
           COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],'') AS cmte,
           upper(p.last_name) AS surname
      FROM transparent_motivations.politician_sources s
      JOIN _rows r ON r.pid = s.essentials_politician_id
      JOIN essentials.politicians p ON p.id = s.essentials_politician_id
     WHERE s.source_system = 'cal_access'
       AND s.research_status = 'disputed'
       AND p.last_name IS NOT NULL
       AND upper(COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],''))
             NOT LIKE upper(p.last_name) || '%'
       AND upper(COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],''))
             LIKE '%' || upper(p.last_name) || '%'
       AND s.external_id NOT IN (SELECT ext FROM _keeps);

  -- ── PRE-VERIFY ────────────────────────────────────────────────────────────────────────────

  -- 1. Exactly 204, split exactly as measured. 🔴 The TOTAL alone would pass if 41 moved between
  --    politicians; the per-politician check is what makes this a gate rather than a tally.
  SELECT count(*) INTO v_cnt FROM _srcs;
  IF v_cnt <> 204 THEN RAISE EXCEPTION 'CC_0226: worklist is % sources, expected 204', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM _rows r LEFT JOIN (SELECT pid, count(*) AS n FROM _srcs GROUP BY pid) g ON g.pid = r.pid
   WHERE COALESCE(g.n,0) <> r.expected;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0226: % of the 44 politicians hold a different count than measured — re-audit', v_cnt;
  END IF;

  -- 2. 🔴🔴 THE CONTROL INHERITED FROM CC_0223: not one committee name may START with the
  --    politician's surname. A row that does is one this slice has not read.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE cmte <> '' AND upper(cmte) LIKE surname || '%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0226: % committees DO start with the politician surname — stop and read them', v_cnt;
  END IF;

  -- 3. 🔴 THIS SLICE'S OWN CONTROL, AND THE OPPOSITE OF 2: every committee name MUST contain the
  --    surname somewhere. Gate 2 alone would pass vacuously over rows the predicate never
  --    selected on; this proves the surname is why each row is here.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE upper(cmte) NOT LIKE '%' || surname || '%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0226: % committees do NOT contain the surname — the predicate changed under this list', v_cnt;
  END IF;

  -- 4. Every one carries a committee name. A blank would mean the predicate judged nothing.
  SELECT count(*) INTO v_cnt FROM _srcs WHERE cmte = '';
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0226: % sources have no committee name to judge', v_cnt; END IF;

  -- 5. 🔴 ALL 44 ARE LIVE AND NAMED AS EXPECTED — the reason this is not deferrable.
  SELECT count(*) INTO v_cnt FROM _rows r JOIN essentials.politicians p ON p.id = r.pid
   WHERE p.is_active AND p.full_name = r.who;
  IF v_cnt <> 44 THEN
    RAISE EXCEPTION 'CC_0226: % of the 44 politicians are live and named as expected, want 44', v_cnt;
  END IF;

  -- 6. No money, so nothing publishes and nothing can be stranded.
  --    (`contributions.politician_source_id` has NO foreign key — a strand would be silent.)
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN
    RAISE EXCEPTION 'CC_0226: the 204 sources carry % contributions, expected 0 — refusing', v_contrib0;
  END IF;

  -- 7. 🔴 All 10 keeps exist, are disputed, and sit on the politician named. If one has moved or
  --    been adjudicated since the audit, this list is stale and must not be acted on.
  SELECT count(*) INTO v_cnt
    FROM _keeps k
    JOIN transparent_motivations.politician_sources s
      ON s.external_id = k.ext AND s.source_system = 'cal_access' AND s.research_status = 'disputed'
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id AND p.full_name = k.who;
  IF v_cnt <> 10 THEN
    RAISE EXCEPTION 'CC_0226: % of the 10 keeps are disputed on the expected politician, want 10', v_cnt;
  END IF;

  -- ── THE CHANGE ────────────────────────────────────────────────────────────────────────────

  UPDATE transparent_motivations.politician_sources s
     SET research_status = 'not_applicable',
         notes = COALESCE(s.notes,'')
                 || ' | NOT APPLICABLE CC_0226: the committee''s own name carries this surname, '
                 || 'but it belongs to somebody else — a place name, a common noun, a district, '
                 || 'another person, or this surname used as a FORENAME. Settled against the '
                 || 'politician''s jurisdiction and their own committees in this corpus. '
                 || 'Adjudicated 2026-10-10; re-attaching it to its real owner is a separate, '
                 || 'evidenced step.',
         updated_at = now()
    FROM _srcs x
   WHERE s.id = x.id AND s.research_status = 'disputed';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 204 THEN RAISE EXCEPTION 'CC_0226: updated % rows, expected 204', n; END IF;

  -- ── POST-VERIFY ───────────────────────────────────────────────────────────────────────────

  -- 1. End state, read back rather than inferred from ROW_COUNT.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _srcs x ON x.id = s.id
   WHERE s.research_status = 'not_applicable';
  IF v_cnt <> 204 THEN RAISE EXCEPTION 'CC_0226: % reached not_applicable, expected 204', v_cnt; END IF;

  -- 2. 🔴 Counting what is LEFT catches an over-wide UPDATE; ROW_COUNT cannot. These 44
  --    politicians must now hold exactly the keeps as their only surname-not-leading rows.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN _rows r ON r.pid = s.essentials_politician_id
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed'
     AND upper(COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],''))
           NOT LIKE upper(p.last_name) || '%'
     AND upper(COALESCE((regexp_match(s.notes,'"committee_name"\s*:\s*"([^"]*)"'))[1],''))
           LIKE '%' || upper(p.last_name) || '%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0226: the 44 politicians still hold % surname-not-leading disputed sources, expected 0', v_cnt;
  END IF;

  -- 3. 🔴🔴 THE TEN SURVIVED. This migration is pinned by what it refuses to change — four of
  --    these are OPPOSE committees and detaching one would erase a real finding.
  SELECT count(*) INTO v_cnt
    FROM _keeps k
    JOIN transparent_motivations.politician_sources s
      ON s.external_id = k.ext AND s.source_system = 'cal_access'
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 10 THEN
    RAISE EXCEPTION 'CC_0226: only % of the 10 genuine support/oppose committees are still disputed, want 10', v_cnt;
  END IF;

  -- 4. Nothing outside the worklist was touched.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.notes LIKE '%CC_0226%' AND s.id NOT IN (SELECT id FROM _srcs);
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0226: % sources outside the worklist carry a CC_0226 note', v_cnt; END IF;

  -- 5. The rest of the disputed population is UNCHANGED: 1,231 - 204 = 1,027.
  SELECT count(*) INTO v_cnt FROM transparent_motivations.politician_sources s
   WHERE s.source_system = 'cal_access' AND s.research_status = 'disputed';
  IF v_cnt <> 1027 THEN
    RAISE EXCEPTION 'CC_0226: % cal_access sources still disputed, expected 1,027', v_cnt;
  END IF;

  -- 6. No contribution was created or stranded.
  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_contrib0 <> 0 THEN
    RAISE EXCEPTION 'CC_0226: the 204 sources now carry % contributions, expected 0', v_contrib0;
  END IF;

  RAISE NOTICE 'CC_0226: 204 foreign CAL-ACCESS sources detached from 44 live politicians; 10 genuine support/oppose committees left disputed; 1,027 disputed remain.';
END $$;

COMMIT;
