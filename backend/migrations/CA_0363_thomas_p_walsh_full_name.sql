-- CA_0363: correct Rep. Thomas Walsh's (MA, 12th Essex) middle initial: "Thomas J. Walsh" -> "Thomas P. Walsh".
--
-- Found in gun-policy Season 3 Stage 5 (2026-11-04): the Massachusetts legislature names him "Thomas P. Walsh".
-- His own profile, https://malegislature.gov/Legislators/Profile/TJW1 (the URL already stored on his row), was read
-- 2026-11-04: its title is "Representative Thomas P. Walsh", it prints "Thomas P. Walsh" 35 times and "Thomas J."
-- nowhere, and it names his district, 12th Essex. (The profile code TJW1 is the legislature's own id, not a
-- name.) LegiScan people_id 17960 "Thomas Walsh", HD-12-ESS, is already mapped to him by district.
--
-- Old value, recorded here because the UPDATE overwrites it: full_name = 'Thomas J. Walsh'.
-- first_name / last_name ('Thomas' / 'Walsh') are right and unchanged; middle_initial stays NULL.
-- He has no race_candidates rows, and no other politician row is named Thomas ? Walsh.
-- Guarded on the exact old value and on full_name_manual_override = false: idempotent, and it refuses a row
-- someone has since edited.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = 'ff2939e8-befb-4c16-ace7-9f677847088c' AND full_name IN ('Thomas J. Walsh', 'Thomas P. Walsh')
     AND first_name = 'Thomas' AND last_name = 'Walsh' AND NOT full_name_manual_override;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-flight: expected Walsh ff2939e8 as authored, found % rows', n; END IF;
END $$;

UPDATE essentials.politicians SET full_name = 'Thomas P. Walsh'
 WHERE id = 'ff2939e8-befb-4c16-ace7-9f677847088c' AND full_name = 'Thomas J. Walsh' AND NOT full_name_manual_override;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.politicians
   WHERE id = 'ff2939e8-befb-4c16-ace7-9f677847088c' AND full_name = 'Thomas P. Walsh';
  IF n <> 1 THEN RAISE EXCEPTION 'post-verify: expected Walsh ff2939e8 named Thomas P. Walsh, found %', n; END IF;
  SELECT count(*) INTO n FROM essentials.politicians WHERE full_name = 'Thomas J. Walsh';
  IF n <> 0 THEN RAISE EXCEPTION 'post-verify: % rows still named Thomas J. Walsh', n; END IF;
END $$;

COMMIT;
