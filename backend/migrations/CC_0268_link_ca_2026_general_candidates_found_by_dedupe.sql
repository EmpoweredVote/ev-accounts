-- CC_0268_link_ca_2026_general_candidates_found_by_dedupe.sql
--
-- Links TEN CA 2026 Statewide General candidacy rows to politician rows WE ALREADY HOLD.
--
-- 🔴 THIS MIGRATION EXISTS BECAUSE THE JOB ASKED FOR WAS THE OTHER ONE. The request was to
-- "do the 117" -- the 117 general candidates with no person record -- by CREATING politician
-- rows for them. Before creating anything, a dedupe pass ran, because the house rule is ONE
-- ROW PER PERSON and the duplicate-name guard keys on (first_name, last_name), which is blind
-- to a middle initial, an accent, a nickname and an archived row alike.
--
-- The pass found that TEN of them are NOT new people. Creating rows for these ten would have
-- manufactured ten duplicates of people we already publish -- and a merge afterwards is the
-- expensive direction: five foreign keys cascade, two of them carry stance research.
--
-- ⚠ "NO EXACT NAME MATCH" IS NOT "NEW PERSON". Every one of these ten failed an exact
-- lower(full_name) comparison. What separated them was a middle initial, a formal first name,
-- one accent, and in one case a single missing full stop.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- THE EVIDENCE, PER ROW. Two instruments, both already proven in CC_0263/CC_0266.
--
-- ▶ INSTRUMENT A -- GEOGRAPHIC CORROBORATION. The person we hold occupies a seat whose
-- territory sits inside the district the candidate seeks. Measured with ST_Intersects over
-- essentials.geofence_boundaries joined on (mtfcc, geo_id), never geo_id alone.
--
--   Esmeralda Soria -> Esmeralda Z. Soria, Assembly District 27
--       AD-27 is 99.1% inside State Senate District 14 (sought).   control SD-40: 0.0%
--   Mike Gipson -> Mike A. Gipson, Assembly District 65
--       AD-65 is 100.0% inside Board of Equalization District 3 (sought). control D1: 0.0%
--   Mark Pulido -> Mark E. Pulido, Council Member, City of Cerritos
--       Cerritos is 100.0% inside Assembly District 67 (sought).    control AD-2: 0.0%
--   John M. Erickson -> John Erickson, Council Member, City of West Hollywood
--       West Hollywood is 100.0% inside State Senate District 24 (sought). control SD-1: 0.0%
--   Charles Frederick Hughes -> Charles Hughes, Antelope Valley Joint Union High, Trustee Area 1
--       TA-1 is 99.2% inside Assembly District 34 (sought).         control AD-80: 0.0%
--
-- 🔴 ALL FOUR CONTROLS RETURNED 0.0% AND WERE READ BEFORE THE TESTS WERE TRUSTED. A geometric
-- test that answers "true" to everything proves nothing; these discriminate.
--
-- ▶ INSTRUMENT B -- PRIMARY-ADVANCED CONTINUITY. The person we hold already carries a
-- race_candidates row for THE SAME OFFICE in the June 2026 primary, with result 'advanced'.
-- A candidate certified as having advanced for an office is the candidate for that office on
-- the November ballot. This is a document about the same seat, not a name resemblance.
--
--   Herb W. Morgan   -> Herb W Morgan    primary "CA State Controller",            advanced
--   Sarah Rascón     -> Sarah Rascon     primary "CA State Senate District 26",    advanced
--   Ashley M. Brown  -> Ashley M. Brown  primary "CA State Assembly District 55",  advanced
--   Jennifer Hawks   -> Jennifer Hawks   primary "CA State Treasurer",             advanced
--   Michael E. Gates -> Michael E. Gates primary "CA Attorney General",            advanced
--
-- ⚠ Morgan and Rascón differ from their own primary rows by a full stop and an accent
-- respectively. Brown, Hawks and Gates match exactly and were missed only because the earlier
-- sweep looked for a politician with the same name AND no existing link, and theirs sat on a
-- DIFFERENT election's row. The bug was in the question, not the data.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 TWO REFUSALS, AND THEY ARE THE POINT OF RUNNING THE PASS AT ALL.
--
-- ▶ ED DELGADO -- CA Assembly District 60 -- REFUSED. There is exactly one active politician
-- named "Ed Delgado", which is precisely the signal that linked ten rows above. He is a
-- WISCONSIN Assembly District 57 candidate who LOST. Comparing the election's state with the
-- state of the race the matched person actually ran in is one join, and it caught him.
-- This is the THIRD confirmed cross-state wrong person in this programme, after Cheryl
-- Williams (CA school board -> TX county commissioner) and Amanda Campbell (CO SoS -> TX
-- school board). The rate is now 3 in roughly 50 single-namesake matches examined.
-- 🔴 "EXACTLY ONE ACTIVE NAMESAKE" IS A FILTER FOR WHAT TO INVESTIGATE. IT IS NEVER A REASON
-- TO LINK. He gets a NEW person record in CC_0269 like any other unmatched candidate.
--
-- ▶ SONJA SHAW -- Superintendent of Public Instruction -- NOT TOUCHED. CC_0263 linked her,
-- the operator ruled the evidence too thin, and CC_0264 reverted it. Her politician row now
-- records a specific seat -- Chino Valley Unified School District, Trustee Area 3 -- which is
-- the thing CC_0264 said would settle it ("anything naming the district beside the name").
-- That is a materially better position than the one that was ruled on. It is NOT acted on
-- here: reversing an operator's ruling is not a migration's decision to make, and the
-- statewide race still cannot be geographically corroborated. Flagged for a ruling.
--
-- ▶ ANDREA LEE ANDERSON -- not a match. The dedupe pass paired her with "A. Dane Anderson"
-- only because an initial-only first name matches any first name beginning with that letter.
-- She is a new person and is created in CC_0269.
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ▶ WHAT THIS CHANGES FOR A VOTER. Nine of the ten politician rows carry a default image, so
-- nine ballot pages gain a photograph through COALESCE(rc.photo_url, pi.url) -- every one of
-- these candidacy rows has photo_url NULL, so nothing is overridden and nothing is cleared.
-- Charles Hughes has no image; his link gains a profile, not a picture.
-- None of the ten carries any compass answer, so no stance moves into view. That is the
-- consequence CC_0262 required to be stated before writing, and here it is empty.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _link (
  rc_id     uuid PRIMARY KEY,
  cand_name text NOT NULL,
  seeks     text NOT NULL,
  pol_id    uuid NOT NULL,
  pol_name  text NOT NULL,
  basis     text NOT NULL
) ON COMMIT DROP;

INSERT INTO _link VALUES
 ('9f4baf8b-6a28-4c47-bcc3-16ab608f4534','Esmeralda Soria','State Senate District 14',
  '2326fe1b-923d-4e2f-9598-0c8a23528df8','Esmeralda Z. Soria','geo: AD-27 99.1% in SD-14'),
 ('41e22561-3dbc-4d52-bdcc-a95bb5da6b8d','Mike Gipson','State Board of Equalization, 3rd District',
  '6133e73c-4c33-4cfc-9fd3-de1382729f42','Mike A. Gipson','geo: AD-65 100% in BoE D3'),
 ('ea299adf-16a4-4ca3-84c7-bb2bf1828c04','Mark Pulido','State Assembly District 67',
  '8d5cb94a-4110-4e86-9f06-2c4f89bb7c71','Mark E. Pulido','geo: Cerritos 100% in AD-67'),
 ('ae0aaef0-9b38-4b9d-8f83-14096801b8c4','John M. Erickson','State Senate District 24',
  '29ccd743-6e37-42ec-8999-f1316fff3270','John Erickson','geo: West Hollywood 100% in SD-24'),
 ('44e8db66-59dc-48f9-9e2a-80dc19fcdc94','Charles Frederick Hughes','State Assembly District 34',
  '98b2d8bf-08fa-54f4-a70a-405505259804','Charles Hughes','geo: AV HS TA-1 99.2% in AD-34'),
 ('d29380e0-dde7-4bea-8d0a-8c09609b4c74','Herb W. Morgan','Controller',
  'e01e8e8f-bf9d-4944-9a72-71d8e11a6be5','Herb W Morgan','primary advanced, same office'),
 ('3eb0a96f-c301-404e-9084-679308b5eedc','Sarah Rascón','State Senate District 26',
  '16b687c1-1577-4c7b-a978-54bb1995a0f6','Sarah Rascon','primary advanced, same office'),
 ('3165cfeb-0279-488b-a713-f7418b64182a','Ashley M. Brown','State Assembly District 55',
  'df0fdde7-448c-42fb-971d-8fd28c56ca0c','Ashley M. Brown','primary advanced, same office'),
 ('852e074e-fd90-4cad-82d5-0d5fc9221e53','Jennifer Hawks','Treasurer',
  '8cac6e85-ec44-494a-9f36-286e87115b72','Jennifer Hawks','primary advanced, same office'),
 ('a8ff0569-3c94-457f-8436-891eb6407ce2','Michael E. Gates','Attorney General',
  'f45f28fc-7278-4114-b29a-c7d390d5a5c4','Michael E. Gates','primary advanced, same office');

-- ── Guards: every fact the header rests on, re-asserted against the live database.
DO $$
DECLARE r record; v_name text; v_pid uuid; v_seeks text; v_active bool; v_imgs int;
BEGIN
  FOR r IN SELECT * FROM _link LOOP
    -- the person
    SELECT p.full_name, p.is_active INTO v_name, v_active
      FROM essentials.politicians p WHERE p.id = r.pol_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0268: politician % does not exist', r.pol_id;
    END IF;
    IF v_name <> r.pol_name THEN
      RAISE EXCEPTION 'CC_0268: politician % is "%", expected "%"', r.pol_id, v_name, r.pol_name;
    END IF;
    IF NOT v_active THEN
      RAISE EXCEPTION 'CC_0268: % is ARCHIVED - refusing to link a candidacy to an archived '
                      'row, which would resurrect someone deliberately retired', v_name;
    END IF;
    SELECT count(*) INTO v_imgs FROM essentials.politician_images pi
     WHERE pi.politician_id = r.pol_id AND pi.type='default';
    IF v_imgs > 1 THEN
      RAISE EXCEPTION 'CC_0268: % has % default images - the ballot page would inherit an '
                      'ambiguous photo', v_name, v_imgs;
    END IF;

    -- the candidacy
    SELECT rc.full_name, rc.politician_id, ra.position_name
      INTO v_name, v_pid, v_seeks
      FROM essentials.race_candidates rc
      JOIN essentials.races ra ON ra.id = rc.race_id
     WHERE rc.id = r.rc_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0268: race_candidates row % does not exist', r.rc_id;
    END IF;
    IF v_name <> r.cand_name THEN
      RAISE EXCEPTION 'CC_0268: row % is "%", expected "%"', r.rc_id, v_name, r.cand_name;
    END IF;
    IF v_seeks IS DISTINCT FROM r.seeks THEN
      RAISE EXCEPTION 'CC_0268: row % seeks "%", expected "%" - the evidence was gathered '
                      'against a different race, REFUSING', r.rc_id, v_seeks, r.seeks;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> r.pol_id THEN
      RAISE EXCEPTION 'CC_0268: row % is already linked to %, REFUSING to repoint it',
                      r.rc_id, v_pid;
    END IF;
  END LOOP;

  -- 🔴 The archived John M. Erickson must NOT be the link target, and must stay archived.
  PERFORM 1 FROM essentials.politicians
   WHERE id = 'af66146f-560a-4e54-94c1-0bacee36b621'::uuid AND is_active = false;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'CC_0268: the archived "John M. Erickson" row is missing or has been '
                    'reactivated - re-examine which of the two is the councilmember';
  END IF;
END $$;

UPDATE essentials.race_candidates rc
SET politician_id = l.pol_id
FROM _link l
WHERE rc.id = l.rc_id AND rc.politician_id IS DISTINCT FROM l.pol_id;

-- ── post-verify
DO $$
DECLARE n_linked int; n_render int; n_delgado int; n_shaw int; n_offsite int; n_arch int;
BEGIN
  SELECT count(*) INTO n_linked
    FROM essentials.race_candidates rc JOIN _link l ON l.rc_id = rc.id
   WHERE rc.politician_id = l.pol_id;
  IF n_linked <> 10 THEN
    RAISE EXCEPTION 'CC_0268: expected 10 linked rows, found %', n_linked;
  END IF;

  -- nine must now serve a photograph the way electionService computes it
  SELECT count(*) INTO n_render
    FROM essentials.race_candidates rc
    JOIN _link l ON l.rc_id = rc.id
    LEFT JOIN LATERAL (SELECT pi.url FROM essentials.politician_images pi
                        WHERE pi.politician_id = rc.politician_id AND pi.type='default'
                        LIMIT 1) pi ON true
   WHERE NULLIF(COALESCE(rc.photo_url, pi.url),'') IS NOT NULL;
  IF n_render <> 9 THEN
    RAISE EXCEPTION 'CC_0268: expected 9 of 10 ballot pages to serve a photograph, found %',
                    n_render;
  END IF;

  -- 🔴 the refusals must hold
  SELECT count(*) INTO n_delgado FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id
    JOIN essentials.elections e ON e.id = ra.election_id
   WHERE e.name='CA 2026 Statewide General' AND rc.full_name='Ed Delgado'
     AND rc.politician_id IS NOT NULL;
  IF n_delgado <> 0 THEN
    RAISE EXCEPTION 'CC_0268: Ed Delgado got linked - he is the WISCONSIN candidate';
  END IF;

  SELECT count(*) INTO n_shaw FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id
    JOIN essentials.elections e ON e.id = ra.election_id
   WHERE e.name='CA 2026 Statewide General' AND rc.full_name='Sonja Shaw'
     AND rc.politician_id IS NOT NULL;
  IF n_shaw <> 0 THEN
    RAISE EXCEPTION 'CC_0268: Sonja Shaw got re-linked - CC_0264 reverted that by ruling';
  END IF;

  SELECT count(*) INTO n_arch FROM essentials.politicians
   WHERE id='af66146f-560a-4e54-94c1-0bacee36b621'::uuid AND is_active=false;
  IF n_arch <> 1 THEN
    RAISE EXCEPTION 'CC_0268: the archived John M. Erickson row was disturbed';
  END IF;

  SELECT count(*) INTO n_offsite FROM essentials.race_candidates rc
   WHERE NULLIF(rc.photo_url,'') IS NOT NULL
     AND rc.result IS DISTINCT FROM 'not_nominated'
     AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_offsite <> 0 THEN
    RAISE EXCEPTION 'CC_0268: % live ballot row(s) render off-site', n_offsite;
  END IF;

  RAISE NOTICE 'CC_0268 OK - 10 linked, 9 ballot pages gain a photograph, 2 refusals hold';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: RUN THE DEDUPE PASS BEFORE THE CREATE, NOT AFTER.
-- The task was "create 117 people". Ten of them already existed, hidden from the duplicate
-- guard by a middle initial, a formal first name, one accent and one missing full stop.
-- Creating first and merging later is the expensive direction and the house rule is one row
-- per person. The pass cost one query and saved ten merges.
-- ⚠ AND IT CAUGHT A WRONG PERSON IN THE OTHER DIRECTION. Ed Delgado had the cleanest possible
-- signal -- exactly one active namesake -- and is a Wisconsin candidate who lost. The state of
-- the race the matched person actually ran in is one join away and is the cheapest wrong-person
-- test we have. Run it every time.
-- ───────────────────────────────────────────────────────────────────────────────────────────
