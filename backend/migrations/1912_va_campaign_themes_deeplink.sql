-- 1912_va_campaign_themes_deeplink.sql
-- Five rows repaired by migration 1911 cite a bare Ballotpedia page when what they actually
-- rest on is the candidate's OWN Candidate Connection survey answer. Deep-link the anchor.
--
-- This is the same fix migration 1910 made for California, and it is worth stating as a rule
-- rather than a one-off: 🔑 WHEN THE EVIDENCE IS THE CANDIDATE'S OWN SURVEY ANSWER, THE
-- CITATION MUST BE THE ANCHOR, NOT THE PAGE. A Candidate Connection response is written by the
-- candidate and published nowhere else, so Ballotpedia is the primary source rather than a
-- conduit -- but only the anchored URL says so, and a bare /Name page is still a biography,
-- which is the defect this whole cohort exists to clear. `check-stance-sources` enforces
-- exactly this and names the remedy in its own failure message.
--
-- All three anchors were verified present in the fetched HTML (id="Campaign_themes").
-- ⚠ Four other 1911 repairs also cite Ballotpedia (Carroll Foy abortion, Deeds same-sex-marriage
-- and taxes, VanValkenburg housing) but carry a second non-Ballotpedia source, so the gate does
-- not flag them and their citations are left as they are.
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
     AND c.reasoning LIKE 'Citation repaired%(migration 1911)%'
     AND (p.full_name, t.topic_key) IN (
          ('Ghazala Hashmi','childcare'), ('Ghazala Hashmi','medicare/aid'),
          ('Ghazala Hashmi','economic-development'), ('Joshua G. Cole','taxes'),
          ('Sam Rasoul','civil-rights'))
     AND array_length(c.sources,1) = 1
     AND EXISTS (SELECT 1 FROM unnest(c.sources) u
                  WHERE u ILIKE '%ballotpedia.org/%' AND u NOT ILIKE '%#Campaign_themes%');
  IF n <> 5 THEN
    RAISE EXCEPTION 'migration 1912: expected 5 bare-Ballotpedia repairs from 1911, found %', n;
  END IF;
END
$pre$;

UPDATE inform.politician_context c
   SET sources = ARRAY[c.sources[1] || '#Campaign_themes']::text[], updated_at = now()
  FROM essentials.politicians p, inform.compass_topics t
 WHERE p.id = c.politician_id AND t.id = c.topic_id
   AND c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
   AND c.reasoning LIKE 'Citation repaired%(migration 1911)%'
   AND array_length(c.sources,1) = 1
   AND c.sources[1] ILIKE '%ballotpedia.org/%'
   AND c.sources[1] NOT ILIKE '%#Campaign_themes%'
   AND (p.full_name, t.topic_key) IN (
        ('Ghazala Hashmi','childcare'), ('Ghazala Hashmi','medicare/aid'),
        ('Ghazala Hashmi','economic-development'), ('Joshua G. Cole','taxes'),
        ('Sam Rasoul','civil-rights'));

DO $post$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_context c
    JOIN essentials.politicians p ON p.id = c.politician_id
    JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE c.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (p.full_name, t.topic_key) IN (
          ('Ghazala Hashmi','childcare'), ('Ghazala Hashmi','medicare/aid'),
          ('Ghazala Hashmi','economic-development'), ('Joshua G. Cole','taxes'),
          ('Sam Rasoul','civil-rights'))
     AND EXISTS (SELECT 1 FROM unnest(c.sources) u WHERE u ILIKE '%#Campaign_themes%');
  IF n <> 5 THEN
    RAISE EXCEPTION 'migration 1912: % of 5 rows now deep-link the anchor, expected 5', n;
  END IF;

  -- no chair may have moved
  SELECT count(*) INTO n
    FROM inform.politician_answers a
    JOIN essentials.politicians p ON p.id = a.politician_id
    JOIN inform.compass_topics t ON t.id = a.topic_id
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'
     AND (p.full_name, t.topic_key) IN (
          ('Ghazala Hashmi','childcare'), ('Ghazala Hashmi','medicare/aid'),
          ('Ghazala Hashmi','economic-development'), ('Joshua G. Cole','taxes'),
          ('Sam Rasoul','civil-rights'))
     AND a.value > 0;
  IF n <> 5 THEN
    RAISE EXCEPTION 'migration 1912: a chair moved; % of 5 still live', n;
  END IF;
END
$post$;
