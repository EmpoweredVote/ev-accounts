-- CA_0193_season2_housing_barragan_reresearch.sql
-- Season 2 re-research of Rep. Nanette Diaz Barragán's Housing answer (U.S. House CA-44). The Season 2 row held
-- chair 3, carried mechanically from her Season 1 chair 2 by CC_0058's rung_map and never researched against the
-- Season 2 ladder. Her record describes chair 2. One UPDATE of one answer and its context; nothing is inserted or
-- deleted.
-- Slot CA_0193 reserved via `steward slot CA` before this file existed. Author: Chris Andrews.
--
-- WHY. CA_0190 left this row as a lead ("NOT IN THIS FILE: Barragán's Season 2 Housing row"). CC_0058 re-indexed Season
-- 1 answers onto the Season 2 ladder by rung_map {1:1,2:3,3:4,4:5,5:5}, so her Season 1 chair 2 ("rent caps, required
-- affordable units, and publicly fund new housing") landed on Season 2 chair 3 ("Build no public housing, but set binding
-- rules on the private market like rent caps or required affordable units"). The context was copied verbatim: it still
-- ends "aligns with new stance 2", it names no rent cap or inclusionary rule, and its evidence (the Yes in God's Backyard
-- Act, the Returning Home Act, federal funding for her district) is grants and rental assistance, which describe
-- subsidies, not chair 3.
--
-- THE LADDER IS THE ONE SEASON 2 SERVES: housing pin r3 (v2), which is also the latest published revision of v2 (r2 was
-- rejected), so pin and served text agree. Its rationale (CA_0043) defines the rungs as mutually exclusive by how far
-- government should go, and chair 2 as the NEW public option: "large public sector competing with the market, market
-- stays the norm". The pre-flight re-reads chair 2's served text and refuses if it differs from the text researched
-- against.
--
-- THE EVIDENCE (Season 1 value 2 -> Season 2 carry 3 -> Season 2 chair 2):
--   Homes Act of 2024 (H.R. 9662, 118th; cosponsored 2024-12-19). A Housing Development Authority inside HUD builds or
--     acquires "permanently affordable social housing" (owned by the Authority or conveyed to public housing agencies,
--     nonprofits, tenant cooperatives or land trusts), "as an alternative to market-rate housing", for families unable to
--     afford market rents. $30B a year for FY2025-2035, a $150B loan-liability ceiling, and repeal of the Faircloth
--     Amendment (the cap on public housing units). This is the public option chair 2 was written for.
--   Green New Deal for Public Housing Act (H.R. 7782, 118th; original cosponsor 2024-03-21; also H.R. 2664, 117th,
--     cosponsored 2022-03-09). Modernizes the public housing stock; repeals Faircloth.
--   H.Res. 568 (117th; cosponsored 2022-09-13). Right to decent, affordable housing; $140B every five years for the Public
--     Housing Capital Fund; Faircloth repeal; universal Housing Choice Vouchers.
--   barragan.house.gov/housing-homeless/: she supports "efforts that combine housing market-driven solutions, federal
--     support and state and local initiatives" -- private housing stays the norm.
--   Not chair 1: nothing found makes government the MAIN provider. H.Res. 568's right to housing is met with universal
--     vouchers, which rent private housing. Not 3 or 4: both exclude building public housing.
--   Consistent, not decisive: original cosponsor of the Housing for All Act in the 117th-119th (H.R. 6989, H.R. 5254,
--     H.R. 2945; the 119th text funds the Housing Trust Fund and vouchers); her own YIGBY Act (H.R. 7152) and Returning
--     Home Act (H.R. 7057) are grant programs; the Protecting Renters from Evictions Act (H.R. 4791, 2021, original
--     cosponsor) extended the eviction moratorium. None of them excludes chair 2.
--   ⚖ JUDGMENT CALL: the Homes Act and the Green New Deal for Public Housing Act are 118th-Congress cosponsorships. The
--     Homes Act has not been reintroduced in the 119th; she is not (as of 2026-09-23) among the 41 cosponsors of the
--     119th Green New Deal for Public Housing Act (H.R. 10063, introduced 2026-08-06), nor was she on the 116th version
--     (H.R. 5185) or the standalone Faircloth repeal (H.R. 659, 117th). Absence of a cosponsorship is not a contrary act,
--     and nothing found withdraws or contradicts the 2024 positions.
-- Searched: all 3,339 bills she sponsored or cosponsored (api.congress.gov, member B001300), filtered to housing; bill
-- text on govinfo.gov; 376 barragan.house.gov posts matching housing terms (no rent-control, rent-cap, social-housing or
-- inclusionary-zoning statement found). No House roll call was needed: nothing found is a vote on public housing.
--
-- 🔴 SEASON 1 IS NOT TOUCHED (it is closed, and inform.closed_season_is_immutable() would refuse anyway), and neither is
-- any other row. Asserted by fingerprint at the bottom: every answer, context and evidence row in the corpus except this
-- one Season 2 pair must hash the same after this file as before it.
--
-- No migration runner exists; this file records SQL applied by hand. Pure DML.
-- STATUS: APPLIED to prod 2026-09-23 (operator approval: Chris Andrews). Before the apply: dry run x2 (BEGIN ... ROLLBACK;
--   the second ran the body twice to prove the re-run is a no-op), each with a whole-corpus snapshot control that read
--   identical afterwards, and a positive control (a planted 1-second change to Barragán's Season 2 campaign-finance
--   context) that the fingerprint gate caught. After: a re-run wrote nothing; the control differs only in the answers and
--   context hashes (counts unchanged) and the target pair; check:stance-sources at baseline (0 / 179 / 1 / 0 / 0 / 0 / 50
--   / 670); audit-chair-evidence --check OK on the Season 2 row (season_id set in the rollback file).
--
-- ROLLBACK: backend/data/stance-retirement/2026-09-23-ca0193-barragan-housing-rollback.json holds the Season 2
-- pre-image. Set the answer back to 3 and restore the context reasoning and sources from the file.
-- IDEMPOTENT: each write is guarded on its pre-image; a re-run writes nothing and every gate still passes.

BEGIN;

-- ─── The row ─────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE _ca0193_row (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  topic_key     text NOT NULL,
  s1_value      int  NOT NULL,     -- the Season 1 answer (untouched), for the record
  carried_value int  NOT NULL,     -- the CC_0058 carry this file replaces
  value         int  NOT NULL,
  served_text   text NOT NULL,
  reasoning     text NOT NULL,
  sources       text[] NOT NULL,
  PRIMARY KEY (politician_id, topic_key)
) ON COMMIT DROP;

INSERT INTO _ca0193_row VALUES
('5bd54ac0-c8b9-486c-844c-ecc4313e5de7', 'Nanette Diaz Barragán', 'housing', 2, 3, 2,
 'Build a large public housing sector that competes with the private market to hold prices down, while private housing stays the norm.',
 $r$Barragán backs a large public housing option that operates alongside the private market. She cosponsored the Homes Act of 2024 (H.R. 9662, 118th Congress, cosponsored 2024-12-19). It creates a Housing Development Authority within HUD "to develop a stock of permanently affordable, quality, publicly financed, and climate resilient housing that is shielded from market speculation," and to maintain "a housing system, as an alternative to market-rate housing," for families unable to afford market rents. The Authority would own this housing or convey it to public housing agencies, nonprofits, tenant cooperatives or community land trusts, under a permanent affordability restriction. The bill authorizes $30 billion a year for fiscal years 2025 through 2035 and repeals the Faircloth Amendment, the federal cap on the number of public housing units. She was an original cosponsor of the Green New Deal for Public Housing Act (H.R. 7782, 118th Congress, 2024-03-21), which modernizes the public housing stock and also repeals the Faircloth Amendment. She cosponsored H.Res. 568 (117th Congress, 2022-09-13), which calls for $140 billion every five years for the Public Housing Capital Fund. Her own statement keeps private housing as the norm: her housing page says she supports "efforts that combine housing market-driven solutions, federal support and state and local initiatives." No bill or statement found makes government the main provider of housing. H.Res. 568 states a right to decent, affordable housing, but it would meet that right with universal Housing Choice Vouchers, which pay rent in private housing. Her own bills add subsidies to this approach: the Yes in God's Backyard Act (H.R. 7152, 2026) gives technical assistance to faith-based organizations and colleges, and grants to local governments that remove barriers to affordable rental housing on their land, and the Returning Home Act (H.R. 7057, 2026) funds rental assistance for people returning from incarceration.$r$,
 ARRAY[$r$https://www.congress.gov/bill/118th-congress/house-bill/9662/cosponsors$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-118hr9662ih/html/BILLS-118hr9662ih.htm$r$,
       $r$https://www.congress.gov/bill/118th-congress/house-bill/7782/cosponsors$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-118hr7782ih/html/BILLS-118hr7782ih.htm$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-117hres568ih/html/BILLS-117hres568ih.htm$r$,
       $r$https://barragan.house.gov/housing-homeless/$r$,
       $r$https://www.govinfo.gov/content/pkg/BILLS-119hr7152ih/html/BILLS-119hr7152ih.htm$r$]);

-- The pin the row sits on: read from season_questions, never hand-typed.
CREATE TEMP TABLE _ca0193_target ON COMMIT DROP AS
SELECT r.*, sq.season_id, sq.topic_id, sq.topic_revision_id
  FROM _ca0193_row r
  JOIN inform.compass_topics_promoted pr ON pr.topic_key = r.topic_key
  JOIN inform.season_questions sq ON sq.topic_id = pr.id
  JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open';

-- Fingerprints of everything this file must NOT change: the whole corpus minus the one target pair. Hard-coded ids (no
-- temp-table references) so the view can be dropped cleanly before COMMIT.
CREATE OR REPLACE TEMP VIEW _ca0193_fp_now AS
WITH tgt(pid, tid, sid) AS (VALUES ('5bd54ac0-c8b9-486c-844c-ecc4313e5de7'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid,
                                    '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid))
SELECT 'answers, all but target' AS k, count(*) AS n,
       md5(coalesce(string_agg(concat_ws('|', a.politician_id, a.topic_id, a.season_id, a.value, a.write_in_text, a.topic_revision_id, a.editor_id, a.updated_at), E'\n' ORDER BY a.politician_id, a.topic_id, a.season_id), '')) AS h
  FROM inform.politician_answers a
 WHERE (a.politician_id, a.topic_id, a.season_id) NOT IN (SELECT pid, tid, sid FROM tgt)
UNION ALL
SELECT 'context, all but target', count(*),
       md5(coalesce(string_agg(concat_ws('|', c.politician_id, c.topic_id, c.season_id, c.reasoning, c.sources::text, c.topic_revision_id, c.editor_id, c.updated_at), E'\n' ORDER BY c.politician_id, c.topic_id, c.season_id), ''))
  FROM inform.politician_context c
 WHERE (c.politician_id, c.topic_id, c.season_id) NOT IN (SELECT pid, tid, sid FROM tgt)
UNION ALL
SELECT 'evidence, all', count(*),
       md5(coalesce(string_agg(concat_ws('|', e.id, e.politician_id, e.topic_id, e.season_id, e.source_url, e.snippet, e.snippet_index, e.verified_at, e.batch_id), E'\n' ORDER BY e.id), ''))
  FROM inform.politician_context_evidence e;

CREATE TEMP TABLE _ca0193_fp_before ON COMMIT DROP AS SELECT * FROM _ca0193_fp_now;
CREATE TEMP TABLE _ca0193_state (run text NOT NULL, s2_answers int NOT NULL, s2_context int NOT NULL) ON COMMIT DROP;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; rec record; v_served text; v_st text;
BEGIN
  IF (SELECT status FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3') IS DISTINCT FROM 'closed'
  OR (SELECT status FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194') IS DISTINCT FROM 'open' THEN
    RAISE EXCEPTION 'CA_0193: expected Season 1 closed and Season 2 open';
  END IF;

  IF (SELECT count(*) FROM _ca0193_target) <> 1
  OR (SELECT count(*) FROM _ca0193_target WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
                                              AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
                                              AND topic_revision_id = '598c879d-f387-461c-9120-fbbbf6314bbc') <> 1 THEN
    RAISE EXCEPTION 'CA_0193: expected the row to resolve to the Season 2 housing pin r3 (598c879d), got % row(s)',
      (SELECT count(*) FROM _ca0193_target);
  END IF;

  -- The person: active, seated, named as the row says; and the topic admits a federal seat.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = '5bd54ac0-c8b9-486c-844c-ecc4313e5de7' AND p.full_name = 'Nanette Diaz Barragán'
     AND p.is_active AND EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = p.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'CA_0193: expected Nanette Diaz Barragán active and holding a seat'; END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
                                                             AND role_scope::text = 'federal') THEN
    RAISE EXCEPTION 'CA_0193: housing does not admit the federal tier';
  END IF;

  -- Season 1 is the record and stays at 2; this file does not write it (the closed-season trigger would refuse).
  IF NOT EXISTS (SELECT 1 FROM inform.politician_answers
                  WHERE politician_id = '5bd54ac0-c8b9-486c-844c-ecc4313e5de7' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'
                    AND season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND value = 2) THEN
    RAISE EXCEPTION 'CA_0193: Season 1 housing answer is not the value 2 this file was researched against';
  END IF;

  -- The ladder: chair 2's served text (latest published revision of the pinned version) is the text the evidence was
  -- read against. A ladder edit after this file was written must stop it.
  FOR rec IN SELECT * FROM _ca0193_target LOOP
    SELECT sr.text INTO v_served
      FROM inform.compass_topic_revisions pin
      JOIN LATERAL (SELECT e.id FROM inform.compass_topic_revisions e
                     WHERE e.topic_id = pin.topic_id AND e.version = pin.version AND e.status IN ('published', 'superseded')
                     ORDER BY e.revision DESC LIMIT 1) eff ON true
      JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id AND sr.value = rec.value
     WHERE pin.id = rec.topic_revision_id;
    IF v_served IS DISTINCT FROM rec.served_text THEN
      RAISE EXCEPTION 'CA_0193: % / % chair % now serves "%", researched against "%"', rec.who, rec.topic_key, rec.value, v_served, rec.served_text;
    END IF;
  END LOOP;

  -- No evidence rows hang off the Season 2 context this file rewrites.
  SELECT count(*) INTO v_n FROM _ca0193_target t JOIN inform.politician_context_evidence e
      ON e.politician_id = t.politician_id AND e.topic_id = t.topic_id AND e.season_id = t.season_id;
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0193: % evidence row(s) on the target Season 2 context -- not expected', v_n; END IF;

  -- State: 'fresh' (the CC_0058 carry, as CA_0190 found it) or 'done' (this file has run). Anything else is a state
  -- this file did not create and must not overwrite.
  SELECT CASE
    WHEN a.value = t.carried_value AND a.topic_revision_id = t.topic_revision_id AND c.topic_revision_id = t.topic_revision_id
         AND c.reasoning LIKE 'Barragan co-chairs the Congressional Caucus on Homelessness and introduced the Yes in God''s Backyard Act (H.R. 7152%'
         AND c.reasoning LIKE '%aligns with new stance 2.' THEN 'fresh'
    WHEN a.value = t.value AND a.write_in_text IS NULL AND a.topic_revision_id = t.topic_revision_id
         AND c.topic_revision_id = t.topic_revision_id AND c.reasoning = t.reasoning AND c.sources = t.sources THEN 'done'
    ELSE 'other' END
    INTO v_st
    FROM _ca0193_target t
    JOIN inform.politician_answers a ON a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
    JOIN inform.politician_context c ON c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id;
  IF v_st IS NULL OR v_st = 'other' THEN
    RAISE EXCEPTION 'CA_0193: the Season 2 housing pair is neither the CC_0058 carry nor this file''s result (%) -- someone else has written here',
      coalesce(v_st, 'missing');
  END IF;

  INSERT INTO _ca0193_state
  SELECT CASE v_st WHEN 'fresh' THEN 'fresh' ELSE 'rerun' END,
         (SELECT count(*) FROM inform.politician_answers WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'),
         (SELECT count(*) FROM inform.politician_context WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194');

  RAISE NOTICE 'CA_0193 pre-flight OK (%): seasons, person, tier, Season 1 value, served ladder. Season 2 holds % answers / % context.',
    (SELECT run FROM _ca0193_state), (SELECT s2_answers FROM _ca0193_state), (SELECT s2_context FROM _ca0193_state);
END $$;

-- ─── Writes ─────────────────────────────────────────────────────────────────────────────────────
-- The CC_0058 carry (3) becomes chair 2, with reasoning and sources researched against the Season 2 ladder. Both
-- guarded on the pre-image, so a re-run matches nothing.
UPDATE inform.politician_answers a
   SET value = t.value, write_in_text = NULL, updated_at = now()
  FROM _ca0193_target t
 WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
   AND a.value = t.carried_value;

UPDATE inform.politician_context c
   SET reasoning = t.reasoning, sources = t.sources, updated_at = now()
  FROM _ca0193_target t
 WHERE c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id
   AND c.reasoning LIKE 'Barragan co-chairs the Congressional Caucus on Homelessness and introduced the Yes in God''s Backyard Act (H.R. 7152%'
   AND c.reasoning LIKE '%aligns with new stance 2.';

-- ─── Post-verify ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_a0 int; v_c0 int; v_a int; v_c int; v_run text;
BEGIN
  SELECT run, s2_answers, s2_context INTO v_run, v_a0, v_c0 FROM _ca0193_state;

  -- The target holds exactly what this file says, against the Season 2 pin.
  SELECT count(*) INTO v_n
    FROM _ca0193_target t
    JOIN inform.politician_answers a ON a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
    JOIN inform.politician_context c ON c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id
   WHERE a.value = t.value AND a.write_in_text IS NULL
     AND a.topic_revision_id = t.topic_revision_id AND c.topic_revision_id = t.topic_revision_id
     AND c.reasoning = t.reasoning AND c.sources = t.sources AND cardinality(c.sources) > 0;
  IF v_n <> 1 THEN RAISE EXCEPTION 'CA_0193: expected the target pair exactly as written, found %', v_n; END IF;

  -- Updates only: Season 2 counts do not move.
  SELECT count(*) INTO v_a FROM inform.politician_answers WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  SELECT count(*) INTO v_c FROM inform.politician_context WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF v_a <> v_a0 OR v_c <> v_c0 THEN
    RAISE EXCEPTION 'CA_0193: Season 2 counts moved (answers % -> %, context % -> %)', v_a0, v_a, v_c0, v_c;
  END IF;

  -- Every other answer, context and evidence row in the corpus: unchanged, by fingerprint.
  SELECT count(*) INTO v_n
    FROM _ca0193_fp_before b JOIN _ca0193_fp_now n USING (k)
   WHERE b.n <> n.n OR b.h <> n.h;
  IF v_n > 0 OR (SELECT count(*) FROM _ca0193_fp_now) <> 3 THEN
    RAISE EXCEPTION 'CA_0193: % protected fingerprint(s) changed (rows outside the target pair)', v_n;
  END IF;

  -- The CC_0058 §3f pair invariant, season-wide: every non-blank Season 2 answer has its context row.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id);
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0193: % non-blank Season 2 answer(s) have no context row', v_n; END IF;

  -- Her compass now reads chair 2: the newest-published-season collapse the read path uses.
  SELECT count(*) INTO v_n
    FROM _ca0193_target t
    JOIN LATERAL (SELECT a.value FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft'
                   WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id
                   ORDER BY s.number DESC LIMIT 1) latest ON true
   WHERE latest.value = t.value;
  IF v_n <> 1 THEN RAISE EXCEPTION 'CA_0193: the newest published season does not serve chair 2 for the target'; END IF;

  RAISE NOTICE 'CA_0193 OK (%): Barragán Season 2 Housing 3 -> 2 (public option). Season 2 still % answers / % context. Every other row unchanged.',
    v_run, v_a, v_c;
END $$;

DROP VIEW _ca0193_fp_now;

COMMIT;
