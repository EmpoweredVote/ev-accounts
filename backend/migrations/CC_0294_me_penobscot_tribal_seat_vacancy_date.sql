-- CC_0294 — date the Penobscot Nation's vacant tribal seat in the Maine House.
--
-- This is the last open item from the Maine municipal programme
-- (`backend/data/seed-me-municipal-2026/ROSTERS.md`), and it is the one item in that queue
-- that was NOT skeleton work. It is a real vacancy that has been wearing the skeleton's
-- clothes: flagged `is_vacant` with a NULL `vacant_since`.
--
-- ⚠ THE TRACKER SAID "THAT COULD BE A REAL VACANCY — DO NOT SEAT IT FROM A ROSTER WITHOUT
-- CHECKING." It is, and this migration does not seat anybody. It writes the date.
--
-- ─── WHAT WAS CHECKED, AND AGAINST WHAT ──────────────────────────────────────────────────
-- Maine seats Wabanaki tribal representatives in the House under 3 MRSA §1 (ADR 0003; offices
-- created by migration 1718). They are `representation_basis = 'membership'`, carry no
-- `geo_id` — enrollment is not inferable from an address — and are `committee_only`.
--
-- We hold three, and the Legislature's own member list for the 132nd Legislature, read
-- 2026-10-26, shows exactly TWO sitting under the heading "Tribal Representatives":
--
--   Dana, Aaron M.  — Tribal Representative (Tribal - Princeton)   → Passamaquoddy, seated
--   Reynolds, Brian — Tribal Representative (Tribal - Augusta)     → Maliseet, seated
--   (no Penobscot representative appears)
--
-- 🟢 So our data was right and the flag is honest. What it lacked was the date that separates
-- a documented vacancy from "we have not seeded a holder".
--
-- ─── THE DATE, AND WHY THIS ONE ──────────────────────────────────────────────────────────
-- The Maine Legislature's Law Library publishes a *Chronology of Wabanaki Tribal
-- Representation* (`legislature.maine.gov/lawlibrary/chronology-of-tribal-representation/9262`,
-- page dated 2025-01-22). Two entries matter, and they are different events:
--
--   2015 — "On May 26 the Penobscot Nation and Passamaquoddy Tribe withdrew their
--           representatives to the Maine Legislature."
--   2016 — "June 20. The Penobscot Nation states it is formally vacating its Legislative seat
--           in favor of naming an ambassador to facilitate relations between the Nation and
--           state and federal governments."
--
-- ▶ **The 2015 withdrawal emptied the seat; the 2016 statement confirmed a state that already
--   existed.** `vacant_since` is the FIRST VACANT DAY, so it is `2015-05-27` — the day after.
--   The representative was still the representative on 26 May: he addressed the House that day
--   and then left. This follows the Brewer precedent exactly (`CC_0292`, R9d): a councillor
--   recorded at the meeting that ended his tenure was a member of record for that day, so the
--   first vacant day is the next one. Reading 2015-05-26 instead is defensible and differs by
--   one day; the Brewer rule decides it, and consistency is worth more than the day.
--
-- ⚠ The Passamaquoddy withdrew on the SAME day and came back — Aaron Dana has held their seat
--   since 2022. The Maliseet seat was separately unfilled from 2018-11-28 and was reclaimed in
--   May 2025 by Brian Reynolds. **A withdrawn tribal seat is not permanently withdrawn**, which
--   is the whole reason this is a dated vacancy and not a deletion.
--
-- 🔴 NO `office_terms` VACANCY SPAN IS WRITTEN. The Penobscot representative who left in 2015
--   was never seeded, so there is no term to close, and `vacate_office` exists to close one.
--   Same shape as Brewer's At-Large 5.
--
-- ─── ⚠ A FOURTH SEAT EXISTS IN LAW AND MUST NOT BE CREATED YET ───────────────────────────
-- PL 2026 c. 705 (LD 785 / SP 344, "An Act to Amend Certain Tax Laws Regarding the Wabanaki
-- Nations"), signed by the Governor 2026-04-15, amends 3 MRSA §1:
--
--   "Beginning with the 133rd Legislature, the Tribal Clerk of the Mi'kmaq Nation shall …
--    furnish to the Clerk of the preceding House of Representatives a certification … of the
--    name and residence of the Representative-elect of the Mi'kmaq Nation to the Legislature."
--
-- and §2 likewise, "beginning with the First Regular Session of the 133rd Legislature".
--
-- 🔴 **THE 133rd LEGISLATURE CONVENES ON THE FIRST WEDNESDAY OF DECEMBER 2026 — 2026-12-02.**
-- Until then the Mi'kmaq Nation has no seat to hold, and creating the office now would assert
-- to a Mi'kmaq citizen that they are represented in Augusta today when they are not. This
-- migration therefore **refuses to run if a Mi'kmaq seat already exists**, the same way
-- `CC_0290` refuses while a Missouri 2026 polygon exists. The follow-up is dated in
-- ROSTERS.md.
--
-- ─── MEASUREMENT ─────────────────────────────────────────────────────────────────────────
-- `offices_missing_terms` does NOT move: 297 / 58 / 239 before and after. Dating a vacancy
-- does not seat anybody, and the view counts offices with no term row either way. What moves
-- is the sub-bucket that actually matters — **dated vacancies 14 → 15** — and with it the last
-- undated vacancy flag anywhere in Maine, at any level of government, goes to zero.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_txt text;
BEGIN
  -- Maine holds exactly three membership-basis House seats today, and they are the three
  -- Wabanaki nations named in 3 MRSA §1 before PL 2026 c.705 takes effect.
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'State of Maine' AND c.name = 'Maine House of Representatives'
     AND d.representation_basis = 'membership';
  IF n <> 3 THEN
    RAISE EXCEPTION 'CC_0294: expected 3 Wabanaki tribal seats, found % - read 3 MRSA sec.1 '
                    'and the Legislature''s member list before changing anything', n;
  END IF;

  -- 🔴 PL 2026 c.705's Mi'kmaq seat begins with the 133rd Legislature (convenes 2026-12-02).
  -- If one exists already, somebody created it early and this migration's premises are stale.
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.name = 'State of Maine' AND o.representation_note ILIKE '%mi''kmaq%';
  IF bad <> 0 THEN
    RAISE EXCEPTION 'CC_0294: a Mi''kmaq tribal seat already exists. PL 2026 c.705 gives it to '
                    'the 133rd Legislature, which convenes 2026-12-02 - if that date has passed '
                    'this migration is simply out of date; if it has not, the seat is premature';
  END IF;

  -- 🔴 A membership district must never carry a geo_id (ADR 0003): enrollment is not inferable
  -- from an address, so these seats are additional and explained, never assigned.
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'State of Maine' AND d.representation_basis = 'membership'
     AND d.geo_id IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0294: % membership district(s) carry a geo_id', bad; END IF;

  -- exactly one of the three is unseated, and it is the Penobscot one
  SELECT string_agg(substring(o.representation_note from 'reserved for the ([^ ]+( [^ ]+)*?) in the'),
                    ', ' ORDER BY o.id) INTO v_txt
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'State of Maine' AND d.representation_basis = 'membership'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF v_txt IS DISTINCT FROM 'Penobscot Nation' THEN
    RAISE EXCEPTION 'CC_0294: the unseated tribal seat(s) are [%], expected the Penobscot Nation '
                    'alone - re-read the Legislature''s member list', coalesce(v_txt, 'none');
  END IF;

  -- and it is flagged WITHOUT a date, which is exactly what this migration fixes
  SELECT count(*) INTO bad FROM essentials.offices o
   WHERE o.id = '82d545f5-bdfd-4fc3-9161-b4e2fddd32ac'
     AND o.is_vacant AND o.vacant_since IS NULL;
  IF bad <> 1 THEN
    RAISE EXCEPTION 'CC_0294: the Penobscot seat is not flagged-without-a-date; somebody has '
                    'already changed it, read the row first';
  END IF;
END $$;

-- ─── Date the vacancy. No seating, no span, no new office. ───────────────────────────────
UPDATE essentials.offices
   SET vacant_since = DATE '2015-05-27'
 WHERE id = '82d545f5-bdfd-4fc3-9161-b4e2fddd32ac'
   AND is_vacant
   AND vacant_since IS DISTINCT FROM DATE '2015-05-27';

-- ─── And say so in the note a voter actually reads ───────────────────────────────────────
-- `representation_note` is required whenever voting_powers <> 'full' or representation_basis
-- <> 'residency', and the read path must not render the seat without it. The old text said
-- "withdrew in 2015"; this gives the voter both events, the current status and the date.
UPDATE essentials.offices
   SET representation_note =
       'A seat reserved for the Penobscot Nation in the Maine House of Representatives. Its '
    || 'holder is chosen by the Nation, not elected by residents of a geographic district, and '
    || 'may introduce bills, serve on committees and vote in committee, but not on the House '
    || 'floor. The seat is currently empty: the Penobscot Nation withdrew its representative on '
    || '26 May 2015, and on 20 June 2016 stated that it was formally vacating the seat in favour '
    || 'of naming an ambassador to the state and federal governments. The Nation may fill it '
    || 'again at any time — the Passamaquoddy Tribe withdrew on the same day in 2015 and returned '
    || 'in 2022. This does not replace the district representative for anyone; it is additional '
    || 'representation for tribal members.'
 WHERE id = '82d545f5-bdfd-4fc3-9161-b4e2fddd32ac';

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int; bad int; v_unflagged int; v_total int; v_dated int; v_txt text;
BEGIN
  -- the seat is flagged AND dated, and still unseated
  SELECT count(*) INTO bad FROM essentials.offices o
   WHERE o.id = '82d545f5-bdfd-4fc3-9161-b4e2fddd32ac'
     AND o.is_vacant AND o.vacant_since = DATE '2015-05-27'
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF bad <> 1 THEN RAISE EXCEPTION 'CC_0294: the Penobscot seat is not flagged-and-dated-and-unseated'; END IF;

  -- the note still exists and now names both events
  SELECT count(*) INTO bad FROM essentials.offices o
   WHERE o.id = '82d545f5-bdfd-4fc3-9161-b4e2fddd32ac'
     AND o.representation_note IS NOT NULL
     AND o.representation_note LIKE '%26 May 2015%'
     AND o.representation_note LIKE '%20 June 2016%';
  IF bad <> 1 THEN
    RAISE EXCEPTION 'CC_0294: the representation_note is missing or does not carry both dates - '
                    'the read path must not render a non-residency seat without a note';
  END IF;

  -- nobody was seated and no office was created
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE g.name = 'State of Maine' AND d.representation_basis = 'membership';
  IF n <> 3 THEN RAISE EXCEPTION 'CC_0294: Maine now has % tribal seats, expected 3', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name = 'State of Maine' AND d.representation_basis = 'membership'
     AND och.politician_id IS NOT NULL;
  IF n <> 2 THEN
    RAISE EXCEPTION 'CC_0294: % tribal seats are held, expected 2 (Passamaquoddy and Maliseet)', n;
  END IF;

  -- 🟢 THE CLOSE: not one Maine office at ANY level is flagged vacant without a date.
  SELECT string_agg(g.name || ' / ' || o.title, ', ') INTO v_txt
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.is_vacant AND o.vacant_since IS NULL
     AND (lower(coalesce(d.state,'')) = 'me' OR g.name LIKE '%, Maine, US' OR g.name = 'State of Maine');
  IF v_txt IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0294: Maine offices still flagged without a date: %', v_txt;
  END IF;

  -- and all three that remain flagged in Maine are dated and real
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.is_vacant
     AND (lower(coalesce(d.state,'')) = 'me' OR g.name LIKE '%, Maine, US' OR g.name = 'State of Maine');
  IF n <> 3 THEN
    RAISE EXCEPTION 'CC_0294: % flagged Maine offices, expected 3 (Brewer, South Portland schools, Penobscot)', n;
  END IF;

  -- the global invariant: zero seated-and-flagged, repo-wide
  SELECT count(*) INTO bad FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.is_vacant AND och.politician_id IS NOT NULL;
  IF bad <> 0 THEN RAISE EXCEPTION 'CC_0294: % office(s) are seated AND flagged - the is_vacant trap', bad; END IF;

  -- 🔴 the drift metric must NOT move: dating a vacancy seats nobody
  SELECT count(*) FILTER (WHERE NOT o.is_vacant), count(*),
         count(*) FILTER (WHERE o.is_vacant AND o.vacant_since IS NOT NULL)
    INTO v_unflagged, v_total, v_dated
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 239 THEN
    RAISE EXCEPTION 'CC_0294: unflagged offices_missing_terms is %, expected the 239 baseline', v_unflagged;
  END IF;
  IF v_total <> 297 THEN
    RAISE EXCEPTION 'CC_0294: total offices_missing_terms is %, expected 297 unchanged - this '
                    'migration seats nobody', v_total;
  END IF;
  IF v_dated <> 15 THEN
    RAISE EXCEPTION 'CC_0294: dated vacancies is %, expected 14 + 1 = 15', v_dated;
  END IF;

  RAISE NOTICE 'CC_0294 OK - Penobscot tribal seat dated 2015-05-27; zero undated vacancy flags '
               'left in Maine; missing_terms unchanged at 297/58/239, dated vacancies 14 -> 15';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE THIS ADDS: A FLAG WITHOUT A DATE CANNOT TELL YOU WHICH KIND OF THING IT IS.
-- Across Maine, `is_vacant = true, vacant_since = NULL` meant "nobody has seeded this" 137 times
-- and "a real vacancy nobody dated" once. The two are indistinguishable in the database and
-- point in opposite directions — one is a data gap to fill, the other is a fact to publish.
-- ▶ The programme spent five waves on the first and this migration on the second, and only the
--   DATE tells them apart. Date a vacancy at the moment you establish it, or the next session
--   has to re-derive which kind it was.
--
-- ▶ DATED FOLLOW-UP, 2026-12-02 — the 133rd Legislature convenes and the Mi'kmaq Nation's seat
--   exists in law (PL 2026 c.705). Create it then, as a 4th `membership` district with NO
--   geo_id, `voting_powers = 'committee_only'`, and a `representation_note` — and seat it only
--   if the Nation has certified a Representative-elect, which it is not obliged to do.
--   ⚠ Write BOTH exits down: "they certified someone" and "they did not". The Missouri hedge
--   sat unexited for a year because only one of its two exits created work
--   (`project_mo_2026_map_blocked_not_stale`).
