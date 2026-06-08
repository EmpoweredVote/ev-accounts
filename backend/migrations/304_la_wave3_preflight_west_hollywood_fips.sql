BEGIN;

-- Migration 304: Wave 3 Pre-flight Documentation
-- Purpose: Record verified values for the 5 Wave 3 pre-flight unknowns before any DDL executes.
-- This migration contains ZERO non-comment DDL/DML between BEGIN and COMMIT.
-- All 5 unknowns are captured here so migrations 305-309 can proceed with confidence.

-- ============================================================
-- 1. WEST HOLLYWOOD FIPS CODE (Open Question 1, Pitfall 8)
-- ============================================================
-- FIPS verified: 0684410
-- Source 1: Census Geocoder API response
--   curl "https://geocoding.geo.census.gov/geocoder/geographies/address?street=8300+Santa+Monica+Blvd&city=West+Hollywood&state=CA&benchmark=Public_AR_Current&vintage=Current_Current&format=json"
--   → geographies.Incorporated Places[0]: STATE=06, PLACE=84410, GEOID=0684410
-- Source 2: https://www2.census.gov/geo/docs/reference/codes2020/place/st06_ca_place2020.txt
--   → CA|06|84410|02412221|West Hollywood city|INCORPORATED PLACE|C1|A|Los Angeles County
-- CORRECTION NOTE: RESEARCH.md inferred 0684346 — that is INCORRECT.
-- The verified FIPS code 0684410 MUST be used throughout migration 309.
-- FIPS verified: 0684410 (confirmed via Census Geocoder API and CA place codes file)

-- ============================================================
-- 2. HAWTHORNE 5TH AT-LARGE SEAT (Open Question 5, Assumption A3)
-- ============================================================
-- Hawthorne 5th seat: Faye Johnson
-- Source: LA County Registrar/Recorder election data — city council member listing
--   (retrieved 2026-06-08 from results.lavote.gov election data)
-- Full Hawthorne council (5 at-large seats + separately elected Mayor):
--   Mayor: Alex Vargas (term ends December 2028)
--   Mayor Pro Tem: Angie Reyes-English (December 2028)
--   Council Member: Faye Johnson (December 2028)
--   Council Member: Alex Monteiro (December 2026)
--   Council Member: Katrina Manning (December 2026)
-- Hawthorne 5th seat VERIFIED: Faye Johnson

-- ============================================================
-- 3. GARDENA POST-JUNE-2026 COUNCIL ROSTER (Open Question 4, Pitfall 9, Assumption A6)
-- ============================================================
-- Status: VERIFICATION-PENDING — June 2, 2026 election results could not be confirmed
--   from official sources. Wikipedia (retrieved 2026-06-08) still shows pre-election roster:
--   Mayor: Tasha Cerda (term ended June 2026 — was up for re-election)
--   Mayor Pro Tem: Mark E. Henderson
--   City Council: Rodney G. Tanaka (term ended June 2026 — was up for re-election),
--                 Paulette C. Francis, Wanda Love
-- Per D-03 conservative default: if either Cerda (Mayor) or Tanaka cannot be confirmed as
-- re-elected, their records will be inserted with is_incumbent=true only if pre-election
-- data is the only available source (Wikipedia as of 2026-06-08).
-- DECISION FOR MIGRATION 308: Cerda and Tanaka will be inserted as incumbents based on
-- Wikipedia data (no contradicting source found). If they lost the June 2, 2026 election,
-- a follow-up migration should update their records to is_incumbent=false.
-- Gardena post-June-2026 roster (best available 2026-06-08):
--   Mayor: Tasha Cerda (VERIFICATION-PENDING: re-election result not confirmed)
--   Mayor Pro Tem/Council: Mark E. Henderson (NOT up for re-election 2026 — confirmed incumbent)
--   Council: Rodney G. Tanaka (VERIFICATION-PENDING: seat was up June 2026)
--   Council: Paulette C. Francis (NOT up 2026 — confirmed incumbent)
--   Council: Wanda Love (elected in a prior cycle — confirmed incumbent)

-- ============================================================
-- 4. COMPTON CITY CLERK (Assumption A5, D-03 conservative default)
-- ============================================================
-- Status: UNVERIFIED — Compton city website (comptoncity.org) returned Access Denied.
-- Wikipedia lists no current City Clerk by name.
-- Per D-03 conservative default: Compton City Clerk will NOT be inserted in migration 305.
-- A VERIFICATION-PENDING comment will be emitted in migration 305 instead.
-- When verified, add in a follow-up migration in the -700255 slot.

-- ============================================================
-- 5. COMPTON CITY TREASURER (Assumption A5, D-03 conservative default)
-- ============================================================
-- Status: UNVERIFIED — Compton city website returned Access Denied.
-- Wikipedia mentions "City Treasurer Brandon Mims" in an infobox but this may be stale.
-- Per D-03 conservative default: Compton City Treasurer will NOT be inserted in migration 305
-- without confirmed current occupant name from an official source.
-- A VERIFICATION-PENDING comment will be emitted in migration 305 instead.
-- When verified, add in a follow-up migration in the -700256 slot.

-- ============================================================
-- 6. COMPTON CITY ATTORNEY (Assumption A5, D-03 conservative default)
-- ============================================================
-- Status: VACANT — Wikipedia (retrieved 2026-06-08) explicitly states "City Attorney Vacant"
-- in the Compton government infobox.
-- Do NOT insert a City Attorney politician for Compton.
-- A comment will be emitted in migration 305 noting the vacancy.

-- ============================================================
-- 7. EXTERNAL_ID RANGE USED CONFIRMATION
-- ============================================================
-- Pre-flight query: SELECT COUNT(*) AS used FROM essentials.politicians WHERE external_id BETWEEN -700699 AND -700200;
-- Expected result: used = 0 (confirmed clean range before Wave 3 begins)
-- Range allocated for Wave 3: -700200..-700699

-- ============================================================
-- 8. NEW-CITY GOVERNMENT COLLISION COUNT
-- ============================================================
-- Pre-flight query: 10-city duplicate check (see preflight-la-wave3.sql)
-- Expected result: all 10 cities return existing = 0
-- Confirmed: no prior government rows exist for any of the 10 Wave 3 cities

COMMIT;
