-- CC_0217 — adjudicate the four CAL-ACCESS bucket rows `CC_0216` did not cover.
--
-- `CC_0213` detached 159 sources from seven surname buckets. `CC_0216` adjudicated the 72 on three
-- of them. These are the other four, and all four are **`source = 'scraped'`, `is_active = false`**:
--
--     David Patterson       903b537b   56 disputed + 5 confirmed
--     John M. Erickson      af66146f   13 disputed + 3 confirmed
--     Angie Reyes English   97f376e1   12 disputed
--     Bryan "Bubba" Fish    837613f5    6 disputed
--                                      ── 87 disputed, 8 confirmed, 95 sources
--
-- Worklist: `.planning/todos/2026-10-09-finance-surname-buckets.md`.
--
-- Outcome: **86 of the 87 become `not_applicable`. One stays `disputed`, and five CONFIRMED rows
-- are DOWNGRADED to `disputed`.** No source moves to another politician: unlike `CC_0216`, not one
-- of these 87 belongs to somebody this corpus holds.
--
--
-- ══ WHAT THESE FOUR ROWS ACTUALLY ARE ════════════════════════════════════════════════════════
--
-- 🔴🔴 **THEY ARE SCRAPED DUPLICATES OF SEATED OFFICIALS WE ALREADY HOLD — AND THE EVIDENCE WAS
-- ONE TABLE OVER, AGAIN.** Every one carries an `essentials.politician_contacts` row of
-- `contact_type = 'city_website'`. That is the same lesson `CC_0214` recorded and it paid out again:
--
--     John M. Erickson      weho.org              -> John Erickson, Council Member, West Hollywood
--     Bryan "Bubba" Fish    culvercity.org        -> Bryan Fish,   Council Member, Culver City
--     Angie Reyes English   cityofhawthorne.org   -> Angie Reyes English, Council Member, Hawthorne
--     David Patterson       cityofhawthorne.org   -> nobody; Hawthorne seats no Patterson
--
-- ▶ **Three of the four duplicate a LIVE, SEATED politician.** Those merges are NOT done here —
-- attribution first, merge second, and `CC_0214`'s rule is that a bucket row is retired only once
-- its disputed sources are adjudicated. This migration is that prerequisite. The merges are a
-- separate, evidenced step, and John Erickson's is the one that moves money:
-- **$1,398,852.72 / 967 contributions of his 2026 State Senate campaign sit on the scraped row**,
-- while his live page shows only his West Hollywood council money ($116,264.23 / 299).
--
-- ⚠ **THE DUPLICATE GUARD IS BLIND TO ALL THREE, AND ANGIE REYES ENGLISH IS A NEW BLINDNESS.**
-- `check:duplicate-people` compares `(lower(first_name), lower(last_name))`. Her two rows carry the
-- SAME `full_name` and split it differently:
--     live be3ca929   first_name 'Angie'        last_name 'Reyes English'
--     scraped 97f376e1 first_name 'Angie Reyes'  last_name 'English'
-- 🔴 **A COMPOUND SURNAME SPLIT AT A DIFFERENT POINT DEFEATS THE GUARD EVEN WHEN `full_name`
-- MATCHES EXACTLY.** That is a third blindness beside archived rows and nicknames.
-- (Erickson is the nickname/middle-name shape — "John M." vs "John"; Fish is 'Bryan "Bubba"' vs
-- "Bryan".) All four are also `is_active = false`, so the archived-row blindness applies too.
--
--
-- ══ PART A — 86 SOURCES: THE OWNER IS KNOWN AND IS NOT IN THIS CORPUS ════════════════════════
--
-- Terminal state `not_applicable`, per the operator ruling of 2026-10-09 recorded in `CC_0216`:
-- `disputed` reads as *contested and unresolved* and invites the next session to redo the research.
--
-- **David Patterson, 56.** 🔴 **NINE OF THEM ARE JIM PATTERSON'S ENTIRE ASSEMBLY CAREER** —
-- 2,937 contributions. CAL-ACCESS's candidate page for `PATTERSON, JIM` (candidate filer 1346007,
-- Republican, AD-23 then AD-08, 2012-2022) names all nine:
--     1393990 ASSEMBLY 2018 (616) · 1435401 ASSEMBLY 2022 (578) · 1374569 ASSEMBLY 2016 (545)
--     1414590 ASSEMBLY 2020 (440) · 1353680 ASSEMBLY 2014 (334) · 1346331 ASSEMBLY 2012 (267)
--     1458365 BOARD OF EQUALIZATION 2026 (123) · 1458946 OFFICEHOLDER ACCOUNT (33)
--     1381961 SENATE 2018 (1)
--   Jim Patterson has **no row in this corpus** (searched `full_name ILIKE '%patterson%'` for Jim and
--   James: the only hits are committee-name placeholder rows). So there is nowhere for them to go.
--   ⚠ Note these are NOT Joe Patterson's, whose four committees `CC_0213` already repointed — the
--   two men filed separate `PATTERSON FOR ASSEMBLY 2022` committees, 1435401 and 1443381.
--   The remaining ~9 are candidates in the **CITY of Patterson, California** (Clauzel, Farinha,
--   Fierros, Homen, Leonard, Lustgarten, Mataka, McComak, Parham) — the same place-name trap as
--   Dixon, and 🟢 **we hold no government named Patterson**, so none of them can be here either.
--
-- **John M. Erickson, 13.** Brian (a San Diego judge), George, Donna, Paul L., Molly, T., Tory,
--   Victoria, Leslie, Stephanie, plus three forename-less ones that are placed by jurisdiction:
--   Orange Unified (714), Soquel Union in Santa Cruz (831), and 1026092, whose filer id predates his
--   2020 election by two decades. None is West Hollywood. Only Brian's holds money (323).
--
-- **Angie Reyes English, 12.** Ken (a Sonoma County judge, 167 contributions), Alice (Tracy), Tony
--   (Laguna Niguel, three committees sharing one filer phone), Jamila, Don, Cornell, John, Lance,
--   and `CALIFORNIA ENGLISH CAMPAIGN`, a 1990s ballot-measure committee filed from Nevada.
--   None is Hawthorne. 🟢 Her OWN committees are not in this bucket at all — they sit on
--   `cal_access_discovery` placeholder rows ("REYES ENGLISH HAWTHORNE COUNCIL 2024" and friends),
--   which hold **zero contributions**, the same CAL-ACCESS ingestion gap `CC_0214` recorded.
--
-- **Bryan "Bubba" Fish, 5 of 6.** Jonathan (an Orange County judge, 9 contributions), Nanette,
--   Barbara, Charlie, and `CALIFORNIA WATER, FISH, & FORESTS 98'` — a 1998 ballot committee that is
--   not a person at all.
--
--
-- ══ PART B — ONE STAYS `disputed`, BECAUSE IT IS GENUINELY UNDETERMINED ══════════════════════
--
--     1465836  FISH FOR CITY COUNCIL 2028   0 contributions
--
-- No forename. The seated Bryan Fish is a Culver City council member and this is the only committee
-- in his bucket with a 310 filer phone, so it may well be his — but nothing available settles it:
-- CAL-ACCESS lists no FISH on its **state** candidate index (he is a local filer), and we hold no
-- NetFile agency for Culver City (only `LACO` and `WEHO`).
-- ▶ **`not_applicable` would assert "this is not his committee", which is a claim, not a shrug.**
-- `disputed` is the honest state for a row nobody has been able to place. It publishes nothing
-- either way.
--
--
-- ══ PART C — FIVE CONFIRMATIONS THAT WERE NEVER EARNED ═══════════════════════════════════════
--
-- 🔴🔴 **`CC_0213` LEFT FIVE SOURCES `confirmed` ON DAVID PATTERSON'S ROW, AND THEY CANNOT ALL BE
-- ONE MAN.** Its detach predicate kept any committee whose name contained the row's forename, so
-- every "…; DAVID" survived. Read together they describe two people ~400 miles apart:
--
--     1378890  PATTERSON FOR CITY COUNCIL 2015; DAVID                      (562) 983-0815
--     1411761  PATTERSON FOR CITY TREASURER 2018; DAVID                    (562) 983-0815
--     1359739  PATTERSON FOR TREASURER 2013, DAVID                         (562) 983-0815
--     1349392  PATTERSON TO THE PLACER COUNTY BOARD OF EDUCATION 2016      (916) 801-2454
--     1425211  PATTERSON PLACER COUNTY BOARD OF EDUCATION 2020; REELECT DAVID  (916) 801-2454
--
-- Nobody holds a Signal-Hill-area city treasurership and a Placer County school board seat at once.
-- And **neither cluster is Hawthorne**, the only jurisdiction this row carries — whose council,
-- clerk and treasurer seats we hold in full, and which seats no Patterson.
--
-- ▶ **They are downgraded to `disputed`, NOT to `not_applicable`.** One of the two clusters could
-- still be this row's person; what is disproved is that all five are. `not_applicable` would assert
-- more than is known. All five hold **zero contributions**, so nothing published changes — but a
-- `confirmed` source is a loaded gun: it publishes the moment either the CAL-ACCESS ingestion gap
-- closes or somebody merges this row into a live person. That is exactly the `CC_0213` harm, armed.
--
-- 🟢 **John M. Erickson's three confirmations ARE earned and are left alone** — 1479089 and 1489255
-- name him, and 1423886 is "ERICKSON FOR WH CITY COUNCIL 2020; JOHN", naming the very seat his live
-- row holds. That is the `CC_0212` test: the source names the seat, which beats the name.
--
-- ⚠ **A FILER PHONE IS THE TREASURER'S NUMBER, NOT THE CANDIDATE'S — IT GROUPS, IT DOES NOT
-- IDENTIFY.** Measured here: **(310) 817-6679** is shared by `PATTERSON FOR CITY COUNCIL 2024` and
-- `FISH FOR CITY COUNCIL 2028`, and **(323) 655-4065** by `PATTERSON FOR MALIBU CITY COUNCIL 2014`
-- and John Erickson's own `ERICKSON FOR WH CITY COUNCIL 2020`. Unrelated candidates, one filing
-- agent. `CC_0216` leaned on a phone match as one of three signals for `DIXON FOR SUPERVISOR 2026`;
-- that conclusion still stands on the other two (an explicit non-conflicting forename, and donor
-- overlap of 12.4-62.8% against 0.0-4.4% for controls), but **the phone leg was weaker than that
-- migration's comment claims.** Treat a shared phone as "same filing agent", never "same person".
--
-- NOT DONE HERE, deliberately: the three merges, and the 1,486 disputed `cal_access` sources
-- elsewhere in the corpus — 319 politicians, many of them ACTIVE.

BEGIN;

DO $$
DECLARE
  v_cnt       bigint;
  v_contrib0  bigint;
  n_na        int := 0;
  n_down      int := 0;
BEGIN
  -- ── idempotence
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE p.id::text LIKE '903b537b%' AND s.research_status = 'confirmed';
  IF v_cnt = 0 THEN
    RAISE NOTICE 'CC_0217: already applied (David Patterson holds no confirmed sources) — skipping';
    RETURN;
  END IF;

  -- ── resolve the four bucket rows by id prefix
  CREATE TEMP TABLE _rows ON COMMIT DROP AS
    SELECT p.id, p.full_name
      FROM essentials.politicians p
     WHERE p.id::text LIKE '903b537b%' OR p.id::text LIKE 'af66146f%'
        OR p.id::text LIKE '97f376e1%' OR p.id::text LIKE '837613f5%';

  SELECT count(*) INTO v_cnt FROM _rows;
  IF v_cnt <> 4 THEN RAISE EXCEPTION 'CC_0217: resolved % bucket rows, expected 4', v_cnt; END IF;

  -- all four must be inactive. Adjudicating sources off a LIVE page is a different decision, and
  -- three of these rows have a live twin whose page must not move until the merge is done properly.
  SELECT count(*) INTO v_cnt
    FROM _rows r JOIN essentials.politicians p ON p.id = r.id WHERE p.is_active;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0217: % bucket rows are ACTIVE — refusing', v_cnt; END IF;

  -- the 95 must be there, all cal_access, all with parseable notes, 87 disputed and 8 confirmed
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id;
  IF v_cnt <> 95 THEN RAISE EXCEPTION 'CC_0217: rows hold % sources, expected 95', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.source_system <> 'cal_access' OR s.notes IS NULL;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'CC_0217: % sources are not cal_access rows with notes', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 87 THEN RAISE EXCEPTION 'CC_0217: % disputed sources, expected 87', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.research_status = 'confirmed';
  IF v_cnt <> 8 THEN RAISE EXCEPTION 'CC_0217: % confirmed sources, expected 8', v_cnt; END IF;

  -- hold the 95 ids so "nothing was touched" can be asked of exactly these rows. Asking it of the
  -- whole `contributions` table exceeds the statement timeout — CC_0213 recorded that trap.
  CREATE TEMP TABLE _srcs ON COMMIT DROP AS
    SELECT s.id FROM transparent_motivations.politician_sources s
      JOIN _rows r ON r.id = s.essentials_politician_id;

  SELECT count(*) INTO v_contrib0
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);

  -- ── PART A + B: every disputed source EXCEPT 1465836 has a known owner outside this corpus.
  --    Runs BEFORE part C, so the five downgraded confirmations are not swept up by it.
  WITH moved AS (
    UPDATE transparent_motivations.politician_sources s
       SET research_status = 'not_applicable',
           notes = (s.notes::jsonb || jsonb_build_object(
                      'adjudicated_by','CC_0217',
                      'adjudication','committee belongs to a person with no row in this corpus'))::text,
           updated_at = now()
      FROM _rows r
     WHERE s.essentials_politician_id = r.id
       AND s.source_system = 'cal_access'
       AND s.research_status = 'disputed'
       AND s.external_id <> '1465836'
    RETURNING 1)
  SELECT count(*) INTO v_cnt FROM moved;
  n_na := v_cnt::int;
  IF n_na <> 86 THEN RAISE EXCEPTION 'CC_0217: marked % not_applicable, expected 86', n_na; END IF;

  -- 1465836 must still be disputed, and must still be exactly one row on the Fish bucket.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.external_id = '1465836' AND s.research_status = 'disputed'
     AND r.id::text LIKE '837613f5%';
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'CC_0217: FISH FOR CITY COUNCIL 2028 resolves to % disputed rows, expected 1', v_cnt;
  END IF;

  -- ── PART C: downgrade the five unearned confirmations on David Patterson's row.
  --    Named explicitly, so this can never reach John Erickson's three earned ones.
  WITH down AS (
    UPDATE transparent_motivations.politician_sources s
       SET research_status = 'disputed',
           notes = (s.notes::jsonb || jsonb_build_object(
                      'adjudicated_by','CC_0217',
                      'adjudication','confirmed by CC_0213 on the forename DAVID alone; these five describe two different David Pattersons (Signal Hill area and Placer County) and neither is Hawthorne, this row''s only jurisdiction'))::text,
           updated_at = now()
      FROM _rows r
     WHERE s.essentials_politician_id = r.id
       AND r.id::text LIKE '903b537b%'
       AND s.research_status = 'confirmed'
       AND s.external_id IN ('1378890','1411761','1359739','1349392','1425211')
    RETURNING 1)
  SELECT count(*) INTO v_cnt FROM down;
  n_down := v_cnt::int;
  IF n_down <> 5 THEN RAISE EXCEPTION 'CC_0217: downgraded % confirmations, expected 5', n_down; END IF;

  -- ══ POST-VERIFY ═════════════════════════════════════════════════════════════════════════════

  -- 1. End state across the four rows: 86 not_applicable, 6 disputed, 3 confirmed.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.research_status = 'not_applicable';
  IF v_cnt <> 86 THEN RAISE EXCEPTION 'CC_0217: % not_applicable, expected 86', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.research_status = 'disputed';
  IF v_cnt <> 6 THEN RAISE EXCEPTION 'CC_0217: % disputed, expected 6 (1 Fish + 5 Patterson)', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.research_status = 'confirmed';
  IF v_cnt <> 3 THEN RAISE EXCEPTION 'CC_0217: % confirmed, expected 3 (Erickson only)', v_cnt; END IF;

  -- 2. 🔴 THE ONE THAT MATTERS: every surviving confirmation must sit on John M. Erickson's row and
  --    name him. David Patterson's row must publish NOTHING that merging it could later expose.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id
   WHERE s.research_status = 'confirmed'
     AND (r.id::text NOT LIKE 'af66146f%'
          OR upper((s.notes::jsonb->>'committee_name')) NOT LIKE '%JOHN%');
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0217: % confirmed sources are not John Erickson''s own named committees', v_cnt;
  END IF;

  -- 3. Erickson keeps his 981 contributions. This is the CC_0213 middle-name trap, asserted:
  --    his first_name is "John M.", and a naive forename compare detaches his own money.
  SELECT count(c.id) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    LEFT JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.essentials_politician_id::text LIKE 'af66146f%'
     AND s.research_status = 'confirmed' AND s.source_type = 'candidate_committee';
  IF v_cnt <> 981 THEN
    RAISE EXCEPTION 'CC_0217: John M. Erickson publishes % contributions, expected 981', v_cnt;
  END IF;

  -- 4. Nothing else on these four rows publishes.
  SELECT count(c.id) INTO v_cnt
    FROM transparent_motivations.politician_sources s
    JOIN _rows r ON r.id = s.essentials_politician_id
    JOIN transparent_motivations.contributions c ON c.politician_source_id = s.id
   WHERE s.research_status = 'confirmed' AND s.source_type = 'candidate_committee'
     AND r.id::text NOT LIKE 'af66146f%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'CC_0217: % contributions still publish on a row other than Erickson''s', v_cnt;
  END IF;

  -- 5. No source left these four rows — this migration repoints nothing, unlike CC_0216.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.politician_sources s JOIN _rows r ON r.id = s.essentials_politician_id;
  IF v_cnt <> 95 THEN RAISE EXCEPTION 'CC_0217: rows now hold % sources, expected 95', v_cnt; END IF;

  -- 6. No contribution row was touched or stranded.
  SELECT count(*) INTO v_cnt
    FROM transparent_motivations.contributions c WHERE c.politician_source_id IN (SELECT id FROM _srcs);
  IF v_cnt <> v_contrib0 THEN
    RAISE EXCEPTION 'CC_0217: the 95 sources carried % contributions and now carry %', v_contrib0, v_cnt;
  END IF;

  RAISE NOTICE 'CC_0217: 86 not_applicable, 5 confirmations downgraded, 1 left disputed, 0 repointed';
END $$;

COMMIT;
