# Two successors never seated — MD 42A and ME 29 (found 2026-08-12)

## RESOLVED 2026-08-12 (same day) — both seated on prod, migration 1715

- **MD 42A → Alexander M. Harlan** (R), `external_id -2420142`, term_start **2026-08-03**,
  `how_started = 'appointed'`, `start_precision = 'day'`, `is_appointed = true`,
  `appointment_date = 2026-08-03`.
- **ME 29 → Nancy J. Theriault** (R), `external_id -232029`, term_start **2026-07-14**,
  `how_started = 'elected'`, `start_precision = 'day'`.
- Both offices had `is_vacant` and `vacant_since` **cleared in the same migration** — see the
  `seat_officeholder` note below; the post-verify asserts it explicitly.
- `roster-diff.mjs md me` now returns **MD lower 141 v 141** and **ME lower 151 v 153** (the 2 tribal
  seats), with zero seat gaps. `check:occupancy` and `check:migrations` both green.

**No vacancy span was written for either seat**, deliberately. Neither office had a predecessor term
(0 rows) and neither predecessor exists as a politician. MD 42A's `vacant_since` read 2026-06-01, but
that date's provenance is unknown to us and the sources say only "June 2026" — so per ADR 0002 we did
not invent a span start. The record now reads "Harlan from 2026-08-03, nothing asserted before".

**🔴 The MD `external_id` slot was a trap.** The band is district-ordered and the slot where 42A
belongs (`-2420124`) was already occupied — by an inactive politician row literally named **"Vacant"**
that the MD seed parked there. Reasoning from the gap in the *seated* rows would have picked it and
collided; `external_id` is uniquely indexed, so it would have failed the insert rather than
mis-seating, but only because that index exists. Harlan extends the band to `-2420142` instead and the
placeholder is left inert (4 such rows exist repo-wide, none active, none seated — their own cleanup
question). ME's band is district-keyed (`-232000 - district`), so ME 29 took the `-232029` slot its
own seed had left empty.

---
_Original findings below._

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

## Headshots ✅ 2026-08-12 (migration 1716)

Both from the chambers' own official portraits, `public_domain`, mirrored to `politician_photos` at
600x750 like their seatmates:

- **Harlan** — `mgaleg.maryland.gov/2026RS/images/harlan01.jpg` (250x300). Alt text "Harlan,
  Alexander M." and a Maryland-flag lapel pin both corroborate identity. Top crop is **tight** — hair
  at the frame edge, tighter than the usual one-ear-above-hair; accepted because the source frames it
  that way.
- **Theriault** — `legislature.maine.gov/house/Repository/MemberProfiles/c4c60e9c…_Theriault.jpg`
  (152x202). Soft at 600x750, and **that is the chamber standard, not a shortfall**: seatmate Irene
  Gifford's source is the same 152x202 stored at 600x750.

🔴 **Identity was established PAGE-BOUND, not by filename.** A *Timothy* Theriault also exists in
Maine politics; filename matching is exactly what fails there. Both renders were then pulled back
from the CDN and viewed at the pid they were stored under — a byte-count match cannot catch a
pid-to-face swap, which is the defect a contact sheet has caught in prior waves.

🔴 **Migration 1715 had a defect, fixed in 1716.** It created both politician rows without setting
`politicians.is_vacant`, leaving NULL where all 1,338 seated state legislators carry `false`. The
headshot tooling filters `AND p.is_vacant = false`, and **NULL fails that**, so both members were
invisible to the very sweep meant to find people without photos. Same family as the missing-`office_terms`
trap: nothing errors, the row just stops existing as far as the worklist is concerned. When
hand-creating a politician, copy the peers' full column shape — not just the columns you happen to
care about.

## Tribal representatives → ADR 0003 (accepted 2026-08-12)

Resolved as a **modelling decision**, not an exception:
[`docs/adr/0003-non-residency-representation.md`](../../docs/adr/0003-non-residency-representation.md).
Maine reserves **three** non-voting tribal seats (Penobscot Nation, Passamaquoddy, Houlton Band of
Maliseet); two are filled and **Penobscot's is vacant because the Nation has not sent anyone** — a
political act the current model cannot record at all. Two new fields, `districts.representation_basis`
and `offices.voting_powers`, plus a binding rule that membership in a polity is **never inferred from
an address** (so these seats are additive and explained, never assigned). Not yet implemented; Maine's
three seats are the first instance and the territories follow as a powers-only change.

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
