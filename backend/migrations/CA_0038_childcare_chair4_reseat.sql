BEGIN;

-- =============================================================================
-- CA_0038: Childcare — option-4 re-seat (in-place), for the v2 split
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: re-audit the twelve option-4 axis-orphans against the v2 wording
--   ("Limiting government support to childcare subsidies for the lowest-income families,
--   relying on the private market for everyone else"), CA_0036 having parked v2 and
--   CA_0037 having pinned v2 into Season 2. Their prior chair-4 seatings rested on a
--   deregulation instrument, which the v2 wording drops. Primary-source re-audit
--   (2026-08-30):
--     5 MOVE to chair 3 (targeted subsidies / provider facility grants — primary bill found):
--         Erin Paré, Dean Arp, Donny Lambeth, Heather H. Rhyne — NC HB877 (2025),
--           "Childcare Pilot": $5,000,000 nonrecurring FY2025-26 for a public-private
--           childcare facility at 25%+ below market (primary sponsors, verified in the bill text).
--         Nancy Mace — H.R. 5581 (118th), Child Care Assistance for Maternal Health Act,
--           co-introduced with Rep. McClellan: targeted grants for short-term child care for
--           pregnant/postpartum families, prioritizing low-income/homeless/single-parent/disability.
--     7 BLANK (no primary childcare-subsidy source; only a deregulation instrument):
--         Aaron Márquez, Christie New Craig, Jake Johnson, Julie Jackson, Russell J. Black,
--         Tara A. Durant, Wren M. Williams.
--
-- WHY IN-PLACE (changes open Season 1): the schema cannot represent "seated in Season 1,
--   different/blank in Season 2" — politician_answers.value is CHECK 1..5 (no 0), and the compare
--   read collapses to the newest season with no status gate, so an absent/edited Season-2 row
--   falls back to / overrides the Season-1 seating. The edits therefore apply to the shared
--   (Season-1) rows. CA_0033 / CA_0035 style.
--     · The 5 MOVES are correct for BOTH seasons: chair 3 text is byte-identical in v1 and v2,
--       and each move rests on a primary facility-grant/targeted-subsidy bill that was always the
--       better placement — a re-audit improvement, not a season conflict.
--     · The 7 BLANKS are a deliberate call (Chris Andrews, 2026-08-30). Unlike CA_0035, childcare's
--       deregulation clause is on-topic and each blank had a primary v1 deregulation seating, so this
--       DOES remove correct-under-v1 seatings from open Season 1. Decision: treat deregulation as the
--       off-axis barrel of the split rung — the compass seats the funding/subsidy axis, and none of
--       these seven has a primary-source position on it, so a blank spoke is the honest answer for
--       both seasons. Primary sources were exhausted on 2026-08-30 (some campaign/legislature pages
--       were unreachable; re-source later if one surfaces).
--
-- Expected end state (childcare answers): 1=116, 2=496, 3=93, 4=73, 5=20 (was 116/496/88/85/20);
-- 7 answer rows removed; 5 moved 4->3.
-- Idempotent: every step no-ops on re-run.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id='c1ac1330-47f7-44ec-baf3-c913d926b97c' AND topic_key='childcare') THEN
    RAISE EXCEPTION 'CA_0038: childcare topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id='0e9fe0f2-cfab-4553-99cd-c3195d08e236' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c' AND version=2) THEN
    RAISE EXCEPTION 'CA_0038: v2 revision missing';
  END IF;
END $$;

-- ── 1. Moves: chair 4 -> chair 3 (targeted subsidies / provider facility grants) ──────────────
-- The four NC HB877 primary sponsors.
UPDATE inform.politician_answers SET value=3, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c' AND value=4
   AND politician_id IN (
     '91c8abbc-8c76-42f2-8607-47ee476a0a8e',  -- Erin Paré
     '17c741bd-42b9-4d9a-8cb0-c4d4505b5df1',  -- Dean Arp
     '45274204-828d-4292-8466-36f9681f99ec',  -- Donny Lambeth
     'c7a28684-7476-44a0-a446-9a77116be4b4'); -- Heather H. Rhyne

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Rep. Erin Paré is a primary sponsor of NC House Bill 877 (2025), the "Childcare Pilot," which appropriates $5,000,000 in nonrecurring FY2025-26 funds to establish a public-private-partnership childcare facility offering rates at least 25% below market. This is a targeted, non-universal provider/facility grant (priority placement for state and university employees, no family income means-test) rather than deregulation, matching the chair on targeted subsidies and provider facility grants.$r$,
  sources = ARRAY['https://www.ncleg.gov/BillLookUp/2025/H877','https://www.ncleg.gov/Sessions/2025/Bills/House/PDF/H877v1.pdf']::text[]
 WHERE politician_id='91c8abbc-8c76-42f2-8607-47ee476a0a8e' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Rep. Dean Arp is a primary sponsor of NC House Bill 877 (2025), the "Childcare Pilot," which appropriates $5,000,000 in nonrecurring FY2025-26 funds to establish a public-private-partnership childcare facility offering rates at least 25% below market — a targeted provider/facility grant, not deregulation, matching the chair on targeted subsidies and provider facility grants.$r$,
  sources = ARRAY['https://www.ncleg.gov/BillLookUp/2025/H877','https://www.ncleg.gov/Sessions/2025/Bills/House/PDF/H877v1.pdf']::text[]
 WHERE politician_id='17c741bd-42b9-4d9a-8cb0-c4d4505b5df1' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Rep. Donny Lambeth is a primary sponsor of NC House Bill 877 (2025), the "Childcare Pilot," which appropriates $5,000,000 in nonrecurring FY2025-26 funds to establish a public-private-partnership childcare facility offering rates at least 25% below market — a targeted provider/facility grant, not deregulation, matching the chair on targeted subsidies and provider facility grants.$r$,
  sources = ARRAY['https://www.ncleg.gov/BillLookUp/2025/H877','https://www.ncleg.gov/Sessions/2025/Bills/House/PDF/H877v1.pdf']::text[]
 WHERE politician_id='45274204-828d-4292-8466-36f9681f99ec' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Rep. Heather Rhyne is a primary sponsor of NC House Bill 877 (2025), the "Childcare Pilot," which appropriates $5,000,000 in nonrecurring FY2025-26 funds to establish a public-private-partnership childcare facility offering rates at least 25% below market — a targeted provider/facility grant, not deregulation, matching the chair on targeted subsidies and provider facility grants.$r$,
  sources = ARRAY['https://www.ncleg.gov/BillLookUp/2025/H877','https://www.ncleg.gov/Sessions/2025/Bills/House/PDF/H877v1.pdf']::text[]
 WHERE politician_id='c7a28684-7476-44a0-a446-9a77116be4b4' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';

-- Nancy Mace.
UPDATE inform.politician_answers SET value=3, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c' AND value=4
   AND politician_id='096ba968-82d5-46ce-86ab-4b387973978d';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Rep. Nancy Mace co-introduced H.R. 5581 (118th Congress), the Child Care Assistance for Maternal Health Act, with Rep. Jennifer McClellan — a bipartisan bill authorizing competitive federal grants for demonstration projects that give pregnant and postpartum families short-term child care access, prioritizing low-income families, families experiencing homelessness, single parents, and children with disabilities. This is a targeted, non-universal subsidy/grant, matching the chair on targeted subsidies and provider grants. (Her other childcare bill, H.R. 8983, only repeals a D.C. staff-credentialing rule — deregulation — and is not used here.)$r$,
  sources = ARRAY['https://www.congress.gov/bill/118th-congress/house-bill/5581','https://mcclellan.house.gov/media/press-releases/mcclellan-mace-introduce-bipartisan-legislation-improve-access-child-care-0']::text[]
 WHERE politician_id='096ba968-82d5-46ce-86ab-4b387973978d' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';

-- ── 2. Blanks: remove the seating, rewrite context as a documented blank ──────────────────────
CREATE TEMP TABLE cc_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO cc_blank(pid, tid) VALUES
  ('0df9cd85-3923-48bd-86c2-b7d4b31d510d','c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Aaron Márquez
  ('7b7540c8-f62f-4edd-a49a-19a3f883ebd8','c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Christie New Craig
  ('9e00a45b-30f4-4d84-a1fe-861e81eb30ea','c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Jake Johnson
  ('e79822a0-d968-4e00-b107-de54732134bf','c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Julie Jackson
  ('81db75c5-8c48-40f3-8cb1-7220def31e72','c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Russell J. Black
  ('70d45f9c-aef9-4cd7-be4c-5ae568e94f94','c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Tara A. Durant
  ('38cb6796-1539-48ac-92e6-00068aa5e339','c1ac1330-47f7-44ec-baf3-c913d926b97c'); -- Wren M. Williams

DELETE FROM inform.politician_answers a USING cc_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid;

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://www.azleg.gov/legtext/57leg/2R/bills/HB4024P.pdf']::text[],
  reasoning = $r$Researched 2026-08-30 — Aaron Márquez's only childcare instrument is HB4024 (2026), a licensing exemption for DoD/USCG-certified family childcare — deregulation, off this subsidy axis. Checked the Arizona Legislature member/bill pages (unavailable) and his campaign site (healthcare and schools; no childcare-subsidy content). A third-party scorecard is not an allowed primary source. No primary source places him on the childcare-subsidy spectrum; left blank.$r$
 WHERE politician_id='0df9cd85-3923-48bd-86c2-b7d4b31d510d' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=bil&val=SB170']::text[],
  reasoning = $r$Researched 2026-08-30 — Christie New Craig's only childcare instrument is SB170 (2025), a licensing exemption for out-of-school-time programs — deregulation, off this subsidy axis. Checked her campaign issues page (public safety, education, veterans, jobs; no childcare-subsidy content). No primary source places her on the childcare-subsidy spectrum; left blank.$r$
 WHERE politician_id='7b7540c8-f62f-4edd-a49a-19a3f883ebd8' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://jakejohnsonforcongress.com/priorities']::text[],
  reasoning = $r$Researched 2026-08-30 — Jake Johnson's only childcare statement is a pledge to "cut red tape" to expand childcare options — deregulation, off this subsidy axis. His stated priorities (costs/tariffs, corruption/term limits, rural investment) contain no childcare-subsidy or public-funding position. No primary source places him on the childcare-subsidy spectrum; left blank.$r$
 WHERE politician_id='9e00a45b-30f4-4d84-a1fe-861e81eb30ea' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://www.juliejacksonforutah.com/priorities']::text[],
  reasoning = $r$Researched 2026-08-30 — Julie Jackson's only childcare statement is "removing regulation from child care centers to make childcare more affordable" — pure deregulation, off this subsidy axis. Her campaign materials state no childcare-subsidy or public-funding position. No primary source places her on the childcare-subsidy spectrum; left blank.$r$
 WHERE politician_id='e79822a0-d968-4e00-b107-de54732134bf' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY[]::text[],
  reasoning = $r$Researched 2026-08-30 — Russell J. Black's only childcare position is a campaign proposal to loosen Maine's child-to-staff ratio regulations — deregulation, off this subsidy axis. His campaign site was unreachable and his official Maine Senate committee record shows no childcare-subsidy bill. No primary source places him on the childcare-subsidy spectrum; left blank.$r$
 WHERE politician_id='81db75c5-8c48-40f3-8cb1-7220def31e72' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB75']::text[],
  reasoning = $r$Researched 2026-08-30 — Tara A. Durant's only childcare instruments are SB75/SB76 (2024), licensure exemptions for military-affiliated and religious childcare — deregulation, off this subsidy axis. Her campaign site was inaccessible (password-protected) and no legislature record of a childcare-subsidy bill was retrievable. No primary source places her on the childcare-subsidy spectrum; left blank.$r$
 WHERE politician_id='70d45f9c-aef9-4cd7-be4c-5ae568e94f94' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://www.vpap.org/legislators/331499-wren-williams/legislation/']::text[],
  reasoning = $r$Researched 2026-08-30 — Wren M. Williams's only childcare instrument is HB744 (2026), a licensure exemption for light family day homes — deregulation, off this subsidy axis. Checked his campaign issues page (economy, education, healthcare, 2A, pro-life, elections, community; no childcare-subsidy content). No primary source places him on the childcare-subsidy spectrum; left blank.$r$
 WHERE politician_id='38cb6796-1539-48ac-92e6-00068aa5e339' AND topic_id='c1ac1330-47f7-44ec-baf3-c913d926b97c';

-- @context-decision: rewritten-as-blank — the childcare topic applies to each person and each record
-- WAS read against primary sources on 2026-08-30; each has only a deregulation instrument (off the
-- funding/subsidy axis) and no primary childcare-subsidy source, so each context is a documented blank
-- naming what was checked. No answer row remains for these pairs.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate on the blanked pairs (regexes identical).
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM cc_blank t
    JOIN inform.politician_context pc ON pc.politician_id=t.pid AND pc.topic_id=t.tid
   WHERE coalesce(cardinality(pc.sources),0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'CA_0038 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 3. Post-verify ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE tid uuid := 'c1ac1330-47f7-44ec-baf3-c913d926b97c'; c1 int;c2 int;c3 int;c4 int;c5 int; miss int; mv int;
BEGIN
  -- 5 movers now at chair 3
  SELECT count(*) INTO mv FROM inform.politician_answers
   WHERE topic_id=tid AND value=3 AND politician_id IN (
     '91c8abbc-8c76-42f2-8607-47ee476a0a8e','17c741bd-42b9-4d9a-8cb0-c4d4505b5df1',
     '45274204-828d-4292-8466-36f9681f99ec','c7a28684-7476-44a0-a446-9a77116be4b4',
     '096ba968-82d5-46ce-86ab-4b387973978d');
  IF mv <> 5 THEN RAISE EXCEPTION 'verify: % of 5 movers at chair 3 (expected 5)', mv; END IF;
  -- 7 blanks have no answer row
  SELECT count(*) INTO miss FROM cc_blank b JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF miss <> 0 THEN RAISE EXCEPTION 'verify: % blanked pair(s) still have an answer row', miss; END IF;
  -- distribution
  SELECT count(*) FILTER (WHERE value=1),count(*) FILTER (WHERE value=2),count(*) FILTER (WHERE value=3),count(*) FILTER (WHERE value=4),count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid;
  IF (c1,c2,c3,c4,c5) <> (116,496,93,73,20) THEN
    RAISE EXCEPTION 'verify: chair counts %/%/%/%/% (expected 116/496/93/73/20)', c1,c2,c3,c4,c5;
  END IF;
  RAISE NOTICE 'CA_0038 post-verify OK: 1=%/2=%/3=%/4=%/5=%; 5 moved 4->3, 7 blanked', c1,c2,c3,c4,c5;
END $$;

COMMIT;
