-- CC_0335_photo_licence_overclaims.sql
--
-- Four photo-licence over-claims, found by diffing every seed/audit manifest against production.
-- 🔴 TWO OF THE FOUR TURNED OUT NOT TO BE LICENCE FAULTS AT ALL. They are the WRONG HUMAN BEING on
-- a live voter-facing page, and the false licence is a symptom of that, not the disease.
--
-- HOW THESE FOUR WERE FOUND. 1,312 rows across 17 manifests carry a recorded licence
-- (knight-fl · la-county-headshot-audit · seed-charlotte · seed-ks · seed-ky · seed-mn ×3 ·
-- seed-nd · seed-pa ×3 · seed-tn · 4 stance-research/*/headshots). Compared against production
-- with punctuation squashed (so cc-by-sa-4.0 and cc_by-sa_4.0 read as equal, while _4.0 and _2.0
-- correctly do not): 1,282 agree, 23 disagree, 4 pids no longer resolve, 3 carry no prod licence.
-- 🔴 ONLY THE DIRECTION MATTERS. 19 of the 23 are production claiming LESS than the manifest --
-- nine are the pure vocabulary pair `unknown` vs `scraped_no_license`, and several are CC_0329's
-- own deliberate Ballotpedia -> candidate_submitted rewrites disagreeing with the manifest they
-- superseded. Those assert nothing untrue and are deliberately NOT touched here. A raw count of
-- disagreements would have reported 23 problems where there are 4.
--
-- ============================================================================================
-- 🔴🔴 THE TWO WRONG PEOPLE. A NAMESAKE'S WIKIMEDIA PHOTOGRAPH, AND THE CC LICENCE CAME WITH IT.
-- ============================================================================================
-- Both sat in the 43-row population that claims a CC licence with NO recorded origin, and for both
-- the LA County audit -- the only other record we hold of these photographs -- recorded the licence
-- as `unknown`. Production says cc_by-sa_4.0. That gap is what an inferred-from-the-host licence
-- looks like, and opening the images showed why: each is a famous namesake whose photograph really
-- IS on Wikimedia under CC BY-SA 4.0. The licence was true about the file and false about the row.
--
--   ALI SALEH (1ef074ea-…, Bell, California). Ours is an older man with a heavy black moustache:
--   Ali Abdullah SALEH, the late President of Yemen. The City of Bell publishes its own photograph
--   of its Ali Saleh (cityofbell.gov …/city-council/images/ali-saleh.jpg, 1009x1261) and he is a
--   visibly different, much younger man with a trimmed dark beard in a light grey suit.
--
--   JOE FRANKLIN (d2e60dbe-…, Manhattan Beach, California). Ours is an elderly man photographed in
--   a hotel corridor: Joe FRANKLIN, the New York talk-show host, who died in 2015. Manhattan
--   Beach's own Mayor Joe Franklin (manhattanbeach.gov …/showpublishedimage/34705, alt "Joe
--   Franklin") is a different man with white hair in a dark suit, seated before the US and
--   California flags.
--
-- ⚠ WHY THIS MIGRATION REMOVES RATHER THAN REPLACES THEM. Removing a wrong face is unambiguously
-- correct and needs no new permission. Replacing it needs each city's use policy read first --
-- the rule this programme paid for at gov.texas.gov -- and Manhattan Beach publishes its portrait
-- only at 224x148, below the 600x750 house target, and this repo does not upscale. So the
-- photographs come down now and the replacements are a separate, sourced piece of work.
-- 🟢 NOTHING IS DESTROYED: both storage objects are left in place, so a revert is re-inserting the
-- image row and restoring the scalar from the values recorded below.
--
-- ============================================================================================
-- THE OTHER TWO ARE GENUINE LICENCE FAULTS, AND THEY GET OPPOSITE TREATMENT
-- ============================================================================================
--   R. REX PARRIS (87546d4d-…, Mayor of Lancaster, California) -- ✅ THE PERSON IS RIGHT. Checked
--   against Lancaster's own "Parris New Official Portrait" (1920x2111): same man, same beard, same
--   glasses, different setting. Only the licence is unsupportable -- cc_by-sa_4.0 with no origin,
--   recorded `unknown` by the audit. BLANKED to NULL, the CC_0334 (Sid Miller) disposition: NULL
--   renders no credit line, where 'unknown' would render one pointing at a source we cannot name.
--   The photograph does not change.
--
--   CHRIS RABB (013bf70b-…, Pennsylvania House) -- REPLACED, the CC_0327 (Kaela Berg) disposition.
--   🔴 A NUMBER IN HIS MANIFEST ROW NEARLY BOUGHT THE WRONG FIX. He is 1 of 254 PA-wave rows
--   carrying `cc0` where 251 colleagues carry the Assembly string -- the "one row disagrees with
--   its chamber" signature of the Eric Pratt over-claim, whose fix is a relabel. His manifest row
--   also reads identity_mad: 0.86, far under the 1.5 match threshold, which reads as "our stored
--   file IS the Assembly portrait". OPENING THE IMAGE KILLED THAT: ours is a CAMPAIGN RALLY photo,
--   with a "RABB for CONGRESS" banner behind him and a microphone in his hand. His manifest row is
--   flagged `already_hosted: true`, meaning the wave SKIPPED him -- so its licence string and its
--   MAD score describe the photograph it would have imported, NEVER the one we store.
--   ▶ identity_mad IN A SKIPPED ROW IS NOT A TEST OF OUR STORED FILE.
--   `cc0` is a public-domain dedication, and nobody dedicated a campaign photographer's work to the
--   public domain. So the photograph is replaced with the Assembly's own, under the terms his 251
--   colleagues already carry.
--
-- THE REPLACEMENT, AND THE POLICY READ THAT PRECEDED IT (gov.texas.gov rule):
--   palegis.us/legal was read on 2026-11-02 before the file was taken. It carries exactly two
--   things -- an accuracy disclaimer ("AS IS without warranty") and a DMCA notice-and-takedown
--   procedure. No reservation of rights, no "may not be used without permission". That is the
--   silence the 251 existing rows already record, re-verified rather than inherited.
--   Source  https://www.palegis.us/resources/images/members/original/1760.jpg  (4838x6773)
--   Crop    MEASURED, not centred: 4:5 at full width => 4838x6048, excess height 725 taken
--           ENTIRELY FROM THE BOTTOM (y=0), which keeps the photographer's own headroom; a centre
--           crop would have left 3.6% headroom against 9.6%. Downscaled x0.1240 to 600x750 --
--           nothing enlarged. ⚠ The two candidate crops looked like different zoom levels side by
--           side; mean absolute difference once shift-aligned was 2.243, i.e. a pure 45px shift.
--           The eye was wrong and the measurement corrected it.
--   Object  politician_photos/pa-legis-2026/013bf70b-627c-4699-b11d-67924e6916a2-headshot.jpg
--           Uploaded under a NEW key, so his old object survives untouched. Verified: new object
--           HTTP 200 / 34,089 B (matching the local file), old object still HTTP 200 / 84,946 B,
--           and a never-uploaded key in the same prefix returns HTTP 400 -- so the 200s mean
--           something.
--
-- ============================================================================================
-- 🔴 VALUES THIS MIGRATION OVERWRITES, RECORDED HERE BECAUSE NOTHING ELSE RECORDS THEM
-- ============================================================================================
--   Ali Saleh      image 41516abd-4952-4b53-9b3b-00a582ed054f (type default) DELETED
--                  it held photo_license 'cc_by-sa_4.0' and url
--                  …/politician_photos/la_county/2026-audit/1ef074ea-8237-48b9-b84d-8b165e790bbb.jpg
--                  politicians.photo_custom_url  (that same url)  -> NULL
--                  politicians.photo_origin_url  was already NULL, unchanged
--   Joe Franklin   image 988ad452-d57d-4fc1-9221-ece0d1706249 (type default) DELETED
--                  it held photo_license 'cc_by-sa_4.0' and url
--                  …/politician_photos/la_county/2026-audit/d2e60dbe-31b5-44e0-9c95-b95b65bdb697.jpg
--                  politicians.photo_custom_url  (that same url)  -> NULL
--                  politicians.photo_origin_url  was already NULL, unchanged
--   R. Rex Parris  image 7184e697-5a57-4f21-8ed8-fd37d9b0cf46
--                  photo_license  'cc_by-sa_4.0' -> NULL      (url and scalars unchanged)
--   Chris Rabb     image 6e96277c-b4cb-488c-8418-fc2a175734eb
--                  photo_license  'cc0' -> the 166-char Pennsylvania General Assembly string
--                  url / photo_custom_url
--                     …/politician_photos/013bf70b-627c-4699-b11d-67924e6916a2-headshot.jpg
--                  -> …/politician_photos/pa-legis-2026/013bf70b-627c-4699-b11d-67924e6916a2-headshot.jpg
--                  photo_origin_url  NULL -> https://www.palegis.us/house/members/bio/1760/rep-rabb
--
-- ⚠ OUT OF SCOPE, FOUND WHILE DOING THIS, NOT FIXED HERE. Two occupancy facts contradict their
-- city's own roster: we seat Ali Saleh as Bell's MAYOR (Bell's mayor is Ana Maria Quintana; Saleh
-- is a councilmember) and Joe Franklin as a Manhattan Beach COUNCIL MEMBER (he is its mayor). Both
-- cities rotate the mayoralty, so these are probably stale rather than wrong-in-kind. They are an
-- occupancy question, not a licence one.
--
-- ▶ THE REAL FOLLOW-UP: 40 of the 43 no-origin CC rows have NOT been looked at. Two of the three
-- examined here were the wrong person. That population was assembled by exactly the predicate that
-- selects for this defect -- a CC licence inferred from a host, with no origin -- so the hit rate
-- is not a coincidence and the remaining 40 should be swept FOR IDENTITY, not for attribution.
--
-- Run: node backend/scripts/apply-migration-file.mjs backend/migrations/CC_0335_photo_licence_overclaims.sql

BEGIN;

-- A census taken BEFORE anything moves, so the final gate can prove nothing else shifted.
CREATE TEMP TABLE lic_before AS
  SELECT coalesce(photo_license, '<null>') AS lic, count(*) AS n
    FROM essentials.politician_images
   GROUP BY 1;

CREATE TEMP TABLE fix (
  politician_id uuid PRIMARY KEY,
  who           text NOT NULL,
  image_id      uuid NOT NULL,
  action        text NOT NULL,          -- 'remove' | 'blank' | 'relabel'
  old_licence   text NOT NULL,
  new_licence   text,                   -- NULL for remove and blank
  new_url       text,                   -- only for relabel
  new_origin    text                    -- only for relabel
) ON COMMIT DROP;

INSERT INTO fix VALUES
 ('1ef074ea-8237-48b9-b84d-8b165e790bbb'::uuid, 'Ali Saleh',
  '41516abd-4952-4b53-9b3b-00a582ed054f'::uuid, 'remove', 'cc_by-sa_4.0', NULL, NULL, NULL),
 ('d2e60dbe-31b5-44e0-9c95-b95b65bdb697'::uuid, 'Joe Franklin',
  '988ad452-d57d-4fc1-9221-ece0d1706249'::uuid, 'remove', 'cc_by-sa_4.0', NULL, NULL, NULL),
 ('87546d4d-78ee-4aae-82cb-89ae805e10b4'::uuid, 'R. Rex Parris',
  '7184e697-5a57-4f21-8ed8-fd37d9b0cf46'::uuid, 'blank',  'cc_by-sa_4.0', NULL, NULL, NULL),
 ('013bf70b-627c-4699-b11d-67924e6916a2'::uuid, 'Chris Rabb',
  '6e96277c-b4cb-488c-8418-fc2a175734eb'::uuid, 'relabel', 'cc0',
  'Pennsylvania General Assembly official member portrait (palegis.us). The chambers publish no use policy; the site''s only copyright page is a DMCA complaint procedure.',
  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/pa-legis-2026/013bf70b-627c-4699-b11d-67924e6916a2-headshot.jpg',
  'https://www.palegis.us/house/members/bio/1760/rep-rabb');

-- ---------------------------------------------------------------------------------------------
-- Pre-flight. Every row must still be exactly what the header says it is, or the record of the
-- overwritten values above is already wrong and must not be trusted.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM fix f JOIN essentials.politicians p ON p.id = f.politician_id;
  IF n <> 4 THEN RAISE EXCEPTION 'pre-flight: expected 4 politicians, found %', n; END IF;

  SELECT count(*) INTO n
    FROM fix f
    JOIN essentials.politician_images pi ON pi.id = f.image_id
   WHERE pi.politician_id = f.politician_id
     AND pi.type = 'default'
     AND pi.photo_license = f.old_licence;
  IF n <> 4 THEN
    RAISE EXCEPTION 'pre-flight: expected 4 rows on their recorded image id AND old licence, found %', n;
  END IF;

  -- Each has exactly ONE image row, so removing the default one leaves no second face behind and
  -- relabelling cannot miss a sibling.
  SELECT count(*) INTO n
    FROM essentials.politician_images pi
    JOIN fix f ON f.politician_id = pi.politician_id
   WHERE pi.id <> f.image_id;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-flight: % extra image row(s) exist for these four', n; END IF;

  -- 🔴 SEAT CHECK. The licence written to Rabb is chamber-specific: it states what the Pennsylvania
  -- General Assembly publishes. Writing it onto someone outside that body would be a false
  -- statement about a source, so assert the seat and not merely the person.
  SELECT count(*) INTO n
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE och.politician_id = '013bf70b-627c-4699-b11d-67924e6916a2'::uuid
     AND c.name ILIKE '%Pennsylvania%House%';
  IF n < 1 THEN RAISE EXCEPTION 'pre-flight: Rabb does not hold a Pennsylvania House seat'; END IF;

  -- The string being written must be the one his colleagues already carry, byte for byte. A near
  -- miss would silently create a 2-value vocabulary that every later census has to reconcile.
  SELECT count(*) INTO n
    FROM essentials.politician_images
   WHERE photo_license = (SELECT new_licence FROM fix WHERE who = 'Chris Rabb');
  IF n <> 251 THEN
    RAISE EXCEPTION 'pre-flight: expected 251 rows already on the PA string, found % -- the text differs', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- 1. The two wrong people: the photograph comes down.
-- ---------------------------------------------------------------------------------------------
DELETE FROM essentials.politician_images pi
 USING fix f
 WHERE pi.id = f.image_id AND f.action = 'remove';

UPDATE essentials.politicians p
   SET photo_custom_url = NULL
  FROM fix f
 WHERE p.id = f.politician_id AND f.action = 'remove';

-- ---------------------------------------------------------------------------------------------
-- 2. Parris: the unsupportable claim is blanked. The photograph stays.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET photo_license = NULL
  FROM fix f
 WHERE pi.id = f.image_id AND f.action = 'blank' AND pi.photo_license = f.old_licence;

-- ---------------------------------------------------------------------------------------------
-- 3. Rabb: the photograph is replaced and the licence states its real source.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.politician_images pi
   SET photo_license = f.new_licence,
       url           = f.new_url
  FROM fix f
 WHERE pi.id = f.image_id AND f.action = 'relabel' AND pi.photo_license = f.old_licence;

UPDATE essentials.politicians p
   SET photo_custom_url = f.new_url,
       photo_origin_url = f.new_origin
  FROM fix f
 WHERE p.id = f.politician_id AND f.action = 'relabel';

-- ---------------------------------------------------------------------------------------------
-- Post-verify. Meaning-bearing gates first; the arithmetic census last, because a generator's own
-- row counts move for ANY edit and shadow every semantic gate behind them (CC_0328).
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE n int; v_before int;
BEGIN
  -- 🟢 THE WHOLE POINT, AS A NUMBER: none of these four now asserts a licence nobody granted.
  SELECT count(*) INTO n
    FROM essentials.politician_images pi
    JOIN fix f ON f.politician_id = pi.politician_id
   WHERE pi.photo_license ILIKE 'cc%';
  IF n <> 0 THEN RAISE EXCEPTION 'post-verify: % of the four still claim a CC licence', n; END IF;

  -- 🔴 THE WRONG FACES MUST BE UNREACHABLE BY EITHER PATH. The grid reads images[] and the backend
  -- reads the scalar, so a removal that clears only one of them still shows the wrong man.
  SELECT count(*) INTO n
    FROM fix f
    LEFT JOIN essentials.politician_images pi ON pi.politician_id = f.politician_id
    LEFT JOIN essentials.politicians p ON p.id = f.politician_id
   WHERE f.action = 'remove'
     AND (pi.id IS NOT NULL OR coalesce(p.photo_custom_url, '') <> '' OR coalesce(p.photo_origin_url, '') <> '');
  IF n <> 0 THEN
    RAISE EXCEPTION 'post-verify: a removed photograph is still reachable on % row(s)', n;
  END IF;

  -- Parris keeps his photograph and loses only the claim.
  SELECT count(*) INTO n
    FROM essentials.politician_images
   WHERE id = '7184e697-5a57-4f21-8ed8-fd37d9b0cf46'::uuid
     AND photo_license IS NULL
     AND url LIKE '%la_county/2026-audit/87546d4d-78ee-4aae-82cb-89ae805e10b4.jpg';
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: Parris is not blanked-with-photograph-intact'; END IF;

  -- 🔴 Rabb: the scalar and the image row must AGREE and both point at the new object. A split
  -- leaves a voter looking at one photograph while the record describes another.
  SELECT count(*) INTO n
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.id = '6e96277c-b4cb-488c-8418-fc2a175734eb'::uuid
     AND pi.url = p.photo_custom_url
     AND pi.url LIKE '%politician_photos/pa-legis-2026/%'
     AND p.photo_origin_url = 'https://www.palegis.us/house/members/bio/1760/rep-rabb';
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: Rabb''s image row and scalar do not agree on the new object'; END IF;

  -- His chamber is now uniform: 251 + Rabb.
  SELECT count(*) INTO n
    FROM essentials.politician_images
   WHERE photo_license = (SELECT new_licence FROM fix WHERE who = 'Chris Rabb');
  IF n <> 252 THEN RAISE EXCEPTION 'post-verify: expected 252 rows on the PA string, found %', n; END IF;

  -- ⚠ DELTA, NOT TOTAL. The no-origin CC population is measured as the CHANGE this transaction
  -- makes, because other sessions move the absolute number while this file is being written.
  SELECT count(*) INTO n
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE pi.type = 'default'
     AND pi.photo_license ~* '^\s*cc[-_ ]?(by|zero)'
     AND lower(trim(pi.photo_license)) NOT LIKE 'cc0%'
     AND coalesce(p.photo_origin_url, '') = '';
  SELECT coalesce((SELECT b.n FROM lic_before b WHERE b.lic = 'cc_by-sa_4.0'), 0) INTO v_before;
  IF n <> 40 THEN
    RAISE EXCEPTION 'post-verify: expected the no-origin CC population to fall 43 -> 40, found %', n;
  END IF;

  -- The three cc_by-sa_4.0 rows this migration touched are gone from that value, and only those.
  SELECT count(*) INTO n FROM essentials.politician_images WHERE photo_license = 'cc_by-sa_4.0';
  IF n <> v_before - 3 THEN
    RAISE EXCEPTION 'post-verify: cc_by-sa_4.0 moved % -> %, expected a fall of exactly 3', v_before, n;
  END IF;

  -- Nothing outside the four values this migration touches changed count.
  SELECT count(*) INTO n
    FROM (SELECT coalesce(photo_license, '<null>') AS lic, count(*) AS n
            FROM essentials.politician_images GROUP BY 1) a
    FULL JOIN lic_before b ON b.lic = a.lic
   WHERE coalesce(a.n, 0) <> coalesce(b.n, 0)
     AND coalesce(a.lic, b.lic) NOT IN (
       'cc_by-sa_4.0', 'cc0', '<null>',
       'Pennsylvania General Assembly official member portrait (palegis.us). The chambers publish no use policy; the site''s only copyright page is a DMCA complaint procedure.');
  IF n <> 0 THEN
    RAISE EXCEPTION 'post-verify: % licence value(s) outside the four changed count', n;
  END IF;
END $$;

COMMIT;
