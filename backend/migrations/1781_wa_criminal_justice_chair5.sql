-- 1781_wa_criminal_justice_chair5.sql
-- 12 rows on `judicial-criminal-justice` at chair 5, from SB 5566 (increasing the penalty for
-- assaulting a law enforcement officer, McCune R-2 prime). All 12 sponsors are Republicans, and this
-- closes 6 of the 11 Senate Republicans who were the last uncovered bloc.
--
-- ── ⚖ THIS EXTENDS THE OPERATOR'S RULING TO THE OTHER END OF THE LADDER. FLAGGED AS AN EXTENSION. ──
-- The ruling applied in migration 1780 was "structure over inferred purpose", made about chairs 1 and
-- 3. Chairs 4 and 5 are the same kind of pair, the other way up:
--   · chair 4, "making sure others think twice before doing the same thing", is a PURPOSE — general
--     deterrence, a claim about the effect on people who are not before the court;
--   · chair 5, "punishing the behavior; society needs to know that breaking the law has real
--     consequences", is a STRUCTURE — the sanction attaches to the conduct.
-- SB 5566 raises a felony class, moves the offence up the grid, and adds a mandatory minimum, while
-- stating no purpose at all. Reading deterrence into it is exactly the inference the ruling forbids,
-- so it is seated at chair 5. **If the operator meant the ruling to govern only the 1/3 pair, this is
-- the migration to revisit — the rows are otherwise unaffected.**
--   · chair 3 ("a mix: some accountability, some support, depending on what happened") is REFUTED
--     rather than unproven: the act has no support limb whatsoever, which is exactly what separates it
--     from the second-look statutes seated at chair 3 in migration 1780;
--   · chairs 1 and 2 are refuted in the same way — no rehabilitation, treatment or restitution.
--
-- ── 🔑 A UNANIMOUS BILL CANNOT EVIDENCE A CHAIR ON A PHILOSOPHY LADDER ────────────────────────────
-- The higher-reach instrument here was SSB 5323 (theft of first-responder equipment, 17 sponsors, 7
-- of them uncovered, ENACTED). It was rejected as a seating instrument after the session law was
-- read: it passed the Senate **48-0** and the House **96-0**. A measure every single legislator
-- supported cannot distinguish one chair from another, because the chairs describe a PREFERENCE among
-- competing values and a unanimous vote demonstrates no preference. Seating 17 people at chair 5 for
-- co-sponsoring a narrow enhancement about stealing firefighters' rescue equipment would read as a
-- philosophy none of them stated. SB 5566 by contrast is all-Republican and died in a committee
-- controlled by the other party — it is contested, so sponsoring it is a position.
-- 🔧 Rule to carry: before seating a cohort from an enacted bill, check the roll call. Unanimity is a
-- disqualifier, not a strength.
--
-- ── per-member screen: 5 flagged, all read, nobody moved ──────────────────────────────────────────
-- Every competing instrument was another enhancement, which reinforces rather than moves: Fortunato's
-- organized retail theft enhancement and general penalty increases, Wagoner's death penalty for
-- incarcerated murderers, Christian's juvenile firearm sentencing standards, Harris's penalties for
-- assaulting outreach workers, Boehnke's bill on violent protests at postsecondary institutions.
-- ⚠ One looked like a support instrument and is not. Christian's SB 5760 establishes a work release
-- centre — in the general administration building on the capitol campus, so that inmates are "in close
-- proximity to publicly elected officials"; it is captioned "the inmates in Olympia act". Its stated
-- purpose is legislative access, not reentry, so it reaches no chair. A stated purpose still has to
-- be ON the ladder's question.
BEGIN;

CREATE TEMP TABLE c5_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fec68f5f-c9e1-4579-869a-7b4a78f7da90' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Curtis King already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='fec68f5f-c9e1-4579-869a-7b4a78f7da90' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Curtis King already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d0350f2f-6463-452e-b97d-c18ea094e2ee' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Holy already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d0350f2f-6463-452e-b97d-c18ea094e2ee' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Holy already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='aadf55f0-a4b4-4a4a-acf0-bfce06815149' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Wilson already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='aadf55f0-a4b4-4a4a-acf0-bfce06815149' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeff Wilson already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='6cc4c706-fa7a-486f-ac67-6cbdede4a607' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim McCune already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='6cc4c706-fa7a-486f-ac67-6cbdede4a607' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim McCune already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f3cd74bb-3bdb-4d55-a07d-5c14bda50926' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Goehner already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f3cd74bb-3bdb-4d55-a07d-5c14bda50926' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Goehner already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='3db3f064-dd6e-4bca-9200-3d4395972253' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Wagoner already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='3db3f064-dd6e-4bca-9200-3d4395972253' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Keith Wagoner already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0e935fed-534e-42b0-a5ad-74f4199ff6df' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Leonard Christian already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0e935fed-534e-42b0-a5ad-74f4199ff6df' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Leonard Christian already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Boehnke already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Boehnke already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='624622d4-ce11-4fa3-9f0b-89c47559d1c6' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nikki Torres already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='624622d4-ce11-4fa3-9f0b-89c47559d1c6' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nikki Torres already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c4e1312c-e746-483e-a3ec-f27bc40b6d26' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Paul Harris already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c4e1312c-e746-483e-a3ec-f27bc40b6d26' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Paul Harris already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Perry Dozier already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Perry Dozier already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d3fad6d8-8022-4c66-b505-4e7a8fc816d7' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Phil Fortunato already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d3fad6d8-8022-4c66-b505-4e7a8fc816d7' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Phil Fortunato already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=5 AND text ILIKE '%real consequences%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: chair 5 is no longer the consequences chair — re-read before seating'; END IF;
  -- migration 1780's chair-3 rows must still be there; this migration is the other end of the same ladder
  SELECT count(*) INTO n FROM inform.politician_answers WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=3;
  IF n < 12 THEN RAISE EXCEPTION 'pre-check: expected at least the 12 chair-3 rows from migration 1780, found %', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('fec68f5f-c9e1-4579-869a-7b4a78f7da90','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('d0350f2f-6463-452e-b97d-c18ea094e2ee','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('6cc4c706-fa7a-486f-ac67-6cbdede4a607','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Prime sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('3db3f064-dd6e-4bca-9200-3d4395972253','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('624622d4-ce11-4fa3-9f0b-89c47559d1c6','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('c4e1312c-e746-483e-a3ec-f27bc40b6d26','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 5566, which would make assault in the third degree a class B felony instead of a class C felony when the victim is a law enforcement officer or when a peace officer is assaulted with a projectile stun gun, move that offence up the sentencing grid, and impose a mandatory minimum term on anyone convicted of assaulting an officer "in furtherance of a riot or unlawful assembly". The act contains no findings and no intent section, and it carries no treatment, diversion or restitution provision of any kind.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('fec68f5f-c9e1-4579-869a-7b4a78f7da90','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('d0350f2f-6463-452e-b97d-c18ea094e2ee','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('aadf55f0-a4b4-4a4a-acf0-bfce06815149','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('6cc4c706-fa7a-486f-ac67-6cbdede4a607','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('f3cd74bb-3bdb-4d55-a07d-5c14bda50926','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('3db3f064-dd6e-4bca-9200-3d4395972253','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('0e935fed-534e-42b0-a5ad-74f4199ff6df','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('624622d4-ce11-4fa3-9f0b-89c47559d1c6','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('c4e1312c-e746-483e-a3ec-f27bc40b6d26','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5),
('d3fad6d8-8022-4c66-b505-4e7a8fc816d7','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 5);

DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; c5 int; primes int;
BEGIN
  SELECT * INTO s FROM c5_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 12 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +12', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 12 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +12', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND a.politician_id IN ('fec68f5f-c9e1-4579-869a-7b4a78f7da90','d0350f2f-6463-452e-b97d-c18ea094e2ee','aadf55f0-a4b4-4a4a-acf0-bfce06815149','6cc4c706-fa7a-486f-ac67-6cbdede4a607','f3cd74bb-3bdb-4d55-a07d-5c14bda50926','3db3f064-dd6e-4bca-9200-3d4395972253','0e935fed-534e-42b0-a5ad-74f4199ff6df','7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','624622d4-ce11-4fa3-9f0b-89c47559d1c6','c4e1312c-e746-483e-a3ec-f27bc40b6d26','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','d3fad6d8-8022-4c66-b505-4e7a8fc816d7')
     AND (a.value <> 5
          OR c.reasoning !~ 'no findings and no intent section'
          OR c.reasoning !~ 'mandatory minimum'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5566.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % row(s) wrong chair, missing the structural reasoning, or missing SB 5566', bad; END IF;

  SELECT count(*) INTO c5 FROM inform.politician_answers
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=5 AND politician_id IN ('fec68f5f-c9e1-4579-869a-7b4a78f7da90','d0350f2f-6463-452e-b97d-c18ea094e2ee','aadf55f0-a4b4-4a4a-acf0-bfce06815149','6cc4c706-fa7a-486f-ac67-6cbdede4a607','f3cd74bb-3bdb-4d55-a07d-5c14bda50926','3db3f064-dd6e-4bca-9200-3d4395972253','0e935fed-534e-42b0-a5ad-74f4199ff6df','7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','624622d4-ce11-4fa3-9f0b-89c47559d1c6','c4e1312c-e746-483e-a3ec-f27bc40b6d26','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','d3fad6d8-8022-4c66-b505-4e7a8fc816d7');
  IF c5 <> 12 THEN RAISE EXCEPTION 'guard 2: chair-5 count is %, expected 12', c5; END IF;

  SELECT count(*) INTO primes FROM inform.politician_context
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND politician_id IN ('fec68f5f-c9e1-4579-869a-7b4a78f7da90','d0350f2f-6463-452e-b97d-c18ea094e2ee','aadf55f0-a4b4-4a4a-acf0-bfce06815149','6cc4c706-fa7a-486f-ac67-6cbdede4a607','f3cd74bb-3bdb-4d55-a07d-5c14bda50926','3db3f064-dd6e-4bca-9200-3d4395972253','0e935fed-534e-42b0-a5ad-74f4199ff6df','7736eecd-7c77-4de7-b2e4-ba0bf1aac7ec','624622d4-ce11-4fa3-9f0b-89c47559d1c6','c4e1312c-e746-483e-a3ec-f27bc40b6d26','4be6f4b9-2c9d-4cff-b75a-cdb0c322c2b3','d3fad6d8-8022-4c66-b505-4e7a8fc816d7') AND reasoning LIKE 'Prime sponsor of %';
  IF primes <> 1 THEN RAISE EXCEPTION 'guard 2: % prime-sponsor row(s), expected 1', primes; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'judicial-criminal-justice: 12 at chair 5 from SB 5566; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
