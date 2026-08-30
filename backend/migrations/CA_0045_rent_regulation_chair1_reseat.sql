BEGIN;

-- =============================================================================
-- CA_0045: Rent Regulation — chair-1 re-seat (in-place), for the v2 de-barrel
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: re-audit the 36 rows seated on rent-regulation chair 1 against the v2
--   wording. The rev-2 draft (id 6836f9f4-79e4-4d94-ad36-d195f5d2e7a2) de-barrels
--   the old chair 1 —
--     v1: "Expand rent control to all rental units with strong tenant protections
--          and just-cause eviction requirements"  (three welded positions)
--     v2: "Expand rent control to cover all rental units communitywide"
--   — sharpening chair 1 to the MAXIMAL/universal position only. Chair 2
--   ("Strengthen existing rent stabilization and extend coverage to more units")
--   is the incremental position. A stabilization instrument (an RSO cap, an
--   AB 1482-style statewide cap with new-construction/single-family exemptions, an
--   MA "Rent Stabilization Act" / "lift the ban" local-option bill) proves the pro
--   DIRECTION and the stabilization MAGNITUDE — chair 2, not chair 1. The old broad
--   chair 1 was absorbing the entire stabilization cohort.
--
--   Primary-source re-audit (2026-08-30), full per-row rationale + sources in
--   data/season2-carry/rent-regulation-chair1-reaudit.json:
--     7 KEEP at chair 1 (universal / repeal-Costa-Hawkins / broad municipal RC regime):
--         Caroline Torosis, John Heilman, Yasmine-Imani McMorrin, Julia M. Mejia,
--         Konstantine Anthony (first pass); Rae Chen Huang, Jackie Fielder (re-sourced).
--     26 MOVE to chair 2 (stabilization / local-option / strengthen-existing / extend-to-more):
--         the 13 MA "lift-the-ban" legislators, David Chiu (AB 1482), Hugo Soto-Martinez,
--         John Erickson, Eunisses Hernandez, Lauren Meister, Lindsey Horvath, Ayanna Pressley,
--         Hilda Solis, Cindy Allen, Mary Washington, Suely Saro (first pass); plus
--         Connie Chan (SF File 220636) and Shamann Walton (SF File 240822) (re-sourced).
--     3 BLANK (no qualifying primary rent-control instrument; re-sourced 2026-08-30):
--         Dan Hall, Shelly Hettleman, Ellen Zhang.
--
--   Of the 7 first-pass blanks, a primary-source re-source pass rescued 4 (Huang, Fielder
--   -> chair 1; Chan, Walton -> chair 2) and confirmed 3 as blank. The 4 rescued rows and
--   the 2 re-sourced movers get their context reasoning rewritten to the new primary
--   instrument (their prior reasoning cited eviction/tenant-organizing work that does not
--   support the assigned chair). The other 24 movers keep their existing reasoning, which
--   already names a stabilization instrument that supports chair 2. The 5 first-pass keeps
--   are left untouched.
--
-- WHY IN-PLACE (changes open Season 1): the schema cannot represent "seated in Season 1,
--   different/blank in Season 2" — politician_answers.value is CHECK 1..5 (no 0), and the
--   compare read collapses to the newest season with no status gate, so an absent/edited
--   Season-2 row would fall back to / override the Season-1 seating. The edits therefore
--   apply to the shared (Season-1 / rev-1) rows — all 36 are stamped Season 1, rev 1.
--   A wrong chair is wrong in the open season too, so the corrections are right for BOTH
--   seasons and the corrected chairs carry into Season 2 when it opens with rev 2 pinned.
--   CA_0033 / CA_0035 / CA_0038 style. (Pinning rev 2 into Season 2 is a SEPARATE later
--   migration; this one only fixes the seatings.)
--
-- Expected end state (rent-regulation answers): 1=7, 2=167, 3=24, 4=29, 5=10
--   (was 36/141/24/29/10); 3 answer rows removed; 26 moved 1->2.
-- Idempotent: every step no-ops on re-run.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND topic_key='rent-regulation') THEN
    RAISE EXCEPTION 'CA_0045: rent-regulation topic id mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topic_revisions WHERE id='6836f9f4-79e4-4d94-ad36-d195f5d2e7a2' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND revision=2) THEN
    RAISE EXCEPTION 'CA_0045: v2 revision missing';
  END IF;
END $$;

-- ── 1. Moves: chair 1 -> chair 2 (stabilization / extend-to-more-units) ───────────────────────
-- The 24 first-pass movers keep their existing stabilization reasoning (already chair-2 correct).
UPDATE inform.politician_answers SET value=2, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND value=1
   AND politician_id IN (
     'c61baf45-dc2a-4d78-b4b7-21b1e9d79464',  -- Ayanna Pressley
     '7cbdb829-4836-49e9-afb2-cb8035afc6bf',  -- Christine P. Barber
     'fd3bf15c-265b-46a9-aa72-c9097749d762',  -- Chynah Tyler
     'a6893dff-7151-4dd2-8b5f-fb9124ee3c96',  -- Cindy Allen
     '5c36a94c-9006-4550-a37e-978a65d2725c',  -- Daniel J. Hunt
     '86c12b33-cb76-41da-bdf0-6b58a0cbbed6',  -- David Chiu
     '98291d86-d42d-49d0-a5b2-d689a8154b15',  -- Erika Uyterhoeven
     '317698c6-2ae7-4f7f-ab39-bb3811ed50f3',  -- Eunisses Hernandez
     'f1f3e6ca-5532-4f33-8ec2-64791b08f59b',  -- Hilda L. Solis
     '6c795b3b-d59d-4667-b79e-8a2e27e0c283',  -- Hugo Soto-Martinez
     '29ccd743-6e37-42ec-8999-f1316fff3270',  -- John Erickson
     'c4c3ed02-2592-4505-a26c-0195d0b5314e',  -- Judith A. Garcia
     '5b6291a0-b5ab-4f27-a318-d309c726d8e6',  -- Lauren Meister
     '81dfcf88-c739-4461-9d16-931f8d51a8c5',  -- Lindsey P. Horvath
     '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',  -- Liz Miranda
     '11d73e67-bcd9-419a-8b0d-a26447eb0c0b',  -- Lydia M. Edwards
     '2b1a645a-72ce-4c0f-80ec-17565a2d6d10',  -- Marjorie C. Decker
     '38404814-7be0-40e3-b044-062f98b2a5b0',  -- Mary Washington
     '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',  -- Mike Connolly
     'c14b3502-f142-4c1f-bfa9-a8fa52351a8e',  -- Natalie Higgins
     'd40a0eda-36fc-4032-8382-20c76a36d6a6',  -- Patricia D. Jehlen
     'e96b35eb-dad1-4a29-b416-d9b10838840f',  -- Russell E. Holmes
     '28a703f8-8316-4d3c-bfc0-3dcd77eab96c',  -- Samantha Montaño
     'b13891ed-faa2-481b-b773-7d0f0c2f6bbf'); -- Suely Saro

-- The 2 re-sourced movers (also 1->2), with context rewritten to the new primary instrument.
UPDATE inform.politician_answers SET value=2, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2' AND value=1
   AND politician_id IN (
     'f3f21e38-d8e6-41d2-9d74-0360a5f679b9',  -- Connie Chan
     'eab7b830-c831-45f9-bca8-11b079f42680'); -- Shamann Walton

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Supervisor Connie Chan is a co-sponsor of San Francisco Board of Supervisors File 220636 (2022), a charter amendment (with Aaron Peskin) requiring developers who exceed new density and height limits to place rent control on all residential units in those projects — extending rent-control coverage to units otherwise exempt under Costa-Hawkins. This is a conditional, incentive-based expansion to more units, matching the chair on strengthening existing rent stabilization and extending coverage to more units, rather than a universal cap on all rental units.$r$,
  sources = ARRAY['https://sfgov.legistar.com/View.ashx?M=F&ID=10932716&GUID=B847E6F5-B071-4CC2-8C0A-5BE98EDA82B7']::text[]
 WHERE politician_id='f3f21e38-d8e6-41d2-9d74-0360a5f679b9' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Supervisor Shamann Walton voted for San Francisco Board of Supervisors File 240822 (Peskin, October 2024), which moved the city's rent-control eligibility cutoff from 1979 to 1994, extending rent stabilization to roughly 16,000 additional units (contingent on state Proposition 33 repealing Costa-Hawkins). The board passed it unanimously, having scaled it back from an all-buildings proposal to the 1994 cutoff — an extension of existing rent stabilization to more units, matching the chair on strengthening rent stabilization and extending coverage, not a universal cap on all rental units.$r$,
  sources = ARRAY['https://sfstandard.com/2024/10/09/new-law-would-expand-san-francisco-rent-control-but-theres-a-big-catch/']::text[]
 WHERE politician_id='eab7b830-c831-45f9-bca8-11b079f42680' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';

-- ── 2. Keeps at chair 1 with rewritten context (the 2 re-sourced rescues) ─────────────────────
-- Value already 1; only the reasoning/sources are corrected to the Costa-Hawkins instrument.
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$On her own Los Angeles mayoral campaign housing platform, Rae Chen Huang states she "will use her influence as Los Angeles Mayor to push for the repeal of Costa Hawkins," framing it as unfreezing rent stabilization so it can reach units built after 1978 that current law exempts. Advocating repeal of the state Costa-Hawkins Act to extend rent control to all units, including new construction, is the maximal position — the chair on expanding rent control to cover all rental units communitywide.$r$,
  sources = ARRAY['https://www.raeforla.com/housing-for-all/']::text[]
 WHERE politician_id='17db34eb-dd9e-45b7-b877-14b393bb695e' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning = $r$Jackie Fielder's formally introduced 2020 State Senate housing platform called for repealing the state Costa-Hawkins Rental Housing Act and enacting "universal rent control" — rent control on all rental units including new construction — a position reported consistently across contemporaneous coverage of her campaign. Championing Costa-Hawkins repeal and universal coverage is the maximal position: the chair on expanding rent control to cover all rental units communitywide. (Her original 2020 campaign site is no longer reachable; this rests on contemporaneous reporting of the introduced plan.)$r$,
  sources = ARRAY['https://missionlocal.org/2020/01/state-sen-candidate-jackie-fielder-introduces-housing-plan-says-sb-50-is-on-its-last-legs/']::text[]
 WHERE politician_id='02f88a57-ccf5-4fe1-a693-7fc949321fb1' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';

-- ── 3. Blanks: remove the seating, rewrite context as a documented blank ──────────────────────
CREATE TEMP TABLE rr_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO rr_blank(pid, tid) VALUES
  ('dd36f867-372c-4444-ba9a-39c46ce4c510','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Dan Hall
  ('3089c813-f0a8-46af-9a7b-1699129037e9','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'),  -- Shelly Hettleman
  ('9ba2fd8c-7c37-474b-b05c-41ce75d00ca8','c308e8e8-caac-44f5-ab04-dbfecf40bbe2'); -- Ellen Zhang

DELETE FROM inform.politician_answers a USING rr_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid;

UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://electdanhall.com/priorities/']::text[],
  reasoning = $r$Researched 2026-08-30 — Dan Hall (Santa Monica City Council) states on his own site only that he will "fight for the strongest renter protections" — an aspiration with no rent-control instrument or magnitude. His one recorded housing act is a 6-0 eviction-protection vote (tenant protection, not rent control), and a news-reported line about organizing against threats to Santa Monica's rent-control law is defensive activism, not a sponsored ordinance or recorded rent-control vote. No primary source places him on the rent-control spectrum (expand-to-all-units vs strengthen-existing-stabilization); left blank.$r$
 WHERE politician_id='dd36f867-372c-4444-ba9a-39c46ce4c510' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/SB0481?ys=2024RS']::text[],
  reasoning = $r$Researched 2026-08-30 — Sen. Shelly Hettleman (Maryland) co-sponsored the "Renters' Rights and Stabilization Act of 2024" (SB0481), which despite its title imposes no rent cap or stabilization program (eviction-filing surcharges, a one-month deposit limit, rental-assistance voucher priority). No Maryland bill she sponsored caps rent — Maryland's rent caps are county-level, not her legislation — and no rent-control magnitude statement appears on her own site. No primary source places her on the rent-control spectrum; left blank.$r$
 WHERE politician_id='3089c813-f0a8-46af-9a7b-1699129037e9' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources = ARRAY['https://ellenfordistrict8.com/platform']::text[],
  reasoning = $r$Researched 2026-08-30 — Ellen Zhang (Madison, WI Common Council, District 8) lists "rent control" only as one bare bullet in a borrowed Tenant Bill of Rights, with no magnitude; her actual housing plan is supply-side, and Wisconsin bans local rent control. A bare "rent control" mention cannot distinguish expanding to all units (chair 1) from strengthening existing stabilization (chair 2); left blank.$r$
 WHERE politician_id='9ba2fd8c-7c37-474b-b05c-41ce75d00ca8' AND topic_id='c308e8e8-caac-44f5-ab04-dbfecf40bbe2';

-- @context-decision: rewritten-as-blank — the rent-regulation topic applies to each of the three
-- and each record WAS read against primary sources on 2026-08-30; none has a qualifying primary
-- rent-control instrument (only aspiration / eviction / affordable-housing / a bare platform bullet),
-- so each context is a documented blank naming what was checked. No answer row remains for these pairs.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate on the blanked pairs (regexes identical).
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM rr_blank t
    JOIN inform.politician_context pc ON pc.politician_id=t.pid AND pc.topic_id=t.tid
   WHERE coalesce(cardinality(pc.sources),0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION 'CA_0045 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- ── 4. Post-verify ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE tid uuid := 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'; c1 int;c2 int;c3 int;c4 int;c5 int; miss int; mv int; kept1 int;
BEGIN
  -- 26 movers now at chair 2
  SELECT count(*) INTO mv FROM inform.politician_answers
   WHERE topic_id=tid AND value=2 AND politician_id IN (
     'c61baf45-dc2a-4d78-b4b7-21b1e9d79464','7cbdb829-4836-49e9-afb2-cb8035afc6bf',
     'fd3bf15c-265b-46a9-aa72-c9097749d762','a6893dff-7151-4dd2-8b5f-fb9124ee3c96',
     '5c36a94c-9006-4550-a37e-978a65d2725c','86c12b33-cb76-41da-bdf0-6b58a0cbbed6',
     '98291d86-d42d-49d0-a5b2-d689a8154b15','317698c6-2ae7-4f7f-ab39-bb3811ed50f3',
     'f1f3e6ca-5532-4f33-8ec2-64791b08f59b','6c795b3b-d59d-4667-b79e-8a2e27e0c283',
     '29ccd743-6e37-42ec-8999-f1316fff3270','c4c3ed02-2592-4505-a26c-0195d0b5314e',
     '5b6291a0-b5ab-4f27-a318-d309c726d8e6','81dfcf88-c739-4461-9d16-931f8d51a8c5',
     '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe','11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
     '2b1a645a-72ce-4c0f-80ec-17565a2d6d10','38404814-7be0-40e3-b044-062f98b2a5b0',
     '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92','c14b3502-f142-4c1f-bfa9-a8fa52351a8e',
     'd40a0eda-36fc-4032-8382-20c76a36d6a6','e96b35eb-dad1-4a29-b416-d9b10838840f',
     '28a703f8-8316-4d3c-bfc0-3dcd77eab96c','b13891ed-faa2-481b-b773-7d0f0c2f6bbf',
     'f3f21e38-d8e6-41d2-9d74-0360a5f679b9','eab7b830-c831-45f9-bca8-11b079f42680');
  IF mv <> 26 THEN RAISE EXCEPTION 'verify: % of 26 movers at chair 2 (expected 26)', mv; END IF;
  -- 7 keeps still at chair 1
  SELECT count(*) INTO kept1 FROM inform.politician_answers
   WHERE topic_id=tid AND value=1 AND politician_id IN (
     '0314141a-3444-4382-a9ae-84394bbd486f','ea0b6144-fea3-47a1-878b-8cee956a4c79',
     '1408cd55-dccb-40fa-9296-049af125ec6f','cd9d9fd5-c20f-4b57-9065-f52516adca84',
     '6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7','17db34eb-dd9e-45b7-b877-14b393bb695e',
     '02f88a57-ccf5-4fe1-a693-7fc949321fb1');
  IF kept1 <> 7 THEN RAISE EXCEPTION 'verify: % of 7 keeps at chair 1 (expected 7)', kept1; END IF;
  -- 3 blanks have no answer row
  SELECT count(*) INTO miss FROM rr_blank b JOIN inform.politician_answers a ON a.politician_id=b.pid AND a.topic_id=b.tid;
  IF miss <> 0 THEN RAISE EXCEPTION 'verify: % blanked pair(s) still have an answer row', miss; END IF;
  -- distribution
  SELECT count(*) FILTER (WHERE value=1),count(*) FILTER (WHERE value=2),count(*) FILTER (WHERE value=3),count(*) FILTER (WHERE value=4),count(*) FILTER (WHERE value=5)
    INTO c1,c2,c3,c4,c5 FROM inform.politician_answers WHERE topic_id=tid;
  IF (c1,c2,c3,c4,c5) <> (7,167,24,29,10) THEN
    RAISE EXCEPTION 'verify: chair counts %/%/%/%/% (expected 7/167/24/29/10)', c1,c2,c3,c4,c5;
  END IF;
  RAISE NOTICE 'CA_0045 post-verify OK: 1=%/2=%/3=%/4=%/5=%; 26 moved 1->2, 3 blanked', c1,c2,c3,c4,c5;
END $$;

COMMIT;
