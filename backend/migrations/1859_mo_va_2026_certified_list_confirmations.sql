-- 1859_mo_va_2026_certified_list_confirmations.sql
--
-- Phase 167 (post-primary reconciliation), cluster 6 of 17: the MISSOURI and VIRGINIA rows that
-- migrations 1578 and 1575 deliberately refused to retire on 2026-08-07, extending their
-- provisional window to 2026-09-01 "pending the official November candidate list". Both lists
-- now exist and were read first-hand. This closes them.
--
-- 18 rows: 17 retired, 1 confirmed and kept.
--
-- ============================================================================
-- MISSOURI — the certification exists, and it is conclusive
-- ============================================================================
--   "Certification of Candidates and Party Emblems", certified by Denny Hoskins, CPA,
--   Secretary of State, dated August 25, 2026
--   www.sos.mo.gov/CMSImages/ElectionCandidates/2026GeneralElectionCertifiedCandidates.pdf
--   (linked from s1.sos.mo.gov/elections/candidatesonballot/ as "Certified Candidates -
--   November 2026"; Content-Type application/pdf, 813,890 bytes; fetched 2026-09-11)
--
-- 🔴 ITS SCOPE IS WHAT MAKES ABSENCE MEANINGFUL, AND IT SAYS SO ITSELF. Under §115.401 the
-- Secretary certifies "the persons named hereinafter ... were duly and lawfully nominated as
-- candidates of the above-named parties AND INDEPENDENT CANDIDATES for the offices herein
-- named to be filled at the general election to be held November 3, 2026." It enumerates
-- Republican, Democratic and Libertarian candidates, and it enumerates independents by name —
-- there are exactly two, both for State Representative (District 127 Racheal Martin, District
-- 128 Shane Sawyer). This matters because 1578 correctly noted that Missouri minor parties
-- nominate BY CONVENTION, so absence from the August primary results carried no information.
-- Absence from THIS document does carry information: it is the list of who is on the ballot.
--
-- The certified U.S. Representative field, all 24 names, is:
--   REP  D1 Paul Berry III · D2 Ann Wagner · D3 Bob Onder · D4 Mark Alford ·
--        D5 Rick Brattin · D6 Chris Stigall · D7 Eric W. Burlison · D8 Jason T. Smith
--   DEM  D1 Wesley Bell · D2 Fred Wellman · D3 Bethany Emann · D4 Jordan Herrera ·
--        D5 Emanuel Cleaver II · D6 Josh Smead · D7 Missi Hesketh · D8 Chris Reichard
--   LIB  D1 Tom Schmitz · D2 Brandon Coulter Daugherty · D3 Jim Higgins · D4 Thomas Holbrook ·
--        D5 Randall "Randy" Langkraehr · D6 Andy Maidment · D7 Kevin Craig ·
--        D8 Rebecca Sharpe Lombard
--
-- NONE of our 16 provisional Missouri rows appears anywhere in it. The document was proven to
-- have been read in full before absence was trusted: the extraction was checked against names
-- that MUST be present (Wagner, Alford, Burlison, Cleaver, Onder, Hoskins) and all were found.
--
-- ============================================================================
-- VIRGINIA — one retired, one confirmed, read from the raw page rather than a summary
-- ============================================================================
--   "2026 November Federal Offices Candidate List", revision 9-8-2026, Virginia Department of
--   Elections — elections.virginia.gov/casting-a-ballot/candidate-list/
--   november-3-2026-gen-elect-federal-offices/ (fetched 2026-09-11). The page states: "If an
--   office had no candidates qualify for ballot access, the office will not be included in the
--   above candidate lists."
--
--   ANDRE KERSEY (VA-04): the string "Kersey" occurs ZERO times in the page. The 4th District
--   block lists exactly three: Jennifer L. McClellan (Democratic), Robert P. "Family Man"
--   Murray, Jr. (Republican), Joan E. "Andrews" Bell (Independent). RETIRED.
--
--   RANDALL TERRY (VA-07): PRESENT, verbatim — "Member, House of Representatives / 7th
--   District / Independent / Randall A. Terry / No / randallterryprolife@gmail.com /
--   www.terry.vote / 904-687-9806 / 4752 Oak Rd / Barlett / TN / 38002". CONFIRMED and kept.
--
-- 🔴 A summarising fetch first reported both of these, and its answers happened to be right.
-- They were re-read from the raw HTML anyway, and control names (Vindman, Ollivant, McClellan)
-- were checked to prove the document had loaded. A retirement decided by a model's summary of
-- a page is not a retirement decided by the page.
--
-- ============================================================================
-- ⚠ WHAT THIS CLUSTER FOUND THAT IT DOES NOT FIX — AND IT IS BIGGER THAN THE CLUSTER
-- ============================================================================
-- Virginia's certified list disagrees with our field in BOTH directions, and most of the
-- disagreement is in rows that are NOT provisional and therefore were never in this phase's
-- scope at all:
--
--   VA-04  certified: McClellan, Murray (R), Bell (I)
--          ours:      McClellan, Kersey (retired here), Jason Brown II
--          -> MISSING the Republican nominee Robert P. "Family Man" Murray, Jr. and the
--             independent Joan E. "Andrews" Bell. "Brown" occurs zero times on the page.
--   VA-07  certified: Vindman, Ollivant, Demirci Lopez (Lib), Ahrar (I), Ertle (I), Terry (I)
--          ours:      Vindman, Ollivant, Terry, Philip Harding, Ricky Smithers
--          -> MISSING Taner E. Demirci Lopez, Alaha Ahrar, Joshua E. Ertle. "Harding" and
--             "Smithers" each occur zero times on the page.
--
-- Jason Brown II, Philip Harding and Ricky Smithers are NOT touched here. They carry no
-- provisional flag, so they were seeded on a different basis with a different rationale — most
-- likely FEC filers — and retiring them belongs to whoever owns that basis, not to a
-- post-primary reconciliation. Filed:
--   .planning/todos/2026-09-11-va-cd4-cd7-field-disagrees-with-certified-list.md
--
-- VA-07 therefore KEEPS a flag (on Terry's row) because the race is known incomplete. VA-04
-- ends with no flagged row at all — the same structural gap 1858 hit on Deschutes Treasurer:
-- the flag lives on candidate rows, so an incomplete race whose only provisional row was
-- retired has no way to say so.
--
-- Nothing is hard-deleted and no politician row is deactivated.
-- Idempotent: every UPDATE is guarded on the value it is about to write.

BEGIN;

CREATE TEMP TABLE cert_target (
  election_id uuid NOT NULL,
  our_name    text NOT NULL,
  disposition text NOT NULL CHECK (disposition IN ('not_nominated','confirmed')),
  keep_flag   boolean NOT NULL,
  src         text NOT NULL
) ON COMMIT DROP;

-- ── Missouri: 16 rows, none on the certified list ───────────────────────────────────────────
-- ⚠ THEY ARE SPLIT ACROSS TWO ELECTION RECORDS, which is how this migration found the split:
-- the first draft matched 17 of 18 names and the post-verify refused to proceed. 15 sit on
-- "MO 2026 Congressional Redistricting - Polygon Pending" (2026-03-24) and 1, Clayton Harbison
-- in District 8, sits on "MO 2026 Statewide General" (2026-11-03). See the todo — 46 Missouri
-- candidate rows in total hang off that March-dated redistricting placeholder rather than off
-- the November general, and that is not this migration's to fix.
INSERT INTO cert_target (election_id, our_name, disposition, keep_flag, src)
SELECT '8e4e030d-2e4b-46d0-beea-2138b706513f'::uuid, n, 'not_nominated', false,
  'Absent from the Missouri Secretary of State''s "Certification of Candidates and Party '
  || 'Emblems" for the general election of November 3, 2026, certified by Denny Hoskins, CPA '
  || 'under RSMo 115.401 and dated August 25, 2026 '
  || '(www.sos.mo.gov/CMSImages/ElectionCandidates/2026GeneralElectionCertifiedCandidates.pdf, '
  || 'linked from s1.sos.mo.gov/elections/candidatesonballot/ as "Certified Candidates - '
  || 'November 2026"; fetched 2026-09-11). That certification covers Republican, Democratic '
  || 'and Libertarian candidates AND independent candidates, which it enumerates by name, so '
  || 'absence from it is dispositive rather than merely uninformative — the point migration '
  || '1578 was waiting on, since Missouri minor parties nominate by convention and so are '
  || 'invisible in August primary results. Its certified U.S. Representative field is 24 names '
  || 'across the three parties and includes none of ours.'
FROM unnest(ARRAY['Chuck Summers','Nick Vivio','Ryan Sheridan','Mike Conner','Ashleigh Rogers',
                  'G Rick','Hartzell Gray','Jeanette Cass','Randy Miller','Wayne Russell',
                  'Berton A. Knox','Brad Patty','Brett Hueffmeier','Micah Beebe',
                  'Taylor Burks']) AS n;

-- Clayton Harbison (District 8), same certification, different election record.
INSERT INTO cert_target (election_id, our_name, disposition, keep_flag, src)
SELECT '25941a7b-a488-4289-9d8a-3e9ca3d275ad'::uuid, 'Clayton Harbison', 'not_nominated', false, src
  FROM cert_target WHERE our_name = 'Chuck Summers';

-- ── Virginia: one retired, one confirmed ────────────────────────────────────────────────────
INSERT INTO cert_target (election_id, our_name, disposition, keep_flag, src) VALUES
  ('a820319c-d64f-4f6b-b173-2fcc06fab95b'::uuid, 'Andre Kersey', 'not_nominated', false,
   'Absent from the Virginia Department of Elections "2026 November Federal Offices Candidate '
   || 'List", revision 9-8-2026 (elections.virginia.gov/casting-a-ballot/candidate-list/'
   || 'november-3-2026-gen-elect-federal-offices/, fetched 2026-09-11 and read from the raw '
   || 'page). The string "Kersey" occurs zero times in it. Its 4th District block lists exactly '
   || 'three candidates: Jennifer L. McClellan (Democratic), Robert P. "Family Man" Murray, Jr. '
   || '(Republican) and Joan E. "Andrews" Bell (Independent). The page states "If an office had '
   || 'no candidates qualify for ballot access, the office will not be included in the above '
   || 'candidate lists", so the office being listed means its field is the field. This is the '
   || 'official list migration 1575 extended his provisional window to wait for.'),
  ('a820319c-d64f-4f6b-b173-2fcc06fab95b'::uuid, 'Randall Terry', 'confirmed', true,
   'CONFIRMED on the ballot. Virginia Department of Elections "2026 November Federal Offices '
   || 'Candidate List", revision 9-8-2026 (fetched 2026-09-11, read from the raw page), lists '
   || 'verbatim: "Member, House of Representatives / 7th District / Independent / Randall A. '
   || 'Terry / No / randallterryprolife@gmail.com / www.terry.vote / 904-687-9806 / 4752 Oak Rd '
   || '/ Barlett / TN / 38002". He ran in no primary, so no primary outcome is recorded. His '
   || 'row keeps provisional_until because VA-07 is known incomplete: the certified field also '
   || 'holds Taner E. Demirci Lopez (Libertarian), Alaha Ahrar (Independent) and Joshua E. '
   || 'Ertle (Independent), none of whom are in our data.');

CREATE TEMP TABLE cert_resolved AS
SELECT rc.id AS rc_id, t.disposition, t.keep_flag, t.src
  FROM cert_target t
  JOIN essentials.races r ON r.election_id = t.election_id
  JOIN essentials.race_candidates rc
    ON rc.race_id = r.id AND rc.full_name = t.our_name AND rc.provisional_until IS NOT NULL;

DO $$
DECLARE n_t int; n_m int;
BEGIN
  SELECT count(*) INTO n_t FROM cert_target;
  SELECT count(*) INTO n_m FROM cert_resolved;
  IF n_t <> 18 THEN RAISE EXCEPTION 'target holds % rows, expected 18', n_t; END IF;
  IF n_m <> n_t THEN RAISE EXCEPTION 'only % of % names matched a provisional row', n_m, n_t; END IF;
END $$;

-- ── 1. the 17 retirements ───────────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET result = 'not_nominated',
       result_source = t.src,
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = NULL,
       updated_at = now()
  FROM cert_resolved t
 WHERE rc.id = t.rc_id
   AND t.disposition = 'not_nominated'
   AND (rc.result IS DISTINCT FROM 'not_nominated'
        OR rc.result_source IS DISTINCT FROM t.src
        OR rc.provisional_until IS NOT NULL);

-- ── 2. Randall Terry: confirmed, kept, and his race stays flagged ───────────────────────────
UPDATE essentials.race_candidates rc
   SET result_source = t.src,
       last_verified_at = now(),
       provisional_until = DATE '2026-09-18',
       updated_at = now()
  FROM cert_resolved t
 WHERE rc.id = t.rc_id
   AND t.disposition = 'confirmed'
   AND (rc.provisional_until IS DISTINCT FROM DATE '2026-09-18' OR rc.last_verified_at IS NULL);

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_mo_live int; n_va_kersey int; n_terry int; n_stale int; n_ret int;
BEGIN
  SELECT count(*) INTO n_ret
    FROM essentials.race_candidates rc JOIN cert_resolved t ON t.rc_id = rc.id
   WHERE t.disposition = 'not_nominated' AND rc.result = 'not_nominated';
  IF n_ret <> 17 THEN RAISE EXCEPTION 'expected 17 retirements, found %', n_ret; END IF;

  -- no Missouri row from this cluster may remain live, on EITHER of Missouri's two elections
  SELECT count(*) INTO n_mo_live
    FROM essentials.race_candidates rc JOIN cert_resolved t ON t.rc_id = rc.id
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id IN ('8e4e030d-2e4b-46d0-beea-2138b706513f',
                           '25941a7b-a488-4289-9d8a-3e9ca3d275ad')
     AND essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n_mo_live <> 0 THEN RAISE EXCEPTION '% Missouri rows still live after the cull', n_mo_live; END IF;

  SELECT count(*) INTO n_va_kersey
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'a820319c-d64f-4f6b-b173-2fcc06fab95b'
     AND rc.full_name = 'Andre Kersey'
     AND NOT essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n_va_kersey <> 1 THEN RAISE EXCEPTION 'Andre Kersey is still live'; END IF;

  -- Terry must stay LIVE and stay FLAGGED
  SELECT count(*) INTO n_terry
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'a820319c-d64f-4f6b-b173-2fcc06fab95b'
     AND rc.full_name = 'Randall Terry'
     AND essentials.is_live_candidate(rc.candidate_status, rc.result)
     AND rc.provisional_until = DATE '2026-09-18';
  IF n_terry <> 1 THEN RAISE EXCEPTION 'Randall Terry is not live-and-flagged as required'; END IF;

  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc JOIN cert_resolved t ON t.rc_id = rc.id
   WHERE rc.provisional_until IS NOT NULL AND rc.provisional_until <= CURRENT_DATE
     AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);
  IF n_stale > 0 THEN RAISE EXCEPTION '% of this cluster''s rows left stale', n_stale; END IF;

  RAISE NOTICE 'MO+VA confirmations OK: 17 retired against certified lists, 1 confirmed (Terry, '
    'VA-07) and kept flagged while three certified VA-07 candidates are missing from our field';
END $$;

COMMIT;

-- ROLLBACK:
--   UPDATE essentials.race_candidates rc
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL,
--          last_verified_at = NULL, provisional_until = DATE '2026-09-01', updated_at = now()
--     FROM essentials.races r
--    WHERE rc.race_id = r.id
--      AND r.election_id IN ('8e4e030d-2e4b-46d0-beea-2138b706513f','25941a7b-a488-4289-9d8a-3e9ca3d275ad',
--                            'a820319c-d64f-4f6b-b173-2fcc06fab95b')
--      AND rc.full_name IN ('Chuck Summers','Nick Vivio','Ryan Sheridan','Mike Conner',
--        'Ashleigh Rogers','G Rick','Hartzell Gray','Jeanette Cass','Randy Miller',
--        'Wayne Russell','Berton A. Knox','Brad Patty','Brett Hueffmeier','Micah Beebe',
--        'Taylor Burks','Clayton Harbison','Andre Kersey','Randall Terry');
