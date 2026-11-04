BEGIN;

-- =============================================================================
-- CA_0347: names and descriptions for the 17 new Season 2 communities
-- =============================================================================
-- Created 2026-11-02 with Chris Andrews. Slot reserved through the steward.
--
-- WHAT THIS DOES
-- CA_0343 created 17 Focused Communities with description NULL, deliberately:
-- every existing community carries editorial copy in Chris's voice, and writing
-- seventeen more without him would have been invented content on a live page.
-- He has now written them. This lands that copy, and shortens 10 names to the
-- label the Compass spoke already shows.
--
-- 🔴 WHY THE ROOT CLAIMS MOVE TOO, AND WHY THAT IS NOT OPTIONAL.
-- connect.claims seeds one root per community with body = the community name
-- (CA_0342 §7a), and CA_0343's post-verify gate ASSERTS that every root's body
-- equals its community's name — all 61 satisfy it today. Renaming a community
-- without renaming its root would break that invariant, make CA_0343's gate fail
-- on a re-run, and show a reader the old long title at the top of the argument
-- tree while the directory showed the short one. So the two move together.
--
-- 🔴 THE EDIT LOG GETS A SENTINEL ACTOR, ON PURPOSE.
-- trg_log_claim_edit fires on a body change and RAISES when fc.actor_id is unset,
-- because a human edit must name its editor. This is not a human edit — it is
-- editorial copy arriving by migration — and there is no user to name. Rather
-- than disable the audit trigger (which would leave the rename invisible in the
-- history) or invent a person, the actor is the nil uuid
-- 00000000-0000-0000-0000-000000000000, which is obviously not an account.
-- The rows it writes are kind = 'edit' and will appear in the public history at
-- GET /claims/:id/edits, showing the previous wording. That is accurate and
-- public either way, so nothing is leaked by it.
--
-- WHAT IS NOT INVENTED
-- Every description was drafted against the topic's own question_text and reviewed
-- by Chris before this file existed; the copy below is the reviewed text, so this
-- file is the record and there is no draft to chase elsewhere.
-- Each new name is the Compass topic's own short_title, verbatim — the label the
-- spoke already shows — never a phrase invented here, and §2 refuses to run if
-- editorial has drifted from the Compass.
--
-- Every description states a disagreement and declines to settle it. That is not
-- a style preference: a reader who feels pre-judged by the blurb will not argue in
-- good faith underneath it, and the argument tree only works if both sides show up.
--
-- Idempotent — safe to re-run. There is no migration runner (see CLAUDE.md).
-- =============================================================================

-- 0. Preconditions.
DO $$
BEGIN
  IF to_regclass('connect.communities') IS NULL OR to_regclass('connect.claims') IS NULL THEN
    RAISE EXCEPTION 'CA_0347: connect.communities and connect.claims must exist';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM connect.communities WHERE description IS NULL) THEN
    RAISE NOTICE 'CA_0347: no community is missing a description; this is a re-run or the copy already landed';
  END IF;
END $$;

-- The actor for the edit-log rows this migration causes. Not a person; see the header.
SELECT set_config('fc.actor_id', '00000000-0000-0000-0000-000000000000', true);

-- 1. The copy. Keyed on slug, which CA_0343 set from the topic's own topic_key.
CREATE TEMP TABLE ca0347_copy (slug TEXT PRIMARY KEY, new_name TEXT, description TEXT) ON COMMIT DROP;

INSERT INTO ca0347_copy (slug, new_name, description) VALUES
('2020-election', '2020 Election',
 'Americans disagree about the 2020 presidential election, and where someone lands shapes what they think elections need now. Discuss how you read what happened — and what should follow from it.'),
('border-security', 'Border Security',
 'Someone crosses the border without permission. What should happen next — and does it depend on who they are, or why they came? Discuss where enforcement, asylum and discretion should meet.'),
('cannabis-policy', 'Cannabis Policy',
 'Should cannabis be treated like alcohol, like medicine, or like a crime? Discuss what the law should allow, who should be licensed to sell it, and what happens to past convictions.'),
('defense-spending', 'Defense Spending',
 'Every dollar for the military is a dollar not spent elsewhere — and every dollar cut is a capability someone argues you will miss. Discuss how much is enough, and how you would know.'),
('education-ai', 'AI in Schools',
 'When a student uses AI to write an essay, is that cheating, a tool, or the whole point? Discuss what belongs in the classroom and what should stay out of it.'),
('education-charter-authorization', 'Charter Schools',
 'A charter school wants to open in your district. Should the board welcome it, hold it to the same standard as every other school, or turn it down? Discuss who gets to start a school, and on what terms.'),
('education-curriculum', 'Curriculum Content',
 'Who decides how race, gender and history are taught — the state, the district, the teacher, or the parent? Discuss where that call belongs when people disagree about the answer.'),
('education-equity-programs', 'School Equity Programs',
 'Some students arrive further behind than others. Should schools target extra help by group, by need, or not at all? Discuss what closing a gap should look like in practice.'),
('education-gender-identity', 'Student Gender Identity',
 'A student uses a different name at school than at home. What should the school do — tell the parents, follow the student''s lead, or something in between? Discuss where a school''s duty to a family meets its duty to a child.'),
('education-library-books', 'School Library Books',
 'A parent objects to a book on the library shelf. Who decides whether it stays — and where does the book sit while they decide? Discuss how a school should handle a challenge.'),
('education-school-budget', 'School Budget',
 'Smaller classes, better pay, newer buildings, lower taxes — a school budget cannot do all of it. Discuss what you would fund first, and what you would ask taxpayers to cover.'),
('education-school-police', 'Police in Schools',
 'Should there be a police officer in the hallway? Discuss what an officer in a school is for, what they should handle, and what belongs to a counselor or a principal instead.'),
('gun-policy', 'Gun Policy',
 'Where should the line sit between someone''s right to own a firearm and a government''s interest in regulating it? Discuss what should be required, of whom, and what difference you think it would make.'),
('israel-military-aid', 'Israel Military Aid',
 'The U.S. sends military aid to Israel. Should it continue, come with conditions, or stop? Discuss what American support should depend on.'),
('military-intervention', 'Military Intervention',
 'When, if ever, should the United States send its military somewhere? Discuss what has to be true before force is justified — and who should get to decide.'),
('minimum-wage', 'Minimum Wage',
 'What is the least an hour of work should be allowed to pay — and should that number be the same everywhere? Discuss what a wage floor is for, and what it costs.'),
('ranked-choice-voting', 'Ranked-Choice Voting',
 'You like three candidates and can only pick one. Should you be able to rank them instead? Discuss how votes should be cast and counted, and what each method rewards.');

-- 2. Every new name must be the topic's own short_title, verbatim. If editorial drifts from
--    the Compass, this stops rather than quietly inventing a label the spoke does not use.
DO $$
DECLARE v_bad TEXT;
BEGIN
  SELECT string_agg(format('%s: copy says %L, spoke says %L', p.slug, p.new_name, t.short_title), '; ')
    INTO v_bad
  FROM ca0347_copy p
  JOIN connect.communities c ON c.slug = p.slug
  JOIN inform.compass_topics t ON t.id = c.topic_id
  WHERE t.short_title IS DISTINCT FROM p.new_name;

  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CA_0347: a name here is not the Compass spoke label — %', v_bad;
  END IF;
END $$;

-- 3. The root claims first, while communities.name still holds the OLD value, so the join
--    finds them. Body only; path, depth and the counts are nobody's business here.
UPDATE connect.claims k
   SET body = p.new_name
  FROM connect.communities c
  JOIN ca0347_copy p ON p.slug = c.slug
 WHERE k.community_id = c.id
   AND k.parent_claim_id IS NULL
   AND k.body IS DISTINCT FROM p.new_name;

-- 4. Then the communities.
UPDATE connect.communities c
   SET name        = p.new_name,
       description = p.description,
       updated_at  = now()
  FROM ca0347_copy p
 WHERE c.slug = p.slug
   AND (c.name IS DISTINCT FROM p.new_name OR c.description IS DISTINCT FROM p.description);

-- 5. Post-verify gate.
DO $$
DECLARE
  v_missing   INT;
  v_no_desc   INT;
  v_blank     INT;
  v_drift     INT;
  v_total     INT;
BEGIN
  SELECT count(*) INTO v_missing
  FROM ca0347_copy p WHERE NOT EXISTS (SELECT 1 FROM connect.communities c WHERE c.slug = p.slug);
  IF v_missing <> 0 THEN
    RAISE EXCEPTION 'CA_0347: % slug(s) in this file name no community', v_missing;
  END IF;

  -- a. Every one of the 17 now carries its copy, exactly.
  SELECT count(*) INTO v_no_desc
  FROM ca0347_copy p JOIN connect.communities c ON c.slug = p.slug
  WHERE c.description IS DISTINCT FROM p.description OR c.name IS DISTINCT FROM p.new_name;
  IF v_no_desc <> 0 THEN
    RAISE EXCEPTION 'CA_0347: % community row(s) did not take the copy', v_no_desc;
  END IF;

  -- b. No community anywhere is left without a description. This is the whole point.
  SELECT count(*) INTO v_blank FROM connect.communities WHERE btrim(coalesce(description, '')) = '';
  IF v_blank <> 0 THEN
    RAISE EXCEPTION 'CA_0347: % community(ies) still have no description', v_blank;
  END IF;

  -- c. 🔴 THE INVARIANT CA_0343 ASSERTS, RE-CHECKED ACROSS ALL 61, not just the 17 —
  --    a rename that moved a community but not its root would be invisible here otherwise.
  SELECT count(*) INTO v_drift
  FROM connect.communities c
  JOIN connect.claims k ON k.community_id = c.id AND k.parent_claim_id IS NULL
  WHERE k.body IS DISTINCT FROM c.name;
  IF v_drift <> 0 THEN
    RAISE EXCEPTION 'CA_0347: % root claim(s) no longer match their community name', v_drift;
  END IF;

  SELECT count(*) INTO v_total FROM connect.communities;
  RAISE NOTICE 'CA_0347 OK — 17 communities carry their copy, % communities in total, every one with a description, every root still matching its community name.', v_total;
END $$;

COMMIT;
