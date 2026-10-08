-- 1910_ca_campaign_themes_deeplink.sql
-- Two rows repaired by migration 1909 cite a bare Ballotpedia page when what they actually rest
-- on is the candidate's OWN Candidate Connection survey answer. Deep-link the anchor.
--
-- ══ WHY THIS IS A REAL FIX AND NOT A BASELINE BUMP ════════════════════════════════════════════
-- `npm run check:stance-sources` failed on migration 1909 with exactly two new BALLOTPEDIA_ONLY
-- rows, and the gate's own message says what to do:
--     "If the claim rests on the candidate's own Candidate Connection answers, deep-link
--      #Campaign_themes -- that counts."
-- It is right. A Candidate Connection response is WRITTEN BY THE CANDIDATE and published nowhere
-- else, so Ballotpedia is the primary source rather than a conduit -- but only the anchored URL
-- says so. A bare /Name page is still just a biography, which is the very defect this cohort
-- exists to clear.
--
-- 🔑 THE GENERAL LESSON, AND IT APPLIES BEYOND THESE TWO ROWS: a repair that improves only the
-- REASONING and leaves the citation byte-identical does not clear the detector, and should not
-- -- the detector reads SOURCES. Of the 32 rows migration 1909 repaired, 30 cite a Wikipedia
-- biography that genuinely carries the evidence in its body, and those remain legitimately
-- flagged as biography-sourced until someone cites the underlying roll call, ordinance or news
-- report the biography itself draws on. That is recorded as owed work, not papered over here.
--
-- Both anchors were verified present in the fetched HTML (id="Campaign_themes"), not assumed.
--
-- Season 1 is CLOSED and IMMUTABLE: every write here is forward, into Season 2.
-- No migration runner exists; this file records SQL applied by hand.

DO $pre$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_context c
    JOIN essentials.politicians p ON p.id = c.politician_id
    JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND c.reasoning LIKE 'Citation repaired%(migration 1909)%'
     AND (p.full_name, t.topic_key) IN (('Ana Valencia','public-safety-approach'),
                                        ('Patrick J. Ahrens','homelessness'))
     AND EXISTS (SELECT 1 FROM unnest(c.sources) u
                  WHERE u ILIKE '%ballotpedia.org/%' AND u NOT ILIKE '%#Campaign_themes%');
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1910: expected 2 bare-Ballotpedia repairs from 1909, found %', n;
  END IF;
END
$pre$;

-- Ana Valencia / public-safety-approach
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Ana_Valencia_(Norwalk_City_Council_At-large,_California,_candidate_2024)#Campaign_themes']::text[],
       updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND politician_id = 'ba647863-25fb-4ccf-9cb0-5a1c912d1b27'::uuid
   AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid;

-- Patrick J. Ahrens / homelessness
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Patrick_Ahrens#Campaign_themes']::text[],
       updated_at = now()
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND politician_id = 'bd4dc076-4bdd-4e10-be2c-80d998b17c50'::uuid
   AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a'::uuid;

DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_context c
    JOIN essentials.politicians p ON p.id = c.politician_id
    JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (p.full_name, t.topic_key) IN (('Ana Valencia','public-safety-approach'),
                                        ('Patrick J. Ahrens','homelessness'))
     AND EXISTS (SELECT 1 FROM unnest(c.sources) u WHERE u ILIKE '%#Campaign_themes%');
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1910: % of 2 rows now deep-link the anchor, expected 2', n;
  END IF;

  -- the chairs must not have moved
  SELECT count(*) INTO n
    FROM inform.politician_answers a
    JOIN essentials.politicians p ON p.id = a.politician_id
    JOIN inform.compass_topics t ON t.id = a.topic_id
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (p.full_name, t.topic_key) IN (('Ana Valencia','public-safety-approach'),
                                        ('Patrick J. Ahrens','homelessness'))
     AND a.value > 0;
  IF n <> 2 THEN
    RAISE EXCEPTION 'migration 1910: a chair moved; % of 2 still live', n;
  END IF;
END
$post$;
