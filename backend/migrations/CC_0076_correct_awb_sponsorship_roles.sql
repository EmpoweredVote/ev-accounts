BEGIN;

-- =============================================================================
-- CC_0076: correct who leads the Assault Weapons Ban — CC_0074 had it reversed
-- =============================================================================
-- Slot CC_0076 reserved via `steward slot CC` before this file existed.
--
-- WHAT WAS WRONG. CC_0074 published gun-policy reasoning for both California
-- senators that misdescribes their roles on the same bill, in opposite
-- directions:
--
--   Schiff's row said "Lead cosponsor of legislation to prohibit…"
--     — he is the SPONSOR.
--   Padilla's row cited his office page's "reintroduction of the Assault
--     Weapons Ban", which reads as though he leads it
--     — he is a cosponsor.
--
-- The bill is S. 1531, the Assault Weapons Ban of 2025, introduced 2025-04-30
-- with 44 cosponsors. Verified against the authoritative record, which names
-- "Sen. Schiff, Adam B. [D-CA]" as sponsor and lists Padilla among the original
-- cosponsors:
--   https://www.govinfo.gov/bulkdata/BILLSTATUS/119/s/BILLSTATUS-119s1531.xml
--   https://www.govinfo.gov/content/pkg/BILLS-119s1531is/html/BILLS-119s1531is.htm
--
-- 🔴 THE CHAIRS ARE UNCHANGED AND WERE NEVER WRONG. Sponsoring an assault
-- weapons ban and cosponsoring one both seat chair 2 — "ban semi-automatic
-- assault-style weapons, while allowing other firearms". No `value` moves here,
-- so this is a REWRITE of voter-facing prose, not a re-seating. It is exactly
-- the disposition CLAUDE.md's answer-delete rule calls a rewrite: the answer
-- stands, the reasoning under it did not.
--
-- ⚠ WHY THE FLOORS DO NOT MOVE. UPDATE, not INSERT or DELETE — the Season 2
-- context row COUNT is unchanged at 2,661, and the answer count at 2,689. The
-- post-verify asserts both, so a floor change here would be wrong in either
-- direction.
--
-- ── HOW THE ERROR HAPPENED, SO IT DOES NOT REPEAT ────────────────────────────
--
-- The claim came from a fetch SUMMARY of a press release, which said Schiff was
-- "a lead co-sponsor, not merely listed among cosponsors". That is the
-- summariser's phrasing, not the record's. The press release is a real primary
-- source and the reasoning's claim terms genuinely appeared on it — the
-- verifier passed the row 14/14 — because the gate proves a source CARRIES the
-- words, never that the words describe the record correctly.
--
-- 🔑 THE STRUCTURED RECORD IS WHAT SETTLES A ROLE, AND IT IS NOW REACHABLE.
-- api.congress.gov distinguishes sponsored-legislation from
-- cosponsored-legislation, and it caught this on its first real run over the
-- same two senators. congress.gov was never blocked to us; its WEBSITE is
-- bot-walled and its API is open with an api.data.gov key. For any future claim
-- of the form "X leads bill Y", read the sponsor field — not a press release,
-- and never a summary of one.
--
-- ── THE NEW REASONING ────────────────────────────────────────────────────────
--
-- Both strings passed `verify-reresearch-rows.mjs --tier=federal` before this
-- file was written: Schiff 7/7 claim terms against the bill text; Padilla 7/7
-- across the union of the bill text and the press release, which is where the
-- word "cosponsor" actually appears.

CREATE TEMPORARY TABLE _cc0076_fix (
  politician_id uuid   NOT NULL,
  who           text   NOT NULL,
  reasoning     text   NOT NULL,
  sources       text[] NOT NULL
) ON COMMIT DROP;

INSERT INTO _cc0076_fix VALUES
  ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', 'Adam B. Schiff',
   'Introduced the Assault Weapons Ban of 2025, to regulate assault weapons and ensure that the right to keep and bear arms is not unlimited.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119s1531is/html/BILLS-119s1531is.htm']),

  ('2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f', 'Alex Padilla',
   'Cosponsor of the Assault Weapons Ban of 2025, to regulate assault weapons and ensure that the right to keep and bear arms is not unlimited.',
   ARRAY['https://www.govinfo.gov/content/pkg/BILLS-119s1531is/html/BILLS-119s1531is.htm',
         'https://www.padilla.senate.gov/newsroom/press-releases/padilla-schiff-murphy-blumenthal-mcbath-reintroduce-assault-weapons-ban/']);

-- -----------------------------------------------------------------------------
-- 1. Preconditions
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2 uuid;
  v_n  int;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';
  IF v_s2 IS NULL OR (SELECT number FROM inform.seasons WHERE id = v_s2) <> 2 THEN
    RAISE EXCEPTION 'CC_0076: Season 2 is not the open season';
  END IF;

  SELECT count(*) INTO v_n
    FROM _cc0076_fix f
    JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE lower(p.full_name) <> lower(f.who);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0076: % row(s) name a different person than their politician_id resolves to', v_n;
  END IF;

  -- Both context rows must already exist. If they do not, CC_0074 was never
  -- applied here and this file is being run against the wrong database.
  SELECT count(*) INTO v_n
    FROM _cc0076_fix f
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_context c
      ON c.politician_id = f.politician_id AND c.topic_id = t.id AND c.season_id = v_s2;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0076: expected 2 existing gun-policy context rows to correct, found %', v_n;
  END IF;

  RAISE NOTICE 'CC_0076 preconditions OK: Season 2 open, names match ids, both context rows present.';
END $$;

-- -----------------------------------------------------------------------------
-- 2. The rewrite
-- -----------------------------------------------------------------------------
-- Only reasoning and sources move. politician_id, topic_id, season_id and
-- topic_revision_id are the row's identity and its pin; touching them here would
-- be a different change wearing this one's name.
UPDATE inform.politician_context c
   SET reasoning  = f.reasoning,
       sources    = f.sources,
       updated_at = now()
  FROM _cc0076_fix f, inform.compass_topics t, inform.seasons s
 WHERE c.politician_id = f.politician_id
   AND t.topic_key = 'gun-policy'
   AND c.topic_id = t.id
   AND s.status = 'open'
   AND c.season_id = s.id;

-- -----------------------------------------------------------------------------
-- 3. Assert the outcome
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_s2      uuid;
  v_n       int;
  v_answers int;
  v_context int;
BEGIN
  SELECT id INTO v_s2 FROM inform.seasons WHERE status = 'open';

  -- 3a. both rows now read as intended
  SELECT count(*) INTO v_n
    FROM _cc0076_fix f
    JOIN inform.compass_topics t ON t.topic_key = 'gun-policy'
    JOIN inform.politician_context c
      ON c.politician_id = f.politician_id AND c.topic_id = t.id AND c.season_id = v_s2
   WHERE c.reasoning = f.reasoning AND c.sources = f.sources;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0076: % of 2 context rows carry the corrected reasoning', v_n;
  END IF;

  -- 3b. the word that was wrong is gone from both, and from nowhere else by accident
  SELECT count(*) INTO v_n
    FROM inform.politician_context c
    JOIN inform.compass_topics t ON t.id = c.topic_id AND t.topic_key = 'gun-policy'
   WHERE c.season_id = v_s2 AND c.reasoning ILIKE '%lead cosponsor%';
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0076: % gun-policy row(s) still say "lead cosponsor"', v_n;
  END IF;

  -- 3c. nothing was inserted or deleted — the whole point of a rewrite
  SELECT count(*) INTO v_answers FROM inform.politician_answers WHERE season_id = v_s2;
  SELECT count(*) INTO v_context FROM inform.politician_context WHERE season_id = v_s2;
  IF v_answers <> 2689 OR v_context <> 2661 THEN
    RAISE EXCEPTION 'CC_0076: corpus moved — % answers / % context, expected 2689 / 2661. The floors must not change for a rewrite.',
      v_answers, v_context;
  END IF;

  -- 3d. CC_0058 §3f still holds
  SELECT count(*) INTO v_n
    FROM inform.politician_answers a
   WHERE a.season_id = v_s2 AND a.value <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
                        AND c.season_id = a.season_id);
  IF v_n > 0 THEN
    RAISE EXCEPTION 'CC_0076: % non-blank Season 2 answer(s) carry no reasoning', v_n;
  END IF;

  RAISE NOTICE 'CC_0076 OK: 2 gun-policy context rows corrected. Corpus unchanged at % answers / % context — floors do not move.',
    v_answers, v_context;
END $$;

COMMIT;
