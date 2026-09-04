BEGIN;

-- =============================================================================
-- CA_0096: Homelessness — chair-4 re-audit (in-place), for the v2 "civil penalties" reword
-- =============================================================================
-- Created 2026-08-31 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2).
--
-- CONTEXT. CA_0063 approved the homelessness v2 rework and pinned it into Season 2
--   (still draft). v2 narrows chair 4 from "graduated warnings and penalties, while
--   requiring jurisdictions to maintain basic shelter options" to "Prohibiting
--   encampments on public property, enforced through graduated warnings and CIVIL
--   penalties". That narrowing moves the chair-4/chair-5 line onto penalty TYPE:
--     chair 4 (v2) = civil penalties;  chair 5 (v2) = "criminal penalties".
--   This migration is the re-audit CA_0063 flagged: the 123 chair-4 rows re-checked
--   against the new wording, moving the ones whose supported camping ban carries
--   CRIMINAL penalties down to chair 5.
--
-- RULING (Chris Andrews, 2026-08-31), applied here:
--   (1) A fine-only Class C misdemeanor (criminal classification, NO jail) is treated
--       as the CIVIL tier and STAYS at chair 4. So Greg Abbott (HB1925), Katy Hall
--       (HB505) and the McKinney voters (Lynch, Cloutier, Franklin — Class C, $500 fine)
--       stay at chair 4, as do the confirmed-civil bans (Beaverton Ord 4841 civil
--       infraction; Tigard Class 3 civil infraction; Brockton $200 fine) and every
--       inference row with no ordinance/penalty established.
--   (2) A ban carried by JAIL / ARREST / CRIMINAL PROSECUTION is chair 5, even where the
--       politician pairs it with services or disclaimed "criminalization" — under the
--       reworded ladder the services-pairing no longer separates 4 from 5; penalty type
--       does. So the Fremont/Henderson/Colorado-Springs service-pairers move too.
--
-- THE 14 MOVES (chair 4 -> chair 5). Penalty type of each shared ordinance was verified
--   by primary/press search 2026-08-31:
--     Fremont citywide Camping Ordinance (adopted 6-1, 2025-02-11): camping on public
--       property is a MISDEMEANOR, up to $1,000 + 6 months jail (not an infraction).
--       -> Kathy Kimberlin, Yang Shao, Raymond Liu, Teresa Keng, Yajing Zhang, Raj Salwan.
--     Henderson Ordinance No. 3967 (adopted 2023-06-06): public-right-of-way camping is a
--       MISDEMEANOR, up to 6 months jail / $1,000; 150 citations-or-arrests Aug'23-Sep'24.
--       -> Dan H. Stewart, Jim Seebock.
--     Colorado Springs Ordinance No. 26-08 (final passage 7-2, 2026-03-10): camping /
--       vehicle-camping ban, after a warning up to 10 days JAIL + $300 + probation.
--       -> David Leinweber, Brandy Williams.
--     Arrest / criminal prosecution (own reasoning already names it):
--       -> Matt Mahan (arrest after 3 shelter refusals), Aurelio Mattucci (arrest of
--          refusers), George Chen (arrest of refusers), Nathan Hochman (misdemeanor
--          prosecution of repeat refusers).
--   Josh Hoover (AB-257) was CONSIDERED and LEFT at chair 4: AB-257 is infraction-forward
--   ($10, escalating to a misdemeanor ceiling) and it failed in committee — a graduated
--   civil-penalty scheme under ruling (1), not a jail/arrest ban.
--   New distribution: 34 / 291 / 164 / 109 / 41 (was 34 / 291 / 164 / 123 / 27).
--
-- REASONING EDITS. 7 movers already name the criminal mechanism in their own reasoning
--   (Kimberlin, Yang Shao, Dan Stewart, Mahan, Mattucci, George Chen, Hochman) and are
--   moved value-only, untouched (CA_0045 discipline). The other 7 (Liu, Keng, Zhang,
--   Salwan, Seebock, Leinweber, Williams) have their context reasoning rewritten to state
--   the verified criminal (jail) penalty of the ordinance they voted for — Leinweber's
--   especially, whose prior reasoning quoted him calling the ordinance non-criminalizing;
--   the rewrite records that the instrument he voted for imposes jail, which is the
--   chair-5 fact, while noting his framing.
--
-- WHY IN-PLACE (edits the OPEN Season 1). No Season 2 answer rows exist yet (Season 2 is
--   unassembled); the answers are the single shared Season-1 set. The schema cannot hold
--   "chair 4 in Season 1, chair 5 in Season 2" (politician_answers.value is CHECK 1..5 and
--   the compare read collapses to the newest season with no status gate), so the correction
--   is applied to the shared rows and carries into Season 2 when it opens with v2 pinned —
--   exactly as CA_0045 / CA_0033 / CA_0035 / CA_0038 did for their reworks. Note: under the
--   OLD v1 chair-4 wording ("graduated warnings and penalties" — unqualified) several of
--   these were defensibly chair 4; the move sharpens them toward the criminal pole for the
--   v2 ladder, and a criminal-penalty ban still reads as chair-5-leaning in the open season.
--
-- Idempotent: every UPDATE no-ops on re-run (value already 5).
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='4938766b-b45a-46e3-93bd-b8b30651271a' AND topic_key='homelessness') THEN
    RAISE EXCEPTION 'CA_0096: homelessness topic id mismatch';
  END IF;
  -- The re-audit is against v2 (rev2, version 2), which CA_0063 approved + pinned to Season 2.
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions
                 WHERE id='6958fa99-e317-45d7-8076-d11a0a78c897'
                   AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a'
                   AND version=2 AND revision=2) THEN
    RAISE EXCEPTION 'CA_0096: homelessness v2 revision missing';
  END IF;
END $$;

-- ── 1. Moves 4 -> 5, reasoning already names the criminal mechanism (7 keepers) ───────────────
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='4938766b-b45a-46e3-93bd-b8b30651271a' AND value=4
   AND politician_id IN (
     'f886f6da-d08f-4294-81bc-faf4a1eaad4d',  -- Kathy Kimberlin (Fremont — fines + jail)
     '7db82a3d-5aa2-4150-996e-b170b50b47fe',  -- Yang Shao (Fremont — $1,000 + 6 months jail)
     '50682ef1-360a-4597-9e1a-eaf43c50673d',  -- Dan H. Stewart (Henderson — criminal enforcement)
     '41949a2b-563a-4608-91c6-951c63252a91',  -- Matt Mahan (arrest after 3 refusals)
     '2b4b35a8-1498-46ad-aa9b-04650b454262',  -- Aurelio Mattucci (arrest of refusers)
     '3dfd7349-e0e2-486d-8767-8dfc203ca986',  -- George Chen (arrest of refusers)
     '83474f06-c501-416d-a870-65d75f0cec9d'); -- Nathan Hochman (criminal prosecution)

-- ── 2. Moves 4 -> 5, with context reasoning rewritten to the verified criminal penalty ────────
UPDATE inform.politician_answers SET value=5, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='4938766b-b45a-46e3-93bd-b8b30651271a' AND value=4
   AND politician_id IN (
     '42e95c4c-4e02-4d60-805c-6a3d857dd95a',  -- Raymond Liu (Fremont)
     'fecd31b9-fc2e-4d90-80f2-15ac89fb0eff',  -- Teresa Keng (Fremont)
     'd6d492b6-cbaf-4398-9301-4fbd10da571f',  -- Yajing Zhang (Fremont)
     '71124b00-549d-460c-8f84-41a01d99e037',  -- Raj Salwan (Fremont)
     '99d43f01-4b07-471f-bacf-e89d2a1c36b2',  -- Jim Seebock (Henderson)
     'e0e02e79-583b-4db8-86a0-6674faa0f090',  -- David Leinweber (Colorado Springs)
     '3a5875b4-4eeb-4c1f-b69c-1446f7955b43'); -- Brandy Williams (Colorado Springs)

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Liu voted YES for Fremont's citywide Camping Ordinance (adopted 6-1 on February 11, 2025), which bans camping on public property and classifies the violation itself as a misdemeanor punishable by up to a $1,000 fine and six months in jail — not a civil infraction. He also voted YES on the December 2024 property-removal ordinance that preceded it. A camping ban carried by criminal (misdemeanor/jail) penalties is the criminal-enforcement chair, not the civil-penalty tier.$r$,
  sources = ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/','https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/','https://www.fremont.gov/Home/Components/News/News/1259/']::text[]
 WHERE politician_id='42e95c4c-4e02-4d60-805c-6a3d857dd95a' AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Keng voted with the 6-1 majority for Fremont's citywide Camping Ordinance (adopted February 11, 2025), which bans camping on public property as a misdemeanor punishable by up to $1,000 and six months in jail, and for the December 2024 property-removal ordinance that preceded it. A camping ban enforced by criminal (misdemeanor/jail) penalties is the criminal-enforcement chair, not the civil-penalty tier.$r$,
  sources = ARRAY['https://www.tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/','https://www.tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/','https://www.fremont.gov/Home/Components/News/News/1259/']::text[]
 WHERE politician_id='fecd31b9-fc2e-4d90-80f2-15ac89fb0eff' AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Zhang voted YES on the December 17, 2024 property-removal ordinance and joined the 6-1 majority for Fremont's citywide Camping Ordinance (adopted February 11, 2025), which classifies camping on public property as a misdemeanor punishable by up to $1,000 and six months in jail. A camping ban carried by criminal (misdemeanor/jail) penalties is the criminal-enforcement chair, not the civil-penalty tier.$r$,
  sources = ARRAY['https://tricityvoice.com/new-housing-ordinance-causes-rift-in-fremont/','https://tricityvoice.com/fremonts-homeless-encampment-ban-divides-the-community/','https://www.fremont.gov/Home/Components/News/News/1259/']::text[]
 WHERE politician_id='d6d492b6-cbaf-4398-9301-4fbd10da571f' AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$As Fremont mayor, Salwan led and voted for the citywide Camping Ordinance (adopted 6-1, February 11, 2025), which makes camping on public property a misdemeanor punishable by up to $1,000 and six months in jail; the council later struck the ordinance's "aiding and abetting" clause but left the criminal camping ban intact. Pairing enforcement with continued outreach does not change that the ban itself carries criminal (misdemeanor/jail) penalties — the criminal-enforcement chair, not the civil-penalty tier.$r$,
  sources = ARRAY['https://en.wikipedia.org/wiki/Raj_Salwan','https://rajsalwan.com/priorities','https://www.fremont.gov/Home/Components/News/News/1259/']::text[]
 WHERE politician_id='71124b00-549d-460c-8f84-41a01d99e037' AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Seebock championed and voted for Henderson's public-camping ban, Ordinance No. 3967 (adopted June 6, 2023), under which camping or sleeping in a public right-of-way is a misdemeanor punishable by up to six months in jail and/or a $1,000 fine; Henderson police recorded 150 citations or arrests among 99 people under it between August 2023 and September 2024. A camping ban carried by criminal penalties is the criminal-enforcement chair even though he emphasized shelter/service offers before warnings — the reworded ladder no longer separates it from the civil-penalty chair by that pairing.$r$,
  sources = ARRAY['https://www.reviewjournal.com/local/henderson/henderson-council-passes-ordinance-outlawing-public-camping-2790502/','https://library.municode.com/nv/henderson/codes/code_of_ordinances']::text[]
 WHERE politician_id='99d43f01-4b07-471f-bacf-e89d2a1c36b2' AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Leinweber voted for Colorado Springs Ordinance No. 26-08 (final passage 7-2, March 10, 2026), which bans camping — including vehicle camping — on public property and, after a warning, is punishable by up to 10 days in jail, a fine of up to $300, and/or probation. Although Leinweber told council the ordinance "does not criminalize homelessness" and called for more services, the instrument he voted for imposes criminal (jail) penalties for public camping — the criminal-enforcement chair; under the reworded ladder his service framing no longer distinguishes it from the civil-penalty chair.$r$,
  sources = ARRAY['https://coloradosprings.legistar.com/LegislationDetail.aspx?ID=12939','https://www.cpr.org/2026/03/10/more-restrictions-car-camping-colorado-springs/']::text[]
 WHERE politician_id='e0e02e79-583b-4db8-86a0-6674faa0f090' AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Williams seconded the motion for final passage of Colorado Springs Ordinance No. 26-08 (adopted 7-2, March 10, 2026), a camping and vehicle-camping ban on public property punishable, after a warning, by up to 10 days in jail, a fine of up to $300, and/or probation. A camping ban carried by criminal (jail) penalties is the criminal-enforcement chair; her stated preference for "a variety of options" does not change the instrument's criminal penalties under the reworded ladder.$r$,
  sources = ARRAY['https://coloradosprings.legistar.com/LegislationDetail.aspx?ID=12939','https://www.cpr.org/2025/03/13/colorado-springs-2025-city-council-candidate-questionnaire-brandy-williams/','https://www.cpr.org/2026/03/10/more-restrictions-car-camping-colorado-springs/']::text[]
 WHERE politician_id='3a5875b4-4eeb-4c1f-b69c-1446f7955b43' AND topic_id='4938766b-b45a-46e3-93bd-b8b30651271a';

-- ── 3. Post-verify ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  tid uuid := '4938766b-b45a-46e3-93bd-b8b30651271a';
  c1 int;c2 int;c3 int;c4 int;c5 int; mv int;
BEGIN
  -- All 14 targeted rows are now at chair 5.
  SELECT count(*) INTO mv FROM inform.politician_answers
   WHERE topic_id=tid AND value=5 AND politician_id IN (
     'f886f6da-d08f-4294-81bc-faf4a1eaad4d','7db82a3d-5aa2-4150-996e-b170b50b47fe',
     '42e95c4c-4e02-4d60-805c-6a3d857dd95a','fecd31b9-fc2e-4d90-80f2-15ac89fb0eff',
     'd6d492b6-cbaf-4398-9301-4fbd10da571f','71124b00-549d-460c-8f84-41a01d99e037',
     '50682ef1-360a-4597-9e1a-eaf43c50673d','99d43f01-4b07-471f-bacf-e89d2a1c36b2',
     'e0e02e79-583b-4db8-86a0-6674faa0f090','3a5875b4-4eeb-4c1f-b69c-1446f7955b43',
     '41949a2b-563a-4608-91c6-951c63252a91','2b4b35a8-1498-46ad-aa9b-04650b454262',
     '3dfd7349-e0e2-486d-8767-8dfc203ca986','83474f06-c501-416d-a870-65d75f0cec9d');
  IF mv <> 14 THEN RAISE EXCEPTION 'CA_0096 verify: % of 14 movers at chair 5 (expected 14)', mv; END IF;

  -- Distribution.
  SELECT count(*) FILTER (WHERE value=1),count(*) FILTER (WHERE value=2),count(*) FILTER (WHERE value=3),
         count(*) FILTER (WHERE value=4),count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid;
  IF (c1,c2,c3,c4,c5) <> (34,291,164,109,41) THEN
    RAISE EXCEPTION 'CA_0096 verify: chair counts %/%/%/%/% (expected 34/291/164/109/41)', c1,c2,c3,c4,c5;
  END IF;

  -- The 7 rewritten rows carry the verified criminal-penalty language.
  IF EXISTS (SELECT 1 FROM inform.politician_context
             WHERE politician_id='e0e02e79-583b-4db8-86a0-6674faa0f090' AND topic_id=tid
               AND reasoning NOT ILIKE '%10 days in jail%') THEN
    RAISE EXCEPTION 'CA_0096 verify: Leinweber reasoning not rewritten to the jail penalty';
  END IF;

  RAISE NOTICE 'CA_0096 post-verify OK: 1=%/2=%/3=%/4=%/5=%; 14 moved 4->5', c1,c2,c3,c4,c5;
END $$;

COMMIT;
