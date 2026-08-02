-- 1528_repair_held_source_rows.sql
--
-- Repair 13 of the 22 rows that 1527 deliberately HELD because its automated guards could not prove
-- the right fix. Each is resolved here by hand, and the evidence for each is recorded inline.
--   Rollback: data/stance-retirement/2026-08-01-prose-sources-rollback.json (the `held` array)
--   Review:   data/stance-retirement/2026-08-02-held-rows-resolution.md
--
-- 🔴 THE GUARDS WERE RIGHT TO HOLD ALL OF THESE. Every one needed a DIFFERENT repair from the one an
-- automated rule would have picked, and three needed evidence a rule cannot gather:
--   - Tregub's two rows look like an unprovable split (both halves return 200), but the two halves are
--     DIFFERENT PAGES -- "Berkeley" and "Berkeley, California" are distinct Wikipedia articles, and
--     only the latter is about the city this councilmember serves.
--   - García's rejoin 404s, so the automated fix was simply WRONG. The remedy is a re-source.
--   - Linda Sanchez's URL 403s from a script either way, so the network can say nothing at all.

BEGIN;

-- ============================================================ SPLIT URL — rejoin on the comma (3)

-- Igor Tregub / Deportation + Immigration — https://en.wikipedia.org/wiki/Berkeley,_California was
-- split on its comma. 1527 held these because BOTH halves return 200, which its rule read as "the
-- truncated URL is fine, so rejoining is unnecessary". That rule is wrong here: /wiki/Berkeley and
-- /wiki/Berkeley,_California are different articles (titles "Berkeley" vs "Berkeley, California"),
-- and the citation for a Berkeley city councilmember is the city.
UPDATE inform.politician_context
   SET sources = ARRAY['https://berkeleyca.gov/your-government/city-council/council-roster/igor-tregub',
                       'https://en.wikipedia.org/wiki/Berkeley,_California']::text[]
 WHERE politician_id = '9f9a35a9-0226-45f0-9fd8-ef46163f7245'
   AND topic_id IN ('44905f3b-e105-4f6c-afc7-5d223813dbac', '4e2c69ce-591e-4197-9cd5-7aceff79d390');

-- Linda Sanchez / Housing — a congress.gov URL whose JSON query parameter contains a comma:
--   ?q={"sponsorship":"sponsored","type":"bills"}
-- split into ...%22sponsored%22  +  %22type%22:%22bills%22%7D. congress.gov returns 403 to scripted
-- requests, so 1527 could not prove it; but the truncated form is UNCLOSED JSON ({ with no }), which
-- is decisive on structure alone. Rejoined.
UPDATE inform.politician_context
   SET sources = ARRAY['https://lindasanchez.house.gov/issues/housing',
                       'https://www.congress.gov/member/linda-sanchez/S001156?q=%7B%22sponsorship%22:%22sponsored%22,%22type%22:%22bills%22%7D']::text[]
 WHERE politician_id = 'bb73793e-ad67-431a-bb03-663b765204d8'
   AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- ============================================================ RE-SOURCE — the rejoin is dead (2)

-- Mónica García / Immigration + Deportation — the stored URL is a split of
-- ballotpedia.org/Monica_Garcia_(Los_Angeles_Unified_School_District_Board_of_Education,_District_2),
-- but 🔴 THE REJOINED URL 404s TOO: Ballotpedia renamed the page. So the automated repair would have
-- produced a second broken link. https://ballotpedia.org/Monica_Garcia returns 200 and the page
-- identifies itself as "Mónica García (Los Angeles Unified School District, California)".
-- ⚠ Identity was CHECKED, not assumed -- a 200 is not identity confirmation, and a Ballotpedia page
-- matching a name has already turned out to be a different person once on this workstream.
UPDATE inform.politician_context
   SET sources = ARRAY['https://ballotpedia.org/Monica_Garcia']::text[]
 WHERE politician_id = 'a123c59e-694b-43cc-af03-6610b645e6d2'
   AND topic_id IN ('4e2c69ce-591e-4197-9cd5-7aceff79d390', '44905f3b-e105-4f6c-afc7-5d223813dbac');

-- ============================================================ DROP — junk or duplicate (6)
-- These rows' reasoning is COMPLETE and already carries the claim; the stray entry is either a bare
-- name or a quotation the reasoning already states. Nothing is lost by dropping it, and rejoining it
-- onto finished prose (what 1527's other branch would have done) would have corrupted the text.

-- John Lee / Taxes — the entry is the subject's own name.
UPDATE inform.politician_context
   SET sources = ARRAY['https://laist.com/news/politics/outside-spending-to-reelect-john-lee-tops-1m-as-the-city-councilmember-remains-under-ethics-scrutiny',
                       'https://laist.com/news/housing-homelessness/los-angeles-rent-increase-freeze-covid-pandemic-rso-six-month-extension-delay-9-7-4-percent-housing-tenants-landlords']::text[]
 WHERE politician_id = 'c3155cf3-9a97-43d1-a076-dd6ef6aa46e9' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

-- Steve Daines / Voting Rights — the entry is "Susan Collins", an unrelated senator's name.
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Senate/Steve_Daines.htm',
                       'https://en.wikipedia.org/wiki/Steve_Daines']::text[]
 WHERE politician_id = '24109768-01ad-4bab-b833-b7bc1d8f437d' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

-- Gary Palmer / Campaign Finance — the entry is a quotation the reasoning already reproduces in full
-- ("Given that individual contributions must be disclosed, I support full disclosure...").
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/House/Gary_Palmer_Government_Reform.htm']::text[]
 WHERE politician_id = '9c7e62aa-c793-4630-b58b-4eb219b91d30' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';

-- Garland Barr / Taxes — the entry duplicates the reasoning's own "advocates a 'single-rate tax system'".
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/House/Andy_Barr.htm',
                       'https://en.wikipedia.org/wiki/Andy_Barr_(politician)']::text[]
 WHERE politician_id = '164fb70e-b8c1-48cd-a6ef-12d80165c67d' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

-- Steven Horsford / School Vouchers — the entry is a campaign slogan the reasoning paraphrases
-- ("His stated position of not gutting education...").
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/House/Steven_Horsford.htm']::text[]
 WHERE politician_id = '7644cd40-b5c1-494a-8e65-f3126fc7f9ee' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- Kelly Armstrong / School Vouchers — the entry is a budget line the reasoning already states.
UPDATE inform.politician_context
   SET sources = ARRAY['https://www.ontheissues.org/Kelly_Armstrong.htm']::text[]
 WHERE politician_id = '7544a9ec-53aa-4ed1-86a3-5f5f4d399544' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- ============================================================ REASONING SPLIT — rejoin (2)

-- Kris Fair / Misinformation — the reasoning was split on commas and its tail became "sources".
-- 1527 held it only because the FIRST fragment ("disinformation") has no whitespace, so its
-- prose test did not fire. The mgaleg citation survives and is kept.
UPDATE inform.politician_context
   SET reasoning = 'Fair sponsored legislation targeting election misinformation, disinformation, and deepfakes — supporting platform/government action against political misinformation.',
       sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/fair01']::text[]
 WHERE politician_id = 'dfb9ae21-4605-4c58-94e8-84b1eb1a30c1' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

-- Benjamin Brooks / Public Safety Approach — 🔴 THE WORST SINGLE ROW FOUND. Its one "source" is a raw
-- CSV fragment containing THREE records: the tail of this row's own reasoning, its real URL, and then
-- TWO COMPLETE STANCE ROWS (local-environment and economic-development) that were swallowed whole and
-- never reached the database -- Brooks has neither topic today. Only this row is repaired here; the
-- two lost rows are reported in the review, because re-creating them would be INSERTING STANCES, not
-- repairing one, and that is a research decision.
-- Checked corpus-wide: exactly ONE sources entry contains a newline, so the row-swallowing was a
-- single incident and not systemic.
UPDATE inform.politician_context
   SET reasoning = 'Brooks participated in a Fraternal Order of Police training exercise in 2020 and stated the experience gave perspective but "did not change his mind on policing reforms", indicating support for reform while acknowledging law enforcement complexity.',
       sources = ARRAY['https://en.wikipedia.org/wiki/Benjamin_Brooks_(politician)']::text[]
 WHERE politician_id = 'a16b94b0-dd22-40a9-af91-03295ea27986' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

DO $$
DECLARE v_n int; v_ids text[][];
BEGIN
  -- Every row touched here must now hold only real URLs, and must still hold at least one.
  SELECT count(*) INTO v_n
    FROM inform.politician_context pc
   WHERE (pc.politician_id::text, pc.topic_id::text) IN (
           ('9f9a35a9-0226-45f0-9fd8-ef46163f7245','44905f3b-e105-4f6c-afc7-5d223813dbac'),
           ('9f9a35a9-0226-45f0-9fd8-ef46163f7245','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
           ('bb73793e-ad67-431a-bb03-663b765204d8','669cac97-66a6-4087-b036-936fbe62efb3'),
           ('a123c59e-694b-43cc-af03-6610b645e6d2','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
           ('a123c59e-694b-43cc-af03-6610b645e6d2','44905f3b-e105-4f6c-afc7-5d223813dbac'),
           ('c3155cf3-9a97-43d1-a076-dd6ef6aa46e9','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
           ('24109768-01ad-4bab-b833-b7bc1d8f437d','d1792200-1d3b-4955-a0b7-0e6980d7a7b2'),
           ('9c7e62aa-c793-4630-b58b-4eb219b91d30','92730f69-ae57-401c-8ad1-2d07834a895d'),
           ('164fb70e-b8c1-48cd-a6ef-12d80165c67d','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
           ('7644cd40-b5c1-494a-8e65-f3126fc7f9ee','00b95a6a-75db-4521-b523-3326bba938de'),
           ('7544a9ec-53aa-4ed1-86a3-5f5f4d399544','00b95a6a-75db-4521-b523-3326bba938de'),
           ('dfb9ae21-4605-4c58-94e8-84b1eb1a30c1','ddd65d64-9dc7-4208-a30f-59f4b9c0653d'),
           ('a16b94b0-dd22-40a9-af91-03295ea27986','e9ebefcd-c496-45e8-b816-a79f8442ba85'))
     AND (coalesce(cardinality(pc.sources), 0) = 0
          OR EXISTS (SELECT 1 FROM unnest(pc.sources) s
                      WHERE s !~* '^https?://' AND s !~ '^[a-z0-9.-]+\.[a-z]{2,}(/|$)'));
  IF v_n <> 0 THEN RAISE EXCEPTION '% repaired row(s) still hold a non-URL source or none at all', v_n; END IF;

  -- The two rejoined URLs must be exactly what was verified, not a near miss.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = '9f9a35a9-0226-45f0-9fd8-ef46163f7245'
     AND 'https://en.wikipedia.org/wiki/Berkeley,_California' = ANY(sources);
  IF v_n <> 2 THEN RAISE EXCEPTION 'expected 2 Tregub rows citing Berkeley,_California, found %', v_n; END IF;

  -- No swallowed CSV may survive anywhere in the corpus.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s ~ E'\n');
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still contain a newline in sources', v_n; END IF;
END $$;

COMMIT;
