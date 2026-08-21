-- 1844_co_legislature_incumbents.sql
-- Seats all 100 Colorado state legislators (35 senators + 65 representatives).
--
-- SOURCES -- three, reconciled seat by seat; a seat was only accepted when all
-- three named the same person (scripts/build-co-legislature-roster.mjs):
--   Identity, district, party, email, name spelling : leg.colorado.gov/legislators
--   Independent cross-check + official portrait URL : data.openstates.org
--   Assumed-office date                             : ballotpedia.org
--
-- WHY THREE. Open States is a detector, not an oracle -- it lagged our TX SD-22
-- fix and dropped a sitting TX HD-93 member. Ballotpedia is the ONLY one of the
-- three carrying an assumed-office date. The chamber's own table is the
-- tiebreaker on identity.
--
-- ⚠ THE CHAMBER'S TABLE CARRIES 101 ROWS. Senate District 21 appears twice: once
-- for Dafna Michaelson Jenet annotated "resigned as of 2/13/26" and once for her
-- successor. The resigned row is dropped by the builder, and the drop is
-- asserted rather than assumed. SD 21 is seated here to ADRIENNE BENAVIDEZ from
-- 2026-03-02, which post-dates the 2026-02-13 resignation as it must.
--
-- ⚠ term_start IS THE ASSUMED-OFFICE DATE, not the start of the current two-year
-- term. office_terms models how long THIS PERSON has held THIS SEAT, so a member
-- returned at three elections carries one continuous term from their first, not
-- three. Amy Paschal's HD 18 term begins 2025-01-08 -- the day Marc Snyder
-- vacated it for SD 12 -- which is exactly the sort of thing a "current term"
-- reading would erase.
--
-- ⚠ DO NOT SOURCE THIS FROM WIKIPEDIA'S "Start" COLUMN. Measured 2026-08-21: it
-- holds the ELECTION year for elected members and the APPOINTMENT year for
-- appointees, in the same column. Marc Snyder shows 2024 there but took the seat
-- 2025-01-08. start_precision='year' does not excuse a wrong year.
--
-- DATE PRECISION is recorded, never fabricated: 99 seats carry a full
-- assumed-office date (start_precision='day'); 1 carries only a year
-- (SD 26, Jeff Bridges -- Ballotpedia has "2019" and nothing finer), stored as
-- 2019-01-01 with start_precision='year' so month and day are explicitly NOT
-- being claimed.
--
-- how_started is NULL throughout. Several members arrived by vacancy-committee
-- appointment rather than election -- the non-January assumed-office dates make
-- that visible -- but which is which was not verified per member, and
-- seat_officeholder's default of 'elected' would assert it for all 100.
--
-- term_end is NULL for all (currently serving) but term_start is ALWAYS
-- populated: a NULL/NULL pair reads downstream as "currently serving" and would
-- mask a later departure.
--
-- NAME FORM: the chamber's own spelling wins; the short form other sources use is
-- kept in alternate_names so the person stays findable either way.
--   H44  Anthony Hartsook     also listed as "Tony Hartsook"
--   H53  Andrew Boesenecker   also listed as "Andy Boesenecker"
--   H58  Larry Don Suckla     also listed as "Larry Suckla"
--   H62  Matthew Martinez     also listed as "Matt Martinez"
--
-- PORTRAITS: 92 of 100 carry an official leg.colorado.gov portrait URL,
-- recorded in photo_origin_url for the headshot pass. The remaining 8 are a
-- known backlog, not an error.
--
-- EXTERNAL IDS: Senate SD n -> -(810000+n); House HD n -> -(820000+n), mirroring
-- WA's scheme off the state FIPS (CO = 08). Verified collision-free 2026-08-21:
-- zero existing rows in -810001..-829999.
--
-- IDEMPOTENCY: politicians uses ON CONFLICT (external_id) DO NOTHING (real unique
-- index). Occupancy goes through essentials.seat_officeholder(), which is
-- idempotent and which closes any predecessor's term rather than silently
-- overlapping it -- the two-step CLAUDE.md requires. It is called only where no
-- term already exists for the pair, so a re-run is a no-op.
--
-- Joins key on (geo_id, district_type, mtfcc) because geo_id is NOT unique across
-- MTFCCs. STATE_UPPER=G5210, STATE_LOWER=G5220.

BEGIN;

CREATE TEMP TABLE co_leg_seed (
  seat            text,
  district_type   text,
  mtfcc           text,
  district_suffix text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  party           text,
  party_short     text,
  email           text,
  aliases         text[],
  term_start      date,
  start_precision text,
  photo_url       text
) ON COMMIT DROP;

INSERT INTO co_leg_seed VALUES
    ('S1', 'STATE_UPPER', 'G5210', '001', 'State Senator', -810001, 'Byron Pelton', 'Byron', 'Pelton', 'Republican', 'R', 'byron.pelton.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdzk5QXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--7602b8809ffd638d639b8a39132341d13e764130/Pelton,%20Byron.jpg'),
    ('S2', 'STATE_UPPER', 'G5210', '002', 'State Senator', -810002, 'Lisa Frizell', 'Lisa', 'Frizell', 'Republican', 'R', 'lisa.frizell.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBODVTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--2ea2d7fd307e8f1e762f9099be3a5b09bcb15f0a/Frizell,%20Lisa.jpg'),
    ('S3', 'STATE_UPPER', 'G5210', '003', 'State Senator', -810003, 'Nick Hinrichsen', 'Nick', 'Hinrichsen', 'Democratic', 'D', 'nick.hinrichsen.senate@coleg.gov', '{}'::text[], DATE '2022-02-28', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMmhUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--4b49d3c681dec554da650bb248660b5dca8c032a/Hinrichsen,%20Nick.jpg'),
    ('S4', 'STATE_UPPER', 'G5210', '004', 'State Senator', -810004, 'Mark Baisley', 'Mark', 'Baisley', 'Republican', 'R', 'mark.baisley@senate.co.com', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBK2hTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--7e5bc18c718b71be8507a78ac7fd5c9f047b70ae/Baisley,%20Mark.jpg'),
    ('S5', 'STATE_UPPER', 'G5210', '005', 'State Senator', -810005, 'Marc Catlin', 'Marc', 'Catlin', 'Republican', 'R', 'marc.catlin.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdzlUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--a385166cb7a79caaf96ebfd19a9e619a73014264/Catlin,%20Marc.jpg'),
    ('S6', 'STATE_UPPER', 'G5210', '006', 'State Senator', -810006, 'Cleave Simpson', 'Cleave', 'Simpson', 'Republican', 'R', 'cleave.simpson.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBL3hTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--7513585dd62fce02f81a3e6d3a1c44d08d397b9b/Simpson,%20Cleave.jpg'),
    ('S7', 'STATE_UPPER', 'G5210', '007', 'State Senator', -810007, 'Janice Rich', 'Janice', 'Rich', 'Republican', 'R', 'janice.rich.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBLzVTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--afd770f3635f91909fdcc0bde3b95c1599089da7/Rich,%20Janice.jpg'),
    ('S8', 'STATE_UPPER', 'G5210', '008', 'State Senator', -810008, 'Dylan Roberts', 'Dylan', 'Roberts', 'Democratic', 'D', 'dylan.roberts.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOXhTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--8f1c6929289275427225aba6c766440b456c3b1a/Roberts,%20Dylan.jpg'),
    ('S9', 'STATE_UPPER', 'G5210', '009', 'State Senator', -810009, 'Lynda Zamora Wilson', 'Lynda', 'Wilson', 'Republican', 'R', 'lynda.zamorawilson.senate@coleg.gov', '{}'::text[], DATE '2025-07-08', 'day', NULL),
    ('S10', 'STATE_UPPER', 'G5210', '010', 'State Senator', -810010, 'Larry Liston', 'Larry', 'Liston', 'Republican', 'R', 'larry.liston.senate@coleg.gov', '{}'::text[], DATE '2021-01-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBK1pTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--4e7ce4fd5e7d42b1e4e7ad102c27293ed3fd28c6/Liston,%20Larry.jpg'),
    ('S11', 'STATE_UPPER', 'G5210', '011', 'State Senator', -810011, 'Tony Exum', 'Tony', 'Exum', 'Democratic', 'D', 'tony.exum.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBKzFTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--d4163d37a59db187d2e91b1e4af903d1385df345/Exum,%20Tony%20SR.jpg'),
    ('S12', 'STATE_UPPER', 'G5210', '012', 'State Senator', -810012, 'Marc Snyder', 'Marc', 'Snyder', 'Democratic', 'D', 'marc.snyder.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeWxwQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--af6fe2d0b4cf102c536ab81e2462d61d44783d1a/Snyder,%20Marc.jpg'),
    ('S13', 'STATE_UPPER', 'G5210', '013', 'State Senator', -810013, 'Scott Bright', 'Scott', 'Bright', 'Republican', 'R', 'scott.bright.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/ScottBright.jpg'),
    ('S14', 'STATE_UPPER', 'G5210', '014', 'State Senator', -810014, 'Cathy Kipp', 'Cathy', 'Kipp', 'Democratic', 'D', 'cathy.kipp.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBLzFTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--0c9240ecbd4ae088cff97b227aa60c5b2bf6ac83/Kipp,%20Cathy.jpg'),
    ('S15', 'STATE_UPPER', 'G5210', '015', 'State Senator', -810015, 'Janice Marchman', 'Janice', 'Marchman', 'Democratic', 'D', 'janice.marchman.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBL0ZTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--fcb333a05c84defed2c15ce0bdf8723c605199f3/Marchman,%20Janice.jpg'),
    ('S16', 'STATE_UPPER', 'G5210', '016', 'State Senator', -810016, 'Chris Kolker', 'Chris', 'Kolker', 'Democratic', 'D', 'chris.kolker.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBL2xTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--56397ac18c5c7504955ce6730cdb98acc6f36205/Kolker,%20Chris.jpg'),
    ('S17', 'STATE_UPPER', 'G5210', '017', 'State Senator', -810017, 'Katie Wallace', 'Katie', 'Wallace', 'Democratic', 'D', 'katie.wallace.senate@coleg.gov', '{}'::text[], DATE '2025-03-21', 'day', NULL),
    ('S18', 'STATE_UPPER', 'G5210', '018', 'State Senator', -810018, 'Judy Amabile', 'Judy', 'Amabile', 'Democratic', 'D', 'judy.amabile.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOUZTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--b064f9311bf3386a06c699ba6aeee37a07444669/Judy%20Amabile.jpg'),
    ('S19', 'STATE_UPPER', 'G5210', '019', 'State Senator', -810019, 'Lindsey Daugherty', 'Lindsey', 'Daugherty', 'Democratic', 'D', 'lindsey.daugherty.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBL0pTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--4a370bf5b571c75e61965486b4074d0d108d80b8/Daugherty,%20Lindsey.jpg'),
    ('S20', 'STATE_UPPER', 'G5210', '020', 'State Senator', -810020, 'Lisa Cutter', 'Lisa', 'Cutter', 'Democratic', 'D', 'lisa.cutter.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBL3BTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--f08a5431fd4e493fd52194b1418976fd5a250df8/Cutter,%20Lisa.jpg'),
    ('S21', 'STATE_UPPER', 'G5210', '021', 'State Senator', -810021, 'Adrienne Benavidez', 'Adrienne', 'Benavidez', 'Democratic', 'D', 'adrienne.benavidez.senate@coleg.gov', '{}'::text[], DATE '2026-03-02', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMmlFQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--23746f2c8382ad88801fb500a0e47384becef5d8/Benavidez,%20Adrienne.jpg'),
    ('S22', 'STATE_UPPER', 'G5210', '022', 'State Senator', -810022, 'Jessie Danielson', 'Jessie', 'Danielson', 'Democratic', 'D', 'jessie.danielson.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBK1JTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--444190d18434e86fd51db8d0f3656887bb45824b/Danielson,%20Jessie.jpg'),
    ('S23', 'STATE_UPPER', 'G5210', '023', 'State Senator', -810023, 'Barbara Kirkmeyer', 'Barbara', 'Kirkmeyer', 'Republican', 'R', 'barbara.kirkmeyer.senate@coleg.gov', '{}'::text[], DATE '2021-01-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBKzlTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--b75364af53ed9e801f5b0adfea3ca5cd1bbb3cf9/Kirkmeyer,%20Barbara.jpg'),
    ('S24', 'STATE_UPPER', 'G5210', '024', 'State Senator', -810024, 'Kyle Mullica', 'Kyle', 'Mullica', 'Democratic', 'D', 'kyle.mullica.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBK05TQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--c8a05176c5f582700250b8669d5df16c090a5d05/Mullica,%20Kyle.jpg'),
    ('S25', 'STATE_UPPER', 'G5210', '025', 'State Senator', -810025, 'William Lindstedt', 'William', 'Lindstedt', 'Democratic', 'D', 'william.lindstedt.senate@coleg.gov', '{}'::text[], DATE '2025-12-30', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBK1ZTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--5f021c807d11e6b00e9c2e987dd101e88185bee0/Lindstedt,%20William.jpg'),
    ('S26', 'STATE_UPPER', 'G5210', '026', 'State Senator', -810026, 'Jeff Bridges', 'Jeff', 'Bridges', 'Democratic', 'D', 'jeff.bridges.senate@coleg.gov', '{}'::text[], DATE '2019-01-01', 'year', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeWhwQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--1f18e804077a78214975ed08168ecc3aa4c6f896/Bridges,Jeff.jpg'),
    ('S27', 'STATE_UPPER', 'G5210', '027', 'State Senator', -810027, 'Tom Sullivan', 'Tom', 'Sullivan', 'Democratic', 'D', 'tom.sullivan.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOWxTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--85d8c976f450d3f48b1dbe66ac712d2be0f5e86b/Sullivan,Tom.jpg'),
    ('S28', 'STATE_UPPER', 'G5210', '028', 'State Senator', -810028, 'Mike Weissman', 'Mike', 'Weissman', 'Democratic', 'D', 'mike.weissman.senate@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOUJTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--8f5c3253e6bdff26fefd8864913fd683300d7176/Weissman,Mike.jpg'),
    ('S29', 'STATE_UPPER', 'G5210', '029', 'State Senator', -810029, 'Iman Jodeh', 'Iman', 'Jodeh', 'Democratic', 'D', 'iman.jodeh.senate@coleg.gov', '{}'::text[], DATE '2025-01-10', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOXRTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--29b2053d4c36e8d2d5d661dd8e279ff5a4fa30e5/Iman_Jodeh.jpg'),
    ('S30', 'STATE_UPPER', 'G5210', '030', 'State Senator', -810030, 'John Carson', 'John', 'Carson', 'Republican', 'R', 'john.carson.senate@coleg.gov', '{}'::text[], DATE '2025-01-10', 'day', 'https://i0.wp.com/coloradocommunitymedia.com/wp-content/uploads/2024/06/DCO-0613-Commissioner-D3-race-2.jpg?w=768&ssl=1'),
    ('S31', 'STATE_UPPER', 'G5210', '031', 'State Senator', -810031, 'Matt Ball', 'Matt', 'Ball', 'Democratic', 'D', 'matt.ball.senate@coleg.gov', '{}'::text[], DATE '2025-01-10', 'day', 'https://images.squarespace-cdn.com/content/67330255adbf4c1a48d665b3/1732088535559-59YBHTFEFBLWVIPHRMDL/Matt+Ball+Headshot_park.jpeg?content-type=image%2Fjpeg'),
    ('S32', 'STATE_UPPER', 'G5210', '032', 'State Senator', -810032, 'Robert Rodriguez', 'Robert', 'Rodriguez', 'Democratic', 'D', 'robert.rodriguez.senate@coleg.gov', '{}'::text[], DATE '2019-01-04', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOVZTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--1d263d3105ce58458603b07ad78a431ab0fa5a38/Rodriguez,Robert.jpg'),
    ('S33', 'STATE_UPPER', 'G5210', '033', 'State Senator', -810033, 'James Coleman', 'James', 'Coleman', 'Democratic', 'D', 'james.coleman.senate@coleg.gov', '{}'::text[], DATE '2021-01-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBKzVTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--7a5daba3d83289b2d6431d3200c1731a422d6091/Coleman,%20James%20.jpg'),
    ('S34', 'STATE_UPPER', 'G5210', '034', 'State Senator', -810034, 'Julie Gonzales', 'Julie', 'Gonzales', 'Democratic', 'D', 'julie.gonzales.senate@coleg.gov', '{}'::text[], DATE '2019-01-04', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOXBTQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--f26a08c473c6f23699613abea473f8b3120e976c/Gonzales,%20Julie.jpg'),
    ('S35', 'STATE_UPPER', 'G5210', '035', 'State Senator', -810035, 'Rod Pelton', 'Rod', 'Pelton', 'Republican', 'R', 'rod.pelton.senate@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOU5TQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--08b2017b389fcad9ad2c05f5ffc23692931b3216/Pelton,%20Rod.jpg'),
    ('H1', 'STATE_LOWER', 'G5220', '001', 'State Representative', -820001, 'Javier Mabrey', 'Javier', 'Mabrey', 'Democratic', 'D', 'javier.mabrey.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeGhUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--d5786817bd26f7bddab7f2d1085068af877cdf48/Mabrey,%20Javier.jpg'),
    ('H2', 'STATE_LOWER', 'G5220', '002', 'State Representative', -820002, 'Steven Woodrow', 'Steven', 'Woodrow', 'Democratic', 'D', 'steven.woodrow.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMXhUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--b28a2d8e234c37d646a99efd0b7aea44a198fe9d/Woodrow,Steven-.jpg'),
    ('H3', 'STATE_LOWER', 'G5220', '003', 'State Representative', -820003, 'Meg Froelich', 'Meg', 'Froelich', 'Democratic', 'D', 'meg.froelich.house@coleg.gov', '{}'::text[], DATE '2019-01-14', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeUpUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--2f6a935d21bc9d78189accacc0743c3071e567a1/Froelich,%20Meg.jpg'),
    ('H4', 'STATE_LOWER', 'G5220', '004', 'State Representative', -820004, 'Cecelia Espenoza', 'Cecelia', 'Espenoza', 'Democratic', 'D', 'cecelia.espenoza.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/CeceliaEspenoza24.jpg'),
    ('H5', 'STATE_LOWER', 'G5220', '005', 'State Representative', -820005, 'Alex Valdez', 'Alex', 'Valdez', 'Democratic', 'D', 'alex.valdez.house@coleg.gov', '{}'::text[], DATE '2019-01-04', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMU5UQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--d081dee839aa2f1b43bce42882d1b5e679141a05/Valdez,%20Alex.jpg'),
    ('H6', 'STATE_LOWER', 'G5220', '006', 'State Representative', -820006, 'Sean Camacho', 'Sean', 'Camacho', 'Democratic', 'D', 'sean.camacho.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/SeanCamacho2024.jpeg'),
    ('H7', 'STATE_LOWER', 'G5220', '007', 'State Representative', -820007, 'Jennifer Bacon', 'Jennifer', 'Bacon', 'Democratic', 'D', 'jennifer.bacon.house@coleg.gov', '{}'::text[], DATE '2021-01-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeXhUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--9cf98fe8dc3d759fedb356430b801c66ad2b1edd/Bacon,%20Jennifer.jpg'),
    ('H8', 'STATE_LOWER', 'G5220', '008', 'State Representative', -820008, 'Lindsay Gilchrist', 'Lindsay', 'Gilchrist', 'Democratic', 'D', 'lindsay.gilchrist.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://images.squarespace-cdn.com/content/v1/5ea0cb44b06d660224de3cc9/1588045290088-U5X5Z0VC06EFGHN9K1AC/lindsay-gilchrist.jpg?format=500w'),
    ('H9', 'STATE_LOWER', 'G5220', '009', 'State Representative', -820009, 'Emily Sirota', 'Emily', 'Sirota', 'Democratic', 'D', 'emily.sirota.house@coleg.gov', '{}'::text[], DATE '2019-01-04', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeTVUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--14b86aa8d8dc84d49199d71d5ad732b0abe8eb38/Sirota,%20Emily.jpg'),
    ('H10', 'STATE_LOWER', 'G5220', '010', 'State Representative', -820010, 'Junie Joseph', 'Junie', 'Joseph', 'Democratic', 'D', 'junie.joseph.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeWRUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--c05fd8101f2bb8458f9e92fcaac1e5d867b1b662/Joseph,Junie.jpg'),
    ('H11', 'STATE_LOWER', 'G5220', '011', 'State Representative', -820011, 'Karen McCormick', 'Karen', 'McCormick', 'Democratic', 'D', 'karen.mccormick.house@coleg.gov', '{}'::text[], DATE '2021-01-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMkJUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--e6c90c7865f8557c6411c91a27f58280cf938f05/McCormick,%20Karen.jpg'),
    ('H12', 'STATE_LOWER', 'G5220', '012', 'State Representative', -820012, 'Kyle Brown', 'Kyle', 'Brown', 'Democratic', 'D', 'kyle.brown.house@coleg.gov', '{}'::text[], DATE '2023-02-01', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMEZUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--4dbbcef24e21979fc4a8cd74bea005733c789d61/Brown,%20Kyle.jpg'),
    ('H13', 'STATE_LOWER', 'G5220', '013', 'State Representative', -820013, 'Julie McCluskie', 'Julie', 'McCluskie', 'Democratic', 'D', 'julie.mccluskie.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeEpUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--876516c8bc7b672caf43f253b83440d18b6eba1a/McCluskie,%20Julie.jpg'),
    ('H14', 'STATE_LOWER', 'G5220', '014', 'State Representative', -820014, 'Ava Flanell', 'Ava', 'Flanell', 'Republican', 'R', 'ava.flanell.house@coleg.gov', '{}'::text[], DATE '2025-10-11', 'day', NULL),
    ('H15', 'STATE_LOWER', 'G5220', '015', 'State Representative', -820015, 'Scott Bottoms', 'Scott', 'Bottoms', 'Republican', 'R', 'scott.bottoms.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMCtIQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--2fb56df7ac0ddd22f63e0eb99a03b0d30e48bff5/Rep%20Bottoms%202026.jpg'),
    ('H16', 'STATE_LOWER', 'G5220', '016', 'State Representative', -820016, 'Rebecca Keltie', 'Rebecca', 'Keltie', 'Republican', 'R', 'rebecca.keltie.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Rebecca_Keltie_new.jpeg'),
    ('H17', 'STATE_LOWER', 'G5220', '017', 'State Representative', -820017, 'Regina English', 'Regina', 'English', 'Democratic', 'D', 'regina.english.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBejFUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--854752db6d6188b1f926eb9e309d7791738093e5/English,%20Regina.jpg'),
    ('H18', 'STATE_LOWER', 'G5220', '018', 'State Representative', -820018, 'Amy Paschal', 'Amy', 'Paschal', 'Democratic', 'D', 'amy.paschal.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/AmyPaschall24.jpg'),
    ('H19', 'STATE_LOWER', 'G5220', '019', 'State Representative', -820019, 'Dan Woog', 'Dan', 'Woog', 'Republican', 'R', 'dan.woog.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBNEZUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--6bf3d084b17e200e01f2ade18431e32df8e43a60/Rep%20Woog%202026.jpg'),
    ('H20', 'STATE_LOWER', 'G5220', '020', 'State Representative', -820020, 'Jarvis Caldwell', 'Jarvis', 'Caldwell', 'Republican', 'R', 'jarvis.caldwell.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://coloradonewsline.com/wp-content/uploads/2023/12/jarvis-caldwell--200x300.jpeg'),
    ('H21', 'STATE_LOWER', 'G5220', '021', 'State Representative', -820021, 'Mary Bradfield', 'Mary', 'Bradfield', 'Republican', 'R', 'mary.bradfield.house@coleg.gov', '{}'::text[], DATE '2021-01-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMXRUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--e23010a39e960f0ad905ba4df19c5be9cf9ea5b9/Bradfield,Mary.jpg'),
    ('H22', 'STATE_LOWER', 'G5220', '022', 'State Representative', -820022, 'Ken DeGraaf', 'Ken', 'DeGraaf', 'Republican', 'R', 'ken.degraaf.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeUJUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--375071f2707656fb29aac1700948de56433dd649/deGraaf,%20Ken.jpg'),
    ('H23', 'STATE_LOWER', 'G5220', '023', 'State Representative', -820023, 'Monica Duran', 'Monica', 'Duran', 'Democratic', 'D', 'monica.duran.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeDVUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--807d51d68890b754bbaed0298372904fcf4a75d5/Duran,%20Monica.jpg'),
    ('H24', 'STATE_LOWER', 'G5220', '024', 'State Representative', -820024, 'Lisa Feret', 'Lisa', 'Feret', 'Democratic', 'D', 'lisa.feret.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Lisa_Feret_20240622_065004.jpeg'),
    ('H25', 'STATE_LOWER', 'G5220', '025', 'State Representative', -820025, 'Tammy Story', 'Tammy', 'Story', 'Democratic', 'D', 'tammy.story.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBelJUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--6eaeb97b2bd0b0a9f0bf46040f34663cd0c37112/Story,%20Tammy.jpg'),
    ('H26', 'STATE_LOWER', 'G5220', '026', 'State Representative', -820026, 'Meghan Lukens', 'Meghan', 'Lukens', 'Democratic', 'D', 'meghan.lukens.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBM05UQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--16c3fe74431c9197b51b11e7bd64eb387369e758/Lukens,%20Meghan.jpg'),
    ('H27', 'STATE_LOWER', 'G5220', '027', 'State Representative', -820027, 'Brianna Titone', 'Brianna', 'Titone', 'Democratic', 'D', 'brianna.titone.house@coleg.gov', '{}'::text[], DATE '2019-01-04', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeUZUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--ee1a1cad1906ee93f20ffecfca5d9444e525ac05/Titone,%20Brianna.jpg'),
    ('H28', 'STATE_LOWER', 'G5220', '028', 'State Representative', -820028, 'Sheila Lieder', 'Sheila', 'Lieder', 'Democratic', 'D', 'sheila.lieder.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeE5UQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--bbb6f4456c06c54b1c8fffade0441c9a63ccf12e/Lieder,%20Sheila.jpg'),
    ('H29', 'STATE_LOWER', 'G5220', '029', 'State Representative', -820029, 'Lori Goldstein', 'Lori', 'Goldstein', 'Democratic', 'D', 'lori.goldstein.house@coleg.gov', '{}'::text[], DATE '2026-01-14', 'day', NULL),
    ('H30', 'STATE_LOWER', 'G5220', '030', 'State Representative', -820030, 'Rebekah Stewart', 'Rebekah', 'Stewart', 'Democratic', 'D', 'rebekah.stewart.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/RebekahStewart2024.jpeg'),
    ('H31', 'STATE_LOWER', 'G5220', '031', 'State Representative', -820031, 'Jacque Phillips', 'Jacque', 'Phillips', 'Democratic', 'D', 'jacque.phillips.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/jacque_phillips.jpg'),
    ('H32', 'STATE_LOWER', 'G5220', '032', 'State Representative', -820032, 'Manny Rutinel', 'Manny', 'Rutinel', 'Democratic', 'D', 'manny.rutinel.house@coleg.gov', '{}'::text[], DATE '2023-10-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBelZUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--ef4c74094f42d481f610cc35459aa4ca3a78b6eb/Rutinel,%20Manny.jpg'),
    ('H33', 'STATE_LOWER', 'G5220', '033', 'State Representative', -820033, 'Kenny Nguyen', 'Kenny', 'Nguyen', 'Democratic', 'D', 'kenny.nguyen.house@coleg.gov', '{}'::text[], DATE '2026-01-14', 'day', NULL),
    ('H34', 'STATE_LOWER', 'G5220', '034', 'State Representative', -820034, 'Jenny Willford', 'Jenny', 'Willford', 'Democratic', 'D', 'jenny.willford.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBM0pUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--1d5d85081063604c97df120526af629e099e84e1/Willford,%20Jenny.jpg'),
    ('H35', 'STATE_LOWER', 'G5220', '035', 'State Representative', -820035, 'Lorena Garcia', 'Lorena', 'Garcia', 'Democratic', 'D', 'lorena.garcia.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMVZUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--000f403a3a00241cbcadbe814acab9558e10dde4/Garcia,%20Lorena.jpg'),
    ('H36', 'STATE_LOWER', 'G5220', '036', 'State Representative', -820036, 'Michael Carter', 'Michael', 'Carter', 'Democratic', 'D', 'michael.carter.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://aps.ss20.sharpschool.com/UserFiles/Servers/Server_3217444/Image/Board%20of%20Education/Members/Carter_Michael_152-200x300.jpg'),
    ('H37', 'STATE_LOWER', 'G5220', '037', 'State Representative', -820037, 'Chad Clifford', 'Chad', 'Clifford', 'Democratic', 'D', 'chad.clifford.house@coleg.gov', '{}'::text[], DATE '2024-01-03', 'day', NULL),
    ('H38', 'STATE_LOWER', 'G5220', '038', 'State Representative', -820038, 'Gretchen Rydin', 'Gretchen', 'Rydin', 'Democratic', 'D', 'gretchen.rydin.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/GretchenRydin2024.jpeg'),
    ('H39', 'STATE_LOWER', 'G5220', '039', 'State Representative', -820039, 'Brandi Bradley', 'Brandi', 'Bradley', 'Republican', 'R', 'brandi.bradley.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMnhUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--f00bc156e1af4f5ddf1b991b5f96817a5221767c/Bradley,%20Brandi.jpg'),
    ('H40', 'STATE_LOWER', 'G5220', '040', 'State Representative', -820040, 'Naquetta Ricks', 'Naquetta', 'Ricks', 'Democratic', 'D', 'naquetta.ricks.house@coleg.gov', '{}'::text[], DATE '2021-01-13', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMjlUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--6ad9235336da0cb9a035f6bb879b11838db6749e/Ricks,%20Naquetta.jpg'),
    ('H41', 'STATE_LOWER', 'G5220', '041', 'State Representative', -820041, 'Jamie Jackson', 'Jamie', 'Jackson', 'Democratic', 'D', 'jamie.jackson.house@coleg.gov', '{}'::text[], DATE '2025-01-27', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Jamie_Jackson_Colorado_House.jpg'),
    ('H42', 'STATE_LOWER', 'G5220', '042', 'State Representative', -820042, 'Mandy Lindsay', 'Mandy', 'Lindsay', 'Democratic', 'D', 'mandy.lindsay.house@coleg.gov', '{}'::text[], DATE '2022-01-18', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeFpUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--16f693f706022e86e268da5a37a9a93ff4aef1ba/Lindsay,%20Mandy.jpg'),
    ('H43', 'STATE_LOWER', 'G5220', '043', 'State Representative', -820043, 'Bob Marshall', 'Bob', 'Marshall', 'Democratic', 'D', 'bob.marshall.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBM1pUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--18c815634a34450ae6caf0855eeb0406ea4582cc/Marshall,%20Bob.jpg'),
    ('H44', 'STATE_LOWER', 'G5220', '044', 'State Representative', -820044, 'Anthony Hartsook', 'Anthony', 'Hartsook', 'Republican', 'R', 'anthony.hartsook.house@coleg.gov', ARRAY['Tony Hartsook']::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeVpUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--500af1f4202491ae4bd34d7f8e8196708b8f0019/Hartsook,Anthony.jpg'),
    ('H45', 'STATE_LOWER', 'G5220', '045', 'State Representative', -820045, 'Max Brooks', 'Max', 'Brooks', 'Republican', 'R', 'max.brooks.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/MaxBrooks2024.jpg'),
    ('H46', 'STATE_LOWER', 'G5220', '046', 'State Representative', -820046, 'Tisha Mauro', 'Tisha', 'Mauro', 'Democratic', 'D', 'tisha.mauro.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMlJUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--c083d9d0c61aec511c97d0802cd5873416f901d9/Mauro,%20Tisha.jpg'),
    ('H47', 'STATE_LOWER', 'G5220', '047', 'State Representative', -820047, 'Ty Winter', 'Ty', 'Winter', 'Republican', 'R', 'ty.winter.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMmRUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--7e3263a1638a76c8a5732293d1ea8f844d2e9d25/Winter,Ty.jpg'),
    ('H48', 'STATE_LOWER', 'G5220', '048', 'State Representative', -820048, 'Carlos Barron', 'Carlos', 'Barron', 'Republican', 'R', 'carlos.barron.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://i0.wp.com/coloradocommunitymedia.com/wp-content/uploads/2024/10/7A10C326-743A-4DF1-9625-6E709398C30F-JF-Services-Inc-Office-e1728345969755.jpg?resize=150%2C150&ssl=1'),
    ('H49', 'STATE_LOWER', 'G5220', '049', 'State Representative', -820049, 'Lesley Smith', 'Lesley', 'Smith', 'Democratic', 'D', 'lesley.smith.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/Lesley_Smith_20230524_083227.jpg'),
    ('H50', 'STATE_LOWER', 'G5220', '050', 'State Representative', -820050, 'Ryan Gonzalez', 'Ryan', 'Gonzalez', 'Republican', 'R', 'ryan.gonzalez.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/ryangonzalez.jpeg'),
    ('H51', 'STATE_LOWER', 'G5220', '051', 'State Representative', -820051, 'Ron Weinberg', 'Ron', 'Weinberg', 'Republican', 'R', 'ron.weinberg.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBekpUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--ff0c3a27e8b7c137cbdb5c5fde02af093a8db4b4/Rep%20Ron%20Weinberg.JPG'),
    ('H52', 'STATE_LOWER', 'G5220', '052', 'State Representative', -820052, 'Yara Zokaie', 'Yara', 'Zokaie', 'Democratic', 'D', 'yara.zokaie.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/yf.jpeg'),
    ('H53', 'STATE_LOWER', 'G5220', '053', 'State Representative', -820053, 'Andrew Boesenecker', 'Andrew', 'Boesenecker', 'Democratic', 'D', 'andrew.boesenecker.house@coleg.gov', ARRAY['Andy Boesenecker']::text[], DATE '2021-04-28', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBMGhUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--cfaae02348bca597a92a30ada0c08d3e68ecc93f/Boesenecker,%20Andrew.jpg'),
    ('H54', 'STATE_LOWER', 'G5220', '054', 'State Representative', -820054, 'Matt Soper', 'Matt', 'Soper', 'Republican', 'R', 'matthew.soper.house@coleg.gov', '{}'::text[], DATE '2019-01-04', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBOVdUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--767a7057ff5fd758ce0cbddae6aa4c7b1ef907f2/Soper,%20Matthew.jpg'),
    ('H55', 'STATE_LOWER', 'G5220', '055', 'State Representative', -820055, 'Rick Taggart', 'Rick', 'Taggart', 'Republican', 'R', 'rick.taggart.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBd3BUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--6b1fb5526e7780f89f9b2fb79535d4e7c39fc37b/TaggartRick.jpg'),
    ('H56', 'STATE_LOWER', 'G5220', '056', 'State Representative', -820056, 'Chris Richardson', 'Chris', 'Richardson', 'Republican', 'R', 'chris.richardson.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://i0.wp.com/coloradocommunitymedia.com/wp-content/uploads/2022/10/20221012-100004-Richardson20for20Facebook.jpg?resize=1200%2C782&ssl=1'),
    ('H57', 'STATE_LOWER', 'G5220', '057', 'State Representative', -820057, 'Elizabeth Velasco', 'Elizabeth', 'Velasco', 'Democratic', 'D', 'elizabeth.velasco.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBNTltQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--1fae82b072c31f28dbf73e893d992426893562a5/Velasco,%20Elizabeth.jpg'),
    ('H58', 'STATE_LOWER', 'G5220', '058', 'State Representative', -820058, 'Larry Don Suckla', 'Larry', 'Suckla', 'Republican', 'R', 'larry.suckla.house@coleg.gov', ARRAY['Larry Suckla']::text[], DATE '2025-01-08', 'day', NULL),
    ('H59', 'STATE_LOWER', 'G5220', '059', 'State Representative', -820059, 'Katie Stewart', 'Katie', 'Stewart', 'Democratic', 'D', 'katie.stewart.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/KatieStewart2024.jpg'),
    ('H60', 'STATE_LOWER', 'G5220', '060', 'State Representative', -820060, 'Stephanie Luck', 'Stephanie', 'Luck', 'Republican', 'R', 'stephanie.luck.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBdzVUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--30a0b950ff1755b8691052388ed9b70f8fe688cc/Luck,%20Stephanie.jpg'),
    ('H61', 'STATE_LOWER', 'G5220', '061', 'State Representative', -820061, 'Eliza Hamrick', 'Eliza', 'Hamrick', 'Democratic', 'D', 'eliza.hamrick.house@coleg.gov', '{}'::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBd3RUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--291f32764a20e23b89e6ea44560dea6151853b61/Hamrick,Eliza-.jpg'),
    ('H62', 'STATE_LOWER', 'G5220', '062', 'State Representative', -820062, 'Matthew Martinez', 'Matthew', 'Martinez', 'Democratic', 'D', 'matthew.martinez.house@coleg.gov', ARRAY['Matt Martinez']::text[], DATE '2023-01-09', 'day', 'https://leg.colorado.gov/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBeEJUQXc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--4743a8832adf9daea6fe22f97942afef67ab8d1a/Martinez,%20Matthew.jpg'),
    ('H63', 'STATE_LOWER', 'G5220', '063', 'State Representative', -820063, 'Dusty Johnson', 'Dusty', 'Johnson', 'Republican', 'R', 'dustyforcolorado@gmail.com', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/DustyJohnsonCO.jpg'),
    ('H64', 'STATE_LOWER', 'G5220', '064', 'State Representative', -820064, 'Scott Slaugh', 'Scott', 'Slaugh', 'Republican', 'R', 'scott.slaugh.house@coleg.gov', '{}'::text[], DATE '2025-09-23', 'day', NULL),
    ('H65', 'STATE_LOWER', 'G5220', '065', 'State Representative', -820065, 'Lori Garcia Sander', 'Lori', 'Sander', 'Republican', 'R', 'lori.garciasander.house@coleg.gov', '{}'::text[], DATE '2025-01-08', 'day', 'https://s3.amazonaws.com/ballotpedia-api4/files/thumbs/200/300/LoriSander2024.jpg');

-- Guard the payload itself before it touches anything.
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM co_leg_seed;
  IF v_n <> 100 THEN RAISE EXCEPTION 'seed payload: expected 100 rows, got %', v_n; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM co_leg_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT seat FROM co_leg_seed GROUP BY seat HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate seat key(s)', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, party, party_short_name,
   email_addresses, alternate_names, photo_origin_url, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.party, s.party_short,
       CASE WHEN s.email IS NULL THEN NULL ELSE ARRAY[s.email]::text[] END,
       s.aliases, s.photo_url, true, true,
       'leg.colorado.gov/legislators for identity/district/party/email; data.openstates.org for cross-check and the official portrait URL; ballotpedia.org chamber rosters for the assumed-office date. All 100 seats reconciled across all three. Retrieved 2026-08-21.'
FROM co_leg_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy, via the helper ───────────────────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before inserting,
-- which is the whole reason it exists. how_started is passed NULL explicitly:
-- the default is 'elected' and that is not known to be true for every member.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, o.id AS office_id, p.id AS politician_id, s.seat
    FROM co_leg_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.district_type = s.district_type
     AND d.mtfcc = s.mtfcc
     AND d.state ILIKE 'co'
     AND right(d.geo_id, 3) = s.district_suffix
    JOIN essentials.offices o
      ON o.district_id = d.id AND o.title = s.office_title
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = o.id AND t.politician_id = p.id
    )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      'leg.colorado.gov/legislators for identity/district/party/email; data.openstates.org for cross-check and the official portrait URL; ballotpedia.org chamber rosters for the assumed-office date. All 100 seats reconciled across all three. Retrieved 2026-08-21.',
      NULL,                 -- how_started: election vs vacancy appointment not verified per member
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % legislator(s)', v_seated;
END $$;

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_pol int; v_held int; v_null int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_pol
  FROM essentials.politicians WHERE external_id BETWEEN -829999 AND -810001;

  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL
  -- politician_id and NOT an absent row. Counting seated occupancy REQUIRES the
  -- IS NOT NULL, or this passes vacuously.
  SELECT count(*) INTO v_held
  FROM essentials.office_current_holder och
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER')
    AND d.state ILIKE 'co'
    AND och.politician_id IS NOT NULL;

  SELECT count(*) INTO v_null
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND d.state ILIKE 'co'
    AND t.term_start IS NULL;

  -- A CO state-leg office with no term row is invisible: no holder, and nothing
  -- errors. This is the failure mode CI cannot catch, so it is asserted here.
  SELECT count(*) INTO v_orphan
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND d.state ILIKE 'co'
    AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);

  IF v_pol <> 100 THEN RAISE EXCEPTION 'CO legislators inserted: expected 100, got %', v_pol; END IF;
  IF v_held <> 100 THEN RAISE EXCEPTION 'CO state-leg seats with a current holder: expected 100, got %', v_held; END IF;
  IF v_null <> 0 THEN RAISE EXCEPTION 'CO state-leg terms with NULL term_start: %', v_null; END IF;
  IF v_orphan <> 0 THEN RAISE EXCEPTION 'CO state-leg offices with NO term row (invisible seats): %', v_orphan; END IF;
END $$;

COMMIT;
