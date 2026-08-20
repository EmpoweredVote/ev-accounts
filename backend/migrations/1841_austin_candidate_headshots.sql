-- 1841_austin_candidate_headshots.sql
-- Austin City Council Nov 2026 candidates: 8 campaign-site headshots, politician records created and
-- race_candidates linked.
--
-- ALREADY APPLIED to prod 2026-08-20 by the find-headshots path; idempotent. This migration is the
-- repo's record of which candidate maps to which politician row and where each portrait came from.
--
-- SOURCE SURVEY (measured before any import). No cohort source exists for this field:
--   patch.com/texas/austin            -> 404. Patch does not cover Austin.
--   Ballotpedia                       -> 0 of 19 usable. 15 are 404; two "hits" (Steven Brown,
--                                        Eduardo Romero) are DISAMBIGUATION pages for common names,
--                                        not these candidates; the two real pages both show
--                                        Ballotpedia's "submit a photo" placeholder.
--   KXAN candidate guide              -> 403, blocks Playwright too.
--   Friends of Austin Neighborhoods   -> empty stub page.
--   austincurrent.org (Monitor's successor) -> no portraits, BUT its 2026-08-19 fundraising piece
--                                        LINKS each candidate's campaign site by name. That is how
--                                        11 of the 19 sites were found in one pass.
--
-- 🔴 THE CONTACT SHEET REJECTED THREE IMAGES THAT WOULD OTHERWISE HAVE SHIPPED AS HEADSHOTS:
--     Farrah Abraham  -> a campaign GRAPHIC ("VOTE DISTRICT 5 / 2026") with text over a flag.
--     Katie Kam       -> a LOGO/wordmark, not a photograph at all.
--     Selena Xie      -> a GROUP photo of people seated in council chambers; her site carries only
--                        event photography, no portrait.
--    A fourth defect was caught at crop review: Rich Heyman's first crop cut off the top of his
--    head -- the same defect just fixed on the Chip Roy portrait -- and was re-cropped before import.
--
-- Two portraits are SOFT and flagged REPLACE in photo_license: Michael Nahas (300x300 source, x2.63)
-- and Jeffery Bowen (523x349, x2.27). They are the only images those campaigns publish. The gate
-- here is the UPSCALE FACTOR, not a pixel floor.
--
-- Licence for all eight is the candidate's own campaign site (press_use), recorded per row with the
-- host and the measured upscale.
--
-- Idempotency: the link UPDATE is guarded on IS NULL; the gate asserts the end state.

BEGIN;

UPDATE essentials.race_candidates rc SET politician_id = v.pid::uuid
FROM (VALUES
  ('3fc94c88-f504-4cf2-aa16-8d4d887de367','98736920-231a-4c28-9d12-2ce1e55ffea8'),
  ('9800bc93-3245-4240-853f-2b61a0866c4f','6d47588a-198b-4643-b5fa-3722fb1a9e0c'),
  ('b2dd57c7-4a9c-4938-a60e-5a7736258596','5f222044-4f16-4cc6-91dc-1e361f692e6e'),
  ('c23b4497-9c41-4dc7-a724-bc8228794338','b4df625a-c699-41cf-944b-21164eea46e0'),
  ('5034a80d-70bc-42a3-9f17-17467b019022','e1ce4a17-a3cc-4ea2-951a-4ee401203dee'),
  ('02b5b5b4-c62e-4690-b003-9e21d0f916fc','140e90de-f225-4016-8efa-a65aed20dec1'),
  ('36bbbf80-94c8-4825-96b9-58949f357706','061d19ba-6c1d-44b9-ad22-657dad8f65b7'),
  ('36ea65a3-fd10-47ec-adc4-df27d54c0f74','a46e4b66-8e5f-411a-a829-696fae135ed3')
) AS v(rcid, pid)
WHERE rc.id = v.rcid::uuid AND rc.politician_id IS NULL;

DO $$
DECLARE v_linked int; v_img int; v_replace int;
BEGIN
  SELECT count(*) INTO v_linked FROM essentials.race_candidates rc
   WHERE rc.id = ANY(ARRAY[
     '3fc94c88-f504-4cf2-aa16-8d4d887de367','9800bc93-3245-4240-853f-2b61a0866c4f',
     'b2dd57c7-4a9c-4938-a60e-5a7736258596','c23b4497-9c41-4dc7-a724-bc8228794338',
     '5034a80d-70bc-42a3-9f17-17467b019022','02b5b5b4-c62e-4690-b003-9e21d0f916fc',
     '36bbbf80-94c8-4825-96b9-58949f357706','36ea65a3-fd10-47ec-adc4-df27d54c0f74']::uuid[])
     AND rc.politician_id IS NOT NULL;
  IF v_linked <> 8 THEN RAISE EXCEPTION 'Expected 8 linked candidates, found %', v_linked; END IF;

  -- Every linked candidate must actually have a renderable image; a link with no portrait is the
  -- silent failure this pass exists to avoid.
  SELECT count(*) INTO v_img FROM essentials.race_candidates rc
    JOIN essentials.politician_images i ON i.politician_id = rc.politician_id
   WHERE rc.id = ANY(ARRAY[
     '3fc94c88-f504-4cf2-aa16-8d4d887de367','9800bc93-3245-4240-853f-2b61a0866c4f',
     'b2dd57c7-4a9c-4938-a60e-5a7736258596','c23b4497-9c41-4dc7-a724-bc8228794338',
     '5034a80d-70bc-42a3-9f17-17467b019022','02b5b5b4-c62e-4690-b003-9e21d0f916fc',
     '36bbbf80-94c8-4825-96b9-58949f357706','36ea65a3-fd10-47ec-adc4-df27d54c0f74']::uuid[]);
  IF v_img <> 8 THEN RAISE EXCEPTION 'Expected 8 candidate images, found %', v_img; END IF;

  SELECT count(*) INTO v_replace FROM essentials.politician_images
   WHERE politician_id IN ('b4df625a-c699-41cf-944b-21164eea46e0','061d19ba-6c1d-44b9-ad22-657dad8f65b7')
     AND photo_license LIKE '%REPLACE%';
  IF v_replace <> 2 THEN RAISE EXCEPTION 'Expected the 2 soft portraits flagged REPLACE, found %', v_replace; END IF;

  RAISE NOTICE 'OK: 8 Austin candidates linked with campaign-site portraits; 2 flagged REPLACE.';
END $$;

COMMIT;
