-- 1512_repoint_primary_site_citations.sql
--
-- Point 43 stance citations at the page that carries the claim instead of at the front door
-- of the same site. NOTHING IS DELETED AND NO CITATION CHANGES HOST -- every statement below swaps one
-- string in inform.politician_context.sources for a longer string on the same domain.
--   Evidence:        data/stance-retirement/2026-07-31-primary-site-paths.json
--   Rollback record: data/stance-retirement/2026-07-31-primary-site-paths-rollback.json
--                    (carries the exact prior sources array for all 43 rows)
--
-- WHY THESE ROWS EXIST. They are part of the 601-row PRIMARY_SITE_NO_PATH class -- answers whose only
-- citation is a bare root with no path. That class was first written up as "indefensible on their
-- face, retire as a class". Measured against prod 2026-07-31 that description fits exactly ONE row:
-- 596 cite the candidate's own campaign site and 5 an officeholder's own .gov office site. The
-- citation is imprecise, not absent, and 367 of the 601 are live on candidate cards. Retiring the
-- class would have deleted ~596 true, sourced rows.
--
-- WHAT WAS ACTUALLY REPAIRABLE, AND WHY IT IS A SMALL SHARE OF 601. Each site was crawled and each
-- row's quote re-tested page by page:
--   DEEP_PAGE         23  the claim verifies on an interior page (/issues, /platform, /priorities)
--   HOMEPAGE_ANCHOR   20  single-page site; the claim sits in a named section with a topical id
-- Everything else is NOT applied here and is not a defect to be fixed by this migration:
--   HOMEPAGE_ONLY    265  the claim IS on the homepage and the site has nothing more specific to
--                         point at. These citations are already as precise as the source permits.
--   NOT_FOUND        130  the verbatim quote is not on the site as fetched -- a HUMAN READ, never a
--                         retirement. Hand-checked: some are inexact quotation over substance that is
--                         plainly present (voteforpedrori.com says "Dissolve AIPAC. No Foreign-Interest
--                         Lobby Money"; the row compresses it to "No AIPAC Money. No Foreign-Interest
--                         Lobby Money"), others are genuine absences (shannontaylorva.com has no
--                         occurrence of "tariff" at all).
--   UNREADABLE       112  client-rendered shells -- 1,027k of HTML yielding 7k of text. An unread page
--                         is NOT an absent claim; same false negative as the silent HTTP-202.
--   DEAD_SITE         16  the campaign site 404s. Wayback is the likely remedy, not deletion.
--   UNTESTABLE        23  no quote and no distinctive term survived extraction.
--   DEEP_PAGE_WEAK     9  one matching term, no quote. Probably right; "probably" is not the bar for
--                         writing to prod, so they are held for a human.
--
-- 🔴 3 OF THE 43 MATCHED SOME BUT NOT ALL OF THEIR QUOTES. One verified quote is enough to
-- locate the page -- a row legitimately draws on more than one -- but it is NOT a verdict on the row.
-- Whether every quote holds is the citation audit's job, and re-pointing does not settle it.
--
-- 🔴 AN ANCHOR IS ONLY CITED WHEN ITS NAME SAYS WHAT IT POINTS AT. Three rounds of filtering generated
-- ids (#comp-jtv6vr22, then #page/#PAGES_CONTAINER, then #zi245S/#ui-id-6/#container02) each just moved
-- the junk, so the rule is now an allow-list: the id must contain a topical word and enclose under 40%
-- of the page. Structural ids move when the owner edits the page and would rot the citation silently.

BEGIN;

CREATE TEMP TABLE _repoint_1512 (
  politician_id uuid,
  topic_id      uuid,
  old_root      text,
  new_url       text
) ON COMMIT DROP;

INSERT INTO _repoint_1512 (politician_id, topic_id, old_root, new_url) VALUES
  ('04ff9d00-cf63-4d3b-875a-48c027a46a37', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'https://www.votebraun.com', 'https://www.votebraun.com/about'),  -- John Braun: Taxes
  ('00425ef8-553e-4b65-8aef-17390bcde3d1', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 'https://jerseyjustin4senate.org', 'https://jerseyjustin4senate.org/issue-immigration'),  -- Justin Murphy: Immigration
  ('0b5c3611-d1f3-4f23-b8c8-3ac33e299cd4', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'https://www.brandon4missouri.com', 'https://www.brandon4missouri.com#PROMISES'),  -- Brandon Wilkinson: Taxes
  ('169596c9-1ece-4a8a-b601-ce87af369a33', '669cac97-66a6-4087-b036-936fbe62efb3', 'https://www.electbrianknudsen.com', 'https://www.electbrianknudsen.com#brians-priorities'),  -- Brian Knudsen: Housing
  ('172350d1-31b0-4253-a692-1c15e8db13e5', '92730f69-ae57-401c-8ad1-2d07834a895d', 'https://www.cch8th.com', 'https://www.cch8th.com#priorities'),  -- Clayton Harbison: Campaign Finance
  ('26fd4e32-1fea-4c04-9607-0e33255f133c', '92730f69-ae57-401c-8ad1-2d07834a895d', 'https://davedawsonforiowa.com', 'https://davedawsonforiowa.com#bio'),  -- Dave Dawson: Campaign Finance
  ('3137fb1b-21bd-4711-88ce-f84401608b03', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 'https://www.niladevanath.com', 'https://niladevanath.com/issues.html'),  -- Nila Devanath: Abortion
  ('3137fb1b-21bd-4711-88ce-f84401608b03', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'https://www.niladevanath.com', 'https://niladevanath.com/issues.html'),  -- Nila Devanath: Childcare
  ('372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a', 'a22215c3-6693-4bc2-b248-01aebba14570', 'https://www.erickakopp.com', 'https://erickakopp.com#priorities-section'),  -- Ericka Kopp: Fossil Fuels
  ('372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'https://www.erickakopp.com', 'https://erickakopp.com#about-section'),  -- Ericka Kopp: Healthcare
  ('372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'https://www.erickakopp.com', 'https://erickakopp.com#priorities-section'),  -- Ericka Kopp: Climate Change
  ('372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'https://www.erickakopp.com', 'https://erickakopp.com#about-section'),  -- Ericka Kopp: Taxes
  ('4051eba2-cbdc-4764-9089-76fcd20a2083', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 'https://www.macyjonesforcongress.com', 'https://www.macyjonesforcongress.com/platform'),  -- Macy Jones: Immigration
  ('4051eba2-cbdc-4764-9089-76fcd20a2083', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'https://www.macyjonesforcongress.com', 'https://www.macyjonesforcongress.com/platform'),  -- Macy Jones: Healthcare
  ('44d86767-7041-4ce9-9d03-ce23dd663c95', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 'https://www.tomcraddick.com', 'https://tomcraddick.com#about'),  -- Tom Craddick: Same-Sex Marriage
  ('46a247f2-fa5c-49fc-8fa5-af215e728672', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 'https://www.jamesbecerra.com', 'https://www.jamesbecerra.com/about'),  -- James Becerra: Growth and Development Pace
  ('4f896b69-d922-4838-b54d-51a00a452e08', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 'https://www.electstephanie.com', 'https://www.electstephanie.com/priorities'),  -- Stephanie Pitcher: Immigration
  ('580f3720-7990-4a2b-a417-78d90012db93', '666bf03d-81fc-4138-ab15-69ae734c9023', 'https://jamiejoyce.com', 'https://www.jamiejoyce.com/about-jamie'),  -- Jamie Joyce: AI Oversight
  ('786ac925-59d3-40e3-a9ce-b63a54f4caf4', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 'https://marclahood.com', 'https://marclahood.com#ABOUT'),  -- Marc LaHood: Same-Sex Marriage
  ('80e30a8b-f5a7-47c9-a044-454e1416f290', '00b95a6a-75db-4521-b523-3326bba938de', 'https://www.devasimmons.com', 'https://www.devasimmons.com/en/issues'),  -- Deva Simmons: School Vouchers
  ('80e30a8b-f5a7-47c9-a044-454e1416f290', '48cc9585-ec22-4f53-8d42-6839828dd36f', 'https://www.devasimmons.com', 'https://www.devasimmons.com/en/issues'),  -- Deva Simmons: Redistricting
  ('96eff205-63aa-4999-890c-c83bcad391dd', '24e9212c-b011-422a-865c-093e35050901', 'https://hooslynforhouse.com', 'https://hooslynforhouse.com#policies'),  -- Adonis Hooslyn: Ukraine Support
  ('96eff205-63aa-4999-890c-c83bcad391dd', '666bf03d-81fc-4138-ab15-69ae734c9023', 'https://hooslynforhouse.com', 'https://hooslynforhouse.com#policies'),  -- Adonis Hooslyn: AI Oversight
  ('96eff205-63aa-4999-890c-c83bcad391dd', '669cac97-66a6-4087-b036-936fbe62efb3', 'https://hooslynforhouse.com', 'https://hooslynforhouse.com#policies'),  -- Adonis Hooslyn: Housing
  ('9a171371-be83-456e-acd5-ece936ee84ae', '00b95a6a-75db-4521-b523-3326bba938de', 'https://brooksbenson4utah.com', 'https://brooksbenson4utah.com#issues'),  -- Brooks Benson: School Vouchers
  ('9a171371-be83-456e-acd5-ece936ee84ae', 'a22215c3-6693-4bc2-b248-01aebba14570', 'https://brooksbenson4utah.com', 'https://brooksbenson4utah.com#issues'),  -- Brooks Benson: Fossil Fuels
  ('9c0e81fa-4b5c-4365-b0cd-892bdaff10a6', 'a22215c3-6693-4bc2-b248-01aebba14570', 'https://ericjenkinsforkansas.com', 'https://ericjenkinsforkansas.com#page-issues'),  -- Eric Jenkins: Fossil Fuels
  ('ab51e336-3cde-4b76-b096-c14879af8426', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'https://www.morganlovesoregon.com', 'https://www.morganlovesoregon.com/priorities-issues'),  -- Morgan Schmidt: Homelessness Response
  ('bb0cad08-e4da-4e44-b624-b7470dbb591e', '669cac97-66a6-4087-b036-936fbe62efb3', 'https://whiteforlancasterca.net', 'https://whiteforlancasterca.net#platform'),  -- Cedric White: Housing
  ('c85b90a2-e81b-41a8-a74a-90d03018a443', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 'https://jjsingh.com', 'https://www.jjsingh.com/about'),  -- JJ Singh: Abortion
  ('c85b90a2-e81b-41a8-a74a-90d03018a443', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 'https://jjsingh.com', 'https://www.jjsingh.com/about'),  -- JJ Singh: Childcare
  ('cc812498-af24-4ec2-8028-4e245d088fd8', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'https://johnduresky4congress.com', 'https://www.johnduresky4congress.com/issues'),  -- John Duresky: Healthcare
  ('d6cb7df2-1297-4c4e-8a9d-ac97f13fe32f', '24e9212c-b011-422a-865c-093e35050901', 'https://www.kshamasawant.org', 'https://www.kshamasawant.org/why-im-running'),  -- Kshama Sawant: Ukraine Support
  ('d6cb7df2-1297-4c4e-8a9d-ac97f13fe32f', '669cac97-66a6-4087-b036-936fbe62efb3', 'https://www.kshamasawant.org', 'https://www.kshamasawant.org/why-im-running'),  -- Kshama Sawant: Housing
  ('d6cb7df2-1297-4c4e-8a9d-ac97f13fe32f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'https://www.kshamasawant.org', 'https://www.kshamasawant.org/why-im-running'),  -- Kshama Sawant: Taxes
  ('df2b0dba-63d7-4f18-b713-7cc0594ec61d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'https://janielopez.com', 'https://www.janielopez.com/issues'),  -- Janie Lopez: Healthcare
  ('e3f5ae9f-a5e7-4eb1-bd6a-3c55b7ae8782', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'https://www.bradsmithforcongress.com', 'https://www.bradsmithforcongress.com/priorities-and-positions'),  -- Brad Smith: Climate Change
  ('b266c38d-9763-48d4-bcba-7b44adf79ab9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'https://hopper4texas.com', 'https://hopper4texas.com/platform'),  -- Andy Hopper: Taxes
  ('e752a957-c776-4942-9aae-63ebf23174ac', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 'https://www.scottschwab.com', 'https://scottschwab.com#priorities'),  -- Scott Schwab: Immigration
  ('e752a957-c776-4942-9aae-63ebf23174ac', '669cac97-66a6-4087-b036-936fbe62efb3', 'https://www.scottschwab.com', 'https://scottschwab.com/schwab-outlines-vision-for-better-affordable-living-by-decreasing-property-taxes'),  -- Scott Schwab: Housing
  ('fc23f648-2ec4-4c6c-a9f5-0722b809e6b1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 'https://allenforutahcounty.com', 'https://allenforutahcounty.com#whyus'),  -- Fred Allen: Taxes
  ('fee24b69-dd56-4b07-a890-a08e898dc031', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'https://wileyfor21.com', 'https://wileyfor21.com#priorities'),  -- Aaron Wiley: Healthcare
  ('b8856cc7-d711-436d-96b3-f0cbd352350a', '0bc588c6-39e1-4084-b5de-cac909b8b762', 'https://atoosareaser.com', 'https://atoosareaser.com/bio')  -- Atoosa R. Reaser: Civil Rights
;

-- Match on the trailing-slash-normalised element so a stored "https://site.com/" is found by a
-- proposal recorded as "https://site.com". Ordinality keeps the array in its original order.
UPDATE inform.politician_context pc
   SET sources = (
     SELECT array_agg(CASE WHEN btrim(s, '/') = r.old_root THEN r.new_url ELSE s END ORDER BY ord)
       FROM unnest(pc.sources) WITH ORDINALITY AS u(s, ord))
  FROM _repoint_1512 r
 WHERE pc.politician_id = r.politician_id
   AND pc.topic_id = r.topic_id;

DO $$
DECLARE
  v_target   int;
  v_unfixed  int;
  v_lost     int;
BEGIN
  SELECT count(*) INTO v_target FROM _repoint_1512;
  IF v_target <> 43 THEN
    RAISE EXCEPTION 'expected 43 targeted rows, found %', v_target;
  END IF;

  -- Every targeted row must now carry at least one source with a path. If one does not, the old_root
  -- did not match what was stored and the row was silently left behind.
  SELECT count(*) INTO v_unfixed
    FROM inform.politician_context pc
    JOIN _repoint_1512 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE NOT EXISTS (
     SELECT 1 FROM unnest(pc.sources) s
      WHERE btrim(s, '/') !~* '^https?://(www\.)?[a-z0-9.-]+$');
  IF v_unfixed <> 0 THEN
    RAISE EXCEPTION '% targeted rows still cite only a bare domain -- old_root did not match', v_unfixed;
  END IF;

  -- Nothing may lose a source. This migration substitutes; it never drops.
  SELECT count(*) INTO v_lost
    FROM inform.politician_context pc
    JOIN _repoint_1512 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF v_lost <> 0 THEN
    RAISE EXCEPTION '% targeted rows ended with an empty sources array', v_lost;
  END IF;
END $$;

COMMIT;
