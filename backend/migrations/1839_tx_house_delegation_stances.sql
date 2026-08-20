-- 1839_tx_house_delegation_stances.sql
-- Texas US House delegation: first stances for members who carried none, plus a bioguide_id backfill.
--
-- ALREADY APPLIED to prod 2026-08-19; idempotent so re-applying is a no-op. The research CSV is
-- gitignored, so this migration is the repo's audit trail for a voter-facing change.
--
-- WHY THIS IS ONLY SIX ROWS
--
-- Eleven of the 37 seated Texas US House members had zero stances. Seven landmark 119th-Congress
-- roll calls were pulled from the House Clerk electronic voting system and each member's Yea/Nay
-- read from the XML. Exactly ONE is chair-determinative, and only for members who voted Yea. The
-- refusals are the substance of this migration:
--
--   H.R. 28  Protection of Women and Girls in Sports Act (roll 12)  -> USED.
--     Single-subject, and the operative content IS the chair text: it amends Title IX so federally
--     funded schools may not let athletes whose sex assigned at birth is male compete in women's
--     programs. That is chair 4 (compete only on teams matching sex assigned at birth) and NOT
--     chair 5 -- it does not bar transgender athletes from organized sport, only from teams not
--     matching birth sex. That distinction is what lets the vote pin a chair at all.
--
--   H.R. 1   reconciliation (roll 145)  -> REFUSED. Its tax title matches the taxes chair 4 text
--     almost verbatim, but the bill is an OMNIBUS carrying border, defense and Medicaid provisions;
--     a Yea may be cast for any of them, so it cannot pin a tax chair.
--   H.R. 21  Born-Alive Act (roll 27)   -> REFUSED. Concerns care after a live birth, not the
--     gestational framework the abortion ladder asks about. It splits cleanly on party lines, which
--     is exactly why it is tempting and wrong.
--   S. 5     Laken Riley Act (roll 23)  -> REFUSED. Mandatory detention on charge is consistent
--     with deportation chairs 2, 4 AND 5, and it passed with bipartisan support.
--   H.R. 26  Energy Production (roll 35)-> REFUSED. Two of the five Democrats voted Yea. A vote
--     both parties split cannot be chair-determinative.
--   H.R. 22  SAVE Act (roll 102)        -> REFUSED. Documentary proof of citizenship at
--     REGISTRATION is not chair 4 photo ID for voting.
--
-- THE METHOD IS ASYMMETRIC, AND THAT IS NOT EDITORIAL BIAS. A Yea on a single-subject bill can name
-- a chair; a Nay only says "not that", leaving two or three chairs open. So this pass yields rows
-- for the six members who voted Yea and NONE for the five who voted Nay. The fix is evidence of the
-- same STANDARD for them -- sponsored bills and their own issue pages -- not weaker rows written
-- for balance. Row-count parity bought by lowering the bar is worse than the gap. Do not even this
-- up by guessing.
--
-- bioguide_id was NULL on all 11. Each was resolved 1:1 against the @unitedstates legislators data
-- and cross-checked on district (all 11 matched the seat we hold), then backfilled.
--
-- Idempotency: ON CONFLICT DO NOTHING; the bioguide UPDATE is guarded with IS DISTINCT FROM.

BEGIN;

WITH src(politician_id, topic_key, value, reasoning, sources) AS (VALUES
  ('deae1b6d-3aa5-43fe-aff3-df73052cc434', 'trans-athletes', 4,
   'Crenshaw voted Yea on H.R. 28, the Protection of Women and Girls in Sports Act, on 14 January 2025 (roll call 12, passed 218-206). The bill amends Title IX so that schools receiving federal funds may not allow athletes whose sex assigned at birth is male to compete in women''s or girls'' athletic programs. That is a requirement to compete on the team matching sex assigned at birth. It stops short of barring transgender athletes from organized sport altogether, which is why this vote places him at that position rather than a full ban.',
   ARRAY['https://clerk.house.gov/evs/2025/roll012.xml']),
  ('b638dec8-86d9-4741-959f-002e7850a630', 'trans-athletes', 4,
   'Luttrell voted Yea on H.R. 28, the Protection of Women and Girls in Sports Act, on 14 January 2025 (roll call 12, passed 218-206). The bill amends Title IX so that schools receiving federal funds may not allow athletes whose sex assigned at birth is male to compete in women''s or girls'' athletic programs. That is a requirement to compete on the team matching sex assigned at birth. It stops short of barring transgender athletes from organized sport altogether, which is why this vote places him at that position rather than a full ban.',
   ARRAY['https://clerk.house.gov/evs/2025/roll012.xml']),
  ('1139cf4b-c7be-464f-b343-69c4b0f8ace6', 'trans-athletes', 4,
   'McCaul voted Yea on H.R. 28, the Protection of Women and Girls in Sports Act, on 14 January 2025 (roll call 12, passed 218-206). The bill amends Title IX so that schools receiving federal funds may not allow athletes whose sex assigned at birth is male to compete in women''s or girls'' athletic programs. That is a requirement to compete on the team matching sex assigned at birth. It stops short of barring transgender athletes from organized sport altogether, which is why this vote places him at that position rather than a full ban.',
   ARRAY['https://clerk.house.gov/evs/2025/roll012.xml']),
  ('2bbfde18-85fc-4beb-9378-ec22e955a78a', 'trans-athletes', 4,
   'Arrington voted Yea on H.R. 28, the Protection of Women and Girls in Sports Act, on 14 January 2025 (roll call 12, passed 218-206). The bill amends Title IX so that schools receiving federal funds may not allow athletes whose sex assigned at birth is male to compete in women''s or girls'' athletic programs. That is a requirement to compete on the team matching sex assigned at birth. It stops short of barring transgender athletes from organized sport altogether, which is why this vote places him at that position rather than a full ban.',
   ARRAY['https://clerk.house.gov/evs/2025/roll012.xml']),
  ('815bc4fa-a987-4245-9fa1-cb1026ca3ee5', 'trans-athletes', 4,
   'Roy voted Yea on H.R. 28, the Protection of Women and Girls in Sports Act, on 14 January 2025 (roll call 12, passed 218-206). The bill amends Title IX so that schools receiving federal funds may not allow athletes whose sex assigned at birth is male to compete in women''s or girls'' athletic programs. That is a requirement to compete on the team matching sex assigned at birth. It stops short of barring transgender athletes from organized sport altogether, which is why this vote places him at that position rather than a full ban.',
   ARRAY['https://clerk.house.gov/evs/2025/roll012.xml']),
  ('0248c3ba-caea-4421-9be3-ceaa6e0df69e', 'trans-athletes', 4,
   'Hunt voted Yea on H.R. 28, the Protection of Women and Girls in Sports Act, on 14 January 2025 (roll call 12, passed 218-206). The bill amends Title IX so that schools receiving federal funds may not allow athletes whose sex assigned at birth is male to compete in women''s or girls'' athletic programs. That is a requirement to compete on the team matching sex assigned at birth. It stops short of barring transgender athletes from organized sport altogether, which is why this vote places him at that position rather than a full ban.',
   ARRAY['https://clerk.house.gov/evs/2025/roll012.xml'])
),
resolved AS (
  SELECT s.politician_id::uuid AS pid, t.id AS tid, s.value::numeric AS val, s.reasoning, s.sources
  FROM src s JOIN inform.compass_topics t ON t.topic_key = s.topic_key AND t.is_live = true
),
ins_a AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT pid, tid, val FROM resolved
  ON CONFLICT (politician_id, topic_id) DO NOTHING
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pid, tid, reasoning, sources FROM resolved
ON CONFLICT (politician_id, topic_id) DO NOTHING;

UPDATE essentials.politicians p SET bioguide_id = v.bg
FROM (VALUES
  ('deae1b6d-3aa5-43fe-aff3-df73052cc434','C001120'),('b638dec8-86d9-4741-959f-002e7850a630','L000603'),
  ('449ad20f-7190-4c59-9809-0805e5a0edd8','G000553'),('1139cf4b-c7be-464f-b343-69c4b0f8ace6','M001157'),
  ('2bbfde18-85fc-4beb-9378-ec22e955a78a','A000375'),('815bc4fa-a987-4245-9fa1-cb1026ca3ee5','R000614'),
  ('10d7e182-3200-41d1-b391-2b9abad273ca','C001130'),('db2251fb-8188-4d17-917f-ade709e5e498','J000310'),
  ('b9f6f264-b42d-4bf6-b069-3a0d8d1f3b95','V000131'),('ad8e300f-59f0-4cc6-a818-1986842353d1','D000399'),
  ('0248c3ba-caea-4421-9be3-ceaa6e0df69e','H001095')
) AS v(id, bg)
WHERE p.id = v.id::uuid AND p.bioguide_id IS DISTINCT FROM v.bg;

DO $$
DECLARE
  v_ids uuid[] := ARRAY[
    'deae1b6d-3aa5-43fe-aff3-df73052cc434','b638dec8-86d9-4741-959f-002e7850a630',
    '1139cf4b-c7be-464f-b343-69c4b0f8ace6','2bbfde18-85fc-4beb-9378-ec22e955a78a',
    '815bc4fa-a987-4245-9fa1-cb1026ca3ee5','0248c3ba-caea-4421-9be3-ceaa6e0df69e']::uuid[];
  v_rows int; v_ctx int; v_bio int;
BEGIN
  SELECT count(*) INTO v_rows
    FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'trans-athletes'
   WHERE a.politician_id = ANY(v_ids) AND a.value = 4;
  IF v_rows <> 6 THEN
    RAISE EXCEPTION 'Expected 6 trans-athletes rows at chair 4, found %', v_rows;
  END IF;

  SELECT count(*) INTO v_ctx
    FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id = a.topic_id AND t.topic_key = 'trans-athletes'
    JOIN inform.politician_context c ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE a.politician_id = ANY(v_ids)
     AND btrim(coalesce(c.reasoning,'')) <> '' AND coalesce(array_length(c.sources,1),0) > 0;
  IF v_ctx <> 6 THEN
    RAISE EXCEPTION 'Expected 6 contexts with reasoning AND sources, found %', v_ctx;
  END IF;

  SELECT count(*) INTO v_bio FROM essentials.politicians
   WHERE bioguide_id IN ('C001120','L000603','G000553','M001157','A000375','R000614',
                         'C001130','J000310','V000131','D000399','H001095');
  IF v_bio <> 11 THEN
    RAISE EXCEPTION 'Expected 11 bioguide_id present, found %', v_bio;
  END IF;

  RAISE NOTICE 'OK: 6 trans-athletes stances at chair 4 with sourced reasoning; 11 bioguide_id present.';
END $$;

COMMIT;
