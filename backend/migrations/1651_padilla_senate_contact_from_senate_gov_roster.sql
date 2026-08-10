-- 1651_padilla_senate_contact_from_senate_gov_roster.sql
--
-- Populate real U.S. Senate contact data for Sen. Alex Padilla (2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f),
-- whose contact/bio/term fields were emptied by 1649 when the Inglewood councilmember's data was
-- moved off his record. Already applied to production by direct MCP execution as `postgres`;
-- guarded on END STATE.
--
-- ── SOURCE ─────────────────────────────────────────────────────────────────────────────────────
-- https://www.senate.gov/general/contact_information/senators_cfm.xml -- the Senate's own
-- machine-readable roster. Padilla's <member> block, fetched 2026-08-09:
--   address 331 Hart Senate Office Building Washington DC 20510 · phone (202) 224-3553
--   website https://www.padilla.senate.gov
--   email   https://www.padilla.senate.gov/contact/     <-- NOTE: a FORM URL, not an address
--   class   Class III · bioguide_id P000145
-- Both padilla.senate.gov and its /contact/ page return HTTP 200 with <title> "... Senator Alex
-- Padilla" on the stored host, no cross-host redirect.
--
-- 🔑 That <email> element holds a CONTACT FORM URL, not a mailbox, so it is stored in
-- web_form_url. email_addresses is deliberately left NULL: senators publish a form, not an address,
-- and writing the form URL into an email column would read as populated while being wrong. (Cf.
-- Todd Young's record, which carries todd.young@mail.house.gov -- a stale address from his House
-- service.) Nothing is invented here; a blank column is preferred to a plausible-looking value.
--
-- ── TERM DATES: DERIVED FROM CLASS, CROSS-CHECKED AGAINST THE CORPUS ───────────────────────────
-- Senate terms run Jan 3 -> Jan 3 over six years, and the class fixes which six. senators_cfm.xml
-- puts Padilla in Class III. Todd Young is Class III in the same file and is ALREADY stored here as
-- 2023-01-03 -> 2029-01-03; Jim Banks is Class I and stored as 2025-01-03 -> 2031-01-03. The
-- class -> term mapping is therefore internally consistent in our own data, which is what makes
-- 2023-01-03 -> 2029-01-03 a checked value rather than an assumed one.
--
-- ── SCOPE ──────────────────────────────────────────────────────────────────────────────────────
-- Only the CA senator's row. Note for anyone extending this: senator records here are sparse and
-- inconsistent -- of 14 with a current-holder link, 3 had a bioguide_id and 2 had urls -- so an
-- empty contact block on a senator is the NORM, not evidence of a bug. The XML above covers all
-- 100 senators in one fetch if a proper backfill is ever wanted.
-- Not addressed, still open: this record's finance_summary is an FEC **2026** cycle block with
-- total_raised 0 although Padilla is not up until 2029. Unverified; deliberately untouched.

BEGIN;

-- ⚠ valid_from / valid_to are TEXT columns here, not timestamps, and the corpus convention for
-- senators is a BARE DATE string: Todd Young stores '2023-01-03', not '2023-01-03 00:00:00'.
-- Casting to ::timestamp on write silently produces the longer form and drifts from that format.
UPDATE essentials.politicians
   SET bioguide_id  = 'P000145',
       urls         = ARRAY['https://www.padilla.senate.gov'],
       web_form_url = 'https://www.padilla.senate.gov/contact/',
       valid_from   = '2023-01-03',
       valid_to     = '2029-01-03'
 WHERE id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid
   AND (coalesce(bioguide_id,'') <> 'P000145'
        OR urls IS DISTINCT FROM ARRAY['https://www.padilla.senate.gov']
        OR coalesce(web_form_url,'') <> 'https://www.padilla.senate.gov/contact/'
        OR coalesce(valid_from,'') <> '2023-01-03'
        OR coalesce(valid_to,'')   <> '2029-01-03');

-- ── VERIFY ─────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  SELECT bioguide_id, urls, web_form_url, valid_from, valid_to, email_addresses, photo_origin_url
    INTO r FROM essentials.politicians
   WHERE id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid;

  IF r.bioguide_id IS DISTINCT FROM 'P000145' THEN
    RAISE EXCEPTION 'Padilla bioguide_id is %, expected P000145', r.bioguide_id;
  END IF;
  IF r.urls IS DISTINCT FROM ARRAY['https://www.padilla.senate.gov'] THEN
    RAISE EXCEPTION 'Padilla urls are %, expected the senate.gov site', r.urls;
  END IF;
  IF r.web_form_url IS DISTINCT FROM 'https://www.padilla.senate.gov/contact/' THEN
    RAISE EXCEPTION 'Padilla web_form_url is %', r.web_form_url;
  END IF;
  IF coalesce(r.valid_from,'') <> '2023-01-03' OR coalesce(r.valid_to,'') <> '2029-01-03' THEN
    RAISE EXCEPTION 'Padilla term is % -> %, expected bare dates 2023-01-03 -> 2029-01-03',
                    r.valid_from, r.valid_to;
  END IF;

  -- the form URL must NOT have been written into the email column
  IF r.email_addresses IS NOT NULL THEN
    RAISE EXCEPTION 'Padilla email_addresses should be NULL (senators publish a form), got %', r.email_addresses;
  END IF;

  -- 1649's de-conflation must still hold
  IF coalesce(r.photo_origin_url,'') ILIKE '%inglewood%'
     OR EXISTS (SELECT 1 FROM unnest(coalesce(r.urls, ARRAY[]::text[])) u WHERE u ILIKE '%inglewood%') THEN
    RAISE EXCEPTION 'Sen. Padilla record references Inglewood again';
  END IF;
END $$;

COMMIT;
