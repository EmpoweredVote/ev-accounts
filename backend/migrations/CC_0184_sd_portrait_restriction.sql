-- CC_0184_sd_portrait_restriction.sql
-- Knight Foundation program, wave SD-5 (assets). Slot RESERVED from the allocator.
--
-- Records that a publisher has RESERVED its portraits, and marks the people that reservation
-- covers, so the site can say WHY a seat has no face instead of looking like a gap in our work.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHAT HAPPENED
--
--   2026-09-28  Sent to LRC@sdlegislature.gov. Every South Dakota member profile page renders
--               "Use by Permission Only." above the member's details, so we asked BEFORE any use.
--               Letter: .planning/knight-foundation/letters/2026-09-28-sd-legislature-portrait-permission.md
--   2026-09-29  LRC <lrc@sdlegislature.gov> replied at 10:59, as the Council and not over a named
--               person, in full:
--
--                 "You will need to ask each legislator individually as they are the ones who
--                  can grant permission for use."
--
-- 🔴 THAT IS NOT A REFUSAL AND MUST NOT BE WRITTEN UP AS ONE. The Council said it does not hold
-- the right; the individual member does. Voter-facing copy in this migration says exactly that
-- and no more. A future pass MAY ask the 105 members one at a time; this migration neither does
-- that nor forecloses it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- WHY A NEW TABLE AND NOT A PHOTO URL
--
-- 🔴 NOTHING HERE WRITES photo_custom_url. The placeholder is drawn by the RENDER layer.
-- photo_custom_url is the definition of "this person has a portrait we can paint"
-- (backend/src/lib/photoCoverage.ts), so parking a stick-figure asset in it would report all
-- 105 as COVERED, delete them from the headshot backlog, and corrupt every coverage rollup. That
-- is the same defect that already leaves 86 politicians rendering a roster PAGE URL as a face.
--
-- This column instead creates a THIRD state, which the corpus did not have:
--
--     photo, no restriction    -> covered. Renders the portrait.
--     no photo, no restriction -> TO DO. Renders initials. Stays in the headshot backlog.
--     no photo + restriction   -> BLOCKED. Renders the placeholder + the notice.
--                                NOT covered, and NOT a backlog item: searching again cannot
--                                help, because the portrait was found and may not be used.
--
-- Coverage still counts these 105 as having no portrait, because they have none. Only the
-- backlog changes, and it changes because the work is finished, not because it was done.
--
-- ⚠ THE COPY LIVES IN THE TABLE, NOT IN THE FRONTEND. South Dakota is the first publisher to
-- reserve its portraits and it will not be the last. The next one is one INSERT plus one UPDATE;
-- no frontend release, and no state name compiled into a React bundle.

BEGIN;

-- ── 1. The lookup ────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS essentials.photo_restrictions (
  code               text PRIMARY KEY,
  authority          text        NOT NULL,
  authority_contact  text,
  publisher_notice   text,
  asked_on           date        NOT NULL,
  replied_on         date,
  reply_verbatim     text,
  card_label         text        NOT NULL,
  notice_headline    text        NOT NULL,
  notice_body        text        NOT NULL,
  created_at         timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT photo_restrictions_reply_after_ask CHECK (replied_on IS NULL OR replied_on >= asked_on)
);

COMMENT ON TABLE essentials.photo_restrictions IS
  'A publisher that has reserved its officials'' portraits, and the voter-facing explanation for the seats it covers. Referenced by politicians.photo_restriction_code. A row here means the portrait EXISTS and we may not use it -- which is a different fact from not having found one, and the site renders the two differently. Copy is stored here so adding a publisher is an INSERT, not a frontend release. Created by CC_0184.';

COMMENT ON COLUMN essentials.photo_restrictions.reply_verbatim IS
  'The publisher''s answer, quoted exactly. Never paraphrase it into this column -- the paraphrase belongs in notice_body, where it is labelled as ours.';
COMMENT ON COLUMN essentials.photo_restrictions.card_label IS
  'Short marker for a 448x127 result card. The card has room for one line and no more.';
COMMENT ON COLUMN essentials.photo_restrictions.notice_body IS
  'Voter-facing. Rendered above the affected body on the results page, so a reader meets the explanation BEFORE the placeholders. Paragraphs are separated by a blank line.';

-- ── 2. The link ──────────────────────────────────────────────────────────────────────────────

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS photo_restriction_code text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conname = 'politicians_photo_restriction_code_fkey'
       AND conrelid = 'essentials.politicians'::regclass
  ) THEN
    ALTER TABLE essentials.politicians
      ADD CONSTRAINT politicians_photo_restriction_code_fkey
      FOREIGN KEY (photo_restriction_code)
      REFERENCES essentials.photo_restrictions(code)
      ON UPDATE CASCADE ON DELETE SET NULL;
  END IF;
END $$;

COMMENT ON COLUMN essentials.politicians.photo_restriction_code IS
  'NON-NULL means: a portrait of this person exists and its publisher has reserved it, so we do not display one. This is NOT "no portrait found" -- that is this column NULL with no photo, and it renders initials and stays in the headshot backlog. Setting this NEVER implies coverage: photo_custom_url stays NULL and photoCoverage still reports no portrait. Clear this column at the moment a portrait is licensed, in the same migration that writes the portrait.';

CREATE INDEX IF NOT EXISTS politicians_photo_restriction_code_idx
  ON essentials.politicians (photo_restriction_code)
  WHERE photo_restriction_code IS NOT NULL;

-- ── 3. South Dakota ──────────────────────────────────────────────────────────────────────────

INSERT INTO essentials.photo_restrictions (
  code, authority, authority_contact, publisher_notice,
  asked_on, replied_on, reply_verbatim,
  card_label, notice_headline, notice_body
) VALUES (
  'sd-legislature-2026',
  'South Dakota Legislative Research Council',
  'lrc@sdlegislature.gov',
  'Use by Permission Only.',
  DATE '2026-09-28',
  DATE '2026-09-29',
  'You will need to ask each legislator individually as they are the ones who can grant permission for use.',
  'Portrait use restricted',
  'Why these members have no photograph',
  'The South Dakota Legislature marks every member portrait "Use by Permission Only." We asked the Legislative Research Council on 28 September 2026. The Council replied on 29 September 2026 that each legislator grants permission individually.'
  || E'\n\n' ||
  'We have not copied or published any South Dakota portrait. Members who grant permission will show their photograph here.'
)
ON CONFLICT (code) DO UPDATE SET
  authority         = EXCLUDED.authority,
  authority_contact = EXCLUDED.authority_contact,
  publisher_notice  = EXCLUDED.publisher_notice,
  asked_on          = EXCLUDED.asked_on,
  replied_on        = EXCLUDED.replied_on,
  reply_verbatim    = EXCLUDED.reply_verbatim,
  card_label        = EXCLUDED.card_label,
  notice_headline   = EXCLUDED.notice_headline,
  notice_body       = EXCLUDED.notice_body;

-- The 105 seated members of the 101st South Dakota Legislature, reached through the seat rather
-- than through a name list: 35 Senate + 70 House. Measured 2026-09-29 before writing -- all 105
-- carry NO photo_custom_url, NO photo_origin_url and NO politician_images row, so this migration
-- overwrites no portrait, and the guard below re-asserts that after the fact.
UPDATE essentials.politicians p
   SET photo_restriction_code = 'sd-legislature-2026'
 WHERE p.id IN (
         SELECT och.politician_id
           FROM essentials.offices o
           JOIN essentials.chambers c    ON c.id = o.chamber_id
           JOIN essentials.governments g ON g.id = c.government_id
           JOIN essentials.office_current_holder och ON och.office_id = o.id
          WHERE g.state = 'SD'
            AND g.name  = 'State of South Dakota'
            AND c.name IN ('South Dakota Senate', 'South Dakota House of Representatives')
            AND och.politician_id IS NOT NULL
       )
   AND p.photo_restriction_code IS DISTINCT FROM 'sd-legislature-2026';

-- ── 4. Post-verify gate ──────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_marked    int;
  v_house     int;
  v_senate    int;
  v_withphoto int;
  v_leak      int;
BEGIN
  SELECT count(*) INTO v_marked
    FROM essentials.politicians
   WHERE photo_restriction_code = 'sd-legislature-2026';
  IF v_marked <> 105 THEN
    RAISE EXCEPTION 'SD-5 restriction gate: % people carry the SD code, expected 105', v_marked;
  END IF;

  SELECT count(DISTINCT och.politician_id) FILTER (WHERE c.name LIKE '%House%'),
         count(DISTINCT och.politician_id) FILTER (WHERE c.name LIKE '%Senate%')
    INTO v_house, v_senate
    FROM essentials.offices o
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.state = 'SD' AND g.name = 'State of South Dakota'
     AND c.name IN ('South Dakota Senate', 'South Dakota House of Representatives')
     AND p.photo_restriction_code = 'sd-legislature-2026';
  IF v_house <> 70 OR v_senate <> 35 THEN
    RAISE EXCEPTION 'SD-5 restriction gate: marked % House + % Senate, expected 70 + 35', v_house, v_senate;
  END IF;

  -- 🔴 A restriction on a person who HAS a portrait is a contradiction: it would hide a photo we
  -- are entitled to show. Assert the emptiness rather than trusting the pre-flight measurement.
  SELECT count(*) INTO v_withphoto
    FROM essentials.politicians p
    LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
   WHERE p.photo_restriction_code IS NOT NULL
     AND (   img.politician_id IS NOT NULL
          OR btrim(coalesce(p.photo_custom_url, '')) <> ''
          OR btrim(coalesce(p.photo_origin_url, '')) <> '');
  IF v_withphoto <> 0 THEN
    RAISE EXCEPTION 'SD-5 restriction gate: % restricted person(s) already carry a portrait', v_withphoto;
  END IF;

  -- The code must not have reached anyone outside South Dakota's legislature.
  SELECT count(*) INTO v_leak
    FROM essentials.politicians p
   WHERE p.photo_restriction_code = 'sd-legislature-2026'
     AND NOT EXISTS (
       SELECT 1
         FROM essentials.offices o
         JOIN essentials.chambers c    ON c.id = o.chamber_id
         JOIN essentials.governments g ON g.id = c.government_id
         JOIN essentials.office_current_holder och ON och.office_id = o.id
        WHERE och.politician_id = p.id
          AND g.state = 'SD' AND g.name = 'State of South Dakota'
          AND c.name IN ('South Dakota Senate', 'South Dakota House of Representatives'));
  IF v_leak <> 0 THEN
    RAISE EXCEPTION 'SD-5 restriction gate: % marked person(s) hold no SD legislative seat', v_leak;
  END IF;

  RAISE NOTICE 'SD-5 restriction gate PASSED: 105 marked (70 House + 35 Senate), 0 carry a portrait, 0 outside the SD Legislature, photo_custom_url untouched.';
END $$;

COMMIT;
