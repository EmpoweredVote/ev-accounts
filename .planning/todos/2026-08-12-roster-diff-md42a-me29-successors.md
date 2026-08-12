# Two successors never seated — MD 42A and ME 29 (found 2026-08-12)

Found by `backend/scripts/roster-diff.mjs`, the multi-state roster diff built after TX SD-22
(migration 1712). All 11 states where we hold a full chamber were swept — 22 chambers, 1,338 seated
rows. **These two are the entire actionable result.**

Both are the *mirror image* of Birdwell: we correctly recorded the vacancy and then never seated the
successor. `office_current_holder` returns a NULL holder, so the seat renders as vacant to voters who
now have a sitting representative.

## MD 42A — Alexander M. Harlan (R), sworn 2026-08-03

- Office `7f8936f1-734a-4f4e-9d48-d73399dba7f1`, `State Legislative Subdistrict 42A`.
  `is_vacant = true`, `vacant_since = 2026-06-01`, **0 `office_terms` rows** — so there is no
  predecessor term to close.
- Nino Mangione resigned in June 2026 (ran for Baltimore County Council). Harlan was nominated by
  the Baltimore County Republican Central Committee and **appointed by Gov. Moore**.
- Oracle: `mgaleg.maryland.gov/mgawebsite/Members/Details/harlan01` — "Delegate Alexander M. Harlan",
  district "42A", Republican, **"Member of the Maryland House of Delegates since August 3, 2026."**
- ⇒ `how_started => 'appointed'`, `term_start = 2026-08-03`, `start_precision => 'day'`.

## ME 29 — Nancy J. Theriault (R, Millinocket), sworn 2026-07-14

- Office `ddb05295-68a1-4247-8b69-476269e13840`, `State House District 29`. `is_vacant = true`,
  `vacant_since = NULL`, **0 `office_terms` rows**.
- Rep. Kathy Javner (R-Chester) **died** early 2026; Theriault won the June 2026 special election
  (61.3%, 1,102–695 over Nancy McDowell) and was sworn in by Gov. Mills.
- Oracle: `legislature.maine.gov/house/MemberProfiles/Details/3142` — "Nancy J. Theriault", House
  District 29, Republican, Millinocket. The profile carries **no swearing-in date**; the date comes
  from the Maine House Republicans release, published 2026-07-14 and reading "sworn in today".
- ⇒ `how_started => 'elected'`, `term_start = 2026-07-14`, `start_precision => 'day'`.

## 🔴 Why this is a seed job and not two `seat_officeholder` calls

1. **Neither person exists in `essentials.politicians`.** Searching `%harlan%` / `%theriault%`
   returns 16 rows and **every one is FEC ALLCAPS committee junk** ("HARLAN FOR CAPITOLA CITY
   COUNCIL 2010", "THERIAULT FOR TORRANCE UNIFIED SCHOOL BOARD") — all California, none a person.
   Do not let a fuzzy match pick one of these up. Two new politician rows are needed, under the
   normal dedupe rules.
2. **`seat_officeholder` does NOT clear `offices.is_vacant`.** Only `vacate_office` syncs that flag.
   Seating without clearing it lands the row straight in the `is_vacant` trap documented in
   CLAUDE.md — a seat carrying a current term while still flagged vacant, which makes any query
   filtering `is_vacant = false` emit a spurious all-NULL office row for the new holder. Clear
   `is_vacant` and `vacant_since` in the same migration, and post-verify both.
3. Neither has a headshot; both are candidates for the next sweep.

## Also surfaced, needing a decision rather than a fix

**Maine seats two tribal representatives** the diff reports as unheld: **Aaron Dana**
(Passamaquoddy Tribe) and **Brian Reynolds** (Houlton Band of Maliseet Indians). They are real
members of the Maine House but are not district-based, and we have no office for either — Maine is
151 numbered districts on our side against 153 members on theirs. This is a **modeling** question
(do non-district tribal representatives get an office?), not drift. Left alone deliberately.

## What came back clean

MD 33C looked like a mismatch — ours "Heather Bagnall" vs Open States "Heather Bagnall Tudball" —
but the chamber's own page is still `bagnall01`, "Delegate Heather Bagnall". **We match the oracle;
Open States is the outlier.** No action. This is the argument for checking the chamber's own roster
before believing a third party.

Every other chamber — AZ, CA, MA, MD upper, ME upper, NV, OR, TX, UT, VA, WI — is **zero**.
