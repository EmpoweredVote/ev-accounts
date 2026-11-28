-- Migration CA_0437_bloomington_sponsor_sentence_runon: cut one sponsorship quote at the end of its own sentence
--
-- WHY: the sponsor reader (backend/src/lib/localRecord/onboard/sponsors.ts) did not split a synopsis that ends
--   without a full stop from the next line of the minutes, so the stored proof sentence for Ord 2026-22 Amendment 03
--   (Piedmont-Smith, meeting file 17809) ran on into the next motion, "Piedmont-Smith moved and Zulich seconded
--   Amendment 05 to Ordinance 2026-22." The quote is shown to voters as proof, so the run-on misquotes the record.
--   The reader is fixed in the same PR; this file corrects the one row already stored.
-- WHAT: one UPDATE of essentials.legislative_sponsorships.sentence, row 455135ab-6362-4698-9cd4-3cb6e53f4fed. No
--   other column changes; no row is added or removed. Measured by a first-load dry run from the cached documents with
--   the fixed reader: 224 rows read, same members and roles as before; 2 sentences change, and only this one is stored
--   (the other, Ord 2026-31 Amendment 02, has no bill row).
-- OLD VALUE (overwritten here; md5 17829796798f9bf205b002fd6832438e, 726 characters):
--     This amendment, sponsored by Cm. Piedmont-Smith, does the following: 1) Aligns prohibited uses with the
--     expanded definition of surveillance camera proposed by Am. 02 and allows limited technical access to internal
--     systems for repairs - 2.87.035 2) Clarifies that acquisition of ALPR systems, as well as their use, is banned
--     - 2.87.030(a) 3) Clarifies the ban on access to ALPR data collected by others - 2.87.030(d) 4) Adds a
--     requirement for surveillance cameras that ARE allowed under this ordinance to not by used for facial
--     recognition, biometric identification, or automated tracking of persons without prior city council
--     authorization - 2.87.040 Piedmont-Smith moved and Zulich seconded Amendment 05 to Ordinance 2026-22.
-- NEW VALUE (650 characters; the old value cut before " Piedmont-Smith moved ..."):
--     This amendment, sponsored by Cm. Piedmont-Smith, does the following: 1) Aligns prohibited uses with the
--     expanded definition of surveillance camera proposed by Am. 02 and allows limited technical access to internal
--     systems for repairs - 2.87.035 2) Clarifies that acquisition of ALPR systems, as well as their use, is banned
--     - 2.87.030(a) 3) Clarifies the ban on access to ALPR data collected by others - 2.87.030(d) 4) Adds a
--     requirement for surveillance cameras that ARE allowed under this ordinance to not by used for facial
--     recognition, biometric identification, or automated tracking of persons without prior city council
--     authorization - 2.87.040
-- Idempotent: the UPDATE matches only the exact old value. Re-running after it applied changes nothing and passes.
-- Slot: CA_0437, reserved by the owner's session.

BEGIN;

DO $$
DECLARE
  old_sentence constant text := $q$This amendment, sponsored by Cm. Piedmont-Smith, does the following: 1) Aligns prohibited uses with the expanded definition of surveillance camera proposed by Am. 02 and allows limited technical access to internal systems for repairs - 2.87.035 2) Clarifies that acquisition of ALPR systems, as well as their use, is banned - 2.87.030(a) 3) Clarifies the ban on access to ALPR data collected by others - 2.87.030(d) 4) Adds a requirement for surveillance cameras that ARE allowed under this ordinance to not by used for facial recognition, biometric identification, or automated tracking of persons without prior city council authorization - 2.87.040 Piedmont-Smith moved and Zulich seconded Amendment 05 to Ordinance 2026-22.$q$;
  new_sentence constant text := $q$This amendment, sponsored by Cm. Piedmont-Smith, does the following: 1) Aligns prohibited uses with the expanded definition of surveillance camera proposed by Am. 02 and allows limited technical access to internal systems for repairs - 2.87.035 2) Clarifies that acquisition of ALPR systems, as well as their use, is banned - 2.87.030(a) 3) Clarifies the ban on access to ALPR data collected by others - 2.87.030(d) 4) Adds a requirement for surveillance cameras that ARE allowed under this ordinance to not by used for facial recognition, biometric identification, or automated tracking of persons without prior city council authorization - 2.87.040$q$;
  rows_before  bigint;
  rows_after   bigint;
  changed      bigint;
  now_sentence text;
BEGIN
  IF md5(old_sentence) <> '17829796798f9bf205b002fd6832438e' THEN
    RAISE EXCEPTION 'CA_0437: the old value in this file is not the one measured in production';
  END IF;
  IF left(old_sentence, length(new_sentence)) <> new_sentence THEN
    RAISE EXCEPTION 'CA_0437: the new value is not a cut of the old one';
  END IF;

  SELECT count(*) INTO rows_before FROM essentials.legislative_sponsorships
   WHERE bill_id = 'c8f805b3-49af-448f-893b-4af1053a4057';

  UPDATE essentials.legislative_sponsorships
     SET sentence = new_sentence, updated_at = now()
   WHERE id = '455135ab-6362-4698-9cd4-3cb6e53f4fed'
     AND bill_id = 'c8f805b3-49af-448f-893b-4af1053a4057'
     AND amendment_label = 'Amendment 03'
     AND politician_id = '91f6d45d-5e7e-48f6-aab1-9476d81946b5'
     AND role = 'sponsor'
     AND sentence = old_sentence;
  GET DIAGNOSTICS changed = ROW_COUNT;

  -- Post-verify.
  IF changed > 1 THEN
    RAISE EXCEPTION 'CA_0437: % rows changed, expected at most 1', changed;
  END IF;
  SELECT sentence INTO now_sentence FROM essentials.legislative_sponsorships
   WHERE id = '455135ab-6362-4698-9cd4-3cb6e53f4fed'
     AND politician_id = '91f6d45d-5e7e-48f6-aab1-9476d81946b5' AND role = 'sponsor'
     AND amendment_label = 'Amendment 03';
  IF now_sentence IS DISTINCT FROM new_sentence THEN
    RAISE EXCEPTION 'CA_0437: the row does not hold the new value (changed %, now %)', changed, left(coalesce(now_sentence, '<missing>'), 80);
  END IF;
  SELECT count(*) INTO rows_after FROM essentials.legislative_sponsorships
   WHERE bill_id = 'c8f805b3-49af-448f-893b-4af1053a4057';
  IF rows_after <> rows_before THEN
    RAISE EXCEPTION 'CA_0437: sponsorship rows for Ord 2026-22 moved from % to %', rows_before, rows_after;
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.legislative_sponsorships
              WHERE sentence ~ '\m[A-Z][A-Za-z''-]+ moved and [A-Z][A-Za-z''-]+ seconded') THEN
    RAISE EXCEPTION 'CA_0437: a stored sponsorship sentence still holds a "moved and seconded" motion';
  END IF;
  RAISE NOTICE 'CA_0437: % row changed; Ord 2026-22 keeps % sponsorship rows', changed, rows_after;
END $$;

COMMIT;
